# Troubleshooting

## A schedule does not start

Check **Pause/Resume**, at least one enabled schedule, the correct real date/day and time, an available CasterLive DJ executable path, and valid coordinates for every CLICK action. Open **Activity and diagnostics** to identify the decision the Worker logged. The panel must have launched its Worker, but can itself be minimized.

## START works; CLOSE does not

Inspect `CasterLiveAutomation_Log.txt` locally. Look for `TRIGGER CLOSE`, `RIPRISTINO`, and `CLIC BLOCCATO`. The close event will be skipped if no successful scheduled START was recorded or if the session state is uncertain. **Do not blindly reset runtime state or repeat SEND.** Check the actual streaming state manually.

A `client 0x0` or unexpected HWND in the log indicates that Windows reported a window without a usable internal area. The defensive click mechanism should stop rather than click the desktop. Recheck the main window and its calibration.

## Buttons click in the wrong place

Use the calibration tool to record the coordinates again. Keep window dimensions stable, check DPI/display scaling, and avoid moving/overlapping other windows while the sequence is executing. Never disable the click-safety checks to force completion.

## Only tests work but the schedule does not

Confirm that the automation is not paused; that the Worker heartbeat is current; that the date/day, start time and exceptional dates were saved; and that a previous failed session is not blocking retries by design. The Worker performs scheduled checks independently of panel visibility.

## The UI looks blank or glitches after changing language

Use the latest source release, switch back to Italian, and try resizing the panel. This may be related to native Windows theme rendering/DPI. Report Windows version, AutoHotkey v2 version and screen scaling, without uploading settings files.

## How to file a useful issue

Provide the product version, Windows version, AutoHotkey version, reproduction steps, expected behavior, observed behavior, and **redacted** relevant log lines. Never attach the local settings, schedules, runtime INI or full unredacted logs.
