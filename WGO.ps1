#Requires -Version 5.1
<#
    WGO - Windows General Optimizations
    GUI (WPF/XAML) tool for optimization, bloatware removal, privacy,
    visual tweaks and utility installation on Windows 10/11.

    Run as Administrator. Some actions (Group Policy / Registry HKLM,
    Checkpoint-Computer, provisioned AppX removal) require elevation.
#>

# ============================================================================
# 0. ELEVATION / PREREQUISITES
# ============================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Non-terminating cmdlet errors (e.g. Access Denied) must actually reach the
# nearest try/catch instead of silently being written to the error stream
# while execution carries on to the next line and logs a false "OK". Any
# call that intentionally wants to fail silently already sets its own
# -ErrorAction Ignore/SilentlyContinue, which still overrides this.
$ErrorActionPreference = 'Stop'

if (-not $isAdmin) {
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"

        if ([string]::IsNullOrEmpty($PSCommandPath)) {
            $scriptUrl = "https://raw.githubusercontent.com/Khotyz/WGO/main/WGO.ps1"
            $encodedCommand = [Convert]::ToBase64String(
                [Text.Encoding]::Unicode.GetBytes("irm '$scriptUrl' | iex")
            )
            $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand"
        } else {
            $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        }

        $psi.Verb = "runas"
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("WGO precisa ser executado como Administrador.", "WGO", "OK", "Warning") | Out-Null
    }
    exit
}

# ============================================================================
# 1. NON-ASCII CHARACTER HELPER (strict use of [char]0xXXXX)
# ============================================================================

function U {
    param([int[]]$Codes)
    -join ($Codes | ForEach-Object { [char]$_ })
}

# pt-BR accented characters
$c_ccedil = [char]0x00E7
$c_atil   = [char]0x00E3
$c_aacute = [char]0x00E1
$c_eacute = [char]0x00E9
$c_ecirc  = [char]0x00EA
$c_iacute = [char]0x00ED
$c_oacute = [char]0x00F3
$c_ocirc  = [char]0x00F4
$c_otil   = [char]0x00F5
$c_uacute = [char]0x00FA
$c_acirc  = [char]0x00E2

# es-ES special characters
$c_enye   = [char]0x00F1
$c_iexcl  = [char]0x00A1
$c_iques  = [char]0x00BF

# ============================================================================
# 2. TRANSLATION DICTIONARIES (en-US / pt-BR / es-ES / zh-CN)
# ============================================================================

$Lang = @{}

$Lang['en-US'] = @{
    AppTitle          = "WGO - Windows General Optimizations"
    TabOptimizations  = "Optimizations & Privacy"
    TabInstaller      = "App Installer"
    LblLanguage       = "Language:"
    GrpRestore        = "System Safety"
    BtnCreateRestore  = "Create Restore Point"
    ChkSelectAll      = "Select All / Deselect All"
    GrpBloat          = "Bloatware & AI Apps Removal"
    ChkBloat          = "Remove bloatware / AI apps (keeps Store, Xbox, Edge/WebView2, runtimes)"
    GrpSearch         = "Start Menu Search"
    ChkSearch         = "Force 100% local search (disable Bing/Edge web search)"
    GrpVisual         = "Visual Effects"
    ChkVisual         = "Apply custom performance visual effects profile"
    GrpPrivacy        = "Deep Privacy / Telemetry"
    ChkPrivacy        = "Block telemetry, WER, CEIP, Activity Feed, Location (Group Policy)"
    GrpDrivers        = "Windows Update Drivers"
    ChkDrivers        = "Block automatic driver installation via Windows Update"
    GrpPagefile       = "Virtual Memory (Pagefile)"
    ChkPagefile       = "Set static pagefile size (RAM x 1.5)"
    BtnRunSelected    = "Run Selected Optimizations"
    GrpInstaller      = "Useful Applications"
    BtnInstallApps    = "Install Selected"

    TabExternalScripts = "External Scripts"
    TxtExtScriptsWarning = "These are independent, third-party open-source scripts (not part of WGO). Each one opens in its own window and requests admin rights on its own. Only run tools from sources you trust."

    TxtAmdOptimizerTitle = "AMD Stability Optimizer"
    TxtAmdOptimizerDesc  = "A dedicated toolkit for AMD Radeon GPUs that targets the most common causes of driver crashes, black screens and stutter. It disables ULPS, Multi-Plane Overlay and HDCP, extends the TDR driver-timeout, turns off Fast Startup/Hibernation and the AMD Crash Defender service, fixes hardware-acceleration flicker in Chrome/Edge/Electron apps (Discord, Spotify), and unlocks Windows' hidden Ultimate Performance power plan. It creates a registry backup and, when possible, a System Restore Point before touching anything, and every change can be reverted from its own interface."
    BtnRunAmdOptimizer   = "Run AMD Stability Optimizer"

    TxtMassgraveTitle = "Windows & Office Activation (MAS)"
    TxtMassgraveDesc  = "Launches the official Microsoft Activation Scripts (MASSGRAVE) project, a well-known open-source community tool for activating Windows and Microsoft Office via HWID, KMS38 or Online KMS. It opens an interactive text menu in a new console window; just follow the on-screen options to pick the activation method you want."
    BtnRunMassgrave   = "Run Activation Script"

    LogExtScriptStart    = "Launching external script: {0}..."
    LogExtScriptLaunched = "{0} launched in a new window. Follow the instructions there."
    LogExtScriptError    = "Error launching {0}: {1}"

    LogHeader         = "Execution Log"
    AppFirefoxDesc    = "Highly recommended browser that does not use the Chromium engine, offering real privacy, more user control and full support for effective ad blockers (like uBlock Origin)."
    AppNanaZipDesc    = "Lightweight, modern archiver natively integrated into the new Windows 11 context menu."
    AppNppDesc        = "Fast, lightweight and essential text editor to replace the default Notepad."
    AppFdmDesc        = "Powerful download manager with HTTP/HTTPS file acceleration."
    AppQbtDesc        = "Open-source BitTorrent client, extremely lightweight, free of ads, bloatware or unwanted bundled software."
    AppSteamDesc      = "Digital game store and launcher by Valve."
    AppEpicDesc       = "Epic Games digital store and launcher."
    AppGogDesc        = "DRM-free digital game store and launcher."
    AppSevenZipDesc   = "Free, open-source file archiver with a very high compression ratio."
    AppWiztreeDesc    = "Extremely fast disk space analyzer, an alternative to WinDirStat."
    AppMemreductDesc  = "Lightweight real-time RAM monitoring and cleaning utility."
    AppBleachbitDesc  = "Free, open-source tool to clean disk clutter and protect privacy."
    AppMoonlightDesc  = "Open-source game streaming client, used to connect to a Sunshine or NVIDIA GameStream host."
    AppSunshineDesc   = "Self-hosted, open-source game stream host for Moonlight, with low-latency GPU-accelerated encoding."
    MsgReady          = "Ready."
    MsgDone           = "Done."

    GrpExtraPrivacy    = "Additional Telemetry Blocking"
    ChkAdvertisingId   = "Disable advertising ID (personalized ads)"
    ChkTailoredExp     = "Disable tailored experiences / Windows suggestions & tips"
    ChkDiagTrackSvc    = "Disable Connected User Experiences and Telemetry service (DiagTrack) and dmwappushservice"
    ChkCopilotBlock    = "Block Copilot, Recall and AI data analysis via policy"
    ChkInputTelemetry  = "Disable typing/handwriting personalization and clipboard cloud sync"

    LogRestoreTry      = "Attempting to create a System Restore Point..."
    LogRestoreOk       = "Restore Point created successfully."
    LogRestoreFail     = "Failed to create Restore Point: {0}"
    LogRestoreHint     = "Check that System Protection is enabled (SystemPropertiesProtection.exe) and that the script is elevated."
    LogBloatStart      = "Starting removal of bloatware / AI apps..."
    LogBloatUserRemoved = "Removed (user): {0}"
    LogBloatProvRemoved = "Removed (provisioned): {0}"
    LogBloatError      = "Error removing {0}: {1}"
    LogBloatDone       = "Bloatware removal finished. Whitelisted items were preserved."
    LogSearchStart     = "Configuring Start Menu search as 100% local..."
    LogSearchOk        = "Local search applied successfully (DisableSearchBoxSuggestions, BingSearchEnabled, CortanaConsent)."
    LogSearchError     = "Error configuring local search: {0}"
    LogVisualStart     = "Applying custom Visual Effects profile..."
    LogVisualOk        = "Visual effects applied: window animations, drag content, thumbnails, translucent selection, smoothed fonts and icon shadows kept enabled; other effects disabled."
    LogVisualError     = "Error applying visual effects: {0}"
    LogPrivacyStart    = "Applying telemetry blocking and deep privacy policies..."
    LogPrivacyOk       = "Telemetry, WER, CEIP, App Compat, Location and Timeline policies applied via HKLM (Group Policy)."
    LogPrivacyError    = "Error applying privacy policies (check administrator elevation): {0}"
    LogExtraStart      = "Applying additional telemetry-blocking options..."
    LogExtraAdvOk      = "Advertising ID disabled."
    LogExtraTailoredOk = "Tailored experiences / Windows suggestions disabled."
    LogExtraDiagTrackOk = "DiagTrack and dmwappushservice services stopped and disabled."
    LogExtraCopilotOk  = "Copilot, Recall and AI data analysis blocked via policy."
    LogExtraInputOk    = "Typing personalization and clipboard cloud sync disabled."
    LogExtraError      = "Error applying additional telemetry option ({0}): {1}"
    LogExtraDone       = "Additional telemetry-blocking options finished."

    GrpAdvancedTweaks   = "Advanced System Tweaks"
    ChkDiagTrackFull    = "Disable Telemetry (DiagTrack service + registry policy)"
    ChkEdgeWidgets      = "Disable Edge preload and Widgets"
    ChkDeliveryOpt      = "Disable Delivery Optimization (P2P)"
    ChkAppsBackground   = "Suspend UWP apps running in background"
    ChkNetworkLatency   = "Network optimization / latency reduction (TCP/IP)"

    LogAdvStart            = "Applying advanced system tweaks..."
    LogAdvDiagTrackOk      = "Telemetry disabled (DiagTrack service stopped/disabled, AllowTelemetry set to 0)."
    LogAdvEdgeWidgetsOk    = "Edge preload/background mode and taskbar Widgets disabled."
    LogAdvDeliveryOptOk    = "Delivery Optimization set to HTTP-only (P2P disabled)."
    LogAdvAppsBackgroundOk = "UWP apps blocked from running in the background."
    LogAdvNetworkOk        = "Network throttling disabled; TCP ack/nodelay tuned on {0} active interface(s)."
    LogAdvError            = "Error applying advanced tweak ({0}): {1}"
    LogAdvDone             = "Advanced system tweaks finished."

    GrpMoreOptimizations = "System Cleanup & Performance"
    ChkHibernation       = "Disable Hibernation (frees hiberfil.sys disk space)"
    ChkPowerPlan         = "Set power plan to High Performance"
    ChkTempCleanup       = "Clean temp files, old Prefetch, Windows.old and Windows Update cache"
    ChkHotCorners        = "Disable Snap Assist / Aero Shake (Hot Corners)"
    ChkRecallBlock       = "Disable Windows Recall"
    ChkBootTimeout       = "Reduce boot menu timeout to 5 seconds"
    ChkOfficeTelemetry   = "Block Office and OneDrive telemetry"
    ChkExtraSchedTasks   = "Remove additional telemetry scheduled tasks"
    ChkDiskOptimize      = "Auto-detect disks (SSD/HDD) and configure TRIM / scheduled defrag"
    ChkHagsGameMode      = "Enable Game Mode and Hardware-Accelerated GPU Scheduling (HAGS)"
    ChkUltimatePerf      = "Enable Ultimate Performance power plan with CPU minimum state at 100%"
    ChkDryRun            = "Dry Run (only log what would change, apply nothing)"
    BtnRestoreDefaults   = "Restore Defaults"
    BtnExportProfile     = "Export Profile"
    BtnImportProfile     = "Import Profile"

    LogMoreStart              = "Applying system cleanup & performance tweaks..."
    LogHibernationOk          = "Hibernation disabled (hiberfil.sys removed)."
    LogPowerPlanOk            = "Power plan set to High Performance."
    LogTempCleanupOk          = "Temporary files, old Prefetch entries, Windows.old and Windows Update cache cleaned."
    LogHotCornersOk           = "Snap Assist and Aero Shake disabled."
    LogRecallBlockOk          = "Windows Recall disabled via policy."
    LogBootTimeoutOk          = "Boot menu timeout set to 5 seconds."
    LogOfficeTelemetryOk      = "Office and OneDrive telemetry blocked."
    LogExtraSchedTasksOk      = "Additional telemetry scheduled tasks disabled."
    LogDiskOptimizeOk         = "Disk optimization applied: {0}"
    LogHagsGameModeOk         = "Game Mode and Hardware-Accelerated GPU Scheduling (HAGS) enabled. A restart is recommended for HAGS to take effect."
    LogUltimatePerfOk         = "Ultimate Performance power plan enabled and set active, with CPU minimum state at 100% (AC and DC)."
    LogMoreError              = "Error applying tweak ({0}): {1}"
    LogMoreDone               = "System cleanup & performance tweaks finished."

    LogRestoreDefaultsStart = "Restoring registry and service defaults..."
    LogRestoreDefaultsOk    = "Defaults restored successfully. A restart is recommended."
    LogRestoreDefaultsError = "Error restoring defaults: {0}"

    LogExportStart     = "Exporting current configuration profile..."
    LogExportOk        = "Profile exported to: {0}"
    LogExportError     = "Error exporting profile: {0}"
    LogExportCancelled = "Profile export cancelled by user."

    LogImportStart     = "Importing configuration profile..."
    LogImportOk        = "Profile imported from: {0}"
    LogImportError     = "Error importing profile: {0}"
    LogImportCancelled = "Profile import cancelled by user."

    LogDryRunPrefix = "[DRY RUN] Would apply: {0}"
    LogDryRunNote   = "Dry Run mode enabled: no changes will be made, only logged."

    LogDriversStart    = "Blocking automatic driver installation via Windows Update..."
    LogDriversOk       = "Automatic driver installation via Windows Update blocked."
    LogDriversError    = "Error blocking automatic drivers: {0}"
    LogPagefileRam     = "Detected RAM: {0} MB. Calculated pagefile size (RAM x 1.5): {1} MB."
    LogPagefileOk      = "Pagefile configured successfully: Initial and Maximum = {0} MB (fixed, no fragmentation)."
    LogPagefileError   = "Error configuring pagefile: {0}"
    LogChocoSearching = "Checking whether Chocolatey is installed..."
    LogChocoFound     = "Chocolatey found at: {0}"
    LogChocoNotFound  = "Chocolatey could not be installed automatically. Install it manually from https://chocolatey.org/install and try again."
    LogChocoInstalling      = "Chocolatey was not found. Installing Chocolatey automatically..."
    LogChocoInstallOk = "Chocolatey installed successfully."
    LogChocoInstallFailed = "Failed to install Chocolatey: {0}"
    LogInstallStart    = "Starting installation: {0} ({1})..."
    LogTryingWinget       = "Trying winget for {0}..."
    LogWingetFailedFallback = "Winget could not install {0} ({1}), falling back to Chocolatey..."
    LogWingetNotAvailable  = "Winget is not available for {0}, falling back to Chocolatey..."
    LogInstallOk       = "{0} installed successfully."
    LogInstallAlready  = "{0} is already installed (no action needed)."
    LogInstallWarn     = "{0} returned exit code {1}. Check the log at {2}"
    LogInstallError    = "Error installing {0}: {1}"
    LogLangChanged     = "Language changed to {0}."
    LogOptStart        = "======== Starting execution of selected optimizations ========"
    LogOptDone         = "======== Execution finished ========"
    LogInstallBatchStart = "======== Starting installation of selected applications ========"
    LogInstallBatchDone  = "======== Application installation finished ========"
    LogNoAppsSelected  = "No application was selected."
    TxtChocoRequired   = "Apps below are installed automatically via winget (built into Windows) whenever possible. Chocolatey is used as an automatic fallback for apps winget can't find - install it below just in case."
    ChocoStatusFound   = "Chocolatey is installed. You're ready to install apps below."
    ChocoStatusNotFound = "Chocolatey was not detected on this system yet."
    BtnInstallChoco    = "Install Chocolatey"
    LogChocoRequiredFirst = "Chocolatey is not installed. Click 'Install Chocolatey' above first."
    LogUnhandledError  = "Unexpected error: {0}"
}

