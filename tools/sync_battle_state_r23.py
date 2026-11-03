"""Export canonical declarative battle metadata, never observed test answers."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1]
data=json.loads((R/'verification/parity-r23/battle-round6-oracle.json').read_text(encoding='utf-8'))
for name,digest in data['provenance'].items():
 assert hashlib.sha256((Path('C:/Clauede Code/dungeon-bot/bot/src')/name).read_bytes()).hexdigest()==digest
lines=['extends RefCounted','## Declarative B.CLS/CAST/ATK/KIT/DF/PSK/EDEF/FOES/GRADES, exported from canonical Lua.']
for name,value in data['constants'].items():
 lines.append('const '+name.upper()+'='+json.dumps(value,ensure_ascii=False,separators=(',',':')))
(R/'project/game/battle_source_data_r23.gd').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({k:len(v) if isinstance(v,(list,dict)) else v for k,v in data['constants'].items()}))
