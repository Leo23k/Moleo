# Structured, single-use cleanup plans used by Moleo's GUI.
. "$PSScriptRoot\..\core\base.ps1"
. "$PSScriptRoot\..\core\log.ps1"
. "$PSScriptRoot\..\core\ui.ps1"
. "$PSScriptRoot\..\core\file_ops.ps1"
. "$PSScriptRoot\user.ps1"
. "$PSScriptRoot\caches.ps1"
. "$PSScriptRoot\apps.ps1"

$script:MoleCleanPathGuard = $true
$script:ExportListFile = $null
$script:MoleCleanPlanCaptureMode = $false
$script:MoleCleanPlanCancellationToken = $null
$script:MoleCleanPlanPlans = @{}
$script:MoleCleanPlanCapture = $null

function Add-MoleCleanPlanFile {
    param([string]$Path, [string]$Group, [string]$Reason, $ScannedEntry = $null)

    $token = if ($script:MoleCleanPlanCancellationToken) { $script:MoleCleanPlanCancellationToken } else { [System.Threading.CancellationToken]::None }
    $snapshot = New-MoleCleanFileSnapshot -Path $Path -CancellationToken $token
    if (-not $snapshot) {
        $null = $script:MoleCleanPlanCapture.SkippedCount++
        return
    }
    if ($ScannedEntry) {
        $scanned = $ScannedEntry.MolePathSnapshot
        $sameIdentity = $null -ne $scanned -and $scanned.Entries.Count -eq $snapshot.Entries.Count
        if ($sameIdentity) {
            foreach ($scannedPath in $scanned.Entries.Keys) {
                if ($snapshot.Entries[$scannedPath] -ne $scanned.Entries[$scannedPath]) { $sameIdentity = $false; break }
            }
        }
        if (-not $sameIdentity -or $snapshot.Length -ne $ScannedEntry.Length -or
            $snapshot.LastWriteUtcTicks -ne $ScannedEntry.LastWriteTimeUtc.Ticks -or
            $snapshot.Attributes -ne [uint32]$ScannedEntry.Attributes) {
            $null = $script:MoleCleanPlanCapture.SkippedCount++
            return
        }
    }
    $key = $snapshot.Path
    if ($script:MoleCleanPlanCapture.Items.ContainsKey($key)) {
        $existing = $script:MoleCleanPlanCapture.Items[$key]
        if ($existing.Group -ne $Group -and $existing.Reason -notlike "*$Reason*") {
            $null = $existing.Reason += "; $Reason"
        }
        return
    }
    $id = [guid]::NewGuid().ToString('N')
    $null = $script:MoleCleanPlanCapture.Items[$key] = @{
        Id = $id
        Group = $Group
        Path = $snapshot.Path
        Type = 'File'
        EstimatedBytes = [long]$snapshot.Length
        Reason = $Reason
        Snapshot = $snapshot
    }
}

function Add-MoleCleanPlanCandidate {
    param([Parameter(Mandatory)][string]$Path, [string]$Description)

    if ($script:MoleCleanPlanCancellationToken -and $script:MoleCleanPlanCancellationToken.IsCancellationRequested) {
        throw [System.OperationCanceledException]::new('Cleanup scan cancelled.')
    }
    if (-not (Test-SafePath -Path $Path)) {
        $null = $script:MoleCleanPlanCapture.SkippedCount++
        return
    }
    $reason = if ($Description) { $Description } else { 'Cleanup candidate' }
    try {
        $entry = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $null = $script:MoleCleanPlanCapture.SkippedCount++
            return
        }
        if (-not $entry.PSIsContainer) {
            $null = Add-MoleCleanPlanFile -Path $entry.FullName -Group $reason -Reason $reason
            return
        }

        $tree = Get-SafeDirectoryTreeItems -Path $entry.FullName
        if (-not $tree.Success -or @($tree.Items | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count -gt 0) {
                $null = $script:MoleCleanPlanCapture.SkippedCount++
            return
        }
        foreach ($child in $tree.Items) {
            if ($script:MoleCleanPlanCancellationToken -and $script:MoleCleanPlanCancellationToken.IsCancellationRequested) {
                throw [System.OperationCanceledException]::new('Cleanup scan cancelled.')
            }
            if (-not $child.PSIsContainer) {
                $null = Add-MoleCleanPlanFile -Path $child.FullName -Group $reason -Reason $reason -ScannedEntry $child
            }
        }
    }
    catch [System.OperationCanceledException] { throw }
    catch {
        $null = $script:MoleCleanPlanCapture.SkippedCount++
        Write-Debug "Cleanup candidate was not added to the plan: $Path - $_"
    }
}

