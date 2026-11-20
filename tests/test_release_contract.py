"""Public version, packaging and attribution contracts. No private project notes."""
from pathlib import Path
import re

r = Path(__file__).resolve().parents[1]
version = (r / 'VERSION').read_text(encoding='utf-8-sig').strip()
assert re.fullmatch(r'\d+\.\d+', version), f'Invalid VERSION: {version!r}'
assert (r / 'CasterLiveAutomation.ahk').exists()
assert not (r / 'CasterLiveAutomation_V5.ahk').exists()

for f in ['README.md', 'docs/README.it.md', 'docs/README.es.md',
          'docs/README.fr.md', 'LICENSE', 'CHANGELOG.md']:
    x = (r / f).read_text(encoding='utf-8-sig')
    assert '@Alessio278' in x, f'Missing approved attribution in {f}'
    assert not re.search(r'Alessio\s+Natalucci', x, re.I), f'Full-name credit in {f}'

for f in ['CasterLiveAutomation.ahk', 'CasterLiveAutomation_Worker.ahk',
          'CasterLiveAutomation_ScheduleLib.ahk']:
    assert not re.search(r'Alessio\s+Natalucci', (r / f).read_text(encoding='utf-8-sig'), re.I)

main = (r / 'CasterLiveAutomation.ahk').read_text(encoding='utf-8-sig')
worker = (r / 'CasterLiveAutomation_Worker.ahk').read_text(encoding='utf-8-sig')
assert f'"CasterLiveAutomation  |  {version}"' in main, 'GUI version differs from VERSION'
assert f'"WorkerVersion", "") != "{version}"' in main, 'GUI WorkerVersion differs from VERSION'
assert f'WState("WorkerVersion", "{version}")' in worker, 'Worker protocol differs from VERSION'
assert 'CasterLiveAutomation-$version.exe' in (r / 'scripts/Build-Windows.ps1').read_text(encoding='utf-8-sig')
assert (r / 'third_party/GPL-2.0.txt').exists()
assert (r / '.github/workflows/auto-release.yml').exists(), 'Missing automatic release workflow'
print(f'PASS: v{version} public release contracts; no private context required')
