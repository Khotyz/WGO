# Wgo.Amd.psm1 - AMD Radeon stability fixes (ULPS, MPO, TDR, Crash Defender, HDCP, telemetry, HW accel)
# Paths are inlined per-function (not $script: vars) since function bodies are
# copied verbatim into the background runspace, which does not carry this
# module's own script-scope state with them.

function Get-WgoAmdUlpsEntries {
    Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -Recurse -ErrorAction SilentlyContinue |
        Get-ItemProperty -Name "EnableUlps" -ErrorAction SilentlyContinue
}

function Set-WgoAmdUlps {
    try {
        $entries = Get-WgoAmdUlpsEntries
        if (-not $entries) { Write-Log (T 'LogAmdUlpsUnavailable') "WARN"; return $false }
        foreach ($entry in $entries) {
            Set-ItemProperty -Path $entry.PSPath -Name "EnableUlps" -Value 0 -ErrorAction Stop
            if (Get-ItemProperty -Path $entry.PSPath -Name "EnableUlps_NA" -ErrorAction SilentlyContinue) {
                Set-ItemProperty -Path $entry.PSPath -Name "EnableUlps_NA" -Value 0 -ErrorAction Stop
            }
        }
        Write-Log (T 'LogAmdUlpsOk') "OK"
        return $true
    } catch { Write-Log (T 'LogMoreError' "AmdUlps" $_.Exception.Message) "ERROR"; return $false }
}

function Set-WgoAmdMpo {
    try {
        # OverlayTestMode is a DWM debug/test switch, not a supported way to
        # disable Multi-Plane Overlay. Forcing it to 5 is a known cause of
        # random gray screens (apps needing a minimize/restore to redraw),
        # so this reverts it instead of setting it.
        $dwmPath = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
        if (Test-Path $dwmPath) {
            Remove-ItemProperty -Path $dwmPath -Name "OverlayTestMode" -Force -ErrorAction SilentlyContinue
        }
        Write-Log (T 'LogAmdMpoOk') "OK"
        return $true
    } catch { Write-Log (T 'LogMoreError' "AmdMpo" $_.Exception.Message) "ERROR"; return $false }
}

function Set-WgoAmdTdr {
    try {
        $gfxPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (-not (Test-Path $gfxPath)) { New-Item -Path $gfxPath -Force | Out-Null }
        Set-ItemProperty -Path $gfxPath -Name "TdrDelay" -Value 10 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $gfxPath -Name "TdrDdiDelay" -Value 10 -Type DWord -Force -ErrorAction Stop
        Write-Log (T 'LogAmdTdrOk') "OK"
        return $true
    } catch { Write-Log (T 'LogMoreError' "AmdTdr" $_.Exception.Message) "ERROR"; return $false }
}

function Get-WgoAmdCrashDefenderService {
    Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -match 'Crash\s*Defender' -or $_.Name -match 'Crash\s*Defender'
    } | Select-Object -First 1
}

function Set-WgoAmdCrashDefender {
    try {
        $svc = Get-WgoAmdCrashDefenderService
        if (-not $svc) { Write-Log (T 'LogAmdCrashDefenderUnavailable') "WARN"; return $false }
        $svcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$($svc.Name)"
        if ($svc.Status -eq 'Running') { Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue }
        Set-ItemProperty -Path $svcPath -Name "Start" -Value 4 -Type DWord -Force -ErrorAction Stop
        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Log (T 'LogAmdCrashDefenderOk') "OK"
        return $true
    } catch { Write-Log (T 'LogMoreError' "AmdCrashDefender" $_.Exception.Message) "ERROR"; return $false }
}

function Get-WgoAmdDriverSubkeys {
    Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -match '^\d{4}$' } |
        Where-Object {
            $desc = (Get-ItemProperty -Path $_.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue).DriverDesc
            $desc -match "AMD|Radeon"
        }
}

function Set-WgoAmdHdcp {
    try {
        $subkeys = Get-WgoAmdDriverSubkeys
        if (-not $subkeys) { Write-Log (T 'LogAmdHdcpUnavailable') "WARN"; return $false }
        foreach ($key in $subkeys) {
            Set-ItemProperty -Path $key.PSPath -Name "DAL2_DisableHDCP" -Value 1 -Type DWord -Force -ErrorAction Stop
        }
        Write-Log (T 'LogAmdHdcpOk') "OK"
        return $true
    } catch { Write-Log (T 'LogMoreError' "AmdHdcp" $_.Exception.Message) "ERROR"; return $false }
}

function Get-WgoAmdTelemetryServices {
    Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -match 'AMD External Events' -or $_.DisplayName -match 'AMD User Experience' -or
        $_.Name -match 'AMD.*External.*Events' -or $_.Name -match 'AMD.*User.*Experience'
    }
}

function Set-WgoAmdTelemetry {
    try {
        $services = Get-WgoAmdTelemetryServices
        if (-not $services) { Write-Log (T 'LogAmdTelemetryUnavailable') "WARN"; return $false }
        foreach ($svc in $services) {
            $svcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$($svc.Name)"
            if ($svc.Status -eq 'Running') { Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue }
            Set-ItemProperty -Path $svcPath -Name "Start" -Value 4 -Type DWord -Force -ErrorAction Stop
            Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        }
        Write-Log (T 'LogAmdTelemetryOk') "OK"
        return $true
    } catch { Write-Log (T 'LogMoreError' "AmdTelemetry" $_.Exception.Message) "ERROR"; return $false }
}

function Set-WgoAmdHwAccel {
    try {
        $dwmPath = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
        $gfxPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        $chromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
        $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

        # OverlayTestMode is a DWM debug/test switch and forcing it to 5 is a
        # known cause of random gray screens, so it's reverted here instead
        # of being set.
        if (Test-Path $dwmPath) {
            Remove-ItemProperty -Path $dwmPath -Name "OverlayTestMode" -Force -ErrorAction SilentlyContinue
        }

        if (-not (Test-Path $gfxPath)) { New-Item -Path $gfxPath -Force | Out-Null }
        Set-ItemProperty -Path $gfxPath -Name "HwSchMode" -Value 1 -Type DWord -Force -ErrorAction Stop

        if (-not (Test-Path $chromePolicyPath)) { New-Item -Path $chromePolicyPath -Force | Out-Null }
        Set-ItemProperty -Path $chromePolicyPath -Name "UseAngle" -Value "opengl" -Type String -Force -ErrorAction Stop

        if (-not (Test-Path $edgePolicyPath)) { New-Item -Path $edgePolicyPath -Force | Out-Null }
        Set-ItemProperty -Path $edgePolicyPath -Name "UseAngle" -Value "opengl" -Type String -Force -ErrorAction Stop

        Write-Log (T 'LogAmdHwAccelOk') "OK"
        return $true
    } catch { Write-Log (T 'LogMoreError' "AmdHwAccel" $_.Exception.Message) "ERROR"; return $false }
}

Export-ModuleMember -Function @(
    'Set-WgoAmdUlps', 'Set-WgoAmdMpo', 'Set-WgoAmdTdr', 'Set-WgoAmdCrashDefender',
    'Set-WgoAmdHdcp', 'Set-WgoAmdTelemetry', 'Set-WgoAmdHwAccel',
    'Get-WgoAmdUlpsEntries', 'Get-WgoAmdCrashDefenderService', 'Get-WgoAmdDriverSubkeys', 'Get-WgoAmdTelemetryServices'
)
