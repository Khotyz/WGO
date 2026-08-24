# Wgo.UI.psm1 - UI initialization, events, themes, language

$Global:WgoUI_Initialized = $false
$Global:WgoUI_Window = $null
$Global:WgoUI_Ctrl = @{}
$Global:WgoUI_OptimizationCheckboxNames = @(
    'chkBloat','chkSearch','chkVisual','chkPrivacy','chkDrivers','chkPagefile',
    'chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry',
    'chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground','chkNetworkLatency','chkHungAppTimeout',
    'chkDisableSysMain','chkDisableWSearch','chkDisableSpooler','chkWinSxSCleanup',
    'chkHibernation','chkPowerPlan','chkTempCleanup','chkHotCorners',
    'chkBootTimeout','chkOfficeTelemetry','chkExtraSchedTasks','chkDiskOptimize','chkHagsGameMode','chkUltimatePerf','chkKernelGamingPriority','chkGameDvrDisable','chkInputLagReduction',
    'chkSearchIndexOptimize','chkGhostAdapters','chkFastStartup',
    'chkResidualServices','chkStandbyListClean','chkLargeSystemCache','chkAutoStandbyClean',
    'chkDisableCoreParking','chkDisableHPET','chkTimerResolution',
    'chkIncreaseTdrNvidia','chkDisableNvidiaTelemetry',
    'chkDisableNagle','chkDisableIPv6','chkRssOptimize',
    'chkHostsBlock','chkPrivacyDeep','chkCacheClean','chkUiCleanup','chkTcpAutotuning',
    'chkDoH','chkFastShutdown','chkPrefetchSSD','chkRemoveWinBackup','chkTcpIpReset',
    'chkRemoveOnedrive','chkDisableGameBar','chkDisableStore','chkDisableWer'
)

# Risky tweaks are intentionally excluded from Select All, profile presets, and
# last-run persistence - they must be re-confirmed by the user every single time.
$Global:WgoUI_RiskyCheckboxNames = @(
    'chkRiskyUAC','chkRiskySmartScreen','chkRiskyDefenderRT','chkRiskyWinUpdateSvc','chkRiskyBits',
    'chkRiskyDisableFirewall','chkRiskyDisableDEP','chkRiskyNvidiaMaxPerf'
)

$Global:WgoUI_Profiles = @{
    Basic = @(
        'chkBloat','chkSearch','chkVisual','chkPrivacy','chkDrivers','chkPagefile',
        'chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry',
        'chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground',
        'chkTempCleanup','chkOfficeTelemetry','chkExtraSchedTasks','chkDiskOptimize',
        'chkSearchIndexOptimize','chkResidualServices',
        'chkCacheClean','chkPrefetchSSD','chkFastShutdown'
    )
    Laptop = @(
        'chkBloat','chkSearch','chkVisual','chkPrivacy','chkDrivers','chkPagefile',
        'chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry',
        'chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground',
        'chkTempCleanup','chkOfficeTelemetry','chkExtraSchedTasks','chkDiskOptimize',
        'chkSearchIndexOptimize','chkResidualServices','chkStandbyListClean','chkGhostAdapters',
        'chkCacheClean','chkPrefetchSSD','chkFastShutdown','chkDoH','chkPrivacyDeep'
    )
    Gamer = @(
        'chkBloat','chkSearch','chkVisual','chkPrivacy','chkDrivers','chkPagefile',
        'chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry',
        'chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground','chkNetworkLatency','chkHungAppTimeout',
        'chkHibernation','chkPowerPlan','chkTempCleanup','chkBootTimeout',
        'chkOfficeTelemetry','chkExtraSchedTasks','chkDiskOptimize','chkHagsGameMode','chkUltimatePerf',
        'chkKernelGamingPriority','chkGameDvrDisable','chkInputLagReduction',
        'chkSearchIndexOptimize','chkGhostAdapters','chkFastStartup','chkResidualServices','chkStandbyListClean',
        'chkCacheClean','chkPrefetchSSD','chkFastShutdown','chkTcpAutotuning','chkLargeSystemCache',
        'chkAutoStandbyClean','chkDisableCoreParking','chkDisableHPET','chkTimerResolution','chkDisableNagle'
    )
    Privacy = @(
        'chkBloat','chkSearch','chkPrivacy',
        'chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry',
        'chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground',
        'chkOfficeTelemetry','chkExtraSchedTasks',
        'chkHostsBlock','chkPrivacyDeep','chkDoH','chkUiCleanup','chkCacheClean'
    )
    Esports = @(
        'chkVisual','chkPagefile',
        'chkCopilotBlock',
        'chkHibernation','chkPowerPlan','chkTempCleanup','chkBootTimeout',
        'chkDiskOptimize','chkHagsGameMode','chkUltimatePerf',
        'chkKernelGamingPriority','chkGameDvrDisable','chkInputLagReduction',
        'chkGhostAdapters','chkFastStartup','chkStandbyListClean','chkLargeSystemCache','chkAutoStandbyClean',
        'chkCacheClean','chkPrefetchSSD','chkFastShutdown','chkTcpAutotuning',
        'chkDisableCoreParking','chkTimerResolution','chkHungAppTimeout',
        'chkIncreaseTdrNvidia','chkDisableNvidiaTelemetry',
        'chkDisableNagle','chkRssOptimize'
    )
}

function Set-WgoUITheme {
    param([ValidateSet('Dark', 'Light')][string]$ThemeName)
    $palettes = @{
        Dark = @{
            BgDark = '#FF1A1B1E'; BgPanel = '#FF232428'; BgCard = '#FF2B2D31'; BgCardHover = '#FF32353A'
            AccentBrush = '#FF4CC2FF'; AccentHoverBrush = '#FF75D2FF'; AccentPressedBrush = '#FF2AA0DE'
            TextPrimary = '#FFF3F4F6'; TextSecondary = '#FF9CA3AF'
            BorderBrush1 = '#FF3A3C41'; BorderAccentBrush = '#552EA6E0'
            LogBg = '#FF141517'; LogText = '#FF7CE0C6'
        }
        Light = @{
            BgDark = '#FFF3F4F6'; BgPanel = '#FFEDEEF1'; BgCard = '#FFFFFFFF'; BgCardHover = '#FFEFF6FC'
            AccentBrush = '#FF0B76C7'; AccentHoverBrush = '#FF2E8FDD'; AccentPressedBrush = '#FF085C9E'
            TextPrimary = '#FF16181B'; TextSecondary = '#FF565C64'
            BorderBrush1 = '#FFD7DBE0'; BorderAccentBrush = '#552E8FDD'
            LogBg = '#FFE9ECEF'; LogText = '#FF0B6B47'
        }
    }
    $palette = $palettes[$ThemeName]
    try {
        $newBrushes = @{}
        foreach ($key in $palette.Keys) {
            [System.Windows.Media.Color]$color = [System.Windows.Media.ColorConverter]::ConvertFromString($palette[$key])
            $newBrushes[$key] = [System.Windows.Media.SolidColorBrush]::new($color)
        }
        foreach ($key in $newBrushes.Keys) {
            if ($Global:WgoUI_Window.Resources.Contains($key)) {
                $Global:WgoUI_Window.Resources.Remove($key)
            }
            $Global:WgoUI_Window.Resources.Add($key, $newBrushes[$key])
        }
        $Global:WgoCurrentTheme = $ThemeName
        if ($Global:WgoUI_Ctrl['btnThemeToggle']) {
            $Global:WgoUI_Ctrl['btnThemeToggle'].Content = if ($ThemeName -eq 'Light') { T 'BtnThemeDark' } else { T 'BtnThemeLight' }
        }
    } catch {
        try { Write-Log ("Theme switch failed: " + $_.Exception.Message) "ERROR" } catch { }
    }
}

