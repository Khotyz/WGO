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
    'chkDisableCoreParking','chkDisableHPET','chkTimerResolution','chkGameBarMicFix',
    'chkIncreaseTdrNvidia','chkDisableNvidiaTelemetry',
    'chkDisableNagle','chkDisableIPv6','chkRssOptimize',
    'chkHostsBlock','chkPrivacyDeep','chkCacheClean','chkUiCleanup','chkTcpAutotuning',
    'chkDoH','chkFastShutdown','chkPrefetchSSD','chkRemoveWinBackup','chkTcpIpReset',
    'chkRemoveOnedrive','chkDisableGameBar','chkDisableStore','chkDisableWer',
    'chkClearEventLogs','chkDeleteMinidump','chkClearStoreCache',
    'chkPauseUpdates','chkDisableEdgeTelemetry','chkDisableSpotlight',
    'chkAmdUlps','chkAmdMpo','chkAmdTdr','chkAmdCrashDefender','chkAmdHdcp','chkAmdTelemetry','chkAmdHwAccel'
)

# Risky tweaks are intentionally excluded from Select All, profile presets, and
# last-run persistence - they must be re-confirmed by the user every single time.
$Global:WgoUI_RiskyCheckboxNames = @(
    'chkRiskyUAC','chkRiskySmartScreen','chkRiskyDefenderRT','chkRiskyWinUpdateSvc','chkRiskyBits',
    'chkRiskyDisableFirewall','chkRiskyDisableDEP','chkRiskyNvidiaMaxPerf'
)

