# Wgo.AppInstaller.psm1 - Application installation via winget, falling back to Scoop

$Global:WgoWingetPath = $null
$Global:WgoScoopPath = $null
$Global:WgoScoopReadyLogged = $false

$Global:WgoAppCatalog = @{
    'firefox'                 = @{ Name = "Mozilla Firefox";        WingetId = "Mozilla.Firefox";                      ScoopId = "firefox" }
    'nanazip'                 = @{ Name = "NanaZip";                 WingetId = "M2Team.NanaZip";                       ScoopId = "nanazip" }
    'notepadplusplus.install' = @{ Name = "Notepad++";                WingetId = "Notepad++.Notepad++";                  ScoopId = "notepadplusplus" }
    'freedownloadmanager'     = @{ Name = "Free Download Manager";    WingetId = "FreeDownloadManager.FreeDownloadManager"; ScoopId = "freedownloadmanager" }
    'qbittorrent'             = @{ Name = "qBittorrent";               WingetId = "qBittorrent.qBittorrent";              ScoopId = "qbittorrent" }
    'steam'                   = @{ Name = "Steam";                     WingetId = "Valve.Steam";                          ScoopId = "steam" }
    'epicgameslauncher'       = @{ Name = "Epic Games Launcher";       WingetId = "EpicGames.EpicGamesLauncher";          ScoopId = "epic-games-launcher" }
    'goggalaxy'               = @{ Name = "GOG Galaxy";                WingetId = "GOG.Galaxy";                           ScoopId = "gog-galaxy" }
    '7zip'                    = @{ Name = "7-Zip";                     WingetId = "7zip.7zip";                            ScoopId = "7zip" }
    'wiztree'                 = @{ Name = "WizTree";                   WingetId = "AntibodySoftware.WizTree";             ScoopId = "wiztree" }
    'memreduct'               = @{ Name = "Mem Reduct";                WingetId = "Henry++.MemReduct";                    ScoopId = "memreduct" }
    'bleachbit'                = @{ Name = "BleachBit";                 WingetId = "BleachBit.BleachBit";                  ScoopId = "bleachbit" }
    'moonlight'               = @{ Name = "Moonlight";                 WingetId = "MoonlightGameStreamingProject.Moonlight"; ScoopId = "moonlight" }
    'sunshine'                = @{ Name = "Sunshine";                  WingetId = "LizardByte.Sunshine";                  ScoopId = "sunshine" }
    'nilesoftshell'           = @{ Name = "Nilesoft Shell";            WingetId = "Nilesoft.Shell";                       ScoopId = "nilesoft-shell" }
    'flowlauncher'            = @{ Name = "Flow Launcher";             WingetId = "Flow-Launcher.Flow-Launcher";          ScoopId = "flow-launcher" }
    'sharex'                  = @{ Name = "ShareX";                    WingetId = "ShareX.ShareX";                        ScoopId = "sharex" }
    'cpuz'                    = @{ Name = "CPU-Z";                     WingetId = "CPUID.CPU-Z";                          ScoopId = "cpu-z" }
    'hwinfo'                  = @{ Name = "HWiNFO";                    WingetId = "REALiX.HWiNFO";                        ScoopId = "hwinfo" }
    'brave'                   = @{ Name = "Brave";                     WingetId = "Brave.Brave";                          ScoopId = "brave" }
    'dnsjumper'               = @{ Name = "DNS Jumper";                WingetId = "";                                     ScoopId = "dnsjumper" }
    'capframex'               = @{ Name = "CapFrameX";                 WingetId = "CXWorld.CapFrameX";                    ScoopId = "capframex" }
    'msiafterburner'          = @{ Name = "MSI Afterburner";           WingetId = "Guru3D.Afterburner";                   ScoopId = "afterburner" }
    'rtss'                    = @{ Name = "RivaTuner Statistics Server"; WingetId = "Guru3D.RTSS";                        ScoopId = "rtss" }
    'dlssswapper'             = @{ Name = "DLSS Swapper";               WingetId = "beeradmoore.dlss-swapper";             ScoopId = "dlss-swapper" }
    'ddu'                     = @{ Name = "Display Driver Uninstaller"; WingetId = "";                                     ScoopId = "ddu" }
    'hwmonitor'               = @{ Name = "HWMonitor";                 WingetId = "CPUID.HWMonitor";                      ScoopId = "hwmonitor" }
}

# ============================================================================
# WINGET
# ============================================================================
function Find-WgoWinget {
    if ($Global:WgoWingetPath -and (Test-Path $Global:WgoWingetPath)) { return $Global:WgoWingetPath }
    try {
        $cmd = Get-Command winget.exe -ErrorAction Ignore
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            $Global:WgoWingetPath = $cmd.Source
            return $Global:WgoWingetPath
        }
    } catch {}
    # winget is an App Execution Alias under the invoking user's profile; an
    # elevated (RunAs) process can end up with a different/stale PATH that
    # doesn't resolve it via Get-Command, so check the known locations too.
    $candidates = @("$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe")
    $wingetPkgRoot = "$env:ProgramFiles\WindowsApps"
    if (Test-Path $wingetPkgRoot) {
        $pkg = Get-ChildItem -Path $wingetPkgRoot -Directory -Filter "Microsoft.DesktopAppInstaller_*" -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending | Select-Object -First 1
        if ($pkg) { $candidates += (Join-Path $pkg.FullName "winget.exe") }
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c -ErrorAction SilentlyContinue)) {
            $Global:WgoWingetPath = $c
            return $Global:WgoWingetPath
        }
    }
    return $null
}

