# Installation and setup (Windows)

## Requirements

- Windows 10 or 11, with an interactive, unlocked desktop.
- **AutoHotkey v2** (not v1), from https://www.autohotkey.com/.
- CasterLive DJ installed separately. This repository does not include it.
- A writable directory in your own user profile.

## Install

1. Download the source preview ZIP from **GitHub Releases**, or use **Code → Download ZIP** for the whole repository.
2. Extract the ZIP to a new writable folder, such as `Documents\CasterLiveAutomation`. Do not run scripts directly inside a ZIP.
3. Keep `CasterLiveAutomation_V5.ahk`, `CasterLiveAutomation_Worker.ahk`, and `CasterLiveAutomation_ScheduleLib.ahk` **in the same directory**.
4. Double-click `CasterLiveAutomation_V5.ahk`. If Windows asks which application to use, choose **AutoHotkey v2**.
5. The panel begins **PAUSED** and the schedules list is empty on first use.
6. Configure the CasterLive DJ executable path (`CasterLive DJ.exe`), add and enable a schedule, and register the coordinates of used buttons.
7. Check the shared action sequences before enabling automation. Default START is `OPEN → LOGIN → STOP ×3 → SEND`. Default CLOSE is `SEND → NEXT → CLOSE`.
8. Use **Resume automation** only when every required click is configured and CasterLive DJ is not already sending audio.

## Basic schedule example

To automate Saturday 00:01 to 02:00, choose Saturday, Start `00:01`, End `02:00`. For a Friday evening show from `23:00` to `02:00`, choose Friday; CLOSE will run Saturday morning.

## Before going live

Run the manual tests in [TEST.md](TEST.md). Minimize and move the target window between START and CLOSE and confirm both the actions and the logs. Window geometry validation is designed to stop unsafe clicks, not to make every GUI layout reliably automatable.

## Automatic start on Windows

The panel can create an entry in the Windows Startup folder. This starts after user sign-in, **not on a locked desktop before sign-in**. Do not allow a second installation of the automation to run concurrently against the same CasterLive DJ process. Close older versions and remove their Startup links as appropriate.

## Upgrading

- Exit both the panel and the Worker. Verify SEND manually and close CasterLive DJ before replacing files.
- **Back up** the entire existing folder and INI files before upgrading.
- Replace the three `.ahk` source files; keep your existing `CasterLiveAutomation_*.ini` files unless deliberately resetting to first-run state.
- Legacy file name migration is documented in [MIGRATION.md](MIGRATION.md).

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md). For privacy, redact paths, dates and other personal details before reporting bugs.
