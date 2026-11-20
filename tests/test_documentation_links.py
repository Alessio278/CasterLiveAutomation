"""Validate local Markdown links in the prepared public repository."""
from pathlib import Path
import re
r=Path(__file__).resolve().parents[1]
broken=[]
for doc in r.rglob('*.md'):
    for match in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)',doc.read_text(encoding='utf-8-sig')):
        link=match.strip().split(' ')[0]
        if link.startswith(('https:','http:','mailto:','#')): continue
        relative=link.split('#')[0]
        if relative and not (doc.parent/relative).exists():
            broken.append(f'{doc.relative_to(r)} -> {link}')
assert not broken, '\n'.join(broken)
print('PASS: all relative Markdown links exist')
