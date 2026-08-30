# Wgo.AppInstaller.psm1 - Application installation via winget and Chocolatey

$Global:WgoChocoPath = $null
$Global:WgoWingetPath = $null

$Global:WgoAppCatalog = @{
    'firefox'                 = @{ Name = "Mozilla Firefox";        WingetId = "Mozilla.Firefox";                      ChocoId = "firefox" }
    'nanazip'                 = @{ Name = "NanaZip";                 WingetId = "M2Team.NanaZip";                       ChocoId = "nanazip" }
    'notepadplusplus.install' = @{ Name = "Notepad++";                WingetId = "Notepad++.Notepad++";                  ChocoId = "notepadplusplus.install" }
    'freedownloadmanager'     = @{ Name = "Free Download Manager";    WingetId = "FreeDownloadManager.FreeDownloadManager"; ChocoId = "freedownloadmanager" }
    'qbittorrent'             = @{ Name = "qBittorrent";               WingetId = "qBittorrent.qBittorrent";              ChocoId = "qbittorrent" }
    'steam'                   = @{ Name = "Steam";                     WingetId = "Valve.Steam";                          ChocoId = "steam" }
    'epicgameslauncher'       = @{ Name = "Epic Games Launcher";       WingetId = "EpicGames.EpicGamesLauncher";          ChocoId = "epicgameslauncher" }
    'goggalaxy'               = @{ Name = "GOG Galaxy";                WingetId = "GOG.Galaxy";                           ChocoId = "goggalaxy" }
    '7zip'                    = @{ Name = "7-Zip";                     WingetId = "7zip.7zip";                            ChocoId = "7zip.install" }
    'wiztree'                 = @{ Name = "WizTree";                   WingetId = "AntibodySoftware.WizTree";             ChocoId = "wiztree" }
    'memreduct'               = @{ Name = "Mem Reduct";                WingetId = "Henry++.MemReduct";                    ChocoId = "memreduct" }
    'bleachbit'                = @{ Name = "BleachBit";                 WingetId = "BleachBit.BleachBit";                  ChocoId = "bleachbit" }
    'moonlight'               = @{ Name = "Moonlight";                 WingetId = "MoonlightGameStreamingProject.Moonlight"; ChocoId = "moonlight-qt" }
    'sunshine'                = @{ Name = "Sunshine";                  WingetId = "LizardByte.Sunshine";                  ChocoId = "sunshine" }
    'nilesoftshell'           = @{ Name = "Nilesoft Shell";            WingetId = "Nilesoft.Shell";                       ChocoId = "nilesoft-shell" }
    'optiscalerclient'        = @{ Name = "Optiscaler Client";         WingetId = "Agustinm28.OptiscalerClient";          ChocoId = "" }
    'flowlauncher'            = @{ Name = "Flow Launcher";             WingetId = "Flow-Launcher.Flow-Launcher";          ChocoId = "flow-launcher" }
    'sharex'                  = @{ Name = "ShareX";                    WingetId = "ShareX.ShareX";                        ChocoId = "sharex" }
    'cpuz'                    = @{ Name = "CPU-Z";                     WingetId = "CPUID.CPU-Z";                          ChocoId = "cpu-z" }
    'hwmonitor'               = @{ Name = "HWMonitor";                 WingetId = "CPUID.HWMonitor";                      ChocoId = "hwmonitor" }
    'brave'                   = @{ Name = "Brave";                     WingetId = "Brave.Brave";                          ChocoId = "brave" }
    'dnsjumper'               = @{ Name = "DNS Jumper";                WingetId = "sordum.DnsJumper";                     ChocoId = "dnsjumper" }
}

function Find-WgoChocolatey {
    if ($Global:WgoChocoPath -and (Test-Path $Global:WgoChocoPath)) { return $Global:WgoChocoPath }
    try {
        $cmd = Get-Command choco.exe -ErrorAction Ignore
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            $Global:WgoChocoPath = $cmd.Source
            return $Global:WgoChocoPath
        }
    } catch {}
    $candidates = @()
    if ($env:ChocolateyInstall) { $candidates += (Join-Path $env:ChocolateyInstall "bin\choco.exe") }
    $candidates += "$env:ProgramData\chocolatey\bin\choco.exe"
    $candidates += "$env:SystemDrive\ProgramData\chocolatey\bin\choco.exe"
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) {
            $Global:WgoChocoPath = $c
            return $Global:WgoChocoPath
        }
    }
    return $null
}

