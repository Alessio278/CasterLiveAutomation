# Contributing to CasterLiveAutomation

Thanks for helping improve the project. The codebase uses **AutoHotkey v2** and is currently published as a preview, so stability and safety come before additional features.

## Before submitting changes

1. Search existing issues; open a feature request or bug report when a change affects scheduling or `SEND` behavior.
2. Work in a feature branch, then submit a pull request describing what changed and why.
3. Separate GUI translation changes from Worker and scheduling changes whenever possible.
4. Keep all personal files out of the repository. Never commit `*_Settings.ini`, `*_Schedules.ini`, `*_Runtime.ini`, logs or recordings of credentials.
5. Record the **test level**: static checks only, AHK calendar tests on Windows, or a complete GUI START/CLOSE cycle.

## Tests

Run the Python static checks (Python 3):

```bash
python tests/check_sources.py
python tests/test_language_ui_regression.py
python tests/test_naming_migration.py
python tests/test_window_recovery_static.py
python tests/test_repository_safety.py
```

On Windows with AutoHotkey v2, run:

```text
tests/schedule_cases.ahk
tests/first_run_schedule_cases.ahk
```

For changes to the Worker or click safety, complete the [manual test plan](docs/TEST.md) against a **non-live** CasterLive DJ session. GitHub Actions static checks are not equivalent to a Windows integration test.

## Safety rules

- Never make SEND retry automatically when the previous result is uncertain: a second click may stop a broadcast.
- Treat minimized windows, alternate monitors, DPI changes and hidden/secondary windows as safety-critical cases.
- Fail closed when the clicked window or recorded button geometry cannot be verified.
- Do not use hard-coded machine paths or user data; keep local state in ignored INI files.

## Review and licensing

By proposing changes, you agree that contributions accepted into this repository can be published under its [MIT License](LICENSE). Keep copyright notices for third-party code and disclose new dependencies and their licenses.
