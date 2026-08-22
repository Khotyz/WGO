# WGO - Windows General Optimizations

**WGO** is a comprehensive, all-in-one optimization toolkit for Windows 10 and 11. It brings together system tweaks, privacy hardening, bloatware removal, application installation, diagnostics, and recovery utilities into a single, easy-to-use graphical interface.

> **⚠️ Important**  
> WGO modifies system settings, registry keys, and services. While it creates a System Restore Point before making changes, please review each option carefully. Risky tweaks (which weaken security or update mechanisms) are clearly marked and require explicit confirmation.

---

## ✨ Key Features

### 🧹 Optimizations & Privacy
- **Bloatware Removal** – Uninstall pre-installed apps (AI apps, Copilot, Recall, Paint 3D, Your Phone, Teams, etc.) while keeping essential components like Store, Xbox, Edge/WebView2, and runtimes.
- **Search & Visuals** – Force 100% local search (disable Bing/Edge web search) and apply a performance-oriented visual effects profile.
- **Deep Privacy** – Block telemetry, Windows Error Reporting (WER), CEIP, Activity Feed, location services, and advertising ID via Group Policy.
- **Additional Telemetry Blocking** – Disable DiagTrack/dmwappushservice, Copilot/Recall, input personalization, and clipboard cloud sync.
- **Driver & Pagefile** – Block automatic driver installation via Windows Update and set an optimized static pagefile size based on installed RAM.

### ⚡ Advanced System Tweaks
- Disable Edge preload and Widgets.
- Disable Delivery Optimization (P2P).
- Suspend UWP background apps.
- Network latency reduction (TCP/IP tuning).

### 🛠 Service Management & Cleanup
- Disable SysMain (SuperFetch) – frees RAM/CPU, recommended for SSDs.
- Disable Windows Search (WSearch) – stops file indexing.
- Disable Print Spooler (if no printer is used).
- Clean the WinSxS component store to reclaim disk space.

### 🧼 System Cleanup & Performance
- Disable Hibernation (frees `hiberfil.sys`).
- Set power plan to High Performance.
- Clean temporary files, old Prefetch, Windows.old, and Windows Update cache.
- Disable Snap Assist / Aero Shake.
- Reduce boot menu timeout to 5 seconds.
- Block Office and OneDrive telemetry.
- Remove additional telemetry scheduled tasks.
- Auto-configure TRIM for SSDs and scheduled defrag for HDDs.
- Enable Game Mode and Hardware-Accelerated GPU Scheduling (HAGS).
- Enable Ultimate Performance power plan (CPU min state at 100%).
- Prioritize foreground games (kernel + MMCSS).
- Disable Xbox Game DVR background recording.
- Reduce input lag (disable mouse acceleration, Sticky/Filter Keys popups, Fullscreen Optimizations).
- Exclude junk/cache folders from Windows Search indexing.
- Remove hidden/ghost network adapters from Device Manager.
- Disable Fast Startup (prevents RAM leaks across reboots).
- Set low-value background services (PcaSvc, WerSvc, wisvc, RetailDemo) to Manual.
- Clear Standby List memory cache instantly.
- Optimise system cache for high-RAM systems (8GB+).

### 🕵️ Additional Privacy & Cleanup
- Block telemetry domains via the hosts file.
- Disable Shared Experiences and Cortana completely.
- Clear icon and font cache.
- Remove People bar, News & Interests icon, and Ink Workspace.
- Disable TCP window autotuning.
- Set Cloudflare DNS and enable DNS over HTTPS (DoH).
- Skip pagefile clearing on shutdown (faster shutdown).
- Disable Prefetch on SSDs (auto-detected).
- Remove the "Windows Backup" app (not removable from Settings).
- Reset TCP/IP stack (fixes network connectivity issues).

### ⚠️ Risky Tweaks (Advanced)
These options weaken Windows security or update mechanisms. They are **not** recommended unless you fully understand the consequences.
- Disable User Account Control (UAC).
- Disable SmartScreen (Windows and Edge).
- Disable Windows Defender real-time protection.
- Disable the Windows Update service.
- Disable BITS (Background Intelligent Transfer).