function Update-WgoUILanguage {
    param([string]$Code)
    $t = $global:Lang[$Code]
    $Global:CurrentLangCode = $Code
    $c = $Global:WgoUI_Ctrl

    $Global:WgoUI_Window.Title                       = $t.AppTitle
    $c['txtAppTitle'].Text                           = $t.AppTitle
    $c['txtLblLanguage'].Text                        = $t.LblLanguage
    $c['btnThemeToggle'].Content                     = if ($Global:WgoCurrentTheme -eq 'Light') { $t.BtnThemeDark } else { $t.BtnThemeLight }
    $c['txtLogHeader'].Text                          = $t.LogHeader
    $c['tabOptimizations'].Header                    = $t.TabOptimizations
    $c['tabInstaller'].Header                        = $t.TabInstaller
    $c['tabExternalScripts'].Header                  = $t.TabExternalScripts
    $c['tabUtilities'].Header                        = $t.TabUtilities
    $c['chkSelectAll'].Content                       = $t.ChkSelectAll
    $c['grpRestore'].Header                          = $t.GrpRestore
    $c['btnCreateRestore'].Content                   = $t.BtnCreateRestore
    $c['grpBloat'].Header                            = $t.GrpBloat
    $c['chkBloat'].Content                           = $t.ChkBloat
    $c['grpSearch'].Header                           = $t.GrpSearch
    $c['chkSearch'].Content                          = $t.ChkSearch
    $c['grpVisual'].Header                           = $t.GrpVisual
    $c['chkVisual'].Content                          = $t.ChkVisual
    $c['grpPrivacy'].Header                          = $t.GrpPrivacy
    $c['chkPrivacy'].Content                         = $t.ChkPrivacy
    $c['grpDrivers'].Header                          = $t.GrpDrivers
    $c['chkDrivers'].Content                         = $t.ChkDrivers
    $c['grpPagefile'].Header                         = $t.GrpPagefile
    $c['chkPagefile'].Content                        = $t.ChkPagefile
    $c['grpExtraPrivacy'].Header                     = $t.GrpExtraPrivacy
    $c['chkAdvertisingId'].Content                   = $t.ChkAdvertisingId
    $c['chkTailoredExp'].Content                     = $t.ChkTailoredExp
    $c['chkDiagTrackSvc'].Content                    = $t.ChkDiagTrackSvc
    $c['chkCopilotBlock'].Content                    = $t.ChkCopilotBlock
    $c['chkInputTelemetry'].Content                  = $t.ChkInputTelemetry
    $c['grpAdvancedTweaks'].Header                   = $t.GrpAdvancedTweaks
    $c['chkEdgeWidgets'].Content                     = $t.ChkEdgeWidgets
    $c['chkDeliveryOpt'].Content                     = $t.ChkDeliveryOpt
    $c['chkAppsBackground'].Content                  = $t.ChkAppsBackground
    $c['chkNetworkLatency'].Content                  = $t.ChkNetworkLatency
    $c['chkHungAppTimeout'].Content                  = $t.ChkHungAppTimeout
    $c['grpServiceMgmt'].Header                      = $t.GrpServiceMgmt
    $c['chkDisableSysMain'].Content                  = $t.ChkDisableSysMain
    $c['chkDisableWSearch'].Content                  = $t.ChkDisableWSearch
    $c['chkDisableSpooler'].Content                  = $t.ChkDisableSpooler
    $c['chkWinSxSCleanup'].Content                   = $t.ChkWinSxSCleanup
    $c['txtXboxServicesNote'].Text                   = $t.TxtXboxServicesNote
    $c['grpXboxServices'].Header                     = $t.GrpXboxServices
    $c['chkDisableXboxServices'].Content              = $t.ChkDisableXboxServices
    $c['grpMoreOptimizations'].Header                = $t.GrpMoreOptimizations
    $c['chkHibernation'].Content                     = $t.ChkHibernation
    $c['chkPowerPlan'].Content                       = $t.ChkPowerPlan
    $c['chkTempCleanup'].Content                     = $t.ChkTempCleanup
    $c['chkHotCorners'].Content                      = $t.ChkHotCorners
    $c['chkBootTimeout'].Content                     = $t.ChkBootTimeout
    $c['chkOfficeTelemetry'].Content                 = $t.ChkOfficeTelemetry
    $c['chkExtraSchedTasks'].Content                 = $t.ChkExtraSchedTasks
    $c['chkDiskOptimize'].Content                    = $t.ChkDiskOptimize
    $c['chkHagsGameMode'].Content                    = $t.ChkHagsGameMode
    $c['chkUltimatePerf'].Content                    = $t.ChkUltimatePerf
    $c['chkKernelGamingPriority'].Content            = $t.ChkKernelGamingPriority
    $c['chkGameDvrDisable'].Content                  = $t.ChkGameDvrDisable
    $c['chkInputLagReduction'].Content               = $t.ChkInputLagReduction
    $c['chkSearchIndexOptimize'].Content             = $t.ChkSearchIndexOptimize
    $c['chkGhostAdapters'].Content                   = $t.ChkGhostAdapters
    $c['chkFastStartup'].Content                     = $t.ChkFastStartup
    $c['chkResidualServices'].Content                = $t.ChkResidualServices
    $c['chkStandbyListClean'].Content                = $t.ChkStandbyListClean
    $c['chkLargeSystemCache'].Content                = $t.ChkLargeSystemCache
    $c['chkAutoStandbyClean'].Content                = $t.ChkAutoStandbyClean
    $c['grpCpuTimerTweaks'].Header                   = $t.GrpCpuTimerTweaks
    $c['chkDisableCoreParking'].Content              = $t.ChkDisableCoreParking
    $c['chkDisableHPET'].Content                     = $t.ChkDisableHPET
    $c['chkTimerResolution'].Content                 = $t.ChkTimerResolution
    $c['grpGpuTweaks'].Header                        = $t.GrpGpuTweaks
    $c['chkIncreaseTdrNvidia'].Content                = $t.ChkIncreaseTdrNvidia
    $c['chkDisableNvidiaTelemetry'].Content          = $t.ChkDisableNvidiaTelemetry
    $c['grpNetworkAdvanced'].Header                  = $t.GrpNetworkAdvanced
    $c['chkDisableNagle'].Content                    = $t.ChkDisableNagle
    $c['chkDisableIPv6'].Content                     = $t.ChkDisableIPv6
    $c['chkRssOptimize'].Content                     = $t.ChkRssOptimize
    $c['grpExtraTweaks2'].Header                     = $t.GrpExtraTweaks2
    $c['chkHostsBlock'].Content                      = $t.ChkHostsBlock
    $c['chkPrivacyDeep'].Content                     = $t.ChkPrivacyDeep
    $c['chkCacheClean'].Content                      = $t.ChkCacheClean
    $c['chkUiCleanup'].Content                       = $t.ChkUiCleanup
    $c['chkTcpAutotuning'].Content                   = $t.ChkTcpAutotuning
    $c['chkDoH'].Content                             = $t.ChkDoH
    $c['chkFastShutdown'].Content                    = $t.ChkFastShutdown
    $c['chkPrefetchSSD'].Content                     = $t.ChkPrefetchSSD
    $c['chkRemoveWinBackup'].Content                 = $t.ChkRemoveWinBackup
    $c['chkTcpIpReset'].Content                      = $t.ChkTcpIpReset
    $c['chkRemoveOnedrive'].Content                  = $t.ChkRemoveOnedrive
    $c['chkDisableGameBar'].Content                  = $t.ChkDisableGameBar
    $c['chkDisableStore'].Content                    = $t.ChkDisableStore
    $c['chkDisableWer'].Content                      = $t.ChkDisableWer
    $c['txtRiskyWarning'].Text                       = $t.TxtRiskyWarning
    $c['grpRiskyTweaks'].Header                      = $t.GrpRiskyTweaks
    $c['chkRiskyUAC'].Content                        = $t.ChkRiskyUAC
    $c['chkRiskySmartScreen'].Content                = $t.ChkRiskySmartScreen
    $c['chkRiskyDefenderRT'].Content                 = $t.ChkRiskyDefenderRT
    $c['chkRiskyWinUpdateSvc'].Content                = $t.ChkRiskyWinUpdateSvc
    $c['chkRiskyBits'].Content                       = $t.ChkRiskyBits
    $c['chkRiskyDisableFirewall'].Content            = $t.ChkRiskyDisableFirewall
    $c['chkRiskyDisableDEP'].Content                 = $t.ChkRiskyDisableDEP
    $c['chkRiskyNvidiaMaxPerf'].Content               = $t.ChkRiskyNvidiaMaxPerf
    $c['grpProfiles'].Header                         = $t.GrpProfiles
    $c['btnProfileBasic'].Content                    = $t.BtnProfileBasic
    $c['btnProfileLaptop'].Content                   = $t.BtnProfileLaptop
    $c['btnProfileGamer'].Content                    = $t.BtnProfileGamer
    $c['btnProfilePrivacy'].Content                   = $t.BtnProfilePrivacy
    $c['btnProfileEsports'].Content                   = $t.BtnProfileEsports
    $c['btnProfileMax'].Content                      = $t.BtnProfileMax
    $c['chkDryRun'].Content                          = $t.ChkDryRun
    $c['btnRunSelected'].Content                     = $t.BtnRunSelected
    $c['btnRestoreDefaults'].Content                 = $t.BtnRestoreDefaults
    $c['btnExportProfile'].Content                   = $t.BtnExportProfile
    $c['btnImportProfile'].Content                   = $t.BtnImportProfile
    $c['txtChocoRequired'].Text                      = $t.TxtChocoRequired
    $c['btnInstallChoco'].Content                    = $t.BtnInstallChoco
    Update-WgoChocoStatus
    $c['btnInstallApps'].Content                     = $t.BtnInstallApps
    $c['grpAppsBrowsers'].Header                     = $t.GrpAppsBrowsers
    $c['chkFirefox'].Content                         = "Mozilla Firefox"
    $c['txtFirefoxDesc'].Text                        = $t.AppFirefoxDesc
    $c['chkBrave'].Content                           = "Brave"
    $c['txtBraveDesc'].Text                          = $t.AppBraveDesc
    $c['grpAppsFiles'].Header                        = $t.GrpAppsFiles
    $c['chkNanaZip'].Content                         = "NanaZip"
    $c['txtNanaZipDesc'].Text                        = $t.AppNanaZipDesc
    $c['chkSevenZip'].Content                        = "7-Zip"
    $c['txtSevenZipDesc'].Text                       = $t.AppSevenZipDesc
    $c['chkNpp'].Content                             = "Notepad++"
    $c['txtNppDesc'].Text                            = $t.AppNppDesc
    $c['chkWiztree'].Content                         = "WizTree"
    $c['txtWiztreeDesc'].Text                        = $t.AppWiztreeDesc
    $c['grpAppsDownloads'].Header                    = $t.GrpAppsDownloads
    $c['chkFdm'].Content                             = "Free Download Manager"
    $c['txtFdmDesc'].Text                            = $t.AppFdmDesc
    $c['chkQbt'].Content                             = "qBittorrent"
    $c['txtQbtDesc'].Text                            = $t.AppQbtDesc
    $c['grpAppsGaming'].Header                       = $t.GrpAppsGaming
    $c['chkSteam'].Content                           = "Steam"
    $c['txtSteamDesc'].Text                          = $t.AppSteamDesc
    $c['chkEpic'].Content                            = "Epic Games Launcher"
    $c['txtEpicDesc'].Text                           = $t.AppEpicDesc
    $c['chkGog'].Content                             = "GOG Galaxy"
    $c['txtGogDesc'].Text                            = $t.AppGogDesc
    $c['chkMoonlight'].Content                       = "Moonlight"
    $c['txtMoonlightDesc'].Text                      = $t.AppMoonlightDesc
    $c['chkSunshine'].Content                        = "Sunshine"
    $c['txtSunshineDesc'].Text                       = $t.AppSunshineDesc
    $c['grpAppsMonitoring'].Header                   = $t.GrpAppsMonitoring
    $c['chkCpuz'].Content                            = "CPU-Z"
    $c['txtCpuzDesc'].Text                           = $t.AppCpuzDesc
    $c['chkHwmonitor'].Content                       = "HWMonitor"
    $c['txtHwmonitorDesc'].Text                      = $t.AppHwmonitorDesc
    $c['chkMemreduct'].Content                       = "Mem Reduct"
    $c['txtMemreductDesc'].Text                      = $t.AppMemreductDesc
    $c['chkBleachbit'].Content                       = "BleachBit"
    $c['txtBleachbitDesc'].Text                      = $t.AppBleachbitDesc
    $c['grpAppsProductivity'].Header                 = $t.GrpAppsProductivity
    $c['chkNilesoftShell'].Content                   = "Nilesoft Shell"
    $c['txtNilesoftShellDesc'].Text                  = $t.AppNilesoftShellDesc
    $c['chkOptiscalerClient'].Content                = "Optiscaler Client"
    $c['txtOptiscalerClientDesc'].Text               = $t.AppOptiscalerClientDesc
    $c['chkFlowLauncher'].Content                    = "Flow Launcher"
    $c['txtFlowLauncherDesc'].Text                   = $t.AppFlowLauncherDesc
    $c['chkShareX'].Content                          = "ShareX"
    $c['txtShareXDesc'].Text                         = $t.AppShareXDesc
    $c['chkDnsJumper'].Content                       = "DNS Jumper"
    $c['txtDnsJumperDesc'].Text                      = $t.AppDnsJumperDesc
    $c['txtUniGetUITitle'].Text                      = "UniGetUI"
    $c['txtUniGetUIDesc'].Text                       = $t.TxtUniGetUIDesc
    $c['btnRunUniGetUI'].Content                     = $t.BtnRunUniGetUI
    $c['txtExtScriptsWarning'].Text                  = $t.TxtExtScriptsWarning
    $c['txtAmdOptimizerTitle'].Text                  = $t.TxtAmdOptimizerTitle
    $c['txtAmdOptimizerDesc'].Text                   = $t.TxtAmdOptimizerDesc
    $c['btnRunAmdOptimizer'].Content                 = $t.BtnRunAmdOptimizer
    $c['txtMassgraveTitle'].Text                     = $t.TxtMassgraveTitle
    $c['txtMassgraveDesc'].Text                      = $t.TxtMassgraveDesc
    $c['btnRunMassgrave'].Content                    = $t.BtnRunMassgrave
    $c['grpUtilities'].Header                        = $t.GrpUtilities
    $c['txtSafeModeNetTitle'].Text                   = $t.TxtSafeModeNetTitle
    $c['txtSafeModeNetDesc'].Text                    = $t.TxtSafeModeNetDesc
    $c['btnSafeModeNet'].Content                     = $t.TxtSafeModeNetTitle
    $c['txtUefiRestartTitle'].Text                   = $t.TxtUefiRestartTitle
    $c['txtUefiRestartDesc'].Text                    = $t.TxtUefiRestartDesc
    $c['btnUefiRestart'].Content                     = $t.TxtUefiRestartTitle
    $c['txtNormalRestartTitle'].Text                 = $t.TxtNormalRestartTitle
    $c['txtNormalRestartDesc'].Text                  = $t.TxtNormalRestartDesc
    $c['btnNormalRestart'].Content                   = $t.TxtNormalRestartTitle
    $c['grpHiddenTools'].Header                      = $t.GrpHiddenTools
    $c['txtDiskCleanupTitle'].Text                   = $t.TxtDiskCleanupTitle
    $c['txtDiskCleanupDesc'].Text                    = $t.TxtDiskCleanupDesc
    $c['btnDiskCleanup'].Content                     = $t.TxtDiskCleanupTitle
    $c['txtRamCleanTitle'].Text                      = $t.TxtRamCleanTitle
    $c['txtRamCleanDesc'].Text                       = $t.TxtRamCleanDesc
    $c['btnRamClean'].Content                        = $t.TxtRamCleanTitle
    $c['txtResourceMonitorTitle'].Text               = $t.TxtResourceMonitorTitle
    $c['txtResourceMonitorDesc'].Text                = $t.TxtResourceMonitorDesc
    $c['btnResourceMonitor'].Content                 = $t.TxtResourceMonitorTitle
    $c['txtOptimizeDrivesTitle'].Text                = $t.TxtOptimizeDrivesTitle
    $c['txtOptimizeDrivesDesc'].Text                 = $t.TxtOptimizeDrivesDesc
    $c['btnOptimizeDrives'].Content                  = $t.TxtOptimizeDrivesTitle
    $c['txtMemDiagTitle'].Text                       = $t.TxtMemDiagTitle
    $c['txtMemDiagDesc'].Text                        = $t.TxtMemDiagDesc
    $c['btnMemDiag'].Content                         = $t.TxtMemDiagTitle
    $c['grpSystemDiagnostics'].Header                = $t.GrpSystemDiagnostics
    $c['txtSystemIntegrityTitle'].Text               = $t.TxtSystemIntegrityTitle
    $c['txtSystemIntegrityDesc'].Text                = $t.TxtSystemIntegrityDesc
    $c['btnSystemIntegrity'].Content                 = $t.BtnSystemIntegrity
    $c['txtFlushDNSTitle'].Text                      = $t.TxtFlushDNSTitle
    $c['txtFlushDNSDesc'].Text                       = $t.TxtFlushDNSDesc
    $c['btnFlushDNS'].Content                        = $t.BtnFlushDNS
}

