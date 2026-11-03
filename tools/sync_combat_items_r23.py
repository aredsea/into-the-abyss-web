"""Regenerate only combat item data, from the executed canonical Lua oracle."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
manifest=json.loads((O/'battle-round9-items-oracle.json').read_text(encoding='utf-8'))
c=manifest['constants'];items=c['items']
for d in items.values():
    if d.get('kind') in c['kinds']:d['fraction']=c['kinds'][d['kind']]['frac'][d['size']]
def literal(v):return json.dumps(v,ensure_ascii=False,separators=(',',':'),sort_keys=True)
(R/'project/game/combat_item_data_r23.gd').write_text('extends RefCounted\n## Executed 71-shop/78-battle-item oracle data; 79-sex item omitted.\nconst ORDER='+literal(c['order'])+'\nconst ITEMS='+literal(items)+'\nconst ENGLISH='+literal(c['english'])+'\nconst NAMES='+literal(c['names'])+'\n',encoding='utf-8')
