"""Detect easily recognizable private data, but never claim a complete privacy audit."""
from pathlib import Path
import re
r=Path(__file__).resolve().parents[1]
for pattern in ['*Settings.ini','*Schedules.ini','*Runtime.ini','*Log.txt','*.exe','*.zip']:
    forbidden=[p for p in r.glob(pattern) if p.is_file()]
    assert not forbidden, f'Private/generated file(s): {forbidden}'
ignore=(r/'.gitignore').read_text()
assert '*.ini' in ignore and '*.exe' in ignore
for p in r.rglob('*'):
    if not p.is_file() or '.git' in p.parts: continue
    rel=p.relative_to(r)
    assert p.suffix.lower() not in {'.exe','.zip','.7z','.rar','.lnk'}, rel
    if p.suffix.lower() in {'.md','.ahk','.py','.yml','.yaml','.ps1','.txt'}:
        text=p.read_text(encoding='utf-8-sig')
        assert not re.search(r'(?i)C:\\Users\\[^\\\s]+', text), f'Personal path in {rel}'
        assert not re.search(r'(?i)alessio\s+natalucci', text), f'Superseded personal credit in {rel}'
print('PASS: public tree scan for common sensitive data - historical commits not checked')
