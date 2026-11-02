from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
ids=[c['id'] for c in json.loads((R/'project/data/world.json').read_text(encoding='utf-8'))['companions']]
parties=[ids[i:i+4] for i in range(0,len(ids),4)]
parties[-1]+=[i for i in ids if i not in parties[-1]][:4-len(parties[-1])]
lua='local parties={'+','.join('{'+','.join(json.dumps(i) for i in p)+'}' for p in parties)+'}'
s=(R/'tools/oracle_combat_a6_mixed.mjs').read_text(encoding='utf-8')
s=s.replace("src=src.replace('local trace={};'",'src=src.replace(/local parties=.+/,'+json.dumps(lua)+");\nsrc=src.replace('local trace={};'")
s=s.replace('a6-mixed-oracle.json','p3-mixed-oracle.json')
(R/'tools/oracle_combat_p3_mixed.mjs').write_text(s,encoding='utf-8')
s=(R/'project/tests/combat_a6_mixed_audit.gd').read_text(encoding='utf-8').replace('a6-mixed-oracle.json','p3-mixed-oracle.json').replace('a6-mixed-audit.json','p3-mixed-audit.json').replace('reports.size()==48 and ','').replace('A6 mixed parity','P3 mixed parity')
(R/'project/tests/combat_p3_mixed_audit.gd').write_text(s,encoding='utf-8')
print(len(ids),len(parties))
