# Changelog

---

## [6.5] – 2026-10-23

Everything the 6.x line needed: bloatware removal that knows who installed each package, clipboard
history and keyboard timing as standalone switches, a Store path for Windows LTSC, classic Paint,
Photo Viewer and Notepad restored as opt-ins, AI/cloud policy blocks that work on any supported build,
an isolated Edge telemetry action and an audited Scoop catalog.

WGO targets Windows 10 and Windows 11. Nothing in this release is tied to a single build — every
policy is written through documented paths, and features that only exist on newer builds are simply
inert (and reported as such) everywhere else.

### Highlights

- **Bloatware removal checks provisioning and install time** before deleting anything, so a Store app
  you installed after setup (NanaZip, WhatsApp Desktop, …) is never removed.
- **Clipboard history is its own switch**, fully split from input personalization.
- **Keyboard repeat delay is standalone** and only enabled by *Maximum Optimization*.
- **Microsoft Store + App Installer on Windows LTSC / IoT Enterprise**, with a winget source reset.
- **Classic Paint (no Copilot), classic Photo Viewer and classic Notepad** as opt-in actions.
- **Edge telemetry removal is isolated** and no longer touches the built-in password manager.
- **Scoop catalog audited against the live manifests**, DDU removed, missing shortcuts now reported.
- All four languages (**en-US**, **pt-BR**, **es-ES**, **zh-CN**) ship the same key set.

---

## Added

### Smart bloatware removal

`Remove-WgoBloatware` is now intelligent about ownership and summarises what it did.

| Rule | Behaviour |
| --- | --- |
| Protected components | Skipped through `Test-WgoProtectedPackage` |
| `NonRemovable` packages | Skipped and logged as protected |
| Provisioned with the same version | Removed (genuine inbox bloat) |
| Provisioned but a different version is installed | Kept — a newer version means the Store updated it after the user opened it |
| Not provisioned at all | Kept when the signature is not `Store`/`System`, when the install folder is missing, when the Windows install date cannot be read, or when the folder is younger than two days |
| Ignore list | `Microsoft.Copilot`, `Microsoft.Windows.Ai.Copilot.Provider`, `MicrosoftWindows.Client.CoPilot`, `Microsoft.WindowsRecall`, `Microsoft.Windows.Recall` and `Microsoft.549981C3F5F10` skip the user-install check, mirroring Microsoft's own removal rule for those apps |
| Anything ambiguous | Kept — the rule fails **closed** |

- The old check relied on `InstallLocation` alone. Store packages installed per-user often report an
  empty `InstallLocation`, which made the date test inconclusive and the package removable. The
  comparison now also uses `%ProgramFiles%\WindowsApps\<PackageFullName>` and, above all, a
  provisioned-version table, so a package Windows never provisioned is always treated as
  user-installed.
- **14 new inbox targets**: `Microsoft.BingSearch`, `Microsoft.BingTranslator`, `Microsoft.BingTravel`,
  `Microsoft.BingHealthAndFitness`, `Microsoft.BingFoodAndDrink`, `Microsoft.Microsoft3DViewer`,
  `Microsoft.Print3D`, `Microsoft.MicrosoftJournal`, `Microsoft.GetHelp`, `Microsoft.Messaging`,
  `Microsoft.OneConnect`, `Microsoft.Office.Sway`, `Microsoft.Windows.DevHome`,
  `Microsoft.Windows.DevHomeGitHubExtension`, `MicrosoftCorporationII.MicrosoftFamily` and
  `MicrosoftWindows.CrossDevice`. The catalog now covers **54 inbox package patterns**.
- New log lines: `LogBloatRemoving` (one line per package right before it is deleted),
  `LogBloatSkippedUser`, `LogBloatSkippedProtected` and `LogBloatUserInstallSummary` (removed and
  preserved counts).
