"""Run the final whole-project suite once on this pass's owned local D1 server."""
from pathlib import Path
import subprocess,os,sys,socket,time,json,uuid,hashlib
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'expe-pass4-suite-complete';S.mkdir(exist_ok=True)
with socket.socket() as sock:
 sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
temp=R/'.p6tmp';temp.mkdir(exist_ok=True)
control='expe-pass4-cloud-'+uuid.uuid4().hex[:8]
env={**os.environ,'ABYSS_NODE_MODULES':str(R.parent/'r21-d-town/server/abyss-save'),
 'TEMP':str(temp),'TMP':str(temp),'TMPDIR':str(temp),'ABYSS_TEST_PORT':str(port),
 'ABYSS_TEST_SERVER':f'http://127.0.0.1:{port}','R23_CLOUD_CONTROL':control,'R23_SUITE_NAME':S.name}
lock={p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['project/game','project/ui','project/tests'] for p in (R/folder).rglob('*.gd')}
(O/'expe-pass4-code-lock.json').write_text(json.dumps(lock,indent=2),encoding='utf-8')
assert not (S/'rows').exists(), 'Do not rerun a whole suite over prior results'
with (S/'local-server.log').open('wb') as log:
 server=subprocess.Popen(['node','--import','./tools/cloud_battle_r23_preload.mjs','server/abyss-save/test/serve.mjs'],cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT)
 print(json.dumps({'server_pid':server.pid,'url':env['ABYSS_TEST_SERVER']}),flush=True)
 try:
  for _ in range(300):
   if server.poll() is not None:raise RuntimeError('Local server exited; see local-server.log')
   if b'Local D1 worker' in (S/'local-server.log').read_bytes():break
   time.sleep(.1)
  else:raise RuntimeError('Local server readiness timeout')
  code=subprocess.call([sys.executable,'tools/run_battle_r23_parallel.py',*sys.argv[1:]],cwd=R,env=env)
 finally:
  (O/(control+'.json')).write_text(json.dumps({'id':str(uuid.uuid4()),'shutdown':True}),encoding='utf-8')
  try:server.wait(timeout=30)
  except subprocess.TimeoutExpired:server.terminate();server.wait(timeout=10)
  (S/'server-result.json').write_text(json.dumps({'pid':server.pid,'port':port,'exit':server.returncode,'control':control}),encoding='utf-8')
changed=[p for p,h in lock.items() if not (R/p).exists() or hashlib.sha256((R/p).read_bytes()).hexdigest()!=h]
(S/'code-lock-result.json').write_text(json.dumps({'changed':changed}),encoding='utf-8')
if changed:raise RuntimeError('Code changed during final suite: '+', '.join(changed))
raise SystemExit(code)
