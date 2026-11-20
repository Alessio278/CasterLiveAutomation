"""Detect easily recognizable private data, but never claim a complete privacy audit."""
from pathlib import Path
import subprocess
import re
r=Path(__file__).resolve().parents[1]
private_context = ('AI_PROJECT_INSTRUCTIONS.md', 'PROJECT_STATE.md', 'PROJECT_KNOWLEDGE.md')
# In a local checkout ignored notes can still exist. Test the *tracked* tree instead.
if (r / '.git').exists():
    tracked = subprocess.run(['git', '-C', str(r), 'ls-files', '-z'],
                             check=True, capture_output=True).stdout.decode('utf-8').split('\0')
    assert not set(private_context).intersection(tracked), 'Private project notes are tracked by Git'
else:
    for filename in private_context:
        assert not (r / filename).exists(), f'Private file in public source package: {filename}'

for pattern in ['*Settings.ini','*Schedules.ini','*Runtime.ini','*Log.txt','*.exe','*.zip']:
    forbidden=[p for p in r.glob(pattern) if p.is_file()]
    assert not forbidden, f'Private/generated file(s): {forbidden}'
ignore=(r/'.gitignore').read_text()
assert '*.ini' in ignore and '*.exe' in ignore
assert all(filename in ignore for filename in private_context), 'Private files must be in .gitignore'
for p in r.rglob('*'):
    if not p.is_file() or any(part in {'.git','dist','build','__pycache__','.pytest_cache'} for part in p.relative_to(r).parts): continue
    if p.name in private_context: continue  # ignored, local-only notes are not release inputs
    rel=p.relative_to(r)
    assert p.suffix.lower() not in {'.exe','.zip','.7z','.rar','.lnk'}, rel
    if p.suffix.lower() in {'.md','.ahk','.py','.yml','.yaml','.ps1','.txt'}:
        text=p.read_text(encoding='utf-8-sig')
        assert not re.search(r'(?i)C:\\Users\\[^\\\s]+', text), f'Personal path in {rel}'
        assert not re.search(r'(?i)alessio\s+natalucci', text), f'Superseded personal credit in {rel}'
print('PASS: public tree scan for common sensitive data - historical commits not checked')
