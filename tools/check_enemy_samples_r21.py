"""Negative fixture probes: the action suite must reject insufficient oracle coverage."""
from pathlib import Path
import subprocess, sys, json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'verification/data-r21'
action=json.loads((OUT/'enemy-action-oracle.json').read_text(encoding='utf-8-sig'))
gear=json.loads((OUT/'elite-gear-oracle.json').read_text(encoding='utf-8-sig'))
source=(ROOT/'project/tests/enemy_action_r21_test.gd').read_text(encoding='utf-8-sig')
results=[]
label=sys.argv[1] if len(sys.argv)>1 else 'latest'
for case in ['empty','missing_enemy','no_silence','no_gear']:
    data=json.loads(json.dumps(action)); gears=gear
    if case=='empty': data['samples']=[]; data['silence']=[]; gears=[]
    if case=='missing_enemy': data['samples']=[r for r in data['samples'] if r['id']!=data['samples'][0]['id']]
    if case=='no_silence': data['silence']=[]
    if case=='no_gear': gears=[]
    af=OUT/'sample-probe-oracle.json'; gf=OUT/'sample-probe-gear.json'
    af.write_text(json.dumps(data),encoding='utf-8'); gf.write_text(json.dumps(gears),encoding='utf-8')
    script=ROOT/'project/tests/enemy_sample_probe_r21.gd'
    script.write_text(source.replace('enemy-action-oracle.json','sample-probe-oracle.json').replace('elite-gear-oracle.json','sample-probe-gear.json').replace('enemy-action-results.json','sample-probe-results.json'),encoding='utf-8')
    try:
        p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--script','res://tests/enemy_sample_probe_r21.gd'],cwd=ROOT,capture_output=True,encoding='utf-8',errors='replace',timeout=180)
        log=p.stdout+p.stderr
        (OUT/('sample-probe-'+label+'-'+case+'.log')).write_text(log,encoding='utf-8')
        errors=[l for l in log.splitlines() if ('SCRIPT ERROR:' in l or l.startswith('ERROR:')) and 'root certificate store' not in l]
        results.append({'case':case,'exit_code':p.returncode,'rejected':p.returncode==1 and not errors,'engine_errors':errors})
    finally:
        for f in [script,script.with_suffix('.gd.uid'),af,gf,OUT/'sample-probe-results.json']:
            if f.exists(): f.unlink()
(OUT/('sample-probes-'+label+'.json')).write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
print(json.dumps(results))
sys.exit(0 if all(r['rejected'] for r in results) else 1)
