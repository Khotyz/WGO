param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Stop'
$script:fail = 0; $script:warn = 0
function Fail($m) { $script:fail++; Write-Host "  [FALHA] $m" -ForegroundColor Red }
function Warn($m) { $script:warn++; Write-Host "  [AVISO] $m" -ForegroundColor Yellow }
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Section($m) { Write-Host "`n== $m" -ForegroundColor Cyan }

$files = Get-ChildItem -Path $Root -Recurse -Include *.ps1, *.psm1 | Where-Object { $_.FullName -notmatch '[\\/]tests[\\/]' -and $_.Name -ne 'Test-WgoStatic.ps1' }

Section "1. Sintaxe PowerShell ($($files.Count) arquivos)"
$asts = @{}
foreach ($f in $files) {
    $tokens = $null; $errs = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errs)
    if ($errs -and $errs.Count) { foreach ($e in $errs) { Fail "$($f.Name):$($e.Extent.StartLineNumber) $($e.Message)" } }
    else { $asts[$f.Name] = $ast }
}
if ($script:fail -eq 0) { Ok "todos os arquivos parseiam sem erro" }

Section "2. XAML"
$xamlPath = Join-Path $Root 'xaml\MainWindow.xaml'
$xamlNames = @()
try {
    [xml]$xaml = Get-Content $xamlPath -Raw
    $xamlNames = $xaml.SelectNodes('//*') | ForEach-Object { $_.GetAttribute('Name', 'http://schemas.microsoft.com/winfx/2006/xaml') } | Where-Object { $_ }
    Ok "XAML bem formado ($($xamlNames.Count) elementos nomeados)"
} catch { Fail "XAML inválido: $($_.Exception.Message)" }

Section "3. Idiomas"
$langs = @{}
foreach ($lf in Get-ChildItem (Join-Path $Root 'lang') -Filter *.json) {
    try {
        $j = Get-Content $lf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $langs[$lf.BaseName] = @($j.PSObject.Properties.Name)
    } catch { Fail "$($lf.Name) inválido: $($_.Exception.Message)" }
}
if ($langs.ContainsKey('en-US')) {
    foreach ($k in $langs.Keys) {
        if ($k -eq 'en-US') { continue }
        $missing = $langs['en-US'] | Where-Object { $langs[$k] -notcontains $_ }
        if ($missing) { Warn "$k sem $(@($missing).Count) chave(s) presentes em en-US (cai no fallback en-US): $((@($missing) | Select-Object -First 8) -join ', ')$(if (@($missing).Count -gt 8) {' ...'})" }
    }
    $allKeys = $langs['en-US']
    if ($script:warn -eq 0) { Ok "$($langs.Count) idiomas com o mesmo conjunto de chaves ($($allKeys.Count))" }
}

Section "4. Controles referenciados no código x XAML"
$uiAst = $asts['Wgo.UI.psm1']
if ($uiAst) {
    $used = [System.Collections.Generic.HashSet[string]]::new()
    $uiAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.IndexExpressionAst] }, $true) | ForEach-Object {
        if ($_.Index -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $_.Target.Extent.Text -match '^\$c$|WgoUI_Ctrl$') { [void]$used.Add($_.Index.Value) }
    }
    $missing = $used | Where-Object { $xamlNames -notcontains $_ } | Sort-Object
    if ($missing) { foreach ($m in $missing) { Fail "Controle '$m' usado no código mas ausente no XAML" } } else { Ok "todos os $($used.Count) controles usados existem no XAML" }
}

Section "5. Chaves de tradução usadas em T '...'"
$badKeys = @{}
foreach ($kv in $asts.GetEnumerator()) {
    $kv.Value.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'T' }, $true) | ForEach-Object {
        $arg = $_.CommandElements | Select-Object -Skip 1 -First 1
        if ($arg -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            if ($allKeys -and $allKeys -notcontains $arg.Value) { $badKeys["$($kv.Key): $($arg.Value)"] = $true }
        }
    }
}
if ($badKeys.Count) { foreach ($b in $badKeys.Keys | Sort-Object) { Fail "Chave inexistente em en-US -> $b" } } else { Ok "todas as chaves T literais existem" }

