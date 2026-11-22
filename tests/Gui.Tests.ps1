Describe 'Moleo desktop GUI foundation' {
    It 'loads the WPF shell and validates Status and Analyze backend contracts' {
        $gui = Join-Path (Split-Path -Parent $PSScriptRoot) 'gui.ps1'
        $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $output = & $windowsPowerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $gui -Validate 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) { throw "GUI validation failed: $($output -join "`n")" }
        $result = ($output -join "`n") | ConvertFrom-Json
        if (-not $result.XamlLoaded -or -not $result.NavigationWorks -or -not $result.CleanSelectionWorks -or -not $result.CleanConfirmationRequired -or -not $result.CleanHandlersReady -or -not $result.AppsControlsReady -or -not $result.AppsSelectionWorks -or -not $result.OptimizeControlsReady -or -not $result.OptimizeSelectionWorks -or -not $result.OptimizeBackendConnected -or -not $result.StatusJsonParsing -or -not $result.StatusUnavailableHandling -or -not $result.AnalyzeJsonParsing -or -not $result.BackendProcessStops -or -not ($result.StatusBackendMissingHandled -or ($result.StatusBackendAvailable -and $result.StatusBackendConnected -and $result.StatusTimerCallbackWorks -and $result.WindowCloseStopsBackend)) -or -not ($result.AnalyzeBackendMissingHandled -or ($result.AnalyzeBackendAvailable -and $result.AnalyzeTimerCallbackWorks -and $result.AnalyzeFixtureScanned -and $result.AnalyzeTreemapRendered)) -or -not $result.AnalyzeControlsReady) { throw 'GUI validation returned incomplete navigation, Apps/Optimize, backend, timer, lifecycle, page selection, confirmation, treemap, or Clean checks.' }
    }
}
