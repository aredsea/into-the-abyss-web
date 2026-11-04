"""Re-run the eight frozen battle audits in the fourth isolated engine slot."""
from pathlib import Path
import subprocess,os,sys,time,json,re
R=Path(__file__).resolve().parents[1];O=R/'verification/reskin-r24/audits';O.mkdir(parents=True,exist_ok=True)
names=['combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
if sys.argv[1:]:names=[n for n in names if n in sys.argv[1:]]
rows=json.loads((O/'results.json').read_text(encoding='utf-8')) if (O/'results.json').exists() else []
for n in names:
 start=time.monotonic()
 with (O/(n+'.log')).open('wb') as log:
  p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--script','res://tests/'+n+'.gd'],cwd=R,env={**os.environ,'R23_RUNTIME_SLOT':'reskin-main','PYTHONIOENCODING':'utf-8'},stdout=log,stderr=subprocess.STDOUT,timeout=1200)
 text=(O/(n+'.log')).read_text(encoding='utf-8',errors='replace');errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
 row={'test':n,'exit':p.returncode,'errors':errors,'summary':[s[:250] for s in text.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|PASS|battles',s)][-3:],'passed':p.returncode==0 and not errors,'seconds':round(time.monotonic()-start,2)}
 rows=[r for r in rows if r['test']!=n]+[row];(O/'results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(row),flush=True)
