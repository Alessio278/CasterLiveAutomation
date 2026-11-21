from pathlib import Path
r=Path(__file__).resolve().parents[1]
main=(r/'CasterLiveAutomation.ahk').read_text(encoding='utf-8-sig')
worker=(r/'CasterLiveAutomation_Worker.ahk').read_text(encoding='utf-8-sig')
lib=(r/'CasterLiveAutomation_ScheduleLib.ahk').read_text(encoding='utf-8-sig')
for text in (main,worker):
    assert '#Include CasterLiveAutomation_ScheduleLib.ahk' in text
    assert 'CLAMigrateLegacyFiles(' in text
    for key in ['CasterLiveAutomation_Settings.ini','CasterLiveAutomation_Schedules.ini','CasterLiveAutomation_Runtime.ini']:
        assert key in text
assert 'CasterLiveDJ_Configurazione.ini' in lib
assert 'CasterAutomation_Schedules.ini' in lib
assert 'CasterLiveAutomation.lnk' in main
# Legacy Win-start links can have arbitrary names; clean only exact old script targets.
assert 'Loop Files startupFolder' in main
assert 'A_StartupCommon' in main
assert 'casterlivedj_v5.ahk' in main
assert 'FileGetShortcut(legacy, &oldTarget, , &oldArgs)' in main
assert 'StrLower(legacy) = StrLower(gShortcut)' in main
assert not (r/'CasterLiveAutomation_V5.ahk').exists()
print('PASS: new entrypoint, non-destructive data migration and startup link')