$Lang['pt-BR'] = @{
    AppTitle          = "WGO - Windows General Optimizations"
    TabOptimizations  = "Otimiza" + $c_ccedil + $c_otil + "es & Privacidade"
    TabInstaller      = "Instalador de Apps"
    LblLanguage       = "Idioma:"
    GrpRestore        = "Seguran" + $c_ccedil + "a do Sistema"
    BtnCreateRestore  = "Criar Ponto de Restaura" + $c_ccedil + $c_atil + "o"
    ChkSelectAll      = "Selecionar Tudo / Desmarcar Tudo"
    GrpBloat          = "Remo" + $c_ccedil + $c_atil + "o de Bloatwares e Apps de IA"
    ChkBloat          = "Remover bloatwares / apps de IA (mant" + $c_eacute + "m Store, Xbox, Edge/WebView2, runtimes)"
    GrpSearch         = "Pesquisa do Menu Iniciar"
    ChkSearch         = "For" + $c_ccedil + "ar pesquisa 100% local (desativar busca web Bing/Edge)"
    GrpVisual         = "Efeitos Visuais"
    ChkVisual         = "Aplicar perfil de efeitos visuais personalizado de desempenho"
    GrpPrivacy        = "Privacidade Profunda / Telemetria"
    ChkPrivacy        = "Bloquear telemetria, WER, CEIP, Feed de Atividades, Localiza" + $c_ccedil + $c_atil + "o (Diretiva de Grupo)"
    GrpDrivers        = "Drivers via Windows Update"
    ChkDrivers        = "Bloquear instala" + $c_ccedil + $c_atil + "o autom" + $c_aacute + "tica de drivers pelo Windows Update"
    GrpPagefile       = "Mem" + $c_oacute + "ria Virtual (Pagefile)"
    ChkPagefile       = "Definir tamanho est" + $c_aacute + "tico da mem" + $c_oacute + "ria paginada (RAM x 1.5)"
    BtnRunSelected    = "Executar Otimiza" + $c_ccedil + $c_otil + "es Selecionadas"
    GrpInstaller      = "Aplicativos " + $c_uacute + "teis"
    BtnInstallApps    = "Instalar Selecionados"

    TabExternalScripts = "Scripts Externos"
    TxtExtScriptsWarning = "Estes s" + $c_atil + "o scripts independentes de terceiros, de c" + $c_oacute + "digo aberto (n" + $c_atil + "o fazem parte do WGO). Cada um abre sua pr" + $c_oacute + "pria janela e solicita permiss" + $c_atil + "o de administrador por conta pr" + $c_oacute + "pria. S" + $c_oacute + " execute ferramentas de fontes confi" + $c_aacute + "veis."

    TxtAmdOptimizerTitle = "AMD Stability Optimizer"
    TxtAmdOptimizerDesc  = "Um kit dedicado para placas de v" + $c_iacute + "deo AMD Radeon que ataca as causas mais comuns de travamentos de driver, telas pretas e engasgos. Ele desativa o ULPS, o Multi-Plane Overlay e o HDCP, aumenta o tempo limite (TDR) do driver, desliga o Fast Startup/Hiberna" + $c_ccedil + $c_atil + "o e o servi" + $c_ccedil + "o AMD Crash Defender, corrige o piscar de tela por acelera" + $c_ccedil + $c_atil + "o de hardware no Chrome/Edge/apps Electron (Discord, Spotify) e desbloqueia o plano de energia oculto de Ultra Desempenho do Windows. Ele cria um backup do registro e, quando poss" + $c_iacute + "vel, um Ponto de Restaura" + $c_ccedil + $c_atil + "o antes de qualquer altera" + $c_ccedil + $c_atil + "o, e tudo pode ser revertido pela pr" + $c_oacute + "pria interface dele."
    BtnRunAmdOptimizer   = "Executar AMD Stability Optimizer"

    TxtMassgraveTitle = "Ativa" + $c_ccedil + $c_atil + "o do Windows e Office (MAS)"
    TxtMassgraveDesc  = "Executa o projeto oficial Microsoft Activation Scripts (MASSGRAVE), uma ferramenta de c" + $c_oacute + "digo aberto muito conhecida da comunidade para ativar Windows e Microsoft Office via HWID, KMS38 ou KMS Online. Ele abre um menu de texto interativo em uma nova janela de console; basta seguir as op" + $c_ccedil + $c_otil + "es na tela para escolher o m" + $c_eacute + "todo de ativa" + $c_ccedil + $c_atil + "o desejado."
    BtnRunMassgrave   = "Executar Script de Ativa" + $c_ccedil + $c_atil + "o"

    LogExtScriptStart    = "Iniciando script externo: {0}..."
    LogExtScriptLaunched = "{0} iniciado em uma nova janela. Siga as instru" + $c_ccedil + $c_otil + "es exibidas l" + $c_aacute + "."
    LogExtScriptError    = "Erro ao iniciar {0}: {1}"

    LogHeader         = "Log de Execu" + $c_ccedil + $c_atil + "o"
    AppFirefoxDesc    = "Navegador altamente recomendado por n" + $c_atil + "o utilizar o motor Chromium, oferecendo privacidade real, maior controle do usu" + $c_aacute + "rio e suporte completo a bloqueadores de an" + $c_uacute + "ncios eficientes (como uBlock Origin)."
    AppNanaZipDesc    = "Compactador/descompactador de arquivos leve, moderno e nativamente integrado ao novo menu de contexto do Windows 11."
    AppNppDesc        = "Editor de texto r" + $c_aacute + "pido, leve e essencial para substitui" + $c_ccedil + $c_atil + "o do Bloco de Notas padr" + $c_atil + "o."
    AppFdmDesc        = "Gerenciador de downloads poderoso com acelera" + $c_ccedil + $c_atil + "o de arquivos HTTP/HTTPS."
    AppQbtDesc        = "Cliente BitTorrent de c" + $c_oacute + "digo aberto, extremamente leve, livre de an" + $c_uacute + "ncios, bloatware ou softwares indesejados."
    AppSteamDesc      = "Loja e launcher de jogos digitais da Valve."
    AppEpicDesc       = "Loja e launcher digital da Epic Games."
    AppGogDesc        = "Loja e launcher de jogos digitais livres de DRM."
    AppSevenZipDesc   = "Compactador de arquivos gratuito e de c" + $c_oacute + "digo aberto, com alt" + $c_iacute + "ssima taxa de compress" + $c_atil + "o."
    AppWiztreeDesc    = "Analisador de espa" + $c_ccedil + "o em disco extremamente r" + $c_aacute + "pido, alternativa ao WinDirStat."
    AppMemreductDesc  = "Utilit" + $c_aacute + "rio leve de monitoramento e limpeza de RAM em tempo real."
    AppBleachbitDesc  = "Ferramenta gratuita e de c" + $c_oacute + "digo aberto para limpar arquivos desnecess" + $c_aacute + "rios do disco e proteger a privacidade."
    AppMoonlightDesc  = "Cliente de streaming de jogos de c" + $c_oacute + "digo aberto, usado para conectar a um host Sunshine ou NVIDIA GameStream."
    AppSunshineDesc   = "Host de streaming de jogos auto-hospedado e de c" + $c_oacute + "digo aberto para o Moonlight, com codifica" + $c_ccedil + $c_atil + "o acelerada por GPU e baixa lat" + $c_ecirc + "ncia."
    MsgReady          = "Pronto."
    MsgDone           = "Conclu" + $c_iacute + "do."

    GrpExtraPrivacy    = "Bloqueio Adicional de Telemetria"
    ChkAdvertisingId   = "Desativar ID de publicidade (an" + $c_uacute + "ncios personalizados)"
    ChkTailoredExp     = "Desativar experi" + $c_ecirc + "ncias personalizadas / sugest" + $c_otil + "es e dicas do Windows"
    ChkDiagTrackSvc    = "Desativar servi" + $c_ccedil + "o Connected User Experiences and Telemetry (DiagTrack) e dmwappushservice"
    ChkCopilotBlock    = "Bloquear Copilot, Recall e an" + $c_aacute + "lise de dados por IA via diretiva"
    ChkInputTelemetry  = "Desativar personaliza" + $c_ccedil + $c_atil + "o de digita" + $c_ccedil + $c_atil + "o/escrita e sincroniza" + $c_ccedil + $c_atil + "o de " + $c_aacute + "rea de transfer" + $c_ecirc + "ncia na nuvem"

    LogRestoreTry      = "Tentando criar Ponto de Restaura" + $c_ccedil + $c_atil + "o do Sistema..."
    LogRestoreOk       = "Ponto de Restaura" + $c_ccedil + $c_atil + "o criado com sucesso."
    LogRestoreFail     = "Falha ao criar Ponto de Restaura" + $c_ccedil + $c_atil + "o: {0}"
    LogRestoreHint     = "Verifique se a Prote" + $c_ccedil + $c_atil + "o do Sistema est" + $c_aacute + " ativada (SystemPropertiesProtection.exe) e se o script est" + $c_aacute + " elevado."
    LogBloatStart      = "Iniciando remo" + $c_ccedil + $c_atil + "o de bloatware / apps de IA..."
    LogBloatUserRemoved = "Removido (usu" + $c_aacute + "rio): {0}"
    LogBloatProvRemoved = "Removido (provisionado): {0}"
    LogBloatError      = "Erro ao remover {0} : {1}"
    LogBloatDone       = "Remo" + $c_ccedil + $c_atil + "o de bloatware finalizada. Itens da whitelist foram preservados."
    LogSearchStart     = "Configurando pesquisa do Menu Iniciar como 100% local..."
    LogSearchOk        = "Pesquisa local aplicada com sucesso (DisableSearchBoxSuggestions, BingSearchEnabled, CortanaConsent)."
    LogSearchError     = "Erro ao configurar pesquisa local: {0}"
    LogVisualStart     = "Aplicando perfil de Efeitos Visuais personalizado..."
    LogVisualOk        = "Efeitos visuais aplicados: anima" + $c_ccedil + $c_otil + "es de janela, arraste de conte" + $c_uacute + "do, miniaturas, sele" + $c_ccedil + $c_atil + "o translucida, fontes suavizadas e sombras de icones mantidos ativos; demais efeitos desativados."
    LogVisualError     = "Erro ao aplicar efeitos visuais: {0}"
    LogPrivacyStart    = "Aplicando pol" + $c_iacute + "ticas de bloqueio de telemetria e privacidade profunda..."
    LogPrivacyOk       = "Pol" + $c_iacute + "ticas de telemetria, WER, CEIP, App Compat, Localiza" + $c_ccedil + $c_atil + "o e Timeline aplicadas via HKLM (GPO)."
    LogPrivacyError    = "Erro ao aplicar pol" + $c_iacute + "ticas de privacidade (verifique eleva" + $c_ccedil + $c_atil + "o de administrador): {0}"
    LogExtraStart      = "Aplicando op" + $c_ccedil + $c_otil + "es adicionais de bloqueio de telemetria..."
    LogExtraAdvOk      = "ID de publicidade desativado."
    LogExtraTailoredOk = "Experi" + $c_ecirc + "ncias personalizadas / sugest" + $c_otil + "es do Windows desativadas."
    LogExtraDiagTrackOk = "Servi" + $c_ccedil + "os DiagTrack e dmwappushservice parados e desativados."
    LogExtraCopilotOk  = "Copilot, Recall e an" + $c_aacute + "lise de dados por IA bloqueados via diretiva."
    LogExtraInputOk    = "Personaliza" + $c_ccedil + $c_atil + "o de digita" + $c_ccedil + $c_atil + "o e sincroniza" + $c_ccedil + $c_atil + "o de " + $c_aacute + "rea de transfer" + $c_ecirc + "ncia na nuvem desativadas."
    LogExtraError      = "Erro ao aplicar op" + $c_ccedil + $c_atil + "o adicional de telemetria ({0}): {1}"
    LogExtraDone       = "Op" + $c_ccedil + $c_otil + "es adicionais de bloqueio de telemetria finalizadas."

    GrpAdvancedTweaks   = "Ajustes Avan" + $c_ccedil + "ados do Sistema"
    ChkDiagTrackFull    = "Desativar Telemetria (servi" + $c_ccedil + "o DiagTrack + pol" + $c_iacute + "tica de registro)"
    ChkEdgeWidgets      = "Desativar pr" + $c_eacute + "-carregamento do Edge e Widgets"
    ChkDeliveryOpt      = "Desativar Otimiza" + $c_ccedil + $c_atil + "o de Entrega (P2P)"
    ChkAppsBackground   = "Suspender apps UWP em segundo plano"
    ChkNetworkLatency   = "Otimiza" + $c_ccedil + $c_atil + "o de Rede / Redu" + $c_ccedil + $c_atil + "o de Lat" + $c_ecirc + "ncia (TCP/IP)"

    LogAdvStart            = "Aplicando ajustes avan" + $c_ccedil + "ados do sistema..."
    LogAdvDiagTrackOk      = "Telemetria desativada (servi" + $c_ccedil + "o DiagTrack parado/desativado, AllowTelemetry definido como 0)."
    LogAdvEdgeWidgetsOk    = "Pr" + $c_eacute + "-carregamento/segundo plano do Edge e Widgets da barra de tarefas desativados."
    LogAdvDeliveryOptOk    = "Otimiza" + $c_ccedil + $c_atil + "o de Entrega definida somente para HTTP (P2P desativado)."
    LogAdvAppsBackgroundOk = "Apps UWP bloqueados de executar em segundo plano."
    LogAdvNetworkOk        = "Throttling de rede desativado; TCP ack/nodelay ajustados em {0} interface(s) ativa(s)."
    LogAdvError            = "Erro ao aplicar ajuste avan" + $c_ccedil + "ado ({0}): {1}"
    LogAdvDone             = "Ajustes avan" + $c_ccedil + "ados do sistema conclu" + $c_iacute + "dos."

    GrpMoreOptimizations = "Limpeza e Desempenho do Sistema"
    ChkHibernation       = "Desativar Hiberna" + $c_ccedil + $c_atil + "o (libera espa" + $c_ccedil + "o do hiberfil.sys)"
    ChkPowerPlan         = "Definir plano de energia como Alto Desempenho"
    ChkTempCleanup       = "Limpar arquivos tempor" + $c_aacute + "rios, Prefetch antigo, Windows.old e cache do Windows Update"
    ChkHotCorners        = "Desativar Snap Assist / Aero Shake (Hot Corners)"
    ChkRecallBlock       = "Desativar o Windows Recall"
    ChkBootTimeout       = "Reduzir o tempo de espera do menu de boot para 5 segundos"
    ChkOfficeTelemetry   = "Bloquear telemetria do Office e do OneDrive"
    ChkExtraSchedTasks   = "Remover tarefas agendadas adicionais de telemetria"
    ChkDiskOptimize      = "Detectar discos (SSD/HDD) automaticamente e configurar TRIM / desfragmenta" + $c_ccedil + $c_atil + "o agendada"
    ChkHagsGameMode      = "Ativar Modo de Jogo e agendamento de GPU acelerado por hardware (HAGS)"
    ChkUltimatePerf      = "Ativar plano de energia Desempenho M" + $c_aacute + "ximo (Ultimate Performance) com CPU m" + $c_iacute + "nima em 100%"
    ChkDryRun            = "Modo Simula" + $c_ccedil + $c_atil + "o (apenas registra o que seria alterado, sem aplicar)"
    BtnRestoreDefaults   = "Restaurar Padr" + $c_otil + "es"
    BtnExportProfile     = "Exportar Perfil"
    BtnImportProfile     = "Importar Perfil"

    LogMoreStart              = "Aplicando ajustes de limpeza e desempenho do sistema..."
    LogHibernationOk          = "Hiberna" + $c_ccedil + $c_atil + "o desativada (hiberfil.sys removido)."
    LogPowerPlanOk            = "Plano de energia definido como Alto Desempenho."
    LogTempCleanupOk          = "Arquivos tempor" + $c_aacute + "rios, Prefetch antigo, Windows.old e cache do Windows Update limpos."
    LogHotCornersOk           = "Snap Assist e Aero Shake desativados."
    LogRecallBlockOk          = "Windows Recall desativado via pol" + $c_iacute + "tica."
    LogBootTimeoutOk          = "Tempo de espera do menu de boot definido para 5 segundos."
    LogOfficeTelemetryOk      = "Telemetria do Office e do OneDrive bloqueada."
    LogExtraSchedTasksOk      = "Tarefas agendadas adicionais de telemetria desativadas."
    LogDiskOptimizeOk         = "Otimiza" + $c_ccedil + $c_atil + "o de disco aplicada: {0}"
    LogHagsGameModeOk         = "Modo de Jogo e HAGS (agendamento de GPU acelerado por hardware) ativados. Reinicie o PC para o HAGS ter efeito."
    LogUltimatePerfOk         = "Plano Desempenho M" + $c_aacute + "ximo ativado e definido como padr" + $c_atil + "o, com CPU m" + $c_iacute + "nima em 100% (energia e bateria)."
    LogMoreError              = "Erro ao aplicar ajuste ({0}): {1}"
    LogMoreDone               = "Ajustes de limpeza e desempenho do sistema conclu" + $c_iacute + "dos."

    LogRestoreDefaultsStart = "Restaurando valores padr" + $c_atil + "o de registro e servi" + $c_ccedil + "os..."
    LogRestoreDefaultsOk    = "Padr" + $c_otil + "es restaurados com sucesso. Reinicie o computador quando poss" + $c_iacute + "vel."
    LogRestoreDefaultsError = "Erro ao restaurar padr" + $c_otil + "es: {0}"

    LogExportStart     = "Exportando o perfil de configura" + $c_ccedil + $c_atil + "o atual..."
    LogExportOk        = "Perfil exportado para: {0}"
    LogExportError     = "Erro ao exportar o perfil: {0}"
    LogExportCancelled = "Exporta" + $c_ccedil + $c_atil + "o de perfil cancelada pelo usu" + $c_aacute + "rio."

    LogImportStart     = "Importando perfil de configura" + $c_ccedil + $c_atil + "o..."
    LogImportOk        = "Perfil importado de: {0}"
    LogImportError     = "Erro ao importar o perfil: {0}"
    LogImportCancelled = "Importa" + $c_ccedil + $c_atil + "o de perfil cancelada pelo usu" + $c_aacute + "rio."

    LogDryRunPrefix = "[SIMULA" + $c_ccedil + $c_atil + "O] Seria aplicado: {0}"
    LogDryRunNote   = "Modo Simula" + $c_ccedil + $c_atil + "o ativado: nenhuma altera" + $c_ccedil + $c_atil + "o ser" + $c_aacute + " feita, apenas registrada no log."

    LogDriversStart    = "Bloqueando instala" + $c_ccedil + $c_atil + "o autom" + $c_aacute + "tica de drivers via Windows Update..."
    LogDriversOk       = "Instala" + $c_ccedil + $c_atil + "o autom" + $c_aacute + "tica de drivers pelo Windows Update bloqueada."
    LogDriversError    = "Erro ao bloquear drivers autom" + $c_aacute + "ticos: {0}"
    LogPagefileRam     = "RAM detectada: {0} MB. Tamanho de pagefile calculado (RAM x 1.5): {1} MB."
    LogPagefileOk      = "Pagefile configurado com sucesso: Inicial e M" + $c_aacute + "ximo = {0} MB (fixo, sem fragmenta" + $c_ccedil + $c_atil + "o)."
    LogPagefileError   = "Erro ao configurar pagefile: {0}"
    LogChocoSearching = "Verificando se o Chocolatey est" + $c_aacute + " instalado..."
    LogChocoFound     = "Chocolatey encontrado em: {0}"
    LogChocoNotFound  = "N" + $c_atil + "o foi poss" + $c_iacute + "vel instalar o Chocolatey automaticamente. Instale manualmente em https://chocolatey.org/install e tente novamente."
    LogChocoInstalling      = "Chocolatey n" + $c_atil + "o encontrado. Instalando o Chocolatey automaticamente..."
    LogChocoInstallOk = "Chocolatey instalado com sucesso."
    LogChocoInstallFailed = "Falha ao instalar o Chocolatey: {0}"
    LogInstallStart    = "Iniciando instala" + $c_ccedil + $c_atil + "o: {0} ({1})..."
    LogTryingWinget       = "Tentando instalar {0} via winget..."
    LogWingetFailedFallback = "O winget n" + $c_atil + "o conseguiu instalar {0} ({1}), usando o Chocolatey como alternativa..."
    LogWingetNotAvailable  = "O winget n" + $c_atil + "o est" + $c_aacute + " dispon" + $c_iacute + "vel para {0}, usando o Chocolatey como alternativa..."
    LogInstallOk       = "{0} instalado com sucesso."
    LogInstallAlready  = "{0} j" + $c_aacute + " estava instalado (nenhuma a" + $c_ccedil + $c_atil + "o necess" + $c_aacute + "ria)."
    LogInstallWarn     = "{0} retornou c" + $c_oacute + "digo de sa" + $c_iacute + "da {1}. Verifique o log em {2}"
    LogInstallError    = "Erro ao instalar {0}: {1}"
    LogLangChanged     = "Idioma alterado para {0}."
    LogOptStart        = "======== Iniciando execu" + $c_ccedil + $c_atil + "o das otimiza" + $c_ccedil + $c_otil + "es selecionadas ========"
    LogOptDone         = "======== Execu" + $c_ccedil + $c_atil + "o finalizada ========"
    LogInstallBatchStart = "======== Iniciando instala" + $c_ccedil + $c_atil + "o de aplicativos selecionados ========"
    LogInstallBatchDone  = "======== Instala" + $c_ccedil + $c_atil + "o de aplicativos finalizada ========"
    LogNoAppsSelected  = "Nenhum aplicativo foi selecionado."
    TxtChocoRequired   = "Os apps abaixo s" + $c_atil + "o instalados automaticamente via winget (nativo do Windows) sempre que poss" + $c_iacute + "vel. O Chocolatey " + $c_eacute + " usado como alternativa autom" + $c_aacute + "tica para apps que o winget n" + $c_atil + "o encontrar - instale-o abaixo por precau" + $c_ccedil + $c_atil + "o."
    ChocoStatusFound   = "Chocolatey est" + $c_aacute + " instalado. Voc" + $c_ecirc + " j" + $c_aacute + " pode instalar os apps abaixo."
    ChocoStatusNotFound = "O Chocolatey ainda n" + $c_atil + "o foi detectado neste sistema."
    BtnInstallChoco    = "Instalar Chocolatey"
    LogChocoRequiredFirst = "O Chocolatey n" + $c_atil + "o est" + $c_aacute + " instalado. Clique em 'Instalar Chocolatey' acima primeiro."
    LogUnhandledError      = "Erro inesperado: {0}"
}

