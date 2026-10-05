param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$script:fails = 0
function Assert([bool]$Cond, [string]$Msg) {
    if ($Cond) { Write-Host "  [ OK ] $Msg" -ForegroundColor Green } else { $script:fails++; Write-Host "  [FALHA] $Msg" -ForegroundColor Red }
}
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$catText = [IO.File]::ReadAllText((Join-Path $Root 'Modules/Wgo.AppInstaller/Wgo.AppInstaller.psm1'))
$entries = [regex]::Matches($catText, "'([^']+)'\s*=\s*@\{\s*Name = `"([^`"]*)`";\s*WingetId = `"([^`"]*)`";\s*ScoopId = `"([^`"]*)`"; Bucket = `"([^`"]*)`"")
Write-Host "`n== Catálogo: $($entries.Count) apps" -ForegroundColor Cyan

$repos = @{ main = 'Main'; extras = 'Extras'; games = 'Games' }
$manifests = @{}
foreach ($b in $repos.Keys) {
    $zip = Join-Path ([IO.Path]::GetTempPath()) "wgo_cat_$b.zip"
    $dir = Join-Path ([IO.Path]::GetTempPath()) "wgo_cat_$b"
    Remove-Item $dir -Recurse -Force -ErrorAction Ignore
    Invoke-WebRequest -Uri "https://codeload.github.com/ScoopInstaller/$($repos[$b])/zip/refs/heads/master" -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $dir -Force
    $inner = Get-ChildItem $dir -Directory | Select-Object -First 1
    $manifests[$b] = @{}
    foreach ($f in Get-ChildItem (Join-Path $inner.FullName 'bucket') -Filter *.json -File) { $manifests[$b][$f.BaseName] = $f.FullName }
    Write-Host "  bucket $b : $($manifests[$b].Count) manifestos"
}

Write-Host "`n== ScoopId existe no bucket declarado" -ForegroundColor Cyan
foreach ($e in $entries) {
    $key = $e.Groups[1].Value; $sid = $e.Groups[4].Value; $bucket = $e.Groups[5].Value
    $ok = $manifests[$bucket].ContainsKey($sid)
    $other = @($manifests.Keys | Where-Object { $manifests[$_].ContainsKey($sid) }) -join ','
    Assert $ok ("{0,-26} {1,-22} bucket={2}{3}" -f $key, $sid, $bucket, $(if (-not $ok -and $other) { "  (encontrado em: $other)" } else { '' }))
}

$xaml = [IO.File]::ReadAllText((Join-Path $Root 'xaml/MainWindow.xaml'))
$tags = [regex]::Matches($xaml, '<CheckBox x:Name="(chk\w+)"[^>]*?Tag="([^"]+)"') | ForEach-Object { $_.Groups[2].Value }
Write-Host "`n== Tags do XAML x catálogo" -ForegroundColor Cyan
$keys = $entries | ForEach-Object { $_.Groups[1].Value }
foreach ($t in $tags) { Assert ($keys -contains $t) "Tag '$t' existe no catálogo" }
foreach ($k in $keys) { Assert ($tags -contains $k) "Entrada '$k' tem checkbox no XAML" }

Write-Host "`n================ RESULTADO: $($script:fails) falha(s) ================" -ForegroundColor $(if ($script:fails) { 'Red' } else { 'Green' })
exit ([int]($script:fails -gt 0))
