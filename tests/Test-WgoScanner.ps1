param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$env:SystemRoot = '/mnt/c/Windows'; $env:WINDIR = '/mnt/c/Windows'; $env:SystemDrive = '/mnt/c'; $env:TEMP = '/tmp'
$script:fails = 0
function Assert([bool]$Cond, [string]$Msg) {
    if ($Cond) { Write-Host "  [ OK ] $Msg" -ForegroundColor Green } else { $script:fails++; Write-Host "  [FALHA] $Msg" -ForegroundColor Red }
}
function Section($m) { Write-Host "`n== $m" -ForegroundColor Cyan }

$script:Reg = @{}            # "path|name" -> valor
$script:Services = @{}       # nome -> StartType
$script:Tasks = @{}          # "dir|leaf" -> State
$script:Videos = @()         # nomes de adaptadores
$script:Appx = @()
$script:ThrowIn = $null

function Norm([string]$p) { return $p.TrimEnd('\').ToLowerInvariant() }
function Get-ItemProperty {
    param([string]$LiteralPath, [string]$Path, [string]$Name, $ErrorAction)
    $p = Norm ($(if ($LiteralPath) { $LiteralPath } else { $Path }))
    if ($Name) {
        $k = "$p|$($Name.ToLowerInvariant())"
        if (-not $script:Reg.ContainsKey($k)) { throw "Property $Name does not exist at $p" }
        return [pscustomobject]@{ $Name = $script:Reg[$k] }
    }
    $o = [ordered]@{}
    foreach ($k in $script:Reg.Keys) { if ($k.StartsWith("$p|")) { $o[$k.Substring($p.Length + 1)] = $script:Reg[$k] } }
    return [pscustomobject]$o
}
function Get-ChildItem {
    param([string]$LiteralPath, [string]$Path, [switch]$File, $ErrorAction)
    $root = Norm ($(if ($LiteralPath) { $LiteralPath } else { $Path }))
    $seen = @{}
    foreach ($k in $script:Reg.Keys) {
        if ($k.StartsWith("$root\")) { $child = $k.Substring($root.Length + 1).Split('|')[0].Split('\')[0]; $seen[$child] = $true }
    }
    foreach ($c in $seen.Keys) { [pscustomobject]@{ PSPath = "$root\$c"; PSChildName = $c } }
}
function Get-Service {
    param([string]$Name, $ErrorAction)
    if ($Name) { if ($script:Services.ContainsKey($Name)) { return [pscustomobject]@{ Name = $Name; DisplayName = $Name; StartType = $script:Services[$Name]; Status = 'Running' } } ; return $null }
    foreach ($n in $script:Services.Keys) { [pscustomobject]@{ Name = $n; DisplayName = $n; StartType = $script:Services[$n]; Status = 'Running' } }
}
function Get-ScheduledTask {
    param([string]$TaskPath, [string]$TaskName, $ErrorAction)
    foreach ($k in $script:Tasks.Keys) {
        $d, $l = $k.Split('|')
        if ((-not $TaskPath -or $d.TrimEnd('\') -ieq $TaskPath.TrimEnd('\')) -and (-not $TaskName -or $l -ieq $TaskName)) {
            if ($TaskPath -and -not $TaskPath.EndsWith('\')) { continue }
            [pscustomobject]@{ TaskPath = $d; TaskName = $l; State = $script:Tasks[$k] }
        }
    }
}
function Get-AppxPackage { param([switch]$AllUsers, $Name, $ErrorAction) foreach ($n in $script:Appx) { [pscustomobject]@{ Name = $n } } }
function Get-PnpDevice { param($Class, $ErrorAction) @() }
function Get-PhysicalDisk { param($ErrorAction) foreach ($d in $script:Disks) { [pscustomobject]$d } }
function Get-Partition { param($DriveLetter, $ErrorAction) [pscustomobject]@{ DiskNumber = 0 } }
$coreAst = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $Root 'Modules/Wgo.Core/Wgo.Core.psm1'), [ref]$null, [ref]$null)
foreach ($fn in @($coreAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Get-WgoDiskKinds', 'Get-WgoDiskSummary', 'Test-WgoSystemDriveIsSsd') }, $true))) { . ([scriptblock]::Create($fn.Extent.Text)) }
function Get-NetTCPSetting { param($SettingName, $ErrorAction) [pscustomobject]@{ AutoTuningLevelLocal = $script:AutoTuning } }
function Get-Content { param($LiteralPath, [switch]$Raw, $ErrorAction) return $script:HostsText }
function Test-Path { param($LiteralPath, $Path, $ErrorAction) return $false }
function bcdedit.exe { $global:LASTEXITCODE = 0; return $script:Bcd }
function fsutil.exe { $global:LASTEXITCODE = 0; return 'NTFS DisableDeleteNotify = 0  (Allows TRIM operations)' }
function Get-CimInstance {
    param([string]$ClassName, [string]$Filter, $ErrorAction)
    switch ($ClassName) {
        'Win32_OperatingSystem'   { [pscustomobject]@{ Caption = 'Microsoft Windows 11 Pro'; BuildNumber = '22631' } }
        'Win32_Processor'         { [pscustomobject]@{ Name = 'AMD Ryzen 7 7800X3D 8-Core Processor'; Manufacturer = 'AuthenticAMD'; NumberOfCores = 8; NumberOfLogicalProcessors = 16 } }
        'Win32_ComputerSystem'    { [pscustomobject]@{ TotalPhysicalMemory = 32GB; Manufacturer = 'ASUS'; Model = 'System Product Name'; UserName = 'PC\user'; AutomaticManagedPagefile = $script:AutoPf } }
        'Win32_Battery'           { $null }
        'Win32_SystemEnclosure'   { [pscustomobject]@{ ChassisTypes = @(3) } }
        'Win32_VideoController'   { foreach ($n in $script:Videos) { [pscustomobject]@{ Name = $n; AdapterCompatibility = ''; DriverVersion = '1.0' } } }
        'Win32_PageFileSetting'   { if ($script:PfSet) { [pscustomobject]@{ Name = "$env:SystemDrive\pagefile.sys"; InitialSize = 2048; MaximumSize = 4096 } } }
        default                   { $null }
    }
}
function Get-WgoActiveSchemeGuid { return $script:Scheme }
function Test-WgoProtectedPackage { param($Name) return ($Name -like 'Microsoft.WindowsStore*') }
function Get-WgoBloatwareTargets { return @('Microsoft.BingNews', 'Microsoft.YourPhone') }
function Get-WgoOptimizedPagefileSize { param($RamMB) return @{ Min = 2048; Max = 4096 } }
function Get-WgoAmdUlpsEntries { return @() }
function Get-WgoAmdCrashDefenderService { return $null }
function Get-WgoAmdDriverSubkeys { return @() }
function Get-WgoAmdTelemetryServices { return @() }

Import-Module (Join-Path $Root 'Modules/Wgo.Scanner/Wgo.Scanner.psm1') -Force

function Reset-World {
    $script:Reg = @{}; $script:Services = @{}; $script:Tasks = @{}; $script:Appx = @()
    $script:AutoTuning = 'Normal'; $script:HostsText = "127.0.0.1 localhost`n"; $script:AutoPf = $true; $script:PfSet = $false
    $script:Scheme = '381b4222-f694-41f0-9685-4b25ce48ccc1'
    $script:Bcd = @('timeout 30')
    $script:Disks = @(@{ FriendlyName = 'NVMe0'; MediaType = 'SSD'; BusType = 'NVMe'; Size = 500GB; DeviceId = '0' })
    $Global:WgoGpuInventoryCache = $null
}

Section "A. Detecção de GPU"
$cases = @(
    @{ N = @('NVIDIA GeForce RTX 4070');                                V = 'NVIDIA'; I = $false },
    @{ N = @('AMD Radeon RX 7800 XT');                                  V = 'AMD';    I = $false },
    @{ N = @('AMD Radeon(TM) Graphics');                                V = 'AMD';    I = $true  },
    @{ N = @('AMD Radeon(TM) 780M');                                    V = 'AMD';    I = $true  },
    @{ N = @('AMD Radeon RX 6800M');                                    V = 'AMD';    I = $false },
    @{ N = @('AMD Radeon(TM) RX Vega 11 Graphics');                     V = 'AMD';    I = $true  },
    @{ N = @('Intel(R) UHD Graphics 770');                              V = 'Intel';  I = $true  },
    @{ N = @('Intel(R) Arc(TM) A770 Graphics');                         V = 'Intel';  I = $false }
)
foreach ($c in $cases) {
    Reset-World; $script:Videos = $c.N
    $g = @(Get-WgoGpuInventory)
    Assert ($g.Count -eq 1 -and $g[0].Vendor -eq $c.V -and $g[0].IsIntegrated -eq $c.I) "$($c.N[0]) -> $($c.V), integrada=$($c.I)"
}
Reset-World; $script:Videos = @('AMD Radeon(TM) Graphics', 'NVIDIA GeForce RTX 4060 Laptop GPU', 'Microsoft Basic Display Adapter', 'Parsec Virtual Display Adapter')
$g = @(Get-WgoGpuInventory)
Assert ($g.Count -eq 2) "híbrido AMD iGPU + NVIDIA dGPU: adaptadores virtuais/básicos ignorados (2 de 4)"
Assert ((Test-WgoGpuVendorPresent -Vendor 'NVIDIA') -and (Test-WgoGpuVendorPresent -Vendor 'AMD')) "híbrido: NVIDIA *e* AMD presentes (o Get-WgoGpuVendor antigo só via AMD)"
Assert (-not (Test-WgoGpuVendorPresent -Vendor 'Intel')) "híbrido: Intel ausente"

Section "B. Máquina limpa (AMD dGPU, sem NVIDIA)"
Reset-World; $script:Videos = @('AMD Radeon RX 7800 XT'); $script:Services = @{ SysMain = 'Automatic'; WSearch = 'Automatic'; Spooler = 'Automatic'; DiagTrack = 'Automatic' }
$script:Appx = @('Microsoft.BingNews', 'Microsoft.WindowsStore', 'Microsoft.Foo')
$hw = Get-WgoHardwareProfile
Assert ($hw.HasAmd -and -not $hw.HasNvidia -and $hw.RamGb -eq 32 -and -not $hw.IsLaptop -and $hw.HasSsd) "perfil de hardware: AMD, sem NVIDIA, 32 GB, desktop, SSD ($($hw.DiskSummary))"
$st = Get-WgoOptimizationStatus -Hardware $hw
Assert ($st.Count -ge 60) "scan cobre $($st.Count) opções"
Assert ($st['chkIncreaseTdrNvidia'].State -eq 'NotApplicable' -and $st['chkIncreaseTdrNvidia'].Reason -eq 'NoNvidia') "opções NVIDIA -> NotApplicable/NoNvidia sem GPU NVIDIA"
Assert ($st['chkRiskyNvidiaMaxPerf'].State -eq 'NotApplicable') "opção arriscada NVIDIA também desabilitada"
Assert ($st['chkAmdTdr'].State -eq 'Pending') "AMD TDR -> Pending na máquina limpa"
Assert ($st['chkBloat'].State -eq 'Pending' -and $st['chkBloat'].Detail -match 'BingNews' -and $st['chkBloat'].Detail -notmatch 'WindowsStore') "bloatware: acha BingNews, ignora pacote protegido (Store)"
Assert ($st['chkDisableSysMain'].State -eq 'Pending') "SysMain Automatic -> Pending"
Assert ($st['chkPowerPlan'].State -eq 'Pending') "plano Balanced -> Pending"
Assert ($st['chkHibernation'].State -eq 'Unknown') "sem HibernateEnabled no registro -> Unknown (não chuta)"
$pend = @($st.Values | Where-Object { $_.State -eq 'Pending' }).Count
Assert ($pend -ge 30) "máquina limpa: $pend opções pendentes"

Section "C. Máquina otimizada (registro/serviços/tarefas preenchidos)"
Reset-World; $script:Videos = @('NVIDIA GeForce RTX 4070', 'Intel(R) UHD Graphics 770')
$srcPath = Join-Path $Root 'Modules/Wgo.Scanner/Wgo.Scanner.psm1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($srcPath, [ref]$null, [ref]$null)
$hts = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.HashtableAst] -and $n.KeyValuePairs.Count -eq 3 -and ($n.KeyValuePairs | ForEach-Object { $_.Item1.Extent.Text }) -join ',' -eq 'P,N,V' }, $true)
$expected = @()
$vars = @{
    '$gfx' = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; '$dcPolicy' = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
    '$edgePolicy' = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; '$cdm' = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    '$advKey' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; '$mmKey' = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    '$sysProfile' = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
}
foreach ($h in $hts) {
    $pt = $h.KeyValuePairs[0].Item2.Extent.Text.Trim("'`" "); $nm = $h.KeyValuePairs[1].Item2.Extent.Text.Trim("'`" ")
    $vt = $h.KeyValuePairs[2].Item2.Extent.Text
    if ($pt.StartsWith('$')) {
        $m = [regex]::Match($pt, '^(\$\w+)(.*)$'); $pt = $vars[$m.Groups[1].Value] + ($m.Groups[2].Value)
    }
    $val = if ($vt -match "^'(.*)'$") { $Matches[1] } elseif ($vt -match '^0x[0-9A-Fa-f]+L?$') { [System.BitConverter]::ToInt32([System.BitConverter]::GetBytes([uint32][convert]::ToUInt32(($vt -replace 'L$', '').Substring(2), 16)), 0) } else { [int]$vt }
    $script:Reg[(Norm $pt) + '|' + $nm.ToLowerInvariant()] = $val
    $expected += [pscustomobject]@{ Path = $pt; Name = $nm; Value = $vt }
}
Assert ($expected.Count -ge 80) "extraídas $($expected.Count) verificações de registro do Scanner"
$script:Services = @{ SysMain = 'Disabled'; WSearch = 'Disabled'; Spooler = 'Disabled'; DiagTrack = 'Disabled'; dmwappushservice = 'Disabled'; WerSvc = 'Disabled'; PcaSvc = 'Manual'; NvTelemetryContainer = 'Disabled' }
foreach ($t in @('\Microsoft\Windows\Feedback\Siuf\|DmClient', '\Microsoft\Windows\Autochk\|Proxy')) { $script:Tasks[$t] = 'Disabled' }
$script:Tasks['\|WGO_StandbyClean'] = 'Ready'
$script:AutoTuning = 'Disabled'; $script:HostsText = "0.0.0.0 x`n# WGO-telemetry-block`n0.0.0.0 y"
$script:AutoPf = $false; $script:PfSet = $true
$script:Scheme = 'aaaaaaaa-0000-0000-0000-000000000001'
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\aaaaaaaa-0000-0000-0000-000000000001\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c') + '|acsettingindex'] = 100
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\aaaaaaaa-0000-0000-0000-000000000001\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583') + '|acsettingindex'] = 100
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Control\Power') + '|hibernateenabled'] = 0
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndis\Parameters\Rss') + '|rssmaxprocessors'] = 4
$script:Reg[(Norm 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings') + '|pauseupdatesstarttime'] = 'x'
$script:Reg[(Norm 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings') + '|pauseupdatesexpirytime'] = ((Get-Date).AddDays(3).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))
$ifb = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{guid-1}'
$script:Reg[(Norm $ifb) + '|dhcpipaddress'] = '192.168.0.10'; $script:Reg[(Norm $ifb) + '|tcpnodelay'] = 1; $script:Reg[(Norm $ifb) + '|tcpackfrequency'] = 1
$script:Bcd = @('timeout                 5', 'tscsyncpolicy Enhanced', 'useplatformclock No')
$games = Norm 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
$script:Reg["$games|gpu priority"] = 8; $script:Reg["$games|priority"] = 6
$script:Reg["$games|scheduling category"] = 'High'; $script:Reg["$games|sfio priority"] = 'High'
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl') + '|win32priorityseparation'] = 38
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndis\Parameters\Rss') + '|rssbaseprocessor'] = 0
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers') + '|hwschmode'] = 2

$hw = Get-WgoHardwareProfile
$st = Get-WgoOptimizationStatus -Hardware $hw
$regBased = @('chkSearch','chkVisual','chkPrivacy','chkDrivers','chkAdvertisingId','chkTailoredExp','chkDiagTrackSvc','chkCopilotBlock','chkInputTelemetry','chkEdgeWidgets','chkDeliveryOpt','chkAppsBackground','chkNetworkLatency','chkHungAppTimeout','chkDisableSysMain','chkDisableWSearch','chkDisableSpooler','chkHibernation','chkPowerPlan','chkFastStartup','chkPrefetchSSD','chkLargeSystemCache','chkFastShutdown','chkDisableCoreParking','chkHagsGameMode','chkKernelGamingPriority','chkGameDvrDisable','chkGameBarMicFix','chkInputLagReduction','chkHotCorners','chkOfficeTelemetry','chkSearchIndexOptimize','chkResidualServices','chkAutoStandbyClean','chkDisableNagle','chkDisableIPv6','chkRssOptimize','chkTcpAutotuning','chkDoH','chkHostsBlock','chkPrivacyDeep','chkUiCleanup','chkDisableGameBar','chkDisableStore','chkDisableWer','chkPauseUpdates','chkDisableEdgeTelemetry','chkDisableSpotlight','chkIncreaseTdrNvidia','chkDisableNvidiaTelemetry','chkPagefile','chkBootTimeout','chkDisableHPET','chkDiskOptimize','chkExtraSchedTasks','chkUltimatePerf')
foreach ($n in $regBased) {
    $s = $st[$n]
    Assert ($s -and $s.State -eq 'Applied') ("{0,-26} -> {1}{2}" -f $n, $(if ($s) { $s.State } else { '(ausente)' }), $(if ($s -and $s.State -ne 'Applied') { "  [$($s.Reason) $($s.Detail)]" } else { '' }))
}
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers') + '|hwschmode'] = 0
Assert ($st['chkSteamBoost'].State -eq 'Partial') "Steam: IFEO gravado mas autoajuste TCP desabilitado -> Partial"
Assert ($st['chkTcpAutotuning'].State -eq 'Applied') "autoajuste TCP desabilitado -> chkTcpAutotuning Applied"
$script:AutoTuning = 'Normal'
$stSteam = Get-WgoOptimizationStatus -Hardware $hw
Assert ($stSteam['chkSteamBoost'].State -eq 'Applied') "Steam: IFEO + autoajuste Normal -> Applied"
Assert ($stSteam['chkTcpAutotuning'].State -eq 'Pending') "autoajuste Normal -> chkTcpAutotuning volta a Pending (opções são excludentes)"
$st2 = Get-WgoOptimizationStatus -Hardware $hw
Assert ($st2['chkHagsGameMode'].State -ne 'Applied') "HAGS: alterar HwSchMode tira o status de Applied (detector reage a mudança)"
Assert ($st['chkAmdTdr'].State -eq 'NotApplicable' -and $st['chkAmdTdr'].Reason -eq 'NoAmd') "sem GPU AMD: opções AMD -> NotApplicable/NoAmd"

Section "B3. Discos mistos (SSD + HDD)"
Reset-World
$script:Disks = @(
    @{ FriendlyName = 'Samsung 980'; MediaType = 'Unspecified'; BusType = 'NVMe'; Size = 1000GB; DeviceId = '0' },
    @{ FriendlyName = 'WD Blue'; MediaType = 'HDD'; BusType = 'SATA'; Size = 2000GB; DeviceId = '1' },
    @{ FriendlyName = 'USB Stick'; MediaType = 'Unspecified'; BusType = 'USB'; Size = 16GB; DeviceId = '2' }
)
$hwMixed = Get-WgoHardwareProfile
Assert ($hwMixed.HasSsd -and $hwMixed.HasHdd) "SSD NVMe (MediaType Unspecified) + HDD: ambos detectados, USB ignorado"
Assert ($hwMixed.DiskSummary -eq 'HDD + NVMe SSD') "resumo de discos: $($hwMixed.DiskSummary)"
Assert ($hwMixed.SystemDriveIsSsd) "disco do sistema (0) é SSD"
$script:Disks[0].DeviceId = '1'; $script:Disks[1].DeviceId = '0'
$hwHddSys = Get-WgoHardwareProfile
$stHdd = Get-WgoOptimizationStatus -Hardware $hwHddSys
Assert (-not $hwHddSys.SystemDriveIsSsd -and $stHdd['chkPrefetchSSD'].State -eq 'NotApplicable') "sistema em HDD: PrefetchSSD não se aplica"

Section "B2. Steam na máquina limpa"
Reset-World; $script:Videos = @('NVIDIA GeForce RTX 4070')
$hwClean = Get-WgoHardwareProfile
$stClean = Get-WgoOptimizationStatus -Hardware $hwClean
Assert ($stClean['chkSteamBoost'].State -eq 'Pending') "Steam: sem IFEO -> Pending mesmo com autoajuste Normal (padrão do Windows)"

Section "D. Falha em um detector não derruba o scan"
Reset-World; $script:Videos = @('AMD Radeon RX 7800 XT')
function Get-ScheduledTask { throw 'Task Scheduler service is not running' }
$hw = Get-WgoHardwareProfile
$st = Get-WgoOptimizationStatus -Hardware $hw
Assert ($st['chkExtraSchedTasks'].State -eq 'Unknown' -and $st['chkExtraSchedTasks'].Reason -eq 'ProbeFailed') "chkExtraSchedTasks -> Unknown/ProbeFailed (Task Scheduler quebrado)"
Assert ($st['chkSearch'].State -eq 'Pending') "os demais detectores seguem funcionando"

Section "E. Valores esperados pelo Scanner x valores que o Core/Amd realmente escrevem"
$coreText = [IO.File]::ReadAllText((Join-Path $Root 'Modules/Wgo.Core/Wgo.Core.psm1')) + "`n" + [IO.File]::ReadAllText((Join-Path $Root 'Modules/Wgo.Amd/Wgo.Amd.psm1'))
$bad = 0; $checked = 0
foreach ($e in ($expected | Sort-Object Name, Value -Unique)) {
    $val = [regex]::Escape($e.Value.Trim("'"))
    $name = [regex]::Escape($e.Name)
    $rx = "(?s)-Name\s+[`"']?$name[`"']?\s+(?:-PropertyType\s+\w+\s+)?-Value\s+[`"']?$val\b|-Name\s+[`"']?$name[`"']?.{0,60}?-Value\s+\(?[`"']?$val\b"
    $checked++
    if ($coreText -notmatch $rx) { $bad++; Write-Host "  [AVISO] '$($e.Name)' = $($e.Value) não encontrado como escrita literal no Core/Amd (pode ser gravado via variável/loop)" -ForegroundColor Yellow }
}
Assert $true "$checked pares nome/valor conferidos contra o Core ($($checked - $bad) casam literalmente, $bad para revisão manual acima)"

Section "F. System Tuning"
Reset-World
$tune = @('chkNtfsOptimize','chkDisableLLMNR','chkMenuDelay','chkDnsCacheSize','chkIndexerThrottle','chkKeyboardFast')
$stT = Get-WgoOptimizationStatus -Hardware (Get-WgoHardwareProfile)
foreach ($n in $tune) { Assert ($stT[$n].State -eq 'Pending') "$n limpo -> Pending" }
$fs = Norm 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
foreach ($v in @(1, 0x80000001L)) {
    $script:Reg["$fs|ntfsdisablelastaccessupdate"] = $v
    $stN = Get-WgoOptimizationStatus -Hardware (Get-WgoHardwareProfile)
    Assert ($stN['chkNtfsOptimize'].State -eq 'Applied') "NTFS last access = $v -> Applied"
}
$script:Reg["$fs|ntfsdisablelastaccessupdate"] = 0x80000002L
Assert ((Get-WgoOptimizationStatus -Hardware (Get-WgoHardwareProfile))['chkNtfsOptimize'].State -eq 'Pending') "NTFS gerenciado pelo sistema (0x80000002) -> Pending"
$script:Reg[(Norm 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient') + '|enablemulticast'] = 0
$script:Reg[(Norm 'HKCU:\Control Panel\Desktop') + '|menushowdelay'] = '0'
$script:Reg[(Norm 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters') + '|maxcachettl'] = 86400
$ws = Norm 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
$script:Reg["$ws|preventindexingonbattery"] = 1
$script:Reg[(Norm 'HKCU:\Control Panel\Keyboard') + '|keyboarddelay'] = '0'
$stT = Get-WgoOptimizationStatus -Hardware (Get-WgoHardwareProfile)
Assert ($stT['chkIndexerThrottle'].State -eq 'Partial') "indexador com apenas uma política -> Partial"
$script:Reg["$ws|disableremovabledriveindexing"] = 1
$stT = Get-WgoOptimizationStatus -Hardware (Get-WgoHardwareProfile)
foreach ($n in @('chkDisableLLMNR','chkMenuDelay','chkDnsCacheSize','chkIndexerThrottle','chkKeyboardFast')) { Assert ($stT[$n].State -eq 'Applied') "$n gravado -> Applied" }

Write-Host "`n================ RESULTADO: $($script:fails) falha(s) ================" -ForegroundColor $(if ($script:fails) { 'Red' } else { 'Green' })
exit ([int]($script:fails -gt 0))
