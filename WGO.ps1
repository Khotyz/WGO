#Requires -Version 5.1
<#
    WGO - Windows General Optimizations
    Modularized entry point with robust error handling.

    Can be run two ways:
      1. Locally: double-click WGO.ps1, or "powershell -File WGO.ps1" from the project folder.
      2. Online:  irm https://raw.githubusercontent.com/Khotyz/WGO/main/WGO.ps1 | iex
         In this mode there is no script file on disk (iex runs the text in memory), so the
         bootstrap block below downloads the full repository to a temp folder and relaunches
         WGO.ps1 from there - this is required because Modules/, xaml/ and lang/ are separate
         files that "irm | iex" alone can never fetch.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$ErrorActionPreference = 'Stop'

# ============================================================================
# ERROR HANDLING HELPER
# ============================================================================
function Show-WgoStartupError {
    param(
        [string]$Message,
        [string]$Detail = ""
    )
    $fullMsg = if ($Detail) { "$Message`n`nDetalhe: $Detail" } else { $Message }
    Write-Host "`n============================================================" -ForegroundColor Red
    Write-Host $fullMsg -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red

    try {
        $logPath = Join-Path $env:TEMP "WGO_ERROR.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "--- $timestamp ---" | Out-File -FilePath $logPath -Append
        $fullMsg | Out-File -FilePath $logPath -Append
        "`n" | Out-File -FilePath $logPath -Append
    } catch { }

    [System.Windows.Forms.MessageBox]::Show(
        $fullMsg,
        "WGO - Erro de Inicialização",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null

    exit 1
}

# ============================================================================
# ONLINE BOOTSTRAP
# When launched via "irm ... | iex" there is no physical script file, so
# $PSCommandPath is empty and the app's Modules/xaml/lang files were never
# downloaded. Detect that case, pull the full repo, and relaunch from disk.
# ============================================================================
$IsRunningFromFile = -not [string]::IsNullOrEmpty($PSCommandPath) -and (Test-Path -LiteralPath $PSCommandPath -ErrorAction SilentlyContinue)

if (-not $IsRunningFromFile) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        $repoZipUrl = "https://github.com/Khotyz/WGO/archive/refs/heads/main.zip"
        $tempRoot   = Join-Path $env:TEMP "WGO_bootstrap"
        $zipPath    = Join-Path $env:TEMP "WGO_bootstrap.zip"

        if (Test-Path $tempRoot) { Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null

        Write-Host "Baixando o WGO..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $repoZipUrl -OutFile $zipPath -UseBasicParsing

        Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        # GitHub's branch zip always extracts into a single "<repo>-<branch>" subfolder
        $extracted = Get-ChildItem -Path $tempRoot -Directory | Select-Object -First 1
        if (-not $extracted) { throw "O download não continha nenhuma pasta extraída." }

        $entryScript = Join-Path $extracted.FullName "WGO.ps1"
        if (-not (Test-Path $entryScript)) {
            throw "Não foi possível localizar WGO.ps1 após o download em '$($extracted.FullName)'."
        }

        # Relaunch from disk: the new process gets a real $PSCommandPath, so both
        # the elevation check and module/xaml loading below work exactly as if
        # the user had downloaded and run the project locally.
        Start-Process powershell.exe -ArgumentList @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$entryScript`""
        ) -Verb RunAs | Out-Null
    } catch {
        Show-WgoStartupError -Message "Falha ao baixar o WGO para execução online." -Detail $_.Exception.Message
    }
    exit
}

# ============================================================================
# ELEVATION
# From this point on we are guaranteed to be running from a real file on disk
# (either the user's local copy, or the bootstrap relaunch above).
# ============================================================================
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName  = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $psi.Verb      = "runas"
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "WGO precisa ser executado como Administrador.",
            "WGO",
            "OK",
            "Warning"
        ) | Out-Null
    }
    exit
}

# ============================================================================
# GLOBAL STATE (must be defined before modules are imported)
# ============================================================================
$Global:WgoLogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$Global:CurrentLangCode = "pt-BR"
$Global:WgoCurrentTheme = "Dark"
$Global:WgoLastRunPath = Join-Path $env:LOCALAPPDATA "WGO\last-run.json"

# Functions shared with background-task runspaces (see Start-WgoBackgroundTask)
$Global:WgoSharedFunctionNames = @(
    'Write-Log', 'T', 'Show-WgoFatalError',
    'New-WgoRestorePoint', 'Remove-WgoBloatware', 'Test-WgoProtectedPackage',
    'Set-WgoLocalSearch', 'Set-WgoVisualEffects', 'Set-WgoPrivacyPolicies',
    'Set-WgoExtraPrivacy', 'Set-WgoAdvancedTweaks', 'Set-WgoBlockDriverUpdates', 'Set-WgoPagefile',
    'Set-WgoMoreOptimizations', 'Restore-WgoDefaults', 'Invoke-WgoStandbyListPurge',
    'Find-WgoChocolatey', 'Update-WgoSessionEnvironment', 'Install-WgoChocolatey',
    'Test-WgoChocolatey', 'Find-WgoWinget', 'Install-ViaWinget',
    'Install-ViaChocolatey', 'Install-WgoApp', 'Start-WgoExternalScriptAsCurrentUser',
    'Set-WgoServiceMgmt', 'Clear-WgoWinSxS', 'Invoke-WgoSystemIntegrity', 'Clear-WgoDNS',
    'Test-WgoAppInstalled', 'Set-WgoExtraTweaks2', 'Set-WgoRiskyTweaks', 'Remove-WgoWindowsBackupApp',
    'Set-WgoCpuTimerTweaks', 'Set-WgoGpuTweaks', 'Set-WgoNetworkAdvanced', 'Set-WgoTimerResolutionNative',
    'Set-WgoXboxServices'
)

# ============================================================================
# MAIN SCRIPT WITH ERROR HANDLING
# ============================================================================
try {
    $scriptRoot = Split-Path -Parent $PSCommandPath
    $Global:WgoRootPath = $scriptRoot

    $moduleRoot = Join-Path $scriptRoot "Modules"
    if (-not (Test-Path $moduleRoot)) {
        throw "Pasta 'Modules' não encontrada em '$moduleRoot'.`nVerifique se o script está no diretório correto ou se os módulos estão presentes."
    }

    # Load order matters: each module may depend on functions from the ones before it
    $modulePaths = @(
        "Wgo.Shared",
        "Wgo.Native",
        "Wgo.Core",
        "Wgo.Services",
        "Wgo.AppInstaller",
        "Wgo.Utilities",
        "Wgo.Profile",
        "Wgo.UI"
    )

    $loadedModules = @()
    foreach ($mod in $modulePaths) {
        $psm1 = Join-Path $moduleRoot "$mod\$mod.psm1"
        if (-not (Test-Path $psm1)) {
            throw "Módulo '$mod' não encontrado.`nEsperado: '$psm1'."
        }
        Import-Module $psm1 -Force -ErrorAction Stop
        $loadedModules += $mod
    }

    Write-Host "Módulos carregados: $($loadedModules -join ', ')" -ForegroundColor Green

    $xamlPath = Join-Path $scriptRoot "xaml\MainWindow.xaml"
    if (-not (Test-Path $xamlPath)) {
        throw "Arquivo XAML não encontrado em '$xamlPath'.`nVerifique se a pasta 'xaml' existe e contém 'MainWindow.xaml'."
    }

    Initialize-WgoUI -XamlPath $xamlPath

} catch {
    Show-WgoStartupError -Message $_.Exception.Message -Detail $_.Exception.InnerException.Message
}