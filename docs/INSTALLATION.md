# Installation - CasterLiveAutomation 1.0

## Source distribution (supported workflow for validation)

1. Install [AutoHotkey v2](https://www.autohotkey.com/) and CasterLive DJ independently.
2. Extract `CasterLiveAutomation.ahk`, `CasterLiveAutomation_Worker.ahk` and `CasterLiveAutomation_ScheduleLib.ahk` to the same **writable** folder (e.g. under Documents).
3. Double-click `CasterLiveAutomation.ahk`. No BAT, PowerShell launcher or admin rights should be required for ordinary execution.
4. On a clean first run the application is PAUSED and has zero schedules. Select the target executable, add a schedule and calibrate buttons used by the sequences.
5. Inspect default START `OPEN -> LOGIN -> STOP x3 -> SEND` and CLOSE `SEND -> NEXT -> CLOSE`. Do not repeatedly press SEND in manual tests.
6. Choose Resume only after a valid configuration, then perform a full supervised START/CLOSE cycle.
7. The user must be signed into Windows and the desktop must be unlocked. On exit or PC shutdown, **do not assume** missed events run later.

The GUI can create a Windows Startup shortcut; verify its target if the main file name changed from a prior release. Do not keep old V5 or V3 processes running.

## Binary distribution

Run `scripts/Build-Windows.ps1` **on Windows** with AutoHotkey v2 and Ahk2Exe installed. It is designed to produce a ZIP with `CasterLiveAutomation-1.0.exe` and `CasterLiveAutomation-Worker.exe`; both EXEs are required in the same writable folder. The current deliverable does **not** include a tested binary. See [Windows build](WINDOWS_BUILD.md).

## Existing installations

Copy the configuration files only after backing up all INI and logs and confirming Caster is not broadcasting. The shared configuration schema is preserved, but an old V5 worker process is incompatible with the new WorkerVersion and must be terminated. See [migration](MIGRATION.md).
