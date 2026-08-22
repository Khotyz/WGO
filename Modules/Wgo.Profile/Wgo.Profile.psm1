# Wgo.Profile.psm1 - Profile import/export and last-run state

function Save-WgoLastRunState {
    try {
        $dir = Split-Path $Global:WgoLastRunPath -Parent
        if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        $state = @{ Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") }
        foreach ($n in $Global:WgoUI_OptimizationCheckboxNames) {
            if ($Global:WgoUI_Ctrl[$n]) { $state[$n] = [bool]$Global:WgoUI_Ctrl[$n].IsChecked }
        }
        if ($Global:WgoUI_Ctrl['chkDryRun']) { $state['chkDryRun'] = [bool]$Global:WgoUI_Ctrl['chkDryRun'].IsChecked }
        ($state | ConvertTo-Json) | Set-Content -Path $Global:WgoLastRunPath -Encoding UTF8
    } catch {}
}

function Restore-WgoLastRunState {
    try {
        if (-not (Test-Path $Global:WgoLastRunPath)) {
            Write-Log (T 'LogLastRunNone') "INFO"
            return
        }
        $state = Get-Content -Path $Global:WgoLastRunPath -Raw | ConvertFrom-Json
        foreach ($n in $Global:WgoUI_OptimizationCheckboxNames) {
            if ($Global:WgoUI_Ctrl[$n] -and ($state.PSObject.Properties.Name -contains $n)) {
                $Global:WgoUI_Ctrl[$n].IsChecked = [bool]$state.$n
            }
        }
        if ($Global:WgoUI_Ctrl['chkDryRun'] -and ($state.PSObject.Properties.Name -contains 'chkDryRun')) {
            $Global:WgoUI_Ctrl['chkDryRun'].IsChecked = [bool]$state.chkDryRun
        }
        Write-Log (T 'LogLastRunFound' $state.Timestamp) "INFO"
    } catch {
        Write-Log (T 'LogLastRunNone') "INFO"
    }
}

Export-ModuleMember -Function Save-WgoLastRunState, Restore-WgoLastRunState