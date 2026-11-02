"""Refresh existing Lua fixtures in a disposable, in-worktree mirror.

The source oracle programs run unchanged. Their generated game data is compared
as JSON, never copied over the working game, so serialization order cannot
produce unrelated data edits.
"""
from pathlib import Path
import subprocess,json,shutil,sys
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/parity-r23/fresh-oracles';OUT.mkdir(parents=True,exist_ok=True)
for sub in ['tools','project/data','project/game','project/ui']:(OUT/sub).mkdir(parents=True,exist_ok=True)
for sub,pattern in [('project/data','*.json'),('project/game','*.gd'),('project/ui','*.gd')]:
    for p in (ROOT/sub).glob(pattern):shutil.copyfile(p,OUT/sub/p.name)
results=[]
for bundle in ['persona','panels','chronicle','settings']:
    name=bundle+'_r22_oracle.mjs';shutil.copyfile(ROOT/'tools'/name,OUT/'tools'/name)
    with (OUT/(bundle+'.log')).open('wb') as log:p=subprocess.run(['node','tools/'+name],cwd=OUT,stdout=log,stderr=subprocess.STDOUT,timeout=240)
    if p.returncode:raise RuntimeError(name+' failed; see '+str(OUT/(bundle+'.log')))
    data={'persona':'persona-r22','panels':'panels-r22','chronicle':'chronicle-r22','settings':'localization-r22'}[bundle]+'.json'
    actual=json.loads((ROOT/'project/data'/data).read_text(encoding='utf-8'));generated=json.loads((OUT/'project/data'/data).read_text(encoding='utf-8'))
    same=actual==generated
    differences=[]
    if not same:
        for k in set(actual)|set(generated):
            if actual.get(k)!=generated.get(k):
                if isinstance(actual.get(k),dict) and isinstance(generated.get(k),dict):
                    differences.append({'key':k,'added':sorted(set(generated[k])-set(actual[k])),'removed':sorted(set(actual[k])-set(generated[k])),'changed':[s for s in set(actual[k])&set(generated[k]) if actual[k][s]!=generated[k][s]]})
                else:differences.append({'key':k})
    source=OUT/'verification'/(bundle+'-r22');dest=ROOT/'verification'/(bundle+'-r22')
    # Only evidence fixtures are refreshed. No exported data or screenshots.
    for filename in ['oracle.json','provenance.json']:
        if (source/filename).exists():shutil.copyfile(source/filename,dest/filename)
    subset_equal=not differences or all(set(x)<=set(['key','added','removed','changed']) and not x.get('added') and not x.get('changed') and 'removed' in x for x in differences)
    row={'bundle':bundle,'exit':p.returncode,'game_data_equal':same,'all_generated_fields_match':subset_equal,'preserved_native_extensions_only':not same and subset_equal,'differences':differences};results.append(row)
    (OUT/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(row,ensure_ascii=True),flush=True)