$Lang['es-ES'] = @{
    AppTitle          = "WGO - Windows General Optimizations"
    TabOptimizations  = "Optimizaciones y Privacidad"
    TabInstaller      = "Instalador de Apps"
    LblLanguage       = "Idioma:"
    GrpRestore        = "Seguridad del Sistema"
    BtnCreateRestore  = "Crear Punto de Restauraci" + [char]0x00F3 + "n"
    ChkSelectAll      = "Seleccionar Todo / Deseleccionar Todo"
    GrpBloat          = "Eliminaci" + [char]0x00F3 + "n de Bloatware y Apps de IA"
    ChkBloat          = "Eliminar bloatware / apps de IA (mantiene Store, Xbox, Edge/WebView2, runtimes)"
    GrpSearch         = "B" + [char]0x00FA + "squeda del Men" + [char]0x00FA + " Inicio"
    ChkSearch         = "Forzar b" + [char]0x00FA + "squeda 100% local (desactivar b" + [char]0x00FA + "squeda web Bing/Edge)"
    GrpVisual         = "Efectos Visuales"
    ChkVisual         = "Aplicar perfil de efectos visuales de rendimiento personalizado"
    GrpPrivacy        = "Privacidad Profunda / Telemetr" + [char]0x00ED + "a"
    ChkPrivacy        = "Bloquear telemetr" + [char]0x00ED + "a, WER, CEIP, Feed de Actividades, Ubicaci" + [char]0x00F3 + "n (Directiva de Grupo)"
    GrpDrivers        = "Controladores v" + [char]0x00ED + "a Windows Update"
    ChkDrivers        = "Bloquear instalaci" + [char]0x00F3 + "n autom" + [char]0x00E1 + "tica de controladores por Windows Update"
    GrpPagefile       = "Memoria Virtual (Pagefile)"
    ChkPagefile       = "Establecer tama" + $c_enye + "o est" + [char]0x00E1 + "tico del archivo de paginaci" + [char]0x00F3 + "n (RAM x 1.5)"
    BtnRunSelected    = "Ejecutar Optimizaciones Seleccionadas"
    GrpInstaller      = "Aplicaciones " + [char]0x00DA + "tiles"
    BtnInstallApps    = "Instalar Seleccionados"

    TabExternalScripts = "Scripts Externos"
    TxtExtScriptsWarning = "Estos son scripts independientes de terceros, de c" + [char]0x00F3 + "digo abierto (no forman parte de WGO). Cada uno abre su propia ventana y solicita permisos de administrador por su cuenta. Ejecute " + [char]0x00FA + "nicamente herramientas de fuentes confiables."

    TxtAmdOptimizerTitle = "AMD Stability Optimizer"
    TxtAmdOptimizerDesc  = "Un kit dedicado para tarjetas gr" + [char]0x00E1 + "ficas AMD Radeon que ataca las causas m" + [char]0x00E1 + "s comunes de bloqueos del controlador, pantallas negras y tirones. Desactiva ULPS, Multi-Plane Overlay y HDCP, aumenta el tiempo de espera (TDR) del controlador, desactiva Fast Startup/Hibernaci" + [char]0x00F3 + "n y el servicio AMD Crash Defender, corrige el parpadeo por aceleraci" + [char]0x00F3 + "n por hardware en Chrome/Edge/apps Electron (Discord, Spotify) y desbloquea el plan de energ" + [char]0x00ED + "a oculto de Rendimiento M" + [char]0x00E1 + "ximo de Windows. Crea una copia de seguridad del registro y, cuando es posible, un Punto de Restauraci" + [char]0x00F3 + "n antes de cualquier cambio, y todo puede revertirse desde su propia interfaz."
    BtnRunAmdOptimizer   = "Ejecutar AMD Stability Optimizer"

    TxtMassgraveTitle = "Activaci" + [char]0x00F3 + "n de Windows y Office (MAS)"
    TxtMassgraveDesc  = "Ejecuta el proyecto oficial Microsoft Activation Scripts (MASSGRAVE), una herramienta de c" + [char]0x00F3 + "digo abierto muy conocida de la comunidad para activar Windows y Microsoft Office mediante HWID, KMS38 o KMS en l" + [char]0x00ED + "nea. Abre un men" + [char]0x00FA + " de texto interactivo en una nueva ventana de consola; solo siga las opciones en pantalla para elegir el m" + [char]0x00E9 + "todo de activaci" + [char]0x00F3 + "n deseado."
    BtnRunMassgrave   = "Ejecutar Script de Activaci" + [char]0x00F3 + "n"

    LogExtScriptStart    = "Iniciando script externo: {0}..."
    LogExtScriptLaunched = "{0} iniciado en una nueva ventana. Siga las instrucciones mostradas all" + [char]0x00ED + "."
    LogExtScriptError    = "Error al iniciar {0}: {1}"

    LogHeader         = "Registro de Ejecuci" + [char]0x00F3 + "n"
    AppFirefoxDesc    = "Navegador muy recomendado por no utilizar el motor Chromium, ofreciendo privacidad real, m" + [char]0x00E1 + "s control del usuario y soporte completo para bloqueadores de anuncios eficientes (como uBlock Origin)."
    AppNanaZipDesc    = "Compresor/descompresor de archivos ligero, moderno e integrado nativamente en el nuevo men" + [char]0x00FA + " contextual de Windows 11."
    AppNppDesc        = "Editor de texto r" + [char]0x00E1 + "pido, ligero y esencial para reemplazar el Bloc de notas predeterminado."
    AppFdmDesc        = "Potente gestor de descargas con aceleraci" + [char]0x00F3 + "n de archivos HTTP/HTTPS."
    AppQbtDesc        = "Cliente BitTorrent de c" + [char]0x00F3 + "digo abierto, extremadamente ligero, sin anuncios ni bloatware."
    AppSteamDesc      = "Tienda y launcher de juegos digitales de Valve."
    AppEpicDesc       = "Tienda y launcher digital de Epic Games."
    AppGogDesc        = "Tienda y launcher de juegos digitales libres de DRM."
    AppSevenZipDesc   = "Compresor de archivos gratuito y de c" + [char]0x00F3 + "digo abierto, con una tasa de compresi" + [char]0x00F3 + "n muy alta."
    AppWiztreeDesc    = "Analizador de espacio en disco extremadamente r" + [char]0x00E1 + "pido, alternativa a WinDirStat."
    AppMemreductDesc  = "Utilidad ligera de monitoreo y limpieza de RAM en tiempo real."
    AppBleachbitDesc  = "Herramienta gratuita y de c" + [char]0x00F3 + "digo abierto para limpiar archivos innecesarios del disco y proteger la privacidad."
    AppMoonlightDesc  = "Cliente de transmisi" + [char]0x00F3 + "n de juegos de c" + [char]0x00F3 + "digo abierto, usado para conectarse a un host Sunshine o NVIDIA GameStream."
    AppSunshineDesc   = "Host de transmisi" + [char]0x00F3 + "n de juegos autoalojado y de c" + [char]0x00F3 + "digo abierto para Moonlight, con codificaci" + [char]0x00F3 + "n acelerada por GPU y baja latencia."
    MsgReady          = "Listo."
    MsgDone           = "Completado."

    GrpExtraPrivacy    = "Bloqueo Adicional de Telemetr" + [char]0x00ED + "a"
    ChkAdvertisingId   = "Desactivar ID de publicidad (anuncios personalizados)"
    ChkTailoredExp     = "Desactivar experiencias personalizadas / sugerencias de Windows"
    ChkDiagTrackSvc    = "Desactivar servicio Connected User Experiences and Telemetry (DiagTrack) y dmwappushservice"
    ChkCopilotBlock    = "Bloquear Copilot, Recall y an" + [char]0x00E1 + "lisis de datos por IA mediante directiva"
    ChkInputTelemetry  = "Desactivar personalizaci" + [char]0x00F3 + "n de escritura y sincronizaci" + [char]0x00F3 + "n de portapapeles en la nube"

    LogRestoreTry      = "Intentando crear un Punto de Restauraci" + [char]0x00F3 + "n del Sistema..."
    LogRestoreOk       = "Punto de Restauraci" + [char]0x00F3 + "n creado correctamente."
    LogRestoreFail     = "Error al crear el Punto de Restauraci" + [char]0x00F3 + "n: {0}"
    LogRestoreHint     = "Verifique que la Protecci" + [char]0x00F3 + "n del Sistema est" + [char]0x00E9 + " activada (SystemPropertiesProtection.exe) y que el script se ejecute elevado."
    LogBloatStart      = "Iniciando la eliminaci" + [char]0x00F3 + "n de bloatware / apps de IA..."
    LogBloatUserRemoved = "Eliminado (usuario): {0}"
    LogBloatProvRemoved = "Eliminado (aprovisionado): {0}"
    LogBloatError      = "Error al eliminar {0} : {1}"
    LogBloatDone       = "Eliminaci" + [char]0x00F3 + "n de bloatware finalizada. Los elementos de la lista blanca se conservaron."
    LogSearchStart     = "Configurando la b" + [char]0x00FA + "squeda del Men" + [char]0x00FA + " Inicio como 100% local..."
    LogSearchOk        = "B" + [char]0x00FA + "squeda local aplicada correctamente (DisableSearchBoxSuggestions, BingSearchEnabled, CortanaConsent)."
    LogSearchError     = "Error al configurar la b" + [char]0x00FA + "squeda local: {0}"
    LogVisualStart     = "Aplicando el perfil de Efectos Visuales personalizado..."
    LogVisualOk        = "Efectos visuales aplicados: animaciones de ventana, arrastre de contenido, miniaturas, selecci" + [char]0x00F3 + "n translucida, fuentes suavizadas y sombras de iconos mantenidos activos; los dem" + [char]0x00E1 + "s efectos desactivados."
    LogVisualError     = "Error al aplicar los efectos visuales: {0}"
    LogPrivacyStart    = "Aplicando directivas de bloqueo de telemetr" + [char]0x00ED + "a y privacidad profunda..."
    LogPrivacyOk       = "Directivas de telemetr" + [char]0x00ED + "a, WER, CEIP, App Compat, Ubicaci" + [char]0x00F3 + "n y Timeline aplicadas mediante HKLM (GPO)."
    LogPrivacyError    = "Error al aplicar las directivas de privacidad (verifique la elevaci" + [char]0x00F3 + "n de administrador): {0}"
    LogExtraStart      = "Aplicando opciones adicionales de bloqueo de telemetr" + [char]0x00ED + "a..."
    LogExtraAdvOk      = "ID de publicidad desactivado."
    LogExtraTailoredOk = "Experiencias personalizadas / sugerencias de Windows desactivadas."
    LogExtraDiagTrackOk = "Servicios DiagTrack y dmwappushservice detenidos y desactivados."
    LogExtraCopilotOk  = "Copilot, Recall y an" + [char]0x00E1 + "lisis de datos por IA bloqueados mediante directiva."
    LogExtraInputOk    = "Personalizaci" + [char]0x00F3 + "n de escritura y sincronizaci" + [char]0x00F3 + "n de portapapeles en la nube desactivadas."
    LogExtraError      = "Error al aplicar la opci" + [char]0x00F3 + "n adicional de telemetr" + [char]0x00ED + "a ({0}): {1}"
    LogExtraDone       = "Opciones adicionales de bloqueo de telemetr" + [char]0x00ED + "a finalizadas."

    GrpAdvancedTweaks   = "Ajustes Avanzados del Sistema"
    ChkDiagTrackFull    = "Desactivar Telemetr" + [char]0x00ED + "a (servicio DiagTrack + directiva de registro)"
    ChkEdgeWidgets      = "Desactivar precarga de Edge y Widgets"
    ChkDeliveryOpt      = "Desactivar Optimizaci" + [char]0x00F3 + "n de Entrega (P2P)"
    ChkAppsBackground   = "Suspender apps UWP en segundo plano"
    ChkNetworkLatency   = "Optimizaci" + [char]0x00F3 + "n de red / reducci" + [char]0x00F3 + "n de latencia (TCP/IP)"

    LogAdvStart            = "Aplicando ajustes avanzados del sistema..."
    LogAdvDiagTrackOk      = "Telemetr" + [char]0x00ED + "a desactivada (servicio DiagTrack detenido/deshabilitado, AllowTelemetry en 0)."
    LogAdvEdgeWidgetsOk    = "Precarga/segundo plano de Edge y Widgets de la barra de tareas desactivados."
    LogAdvDeliveryOptOk    = "Optimizaci" + [char]0x00F3 + "n de Entrega establecida solo en HTTP (P2P desactivado)."
    LogAdvAppsBackgroundOk = "Apps UWP bloqueadas para ejecutarse en segundo plano."
    LogAdvNetworkOk        = "Throttling de red desactivado; TCP ack/nodelay ajustados en {0} interfaz(es) activa(s)."
    LogAdvError            = "Error al aplicar ajuste avanzado ({0}): {1}"
    LogAdvDone             = "Ajustes avanzados del sistema finalizados."

    GrpMoreOptimizations = "Limpieza y Rendimiento del Sistema"
    ChkHibernation       = "Desactivar Hibernaci" + [char]0x00F3 + "n (libera espacio de hiberfil.sys)"
    ChkPowerPlan         = "Establecer plan de energ" + [char]0x00ED + "a en Alto Rendimiento"
    ChkTempCleanup       = "Limpiar archivos temporales, Prefetch antiguo, Windows.old y cach" + [char]0x00E9 + " de Windows Update"
    ChkHotCorners        = "Desactivar Snap Assist / Aero Shake (Hot Corners)"
    ChkRecallBlock       = "Desactivar Windows Recall"
    ChkBootTimeout       = "Reducir el tiempo de espera del men" + [char]0x00FA + " de arranque a 5 segundos"
    ChkOfficeTelemetry   = "Bloquear la telemetr" + [char]0x00ED + "a de Office y OneDrive"
    ChkExtraSchedTasks   = "Eliminar tareas programadas adicionales de telemetr" + [char]0x00ED + "a"
    ChkDiskOptimize      = "Detectar discos (SSD/HDD) autom" + [char]0x00E1 + "ticamente y configurar TRIM / desfragmentaci" + [char]0x00F3 + "n programada"
    ChkHagsGameMode      = "Activar Modo de Juego y la planificaci" + [char]0x00F3 + "n de GPU acelerada por hardware (HAGS)"
    ChkUltimatePerf      = "Activar el plan de energ" + [char]0x00ED + "a Rendimiento M" + [char]0x00E1 + "ximo (Ultimate Performance) con la CPU al m" + [char]0x00ED + "nimo en 100%"
    ChkDryRun            = "Modo Simulaci" + [char]0x00F3 + "n (solo registra los cambios sin aplicarlos)"
    BtnRestoreDefaults   = "Restaurar Valores Predeterminados"
    BtnExportProfile     = "Exportar Perfil"
    BtnImportProfile     = "Importar Perfil"

    LogMoreStart              = "Aplicando ajustes de limpieza y rendimiento del sistema..."
    LogHibernationOk          = "Hibernaci" + [char]0x00F3 + "n desactivada (hiberfil.sys eliminado)."
    LogPowerPlanOk            = "Plan de energ" + [char]0x00ED + "a establecido en Alto Rendimiento."
    LogTempCleanupOk          = "Archivos temporales, Prefetch antiguo, Windows.old y cach" + [char]0x00E9 + " de Windows Update limpiados."
    LogHotCornersOk           = "Snap Assist y Aero Shake desactivados."
    LogRecallBlockOk          = "Windows Recall desactivado mediante directiva."
    LogBootTimeoutOk          = "Tiempo de espera del men" + [char]0x00FA + " de arranque establecido en 5 segundos."
    LogOfficeTelemetryOk      = "Telemetr" + [char]0x00ED + "a de Office y OneDrive bloqueada."
    LogExtraSchedTasksOk      = "Tareas programadas adicionales de telemetr" + [char]0x00ED + "a desactivadas."
    LogDiskOptimizeOk         = "Optimizaci" + [char]0x00F3 + "n de disco aplicada: {0}"
    LogHagsGameModeOk         = "Modo de Juego y HAGS (planificaci" + [char]0x00F3 + "n de GPU acelerada por hardware) activados. Se recomienda reiniciar para que HAGS surta efecto."
    LogUltimatePerfOk         = "Plan Rendimiento M" + [char]0x00E1 + "ximo activado y establecido como predeterminado, con la CPU al m" + [char]0x00ED + "nimo en 100% (CA y bater" + [char]0x00ED + "a)."
    LogMoreError              = "Error al aplicar el ajuste ({0}): {1}"
    LogMoreDone               = "Ajustes de limpieza y rendimiento del sistema finalizados."

    LogRestoreDefaultsStart = "Restaurando valores predeterminados de registro y servicios..."
    LogRestoreDefaultsOk    = "Valores predeterminados restaurados correctamente. Se recomienda reiniciar."
    LogRestoreDefaultsError = "Error al restaurar los valores predeterminados: {0}"

    LogExportStart     = "Exportando el perfil de configuraci" + [char]0x00F3 + "n actual..."
    LogExportOk        = "Perfil exportado a: {0}"
    LogExportError     = "Error al exportar el perfil: {0}"
    LogExportCancelled = "Exportaci" + [char]0x00F3 + "n de perfil cancelada por el usuario."

    LogImportStart     = "Importando perfil de configuraci" + [char]0x00F3 + "n..."
    LogImportOk        = "Perfil importado desde: {0}"
    LogImportError     = "Error al importar el perfil: {0}"
    LogImportCancelled = "Importaci" + [char]0x00F3 + "n de perfil cancelada por el usuario."

    LogDryRunPrefix = "[SIMULACI" + [char]0x00D3 + "N] Se aplicar" + [char]0x00ED + "a: {0}"
    LogDryRunNote   = "Modo Simulaci" + [char]0x00F3 + "n activado: no se aplicar" + [char]0x00E1 + " ning" + [char]0x00FA + "n cambio, solo se registrar" + [char]0x00E1 + " en el log."

    LogDriversStart    = "Bloqueando la instalaci" + [char]0x00F3 + "n autom" + [char]0x00E1 + "tica de controladores mediante Windows Update..."
    LogDriversOk       = "Instalaci" + [char]0x00F3 + "n autom" + [char]0x00E1 + "tica de controladores mediante Windows Update bloqueada."
    LogDriversError    = "Error al bloquear los controladores autom" + [char]0x00E1 + "ticos: {0}"
    LogPagefileRam     = "RAM detectada: {0} MB. Tama" + $c_enye + "o de pagefile calculado (RAM x 1.5): {1} MB."
    LogPagefileOk      = "Pagefile configurado correctamente: Inicial y M" + [char]0x00E1 + "ximo = {0} MB (fijo, sin fragmentaci" + [char]0x00F3 + "n)."
    LogPagefileError   = "Error al configurar el pagefile: {0}"
    LogChocoSearching = "Comprobando si Chocolatey est" + [char]0x00E1 + " instalado..."
    LogChocoFound     = "Chocolatey encontrado en: {0}"
    LogChocoNotFound  = "No se pudo instalar Chocolatey autom" + [char]0x00E1 + "ticamente. Instalelo manualmente desde https://chocolatey.org/install e intente de nuevo."
    LogChocoInstalling      = "Chocolatey no encontrado. Instalando Chocolatey autom" + [char]0x00E1 + "ticamente..."
    LogChocoInstallOk = "Chocolatey instalado correctamente."
    LogChocoInstallFailed = "Error al instalar Chocolatey: {0}"
    LogInstallStart    = "Iniciando instalaci" + [char]0x00F3 + "n: {0} ({1})..."
    LogTryingWinget       = "Probando instalar {0} con winget..."
    LogWingetFailedFallback = "Winget no pudo instalar {0} ({1}), usando Chocolatey como alternativa..."
    LogWingetNotAvailable  = "Winget no est" + [char]0x00E1 + " disponible para {0}, usando Chocolatey como alternativa..."
    LogInstallOk       = "{0} instalado correctamente."
    LogInstallAlready  = "{0} ya estaba instalado (ninguna acci" + [char]0x00F3 + "n necesaria)."
    LogInstallWarn     = "{0} devolvi" + [char]0x00F3 + " el c" + [char]0x00F3 + "digo de salida {1}. Verifique el log en {2}"
    LogInstallError    = "Error al instalar {0}: {1}"
    LogLangChanged     = "Idioma cambiado a {0}."
    LogOptStart        = "======== Iniciando ejecuci" + [char]0x00F3 + "n de las optimizaciones seleccionadas ========"
    LogOptDone         = "======== Ejecuci" + [char]0x00F3 + "n finalizada ========"
    LogInstallBatchStart = "======== Iniciando instalaci" + [char]0x00F3 + "n de aplicaciones seleccionadas ========"
    LogInstallBatchDone  = "======== Instalaci" + [char]0x00F3 + "n de aplicaciones finalizada ========"
    LogNoAppsSelected  = "No se seleccion" + [char]0x00F3 + " ninguna aplicaci" + [char]0x00F3 + "n."
    TxtChocoRequired   = "Las aplicaciones de abajo se instalan autom" + [char]0x00E1 + "ticamente mediante winget (nativo de Windows) siempre que sea posible. Chocolatey se usa como alternativa autom" + [char]0x00E1 + "tica para apps que winget no encuentre - inst" + [char]0x00E1 + "lelo abajo por precauci" + [char]0x00F3 + "n."
    ChocoStatusFound   = "Chocolatey est" + [char]0x00E1 + " instalado. Ya puede instalar las aplicaciones de abajo."
    ChocoStatusNotFound = "Chocolatey a" + [char]0x00FA + "n no se ha detectado en este sistema."
    BtnInstallChoco    = "Instalar Chocolatey"
    LogChocoRequiredFirst = "Chocolatey no est" + [char]0x00E1 + " instalado. Haga clic en 'Instalar Chocolatey' arriba primero."
    LogUnhandledError      = "Error inesperado: {0}"
}

# zh-CN (Simplified Chinese) - built strictly with [char]0xXXXX code points
function ZH { param([int[]]$Codes) -join ($Codes | ForEach-Object { [char]$_ }) }

