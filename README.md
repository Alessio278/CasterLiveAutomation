# CasterLiveAutomation

**Windows automation for CasterLive DJ, built with AutoHotkey v2.**

[Italiano](README.it.md) · [Installation](docs/INSTALLATION.md) · [Features](#features) · [Safety](docs/CLICK_SAFETY.md) · [Contributing](CONTRIBUTING.md)

![Version](https://img.shields.io/badge/version-0.5.0--rc.1-orange)
![Windows](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-555555)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2-555555)
![License](https://img.shields.io/badge/license-MIT-success)
![Release status](https://img.shields.io/badge/status-pre--release-orange)

CasterLiveAutomation helps automate the opening and closing of **CasterLive DJ** at scheduled times. Set up non-overlapping schedules, assign button coordinates, customize action sequences, and review diagnostic logs from a compact dark interface.

**Version 0.5 — Pre-release (`v0.5.0-rc.1`).** Created by Alessio Natalucci. This is an independent community project, **not affiliated with the developers of CasterLive DJ**. The third-party CasterLive DJ application is not included.

> [!WARNING]
> **Pre-release v0.5 — not yet certified for unattended broadcasting.** The most recent minimized-window CLOSE recovery has not been verified in a complete Windows end-to-end test. Run the [manual test plan](docs/TEST.md) with SEND off and a person present before using it for a live broadcast. A green status indicates that the automation is configured, *not* that audio is on air.

## Features

- **Multiple schedules:** enable several non-overlapping schedules with recurring weekdays, one-off dates, a start time, and an end time.
- **Overnight sessions:** a Friday 23:00 start can close on Saturday at 02:00; the selected date/day always means the *start* day.
- **Editable actions:** `OPEN`, `CLICK`, `WAIT`, and `CLOSE`. Assign a label to each click, including repetition counts and delays.
- **13 configurable button labels**, initially without coordinates: `LOGIN`, `MUTE_MASTER`, `NEXT`, `PLAY`, `STOP`, `RESTART`, `SEND`, `RECEIVE`, `MONITOR`, `MONITOR_MIC`, `MONITOR_AUDIO`, `SETTINGS`, `ENTER`.
- **Window-aware clicks:** recompute button positions after a window moves; attempt to restore minimized windows; abort rather than click if target geometry is unsafe.
- **Session safety:** CLOSE is linked to a successful scheduled START; duplicate or uncertain SEND interactions are blocked.
- **Dark interface and diagnostics:** a 640 × 640 resizable panel, tray support, and a log with troubleshooting information.
- **Four interface languages:** Italian, English, French, and Spanish (some advanced messages and logs remain Italian).
- **Safe first run:** starts **PAUSED** with **zero schedules**. Resume explicitly after configuring the application and calibrating the required buttons.

All schedules currently share **one configured target application and the same two sequences**. Per-schedule applications and action sequences are not supported.

## Quick start

1. Install [AutoHotkey v2](https://www.autohotkey.com/) on Windows 10 or 11, and install CasterLive DJ separately.
2. Download the **v0.5 pre-release source ZIP** from this project's Releases page, or clone/download this repository. Keep the three `.ahk` files together.
3. Extract to a writable directory, e.g. `Documents\CasterLiveAutomation`.
4. Double-click **`CasterLiveAutomation_V5.ahk`**.
5. In **Schedules**, select the CasterLive DJ executable and add an enabled schedule. New installs start with **zero** schedules.
6. In **Buttons**, calibrate the buttons actually used by START and CLOSE. Unused labels can remain unconfigured.
7. Check the sequences. Default START: `OPEN → LOGIN → STOP ×3 → SEND`. Default CLOSE: `SEND → NEXT → CLOSE`.
8. Click **Resume automation** only after validation. Test START and CLOSE with Windows unlocked and no broadcast running.

Detailed instructions: **[Installation and setup](docs/INSTALLATION.md)** · [Guida italiana](docs/INSTALLAZIONE_IT.md).

## Scheduling example

| Schedule | Recurrence | Start | Close |
|---|---|---|---|
| Weekend radio | Saturday, Sunday | 00:01 | 02:00, same day |
| Evening broadcast | Friday | 23:00 | 02:00, next day |
| New Year's Eve | December 31, 2026 | 23:00 | 02:00 on January 1, 2027 |

These are **examples only**. They are not automatically installed or activated. Conflicting active schedules are rejected; consecutive schedules that share a boundary are allowed but need a real-world margin for the button sequence to finish.

## Safety and limitations

CasterLiveAutomation interacts with visible Windows GUI elements, not with a streaming API. It **cannot determine whether audio is actually live** and must not be treated as a broadcast continuity guarantee.

- The PC must be awake, the user session signed in, and Windows **unlocked** while clicks run.
- Minimized and moved windows are supported by defensive checks, but resizing or changes in the target UI can invalidate calibration.
- The application will stop on uncertain window targets or session states instead of guessing or repeatedly pressing SEND.
- Keep only **one copy of the automation** running against the same CasterLive DJ instance.
- Configuration, schedules, runtime state and logs are **local/private**, not to be submitted to GitHub.

Read [Click safety](docs/CLICK_SAFETY.md), [Architecture](docs/ARCHITECTURE.md), and [Known limitations](docs/KNOWN_LIMITATIONS.md).

## Repository structure

```text
CasterLiveAutomation_V5.ahk             # interface / schedule editor
CasterLiveAutomation_Worker.ahk         # independent scheduler and click executor
CasterLiveAutomation_ScheduleLib.ahk    # schedule validation and persistence
tests/                                  # Python static checks and AHK calendar tests
docs/                                   # installation, testing and architecture
.github/                                # GitHub issues, PR template and static CI
README.it.md                            # documentation in Italian
LICENSE                                 # MIT
```

Note: the entrypoint filename retains `_V5.ahk` for compatibility with existing Windows startup shortcuts. The publicly distributed software version is **0.5**, not 5.0. The internal Worker protocol string `5.0` is retained for backward compatibility.

The following user files are created **locally** and intentionally excluded from the repository:

`CasterLiveAutomation_Settings.ini`, `CasterLiveAutomation_Schedules.ini`, `CasterLiveAutomation_Runtime.ini`, and `CasterLiveAutomation_Log.txt`.

## Development and contributions

Static source checks run on GitHub Actions. **They do not execute AutoHotkey on Windows or verify actual GUI clicks.** Calendar tests are provided in `tests/` and need AutoHotkey v2 on Windows.

See [CONTRIBUTING.md](CONTRIBUTING.md) for issues and pull requests and [SECURITY.md](SECURITY.md) for confidential reports. The current release details are in [CHANGELOG.md](CHANGELOG.md).

## License and attribution

Copyright © 2026 **Alessio Natalucci**. Source code is available under the [MIT License](LICENSE).

CasterLive DJ is third-party software and is **not bundled, redistributed, or licensed** by this repository.
