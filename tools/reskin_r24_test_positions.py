"""Update pointer coordinates for controls moved into scroll regions.

Assertions, expected actions, state changes and source strings are untouched.
"""
from pathlib import Path
import re,json
R=Path(__file__).resolve().parents[1];changed=[]
insertion='''
	# r24: the same control may now live below the first viewport.
	if b is Control:
		var viewport=b.get_parent()
		while viewport!=null and not viewport is ScrollContainer:viewport=viewport.get_parent()
		if viewport is ScrollContainer:
			viewport.ensure_control_visible(b);await process_frame;await process_frame
'''
for p in (R/'project/tests').glob('ui_*.gd'):
 t=p.read_text(encoding='utf-8');parts=re.split(r'(?=^func )',t,flags=re.M);dirty=False
 for i,part in enumerate(parts):
  if not re.match(r'func (click|tap)\(',part) or 'push_input' not in part or '# r24:' in part:continue
  match=re.search(r'\tvar b=s\.controls\[id\]',part)
  if not match:continue
  tail=part[match.end():]
  if tail.startswith(';'):tail='\t'+tail[1:].lstrip()
  elif tail.startswith('\n'):tail=tail[1:]
  parts[i]=part[:match.end()]+insertion+tail;dirty=True
 if dirty:p.write_text(''.join(parts),encoding='utf-8');changed.append(str(p.relative_to(R)))
(R/'verification/reskin-r24/test-position-updates.json').write_text(json.dumps({'files':changed,'expectations_changed':False,'reason':'Scroll existing controls into view before computing actual mouse coordinates'},indent=2),encoding='utf-8')
print('Pointer helpers updated:',len(changed))
