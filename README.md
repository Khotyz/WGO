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
- Download `WGO.zip` from the [Releases](https://github.com/Khotyz/WGO/releases/latest) page.
- Extract it anywhere.
- Right‑click `WGO.ps1` → **Run with PowerShell**.

> The script auto‑elevates to Administrator if needed.

---

## ✨ Key Features

### 🧹 Privacy & System Hardening
- Remove pre‑installed bloatware and AI apps (Copilot, Recall, Paint 3D, Your Phone, etc.) while keeping Store, Xbox, Edge/WebView2, and runtimes.
- Force 100% local search (disable Bing/Edge web results).
- Block telemetry, WER, CEIP, Activity Feed, and location via Group Policy.
- Disable advertising ID, tailored experiences, Copilot/Recall, and input personalisation.
- Block telemetry domains via the `hosts` file.
- Disable Shared Experiences, Cortana, and Windows Spotlight.
- Disable Edge telemetry and Windows Error Reporting.

### ⚡ Performance & Memory
- Apply a performance visual‑effects profile (disable animations, shadows, transparency).
- Set power plan to **High Performance** or **Ultimate Performance** (CPU min state 100%).
- Disable Hibernation, Fast Startup, SysMain (SuperFetch), and Windows Search indexing.
- Reduce input lag (mouse acceleration, Sticky Keys, Fullscreen Optimizations).
- Reduce network latency (TCP/IP tuning, disable Nagle, IPv6, TCP autotuning).
- Increase timer resolution to 0.5ms.
- Optimise system cache for 8GB+ RAM.
- Instantly clear Standby List (frees cached RAM).
- Auto‑clean Standby List every 5 minutes (scheduled task).
- Clean temporary files, Prefetch, Windows.old, and Windows Update cache.
- Clear icon/font cache, event logs, minidumps, and Store cache.

### 🛠️ Service & Driver Management
- Block automatic driver updates via Windows Update.
- Disable unnecessary services: Print Spooler, SysMain, WSearch, Xbox services, BITS, Windows Update, etc.
- Set low‑value services (PcaSvc, WerSvc, wisvc, RetailDemo) to Manual.
- Clean the WinSxS component store.
- Configure TRIM for SSDs and scheduled defrag for HDDs.

### 🌐 Network & GPU Tweaks
- Disable IPv6, Nagle’s algorithm, and TCP window autotuning.
- Set Cloudflare DNS with DNS over HTTPS.
- Reset TCP/IP stack, flush DNS, release/renew IP.
- Optimise Receive Side Scaling (RSS).
- Increase NVIDIA TDR timeout to prevent driver crashes.
- Disable NVIDIA telemetry services and scheduled tasks.

### 🔧 AMD Radeon Fixes (dedicated tab)
- **Disable ULPS** – prevents unstable low‑power states on multi‑GPU or hybrid setups.
- **Disable MPO** – removes the `OverlayTestMode` registry key (known to cause gray screens).
- **Extend TDR timeout** – gives the driver more time before a reset.
- **Disable AMD Crash Defender** – prevents masking real driver crashes.
- **Disable HDCP** – avoids display disconnects with incompatible monitors/cables.
- **Disable AMD telemetry** – stops AMD External Events and AMD User Experience services.
- **Fix browser/Electron hardware acceleration** – removes MPO, disables HAGS, forces Chrome/Edge to use OpenGL.

### 📦 App Installer (winget + Scoop)
Install popular apps via **winget** (built into Windows) with automatic fallback to **Scoop**.  
New apps include:

**Browsers:** Firefox, Brave  
**Files & Archives:** NanaZip, 7‑Zip, Notepad++, WizTree  
**Downloads:** Free Download Manager, qBittorrent  
**Gaming:** Steam, Epic Games Launcher, GOG Galaxy, Moonlight, Sunshine  
**Monitoring & Cleanup:** CPU‑Z, HWiNFO, Mem Reduct, BleachBit, DNS Jumper, CapFrameX, MSI Afterburner, RivaTuner Statistics Server, DLSS Swapper, Display Driver Uninstaller (DDU), HWMonitor  
**Productivity:** Nilesoft Shell, Flow Launcher, ShareX

> **Note:** Scoop is installed automatically the first time it's needed. Desktop shortcuts are created for Scoop‑installed apps where possible.

### 🧰 Utilities & Recovery
- Create System Restore Points.
- Restart to Safe Mode with Networking, UEFI firmware, or normally.
- Run DISM and SFC to repair system files.
- Flush DNS, release/renew IP, register DNS.
- Manage startup programs (enable/disable).
- Schedule automatic optimisations (daily, weekly, or custom).
- View system info (CPU, RAM, GPU, OS, disk type, battery health).

### 🧾 Profiles & Safety
- Predefined profiles: **Basic**, **Laptop**, **Gamer**, **Privacy**, **eSports**, **Maximum**.
- Export/import your own settings as JSON.
- Last‑run state is saved automatically (`%LOCALAPPDATA%\WGO\last-run.json`).
- **Dry‑run mode** – see what would be changed without applying anything.
- **Risky tweaks** (disable UAC, Defender, Firewall, etc.) are clearly marked and require explicit confirmation.
- Restore defaults per category: **All**, **Privacy**, **Network**, **Services**, **Visual**, or **AMD**.

---

## 📋 Requirements

- Windows 10 / 11 (64‑bit recommended)
- PowerShell 5.1 or later (built‑in)
- Administrator privileges (auto‑requested)

---

## 🛡️ Safety First

- A **System Restore Point** is created automatically before any change.
- All actions are logged in real‑time.
- You can revert changes with the **Restore Defaults** button.

---

## 📄 License

MIT – see the [LICENSE](LICENSE) file.

---

**Enjoy a cleaner, faster, and more private Windows!**
