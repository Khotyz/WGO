# WGO 7.0 — Changelog

**Date:** 2026-11-25  
**Focus:** Conservative presets, optional-data privacy controls, reversible policy changes, and system-wide memory visibility.

## Highlights

- Reworked all existing presets around a conservative privacy and background-activity baseline, without adding new profiles.
- Made **Maximum Optimization** a union of reviewed preset options rather than a select-everything action.
- Kept clipboard-history disabling and stronger Edge restrictions out of ordinary presets; **Max selects both**.
- Preserved required diagnostic data in the general privacy action instead of forcing diagnostics off.
- Added per-value backup and rollback coverage for **20 settings** managed by the reviewed policy helper.
- Added before-and-after logging of whole-system physical memory usage.

## Added

### Reversible privacy controls

- Added the documented per-user policy for disabling tailored experiences based on diagnostic data.
- Added the documented policy for preventing typing and inking samples from being sent for product improvement, without disabling local personalization or dictation settings.
- Integrated two additional controls into the existing general privacy option:
  - `AllowDeviceNameInTelemetry=0`: prevents the computer name from being included in diagnostic data on supported editions and builds.
  - `DoNotShowFeedbackNotifications=1`: suppresses automatic feedback questions without disabling Feedback Hub or other application notifications. This setting is reintroduced from the older implementation as an independently reversible policy.
- Added baseline preservation, registry readback, idempotent application, and independent rollback through `Invoke-WgoOptionalPrivacyPolicy`.
- Added explicit dry-run and `WhatIf` support to the helper, including rollback previews.

### Memory visibility and validation

- Added `Get-WgoMemorySnapshot` to report physical memory used and available across the entire system, not just the WGO process.
- Added portable static contract tests and isolated PowerShell tests for preset selection, policy application, rollback, failure handling, and memory metrics.
- Added detailed privacy and services-policy review documents with sources, applicability limits, and recovery guidance.

## Changed

### Presets and selection behavior

- **Basic:** conservative privacy and background-activity baseline; now also used at UI startup.
- **Laptop:** retains battery-oriented indexing controls without forcing high-performance power settings or disabling hibernation.
- **Gamer:** retains visual responsiveness and storage maintenance without automatic kernel, timer, or GPU overrides.
- **Privacy:** adds Spotlight restrictions to the common privacy baseline.
- **Esports:** retains interface responsiveness without automatic timer or core-parking changes.
- **Max:** combines reviewed preset options and explicitly selects clipboard-history disabling and stronger Edge restrictions.
- Replaced broad **Select All** behavior with selection of reviewed options only.
- Applying a preset now clears previously selected advanced and risky actions rather than allowing them to carry over.
- Presets respect disabled controls, unsupported options, and the skip-already-applied preference.
- Advanced actions outside the reviewed baseline now require confirmation before real execution.
- Profile imports accept only known optimization controls and actual JSON boolean values.

### Privacy and background activity

- The general privacy action now sets `AllowTelemetry=1` and limits activity sharing instead of disabling WER, compatibility features, location, sensors, or diagnostic tasks.
- Advertising-ID changes are limited to the existing per-user preference.
- Input privacy no longer changes local typing personalization or contact-harvesting preferences.
- Edge startup boost and background mode use the reviewed backup/rollback helper.
- Widgets and Windows 10 News and interests use their documented policies on supported editions and builds, rather than relying only on hiding the taskbar icon.
- Battery indexing pauses indexing while on battery without disabling removable-drive indexing; desktops without a battery are left unchanged by that action.
- Scheduled Basic execution now applies only its machine-wide subset, avoiding interactive-user HKCU changes, cache purges, and file cleanup.

## Fixed

- Corrected Edge's `ExperimentationAndConfigurationServiceControl` from `2` to `1`: compatibility configuration downloads remain allowed, while experiments are restricted.
- Removed obsolete Edge policy writes from the stronger restriction set, without guessing replacement policies.
- Stronger Edge restrictions no longer overwrite password-manager settings or remove password-related policy values.
- Clipboard-history disabling now uses the documented history and cross-device synchronization policies.
- Prevented broad legacy restore operations from deleting entire registry keys containing tracked policy baselines.
- Updated scanner checks to match the revised setters and their build-specific requirements.
- Removed an unrelated Game DVR policy reset from general optimization execution.

## Safety and Compatibility

- Removed automatic preset selection of standby-list purges, recurring memory-cleanup tasks, large-system-cache tweaks, fixed pagefiles, Prefetch disabling, broad service changes, destructive cleanup, and hardware-specific overrides.
- No new automatic service-disable list was added. Existing manual actions remain available; this does not make them universally safe or recommended.
- Windows policy application uses conservative edition/build checks. Unsupported or unverified combinations are skipped rather than forced.
- Local registry values may be overridden by Group Policy or Intune. Registry readback does not prove effective policy or browser support.
- Updated user-facing descriptions in **English, Brazilian Portuguese, Spanish, and Simplified Chinese**. All four language files retain matching keys and formatting placeholders.
- New code comments are written in English.

## Upgrade Notes and Known Limitations

- Applying a revised preset **does not undo changes made by older WGO versions**. Existing service changes, scheduled cleanup tasks, removed applications, and deleted data require separate review.
- Precise rollback covers the 20 settings managed by the reviewed helper, not every legacy WGO action. Preserve the saved baselines and prefer per-item rollback when possible.
- Disabling device-name reporting can remove names from organizational update reports. Review managed-device requirements before applying it.
- Restricting Widgets, background extensions, activity sharing, or online suggestions changes those features by design; review the option descriptions before applying a preset.
- This release does **not** promise zero telemetry, a fixed RAM reduction, or universal performance improvements. Immediate memory samples are not a benchmark.