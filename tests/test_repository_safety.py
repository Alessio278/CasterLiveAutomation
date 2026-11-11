"""Conservative public-repository checks; not a substitute for manually reviewing files."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
private = [
    'CasterLiveAutomation_Settings.ini',
    'CasterLiveAutomation_Schedules.ini',
    'CasterLiveAutomation_Runtime.ini',
    'CasterLiveAutomation_Log.txt',
    'CasterLiveDJ_Configurazione.ini',
    'CasterLiveDJ_Log.txt',
]
for name in private:
    assert not (root / name).exists(), f'Private file present: {name}'

ignore = (root / '.gitignore').read_text(encoding='utf-8')
assert '*.ini' in ignore and '*_Log.txt' in ignore
assert '!examples/' not in ignore and '!examples/*.example.ini' not in ignore

for f in root.rglob('*'):
    if not f.is_file() or '.git' in f.parts:
        continue
    rel = f.relative_to(root)
    assert 'Profiles' not in f.parts and 'Backup_' not in str(f), f'Private data folder: {rel}'
    assert f.suffix.lower() not in {'.exe', '.zip', '.7z', '.rar', '.lnk'}, f'Unexpected binary: {rel}'
    if f.suffix.lower() in {'.md', '.ahk', '.py', '.yml', '.yaml', '.ini'}:
        text = f.read_text(encoding='utf-8-sig')
        # Source/docs may refer to example Windows paths, but may not embed real profile directories.
        assert not re.search(r'(?i)C:\\Users\\[^\\\s]+', text), f'Possible user profile path: {rel}'
print('PASS: no known private runtime files or packaged binaries')