function Get-MoleCleanPlanView {
    param([hashtable]$Plan)

    $items = @($Plan.Items.Values | Sort-Object Group, Path | ForEach-Object {
        [pscustomobject]@{
            Id = $_.Id
            Group = $_.Group
            Path = $_.Path
            Type = $_.Type
            EstimatedBytes = $_.EstimatedBytes
            Reason = $_.Reason
        }
    })
    $estimatedBytes = 0L
    if ($items.Count -gt 0) { $estimatedBytes = [long](($items | Measure-Object -Property EstimatedBytes -Sum).Sum) }
    [pscustomobject]@{
        PlanId = $Plan.Id
        ExpiresAt = $Plan.ExpiresAt
        State = $Plan.State
        Items = $items
        EstimatedBytes = $estimatedBytes
        SkippedCount = $Plan.SkippedCount
        ExcludedGroups = @('Developer owner-cache commands', 'System cleanup', 'Game media')
    }
}

function Complete-MoleCleanPlan {
    param([hashtable]$Capture)

    $now = [datetime]::UtcNow
    foreach ($oldId in @($script:MoleCleanPlanPlans.Keys)) {
        if ($script:MoleCleanPlanPlans[$oldId].ExpiresAt -lt $now) { $null = $script:MoleCleanPlanPlans.Remove($oldId) }
    }
    $id = [guid]::NewGuid().ToString('N')
    $plan = @{
        Id = $id
        CreatedAt = $now
        ExpiresAt = $now.AddMinutes(10)
        State = 'Ready'
        Items = @{}
        SkippedCount = $Capture.SkippedCount
    }
    foreach ($candidate in $Capture.Items.Values) { $null = $plan.Items[$candidate.Id] = $candidate }
    $null = $script:MoleCleanPlanPlans[$id] = $plan
    return Get-MoleCleanPlanView -Plan $plan
}

function New-MoleCleanPlan {
    param([System.Threading.CancellationToken]$CancellationToken = [System.Threading.CancellationToken]::None)

    if ($script:MoleCleanPlanCaptureMode) { throw 'A cleanup plan scan is already active.' }
    $capture = @{ Items = @{}; SkippedCount = 0 }
    $script:MoleCleanPlanCapture = $capture
    $script:MoleCleanPlanCancellationToken = $CancellationToken
    $script:MoleCleanPlanCaptureMode = $true
    $oldDryRun = Test-DryRunMode
    $oldEnvironment = $env:MOLE_DRY_RUN
    Set-DryRunMode -Enabled $true
    $env:MOLE_DRY_RUN = '1'
    try {
        $null = Invoke-UserCleanup -TempDaysOld 7 -LogDaysOld 7
        if ($CancellationToken.IsCancellationRequested) { throw [System.OperationCanceledException]::new('Cleanup scan cancelled.') }
        $null = Clear-BrowserCaches
        $null = Clear-GPUShaderCaches
        $null = Clear-AppCaches
        if ($CancellationToken.IsCancellationRequested) { throw [System.OperationCanceledException]::new('Cleanup scan cancelled.') }
        $null = Invoke-AppCleanup
        if ($CancellationToken.IsCancellationRequested) { throw [System.OperationCanceledException]::new('Cleanup scan cancelled.') }
    }
    finally {
        $script:MoleCleanPlanCaptureMode = $false
        $script:MoleCleanPlanCancellationToken = $null
        $script:MoleCleanPlanCapture = $null
        Set-DryRunMode -Enabled $oldDryRun
        if ($null -eq $oldEnvironment) { Remove-Item Env:\MOLE_DRY_RUN -ErrorAction SilentlyContinue }
        else { $env:MOLE_DRY_RUN = $oldEnvironment }
    }

    return Complete-MoleCleanPlan -Capture $capture
}

