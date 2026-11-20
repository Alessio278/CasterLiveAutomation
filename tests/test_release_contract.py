"""Version, packaging, attribution and public-documentation assertions."""
from pathlib import Path
import re
r=Path(__file__).resolve().parents[1]
assert (r/'VERSION').read_text().strip() == '1.0'
assert (r/'CasterLiveAutomation.ahk').exists()
assert not (r/'CasterLiveAutomation_V5.ahk').exists()
for f in ['README.md','docs/README.it.md','docs/README.es.md','docs/README.fr.md', 'LICENSE', 'CHANGELOG.md', 'AI_PROJECT_INSTRUCTIONS.md','PROJECT_STATE.md','PROJECT_KNOWLEDGE.md']:
    x=(r/f).read_text(encoding='utf-8-sig')
    assert '@Alessio278' in x, f'Missing approved attribution in {f}'
    assert not re.search(r'Alessio\s+Natalucci', x, re.I), f'Superseded full-name credit in {f}'
for f in ['CasterLiveAutomation.ahk','CasterLiveAutomation_Worker.ahk','CasterLiveAutomation_ScheduleLib.ahk']:
    assert not re.search(r'Alessio\s+Natalucci', (r/f).read_text(encoding='utf-8-sig'),re.I)
assert 'CasterLiveAutomation-$version.exe' in (r/'scripts/Build-Windows.ps1').read_text()
assert (r/'third_party/GPL-2.0.txt').exists()
print('PASS: v1.0 release, attribution, source and build inputs')
