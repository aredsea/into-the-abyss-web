from pathlib import Path
import subprocess,sys,json,time,os
sys.stdout.reconfigure(encoding='utf-8')
OUT=Path(__file__).resolve().parent;R=OUT/'runtime'
results=[]
commands=[['node','tools/'+n] for n in ['oracle_data_r21.mjs','oracle_enemy_r21.mjs','oracle_enemy_review_r21.mjs','town_r21_oracle.mjs','town_r21_commerce_oracle.mjs']]
commands += [[sys.executable,'tools/godot_r17.py','--headless','--script',f'res://tests/{n}.gd'] for n in ['data_r21_test','enemy_action_r21_test','enemy_review_r21_test','town_r21_test','town_commerce_r21_test']]
for i,cmd in enumerate(commands):
 start=time.time()
 r=subprocess.run(cmd,cwd=R,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=150,env={**os.environ,'PYTHONIOENCODING':'utf-8'})
 s=r.stdout.decode('utf-8',errors='replace');(OUT/f'fresh-{i+1:02}.log').write_text(s,encoding='utf-8')
 d={'command':cmd,'exit_code':r.returncode,'seconds':round(time.time()-start,2),'log':f'fresh-{i+1:02}.log','summary':[l for l in s.splitlines() if not l.startswith(('Godot Engine','WARNING:','   at:','ERROR: Condition','\t'))]};results.append(d)
 (OUT/'fresh-checks.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(d,ensure_ascii=False),flush=True)
 if r.returncode:sys.exit(r.returncode)
