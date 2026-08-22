# Wgo.Utilities.psm1 - External scripts and system utilities

function Start-WgoExternalScript {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Name,
        [ValidateSet('iwr', 'irm')][string]$Downloader = 'irm',
        [string]$RawCommand = $null
    )
    try {
        Write-Log (T 'LogExtScriptStart' $Name) "INFO"
        $cmd = if ($RawCommand) {
            $RawCommand
        } elseif ($Downloader -eq 'iwr') {
            "iwr -useb '$Url' | iex"
        } else {
            "irm '$Url' | iex"
        }
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-Command", $cmd `
            -ErrorAction Stop | Out-Null
        Write-Log (T 'LogExtScriptLaunched' $Name) "OK"
    } catch {
        Write-Log (T 'LogExtScriptError' $Name $_.Exception.Message) "ERROR"
    }
}

function Start-WgoExternalScriptAsCurrentUser {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$Name
    )
    try {
        Write-Log (T 'LogExtScriptStart' $Name) "INFO"
        $taskName = "WGO_Temp_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        $scriptFile = Join-Path $env:TEMP "wgo_run_$taskName.ps1"
        Set-Content -Path $scriptFile -Value $Command -Encoding UTF8 -Force
        $psCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File `"$scriptFile`""
        $outFile = Join-Path $env:TEMP "wgo_schtasks_$taskName.log"
        $createArgString = '/create /tn "' + $taskName + '" /tr "' + $psCommand + '" /sc once /st 00:00 /ru "' + $env:USERNAME + '" /it /rl LIMITED /f'
        $createResult = Start-Process -FilePath "schtasks.exe" -ArgumentList $createArgString -Wait -PassThru `
            -WindowStyle Hidden -RedirectStandardOutput $outFile -RedirectStandardError "$outFile.err" -ErrorAction Stop
        if ($createResult.ExitCode -ne 0) {
            $detail = @(Get-Content $outFile, "$outFile.err" -ErrorAction Ignore) -join ' '
            Write-Log (T 'LogExtScriptError' $Name "schtasks /create exit code $($createResult.ExitCode): $detail") "ERROR"
            Remove-Item $outFile, "$outFile.err", $scriptFile -Force -ErrorAction Ignore
            return
        }
        Remove-Item $outFile, "$outFile.err" -Force -ErrorAction Ignore
        Start-Process -FilePath "schtasks.exe" -ArgumentList @("/run", "/tn", $taskName) -Wait -WindowStyle Hidden -ErrorAction Stop | Out-Null
        Start-Sleep -Seconds 2
        Start-Process -FilePath "schtasks.exe" -ArgumentList @("/delete", "/tn", $taskName, "/f") -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
        Write-Log (T 'LogExtScriptLaunched' $Name) "OK"
    } catch {
        Write-Log (T 'LogExtScriptError' $Name $_.Exception.Message) "ERROR"
    }
}

Export-ModuleMember -Function Start-WgoExternalScript, Start-WgoExternalScriptAsCurrentUser