# WGO - Windows General Optimizations

WGO is a graphical (WPF) PowerShell tool for optimizing, debloating, and configuring privacy on Windows 10/11.

It lets you:

- Remove bloatware and AI-related apps (with a built-in whitelist for Store, Xbox, Edge/WebView2, and runtimes)
- Block telemetry, WER, CEIP, Activity Feed, Location, Advertising ID, and Copilot/Recall via Group Policy
- Force 100% local Start Menu search (disable Bing/Edge web search)
- Apply a custom performance-oriented Visual Effects profile
- Block automatic driver installation through Windows Update
- Set a static pagefile size
- Create a System Restore Point before making changes
- Install useful apps (Firefox, NanaZip, Notepad++, Free Download Manager, qBittorrent, Steam, Epic Games Launcher, GOG Galaxy) automatically via **winget**, with an automatic **Chocolatey** fallback
- Track everything through a real-time execution log

Available in English, Portuguese (pt-BR), Spanish (es-ES), and Chinese (zh-CN).

## Requirements

- Windows 10 (2004+) or Windows 11
- PowerShell 5.1+
- Administrator privileges (the script self-elevates)

## Run online (recommended)

Open PowerShell **as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/Khotyz/WGO/main/WGO.ps1 | iex
```

This downloads and runs the latest version of the script directly, with no manual download needed. The script will request elevation automatically if it isn't already running as Administrator.

## Run locally

1. Download `WGO.ps1` from this repository.
2. Right-click the file and select **Run with PowerShell**, or run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\WGO.ps1
```

## Disclaimer

WGO modifies system settings, registry policies, and installed applications. A System Restore Point is created automatically before optimizations run, but you should still review the options before applying them and use the tool at your own risk.

## License

Licensed under the [MIT License](LICENSE).
