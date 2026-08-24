# Wgo.Core.psm1 - Core optimization functions

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

$BloatwareCriticalProtect = @(
    "Microsoft.DesktopAppInstaller",
    "Microsoft.VCLibs",
    "Microsoft.UI.Xaml",
    "Microsoft.WindowsStore",
    "Microsoft.NET.Native",
    # Apps installable through WGO's own App Installer tab must never be treated as bloatware,
    # even if a profile preset re-enables "Remove bloatware / AI apps".
    "MouriNaruto.NanaZip",
    "40174MouriNaruto.NanaZip"
)

$BloatwareTargets = @(
    "Microsoft.Copilot",
    "Microsoft.Windows.Ai.Copilot.Provider",
    "MicrosoftWindows.Client.CoPilot",
    "Microsoft.WindowsRecall",
    "Microsoft.Windows.Recall",
    "Microsoft.549981C3F5F10",
    "Microsoft.Paint3D",
    "Microsoft.MSPaint",
    "Microsoft.YourPhone",
    "microsoft.windowscommunicationsapps",
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

function Test-WgoProtectedPackage {
    param([string]$Name)
    if ([string]::IsNullOrEmpty($Name)) { return $false }
    foreach ($p in $BloatwareCriticalProtect) {
        if ($Name -like "$p*") { return $true }
    }
    return ($BloatwareWhitelist -contains $Name)
}

function Remove-WgoBloatware {
    Write-Log (T 'LogBloatStart') "INFO"
    foreach ($appName in $BloatwareTargets) {
        if (Test-WgoProtectedPackage -Name $appName) { continue }
        try {
            # Match by exact name or "prefix." (package family convention), not a loose
            # "*substring*" wildcard - avoids catching unrelated packages that merely happen
            # to contain the target string somewhere in their name.
            $pkgs = Get-AppxPackage -AllUsers -ErrorAction Ignore |
                    Where-Object { ($_.Name -eq $appName -or $_.Name -like "$appName.*") -and -not (Test-WgoProtectedPackage -Name $_.Name) }
            foreach ($p in $pkgs) {
                Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Ignore
                Write-Log (T 'LogBloatUserRemoved' $p.Name) "OK"
            }

            $prov = Get-AppxProvisionedPackage -Online -ErrorAction Ignore |
                    Where-Object { ($_.DisplayName -eq $appName -or $_.DisplayName -like "$appName.*") -and -not (Test-WgoProtectedPackage -Name $_.DisplayName) }
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

function Set-WgoVisualEffects {
    Write-Log (T 'LogVisualStart') "INFO"
    try {
        $desktopKey = "HKCU:\Control Panel\Desktop"
        $vfxKey     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        $advKey     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $dwmKey     = "HKCU:\Software\Microsoft\Windows\DWM"
        foreach ($k in @($vfxKey)) { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } }
        New-ItemProperty -Path $vfxKey -Name "VisualFXSetting" -Value 3 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "MinAnimate" -Value 1 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "DragFullWindows" -Value 1 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $advKey -Name "IconsOnly" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "ListviewAlphaSelect" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "FontSmoothing" -Value 2 -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "FontSmoothingType" -Value 2 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $desktopKey -Name "ListviewShadow" -Value 1 -PropertyType DWord -Force | Out-Null
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
        New-ItemProperty -Path $paths.DataCollection -Name "AllowTelemetry" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.DataCollection -Name "LimitDiagnosticDataConfigurationSet" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.DataCollection -Name "DisableOneSettingsDownloads" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.DataCollection -Name "DoNotShowFeedbackNotifications" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.DataCollection -Name "NumberOfSIUFInPeriod" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.AppCompat -Name "AITEnable" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.AppCompat -Name "DisableInventory" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.AppCompat -Name "DisablePCA" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.WER -Name "Disabled" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.WER -Name "DoReport" -Value 0 -PropertyType DWord -Force | Out-Null
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
        New-ItemProperty -Path $paths.Location -Name "DisableLocation" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.Location -Name "DisableLocationScripting" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.Location -Name "DisableSensors" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.Location -Name "DisableWindowsLocationProvider" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.ActivityFeed -Name "EnableActivityFeed" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.ActivityFeed -Name "PublishUserActivities" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $paths.ActivityFeed -Name "UploadUserActivities" -Value 0 -PropertyType DWord -Force | Out-Null
        Write-Log (T 'LogPrivacyOk') "OK"
    } catch {
        Write-Log (T 'LogPrivacyError' $_.Exception.Message) "ERROR"
    }
}

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
            $dcKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            if (-not (Test-Path $dcKey)) { New-Item -Path $dcKey -Force | Out-Null }
            New-ItemProperty -Path $dcKey -Name "AllowTelemetry" -Value 0 -PropertyType DWord -Force | Out-Null
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
            $aiKey     = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
            $expKey    = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
            if (-not (Test-Path $winKey)) { New-Item -Path $winKey -Force | Out-Null }
            if (-not (Test-Path $aiKey))  { New-Item -Path $aiKey -Force | Out-Null }
            if (-not (Test-Path $expKey)) { New-Item -Path $expKey -Force | Out-Null }
            New-ItemProperty -Path $winKey -Name "TurnOffWindowsCopilot" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $expKey -Name "DisableSearchBoxSuggestions" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $dcKey -Name "AllowRecallEnablement" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $dcKey -Name "DisableAIDataAnalysis" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $aiKey -Name "AllowRecallEnablement" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $aiKey -Name "DisableAIDataAnalysis" -Value 1 -PropertyType DWord -Force | Out-Null
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

function Set-WgoAdvancedTweaks {
    param(
        [bool]$EdgeWidgets    = $false,
        [bool]$DeliveryOpt    = $false,
        [bool]$AppsBackground = $false,
        [bool]$NetworkLatency = $false
    )
    if (-not ($EdgeWidgets -or $DeliveryOpt -or $AppsBackground -or $NetworkLatency)) { return }
    Write-Log (T 'LogAdvStart') "INFO"
    if ($EdgeWidgets) {
        try {
            $edgeKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
            $advKey  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $edgeKey)) { New-Item -Path $edgeKey -Force | Out-Null }
            if (-not (Test-Path $advKey))  { New-Item -Path $advKey -Force | Out-Null }

            $applied = 0
            foreach ($prop in @(
                @{ Path = $edgeKey; Name = "StartupBoostEnabled";   RegPath = "HKLM\SOFTWARE\Policies\Microsoft\Edge" },
                @{ Path = $edgeKey; Name = "BackgroundModeEnabled"; RegPath = "HKLM\SOFTWARE\Policies\Microsoft\Edge" },
                @{ Path = $advKey;  Name = "TaskbarDa";             RegPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" }
            )) {
                try {
                    New-ItemProperty -Path $prop.Path -Name $prop.Name -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                    $applied++
                } catch {
                    try {
                        & reg.exe add $prop.RegPath /v $prop.Name /t REG_DWORD /d 0 /f *>$null
                        if ($LASTEXITCODE -eq 0) { $applied++ }
                    } catch { }
                }
            }
            if ($applied -gt 0) {
                Write-Log (T 'LogAdvEdgeWidgetsOk') "OK"
            } else {
                Write-Log (T 'LogAdvError' "EdgeWidgets" (T 'LogAdvEdgeWidgetsAllFailed')) "WARN"
            }
        } catch {
            Write-Log (T 'LogAdvError' "EdgeWidgets" $_.Exception.Message) "ERROR"
        }
    }
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
    if ($AppsBackground) {
        try {
            $bgKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
            if (-not (Test-Path $bgKey)) { New-Item -Path $bgKey -Force | Out-Null }
            New-ItemProperty -Path $bgKey -Name "LetAppsRunInBackground" -Value 2 -PropertyType DWord -Force | Out-Null
            $bgPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
            if (-not (Test-Path $bgPolicyKey)) { New-Item -Path $bgPolicyKey -Force | Out-Null }
            New-ItemProperty -Path $bgPolicyKey -Name "LetAppsRunInBackground" -Value 2 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogAdvAppsBackgroundOk') "OK"
        } catch {
            Write-Log (T 'LogAdvError' "AppsBackground" $_.Exception.Message) "ERROR"
        }
    }
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

function Get-WgoOptimizedPagefileSize {
    param([double]$RamMB)
    $ramGB = $RamMB / 1024
    if     ($ramGB -le 2)  { return @{ Min = 3072; Max = 6144  } }
    elseif ($ramGB -le 4)  { return @{ Min = 4096; Max = 8192  } }
    elseif ($ramGB -le 6)  { return @{ Min = 4096; Max = 9216  } }
    elseif ($ramGB -le 8)  { return @{ Min = 4096; Max = 12288 } }
    elseif ($ramGB -le 12) { return @{ Min = 4096; Max = 10240 } }
    elseif ($ramGB -le 16) { return @{ Min = 4096; Max = 8192  } }
    elseif ($ramGB -le 24) { return @{ Min = 2048; Max = 4096  } }
    elseif ($ramGB -le 32) { return @{ Min = 2048; Max = 4096  } }
    else                   { return @{ Min = 1024; Max = 2048  } }
}

function Set-WgoPagefile {
    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        $ramMB = [Math]::Round($cs.TotalPhysicalMemory / 1MB)
        $rec = Get-WgoOptimizedPagefileSize -RamMB $ramMB
        $minMB = $rec.Min
        $maxMB = $rec.Max
        Write-Log (T 'LogPagefileRam' $ramMB $minMB $maxMB) "INFO"
        $cs2 = Get-CimInstance -ClassName Win32_ComputerSystem
        if ($cs2.AutomaticManagedPagefile) {
            Set-CimInstance -InputObject $cs2 -Property @{ AutomaticManagedPagefile = $false } -ErrorAction Stop
        }
        $sysDrive = $env:SystemDrive
        $pagefilePath = "$sysDrive\pagefile.sys"
        $existing = Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction Ignore |
                    Where-Object { $_.Name -eq $pagefilePath }
        if ($existing) {
            Set-CimInstance -InputObject $existing -Property @{ InitialSize = $minMB; MaximumSize = $maxMB } -ErrorAction Stop
        } else {
            $newPF = New-CimInstance -ClassName Win32_PageFileSetting -Property @{
                Name        = $pagefilePath
                InitialSize = $minMB
                MaximumSize = $maxMB
            } -ErrorAction Stop
        }
        Write-Log (T 'LogPagefileOk' $minMB $maxMB) "OK"
    } catch {
        Write-Log (T 'LogPagefileError' $_.Exception.Message) "ERROR"
    }
}

function Set-WgoMoreOptimizations {
    param(
        [bool]$Hibernation     = $false,
        [bool]$PowerPlan       = $false,
        [bool]$TempCleanup     = $false,
        [bool]$HotCorners      = $false,
        [bool]$BootTimeout     = $false,
        [bool]$OfficeTelemetry = $false,
        [bool]$ExtraSchedTasks = $false,
        [bool]$DiskOptimize    = $false,
        [bool]$HagsGameMode    = $false,
        [bool]$UltimatePerf    = $false,
        [bool]$KernelGamingPriority = $false,
        [bool]$GameDvrDisable  = $false,
        [bool]$InputLagReduction = $false,
        [bool]$SearchIndexOptimize = $false,
        [bool]$GhostAdapters   = $false,
        [bool]$FastStartup     = $false,
        [bool]$ResidualServices = $false,
        [bool]$StandbyListClean = $false,
        [bool]$LargeSystemCache = $false,
        [bool]$AutoStandbyClean = $false,
        [bool]$DryRun          = $false
    )
    if (-not ($Hibernation -or $PowerPlan -or $TempCleanup -or $HotCorners -or
               $BootTimeout -or $OfficeTelemetry -or $ExtraSchedTasks -or $DiskOptimize -or
               $HagsGameMode -or $UltimatePerf -or $KernelGamingPriority -or $GameDvrDisable -or $InputLagReduction -or
               $SearchIndexOptimize -or $GhostAdapters -or $FastStartup -or $ResidualServices -or $StandbyListClean -or
               $LargeSystemCache -or $AutoStandbyClean)) { return }
    Write-Log (T 'LogMoreStart') "INFO"
    if ($DryRun) { Write-Log (T 'LogDryRunNote') "WARN" }

    if ($Hibernation) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkHibernation')) "INFO" }
        else {
            try {
                & powercfg.exe /hibernate off 2>$null | Out-Null
                Write-Log (T 'LogHibernationOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "Hibernation" $_.Exception.Message) "ERROR" }
        }
    }
    if ($PowerPlan) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkPowerPlan')) "INFO" }
        else {
            try {
                & powercfg.exe /setactive SCHEME_MIN 2>$null | Out-Null
                Write-Log (T 'LogPowerPlanOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "PowerPlan" $_.Exception.Message) "ERROR" }
        }
    }
    if ($TempCleanup) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkTempCleanup')) "INFO" }
        else {
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
                $shaderCachePaths = @(
                    "$env:LOCALAPPDATA\D3DSCache",
                    "$env:LOCALAPPDATA\NVIDIA\DXCache",
                    "$env:LOCALAPPDATA\NVIDIA\GLCache",
                    "$env:LOCALAPPDATA\AMD\DxCache",
                    "$env:LOCALAPPDATA\AMD\DxcCache",
                    "$env:LOCALAPPDATA\AMD\VkCache",
                    "$env:LOCALAPPDATA\Intel\ShaderCache"
                )
                foreach ($scPath in $shaderCachePaths) {
                    if (Test-Path $scPath) {
                        Remove-Item -Path "$scPath\*" -Recurse -Force -ErrorAction Ignore
                    }
                }
                Write-Log (T 'LogShaderCacheCleanOk') "OK"
                Write-Log (T 'LogTempCleanupOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "TempCleanup" $_.Exception.Message) "ERROR" }
        }
    }
    if ($HotCorners) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkHotCorners')) "INFO" }
        else {
            try {
                $advKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                if (-not (Test-Path $advKey)) { New-Item -Path $advKey -Force | Out-Null }
                New-ItemProperty -Path $advKey -Name "EnableSnapAssistFlyout" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $advKey -Name "SnapFill" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $advKey -Name "SnapAssist" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $advKey -Name "DisallowShaking" -Value 1 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogHotCornersOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "HotCorners" $_.Exception.Message) "ERROR" }
        }
    }
    if ($BootTimeout) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkBootTimeout')) "INFO" }
        else {
            try {
                & bcdedit.exe /timeout 5 2>$null | Out-Null
                Write-Log (T 'LogBootTimeoutOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "BootTimeout" $_.Exception.Message) "ERROR" }
        }
    }
    if ($OfficeTelemetry) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkOfficeTelemetry')) "INFO" }
        else {
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
            } catch { Write-Log (T 'LogMoreError' "OfficeTelemetry" $_.Exception.Message) "ERROR" }
        }
    }
    if ($ExtraSchedTasks) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkExtraSchedTasks')) "INFO" }
        else {
            try {
                $extraTasks = @(
                    "\Microsoft\Windows\Feedback\Siuf\DmClient",
                    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
                    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
                    "\Microsoft\Office\OfficeTelemetryAgentFallBack2016",
                    "\Microsoft\Office\OfficeTelemetryAgentLogOn2016",
                    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
                    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
                    "\Microsoft\Windows\Application Experience\StartupAppTask",
                    "\Microsoft\Windows\Autochk\Proxy",
                    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
                    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
                )
                foreach ($task in $extraTasks) {
                    try { Disable-ScheduledTask -TaskPath (Split-Path $task) -TaskName (Split-Path $task -Leaf) -ErrorAction Ignore | Out-Null } catch {}
                }
                Write-Log (T 'LogExtraSchedTasksOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "ExtraSchedTasks" $_.Exception.Message) "ERROR" }
        }
    }
    if ($DiskOptimize) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkDiskOptimize')) "INFO" }
        else {
            try {
                $disks = Get-PhysicalDisk -ErrorAction Ignore
                $hasSSD = $false; $hasHDD = $false
                foreach ($d in $disks) {
                    if ($d.MediaType -eq 'SSD') { $hasSSD = $true }
                    elseif ($d.MediaType -eq 'HDD') { $hasHDD = $true }
                }
                $summary = @()
                if ($hasSSD) {
                    & fsutil.exe behavior set DisableDeleteNotify 0 2>$null | Out-Null
                    $summary += "SSD: TRIM ON"
                }
                if ($hasHDD) {
                    try { Enable-ScheduledTask -TaskName "ScheduledDefrag" -TaskPath "\Microsoft\Windows\Defrag\" -ErrorAction Ignore | Out-Null } catch {}
                    $summary += "HDD: Scheduled Defrag ON"
                }
                if (-not $hasSSD -and -not $hasHDD) { $summary += "N/A" }
                Write-Log (T 'LogDiskOptimizeOk' ($summary -join ", ")) "OK"
            } catch { Write-Log (T 'LogMoreError' "DiskOptimize" $_.Exception.Message) "ERROR" }
        }
    }
    if ($HagsGameMode) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkHagsGameMode')) "INFO" }
        else {
            try {
                $gameBarKey  = "HKCU:\Software\Microsoft\GameBar"
                $graphicsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
                if (-not (Test-Path $gameBarKey))  { New-Item -Path $gameBarKey -Force | Out-Null }
                if (-not (Test-Path $graphicsKey)) { New-Item -Path $graphicsKey -Force | Out-Null }
                New-ItemProperty -Path $gameBarKey -Name "AutoGameModeEnabled" -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $gameBarKey -Name "AllowAutoGameMode"   -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $graphicsKey -Name "HwSchMode" -Value 2 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogHagsGameModeOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "HagsGameMode" $_.Exception.Message) "ERROR" }
        }
    }
    if ($UltimatePerf) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkUltimatePerf')) "INFO" }
        else {
            try {
                $ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
                $existing = (& powercfg.exe /list) -join "`n"
                $scheme = $null
                if ($existing -match "([0-9a-fA-F-]{36})\s+\(.*Ultimate Performance.*\)") {
                    $scheme = $Matches[1]
                } else {
                    $dup = & powercfg.exe -duplicatescheme $ultimateGuid
                    if ($dup -match "([0-9a-fA-F-]{8}-[0-9a-fA-F-]{4}-[0-9a-fA-F-]{4}-[0-9a-fA-F-]{4}-[0-9a-fA-F-]{12})") {
                        $scheme = $Matches[1]
                    }
                }
                if (-not $scheme) { $scheme = $ultimateGuid }
                & powercfg.exe /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 100 2>$null | Out-Null
                & powercfg.exe /setdcvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 100 2>$null | Out-Null
                & powercfg.exe /setactive $scheme 2>$null | Out-Null
                Write-Log (T 'LogUltimatePerfOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "UltimatePerf" $_.Exception.Message) "ERROR" }
        }
    }
    if ($KernelGamingPriority) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkKernelGamingPriority')) "INFO" }
        else {
            try {
                $priorityKey = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
                if (-not (Test-Path $priorityKey)) { New-Item -Path $priorityKey -Force | Out-Null }
                New-ItemProperty -Path $priorityKey -Name "Win32PrioritySeparation" -Value 38 -PropertyType DWord -Force | Out-Null
                $gamesTaskKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
                if (-not (Test-Path $gamesTaskKey)) { New-Item -Path $gamesTaskKey -Force | Out-Null }
                New-ItemProperty -Path $gamesTaskKey -Name "GPU Priority"         -Value 8    -PropertyType DWord  -Force | Out-Null
                New-ItemProperty -Path $gamesTaskKey -Name "Priority"             -Value 6    -PropertyType DWord  -Force | Out-Null
                New-ItemProperty -Path $gamesTaskKey -Name "Scheduling Category"  -Value "High" -PropertyType String -Force | Out-Null
                New-ItemProperty -Path $gamesTaskKey -Name "SFIO Priority"        -Value "High" -PropertyType String -Force | Out-Null
                Write-Log (T 'LogKernelGamingPriorityOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "KernelGamingPriority" $_.Exception.Message) "ERROR" }
        }
    }
    if ($GameDvrDisable) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkGameDvrDisable')) "INFO" }
        else {
            try {
                $gameConfigKey = "HKCU:\System\GameConfigStore"
                $gameDvrPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
                if (-not (Test-Path $gameConfigKey))    { New-Item -Path $gameConfigKey -Force | Out-Null }
                if (-not (Test-Path $gameDvrPolicyKey)) { New-Item -Path $gameDvrPolicyKey -Force | Out-Null }
                New-ItemProperty -Path $gameConfigKey -Name "GameDVR_Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $gameDvrPolicyKey -Name "AllowGameDVR" -Value 0 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogGameDvrDisableOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "GameDvrDisable" $_.Exception.Message) "ERROR" }
        }
    }
    if ($InputLagReduction) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkInputLagReduction')) "INFO" }
        else {
            try {
                $mouseKey = "HKCU:\Control Panel\Mouse"
                Set-ItemProperty -Path $mouseKey -Name "MouseSpeed"      -Value "0" -Type String -Force
                Set-ItemProperty -Path $mouseKey -Name "MouseThreshold1" -Value "0" -Type String -Force
                Set-ItemProperty -Path $mouseKey -Name "MouseThreshold2" -Value "0" -Type String -Force
                $accessKey = "HKCU:\Control Panel\Accessibility"
                Set-ItemProperty -Path "$accessKey\StickyKeys"        -Name "Flags" -Value "58" -Type String -Force
                Set-ItemProperty -Path "$accessKey\ToggleKeys"        -Name "Flags" -Value "58" -Type String -Force
                Set-ItemProperty -Path "$accessKey\Keyboard Response" -Name "Flags" -Value "58" -Type String -Force
                $gameConfigKey = "HKCU:\System\GameConfigStore"
                if (-not (Test-Path $gameConfigKey)) { New-Item -Path $gameConfigKey -Force | Out-Null }
                New-ItemProperty -Path $gameConfigKey -Name "GameDVR_FSEBehaviorMode"          -Value 2 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $gameConfigKey -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogInputLagReductionOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "InputLagReduction" $_.Exception.Message) "ERROR" }
        }
    }
    if ($SearchIndexOptimize) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkSearchIndexOptimize')) "INFO" }
        else {
            try {
                $junkPaths = @(
                    "$env:TEMP",
                    "$env:WINDIR\Temp",
                    "$env:WINDIR\Prefetch",
                    "$env:WINDIR\SoftwareDistribution\Download",
                    "$env:LOCALAPPDATA\Temp",
                    "$env:LOCALAPPDATA\D3DSCache",
                    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
                    "$env:LOCALAPPDATA\Microsoft\Windows\WebCache",
                    "$env:LOCALAPPDATA\Packages"
                )
                foreach ($jp in $junkPaths) {
                    if (Test-Path $jp) {
                        try {
                            $folder = Get-Item -Path $jp -Force -ErrorAction Stop
                            $folder.Attributes = $folder.Attributes -bor [System.IO.FileAttributes]::NotContentIndexed
                        } catch { }
                    }
                }
                $searchPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                if (-not (Test-Path $searchPolicyKey)) { New-Item -Path $searchPolicyKey -Force | Out-Null }
                New-ItemProperty -Path $searchPolicyKey -Name "AllowIndexingEncryptedStoresOrItems" -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $searchPolicyKey -Name "PreventIndexingOutlook"              -Value 1 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogSearchIndexOptimizeOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "SearchIndexOptimize" $_.Exception.Message) "ERROR" }
        }
    }
    if ($GhostAdapters) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkGhostAdapters')) "INFO" }
        else {
            try {
                $removed = 0
                $ghosts = Get-PnpDevice -Class Net -ErrorAction Stop |
                    Where-Object { $_.Status -eq 'Unknown' }
                foreach ($g in $ghosts) {
                    try {
                        & pnputil.exe /remove-device $g.InstanceId 2>$null | Out-Null
                        $removed++
                        Write-Log ("  - $($g.FriendlyName)") "INFO"
                    } catch { }
                }
                if ($removed -gt 0) {
                    Write-Log (T 'LogGhostAdaptersOk' $removed) "OK"
                } else {
                    Write-Log (T 'LogGhostAdaptersNone') "OK"
                }
            } catch { Write-Log (T 'LogMoreError' "GhostAdapters" $_.Exception.Message) "ERROR" }
        }
    }
    if ($FastStartup) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkFastStartup')) "INFO" }
        else {
            try {
                $powerKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
                if (-not (Test-Path $powerKey)) { New-Item -Path $powerKey -Force | Out-Null }
                New-ItemProperty -Path $powerKey -Name "HiberbootEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogFastStartupOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "FastStartup" $_.Exception.Message) "ERROR" }
        }
    }
    if ($ResidualServices) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkResidualServices')) "INFO" }
        else {
            try {
                $targetServices = @("PcaSvc", "WerSvc", "wisvc", "RetailDemo", "Fax", "RemoteRegistry", "MapsBroker", "lfsvc", "WMPNetworkSvc", "PhoneSvc", "CDPSvc", "SEMgrSvc")
                $applied = @()
                foreach ($svcName in $targetServices) {
                    $svc = Get-Service -Name $svcName -ErrorAction Ignore
                    if ($svc) {
                        try {
                            Set-Service -Name $svcName -StartupType Manual -ErrorAction Stop
                            $applied += $svcName
                        } catch { }
                    }
                }
                Write-Log (T 'LogResidualServicesOk' $applied.Count ($applied -join ", ")) "OK"
            } catch { Write-Log (T 'LogMoreError' "ResidualServices" $_.Exception.Message) "ERROR" }
        }
    }
    if ($StandbyListClean) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkStandbyListClean')) "INFO" }
        else {
            $freedMb = Invoke-WgoStandbyListPurge
            if ($null -ne $freedMb) {
                Write-Log (T 'LogStandbyListCleanOk' $freedMb) "OK"
            } else {
                Write-Log (T 'LogStandbyListCleanFail') "WARN"
            }
        }
    }
    if ($LargeSystemCache) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkLargeSystemCache')) "INFO" }
        else {
            try {
                $totalRamGb = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
                if ($totalRamGb -ge 8) {
                    $mmKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
                    New-ItemProperty -Path $mmKey -Name "LargeSystemCache" -Value 1 -PropertyType DWord -Force | Out-Null
                    New-ItemProperty -Path $mmKey -Name "DisablePagingExecutive" -Value 1 -PropertyType DWord -Force | Out-Null
                    Write-Log (T 'LogLargeSystemCacheOk' $totalRamGb) "OK"
                } else {
                    Write-Log (T 'LogLargeSystemCacheSkipped' $totalRamGb) "INFO"
                }
            } catch { Write-Log (T 'LogMoreError' "LargeSystemCache" $_.Exception.Message) "ERROR" }
        }
    }
    if ($AutoStandbyClean) {
        if ($DryRun) { Write-Log (T 'LogDryRunPrefix' (T 'ChkAutoStandbyClean')) "INFO" }
        else {
            try {
                $taskName = "WGO_StandbyClean"
                $nativeModule = Join-Path $Global:WgoRootPath "Modules\Wgo.Native\Wgo.Native.psm1"
                $taskCmd = "Import-Module '$nativeModule' -Force; Invoke-WgoStandbyListPurge | Out-Null"
                $encodedCmd = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($taskCmd))
                $action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -EncodedCommand $encodedCmd"
                $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
                $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
                $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Ignore
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null
                Write-Log (T 'LogAutoStandbyCleanOk') "OK"
            } catch { Write-Log (T 'LogMoreError' "AutoStandbyClean" $_.Exception.Message) "ERROR" }
        }
    }
    Write-Log (T 'LogMoreDone') "OK"
}