- New helpers, all exported and shared with the background runspace: `Test-WgoBloatwareMatch`,
  `Get-WgoOsInstallDate`, `Get-WgoProvisionedPackageNames`, `Get-WgoProvisionedPackageTable`,
  `Get-WgoPackageInstallTime` and `Test-WgoUserInstalledPackage`.

### Clipboard history as its own option

- New checkbox `chkClipboardHistory` in *Additional Telemetry Blocking*, backed by the
  `-ClipboardHistory` switch on `Set-WgoExtraPrivacy` (writes `EnableClipboardHistory=0` and
  `CloudClipboardAutomaticUpload=0`).
- `chkInputTelemetry` now covers input personalization only. Its label, tooltip and log line no longer
  mention the clipboard anywhere — the previous strings said “and clipboard cloud sync”, which made
  both options look like a single action. The clipboard is only described by its own label, tooltip
  and log line.
- Off by default and absent from Basic, Laptop, Gamer, eSports and Privacy. Only *Maximum
  Optimization* enables it, as a 100 % performance preset.
- New detector `chkClipboardHistory` and the `LogClipboardOk` message.

### Classic apps (opt-in)

New group **“Classic apps (opt-in)”** with three checkboxes and three functions:

- **Paint without Copilot** (`Set-WgoPaintWithoutCopilot -RemoveCopilot`) writes `DisableCocreator`,
  `DisableGenerativeFill` and `DisableImageCreator` under
  `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint`. When a Classic Paint layout exists
  at `%ProgramFiles%\Classic Apps\Microsoft Paint\Program\mspaint.exe` it also registers
  `App Paths\mspaint.exe` and a `Classic Paint.lnk` shortcut.
- **Classic Photo Viewer** (`Set-WgoClassicPhotoViewer -Register`) re-registers
  `HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations` for 13 image
  extensions, adds the `RegisteredApplications` entry, writes the per-extension `OpenWithProgids`
  values and warns when `PhotoViewer.dll` is missing.
- **Classic Notepad** (`Set-WgoClassicNotepad -Restore`) installs Microsoft's official
  `Microsoft.Windows.Notepad.System~~~~0.0.1.0` feature on demand, points
  `HKCU\...\App Paths\notepad.exe` at `%SystemRoot%\System32\notepad.exe`, disables the Store
  Notepad app execution alias (renamed to `notepad.exe.wgoalias`) and creates a *Notepad (classic)*
  shortcut. Restore defaults → Visual puts the alias back.
- All three stay outside every profile and outside *Select All*.
- New detectors `chkPaintNoCopilot`, `chkClassicPhotoViewer`, `chkClassicNotepad`, plus the
  `LogPaint*`, `LogPhotoViewer*` and `LogNotepad*` messages.

### Microsoft Store and App Installer for Windows LTSC

New **“Windows LTSC components”** group in the *App Installer* tab:

| Button | Action |
| --- | --- |
| `Install Microsoft Store` | `Install-WgoStoreApp` — tries `wsreset -i` first (up to five minutes), then falls back to `9WZDNCRFJBMP` from `msstore` and finally `Microsoft.WindowsStore` from `winget` |
| `Install App Installer (winget)` | `Install-WgoAppInstaller` — downloads `aka.ms/getwinget` with the VCLibs and `Microsoft.UI.Xaml.2.8` dependencies for the current architecture, installs them with `Add-AppxPackage`, then verifies that winget resolves |

- Both buttons finish by calling `Initialize-WgoWingetSources`, which resets the sources and re-adds
  `winget` (`https://cdn.winget.microsoft.com/cache`) and `msstore`
  (`https://storeedgefd.dsx.mp.microsoft.com/v9.0`) when they are missing, so winget is usable right
  after installation.
- `Test-WgoStorePresent` and `Get-WgoPackageArchitecture` support both flows; every step is logged.

### AI and cloud content blocks

New group **“AI and cloud content”** with three checkboxes, backed by `Set-WgoAiCloudPrivacy`. Both
the machine and the user policy scopes are written, so the blocks apply whether a build reads its
policies per machine or per user.

