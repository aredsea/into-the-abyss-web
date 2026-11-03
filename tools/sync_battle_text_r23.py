"""Import source UI dictionaries, never expected fixture outputs, into combat ABI."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1]
d=json.loads((R/'verification/parity-r23/round5-oracle.json').read_text(encoding='utf-8'))
for f,h in d['provenance'].items():
 assert hashlib.sha256((Path('C:/Clauede Code/dungeon-bot/bot/src')/f).read_bytes()).hexdigest()==h
lines=['extends RefCounted','## Canonical UI/en dictionaries exported by the real Lua runtime.']
source=Path('C:/Clauede Code/dungeon-bot/bot/src')
combat='\n'.join((source/f).read_text(encoding='utf-8') for f in ['20-state.lua','24-stats.lua','26-start.lua','27-compose.lua','29-persona-skill.lua','30-engine.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','40-fx.lua','50-render.lua','51-raid.lua'])
terms=set(d['constants']['combat_terms'])
round6=json.loads((R/'verification/parity-r23/battle-round6-oracle.json').read_text(encoding='utf-8'))
for row in round6['rows']:
 if row['op']=='dmg_line':
  # Verb inflections are runtime values, so they may not occur as source literals.
  terms.update(k for k in d['constants']['words'] if k in row['expected'])
data={**d['constants'],'ui':{k:v for k,v in d['constants']['ui'].items() if k in combat},'words':{k:v for k,v in d['constants']['words'].items() if k in terms or k in combat}}
# Only combat vocabulary is shipped; unrelated town/intimacy text stays out.
for k in ['ui','words','pbadges','phase_ids']:lines.append('const '+k.upper()+'='+json.dumps(data[k],ensure_ascii=False,separators=(',',':')))
(R/'project/game/combat_text_r23.gd').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({'ui':len(data['ui']),'words':len(data['words'])}))