function Install-ViaWinget {
    param([string]$WingetId, [string]$DisplayName)
    if (-not $WingetId) { return $false }
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
# SCOOP (fallback source: community-maintained manifests, no ghost registrations)
# ============================================================================
function Find-WgoScoop {
    if ($Global:WgoScoopPath -and (Test-Path $Global:WgoScoopPath) -and (Test-WgoScoopCore $Global:WgoScoopPath)) {
        return $Global:WgoScoopPath
    }
    try {
        $cmd = Get-Command scoop.cmd -ErrorAction Ignore
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source) -and (Test-WgoScoopCore $cmd.Source)) {
            $Global:WgoScoopPath = $cmd.Source
            return $Global:WgoScoopPath
        }
    } catch {}
    $candidates = @()
    if ($env:SCOOP) { $candidates += (Join-Path $env:SCOOP "shims\scoop.cmd") }
    $candidates += "$env:USERPROFILE\scoop\shims\scoop.cmd"
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c) -and (Test-WgoScoopCore $c)) {
            $Global:WgoScoopPath = $c
            return $Global:WgoScoopPath
        }
    }
    return $null
}

function Test-WgoScoopCore {
    param([string]$ScoopCmdPath)
    try {
        $shimsDir = Split-Path $ScoopCmdPath -Parent
        $scoopRoot = Split-Path $shimsDir -Parent
        return (Test-Path (Join-Path $scoopRoot "apps\scoop\current\bin\scoop.ps1"))
    } catch { return $false }
}

function Install-WgoScoop {
    $existing = Find-WgoScoop
    if ($existing) {
        if (-not $Global:WgoScoopReadyLogged) {
            Write-Log (T 'LogScoopInstallOk') "OK"
            $Global:WgoScoopReadyLogged = $true
        }
        try { & $existing bucket add extras 2>$null 6>$null | Out-Null } catch {}
        return $existing
    }
    Write-Log (T 'LogScoopInstalling') "INFO"
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        # get.scoop.sh aborts outright if $env:USERPROFILE\scoop already exists,
        # even if that install is broken/incomplete, so a leftover directory
        # from a previous failed attempt has to be cleared out first.
        $scoopRoot = "$env:USERPROFILE\scoop"
        if ((Test-Path $scoopRoot) -and -not (Test-Path "$scoopRoot\apps\scoop\current\bin\scoop.ps1")) {
            Remove-Item -Path $scoopRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        # Scoop's own installer refuses to run under an elevated session unless
        # -RunAsAdmin is explicitly passed, and WGO always runs as Administrator.
        # It's launched in a separate powershell.exe process (with its own real
        # console) because its Write-Host calls read $Host.UI.RawUI.ForegroundColor,
        # which is null/unsupported when WGO runs as a console-less WPF process.
        $installScript = (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        $tempScript = "$env:TEMP\wgo_scoop_install.ps1"
        Set-Content -Path $tempScript -Value $installScript -Encoding UTF8 -Force
        $logFile = "$env:TEMP\wgo_scoop_install.log"
        $proc = Start-Process -FilePath "powershell.exe" `
                    -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $tempScript, "-RunAsAdmin") `
                    -NoNewWindow -Wait -PassThru `
                    -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.err" -ErrorAction Stop
        Remove-Item $tempScript -ErrorAction Ignore
        Update-WgoSessionEnvironment
        $Global:WgoScoopPath = $null
        $resolved = Find-WgoScoop
        if ($resolved) {
            try { & $resolved bucket add extras 2>$null 6>$null | Out-Null } catch {}
            Write-Log (T 'LogScoopInstallOk') "OK"
            $Global:WgoScoopReadyLogged = $true
            return $resolved
        }
        $lastLine = (Get-Content -Path $logFile -Tail 1 -ErrorAction SilentlyContinue) -join ' '
        if ($lastLine) {
            Write-Log "$(T 'LogScoopInstallFailed'): $lastLine" "ERROR"
        } else {
            Write-Log (T 'LogScoopInstallFailed') "ERROR"
        }
        return $null
    } catch {
        Write-Log "$(T 'LogScoopInstallFailed'): $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Update-WgoSessionEnvironment {
    try {
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = @($machinePath, $userPath) -join ";"
    } catch {}
}

function Update-WgoScoopStatus {
    $found = [bool](Find-WgoScoop)
    $text = if ($found) { T 'ScoopStatusFound' } else { T 'ScoopStatusNotFound' }
    $window = $Global:WgoUI_Window
    $ctrl = $Global:WgoUI_Ctrl
    if ($window -and $window.Dispatcher -and -not $window.Dispatcher.CheckAccess()) {
        $window.Dispatcher.Invoke([action]{ $ctrl['txtScoopStatus'].Text = $text })
    } else {
        if ($ctrl -and $ctrl['txtScoopStatus']) { $ctrl['txtScoopStatus'].Text = $text }
    }
}

function Install-ViaScoop {
    param([string]$ScoopId, [string]$DisplayName)
    if (-not $ScoopId) { return $false }
    $scoopExe = Install-WgoScoop
    if (-not $scoopExe) {
        Write-Log (T 'LogScoopNotFound' $DisplayName) "WARN"
        return $false
    }
    try {
        $listOutput = & $scoopExe list $ScoopId 2>$null 6>$null
        if ($listOutput -and ($listOutput -join "`n") -match [regex]::Escape($ScoopId)) {
            Write-Log (T 'LogInstallAlready' $DisplayName) "OK"
            return $true
        }
        Write-Log (T 'LogTryingScoop' $DisplayName) "INFO"
        & $scoopExe install $ScoopId 2>$null 6>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log (T 'LogInstallOk' $DisplayName) "OK"
            return $true
        }
        Write-Log (T 'LogInstallError' $DisplayName 'scoop install failed') "ERROR"
        return $false
    } catch {
        Write-Log (T 'LogInstallError' $DisplayName $_.Exception.Message) "ERROR"
        return $false
    }
}

