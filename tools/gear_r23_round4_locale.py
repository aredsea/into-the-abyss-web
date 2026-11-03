"""Copy source-owned translations into the facility-scoped adapter only."""
from pathlib import Path
import json,re
R=Path(__file__).resolve().parents[1]
d=json.loads((R/'verification/parity-r23/gear-round4-oracle.json').read_text(encoding='utf-8'))['locale']
texts=(R/'project/ui/facilities_screen_r22.gd').read_text(encoding='utf-8')
for name in ['65-codex.lua','71-shop.lua','72-guild.lua','73-inn.lua','82-smithy.lua']:
    texts+=(Path('C:/Clauede Code/dungeon-bot/bot/src')/name).read_text(encoding='utf-8')
keys=set(re.findall(r'"([^"\n]*)"',texts))
keys.update(['일반','고급','희귀','영웅','전설'])
def strings(x):
    if isinstance(x,str):keys.add(x)
    elif isinstance(x,dict):
        for value in x.values():strings(value)
    elif isinstance(x,list):
        for value in x:strings(value)
strings(json.loads((R/'project/data/gear-r22.json').read_text(encoding='utf-8')))
strings(json.loads((R/'project/data/panels-r22.json').read_text(encoding='utf-8'))['cast'])
d={kind:{key:value for key,value in table.items() if key in keys} for kind,table in d.items()}
# No network, translated copy writing, or edits to shared locale/state owners.
content='extends RefCounted\n## Original bot UI pack and dictionary; facility presentation only.\n'
for key in ['ui','words']:
    content+='const '+key.upper()+'='+json.dumps(d[key],ensure_ascii=False,indent=1)+'\n'
content+='''const L=preload("res://game/localization_r22.gd")
static func u(value: String,vars: Variant=null,lang="ko") -> String:
	return L.u(UI.get(value,value) if lang=="en" else value,vars,lang)
'''
(R/'project/game/gear_locale_r23.gd').write_text(content,encoding='utf-8')
print({k:len(v) for k,v in d.items()})
