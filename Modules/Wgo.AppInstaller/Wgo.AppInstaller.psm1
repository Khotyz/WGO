# Wgo.AppInstaller.psm1 - Application installation via winget, falling back to Scoop

$Global:WgoWingetPath = $null
$Global:WgoScoopPath = $null
$Global:WgoScoopReadyLogged = $false

$Global:WgoAppCatalog = @{
    'firefox'                 = @{ Name = "Mozilla Firefox";        WingetId = "Mozilla.Firefox";                      ScoopId = "firefox"; Bucket = "extras" }
    'nanazip'                 = @{ Name = "NanaZip";                 WingetId = "M2Team.NanaZip";                       ScoopId = "nanazip"; Bucket = "main" }
    'notepadplusplus.install' = @{ Name = "Notepad++";                WingetId = "Notepad++.Notepad++";                  ScoopId = "notepadplusplus"; Bucket = "extras" }
    'freedownloadmanager'     = @{ Name = "Free Download Manager";    WingetId = "FreeDownloadManager.FreeDownloadManager"; ScoopId = "freedownloadmanager"; Bucket = "extras" }
    'qbittorrent'             = @{ Name = "qBittorrent";               WingetId = "qBittorrent.qBittorrent";              ScoopId = "qbittorrent"; Bucket = "extras" }
    'steam'                   = @{ Name = "Steam";                     WingetId = "Valve.Steam";                          ScoopId = "steam"; Bucket = "games" }
    'epicgameslauncher'       = @{ Name = "Epic Games Launcher";       WingetId = "EpicGames.EpicGamesLauncher";          ScoopId = "epic-games-launcher"; Bucket = "games" }
    'goggalaxy'               = @{ Name = "GOG Galaxy";                WingetId = "GOG.Galaxy";                           ScoopId = "goggalaxy"; Bucket = "games" }
    '7zip'                    = @{ Name = "7-Zip";                     WingetId = "7zip.7zip";                            ScoopId = "7zip"; Bucket = "main" }
    'wiztree'                 = @{ Name = "WizTree";                   WingetId = "AntibodySoftware.WizTree";             ScoopId = "wiztree"; Bucket = "extras" }
    'memreduct'               = @{ Name = "Mem Reduct";                WingetId = "Henry++.MemReduct";                    ScoopId = "memreduct"; Bucket = "extras" }
    'bleachbit'                = @{ Name = "BleachBit";                 WingetId = "BleachBit.BleachBit";                  ScoopId = "bleachbit"; Bucket = "extras" }
    'moonlight'               = @{ Name = "Moonlight";                 WingetId = "MoonlightGameStreamingProject.Moonlight"; ScoopId = "moonlight"; Bucket = "extras" }
    'sunshine'                = @{ Name = "Sunshine";                  WingetId = "LizardByte.Sunshine";                  ScoopId = "sunshine"; Bucket = "extras" }
    'nilesoftshell'           = @{ Name = "Nilesoft Shell";            WingetId = "Nilesoft.Shell";                       ScoopId = "nilesoft-shell"; Bucket = "extras" }
    'flowlauncher'            = @{ Name = "Flow Launcher";             WingetId = "Flow-Launcher.Flow-Launcher";          ScoopId = "flow-launcher"; Bucket = "extras" }
    'sharex'                  = @{ Name = "ShareX";                    WingetId = "ShareX.ShareX";                        ScoopId = "sharex"; Bucket = "extras" }
    'cpuz'                    = @{ Name = "CPU-Z";                     WingetId = "CPUID.CPU-Z";                          ScoopId = "cpu-z"; Bucket = "extras" }
    'hwinfo'                  = @{ Name = "HWiNFO";                    WingetId = "REALiX.HWiNFO";                        ScoopId = "hwinfo"; Bucket = "extras" }
    'brave'                   = @{ Name = "Brave";                     WingetId = "Brave.Brave";                          ScoopId = "brave"; Bucket = "extras" }
    'dnsjumper'               = @{ Name = "DNS Jumper";                WingetId = "";                                     ScoopId = "dnsjumper"; Bucket = "extras" }
    'capframex'               = @{ Name = "CapFrameX";                 WingetId = "CXWorld.CapFrameX";                    ScoopId = "capframex"; Bucket = "extras" }
    'msiafterburner'          = @{ Name = "MSI Afterburner";           WingetId = "Guru3D.Afterburner";                   ScoopId = "msiafterburner"; Bucket = "extras" }
    'rtss'                    = @{ Name = "RivaTuner Statistics Server"; WingetId = "Guru3D.RTSS";                        ScoopId = "rtss"; Bucket = "extras" }
    'dlssswapper'             = @{ Name = "DLSS Swapper";               WingetId = "beeradmoore.dlss-swapper";             ScoopId = "dlss-swapper"; Bucket = "games" }
    'ddu'                     = @{ Name = "Display Driver Uninstaller"; WingetId = "";                                     ScoopId = "ddu"; Bucket = "extras" }
    'hwmonitor'               = @{ Name = "HWMonitor";                 WingetId = "CPUID.HWMonitor";                      ScoopId = "hwmonitor"; Bucket = "extras" }
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

function Test-WgoWingetInstalled {
    param([string]$WingetId)
    $wingetExe = Find-WgoWinget
    if (-not $wingetExe -or -not $WingetId) { return $false }
    try {
        $out = & $wingetExe list --id $WingetId -e --accept-source-agreements --disable-interactivity 2>$null
        return ($LASTEXITCODE -eq 0 -and ($out -join "`n") -match [regex]::Escape($WingetId))
    } catch { return $false }
}

function Invoke-WgoProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$LogFile,
        [int]$TimeoutSec = 900
    )
    $errFile = "$LogFile.err"
    Remove-Item -Path $LogFile, $errFile -Force -ErrorAction Ignore
    $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -NoNewWindow -PassThru `
                -RedirectStandardOutput $LogFile -RedirectStandardError $errFile -ErrorAction Stop
    $null = $proc.Handle
    if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
        try { & taskkill.exe /PID $proc.Id /T /F 2>&1 | Out-Null } catch { }
        return [pscustomobject]@{ ExitCode = -1; TimedOut = $true }
    }
    $proc.WaitForExit()
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; TimedOut = $false }
}

function Get-WgoLastLogLine {
    param([string]$LogFile)
    foreach ($f in @($LogFile, "$LogFile.err")) {
        if (-not (Test-Path -LiteralPath $f)) { continue }
        $lines = @(Get-Content -LiteralPath $f -Tail 8 -ErrorAction Ignore | Where-Object { $_ -and $_.Trim() })
        $errLine = $lines | Where-Object { $_ -match 'ERROR|error|Couldn|failed|Failed|abort' } | Select-Object -Last 1
        if ($errLine) { return ([string]$errLine).Trim() }
        if ($lines.Count -gt 0 -and $f -eq "$LogFile.err") { return ([string]$lines[-1]).Trim() }
    }
    return ''
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
        if (Test-WgoWingetInstalled -WingetId $WingetId) {
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
        $run = Invoke-WgoProcess -FilePath $wingetExe -ArgumentList $installArgs -LogFile $logFile -TimeoutSec 1200
        if ($run.TimedOut) {
            Write-Log (T 'LogInstallTimeout' $DisplayName) "WARN"
            return $false
        }
        if ($run.ExitCode -eq 0 -or (Test-WgoWingetInstalled -WingetId $WingetId)) {
            Write-Log (T 'LogInstallOk' $DisplayName) "OK"
            return $true
        }
        Write-Log (T 'LogWingetFailedFallback' $DisplayName $run.ExitCode) "WARN"
        return $false
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

function Get-WgoScoopRoot {
    param([string]$ScoopExe)
    if ($ScoopExe) {
        try { return (Split-Path (Split-Path $ScoopExe -Parent) -Parent) } catch { }
    }
    if ($env:SCOOP) { return $env:SCOOP }
    return "$env:USERPROFILE\scoop"
}

function Test-WgoScoopBucket {
    param([string]$Root, [string]$Name)
    return (Test-Path -LiteralPath (Join-Path $Root "buckets\$Name\bucket"))
}

function Initialize-WgoScoopBucket {
    param([Parameter(Mandatory = $true)][string]$ScoopExe, [Parameter(Mandatory = $true)][string]$Name)
    $root = Get-WgoScoopRoot $ScoopExe
    if (Test-WgoScoopBucket -Root $root -Name $Name) { return $true }
    if ($Name -eq 'main') { return $false }

    $gitShim = Join-Path $root "shims\git.exe"
    if (-not (Get-Command git.exe -ErrorAction Ignore) -and -not (Test-Path -LiteralPath $gitShim)) {
        Write-Log (T 'LogScoopGitInstalling') "INFO"
        try {
            $gitRun = Invoke-WgoProcess -FilePath $ScoopExe -ArgumentList @('install', 'main/git') -LogFile "$env:TEMP\wgo_scoop_git.log" -TimeoutSec 900
            if ($gitRun.TimedOut) { Write-Log (T 'LogInstallTimeout' 'Git') "WARN" }
        } catch {
            Write-Log (T 'LogInstallError' 'Git' $_.Exception.Message) "WARN"
        }
    }
    $shimDir = Join-Path $root "shims"
    if (($env:Path -split ';') -notcontains $shimDir) { $env:Path = "$shimDir;$env:Path" }

    Write-Log (T 'LogScoopBucketAdding' $Name) "INFO"
    try {
        $null = Invoke-WgoProcess -FilePath $ScoopExe -ArgumentList @('bucket', 'add', $Name) -LogFile "$env:TEMP\wgo_scoop_bucket_$Name.log" -TimeoutSec 300
    } catch { }
    if (Test-WgoScoopBucket -Root $root -Name $Name) { return $true }

    $repoNames = @{ extras = 'Extras'; games = 'Games'; versions = 'Versions'; nonportable = 'Nonportable' }
    if (-not $repoNames.ContainsKey($Name)) { return $false }
    Write-Log (T 'LogScoopBucketZip' $Name) "WARN"
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        $zipPath = Join-Path $env:TEMP "wgo_bucket_$Name.zip"
        $tmpDir = Join-Path $env:TEMP "wgo_bucket_$Name"
        Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction Ignore
        Invoke-WebRequest -Uri "https://github.com/ScoopInstaller/$($repoNames[$Name])/archive/refs/heads/master.zip" -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force -ErrorAction Stop
        $inner = Get-ChildItem -Path $tmpDir -Directory | Select-Object -First 1
        $target = Join-Path $root "buckets\$Name"
        Remove-Item -Path $target -Recurse -Force -ErrorAction Ignore
        New-Item -Path (Split-Path $target -Parent) -ItemType Directory -Force | Out-Null
        Move-Item -Path $inner.FullName -Destination $target -Force -ErrorAction Stop
        Remove-Item -Path $zipPath, $tmpDir -Recurse -Force -ErrorAction Ignore
    } catch {
        Write-Log (T 'LogScoopBucketFailed' $Name $_.Exception.Message) "ERROR"
    }
    return (Test-WgoScoopBucket -Root $root -Name $Name)
}

function Install-ViaScoop {
    param([string]$ScoopId, [string]$DisplayName, [string]$Bucket = 'extras')
    if (-not $ScoopId) { return $false }
    $scoopExe = Install-WgoScoop
    if (-not $scoopExe) {
        Write-Log (T 'LogScoopNotFound' $DisplayName) "WARN"
        return $false
    }
    $root = Get-WgoScoopRoot $scoopExe
    $appDir = Join-Path $root "apps\$ScoopId\current"
    try {
        if (Test-Path -LiteralPath $appDir) {
            Write-Log (T 'LogInstallAlready' $DisplayName) "OK"
            return $true
        }
        if (-not (Initialize-WgoScoopBucket -ScoopExe $scoopExe -Name $Bucket)) {
            Write-Log (T 'LogScoopBucketUnavailable' $Bucket $DisplayName) "ERROR"
            return $false
        }
        Write-Log (T 'LogTryingScoop' $DisplayName) "INFO"
        $logFile = "$env:TEMP\wgo_scoop_$($ScoopId -replace '[^\w\.-]','_').log"
        $run = Invoke-WgoProcess -FilePath $scoopExe -ArgumentList @('install', "$Bucket/$ScoopId") -LogFile $logFile -TimeoutSec 1200
        if ($run.TimedOut) {
            Write-Log (T 'LogInstallTimeout' $DisplayName) "ERROR"
            return $false
        }
        if (Test-Path -LiteralPath $appDir) {
            Write-Log (T 'LogInstallOk' $DisplayName) "OK"
            return $true
        }
        $detail = Get-WgoLastLogLine -LogFile $logFile
        if (-not $detail) { $detail = "scoop exit code $($run.ExitCode)" }
        Write-Log (T 'LogInstallError' $DisplayName $detail) "ERROR"
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
        $scoopRoot = Get-WgoScoopRoot (Find-WgoScoop)
        $shimBase = "$scoopRoot\shims\$ScoopId"
        $targetExe = $null
        foreach ($ext in @(".exe", ".cmd", ".bat")) {
            if (Test-Path "$shimBase$ext") { $targetExe = "$shimBase$ext"; break }
        }
        if (-not $targetExe) {
            $appCurrent = "$scoopRoot\apps\$ScoopId\current"
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
        return $false
    }
    if ($entry.WingetId) {
        Write-Log (T 'LogInstallStart' $DisplayName $entry.WingetId) "INFO"
    } else {
        Write-Log (T 'LogInstallStartScoopOnly' $DisplayName) "INFO"
    }

    if (Install-ViaWinget -WingetId $entry.WingetId -DisplayName $DisplayName) { return $true }
    if (Install-ViaScoop -ScoopId $entry.ScoopId -DisplayName $DisplayName -Bucket $entry.Bucket) {
        New-WgoScoopAppShortcut -ScoopId $entry.ScoopId -DisplayName $DisplayName
        if ($Key -eq 'msiafterburner') { [void](Install-WgoApp -Key 'rtss' -DisplayName $Global:WgoAppCatalog['rtss'].Name) }
        return $true
    }
    Write-Log (T 'LogInstallError' $DisplayName 'no source available') "ERROR"
    return $false
}

Export-ModuleMember -Function @(
    'Find-WgoWinget', 'Install-ViaWinget', 'Test-WgoWingetInstalled', 'Invoke-WgoProcess', 'Get-WgoLastLogLine',
    'Get-WgoScoopRoot', 'Test-WgoScoopBucket', 'Initialize-WgoScoopBucket',
    'Find-WgoScoop', 'Test-WgoScoopCore', 'Install-WgoScoop', 'Update-WgoSessionEnvironment', 'Update-WgoScoopStatus', 'Install-ViaScoop',
    'Install-WgoApp', 'New-WgoDesktopShortcut', 'New-WgoScoopAppShortcut'
)
