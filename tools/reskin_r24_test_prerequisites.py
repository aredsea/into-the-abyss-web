"""Create test-output directories that do not survive a source-only handoff."""
from pathlib import Path
import re,json
R=Path(__file__).resolve().parents[1];base=(R/'verification').resolve();created=[]
for p in (R/'project/tests').glob('*.gd'):
    for path in re.findall(r'"res://\.\./(verification/[^"\n]+)"',p.read_text(encoding='utf-8')):
        target=(R/path).resolve()
        if target.suffix:target=target.parent
        assert target==base or base in target.parents,target
        if not target.exists():target.mkdir(parents=True,exist_ok=True);created.append(str(target.relative_to(R)))
(R/'verification/reskin-r24/round2/test-directories.json').write_text(json.dumps(created,indent=2),encoding='utf-8')
print('Recreated',len(created),'test output directories')