function Update-WgoSessionEnvironment {
    try {
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = @($machinePath, $userPath) -join ";"
        $machineChoco = [System.Environment]::GetEnvironmentVariable("ChocolateyInstall", "Machine")
        if ($machineChoco) { $env:ChocolateyInstall = $machineChoco }
    } catch {}
}

function Install-WgoChocolatey {
    Write-Log (T 'LogChocoSearching') "INFO"
    $existing = Find-WgoChocolatey
    if ($existing) {
        Write-Log (T 'LogChocoFound' $existing) "INFO"
        return $existing
    }
    Write-Log (T 'LogChocoInstalling') "INFO"
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Ignore
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Update-WgoSessionEnvironment
        $Global:WgoChocoPath = $null
        $resolved = Find-WgoChocolatey
        if ($resolved) {
            Write-Log (T 'LogChocoInstallOk') "OK"
            return $resolved
        } else {
            Write-Log (T 'LogChocoInstallFailed' "choco.exe not found after installation") "ERROR"
            Write-Log (T 'LogChocoNotFound') "ERROR"
            return $null
        }
    } catch {
        Write-Log (T 'LogChocoInstallFailed' $_.Exception.Message) "ERROR"
        Write-Log (T 'LogChocoNotFound') "ERROR"
        return $null
    }
}

function Update-WgoChocoStatus {
    $found = [bool](Find-WgoChocolatey)
    $text = if ($found) { T 'ChocoStatusFound' } else { T 'ChocoStatusNotFound' }
    $window = $Global:WgoUI_Window
    $ctrl = $Global:WgoUI_Ctrl
    if ($window -and $window.Dispatcher -and -not $window.Dispatcher.CheckAccess()) {
        $window.Dispatcher.Invoke([action]{ $ctrl['txtChocoStatus'].Text = $text })
    } else {
        if ($ctrl -and $ctrl['txtChocoStatus']) { $ctrl['txtChocoStatus'].Text = $text }
    }
}

function Find-WgoWinget {
    if ($Global:WgoWingetPath -and (Test-Path $Global:WgoWingetPath)) { return $Global:WgoWingetPath }
    try {
        $cmd = Get-Command winget.exe -ErrorAction Ignore
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            $Global:WgoWingetPath = $cmd.Source
            return $Global:WgoWingetPath
        }
    } catch {}
    return $null
}