function Restore-WgoDefaults {
    Write-Log (T 'LogRestoreDefaultsStart') "INFO"
    try {
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
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        )
        foreach ($k in $keysToRemove) {
            if (Test-Path $k) { Remove-Item -Path $k -Recurse -Force -ErrorAction Ignore }
        }
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
        Remove-ItemProperty -Path $hkcuAdvKey -Name "DisableSearchBoxSuggestions" -Force -ErrorAction Ignore
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Force -ErrorAction Ignore
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Force -ErrorAction Ignore
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
        & bcdedit.exe /timeout 30 2>$null | Out-Null
        try {
            $powerKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
            if (Test-Path $powerKey) {
                New-ItemProperty -Path $powerKey -Name "HiberbootEnabled" -Value 1 -PropertyType DWord -Force | Out-Null
            }
        } catch { }
        try {
            $junkPaths = @(
                "$env:TEMP", "$env:WINDIR\Temp", "$env:WINDIR\Prefetch",
                "$env:LOCALAPPDATA\Temp", "$env:LOCALAPPDATA\D3DSCache",
                "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
                "$env:LOCALAPPDATA\Microsoft\Windows\WebCache",
                "$env:LOCALAPPDATA\Packages"
            )
            foreach ($jp in $junkPaths) {
                if (Test-Path $jp) {
                    $folder = Get-Item -Path $jp -Force -ErrorAction Ignore
                    if ($folder) {
                        $folder.Attributes = $folder.Attributes -band (-bnot [System.IO.FileAttributes]::NotContentIndexed)
                    }
                }
            }
        } catch { }
        foreach ($svcName in @("DiagTrack", "dmwappushservice", "SysMain", "WSearch", "Spooler")) {
            $svc = Get-Service -Name $svcName -ErrorAction Ignore
            if ($svc) {
                Set-Service -Name $svcName -StartupType Automatic -ErrorAction Ignore
                Start-Service -Name $svcName -ErrorAction Ignore
            }
        }
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

function Set-WgoServiceMgmt {
    param(
        [bool]$DisableSysMain  = $false,
        [bool]$DisableWSearch  = $false,
        [bool]$DisableSpooler  = $false
    )
    if (-not ($DisableSysMain -or $DisableWSearch -or $DisableSpooler)) { return }
    Write-Log (T 'LogServicesStart') "INFO"
    $applied = @()
    if ($DisableSysMain) {
        try {
            $svc = Get-Service -Name "SysMain" -ErrorAction Ignore
            if ($svc) {
                Stop-Service -Name "SysMain" -Force -ErrorAction Ignore
                Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction Ignore
                $applied += "SysMain"
            }
        } catch {
            Write-Log (T 'LogServicesError' "SysMain" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableWSearch) {
        try {
            $svc = Get-Service -Name "WSearch" -ErrorAction Ignore
            if ($svc) {
                Stop-Service -Name "WSearch" -Force -ErrorAction Ignore
                Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction Ignore
                $applied += "WSearch"
            }
        } catch {
            Write-Log (T 'LogServicesError' "WSearch" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableSpooler) {
        try {
            $svc = Get-Service -Name "Spooler" -ErrorAction Ignore
            if ($svc) {
                Stop-Service -Name "Spooler" -Force -ErrorAction Ignore
                Set-Service -Name "Spooler" -StartupType Disabled -ErrorAction Ignore
                $applied += "Spooler"
            }
        } catch {
            Write-Log (T 'LogServicesError' "Spooler" $_.Exception.Message) "ERROR"
        }
    }
    if ($applied.Count -gt 0) {
        Write-Log (T 'LogServicesOk' ($applied -join ", ")) "OK"
    }
    Write-Log (T 'LogServicesDone') "OK"
}

function Remove-WgoWindowsBackupApp {
    # "Windows Backup" ships bundled inside the "Windows Feature Experience Pack"
    # (MicrosoftWindows.Client.CBS) since Windows 10/11 23H2+ and is NOT a standalone
    # app - Microsoft has confirmed it cannot be uninstalled, only disabled/hidden.
    # This disables the nag notifications, its scheduled tasks, and its service,
    # and only attempts an AppX removal as a harmless best-effort in case a future
    # Windows build ever splits it back out into its own package.
    try {
        $applied = 0

        # Best-effort: only succeeds if a future/different build ships it as a real AppX
        Get-AppxPackage -AllUsers -Name "*WindowsBackup*" -ErrorAction Ignore | ForEach-Object {
            try { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop; $applied++ } catch { }
        }
        Get-AppxProvisionedPackage -Online -ErrorAction Ignore |
            Where-Object { $_.PackageName -like "*WindowsBackup*" } |
            ForEach-Object {
                try { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop | Out-Null; $applied++ } catch { }
            }

        # Real, documented mechanism: disables the "Turn on Windows Backup" nag notification
        $wbKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsBackup"
        if (-not (Test-Path $wbKey)) { New-Item -Path $wbKey -Force | Out-Null }
        New-ItemProperty -Path $wbKey -Name "DisableMonitoring" -Value 1 -PropertyType DWord -Force | Out-Null
        $applied++

        # Disable its scheduled tasks (Task Scheduler Library > Microsoft > Windows > WindowsBackup)
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsBackup\" -ErrorAction Ignore | ForEach-Object {
            try { Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction Stop | Out-Null; $applied++ } catch { }
        }

        # Disable the Windows Backup service, if present on this build
        $svc = Get-Service -Name "WindowsBackup" -ErrorAction Ignore
        if ($svc) {
            try {
                Stop-Service -Name "WindowsBackup" -Force -ErrorAction Ignore
                Set-Service -Name "WindowsBackup" -StartupType Disabled -ErrorAction Stop
                $applied++
            } catch { }
        }

        if ($applied -gt 0) {
            Write-Log (T 'LogWinBackupRemoveOk') "OK"
        } else {
            Write-Log (T 'LogWinBackupRemoveNone') "INFO"
        }
    } catch {
        Write-Log (T 'LogWinBackupRemoveError' $_.Exception.Message) "ERROR"
    }
}

function Set-WgoExtraTweaks2 {
    param(
        [bool]$HostsBlock       = $false,
        [bool]$PrivacyDeep      = $false,
        [bool]$CacheClean       = $false,
        [bool]$UiCleanup        = $false,
        [bool]$TcpAutotuning    = $false,
        [bool]$DoH              = $false,
        [bool]$FastShutdown     = $false,
        [bool]$PrefetchSSD      = $false,
        [bool]$RemoveWinBackup  = $false,
        [bool]$TcpIpReset       = $false,
        [bool]$RemoveOnedrive   = $false,
        [bool]$DisableGameBar   = $false,
        [bool]$DisableStore     = $false,
        [bool]$DisableWer       = $false
    )
    if (-not ($HostsBlock -or $PrivacyDeep -or $CacheClean -or $UiCleanup -or $TcpAutotuning -or
              $DoH -or $FastShutdown -or $PrefetchSSD -or $RemoveWinBackup -or $TcpIpReset -or
              $RemoveOnedrive -or $DisableGameBar -or $DisableStore -or $DisableWer)) { return }
    Write-Log (T 'LogExtra2Start') "INFO"

    if ($HostsBlock) {
        try {
            $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
            $marker = "# WGO-telemetry-block"
            $domains = @(
                "vortex.data.microsoft.com","vortex-win.data.microsoft.com",
                "settings-win.data.microsoft.com","watson.telemetry.microsoft.com",
                "telemetry.microsoft.com","telecommand.telemetry.microsoft.com",
                "oca.telemetry.microsoft.com","sqm.telemetry.microsoft.com",
                "watson.ppe.telemetry.microsoft.com","redir.metaservices.microsoft.com",
                "choice.microsoft.com","choice.microsoft.com.nsatc.net",
                "df.telemetry.microsoft.com","reports.wes.df.telemetry.microsoft.com",
                "wes.df.telemetry.microsoft.com","services.wes.df.telemetry.microsoft.com",
                "sqm.df.telemetry.microsoft.com","telemetry.appex.bing.net",
                "telemetry.urs.microsoft.com","survey.watson.microsoft.com"
            )
            $content = Get-Content -Path $hostsPath -Raw -ErrorAction Stop
            if ($content -notmatch [regex]::Escape($marker)) {
                $lines = @("`n$marker") + ($domains | ForEach-Object { "0.0.0.0 $_" }) + @("$marker-end`n")
                Add-Content -Path $hostsPath -Value ($lines -join "`r`n") -Encoding ASCII
            }
            Write-Log (T 'LogExtra2HostsOk' $domains.Count) "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "HostsBlock" $_.Exception.Message) "ERROR"
        }
    }

    if ($PrivacyDeep) {
        try {
            $sharedExpKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedExperience"
            if (-not (Test-Path $sharedExpKey)) { New-Item -Path $sharedExpKey -Force | Out-Null }
            New-ItemProperty -Path $sharedExpKey -Name "Disabled" -Value 1 -PropertyType DWord -Force | Out-Null

            $cortanaKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $cortanaKey)) { New-Item -Path $cortanaKey -Force | Out-Null }
            New-ItemProperty -Path $cortanaKey -Name "AllowCortana" -Value 0 -PropertyType DWord -Force | Out-Null

            Get-AppxPackage -AllUsers -Name "Microsoft.549981C3F5F10" -ErrorAction Ignore |
                Remove-AppxPackage -AllUsers -ErrorAction Ignore

            Write-Log (T 'LogExtra2PrivacyDeepOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "PrivacyDeep" $_.Exception.Message) "ERROR"
        }
    }

    if ($CacheClean) {
        try {
            $iconCache = "$env:LOCALAPPDATA\IconCache.db"
            $explorerCacheDir = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
            $fontCacheDir = "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache"
            if (Test-Path $iconCache) { Remove-Item -Path $iconCache -Force -ErrorAction Ignore }
            if (Test-Path $explorerCacheDir) {
                Get-ChildItem -Path $explorerCacheDir -Filter "iconcache*.db" -ErrorAction Ignore |
                    Remove-Item -Force -ErrorAction Ignore
                Get-ChildItem -Path $explorerCacheDir -Filter "thumbcache*.db" -ErrorAction Ignore |
                    Remove-Item -Force -ErrorAction Ignore
            }
            if (Test-Path $fontCacheDir) {
                Get-ChildItem -Path $fontCacheDir -Filter "*.dat" -ErrorAction Ignore |
                    Remove-Item -Force -ErrorAction Ignore
            }
            Write-Log (T 'LogExtra2CacheOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "CacheClean" $_.Exception.Message) "ERROR"
        }
    }

    if ($UiCleanup) {
        try {
            $advKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $advKey)) { New-Item -Path $advKey -Force | Out-Null }
            New-ItemProperty -Path $advKey -Name "PeopleBand" -Value 0 -PropertyType DWord -Force | Out-Null

            $feedsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
            if (-not (Test-Path $feedsKey)) { New-Item -Path $feedsKey -Force | Out-Null }
            New-ItemProperty -Path $feedsKey -Name "ShellFeedsTaskbarViewMode" -Value 2 -PropertyType DWord -Force | Out-Null

            $tabletKey = "HKCU:\Software\Microsoft\TabletTip\1.7"
            if (-not (Test-Path $tabletKey)) { New-Item -Path $tabletKey -Force | Out-Null }
            New-ItemProperty -Path $tabletKey -Name "EnableInkingButton" -Value 0 -PropertyType DWord -Force | Out-Null

            Write-Log (T 'LogExtra2UiCleanupOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "UiCleanup" $_.Exception.Message) "ERROR"
        }
    }

    if ($TcpAutotuning) {
        try {
            & netsh int tcp set global autotuninglevel=disabled | Out-Null
            Write-Log (T 'LogExtra2TcpOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "TcpAutotuning" $_.Exception.Message) "ERROR"
        }
    }

    if ($DoH) {
        try {
            $adapters = Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' }
            $dnsCount = 0
            foreach ($ad in $adapters) {
                Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction Stop
                $dnsCount++
            }
            $dohKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\DohWellKnownServers"
            if (-not (Test-Path $dohKey)) { New-Item -Path $dohKey -Force | Out-Null }
            New-ItemProperty -Path $dohKey -Name "1.1.1.1" -Value "https://cloudflare-dns.com/dns-query" -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $dohKey -Name "1.0.0.1" -Value "https://cloudflare-dns.com/dns-query" -PropertyType String -Force | Out-Null
            $policyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
            if (-not (Test-Path $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
            New-ItemProperty -Path $policyKey -Name "DoHPolicy" -Value 2 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogExtra2DoHOk' $dnsCount) "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "DoH" $_.Exception.Message) "ERROR"
        }
    }

    if ($FastShutdown) {
        try {
            $mmKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            New-ItemProperty -Path $mmKey -Name "ClearPageFileAtShutdown" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogExtra2FastShutdownOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "FastShutdown" $_.Exception.Message) "ERROR"
        }
    }

    if ($PrefetchSSD) {
        try {
            $isSSD = $false
            Get-PhysicalDisk -ErrorAction Ignore | ForEach-Object {
                if ($_.MediaType -eq 'SSD') { $isSSD = $true }
            }
            if ($isSSD) {
                $mmKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
                New-ItemProperty -Path $mmKey -Name "EnablePrefetcher" -Value 0 -PropertyType DWord -Force | Out-Null
                Write-Log (T 'LogExtra2PrefetchOk') "OK"
            } else {
                Write-Log (T 'LogExtra2PrefetchSkipped') "INFO"
            }
        } catch {
            Write-Log (T 'LogExtra2Error' "PrefetchSSD" $_.Exception.Message) "ERROR"
        }
    }

    if ($RemoveWinBackup) { Remove-WgoWindowsBackupApp }

    if ($TcpIpReset) {
        try {
            & netsh int ip reset 2>$null | Out-Null
            & netsh winsock reset 2>$null | Out-Null
            Write-Log (T 'LogExtra2TcpIpResetOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "TcpIpReset" $_.Exception.Message) "ERROR"
        }
    }

    if ($RemoveOnedrive) {
        try {
            # SAFETY: this must ONLY remove the OneDrive application (binaries, app cache,
            # app registry keys). It must NEVER touch $env:USERPROFILE\OneDrive itself, because
            # when "Backup de Pastas" / Known Folder Move is enabled, that path IS the user's
            # real Desktop/Documents/Pictures/etc. - not a copy. Deleting it deletes their files.
            $oneDrivePath = "$env:USERPROFILE\OneDrive"
            $shellFoldersKey     = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
            $userShellFoldersKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
            $knownFolderValueNames = @(
                "Desktop", "Personal", "{F42EE2D3-909F-4907-8871-4C22FC0BF756}",
                "My Pictures", "My Music", "My Video", "{374DE290-123F-4565-9164-39C4925E467B}"
            )
            $isKnownFolderRedirected = $false
            if (Test-Path $oneDrivePath) {
                foreach ($valueName in $knownFolderValueNames) {
                    foreach ($regKey in @($userShellFoldersKey, $shellFoldersKey)) {
                        try {
                            $current = (Get-ItemProperty -Path $regKey -Name $valueName -ErrorAction Ignore).$valueName
                            if ($current -and ($current -like "$oneDrivePath*")) { $isKnownFolderRedirected = $true }
                        } catch {}
                    }
                }
            }

            Stop-Process -Name "OneDrive" -Force -ErrorAction Ignore
            $uninstaller = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
            if (-not (Test-Path $uninstaller)) { $uninstaller = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }
            if (Test-Path $uninstaller) {
                Start-Process -FilePath $uninstaller -ArgumentList "/uninstall" -Wait -ErrorAction Stop
            }

            # Only ever delete the OneDrive app's own support/cache directories - never the
            # user's profile OneDrive folder.
            foreach ($path in @(
                "$env:LOCALAPPDATA\Microsoft\OneDrive",
                "$env:PROGRAMDATA\Microsoft OneDrive", "$env:SYSTEMDRIVE\OneDriveTemp"
            )) {
                if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force -ErrorAction Ignore }
            }

            if ($isKnownFolderRedirected) {
                # Desktop/Documents/etc. live inside \OneDrive\ - it holds real user files.
                # Leave it completely untouched; only the app itself was removed above.
                Write-Log "OneDrive app removed. '$oneDrivePath' contains redirected user folders (Desktop/Documents/etc.) and was left untouched to avoid data loss." "WARN"
            } elseif (Test-Path $oneDrivePath) {
                # No known folder points inside it - safe to remove only if it's actually empty
                # (i.e. genuinely just leftover OneDrive scaffolding, not user data).
                $remaining = @(Get-ChildItem -Path $oneDrivePath -Force -ErrorAction Ignore)
                if ($remaining.Count -eq 0) {
                    Remove-Item -Path $oneDrivePath -Recurse -Force -ErrorAction Ignore
                } else {
                    Write-Log "OneDrive folder '$oneDrivePath' still contains $($remaining.Count) item(s); left in place to avoid data loss." "WARN"
                }
            }

            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\OneDrive" -Recurse -Force -ErrorAction Ignore
            Write-Log (T 'LogRemoveOnedriveOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "RemoveOnedrive" $_.Exception.Message) "ERROR"
        }
    }

    if ($DisableGameBar) {
        try {
            $gbKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar"
            if (-not (Test-Path $gbKey)) { New-Item -Path $gbKey -Force | Out-Null }
            New-ItemProperty -Path $gbKey -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $gbKey -Name "ShowStartupPanel" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogGameBarOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "DisableGameBar" $_.Exception.Message) "ERROR"
        }
    }

    if ($DisableStore) {
        try {
            $storeKey = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
            if (-not (Test-Path $storeKey)) { New-Item -Path $storeKey -Force | Out-Null }
            New-ItemProperty -Path $storeKey -Name "RemoveWindowsStore" -Value 1 -PropertyType DWord -Force | Out-Null
            $svc = Get-Service -Name "PushToInstall" -ErrorAction Ignore
            if ($svc) {
                Stop-Service -Name "PushToInstall" -Force -ErrorAction Ignore
                Set-Service -Name "PushToInstall" -StartupType Disabled -ErrorAction Ignore
            }
            Write-Log (T 'LogStoreOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "DisableStore" $_.Exception.Message) "ERROR"
        }
    }

    if ($DisableWer) {
        try {
            $werKey = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
            if (-not (Test-Path $werKey)) { New-Item -Path $werKey -Force | Out-Null }
            New-ItemProperty -Path $werKey -Name "Disabled" -Value 1 -PropertyType DWord -Force | Out-Null
            $svc = Get-Service -Name "WerSvc" -ErrorAction Ignore
            if ($svc) {
                Stop-Service -Name "WerSvc" -Force -ErrorAction Ignore
                Set-Service -Name "WerSvc" -StartupType Disabled -ErrorAction Ignore
            }
            Write-Log (T 'LogWerOk') "OK"
        } catch {
            Write-Log (T 'LogExtra2Error' "DisableWer" $_.Exception.Message) "ERROR"
        }
    }

    Write-Log (T 'LogExtra2Done') "OK"
}

function Set-WgoRiskyTweaks {
    # These options weaken Windows security or update mechanisms - only apply if you
    # understand and accept the trade-off. The UI already asks for explicit confirmation.
    param(
        [bool]$DisableUAC          = $false,
        [bool]$DisableSmartScreen  = $false,
        [bool]$DisableDefenderRT   = $false,
        [bool]$DisableWinUpdateSvc = $false,
        [bool]$DisableBits         = $false,
        [bool]$DisableFirewall     = $false,
        [bool]$DisableDEP          = $false,
        [bool]$NvidiaMaxPerf       = $false
    )
    if (-not ($DisableUAC -or $DisableSmartScreen -or $DisableDefenderRT -or $DisableWinUpdateSvc -or $DisableBits -or
              $DisableFirewall -or $DisableDEP -or $NvidiaMaxPerf)) { return }
    Write-Log (T 'LogRiskyStart') "WARN"

    if ($DisableUAC) {
        try {
            $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            New-ItemProperty -Path $uacKey -Name "EnableLUA" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogRiskyUACOk') "WARN"
        } catch {
            Write-Log (T 'LogRiskyError' "UAC" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableSmartScreen) {
        try {
            $ssKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            if (-not (Test-Path $ssKey)) { New-Item -Path $ssKey -Force | Out-Null }
            New-ItemProperty -Path $ssKey -Name "EnableSmartScreen" -Value 0 -PropertyType DWord -Force | Out-Null
            $edgeSsKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
            if (-not (Test-Path $edgeSsKey)) { New-Item -Path $edgeSsKey -Force | Out-Null }
            New-ItemProperty -Path $edgeSsKey -Name "SmartScreenEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogRiskySmartScreenOk') "WARN"
        } catch {
            Write-Log (T 'LogRiskyError' "SmartScreen" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableDefenderRT) {
        try {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
            Write-Log (T 'LogRiskyDefenderOk') "WARN"
        } catch {
            Write-Log (T 'LogRiskyError' "DefenderRT" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableWinUpdateSvc) {
        try {
            Stop-Service -Name "wuauserv" -Force -ErrorAction Ignore
            Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction Stop
            Write-Log (T 'LogRiskyWinUpdateOk') "WARN"
        } catch {
            Write-Log (T 'LogRiskyError' "WindowsUpdate" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableBits) {
        try {
            Stop-Service -Name "BITS" -Force -ErrorAction Ignore
            Set-Service -Name "BITS" -StartupType Disabled -ErrorAction Stop
            Write-Log (T 'LogRiskyBitsOk') "WARN"
        } catch {
            Write-Log (T 'LogRiskyError' "BITS" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableFirewall) {
        try {
            Set-NetFirewallProfile -All -Enabled False -ErrorAction Stop
            Write-Log (T 'LogRiskyFirewallOk') "WARN"
        } catch {
            Write-Log (T 'LogRiskyError' "Firewall" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableDEP) {
        try {
            & bcdedit /set nx AlwaysOff | Out-Null
            Write-Log (T 'LogRiskyDEPOk') "WARN"
        } catch {
            Write-Log (T 'LogRiskyError' "DEP" $_.Exception.Message) "ERROR"
        }
    }
    if ($NvidiaMaxPerf) {
        try {
            $gpuBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
            $applied = 0
            if (Test-Path $gpuBase) {
                Get-ChildItem -Path $gpuBase -ErrorAction Stop | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
                    try {
                        New-ItemProperty -Path $_.PSPath -Name "PowerMizerEnable" -Value 0 -PropertyType DWord -Force | Out-Null
                        New-ItemProperty -Path $_.PSPath -Name "PerfLevelSrc" -Value 0x3333 -PropertyType DWord -Force | Out-Null
                        $applied++
                    } catch { }
                }
            }
            if ($applied -gt 0) {
                Write-Log (T 'LogRiskyNvidiaPerfOk' $applied) "WARN"
            } else {
                Write-Log (T 'LogRiskyNvidiaPerfNone') "INFO"
            }
        } catch {
            Write-Log (T 'LogRiskyError' "NvidiaMaxPerf" $_.Exception.Message) "ERROR"
        }
    }
    Write-Log (T 'LogRiskyDone') "WARN"
}

function Set-WgoCpuTimerTweaks {
    param(
        [bool]$DisableCoreParking = $false,
        [bool]$DisableHPET        = $false,
        [bool]$TimerResolution    = $false,
        [bool]$HungAppTimeout     = $false
    )
    if (-not ($DisableCoreParking -or $DisableHPET -or $TimerResolution -or $HungAppTimeout)) { return }
    Write-Log (T 'LogCpuTimerStart') "INFO"

    if ($DisableCoreParking) {
        try {
            $subKey = "54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
            $attrPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\$subKey"
            if (Test-Path $attrPath) {
                New-ItemProperty -Path $attrPath -Name "Attributes" -Value 2 -PropertyType DWord -Force | Out-Null
            }
            $plans = powercfg /list | Select-String -Pattern '([0-9a-fA-F-]{36})' | ForEach-Object { $_.Matches[0].Value }
            foreach ($guid in $plans) {
                # Max processor state must be set to 100 BEFORE min-cores, or powercfg rejects
                # the min-cores value as "out of range" on any plan where max is below 100.
                & powercfg -setacvalueindex $guid "54533251-82be-4824-96c1-47b60b740d00" "bc5038f7-23e0-4960-96da-33abaf5935ec" 100 *>$null
                & powercfg -setdcvalueindex $guid "54533251-82be-4824-96c1-47b60b740d00" "bc5038f7-23e0-4960-96da-33abaf5935ec" 100 *>$null
                & powercfg -setacvalueindex $guid "54533251-82be-4824-96c1-47b60b740d00" "0cc5b647-c1df-4637-891a-dec35c318583" 100 *>$null
                & powercfg -setdcvalueindex $guid "54533251-82be-4824-96c1-47b60b740d00" "0cc5b647-c1df-4637-891a-dec35c318583" 100 *>$null
            }
            $activeGuid = (powercfg /getactivescheme *>&1 | Select-String -Pattern '([0-9a-fA-F-]{36})' | Select-Object -First 1).Matches[0].Value
            if ($activeGuid) { & powercfg -setactive $activeGuid *>$null }
            Write-Log (T 'LogCoreParkingOk') "OK"
        } catch {
            Write-Log (T 'LogCpuTimerError' "CoreParking" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableHPET) {
        try {
            & bcdedit /set useplatformclock false | Out-Null
            & bcdedit /set tscsyncpolicy Enhanced | Out-Null
            Write-Log (T 'LogHPETOk') "WARN"
        } catch {
            Write-Log (T 'LogCpuTimerError' "HPET" $_.Exception.Message) "ERROR"
        }
    }
    if ($TimerResolution) {
        try {
            $applied = Set-WgoTimerResolutionNative
            if ($null -ne $applied) {
                Write-Log (T 'LogTimerResolutionOk' ([math]::Round($applied / 10000, 2))) "OK"
            } else {
                Write-Log (T 'LogTimerResolutionFail') "WARN"
            }
        } catch {
            Write-Log (T 'LogCpuTimerError' "TimerResolution" $_.Exception.Message) "ERROR"
        }
    }
    if ($HungAppTimeout) {
        try {
            $deskKey = "HKCU:\Control Panel\Desktop"
            New-ItemProperty -Path $deskKey -Name "HungAppTimeout" -Value "1000" -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $deskKey -Name "WaitToKillAppTimeout" -Value "2000" -PropertyType String -Force | Out-Null
            Write-Log (T 'LogHungAppOk') "OK"
        } catch {
            Write-Log (T 'LogCpuTimerError' "HungAppTimeout" $_.Exception.Message) "ERROR"
        }
    }
    Write-Log (T 'LogCpuTimerDone') "OK"
}

function Set-WgoGpuTweaks {
    param(
        [bool]$IncreaseTdrNvidia      = $false,
        [bool]$DisableNvidiaTelemetry = $false
    )
    if (-not ($IncreaseTdrNvidia -or $DisableNvidiaTelemetry)) { return }
    Write-Log (T 'LogGpuStart') "INFO"

    if ($IncreaseTdrNvidia) {
        try {
            $gfxKey = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            if (-not (Test-Path $gfxKey)) { New-Item -Path $gfxKey -Force | Out-Null }
            New-ItemProperty -Path $gfxKey -Name "TdrDelay" -Value 10 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $gfxKey -Name "TdrDdiDelay" -Value 10 -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogTdrNvidiaOk') "OK"
        } catch {
            Write-Log (T 'LogGpuError' "TdrNvidia" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableNvidiaTelemetry) {
        try {
            $stopped = 0
            foreach ($svcName in @("NvTelemetryContainer", "NvContainerLocalSystem")) {
                $svc = Get-Service -Name $svcName -ErrorAction Ignore
                if ($svc) {
                    Stop-Service -Name $svcName -Force -ErrorAction Ignore
                    Set-Service -Name $svcName -StartupType Disabled -ErrorAction Ignore
                    $stopped++
                }
            }
            $disabledTasks = 0
            Get-ScheduledTask -ErrorAction Ignore | Where-Object { $_.TaskName -match 'NvTmMon|NvTmRep|NvProfileUpdaterDaily|NvProfileUpdaterOnLogon|NvDriverUpdateCheckDaily' } | ForEach-Object {
                try { Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction Stop | Out-Null; $disabledTasks++ } catch { }
            }
            Write-Log (T 'LogNvidiaTelemetryOk' $stopped $disabledTasks) "OK"
        } catch {
            Write-Log (T 'LogGpuError' "NvidiaTelemetry" $_.Exception.Message) "ERROR"
        }
    }
    Write-Log (T 'LogGpuDone') "OK"
}

function Set-WgoNetworkAdvanced {
    param(
        [bool]$DisableNagle = $false,
        [bool]$DisableIPv6  = $false,
        [bool]$RssOptimize  = $false
    )
    if (-not ($DisableNagle -or $DisableIPv6 -or $RssOptimize)) { return }
    Write-Log (T 'LogNetAdvStart') "INFO"

    if ($DisableNagle) {
        try {
            $ifBase = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            $applied = 0
            if (Test-Path $ifBase) {
                Get-ChildItem -Path $ifBase -ErrorAction Stop | ForEach-Object {
                    try {
                        New-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null
                        New-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
                        $applied++
                    } catch { }
                }
            }
            Write-Log (T 'LogNagleOk' $applied) "OK"
        } catch {
            Write-Log (T 'LogNetAdvError' "Nagle" $_.Exception.Message) "ERROR"
        }
    }
    if ($DisableIPv6) {
        try {
            $v6Key = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
            New-ItemProperty -Path $v6Key -Name "DisabledComponents" -Value 0xFF -PropertyType DWord -Force | Out-Null
            Write-Log (T 'LogIPv6Ok') "WARN"
        } catch {
            Write-Log (T 'LogNetAdvError' "IPv6" $_.Exception.Message) "ERROR"
        }
    }
    if ($RssOptimize) {
        try {
            $rssKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Ndis\Parameters\Rss"
            if (-not (Test-Path $rssKey)) { New-Item -Path $rssKey -Force | Out-Null }
            $cores = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
            $maxProcs = [Math]::Max(2, [Math]::Min(4, $cores))
            New-ItemProperty -Path $rssKey -Name "RssBaseProcessor" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $rssKey -Name "RssMaxProcessors" -Value $maxProcs -PropertyType DWord -Force | Out-Null
            & netsh int tcp set global rssprofile=closest 2>$null | Out-Null
            Write-Log (T 'LogRssOk' $maxProcs) "OK"
        } catch {
            Write-Log (T 'LogNetAdvError' "Rss" $_.Exception.Message) "ERROR"
        }
    }
    Write-Log (T 'LogNetAdvDone') "OK"
}

function Set-WgoXboxServices {
    # Intentionally kept out of $Global:WgoUI_OptimizationCheckboxNames - never touched by
    # "Select All", "Maximum Optimization", or any predefined profile. Xbox/Game Pass and
    # kernel-level anti-cheat (e.g. Vanguard, EAC) can depend on these, so this is opt-in only.
    param(
        [bool]$DisableXboxServices = $false
    )
    if (-not $DisableXboxServices) { return }
    Write-Log (T 'LogXboxStart') "INFO"
    try {
        $targetServices = @("XblAuthManager", "XblGameSave", "XboxNetApiSvc", "XboxGipSvc")
        $applied = @()
        foreach ($svcName in $targetServices) {
            $svc = Get-Service -Name $svcName -ErrorAction Ignore
            if ($svc) {
                try {
                    Stop-Service -Name $svcName -Force -ErrorAction Ignore
                    Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop
                    $applied += $svcName
                } catch { }
            }
        }
        Write-Log (T 'LogXboxOk' $applied.Count ($applied -join ", ")) "OK"
    } catch {
        Write-Log (T 'LogMoreError' "XboxServices" $_.Exception.Message) "ERROR"
    }
}

Export-ModuleMember -Function @(
    'New-WgoRestorePoint', 'Remove-WgoBloatware', 'Test-WgoProtectedPackage',
    'Set-WgoLocalSearch', 'Set-WgoVisualEffects', 'Set-WgoPrivacyPolicies',
    'Set-WgoExtraPrivacy', 'Set-WgoAdvancedTweaks', 'Set-WgoBlockDriverUpdates',
    'Set-WgoPagefile', 'Get-WgoOptimizedPagefileSize', 'Set-WgoMoreOptimizations',
    'Restore-WgoDefaults', 'Set-WgoServiceMgmt',
    'Set-WgoExtraTweaks2', 'Set-WgoRiskyTweaks', 'Remove-WgoWindowsBackupApp',
    'Set-WgoCpuTimerTweaks', 'Set-WgoGpuTweaks', 'Set-WgoNetworkAdvanced', 'Set-WgoXboxServices'
)