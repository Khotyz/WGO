# Windows General Optimizations

**WGO** is a free, open‑source all‑in‑one tool that cleans, speeds up, and hardens Windows 10/11 – all from a clean graphical interface.  
It removes bloatware, blocks telemetry, applies performance tweaks, installs apps, and offers system recovery tools.  
Just check what you want, click **Run Selected Optimizations**, and WGO handles the rest – while creating a restore point automatically.

---

## 🚀 How to Run

### One‑line online (recommended)
Open **PowerShell as Administrator** and paste:

```powershell
irm https://raw.githubusercontent.com/Khotyz/WGO/main/WGO.ps1 | iex
```

This downloads the latest version to a temporary folder, starts the UI, and cleans up after itself.

### Manual install
- Download `WGO.7z` from the [Releases](https://github.com/Khotyz/WGO/releases/latest) page.
- Extract it anywhere.
- Right‑click `WGO.ps1` → **Run with PowerShell**.

> The script auto‑elevates to Administrator if needed.

---

## ✨ Key Features

### 🎨 Interface, Theme & Languages
- Fluent Win11‑style dark/light UI with a one‑click **theme toggle**.
- Multi‑language support out of the box: **en‑US**, **pt‑BR**, **es‑ES**, **zh‑CN** (just drop a new JSON in `lang/` to add more).
- Modular architecture (`Wgo.Core`, `Wgo.Scanner`, `Wgo.Amd`, `Wgo.AppInstaller`, `Wgo.Services`, `Wgo.Utilities`, `Wgo.UI`, …) so features stay isolated and safe.
- Live execution log at the bottom of the window; all long tasks run on a background runspace so the UI never freezes.

### 🔍 System Scanner & Preflight Checks
- **Hardware profile** built on launch: CPU, RAM, GPU inventory (NVIDIA / AMD / Intel, integrated vs. dedicated), disk types (NVMe / SSD / HDD), laptop chassis, VM detection.
- **Automatic status detection** for every option: `Applied`, `Partial`, `Pending`, `NotApplicable` (with reasons like *no NVIDIA GPU*, *no AMD GPU*, *not enough RAM*, *Windows version too old*, *service not present*), and `Unknown` when a probe fails.
- **Re-scan** button and a **"Skip options already applied"** toggle so profiles and *Select All* don't waste time re‑applying what's already in place.
- **Preflight warnings** surfaced before you run anything: not admin, Constrained Language mode, WMI/CIM down, HKCU user mismatch under `RunAs`, System Restore disabled or used in the last 24h, `powercfg` / `bcdedit` / `Get‑NetTCPSetting` / Task Scheduler / AppX / winget unavailable, pending reboot, low disk space, VM detected, Defender Tamper Protection on.
- Status badges (✔ / ◐ / ⊘) are appended directly to checkbox labels and every option gets a rich tooltip with what was detected.

### 🧹 Privacy & System Hardening
- Remove pre‑installed bloatware and AI apps (Copilot, Recall, Paint 3D, Your Phone, etc.) while keeping Store, Xbox, Edge/WebView2, and runtimes.
- Force 100% local search (disable Bing/Edge web results).
- Block telemetry, WER, CEIP, Activity Feed, and location via Group Policy.
- Disable advertising ID, tailored experiences, Copilot/Recall, and input personalisation.
- Block telemetry domains via the `hosts` file.
- Disable Shared Experiences, Cortana, and Windows Spotlight.
- Disable Edge telemetry and Windows Error Reporting.
- Pause Windows Update for 7 days (same registry keys Settings uses).

### ⚡ Performance & Memory
- Apply a performance visual‑effects profile (disable animations, shadows, transparency).
- Set power plan to **High Performance** or **Ultimate Performance** (CPU min state 100%, AC/DC) – with verification that the change actually stuck.
- Disable Hibernation, Fast Startup, SysMain (SuperFetch), and Windows Search indexing.
- Reduce input lag (mouse acceleration, Sticky Keys, Fullscreen Optimizations).
- Reduce network latency (TCP/IP tuning, disable Nagle, IPv6, TCP autotuning).
- Increase timer resolution to 0.5 ms via native `NtSetTimerResolution`.
- Optimise system cache for 8 GB+ RAM (`LargeSystemCache` + `DisablePagingExecutive`).
- Instantly clear Standby List (frees cached RAM).
- Auto‑clean Standby List every 5 minutes (scheduled task).
- Clean temporary files, Prefetch, Windows.old, Windows Update cache, and DirectX / NVIDIA / AMD / Intel shader caches.
- Clear icon/font cache, event logs, minidumps, and Store cache.
- **Steam download boost** – resets TCP autotuning to *Normal* and sets `CpuPriorityClass=3` (High) for `steam.exe` under IFEO. Mutually exclusive with *Disable TCP autotuning* (Steam Boost wins, with a log note).

### 🛠️ Service & Driver Management
- Block automatic driver updates via Windows Update.
- Disable unnecessary services: Print Spooler, SysMain, WSearch, Xbox services (opt‑in), BITS, Windows Update, etc.
- Set low‑value services (PcaSvc, WerSvc, wisvc, RetailDemo, Fax, RemoteRegistry, MapsBroker, lfsvc, PhoneSvc, CDPSvc, SEMgrSvc, WMPNetworkSvc…) to Manual.
- **Xbox services** (XblAuthManager, XblGameSave, XboxNetApiSvc, XboxGipSvc) are intentionally kept out of every profile and out of *Select All* – enable only if you don't use Game Pass or Store games.
- Clean the WinSxS component store.
- Configure TRIM for SSDs and scheduled defrag for HDDs (auto‑detected per drive).

### 🌐 Network & GPU Tweaks
- Disable IPv6, Nagle's algorithm, and TCP window autotuning.
- Set Cloudflare DNS with DNS over HTTPS.
- Reset TCP/IP stack, flush DNS, release/renew IP, register DNS.
- Optimise Receive Side Scaling (RSS).
- Increase NVIDIA TDR timeout to prevent driver crashes.
- Disable NVIDIA telemetry services and scheduled tasks.

### 🖥️ System Tuning (Performance)
- **Disable NTFS last‑access updates** (`fsutil behavior set disablelastaccess 1`) – fewer disk writes; 8.3 short names are left untouched so legacy installers keep working.
- **Disable LLMNR** – stops legacy multicast name resolution broadcasts; regular DNS keeps working.
- **Remove the menu show delay** (400 ms → 0 ms) for instant menus.
- **Increase DNS cache lifetime** (`MaxCacheTtl=86400`, `MaxNegativeCacheTtl=5`).
- **Stop search indexing on battery and removable drives** – fixed‑disk search is unaffected.
- **Fastest keyboard repeat delay and rate**.

### 🔧 AMD Radeon Fixes (dedicated tab)
- **Disable ULPS** – prevents unstable low‑power states on multi‑GPU or hybrid setups.
- **Disable MPO** – reverts the `OverlayTestMode` DWM key that is a known cause of gray screens.
- **Extend TDR timeout** – gives the driver more time before a reset.
- **Disable AMD Crash Defender** – prevents masking real driver crashes.
- **Disable HDCP** – avoids display disconnects with incompatible monitors/cables.
- **Disable AMD telemetry** – stops AMD External Events and AMD User Experience services.
- **Fix browser/Electron hardware acceleration** – reverts MPO, disables HAGS, forces Chrome/Edge to use OpenGL.

> The AMD tab auto‑detects whether a Radeon GPU is present. On NVIDIA/Intel‑only machines the group is disabled and the banner explains why. The tab is also a first‑class restore category (**AMD**) so changes can be reverted independently.

### 📦 App Installer (winget + Scoop)
Install popular apps via **winget** (built into Windows) with automatic fallback to **Scoop**.  
Bulk installs run in the background, report per‑app results, and log everything to `%TEMP%`.

**Browsers:** Firefox, Brave  
**Files & Archives:** NanaZip, 7‑Zip, Notepad++, WizTree  
**Downloads:** Free Download Manager, qBittorrent  
**Gaming:** Steam, Epic Games Launcher, GOG Galaxy, Moonlight, Sunshine  
**Monitoring & Cleanup:** CPU‑Z, HWiNFO, Mem Reduct, BleachBit, DNS Jumper, CapFrameX, MSI Afterburner, RivaTuner Statistics Server, DLSS Swapper, Display Driver Uninstaller (DDU), HWMonitor  
**Productivity:** Nilesoft Shell, Flow Launcher, ShareX

> **Note:** Scoop is installed automatically the first time it's needed. Buckets are added via Git when available, with a ZIP‑download fallback. Desktop shortcuts are created for Scoop‑installed apps where possible. MSI Afterburner automatically pulls RTSS as a companion install.

### 🧰 Utilities & Recovery
- **Restart utilities:** Safe Mode with Networking, UEFI Firmware Settings, or Normal restart (with a *bootcfg* reset reminder).
- **Hidden Windows tools:** Disk Cleanup, Resource Monitor, Optimize Drives (defrag/TRIM), Windows Memory Diagnostic, plus a one‑click **Free Up RAM Now** button.
- **System diagnostics:** DISM `/RestoreHealth`, `sfc /scannow`, Flush DNS, Release/Renew IP, Register DNS.
- **System information:** read‑only CPU/RAM/GPU/OS/disk/battery‑health summary.
- **Startup Programs manager:** list and toggle Run‑key + Startup‑folder entries (disabled items are safely moved aside, with a fallback if a rename fails).
- **Scheduled optimization:** create a daily, weekly, or custom (every N days) task that runs the *Basic* profile silently.
- **Advanced cleanup:** Clear Windows Event Logs, Delete Minidumps, Clear Store Cache, Pause Updates for 7 days, Disable Edge Telemetry, Disable Windows Spotlight.
- Create System Restore Points.

### 🧾 Profiles & Safety
- Predefined profiles: **Basic**, **Laptop**, **Gamer**, **Privacy**, **eSports**, **Maximum**.
- Profiles automatically filter out options that don't apply to your hardware (no NVIDIA → no NVIDIA tweaks; no AMD → no AMD tweaks) and skip already‑applied options when *Skip options already applied* is on.
- Opt‑in actions (`Standby List Clean`, `Auto Standby Clean`) are **never** selected by profiles or by *Select All* – they must be chosen deliberately.
- Export/import your own settings as JSON.
- Last‑run state is saved automatically (`%LOCALAPPDATA%\WGO\last-run.json`).
- **Dry‑run mode** – see what would be changed without applying anything.
- **Risky tweaks** (disable UAC, Defender, Firewall, BITS, Windows Update, SmartScreen, DEP, NVIDIA max‑perf) live in a clearly marked warning section, require explicit confirmation, and are verified after applying (with a *Tamper Protection* hint when relevant).
- Restore defaults per category: **All**, **Privacy**, **Network**, **Services**, **Visual**, **AMD**, **Risky**, **Tuning**.

### 🌐 External Scripts
Run trusted third‑party open‑source tools from their own window (each requests admin on its own):
- **Microsoft Activation Scripts (MASSGRAVE)** – official Windows/Office activation project.
- **UniGetUI** – GUI for winget, Scoop, pip, npm… (opens the official download page to avoid the *publisher could not be verified* winget warning).
- **Optiscaler Client** – DLSS/FSR/XeSS upscaling & frame‑generation injector (GitHub releases page).
- **OCCT** – CPU/GPU/RAM/PSU stress test (opens the official download page).

> A clear in‑app warning states these scripts are **not part of WGO** and should only be run from sources you trust.

---

## 📋 Requirements

- Windows 10 / 11 (64‑bit recommended)
- PowerShell 5.1 or later (built‑in)
- Administrator privileges (auto‑requested)
- Optional: Git (installed automatically via Scoop when a bucket needs it)

---

## 🛡️ Safety First

- A **System Restore Point** is created automatically before any change.
- A hardened `Remove-WgoPathSafely` guard rejects drive roots and shallow paths, and refuses to touch user data folders (Desktop, Documents, Pictures, Music, Videos, `%USERPROFILE%`, `%ProgramFiles%`, `%ProgramData%`, `%PUBLIC%`, `%WINDIR%`) — even via wildcard.
- `RemoveOneDrive` only removes the **app**; the OneDrive data folder is left alone and a warning is shown if Known Folder Move is active.
- HAGS is automatically skipped on AMD GPUs (known driver instability) with a clear log message.
- Power‑plan and Ultimate‑Performance changes are verified after applying — a warning is logged if a third‑party tool (e.g. ExitLag) or Group Policy reverts them.
- All actions are logged in real‑time with per‑step results.
- You can revert changes with the **Restore Defaults** button (per category).

---

## 📄 License

MIT – see the [LICENSE](LICENSE) file.

---

**Enjoy a cleaner, faster, and more private Windows!**