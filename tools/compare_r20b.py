"""R20 baseline versus R20b actual renders; approved comparisons stay separate."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw,ImageChops,ImageEnhance
R=Path(__file__).resolve().parents[1];O=R/'verification/ui-r20'
rows=[];sheet=Image.new('RGB',(1560,3*870),'#eee8dc')
for i,state in enumerate(['base','target','status','skills','supplies','log']):
 before=Image.open(O/f'r20-before/{state}-390.png').convert('RGB')
 after=Image.open(O/f'{state}-390.png').convert('RGB')
 pair=Image.new('RGB',(780,870),'#eee8dc');d=ImageDraw.Draw(pair)
 d.text((10,6),f'{state}: R20',fill='#111');d.text((400,6),'R20b',fill='#111')
 pair.paste(before,(0,26));pair.paste(after,(390,26));pair.save(O/f'{state}-r20-r20b.png')
 sheet.paste(pair,((i%2)*780,(i//2)*870))
 diff=ImageChops.difference(before,after);ImageEnhance.Contrast(diff).enhance(4).save(O/f'{state}-r20b-change.png')
 a=np.asarray(before,dtype=float);b=np.asarray(after,dtype=float)
 rows.append({'state':state,'r20_vs_r20b_mae':float(np.abs(a-b).mean()),'max_channel_delta_gt16_pixels':int((np.abs(a-b).max(axis=2)>16).sum())})
sheet.save(O/'all-r20-r20b.png')
(O/'r20b-visual-comparison.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
p=O/'index.html';s=p.read_text(encoding='utf-8');s+='<h1>R20 / R20b</h1><p>Each pair: previous R20 left, compact R20b right.</p>'+''.join(f'<h2>{r["state"]}</h2><img src="{r["state"]}-r20-r20b.png" width="780">' for r in rows);p.write_text(s,encoding='utf-8')
print(json.dumps(rows,indent=2))
