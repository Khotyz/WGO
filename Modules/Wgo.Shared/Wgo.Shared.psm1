# Wgo.Shared.psm1 - Shared utilities, translation, logging, and UI helpers

function Import-WgoLanguages {
    # Loads every lang/*.json file into $global:Lang, keyed by culture code (e.g. "pt-BR").
    # Adding a new language only requires dropping a new JSON file in lang/.
    $global:Lang = @{}
    $langDir = Join-Path $Global:WgoRootPath "lang"
    if (-not (Test-Path $langDir)) {
        throw "Language folder not found: $langDir"
    }
    Get-ChildItem -Path $langDir -Filter "*.json" | ForEach-Object {
        $code = $_.BaseName
        $json = Get-Content -Path $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $table = @{}
        foreach ($prop in $json.PSObject.Properties) { $table[$prop.Name] = $prop.Value }
        $global:Lang[$code] = $table
    }
}
Import-WgoLanguages

# ============================================================
# FUNCTIONS
# ============================================================

function T {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(ValueFromRemainingArguments = $true)][object[]]$FormatArgs
    )
    $table = $global:Lang[$Global:CurrentLangCode]
    if (-not $table -or -not $table.ContainsKey($Key)) { $table = $global:Lang['en-US'] }
    $template = $table[$Key]
    if (-not $template) { return $Key }
    if ($FormatArgs -and $FormatArgs.Count -gt 0) {
        try { return ($template -f $FormatArgs) } catch { return $template }
    }
    return $template
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $Global:WgoLogQueue.Enqueue("[$timestamp][$Level] $Message")
}

function Show-WgoFatalError {
    param([string]$Message)
    [System.Windows.Forms.MessageBox]::Show(
        $Message, "WGO - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

function Show-WgoConfirm {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [string]$Title = "WGO"
    )

    [xml]$dialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$([System.Security.SecurityElement]::Escape($Title))" Height="220" Width="440"
        WindowStartupLocation="CenterOwner" ResizeMode="NoResize"
        Background="#FF1A1B1E" WindowStyle="None" AllowsTransparency="False"
        BorderBrush="#FF4CC2FF" BorderThickness="1">
    <Border Padding="20" Background="#FF1A1B1E">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,12">
                <Ellipse Width="10" Height="10" Fill="#FF4CC2FF" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock x:Name="txtDialogTitle" Text="$([System.Security.SecurityElement]::Escape($Title))" Foreground="#FF4CC2FF" FontWeight="SemiBold" FontSize="14"/>
            </StackPanel>

            <TextBlock x:Name="txtDialogMessage" Grid.Row="1" Text="$([System.Security.SecurityElement]::Escape($Message))"
                       Foreground="#FFF3F4F6" TextWrapping="Wrap" VerticalAlignment="Center" FontSize="13"/>

            <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
                <Button x:Name="btnDialogNo" Content="No" Width="90" Height="34" Margin="0,0,10,0"
                        Background="#FF2B2D31" Foreground="#FFF3F4F6" BorderBrush="#FF3A3C41" BorderThickness="1"/>
                <Button x:Name="btnDialogYes" Content="Yes" Width="90" Height="34"
                        Background="#FF4CC2FF" Foreground="#FF0B0B0B" BorderBrush="#FF4CC2FF" BorderThickness="1" FontWeight="Bold"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

    $dlgReader = New-Object System.Xml.XmlNodeReader $dialogXaml
    $dlg = [Windows.Markup.XamlReader]::Load($dlgReader)
    try { $dlg.Owner = $Global:WgoUI_Window } catch { }

    $btnYes = $dlg.FindName('btnDialogYes')
    $btnNo  = $dlg.FindName('btnDialogNo')
    $btnYes.Add_Click({ $script:wgoDialogResult = $true; $dlg.Close() }.GetNewClosure())
    $btnNo.Add_Click({ $script:wgoDialogResult = $false; $dlg.Close() }.GetNewClosure())
    $dlg.Add_MouseLeftButtonDown({ if ($_.ChangedButton -eq 'Left') { $dlg.DragMove() } })

    $script:wgoDialogResult = $false
    $dlg.ShowDialog() | Out-Null
    return $script:wgoDialogResult
}

function Start-WgoBackgroundTask {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @(),
        [scriptblock]$OnCompleted = $null
    )

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::MTA
    $rs.ThreadOptions   = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $rs.Open()

    $rs.SessionStateProxy.SetVariable('WgoLogQueue', $Global:WgoLogQueue)
    $rs.SessionStateProxy.SetVariable('WgoRootPath', $Global:WgoRootPath)
    $rs.SessionStateProxy.SetVariable('Lang', $global:Lang)
    $rs.SessionStateProxy.SetVariable('CurrentLangCode', $Global:CurrentLangCode)
    $rs.SessionStateProxy.SetVariable('WgoAppCatalog', $Global:WgoAppCatalog)
    $rs.SessionStateProxy.SetVariable('BloatwareWhitelist', $BloatwareWhitelist)
    $rs.SessionStateProxy.SetVariable('BloatwareTargets', $BloatwareTargets)
    $rs.SessionStateProxy.SetVariable('BloatwareCriticalProtect', $BloatwareCriticalProtect)
    $rs.SessionStateProxy.SetVariable('ErrorActionPreference', 'Stop')

    $ps = [powershell]::Create()
    $ps.Runspace = $rs

    $funcDefs = ($Global:WgoSharedFunctionNames | ForEach-Object {
        $fn = Get-Item "function:\$_" -ErrorAction Ignore
        if ($fn) { "function $_ {`n$($fn.ScriptBlock)`n}" }
    }) -join "`n`n"
    [void]$ps.AddScript($funcDefs)

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

Export-ModuleMember -Function T, Write-Log, Show-WgoFatalError, Show-WgoConfirm, Start-WgoBackgroundTask, Import-WgoLanguages
