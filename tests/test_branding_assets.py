"""Check V1.0 branding assets and source/build wiring without Windows tools."""
from pathlib import Path
import struct
root=Path(__file__).resolve().parents[1]
assets=root/'assets'/'branding'
required=['CasterLiveAutomation-logo.png','CasterLiveAutomation-icon.png','CasterLiveAutomation.ico']
for name in required:
    p=assets/name
    assert p.is_file() and p.stat().st_size>1024, f'Missing or empty asset: {p}'
for name in required[:2]:
    b=(assets/name).read_bytes()
    assert b[:8]==b'\x89PNG\r\n\x1a\n'
    w,h=struct.unpack('>II',b[16:24])
    assert w>=256 and h>=256, (name,w,h)
icon=(assets/'CasterLiveAutomation.ico').read_bytes()
reserved,kind,count=struct.unpack('<HHH',icon[:6])
assert reserved==0 and kind==1 and count>=4, (reserved,kind,count)
source=(root/'CasterLiveAutomation.ahk').read_text(encoding='utf-8-sig')
assert 'ApplyBrandIcon()' in source and 'TraySetIcon(gBrandIcon)' in source
assert 'CasterLiveAutomation.ico' in source and 'gControls["brandIcon"]' in source
build=(root/'scripts/Build-Windows.ps1').read_text()
assert "'/icon', $brandIcon" in build, 'Ahk2Exe must receive branded icon as an argument'
assert "CasterLiveAutomation.ico" in build
for doc in ['README.md','docs/README.it.md','docs/README.es.md','docs/README.fr.md']:
    assert 'CasterLiveAutomation-logo.png' in (root/doc).read_text(encoding='utf-8-sig'), doc
print('PASS: original branding PNG/ICO assets, GUI/tray integration and EXE build wiring')
