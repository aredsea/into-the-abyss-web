"""Full current-project test suite and local cloud service; no git or exports."""
from pathlib import Path
import subprocess,sys,json,time,re,os,socket
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/parity-r23';OUT.mkdir(exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
AUDITS=['combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
tests=['import']+sorted(p.stem for p in (ROOT/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration','balance_probe']+AUDITS)
selected=sys.argv[1:]
if selected==['list']:
    print('\n'.join(tests));raise SystemExit()
names=[n for n in tests if not selected or n in selected]
results=json.loads((OUT/'regression.json').read_text(encoding='utf-8')) if selected and (OUT/'regression.json').exists() else []
env={**os.environ,'PYTHONIOENCODING':'utf-8','ABYSS_TEST_SERVER':'http://127.0.0.1:8787'}
server=None
try:
    if any('cloud' in n for n in names):
        server_log=(OUT/'local-server.log').open('wb')
        server=subprocess.Popen(['node','--import','./tools/ui_r23_server_shutdown.mjs','server/abyss-save/test/serve.mjs'],cwd=ROOT,env=env,stdin=subprocess.PIPE,stdout=server_log,stderr=subprocess.STDOUT,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
        ready=False
        for _ in range(300):
            if server.poll() is not None:break
            # Wait for this child's ready marker, never an unrelated existing listener.
            if b'Local D1 worker' in (OUT/'local-server.log').read_bytes():
                try:
                    with socket.create_connection(('127.0.0.1',8787),timeout=.2):ready=True;break
                except OSError:pass
            time.sleep(.1)
        if not ready:raise RuntimeError('Local server did not become ready; see local-server.log')
    for name in names:
        args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if name.startswith('ui_') and name not in ['ui_rules_r23_test','ui_remaining_r23_test'] or name.endswith('_integration') else ['--headless']),'--script',f'res://tests/{name}.gd']
        start=time.monotonic()
        # This existing integration wrapper provisions an expired account and
        # runs the same test against its own real Worker/D1. serve.mjs remains
        # the local server for ordinary cloud and UI tests.
        command=['node','server/abyss-save/test/godot-r3.mjs',name] if name=='cloud_archive_r22_test' else [sys.executable,'tools/godot_r17.py',*args]
        with (OUT/(name+'.log')).open('wb') as log:
            p=subprocess.Popen(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
            try:code=p.wait(timeout=900)
            except subprocess.TimeoutExpired:
                subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);code=124
        text=(OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace')
        if name=='cloud_archive_r22_test':
            text+='\n'+(ROOT/'verification/cloud-r22/round12/cloud_archive_r22_test.log').read_text(encoding='utf-8',errors='replace')
            (OUT/(name+'.log')).write_text(text,encoding='utf-8')
        errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
        diagnostics=[s for s in text.splitlines() if 'root certificate store' in s]
        summary=[s for s in text.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|PASS|parity|battles|TESTS:',s)][-4:]
        row={'test':name,'exit':code,'errors':errors,'environment_diagnostics':diagnostics,'summary':summary,'seconds':round(time.monotonic()-start,2),'passed':code==0 and not errors}
        results=[r for r in results if r['test']!=name]+[row]
        (OUT/'regression.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print(json.dumps({**row,'errors':errors[:5],'summary':[s[:250] for s in summary]},ensure_ascii=True),flush=True)
finally:
    if server is not None:
        forced=False;stop_sent=False
        try:
            server.stdin.write(b'ABYSS_R23_STOP\n');server.stdin.flush();stop_sent=True;server.stdin.close()
        except (BrokenPipeError,OSError):pass
        try:server.wait(timeout=10)
        except subprocess.TimeoutExpired:
            forced=True;server.kill();server.wait(timeout=5)
        server_log.close()
        clean=not forced and (server.returncode==0 or (stop_sent and server.returncode==130))
        (OUT/'server-lifecycle.json').write_text(json.dumps({'pid':server.pid,'ready':ready,'exit':server.returncode,'forced_shutdown':forced,'stop_requested':stop_sent,'clean_shutdown':clean,'main':'server/abyss-save/test/serve.mjs','shutdown':'private stdin to existing SIGINT disposal handler; 130 is the requested SIGINT exit'},indent=2)+'\n',encoding='utf-8')
        if not clean:raise RuntimeError('Local server did not dispose cleanly; see server-lifecycle.json')
sys.exit(0 if all(r['passed'] for r in results) else 1)