# ============================================================================
# INSTALL VIA WINGET
# ============================================================================
function Install-ViaWinget {
    param([string]$WingetId, [string]$DisplayName)
    $wingetExe = Find-WgoWinget
    if (-not $wingetExe) {
        Write-Log (T 'LogWingetNotAvailable' $DisplayName) "WARN"
        return $false
    }
    try {
        $checkArgs = @("list", "--id", $WingetId, "-e", "--accept-source-agreements", "--disable-interactivity")
        $checkOutput = & $wingetExe @checkArgs 2>$null
        if ($LASTEXITCODE -eq 0 -and ($checkOutput -join "`n") -match [regex]::Escape($WingetId)) {
            Write-Log (T 'LogInstallAlready' $DisplayName) "OK"
            return $true
        }
        Write-Log (T 'LogTryingWinget' $DisplayName) "INFO"
        $logFile = "$env:TEMP\wgo_winget_$($WingetId -replace '[^\w\.-]','_').log"
        $installArgs = @(
            "install", "--id", $WingetId, "-e",
            "--silent",
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--disable-interactivity"
        )
        $proc = Start-Process -FilePath $wingetExe -ArgumentList $installArgs -NoNewWindow -Wait -PassThru `
                    -RedirectStandardOutput $logFile -ErrorAction Stop
        if ($proc.ExitCode -eq 0) {
            Write-Log (T 'LogInstallOk' $DisplayName) "OK"
            return $true
        } else {
            Write-Log (T 'LogWingetFailedFallback' $DisplayName $proc.ExitCode) "WARN"
            return $false
        }
    } catch {
        Write-Log (T 'LogWingetFailedFallback' $DisplayName $_.Exception.Message) "WARN"
        return $false
    }
}

# ============================================================================
# INSTALL VIA CHOCOLATEY (force reinstall to clear ghost registrations)
# ============================================================================
function Install-ViaChocolatey {
    param([string]$ChocoId, [string]$DisplayName)

    $chocoExe = Find-WgoChocolatey
    if (-not $chocoExe) {
        Write-Log (T 'LogInstallError' $DisplayName 'Chocolatey not found') "ERROR"
        return
    }

    # Check for a stale/ghost registration and force a clean reinstall if needed
    $listArgs = @("list", "--local-only", "--exact", $ChocoId, "-r")
    $listOutput = & $chocoExe @listArgs 2>$null

    $isInstalled = $false
    if ($listOutput -and ($listOutput -is [array])) {
        foreach ($line in $listOutput) {
            if ($line -match "^$([regex]::Escape($ChocoId))\|") {
                $isInstalled = $true
                break
            }
        }
    }

    if ($isInstalled) {
        & $chocoExe uninstall $ChocoId -y --no-progress 2>$null | Out-Null
        Start-Sleep -Seconds 2
    }

    Write-Log (T 'LogTryingChoco' $DisplayName) "INFO"
    $logFile = "$env:TEMP\wgo_choco_$ChocoId.log"
    $errFile = "$env:TEMP\wgo_choco_$ChocoId.err.log"

    $installArgs = @(
        "install", $ChocoId, "-y",
        "--no-progress",
        "--limit-output",
        "--accept-license",
        "--force"
    )

    $proc = Start-Process -FilePath $chocoExe -ArgumentList $installArgs -NoNewWindow -Wait -PassThru `
                -RedirectStandardOutput $logFile -RedirectStandardError $errFile -ErrorAction Stop

    $successCodes = @(0, 1641, 3010)

    if ($successCodes -contains $proc.ExitCode) {
        Write-Log (T 'LogInstallOk' $DisplayName) "OK"
    } else {
        Write-Log (T 'LogInstallWarn' $DisplayName $proc.ExitCode $logFile) "WARN"
        try {
            $tail = Get-Content -Path $logFile -Tail 5 -ErrorAction Ignore
            if ($tail) { Write-Log ("choco: " + ($tail -join " | ")) "WARN" }
        } catch {}
    }
}

# ============================================================================
# MAIN ORCHESTRATOR
# ============================================================================
function Install-WgoApp {
    param([string]$Key, [string]$DisplayName)
    $entry = $Global:WgoAppCatalog[$Key]
    if (-not $entry) {
        Write-Log (T 'LogInstallError' $DisplayName "unknown app key: $Key") "ERROR"
        return
    }
    Write-Log (T 'LogInstallStart' $DisplayName $entry.WingetId) "INFO"

    # Try winget first
    $wingetSuccess = Install-ViaWinget -WingetId $entry.WingetId -DisplayName $DisplayName
    if ($wingetSuccess) {
        return
    }

    # Fall back to Chocolatey if winget failed
    if ($entry.ChocoId -and $entry.ChocoId -ne "") {
        Write-Log (T 'LogWingetNotAvailable' $DisplayName) "WARN"
        Install-ViaChocolatey -ChocoId $entry.ChocoId -DisplayName $DisplayName
    } else {
        Write-Log (T 'LogInstallError' $DisplayName 'no Chocolatey ID defined') "ERROR"
    }
}

Export-ModuleMember -Function @(
    'Find-WgoChocolatey', 'Install-WgoChocolatey', 'Update-WgoSessionEnvironment',
    'Update-WgoChocoStatus', 'Find-WgoWinget', 'Install-ViaWinget',
    'Install-ViaChocolatey', 'Install-WgoApp'
)