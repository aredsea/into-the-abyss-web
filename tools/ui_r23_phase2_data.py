"""Ship only the exercised public presentation data from the current Lua oracle."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
o=json.loads((ROOT/'verification/parity-r23/phase2/oracle.json').read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
write(ROOT/'project/data/cloud-recap-r23.json',o['recap_dictionary'])
write(ROOT/'project/data/persona-text-r23.json',o['public_dictionary']['values'])
p=ROOT/'project/data/localization-r22.json';data=json.loads(p.read_text(encoding='utf-8'))
changes={}
for bucket in ['ui','words']:
    changes[bucket]=[k for k,v in o['public_dictionary'][bucket].items() if data[bucket].get(k)!=v]
    data[bucket].update(o['public_dictionary'][bucket])
write(p,data)
write(ROOT/'verification/parity-r23/phase2/data-refresh.json',changes)
print({k:len(v) for k,v in changes.items()})
