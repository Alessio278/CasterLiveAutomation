# Changelog

Significant project changes. Public versions use two components (`1.0`, `1.1`, `2.0`), independently of the original internal script and Worker protocol names.

## [1.0] - Stable version (designated 2026-11-20)

- Added original simplified branding assets (horizontal logo, square PNG, multi-size Windows ICO), used in the GUI title, tray, README, and Windows build configuration.

- Consolidated the prior 0.5 public pre-release into the definitive V1.0 source version.
- Updated project attribution to `Created by @Alessio278`.
- Simplified the source entry point to `CasterLiveAutomation.ahk` while retaining legacy settings/schedule names and non-destructive migration.
- Kept the multiple-schedule, window-safe click and session logic; the Worker handshake protocol is now `1.0`.
- Added four-language README documentation, source privacy checks, Windows build tooling, an automatic stable-release workflow and release checklist.
- Configured automatic stable GitHub releases with two Windows executables, pending a successful Windows CI run for the publishing commit. The CI build does not certify real CasterLive DJ integration.
- Version 1.0 is the first stable version; optional updates may follow.

## [0.5] - Historical pre-release (2026-11-11)

- Multiple non-overlapping schedules, overnight dates, action sequences and safe first run.
- Window-recovery safeguards with fail-closed click validation.
- Dark AutoHotkey GUI with four selectable languages and activity diagnostics.

## Historical context

The V3.11 scheduler was the basis for the first proven start/close cycles. Subsequent internal V5 changes added multiple schedules and safe window handling; results from earlier versions cannot prove V1.0 Windows compatibility.
