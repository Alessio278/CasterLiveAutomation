# Changelog

All notable changes are documented here. Public product version: **CasterLiveAutomation 0.5 — Pre-release**. Historical internal build versions are preserved in the development-history document.

## [0.5.0-rc.1] — First public pre-release (2026-11-11)

### Features

- Multiple non-overlapping schedules with recurring days, exceptional dates, and overnight sessions.
- START and CLOSE action sequence editor (`open`, `click`, `wait`, `close`).
- Default labels with optional, initially empty, button coordinates.
- Safe first run: paused; no preset schedules.
- Persisted session state and close-after-successful-start logic.
- Dark, resizable interface with Italian, English, French and Spanish options.
- Diagnostic activity log, status display, and Windows tray support.

### Defensive improvements

- Window-aware click geometry and checks before interaction.
- Remember the CasterLive DJ window selected during successful START and use it for CLOSE when possible.
- Recover minimized windows conservatively; refuse clicks if window/client validation fails.
- Unified all project filenames under `CasterLiveAutomation` with legacy settings migration.

### Known limitations

- The latest minimized-window close recovery is **not yet verified** by a complete end-to-end Windows test.
- Interface localization is partial; some advanced strings and logs remain Italian.
- All schedules share the same target application and START/CLOSE sequences.
- Requires a signed-in, unlocked interactive Windows desktop.
- No standalone compiled Windows `.exe` is provided.

The historical `V5` filenames and the Worker protocol value `5.0` remain for compatibility; neither denotes public version 5.0.

For prior pre-public development history, see [Development history](docs/DEVELOPMENT_HISTORY.md).
