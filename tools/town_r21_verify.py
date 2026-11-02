"""Run the required common checks once and retain exact stdout and exit codes."""
from pathlib import Path
import subprocess,sys,json,re,time
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';O.mkdir(exist_ok=True)
headless=['world_test','state_test','route_test','expansion_test','motion_test','motion_asset_test','art_test','export_licenses','town_r21_test','data_r21_test','dungeon_r21_test','enemy_action_r21_test','enemy_regression_r21_test','enemy_review_r21_test','town_commerce_r21_test','persona_research_r21_test','affection_r21_test','dialogue_player_r21_test','recruit_r21_test']
render=['ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test','motion_r9_integration','motion_r18_integration','ui_town_r21_test','ui_town_r21_round2_test','ui_data_r21_test','ui_town_r21_round3_test','ui_town_result_r21_test','ui_town_r21_round4_test','ui_town_r21_round5_test','ui_dialogue_r21_test']
selected=set(sys.argv[1:])
headless+=['persona_r22_test','persona_town_r21_round8_test']
render+=['ui_persona_r22_test','ui_persona_town_round8_test']
results=json.loads((O/'common-results.json').read_text(encoding='utf-8')) if selected and (O/'common-results.json').exists() else []
commands=[('import',['--headless','--editor','--import','--quit'])]+[(name,['--headless' if name in headless else '--position']+([] if name in headless else ['-10000,-10000'])+['--script',f'res://tests/{name}.gd']) for name in headless+render]
if selected:commands=[c for c in commands if c[0] in selected]
for name,args in commands:
    start=time.monotonic()
    p=subprocess.run([sys.executable,str(R/'tools/godot_r17.py'),*args],cwd=R,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,encoding='utf-8',errors='replace',timeout=240)
    (O/f'{name}.log').write_text(p.stdout,encoding='utf-8')
    errors=[line for line in p.stdout.splitlines() if ('SCRIPT ERROR:' in line or 'FAIL:' in line or ('ERROR:' in line and 'root certificate store' not in line))]
    summary=[line for line in p.stdout.splitlines() if re.search(r'CHECK|FAILURE|PASS|Exported|Integration',line,re.I)]
    item={'name':name,'exit_code':p.returncode,'seconds':round(time.monotonic()-start,2),'errors':errors,'summary':summary[-8:],'environment_certificate_warning':'root certificate store' in p.stdout}
    results=[r for r in results if r['name']!=name];results.append(item);(O/'common-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
    print(name,'PASS' if p.returncode==0 and not errors else 'FAIL',item['seconds'],summary[-1:] or '',flush=True)
print('COMMON CHECK GROUPS',len(results),'FAILED',sum(r['exit_code']!=0 or bool(r['errors']) for r in results),flush=True)
sys.exit(1 if any(r['exit_code'] or r['errors'] for r in results) else 0)