# ============================================================================
# DESKTOP SHORTCUTS
# Some manifests (portable-style tools) don't register a desktop shortcut.
# ============================================================================
function New-WgoDesktopShortcut {
    param([string]$TargetExe, [string]$ShortcutName)
    try {
        if (-not (Test-Path $TargetExe)) { return $false }
        $desktop = [Environment]::GetFolderPath('Desktop')
        $lnkPath = Join-Path $desktop "$ShortcutName.lnk"
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($lnkPath)
        $shortcut.TargetPath = $TargetExe
        $shortcut.WorkingDirectory = Split-Path $TargetExe -Parent
        $shortcut.Save()
        return $true
    } catch { return $false }
}

function New-WgoScoopAppShortcut {
    param([string]$ScoopId, [string]$DisplayName)
    try {
        $shimBase = "$env:USERPROFILE\scoop\shims\$ScoopId"
        $targetExe = $null
        foreach ($ext in @(".exe", ".cmd", ".bat")) {
            if (Test-Path "$shimBase$ext") { $targetExe = "$shimBase$ext"; break }
        }
        if (-not $targetExe) {
            $appCurrent = "$env:USERPROFILE\scoop\apps\$ScoopId\current"
            if (Test-Path $appCurrent) {
                $exe = Get-ChildItem -Path $appCurrent -Filter "*.exe" -File -Recurse -ErrorAction SilentlyContinue |
                    Sort-Object { $_.Name -notmatch [regex]::Escape($ScoopId) } , Length -Descending |
                    Select-Object -First 1
                if ($exe) { $targetExe = $exe.FullName }
            }
        }
        if (-not $targetExe) { return }
        if (New-WgoDesktopShortcut -TargetExe $targetExe -ShortcutName $DisplayName) {
            Write-Log (T 'LogShortcutCreated' $DisplayName) "OK"
        }
    } catch {}
}

# ============================================================================
# MAIN ORCHESTRATOR: winget -> Scoop
# ============================================================================
function Install-WgoApp {
    param([string]$Key, [string]$DisplayName)
    $entry = $Global:WgoAppCatalog[$Key]
    if (-not $entry) {
        Write-Log (T 'LogInstallError' $DisplayName "unknown app key: $Key") "ERROR"
        return
    }
    if ($entry.WingetId) {
        Write-Log (T 'LogInstallStart' $DisplayName $entry.WingetId) "INFO"
    } else {
        Write-Log (T 'LogInstallStartScoopOnly' $DisplayName) "INFO"
    }

    if (Install-ViaWinget -WingetId $entry.WingetId -DisplayName $DisplayName) { return }
    if (Install-ViaScoop -ScoopId $entry.ScoopId -DisplayName $DisplayName) {
        New-WgoScoopAppShortcut -ScoopId $entry.ScoopId -DisplayName $DisplayName
        if ($Key -eq 'msiafterburner') { Install-WgoApp -Key 'rtss' -DisplayName $Global:WgoAppCatalog['rtss'].Name }
        return
    }
    Write-Log (T 'LogInstallError' $DisplayName 'no source available') "ERROR"
}

Export-ModuleMember -Function @(
    'Find-WgoWinget', 'Install-ViaWinget',
    'Find-WgoScoop', 'Test-WgoScoopCore', 'Install-WgoScoop', 'Update-WgoSessionEnvironment', 'Update-WgoScoopStatus', 'Install-ViaScoop',
    'Install-WgoApp', 'New-WgoDesktopShortcut', 'New-WgoScoopAppShortcut'
)
