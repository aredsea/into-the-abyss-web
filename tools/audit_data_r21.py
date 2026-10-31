"""Exact source-field and original-asset audit, independent of the Godot port."""
from pathlib import Path
import hashlib,json,os
R=Path(__file__).resolve().parents[1]
B=Path(os.environ.get('R21_BOT',r'C:\Clauede Code\dungeon-bot'))
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
src=read(B/'design/enemies.json'); actual=read(R/'project/data/enemies-r21.json'); dg=read(R/'project/data/dungeons-r21.json')
bad=[]
for key in src:
 if key!='enemies' and src[key]!=actual[key]: bad.append(key)
for i,(expected,value) in enumerate(zip(src['enemies'],actual['enemies'])):
 if expected!={k:v for k,v in value.items() if k not in ['art','source']}: bad.append(f'enemies/{i}')
 if value['art']!=f"res://assets/enemies-r21/{expected['id']}.png": bad.append(f'art/{i}')
 if value['source']['pointer']!=f'/enemies/{i}': bad.append(f'source/{i}')
 if any(w not in src['elements'] for w in value['weak']): bad.append(f'weak/{i}')
for key in ['zones','rifts']:
 if src[key]!=dg[key]: bad.append('dungeons/'+key)
stats=read(B/'design/stats.json')['meta']
for key,value in dg['stats'].items():
 if value!=stats[key]: bad.append('stats/'+key)
hashes=read(R/'ASSET-HASHES.json'); changed_assets=[a['path'] for a in hashes if hashlib.sha256((R/a['path']).read_bytes()).hexdigest()!=a['sha256']]
inventory=read(R/'verification/data-r21/source-inventory.json')
changed_source=[n for n,v in inventory.items() if hashlib.sha256((B/n).read_bytes()).hexdigest()!=v['sha256']]
report={'enemies':len(actual['enemies']),'families':len(actual['families']),'zones':len(dg['zones']),'playable_zones':len(dg['zone_order']),'rifts':len(dg['rifts']),'field_mismatches':bad,'original_assets':len(hashes),'changed_assets':changed_assets,'changed_source':changed_source,'failures':len(bad)+len(changed_assets)+len(changed_source)}
(R/'verification/data-r21/source-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False)); raise SystemExit(1 if report['failures'] else 0)