| Option | What it blocks | Registry values |
| --- | --- | --- |
| `Block the Settings AI agent, Click to Do and Recall/Copilot AI components` | Settings agentic search, Click to Do, Recall snapshots and export, Paint Cocreator / Generative Fill / Image Creator | `WindowsAI`: `DisableSettingsAgent=1`, `DisableClickToDo=1`, `DisableAIDataAnalysis=1`, `AllowRecallEnablement=0`, `DisableRecallDataProviders=1`, `AllowRecallExport=0`, `DisableCocreator=1`, `DisableGenerativeFill=1`, `DisableImageCreator=1` — mirrored to `HKCU` plus the Paint policy values |
| `Block AI agent connectors (MCP) and reset agent consent to 1 hour` | MCP agent connectors and long-lived agent consent (default is 30 days) | `WindowsAI`: `ConfigureAgentConnectors=2`, `DisableAgentConnectors=2`, `AgentConsentDuration=1` — machine and user scope |
| `Disable Get Started, Copilot pin screen and cloud suggestions` | Get Started app, Microsoft 365 Copilot pin screen, cloud optimized content, consumer account state content, desktop Spotlight collection, third-party suggestions and the Spotlight surfaces in Settings / notification center | `CloudContent` (machine and user scope) |

Notes:

- These policies cover the AI and cloud surfaces introduced through Windows updates (the newest
  Windows 11 feature update among them). Where a build does not implement a value, writing it is
  harmless and the scanner reports the correct state instead of pretending the option is missing.
- The Settings agent, agent connector and agent consent policies are documented by Microsoft for
  **Enterprise / Education / IoT Enterprise**. On Home and Pro the values are written but inert, so a
  machine later moved to a supported edition picks them up automatically.
- The blocks are part of **Basic**, **Laptop**, **Gamer**, **eSports** and **Privacy**, because the
  telemetry they stop is harmless to normal and gaming use. They can be cleared individually.
- Nothing in this group requires a reboot; a sign-out may be needed for shell surfaces.

### Scan and language coverage

- New scanner detectors `chkWin11AiAgentBlock`, `chkWin11AgentConnectors`, `chkWin11CloudContent` and
  `chkEdgeTelemetryIsolated` so badges and tooltips report the real state instead of staying blank.
- Detectors for the AI/cloud blocks use `Check-PolicyGroups`, which accepts either the machine or the
  user scope per value and only requires the documented values, so a fully applied machine reads
  **Applied** instead of *Partial*.
- New **`Update-WgoBatteryAvailability`** disables battery-only options on desktops.
- **25 new keys** in the original 6.5 batch plus the keys for every option added here, and the
  obsolete `ChkDisableEdgeTelemetry`, `TipDisableEdgeTelemetry`, `LogEdgeTelemetryOk` and
  `AppDduDesc` keys removed.
- New restore logic: **Restore defaults → Privacy** cleans the user-scope Windows AI and CloudContent
  policy keys, the Paint AI values, the clipboard values, the Photo Viewer registrations and the
  classic Paint entries; **Restore defaults → Visual** removes the classic Notepad registration and
  re-enables the Store Notepad alias.

---

## Changed

### Keyboard repeat delay is standalone

- `chkKeyboardFast` was removed from **Basic**, **Laptop**, **Gamer** and **eSports**, so profile
  presets no longer touch typing timing.
- *Maximum Optimization* enables it after applying the preset, together with the clipboard option.
- The tooltip in all four languages explains that a zero repeat delay only shortens typing latency and
  increases the chance of duplicated words.

### Battery-only option

- `chkIndexerThrottle` is battery-scoped: the scanner reports `NotApplicable` (`NoBattery`) on a
  desktop, the checkbox is disabled and cleared, and `Set-WgoSystemTuning` skips
  `PreventIndexingOnBattery` while still disabling indexing on removable drives. New
  `LogIndexerThrottleNoBattery` message and `ScanReasonNoBattery` label.
