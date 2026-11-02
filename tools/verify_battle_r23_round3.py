"""Own the exact local serve.mjs process and run the complete project suite."""
from pathlib import Path
import subprocess,os,sys,socket,time,json,uuid
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
S=O/'suite-round3-final';S.mkdir(exist_ok=True)
with socket.socket() as s:
 s.bind(('127.0.0.1',0));port=s.getsockname()[1]
temp=R/'.p6tmp';temp.mkdir(exist_ok=True)
control='cloud-control-round3-'+uuid.uuid4().hex[:8]
env={**os.environ,'ABYSS_NODE_MODULES':str(R.parent/'r21-d-town/server/abyss-save'),
 'TEMP':str(temp),'TMP':str(temp),'TMPDIR':str(temp),'ABYSS_TEST_PORT':str(port),
 'ABYSS_TEST_SERVER':f'http://127.0.0.1:{port}','R23_CLOUD_CONTROL':control,
 'R23_SUITE_NAME':S.name}
with (S/'local-server.log').open('wb') as log:
 server=subprocess.Popen(['node','--import','./tools/cloud_battle_r23_preload.mjs','server/abyss-save/test/serve.mjs'],cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT)
 print(json.dumps({'server_pid':server.pid,'url':env['ABYSS_TEST_SERVER']}),flush=True)
 try:
  ready=False
  for _ in range(300):
   if server.poll() is not None:raise RuntimeError('Local server exited; see local-server.log')
   try:
    with socket.create_connection(('127.0.0.1',port),timeout=.2):
     # Listening starts before D1 migrations. serve.mjs prints this only after
     # runtime() has finished schema creation and its readiness fetch.
     ready=b'Local D1 worker' in (S/'local-server.log').read_bytes()
     if ready:break
     time.sleep(.1)
   except OSError:time.sleep(.1)
  if not ready:raise RuntimeError('Local server readiness timeout')
  runner='tools/run_battle_r23.py' if os.environ.get('R23_DIRECT')=='1' else 'tools/run_battle_r23_parallel.py'
  code=subprocess.call([sys.executable,runner,*sys.argv[1:]],cwd=R,env=env)
 finally:
  request={'id':str(uuid.uuid4()),'shutdown':True}
  (O/(control+'.json')).write_text(json.dumps(request),encoding='utf-8')
  try:server.wait(timeout=30)
  except subprocess.TimeoutExpired:server.terminate();server.wait(timeout=10)
  record={'pid':server.pid,'port':port,'exit':server.returncode,'control':control,'tests':sys.argv[1:]}
  (S/(control+'-server-result.json')).write_text(json.dumps(record),encoding='utf-8')
  (S/'local-server-result.json').write_text(json.dumps(record),encoding='utf-8')
raise SystemExit(code)
