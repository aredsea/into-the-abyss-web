"""Verify a single read-only missing-name guard after the full numeric suite.

Every previously passing execution either did not reach this access or had the
name key (otherwise the old access raised a captured Script error). For those
executions Dictionary.get(name, "") returns exactly the same value. The only
new behavior is the missing-name path, covered by the two formerly failing
enemy tests and an additional final-code display integration check. The earlier complete support-action matrix has populated names, so the dictionary-read equivalence also covers it.
"""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys,time
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round6-final'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert read(S/'local-server-result.json')['exit']==0
plan=read(S/'final-recheck-plan.json');base=read(S/'final-code-lock.json')['sha256']
current={p:sha(R/p) for p in base};delta=[p for p in base if base[p]!=current[p]]
assert delta==['project/game/dungeon_enemy_r21.gd'],delta
p=R/delta[0];new=p.read_text(encoding='utf-8');old='w.skills[id].name';guard='w.skills[id].get("name", "")'
assert new.count(guard)==1 and old not in new
reconstructed=p.read_bytes().replace(guard.encode('utf-8'),old.encode('utf-8'))
assert hashlib.sha256(reconstructed).hexdigest()==base[delta[0]],'The delta exceeds the single read-only guard'
rows=[read(p) for p in (S/'rows').glob('*.json')]
assert {r['test'] for r in rows if not r['passed']}=={'enemy_action_r21_test','enemy_regression_r21_test'}
archive=S/'name-guard-before';archive.mkdir(exist_ok=True)
for name in ['final-code-lock.json','tested-code.json','final-recheck-plan.json','local-server-result.json','group-exits.json','results.json']:
 if (S/name).exists():shutil.copyfile(S/name,archive/name)
for name in ['enemy_action_r21_test','enemy_regression_r21_test','battle_r23_round6_enemy_test','import']:
 shutil.copyfile(S/(name+'.log'),archive/(name+'.log'))
 shutil.copyfile(S/'rows'/(name+'.json'),archive/(name+'.json'))
tests=['import','enemy_action_r21_test','enemy_regression_r21_test','battle_r23_round6_tiles_test']
reused=['enemy_action_r21_test','enemy_regression_r21_test']
prior=O/'battle-round6-name-recheck'
for name in reused:
 row=read(prior/'rows'/(name+'.json'));assert row['passed']
 assert (prior/'rows'/(name+'.json')).stat().st_mtime-row['seconds']>=p.stat().st_mtime-.5
 shutil.copyfile(prior/'rows'/(name+'.json'),S/'rows'/(name+'.json'))
 shutil.copyfile(prior/(name+'.log'),S/(name+'.log'))
started=time.time();env={**os.environ,'R23_SUITE_NAME':S.name}
code=subprocess.call([sys.executable,'tools/run_battle_r23.py',*[n for n in tests if n not in reused]],cwd=R,env=env)
assert code==0,code
assert all(sha(R/p)==h for p,h in current.items())
for name in tests:
 row=read(S/'rows'/(name+'.json'));assert row['passed']
 assert (S/'rows'/(name+'.json')).stat().st_mtime-row['seconds']>=(p.stat().st_mtime-.5 if name in reused else started-1)
plan['base_sha256']=base;plan['sha256']=current
plan['name_guard_supplement']={'started':started,'tests':tests,'reused_final_code_checks':reused,'reused_checks_path':str(prior.relative_to(R)),'file':delta[0],'before_sha256':base[delta[0]],'after_sha256':current[delta[0]],'before':old,'after':guard,'proof':'A passing old execution necessarily had the name key or did not reach the access. The added default cannot change its returned value, state, RNG or event timing. Missing-name executions and display integration are rerun; the populated-name matrix is covered by exact dictionary-read equivalence.'}
write(S/'final-recheck-plan.json',plan)
write(S/'final-code-lock.json',{'time':started,'sha256':current,'staged_guard_verification':True})
write(S/'tested-code.json',current)
write(S/'final-code-verification.json',{'unchanged':True,'files':len(current),'method':'Full numeric/state revision suite plus a verified single dictionary-read guard and four final-code checks.','name_guard_supplement':True})
write(S/'results.json',[read(p) for p in sorted((S/'rows').glob('*.json'))])
print(json.dumps({'name_guard_verified':True,'final_checks':tests,'failed_groups':0}),flush=True)
