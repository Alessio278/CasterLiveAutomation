# Security and privacy

CasterLiveAutomation controls a real broadcasting GUI. Bugs may unintentionally enable or disable transmission; this is an **operational safety risk**, even if no network vulnerability exists.

## Reporting a vulnerability

If the repository owner has enabled **GitHub private vulnerability reporting**, please use the repository's **Security → Report a vulnerability** interface. Do not publish exploit details or any credentials in a public Issue. If private reporting is not enabled, request a private contact method without disclosing sensitive details.

## Data you should not upload

- Personal `CasterLiveAutomation_Settings.ini` (local executable paths and button geometry)
- `CasterLiveAutomation_Schedules.ini` (broadcast times and dates)
- `CasterLiveAutomation_Runtime.ini` (session state, SEND attempt tokens)
- `CasterLiveAutomation_Log.txt` (window/process details and machine-specific data)
- Screenshots with credentials or private information

## Security model

- CasterLiveAutomation must not bypass login prompts or Windows session security.
- Windows must be unlocked for GUI clicks; a working Worker process does not imply the broadcast is live.
- Window-target validation and uncertainty guards are intentionally conservative.
- Back up local INI files before updating; do not clear an uncertain session without inspecting SEND manually.
