"""Required regression via the isolated launcher; never exports, git, or deploys."""
from pathlib import Path
import subprocess,sys,json,time,re
root=Path(__file__).resolve().parents[1]
folder=root/'verification/facilities-r22';folder.mkdir(exist_ok=True)
headless=['world_test','state_test','route_test','expansion_test','motion_test','motion_asset_test','art_test','export_licenses','data_r21_test','dungeon_r21_test','enemy_action_r21_test','enemy_regression_r21_test','enemy_review_r21_test','town_r21_test','town_commerce_r21_test','persona_research_r21_test','affection_r21_test','recruit_r21_test','dialogue_player_r21_test','persona_r22_test','cloud_r22_test','expedition_r22_test','facilities_r22_test']
native=['ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test','motion_r9_integration','motion_r18_integration','ui_data_r21_test','ui_town_r21_test','ui_town_r21_round2_test','ui_town_r21_round3_test','ui_town_r21_round4_test','ui_town_r21_round5_test','ui_town_result_r21_test','ui_dialogue_r21_test','ui_persona_r22_test','ui_cloud_r22_test','ui_expedition_r22_test','ui_facilities_r22_test']
selected=sys.argv[1:]
result=json.loads((folder/'regression.json').read_text(encoding='utf-8')) if selected and (folder/'regression.json').exists() else []
for name in selected or ['import']+headless+native:
    args=[sys.executable,'tools/godot_r17.py']+(['--headless','--editor','--import','--quit'] if name=='import' else [*(['--headless'] if name in headless else ['--position','-10000,-10000']),'--script',f'res://tests/{name}.gd'])
    start=time.monotonic()
    try:
        p=subprocess.run(args,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=240)
        log=p.stdout.decode('utf-8',errors='replace');code=p.returncode
    except subprocess.TimeoutExpired as e:
        log=(e.stdout or b'').decode('utf-8',errors='replace')+'\nTIMEOUT';code=124
    (folder/(name+'.log')).write_text(log,encoding='utf-8')
    errors=[s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
    summary=[s for s in log.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|PASS|TESTS:',s)][-3:]
    row={'test':name,'exit':code,'errors':errors,'summary':summary,'seconds':round(time.monotonic()-start,2)}
    result=[r for r in result if r['test']!=name];result.append(row)
    (folder/'regression.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({**row,'errors':errors[:5],'summary':[s[:500] for s in summary]},ensure_ascii=True),flush=True)
sys.exit(1 if any(r['exit'] or r['errors'] for r in result) else 0)