# Vendor-specific checkboxes are added/removed from profile presets at runtime
# based on the detected GPU (see Set-WgoUIProfilePreset), since a static
# profile list can't know the hardware in advance.
$Global:WgoUI_NvidiaOnlyCheckboxNames = @('chkIncreaseTdrNvidia','chkDisableNvidiaTelemetry')
$Global:WgoUI_AmdOnlyCheckboxNames = @('chkAmdUlps','chkAmdMpo','chkAmdTdr','chkAmdCrashDefender','chkAmdHdcp','chkAmdTelemetry','chkAmdHwAccel')

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
        'chkKernelGamingPriority','chkGameDvrDisable','chkGameBarMicFix','chkInputLagReduction',
        'chkSearchIndexOptimize','chkGhostAdapters','chkFastStartup','chkResidualServices','chkStandbyListClean',
        'chkCacheClean','chkPrefetchSSD','chkFastShutdown','chkTcpAutotuning','chkLargeSystemCache',
        'chkAutoStandbyClean','chkDisableCoreParking','chkDisableHPET','chkTimerResolution','chkDisableNagle',
        'chkAmdUlps','chkAmdMpo','chkAmdTdr','chkAmdCrashDefender','chkAmdHdcp','chkAmdTelemetry','chkAmdHwAccel'
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
        'chkKernelGamingPriority','chkGameDvrDisable','chkGameBarMicFix','chkInputLagReduction',
        'chkGhostAdapters','chkFastStartup','chkStandbyListClean','chkLargeSystemCache','chkAutoStandbyClean',
        'chkCacheClean','chkPrefetchSSD','chkFastShutdown','chkTcpAutotuning',
        'chkDisableCoreParking','chkTimerResolution','chkHungAppTimeout',
        'chkIncreaseTdrNvidia','chkDisableNvidiaTelemetry',
        'chkDisableNagle','chkRssOptimize',
        'chkAmdUlps','chkAmdMpo','chkAmdTdr','chkAmdCrashDefender','chkAmdHdcp','chkAmdTelemetry','chkAmdHwAccel'
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
    $c['tabAmdGpu'].Header                            = $t.TabAmdGpu
    $c['tabInstaller'].Header                        = $t.TabInstaller
    $c['tabExternalScripts'].Header                  = $t.TabExternalScripts
    $c['tabUtilities'].Header                        = $t.TabUtilities
    $c['chkSelectAll'].Content                       = $t.ChkSelectAll
    $c['chkSelectAll'].ToolTip                        = $t.TipSelectAll
    $c['grpRestore'].Header                          = $t.GrpRestore
    $c['btnCreateRestore'].Content                   = $t.BtnCreateRestore
    $c['grpBloat'].Header                            = $t.GrpBloat
    $c['chkBloat'].Content                           = $t.ChkBloat
    $c['chkBloat'].ToolTip                        = $t.TipBloat
    $c['grpSearch'].Header                           = $t.GrpSearch
    $c['chkSearch'].Content                          = $t.ChkSearch
    $c['chkSearch'].ToolTip                        = $t.TipSearch
    $c['grpVisual'].Header                           = $t.GrpVisual
    $c['chkVisual'].Content                          = $t.ChkVisual
    $c['chkVisual'].ToolTip                        = $t.TipVisual
    $c['grpPrivacy'].Header                          = $t.GrpPrivacy
    $c['chkPrivacy'].Content                         = $t.ChkPrivacy
    $c['chkPrivacy'].ToolTip                        = $t.TipPrivacy
    $c['grpDrivers'].Header                          = $t.GrpDrivers
    $c['chkDrivers'].Content                         = $t.ChkDrivers
    $c['chkDrivers'].ToolTip                        = $t.TipDrivers
    $c['grpPagefile'].Header                         = $t.GrpPagefile
    $c['chkPagefile'].Content                        = $t.ChkPagefile
    $c['chkPagefile'].ToolTip                        = $t.TipPagefile
    $c['grpExtraPrivacy'].Header                     = $t.GrpExtraPrivacy
    $c['chkAdvertisingId'].Content                   = $t.ChkAdvertisingId
    $c['chkAdvertisingId'].ToolTip                        = $t.TipAdvertisingId
    $c['chkTailoredExp'].Content                     = $t.ChkTailoredExp
    $c['chkTailoredExp'].ToolTip                        = $t.TipTailoredExp
    $c['chkDiagTrackSvc'].Content                    = $t.ChkDiagTrackSvc
    $c['chkDiagTrackSvc'].ToolTip                        = $t.TipDiagTrackSvc
    $c['chkCopilotBlock'].Content                    = $t.ChkCopilotBlock
    $c['chkCopilotBlock'].ToolTip                        = $t.TipCopilotBlock
    $c['chkInputTelemetry'].Content                  = $t.ChkInputTelemetry
    $c['chkInputTelemetry'].ToolTip                        = $t.TipInputTelemetry
    $c['grpAdvancedTweaks'].Header                   = $t.GrpAdvancedTweaks
    $c['chkEdgeWidgets'].Content                     = $t.ChkEdgeWidgets
    $c['chkEdgeWidgets'].ToolTip                        = $t.TipEdgeWidgets
    $c['chkDeliveryOpt'].Content                     = $t.ChkDeliveryOpt
    $c['chkDeliveryOpt'].ToolTip                        = $t.TipDeliveryOpt
    $c['chkAppsBackground'].Content                  = $t.ChkAppsBackground
    $c['chkAppsBackground'].ToolTip                        = $t.TipAppsBackground
    $c['chkNetworkLatency'].Content                  = $t.ChkNetworkLatency
    $c['chkNetworkLatency'].ToolTip                        = $t.TipNetworkLatency
    $c['chkHungAppTimeout'].Content                  = $t.ChkHungAppTimeout
    $c['chkHungAppTimeout'].ToolTip                        = $t.TipHungAppTimeout
    $c['grpServiceMgmt'].Header                      = $t.GrpServiceMgmt
    $c['chkDisableSysMain'].Content                  = $t.ChkDisableSysMain
    $c['chkDisableSysMain'].ToolTip                        = $t.TipDisableSysMain
    $c['chkDisableWSearch'].Content                  = $t.ChkDisableWSearch
    $c['chkDisableWSearch'].ToolTip                        = $t.TipDisableWSearch
    $c['chkDisableSpooler'].Content                  = $t.ChkDisableSpooler
    $c['chkDisableSpooler'].ToolTip                        = $t.TipDisableSpooler
    $c['chkWinSxSCleanup'].Content                   = $t.ChkWinSxSCleanup
    $c['chkWinSxSCleanup'].ToolTip                        = $t.TipWinSxSCleanup
    $c['txtXboxServicesNote'].Text                   = $t.TxtXboxServicesNote
    $c['grpXboxServices'].Header                     = $t.GrpXboxServices
    $c['chkDisableXboxServices'].Content              = $t.ChkDisableXboxServices
    $c['chkDisableXboxServices'].ToolTip                        = $t.TipDisableXboxServices
    $c['grpMoreOptimizations'].Header                = $t.GrpMoreOptimizations
    $c['chkHibernation'].Content                     = $t.ChkHibernation
    $c['chkHibernation'].ToolTip                        = $t.TipHibernation
    $c['chkPowerPlan'].Content                       = $t.ChkPowerPlan
    $c['chkPowerPlan'].ToolTip                        = $t.TipPowerPlan
    $c['chkTempCleanup'].Content                     = $t.ChkTempCleanup
    $c['chkTempCleanup'].ToolTip                        = $t.TipTempCleanup
    $c['chkHotCorners'].Content                      = $t.ChkHotCorners
    $c['chkHotCorners'].ToolTip                        = $t.TipHotCorners
    $c['chkBootTimeout'].Content                     = $t.ChkBootTimeout
    $c['chkBootTimeout'].ToolTip                        = $t.TipBootTimeout
    $c['chkOfficeTelemetry'].Content                 = $t.ChkOfficeTelemetry
    $c['chkOfficeTelemetry'].ToolTip                        = $t.TipOfficeTelemetry
    $c['chkExtraSchedTasks'].Content                 = $t.ChkExtraSchedTasks
    $c['chkExtraSchedTasks'].ToolTip                        = $t.TipExtraSchedTasks
    $c['chkDiskOptimize'].Content                    = $t.ChkDiskOptimize
    $c['chkDiskOptimize'].ToolTip                        = $t.TipDiskOptimize
    $c['chkHagsGameMode'].Content                    = $t.ChkHagsGameMode
    $c['chkHagsGameMode'].ToolTip                        = $t.TipHagsGameMode
    $c['chkUltimatePerf'].Content                    = $t.ChkUltimatePerf
    $c['chkUltimatePerf'].ToolTip                        = $t.TipUltimatePerf
    $c['chkKernelGamingPriority'].Content            = $t.ChkKernelGamingPriority
    $c['chkKernelGamingPriority'].ToolTip                        = $t.TipKernelGamingPriority
    $c['chkGameDvrDisable'].Content                  = $t.ChkGameDvrDisable
    $c['chkGameDvrDisable'].ToolTip                        = $t.TipGameDvrDisable
    $c['chkGameBarMicFix'].Content                   = $t.ChkGameBarMicFix
    $c['chkGameBarMicFix'].ToolTip                        = $t.TipGameBarMicFix
    $c['chkInputLagReduction'].Content               = $t.ChkInputLagReduction
    $c['chkInputLagReduction'].ToolTip                        = $t.TipInputLagReduction
    $c['chkSearchIndexOptimize'].Content             = $t.ChkSearchIndexOptimize
    $c['chkSearchIndexOptimize'].ToolTip                        = $t.TipSearchIndexOptimize
    $c['chkGhostAdapters'].Content                   = $t.ChkGhostAdapters
    $c['chkGhostAdapters'].ToolTip                        = $t.TipGhostAdapters
    $c['chkFastStartup'].Content                     = $t.ChkFastStartup
    $c['chkFastStartup'].ToolTip                        = $t.TipFastStartup
    $c['chkResidualServices'].Content                = $t.ChkResidualServices
    $c['chkResidualServices'].ToolTip                        = $t.TipResidualServices
    $c['chkStandbyListClean'].Content                = $t.ChkStandbyListClean
    $c['chkStandbyListClean'].ToolTip                        = $t.TipStandbyListClean
    $c['chkLargeSystemCache'].Content                = $t.ChkLargeSystemCache
    $c['chkLargeSystemCache'].ToolTip                        = $t.TipLargeSystemCache
    $c['chkAutoStandbyClean'].Content                = $t.ChkAutoStandbyClean
    $c['chkAutoStandbyClean'].ToolTip                        = $t.TipAutoStandbyClean
    $c['grpCpuTimerTweaks'].Header                   = $t.GrpCpuTimerTweaks
    $c['chkDisableCoreParking'].Content              = $t.ChkDisableCoreParking
    $c['chkDisableCoreParking'].ToolTip                        = $t.TipDisableCoreParking
    $c['chkDisableHPET'].Content                     = $t.ChkDisableHPET
    $c['chkDisableHPET'].ToolTip                        = $t.TipDisableHPET
    $c['chkTimerResolution'].Content                 = $t.ChkTimerResolution
    $c['chkTimerResolution'].ToolTip                        = $t.TipTimerResolution
    $c['grpGpuTweaks'].Header                        = $t.GrpGpuTweaks
    $c['chkIncreaseTdrNvidia'].Content                = $t.ChkIncreaseTdrNvidia
    $c['chkIncreaseTdrNvidia'].ToolTip                        = $t.TipIncreaseTdrNvidia
    $c['chkDisableNvidiaTelemetry'].Content          = $t.ChkDisableNvidiaTelemetry
    $c['chkDisableNvidiaTelemetry'].ToolTip                        = $t.TipDisableNvidiaTelemetry
    $c['grpNetworkAdvanced'].Header                  = $t.GrpNetworkAdvanced
    $c['chkDisableNagle'].Content                    = $t.ChkDisableNagle
    $c['chkDisableNagle'].ToolTip                        = $t.TipDisableNagle
    $c['chkDisableIPv6'].Content                     = $t.ChkDisableIPv6
    $c['chkDisableIPv6'].ToolTip                      = $t.TipDisableIPv6
    $c['chkRssOptimize'].Content                     = $t.ChkRssOptimize
    $c['chkRssOptimize'].ToolTip                        = $t.TipRssOptimize
    $c['grpExtraTweaks2'].Header                     = $t.GrpExtraTweaks2
    $c['chkHostsBlock'].Content                      = $t.ChkHostsBlock
    $c['chkHostsBlock'].ToolTip                        = $t.TipHostsBlock
    $c['chkPrivacyDeep'].Content                     = $t.ChkPrivacyDeep
    $c['chkPrivacyDeep'].ToolTip                        = $t.TipPrivacyDeep
    $c['chkCacheClean'].Content                      = $t.ChkCacheClean
    $c['chkCacheClean'].ToolTip                        = $t.TipCacheClean
    $c['chkUiCleanup'].Content                       = $t.ChkUiCleanup
    $c['chkUiCleanup'].ToolTip                        = $t.TipUiCleanup
    $c['chkTcpAutotuning'].Content                   = $t.ChkTcpAutotuning
    $c['chkTcpAutotuning'].ToolTip                        = $t.TipTcpAutotuning
    $c['chkDoH'].Content                             = $t.ChkDoH
    $c['chkDoH'].ToolTip                        = $t.TipDoH
    $c['chkFastShutdown'].Content                    = $t.ChkFastShutdown
    $c['chkFastShutdown'].ToolTip                        = $t.TipFastShutdown
    $c['chkPrefetchSSD'].Content                     = $t.ChkPrefetchSSD
    $c['chkPrefetchSSD'].ToolTip                        = $t.TipPrefetchSSD
    $c['chkRemoveWinBackup'].Content                 = $t.ChkRemoveWinBackup
    $c['chkRemoveWinBackup'].ToolTip                        = $t.TipRemoveWinBackup
    $c['chkTcpIpReset'].Content                      = $t.ChkTcpIpReset
    $c['chkTcpIpReset'].ToolTip                        = $t.TipTcpIpReset
    $c['chkRemoveOnedrive'].Content                  = $t.ChkRemoveOnedrive
    $c['chkRemoveOnedrive'].ToolTip                        = $t.TipRemoveOnedrive
    $c['chkDisableGameBar'].Content                  = $t.ChkDisableGameBar
    $c['chkDisableGameBar'].ToolTip                        = $t.TipDisableGameBar
    $c['chkDisableStore'].Content                    = $t.ChkDisableStore
    $c['chkDisableStore'].ToolTip                        = $t.TipDisableStore
    $c['chkDisableWer'].Content                      = $t.ChkDisableWer
    $c['chkDisableWer'].ToolTip                        = $t.TipDisableWer
    $c['txtRiskyWarning'].Text                       = $t.TxtRiskyWarning
    $c['grpRiskyTweaks'].Header                      = $t.GrpRiskyTweaks
    $c['chkRiskyUAC'].Content                        = $t.ChkRiskyUAC
    $c['chkRiskyUAC'].ToolTip                        = $t.TipRiskyUAC
    $c['chkRiskySmartScreen'].Content                = $t.ChkRiskySmartScreen
    $c['chkRiskySmartScreen'].ToolTip                        = $t.TipRiskySmartScreen
    $c['chkRiskyDefenderRT'].Content                 = $t.ChkRiskyDefenderRT
    $c['chkRiskyDefenderRT'].ToolTip                        = $t.TipRiskyDefenderRT
    $c['chkRiskyWinUpdateSvc'].Content                = $t.ChkRiskyWinUpdateSvc
    $c['chkRiskyWinUpdateSvc'].ToolTip                        = $t.TipRiskyWinUpdateSvc
    $c['chkRiskyBits'].Content                       = $t.ChkRiskyBits
    $c['chkRiskyBits'].ToolTip                        = $t.TipRiskyBits
    $c['chkRiskyDisableFirewall'].Content            = $t.ChkRiskyDisableFirewall
    $c['chkRiskyDisableFirewall'].ToolTip                        = $t.TipRiskyDisableFirewall
    $c['chkRiskyDisableDEP'].Content                 = $t.ChkRiskyDisableDEP
    $c['chkRiskyDisableDEP'].ToolTip                        = $t.TipRiskyDisableDEP
    $c['chkRiskyNvidiaMaxPerf'].Content               = $t.ChkRiskyNvidiaMaxPerf
    $c['chkRiskyNvidiaMaxPerf'].ToolTip                        = $t.TipRiskyNvidiaMaxPerf
    $c['grpProfiles'].Header                         = $t.GrpProfiles
    $c['btnProfileBasic'].Content                    = $t.BtnProfileBasic
    $c['btnProfileLaptop'].Content                   = $t.BtnProfileLaptop
    $c['btnProfileGamer'].Content                    = $t.BtnProfileGamer
    $c['btnProfilePrivacy'].Content                   = $t.BtnProfilePrivacy
    $c['btnProfileEsports'].Content                   = $t.BtnProfileEsports
    $c['btnProfileMax'].Content                      = $t.BtnProfileMax
    $c['chkDryRun'].Content                          = $t.ChkDryRun
    $c['chkDryRun'].ToolTip                        = $t.TipDryRun
    $c['btnRunSelected'].Content                     = $t.BtnRunSelected
    $c['btnRestoreDefaults'].Content                 = $t.BtnRestoreDefaults
    $c['btnRestoreDefaults'].ToolTip                 = $t.TipRestoreDefaults
    $c['lblRestoreCategory'].Text                    = $t.LblRestoreCategory
    $c['cmbRestoreCategory'].ToolTip                 = $t.TipRestoreDefaults
    $catLabels = @{ All = $t.TxtCatAll; Privacy = $t.TxtCatPrivacy; Network = $t.TxtCatNetwork; Services = $t.TxtCatServices; Visual = $t.TxtCatVisual; Amd = $t.TxtCatAmd }
    foreach ($catItem in $c['cmbRestoreCategory'].Items) { if ($catLabels.ContainsKey($catItem.Tag)) { $catItem.Content = $catLabels[$catItem.Tag] } }
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
    $c['chkDnsJumper'].Content                       = "DNS Jumper"
    $c['txtDnsJumperDesc'].Text                      = $t.AppDnsJumperDesc
    $c['grpAppsProductivity'].Header                 = $t.GrpAppsProductivity
    $c['chkNilesoftShell'].Content                   = "Nilesoft Shell"
    $c['txtNilesoftShellDesc'].Text                  = $t.AppNilesoftShellDesc
    $c['chkOptiscalerClient'].Content                = "Optiscaler Client"
    $c['txtOptiscalerClientDesc'].Text               = $t.AppOptiscalerClientDesc
    $c['chkFlowLauncher'].Content                    = "Flow Launcher"
    $c['txtFlowLauncherDesc'].Text                   = $t.AppFlowLauncherDesc
    $c['chkShareX'].Content                          = "ShareX"
    $c['txtShareXDesc'].Text                         = $t.AppShareXDesc
    $c['txtUniGetUITitle'].Text                      = "UniGetUI"
    $c['txtUniGetUIDesc'].Text                       = $t.TxtUniGetUIDesc
    $c['btnRunUniGetUI'].Content                     = $t.BtnRunUniGetUI
    $c['txtExtScriptsWarning'].Text                  = $t.TxtExtScriptsWarning
    $c['txtAmdGpuBanner'].Text                       = $t.TxtAmdGpuBanner
    $c['grpAmdGpu'].Header                            = $t.GrpAmdGpu
    $c['chkAmdUlps'].Content                          = $t.ChkAmdUlps
    $c['chkAmdUlps'].ToolTip                          = $t.TipAmdUlps
    $c['chkAmdMpo'].Content                           = $t.ChkAmdMpo
    $c['chkAmdMpo'].ToolTip                           = $t.TipAmdMpo
    $c['chkAmdTdr'].Content                           = $t.ChkAmdTdr
    $c['chkAmdTdr'].ToolTip                           = $t.TipAmdTdr
    $c['chkAmdCrashDefender'].Content                 = $t.ChkAmdCrashDefender
    $c['chkAmdCrashDefender'].ToolTip                 = $t.TipAmdCrashDefender
    $c['chkAmdHdcp'].Content                          = $t.ChkAmdHdcp
    $c['chkAmdHdcp'].ToolTip                          = $t.TipAmdHdcp
    $c['chkAmdTelemetry'].Content                     = $t.ChkAmdTelemetry
    $c['chkAmdTelemetry'].ToolTip                     = $t.TipAmdTelemetry
    $c['chkAmdHwAccel'].Content                       = $t.ChkAmdHwAccel
    $c['chkAmdHwAccel'].ToolTip                       = $t.TipAmdHwAccel
    $amdVendor = Get-WgoGpuVendor
    if ($amdVendor -eq 'AMD') {
        $c['txtAmdGpuBanner'].Text = $t.TxtAmdGpuBannerDetected
        $c['grpAmdGpu'].IsEnabled = $true
    } else {
        $c['txtAmdGpuBanner'].Text = $t.TxtAmdGpuBanner
        $c['grpAmdGpu'].IsEnabled = $false
    }
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
    $c['chkClearEventLogs'].Content                  = $t.ChkClearEventLogs
    $c['chkClearEventLogs'].ToolTip                        = $t.TipClearEventLogs
    $c['chkDeleteMinidump'].Content                  = $t.ChkDeleteMinidump
    $c['chkDeleteMinidump'].ToolTip                        = $t.TipDeleteMinidump
    $c['chkClearStoreCache'].Content                 = $t.ChkClearStoreCache
    $c['chkClearStoreCache'].ToolTip                        = $t.TipClearStoreCache
    $c['chkPauseUpdates'].Content                    = $t.ChkPauseUpdates
    $c['chkPauseUpdates'].ToolTip                        = $t.TipPauseUpdates
    $c['chkDisableEdgeTelemetry'].Content             = $t.ChkDisableEdgeTelemetry
    $c['chkDisableEdgeTelemetry'].ToolTip                        = $t.TipDisableEdgeTelemetry
    $c['chkDisableSpotlight'].Content                = $t.ChkDisableSpotlight
    $c['chkDisableSpotlight'].ToolTip                        = $t.TipDisableSpotlight
    $c['txtReleaseRenewTitle'].Text                  = $t.TxtReleaseRenewTitle
    $c['txtReleaseRenewDesc'].Text                   = $t.TxtReleaseRenewDesc
    $c['btnReleaseRenewIP'].Content                  = $t.BtnReleaseRenewIP
    $c['txtRegisterDNSTitle'].Text                   = $t.TxtRegisterDNSTitle
    $c['txtRegisterDNSDesc'].Text                    = $t.TxtRegisterDNSDesc
    $c['btnRegisterDNS'].Content                     = $t.BtnRegisterDNS
    $c['grpAdvancedUtilities'].Header                = $t.GrpAdvancedUtilities
    $c['txtSystemInfoTitle'].Text                    = $t.TxtSystemInfoTitle
    $c['txtSystemInfoDesc'].Text                     = $t.TxtSystemInfoDesc
    $c['btnSystemInfo'].Content                      = $t.BtnSystemInfo
    $c['txtStartupManagerTitle'].Text                = $t.TxtStartupManagerTitle
    $c['txtStartupManagerDesc'].Text                 = $t.TxtStartupManagerDesc
    $c['btnStartupManager'].Content                  = $t.BtnStartupManager
    $c['txtScheduledOptTitle'].Text                  = $t.TxtScheduledOptTitle
    $c['txtScheduledOptDesc'].Text                   = $t.TxtScheduledOptDesc
    $c['btnScheduledOptimization'].Content           = $t.BtnScheduledOptimization
}