function Set-WgoUIProfilePreset {
    param(
        [string[]]$EnabledNames,
        [string]$ProfileLabel
    )
    $c = $Global:WgoUI_Ctrl

    # Presets overwrite EVERY checkbox, including destructive ones (bloatware/app removal,
    # deep privacy app removal, OneDrive removal). If the user had manually unchecked one of
    # these, clicking a preset would silently re-check it and remove things they didn't ask
    # for. Warn and require confirmation before any destructive item gets turned back on.
    $destructiveNames = @('chkBloat', 'chkPrivacyDeep', 'chkRemoveOnedrive')
    $aboutToEnable = @($destructiveNames | Where-Object {
        ($EnabledNames -contains $_) -and $c[$_] -and (-not [bool]$c[$_].IsChecked)
    })
    if ($aboutToEnable.Count -gt 0) {
        $labels = @($aboutToEnable | ForEach-Object {
            switch ($_) {
                'chkBloat'         { $c['chkBloat'].Content }
                'chkPrivacyDeep'   { 'Privacy Deep (removes Xbox app and related components)' }
                'chkRemoveOnedrive'{ $c['chkRemoveOnedrive'].Content }
                default { $_ }
            }
        }) -join "`n - "
        $confirmed = Show-WgoConfirm -Title "WGO - $ProfileLabel" -Message "This profile will also re-enable:`n - $labels`n`nContinue?"
        if (-not $confirmed) {
            Write-Log "Profile '$ProfileLabel' applied without re-enabling: $($aboutToEnable -join ', ')" "INFO"
            $EnabledNames = @($EnabledNames | Where-Object { $aboutToEnable -notcontains $_ })
        }
    }

    foreach ($n in $Global:WgoUI_OptimizationCheckboxNames) {
        if ($c[$n]) { $c[$n].IsChecked = ($EnabledNames -contains $n) }
    }
    $c['chkSelectAll'].IsChecked = ($EnabledNames.Count -ge $Global:WgoUI_OptimizationCheckboxNames.Count)
    Write-Log (T 'LogProfileApplied' $ProfileLabel (T 'BtnRunSelected')) "INFO"
}