### 📦 App Installer
Install popular applications directly from the UI using **winget** (built into Windows) with automatic fallback to **Chocolatey**.
- **Browsers:** Firefox, Brave
- **File & Archive:** NanaZip, 7-Zip, Notepad++, WizTree
- **Downloads & Torrents:** Free Download Manager, qBittorrent
- **Gaming & Streaming:** Steam, Epic Games Launcher, GOG Galaxy, Moonlight, Sunshine
- **System Monitoring & Cleanup:** CPU-Z, HWMonitor, Mem Reduct, BleachBit
- **Productivity & Customization:** Nilesoft Shell, Optiscaler Client, Flow Launcher, ShareX

> **Note:** If winget fails for any application, WGO automatically falls back to Chocolatey. You can install Chocolatey with one click from the UI.

### 🔧 Utilities & Diagnostics
- **Restart Utilities:** Safe Mode with Networking, UEFI Firmware Settings, Normal Restart.
- **Hidden Windows Tools:** Disk Cleanup, Resource Monitor, Optimize Drives, Windows Memory Diagnostic.
- **System Diagnostics:** Run DISM /RestoreHealth and SFC /scannow to repair system files.
- **Network Tools:** Flush DNS cache.

### 🧩 External Scripts (Third-Party)
Launch independent open-source scripts in their own windows (each requests admin rights separately):
- **AMD Stability Optimizer** – Fixes common AMD Radeon driver crashes, black screens, and stutter.
- **Microsoft Activation Scripts (MAS)** – Community tool for activating Windows and Office (HWID, KMS38, Online KMS).
- **UniGetUI** – Opens the official download page for a graphical package manager (supports WinGet, Chocolatey, Scoop, etc.).

### 🌐 Multi-Language Support
WGO currently supports:
- English (en-US)
- Portuguese (pt-BR)
- Spanish (es-ES)
- Chinese (zh-CN)

---

## 🚀 How to Run

### Option 1 – One‑Line Online Install (Recommended)

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/Khotyz/WGO/main/WGO.ps1 | iex
```

This command downloads the entire repository into a temporary folder and launches the graphical interface with full administrator privileges. No files are left behind after the script exits (unless you save profiles).

### Option 2 – Download the Latest Release

1. Visit the [Releases page](https://github.com/Khotyz/WGO/releases/latest).
2. Download the `WGO.zip` file (or the source code).
3. Extract the archive to a folder of your choice.
4. Right-click `WGO.ps1` and select **Run with PowerShell** (or open PowerShell as Admin, navigate to the folder, and run `.\WGO.ps1`).

---

## 📋 Requirements

- **Windows 10 / 11** (64-bit recommended).
- **PowerShell 5.1** or later (built into Windows).
- **Administrator privileges** – the script will automatically request elevation.

---

## 🛡️ Safety First

- **System Restore Point** – A restore point is created automatically before applying any changes (unless you disable it).
- **Dry Run Mode** – Check the *"Dry Run"* box to see what would be changed without actually applying anything.
- **Profile Export/Import** – Save your current selections as a JSON profile and restore them later.
- **Restore Defaults** – The *"Restore Defaults"* button reverts all registry and service modifications made by WGO (except for installed applications and manual file deletions).

---

## 🧠 How It Works Under the Hood

WGO is modular, consisting of several PowerShell modules:

| Module | Purpose |
|--------|---------|
| `Wgo.Core` | Core optimization functions (bloatware removal, privacy, visual effects, pagefile, etc.). |
| `Wgo.AppInstaller` | Application installation via winget and Chocolatey. |
| `Wgo.Profile` | Profile import/export and last-run state persistence. |
| `Wgo.Utilities` | Launch external scripts (MAS, AMD Optimizer). |
| `Wgo.Shared` | Translation, logging, UI helpers, and background task runner. |
| `Wgo.Services` | Service management and system integrity (DISM, SFC, DNS flush). |
| `Wgo.Native` | Native P/Invoke calls (e.g., clearing Standby List). |
| `Wgo.UI` | WPF interface, themes, language switching, and event handling. |

All modules are loaded dynamically from the `Modules/` folder. The interface is defined in `xaml/MainWindow.xaml` and supports light/dark themes.

---

## 📄 License

This project is open-source (MIT License). Feel free to contribute or adapt it for your own needs.

---

## 🙋 Support & Feedback

- Open an issue on [GitHub Issues](https://github.com/Khotyz/WGO/issues)
- Pull requests are welcome!

---

**Enjoy a cleaner, faster, and more private Windows experience with WGO!**
