"""Recheck every edited trio, then all mandated regressions, one engine slot."""
import sys, os, json, subprocess, time, re
from polish4 import ROOT, OUT
sys.path.insert(0, str(ROOT/'tools'))
from en_r24_verify import cleanup
sys.stdout.reconfigure(encoding='utf-8')
CHECKS=OUT/'polish-checks'
CHECKS.mkdir(exist_ok=True)
started=time.time()
(CHECKS/'started.json').write_text(json.dumps({'started':started})+'\n',encoding='utf-8')
ids=[p.stem for p in sorted((ROOT/'project/data/dialogue-r21').glob('*.json'))]
results=[]
try:
 for start in range(0,len(ids),3):
  group=ids[start:start+3]
  for name in ['finish_locale_data_audit','en_r24_test']:
   p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--script',f'res://tests/{name}.gd','--',','.join(group)],cwd=ROOT,env={**os.environ,'R23_RUNTIME_SLOT':'en-r24','PYTHONIOENCODING':'utf-8'},capture_output=True,timeout=180)
   log=(p.stdout+p.stderr).decode('utf-8',errors='replace')
   errors=[s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
   row=dict(group=group,test=name,exit=p.returncode,passed=p.returncode==0 and not errors,errors=errors,summary=[s for s in log.splitlines() if re.search('CHECKS|FAILURES|AUDIT',s)])
   results.append(row)
   (CHECKS/('-'.join(group)+'-'+name+'.log')).write_text(log,encoding='utf-8')
   source=OUT/('batch-language-audit.json' if name=='finish_locale_data_audit' else 'dialogue-test.json')
   (CHECKS/('-'.join(group)+'-'+name+'.json')).write_bytes(source.read_bytes())
   (CHECKS/'batch-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
   print(json.dumps(row),flush=True)
   if not row['passed']: raise SystemExit(1)
 p=subprocess.run([sys.executable,'tools/en_r24_verify.py'],cwd=ROOT)
 if p.returncode: raise SystemExit(p.returncode)
 regression=json.loads((OUT/'regression.json').read_text(encoding='utf-8'))
 assert len(regression)==20 and all(r['passed'] for r in regression)
 assert all((OUT/(r['test']+'.log')).stat().st_mtime>=started for r in regression)
 result=dict(started=started,finished=time.time(),trio_checks=len(results),trio_failures=sum(not r['passed'] for r in results),full_regressions=len(regression),full_failures=sum(not r['passed'] for r in regression),all_final_logs_fresh=True)
 (CHECKS/'run.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
 print(json.dumps(result),flush=True)
finally:
 cleanup()