$Lang['zh-CN'] = @{
    AppTitle          = "WGO - Windows General Optimizations"
    TabOptimizations  = (ZH 0x4F18,0x5316) + "&" + (ZH 0x9690,0x79C1)
    TabInstaller      = (ZH 0x5E94,0x7528,0x5B89,0x88C5,0x5668)
    LblLanguage       = (ZH 0x8BED,0x8A00) + ":"
    GrpRestore        = (ZH 0x7CFB,0x7EDF,0x5B89,0x5168)
    BtnCreateRestore  = (ZH 0x521B,0x5EFA) + (ZH 0x8FD8,0x539F,0x70B9)
    ChkSelectAll      = (ZH 0x5168,0x9009) + "/" + (ZH 0x53D6,0x6D88) + (ZH 0x5168,0x9009)
    GrpBloat          = (ZH 0x5220,0x9664) + (ZH 0x81C3,0x80BF,0x8F6F,0x4EF6) + "/AI" + (ZH 0x5E94,0x7528)
    ChkBloat          = (ZH 0x5220,0x9664) + (ZH 0x81C3,0x80BF,0x8F6F,0x4EF6) + "/AI" + (ZH 0x5E94,0x7528) + " (" + (ZH 0x4FDD,0x7559) + " Store, Xbox, Edge/WebView2, Runtime)"
    GrpSearch         = (ZH 0x5F00,0x59CB) + (ZH 0x83DC,0x5355) + (ZH 0x641C,0x7D22)
    ChkSearch         = (ZH 0x5F3A,0x5236) + "100%" + (ZH 0x672C,0x5730) + (ZH 0x641C,0x7D22) + " (" + (ZH 0x7981,0x7528) + " Bing/Edge " + (ZH 0x7F51,0x7EDC) + (ZH 0x641C,0x7D22) + ")"
    GrpVisual         = (ZH 0x89C6,0x89C9,0x6548,0x679C)
    ChkVisual         = (ZH 0x5E94,0x7528) + (ZH 0x81EA,0x5B9A,0x4E49) + (ZH 0x6027,0x80FD) + (ZH 0x89C6,0x89C9,0x6548,0x679C) + (ZH 0x914D,0x7F6E)
    GrpPrivacy        = (ZH 0x6DF1,0x5EA6) + (ZH 0x9690,0x79C1) + "/" + (ZH 0x9065,0x6D4B)
    ChkPrivacy        = (ZH 0x963B,0x6B62) + (ZH 0x9065,0x6D4B) + ", WER, CEIP, " + (ZH 0x6D3B,0x52A8) + (ZH 0x63D0,0x9192) + ", " + (ZH 0x4F4D,0x7F6E) + " (" + (ZH 0x7EC4,0x7B56,0x7565) + ")"
    GrpDrivers        = "Windows Update " + (ZH 0x9A71,0x52A8,0x7A0B,0x5E8F)
    ChkDrivers        = (ZH 0x963B,0x6B62) + "Windows Update " + (ZH 0x81EA,0x52A8) + (ZH 0x5B89,0x88C5) + (ZH 0x9A71,0x52A8,0x7A0B,0x5E8F)
    GrpPagefile       = (ZH 0x865A,0x62DF,0x5185,0x5B58) + " (Pagefile)"
    ChkPagefile       = (ZH 0x8BBE,0x7F6E) + (ZH 0x9875,0x9762,0x6587,0x4EF6) + (ZH 0x56FA,0x5B9A) + (ZH 0x5927,0x5C0F) + " (RAM x 1.5)"
    BtnRunSelected    = (ZH 0x8FD0,0x884C) + (ZH 0x5DF2,0x9009) + (ZH 0x4F18,0x5316) + (ZH 0x9879,0x76EE)
    GrpInstaller      = (ZH 0x5B9E,0x7528) + (ZH 0x5E94,0x7528) + (ZH 0x7A0B,0x5E8F)
    BtnInstallApps    = (ZH 0x5B89,0x88C5) + (ZH 0x5DF2,0x9009) + (ZH 0x9879,0x76EE)

    TabExternalScripts = (ZH 0x5916,0x90E8,0x811A,0x672C)
    TxtExtScriptsWarning = (ZH 0x8FD9,0x4E9B,0x662F,0x72EC,0x7ACB,0x7684,0x7B2C,0x4E09,0x65B9,0x5F00,0x6E90,0x811A,0x672C) + "(" + (ZH 0x4E0D,0x5C5E,0x4E8E) + " WGO)" + "," + (ZH 0x6BCF,0x4E2A,0x811A,0x672C,0x90FD,0x4F1A,0x6253,0x5F00,0x81EA,0x5DF1,0x7684,0x7A97,0x53E3) + (ZH 0x5E76,0x81EA,0x884C,0x8BF7,0x6C42,0x7BA1,0x7406,0x5458,0x6743,0x9650) + "," + (ZH 0x8BF7,0x4EC5,0x8FD0,0x884C,0x6765,0x81EA,0x53EF,0x4FE1,0x6765,0x6E90,0x7684,0x5DE5,0x5177)

    TxtAmdOptimizerTitle = "AMD " + (ZH 0x7A33,0x5B9A,0x6027,0x4F18,0x5316,0x5DE5,0x5177)
    TxtAmdOptimizerDesc  = (ZH 0x4E13,0x4E3A) + " AMD Radeon " + (ZH 0x663E,0x5361) + (ZH 0x8BBE,0x8BA1,0x7684,0x5DE5,0x5177,0x5305) + "," + (ZH 0x65E8,0x5728,0x89E3,0x51B3,0x9A71,0x52A8,0x5D29,0x6E83) + "," + (ZH 0x9ED1,0x5C4F) + (ZH 0x4EE5,0x53CA) + (ZH 0x5361,0x987F,0x7B49,0x6700,0x5E38,0x89C1,0x95EE,0x9898) + "." + (ZH 0x5B83,0x4F1A,0x7981,0x7528) + " ULPS" + "," + "Multi-Plane Overlay " + (ZH 0x548C) + " HDCP" + "," + (ZH 0x5E76,0x5EF6,0x957F,0x9A71,0x52A8,0x8D85,0x65F6,0x65F6,0x95F4) + "," + (ZH 0x5E76,0x5173,0x95ED) + " Fast Startup/" + (ZH 0x4F11,0x7720) + (ZH 0x548C) + " AMD Crash Defender " + (ZH 0x670D,0x52A1) + "," + (ZH 0x5E76,0x4FEE,0x590D) + " Chrome/Edge/Electron " + (ZH 0x5E94,0x7528) + "(Discord" + "," + "Spotify)" + (ZH 0x4E2D,0x56E0,0x663E,0x5361,0x786C,0x4EF6,0x52A0,0x901F,0x5BFC,0x81F4,0x7684,0x95EA,0x70C1,0x95EE,0x9898) + "," + (ZH 0x5E76,0x89E3,0x9501) + " Windows " + (ZH 0x9690,0x85CF,0x7684,0x6781,0x9650,0x6027,0x80FD,0x7535,0x6E90,0x8BA1,0x5212) + "." + (ZH 0x5728,0x8FDB,0x884C,0x4EFB,0x4F55,0x66F4,0x6539,0x524D) + "," + (ZH 0x5B83,0x4F1A,0x521B,0x5EFA,0x6CE8,0x518C,0x8868,0x5907,0x4EFD) + (ZH 0x5E76,0x5728,0x53EF,0x80FD,0x7684,0x60C5,0x51B5,0x4E0B,0x521B,0x5EFA,0x7CFB,0x7EDF,0x8FD8,0x539F,0x70B9) + "," + (ZH 0x6240,0x6709,0x66F4,0x6539,0x90FD,0x53EF,0x4EE5,0x5728,0x5176,0x81EA,0x8EAB,0x754C,0x9762,0x4E2D,0x64A4,0x9500) + "."
    BtnRunAmdOptimizer   = (ZH 0x8FD0,0x884C) + " AMD Stability Optimizer"

    TxtMassgraveTitle = "Windows " + (ZH 0x548C) + " Office " + (ZH 0x6FC0,0x6D3B) + " (MAS)"
    TxtMassgraveDesc  = (ZH 0x8FD0,0x884C) + " Microsoft Activation Scripts (MASSGRAVE) " + (ZH 0x5B98,0x65B9,0x9879,0x76EE) + "," + (ZH 0x662F,0x793E,0x533A,0x77E5,0x540D,0x7684,0x5F00,0x6E90,0x5DE5,0x5177) + "," + (ZH 0x7528,0x4E8E,0x901A,0x8FC7) + " HWID" + "," + "KMS38 " + (ZH 0x6216) + (ZH 0x5728,0x7EBF) + " KMS " + (ZH 0x6FC0,0x6D3B) + " Windows " + (ZH 0x548C) + " Microsoft Office" + "." + (ZH 0x5B83,0x4F1A,0x5728,0x65B0,0x7684,0x63A7,0x5236,0x53F0,0x7A97,0x53E3,0x4E2D,0x6253,0x5F00,0x4E00,0x4E2A,0x4EA4,0x4E92,0x5F0F,0x6587,0x672C,0x83DC,0x5355) + "," + (ZH 0x53EA,0x9700,0x6309,0x7167,0x5C4F,0x5E55,0x4E0A,0x7684,0x9009,0x9879,0x9009,0x62E9,0x6240,0x9700,0x7684,0x6FC0,0x6D3B,0x65B9,0x5F0F,0x5373,0x53EF) + "."
    BtnRunMassgrave   = (ZH 0x8FD0,0x884C) + (ZH 0x6FC0,0x6D3B) + (ZH 0x811A,0x672C)

    LogExtScriptStart    = (ZH 0x6B63,0x5728,0x542F,0x52A8,0x5916,0x90E8,0x811A,0x672C) + ": {0}..."
    LogExtScriptLaunched = "{0} " + (ZH 0x5DF2,0x5728,0x65B0,0x7A97,0x53E3,0x4E2D,0x542F,0x52A8) + "," + (ZH 0x8BF7,0x6309,0x7167,0x5176,0x4E2D,0x663E,0x793A,0x7684,0x8BF4,0x660E,0x64CD,0x4F5C) + "."
    LogExtScriptError    = (ZH 0x542F,0x52A8) + " {0} " + (ZH 0x65F6,0x51FA,0x9519) + ": {1}"

    LogHeader         = (ZH 0x8FD0,0x884C) + (ZH 0x65E5,0x5FD7)
    AppFirefoxDesc    = (ZH 0x5F3A,0x70C8,0x63A8,0x8350) + (ZH 0x7684,0x6D4F,0x89C8,0x5668) + "," + (ZH 0x4E0D,0x4F7F,0x7528) + " Chromium " + (ZH 0x5F15,0x64CE) + "," + (ZH 0x63D0,0x4F9B) + (ZH 0x771F,0x6B63,0x7684) + (ZH 0x9690,0x79C1) + (ZH 0x4FDD,0x62A4)
    AppNanaZipDesc    = (ZH 0x8F7B,0x91CF,0x7EA7) + (ZH 0x6587,0x4EF6) + (ZH 0x538B,0x7F29) + (ZH 0x5DE5,0x5177) + "," + (ZH 0x96C6,0x6210) + " Windows 11 " + (ZH 0x53F3,0x952E,0x83DC,0x5355)
    AppNppDesc        = (ZH 0x5FEB,0x901F) + "," + (ZH 0x8F7B,0x91CF,0x7EA7) + (ZH 0x6587,0x672C) + (ZH 0x7F16,0x8F91,0x5668)
    AppFdmDesc        = (ZH 0x5F3A,0x5927) + (ZH 0x7684,0x4E0B,0x8F7D) + (ZH 0x7BA1,0x7406,0x5668)
    AppQbtDesc        = (ZH 0x5F00,0x6E90) + " BitTorrent " + (ZH 0x5BA2,0x6237,0x7AEF) + "," + (ZH 0x65E0) + (ZH 0x5E7F,0x544A) + (ZH 0x548C) + (ZH 0x81C3,0x80BF,0x8F6F,0x4EF6)
    AppSteamDesc      = "Valve " + (ZH 0x6570,0x5B57) + (ZH 0x6E38,0x620F) + (ZH 0x5546,0x5E97)
    AppEpicDesc       = "Epic Games " + (ZH 0x6570,0x5B57) + (ZH 0x5546,0x5E97)
    AppGogDesc        = (ZH 0x65E0) + " DRM " + (ZH 0x6570,0x5B57) + (ZH 0x6E38,0x620F) + (ZH 0x5546,0x5E97)
    AppSevenZipDesc   = (ZH 0x514D,0x8D39) + (ZH 0x5F00,0x6E90) + (ZH 0x7684) + (ZH 0x6587,0x4EF6,0x538B,0x7F29,0x5DE5,0x5177) + "," + (ZH 0x538B,0x7F29,0x7387) + (ZH 0x6781,0x9AD8)
    AppWiztreeDesc    = (ZH 0x901F,0x5EA6,0x6781,0x5FEB) + (ZH 0x7684) + (ZH 0x78C1,0x76D8,0x7A7A,0x95F4,0x5206,0x6790,0x5DE5,0x5177) + "," + (ZH 0x662F) + " WinDirStat " + (ZH 0x7684,0x66FF,0x4EE3,0x54C1)
    AppMemreductDesc  = (ZH 0x8F7B,0x91CF,0x7EA7) + (ZH 0x5B9E,0x65F6) + (ZH 0x5185,0x5B58,0x76D1,0x63A7,0x4E0E,0x6E05,0x7406,0x5DE5,0x5177)
    AppBleachbitDesc  = (ZH 0x514D,0x8D39) + (ZH 0x5F00,0x6E90) + (ZH 0x5DE5,0x5177) + "," + (ZH 0x7528,0x4E8E,0x6E05,0x7406,0x78C1,0x76D8,0x5783,0x573E,0x5E76,0x4FDD,0x62A4,0x9690,0x79C1)
    AppMoonlightDesc  = (ZH 0x5F00,0x6E90,0x6E38,0x620F,0x4E32,0x6D41,0x5BA2,0x6237,0x7AEF) + "," + (ZH 0x7528,0x4E8E,0x8FDE,0x63A5) + " Sunshine " + (ZH 0x6216) + " NVIDIA GameStream " + (ZH 0x4E3B,0x673A)
    AppSunshineDesc   = (ZH 0x81EA,0x6258,0x7BA1,0x7684,0x5F00,0x6E90,0x6E38,0x620F,0x4E32,0x6D41,0x4E3B,0x673A) + "," + (ZH 0x914D,0x5408) + " Moonlight " + (ZH 0x4F7F,0x7528) + "," + (ZH 0x652F,0x6301) + " GPU " + (ZH 0x786C,0x4EF6,0x52A0,0x901F,0x7F16,0x7801) + "," + (ZH 0x5EF6,0x8FDF,0x6781,0x4F4E)
    MsgReady          = (ZH 0x5C31,0x7EEA)
    MsgDone           = (ZH 0x5B8C,0x6210)

    GrpExtraPrivacy    = (ZH 0x9644,0x52A0) + (ZH 0x9065,0x6D4B) + (ZH 0x963B,0x6B62)
    ChkAdvertisingId   = (ZH 0x7981,0x7528) + (ZH 0x5E7F,0x544A) + "ID" + " (" + (ZH 0x4E2A,0x6027,0x5316) + (ZH 0x5E7F,0x544A) + ")"
    ChkTailoredExp     = (ZH 0x7981,0x7528) + (ZH 0x4E2A,0x6027,0x5316) + (ZH 0x4F53,0x9A8C) + "/Windows" + (ZH 0x5EFA,0x8BAE)
    ChkDiagTrackSvc    = (ZH 0x7981,0x7528) + " Connected User Experiences and Telemetry (DiagTrack) " + (ZH 0x548C) + " dmwappushservice " + (ZH 0x670D,0x52A1)
    ChkCopilotBlock    = (ZH 0x901A,0x8FC7) + (ZH 0x7B56,0x7565) + (ZH 0x963B,0x6B62) + " Copilot" + "," + "Recall " + (ZH 0x548C) + "AI" + (ZH 0x6570,0x636E,0x5206,0x6790)
    ChkInputTelemetry  = (ZH 0x7981,0x7528) + (ZH 0x8F93,0x5165) + (ZH 0x4E2A,0x6027,0x5316) + (ZH 0x548C) + (ZH 0x526A,0x8D34,0x677F) + (ZH 0x4E91) + (ZH 0x540C,0x6B65)

    LogRestoreTry      = (ZH 0x6B63,0x5728) + (ZH 0x521B,0x5EFA) + (ZH 0x7CFB,0x7EDF) + (ZH 0x8FD8,0x539F,0x70B9)
    LogRestoreOk       = (ZH 0x8FD8,0x539F,0x70B9) + (ZH 0x521B,0x5EFA) + (ZH 0x6210,0x529F)
    LogRestoreFail     = (ZH 0x521B,0x5EFA) + (ZH 0x8FD8,0x539F,0x70B9) + (ZH 0x5931,0x8D25) + ": {0}"
    LogRestoreHint     = (ZH 0x8BF7,0x68C0,0x67E5) + (ZH 0x7CFB,0x7EDF,0x4FDD,0x62A4) + (ZH 0x662F,0x5426) + (ZH 0x5DF2,0x542F,0x7528) + " (SystemPropertiesProtection.exe)"
    LogBloatStart      = (ZH 0x5F00,0x59CB) + (ZH 0x5220,0x9664) + (ZH 0x81C3,0x80BF,0x8F6F,0x4EF6) + "/AI" + (ZH 0x5E94,0x7528)
    LogBloatUserRemoved = (ZH 0x5DF2,0x5220,0x9664) + " (" + (ZH 0x7528,0x6237) + "): {0}"
    LogBloatProvRemoved = (ZH 0x5DF2,0x5220,0x9664) + " (" + (ZH 0x9884,0x7F6E) + "): {0}"
    LogBloatError      = (ZH 0x5220,0x9664) + " {0} " + (ZH 0x51FA,0x9519) + ": {1}"
    LogBloatDone       = (ZH 0x81C3,0x80BF,0x8F6F,0x4EF6) + (ZH 0x5220,0x9664) + (ZH 0x5B8C,0x6210)
    LogSearchStart     = (ZH 0x6B63,0x5728) + (ZH 0x914D,0x7F6E) + (ZH 0x672C,0x5730) + (ZH 0x641C,0x7D22)
    LogSearchOk        = (ZH 0x672C,0x5730) + (ZH 0x641C,0x7D22) + (ZH 0x5DF2,0x5E94,0x7528)
    LogSearchError     = (ZH 0x914D,0x7F6E) + (ZH 0x641C,0x7D22) + (ZH 0x51FA,0x9519) + ": {0}"
    LogVisualStart     = (ZH 0x6B63,0x5728) + (ZH 0x5E94,0x7528) + (ZH 0x89C6,0x89C9,0x6548,0x679C)
    LogVisualOk        = (ZH 0x89C6,0x89C9,0x6548,0x679C) + (ZH 0x5DF2,0x5E94,0x7528)
    LogVisualError     = (ZH 0x5E94,0x7528) + (ZH 0x89C6,0x89C9,0x6548,0x679C) + (ZH 0x51FA,0x9519) + ": {0}"
    LogPrivacyStart    = (ZH 0x6B63,0x5728) + (ZH 0x5E94,0x7528) + (ZH 0x9690,0x79C1) + (ZH 0x7B56,0x7565)
    LogPrivacyOk       = (ZH 0x9690,0x79C1) + (ZH 0x7B56,0x7565) + (ZH 0x5DF2,0x5E94,0x7528)
    LogPrivacyError    = (ZH 0x5E94,0x7528) + (ZH 0x9690,0x79C1) + (ZH 0x7B56,0x7565) + (ZH 0x51FA,0x9519) + ": {0}"
    LogExtraStart      = (ZH 0x6B63,0x5728) + (ZH 0x5E94,0x7528) + (ZH 0x9644,0x52A0) + (ZH 0x9065,0x6D4B) + (ZH 0x963B,0x6B62) + (ZH 0x9009,0x9879)
    LogExtraAdvOk      = (ZH 0x5E7F,0x544A) + "ID " + (ZH 0x5DF2,0x7981,0x7528)
    LogExtraTailoredOk = (ZH 0x4E2A,0x6027,0x5316) + (ZH 0x4F53,0x9A8C) + (ZH 0x5DF2,0x7981,0x7528)
    LogExtraDiagTrackOk = "DiagTrack " + (ZH 0x548C) + " dmwappushservice " + (ZH 0x5DF2,0x505C,0x6B62) + (ZH 0x5E76) + (ZH 0x7981,0x7528)
    LogExtraCopilotOk  = "Copilot" + "/Recall " + (ZH 0x5DF2,0x963B,0x6B62)
    LogExtraInputOk    = (ZH 0x8F93,0x5165) + (ZH 0x4E2A,0x6027,0x5316) + (ZH 0x5DF2,0x7981,0x7528)
    LogExtraError      = (ZH 0x5E94,0x7528) + (ZH 0x9644,0x52A0) + (ZH 0x9009,0x9879) + " ({0}) " + (ZH 0x51FA,0x9519) + ": {1}"
    LogExtraDone       = (ZH 0x9644,0x52A0) + (ZH 0x9065,0x6D4B) + (ZH 0x963B,0x6B62) + (ZH 0x5B8C,0x6210)

    GrpAdvancedTweaks   = (ZH 0x9AD8,0x7EA7) + (ZH 0x7CFB,0x7EDF) + (ZH 0x8C03,0x4F18)
    ChkDiagTrackFull    = (ZH 0x7981,0x7528) + (ZH 0x9065,0x6D4B) + " (DiagTrack " + (ZH 0x670D,0x52A1) + "+" + (ZH 0x6CE8,0x518C,0x8868) + (ZH 0x7B56,0x7565) + ")"
    ChkEdgeWidgets      = (ZH 0x7981,0x7528) + " Edge " + (ZH 0x9884,0x52A0,0x8F7D) + (ZH 0x548C) + " Widgets"
    ChkDeliveryOpt      = (ZH 0x7981,0x7528) + (ZH 0x4F20,0x9001,0x4F18,0x5316) + " (P2P)"
    ChkAppsBackground   = (ZH 0x6302,0x8D77) + " UWP " + (ZH 0x540E,0x53F0) + (ZH 0x8FD0,0x884C) + (ZH 0x7A0B,0x5E8F)
    ChkNetworkLatency   = (ZH 0x7F51,0x7EDC) + (ZH 0x4F18,0x5316) + "/" + (ZH 0x964D,0x4F4E) + (ZH 0x5EF6,0x8FDF) + " (TCP/IP)"

    LogAdvStart            = (ZH 0x6B63,0x5728) + (ZH 0x5E94,0x7528) + (ZH 0x9AD8,0x7EA7) + (ZH 0x7CFB,0x7EDF) + (ZH 0x8C03,0x4F18) + "..."
    LogAdvDiagTrackOk      = (ZH 0x9065,0x6D4B) + (ZH 0x5DF2,0x7981,0x7528) + " (DiagTrack " + (ZH 0x670D,0x52A1) + (ZH 0x5DF2,0x505C,0x6B62,0x5E76,0x7981,0x7528) + ", AllowTelemetry=0)"
    LogAdvEdgeWidgetsOk    = " Edge " + (ZH 0x9884,0x52A0,0x8F7D) + "/" + (ZH 0x540E,0x53F0) + (ZH 0x548C) + " Widgets " + (ZH 0x5DF2,0x7981,0x7528)
    LogAdvDeliveryOptOk    = (ZH 0x4F20,0x9001,0x4F18,0x5316) + (ZH 0x5DF2,0x8BBE,0x7F6E) + (ZH 0x4EC5) + " HTTP (P2P " + (ZH 0x5DF2,0x7981,0x7528) + ")"
    LogAdvAppsBackgroundOk = "UWP " + (ZH 0x5E94,0x7528) + (ZH 0x5DF2,0x7981,0x6B62) + (ZH 0x540E,0x53F0) + (ZH 0x8FD0,0x884C)
    LogAdvNetworkOk        = (ZH 0x7F51,0x7EDC) + (ZH 0x9650,0x901F) + (ZH 0x5DF2,0x7981,0x7528) + "; " + (ZH 0x5728) + " {0} " + (ZH 0x4E2A,0x6D3B,0x52A8,0x63A5,0x53E3) + (ZH 0x8C03,0x6574) + " TCP ack/nodelay"
    LogAdvError            = (ZH 0x5E94,0x7528) + (ZH 0x9AD8,0x7EA7) + (ZH 0x8C03,0x4F18) + (ZH 0x51FA,0x9519) + " ({0}): {1}"
    LogAdvDone             = (ZH 0x9AD8,0x7EA7) + (ZH 0x7CFB,0x7EDF) + (ZH 0x8C03,0x4F18) + (ZH 0x5B8C,0x6210)

    GrpMoreOptimizations = (ZH 0x7CFB,0x7EDF,0x6E05,0x7406,0x4E0E,0x6027,0x80FD)
    ChkHibernation       = (ZH 0x7981,0x7528,0x4F11,0x7720) + " (" + (ZH 0x91CA,0x653E) + " hiberfil.sys " + (ZH 0x78C1,0x76D8,0x7A7A,0x95F4) + ")"
    ChkPowerPlan         = (ZH 0x5C06,0x7535,0x6E90,0x8BA1,0x5212,0x8BBE,0x7F6E,0x4E3A,0x9AD8,0x6027,0x80FD)
    ChkTempCleanup       = (ZH 0x6E05,0x7406,0x4E34,0x65F6,0x6587,0x4EF6) + "," + (ZH 0x65E7,0x7684,0x9884,0x8BFB,0x53D6,0x6587,0x4EF6) + "," + "Windows.old " + (ZH 0x4EE5,0x53CA) + " Windows " + (ZH 0x66F4,0x65B0,0x7F13,0x5B58)
    ChkHotCorners        = (ZH 0x7981,0x7528) + (ZH 0x8D34,0x9760,0x8F85,0x52A9) + "/" + (ZH 0x6447,0x52A8,0x6700,0x5C0F,0x5316)
    ChkRecallBlock       = (ZH 0x7981,0x7528) + " Windows Recall"
    ChkBootTimeout       = (ZH 0x5C06,0x542F,0x52A8,0x83DC,0x5355,0x8D85,0x65F6,0x65F6,0x95F4,0x7F29,0x77ED,0x4E3A) + " 5 " + (ZH 0x79D2)
    ChkOfficeTelemetry   = (ZH 0x963B,0x6B62) + " Office " + (ZH 0x548C) + " OneDrive " + (ZH 0x9065,0x6D4B)
    ChkExtraSchedTasks   = (ZH 0x5220,0x9664) + (ZH 0x5176,0x4ED6,0x9065,0x6D4B,0x8BA1,0x5212,0x4EFB,0x52A1)
    ChkDiskOptimize      = (ZH 0x81EA,0x52A8,0x68C0,0x6D4B) + (ZH 0x78C1,0x76D8) + " (SSD/HDD) " + (ZH 0x5E76,0x914D,0x7F6E) + " TRIM " + (ZH 0x6216) + (ZH 0x8BA1,0x5212,0x788E,0x7247,0x6574,0x7406)
    ChkHagsGameMode      = (ZH 0x542F,0x7528) + (ZH 0x6E38,0x620F,0x6A21,0x5F0F) + (ZH 0x548C) + (ZH 0x786C,0x4EF6,0x52A0,0x901F) + "GPU" + (ZH 0x8C03,0x5EA6) + " (HAGS)"
    ChkUltimatePerf      = (ZH 0x542F,0x7528) + (ZH 0x6781,0x9650,0x6027,0x80FD) + (ZH 0x7535,0x6E90,0x8BA1,0x5212) + "," + "CPU " + (ZH 0x6700,0x4F4E,0x72B6,0x6001) + (ZH 0x8BBE,0x4E3A) + " 100%"
    ChkDryRun            = (ZH 0x6A21,0x62DF,0x8FD0,0x884C,0x6A21,0x5F0F) + " (" + (ZH 0x4EC5,0x8BB0,0x5F55,0x5C06,0x8981,0x66F4,0x6539,0x7684,0x5185,0x5BB9,0x800C,0x4E0D,0x5B9E,0x9645,0x5E94,0x7528) + ")"
    BtnRestoreDefaults   = (ZH 0x6062,0x590D,0x9ED8,0x8BA4,0x8BBE,0x7F6E)
    BtnExportProfile     = (ZH 0x5BFC,0x51FA,0x914D,0x7F6E,0x6587,0x4EF6)
    BtnImportProfile     = (ZH 0x5BFC,0x5165,0x914D,0x7F6E,0x6587,0x4EF6)

    LogMoreStart              = (ZH 0x6B63,0x5728) + (ZH 0x5E94,0x7528) + (ZH 0x7CFB,0x7EDF,0x6E05,0x7406,0x4E0E,0x6027,0x80FD) + (ZH 0x8C03,0x6574) + "..."
    LogHibernationOk          = (ZH 0x4F11,0x7720) + (ZH 0x5DF2,0x7981,0x7528) + " (" + (ZH 0x5DF2,0x5220,0x9664) + " hiberfil.sys)"
    LogPowerPlanOk            = (ZH 0x7535,0x6E90,0x8BA1,0x5212) + (ZH 0x5DF2,0x8BBE,0x7F6E,0x4E3A,0x9AD8,0x6027,0x80FD)
    LogTempCleanupOk          = (ZH 0x4E34,0x65F6,0x6587,0x4EF6) + "," + (ZH 0x65E7,0x7684,0x9884,0x8BFB,0x53D6,0x6761,0x76EE) + ", Windows.old " + (ZH 0x548C) + " Windows " + (ZH 0x66F4,0x65B0,0x7F13,0x5B58) + (ZH 0x5DF2,0x6E05,0x7406)
    LogHotCornersOk           = (ZH 0x8D34,0x9760,0x8F85,0x52A9) + (ZH 0x548C) + (ZH 0x6447,0x52A8,0x6700,0x5C0F,0x5316) + (ZH 0x5DF2,0x7981,0x7528)
    LogRecallBlockOk          = "Windows Recall " + (ZH 0x5DF2,0x901A,0x8FC7,0x7B56,0x7565,0x7981,0x7528)
    LogBootTimeoutOk          = (ZH 0x542F,0x52A8,0x83DC,0x5355,0x8D85,0x65F6,0x65F6,0x95F4) + (ZH 0x5DF2,0x8BBE,0x7F6E,0x4E3A) + " 5 " + (ZH 0x79D2)
    LogOfficeTelemetryOk      = "Office " + (ZH 0x548C) + " OneDrive " + (ZH 0x9065,0x6D4B) + (ZH 0x5DF2,0x963B,0x6B62)
    LogExtraSchedTasksOk      = (ZH 0x5176,0x4ED6,0x9065,0x6D4B,0x8BA1,0x5212,0x4EFB,0x52A1) + (ZH 0x5DF2,0x7981,0x7528)
    LogDiskOptimizeOk         = (ZH 0x78C1,0x76D8,0x4F18,0x5316) + (ZH 0x5DF2,0x5E94,0x7528) + ": {0}"
    LogHagsGameModeOk         = (ZH 0x6E38,0x620F,0x6A21,0x5F0F) + (ZH 0x548C) + (ZH 0x786C,0x4EF6,0x52A0,0x901F) + "GPU" + (ZH 0x8C03,0x5EA6) + " (HAGS) " + (ZH 0x5DF2,0x542F,0x7528) + "." + (ZH 0x5EFA,0x8BAE) + (ZH 0x91CD,0x542F) + (ZH 0x4EE5,0x4F7F) + " HAGS " + (ZH 0x751F,0x6548) + "."
    LogUltimatePerfOk         = (ZH 0x6781,0x9650,0x6027,0x80FD) + (ZH 0x7535,0x6E90,0x8BA1,0x5212) + (ZH 0x5DF2,0x542F,0x7528) + (ZH 0x5E76) + (ZH 0x8BBE,0x4E3A) + (ZH 0x9ED8,0x8BA4) + "," + "CPU " + (ZH 0x6700,0x4F4E,0x72B6,0x6001) + (ZH 0x8BBE,0x4E3A) + " 100% (" + (ZH 0x4EA4,0x6D41) + (ZH 0x548C) + (ZH 0x7535,0x6C60) + ")."
    LogMoreError              = (ZH 0x5E94,0x7528) + (ZH 0x8C03,0x6574) + (ZH 0x65F6,0x51FA,0x9519) + " ({0}): {1}"
    LogMoreDone               = (ZH 0x7CFB,0x7EDF,0x6E05,0x7406,0x4E0E,0x6027,0x80FD) + (ZH 0x8C03,0x6574) + (ZH 0x5B8C,0x6210)

    LogRestoreDefaultsStart = (ZH 0x6B63,0x5728) + (ZH 0x6062,0x590D) + (ZH 0x6CE8,0x518C,0x8868) + (ZH 0x548C) + (ZH 0x670D,0x52A1) + (ZH 0x7684) + (ZH 0x9ED8,0x8BA4,0x8BBE,0x7F6E) + "..."
    LogRestoreDefaultsOk    = (ZH 0x9ED8,0x8BA4,0x8BBE,0x7F6E) + (ZH 0x5DF2,0x6210,0x529F,0x6062,0x590D) + "," + (ZH 0x5EFA,0x8BAE,0x91CD,0x65B0,0x542F,0x52A8)
    LogRestoreDefaultsError = (ZH 0x6062,0x590D) + (ZH 0x9ED8,0x8BA4,0x8BBE,0x7F6E) + (ZH 0x65F6,0x51FA,0x9519) + ": {0}"

    LogExportStart     = (ZH 0x6B63,0x5728) + (ZH 0x5BFC,0x51FA) + (ZH 0x5F53,0x524D) + (ZH 0x914D,0x7F6E,0x6587,0x4EF6) + "..."
    LogExportOk        = (ZH 0x914D,0x7F6E,0x6587,0x4EF6) + (ZH 0x5DF2,0x5BFC,0x51FA,0x5230) + ": {0}"
    LogExportError     = (ZH 0x5BFC,0x51FA) + (ZH 0x914D,0x7F6E,0x6587,0x4EF6) + (ZH 0x65F6,0x51FA,0x9519) + ": {0}"
    LogExportCancelled = (ZH 0x7528,0x6237) + (ZH 0x5DF2,0x53D6,0x6D88) + (ZH 0x5BFC,0x51FA,0x914D,0x7F6E,0x6587,0x4EF6)

    LogImportStart     = (ZH 0x6B63,0x5728) + (ZH 0x5BFC,0x5165) + (ZH 0x914D,0x7F6E,0x6587,0x4EF6) + "..."
    LogImportOk        = (ZH 0x914D,0x7F6E,0x6587,0x4EF6) + (ZH 0x5DF2,0x4ECE,0x4EE5,0x4E0B,0x4F4D,0x7F6E,0x5BFC,0x5165) + ": {0}"
    LogImportError     = (ZH 0x5BFC,0x5165) + (ZH 0x914D,0x7F6E,0x6587,0x4EF6) + (ZH 0x65F6,0x51FA,0x9519) + ": {0}"
    LogImportCancelled = (ZH 0x7528,0x6237) + (ZH 0x5DF2,0x53D6,0x6D88) + (ZH 0x5BFC,0x5165,0x914D,0x7F6E,0x6587,0x4EF6)

    LogDryRunPrefix = "[" + (ZH 0x6A21,0x62DF,0x8FD0,0x884C) + "] " + (ZH 0x5C06,0x5E94,0x7528) + ": {0}"
    LogDryRunNote   = (ZH 0x6A21,0x62DF,0x8FD0,0x884C,0x6A21,0x5F0F,0x5DF2,0x542F,0x7528) + "," + (ZH 0x4E0D,0x4F1A,0x8FDB,0x884C,0x4EFB,0x4F55,0x66F4,0x6539) + "," + (ZH 0x4EC5,0x8BB0,0x5F55,0x5230,0x65E5,0x5FD7,0x4E2D)

    LogDriversStart    = (ZH 0x6B63,0x5728) + (ZH 0x963B,0x6B62) + (ZH 0x81EA,0x52A8) + (ZH 0x9A71,0x52A8,0x7A0B,0x5E8F) + (ZH 0x5B89,0x88C5)
    LogDriversOk       = (ZH 0x9A71,0x52A8,0x7A0B,0x5E8F) + (ZH 0x81EA,0x52A8) + (ZH 0x5B89,0x88C5) + (ZH 0x5DF2,0x963B,0x6B62)
    LogDriversError    = (ZH 0x963B,0x6B62) + (ZH 0x9A71,0x52A8,0x7A0B,0x5E8F) + (ZH 0x51FA,0x9519) + ": {0}"
    LogPagefileRam     = (ZH 0x68C0,0x6D4B) + " RAM: {0} MB" + "," + (ZH 0x8BA1,0x7B97) + " pagefile " + (ZH 0x5927,0x5C0F) + ": {1} MB"
    LogPagefileOk      = "Pagefile " + (ZH 0x914D,0x7F6E) + (ZH 0x6210,0x529F) + ": {0} MB"
    LogPagefileError   = (ZH 0x914D,0x7F6E) + " pagefile " + (ZH 0x51FA,0x9519) + ": {0}"
    LogChocoSearching = (ZH 0x6B63,0x5728) + (ZH 0x68C0,0x67E5) + " Chocolatey " + (ZH 0x662F,0x5426) + (ZH 0x5DF2,0x5B89,0x88C5)
    LogChocoFound     = "Chocolatey " + (ZH 0x4F4D,0x7F6E) + ": {0}"
    LogChocoNotFound  = (ZH 0x65E0,0x6CD5) + (ZH 0x81EA,0x52A8) + (ZH 0x5B89,0x88C5) + " Chocolatey" + "," + (ZH 0x8BF7,0x8BBF,0x95EE) + " https://chocolatey.org/install " + (ZH 0x624B,0x52A8) + (ZH 0x5B89,0x88C5)
    LogChocoInstalling      = (ZH 0x672A,0x627E,0x5230) + " Chocolatey" + "," + (ZH 0x6B63,0x5728) + (ZH 0x81EA,0x52A8) + (ZH 0x5B89,0x88C5) + "..."
    LogChocoInstallOk = "Chocolatey " + (ZH 0x5B89,0x88C5) + (ZH 0x6210,0x529F)
    LogChocoInstallFailed = "Chocolatey " + (ZH 0x5B89,0x88C5) + (ZH 0x5931,0x8D25) + ": {0}"
    LogInstallStart    = (ZH 0x5F00,0x59CB) + (ZH 0x5B89,0x88C5) + ": {0} ({1})..."
    LogTryingWinget       = (ZH 0x6B63,0x5728,0x5C1D,0x8BD5) + " winget " + (ZH 0x5B89,0x88C5) + " {0}..."
    LogWingetFailedFallback = "winget " + (ZH 0x65E0,0x6CD5,0x5B89,0x88C5) + " {0} ({1})" + "," + (ZH 0x6539,0x7528) + " Chocolatey..."
    LogWingetNotAvailable  = "winget " + (ZH 0x5BF9) + " {0} " + (ZH 0x4E0D,0x53EF,0x7528) + "," + (ZH 0x6539,0x7528) + " Chocolatey..."
    LogInstallOk       = "{0} " + (ZH 0x5B89,0x88C5) + (ZH 0x6210,0x529F)
    LogInstallAlready  = "{0} " + (ZH 0x5DF2) + (ZH 0x5B89,0x88C5)
    LogInstallWarn     = "{0} " + (ZH 0x8FD4,0x56DE) + (ZH 0x9000,0x51FA) + (ZH 0x4EE3,0x7801) + " {1}" + "," + (ZH 0x8BF7,0x67E5,0x770B) + (ZH 0x65E5,0x5FD7) + " {2}"
    LogInstallError    = (ZH 0x5B89,0x88C5) + " {0} " + (ZH 0x51FA,0x9519) + ": {1}"
    LogLangChanged     = (ZH 0x8BED,0x8A00) + (ZH 0x5DF2,0x66F4,0x6539) + (ZH 0x4E3A) + " {0}"
    LogOptStart        = "======== " + (ZH 0x5F00,0x59CB) + (ZH 0x6267,0x884C) + (ZH 0x4F18,0x5316) + " ========"
    LogOptDone         = "======== " + (ZH 0x6267,0x884C) + (ZH 0x5B8C,0x6210) + " ========"
    LogInstallBatchStart = "======== " + (ZH 0x5F00,0x59CB) + (ZH 0x5B89,0x88C5) + (ZH 0x5E94,0x7528) + " ========"
    LogInstallBatchDone  = "======== " + (ZH 0x5B89,0x88C5) + (ZH 0x5B8C,0x6210) + " ========"
    LogNoAppsSelected  = (ZH 0x672A,0x9009,0x62E9) + (ZH 0x4EFB,0x4F55) + (ZH 0x5E94,0x7528)
    TxtChocoRequired   = (ZH 0x4E0B,0x9762,0x7684,0x5E94,0x7528,0x4F1A,0x5C3D,0x91CF) + " winget " + (ZH 0x81EA,0x52A8,0x5B89,0x88C5) + "," + (ZH 0x82E5,0x627E,0x4E0D,0x5230,0x5219,0x81EA,0x52A8,0x6539,0x7528) + " Chocolatey" + "," + (ZH 0x8BF7,0x5148,0x4E8E,0x4E0B,0x65B9,0x5907,0x7528,0x5B89,0x88C5)
    ChocoStatusFound   = "Chocolatey " + (ZH 0x5DF2,0x5B89,0x88C5) + "," + (ZH 0x53EF,0x4EE5,0x5F00,0x59CB,0x5B89,0x88C5,0x4E0B,0x9762,0x7684,0x5E94,0x7528)
    ChocoStatusNotFound = (ZH 0x5C1A,0x672A,0x68C0,0x6D4B,0x5230) + " Chocolatey"
    BtnInstallChoco    = (ZH 0x5B89,0x88C5) + " Chocolatey"
    LogChocoRequiredFirst = "Chocolatey " + (ZH 0x672A,0x5B89,0x88C5) + "," + (ZH 0x8BF7,0x5148,0x70B9,0x51FB,0x4E0A,0x65B9,0x7684) + " " + (ZH 0x5B89,0x88C5) + " Chocolatey"
    LogUnhandledError      = (ZH 0x610F,0x5916,0x9519,0x8BEF) + ": {0}"
}