function Set-WgoUIProfilePreset {
    param(
        [string[]]$EnabledNames,
        [string]$ProfileLabel
    )
    $c = $Global:WgoUI_Ctrl
    $vendor = Get-WgoGpuVendor
    $filtered = $EnabledNames | Where-Object {
        (-not ($Global:WgoUI_NvidiaOnlyCheckboxNames -contains $_) -or $vendor -eq 'NVIDIA') -and
        (-not ($Global:WgoUI_AmdOnlyCheckboxNames -contains $_) -or $vendor -eq 'AMD')
    }
    foreach ($n in $Global:WgoUI_OptimizationCheckboxNames) {
        if ($c[$n]) { $c[$n].IsChecked = ($filtered -contains $n) }
    }
    $c['chkSelectAll'].IsChecked = ($filtered.Count -ge $Global:WgoUI_OptimizationCheckboxNames.Count)
    Write-Log (T 'LogProfileApplied' $ProfileLabel (T 'BtnRunSelected')) "INFO"
}

function Show-WgoStartupManagerDialog {
    $items = Get-WgoStartupPrograms
    [xml]$dialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$([System.Security.SecurityElement]::Escape((T 'TxtStartupManagerTitle')))" Height="420" Width="520"
        WindowStartupLocation="CenterOwner" ResizeMode="NoResize"
        Background="{DynamicResource BgDark}" WindowStyle="None" AllowsTransparency="False"
        BorderBrush="{DynamicResource AccentBrush}" BorderThickness="1">
    <Border Padding="16">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="$([System.Security.SecurityElement]::Escape((T 'TxtStartupManagerTitle')))" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold" FontSize="14" Margin="0,0,0,4"/>
            <TextBlock Grid.Row="0" Text="$([System.Security.SecurityElement]::Escape((T 'TxtStartupManagerDesc')))" Foreground="{DynamicResource TextSecondary}" FontSize="11" TextWrapping="Wrap" Margin="0,24,0,10" VerticalAlignment="Top"/>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                <StackPanel x:Name="pnlStartupItems"/>
            </ScrollViewer>
            <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,14,0,0">
                <Button x:Name="btnStartupClose" Content="Close" Width="100" Height="32"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@
    $dlgReader = New-Object System.Xml.XmlNodeReader $dialogXaml
    $dlg = [Windows.Markup.XamlReader]::Load($dlgReader)
    # Reuse the main window's live resource dictionary so this dialog picks up
    # the same button/checkbox styles and follows the current Dark/Light theme.
    $dlg.Resources = $Global:WgoUI_Window.Resources
    try { $dlg.Owner = $Global:WgoUI_Window } catch { }

    $pnl = $dlg.FindName('pnlStartupItems')
    foreach ($item in $items) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = "$($item.Name)  -  $($item.Command)"
        $cb.IsChecked = [bool]$item.Enabled
        $cb.Margin = "0,4,0,4"
        $cb.Tag = $item
        $cb.ToolTip = $item.Command
        $pnl.Children.Add($cb) | Out-Null
    }
    if ($items.Count -eq 0) {
        $empty = New-Object System.Windows.Controls.TextBlock
        $empty.Text = (T 'TxtStartupManagerDesc')
        $empty.TextWrapping = 'Wrap'
        $empty.Opacity = 0.7
        $pnl.Children.Add($empty) | Out-Null
    }

    $btnClose = $dlg.FindName('btnStartupClose')
    $btnClose.Content = (T 'BtnClose')
    $btnClose.Add_Click({
        try {
            foreach ($child in $pnl.Children) {
                $entry = $child.Tag
                if (-not $entry) { continue }
                $enable = [bool]$child.IsChecked
                if ($enable -eq [bool]$entry.Enabled) { continue }
                Set-WgoStartupProgramState -Name $entry.Name -Source $entry.Source -Type $entry.Type -Command $entry.Command -Enable $enable | Out-Null
            }
        } catch {
            Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR"
        } finally {
            $dlg.Close()
        }
    }.GetNewClosure())
    $dlg.Add_MouseLeftButtonDown({ if ($_.ChangedButton -eq 'Left') { $dlg.DragMove() } })
    $dlg.ShowDialog() | Out-Null
}

