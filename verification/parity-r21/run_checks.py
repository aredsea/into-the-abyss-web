from pathlib import Path
import sys,shutil,subprocess,json,time,hashlib,re,os
sys.stdout.reconfigure(encoding='utf-8')
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[1]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def snapshot():
    return {p.relative_to(ROOT).as_posix():sha(p) for p in ROOT.rglob('*') if p.is_file() and '.git' not in p.relative_to(ROOT).parts and not p.is_relative_to(OUT) and p.name!='PARITY-R21.md'}
def main():
    baseline=snapshot();(OUT/'workspace-before.json').write_text(json.dumps(baseline,ensure_ascii=False,indent=2),encoding='utf-8')
    runtime=OUT/'runtime';(runtime/'tools').mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/'tools/godot_r17.py',runtime/'tools/godot_r17.py')
    for p in (ROOT/'tools').glob('*'):
        if p.is_file():shutil.copy2(p,runtime/'tools'/p.name)
    shutil.copytree(ROOT/'project',runtime/'project',dirs_exist_ok=True,ignore=shutil.ignore_patterns('.godot'))
    for p in (ROOT/'verification').rglob('*'):
        if p.is_relative_to(OUT):continue
        dest=runtime/p.relative_to(ROOT)
        if p.is_dir():dest.mkdir(parents=True,exist_ok=True)
        elif p.suffix.lower() in ('.json','.lua','.gd','.txt','.csv'):
            dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
    print('Isolated project ready',flush=True)
    results=[]
    names=['import','world_test','state_test','route_test','expansion_test','motion_test','motion_asset_test','art_test','export_licenses','data_r21_test','dungeon_r21_test','enemy_action_r21_test','enemy_regression_r21_test','enemy_review_r21_test','town_r21_test','town_commerce_r21_test','ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test','motion_r9_integration','motion_r18_integration']
    for n in names:
        cmd=[sys.executable,'tools/godot_r17.py']
        if n=='import':cmd+=['--headless','--editor','--import','--quit']
        else:cmd+=(['--position','-10000,-10000'] if n.startswith('ui_') or n.endswith('_integration') else ['--headless'])+['--script',f'res://tests/{n}.gd']
        start=time.time()
        try:
            r=subprocess.run(cmd,cwd=runtime,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120,env={**os.environ,'PYTHONIOENCODING':'utf-8'})
            log=r.stdout.decode('utf-8',errors='replace');code=r.returncode
        except subprocess.TimeoutExpired as e:log=(e.stdout or b'').decode('utf-8',errors='replace')+'\nTIMEOUT';code=-1
        (OUT/f'{n}.log').write_text(log,encoding='utf-8')
        errors=[l for l in log.splitlines() if re.search(r'(^|\s)(?:SCRIPT ERROR|ERROR):|\bFAIL(?:ED)?\b|TIMEOUT',l) and 'certificate' not in l.lower() and 'Condition "status' not in l]
        result={'name':n,'command':cmd,'cwd':str(runtime),'exit_code':code,'seconds':round(time.time()-start,2),'errors':errors,'summary':[l for l in log.splitlines() if re.search(r'CHECK|FAILURE|PASS|DUNGEON_R21|DATA_R21|ENEMY_|R19:|R18:|Exported',l)]}
        results.append(result);(OUT/'checks.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
        print(json.dumps(result,ensure_ascii=False),flush=True)
    after=snapshot();changed=[p for p in sorted(set(baseline)|set(after)) if baseline.get(p)!=after.get(p)]
    (OUT/'write-audit.json').write_text(json.dumps({'files_checked':len(baseline),'changed_outside_allowed':changed},ensure_ascii=False,indent=2),encoding='utf-8')
if __name__=='__main__':main()
