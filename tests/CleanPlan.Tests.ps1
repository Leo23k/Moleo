BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    . "$script:RepoRoot\lib\clean\plan.ps1"
}

BeforeEach {
    $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:Root | Out-Null
    $script:SavedProtectedPaths = @($script:ProtectedPaths)
    Set-DryRunMode -Enabled $false
    $script:MoleCleanPlanPlans = @{}
}

AfterEach {
    $script:ProtectedPaths = $script:SavedProtectedPaths
}

function New-TestPlan {
    param([string[]]$Paths)
    $capture = @{ Items = @{}; SkippedCount = 0 }
    $script:MoleCleanPlanCapture = $capture
    foreach ($path in $Paths) { Add-MoleCleanPlanCandidate -Path $path -Description 'Test cache' }
    $script:MoleCleanPlanCapture = $null
    return Complete-MoleCleanPlan -Capture $capture
}

Describe 'Moleo cleanup plans' {
    It 'scans through the cleanup providers in dry-run capture mode without deleting' {
        $file = Join-Path $script:Root 'scan-cache.dat'
        [IO.File]::WriteAllText($file, 'scan-data')
        $script:ScanFixture = $file
        Mock Invoke-UserCleanup {
            if (-not (Test-DryRunMode)) { throw 'Scan did not enable dry-run mode.' }
            Add-MoleCleanPlanCandidate -Path $script:ScanFixture -Description 'Mock temp cache'
        }
        Mock Clear-BrowserCaches { }
        Mock Clear-GPUShaderCaches { }
        Mock Clear-AppCaches { }
        Mock Invoke-AppCleanup { }

        $plan = New-MoleCleanPlan
        $plan.Items.Count | Should -Be 1
        $plan.Items[0].Path | Should -Be $file
        $plan.Items[0].Group | Should -Be 'Mock temp cache'
        Test-Path -LiteralPath $file | Should -BeTrue
        (Test-DryRunMode) | Should -BeFalse
    }

    It 'returns a real file with group, path, reason and estimated bytes, then removes only that selected file' {
        $file = Join-Path $script:Root 'cache.dat'
        [IO.File]::WriteAllText($file, 'planned-data')
        $plan = New-TestPlan -Paths @($file)

        $plan.Items.Count | Should -Be 1
        $plan.Items[0].Group | Should -Be 'Test cache'
        $plan.Items[0].Path | Should -Be $file
        $plan.Items[0].Type | Should -Be 'File'
        $plan.Items[0].EstimatedBytes | Should -Be ([IO.File]::ReadAllBytes($file).Length)

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
        $result.SucceededCount | Should -Be 1
        $result.FailedCount | Should -Be 0
        $result.LogicalBytesRemoved | Should -Be $plan.Items[0].EstimatedBytes
        Test-Path -LiteralPath $file | Should -BeFalse
    }

    It 'does not add a protected path to a plan' {
        $file = Join-Path $script:Root 'protected.dat'
        [IO.File]::WriteAllText($file, 'keep')
        $script:ProtectedPaths += $script:Root
        $plan = New-TestPlan -Paths @($file)
        $plan.Items.Count | Should -Be 0
        $plan.SkippedCount | Should -BeGreaterThan 0
        Test-Path -LiteralPath $file | Should -BeTrue
    }

    It 'refuses a file replaced after scan and leaves the replacement intact' {
        $file = Join-Path $script:Root 'replace.dat'
        [IO.File]::WriteAllText($file, 'old')
        $plan = New-TestPlan -Paths @($file)
        Move-Item -LiteralPath $file -Destination (Join-Path $script:Root 'old.dat')
        [IO.File]::WriteAllText($file, 'new')

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
        $result.FailedCount | Should -Be 1
        $result.Results[0].Error | Should -Match 'snapshot|changed|Scan again'
        Test-Path -LiteralPath $file | Should -BeTrue
    }

    It 'refuses a file whose content changed after scan' {
        $file = Join-Path $script:Root 'changed.dat'
        [IO.File]::WriteAllText($file, 'old')
        $plan = New-TestPlan -Paths @($file)
        [IO.File]::WriteAllText($file, 'new content')

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
        $result.FailedCount | Should -Be 1
        Test-Path -LiteralPath $file | Should -BeTrue
    }

    It 'refuses changed contents even when size and timestamp are restored' {
        $file = Join-Path $script:Root 'restored-stamp.dat'
        [IO.File]::WriteAllText($file, 'old')
        $originalWrite = [IO.File]::GetLastWriteTimeUtc($file)
        $plan = New-TestPlan -Paths @($file)
        [IO.File]::WriteAllText($file, 'new')
        [IO.File]::SetLastWriteTimeUtc($file, $originalWrite)

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
        $result.FailedCount | Should -Be 1
        $result.Results[0].Error | Should -Match 'contents changed'
        Test-Path -LiteralPath $file | Should -BeTrue
    }

    It 'refuses a file replaced by a directory after scan' {
        $file = Join-Path $script:Root 'type-change.dat'
        [IO.File]::WriteAllText($file, 'scanned')
        $plan = New-TestPlan -Paths @($file)
        Remove-Item -LiteralPath $file
        New-Item -ItemType Directory -Path $file | Out-Null
        [IO.File]::WriteAllText((Join-Path $file 'keep.dat'), 'keep')

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
        $result.FailedCount | Should -Be 1
        Test-Path -LiteralPath (Join-Path $file 'keep.dat') | Should -BeTrue
    }

    It 'refuses a target replaced by a junction after scan' {
        $target = Join-Path $script:Root 'junction-target'
        New-Item -ItemType Directory -Path $target | Out-Null
        $path = Join-Path $script:Root 'junction-replacement.dat'
        [IO.File]::WriteAllText($path, 'scanned')
        $plan = New-TestPlan -Paths @($path)
        Remove-Item -LiteralPath $path
        New-Item -ItemType Junction -Path $path -Target $target | Out-Null

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
        $result.FailedCount | Should -Be 1
        Test-Path -LiteralPath $path | Should -BeTrue
    }

    It 'refuses a file under a replaced parent directory' {
        $parent = Join-Path $script:Root 'cache'
        New-Item -ItemType Directory -Path $parent | Out-Null
        $file = Join-Path $parent 'entry.dat'
        [IO.File]::WriteAllText($file, 'old')
        $plan = New-TestPlan -Paths @($parent)
        Move-Item -LiteralPath $parent -Destination (Join-Path $script:Root 'old-cache')
        New-Item -ItemType Directory -Path $parent | Out-Null
        [IO.File]::WriteAllText($file, 'replacement')

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
        $result.FailedCount | Should -Be 1
        Test-Path -LiteralPath $file | Should -BeTrue
    }

    It 'leaves files added to a scanned directory outside the plan untouched' {
        $folder = Join-Path $script:Root 'changing-folder'
        New-Item -ItemType Directory -Path $folder | Out-Null
        $planned = Join-Path $folder 'planned.dat'
        $newFile = Join-Path $folder 'added-after-scan.dat'
        [IO.File]::WriteAllText($planned, 'planned')
        $plan = New-TestPlan -Paths @($folder)
        [IO.File]::WriteAllText($newFile, 'keep')

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
        $result.SucceededCount | Should -Be 1
        Test-Path -LiteralPath $planned | Should -BeFalse
        Test-Path -LiteralPath $newFile | Should -BeTrue
    }

    It 'does not follow or plan a junction' {
        $target = Join-Path $script:Root 'target'
        New-Item -ItemType Directory -Path $target | Out-Null
        $sentinel = Join-Path $target 'keep.dat'
        [IO.File]::WriteAllText($sentinel, 'keep')
        $link = Join-Path $script:Root 'junction'
        New-Item -ItemType Junction -Path $link -Target $target | Out-Null

        $plan = New-TestPlan -Paths @($link)
        $plan.Items.Count | Should -Be 0
        Test-Path -LiteralPath $sentinel | Should -BeTrue
    }

    It 'does not plan the contents of a directory containing a reparse point' {
        $root = Join-Path $script:Root 'cache-tree'
        $target = Join-Path $script:Root 'target'
        New-Item -ItemType Directory -Path $root,$target | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'ordinary.dat'), 'ordinary')
        $sentinel = Join-Path $target 'keep.dat'
        [IO.File]::WriteAllText($sentinel, 'keep')
        New-Item -ItemType Junction -Path (Join-Path $root 'linked') -Target $target | Out-Null

        $plan = New-TestPlan -Paths @($root)
        $plan.Items.Count | Should -Be 0
        Test-Path -LiteralPath $sentinel | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $root 'ordinary.dat') | Should -BeTrue
    }

    It 'does not follow a symbolic link' {
        $target = Join-Path $script:Root 'target-file.dat'
        [IO.File]::WriteAllText($target, 'keep')
        $link = Join-Path $script:Root 'link.dat'
        try { New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Out-Null }
        catch { Set-ItResult -Skipped -Because 'Creating symbolic links is not permitted by this Windows test token.'; return }

        $plan = New-TestPlan -Paths @($link)
        $plan.Items.Count | Should -Be 0
        Test-Path -LiteralPath $target | Should -BeTrue
    }

    It 'refuses a file that is in use after scan' {
        $file = Join-Path $script:Root 'in-use.dat'
        [IO.File]::WriteAllText($file, 'busy')
        $plan = New-TestPlan -Paths @($file)
        $lock = [IO.File]::Open($file, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try {
            $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)
            $result.FailedCount | Should -Be 1
            Test-Path -LiteralPath $file | Should -BeTrue
        }
        finally { $lock.Dispose() }
    }

    It 'leaves every unselected plan item untouched' {
        $first = Join-Path $script:Root 'first.dat'
        $second = Join-Path $script:Root 'second.dat'
        [IO.File]::WriteAllText($first, 'first')
        [IO.File]::WriteAllText($second, 'second')
        $plan = New-TestPlan -Paths @($first, $second)
        $selected = $plan.Items | Where-Object Path -eq $first

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($selected.Id)
        $result.SucceededCount | Should -Be 1
        Test-Path -LiteralPath $first | Should -BeFalse
        Test-Path -LiteralPath $second | Should -BeTrue
    }

    It 'reports one failed item without hiding another item success' {
        $good = Join-Path $script:Root 'good.dat'
        $changed = Join-Path $script:Root 'changed.dat'
        [IO.File]::WriteAllText($good, 'good')
        [IO.File]::WriteAllText($changed, 'old')
        $plan = New-TestPlan -Paths @($good, $changed)
        [IO.File]::WriteAllText($changed, 'modified')

        $result = Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items.Id)
        $result.SucceededCount | Should -Be 1
        $result.FailedCount | Should -Be 1
        ($result.Results | Where-Object Success).Count | Should -Be 1
        ($result.Results | Where-Object { -not $_.Success -and $_.Error }).Count | Should -Be 1
        Test-Path -LiteralPath $good | Should -BeFalse
        Test-Path -LiteralPath $changed | Should -BeTrue
    }

    It 'rejects an expired, tampered, or previously consumed plan' {
        $file = Join-Path $script:Root 'one-shot.dat'
        [IO.File]::WriteAllText($file, 'once')
        $plan = New-TestPlan -Paths @($file)
        { Invoke-MoleCleanPlan -PlanId 'invalid-plan-token' -ItemIds @($plan.Items[0].Id) } | Should -Throw '*invalid*'
        { Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @('not-an-item') } | Should -Throw
        { Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id, $plan.Items[0].Id) } | Should -Throw
        (Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id)).SucceededCount | Should -Be 1
        { Invoke-MoleCleanPlan -PlanId $plan.PlanId -ItemIds @($plan.Items[0].Id) } | Should -Throw

        [IO.File]::WriteAllText($file, 'expired')
        $expired = New-TestPlan -Paths @($file)
        $script:MoleCleanPlanPlans[$expired.PlanId].ExpiresAt = [datetime]::UtcNow.AddSeconds(-1)
        { Invoke-MoleCleanPlan -PlanId $expired.PlanId -ItemIds @($expired.Items[0].Id) } | Should -Throw '*expired*'
        Test-Path -LiteralPath $file | Should -BeTrue
    }
}
