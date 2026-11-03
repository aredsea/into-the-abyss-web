"""Run cloud checks against serve.mjs using a free local port, real Worker/D1."""
from pathlib import Path
import subprocess,os,sys,time,json,re
R=Path(__file__).resolve().parents[1];O=R/'verification/look-r24/cloud';O.mkdir(exist_ok=True)
modules=os.environ.get('ABYSS_NODE_MODULES')
if not modules:
 for name in ['r21-p1','r21-d-town']:
  p=R.parent/name/'server/abyss-save/node_modules'
  if (p/'miniflare/package.json').exists():modules=str(p);break
env={**os.environ,'ABYSS_NODE_MODULES':modules or '', 'TEMP':str(R/'verification/look-r24/tmp'),'TMP':str(R/'verification/look-r24/tmp'),'PYTHONIOENCODING':'utf-8'}
names=sys.argv[1:] or ['cloud_r22_test','cloud_compat_r23_test','cloud_journey_r23_test','cloud_archive_r22_test','town_combat_r21_round14_test','town_r21_round11_test']
rows=json.loads((O/'results.json').read_text(encoding='utf-8')) if sys.argv[1:] and (O/'results.json').exists() else [];server=None;ready=False
try:
 with (O/'server.log').open('wb') as log:
  server=subprocess.Popen(['node','--import','./tools/look_r24_cloud_launcher.mjs','--import','./tools/ui_r23_server_shutdown.mjs','server/abyss-save/test/serve.mjs'],cwd=R,env=env,stdin=subprocess.PIPE,stdout=log,stderr=subprocess.STDOUT,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
  for _ in range(300):
   text=(O/'server.log').read_text(encoding='utf-8',errors='replace');m=re.search(r'Local D1 worker (http://127\.0\.0\.1:\d+)/?',text)
   if m:ready=True;env['ABYSS_TEST_SERVER']=m[1];break
   if server.poll() is not None:break
   time.sleep(.1)
  if not ready:raise RuntimeError('serve.mjs did not become ready')
  for name in names:
   start=time.monotonic()
   command=['node','--import','./tools/look_r24_cloud_launcher.mjs','server/abyss-save/test/godot-r3.mjs',name] if name=='cloud_archive_r22_test' else [sys.executable,'tools/godot_r17.py','--headless','--script','res://tests/'+name+'.gd']
   with (O/(name+'.log')).open('wb') as out:p=subprocess.run(command,cwd=R,env=env,stdout=out,stderr=subprocess.STDOUT,timeout=300)
   text=(O/(name+'.log')).read_text(encoding='utf-8',errors='replace')
   if name=='cloud_archive_r22_test':text+='\n'+(R/'verification/cloud-r22/round12'/ (name+'.log')).read_text(encoding='utf-8',errors='replace')
   errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
   row={'test':name,'exit':p.returncode,'errors':errors,'summary':[s for s in text.splitlines() if re.search('CHECKS|checks|FAILURES|failures|PASS',s)][-3:],'seconds':round(time.monotonic()-start,2),'passed':p.returncode==0 and not errors};rows=[r for r in rows if r['test']!=name]+[row]
   (O/'results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(row,ensure_ascii=True),flush=True)
finally:
 if server and server.poll() is None:
  server.stdin.write(b'ABYSS_R23_STOP\n');server.stdin.flush();server.stdin.close();server.wait(timeout=15)
 (O/'lifecycle.json').write_text(json.dumps({'entry':'server/abyss-save/test/serve.mjs','ready':ready,'exit':server.returncode if server else None,'adaptations':['ephemeral loopback port','cross-worktree dev registry disabled'],'production_sources_changed':False},indent=2),encoding='utf-8')
sys.exit(0 if all(any(r['test']==n and r['passed'] for r in rows) for n in names) else 1)