- Battery detection is stricter: virtual/UPS battery objects are ignored, and the laptop flag now
  requires a laptop chassis *and* a battery, or a battery on a non-desktop chassis.
- `Get-WgoSystemInfo` hides UPS devices from the battery line.

### Microsoft Edge telemetry is now isolated (and safe for saved passwords)

**Problem in 6.0:** Edge telemetry removal lived inside the `Set-WgoExtraTweaks2` batch and wrote an
obsolete `ConfigureTelemetryForDesktop` value. In practice the action removed more than telemetry and
the browser ended up with its **native password manager disabled** — saved credentials stopped being
offered.

**What changed:**

- New dedicated function `Set-WgoEdgeTelemetryIsolation` and a dedicated UI group
  **“Microsoft Edge (isolated)”**. `Set-WgoExtraTweaks2` lost its `-DisableEdgeTelemetry` parameter.
- Only telemetry-scoped policies are written: `MetricsReportingEnabled=0`,
  `SendSiteInfoToImproveServices=0`, `PersonalizationReportingEnabled=0`,
  `ExperimentationAndConfigurationServiceControl=2`, `UserFeedbackAllowed=0`, `SearchSuggestEnabled=0`,
  `EdgeFollowEnabled=0`, `WebWidgetAllowed=0`.
- `PasswordManagerEnabled=1` is written and **verified after applying**, `DisableSavedPasswords` is
  deleted, and a warning is logged if the read-back does not confirm it.
- The action is opt-in and the scanner reports it as applied only when telemetry is off **and**
  `PasswordManagerEnabled=1`.

### winget install chain: Microsoft Store first

App installation now walks three sources instead of two:

| Stage | Source | Details |
| --- | --- | --- |
| 1 | `msstore` | Only when `winget source list` reports it. Uses the entry's `StoreId` when declared, otherwise the `WingetId`. 600 s timeout. |
| 2 | `winget` | Unchanged behaviour with an explicit `--source winget`. 1200 s timeout. |
| 3 | Scoop | Unchanged, plus the catalog guard below. |

- New `Test-WgoWingetSource` caches `winget source list` per session.
- New `Install-ViaWingetSource` performs a single install against one explicit source and reports the
  real failure detail (`Get-WgoLastLogLine`) instead of a bare exit code.
- `Install-ViaWinget` orchestrates the two winget stages and accepts an optional `-StoreId`;
  `Install-WgoApp` passes `$entry.StoreId` down automatically.
- New log keys `LogTryingMsStore`, `LogMsStoreFallback` and `LogWingetSourceFailed` make the origin of
  every install visible.

### Scoop catalog audit

Every `ScoopId` was checked against the live `main`, `extras` and `games` buckets (manifest present,
`bin` shim declared, `installer` script absent).

| App | Scoop fallback | Reason |
| --- | --- | --- |
| Free Download Manager | Removed (winget only) | No `bin` shim |
| Epic Games Launcher | Removed (winget only) | No `bin` shim, no Scoop shortcuts |
| GOG Galaxy | Removed (winget only) | `installer` script + no `bin` shim |
| HWiNFO | Removed (winget only) | `installer` script |
| Flow Launcher | Removed (winget only) | No `bin` shim |
| DLSS Swapper | Removed (winget only) | No `bin` shim |
| Display Driver Uninstaller (DDU) | **Removed from WGO** | No winget package and no reliable Scoop shim |
| Remaining 20 apps | Unchanged | Shim present and no `installer` script |

- `Install-WgoApp` skips the Scoop stage when an entry has no `ScoopId` and logs
  `LogScoopFallbackRemoved`.
- `New-WgoScoopAppShortcut` logs `LogShortcutSkipped` when no executable can be resolved.
- The DDU card, checkbox handler and `AppDduDesc` label were removed from the UI and all languages.

