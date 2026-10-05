

function Get-WgoGpuInventory {
    if ($Global:WgoGpuInventoryCache) { return $Global:WgoGpuInventoryCache }
    $list = @()
    try {
        $controllers = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop)
        foreach ($v in $controllers) {
            $name = [string]$v.Name
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            $compat = [string]$v.AdapterCompatibility
            if ($name -match 'Microsoft Basic|Remote Display|Hyper-V|VMware|VirtualBox|Virtual Display|Parsec|Citrix|Indirect Display|IddCx|DisplayLink|spacedesk|Miracast|Meta Virtual') { continue }
            $both = "$name $compat"
            $vendor = 'Other'
            if     ($both -match 'NVIDIA|GeForce|Quadro|Tesla')                { $vendor = 'NVIDIA' }
            elseif ($both -match 'AMD|Radeon|Advanced Micro Devices|\bATI\b')   { $vendor = 'AMD' }
            elseif ($both -match 'Intel')                                       { $vendor = 'Intel' }

            $integrated = $false
            if ($vendor -eq 'AMD') {
                $integrated = ($name -match 'Radeon(\(TM\))?\s+Graphics|Radeon(\(TM\))?\s+\d{3}M\b|Vega\s+\d+\s+Graphics')
            } elseif ($vendor -eq 'Intel') {
                $integrated = -not ($name -match 'Arc.*\b[AB]\d{3}\b')
            }
            $list += [pscustomobject]@{
                Name          = ($name -replace '\s+', ' ').Trim()
                Vendor        = $vendor
                IsIntegrated  = [bool]$integrated
                DriverVersion = [string]$v.DriverVersion
            }
        }
    } catch { }
    $Global:WgoGpuInventoryCache = $list
    return $list
}

function Test-WgoGpuVendorPresent {
    param([Parameter(Mandatory = $true)][string]$Vendor)
    foreach ($g in @(Get-WgoGpuInventory)) { if ($g.Vendor -eq $Vendor) { return $true } }
    return $false
}

function Get-WgoHardwareProfile {
    $p = [ordered]@{
        OsCaption = ''; OsBuild = 0; IsWin11 = $false
        CpuName = ''; CpuVendor = 'Unknown'; Cores = 0; LogicalProcessors = 0
        RamGb = 0; Manufacturer = ''; Model = ''
        IsVirtualMachine = $false; IsLaptop = $false; HasBattery = $false
        HasSsd = $false; SystemDriveIsSsd = $false; HasHdd = $false; DiskSummary = ''
        Gpus = @(); GpuSummary = ''; HasNvidia = $false; HasAmd = $false; HasIntel = $false
    }
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $p.OsCaption = [string]$os.Caption
        $p.OsBuild   = [int]$os.BuildNumber
        $p.IsWin11   = ($p.OsBuild -ge 22000)
    } catch { }
    try {
        $cpus = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
        if ($cpus.Count -gt 0) {
            $p.CpuName = ([string]$cpus[0].Name -replace '\s+', ' ').Trim()
            if     ($cpus[0].Manufacturer -match 'Intel') { $p.CpuVendor = 'Intel' }
            elseif ($cpus[0].Manufacturer -match 'AMD')   { $p.CpuVendor = 'AMD' }
            $p.Cores = [int](($cpus | Measure-Object -Property NumberOfCores -Sum).Sum)
            $p.LogicalProcessors = [int](($cpus | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)
        }
    } catch { }
    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $p.RamGb = [int][math]::Round($cs.TotalPhysicalMemory / 1GB)
        $p.Manufacturer = [string]$cs.Manufacturer
        $p.Model = [string]$cs.Model
        $p.IsVirtualMachine = ("$($cs.Manufacturer) $($cs.Model)" -match 'Virtual|VMware|KVM|QEMU|Xen|HVM domU|Bochs|Parallels')
    } catch { }
    try {
        $p.HasBattery = [bool](Get-CimInstance -ClassName Win32_Battery -ErrorAction Ignore)
        $laptopChassis = @(8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32)
        $chassis = @((Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction Ignore).ChassisTypes)
        $isLaptopChassis = $false
        foreach ($t in $chassis) { if ($laptopChassis -contains [int]$t) { $isLaptopChassis = $true } }
        $p.IsLaptop = ($p.HasBattery -or $isLaptopChassis)
    } catch { }
    try {
        $disks = @(Get-WgoDiskKinds)
        $p.HasSsd = [bool](@($disks | Where-Object { $_.Kind -eq 'SSD' }).Count)
        $p.HasHdd = [bool](@($disks | Where-Object { $_.Kind -eq 'HDD' }).Count)
        $sys = @($disks | Where-Object { $_.IsSystem })
        $p.SystemDriveIsSsd = if ($sys.Count -gt 0) { [bool]($sys[0].Kind -eq 'SSD') } else { $p.HasSsd }
        $p.DiskSummary = Get-WgoDiskSummary
    } catch { }
    try {
        $gpus = @(Get-WgoGpuInventory)
        $p.Gpus = $gpus
        $p.HasNvidia = [bool](@($gpus | Where-Object { $_.Vendor -eq 'NVIDIA' }).Count)
        $p.HasAmd    = [bool](@($gpus | Where-Object { $_.Vendor -eq 'AMD' }).Count)
        $p.HasIntel  = [bool](@($gpus | Where-Object { $_.Vendor -eq 'Intel' }).Count)
        $p.GpuSummary = (($gpus | ForEach-Object { $_.Name }) -join ' + ')
    } catch { }
    return [pscustomobject]$p
}

