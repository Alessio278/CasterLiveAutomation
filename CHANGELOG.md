# Changelog

Significant project changes. Public versions use two components (`1.0`, `1.1`, `2.0`), independently of the original internal script and Worker protocol names.

## [1.0] - Prepared 2026-11-19 (Windows acceptance pending)

- Added original simplified branding assets (horizontal logo, square PNG, multi-size Windows ICO), used in the GUI title, tray, README, and Windows build configuration.

- Consolidated the prior 0.5 public pre-release into a candidate V1.0 repository.
- Updated project attribution to `Created by @Alessio278`.
- Simplified the source entry point to `CasterLiveAutomation.ahk` while retaining legacy settings/schedule names and non-destructive migration.
- Kept the multiple-schedule, window-safe click and session logic; the Worker handshake protocol is now `1.0`.
- Added four-language README documentation, source privacy checks, the three continuity documents, Windows build tooling and release checklist.
- Planned a two-executable Windows distribution, pending compilation and manual acceptance tests.

## [0.5] - Historical pre-release (2026-11-11)

- Multiple non-overlapping schedules, overnight dates, action sequences and safe first run.
- Window-recovery safeguards with fail-closed click validation.
- Dark AutoHotkey GUI with four selectable languages and activity diagnostics.

## Historical context

The V3.11 scheduler was the basis for the first proven start/close cycles. Subsequent internal V5 changes added multiple schedules and safe window handling; results from earlier versions cannot prove V1.0 Windows compatibility.
