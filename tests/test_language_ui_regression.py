from pathlib import Path
r=Path(__file__).resolve().parents[1]
text=(r/'CasterLiveAutomation.ahk').read_text(encoding='utf-8-sig')
assert 'gControls["languageSelect"]' in text
assert 'RedrawLocalizedGUI' in text
assert 'r4 Choose' in text
assert 'LanguageChanged(' in text
assert 'IniWrite(gLanguage, gCfg, "UI", "Language")' in text
for lang in ['it','en','es','fr']:
    assert '"'+lang+'"' in text
print('PASS: language selector and redraw static checks - Windows rendering untested')