function Get-WgoOptimizationStatus {
    param([Parameter(Mandatory = $true)]$Hardware)

    $result = @{}
    $hw = $Hardware

    function New-Status([string]$State, [string]$Reason = '', [string]$Detail = '') {
        return @{ State = $State; Reason = $Reason; Detail = $Detail }
    }
    function Read-Reg([string]$Path, [string]$Name) {
        try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { return $null }
    }
    function Test-Equal($Actual, $Expected) {
        if ($null -eq $Actual) { return $false }
        if ($Expected -is [string]) { return (([string]$Actual).Trim() -eq $Expected) }
        try { return ((([int64]$Actual) -band 0xFFFFFFFFL) -eq (([int64]$Expected) -band 0xFFFFFFFFL)) } catch { return $false }
    }
    function Check-Reg($Checks) {
        $ok = 0
        foreach ($c in $Checks) { if (Test-Equal (Read-Reg $c.P $c.N) $c.V) { $ok++ } }
        if ($ok -eq $Checks.Count) { return (New-Status 'Applied') }
        if ($ok -eq 0)             { return (New-Status 'Pending') }
        return (New-Status 'Partial' '' "$ok/$($Checks.Count)")
    }
    function Check-Services([string[]]$Names, [string[]]$Accept) {
        $found = 0; $good = 0; $bad = @()
        foreach ($n in $Names) {
            $s = Get-Service -Name $n -ErrorAction Ignore
            if (-not $s) { continue }
            $found++
            if ($Accept -contains [string]$s.StartType) { $good++ } else { $bad += $n }
        }
        if ($found -eq 0)    { return (New-Status 'NotApplicable' 'NoService') }
        if ($good -eq $found) { return (New-Status 'Applied') }
        if ($good -eq 0)      { return (New-Status 'Pending' '' ($bad -join ', ')) }
        return (New-Status 'Partial' '' ($bad -join ', '))
    }
    function Check-Tasks([string[]]$FullPaths) {
        $found = 0; $disabled = 0
        foreach ($t in $FullPaths) {
            $dir = (Split-Path $t) + '\'
            $leaf = Split-Path $t -Leaf
            $task = Get-ScheduledTask -TaskPath $dir -TaskName $leaf -ErrorAction Ignore
            if (-not $task) { continue }
            $found++
            if ([string]$task.State -eq 'Disabled') { $disabled++ }
        }
        if ($found -eq 0)        { return (New-Status 'Applied' 'NoTasks') }
        if ($disabled -eq $found) { return (New-Status 'Applied') }
        if ($disabled -eq 0)      { return (New-Status 'Pending') }
        return (New-Status 'Partial' '' "$disabled/$found")
    }
    function Get-FolderSizeMB([string]$Path, [int]$MaxMs = 2500) {
        if (-not (Test-Path -LiteralPath $Path)) { return 0 }
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $sum = 0L
        $stack = New-Object 'System.Collections.Generic.Stack[string]'
        $stack.Push($Path)
        while ($stack.Count -gt 0 -and $sw.ElapsedMilliseconds -lt $MaxMs) {
            $dir = $stack.Pop()
            try {
                $di = New-Object System.IO.DirectoryInfo $dir
                foreach ($f in $di.EnumerateFiles()) { $sum += $f.Length }
                foreach ($d in $di.EnumerateDirectories()) {
                    if (-not ($d.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) { $stack.Push($d.FullName) }
                }
            } catch { }
        }
        return [math]::Round($sum / 1MB, 1)
    }
    function Get-ActiveIfacePaths {
        $root = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
        $out = @()
        foreach ($k in @(Get-ChildItem -LiteralPath $root -ErrorAction Ignore)) {
            $props = Get-ItemProperty -LiteralPath $k.PSPath -ErrorAction Ignore
            if (-not $props) { continue }
            $names = @($props.PSObject.Properties.Name)
            $hasIp = ($names -contains 'DhcpIPAddress' -and $props.DhcpIPAddress) -or
                     ($names -contains 'IPAddress' -and $props.IPAddress -and ((@($props.IPAddress) -join '') -notin @('', '0.0.0.0')))
            if ($hasIp) { $out += $k.PSPath }
        }
        return $out
    }
    function Get-SchemeSettingIndex([string]$Scheme, [string]$SubGroup, [string]$Setting) {
        return (Read-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$Scheme\$SubGroup\$Setting" 'ACSettingIndex')
    }
    function Get-BcdValue([string]$Name, [string]$Entry = '{current}') {
        $out = (& bcdedit.exe /enum $Entry 2>$null) -join "`n"
        if ($LASTEXITCODE -ne 0) { return $null }
        if ($out -match "(?im)^\s*$Name\s+(\S+)") { return $Matches[1] }
        return ''
    }

    $gfx        = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
    $dcPolicy   = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
    $edgePolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    $cdm        = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    $advKey     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $mmKey      = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    $powerKey   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'
    $sysProfile = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    $laptopNote = if ($hw.IsLaptop) { 'LaptopBattery' } else { '' }

    $detectors = [ordered]@{}

    $detectors['chkBloat'] = {
        $targets = @(Get-WgoBloatwareTargets)
        $found = @()
        foreach ($pkg in @(Get-AppxPackage -AllUsers -ErrorAction Ignore)) {
            $n = [string]$pkg.Name
            if (Test-WgoProtectedPackage -Name $n) { continue }
            foreach ($t in $targets) { if ($n -like "*$t*") { $found += $n; break } }
        }
        $found = @($found | Sort-Object -Unique)
        if ($found.Count -eq 0) { return (New-Status 'Applied') }
        return (New-Status 'Pending' '' ("{0}: {1}" -f $found.Count, (($found | Select-Object -First 4) -join ', ')))
    }
    $detectors['chkSearch'] = { Check-Reg @(
        @{ P = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; N = 'DisableSearchBoxSuggestions'; V = 1 },
        @{ P = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; N = 'BingSearchEnabled'; V = 0 },
        @{ P = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; N = 'CortanaConsent'; V = 0 }) }
    $detectors['chkVisual'] = { Check-Reg @(
        @{ P = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; N = 'VisualFXSetting'; V = 3 },
        @{ P = $advKey; N = 'TaskbarAnimations'; V = 0 },
        @{ P = 'HKCU:\Control Panel\Desktop'; N = 'MenuAnimation'; V = '0' },
        @{ P = 'HKCU:\Software\Microsoft\Windows\DWM'; N = 'EnableAeroPeek'; V = 0 }) }
    $detectors['chkPrivacy'] = { Check-Reg @(
        @{ P = $dcPolicy; N = 'AllowTelemetry'; V = 0 },
        @{ P = $dcPolicy; N = 'LimitDiagnosticDataConfigurationSet'; V = 1 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; N = 'DisableInventory'; V = 1 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; N = 'Disabled'; V = 1 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows'; N = 'CEIPEnable'; V = 0 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors'; N = 'DisableLocation'; V = 1 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; N = 'EnableActivityFeed'; V = 0 }) }
    $detectors['chkDrivers'] = { Check-Reg @(
        @{ P = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching'; N = 'SearchOrderConfig'; V = 0 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; N = 'ExcludeWUDriversInQualityUpdate'; V = 1 }) }
    $detectors['chkPagefile'] = {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        if ($cs.AutomaticManagedPagefile) { return (New-Status 'Pending') }
        $rec = Get-WgoOptimizedPagefileSize -RamMB ([math]::Round($cs.TotalPhysicalMemory / 1MB))
        $pf = Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction Ignore | Where-Object { $_.Name -eq "$env:SystemDrive\pagefile.sys" } | Select-Object -First 1
        if ($pf -and [int]$pf.InitialSize -eq $rec.Min -and [int]$pf.MaximumSize -eq $rec.Max) { return (New-Status 'Applied' '' "$($rec.Min)-$($rec.Max) MB") }
        return (New-Status 'Pending')
    }
    $detectors['chkAdvertisingId'] = { Check-Reg @(
        @{ P = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; N = 'Enabled'; V = 0 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'; N = 'DisabledByGroupPolicy'; V = 1 }) }
    $detectors['chkTailoredExp'] = { Check-Reg @(
        @{ P = $cdm; N = 'SubscribedContent-338388Enabled'; V = 0 },
        @{ P = $cdm; N = 'SystemPaneSuggestionsEnabled'; V = 0 },
        @{ P = $cdm; N = 'PreInstalledAppsEnabled'; V = 0 },
        @{ P = $cdm; N = 'SilentInstalledAppsEnabled'; V = 0 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; N = 'DisableWindowsConsumerFeatures'; V = 1 }) }
    $detectors['chkDiagTrackSvc'] = {
        $reg = Check-Reg @(@{ P = $dcPolicy; N = 'AllowTelemetry'; V = 0 })
        $svc = Check-Services @('DiagTrack', 'dmwappushservice') @('Disabled')
        if ($reg.State -eq 'Applied' -and ($svc.State -in @('Applied', 'NotApplicable'))) { return (New-Status 'Applied') }
        if ($reg.State -eq 'Pending' -and $svc.State -ne 'Applied') { return (New-Status 'Pending') }
        return (New-Status 'Partial')
    }
    $detectors['chkCopilotBlock'] = { Check-Reg @(
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'; N = 'TurnOffWindowsCopilot'; V = 1 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; N = 'DisableAIDataAnalysis'; V = 1 }) }
    $detectors['chkInputTelemetry'] = { Check-Reg @(
        @{ P = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization'; N = 'RestrictImplicitInkCollection'; V = 1 },
        @{ P = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization'; N = 'RestrictImplicitTextCollection'; V = 1 },
        @{ P = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore'; N = 'HarvestContacts'; V = 0 }) }
    $detectors['chkEdgeWidgets'] = {
        $c = @(@{ P = $edgePolicy; N = 'StartupBoostEnabled'; V = 0 }, @{ P = $edgePolicy; N = 'BackgroundModeEnabled'; V = 0 })
        if ($hw.IsWin11) { $c += @{ P = $advKey; N = 'TaskbarDa'; V = 0 } }
        Check-Reg $c }
    $detectors['chkDeliveryOpt'] = { Check-Reg @(@{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; N = 'DODownloadMode'; V = 0 }) }
    $detectors['chkAppsBackground'] = { Check-Reg @(
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'; N = 'LetAppsRunInBackground'; V = 2 },
        @{ P = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; N = 'LetAppsRunInBackground'; V = 2 }) }
    $detectors['chkNetworkLatency'] = { Check-Reg @(
        @{ P = $sysProfile; N = 'NetworkThrottlingIndex'; V = 0xFFFFFFFFL },
        @{ P = $sysProfile; N = 'SystemResponsiveness'; V = 0 }) }
    $detectors['chkHungAppTimeout'] = { Check-Reg @(
        @{ P = 'HKCU:\Control Panel\Desktop'; N = 'HungAppTimeout'; V = '1000' },
        @{ P = 'HKCU:\Control Panel\Desktop'; N = 'WaitToKillAppTimeout'; V = '2000' }) }

    $detectors['chkDisableSysMain'] = { Check-Services @('SysMain') @('Disabled') }
    $detectors['chkDisableWSearch'] = { Check-Services @('WSearch') @('Disabled') }
    $detectors['chkDisableSpooler'] = { Check-Services @('Spooler') @('Disabled') }
    $detectors['chkDisableXboxServices'] = { Check-Services @('XblAuthManager', 'XblGameSave', 'XboxNetApiSvc', 'XboxGipSvc') @('Disabled') }

    $detectors['chkHibernation'] = {
        $v = Read-Reg $powerKey 'HibernateEnabled'
        if ($null -eq $v) { return (New-Status 'Unknown') }
        if ([int]$v -eq 0) { return (New-Status 'Applied') }
        return (New-Status 'Pending' $laptopNote)
    }
    $detectors['chkPowerPlan'] = {
        $g = Get-WgoActiveSchemeGuid
        if (-not $g) { return (New-Status 'Unknown') }
        if ($g -eq '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') { return (New-Status 'Applied' '' 'High Performance') }
        if ($g -notin @('381b4222-f694-41f0-9685-4b25ce48ccc1', 'a1841308-3541-4fab-bc81-f71556f20b4a') -and
            (Test-Equal (Get-SchemeSettingIndex $g '54533251-82be-4824-96c1-47b60b740d00' '893dee8e-2bef-41e0-89c6-b55d0929964c') 100)) {
            return (New-Status 'Applied' '' 'custom, CPU min 100%')
        }
        return (New-Status 'Pending' $laptopNote)
    }
    $detectors['chkUltimatePerf'] = {
        $g = Get-WgoActiveSchemeGuid
        if (-not $g) { return (New-Status 'Unknown') }
        $builtin = @('381b4222-f694-41f0-9685-4b25ce48ccc1', 'a1841308-3541-4fab-bc81-f71556f20b4a', '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c')
        if ($g -notin $builtin -and (Test-Equal (Get-SchemeSettingIndex $g '54533251-82be-4824-96c1-47b60b740d00' '893dee8e-2bef-41e0-89c6-b55d0929964c') 100)) {
            return (New-Status 'Applied')
        }
        return (New-Status 'Pending' $laptopNote)
    }
    $detectors['chkFastStartup'] = { Check-Reg @(@{ P = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; N = 'HiberbootEnabled'; V = 0 }) }
    $detectors['chkBootTimeout'] = {
        $v = Get-BcdValue 'timeout' '{bootmgr}'
        if ($null -eq $v -or $v -eq '') { return (New-Status 'Unknown') }
        if ([int]$v -le 5) { return (New-Status 'Applied' '' "${v}s") }
        return (New-Status 'Pending' '' "${v}s")
    }
    $detectors['chkDiskOptimize'] = {
        if (-not $hw.HasSsd -and -not $hw.HasHdd) { return (New-Status 'Unknown') }
        $okSsd = $true; $okHdd = $true
        if ($hw.HasSsd) {
            $q = (& fsutil.exe behavior query DisableDeleteNotify 2>$null) -join "`n"
            $okSsd = ($q -match 'DisableDeleteNotify\s*=\s*0')
        }
        if ($hw.HasHdd) {
            $t = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction Ignore
            $okHdd = ($t -and [string]$t.State -ne 'Disabled')
        }
        if ($okSsd -and $okHdd) { return (New-Status 'Applied') }
        return (New-Status 'Pending')
    }
    $detectors['chkPrefetchSSD'] = {
        if (-not $hw.SystemDriveIsSsd) { return (New-Status 'NotApplicable' 'NoSsd') }
        Check-Reg @(@{ P = "$mmKey\PrefetchParameters"; N = 'EnablePrefetcher'; V = 0 })
    }
    $detectors['chkLargeSystemCache'] = {
        if ($hw.RamGb -lt 8) { return (New-Status 'NotApplicable' 'LowRam' "$($hw.RamGb) GB") }
        Check-Reg @(@{ P = $mmKey; N = 'LargeSystemCache'; V = 1 }, @{ P = $mmKey; N = 'DisablePagingExecutive'; V = 1 })
    }
    $detectors['chkFastShutdown'] = { Check-Reg @(@{ P = $mmKey; N = 'ClearPageFileAtShutdown'; V = 0 }) }
    $detectors['chkDisableCoreParking'] = {
        $g = Get-WgoActiveSchemeGuid
        if (-not $g) { return (New-Status 'Unknown') }
        if (Test-Equal (Get-SchemeSettingIndex $g '54533251-82be-4824-96c1-47b60b740d00' '0cc5b647-c1df-4637-891a-dec35c318583') 100) { return (New-Status 'Applied') }
        return (New-Status 'Pending' $laptopNote)
    }
    $detectors['chkDisableHPET'] = {
        $tsc = Get-BcdValue 'tscsyncpolicy'
        $plat = Get-BcdValue 'useplatformclock'
        if ($null -eq $tsc) { return (New-Status 'Unknown') }
        if ($tsc -match 'Enhanced' -and $plat -notmatch 'Yes') { return (New-Status 'Applied') }
        return (New-Status 'Pending')
    }
    $detectors['chkTimerResolution'] = {
        if (-not ('Wgo.NativeTimerQuery' -as [type])) {
            Add-Type -Namespace Wgo -Name NativeTimerQuery -MemberDefinition @'
[DllImport("ntdll.dll")]
public static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint CurrentResolution);
'@
        }
        [uint32]$min = 0; [uint32]$max = 0; [uint32]$cur = 0
        $rc = [Wgo.NativeTimerQuery]::NtQueryTimerResolution([ref]$min, [ref]$max, [ref]$cur)
        if ($rc -ne 0) { return (New-Status 'Unknown') }
        $ms = [math]::Round($cur / 10000.0, 2)
        if ($cur -le 5100) { return (New-Status 'Applied' '' "$ms ms") }
        return (New-Status 'Pending' '' "$ms ms")
    }

    $detectors['chkHagsGameMode'] = {
        if ($hw.OsBuild -lt 19041) { return (New-Status 'NotApplicable' 'OsTooOld') }
        $c = @(@{ P = 'HKCU:\Software\Microsoft\GameBar'; N = 'AutoGameModeEnabled'; V = 1 })
        if (-not $hw.HasAmd) { $c += @{ P = $gfx; N = 'HwSchMode'; V = 2 } }
        Check-Reg $c
    }
    $detectors['chkKernelGamingPriority'] = {
        $g = "$sysProfile\Tasks\Games"
        Check-Reg @(
            @{ P = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; N = 'Win32PrioritySeparation'; V = 38 },
            @{ P = $g; N = 'GPU Priority'; V = 8 }, @{ P = $g; N = 'Priority'; V = 6 },
            @{ P = $g; N = 'Scheduling Category'; V = 'High' }, @{ P = $g; N = 'SFIO Priority'; V = 'High' })
    }
    $detectors['chkGameDvrDisable'] = { Check-Reg @(@{ P = 'HKCU:\System\GameConfigStore'; N = 'GameDVR_Enabled'; V = 0 }) }
    $detectors['chkGameBarMicFix'] = { Check-Reg @(@{ P = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'; N = 'EchoCancellationEnabled'; V = 0 }) }
    $detectors['chkInputLagReduction'] = { Check-Reg @(
        @{ P = 'HKCU:\Control Panel\Mouse'; N = 'MouseSpeed'; V = '0' },
        @{ P = 'HKCU:\Control Panel\Mouse'; N = 'MouseThreshold1'; V = '0' },
        @{ P = 'HKCU:\Control Panel\Mouse'; N = 'MouseThreshold2'; V = '0' },
        @{ P = 'HKCU:\Control Panel\Accessibility\StickyKeys'; N = 'Flags'; V = '58' },
        @{ P = 'HKCU:\System\GameConfigStore'; N = 'GameDVR_FSEBehaviorMode'; V = 2 },
        @{ P = 'HKCU:\System\GameConfigStore'; N = 'GameDVR_HonorUserFSEBehaviorMode'; V = 1 }) }
    $detectors['chkHotCorners'] = { Check-Reg @(
        @{ P = $advKey; N = 'SnapAssist'; V = 0 }, @{ P = $advKey; N = 'DisallowShaking'; V = 1 }) }

    $detectors['chkOfficeTelemetry'] = { Check-Reg @(
        @{ P = 'HKCU:\Software\Policies\Microsoft\office\16.0\common'; N = 'qmenable'; V = 0 },
        @{ P = 'HKCU:\Software\Policies\Microsoft\office\16.0\common'; N = 'sendcustomerdata'; V = 0 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; N = 'DisableTelemetry'; V = 1 }) }
    $detectors['chkExtraSchedTasks'] = { Check-Tasks @(
        '\Microsoft\Windows\Feedback\Siuf\DmClient', '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload',
        '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
        '\Microsoft\Office\OfficeTelemetryAgentFallBack2016', '\Microsoft\Office\OfficeTelemetryAgentLogOn2016',
        '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
        '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
        '\Microsoft\Windows\Application Experience\StartupAppTask',
        '\Microsoft\Windows\Autochk\Proxy',
        '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
        '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip') }
    $detectors['chkSearchIndexOptimize'] = { Check-Reg @(
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; N = 'AllowIndexingEncryptedStoresOrItems'; V = 0 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; N = 'PreventIndexingOutlook'; V = 1 }) }
    $detectors['chkResidualServices'] = { Check-Services @('PcaSvc', 'WerSvc', 'wisvc', 'RetailDemo', 'Fax', 'RemoteRegistry', 'MapsBroker', 'lfsvc', 'WMPNetworkSvc', 'PhoneSvc', 'CDPSvc', 'SEMgrSvc') @('Manual', 'Disabled') }
    $detectors['chkAutoStandbyClean'] = {
        $t = Get-ScheduledTask -TaskName 'WGO_StandbyClean' -ErrorAction Ignore
        if ($t -and [string]$t.State -ne 'Disabled') { return (New-Status 'Applied') }
        return (New-Status 'Pending')
    }

    $detectors['chkTempCleanup'] = {
        $mb = (Get-FolderSizeMB $env:TEMP) + (Get-FolderSizeMB "$env:WINDIR\Temp")
        $old = Test-Path -LiteralPath "$env:SystemDrive\Windows.old"
        if ($mb -lt 100 -and -not $old) { return (New-Status 'Applied' '' "$mb MB") }
        return (New-Status 'Pending' '' ("{0} MB{1}" -f $mb, $(if ($old) { ' + Windows.old' } else { '' })))
    }
    $detectors['chkDeleteMinidump'] = {
        $d = "$env:SystemRoot\Minidump"
        $n = if (Test-Path -LiteralPath $d) { @(Get-ChildItem -LiteralPath $d -File -ErrorAction Ignore).Count } else { 0 }
        if ($n -eq 0) { return (New-Status 'Applied') }
        return (New-Status 'Pending' '' "$n files")
    }
    $detectors['chkGhostAdapters'] = {
        $n = @(Get-PnpDevice -Class Net -ErrorAction Stop | Where-Object { $_.Status -eq 'Unknown' }).Count
        if ($n -eq 0) { return (New-Status 'Applied') }
        return (New-Status 'Pending' '' "$n")
    }

    $detectors['chkDisableNagle'] = {
        $paths = @(Get-ActiveIfacePaths)
        if ($paths.Count -eq 0) { return (New-Status 'Unknown') }
        $ok = 0
        foreach ($p in $paths) {
            if ((Test-Equal (Read-Reg $p 'TCPNoDelay') 1) -and (Test-Equal (Read-Reg $p 'TcpAckFrequency') 1)) { $ok++ }
        }
        if ($ok -eq $paths.Count) { return (New-Status 'Applied') }
        if ($ok -eq 0) { return (New-Status 'Pending') }
        return (New-Status 'Partial' '' "$ok/$($paths.Count)")
    }
    $detectors['chkDisableIPv6'] = { Check-Reg @(@{ P = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'; N = 'DisabledComponents'; V = 255 }) }
    $detectors['chkRssOptimize'] = {
        $rss = 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndis\Parameters\Rss'
        $max = Read-Reg $rss 'RssMaxProcessors'
        if ($null -ne $max -and [int]$max -ge 2 -and (Test-Equal (Read-Reg $rss 'RssBaseProcessor') 0)) { return (New-Status 'Applied') }
        return (New-Status 'Pending')
    }
    $detectors['chkTcpAutotuning'] = {
        $s = Get-NetTCPSetting -SettingName Internet -ErrorAction Stop
        if ([string]$s.AutoTuningLevelLocal -eq 'Disabled') { return (New-Status 'Applied') }
        return (New-Status 'Pending' '' ([string]$s.AutoTuningLevelLocal))
    }
    $detectors['chkNtfsOptimize'] = {
        $v = Read-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate'
        if ($null -eq $v) { return (New-Status 'Pending') }
        $n = ([int64]$v) -band 0xFFFFFFFFL
        if ($n -eq 1 -or $n -eq 0x80000001L) { return (New-Status 'Applied') }
        return (New-Status 'Pending')
    }
    $detectors['chkDisableLLMNR'] = { Check-Reg @(@{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'; N = 'EnableMulticast'; V = 0 }) }
    $detectors['chkMenuDelay'] = { Check-Reg @(@{ P = 'HKCU:\Control Panel\Desktop'; N = 'MenuShowDelay'; V = '0' }) }
    $detectors['chkDnsCacheSize'] = { Check-Reg @(@{ P = 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters'; N = 'MaxCacheTtl'; V = 86400 }) }
    $detectors['chkIndexerThrottle'] = { Check-Reg @(
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; N = 'PreventIndexingOnBattery'; V = 1 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; N = 'DisableRemovableDriveIndexing'; V = 1 }) }
    $detectors['chkKeyboardFast'] = { Check-Reg @(@{ P = 'HKCU:\Control Panel\Keyboard'; N = 'KeyboardDelay'; V = '0' }) }
    $detectors['chkSteamBoost'] = {
        $reg = Check-Reg @(@{ P = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\steam.exe\PerfOptions'; N = 'CpuPriorityClass'; V = 3 })
        if ($reg.State -ne 'Applied') { return (New-Status 'Pending') }
        $tcp = Get-NetTCPSetting -SettingName Internet -ErrorAction Stop
        if ([string]$tcp.AutoTuningLevelLocal -eq 'Normal') { return (New-Status 'Applied') }
        return (New-Status 'Partial' '' ([string]$tcp.AutoTuningLevelLocal))
    }
    $detectors['chkDoH'] = { Check-Reg @(
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'; N = 'DoHPolicy'; V = 2 },
        @{ P = 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\DohWellKnownServers'; N = '1.1.1.1'; V = 'https://cloudflare-dns.com/dns-query' }) }
    $detectors['chkHostsBlock'] = {
        $hosts = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
        if ((Get-Content -LiteralPath $hosts -Raw -ErrorAction Stop) -match [regex]::Escape('# WGO-telemetry-block')) { return (New-Status 'Applied') }
        return (New-Status 'Pending')
    }

    $detectors['chkPrivacyDeep'] = { Check-Reg @(
        @{ P = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedExperience'; N = 'Disabled'; V = 1 },
        @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; N = 'AllowCortana'; V = 0 }) }
    $detectors['chkUiCleanup'] = { Check-Reg @(
        @{ P = $advKey; N = 'PeopleBand'; V = 0 },
        @{ P = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds'; N = 'ShellFeedsTaskbarViewMode'; V = 2 },
        @{ P = 'HKCU:\Software\Microsoft\TabletTip\1.7'; N = 'EnableInkingButton'; V = 0 }) }
    $detectors['chkRemoveOnedrive'] = {
        $exe = @("$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe", "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe", "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe")
        foreach ($e in $exe) { if ($e -and (Test-Path -LiteralPath $e)) { return (New-Status 'Pending') } }
        return (New-Status 'Applied')
    }
    $detectors['chkDisableGameBar'] = { Check-Reg @(
        @{ P = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar'; N = 'Enabled'; V = 0 },
        @{ P = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar'; N = 'ShowStartupPanel'; V = 0 }) }
    $detectors['chkDisableStore'] = { Check-Reg @(@{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore'; N = 'RemoveWindowsStore'; V = 1 }) }
    $detectors['chkDisableWer'] = {
        $reg = Check-Reg @(@{ P = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting'; N = 'Disabled'; V = 1 })
        $svc = Check-Services @('WerSvc') @('Disabled')
        if ($reg.State -eq 'Applied' -and $svc.State -in @('Applied', 'NotApplicable')) { return (New-Status 'Applied') }
        if ($reg.State -eq 'Pending' -and $svc.State -ne 'Applied') { return (New-Status 'Pending') }
        return (New-Status 'Partial')
    }
    $detectors['chkPauseUpdates'] = {
        $ux = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
        $exp = Read-Reg $ux 'PauseUpdatesExpiryTime'
        if (-not $exp) { return (New-Status 'Pending') }
        $when = [datetime]::MinValue
        if ([datetime]::TryParse([string]$exp, [ref]$when) -and $when.ToUniversalTime() -gt (Get-Date).ToUniversalTime()) {
            return (New-Status 'Applied' '' $when.ToString('yyyy-MM-dd'))
        }
        return (New-Status 'Pending' 'PauseExpired')
    }
    $detectors['chkDisableEdgeTelemetry'] = { Check-Reg @(
        @{ P = $edgePolicy; N = 'ConfigureTelemetryForDesktop'; V = 0 }, @{ P = $edgePolicy; N = 'MetricsReportingEnabled'; V = 0 }) }
    $detectors['chkDisableSpotlight'] = { Check-Reg @(
        @{ P = $cdm; N = 'SubscribedContent-338388Enabled'; V = 0 }, @{ P = $cdm; N = 'RotatingLockScreenEnabled'; V = 0 }) }

    $detectors['chkIncreaseTdrNvidia'] = {
        if (-not $hw.HasNvidia) { return (New-Status 'NotApplicable' 'NoNvidia') }
        Check-Reg @(@{ P = $gfx; N = 'TdrDelay'; V = 10 }, @{ P = $gfx; N = 'TdrDdiDelay'; V = 10 })
    }
    $detectors['chkDisableNvidiaTelemetry'] = {
        if (-not $hw.HasNvidia) { return (New-Status 'NotApplicable' 'NoNvidia') }
        $svc = Check-Services @('NvTelemetryContainer', 'NvContainerLocalSystem') @('Disabled')
        $tasksOk = $true
        foreach ($t in @(Get-ScheduledTask -ErrorAction Ignore | Where-Object { $_.TaskName -match 'NvTmMon|NvTmRep|NvProfileUpdaterDaily|NvProfileUpdaterOnLogon|NvDriverUpdateCheckDaily' })) {
            if ([string]$t.State -ne 'Disabled') { $tasksOk = $false }
        }
        if ($svc.State -in @('Applied', 'NotApplicable') -and $tasksOk) { return (New-Status 'Applied') }
        if ($svc.State -eq 'Pending' -and -not $tasksOk) { return (New-Status 'Pending') }
        return (New-Status 'Partial')
    }

    $amdGate = { if (-not $hw.HasAmd) { return (New-Status 'NotApplicable' 'NoAmd') } ; return $null }
    $detectors['chkAmdUlps'] = {
        $g = & $amdGate; if ($g) { return $g }
        $entries = @(Get-WgoAmdUlpsEntries)
        if ($entries.Count -eq 0) { return (New-Status 'NotApplicable' 'NoEntries') }
        $off = @($entries | Where-Object { [int]$_.EnableUlps -eq 0 }).Count
        if ($off -eq $entries.Count) { return (New-Status 'Applied') }
        if ($off -eq 0) { return (New-Status 'Pending') }
        return (New-Status 'Partial' '' "$off/$($entries.Count)")
    }
    $detectors['chkAmdMpo'] = {
        $g = & $amdGate; if ($g) { return $g }
        if ($null -eq (Read-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode')) { return (New-Status 'Applied') }
        return (New-Status 'Pending')
    }
    $detectors['chkAmdTdr'] = {
        $g = & $amdGate; if ($g) { return $g }
        Check-Reg @(@{ P = $gfx; N = 'TdrDelay'; V = 10 }, @{ P = $gfx; N = 'TdrDdiDelay'; V = 10 })
    }
    $detectors['chkAmdCrashDefender'] = {
        $g = & $amdGate; if ($g) { return $g }
        $svc = Get-WgoAmdCrashDefenderService
        if (-not $svc) { return (New-Status 'NotApplicable' 'NoService') }
        $s = Get-Service -Name $svc.Name -ErrorAction Stop
        if ([string]$s.StartType -eq 'Disabled') { return (New-Status 'Applied') }
        return (New-Status 'Pending')
    }
    $detectors['chkAmdHdcp'] = {
        $g = & $amdGate; if ($g) { return $g }
        $keys = @(Get-WgoAmdDriverSubkeys)
        if ($keys.Count -eq 0) { return (New-Status 'NotApplicable' 'NoEntries') }
        $on = 0
        foreach ($k in $keys) { if (Test-Equal (Read-Reg $k.PSPath 'DAL2_DisableHDCP') 1) { $on++ } }
        if ($on -eq $keys.Count) { return (New-Status 'Applied') }
        if ($on -eq 0) { return (New-Status 'Pending') }
        return (New-Status 'Partial' '' "$on/$($keys.Count)")
    }
    $detectors['chkAmdTelemetry'] = {
        $g = & $amdGate; if ($g) { return $g }
        $svcs = @(Get-WgoAmdTelemetryServices)
        if ($svcs.Count -eq 0) { return (New-Status 'NotApplicable' 'NoService') }
        Check-Services @($svcs | ForEach-Object { $_.Name }) @('Disabled')
    }
    $detectors['chkAmdHwAccel'] = {
        $g = & $amdGate; if ($g) { return $g }
        Check-Reg @(
            @{ P = $gfx; N = 'HwSchMode'; V = 1 },
            @{ P = 'HKLM:\SOFTWARE\Policies\Google\Chrome'; N = 'UseAngle'; V = 'opengl' },
            @{ P = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; N = 'UseAngle'; V = 'opengl' })
    }

    foreach ($name in @($detectors.Keys)) {
        try {
            $r = & $detectors[$name]
            if ($r -is [System.Array]) { $r = $r | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1 }
            if ($r -isnot [hashtable]) { $r = New-Status 'Unknown' 'ProbeFailed' 'no result' }
            $result[$name] = $r
        } catch {
            $result[$name] = New-Status 'Unknown' 'ProbeFailed' ([string]$_.Exception.Message)
        }
    }

    if (-not $hw.HasNvidia) { $result['chkRiskyNvidiaMaxPerf'] = (New-Status 'NotApplicable' 'NoNvidia') }

    return $result
}

function Invoke-WgoPreflightChecks {
    param($Hardware = $null)
    $checks = New-Object System.Collections.ArrayList
    function Add-Check([string]$Id, [string]$Status, [string]$Detail = '') {
        [void]$checks.Add([pscustomobject]@{ Id = $Id; Status = $Status; Detail = $Detail })
    }

    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $admin = (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        Add-Check 'Admin' $(if ($admin) { 'OK' } else { 'FAIL' })
    } catch { Add-Check 'Admin' 'WARN' $_.Exception.Message; $id = $null }

    Add-Check 'LanguageMode' $(if ($ExecutionContext.SessionState.LanguageMode -eq 'FullLanguage') { 'OK' } else { 'FAIL' }) ([string]$ExecutionContext.SessionState.LanguageMode)

    try { [void](Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop); Add-Check 'Cim' 'OK' }
    catch { Add-Check 'Cim' 'FAIL' $_.Exception.Message }

    try {
        $console = [string](Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName
        if ($id -and $console -and ($console -ne $id.Name)) { Add-Check 'UserMismatch' 'WARN' "$($id.Name) / $console" }
        else { Add-Check 'UserMismatch' 'OK' }
    } catch { Add-Check 'UserMismatch' 'OK' }

    try {
        $polOff = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' -Name DisableSR -ErrorAction Ignore).DisableSR
        $vss = Get-Service -Name 'VSS' -ErrorAction Ignore
        if ($polOff -eq 1 -or ($vss -and [string]$vss.StartType -eq 'Disabled')) {
            Add-Check 'Restore' 'FAIL'
        } else {
            $freq = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -Name SystemRestorePointCreationFrequency -ErrorAction Ignore).SystemRestorePointCreationFrequency
            $recent = $false
            if ($null -eq $freq -or [int]$freq -ne 0) {
                $last = Get-ComputerRestorePoint -ErrorAction Ignore | Sort-Object SequenceNumber | Select-Object -Last 1
                if ($last) {
                    $created = [System.Management.ManagementDateTimeConverter]::ToDateTime($last.CreationTime)
                    if (((Get-Date) - $created).TotalMinutes -lt 1440) { $recent = $true }
                }
            }
            Add-Check 'Restore' $(if ($recent) { 'WARN' } else { 'OK' })
        }
    } catch { Add-Check 'Restore' 'WARN' $_.Exception.Message }

    try { $g = Get-WgoActiveSchemeGuid; Add-Check 'Powercfg' $(if ($g) { 'OK' } else { 'WARN' }) }
    catch { Add-Check 'Powercfg' 'WARN' $_.Exception.Message }
    try { $null = & bcdedit.exe /enum '{current}' 2>$null; Add-Check 'Bcdedit' $(if ($LASTEXITCODE -eq 0) { 'OK' } else { 'WARN' }) }
    catch { Add-Check 'Bcdedit' 'WARN' $_.Exception.Message }
    try { [void](Get-NetTCPSetting -SettingName Internet -ErrorAction Stop); Add-Check 'NetTcp' 'OK' }
    catch { Add-Check 'NetTcp' 'WARN' $_.Exception.Message }
    try { [void](Get-ScheduledTask -TaskName 'ScheduledDefrag' -ErrorAction Stop); Add-Check 'Tasks' 'OK' }
    catch { Add-Check 'Tasks' 'WARN' $_.Exception.Message }
    try { [void](Get-AppxPackage -Name 'Microsoft.WindowsStore' -ErrorAction Stop); Add-Check 'Appx' 'OK' }
    catch { Add-Check 'Appx' 'WARN' $_.Exception.Message }
    try { Add-Check 'Winget' $(if (Find-WgoWinget) { 'OK' } else { 'WARN' }) }
    catch { Add-Check 'Winget' 'WARN' $_.Exception.Message }

    $pending = $false
    foreach ($k in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
                     'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')) {
        if (Test-Path -LiteralPath $k) { $pending = $true }
    }
    Add-Check 'PendingReboot' $(if ($pending) { 'WARN' } else { 'OK' })
    try {
        $drv = ($env:SystemDrive).TrimEnd('\')
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$drv'" -ErrorAction Stop
        $freeGb = [math]::Round($disk.FreeSpace / 1GB, 1)
        Add-Check 'DiskSpace' $(if ($freeGb -lt 5) { 'WARN' } else { 'OK' }) "$freeGb GB"
    } catch { Add-Check 'DiskSpace' 'OK' }
    if ($Hardware -and $Hardware.IsVirtualMachine) { Add-Check 'VirtualMachine' 'WARN' $Hardware.Model }
    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        if ($mp.IsTamperProtected) { Add-Check 'TamperProtection' 'WARN' }
    } catch { }

    return @($checks)
}

Export-ModuleMember -Function @(
    'Get-WgoGpuInventory', 'Test-WgoGpuVendorPresent', 'Get-WgoHardwareProfile',
    'Get-WgoOptimizationStatus', 'Invoke-WgoPreflightChecks'
)
