"""Import canonical passive data from the executed Lua oracle, not its results."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1]
v=json.loads((R/'verification/parity-r23/round4-oracle.json').read_text(encoding='utf-8'))
for name,h in v['provenance'].items():
 assert hashlib.sha256((Path('C:/Clauede Code/dungeon-bot/bot/src')/name).read_bytes()).hexdigest()==h
lines=['extends RefCounted','## Data imported from canonical 05-gen / 34-traits via the real Lua runtime.']
for key,value in v['constants'].items():lines.append('const '+key.upper()+'='+json.dumps(value,ensure_ascii=False,separators=(',',':')))
(R/'project/game/combat_passives_r23.gd').write_text('\n'.join(lines)+'\n',encoding='utf-8')