$Global:CurrentLangCode = "pt-BR"

# ============================================================================
# 3. XAML - GRAPHICAL INTERFACE
# ============================================================================

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WGO" Height="760" Width="920" WindowStartupLocation="CenterScreen"
        Background="#FF202020" FontFamily="Segoe UI">
    <Window.Resources>
        <!-- ================= FLUENT WIN11 DARK/BLUE PALETTE ================= -->
        <SolidColorBrush x:Key="BgDark" Color="#FF1A1B1E"/>
        <SolidColorBrush x:Key="BgPanel" Color="#FF232428"/>
        <SolidColorBrush x:Key="BgCard" Color="#FF2B2D31"/>
        <SolidColorBrush x:Key="BgCardHover" Color="#FF32353A"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#FF4CC2FF"/>
        <SolidColorBrush x:Key="AccentHoverBrush" Color="#FF75D2FF"/>
        <SolidColorBrush x:Key="AccentPressedBrush" Color="#FF2AA0DE"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#FFF3F4F6"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#FF9CA3AF"/>
        <SolidColorBrush x:Key="BorderBrush1" Color="#FF3A3C41"/>
        <SolidColorBrush x:Key="BorderAccentBrush" Color="#552EA6E0"/>

        <DropShadowEffect x:Key="CardShadow" Color="#FF000000" Direction="270" ShadowDepth="2" BlurRadius="14" Opacity="0.35"/>

        <!-- ================= BASE TEXT ================= -->
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
        </Style>

        <!-- ================= FLUENT TOGGLE-SWITCH CHECKBOX ================= -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,6,0,6"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Border x:Name="track" Grid.Column="0" Width="42" Height="22" CornerRadius="11"
                                    Background="#FF44464C" BorderBrush="#FF616469" BorderThickness="1" VerticalAlignment="Center">
                                <Ellipse x:Name="thumb" Width="15" Height="15" Fill="#FFE7E8EA" HorizontalAlignment="Left" Margin="3,0,0,0"/>
                            </Border>
                            <ContentPresenter Grid.Column="1" Margin="12,0,0,0" VerticalAlignment="Center" RecognizesAccessKey="True"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="track" Property="Background" Value="{StaticResource AccentBrush}"/>
                                <Setter TargetName="track" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                                <Setter TargetName="thumb" Property="HorizontalAlignment" Value="Right"/>
                                <Setter TargetName="thumb" Property="Margin" Value="0,0,3,0"/>
                                <Setter TargetName="thumb" Property="Fill" Value="#FF0B0B0B"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="track" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ================= GROUPBOX AS FLUENT SETTINGS CARD ================= -->
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Background" Value="{StaticResource BgPanel}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush1}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Margin" Value="0,0,0,12"/>
            <Setter Property="Padding" Value="18,14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="GroupBox">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="10" Effect="{StaticResource CardShadow}">
                            <StackPanel Margin="{TemplateBinding Padding}">
                                <TextBlock Text="{TemplateBinding Header}" FontSize="14" FontWeight="SemiBold"
                                           Foreground="{TemplateBinding Foreground}" Margin="0,0,0,10"/>
                                <ContentPresenter/>
                            </StackPanel>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ================= FLUENT ACCENT-FILL BUTTON (PRIMARY) ================= -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Foreground" Value="#FF0B0B0B"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="16,9"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{StaticResource AccentHoverBrush}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{StaticResource AccentPressedBrush}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Background" Value="#FF43454A"/>
                                <Setter Property="Foreground" Value="#FF8A8D92"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ================= SECONDARY (OUTLINE) BUTTON ================= -->
        <Style x:Key="SecondaryButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource AccentBrush}"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="16,9"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{StaticResource AccentBrush}" BorderThickness="1.4" CornerRadius="6">
                            <ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#1F4CC2FF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#334CC2FF"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#FF6C6F75"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#FF6C6F75"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ================= FLUENT SEGMENTED TABS ================= -->
        <Style TargetType="TabControl">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="{StaticResource TextSecondary}"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="18,10"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Grid>
                            <Border x:Name="bd" Background="Transparent" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <Border x:Name="indicator" Height="3" VerticalAlignment="Bottom" Background="{StaticResource AccentBrush}"
                                    CornerRadius="2" Opacity="0" Margin="18,0,18,0"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="indicator" Property="Opacity" Value="1"/>
                                <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
                                <Setter TargetName="bd" Property="Background" Value="#14FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ================= FLUENT COMBOBOX ================= -->
        <Style TargetType="ComboBoxItem">
            <Setter Property="Padding" Value="10,7"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="4" Padding="{TemplateBinding Padding}" Margin="3,1">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{StaticResource AccentBrush}"/>
                                <Setter Property="Foreground" Value="#FF0B0B0B"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="{StaticResource BgCard}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush1}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton x:Name="toggle" Background="Transparent" BorderThickness="0" Focusable="False" ClickMode="Press"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border Background="Transparent"/>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <Border x:Name="chrome" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" IsHitTestVisible="False">
                                <Grid Margin="{TemplateBinding Padding}">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="16"/>
                                    </Grid.ColumnDefinitions>
                                    <ContentPresenter Grid.Column="0" Content="{TemplateBinding SelectionBoxItem}" VerticalAlignment="Center"/>
                                    <Path Grid.Column="1" Data="M0,0 L6,6 L12,0" Stroke="{StaticResource TextSecondary}"
                                          StrokeThickness="1.6" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                                </Grid>
                            </Border>
                            <Popup x:Name="popup" IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom" AllowsTransparency="True" PopupAnimation="Fade">
                                <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource BorderBrush1}" BorderThickness="1"
                                        CornerRadius="8" Margin="0,4,0,0" Padding="2" Effect="{StaticResource CardShadow}"
                                        MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}">
                                    <ItemsPresenter/>
                                </Border>
                            </Popup>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="chrome" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ================= FLUENT CARD (App Installer items) ================= -->
        <Style x:Key="CardStyle" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource BgCard}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush1}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="14,12"/>
            <Setter Property="Margin" Value="0,5"/>
            <Setter Property="Effect" Value="{StaticResource CardShadow}"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{StaticResource BgCardHover}"/>
                    <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- ================= SLIM FLUENT SCROLLBAR ================= -->
        <Style x:Key="ScrollThumbStyle" TargetType="Thumb">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border Background="#FF56585E" CornerRadius="4" Margin="2,0"/>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="ScrollRepeatButtonStyle" TargetType="RepeatButton">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RepeatButton">
                        <Border Background="Transparent"/>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="10"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid>
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Style="{StaticResource ScrollRepeatButtonStyle}" Command="ScrollBar.PageUpCommand"/>
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource ScrollThumbStyle}"/>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Style="{StaticResource ScrollRepeatButtonStyle}" Command="ScrollBar.PageDownCommand"/>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <DockPanel Background="{StaticResource BgDark}">
        <!-- HEADER -->
        <Border DockPanel.Dock="Top" Padding="18,14" BorderBrush="{StaticResource AccentBrush}" BorderThickness="0,0,0,2">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#FF23262B" Offset="0"/>
                    <GradientStop Color="#FF1E2530" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="150"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Width="34" Height="34" CornerRadius="8" Margin="0,0,12,0">
                        <Border.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                <GradientStop Color="#FF4CC2FF" Offset="0"/>
                                <GradientStop Color="#FF1A6FBF" Offset="1"/>
                            </LinearGradientBrush>
                        </Border.Background>
                        <TextBlock Text="W" FontSize="17" FontWeight="Bold" Foreground="#FF0B0B0B" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock x:Name="txtAppTitle" Text="WGO - Windows General Optimizations" FontSize="17" FontWeight="Bold" VerticalAlignment="Center" Foreground="{StaticResource TextPrimary}"/>
                </StackPanel>
                <TextBlock x:Name="txtLblLanguage" Grid.Column="1" Text="Language:" VerticalAlignment="Center" Foreground="{StaticResource TextSecondary}" Margin="0,0,8,0"/>
                <ComboBox x:Name="cmbLanguage" Grid.Column="2" SelectedIndex="1">
                    <ComboBoxItem Content="en-US"/>
                    <ComboBoxItem Content="pt-BR"/>
                    <ComboBoxItem Content="es-ES"/>
                    <ComboBoxItem Content="zh-CN"/>
                </ComboBox>
            </Grid>
        </Border>

        <!-- LOG CONSOLE -->
        <Border DockPanel.Dock="Bottom" Background="#FF141517" BorderBrush="{StaticResource BorderBrush1}" BorderThickness="1"
                CornerRadius="10" Padding="14,10" Margin="14,0,14,14" Height="180" Effect="{StaticResource CardShadow}">
            <DockPanel>
                <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="0,0,0,8">
                    <Ellipse Width="8" Height="8" Fill="{StaticResource AccentBrush}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBlock x:Name="txtLogHeader" Text="Execution Log" Foreground="{StaticResource AccentBrush}" FontWeight="SemiBold" FontSize="13"/>
                </StackPanel>
                <ScrollViewer x:Name="scrollLog" VerticalScrollBarVisibility="Auto">
                    <TextBox x:Name="txtLog" Background="Transparent" Foreground="#FF7CE0C6" FontFamily="Cascadia Mono, Consolas" FontSize="12"
                             BorderThickness="0" IsReadOnly="True" TextWrapping="Wrap" AcceptsReturn="True"/>
                </ScrollViewer>
            </DockPanel>
        </Border>

        <!-- TABS -->
        <TabControl x:Name="tabMain" Background="{StaticResource BgDark}" Margin="10" BorderThickness="0">
            <TabItem x:Name="tabOptimizations" Header="Optimizations &amp; Privacy">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="10">

                        <CheckBox x:Name="chkSelectAll" Content="Select All / Deselect All" FontWeight="Bold" Margin="0,0,0,4" IsChecked="True"/>
                        <CheckBox x:Name="chkDryRun" Content="Dry Run (only log what would change, apply nothing)" Margin="0,0,0,10" IsChecked="False"/>

                        <GroupBox x:Name="grpRestore" Header="System Safety">
                            <StackPanel Orientation="Horizontal">
                                <Button x:Name="btnCreateRestore" Content="Create Restore Point" Style="{StaticResource SecondaryButtonStyle}"/>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox x:Name="grpBloat" Header="Bloatware Removal">
                            <CheckBox x:Name="chkBloat" Content="Remove bloatware / AI apps" IsChecked="True"/>
                        </GroupBox>

                        <GroupBox x:Name="grpSearch" Header="Start Menu Search">
                            <CheckBox x:Name="chkSearch" Content="Force 100% local search" IsChecked="True"/>
                        </GroupBox>

                        <GroupBox x:Name="grpVisual" Header="Visual Effects">
                            <CheckBox x:Name="chkVisual" Content="Apply custom performance visual effects profile" IsChecked="True"/>
                        </GroupBox>

                        <GroupBox x:Name="grpPrivacy" Header="Deep Privacy / Telemetry">
                            <CheckBox x:Name="chkPrivacy" Content="Block telemetry / WER / CEIP / Activity Feed / Location" IsChecked="True"/>
                        </GroupBox>

                        <GroupBox x:Name="grpDrivers" Header="Windows Update Drivers">
                            <CheckBox x:Name="chkDrivers" Content="Block automatic driver installation" IsChecked="True"/>
                        </GroupBox>

                        <GroupBox x:Name="grpPagefile" Header="Virtual Memory (Pagefile)">
                            <CheckBox x:Name="chkPagefile" Content="Set static pagefile size (RAM x 1.5)" IsChecked="True"/>
                        </GroupBox>

                        <GroupBox x:Name="grpExtraPrivacy" Header="Additional Telemetry Blocking">
                            <StackPanel>
                                <CheckBox x:Name="chkAdvertisingId" Content="Disable advertising ID" IsChecked="True"/>
                                <CheckBox x:Name="chkTailoredExp" Content="Disable tailored experiences / suggestions" IsChecked="True"/>
                                <CheckBox x:Name="chkDiagTrackSvc" Content="Disable DiagTrack / dmwappushservice" IsChecked="True"/>
                                <CheckBox x:Name="chkCopilotBlock" Content="Block Copilot / Recall / AI data analysis" IsChecked="True"/>
                                <CheckBox x:Name="chkInputTelemetry" Content="Disable input personalization / clipboard cloud sync" IsChecked="True"/>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox x:Name="grpAdvancedTweaks" Header="Advanced System Tweaks">
                            <StackPanel>
                                <CheckBox x:Name="chkDiagTrackFull" Content="Disable Telemetry (DiagTrack)" IsChecked="True"/>
                                <CheckBox x:Name="chkEdgeWidgets" Content="Disable Edge preload and Widgets" IsChecked="True"/>
                                <CheckBox x:Name="chkDeliveryOpt" Content="Disable Delivery Optimization (P2P)" IsChecked="True"/>
                                <CheckBox x:Name="chkAppsBackground" Content="Suspend UWP apps in background" IsChecked="True"/>
                                <CheckBox x:Name="chkNetworkLatency" Content="Network optimization / latency reduction (TCP-IP)" IsChecked="False"/>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox x:Name="grpMoreOptimizations" Header="System Cleanup &amp; Performance">
                            <StackPanel>
                                <CheckBox x:Name="chkHibernation" Content="Disable Hibernation" IsChecked="True"/>
                                <CheckBox x:Name="chkPowerPlan" Content="Set power plan to High Performance" IsChecked="True"/>
                                <CheckBox x:Name="chkTempCleanup" Content="Clean temp files / Prefetch / Windows.old / WU cache" IsChecked="True"/>
                                <CheckBox x:Name="chkHotCorners" Content="Disable Snap Assist / Aero Shake" IsChecked="False"/>
                                <CheckBox x:Name="chkRecallBlock" Content="Disable Windows Recall" IsChecked="True"/>
                                <CheckBox x:Name="chkBootTimeout" Content="Reduce boot menu timeout to 5s" IsChecked="False"/>
                                <CheckBox x:Name="chkOfficeTelemetry" Content="Block Office / OneDrive telemetry" IsChecked="True"/>
                                <CheckBox x:Name="chkExtraSchedTasks" Content="Remove additional telemetry scheduled tasks" IsChecked="True"/>
                                <CheckBox x:Name="chkDiskOptimize" Content="Auto-configure TRIM / scheduled defrag (SSD/HDD)" IsChecked="True"/>
                                <CheckBox x:Name="chkHagsGameMode" Content="Enable Game Mode and HAGS" IsChecked="False"/>
                                <CheckBox x:Name="chkUltimatePerf" Content="Enable Ultimate Performance with CPU min state at 100%" IsChecked="False"/>
                            </StackPanel>
                        </GroupBox>

                        <StackPanel Orientation="Horizontal" Margin="0,4,0,0">
                            <Button x:Name="btnRunSelected" Content="Run Selected Optimizations" Padding="20,10" FontSize="14" Margin="0,0,10,0"/>
                            <Button x:Name="btnRestoreDefaults" Content="Restore Defaults" Style="{StaticResource SecondaryButtonStyle}" Margin="0,0,10,0"/>
                            <Button x:Name="btnExportProfile" Content="Export Profile" Style="{StaticResource SecondaryButtonStyle}" Margin="0,0,10,0"/>
                            <Button x:Name="btnImportProfile" Content="Import Profile" Style="{StaticResource SecondaryButtonStyle}"/>
                        </StackPanel>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem x:Name="tabInstaller" Header="App Installer">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="10">

                        <Border Style="{StaticResource CardStyle}">
                            <StackPanel>
                                <TextBlock x:Name="txtChocoRequired" Text="Installing the apps below requires Chocolatey." TextWrapping="Wrap" FontWeight="Bold"/>
                                <TextBlock x:Name="txtChocoStatus" Text="" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="0,2,0,6" FontSize="12"/>
                                <Button x:Name="btnInstallChoco" Content="Install Chocolatey" HorizontalAlignment="Left" Padding="16,8" FontSize="13"/>
                            </StackPanel>
                        </Border>

                        <GroupBox x:Name="grpInstaller" Header="Useful Applications">
                            <StackPanel>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkFirefox" Content="Mozilla Firefox" FontWeight="Bold" Tag="firefox"/>
                                        <TextBlock x:Name="txtFirefoxDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkNanaZip" Content="NanaZip" FontWeight="Bold" Tag="nanazip"/>
                                        <TextBlock x:Name="txtNanaZipDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkNpp" Content="Notepad++" FontWeight="Bold" Tag="notepadplusplus.install"/>
                                        <TextBlock x:Name="txtNppDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkFdm" Content="Free Download Manager" FontWeight="Bold" Tag="freedownloadmanager"/>
                                        <TextBlock x:Name="txtFdmDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkQbt" Content="qBittorrent" FontWeight="Bold" Tag="qbittorrent"/>
                                        <TextBlock x:Name="txtQbtDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkSteam" Content="Steam" FontWeight="Bold" Tag="steam"/>
                                        <TextBlock x:Name="txtSteamDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkEpic" Content="Epic Games Launcher" FontWeight="Bold" Tag="epicgameslauncher"/>
                                        <TextBlock x:Name="txtEpicDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkGog" Content="GOG Galaxy" FontWeight="Bold" Tag="goggalaxy"/>
                                        <TextBlock x:Name="txtGogDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkSevenZip" Content="7-Zip" FontWeight="Bold" Tag="7zip"/>
                                        <TextBlock x:Name="txtSevenZipDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkWiztree" Content="WizTree" FontWeight="Bold" Tag="wiztree"/>
                                        <TextBlock x:Name="txtWiztreeDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkMemreduct" Content="Mem Reduct" FontWeight="Bold" Tag="memreduct"/>
                                        <TextBlock x:Name="txtMemreductDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkBleachbit" Content="BleachBit" FontWeight="Bold" Tag="bleachbit"/>
                                        <TextBlock x:Name="txtBleachbitDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkMoonlight" Content="Moonlight" FontWeight="Bold" Tag="moonlight"/>
                                        <TextBlock x:Name="txtMoonlightDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                                <Border Style="{StaticResource CardStyle}">
                                    <StackPanel>
                                        <CheckBox x:Name="chkSunshine" Content="Sunshine" FontWeight="Bold" Tag="sunshine"/>
                                        <TextBlock x:Name="txtSunshineDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="24,2,0,0" FontSize="12"/>
                                    </StackPanel>
                                </Border>

                            </StackPanel>
                        </GroupBox>
                        <Button x:Name="btnInstallApps" Content="Install Selected" HorizontalAlignment="Left" Padding="20,10" FontSize="14"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem x:Name="tabExternalScripts" Header="External Scripts">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="10">

                        <TextBlock x:Name="txtExtScriptsWarning" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" FontStyle="Italic" Margin="0,0,0,10" FontSize="12"/>

                        <Border Style="{StaticResource CardStyle}">
                            <StackPanel>
                                <TextBlock x:Name="txtAmdOptimizerTitle" Text="AMD Stability Optimizer" FontWeight="Bold" FontSize="14"/>
                                <TextBlock x:Name="txtAmdOptimizerDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="0,4,0,10" FontSize="12"/>
                                <Button x:Name="btnRunAmdOptimizer" Content="Run AMD Stability Optimizer" HorizontalAlignment="Left" Padding="16,8" FontSize="13"/>
                            </StackPanel>
                        </Border>

                        <Border Style="{StaticResource CardStyle}">
                            <StackPanel>
                                <TextBlock x:Name="txtMassgraveTitle" Text="Windows &amp; Office Activation (MAS)" FontWeight="Bold" FontSize="14"/>
                                <TextBlock x:Name="txtMassgraveDesc" TextWrapping="Wrap" Foreground="{StaticResource TextSecondary}" Margin="0,4,0,10" FontSize="12"/>
                                <Button x:Name="btnRunMassgrave" Content="Run Activation Script" HorizontalAlignment="Left" Padding="16,8" FontSize="13"/>
                            </StackPanel>
                        </Border>

                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>
    </DockPanel>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)


