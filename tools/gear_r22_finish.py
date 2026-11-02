"""Collect final evidence; source, battle files, docs and protected art are read-only."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parents[1];folder=root/'verification/gear-r22'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,value):(folder/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
baseline=read(folder/'baseline.json')
protected={'baseline_files':len(baseline),'baseline_changed':[p for p,h in baseline.items() if not (root/p).exists() or sha(root/p)!=h]}
art=read(root/'ASSET-HASHES.json');protected['assets']=len(art);protected['asset_changes']=[x['path'] for x in art if sha(root/x['path'])!=x['sha256']]
source=Path('C:/Clauede Code/dungeon-bot/bot/src');prov=read(folder/'provenance.json');owner=read(folder/'owner-provenance.json')
all_sources={x['name']:x['sha256'] for x in prov['files']+owner['files']}
protected['source_files']=len(all_sources);protected['source_changes']=[name for name,h in all_sources.items() if sha(source/name)!=h]
protected['docs_files']=sum(1 for p in baseline if p.replace('\\','/').startswith('docs/'))
protected['new_docs_files']=[str(p.relative_to(root)) for p in (root/'docs').rglob('*') if p.is_file() and str(p.relative_to(root)) not in baseline]
write('protected.json',protected)
regression=read(folder/'regression.json')
results={name:read(folder/name) for name in ['results.json','hook-results.json','boundary-results.json']}
summary={'groups':len(regression),'failed_groups':sum(bool(x['exit'] or x['errors']) for x in regression),'new_checks':sum(x['checks'] for x in results.values()),'new_failures':sum(len(x['failures']) for x in results.values()),'tests':{n:{'checks':x['checks'],'failures':len(x['failures'])} for n,x in results.items()},'protected':protected,'source_harness':{}}
for name in ['source-gear','source-smithy']:
    raw=(folder/(name+'.log')).read_bytes();text=raw.decode('utf-16') if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else raw.decode('utf-8',errors='replace')
    summary['source_harness'][name]={'checks':len(re.findall(r'^OK\s',text,re.M)),'failures':len(re.findall(r'^FAIL',text,re.M)),'passed':'전부 통과' in text}
write('summary.json',summary)
# Preserve the exact scoped rows without relabelling all parity statuses.
lines=(root/'PARITY-R21.md').read_text(encoding='utf-8').splitlines()
rows=[s for s in lines if re.match(r'\|P\d+\|',s) and ('81-gear.lua:' in s or '82-smithy.lua:' in s or ('05-gen.lua:' in s and ('GEAR_RAW' in s or 'GEAR_GL' in s)))]
write('parity-scope.json',{'rows':rows,'count':len(rows),'original_statuses_preserved':True,'runtime_battle_integration':'deferred to A as required'})
print(json.dumps({k:v for k,v in summary.items() if k!='protected'},ensure_ascii=True,indent=2))
assert summary['failed_groups']==0 and summary['new_failures']==0
assert all(not protected[k] for k in ['baseline_changed','asset_changes','source_changes','new_docs_files'])