function Get-MoleCleanPlan {
    param([Parameter(Mandatory)][string]$PlanId)

    if (-not $script:MoleCleanPlanPlans.ContainsKey($PlanId)) { return $null }
    $plan = $script:MoleCleanPlanPlans[$PlanId]
    if ($plan.State -eq 'Ready' -and [datetime]::UtcNow -ge $plan.ExpiresAt) { $plan.State = 'Expired' }
    return Get-MoleCleanPlanView -Plan $plan
}

function Invoke-MoleCleanPlan {
    param(
        [Parameter(Mandatory)][string]$PlanId,
        [Parameter(Mandatory)][string[]]$ItemIds
    )

    if (-not $script:MoleCleanPlanPlans.ContainsKey($PlanId)) { throw 'Cleanup plan is invalid. Scan again.' }
    $plan = $script:MoleCleanPlanPlans[$PlanId]
    if ([datetime]::UtcNow -ge $plan.ExpiresAt) { $plan.State = 'Expired'; throw 'Cleanup plan expired. Scan again.' }
    if ($plan.State -ne 'Ready') { throw 'Cleanup plan was already used. Scan again.' }
    if (-not $ItemIds -or $ItemIds.Count -eq 0) { throw 'No cleanup items were selected.' }

    $unique = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($itemId in $ItemIds) {
        if (-not $unique.Add($itemId) -or -not $plan.Items.ContainsKey($itemId)) {
            throw 'Selected item IDs do not belong to this plan.'
        }
    }
    $selected = @($ItemIds | ForEach-Object { $plan.Items[$_] })
    $plan.State = 'Consumed'
    $plan.Items = @{}

    $driveBefore = @{}
    foreach ($drive in @($selected | ForEach-Object { [IO.Path]::GetPathRoot($_.Path) } | Select-Object -Unique)) {
        try { $driveBefore[$drive] = [long](New-Object IO.DriveInfo($drive)).AvailableFreeSpace } catch { }
    }
    $oldDryRun = Test-DryRunMode
    $oldEnvironment = $env:MOLE_DRY_RUN
    Set-DryRunMode -Enabled $false
    $env:MOLE_DRY_RUN = '0'
    $results = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($item in $selected) {
            try { $result = Remove-SafeItem -Path $item.Path -Description $item.Reason -ExpectedSnapshot $item.Snapshot }
            catch { $result = [pscustomobject]@{ Success = $false; BytesRemoved = 0; Error = $_.Exception.Message } }
            $results.Add([pscustomobject]@{
                ItemId = $item.Id
                Group = $item.Group
                Path = $item.Path
                Success = [bool]$result.Success
                BytesRemoved = [long]$result.BytesRemoved
                Error = $result.Error
            })
        }
    }
    finally {
        Set-DryRunMode -Enabled $oldDryRun
        if ($null -eq $oldEnvironment) { Remove-Item Env:\MOLE_DRY_RUN -ErrorAction SilentlyContinue }
        else { $env:MOLE_DRY_RUN = $oldEnvironment }
    }
    $driveDelta = foreach ($drive in $driveBefore.Keys) {
        try {
            $after = [long](New-Object IO.DriveInfo($drive)).AvailableFreeSpace
            [pscustomobject]@{ Drive = $drive; BeforeBytes = $driveBefore[$drive]; AfterBytes = $after; DeltaBytes = ($after - $driveBefore[$drive]) }
        }
        catch { [pscustomobject]@{ Drive = $drive; BeforeBytes = $driveBefore[$drive]; AfterBytes = $null; DeltaBytes = $null } }
    }
    $logicalBytesRemoved = 0L
    if ($results.Count -gt 0) { $logicalBytesRemoved = [long](($results | Measure-Object -Property BytesRemoved -Sum).Sum) }
    [pscustomobject]@{
        PlanId = $PlanId
        State = 'Consumed'
        Results = $results.ToArray()
        SucceededCount = @($results | Where-Object Success).Count
        FailedCount = @($results | Where-Object { -not $_.Success }).Count
        LogicalBytesRemoved = $logicalBytesRemoved
        ObservedDriveSpace = @($driveDelta)
    }
}