$Global:WgoLogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

function Show-WgoFatalError {
    param([string]$Message)
    [System.Windows.Forms.MessageBox]::Show(
        $Message, "WGO - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

function Start-WgoBackgroundTask {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @(),
        [scriptblock]$OnCompleted = $null
    )

    $rs = [runspacefactory]::CreateRunspace()
    # MTA, not STA: this runspace never touches WPF/COM-STA objects (only
    # plain data + cmdlets), and several Storage/CIM cmdlets used here
    # (Get-PhysicalDisk) misbehave under STA, occasionally surfacing a stray
    # access-denied error during pipeline teardown even though the actual
    # work already completed successfully.
    $rs.ApartmentState = [System.Threading.ApartmentState]::MTA
    $rs.ThreadOptions   = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $rs.Open()

    # Share plain data only - never $window/$ctrl (WPF objects are thread-affine).
    $rs.SessionStateProxy.SetVariable('WgoLogQueue', $Global:WgoLogQueue)
    $rs.SessionStateProxy.SetVariable('Lang', $Lang)
    $rs.SessionStateProxy.SetVariable('CurrentLangCode', $Global:CurrentLangCode)
    $rs.SessionStateProxy.SetVariable('WgoAppCatalog', $Global:WgoAppCatalog)
    $rs.SessionStateProxy.SetVariable('BloatwareWhitelist', $BloatwareWhitelist)
    $rs.SessionStateProxy.SetVariable('BloatwareTargets', $BloatwareTargets)
    $rs.SessionStateProxy.SetVariable('BloatwareCriticalProtect', $BloatwareCriticalProtect)
    $rs.SessionStateProxy.SetVariable('ErrorActionPreference', 'Stop')

    $ps = [powershell]::Create()
    $ps.Runspace = $rs

    # Copy the current body of every function the background code is allowed
    # to call into the worker runspace (read live via Get-Item, so there is no
    # duplicated source of truth to keep in sync).
    $funcDefs = ($Global:WgoSharedFunctionNames | ForEach-Object {
        $fn = Get-Item "function:\$_" -ErrorAction Ignore
        if ($fn) { "function $_ {`n$($fn.ScriptBlock)`n}" }
    }) -join "`n`n"
    [void]$ps.AddScript($funcDefs)

    # The actual task, as its own independently-parsed script chunk so that a
    # param() block at its start (if any) binds correctly to -ArgumentList.
    [void]$ps.AddScript($ScriptBlock.ToString())
    foreach ($arg in $ArgumentList) { [void]$ps.AddArgument($arg) }

    $asyncResult = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(150)
    $timer.Add_Tick({
        if (-not $asyncResult.IsCompleted) { return }
        $timer.Stop()
        try {
            $ps.EndInvoke($asyncResult) | Out-Null
            foreach ($errRec in $ps.Streams.Error) {
                $detail = "$($errRec.ToString()) | Category=$($errRec.CategoryInfo.Category) | Reason=$($errRec.CategoryInfo.Reason) | Target=$($errRec.CategoryInfo.TargetName) | At=$($errRec.InvocationInfo.PositionMessage -replace '[\r\n]+',' ')"
                Write-Log (T 'LogUnhandledError' $detail) "ERROR"
            }
        } catch {
            $detail = "$($_.Exception.GetType().FullName): $($_.Exception.Message) | At=$($_.ScriptStackTrace -replace '[\r\n]+',' ')"
            Write-Log (T 'LogUnhandledError' $detail) "ERROR"
        } finally {
            try { $ps.Dispose() } catch {}
            try { $rs.Close() } catch {}
            try { $rs.Dispose() } catch {}
            if ($OnCompleted) {
                try { & $OnCompleted } catch {
                    Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
                }
            }
        }
    }.GetNewClosure())
    $timer.Start()
}

# ============================================================================
# 4. RETRIEVE NAMED CONTROLS
# ============================================================================

$ctrl = @{}
$names = @(
    'txtAppTitle','txtLblLanguage','cmbLanguage','txtLogHeader','scrollLog','txtLog',
    'tabOptimizations','tabInstaller','tabExternalScripts',
    'chkSelectAll','chkDryRun',
    'grpRestore','btnCreateRestore',
    'grpBloat','chkBloat',
    'grpSearch','chkSearch',
    'grpVisual','chkVisual',
    'grpPrivacy','chkPrivacy',
    'grpDrivers','chkDrivers',
    'grpPagefile','chkPagefile',
    'grpExtraPrivacy','chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry',
    'grpAdvancedTweaks','chkDiagTrackFull','chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground','chkNetworkLatency',
    'grpMoreOptimizations','chkHibernation','chkPowerPlan','chkTempCleanup','chkHotCorners','chkRecallBlock',
    'chkBootTimeout','chkOfficeTelemetry','chkExtraSchedTasks','chkDiskOptimize','chkHagsGameMode','chkUltimatePerf',
    'btnRunSelected','btnRestoreDefaults','btnExportProfile','btnImportProfile',
    'grpInstaller','btnInstallApps',
    'txtChocoRequired','txtChocoStatus','btnInstallChoco',
    'chkFirefox','txtFirefoxDesc',
    'chkNanaZip','txtNanaZipDesc',
    'chkNpp','txtNppDesc',
    'chkFdm','txtFdmDesc',
    'chkQbt','txtQbtDesc',
    'chkSteam','txtSteamDesc',
    'chkEpic','txtEpicDesc',
    'chkGog','txtGogDesc',
    'chkSevenZip','txtSevenZipDesc',
    'chkWiztree','txtWiztreeDesc',
    'chkMemreduct','txtMemreductDesc',
    'chkBleachbit','txtBleachbitDesc',
    'chkMoonlight','txtMoonlightDesc',
    'chkSunshine','txtSunshineDesc',
    'txtExtScriptsWarning',
    'txtAmdOptimizerTitle','txtAmdOptimizerDesc','btnRunAmdOptimizer',
    'txtMassgraveTitle','txtMassgraveDesc','btnRunMassgrave'
)
foreach ($n in $names) { $ctrl[$n] = $window.FindName($n) }

# Checkboxes controlled by the "Select All / Deselect All" master checkbox
# (Optimizations & Privacy tab only - excludes the App Installer tab).
$script:optimizationCheckboxNames = @(
    'chkBloat','chkSearch','chkVisual','chkPrivacy','chkDrivers','chkPagefile',
    'chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry',
    'chkDiagTrackFull','chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground','chkNetworkLatency',
    'chkHibernation','chkPowerPlan','chkTempCleanup','chkHotCorners','chkRecallBlock',
    'chkBootTimeout','chkOfficeTelemetry','chkExtraSchedTasks','chkDiskOptimize'
)

# ============================================================================
# 5. LOG / UI UTILITIES
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    # Only touch the ConcurrentQueue here (thread-safe, no WPF objects
    # involved), so this same function works correctly whether it is called
    # from the UI thread or from a background worker runspace. The UI thread
    # drains it via $Global:WgoLogTimer below.
    $Global:WgoLogQueue.Enqueue("[$timestamp][$Level] $Message")
}

# Drains $Global:WgoLogQueue into the log TextBox. Runs only on the UI thread
# (DispatcherTimer ticks are always dispatched there), so this is the single
# place that actually touches the txtLog control - safe and simple.
$Global:WgoLogTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:WgoLogTimer.Interval = [TimeSpan]::FromMilliseconds(150)
$Global:WgoLogTimer.Add_Tick({
    $line = $null
    $appended = $false
    while ($Global:WgoLogQueue.TryDequeue([ref]$line)) {
        $ctrl['txtLog'].AppendText("$line`r`n")
        $appended = $true
    }
    if ($appended) { $ctrl['txtLog'].ScrollToEnd() }
})
$Global:WgoLogTimer.Start()

# T = Translate: resolves a message key in the currently selected UI language and,
# optionally, formats it with -f using the extra arguments passed in.
# This is what makes the execution log fully multi-language (en-US / pt-BR / es-ES / zh-CN),
# instead of being hardcoded in a single language regardless of the UI language selected.
function T {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(ValueFromRemainingArguments = $true)][object[]]$FormatArgs
    )
    $table = $Lang[$Global:CurrentLangCode]
    if (-not $table -or -not $table.ContainsKey($Key)) { $table = $Lang['en-US'] }
    $template = $table[$Key]
    if (-not $template) { return $Key }
    if ($FormatArgs -and $FormatArgs.Count -gt 0) {
        try { return ($template -f $FormatArgs) } catch { return $template }
    }
    return $template
}

function Update-UILanguage {
    param([string]$Code)
    $t = $Lang[$Code]
    $Global:CurrentLangCode = $Code

    $window.Title                       = $t.AppTitle
    $ctrl['txtAppTitle'].Text            = $t.AppTitle
    $ctrl['txtLblLanguage'].Text         = $t.LblLanguage
    $ctrl['txtLogHeader'].Text           = $t.LogHeader
    $ctrl['tabOptimizations'].Header     = $t.TabOptimizations
    $ctrl['tabInstaller'].Header         = $t.TabInstaller

    $ctrl['chkSelectAll'].Content        = $t.ChkSelectAll

    $ctrl['grpRestore'].Header           = $t.GrpRestore
    $ctrl['btnCreateRestore'].Content    = $t.BtnCreateRestore

    $ctrl['grpBloat'].Header             = $t.GrpBloat
    $ctrl['chkBloat'].Content            = $t.ChkBloat

    $ctrl['grpSearch'].Header            = $t.GrpSearch
    $ctrl['chkSearch'].Content           = $t.ChkSearch

    $ctrl['grpVisual'].Header            = $t.GrpVisual
    $ctrl['chkVisual'].Content           = $t.ChkVisual

    $ctrl['grpPrivacy'].Header           = $t.GrpPrivacy
    $ctrl['chkPrivacy'].Content          = $t.ChkPrivacy

    $ctrl['grpDrivers'].Header           = $t.GrpDrivers
    $ctrl['chkDrivers'].Content          = $t.ChkDrivers

    $ctrl['grpPagefile'].Header          = $t.GrpPagefile
    $ctrl['chkPagefile'].Content         = $t.ChkPagefile

    $ctrl['grpExtraPrivacy'].Header      = $t.GrpExtraPrivacy
    $ctrl['chkAdvertisingId'].Content    = $t.ChkAdvertisingId
    $ctrl['chkTailoredExp'].Content      = $t.ChkTailoredExp
    $ctrl['chkDiagTrackSvc'].Content     = $t.ChkDiagTrackSvc
    $ctrl['chkCopilotBlock'].Content     = $t.ChkCopilotBlock
    $ctrl['chkInputTelemetry'].Content   = $t.ChkInputTelemetry

    $ctrl['grpAdvancedTweaks'].Header    = $t.GrpAdvancedTweaks
    $ctrl['chkDiagTrackFull'].Content    = $t.ChkDiagTrackFull
    $ctrl['chkEdgeWidgets'].Content      = $t.ChkEdgeWidgets
    $ctrl['chkDeliveryOpt'].Content      = $t.ChkDeliveryOpt
    $ctrl['chkAppsBackground'].Content   = $t.ChkAppsBackground
    $ctrl['chkNetworkLatency'].Content   = $t.ChkNetworkLatency

    $ctrl['grpMoreOptimizations'].Header = $t.GrpMoreOptimizations
    $ctrl['chkHibernation'].Content      = $t.ChkHibernation
    $ctrl['chkPowerPlan'].Content        = $t.ChkPowerPlan
    $ctrl['chkTempCleanup'].Content      = $t.ChkTempCleanup
    $ctrl['chkHotCorners'].Content       = $t.ChkHotCorners
    $ctrl['chkRecallBlock'].Content      = $t.ChkRecallBlock
    $ctrl['chkBootTimeout'].Content      = $t.ChkBootTimeout
    $ctrl['chkOfficeTelemetry'].Content  = $t.ChkOfficeTelemetry
    $ctrl['chkExtraSchedTasks'].Content  = $t.ChkExtraSchedTasks
    $ctrl['chkDiskOptimize'].Content     = $t.ChkDiskOptimize

    $ctrl['chkDryRun'].Content           = $t.ChkDryRun

    $ctrl['btnRunSelected'].Content      = $t.BtnRunSelected
    $ctrl['btnRestoreDefaults'].Content  = $t.BtnRestoreDefaults
    $ctrl['btnExportProfile'].Content    = $t.BtnExportProfile
    $ctrl['btnImportProfile'].Content    = $t.BtnImportProfile

    $ctrl['txtChocoRequired'].Text       = $t.TxtChocoRequired
    $ctrl['btnInstallChoco'].Content     = $t.BtnInstallChoco
    Update-WgoChocoStatus

    $ctrl['grpInstaller'].Header         = $t.GrpInstaller
    $ctrl['btnInstallApps'].Content      = $t.BtnInstallApps

    $ctrl['chkFirefox'].Content          = "Mozilla Firefox"
    $ctrl['txtFirefoxDesc'].Text         = $t.AppFirefoxDesc
    $ctrl['chkNanaZip'].Content          = "NanaZip"
    $ctrl['txtNanaZipDesc'].Text         = $t.AppNanaZipDesc
    $ctrl['chkNpp'].Content              = "Notepad++"
    $ctrl['txtNppDesc'].Text             = $t.AppNppDesc
    $ctrl['chkFdm'].Content              = "Free Download Manager"
    $ctrl['txtFdmDesc'].Text             = $t.AppFdmDesc
    $ctrl['chkQbt'].Content              = "qBittorrent"
    $ctrl['txtQbtDesc'].Text             = $t.AppQbtDesc
    $ctrl['chkSteam'].Content            = "Steam"
    $ctrl['txtSteamDesc'].Text           = $t.AppSteamDesc
    $ctrl['chkEpic'].Content             = "Epic Games Launcher"
    $ctrl['txtEpicDesc'].Text            = $t.AppEpicDesc
    $ctrl['chkGog'].Content              = "GOG Galaxy"
    $ctrl['txtGogDesc'].Text             = $t.AppGogDesc
    $ctrl['chkSevenZip'].Content          = "7-Zip"
    $ctrl['txtSevenZipDesc'].Text        = $t.AppSevenZipDesc
    $ctrl['chkWiztree'].Content           = "WizTree"
    $ctrl['txtWiztreeDesc'].Text         = $t.AppWiztreeDesc
    $ctrl['chkMemreduct'].Content         = "Mem Reduct"
    $ctrl['txtMemreductDesc'].Text       = $t.AppMemreductDesc
    $ctrl['chkBleachbit'].Content         = "BleachBit"
    $ctrl['txtBleachbitDesc'].Text       = $t.AppBleachbitDesc
    $ctrl['chkMoonlight'].Content         = "Moonlight"
    $ctrl['txtMoonlightDesc'].Text       = $t.AppMoonlightDesc
    $ctrl['chkSunshine'].Content          = "Sunshine"
    $ctrl['txtSunshineDesc'].Text        = $t.AppSunshineDesc

    $ctrl['tabExternalScripts'].Header    = $t.TabExternalScripts
    $ctrl['txtExtScriptsWarning'].Text    = $t.TxtExtScriptsWarning
    $ctrl['txtAmdOptimizerTitle'].Text    = $t.TxtAmdOptimizerTitle
    $ctrl['txtAmdOptimizerDesc'].Text     = $t.TxtAmdOptimizerDesc
    $ctrl['btnRunAmdOptimizer'].Content   = $t.BtnRunAmdOptimizer
    $ctrl['txtMassgraveTitle'].Text       = $t.TxtMassgraveTitle
    $ctrl['txtMassgraveDesc'].Text        = $t.TxtMassgraveDesc
    $ctrl['btnRunMassgrave'].Content      = $t.BtnRunMassgrave
}

# ============================================================================
# 6. FUNCTION 1 - RESTORE POINT
# ============================================================================

function New-WgoRestorePoint {
    Write-Log (T 'LogRestoreTry') "INFO"
    try {
        $svc = Get-Service -Name "srservice" -ErrorAction Ignore
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Ignore

        Checkpoint-Computer -Description "WGO - Before optimizations" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log (T 'LogRestoreOk') "OK"
        return $true
    } catch {
        Write-Log (T 'LogRestoreFail' $_.Exception.Message) "ERROR"
        Write-Log (T 'LogRestoreHint') "WARN"
        return $false
    }
}

# ============================================================================
# 7. FUNCTION 2 - BLOATWARE REMOVAL (EXPANDED WHITELIST)
# ============================================================================

$BloatwareWhitelist = @(
    "Microsoft.WindowsStore",
    "Microsoft.XboxApp",
    "Microsoft.GamingApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.Xbox.TCUI",
    "Microsoft.MicrosoftEdge",
    "Microsoft.MicrosoftEdge.Stable",
    "MicrosoftEdgeDevToolsProtocol",
    "Microsoft.Edge",
    "Microsoft.Edge.GameAssist",
    "Microsoft.WebView2",
    "Microsoft.WebMediaExtensions",
    "Microsoft.VCLibs",
    "Microsoft.VCLibs.140.00",
    "Microsoft.VCLibs.140.00.UWPDesktop",
    "Microsoft.NET.Native",
    "Microsoft.NET.Native.Framework",
    "Microsoft.NET.Native.Runtime",
    "Microsoft.UI.Xaml",
    "Microsoft.UI.Xaml.2.8",
    "Microsoft.UI.Xaml.CBS",
    "Microsoft.Services.Store.Engagement",
    "Microsoft.StorePurchaseApp",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.WindowsAppRuntime",
    "Microsoft.Winget.Source",
    "Microsoft.WindowsTerminal"
)

# Packages that must never be touched by the debloat routine no matter what
# ends up in $BloatwareTargets, since removing them silently breaks winget /
# App Installer. Matched as a name prefix, not an exact string, because
# installed packages carry version-specific suffixes (e.g. Microsoft.UI.Xaml.2.8).
$BloatwareCriticalProtect = @(
    "Microsoft.DesktopAppInstaller",
    "Microsoft.VCLibs",
    "Microsoft.UI.Xaml",
    "Microsoft.WindowsStore",
    "Microsoft.NET.Native"
)

function Test-WgoProtectedPackage {
    param([string]$Name)
    if ([string]::IsNullOrEmpty($Name)) { return $false }
    foreach ($p in $BloatwareCriticalProtect) {
        if ($Name -like "$p*") { return $true }
    }
    return ($BloatwareWhitelist -contains $Name)
}

$BloatwareTargets = @(
    "Microsoft.Copilot",
    "Microsoft.Windows.Ai.Copilot.Provider",
    "MicrosoftWindows.Client.CoPilot",
    "Microsoft.WindowsRecall",
    "Microsoft.Windows.Recall",
    "Microsoft.549981C3F5F10",             # Cortana
    "Microsoft.Paint3D",
    "Microsoft.MSPaint",
    "Microsoft.YourPhone",                 # Phone Link
    "microsoft.windowscommunicationsapps", # Mail e Calendar
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.BingFinance",
    "Microsoft.BingSports",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.SkypeApp",
    "Microsoft.Getstarted",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.GamingServices",
    "Microsoft.Todos",
    "Microsoft.Whiteboard",
    "Microsoft.OutlookForWindows",
    "Microsoft.Teams",
    "MicrosoftTeams",
    "Clipchamp.Clipchamp",
    "Microsoft.549981C3F5F10",
    "Microsoft.3DBuilder",
    "Microsoft.Wallet",
    "Microsoft.Advertising.Xaml"
)

function Remove-WgoBloatware {
    Write-Log (T 'LogBloatStart') "INFO"
    foreach ($appName in $BloatwareTargets) {
        if (Test-WgoProtectedPackage -Name $appName) { continue }
        try {
            $pkgs = Get-AppxPackage -AllUsers -Name "*$appName*" -ErrorAction Ignore |
                    Where-Object { -not (Test-WgoProtectedPackage -Name $_.Name) }
            foreach ($p in $pkgs) {
                Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Ignore
                Write-Log (T 'LogBloatUserRemoved' $p.Name) "OK"
            }

            $prov = Get-AppxProvisionedPackage -Online -ErrorAction Ignore |
                    Where-Object { $_.DisplayName -like "*$appName*" -and -not (Test-WgoProtectedPackage -Name $_.DisplayName) }
            foreach ($pp in $prov) {
                Remove-AppxProvisionedPackage -Online -PackageName $pp.PackageName -ErrorAction Ignore
                Write-Log (T 'LogBloatProvRemoved' $pp.DisplayName) "OK"
            }
        } catch {
            Write-Log (T 'LogBloatError' $appName $_.Exception.Message) "ERROR"
        }
    }
    Write-Log (T 'LogBloatDone') "OK"
}

# ============================================================================
# 8. FUNCTION 3 - 100% LOCAL SEARCH (NO BING / EDGE WEB SEARCH)
# ============================================================================

function Set-WgoLocalSearch {
    Write-Log (T 'LogSearchStart') "INFO"
    try {
        $explorerPolicy = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
        $searchKey      = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"

        if (-not (Test-Path $explorerPolicy)) { New-Item -Path $explorerPolicy -Force | Out-Null }
        if (-not (Test-Path $searchKey))      { New-Item -Path $searchKey -Force | Out-Null }

        New-ItemProperty -Path $explorerPolicy -Name "DisableSearchBoxSuggestions" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $searchKey -Name "BingSearchEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $searchKey -Name "CortanaConsent" -Value 0 -PropertyType DWord -Force | Out-Null

        Write-Log (T 'LogSearchOk') "OK"
    } catch {
        Write-Log (T 'LogSearchError' $_.Exception.Message) "ERROR"
    }
}

# ============================================================================
# 9. FUNCTION 4 - CUSTOM VISUAL EFFECTS
# ============================================================================

function Set-WgoVisualEffects {
    Write-Log (T 'LogVisualStart') "INFO"
    try {
        $desktopKey = "HKCU:\Control Panel\Desktop"
        $vfxKey     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        $advKey     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $dwmKey     = "HKCU:\Software\Microsoft\Windows\DWM"

        foreach ($k in @($vfxKey)) { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } }

        # VisualFXSetting = 3 (custom)
        New-ItemProperty -Path $vfxKey -Name "VisualFXSetting" -Value 3 -PropertyType DWord -Force | Out-Null

        # Enabled
        New-ItemProperty -Path $desktopKey -Name "MinAnimate" -Value 1 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "DragFullWindows" -Value 1 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $advKey -Name "IconsOnly" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "ListviewAlphaSelect" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "FontSmoothing" -Value 2 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "FontSmoothingType" -Value 2 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "ListviewShadow" -Value 1 -PropertyType DWord -Force | Out-Null

        # Disabled
        New-ItemProperty -Path $advKey -Name "TaskbarAnimations" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "ComboBoxAnimation" -Value 0 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "MenuAnimation" -Value 0 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "TooltipAnimation" -Value 0 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -PropertyType Binary -Force | Out-Null
        if (-not (Test-Path $dwmKey)) { New-Item -Path $dwmKey -Force | Out-Null }
        New-ItemProperty -Path $dwmKey -Name "EnableAeroPeek" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "CursorShadow" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $advKey -Name "ListviewWatermark" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "SmoothScroll" -Value 0 -PropertyType DWord -Force | Out-Null

        Write-Log (T 'LogVisualOk') "OK"
    } catch {
        Write-Log (T 'LogVisualError' $_.Exception.Message) "ERROR"
    }
}

# ============================================================================
# 10. FUNCTION 5 - DEEP PRIVACY / TELEMETRY (GPEDIT / REGISTRY)
# ============================================================================

