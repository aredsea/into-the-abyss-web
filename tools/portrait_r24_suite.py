"""Isolated tests: copy input fixtures, no writes to shipped game or old evidence."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import shutil,subprocess,os,sys,json,time,re,threading,socket,uuid
R=Path(__file__).resolve().parents[1];O=R/'verification/portrait-r24';W=O/'test-workspace'
LOG=O/'logs';LOG.mkdir(exist_ok=True)
CLOUD_LOCK=threading.Lock()
EXTRAS=['balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
def cloud_case(name):return name.startswith('cloud_') or name in ['ui_cloud_r22_test','town_combat_r21_round14_test','town_r21_round11_test']
def reset_cloud(name):
    folder=W/'verification/parity-r23';control=os.environ['R23_CLOUD_CONTROL'];request={'id':str(uuid.uuid4()),'archive':name=='cloud_archive_r22_test'}
    (folder/(control+'.json')).write_text(json.dumps(request),encoding='utf-8')
    for _ in range(100):
        try:reply=json.loads((folder/(control+'-result.json')).read_text(encoding='utf-8'))
        except (FileNotFoundError,json.JSONDecodeError):reply={}
        if reply.get('id')==request['id']:
            if not reply.get('ok'):raise RuntimeError(reply)
            return
        time.sleep(.1)
    raise RuntimeError('Isolated test server did not reset')
def start_server():
    shutil.copytree(R/'server',W/'server',dirs_exist_ok=True,ignore=shutil.ignore_patterns('node_modules','.wrangler'))
    shutil.copy2(R/'tools/cloud_battle_r23_preload.mjs',W/'tools/cloud_battle_r23_preload.mjs')
    shutil.copy2(R/'tools/portrait_r24_server.mjs',W/'tools/portrait_r24_server.mjs')
    (W/'verification/cloud-r22/p9c').mkdir(parents=True,exist_ok=True)
    with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
    cache=R/'tools/portrait-tmp';cache.mkdir(exist_ok=True)
    modules=Path('C:/Users/asone/AppData/Local/npm-cache/_npx/c943b712072b77c4/node_modules')
    os.environ.update({'ABYSS_NODE_MODULES':str(modules),'ABYSS_TEST_PORT':str(port),'ABYSS_TEST_SERVER':f'http://127.0.0.1:{port}','R23_CLOUD_CONTROL':'portrait-r24-cloud-'+uuid.uuid4().hex[:8],'TEMP':str(cache),'TMP':str(cache),'TMPDIR':str(cache)})
    os.environ['PORTRAIT_DEV_REGISTRY']=str(cache/('registry-'+str(port)))
    log=(LOG/'local-server.log').open('wb')
    process=subprocess.Popen(['node','--import','./tools/portrait_r24_server.mjs','--import','./tools/cloud_battle_r23_preload.mjs','server/abyss-save/test/serve.mjs'],cwd=W,env=os.environ,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    for _ in range(300):
        if process.poll() is not None:raise RuntimeError('Isolated server failed; see local-server.log')
        try:
            with socket.create_connection(('127.0.0.1',port),timeout=.2):
                if b'Local D1 worker' in (LOG/'local-server.log').read_bytes():print('isolated server ready',port,flush=True);return process,log
        except OSError:pass
        time.sleep(.1)
    process.terminate();raise RuntimeError('Isolated server readiness timeout')
def prepare():
    shutil.copytree(R/'project',W/'project',dirs_exist_ok=True,ignore=shutil.ignore_patterns('.godot'))
    (W/'tools').mkdir(exist_ok=True);shutil.copy2(R/'tools/godot_r17.py',W/'tools/godot_r17.py')
    # Only JSON fixture inputs; never copy screenshots, engines or earlier clones.
    for p in (R/'verification').rglob('*.json'):
        parts=p.relative_to(R/'verification').parts
        if any(x.startswith(('runtime','test-workspace','portrait-r24','attempt-')) for x in parts):continue
        q=W/'verification'/p.relative_to(R/'verification');q.parent.mkdir(parents=True,exist_ok=True)
        if not q.exists():shutil.copy2(p,q)
    print('prepared',flush=True)
def run(name):
    if cloud_case(name):
        with CLOUD_LOCK:
            reset_cloud(name)
            return execute(name)
    return execute(name)
def execute(name):
    start=time.time();slot=os.environ.get('PORTRAIT_RUNTIME_SLOT','portrait-r24-'+threading.current_thread().name.rsplit('_',1)[-1])
    # These inherited capture tests assume their base test has already run.
    # Prepare output directories when running in an otherwise empty clone.
    for folder in ['look-r24/after','town-r21/render']:
        (W/'verification'/folder).mkdir(parents=True,exist_ok=True)
    env={**os.environ,'R23_RUNTIME_SLOT':slot,'PYTHONIOENCODING':'utf-8'}
    native=name.startswith('ui_') and name not in ['ui_rules_r23_test','ui_remaining_r23_test'] or name.endswith('_integration')
    args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if native else ['--headless']),'--script','res://tests/'+name+'.gd']
    with (LOG/(name+'.log')).open('wb') as f:
        try:p=subprocess.run([sys.executable,'tools/godot_r17.py',*args],cwd=W,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=1800 if name in ['combat_a8_audit','ui_dialogue_roster_r21_test'] else 900);code=p.returncode
        except subprocess.TimeoutExpired:code=124
    txt=(LOG/(name+'.log')).read_text(encoding='utf-8',errors='replace')
    errors=[l for l in txt.splitlines() if ('SCRIPT ERROR:' in l or l.startswith('ERROR:')) and 'root certificate store' not in l]
    return {'test':name,'exit':code,'seconds':round(time.time()-start,2),'passed':code==0 and not errors,'errors':errors[:20],'summary':[l for l in txt.splitlines() if re.search('CHECKS|checks|FAILURES|failures|PASS|TESTS:',l)][-4:]}
def suite():
    selected=sys.argv[2:]
    no_cloud='--no-cloud' in selected
    selected=[n for n in selected if n!='--no-cloud']
    if selected==['import']:
        prepare();row=run('import');(O/'import.json').write_text(json.dumps(row,indent=2),encoding='utf-8');print(row,flush=True);return
    names=selected or sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in EXTRAS)
    if no_cloud:names=[n for n in names if not cloud_case(n)]
    path=O/os.environ.get('PORTRAIT_SUITE_FILE','suite.json');rows=json.loads(path.read_text(encoding='utf-8')) if path.exists() else []
    done={r['test'] for r in rows if r['passed']};names=[n for n in names if n not in done] if not selected else names
    server,server_log=start_server() if any(cloud_case(n) for n in names) else (None,None)
    try:
        # Start the expensive 5,120-battle replay early.
        names.sort(key=lambda n:(n!='combat_a8_audit',n))
        with ThreadPoolExecutor(max_workers=3) as pool:
            for f in as_completed([pool.submit(run,n) for n in names]):
                row=f.result();rows=[r for r in rows if r['test']!=row['test']]+[row]
                path.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(row,ensure_ascii=True),flush=True)
    finally:
        if server:
            (W/'verification/parity-r23'/(os.environ['R23_CLOUD_CONTROL']+'.json')).write_text(json.dumps({'id':str(uuid.uuid4()),'shutdown':True}),encoding='utf-8')
            try:server.wait(timeout=30)
            except subprocess.TimeoutExpired:server.terminate();server.wait(timeout=10)
            server_log.close()
    print('groups',len(rows),'failed',sum(not r['passed'] for r in rows),flush=True)
if __name__=='__main__':suite()