function Show-WgoRestartPrompt {
    [xml]$dialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WGO" Width="420" SizeToContent="Height"
        WindowStartupLocation="CenterOwner" ResizeMode="NoResize"
        Background="{DynamicResource BgDark}" WindowStyle="None" AllowsTransparency="False"
        BorderBrush="{DynamicResource AccentBrush}" BorderThickness="1">
    <Border Padding="20">
        <StackPanel>
            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                <Ellipse Width="10" Height="10" Fill="{DynamicResource AccentBrush}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="WGO" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold" FontSize="14"/>
            </StackPanel>
            <TextBlock Text="$([System.Security.SecurityElement]::Escape((T 'TxtRestartPrompt')))" Foreground="{DynamicResource TextPrimary}" TextWrapping="Wrap" FontSize="13" Margin="0,0,0,18"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="btnRestartLater" Content="$([System.Security.SecurityElement]::Escape((T 'BtnRestartLater')))" MinWidth="100" Height="34" Padding="14,8" Margin="0,0,10,0" Style="{DynamicResource SecondaryButtonStyle}"/>
                <Button x:Name="btnRestartNow" Content="$([System.Security.SecurityElement]::Escape((T 'BtnRestartNow')))" MinWidth="100" Height="34" Padding="14,8"/>
            </StackPanel>
        </StackPanel>
    </Border>
</Window>
"@
    $dlgReader = New-Object System.Xml.XmlNodeReader $dialogXaml
    $dlg = [Windows.Markup.XamlReader]::Load($dlgReader)
    $dlg.Resources = $Global:WgoUI_Window.Resources
    try { $dlg.Owner = $Global:WgoUI_Window } catch { }
    $btnNow   = $dlg.FindName('btnRestartNow')
    $btnLater = $dlg.FindName('btnRestartLater')
    $btnNow.Add_Click({ & shutdown.exe /r /t 5 | Out-Null; $dlg.Close() }.GetNewClosure())
    $btnLater.Add_Click({ $dlg.Close() }.GetNewClosure())
    $dlg.Add_MouseLeftButtonDown({ if ($_.ChangedButton -eq 'Left') { $dlg.DragMove() } })
    $dlg.ShowDialog() | Out-Null
}

