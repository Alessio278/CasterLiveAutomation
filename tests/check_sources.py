"""Static behavioral contracts for the V1.0 source. Does NOT run Windows GUI."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
main = (r/'CasterLiveAutomation.ahk').read_text(encoding='utf-8-sig')
w = (r/'CasterLiveAutomation_Worker.ahk').read_text(encoding='utf-8-sig')
lib = (r/'CasterLiveAutomation_ScheduleLib.ahk').read_text(encoding='utf-8-sig')
checks = {
  'version': (r/'VERSION').read_text().strip() == '1.0',
  'author credit': 'Created by @Alessio278' in main,
  'four languages': all(x in main for x in ['"Italiano"','"English"','"Español"','"Français"']),
  'first run paused': 'InitializeFirstRunPause()' in main and 'IniWrite("1", gCfg, "V3", "Paused")' in main,
  'no initial schedule': 'InitializeEmptySchedules()' in main and 'SEnsureEmptySchedules' in lib,
  'window-safe geometry': all(x in w for x in ['ClientToScreen','WCursorOverCaster','GetClientRect','PointClientSize','WResolveCasterForClick','CLIC BLOCCATO']),
  'session check': 'MGet("Status"' in w and 'MExecuteClose' in w,
  'compiled worker launcher': 'CasterLiveAutomation-Worker.exe' in main and 'if A_IsCompiled' in main,
  'source worker launcher': 'CasterLiveAutomation_Worker.ahk' in main and 'A_AhkPath' in main,
  'worker protocol': 'WState("WorkerVersion", "1.0")' in w and '"WorkerVersion", "") != "1.0"' in main,
  'no blind ControlClick': 'ControlClick(' not in w,
  'unchanged external EXE': 'CasterLive DJ.exe' in main and 'CasterLive DJ.exe' in w,
}
for title, success in checks.items():
    print(('PASS' if success else 'FAIL') + ': ' + title)
if not all(checks.values()): raise SystemExit(1)
print('NOTE: static checks are not a Windows runtime acceptance test.')