function Set-WgoPrivacyPolicies {
    Write-Log (T 'LogPrivacyStart') "INFO"
    try {
        $paths = @{
            DataCollection = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            AppCompat      = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"
            WER            = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
            SQMClient      = "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows"
            Location       = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
            ActivityFeed   = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        }
        foreach ($p in $paths.Values) {
            if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        }

        # DataCollection / DiagnosticData
        New-ItemProperty -Path $paths.DataCollection -Name "AllowTelemetry" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.DataCollection -Name "LimitDiagnosticDataConfigurationSet" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.DataCollection -Name "DisableOneSettingsDownloads" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.DataCollection -Name "DoNotShowFeedbackNotifications" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.DataCollection -Name "NumberOfSIUFInPeriod" -Value 0 -PropertyType DWord -Force | Out-Null

        # Application Impact & Compatibility (AppCompat / Inventory)
        New-ItemProperty -Path $paths.AppCompat -Name "AITEnable" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.AppCompat -Name "DisableInventory" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.AppCompat -Name "DisablePCA" -Value 1 -PropertyType DWord -Force | Out-Null

        # Windows Error Reporting
        New-ItemProperty -Path $paths.WER -Name "Disabled" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.WER -Name "DoReport" -Value 0 -PropertyType DWord -Force | Out-Null

        # CEIP (SQMClient) + related scheduled tasks
        New-ItemProperty -Path $paths.SQMClient -Name "CEIPEnable" -Value 0 -PropertyType DWord -Force | Out-Null
        $ceipTasks = @(
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
            "\Microsoft\Windows\Autochk\Proxy",
            "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
        )
        foreach ($task in $ceipTasks) {
            try { Disable-ScheduledTask -TaskPath (Split-Path $task) -TaskName (Split-Path $task -Leaf) -ErrorAction Ignore | Out-Null } catch {}
        }

        # Location & Sensors
        New-ItemProperty -Path $paths.Location -Name "DisableLocation" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.Location -Name "DisableLocationScripting" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.Location -Name "DisableSensors" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.Location -Name "DisableWindowsLocationProvider" -Value 1 -PropertyType DWord -Force | Out-Null

        # Activity History & Timeline
        New-ItemProperty -Path $paths.ActivityFeed -Name "EnableActivityFeed" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.ActivityFeed -Name "PublishUserActivities" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.ActivityFeed -Name "UploadUserActivities" -Value 0 -PropertyType DWord -Force | Out-Null

        Write-Log (T 'LogPrivacyOk') "OK"
    } catch {
        Write-Log (T 'LogPrivacyError' $_.Exception.Message) "ERROR"
    }
}

# ============================================================================
# 10-B. FUNCTION 5-B - ADDITIONAL TELEMETRY OPTIONS
# ============================================================================

function Set-WgoExtraPrivacy {
    param(
        [bool]$AdvertisingId   = $false,
        [bool]$TailoredExp     = $false,
        [bool]$DiagTrackSvc    = $false,
        [bool]$CopilotBlock    = $false,
        [bool]$InputTelemetry  = $false
    )

    if (-not ($AdvertisingId -or $TailoredExp -or $DiagTrackSvc -or $CopilotBlock -or $InputTelemetry)) { return }

    Write-Log (T 'LogExtraStart') "INFO"

    if ($AdvertisingId) {
        try {
            $advKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            $advKeyM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
            if (-not (Test-Path $advKey))  { New-Item -Path $advKey -Force | Out-Null }
            if (-not (Test-Path $advKeyM)) { New-Item -Path $advKeyM -Force | Out-Null }
            New-ItemProperty -Path $advKey -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $advKeyM -Name "DisabledByGroupPolicy" -Value 1 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogExtraAdvOk') "OK"
        } catch {
            Write-Log (T 'LogExtraError' "AdvertisingId" $_.Exception.Message) "ERROR"
        }
    }

    if ($TailoredExp) {
        try {
            $cdmKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            $cloudKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            if (-not (Test-Path $cdmKey))   { New-Item -Path $cdmKey -Force | Out-Null }
            if (-not (Test-Path $cloudKey)) { New-Item -Path $cloudKey -Force | Out-Null }
            $cdmProps = @(
                "SubscribedContent-338388Enabled", "SubscribedContent-338389Enabled",
                "SubscribedContent-353698Enabled", "SystemPaneSuggestionsEnabled",
                "SoftLandingEnabled", "ContentDeliveryAllowed", "OemPreInstalledAppsEnabled",
                "PreInstalledAppsEnabled", "PreInstalledAppsEverEnabled", "SilentInstalledAppsEnabled"
            )
            foreach ($prop in $cdmProps) {
                New-ItemProperty -Path $cdmKey -Name $prop -Value 0 -PropertyType DWord -Force | Out-Null
            }
            New-ItemProperty -Path $cloudKey -Name "DisableWindowsConsumerFeatures" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $cloudKey -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $cloudKey -Name "DisableSoftLanding" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $cloudKey -Name "DisableWindowsSpotlightFeatures" -Value 1 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogExtraTailoredOk') "OK"
        } catch {
            Write-Log (T 'LogExtraError' "TailoredExp" $_.Exception.Message) "ERROR"
        }
    }

    if ($DiagTrackSvc) {
        try {
            foreach ($svcName in @("DiagTrack", "dmwappushservice")) {
                $svc = Get-Service -Name $svcName -ErrorAction Ignore
                if ($svc) {
                    Stop-Service -Name $svcName -Force -ErrorAction Ignore
                    Set-Service -Name $svcName -StartupType Disabled -ErrorAction Ignore
                }
            }
            Write-Log (T 'LogExtraDiagTrackOk') "OK"
        } catch {
            Write-Log (T 'LogExtraError' "DiagTrackSvc" $_.Exception.Message) "ERROR"
        }
    }

    if ($CopilotBlock) {
        try {
            $winKey    = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
            $dcKey     = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            $expKey    = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
            if (-not (Test-Path $winKey)) { New-Item -Path $winKey -Force | Out-Null }
            if (-not (Test-Path $expKey)) { New-Item -Path $expKey -Force | Out-Null }
            New-ItemProperty -Path $winKey -Name "TurnOffWindowsCopilot" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $expKey -Name "DisableSearchBoxSuggestions" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $dcKey -Name "AllowRecallEnablement" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $dcKey -Name "DisableAIDataAnalysis" -Value 1 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogExtraCopilotOk') "OK"
        } catch {
            Write-Log (T 'LogExtraError' "CopilotBlock" $_.Exception.Message) "ERROR"
        }
    }

    if ($InputTelemetry) {
        try {
            $inputKey  = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
            $trainKey  = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
            $clipKey   = "HKCU:\SOFTWARE\Microsoft\Clipboard"
            if (-not (Test-Path $inputKey)) { New-Item -Path $inputKey -Force | Out-Null }
            if (-not (Test-Path $trainKey)) { New-Item -Path $trainKey -Force | Out-Null }
            if (-not (Test-Path $clipKey))  { New-Item -Path $clipKey -Force | Out-Null }
            New-ItemProperty -Path $inputKey -Name "RestrictImplicitInkCollection" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $inputKey -Name "RestrictImplicitTextCollection" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $trainKey -Name "HarvestContacts" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $clipKey -Name "EnableClipboardHistory" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $clipKey -Name "CloudClipboardAutomaticUpload" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogExtraInputOk') "OK"
        } catch {
            Write-Log (T 'LogExtraError' "InputTelemetry" $_.Exception.Message) "ERROR"
        }
    }

    Write-Log (T 'LogExtraDone') "OK"
}

# ============================================================================
# 10-C. FUNCTION 5-C - ADVANCED SYSTEM TWEAKS (DiagTrack / Edge / DO / UWP / TCP)
# ============================================================================

function Set-WgoAdvancedTweaks {
    param(
        [bool]$DiagTrackFull  = $false,
        [bool]$EdgeWidgets    = $false,
        [bool]$DeliveryOpt    = $false,
        [bool]$AppsBackground = $false,
        [bool]$NetworkLatency = $false
    )

    if (-not ($DiagTrackFull -or $EdgeWidgets -or $DeliveryOpt -or $AppsBackground -or $NetworkLatency)) { return }

    Write-Log (T 'LogAdvStart') "INFO"

    # 1. Disable Telemetry (DiagTrack service + policy)
    if ($DiagTrackFull) {
        try {
            $dcKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            if (-not (Test-Path $dcKey)) { New-Item -Path $dcKey -Force | Out-Null }
            New-ItemProperty -Path $dcKey -Name "AllowTelemetry" -Value 0 -PropertyType DWord -Force | Out-Null

            $svc = Get-Service -Name "DiagTrack" -ErrorAction Ignore
            if ($svc) {
                Stop-Service -Name "DiagTrack" -Force -ErrorAction Ignore
                Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction Ignore
            }
            Write-Log (T 'LogAdvDiagTrackOk') "OK"
        } catch {
            Write-Log (T 'LogAdvError' "DiagTrackFull" $_.Exception.Message) "ERROR"
        }
    }

    # 2. Disable Edge preload/background and taskbar Widgets
    if ($EdgeWidgets) {
        try {
            $edgeKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
            $advKey  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $edgeKey)) { New-Item -Path $edgeKey -Force | Out-Null }
            if (-not (Test-Path $advKey))  { New-Item -Path $advKey -Force | Out-Null }
            New-ItemProperty -Path $edgeKey -Name "StartupBoostEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $edgeKey -Name "BackgroundModeEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $advKey -Name "TaskbarDa" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogAdvEdgeWidgetsOk') "OK"
        } catch {
            Write-Log (T 'LogAdvError' "EdgeWidgets" $_.Exception.Message) "ERROR"
        }
    }

    # 3. Delivery Optimization -> HTTP only (disable P2P)
    if ($DeliveryOpt) {
        try {
            $doKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
            if (-not (Test-Path $doKey)) { New-Item -Path $doKey -Force | Out-Null }
            New-ItemProperty -Path $doKey -Name "DODownloadMode" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogAdvDeliveryOptOk') "OK"
        } catch {
            Write-Log (T 'LogAdvError' "DeliveryOpt" $_.Exception.Message) "ERROR"
        }
    }

    # 4. Block UWP apps from running in background
    if ($AppsBackground) {
        try {
            $bgKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
            if (-not (Test-Path $bgKey)) { New-Item -Path $bgKey -Force | Out-Null }
            New-ItemProperty -Path $bgKey -Name "LetAppsRunInBackground" -Value 2 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogAdvAppsBackgroundOk') "OK"
        } catch {
            Write-Log (T 'LogAdvError' "AppsBackground" $_.Exception.Message) "ERROR"
        }
    }

    # 5. Network / TCP-IP latency tuning
    if ($NetworkLatency) {
        try {
            $mmKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            if (-not (Test-Path $mmKey)) { New-Item -Path $mmKey -Force | Out-Null }
            New-ItemProperty -Path $mmKey -Name "NetworkThrottlingIndex" -Value 0xffffffff -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $mmKey -Name "SystemResponsiveness" -Value 0 -PropertyType DWord -Force | Out-Null

            $ifaceRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            $activeCount = 0
            if (Test-Path $ifaceRoot) {
                Get-ChildItem -Path $ifaceRoot -ErrorAction Ignore | ForEach-Object {
                    $ifPath = $_.PSPath
                    $props  = Get-ItemProperty -Path $ifPath -ErrorAction Ignore
                    # Only touch interfaces that actually have an assigned/leased IP (active NICs)
                    $hasIp = ($props.PSObject.Properties.Name -contains 'DhcpIPAddress' -and $props.DhcpIPAddress) -or
                             ($props.PSObject.Properties.Name -contains 'IPAddress' -and $props.IPAddress -and ($props.IPAddress -join '') -notin @('', '0.0.0.0'))
                    if ($hasIp) {
                        New-ItemProperty -Path $ifPath -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null
                        New-ItemProperty -Path $ifPath -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
                        $activeCount++
                    }
                }
            }
            Write-Log (T 'LogAdvNetworkOk' $activeCount) "OK"
        } catch {
            Write-Log (T 'LogAdvError' "NetworkLatency" $_.Exception.Message) "ERROR"
        }
    }

    Write-Log (T 'LogAdvDone') "OK"
}

# ============================================================================
# 10-D. FUNCTION 5-D - SYSTEM CLEANUP & PERFORMANCE (batch 2)
# ============================================================================

function Set-WgoMoreOptimizations {
    param(
        [bool]$Hibernation     = $false,
        [bool]$PowerPlan       = $false,
        [bool]$TempCleanup     = $false,
        [bool]$HotCorners      = $false,
        [bool]$RecallBlock     = $false,
        [bool]$BootTimeout     = $false,
        [bool]$OfficeTelemetry = $false,
        [bool]$ExtraSchedTasks = $false,
        [bool]$DiskOptimize    = $false,
        [bool]$DryRun          = $false
    )

    if (-not ($Hibernation -or $PowerPlan -or $TempCleanup -or $HotCorners -or $RecallBlock -or
               $BootTimeout -or $OfficeTelemetry -or $ExtraSchedTasks -or $DiskOptimize)) { return }

    Write-Log (T 'LogMoreStart') "INFO"
    if ($DryRun) { Write-Log (T 'LogDryRunNote') "WARN" }

    # 1. Disable Hibernation
    if ($Hibernation) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkHibernation')) "INFO"
        } else {
            try {
                & powercfg.exe /hibernate off 2>$null | Out-Null
                Write-Log (T 'LogHibernationOk') "OK"
            } catch {
                Write-Log (T 'LogMoreError' "Hibernation" $_.Exception.Message) "ERROR"
            }
        }
    }

    # 2. High Performance power plan
    if ($PowerPlan) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkPowerPlan')) "INFO"
        } else {
            try {
                # SCHEME_MIN is the built-in alias for the "High performance" plan.
                & powercfg.exe /setactive SCHEME_MIN 2>$null | Out-Null
                Write-Log (T 'LogPowerPlanOk') "OK"
            } catch {
                Write-Log (T 'LogMoreError' "PowerPlan" $_.Exception.Message) "ERROR"
            }
        }
    }

    # 3. Temp files / old Prefetch / Windows.old / Windows Update cache cleanup
    if ($TempCleanup) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkTempCleanup')) "INFO"
        } else {
            try {
                Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction Ignore
                Remove-Item -Path "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction Ignore

                $cutoff = (Get-Date).AddDays(-30)
                Get-ChildItem -Path "$env:WINDIR\Prefetch\*.pf" -ErrorAction Ignore |
                    Where-Object { $_.LastWriteTime -lt $cutoff } |
                    Remove-Item -Force -ErrorAction Ignore

                if (Test-Path "$env:SystemDrive\Windows.old") {
                    Remove-Item -Path "$env:SystemDrive\Windows.old" -Recurse -Force -ErrorAction Ignore
                }

                Stop-Service -Name wuauserv -Force -ErrorAction Ignore
                Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction Ignore
                Start-Service -Name wuauserv -ErrorAction Ignore

                Write-Log (T 'LogTempCleanupOk') "OK"
            } catch {
                Write-Log (T 'LogMoreError' "TempCleanup" $_.Exception.Message) "ERROR"
            }
        }
    }

    # 4. Disable Snap Assist / Aero Shake
    if ($HotCorners) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkHotCorners')) "INFO"
        } else {
            try {
                $advKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                if (-not (Test-Path $advKey)) { New-Item -Path $advKey -Force | Out-Null }
                New-ItemProperty -Path $advKey -Name "EnableSnapAssistFlyout" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $advKey -Name "SnapFill" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $advKey -Name "SnapAssist" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $advKey -Name "DisallowShaking" -Value 1 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogHotCornersOk') "OK"
            } catch {
                Write-Log (T 'LogMoreError' "HotCorners" $_.Exception.Message) "ERROR"
            }
        }
    }

    # 5. Disable Windows Recall
    if ($RecallBlock) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkRecallBlock')) "INFO"
        } else {
            try {
                $aiKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
                if (-not (Test-Path $aiKey)) { New-Item -Path $aiKey -Force | Out-Null }
                New-ItemProperty -Path $aiKey -Name "DisableAIDataAnalysis" -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $aiKey -Name "AllowRecallEnablement" -Value 0 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogRecallBlockOk') "OK"
            } catch {
                Write-Log (T 'LogMoreError' "RecallBlock" $_.Exception.Message) "ERROR"
            }
        }
    }

    # 6. Reduce boot menu timeout to 5 seconds
    if ($BootTimeout) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkBootTimeout')) "INFO"
        } else {
            try {
                & bcdedit.exe /timeout 5 2>$null | Out-Null
                Write-Log (T 'LogBootTimeoutOk') "OK"
            } catch {
                Write-Log (T 'LogMoreError' "BootTimeout" $_.Exception.Message) "ERROR"
            }
        }
    }

    # 7. Block Office / OneDrive telemetry
    if ($OfficeTelemetry) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkOfficeTelemetry')) "INFO"
        } else {
            try {
                $officeCommonKey = "HKCU:\Software\Policies\Microsoft\office\16.0\common"
                $officeOsmKey    = "HKCU:\Software\Policies\Microsoft\office\16.0\osm"
                $oneDriveKey     = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
                foreach ($p in @($officeCommonKey, $officeOsmKey, $oneDriveKey)) {
                    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                }
                New-ItemProperty -Path $officeCommonKey -Name "qmenable" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $officeCommonKey -Name "sendcustomerdata" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $officeOsmKey -Name "enablelogging" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $oneDriveKey -Name "DisableTelemetry" -Value 1 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogOfficeTelemetryOk') "OK"
            } catch {
                Write-Log (T 'LogMoreError' "OfficeTelemetry" $_.Exception.Message) "ERROR"
            }
        }
    }

    # 8. Remove additional telemetry scheduled tasks
    if ($ExtraSchedTasks) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkExtraSchedTasks')) "INFO"
        } else {
            try {
                $extraTasks = @(
                    "\Microsoft\Windows\Feedback\Siuf\DmClient",
                    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
                    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
                    "\Microsoft\Office\OfficeTelemetryAgentFallBack2016",
                    "\Microsoft\Office\OfficeTelemetryAgentLogOn2016"
                )
                foreach ($task in $extraTasks) {
                    try { Disable-ScheduledTask -TaskPath (Split-Path $task) -TaskName (Split-Path $task -Leaf) -ErrorAction Ignore | Out-Null } catch {}
                }
                Write-Log (T 'LogExtraSchedTasksOk') "OK"
            } catch {
                Write-Log (T 'LogMoreError' "ExtraSchedTasks" $_.Exception.Message) "ERROR"
            }
        }
    }

    # 9. Auto-detect disks (SSD/HDD) and configure TRIM / scheduled defrag
    if ($DiskOptimize) {
        if ($DryRun) {
            Write-Log (T 'LogDryRunPrefix' (T 'ChkDiskOptimize')) "INFO"
        } else {
            try {
                $disks = Get-PhysicalDisk -ErrorAction Ignore
                $hasSSD = $false
                $hasHDD = $false
                foreach ($d in $disks) {
                    if ($d.MediaType -eq 'SSD') { $hasSSD = $true }
                    elseif ($d.MediaType -eq 'HDD') { $hasHDD = $true }
                }

                $summary = @()
                if ($hasSSD) {
                    # Ensure TRIM (delete notify) is enabled for SSDs.
                    & fsutil.exe behavior set DisableDeleteNotify 0 2>$null | Out-Null
                    $summary += "SSD: TRIM ON"
                }
                if ($hasHDD) {
                    # Keep/enable the built-in weekly scheduled defrag for HDDs.
                    try { Enable-ScheduledTask -TaskName "ScheduledDefrag" -TaskPath "\Microsoft\Windows\Defrag\" -ErrorAction Ignore | Out-Null } catch {}
                    $summary += "HDD: Scheduled Defrag ON"
                }
                if (-not $hasSSD -and -not $hasHDD) { $summary += "N/A" }

                Write-Log (T 'LogDiskOptimizeOk' ($summary -join ", ")) "OK"
            } catch {
                Write-Log (T 'LogMoreError' "DiskOptimize" $_.Exception.Message) "ERROR"
            }
        }
    }

    Write-Log (T 'LogMoreDone') "OK"
}

# ============================================================================
# 11. FUNCTION 6 - BLOCK AUTOMATIC DRIVERS (WINDOWS UPDATE)
# ============================================================================

function Set-WgoBlockDriverUpdates {
    Write-Log (T 'LogDriversStart') "INFO"
    try {
        $driverSearchKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
        $wuPolicyKey     = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

        if (-not (Test-Path $driverSearchKey)) { New-Item -Path $driverSearchKey -Force | Out-Null }
        if (-not (Test-Path $wuPolicyKey))     { New-Item -Path $wuPolicyKey -Force | Out-Null }

        New-ItemProperty -Path $driverSearchKey -Name "SearchOrderConfig" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $wuPolicyKey -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -PropertyType DWord -Force | Out-Null

        Write-Log (T 'LogDriversOk') "OK"
    } catch {
        Write-Log (T 'LogDriversError' $_.Exception.Message) "ERROR"
    }
}

# ============================================================================
# 12. FUNCTION 7 - VIRTUAL MEMORY (PAGEFILE) TUNING
# ============================================================================

function Set-WgoPagefile {
    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        $ramMB = [Math]::Round($cs.TotalPhysicalMemory / 1MB)
        $pageMB = [Math]::Round($ramMB * 1.5)

        Write-Log (T 'LogPagefileRam' $ramMB $pageMB) "INFO"

        # Disable automatic management
        $cs2 = Get-CimInstance -ClassName Win32_ComputerSystem
        if ($cs2.AutomaticManagedPagefile) {
            Set-CimInstance -InputObject $cs2 -Property @{ AutomaticManagedPagefile = $false } -ErrorAction Stop
        }

        $sysDrive = $env:SystemDrive
        $pagefilePath = "$sysDrive\pagefile.sys"

        $existing = Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction Ignore |
                    Where-Object { $_.Name -eq $pagefilePath }

        if ($existing) {
            Set-CimInstance -InputObject $existing -Property @{ InitialSize = $pageMB; MaximumSize = $pageMB } -ErrorAction Stop
        } else {
            $newPF = New-CimInstance -ClassName Win32_PageFileSetting -Property @{
                Name        = $pagefilePath
                InitialSize = $pageMB
                MaximumSize = $pageMB
            } -ErrorAction Stop
        }

        Write-Log (T 'LogPagefileOk' $pageMB) "OK"
    } catch {
        Write-Log (T 'LogPagefileError' $_.Exception.Message) "ERROR"
    }
}

# ============================================================================
# 12-B. FUNCTION 9 - RESTORE DEFAULTS
# ============================================================================
# Reverts the policy/registry keys and services touched by this script back
# to a state equivalent to a clean Windows install (removes the keys/values
# we created, re-enables the services and scheduled tasks we disabled).
# It intentionally does NOT touch bloatware removal, visual effects, pagefile
# size or app installations, since those are not easily "undoable" 1:1.

function Restore-WgoDefaults {
    Write-Log (T 'LogRestoreDefaultsStart') "INFO"
    try {
        # --- Registry keys created/modified by this script (HKLM policies) ---
        $keysToRemove = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting",
            "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
            "HKLM:\SOFTWARE\Policies\Microsoft\Edge",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization",
            "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
        )
        foreach ($k in $keysToRemove) {
            if (Test-Path $k) { Remove-Item -Path $k -Recurse -Force -ErrorAction Ignore }
        }

        # --- HKCU keys/values created/modified by this script ---
        $hkcuAdvKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        foreach ($name in @("DisableSearchBoxSuggestions","TaskbarDa","EnableSnapAssistFlyout","SnapFill","SnapAssist","DisallowShaking")) {
            Remove-ItemProperty -Path $hkcuAdvKey -Name $name -Force -ErrorAction Ignore
        }
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Recurse -Force -ErrorAction Ignore
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Recurse -Force -ErrorAction Ignore
        Remove-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Recurse -Force -ErrorAction Ignore
        Remove-Item -Path "HKCU:\Software\Microsoft\InputPersonalization" -Recurse -Force -ErrorAction Ignore
        Remove-Item -Path "HKCU:\Software\Microsoft\Clipboard" -Recurse -Force -ErrorAction Ignore
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Recurse -Force -ErrorAction Ignore
        Remove-Item -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common" -Recurse -Force -ErrorAction Ignore
        Remove-Item -Path "HKCU:\Software\Policies\Microsoft\office\16.0\osm" -Recurse -Force -ErrorAction Ignore

        # --- Local search (restore Bing/web search + Cortana consent defaults) ---
        Remove-ItemProperty -Path $hkcuAdvKey -Name "DisableSearchBoxSuggestions" -Force -ErrorAction Ignore
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Force -ErrorAction Ignore
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Force -ErrorAction Ignore

        # --- Network / multimedia throttling back to Windows defaults ---
        $mmKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        if (Test-Path $mmKey) {
            New-ItemProperty -Path $mmKey -Name "NetworkThrottlingIndex" -Value 10 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $mmKey -Name "SystemResponsiveness" -Value 20 -PropertyType DWord -Force | Out-Null
        }
        $ifaceRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
        if (Test-Path $ifaceRoot) {
            Get-ChildItem -Path $ifaceRoot -ErrorAction Ignore | ForEach-Object {
                Remove-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Force -ErrorAction Ignore
                Remove-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Force -ErrorAction Ignore
            }
        }

        # --- Boot menu timeout back to the Windows default (30s) ---
        & bcdedit.exe /timeout 30 2>$null | Out-Null

        # --- Re-enable services disabled by this script ---
        foreach ($svcName in @("DiagTrack", "dmwappushservice")) {
            $svc = Get-Service -Name $svcName -ErrorAction Ignore
            if ($svc) {
                Set-Service -Name $svcName -StartupType Automatic -ErrorAction Ignore
                Start-Service -Name $svcName -ErrorAction Ignore
            }
        }

        # --- Re-enable scheduled tasks disabled by this script ---
        $tasksToReenable = @(
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
            "\Microsoft\Windows\Autochk\Proxy",
            "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
            "\Microsoft\Windows\Feedback\Siuf\DmClient",
            "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
            "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
            "\Microsoft\Office\OfficeTelemetryAgentFallBack2016",
            "\Microsoft\Office\OfficeTelemetryAgentLogOn2016"
        )
        foreach ($task in $tasksToReenable) {
            try { Enable-ScheduledTask -TaskPath (Split-Path $task) -TaskName (Split-Path $task -Leaf) -ErrorAction Ignore | Out-Null } catch {}
        }

        Write-Log (T 'LogRestoreDefaultsOk') "OK"
    } catch {
        Write-Log (T 'LogRestoreDefaultsError' $_.Exception.Message) "ERROR"
    }
}

