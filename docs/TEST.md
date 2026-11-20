# V1.0 acceptance checklist - Windows

**Status:** PREPARED, NOT COMPLETED on Windows in this session. Never run these tests on a live broadcast.

## Source/static checks

- [ ] Python source/version/privacy tests pass on the exact commit.
- [ ] `tests/schedule_cases.ahk` runs in AutoHotkey v2 with success.
- [ ] `tests/first_run_schedule_cases.ahk` runs with success.
- [ ] Windows GUI renders correctly at 640x640, maximized, and at 125% DPI.
- [ ] Change UI language among IT, EN, ES, FR without disappearing labels. Advanced dialogs and logs must be recorded as translation limitations.

## Initial setup, schedules, actions

- [ ] Clean install: starts PAUSED with **zero** schedules and no unsafe implicit SEND.
- [ ] Missing/empty button coordinates can be saved, but clicking them is blocked.
- [ ] Defaults: OPEN -> LOGIN -> STOP x3 -> SEND and SEND -> NEXT -> CLOSE.
- [ ] Recurring days, extra dates, overnight intervals and overlap rejection work; no duplicate start for an extra date already covered by weekdays.
- [ ] Saved schedules/coordinates survive an update; rollback from a backup is possible.

## Worker and real-window safety

- [ ] A successful START opens CasterLive DJ and clicks the intended controls.
- [ ] A CLOSE scheduled after START correctly toggles SEND, presses NEXT, and closes the window.
- [ ] Repeat with GUI hidden, then Caster minimized to taskbar/tray.
- [ ] Repeat after moving the Caster window on screen and on another monitor, without resizing.
- [ ] A Caster window with invalid 0x0 client geometry produces an error **without desktop clicks**.
- [ ] A resized window or wrong HWND fails closed rather than clicking in the wrong application.
- [ ] Session state is kept across Worker restart; a close/error never causes blind SEND retries.
- [ ] Startup shortcut is updated to the V1.0 source entry point or the compiled GUI EXE.
- [ ] Both GUI and Worker stop correctly; no duplicate old process exists.

## Distribution acceptance

- [ ] The Windows compiler actually produced the GUI and Worker EXEs.
- [ ] The EXE pair works on a clean Windows 10/11 system without a separate AutoHotkey installation.
- [ ] The ZIP contains third-party license notices and no private INI/log.
- [ ] The EXE checksum, tag, commit and VERSION agree.
- [ ] No stable GitHub release is advertised before these checks are signed off.

**Evidence to record:** date, Windows version/DPI, AutoHotkey version, CasterLive DJ version, exact commit, logs with sensitive data redacted, and pass/fail per scenario.
