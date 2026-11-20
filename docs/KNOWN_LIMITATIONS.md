# Known limitations - 1.0 stable release

- Windows 10/11, interactive user session only; the machine must be awake and unlocked for GUI clicks.
- Does not verify whether audio is actually broadcasting. SEND is a toggle and must not be retried blindly.
- A wrong/changed CasterLive DJ UI, DPI setting, resized client area, overlay or permission mismatch can prevent safe clicks.
- Recovery of a minimized/tray-hidden Caster window has not been accepted in a full unattended Windows test for this V1.0.
- Windows startup is a shortcut for the signed-in user, **not a Windows service** and not guaranteed at power-off or while locked.
- A schedule has mandatory start **and** end times; optional end time and independent per-schedule applications/sequences are not implemented.
- The UI provides IT, EN, ES, FR but some advanced dialogs/log entries are still in Italian; full coverage is pending.
- Uses a GUI plus separate Worker; a Windows compiled distribution has **two** executables, not one single process/file.
- No built-in verification of application updates or CasterLive DJ API status.
- Static tests and calendar tests do not replace real CasterLive DJ interaction tests.