# ============================================================================
# 13. FUNCTION 8 - APPLICATION INSTALLER (CHOCOLATEY)
# ============================================================================

$Global:WgoChocoPath = $null

# Resolves the actual path to choco.exe, checking PATH first and then the well-known
# installation folders (works even if PATH has not been refreshed yet in this process).
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

# Refreshes Path / ChocolateyInstall in the CURRENT process from the machine + user
# environment, so a just-installed choco.exe can be used right away without having to
# close and reopen the elevated PowerShell session.
function Update-WgoSessionEnvironment {
    try {
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = @($machinePath, $userPath) -join ";"

        $machineChoco = [System.Environment]::GetEnvironmentVariable("ChocolateyInstall", "Machine")
        if ($machineChoco) { $env:ChocolateyInstall = $machineChoco }
    } catch {}
}

# Installs Chocolatey using the official bootstrapper. This is only called from the
# dedicated "Install Chocolatey" button, so clicking that button IS the user's
# confirmation - no extra dialog needed here. Returns the resolved path to
# choco.exe, or $null if the installation failed.
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

# Updates the small status line above the app list to reflect whether Chocolatey
# is currently detected. Safe to call from the UI thread or a background thread.
function Update-WgoChocoStatus {
    $found = [bool](Find-WgoChocolatey)
    $text = if ($found) { T 'ChocoStatusFound' } else { T 'ChocoStatusNotFound' }
    if ($window.Dispatcher.CheckAccess()) {
        $ctrl['txtChocoStatus'].Text = $text
    } else {
        $window.Dispatcher.Invoke([action]{ $ctrl['txtChocoStatus'].Text = $text })
    }
}

# Pure check: does NOT install anything. The app-install flow assumes Chocolatey
# is already installed via the dedicated "Install Chocolatey" button above. If it
# is not found, this logs a clear message telling the user what to do and returns
# $false, instead of silently doing nothing.
function Test-WgoChocolatey {
    $chocoExe = Find-WgoChocolatey
    if ($chocoExe) { return $true }
    Write-Log (T 'LogChocoRequiredFirst') "ERROR"
    return $false
}

# ============================================================================
# 13b. APP CATALOG (winget id + choco id per key)
# ============================================================================

# Central catalog: the key matches each CheckBox's Tag in the XAML.
# Winget is tried first (built into Windows 10 2004+ / Windows 11, no bootstrap
# needed, no external script download), Chocolatey is used as an automatic
# fallback only if winget is missing or does not have the package.
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
}

# Locates winget.exe (App Installer), caching the resolved path like Find-WgoChocolatey.
$Global:WgoWingetPath = $null
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

# Tries to install a package via winget. Returns $true on success (including
# "already installed"), $false if winget is unavailable, the package was not
# found, or the install failed for any other reason (caller should then try
# the Chocolatey fallback).
function Install-ViaWinget {
    param([string]$WingetId, [string]$DisplayName)

    $wingetExe = Find-WgoWinget
    if (-not $wingetExe) { return $false }

    try {
        # Check if it's already installed first, to skip a redundant install
        # and to correctly report "already installed" in the log.
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

        # --disable-interactivity + --accept-*-agreements are critical: without
        # them, winget can sit forever waiting for a source-agreement prompt
        # that never appears in a non-interactive/background context, which
        # looks exactly like a silent hang with no log output.
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

# Installs a package via Chocolatey (requires it to already be installed via
# the dedicated "Install Chocolatey" button). Used as the automatic fallback
# when winget is unavailable or doesn't have the package.
function Install-ViaChocolatey {
    param([string]$ChocoId, [string]$DisplayName)

    $chocoExe = Find-WgoChocolatey
    if (-not $chocoExe) {
        Write-Log (T 'LogChocoRequiredFirst') "ERROR"
        return
    }

    try {
        # Check whether the package is already installed via Chocolatey before
        # attempting to (re)install it. "choco list --local-only" with -r (limit
        # output) prints "id|version" lines for locally-installed packages, one per
        # line, which is easy to match exactly against $ChocoId.
        $listArgs = @("list", "--local-only", "--exact", $ChocoId, "-r")
        $listOutput = & $chocoExe @listArgs 2>$null
        $alreadyInstalled = $false
        foreach ($line in $listOutput) {
            if ($line -match "^\Q$ChocoId\E\|") { $alreadyInstalled = $true; break }
        }

        if ($alreadyInstalled) {
            Write-Log (T 'LogInstallAlready' $DisplayName) "OK"
            return
        }

        $logFile = "$env:TEMP\wgo_choco_$ChocoId.log"
        $errFile = "$env:TEMP\wgo_choco_$ChocoId.err.log"

        $installArgs = @(
            "install", $ChocoId, "-y",
            "--no-progress",
            "--limit-output",
            "--accept-license"
        )

        $proc = Start-Process -FilePath $chocoExe -ArgumentList $installArgs -NoNewWindow -Wait -PassThru `
                    -RedirectStandardOutput $logFile -RedirectStandardError $errFile -ErrorAction Stop

        # Chocolatey exit codes: 0 = success (including "already installed", which choco
        # detects and reports on its own without failing); 1641 / 3010 = success but a
        # reboot is needed/pending. Anything else is a real failure.
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
    } catch {
        Write-Log (T 'LogInstallError' $DisplayName $_.Exception.Message) "ERROR"
    }
}

# Orchestrator called for each selected app: tries winget first (fast, built
# into Windows, no bootstrap needed), and automatically falls back to
# Chocolatey if winget is unavailable or fails for this specific package.
function Install-WgoApp {
    param([string]$Key, [string]$DisplayName)

    $entry = $Global:WgoAppCatalog[$Key]
    if (-not $entry) {
        Write-Log (T 'LogInstallError' $DisplayName "unknown app key: $Key") "ERROR"
        return
    }

    Write-Log (T 'LogInstallStart' $DisplayName $entry.WingetId) "INFO"

    if (Install-ViaWinget -WingetId $entry.WingetId -DisplayName $DisplayName) {
        return
    }

    Write-Log (T 'LogWingetNotAvailable' $DisplayName) "WARN"
    Install-ViaChocolatey -ChocoId $entry.ChocoId -DisplayName $DisplayName
}

# ============================================================================
# 13c. FUNCTIONS ALLOWED INSIDE A WORKER RUNSPACE (background tasks)
# ============================================================================
# Used by Start-WgoBackgroundTask to clone these functions into each
# dedicated worker Runspace it creates. Keep this list in sync whenever a
# new function needs to be callable from inside a Start-WgoBackgroundTask
# scriptblock (i.e. from a background button action).
$Global:WgoSharedFunctionNames = @(
    'Write-Log', 'T', 'Show-WgoFatalError',
    'New-WgoRestorePoint', 'Remove-WgoBloatware', 'Test-WgoProtectedPackage',
    'Set-WgoLocalSearch', 'Set-WgoVisualEffects', 'Set-WgoPrivacyPolicies',
    'Set-WgoExtraPrivacy', 'Set-WgoAdvancedTweaks', 'Set-WgoBlockDriverUpdates', 'Set-WgoPagefile',
    'Set-WgoMoreOptimizations', 'Restore-WgoDefaults',
    'Find-WgoChocolatey', 'Update-WgoSessionEnvironment', 'Install-WgoChocolatey',
    'Test-WgoChocolatey', 'Find-WgoWinget', 'Install-ViaWinget',
    'Install-ViaChocolatey', 'Install-WgoApp'
)

# ============================================================================
# 13-B. FUNCTION 10 - EXTERNAL SCRIPTS LAUNCHER
# ============================================================================
# These are independent, third-party projects (not authored by WGO). Each one
# manages its own UI/console and its own UAC elevation, so WGO only needs to
# spawn a new (non-blocking) PowerShell process pointed at the same command
# the user would type manually - it never runs inside WGO's own process or
# background runspace. Everything is logged to WGO's own log screen.

function Start-WgoExternalScript {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Name,
        [ValidateSet('iwr', 'irm')][string]$Downloader = 'irm'
    )
    try {
        Write-Log (T 'LogExtScriptStart' $Name) "INFO"

        $cmd = if ($Downloader -eq 'iwr') { "iwr -useb '$Url' | iex" } else { "irm '$Url' | iex" }

        # -NoExit keeps the new console window open after the script finishes
        # so the user can read its final output (e.g. the MAS activation
        # result); the AMD Optimizer is a WPF window and simply leaves an
        # idle console behind it, which the user can close manually.
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-Command", $cmd `
            -ErrorAction Stop | Out-Null

        Write-Log (T 'LogExtScriptLaunched' $Name) "OK"
    } catch {
        Write-Log (T 'LogExtScriptError' $Name $_.Exception.Message) "ERROR"
    }
}

# ============================================================================
# 14. UI EVENTS
# ============================================================================

$ctrl['cmbLanguage'].Add_SelectionChanged({
    $item = $ctrl['cmbLanguage'].SelectedItem
    if ($item -ne $null) {
        $code = $item.Content.ToString()
        Update-UILanguage -Code $code
        Write-Log (T 'LogLangChanged' $code) "INFO"
    }
})

$ctrl['chkSelectAll'].Add_Click({
    $isChecked = [bool]$ctrl['chkSelectAll'].IsChecked
    foreach ($n in $script:optimizationCheckboxNames) {
        if ($ctrl[$n]) { $ctrl[$n].IsChecked = $isChecked }
    }
})

$ctrl['btnCreateRestore'].Add_Click({
    $ctrl['btnCreateRestore'].IsEnabled = $false
    Start-WgoBackgroundTask -ScriptBlock {
        try {
            New-WgoRestorePoint | Out-Null
        } catch {
            # Any unexpected error must be visible in the log instead of being
            # silently swallowed by the background task.
            Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
        }
    } -OnCompleted {
        $ctrl['btnCreateRestore'].IsEnabled = $true
    }
})

$ctrl['btnRunSelected'].Add_Click({
    $ctrl['btnRunSelected'].IsEnabled = $false
    $doBloat    = [bool]$ctrl['chkBloat'].IsChecked
    $doSearch   = [bool]$ctrl['chkSearch'].IsChecked
    $doVisual   = [bool]$ctrl['chkVisual'].IsChecked
    $doPrivacy  = [bool]$ctrl['chkPrivacy'].IsChecked
    $doDrivers  = [bool]$ctrl['chkDrivers'].IsChecked
    $doPagefile = [bool]$ctrl['chkPagefile'].IsChecked

    $doAdvertisingId  = [bool]$ctrl['chkAdvertisingId'].IsChecked
    $doTailoredExp    = [bool]$ctrl['chkTailoredExp'].IsChecked
    $doDiagTrackSvc   = [bool]$ctrl['chkDiagTrackSvc'].IsChecked
    $doCopilotBlock   = [bool]$ctrl['chkCopilotBlock'].IsChecked
    $doInputTelemetry = [bool]$ctrl['chkInputTelemetry'].IsChecked

    $doDiagTrackFull  = [bool]$ctrl['chkDiagTrackFull'].IsChecked
    $doEdgeWidgets    = [bool]$ctrl['chkEdgeWidgets'].IsChecked
    $doDeliveryOpt    = [bool]$ctrl['chkDeliveryOpt'].IsChecked
    $doAppsBackground = [bool]$ctrl['chkAppsBackground'].IsChecked
    $doNetworkLatency = [bool]$ctrl['chkNetworkLatency'].IsChecked

    $doHibernation     = [bool]$ctrl['chkHibernation'].IsChecked
    $doPowerPlan       = [bool]$ctrl['chkPowerPlan'].IsChecked
    $doTempCleanup     = [bool]$ctrl['chkTempCleanup'].IsChecked
    $doHotCorners      = [bool]$ctrl['chkHotCorners'].IsChecked
    $doRecallBlock     = [bool]$ctrl['chkRecallBlock'].IsChecked
    $doBootTimeout     = [bool]$ctrl['chkBootTimeout'].IsChecked
    $doOfficeTelemetry = [bool]$ctrl['chkOfficeTelemetry'].IsChecked
    $doExtraSchedTasks = [bool]$ctrl['chkExtraSchedTasks'].IsChecked
    $doDiskOptimize    = [bool]$ctrl['chkDiskOptimize'].IsChecked

    $doDryRun = [bool]$ctrl['chkDryRun'].IsChecked

    Start-WgoBackgroundTask -ScriptBlock {
        param($doBloat, $doSearch, $doVisual, $doPrivacy, $doDrivers, $doPagefile,
              $doAdvertisingId, $doTailoredExp, $doDiagTrackSvc, $doCopilotBlock, $doInputTelemetry,
              $doDiagTrackFull, $doEdgeWidgets, $doDeliveryOpt, $doAppsBackground, $doNetworkLatency,
              $doHibernation, $doPowerPlan, $doTempCleanup, $doHotCorners, $doRecallBlock,
              $doBootTimeout, $doOfficeTelemetry, $doExtraSchedTasks, $doDiskOptimize, $doDryRun)
        try {
            Write-Log (T 'LogOptStart') "INFO"

            if ($doDryRun) {
                # Dry Run: nothing is written to the system. Log every selected
                # item using its own checkbox label, so the user can review the
                # exact list of changes that WOULD be made.
                Write-Log (T 'LogDryRunNote') "WARN"
                $dryItems = @(
                    @{ Flag = $doBloat;           Key = 'ChkBloat' },
                    @{ Flag = $doSearch;          Key = 'ChkSearch' },
                    @{ Flag = $doVisual;          Key = 'ChkVisual' },
                    @{ Flag = $doPrivacy;         Key = 'ChkPrivacy' },
                    @{ Flag = $doDrivers;         Key = 'ChkDrivers' },
                    @{ Flag = $doPagefile;        Key = 'ChkPagefile' },
                    @{ Flag = $doAdvertisingId;   Key = 'ChkAdvertisingId' },
                    @{ Flag = $doTailoredExp;     Key = 'ChkTailoredExp' },
                    @{ Flag = $doDiagTrackSvc;    Key = 'ChkDiagTrackSvc' },
                    @{ Flag = $doCopilotBlock;    Key = 'ChkCopilotBlock' },
                    @{ Flag = $doInputTelemetry;  Key = 'ChkInputTelemetry' },
                    @{ Flag = $doDiagTrackFull;   Key = 'ChkDiagTrackFull' },
                    @{ Flag = $doEdgeWidgets;     Key = 'ChkEdgeWidgets' },
                    @{ Flag = $doDeliveryOpt;     Key = 'ChkDeliveryOpt' },
                    @{ Flag = $doAppsBackground;  Key = 'ChkAppsBackground' },
                    @{ Flag = $doNetworkLatency;  Key = 'ChkNetworkLatency' }
                )
                foreach ($item in $dryItems) {
                    if ($item.Flag) { Write-Log (T 'LogDryRunPrefix' (T $item.Key)) "INFO" }
                }
                # The "System Cleanup & Performance" group logs its own
                # per-feature dry-run lines internally.
                Set-WgoMoreOptimizations -Hibernation $doHibernation -PowerPlan $doPowerPlan `
                    -TempCleanup $doTempCleanup -HotCorners $doHotCorners -RecallBlock $doRecallBlock `
                    -BootTimeout $doBootTimeout -OfficeTelemetry $doOfficeTelemetry `
                    -ExtraSchedTasks $doExtraSchedTasks -DiskOptimize $doDiskOptimize -DryRun $true
            } else {
                New-WgoRestorePoint | Out-Null

                if ($doBloat)    { Remove-WgoBloatware }
                if ($doSearch)   { Set-WgoLocalSearch }
                if ($doVisual)   { Set-WgoVisualEffects }
                if ($doPrivacy)  { Set-WgoPrivacyPolicies }
                if ($doDrivers)  { Set-WgoBlockDriverUpdates }
                if ($doPagefile) { Set-WgoPagefile }

                Set-WgoExtraPrivacy -AdvertisingId $doAdvertisingId -TailoredExp $doTailoredExp `
                    -DiagTrackSvc $doDiagTrackSvc -CopilotBlock $doCopilotBlock -InputTelemetry $doInputTelemetry

                Set-WgoAdvancedTweaks -DiagTrackFull $doDiagTrackFull -EdgeWidgets $doEdgeWidgets `
                    -DeliveryOpt $doDeliveryOpt -AppsBackground $doAppsBackground -NetworkLatency $doNetworkLatency

                Set-WgoMoreOptimizations -Hibernation $doHibernation -PowerPlan $doPowerPlan `
                    -TempCleanup $doTempCleanup -HotCorners $doHotCorners -RecallBlock $doRecallBlock `
                    -BootTimeout $doBootTimeout -OfficeTelemetry $doOfficeTelemetry `
                    -ExtraSchedTasks $doExtraSchedTasks -DiskOptimize $doDiskOptimize -DryRun $false
            }

            Write-Log (T 'LogOptDone') "OK"
        } catch {
            # Any unexpected error must be visible in the log instead of being
            # silently swallowed by the background task.
            Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
        }
    } -ArgumentList @($doBloat, $doSearch, $doVisual, $doPrivacy, $doDrivers, $doPagefile,
                       $doAdvertisingId, $doTailoredExp, $doDiagTrackSvc, $doCopilotBlock, $doInputTelemetry,
                       $doDiagTrackFull, $doEdgeWidgets, $doDeliveryOpt, $doAppsBackground, $doNetworkLatency,
                       $doHibernation, $doPowerPlan, $doTempCleanup, $doHotCorners, $doRecallBlock,
                       $doBootTimeout, $doOfficeTelemetry, $doExtraSchedTasks, $doDiskOptimize, $doDryRun) `
      -OnCompleted {
        $ctrl['btnRunSelected'].IsEnabled = $true
    }
})

$ctrl['btnRestoreDefaults'].Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        (T 'LogRestoreDefaultsStart'),
        "WGO",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $ctrl['btnRestoreDefaults'].IsEnabled = $false
    Start-WgoBackgroundTask -ScriptBlock {
        try {
            Restore-WgoDefaults
        } catch {
            Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
        }
    } -OnCompleted {
        $ctrl['btnRestoreDefaults'].IsEnabled = $true
    }
})

$ctrl['btnExportProfile'].Add_Click({
    try {
        Write-Log (T 'LogExportStart') "INFO"
        $dlg = New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Filter   = "JSON (*.json)|*.json"
        $dlg.FileName = "WGO-Profile.json"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $profile = @{}
            foreach ($n in $script:optimizationCheckboxNames) {
                if ($ctrl[$n]) { $profile[$n] = [bool]$ctrl[$n].IsChecked }
            }
            $profile['chkDryRun'] = [bool]$ctrl['chkDryRun'].IsChecked
            ($profile | ConvertTo-Json) | Set-Content -Path $dlg.FileName -Encoding UTF8
            Write-Log (T 'LogExportOk' $dlg.FileName) "OK"
        } else {
            Write-Log (T 'LogExportCancelled') "WARN"
        }
    } catch {
        Write-Log (T 'LogExportError' $_.Exception.Message) "ERROR"
    }
})

$ctrl['btnImportProfile'].Add_Click({
    try {
        Write-Log (T 'LogImportStart') "INFO"
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Filter = "JSON (*.json)|*.json"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $profile = Get-Content -Path $dlg.FileName -Raw | ConvertFrom-Json
            foreach ($prop in $profile.PSObject.Properties) {
                if ($ctrl[$prop.Name]) { $ctrl[$prop.Name].IsChecked = [bool]$prop.Value }
            }
            Write-Log (T 'LogImportOk' $dlg.FileName) "OK"
        } else {
            Write-Log (T 'LogImportCancelled') "WARN"
        }
    } catch {
        Write-Log (T 'LogImportError' $_.Exception.Message) "ERROR"
    }
})

$ctrl['btnInstallChoco'].Add_Click({
    try {
        $ctrl['btnInstallChoco'].IsEnabled = $false
        Start-WgoBackgroundTask -ScriptBlock {
            try {
                Install-WgoChocolatey | Out-Null
            } catch {
                # Any unexpected error must be visible in the log instead of being
                # silently swallowed by the background task.
                Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
            }
        } -OnCompleted {
            # Runs on the UI thread: safe to touch $ctrl here.
            Update-WgoChocoStatus
            $ctrl['btnInstallChoco'].IsEnabled = $true
        }
    } catch {
        Show-WgoFatalError "btnInstallChoco click handler failed: $($_.Exception.Message)"
        $ctrl['btnInstallChoco'].IsEnabled = $true
    }
})

$ctrl['btnInstallApps'].Add_Click({
  try {
    $ctrl['btnInstallApps'].IsEnabled = $false

    $appChecks = @(
        @{ Chk = $ctrl['chkFirefox']; Name = "Mozilla Firefox" },
        @{ Chk = $ctrl['chkNanaZip']; Name = "NanaZip" },
        @{ Chk = $ctrl['chkNpp'];     Name = "Notepad++" },
        @{ Chk = $ctrl['chkFdm'];     Name = "Free Download Manager" },
        @{ Chk = $ctrl['chkQbt'];     Name = "qBittorrent" },
        @{ Chk = $ctrl['chkSteam'];   Name = "Steam" },
        @{ Chk = $ctrl['chkEpic'];    Name = "Epic Games Launcher" },
        @{ Chk = $ctrl['chkGog'];     Name = "GOG Galaxy" },
        @{ Chk = $ctrl['chkSevenZip']; Name = "7-Zip" },
        @{ Chk = $ctrl['chkWiztree'];  Name = "WizTree" },
        @{ Chk = $ctrl['chkMemreduct']; Name = "Mem Reduct" },
        @{ Chk = $ctrl['chkBleachbit']; Name = "BleachBit" },
        @{ Chk = $ctrl['chkMoonlight']; Name = "Moonlight" },
        @{ Chk = $ctrl['chkSunshine'];  Name = "Sunshine" }
    )

    $selected = @()
    foreach ($a in $appChecks) {
        if ($a.Chk.IsChecked) {
            $selected += @{ Id = $a.Chk.Tag; Name = $a.Name }
        }
    }

    if ($selected.Count -eq 0) {
        Write-Log (T 'LogNoAppsSelected') "WARN"
        $ctrl['btnInstallApps'].IsEnabled = $true
        return
    }

    # $selected is passed via -ArgumentList (plain data: an array of
    # hashtables), not captured via closure - closures over UI-thread
    # variables do not survive being moved into a different runspace.
    Start-WgoBackgroundTask -ScriptBlock {
        param($selected)
        try {
            Write-Log (T 'LogInstallBatchStart') "INFO"
            foreach ($app in $selected) {
                # Install-WgoApp tries winget first and only falls back to
                # Chocolatey per-app if winget can't do it, so we don't gate
                # the whole batch on Chocolatey being installed anymore.
                Install-WgoApp -Key $app.Id -DisplayName $app.Name
            }
            Write-Log (T 'LogInstallBatchDone') "OK"
        } catch {
            # Any unexpected error must be visible in the log instead of being
            # silently swallowed by the background task.
            Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
        }
    } -ArgumentList @(,$selected) -OnCompleted {
        $ctrl['btnInstallApps'].IsEnabled = $true
    }
  } catch {
    Show-WgoFatalError "btnInstallApps click handler failed: $($_.Exception.Message)"
    $ctrl['btnInstallApps'].IsEnabled = $true
  }
})

$ctrl['btnRunAmdOptimizer'].Add_Click({
    Start-WgoExternalScript -Url "https://raw.githubusercontent.com/Khotyz/AMDSTABILITYOPTIMIZER/main/AMD-Stability-Optimizer.ps1" `
        -Name "AMD Stability Optimizer" -Downloader 'iwr'
})

$ctrl['btnRunMassgrave'].Add_Click({
    Start-WgoExternalScript -Url "https://get.activated.win" `
        -Name "Microsoft Activation Scripts (MASSGRAVE)" -Downloader 'irm'
})

# ============================================================================
# 15. STARTUP
# ============================================================================

Update-UILanguage -Code $Global:CurrentLangCode
Write-Log $Lang[$Global:CurrentLangCode].MsgReady "INFO"

$window.ShowDialog() | Out-Null
