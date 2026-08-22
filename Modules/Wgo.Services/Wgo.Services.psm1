# Wgo.Services.psm1 - Service management and system integrity

function Clear-WgoWinSxS {
    Write-Log (T 'LogWinSxSStart') "INFO"
    try {
        $result = & Dism.exe /Online /Cleanup-Image /StartComponentCleanup 2>&1
        $exitCode = $LASTEXITCODE
        $logLine = ($result -join " ").Trim()
        if ($logLine) { Write-Log (T 'LogDISMOutput' $logLine) "INFO" }
        if ($exitCode -eq 0) {
            Write-Log (T 'LogWinSxSOk') "OK"
        } else {
            Write-Log (T 'LogWinSxSError' "DISM returned exit code $exitCode") "ERROR"
        }
    } catch {
        Write-Log (T 'LogWinSxSError' $_.Exception.Message) "ERROR"
    }
}

function Invoke-WgoSystemIntegrity {
    Write-Log (T 'LogSFCStart') "INFO"
    Write-Log (T 'LogDISMStart') "INFO"
    try {
        $dismResult = & Dism.exe /Online /Cleanup-Image /RestoreHealth 2>&1
        $dismExit = $LASTEXITCODE
        $dismLog = ($dismResult -join " ").Trim()
        if ($dismLog) { Write-Log (T 'LogDISMOutput' $dismLog) "INFO" }
        if ($dismExit -eq 0) {
            Write-Log (T 'LogDISMOk') "OK"
        } else {
            Write-Log (T 'LogDISMFailed' $dismExit) "ERROR"
        }
    } catch {
        Write-Log (T 'LogDISMFailed' $_.Exception.Message) "ERROR"
    }
    Write-Log (T 'LogSFCStartScan') "INFO"
    try {
        $sfcResult = & sfc.exe /scannow 2>&1
        $sfcExit = $LASTEXITCODE
        $sfcLog = ($sfcResult -join " ").Trim()
        if ($sfcExit -eq 0) {
            Write-Log (T 'LogSFCOk') "OK"
        } elseif ($sfcExit -eq 1) {
            Write-Log (T 'LogSFCFound' $sfcLog) "OK"
        } else {
            Write-Log (T 'LogSFCError' $sfcExit) "ERROR"
        }
        if ($sfcLog) { Write-Log ("SFC output: $sfcLog") "INFO" }
    } catch {
        Write-Log (T 'LogSFCError' $_.Exception.Message) "ERROR"
    }
}

function Clear-WgoDNS {
    try {
        & ipconfig.exe /flushdns 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log (T 'LogDNSOk') "OK"
        } else {
            Write-Log (T 'LogDNSError' "ipconfig exit code $LASTEXITCODE") "ERROR"
        }
    } catch {
        Write-Log (T 'LogDNSError' $_.Exception.Message) "ERROR"
    }
}

Export-ModuleMember -Function Clear-WgoWinSxS, Invoke-WgoSystemIntegrity, Clear-WgoDNS