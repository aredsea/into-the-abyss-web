"""Run all project checks against locked code and an owned local cloud server."""
from pathlib import Path
import hashlib,json,os,socket,subprocess,sys,time,uuid
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round5-final';S.mkdir(exist_ok=True)
locked={str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for d in ['project/game','project/tests'] for p in (R/d).glob('*.gd')}
(S/'final-code-lock.json').write_text(json.dumps({'time':time.time(),'sha256':locked},indent=2),encoding='utf-8')
with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
temp=R/'.p6tmp';temp.mkdir(exist_ok=True);control='cloud-control-round5-'+uuid.uuid4().hex[:8]
env={**os.environ,'ABYSS_NODE_MODULES':str(R.parent/'r21-d-town/server/abyss-save'),'TEMP':str(temp),'TMP':str(temp),'TMPDIR':str(temp),'ABYSS_TEST_PORT':str(port),'ABYSS_TEST_SERVER':f'http://127.0.0.1:{port}','R23_CLOUD_CONTROL':control,'R23_SUITE_NAME':S.name}
with (S/'local-server.log').open('wb') as log:
 server=subprocess.Popen(['node','--import','./tools/cloud_battle_r23_preload.mjs','server/abyss-save/test/serve.mjs'],cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT)
 print(json.dumps({'server_pid':server.pid,'url':env['ABYSS_TEST_SERVER']}),flush=True)
 try:
  ready=False
  for _ in range(300):
   if server.poll() is not None:raise RuntimeError('Local server exited; see local-server.log')
   try:
    with socket.create_connection(('127.0.0.1',port),timeout=.2):ready=b'Local D1 worker' in (S/'local-server.log').read_bytes()
   except OSError:pass
   if ready:break
   time.sleep(.1)
  if not ready:raise RuntimeError('Local server readiness timeout')
  code=subprocess.call([sys.executable,'tools/run_battle_r23_parallel.py',*sys.argv[1:]],cwd=R,env=env)
 finally:
  (O/(control+'.json')).write_text(json.dumps({'id':str(uuid.uuid4()),'shutdown':True}),encoding='utf-8')
  try:server.wait(timeout=30)
  except subprocess.TimeoutExpired:server.terminate();server.wait(timeout=10)
  (S/'local-server-result.json').write_text(json.dumps({'pid':server.pid,'port':port,'exit':server.returncode,'control':control,'tests':sys.argv[1:]}),encoding='utf-8')
assert all(hashlib.sha256((R/name).read_bytes()).hexdigest()==h for name,h in locked.items()),'Code changed during suite'
(S/'final-code-verification.json').write_text(json.dumps({'unchanged':True,'files':len(locked)}),encoding='utf-8')
raise SystemExit(code)
