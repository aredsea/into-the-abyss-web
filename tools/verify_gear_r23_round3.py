"""Final whole-project run, owning one isolated local serve.mjs instance."""
from pathlib import Path
import subprocess,os,sys,socket,time,json,uuid,hashlib
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
S=O/'suite-gear-round3';S.mkdir(exist_ok=True)
with socket.socket() as s:s.bind(('127.0.0.1',0));port=s.getsockname()[1]
temp=R/'.p6tmp';temp.mkdir(exist_ok=True)
control='cloud-control-gear-round3-'+uuid.uuid4().hex[:8]
env={**os.environ,'ABYSS_NODE_MODULES':str(R/'server/abyss-save'),
 'TEMP':str(temp),'TMP':str(temp),'TMPDIR':str(temp),'ABYSS_TEST_PORT':str(port),
 'ABYSS_TEST_SERVER':f'http://127.0.0.1:{port}','R23_CLOUD_CONTROL':control,'R23_SUITE_NAME':S.name}
def locked():
 return {p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['project/game','project/ui','project/tests'] for p in (R/folder).glob('*.gd')}
before=locked();(S/'code-lock.json').write_text(json.dumps(before,indent=2),encoding='utf-8')
with (S/'local-server.log').open('wb') as log:
 server=subprocess.Popen(['node','--import','./tools/cloud_battle_r23_preload.mjs','server/abyss-save/test/serve.mjs'],cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT)
 print(json.dumps({'server_pid':server.pid,'url':env['ABYSS_TEST_SERVER']}),flush=True)
 try:
  ready=False
  for _ in range(300):
   if server.poll() is not None:raise RuntimeError('Local server exited; see local-server.log')
   try:
    with socket.create_connection(('127.0.0.1',port),timeout=.2):ready=b'Local D1 worker' in (S/'local-server.log').read_bytes()
    if ready:break
   except OSError:pass
   time.sleep(.1)
  if not ready:raise RuntimeError('Local server readiness timeout')
  with (S/'npm-test.log').open('wb') as f:
   npm=subprocess.Popen(['cmd','/c','npm','test'],cwd=R/'server/abyss-save',env=env,stdout=f,stderr=subprocess.STDOUT)
   code=subprocess.call([sys.executable,'tools/run_battle_r23_parallel.py'],cwd=R,env=env)
   npm_code=npm.wait()
  assert before==locked(),'Code changed after final verification started'
 finally:
  (O/(control+'.json')).write_text(json.dumps({'id':str(uuid.uuid4()),'shutdown':True}),encoding='utf-8')
  try:server.wait(timeout=30)
  except subprocess.TimeoutExpired:server.terminate();server.wait(timeout=10)
  (S/'local-server-result.json').write_text(json.dumps({'pid':server.pid,'port':port,'exit':server.returncode,'control':control}),encoding='utf-8')
(S/'final-verification.json').write_text(json.dumps({'project_exit':code,'npm_exit':npm_code,'code_lock_unchanged':before==locked()},indent=2),encoding='utf-8')
raise SystemExit(0 if code==0 and npm_code==0 else 1)