Section "6. Funções usadas em tarefas de background"
$defined = @{}
foreach ($kv in $asts.GetEnumerator()) {
    $kv.Value.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) | ForEach-Object {
        $nested = $false; $up = $_.Parent
        while ($up) { if ($up -is [System.Management.Automation.Language.FunctionDefinitionAst]) { $nested = $true; break }; $up = $up.Parent }
        if (-not $nested) { $defined[$_.Name] = $kv.Key }
    }
}
$entryText = Get-Content (Join-Path $Root 'WGO.ps1') -Raw
$sharedList = @()
if ($entryText -match '(?s)WgoSharedFunctionNames\s*=\s*@\((.*?)\n\)') { $sharedList = [regex]::Matches($Matches[1], "'([^']+)'") | ForEach-Object { $_.Groups[1].Value } }
foreach ($s in $sharedList) { if (-not $defined.ContainsKey($s)) { Fail "Lista compartilhada cita função inexistente: $s" } }

function Get-CalledFunctions($astNode) {
    $astNode.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) |
        ForEach-Object { $_.GetCommandName() } | Where-Object { $_ -and $defined.ContainsKey($_) } | Sort-Object -Unique
}
foreach ($kv in $asts.GetEnumerator()) {
    $kv.Value.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Start-WgoBackgroundTask' }, $true) | ForEach-Object {
        $cmd = $_
        $sb = $cmd.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.ScriptBlockExpressionAst] } | Select-Object -First 1
        if ($sb) {
            foreach ($fn in Get-CalledFunctions $sb.ScriptBlock) {
                if ($sharedList -notcontains $fn -and $fn -notin @('Start-WgoBackgroundTask')) { Fail "$($kv.Key):$($cmd.Extent.StartLineNumber) bloco em background chama '$fn' (definida em $($defined[$fn])) que NÃO está em WgoSharedFunctionNames" }
            }
        }
    }
}
foreach ($s in $sharedList) {
    if (-not $defined.ContainsKey($s)) { continue }
    $fnAst = $asts[$defined[$s]].FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $s }, $true) | Select-Object -First 1
    foreach ($callee in Get-CalledFunctions $fnAst.Body) {
        if ($callee -ne $s -and $sharedList -notcontains $callee) { Fail "Função compartilhada '$s' chama '$callee' (em $($defined[$callee])) que NÃO está na lista de runspace" }
    }
}
if ($script:fail -eq 0) { Ok "nenhuma dependência de runspace faltando" }

Section "7. Handler 'Run Selected': parâmetros x argumentos"
if ($uiAst) {
    $runCalls = $uiAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Start-WgoBackgroundTask' -and $n.Extent.Text.Contains('$doDryRun') }, $true)
    foreach ($rc in $runCalls) {
        $els = $rc.CommandElements
        $sb = $els | Where-Object { $_ -is [System.Management.Automation.Language.ScriptBlockExpressionAst] } | Select-Object -First 1
        $pNames = @($sb.ScriptBlock.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
        $idx = [array]::IndexOf($els, ($els | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'ArgumentList' } | Select-Object -First 1))
        $argArr = $els[$idx + 1]
        $argNames = @([regex]::Matches($argArr.Extent.Text, '\$do\w+') | ForEach-Object { $_.Value.TrimStart('$') })
        if ($pNames.Count -ne $argNames.Count) { Fail "Run: $($pNames.Count) parâmetros x $($argNames.Count) argumentos" }
        else {
            $mismatch = 0
            for ($i = 0; $i -lt $pNames.Count; $i++) { if ($pNames[$i] -ne $argNames[$i]) { Fail "Run: posição $i param '$($pNames[$i])' recebe arg '$($argNames[$i])'"; $mismatch++ } }
            if (-not $mismatch) { Ok "Run: $($pNames.Count) parâmetros alinhados com os argumentos" }
        }
    }
}