### Tests

- `tests/Test-WgoCatalog.ps1` reports Scoop-backed versus winget-only entries, validates that
  winget-only entries declare no bucket, skips empty `ScoopId` values and enforces the audit rule on
  every Scoop-backed entry.
- `tests/Test-WgoScanner.ps1` covers the new detectors, the battery `NotApplicable` path, the classic
  apps and — in section **G** — the ownership rules: a Store app that is not provisioned (NanaZip,
  WhatsApp Desktop) is preserved, an inbox package on the provisioned version is removable, and an
  updated inbox package or a missing install date is treated as user-installed.
- `tests/Test-WgoStatic.ps1` accepts empty `ScoopId` entries during bucket validation while still
  failing on a non-empty `ScoopId` with an invalid bucket.

---

## Fixed

- **Store apps installed by the user were removed by the bloatware pass** — fixed by the ownership
  rules above.
- **Clipboard history looked like part of the input-personalization option** — the strings still
  mentioned the clipboard in all four languages; the clipboard now appears only in its own option.
- **AI/cloud options never showed as applied** — the probes only looked at `HKLM` and demanded values
  that not every build exposes; they now accept either scope and the documented values only.
- **Battery option did nothing on desktops but still appeared as pending** — it is now reported as not
  applicable and skipped.
- **Edge password manager disabled after running Edge telemetry removal** — fixed by the isolated
  implementation; the policy is re-asserted and verified.
- **`Restore defaults` did not fully undo Edge, AI/cloud and classic-app changes** — restore now
  clears the matching machine and user keys and re-enables the Store Notepad alias.
- **Options silently misaligned in the background task** — parameter and argument lists are extended
  in lockstep (99 / 99) to keep positional binding correct.
- **Dry-run did not list the new actions** — the summary now reports the isolated Edge action, the
  AI/cloud blocks and the classic-app options.
- **Dead option name in profiles and UI lists** — `chkDisableEdgeTelemetry` was replaced everywhere.
- **Scoop shortcut failures were invisible** — they are now logged as warnings.

---

## Upgrade notes

- **Profiles changed**: *Basic*, *Laptop*, *Gamer* and *eSports* now enable the AI/cloud blocks and no
  longer touch the keyboard tweak. *Maximum Optimization* still enables the keyboard tweak and also
  the clipboard option — uncheck it after applying if you rely on `Win+V`.
- **Clipboard history is off by default** everywhere except *Maximum Optimization*.
- Existing users of the old Edge telemetry checkbox should tick **“Remove Edge telemetry only (keeps
  the built-in password manager)”**; if a previous release left Edge with the password manager
  disabled, run **Restore defaults → Privacy** and re-apply.
- Profile exports created before 6.5 that reference `chkDisableEdgeTelemetry` or `chkDdu` load with
  those entries ignored.
- Translators: obsolete keys were removed, new ones added, and the en-US file is the reference set.

## Verification performed

- Static validation: every control referenced from `$c[...]` exists in `MainWindow.xaml`, all 89
  optimization checkboxes exist in the XAML, in `WgoUI_OptimizationCheckboxNames` and have a `Chk*`
  label, and no profile references an unknown checkbox.
- Run handler: **99 parameters / 99 arguments**, verified position by position.
- Scanner: **84 detectors**, no orphan detector, every `New-Status` reason has a `ScanReason*` key.
- Languages: en-US, pt-BR, es-ES and zh-CN all carry the same **716 keys**; every literal `T '...'`
  key and every `$t.*` binding resolves.
- Background runspace: all new functions are exported and listed in `WgoSharedFunctionNames`, and none
  of them calls a function outside that list.
- Catalog cross-check against `ScoopInstaller/Main`, `ScoopInstaller/Extras` and
  `ScoopInstaller/Games` (`master`): 26 entries audited (20 Scoop-backed, 6 winget-only).