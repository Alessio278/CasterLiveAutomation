from pathlib import Path
root = Path(__file__).resolve().parents[1]
main = (root / 'CasterLiveAutomation_V5.ahk').read_text(encoding='utf-8-sig')
worker = (root / 'CasterLiveAutomation_Worker.ahk').read_text(encoding='utf-8-sig')
lib = (root / 'CasterLiveAutomation_ScheduleLib.ahk').read_text(encoding='utf-8-sig')
for f in (main, worker):
    assert '#Include CasterLiveAutomation_ScheduleLib.ahk' in f
    assert 'CLAMigrateLegacyFiles(' in f
assert 'CasterLiveAutomation_Settings.ini' in main and 'CasterLiveAutomation_Settings.ini' in worker
assert 'CasterLiveAutomation_Schedules.ini' in main and 'CasterLiveAutomation_Schedules.ini' in worker
assert 'CasterLiveAutomation_Runtime.ini' in main and 'CasterLiveAutomation_Runtime.ini' in worker
assert 'CasterLiveAutomation_Worker.ahk' in main
assert 'CasterLiveAutomation.lnk' in main
assert 'CasterLiveAutomation_Log.txt' in main and 'CasterLiveAutomation_Log.txt' in worker
assert 'CasterLiveDJ_Configurazione.ini' in lib  # deliberate legacy migration
assert 'CasterAutomation_Schedules.ini' in lib  # deliberate legacy migration
assert 'CasterLive DJ.exe' in main and 'CasterLive DJ.exe' in worker # external program unchanged
assert not (root / 'CasterLiveDJ_V3.ahk').exists()
assert not (root / 'CasterLiveDJ_Worker.ahk').exists()
print('PASS: official naming, internal references and migration')