Section "8. Perfis e listas de checkboxes"
$uiText = Get-Content (Join-Path $Root 'Modules\Wgo.UI\Wgo.UI.psm1') -Raw
if ($uiText -match '(?s)WgoUI_OptimizationCheckboxNames\s*=\s*@\((.*?)\n\)') {
    $optNames = [regex]::Matches($Matches[1], "'([^']+)'") | ForEach-Object { $_.Groups[1].Value }
    foreach ($n in $optNames) { if ($xamlNames -notcontains $n) { Fail "Checkbox '$n' está na lista de otimizações mas não no XAML" } }
    $dupes = $optNames | Group-Object | Where-Object Count -gt 1
    foreach ($d in $dupes) { Warn "Checkbox duplicado na lista de otimizações: $($d.Name)" }
    [regex]::Matches($uiText, '(?s)WgoUI_Profiles\s*=\s*@\{(.*?)\n\}') | ForEach-Object {
        [regex]::Matches($_.Groups[1].Value, "'(chk\w+)'") | ForEach-Object { $n = $_.Groups[1].Value; if ($optNames -notcontains $n) { Fail "Perfil referencia '$n' que não está na lista de otimizações" } }
    }
    Ok "$($optNames.Count) checkboxes de otimização verificados contra XAML e perfis"
}

Section "9. Rótulos de idioma, detectores do Scanner e catálogo de apps"
if ($optNames -and $langs.ContainsKey('en-US')) {
    $missingChk = @($optNames | Where-Object { $langs['en-US'] -notcontains ('Chk' + $_.Substring(3)) })
    if ($missingChk.Count) { foreach ($m in $missingChk) { Fail "Sem rótulo 'Chk$($m.Substring(3))' em en-US para $m" } } else { Ok "todos os $($optNames.Count) checkboxes têm rótulo (Chk*) nos idiomas" }
    $scannerText = [IO.File]::ReadAllText((Join-Path $Root 'Modules/Wgo.Scanner/Wgo.Scanner.psm1'))
    $detected = [regex]::Matches($scannerText, "\`$detectors\['(chk\w+)'\]") | ForEach-Object { $_.Groups[1].Value }
    $noDetector = @($optNames | Where-Object { $detected -notcontains $_ })
    $orphans = @($detected | Where-Object { $optNames -notcontains $_ -and $_ -notmatch '^chkRisky' -and $_ -ne 'chkDisableXboxServices' })
    foreach ($o in $orphans) { Fail "Detector '$o' não corresponde a nenhum checkbox de otimização" }
    Ok "$($detected.Count) detectores; sem detector (ações pontuais): $($noDetector -join ', ')"
    $reasons = [regex]::Matches($scannerText, "New-Status\s+'(?:NotApplicable|Applied|Pending|Partial|Unknown)'\s+'(\w+)'") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $reasons += [regex]::Matches($scannerText, "\$laptopNote\s*=\s*if[^']*'(\w+)'") | ForEach-Object { $_.Groups[1].Value }
    foreach ($r in ($reasons | Sort-Object -Unique)) { if ($r -ne 'NoTasks' -and $langs['en-US'] -notcontains "ScanReason$r") { Fail "Motivo '$r' sem chave ScanReason$r" } }
    Ok "$((($reasons | Sort-Object -Unique) | Measure-Object).Count) motivos do Scanner com tradução"
    $ids = [regex]::Matches($scannerText, "Add-Check\s+'(\w+)'") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    foreach ($i in $ids) {
        $need = if ($i -eq 'Restore') { @('PreflightRestoreDisabled', 'PreflightRestoreRecent') } else { @("Preflight$i") }
        foreach ($k in $need) { if ($langs['en-US'] -notcontains $k) { Fail "Verificação '$i' sem chave $k" } }
    }
    Ok "$($ids.Count) verificações de pré-requisito com tradução"
}
$catText = [IO.File]::ReadAllText((Join-Path $Root 'Modules/Wgo.AppInstaller/Wgo.AppInstaller.psm1'))
$entries = [regex]::Matches($catText, "ScoopId = `"([^`"]*)`"(?:; Bucket = `"([^`"]*)`")?")
$badBucket = @($entries | Where-Object { $_.Groups[2].Value -notin @('main', 'extras', 'games') })
foreach ($b in $badBucket) { Fail "ScoopId '$($b.Groups[1].Value)' sem Bucket válido (main/extras/games)" }
if (-not $badBucket.Count) { Ok "$($entries.Count) apps do catálogo com bucket definido" }

Write-Host "`n================ RESULTADO: $($script:fail) falha(s), $($script:warn) aviso(s) ================" -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
exit ([int]($script:fail -gt 0))
