"""Static regression checks for CasterLiveAutomation V5.0 (does not execute AutoHotkey)."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
gui = (root / "CasterLiveAutomation_V5.ahk").read_text(encoding="utf-8-sig")
worker = (root / "CasterLiveAutomation_Worker.ahk").read_text(encoding="utf-8-sig")

checks = {
    "first run paused": 'InitializeFirstRunPause()' in gui,
    "no default schedules": 'InitializeEmptySchedules()' in gui,
    "author byline": 'Creato da Alessio Natalucci' in gui,
    "4 language selection": all(
        language in gui for language in ('"Italiano"', '"English"', '"Français"', '"Español"')
    ),
    "language persistence": 'IniWrite(gLanguage, gCfg, "UI", "Language")' in gui,
    "window-relative point conversion": 'ClientToScreen' in worker,
    "cursor target validation": 'WCursorOverCaster' in worker,
    "recorded-size calibration": 'PointClientSize' in worker and 'PointClientSize' in gui,
    "client geometry validation": 'GetClientRect' in worker,
    "fail-closed click": 'CLIC BLOCCATO' in worker,
    "no alternative blind ControlClick": 'ControlClick(' not in worker,
}
for label, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {label}")
if not all(checks.values()):
    raise SystemExit(1)
print("Static checks passed. Run the AutoHotkey tests and manual safety tests on Windows.")