function Initialize-WgoUI {
    param([string]$XamlPath)

    # Load XAML
    $xamlContent = Get-Content -Path $XamlPath -Raw
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xamlContent)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $Global:WgoUI_Window = $window

    # Safety net for unhandled exceptions
    $window.Dispatcher.add_UnhandledException({
        try {
            if ($Global:WgoLogQueue) {
                $Global:WgoLogQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')][ERROR] Unhandled UI error: $($_.Exception.Message)")
            }
        } catch { }
        $_.Handled = $true
    })

    # Retrieve controls
    $c = $Global:WgoUI_Ctrl
    $names = @(
        'txtAppTitle','txtLblLanguage','cmbLanguage','btnThemeToggle','txtLogHeader','scrollLog','txtLog',
        'tabOptimizations','tabInstaller','tabExternalScripts','tabUtilities',
        'chkSelectAll','chkDryRun',
        'grpRestore','btnCreateRestore',
        'grpBloat','chkBloat',
        'grpSearch','chkSearch',
        'grpVisual','chkVisual',
        'grpPrivacy','chkPrivacy',
        'grpDrivers','chkDrivers',
        'grpPagefile','chkPagefile',
        'grpExtraPrivacy','chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry',
        'grpAdvancedTweaks','chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground','chkNetworkLatency',
        'grpServiceMgmt','chkDisableSysMain','chkDisableWSearch','chkDisableSpooler','chkWinSxSCleanup',
        'txtXboxServicesNote','grpXboxServices','chkDisableXboxServices',
        'grpMoreOptimizations','chkHibernation','chkPowerPlan','chkTempCleanup','chkHotCorners',
        'chkBootTimeout','chkOfficeTelemetry','chkExtraSchedTasks','chkDiskOptimize','chkHagsGameMode','chkUltimatePerf','chkKernelGamingPriority','chkGameDvrDisable','chkInputLagReduction',
        'chkSearchIndexOptimize','chkGhostAdapters','chkFastStartup',
        'chkResidualServices','chkStandbyListClean','chkLargeSystemCache','chkAutoStandbyClean',
        'grpCpuTimerTweaks','chkDisableCoreParking','chkDisableHPET','chkTimerResolution','chkHungAppTimeout',
        'grpGpuTweaks','chkIncreaseTdrNvidia','chkDisableNvidiaTelemetry',
        'grpNetworkAdvanced','chkDisableNagle','chkDisableIPv6','chkRssOptimize',
        'grpExtraTweaks2','chkHostsBlock','chkPrivacyDeep','chkCacheClean','chkUiCleanup','chkTcpAutotuning',
        'chkDoH','chkFastShutdown','chkPrefetchSSD','chkRemoveWinBackup','chkTcpIpReset',
        'chkRemoveOnedrive','chkDisableGameBar','chkDisableStore','chkDisableWer',
        'txtRiskyWarning','grpRiskyTweaks','chkRiskyUAC','chkRiskySmartScreen','chkRiskyDefenderRT',
        'chkRiskyWinUpdateSvc','chkRiskyBits','chkRiskyDisableFirewall','chkRiskyDisableDEP','chkRiskyNvidiaMaxPerf',
        'grpProfiles','btnProfileBasic','btnProfileLaptop','btnProfileGamer','btnProfilePrivacy','btnProfileEsports','btnProfileMax',
        'btnRunSelected','btnRestoreDefaults','btnExportProfile','btnImportProfile',
        'btnInstallApps',
        'txtChocoRequired','txtChocoStatus','btnInstallChoco',
        'grpAppsBrowsers','chkFirefox','txtFirefoxDesc','chkBrave','txtBraveDesc',
        'grpAppsFiles','chkNanaZip','txtNanaZipDesc','chkSevenZip','txtSevenZipDesc',
        'chkNpp','txtNppDesc','chkWiztree','txtWiztreeDesc',
        'grpAppsDownloads','chkFdm','txtFdmDesc','chkQbt','txtQbtDesc',
        'grpAppsGaming','chkSteam','txtSteamDesc','chkEpic','txtEpicDesc','chkGog','txtGogDesc',
        'chkMoonlight','txtMoonlightDesc','chkSunshine','txtSunshineDesc',
        'grpAppsMonitoring','chkCpuz','txtCpuzDesc','chkHwmonitor','txtHwmonitorDesc',
        'chkMemreduct','txtMemreductDesc','chkBleachbit','txtBleachbitDesc',
        'grpAppsProductivity','chkNilesoftShell','txtNilesoftShellDesc',
        'chkOptiscalerClient','txtOptiscalerClientDesc',
        'chkFlowLauncher','txtFlowLauncherDesc',
        'chkShareX','txtShareXDesc',
        'chkDnsJumper','txtDnsJumperDesc',
        'txtExtScriptsWarning',
        'txtAmdOptimizerTitle','txtAmdOptimizerDesc','btnRunAmdOptimizer',
        'txtMassgraveTitle','txtMassgraveDesc','btnRunMassgrave',
        'txtUniGetUITitle','txtUniGetUIDesc','btnRunUniGetUI',
        'grpUtilities','txtSafeModeNetTitle','txtSafeModeNetDesc','btnSafeModeNet',
        'txtUefiRestartTitle','txtUefiRestartDesc','btnUefiRestart',
        'txtNormalRestartTitle','txtNormalRestartDesc','btnNormalRestart',
        'grpHiddenTools',
        'txtDiskCleanupTitle','txtDiskCleanupDesc','btnDiskCleanup',
        'txtRamCleanTitle','txtRamCleanDesc','btnRamClean',
        'txtResourceMonitorTitle','txtResourceMonitorDesc','btnResourceMonitor',
        'txtOptimizeDrivesTitle','txtOptimizeDrivesDesc','btnOptimizeDrives',
        'txtMemDiagTitle','txtMemDiagDesc','btnMemDiag',
        'grpSystemDiagnostics','txtSystemIntegrityTitle','txtSystemIntegrityDesc','btnSystemIntegrity',
        'txtFlushDNSTitle','txtFlushDNSDesc','btnFlushDNS',
        'pnlOptimizationsActions','pnlInstallerActions','pnlOtherActions',
        'tabMain'
    )
    foreach ($n in $names) { 
        try {
            $c[$n] = $window.FindName($n)
        } catch {
            # Silently ignore if control not found
        }
    }

    # Log timer
    $Global:WgoLogTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Global:WgoLogTimer.Interval = [TimeSpan]::FromMilliseconds(150)
    $Global:WgoLogTimer.Add_Tick({
        $line = $null
        $appended = $false
        while ($Global:WgoLogQueue.TryDequeue([ref]$line)) {
            if ($c['txtLog']) {
                $c['txtLog'].AppendText("$line`r`n")
                $appended = $true
            }
        }
        if ($appended -and $c['txtLog']) { $c['txtLog'].ScrollToEnd() }
    })
    $Global:WgoLogTimer.Start()

    # --- Wire up events ---

    # Tab selection changed - show/hide action panels
    $c['tabMain'].Add_SelectionChanged({
        # Get the selected tab item
        $selectedTab = $c['tabMain'].SelectedItem

        # Hide all panels first
        if ($c['pnlOptimizationsActions']) { $c['pnlOptimizationsActions'].Visibility = 'Collapsed' }
        if ($c['pnlInstallerActions']) { $c['pnlInstallerActions'].Visibility = 'Collapsed' }
        if ($c['pnlOtherActions']) { $c['pnlOtherActions'].Visibility = 'Collapsed' }

        # Show the correct panel based on selected tab
        if ($selectedTab -eq $c['tabOptimizations']) {
            if ($c['pnlOptimizationsActions']) { $c['pnlOptimizationsActions'].Visibility = 'Visible' }
        } elseif ($selectedTab -eq $c['tabInstaller']) {
            if ($c['pnlInstallerActions']) { $c['pnlInstallerActions'].Visibility = 'Visible' }
        } else {
            # For other tabs, show empty panel
            if ($c['pnlOtherActions']) { $c['pnlOtherActions'].Visibility = 'Visible' }
        }
    })

    $c['cmbLanguage'].Add_SelectionChanged({
        $item = $c['cmbLanguage'].SelectedItem
        if ($item -ne $null) {
            $code = $item.Content.ToString()
            Update-WgoUILanguage -Code $code
            Write-Log (T 'LogLangChanged' $code) "INFO"
        }
    })

    $c['btnThemeToggle'].Add_Click({
        $next = if ($Global:WgoCurrentTheme -eq 'Light') { 'Dark' } else { 'Light' }
        Set-WgoUITheme -ThemeName $next
    })

    $c['chkSelectAll'].Add_Click({
        $isChecked = [bool]$c['chkSelectAll'].IsChecked
        foreach ($n in $Global:WgoUI_OptimizationCheckboxNames) {
            if ($c[$n]) { $c[$n].IsChecked = $isChecked }
        }
    })

    # Profile buttons
    $c['btnProfileBasic'].Add_Click({
        Set-WgoUIProfilePreset -EnabledNames $Global:WgoUI_Profiles.Basic -ProfileLabel (T 'BtnProfileBasic')
    })
    $c['btnProfileLaptop'].Add_Click({
        Set-WgoUIProfilePreset -EnabledNames $Global:WgoUI_Profiles.Laptop -ProfileLabel (T 'BtnProfileLaptop')
    })
    $c['btnProfileGamer'].Add_Click({
        Set-WgoUIProfilePreset -EnabledNames $Global:WgoUI_Profiles.Gamer -ProfileLabel (T 'BtnProfileGamer')
    })
    $c['btnProfilePrivacy'].Add_Click({
        Set-WgoUIProfilePreset -EnabledNames $Global:WgoUI_Profiles.Privacy -ProfileLabel (T 'BtnProfilePrivacy')
    })
    $c['btnProfileEsports'].Add_Click({
        Set-WgoUIProfilePreset -EnabledNames $Global:WgoUI_Profiles.Esports -ProfileLabel (T 'BtnProfileEsports')
    })
    $c['btnProfileMax'].Add_Click({
        Set-WgoUIProfilePreset -EnabledNames $Global:WgoUI_OptimizationCheckboxNames -ProfileLabel (T 'BtnProfileMax')
    })

    # Create Restore Point
    $c['btnCreateRestore'].Add_Click({
        $c['btnCreateRestore'].IsEnabled = $false
        Start-WgoBackgroundTask -ScriptBlock {
            try { New-WgoRestorePoint | Out-Null } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
        } -OnCompleted { $c['btnCreateRestore'].IsEnabled = $true }
    })

    # Run Selected Optimizations
    $c['btnRunSelected'].Add_Click({
        $c['btnRunSelected'].IsEnabled = $false
        $doBloat = [bool]$c['chkBloat'].IsChecked
        $doSearch = [bool]$c['chkSearch'].IsChecked
        $doVisual = [bool]$c['chkVisual'].IsChecked
        $doPrivacy = [bool]$c['chkPrivacy'].IsChecked
        $doDrivers = [bool]$c['chkDrivers'].IsChecked
        $doPagefile = [bool]$c['chkPagefile'].IsChecked
        $doAdvertisingId = [bool]$c['chkAdvertisingId'].IsChecked
        $doTailoredExp = [bool]$c['chkTailoredExp'].IsChecked
        $doDiagTrackSvc = [bool]$c['chkDiagTrackSvc'].IsChecked
        $doCopilotBlock = [bool]$c['chkCopilotBlock'].IsChecked
        $doInputTelemetry = [bool]$c['chkInputTelemetry'].IsChecked
        $doEdgeWidgets = [bool]$c['chkEdgeWidgets'].IsChecked
        $doDeliveryOpt = [bool]$c['chkDeliveryOpt'].IsChecked
        $doAppsBackground = [bool]$c['chkAppsBackground'].IsChecked
        $doNetworkLatency = [bool]$c['chkNetworkLatency'].IsChecked
        $doDisableSysMain = [bool]$c['chkDisableSysMain'].IsChecked
        $doDisableWSearch = [bool]$c['chkDisableWSearch'].IsChecked
        $doDisableSpooler = [bool]$c['chkDisableSpooler'].IsChecked
        $doWinSxSCleanup = [bool]$c['chkWinSxSCleanup'].IsChecked
        $doHibernation = [bool]$c['chkHibernation'].IsChecked
        $doPowerPlan = [bool]$c['chkPowerPlan'].IsChecked
        $doTempCleanup = [bool]$c['chkTempCleanup'].IsChecked
        $doHotCorners = [bool]$c['chkHotCorners'].IsChecked
        $doBootTimeout = [bool]$c['chkBootTimeout'].IsChecked
        $doOfficeTelemetry = [bool]$c['chkOfficeTelemetry'].IsChecked
        $doExtraSchedTasks = [bool]$c['chkExtraSchedTasks'].IsChecked
        $doDiskOptimize = [bool]$c['chkDiskOptimize'].IsChecked
        $doHagsGameMode = [bool]$c['chkHagsGameMode'].IsChecked
        $doUltimatePerf = [bool]$c['chkUltimatePerf'].IsChecked
        $doKernelGamingPriority = [bool]$c['chkKernelGamingPriority'].IsChecked
        $doGameDvrDisable = [bool]$c['chkGameDvrDisable'].IsChecked
        $doInputLagReduction = [bool]$c['chkInputLagReduction'].IsChecked
        $doSearchIndexOptimize = [bool]$c['chkSearchIndexOptimize'].IsChecked
        $doGhostAdapters = [bool]$c['chkGhostAdapters'].IsChecked
        $doFastStartup = [bool]$c['chkFastStartup'].IsChecked
        $doResidualServices = [bool]$c['chkResidualServices'].IsChecked
        $doStandbyListClean = [bool]$c['chkStandbyListClean'].IsChecked
        $doLargeSystemCache = [bool]$c['chkLargeSystemCache'].IsChecked
        $doHostsBlock = [bool]$c['chkHostsBlock'].IsChecked
        $doPrivacyDeep = [bool]$c['chkPrivacyDeep'].IsChecked
        $doCacheClean = [bool]$c['chkCacheClean'].IsChecked
        $doUiCleanup = [bool]$c['chkUiCleanup'].IsChecked
        $doTcpAutotuning = [bool]$c['chkTcpAutotuning'].IsChecked
        $doDoH = [bool]$c['chkDoH'].IsChecked
        $doFastShutdown = [bool]$c['chkFastShutdown'].IsChecked
        $doPrefetchSSD = [bool]$c['chkPrefetchSSD'].IsChecked
        $doRemoveWinBackup = [bool]$c['chkRemoveWinBackup'].IsChecked
        $doTcpIpReset = [bool]$c['chkTcpIpReset'].IsChecked
        $doRemoveOnedrive = [bool]$c['chkRemoveOnedrive'].IsChecked
        $doDisableGameBar = [bool]$c['chkDisableGameBar'].IsChecked
        $doDisableStore = [bool]$c['chkDisableStore'].IsChecked
        $doDisableWer = [bool]$c['chkDisableWer'].IsChecked
        $doAutoStandbyClean = [bool]$c['chkAutoStandbyClean'].IsChecked
        $doHungAppTimeout = [bool]$c['chkHungAppTimeout'].IsChecked
        $doDisableCoreParking = [bool]$c['chkDisableCoreParking'].IsChecked
        $doDisableHPET = [bool]$c['chkDisableHPET'].IsChecked
        $doTimerResolution = [bool]$c['chkTimerResolution'].IsChecked
        $doIncreaseTdrNvidia = [bool]$c['chkIncreaseTdrNvidia'].IsChecked
        $doDisableNvidiaTelemetry = [bool]$c['chkDisableNvidiaTelemetry'].IsChecked
        $doDisableNagle = [bool]$c['chkDisableNagle'].IsChecked
        $doDisableIPv6 = [bool]$c['chkDisableIPv6'].IsChecked
        $doRssOptimize = [bool]$c['chkRssOptimize'].IsChecked
        $doRiskyUAC = [bool]$c['chkRiskyUAC'].IsChecked
        $doRiskySmartScreen = [bool]$c['chkRiskySmartScreen'].IsChecked
        $doRiskyDefenderRT = [bool]$c['chkRiskyDefenderRT'].IsChecked
        $doRiskyWinUpdateSvc = [bool]$c['chkRiskyWinUpdateSvc'].IsChecked
        $doRiskyBits = [bool]$c['chkRiskyBits'].IsChecked
        $doRiskyDisableFirewall = [bool]$c['chkRiskyDisableFirewall'].IsChecked
        $doRiskyDisableDEP = [bool]$c['chkRiskyDisableDEP'].IsChecked
        $doRiskyNvidiaMaxPerf = [bool]$c['chkRiskyNvidiaMaxPerf'].IsChecked
        $doDisableXboxServices = [bool]$c['chkDisableXboxServices'].IsChecked
        $doDryRun = [bool]$c['chkDryRun'].IsChecked

        $anyRisky = $doRiskyUAC -or $doRiskySmartScreen -or $doRiskyDefenderRT -or $doRiskyWinUpdateSvc -or $doRiskyBits -or
                    $doRiskyDisableFirewall -or $doRiskyDisableDEP -or $doRiskyNvidiaMaxPerf
        if ($anyRisky -and -not $doDryRun) {
            if (-not (Show-WgoConfirm -Message (T 'LogRiskyConfirm') -Title "WGO")) {
                $c['btnRunSelected'].IsEnabled = $true
                return
            }
        }

        Start-WgoBackgroundTask -ScriptBlock {
            param($doBloat, $doSearch, $doVisual, $doPrivacy, $doDrivers, $doPagefile,
                  $doAdvertisingId, $doTailoredExp, $doDiagTrackSvc, $doCopilotBlock, $doInputTelemetry,
                  $doEdgeWidgets, $doDeliveryOpt, $doAppsBackground, $doNetworkLatency,
                  $doDisableSysMain, $doDisableWSearch, $doDisableSpooler, $doWinSxSCleanup,
                  $doHibernation, $doPowerPlan, $doTempCleanup, $doHotCorners,
                  $doBootTimeout, $doOfficeTelemetry, $doExtraSchedTasks, $doDiskOptimize, $doHagsGameMode, $doUltimatePerf,
                  $doKernelGamingPriority, $doGameDvrDisable, $doInputLagReduction,
                  $doSearchIndexOptimize, $doGhostAdapters, $doFastStartup,
                  $doResidualServices, $doStandbyListClean, $doLargeSystemCache,
                  $doHostsBlock, $doPrivacyDeep, $doCacheClean, $doUiCleanup, $doTcpAutotuning,
                  $doDoH, $doFastShutdown, $doPrefetchSSD, $doRemoveWinBackup, $doTcpIpReset,
                  $doRemoveOnedrive, $doDisableGameBar, $doDisableStore, $doDisableWer, $doAutoStandbyClean,
                  $doHungAppTimeout, $doDisableCoreParking, $doDisableHPET, $doTimerResolution,
                  $doIncreaseTdrNvidia, $doDisableNvidiaTelemetry,
                  $doDisableNagle, $doDisableIPv6, $doRssOptimize,
                  $doRiskyUAC, $doRiskySmartScreen, $doRiskyDefenderRT, $doRiskyWinUpdateSvc, $doRiskyBits,
                  $doRiskyDisableFirewall, $doRiskyDisableDEP, $doRiskyNvidiaMaxPerf,
                  $doDisableXboxServices,
                  $doDryRun)
            try {
                Write-Log (T 'LogOptStart') "INFO"
                if ($doDryRun) {
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
                        @{ Flag = $doEdgeWidgets;     Key = 'ChkEdgeWidgets' },
                        @{ Flag = $doDeliveryOpt;     Key = 'ChkDeliveryOpt' },
                        @{ Flag = $doAppsBackground;  Key = 'ChkAppsBackground' },
                        @{ Flag = $doNetworkLatency;  Key = 'ChkNetworkLatency' },
                        @{ Flag = $doHungAppTimeout;  Key = 'ChkHungAppTimeout' },
                        @{ Flag = $doDisableSysMain;  Key = 'ChkDisableSysMain' },
                        @{ Flag = $doDisableWSearch;  Key = 'ChkDisableWSearch' },
                        @{ Flag = $doDisableSpooler;  Key = 'ChkDisableSpooler' },
                        @{ Flag = $doWinSxSCleanup;   Key = 'ChkWinSxSCleanup' },
                        @{ Flag = $doHostsBlock;      Key = 'ChkHostsBlock' },
                        @{ Flag = $doPrivacyDeep;     Key = 'ChkPrivacyDeep' },
                        @{ Flag = $doCacheClean;      Key = 'ChkCacheClean' },
                        @{ Flag = $doUiCleanup;       Key = 'ChkUiCleanup' },
                        @{ Flag = $doTcpAutotuning;   Key = 'ChkTcpAutotuning' },
                        @{ Flag = $doDoH;             Key = 'ChkDoH' },
                        @{ Flag = $doFastShutdown;    Key = 'ChkFastShutdown' },
                        @{ Flag = $doPrefetchSSD;     Key = 'ChkPrefetchSSD' },
                        @{ Flag = $doRemoveWinBackup; Key = 'ChkRemoveWinBackup' },
                        @{ Flag = $doTcpIpReset;      Key = 'ChkTcpIpReset' },
                        @{ Flag = $doLargeSystemCache; Key = 'ChkLargeSystemCache' },
                        @{ Flag = $doRemoveOnedrive;  Key = 'ChkRemoveOnedrive' },
                        @{ Flag = $doDisableGameBar;  Key = 'ChkDisableGameBar' },
                        @{ Flag = $doDisableStore;    Key = 'ChkDisableStore' },
                        @{ Flag = $doDisableWer;      Key = 'ChkDisableWer' },
                        @{ Flag = $doAutoStandbyClean; Key = 'ChkAutoStandbyClean' },
                        @{ Flag = $doDisableCoreParking; Key = 'ChkDisableCoreParking' },
                        @{ Flag = $doDisableHPET;     Key = 'ChkDisableHPET' },
                        @{ Flag = $doTimerResolution; Key = 'ChkTimerResolution' },
                        @{ Flag = $doIncreaseTdrNvidia; Key = 'ChkIncreaseTdrNvidia' },
                        @{ Flag = $doDisableNvidiaTelemetry; Key = 'ChkDisableNvidiaTelemetry' },
                        @{ Flag = $doDisableNagle;    Key = 'ChkDisableNagle' },
                        @{ Flag = $doDisableIPv6;     Key = 'ChkDisableIPv6' },
                        @{ Flag = $doRssOptimize;     Key = 'ChkRssOptimize' },
                        @{ Flag = $doRiskyUAC;           Key = 'ChkRiskyUAC' },
                        @{ Flag = $doRiskySmartScreen;   Key = 'ChkRiskySmartScreen' },
                        @{ Flag = $doRiskyDefenderRT;    Key = 'ChkRiskyDefenderRT' },
                        @{ Flag = $doRiskyWinUpdateSvc;  Key = 'ChkRiskyWinUpdateSvc' },
                        @{ Flag = $doRiskyBits;          Key = 'ChkRiskyBits' },
                        @{ Flag = $doRiskyDisableFirewall; Key = 'ChkRiskyDisableFirewall' },
                        @{ Flag = $doRiskyDisableDEP;    Key = 'ChkRiskyDisableDEP' },
                        @{ Flag = $doRiskyNvidiaMaxPerf; Key = 'ChkRiskyNvidiaMaxPerf' },
                        @{ Flag = $doDisableXboxServices; Key = 'ChkDisableXboxServices' }
                    )
                    foreach ($item in $dryItems) {
                        if ($item.Flag) { Write-Log (T 'LogDryRunPrefix' (T $item.Key)) "INFO" }
                    }
                    Set-WgoMoreOptimizations -Hibernation $doHibernation -PowerPlan $doPowerPlan `
                        -TempCleanup $doTempCleanup -HotCorners $doHotCorners `
                        -BootTimeout $doBootTimeout -OfficeTelemetry $doOfficeTelemetry `
                        -ExtraSchedTasks $doExtraSchedTasks -DiskOptimize $doDiskOptimize `
                        -HagsGameMode $doHagsGameMode -UltimatePerf $doUltimatePerf `
                        -KernelGamingPriority $doKernelGamingPriority -GameDvrDisable $doGameDvrDisable `
                        -InputLagReduction $doInputLagReduction `
                        -SearchIndexOptimize $doSearchIndexOptimize -GhostAdapters $doGhostAdapters -FastStartup $doFastStartup `
                        -ResidualServices $doResidualServices -StandbyListClean $doStandbyListClean -LargeSystemCache $doLargeSystemCache `
                        -AutoStandbyClean $doAutoStandbyClean `
                        -DryRun $true
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
                    Set-WgoAdvancedTweaks -EdgeWidgets $doEdgeWidgets `
                        -DeliveryOpt $doDeliveryOpt -AppsBackground $doAppsBackground -NetworkLatency $doNetworkLatency
                    Set-WgoServiceMgmt -DisableSysMain $doDisableSysMain -DisableWSearch $doDisableWSearch -DisableSpooler $doDisableSpooler
                    if ($doWinSxSCleanup) { Clear-WgoWinSxS }
                    Set-WgoExtraTweaks2 -HostsBlock $doHostsBlock -PrivacyDeep $doPrivacyDeep -CacheClean $doCacheClean `
                        -UiCleanup $doUiCleanup -TcpAutotuning $doTcpAutotuning -DoH $doDoH `
                        -FastShutdown $doFastShutdown -PrefetchSSD $doPrefetchSSD -RemoveWinBackup $doRemoveWinBackup -TcpIpReset $doTcpIpReset `
                        -RemoveOnedrive $doRemoveOnedrive -DisableGameBar $doDisableGameBar -DisableStore $doDisableStore -DisableWer $doDisableWer
                    Set-WgoCpuTimerTweaks -DisableCoreParking $doDisableCoreParking -DisableHPET $doDisableHPET `
                        -TimerResolution $doTimerResolution -HungAppTimeout $doHungAppTimeout
                    Set-WgoGpuTweaks -IncreaseTdrNvidia $doIncreaseTdrNvidia -DisableNvidiaTelemetry $doDisableNvidiaTelemetry
                    Set-WgoNetworkAdvanced -DisableNagle $doDisableNagle -DisableIPv6 $doDisableIPv6 -RssOptimize $doRssOptimize
                    Set-WgoRiskyTweaks -DisableUAC $doRiskyUAC -DisableSmartScreen $doRiskySmartScreen `
                        -DisableDefenderRT $doRiskyDefenderRT -DisableWinUpdateSvc $doRiskyWinUpdateSvc -DisableBits $doRiskyBits `
                        -DisableFirewall $doRiskyDisableFirewall -DisableDEP $doRiskyDisableDEP -NvidiaMaxPerf $doRiskyNvidiaMaxPerf
                    Set-WgoXboxServices -DisableXboxServices $doDisableXboxServices
                    Set-WgoMoreOptimizations -Hibernation $doHibernation -PowerPlan $doPowerPlan `
                        -TempCleanup $doTempCleanup -HotCorners $doHotCorners `
                        -BootTimeout $doBootTimeout -OfficeTelemetry $doOfficeTelemetry `
                        -ExtraSchedTasks $doExtraSchedTasks -DiskOptimize $doDiskOptimize `
                        -HagsGameMode $doHagsGameMode -UltimatePerf $doUltimatePerf `
                        -KernelGamingPriority $doKernelGamingPriority -GameDvrDisable $doGameDvrDisable `
                        -InputLagReduction $doInputLagReduction `
                        -SearchIndexOptimize $doSearchIndexOptimize -GhostAdapters $doGhostAdapters -FastStartup $doFastStartup `
                        -ResidualServices $doResidualServices -StandbyListClean $doStandbyListClean -LargeSystemCache $doLargeSystemCache `
                        -AutoStandbyClean $doAutoStandbyClean `
                        -DryRun $false
                }
                Write-Log (T 'LogOptDone') "OK"
            } catch {
                Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
            }
        } -ArgumentList @($doBloat, $doSearch, $doVisual, $doPrivacy, $doDrivers, $doPagefile,
                           $doAdvertisingId, $doTailoredExp, $doDiagTrackSvc, $doCopilotBlock, $doInputTelemetry,
                           $doEdgeWidgets, $doDeliveryOpt, $doAppsBackground, $doNetworkLatency,
                           $doDisableSysMain, $doDisableWSearch, $doDisableSpooler, $doWinSxSCleanup,
                           $doHibernation, $doPowerPlan, $doTempCleanup, $doHotCorners,
                           $doBootTimeout, $doOfficeTelemetry, $doExtraSchedTasks, $doDiskOptimize, $doHagsGameMode, $doUltimatePerf,
                           $doKernelGamingPriority, $doGameDvrDisable, $doInputLagReduction,
                           $doSearchIndexOptimize, $doGhostAdapters, $doFastStartup,
                           $doResidualServices, $doStandbyListClean, $doLargeSystemCache,
                           $doHostsBlock, $doPrivacyDeep, $doCacheClean, $doUiCleanup, $doTcpAutotuning,
                           $doDoH, $doFastShutdown, $doPrefetchSSD, $doRemoveWinBackup, $doTcpIpReset,
                           $doRemoveOnedrive, $doDisableGameBar, $doDisableStore, $doDisableWer, $doAutoStandbyClean,
                           $doHungAppTimeout, $doDisableCoreParking, $doDisableHPET, $doTimerResolution,
                           $doIncreaseTdrNvidia, $doDisableNvidiaTelemetry,
                           $doDisableNagle, $doDisableIPv6, $doRssOptimize,
                           $doRiskyUAC, $doRiskySmartScreen, $doRiskyDefenderRT, $doRiskyWinUpdateSvc, $doRiskyBits,
                           $doRiskyDisableFirewall, $doRiskyDisableDEP, $doRiskyNvidiaMaxPerf,
                           $doDisableXboxServices,
                           $doDryRun) `
          -OnCompleted {
            $c['btnRunSelected'].IsEnabled = $true
            Save-WgoLastRunState
            $restartRequiredFlags = @(
                $doHibernation, $doFastStartup, $doHagsGameMode, $doDrivers,
                $doVisual, $doPagefile, $doKernelGamingPriority, $doUltimatePerf,
                $doDisableSysMain, $doDisableWSearch, $doDisableSpooler,
                $doRiskyUAC, $doRiskyWinUpdateSvc, $doLargeSystemCache,
                $doDisableHPET, $doRiskyDisableDEP
            )
            if (-not $doDryRun -and ($restartRequiredFlags -contains $true)) {
                if (Show-WgoConfirm -Message (T 'LogRestartPrompt') -Title "WGO") {
                    & shutdown.exe /r /t 5 | Out-Null
                }
            }
        }
    })

    # Restore Defaults
    $c['btnRestoreDefaults'].Add_Click({
        if (-not (Show-WgoConfirm -Message (T 'LogRestoreDefaultsStart') -Title "WGO")) { return }
        $c['btnRestoreDefaults'].IsEnabled = $false
        Start-WgoBackgroundTask -ScriptBlock {
            try { Restore-WgoDefaults } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
        } -OnCompleted {
            $c['btnRestoreDefaults'].IsEnabled = $true
            Remove-Item -Path $Global:WgoLastRunPath -Force -ErrorAction Ignore
        }
    })

    # Export Profile
    $c['btnExportProfile'].Add_Click({
        try {
            Write-Log (T 'LogExportStart') "INFO"
            $dlg = New-Object System.Windows.Forms.SaveFileDialog
            $dlg.Filter = "JSON (*.json)|*.json"
            $dlg.FileName = "WGO-Profile.json"
            if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $profile = @{}
                foreach ($n in $Global:WgoUI_OptimizationCheckboxNames) {
                    if ($c[$n]) { $profile[$n] = [bool]$c[$n].IsChecked }
                }
                $profile['chkDryRun'] = [bool]$c['chkDryRun'].IsChecked
                ($profile | ConvertTo-Json) | Set-Content -Path $dlg.FileName -Encoding UTF8
                Write-Log (T 'LogExportOk' $dlg.FileName) "OK"
            } else {
                Write-Log (T 'LogExportCancelled') "WARN"
            }
        } catch {
            Write-Log (T 'LogExportError' $_.Exception.Message) "ERROR"
        }
    })

    # Import Profile
    $c['btnImportProfile'].Add_Click({
        try {
            Write-Log (T 'LogImportStart') "INFO"
            $dlg = New-Object System.Windows.Forms.OpenFileDialog
            $dlg.Filter = "JSON (*.json)|*.json"
            if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $profile = Get-Content -Path $dlg.FileName -Raw | ConvertFrom-Json
                foreach ($prop in $profile.PSObject.Properties) {
                    if ($c[$prop.Name]) { $c[$prop.Name].IsChecked = [bool]$prop.Value }
                }
                Write-Log (T 'LogImportOk' $dlg.FileName) "OK"
            } else {
                Write-Log (T 'LogImportCancelled') "WARN"
            }
        } catch {
            Write-Log (T 'LogImportError' $_.Exception.Message) "ERROR"
        }
    })

    # Install Chocolatey
    $c['btnInstallChoco'].Add_Click({
        try {
            $c['btnInstallChoco'].IsEnabled = $false
            Start-WgoBackgroundTask -ScriptBlock {
                try { Install-WgoChocolatey | Out-Null } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
            } -OnCompleted {
                Update-WgoChocoStatus
                $c['btnInstallChoco'].IsEnabled = $true
            }
        } catch {
            Show-WgoFatalError "btnInstallChoco click handler failed: $($_.Exception.Message)"
            $c['btnInstallChoco'].IsEnabled = $true
        }
    })

    # Install Apps (now in action bar)
    $c['btnInstallApps'].Add_Click({
        try {
            $c['btnInstallApps'].IsEnabled = $false
            $appChecks = @(
                @{ Chk = $c['chkFirefox']; Name = "Mozilla Firefox" },
                @{ Chk = $c['chkBrave'];   Name = "Brave" },
                @{ Chk = $c['chkNanaZip']; Name = "NanaZip" },
                @{ Chk = $c['chkNpp'];     Name = "Notepad++" },
                @{ Chk = $c['chkFdm'];     Name = "Free Download Manager" },
                @{ Chk = $c['chkQbt'];     Name = "qBittorrent" },
                @{ Chk = $c['chkSteam'];   Name = "Steam" },
                @{ Chk = $c['chkEpic'];    Name = "Epic Games Launcher" },
                @{ Chk = $c['chkGog'];     Name = "GOG Galaxy" },
                @{ Chk = $c['chkSevenZip']; Name = "7-Zip" },
                @{ Chk = $c['chkWiztree'];  Name = "WizTree" },
                @{ Chk = $c['chkCpuz'];     Name = "CPU-Z" },
                @{ Chk = $c['chkHwmonitor']; Name = "HWMonitor" },
                @{ Chk = $c['chkMemreduct']; Name = "Mem Reduct" },
                @{ Chk = $c['chkBleachbit']; Name = "BleachBit" },
                @{ Chk = $c['chkMoonlight']; Name = "Moonlight" },
                @{ Chk = $c['chkSunshine'];  Name = "Sunshine" },
                @{ Chk = $c['chkNilesoftShell']; Name = "Nilesoft Shell" },
                @{ Chk = $c['chkOptiscalerClient']; Name = "Optiscaler Client" },
                @{ Chk = $c['chkFlowLauncher']; Name = "Flow Launcher" },
                @{ Chk = $c['chkShareX']; Name = "ShareX" },
                @{ Chk = $c['chkDnsJumper']; Name = "DNS Jumper" }
            )
            $selected = @()
            foreach ($a in $appChecks) {
                if ($a.Chk.IsChecked) {
                    $selected += @{ Id = $a.Chk.Tag; Name = $a.Name }
                }
            }
            if ($selected.Count -eq 0) {
                Write-Log (T 'LogNoAppsSelected') "WARN"
                $c['btnInstallApps'].IsEnabled = $true
                return
            }
            Start-WgoBackgroundTask -ScriptBlock {
                param($selected)
                try {
                    Write-Log (T 'LogInstallBatchStart') "INFO"
                    foreach ($app in $selected) {
                        Install-WgoApp -Key $app.Id -DisplayName $app.Name
                    }
                    Write-Log (T 'LogInstallBatchDone') "OK"
                } catch {
                    Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
                }
            } -ArgumentList @(,$selected) -OnCompleted {
                $c['btnInstallApps'].IsEnabled = $true
            }
        } catch {
            Show-WgoFatalError "btnInstallApps click handler failed: $($_.Exception.Message)"
            $c['btnInstallApps'].IsEnabled = $true
        }
    })

    # External scripts
    $c['btnRunAmdOptimizer'].Add_Click({
        Start-WgoExternalScript -Url "https://raw.githubusercontent.com/Khotyz/AMDSTABILITYOPTIMIZER/main/AMD-Stability-Optimizer.ps1" `
            -Name "AMD Stability Optimizer" -Downloader 'iwr'
    })
    $c['btnRunMassgrave'].Add_Click({
        Start-WgoExternalScript -Url "https://get.activated.win" `
            -Name "Microsoft Activation Scripts (MASSGRAVE)" -Downloader 'irm'
    })
    $c['btnRunUniGetUI'].Add_Click({
        # Opens the official UniGetUI page instead of a silent install, since the
        # winget/Chocolatey installer can trigger "publisher could not be verified" warnings.
        try {
            Start-Process "https://github.com/Devolutions/UniGetUI/releases/latest"
            Write-Log (T 'LogUniGetUIOpened') "INFO"
        } catch {
            Write-Log (T 'LogToolOpenFail' "UniGetUI" $_.Exception.Message) "ERROR"
        }
    })

    # Utilities
    $c['btnSafeModeNet'].Add_Click({
        if (-not (Show-WgoConfirm -Message (T 'LogSafeModeConfirm') -Title "WGO")) { return }
        $c['btnSafeModeNet'].IsEnabled = $false
        try {
            & bcdedit.exe /set '{current}' safeboot network 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Log (T 'LogSafeModeSet') "OK"
                & shutdown.exe /r /t 5 | Out-Null
            } else {
                Write-Log (T 'LogSafeModeFail' "bcdedit exit code $LASTEXITCODE") "ERROR"
                $c['btnSafeModeNet'].IsEnabled = $true
            }
        } catch {
            Write-Log (T 'LogSafeModeFail' $_.Exception.Message) "ERROR"
            $c['btnSafeModeNet'].IsEnabled = $true
        }
    })
    $c['btnUefiRestart'].Add_Click({
        if (-not (Show-WgoConfirm -Message (T 'LogUefiConfirm') -Title "WGO")) { return }
        $c['btnUefiRestart'].IsEnabled = $false
        try {
            & shutdown.exe /r /fw /t 5 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Log (T 'LogUefiFail') "ERROR"
                $c['btnUefiRestart'].IsEnabled = $true
            }
        } catch {
            Write-Log (T 'LogUefiFail') "ERROR"
            $c['btnUefiRestart'].IsEnabled = $true
        }
    })
    $c['btnNormalRestart'].Add_Click({
        if (-not (Show-WgoConfirm -Message (T 'LogNormalRestartConfirm') -Title "WGO")) { return }
        $c['btnNormalRestart'].IsEnabled = $false
        try {
            & bcdedit.exe /deletevalue '{current}' safeboot 2>$null | Out-Null
            Write-Log (T 'LogNormalRestartOk') "OK"
            & shutdown.exe /r /t 5 | Out-Null
        } catch {
            Write-Log (T 'LogNormalRestartFail' $_.Exception.Message) "ERROR"
            $c['btnNormalRestart'].IsEnabled = $true
        }
    })

    # Hidden tools
    $c['btnDiskCleanup'].Add_Click({
        try { Start-Process -FilePath "cleanmgr.exe" -ErrorAction Stop }
        catch { Write-Log (T 'LogToolOpenFail' "Disk Cleanup" $_.Exception.Message) "ERROR" }
    })
    $c['btnResourceMonitor'].Add_Click({
        try { Start-Process -FilePath "resmon.exe" -ErrorAction Stop }
        catch { Write-Log (T 'LogToolOpenFail' "Resource Monitor" $_.Exception.Message) "ERROR" }
    })
    $c['btnOptimizeDrives'].Add_Click({
        try { Start-Process -FilePath "dfrgui.exe" -ErrorAction Stop }
        catch { Write-Log (T 'LogToolOpenFail' "Optimize Drives" $_.Exception.Message) "ERROR" }
    })
    $c['btnMemDiag'].Add_Click({
        try { Start-Process -FilePath "mdsched.exe" -ErrorAction Stop }
        catch { Write-Log (T 'LogToolOpenFail' "Memory Diagnostic" $_.Exception.Message) "ERROR" }
    })
    $c['btnRamClean'].Add_Click({
        $c['btnRamClean'].IsEnabled = $false
        $freedMb = Invoke-WgoStandbyListPurge
        if ($null -ne $freedMb) {
            Write-Log (T 'LogStandbyListCleanOk' $freedMb) "OK"
        } else {
            Write-Log (T 'LogStandbyListCleanFail') "WARN"
        }
        $c['btnRamClean'].IsEnabled = $true
    })

    # System diagnostics
    $c['btnSystemIntegrity'].Add_Click({
        $c['btnSystemIntegrity'].IsEnabled = $false
        Start-WgoBackgroundTask -ScriptBlock {
            try { Invoke-WgoSystemIntegrity } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
        } -OnCompleted { $c['btnSystemIntegrity'].IsEnabled = $true }
    })
    $c['btnFlushDNS'].Add_Click({
        $c['btnFlushDNS'].IsEnabled = $false
        Start-WgoBackgroundTask -ScriptBlock {
            try { Clear-WgoDNS } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
        } -OnCompleted { $c['btnFlushDNS'].IsEnabled = $true }
    })

    # Set initial visibility: default to Optimizations tab
    if ($c['pnlOptimizationsActions']) { $c['pnlOptimizationsActions'].Visibility = 'Visible' }
    if ($c['pnlInstallerActions']) { $c['pnlInstallerActions'].Visibility = 'Collapsed' }
    if ($c['pnlOtherActions']) { $c['pnlOtherActions'].Visibility = 'Collapsed' }

    # Initial UI state
    Update-WgoUILanguage -Code $Global:CurrentLangCode
    Restore-WgoLastRunState
    Write-Log $global:Lang[$Global:CurrentLangCode].MsgReady "INFO"

    # Show the window
    $window.ShowDialog() | Out-Null
}

Export-ModuleMember -Function Initialize-WgoUI, Update-WgoUILanguage, Set-WgoUITheme, Set-WgoUIProfilePreset