function Show-WgoScheduledOptimizationDialog {
    [xml]$dialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$([System.Security.SecurityElement]::Escape((T 'TxtScheduledOptTitle')))" Width="420" SizeToContent="Height"
        WindowStartupLocation="CenterOwner" ResizeMode="NoResize"
        Background="{DynamicResource BgDark}" WindowStyle="None" AllowsTransparency="False"
        BorderBrush="{DynamicResource AccentBrush}" BorderThickness="1">
    <Border Padding="20">
        <StackPanel>
            <TextBlock Text="$([System.Security.SecurityElement]::Escape((T 'TxtScheduledOptTitle')))" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold" FontSize="14" Margin="0,0,0,16"/>
            <RadioButton x:Name="radDaily" Content="$([System.Security.SecurityElement]::Escape((T 'TxtDaily')))" GroupName="freq" Margin="0,0,0,6"/>
            <RadioButton x:Name="radWeekly" Content="$([System.Security.SecurityElement]::Escape((T 'TxtWeekly')))" GroupName="freq" IsChecked="True" Margin="0,0,0,6"/>
            <RadioButton x:Name="radCustom" Content="$([System.Security.SecurityElement]::Escape((T 'TxtCustom')))" GroupName="freq" Margin="0,0,0,6"/>
            <StackPanel x:Name="pnlCustomDays" Orientation="Horizontal" Margin="28,2,0,16" IsEnabled="False">
                <TextBlock Text="$([System.Security.SecurityElement]::Escape((T 'TxtEveryXDays')))" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBox x:Name="txtCustomDays" Text="3" Width="60" Height="32" TextAlignment="Center" VerticalContentAlignment="Center" ToolTip="$([System.Security.SecurityElement]::Escape((T 'TipCustomDays')))"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,4,0,0">
                <Button x:Name="btnSchedCancel" Content="$([System.Security.SecurityElement]::Escape((T 'BtnCancel')))" MinWidth="90" Height="34" Padding="14,8" Margin="0,0,10,0" Style="{DynamicResource SecondaryButtonStyle}"/>
                <Button x:Name="btnSchedCreate" Content="$([System.Security.SecurityElement]::Escape((T 'BtnCreate')))" MinWidth="90" Height="34" Padding="14,8"/>
            </StackPanel>
        </StackPanel>
    </Border>
</Window>
"@
    $dlgReader = New-Object System.Xml.XmlNodeReader $dialogXaml
    $dlg = [Windows.Markup.XamlReader]::Load($dlgReader)
    $dlg.Resources = $Global:WgoUI_Window.Resources
    try { $dlg.Owner = $Global:WgoUI_Window } catch { }
    $radDaily      = $dlg.FindName('radDaily')
    $radWeekly     = $dlg.FindName('radWeekly')
    $radCustom     = $dlg.FindName('radCustom')
    $pnlCustomDays = $dlg.FindName('pnlCustomDays')
    $txtCustomDays = $dlg.FindName('txtCustomDays')
    $btnCancel     = $dlg.FindName('btnSchedCancel')
    $btnCreate     = $dlg.FindName('btnSchedCreate')

    $syncCustomState = { $pnlCustomDays.IsEnabled = [bool]$radCustom.IsChecked }.GetNewClosure()
    $radDaily.Add_Checked($syncCustomState)
    $radWeekly.Add_Checked($syncCustomState)
    $radCustom.Add_Checked($syncCustomState)

    $btnCancel.Add_Click({ $dlg.Close() }.GetNewClosure())
    $btnCreate.Add_Click({
        $freq = if ($radDaily.IsChecked) { 'Daily' } elseif ($radWeekly.IsChecked) { 'Weekly' } else { 'Custom' }
        $days = 3
        if ($freq -eq 'Custom') {
            $parsed = 0
            if (-not [int]::TryParse($txtCustomDays.Text, [ref]$parsed) -or $parsed -lt 1) {
                Write-Log (T 'LogSchedInvalidDays') "ERROR"
                return
            }
            $days = $parsed
        }
        Start-WgoBackgroundTask -ScriptBlock {
            param($freq, $days)
            try { New-WgoScheduledOptimization -Frequency $freq -IntervalDays $days | Out-Null } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
        } -ArgumentList @($freq, $days)
        $dlg.Close()
    }.GetNewClosure())
    $dlg.Add_MouseLeftButtonDown({ if ($_.ChangedButton -eq 'Left') { $dlg.DragMove() } })
    $dlg.ShowDialog() | Out-Null
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
        'tabOptimizations','tabAmdGpu','tabInstaller','tabExternalScripts','tabUtilities',
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
        'chkBootTimeout','chkOfficeTelemetry','chkExtraSchedTasks','chkDiskOptimize','chkHagsGameMode','chkUltimatePerf','chkKernelGamingPriority','chkGameDvrDisable','chkGameBarMicFix','chkInputLagReduction',
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
        'btnRunSelected','btnRestoreDefaults','lblRestoreCategory','cmbRestoreCategory','btnExportProfile','btnImportProfile',
        'chkClearEventLogs','chkDeleteMinidump','chkClearStoreCache',
        'chkPauseUpdates','chkDisableEdgeTelemetry','chkDisableSpotlight',
        'btnInstallApps',
        'txtChocoRequired','txtChocoStatus','btnInstallChoco',
        'grpAppsBrowsers','chkFirefox','txtFirefoxDesc','chkBrave','txtBraveDesc',
        'grpAppsFiles','chkNanaZip','txtNanaZipDesc','chkSevenZip','txtSevenZipDesc',
        'chkNpp','txtNppDesc','chkWiztree','txtWiztreeDesc',
        'grpAppsDownloads','chkFdm','txtFdmDesc','chkQbt','txtQbtDesc',
        'grpAppsGaming','chkSteam','txtSteamDesc','chkEpic','txtEpicDesc','chkGog','txtGogDesc',
        'chkMoonlight','txtMoonlightDesc','chkSunshine','txtSunshineDesc',
        'grpAppsMonitoring','chkCpuz','txtCpuzDesc','chkHwmonitor','txtHwmonitorDesc',
        'chkMemreduct','txtMemreductDesc','chkBleachbit','txtBleachbitDesc','chkDnsJumper','txtDnsJumperDesc',
        'grpAppsProductivity','chkNilesoftShell','txtNilesoftShellDesc',
        'chkOptiscalerClient','txtOptiscalerClientDesc',
        'chkFlowLauncher','txtFlowLauncherDesc',
        'chkShareX','txtShareXDesc',
        'txtExtScriptsWarning',
        'txtAmdGpuBanner','grpAmdGpu','chkAmdUlps','chkAmdMpo','chkAmdTdr','chkAmdCrashDefender','chkAmdHdcp','chkAmdTelemetry','chkAmdHwAccel',
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
        'txtReleaseRenewTitle','txtReleaseRenewDesc','btnReleaseRenewIP',
        'txtRegisterDNSTitle','txtRegisterDNSDesc','btnRegisterDNS',
        'grpAdvancedUtilities','txtSystemInfoTitle','txtSystemInfoDesc','btnSystemInfo',
        'txtStartupManagerTitle','txtStartupManagerDesc','btnStartupManager',
        'txtScheduledOptTitle','txtScheduledOptDesc','btnScheduledOptimization',
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
        $doGameBarMicFix = [bool]$c['chkGameBarMicFix'].IsChecked
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
        $doClearEventLogs = [bool]$c['chkClearEventLogs'].IsChecked
        $doDeleteMinidump = [bool]$c['chkDeleteMinidump'].IsChecked
        $doClearStoreCache = [bool]$c['chkClearStoreCache'].IsChecked
        $doPauseUpdates = [bool]$c['chkPauseUpdates'].IsChecked
        $doDisableEdgeTelemetry = [bool]$c['chkDisableEdgeTelemetry'].IsChecked
        $doDisableSpotlight = [bool]$c['chkDisableSpotlight'].IsChecked
        $doAmdUlps = [bool]$c['chkAmdUlps'].IsChecked
        $doAmdMpo = [bool]$c['chkAmdMpo'].IsChecked
        $doAmdTdr = [bool]$c['chkAmdTdr'].IsChecked
        $doAmdCrashDefender = [bool]$c['chkAmdCrashDefender'].IsChecked
        $doAmdHdcp = [bool]$c['chkAmdHdcp'].IsChecked
        $doAmdTelemetry = [bool]$c['chkAmdTelemetry'].IsChecked
        $doAmdHwAccel = [bool]$c['chkAmdHwAccel'].IsChecked
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

        # .GetNewClosure() below detaches the -OnCompleted scriptblock from this
        # module, so a plain "Show-WgoRestartPrompt" call inside it fails with
        # CommandNotFoundException; capture the function as data here instead,
        # where it's still resolvable, and invoke that captured reference.
        $restartPromptFn = ${function:Show-WgoRestartPrompt}

        Start-WgoBackgroundTask -ScriptBlock {
            param($doBloat, $doSearch, $doVisual, $doPrivacy, $doDrivers, $doPagefile,
                  $doAdvertisingId, $doTailoredExp, $doDiagTrackSvc, $doCopilotBlock, $doInputTelemetry,
                  $doEdgeWidgets, $doDeliveryOpt, $doAppsBackground, $doNetworkLatency,
                  $doDisableSysMain, $doDisableWSearch, $doDisableSpooler, $doWinSxSCleanup,
                  $doHibernation, $doPowerPlan, $doTempCleanup, $doHotCorners,
                  $doBootTimeout, $doOfficeTelemetry, $doExtraSchedTasks, $doDiskOptimize, $doHagsGameMode, $doUltimatePerf,
                  $doKernelGamingPriority, $doGameDvrDisable, $doGameBarMicFix, $doInputLagReduction,
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
                  $doClearEventLogs, $doDeleteMinidump, $doClearStoreCache,
                  $doPauseUpdates, $doDisableEdgeTelemetry, $doDisableSpotlight,
                  $doAmdUlps, $doAmdMpo, $doAmdTdr, $doAmdCrashDefender, $doAmdHdcp, $doAmdTelemetry, $doAmdHwAccel,
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
                        @{ Flag = $doDisableXboxServices; Key = 'ChkDisableXboxServices' },
                        @{ Flag = $doPauseUpdates;        Key = 'ChkPauseUpdates' },
                        @{ Flag = $doDisableEdgeTelemetry; Key = 'ChkDisableEdgeTelemetry' },
                        @{ Flag = $doDisableSpotlight;     Key = 'ChkDisableSpotlight' },
                        @{ Flag = $doAmdUlps;              Key = 'ChkAmdUlps' },
                        @{ Flag = $doAmdMpo;               Key = 'ChkAmdMpo' },
                        @{ Flag = $doAmdTdr;               Key = 'ChkAmdTdr' },
                        @{ Flag = $doAmdCrashDefender;     Key = 'ChkAmdCrashDefender' },
                        @{ Flag = $doAmdHdcp;              Key = 'ChkAmdHdcp' },
                        @{ Flag = $doAmdTelemetry;         Key = 'ChkAmdTelemetry' },
                        @{ Flag = $doAmdHwAccel;           Key = 'ChkAmdHwAccel' }
                    )
                    foreach ($item in $dryItems) {
                        if ($item.Flag) { Write-Log (T 'LogDryRunPrefix' (T $item.Key)) "INFO" }
                    }
                    Set-WgoMoreOptimizations -Hibernation $doHibernation -PowerPlan $doPowerPlan `
                        -TempCleanup $doTempCleanup -HotCorners $doHotCorners `
                        -BootTimeout $doBootTimeout -OfficeTelemetry $doOfficeTelemetry `
                        -ExtraSchedTasks $doExtraSchedTasks -DiskOptimize $doDiskOptimize `
                        -HagsGameMode $doHagsGameMode -UltimatePerf $doUltimatePerf `
                        -KernelGamingPriority $doKernelGamingPriority -GameDvrDisable $doGameDvrDisable -GameBarMicFix $doGameBarMicFix `
                        -InputLagReduction $doInputLagReduction `
                        -SearchIndexOptimize $doSearchIndexOptimize -GhostAdapters $doGhostAdapters -FastStartup $doFastStartup `
                        -ResidualServices $doResidualServices -StandbyListClean $doStandbyListClean -LargeSystemCache $doLargeSystemCache `
                        -AutoStandbyClean $doAutoStandbyClean `
                        -ClearEventLogs $doClearEventLogs -DeleteMinidump $doDeleteMinidump -ClearStoreCache $doClearStoreCache `
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
                        -RemoveOnedrive $doRemoveOnedrive -DisableGameBar $doDisableGameBar -DisableStore $doDisableStore -DisableWer $doDisableWer `
                        -PauseUpdates $doPauseUpdates -DisableEdgeTelemetry $doDisableEdgeTelemetry -DisableSpotlight $doDisableSpotlight
                    Set-WgoCpuTimerTweaks -DisableCoreParking $doDisableCoreParking -DisableHPET $doDisableHPET `
                        -TimerResolution $doTimerResolution -HungAppTimeout $doHungAppTimeout
                    Set-WgoGpuTweaks -IncreaseTdrNvidia $doIncreaseTdrNvidia -DisableNvidiaTelemetry $doDisableNvidiaTelemetry
                    Set-WgoNetworkAdvanced -DisableNagle $doDisableNagle -DisableIPv6 $doDisableIPv6 -RssOptimize $doRssOptimize
                    Set-WgoRiskyTweaks -DisableUAC $doRiskyUAC -DisableSmartScreen $doRiskySmartScreen `
                        -DisableDefenderRT $doRiskyDefenderRT -DisableWinUpdateSvc $doRiskyWinUpdateSvc -DisableBits $doRiskyBits `
                        -DisableFirewall $doRiskyDisableFirewall -DisableDEP $doRiskyDisableDEP -NvidiaMaxPerf $doRiskyNvidiaMaxPerf
                    Set-WgoXboxServices -DisableXboxServices $doDisableXboxServices
                    if ($doAmdUlps) { Set-WgoAmdUlps }
                    if ($doAmdMpo) { Set-WgoAmdMpo }
                    if ($doAmdTdr) { Set-WgoAmdTdr }
                    if ($doAmdCrashDefender) { Set-WgoAmdCrashDefender }
                    if ($doAmdHdcp) { Set-WgoAmdHdcp }
                    if ($doAmdTelemetry) { Set-WgoAmdTelemetry }
                    if ($doAmdHwAccel) { Set-WgoAmdHwAccel }
                    Set-WgoMoreOptimizations -Hibernation $doHibernation -PowerPlan $doPowerPlan `
                        -TempCleanup $doTempCleanup -HotCorners $doHotCorners `
                        -BootTimeout $doBootTimeout -OfficeTelemetry $doOfficeTelemetry `
                        -ExtraSchedTasks $doExtraSchedTasks -DiskOptimize $doDiskOptimize `
                        -HagsGameMode $doHagsGameMode -UltimatePerf $doUltimatePerf `
                        -KernelGamingPriority $doKernelGamingPriority -GameDvrDisable $doGameDvrDisable -GameBarMicFix $doGameBarMicFix `
                        -InputLagReduction $doInputLagReduction `
                        -SearchIndexOptimize $doSearchIndexOptimize -GhostAdapters $doGhostAdapters -FastStartup $doFastStartup `
                        -ResidualServices $doResidualServices -StandbyListClean $doStandbyListClean -LargeSystemCache $doLargeSystemCache `
                        -AutoStandbyClean $doAutoStandbyClean `
                        -ClearEventLogs $doClearEventLogs -DeleteMinidump $doDeleteMinidump -ClearStoreCache $doClearStoreCache `
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
                           $doKernelGamingPriority, $doGameDvrDisable, $doGameBarMicFix, $doInputLagReduction,
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
                           $doClearEventLogs, $doDeleteMinidump, $doClearStoreCache,
                           $doPauseUpdates, $doDisableEdgeTelemetry, $doDisableSpotlight,
                           $doAmdUlps, $doAmdMpo, $doAmdTdr, $doAmdCrashDefender, $doAmdHdcp, $doAmdTelemetry, $doAmdHwAccel,
                           $doDryRun) `
          -OnCompleted {
            $Global:WgoUI_Ctrl['btnRunSelected'].IsEnabled = $true
            Save-WgoLastRunState
            $restartRequiredFlags = @(
                $doHibernation, $doFastStartup, $doHagsGameMode, $doDrivers,
                $doVisual, $doPagefile, $doKernelGamingPriority, $doUltimatePerf,
                $doDisableSysMain, $doDisableWSearch, $doDisableSpooler,
                $doRiskyUAC, $doRiskyWinUpdateSvc, $doLargeSystemCache,
                $doDisableHPET, $doRiskyDisableDEP,
                $doAmdUlps, $doAmdTdr, $doAmdHwAccel
            )
            if (-not $doDryRun -and ($restartRequiredFlags -contains $true)) {
                & $restartPromptFn
            }
        }.GetNewClosure()
    })

    # Restore Defaults
    $c['btnRestoreDefaults'].Add_Click({
        $category = "All"
        try { $category = $c['cmbRestoreCategory'].SelectedItem.Tag } catch { }
        if (-not (Show-WgoConfirm -Message (T 'LogRestoreDefaultsStart' $category) -Title "WGO")) { return }
        $c['btnRestoreDefaults'].IsEnabled = $false
        Start-WgoBackgroundTask -ScriptBlock {
            param($category)
            try { Restore-WgoDefaults -Category $category } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
        } -ArgumentList @($category) -OnCompleted {
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
                @{ Chk = $c['chkDnsJumper']; Name = "DNS Jumper" },
                @{ Chk = $c['chkMoonlight']; Name = "Moonlight" },
                @{ Chk = $c['chkSunshine'];  Name = "Sunshine" },
                @{ Chk = $c['chkNilesoftShell']; Name = "Nilesoft Shell" },
                @{ Chk = $c['chkOptiscalerClient']; Name = "Optiscaler Client" },
                @{ Chk = $c['chkFlowLauncher']; Name = "Flow Launcher" },
                @{ Chk = $c['chkShareX']; Name = "ShareX" }
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
    $c['btnReleaseRenewIP'].Add_Click({
        $c['btnReleaseRenewIP'].IsEnabled = $false
        Start-WgoBackgroundTask -ScriptBlock {
            try { Invoke-WgoNetworkReleaseRenew | Out-Null } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
        } -OnCompleted { $c['btnReleaseRenewIP'].IsEnabled = $true }
    })
    $c['btnRegisterDNS'].Add_Click({
        $c['btnRegisterDNS'].IsEnabled = $false
        Start-WgoBackgroundTask -ScriptBlock {
            try { Invoke-WgoNetworkRegisterDns | Out-Null } catch { Write-Log (T 'LogUnhandledError' $_.Exception.Message) "ERROR" }
        } -OnCompleted { $c['btnRegisterDNS'].IsEnabled = $true }
    })
    $c['btnSystemInfo'].Add_Click({
        $info = Get-WgoSystemInfo
        if ($null -eq $info) { return }
        $msg = (T 'TxtSysInfoCpu' $info.Cpu) + "`n" + (T 'TxtSysInfoRam' $info.RamGb) + "`n" + (T 'TxtSysInfoGpu' $info.Gpu) + "`n" +
               (T 'TxtSysInfoOs' $info.OsVersion) + "`n" + (T 'TxtSysInfoDisk' $info.DiskType) + "`n" + (T 'TxtSysInfoBattery' $info.Battery)
        [System.Windows.Forms.MessageBox]::Show($msg, (T 'TxtSystemInfoTitle'), [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        Write-Log (T 'LogSystemInfoShown') "INFO"
    })
    $c['btnStartupManager'].Add_Click({
        Show-WgoStartupManagerDialog
    })
    $c['btnScheduledOptimization'].Add_Click({
        Show-WgoScheduledOptimizationDialog
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