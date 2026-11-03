"""Publish only evidence that passed against the final locked product code."""
from pathlib import Path
from collections import Counter
import hashlib,json,shutil,time
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round7-final-v2'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
prior=read(O/'battle-round7-prior.json');coverage=read(O/'coverage.json');cov={r['id']:r for r in coverage['rows']}
packs={}
for suffix in ['', '-persona', '-boundary']:
 stem='battle-round7'+suffix;manifest=read(O/(stem+'-oracle.json'));observed=read(O/(stem+'-latest.json'))
 assert observed['checks']==sum(p['rows'] for p in manifest['parts'])==len(observed['rows']) and not observed['failures']
 assert all(r['ok'] for r in observed['rows'])
 for p in manifest['parts']:
  assert sha(O/p['file'])==p['sha256'] and (O/p['file']).stat().st_size==p['bytes']<40*1024*1024
 for name,h in manifest['provenance'].items():assert sha(Path('C:/Clauede Code/dungeon-bot/bot/src')/name)==h
 packs[suffix]={'counts':manifest['counts'],'checks':observed['checks'],'oracle':'verification/parity-r23/'+stem+'-oracle.json','observations':'verification/parity-r23/'+stem+'-latest.json'}
assert len(coverage['runs'])==26 and all(r['exit']==0 for r in coverage['runs'])
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
suite=[read(p) for p in (S/'rows').glob('*.json')];assert {r['test'] for r in suite}==expected
assert all(r['passed'] and not r['errors'] for r in suite)
assert read(S/'final-code-verification.json')['unchanged']
lock=read(S/'final-code-lock.json');assert lock['sha256']==read(S/'tested-code.json')
assert all(sha(R/name)==h for name,h in {**lock['sha256'],**lock['inputs']}.items())
assert read(S/'local-server-result.json')['exit']==0
for name in ['battle_r23_round7_test','battle_r23_round7_persona_test']:
 assert read(S/'rows'/(name+'.json'))['passed']
parity=[]
for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
 j=read(R/'verification/data-r21'/(name+'.json'));assert j['battles']==j['equal_battles'] and j['source_actions']==j['actual_actions']==j['matched_actions'];parity.append(j)
p2=read(R/'verification/data-r21/p2-full-battles.json');assert p2['different_actions']==0
battles=sum(j['battles'] for j in parity)+p2['battles'];records=sum(j['source_actions'] for j in parity)+p2['compared_actions'];assert (battles,records)==(6320,219785)
manifest=read(O/'battle-round7-start-manifest.json');protected={}
for folder,old in manifest['protected'].items():
 now={str(p.relative_to(R)).replace('\\','/'):sha(p) for p in (R/folder).rglob('*') if p.is_file() and 'node_modules' not in p.parts}
 assert now==old,folder
 protected[folder]={'files':len(now),'changed':[]}
assets=read(R/'ASSET-HASHES.json');assert len(assets)==96 and all(sha(R/a['path'])==a['sha256'] for a in assets)
visual=read(O/'battle-round7-visual-review.json');assert all(i['viewed'] and sha(R/i['path'])==i['sha256'] for i in visual['images'])
before=read(O/'battle-round7-before-replay.json');assert before['checks']==656
before_stats={'checks':before['checks'],'differences':len(before['failures']),'by_operation':dict(Counter(r['label'].split('/')[2] for r in before['rows'] if not r['ok'])),'method':'작업 시작 때 보존한 battle_v3/dungeon_enemy 두 파일과 최종 동일 입력/관측 adapter로 기존 4경로를 재실행. 이전 전체 빌드라고 주장하지 않음. API 부재 guard는 이 차이 수에 포함하지 않음.'}
for file in ['battle_v3.gd','dungeon_enemy_r21.gd','combat_events_r22.gd','personal_rules_r22.gd']:
 assert sha(O/('battle-round7-before-'+file))==manifest['initial_files']['project/game/'+file]
mapping={
 'P1772':('', 'cutin','combat_events_r22.gd','func cutin','대사 4종/대사 없는 id/미지·빈 id, 이름 없음/있음, T=0/소수/양수. cut payload·문구·T 전체와 실제 begin 경로 연결.'),
 'P1871':('', 'foe_line','dungeon_enemy_r21.gd','func foe_line','ko/en, 받침/HTML 이름, 태그 없음/다중·보호막·부상·1/4칸의 문구 반환 전체.'),
 'P1877':('', 'foe_hit_after','dungeon_enemy_r21.gd','func after_hit','32규칙/방어/보스 감경/행동자 생사 조합과 3시각. weak-hit 지연·재진입 억제·반격·로그·필드 이력·RNG. 기존 실제 적/처치 경계 대조와 결합.'),
 'P1880':('', 'counter','dungeon_enemy_r21.gd','func counter','288 HP/보호막/방어/방어 강화·공격 약화·am/0계수·3시각. strike 결과의 tags·kill·ls, 사건·로그·필드 이력·RNG. 중립/무장비 전체 부수 출력과 기존 수치·장비 회귀를 구분.'),
 'P1885':('', 'edot_tick','dungeon_enemy_r21.gd','func tick_dot','빈/1/2/4줄, 0피해 줄, 수명 -1/0/1/3, 죽음/보호막/방어. kill 반환·잔여 DOT·고정 피해·사건/로그/필드 이력/T/RNG. 실제 _tick에서 공통 경로 사용.'),
 'P1910':('', 'e_dot','dungeon_enemy_r21.gd','func dot_action','회피 참/거짓, 계수/지속 누락·0·경계, 기존 0/4줄 FIFO. DOT 상태와 두 반환 경로의 전체 사건·로그·T·RNG. 회피 결과만 외부 훅 의존성으로 주입하며 실제 회피 훅은 6320판 회귀로 확인.'),
 'P1912':('', 'summon','dungeon_enemy_r21.gd','func summon_one','기존 25경계의 수치/정의·RNG와 새 128조합의 전체 기록을 결합. empty 우선, 죽은 minion 재사용/현재 사건 점유/생존 상한. 원본 slot/nil 반환을 e_summon의 tg·중단 결과로 직접 관측; native는 같은 칸의 unit/빈 map ABI.'),
 'P1919':('', 'summon','dungeon_enemy_r21.gd','func summon(','32저장/사건 조합 × 0/1/3/6회. 생성 목록/tgs, 빈 소환/등장 문구, 전체 ev.h·log·T·RNG. 기존 25개의 전체 유닛 통계/정의 비교와 결합.'),
 'P1930':('-boundary', 'dispatch','dungeon_enemy_r21.gd','func dispatch','11종 dispatch(모든 지원 종류·미지/atk/guard 무동작), 주 묶음 6입력과 기존 100종 동작 회귀. 실제 dispatch의 payload·상태·기록·RNG; 상위 enemy_turn 전체 완료로 전파하지 않음.'),
 'P1931':('', 'charge_cancel','dungeon_enemy_r21.gd','func cancel_charge','기본 적 및 실제 break_self 적, HP 1/2/1000·보호막·행동 index 경계. cq/ia와 HP/SH 시간 이력·로그·반환 전체, 기존 3실제 HP 경계도 유지.'),
 'P1934':('', 'phase','dungeon_enemy_r21.gd','func enter_phase2','9실제 단계 보스·동시 2마리, HP 문턱·ph·생사·ev 유무의 전체 전환 기록/RNG. 기존 통계/정의/약점 경계 대조와 결합. 별도 RNG=0/1 의존성 경계가 두 clamp 분기도 직접 통과.'),
 'P1942':('', 'phase','dungeon_enemy_r21.gd','func phase_check','ev 없음→0, ph1/2·생사·문턱 위/동일·동시 2보스의 반환 전환 수와 전체 시간/로그/RNG. 실제 진행은 _tick이 기록장을 먼저 초기화.'),
 'P1679':('-persona','work','persona_research_r21.gd','static func draft_work','저장/편집 조합과 false·scalar·빈 table의 우선순위, 정규화 반환 전체. native research_work/transition에 공통 helper 연결.'),
 'P1680':('-persona','same','persona_research_r21.gd','static func same_parts','모든 유효 32조합 및 미완성/무효 조합, 사용하지 않는 조각 강화와 음수/소수/숫자 문자열/hex/상한. prefix/suffix·전체 조각 단계의 동일 판정.'),
 'P1681':('-persona','dirty','persona_research_r21.gd','static func draft_dirty','ui/psd 타입 경계와 저장/편집 조합 교차 비교. 실제 native research_dirty가 같은 helper 사용.'),
 'P1687':('-persona','changes','persona_research_r21.gd','static func changes','조합 변경과 선택/미선택 모든 조각의 강화 변경을 데이터 순서로 영어 배열 전체 비교. 장면 전달(save)의 완료로 전파하지 않음.'),
}
fixed={'P1772','P1871','P1877','P1880','P1885','P1910','P1919','P1931','P1934','P1942'}
hosts={
 'P1596':'RisuAI 채팅 길이/role 검색. 공통 기능 등가 기준의 호스트 전용 함수.',
 'P3502':'RisuAI 재렌더·메시지 갱신 callback. 공통 기준에 따라 제외.',
 'P3505':'RisuAI 채팅 변수 load/bind/act/save/redraw 호스트 묶음. B.act 및 원본 저장 왕복 자체는 별도 잔여 행으로 유지.',
}
rows=[]
for old in prior['rows']:
 r=dict(old);r['round6_status']=old['status'];r['branch_coverage']=cov[r['id']]
 if r['id'] in mapping:
  suffix,op,file,symbol,contract=mapping[r['id']];p=packs[suffix]
  assert old['status']!='같음' and cov[r['id']]['called'] and not cov[r['id']]['remaining_entries'],r['id']
  line=next(i+1 for i,s in enumerate((R/'project/game'/file).read_text(encoding='utf-8').splitlines()) if symbol in s)
  r.update(status='같음',remaining_reason=None,unverified_branches=[],native_evidence={'file':'project/game/'+file,'symbol':symbol,'line':line})
  extra=[{'test':'battle_r23_round7_persona_test' if suffix=='-persona' else 'battle-round7-boundary-test' if suffix=='-boundary' else 'battle_r23_round7_test','labels':['round7/'+op],'checks':p['counts'][op],'contract':contract,'oracle':p['oracle'],'observations':p['observations']}]
  if r['id']=='P1934':extra.append({'test':'battle-round7-boundary-test','checks':2,'oracle':packs['-boundary']['oracle'],'observations':packs['-boundary']['observations'],'contract':'실제 PM의 [0,1) 영역 밖인 1은 의존성 방어 경계로 구분. canonical B.enter_phase2의 난수 clamp를 직접 실행.'})
  r['new_evidence']=r['new_evidence']+extra
 if r['id'] in fixed:r['fixed']=True;r['round7_fix']='실제 전투 경로의 원본 기록·문구·시각/반환 계약 보완';r['fix']=(r.get('fix')+' / ' if r.get('fix') else '')+r['round7_fix']
 if r['id'] in hosts:
  r.update(status='제외',remaining_reason=None,exclusion_reason=hosts[r['id']])
  r['new_evidence']=r['new_evidence']+[{'rule':'r21-common.md 기능 등가/호스트 전용(11-03)','source':r['source'],'contract':hosts[r['id']]}]
 if r['id'] in ['P1594','P1595']:
  r['remaining_reason']='저장 매체 차이는 사유에서 제거. 원본 VER2 기록을 native에서 불러와 같은 다음 행동/소지·장착·진행으로 재개하는 직접 왕복 대조와 손상 입력 결과 비교가 아직 없음. 원본 migrate 대조 및 native 자체 restore 통과만으로 전체 load/save 행을 승격하지 않음.'
 if r.get('native_evidence'):
  ref=dict(r['native_evidence']);lines=(R/ref['file']).read_text(encoding='utf-8').splitlines();ref['line']=next(i+1 for i,s in enumerate(lines) if ref['symbol'] in s);r['native_evidence']=ref
 rows.append(r)
products=[str(p.relative_to(R)).replace('\\','/') for p in (R/'project/game').glob('*.gd') if manifest['initial_files'].get(str(p.relative_to(R)).replace('\\','/'))!=sha(p)]
checks=sum(p['checks'] for p in packs.values());equal=sum(r['status']=='같음' for r in rows);excluded=sum(r['status']=='제외' for r in rows);remaining=sum(r['status'] not in ['같음','제외'] for r in rows)
assert (len(rows),equal,excluded,remaining)==(212,169,3,40)
summary={**prior['summary'],'newly_equal_rows':equal,'remaining_rows':remaining,'excluded_rows':excluded,'statuses':dict(Counter(r['status'] for r in rows)),'fixed_rows':sum(r['fixed'] for r in rows),'fixed_and_equal_overlap':sum(r['fixed'] and r['status']=='같음' for r in rows),'round7_newly_equal_rows':len(mapping),'round7_excluded_rows':len(hosts),'round7_fixed_evidence_rows':len(fixed),'round7_new_fixed_rows':sum(r['id'] in fixed and not r['fixed'] for r in prior['rows']),'round7_checks':checks,'new_checks':prior['summary']['new_checks']+checks,'new_failures':0,'suite_groups':len(suite),'expected_suite_groups':len(expected),'suite_failed_groups':0,'suite_missing':[],'suite_in_progress':[],'suite_final_code_complete':True,'suite_verification_method':'118 groups on unchanged final product code; one test-fixture prerequisite corrected and rechecked with unchanged expectations; 13-case boundary supplement','called_functions':coverage['called_functions'],'newly_entered_baseline_entries':coverage['newly_entered_baseline_entries'],'fresh_oracle_runs':len(coverage['runs']),'parity_battles':battles,'parity_records':records,'round7_product_files_changed':products,'product_files_changed':sorted(set(prior['summary']['product_files_changed']+products)),'protected':protected}
summary['fixed_but_not_equal_rows']=sum(r['fixed'] and r['status'] not in ['같음','제외'] for r in rows);summary['neither_equal_nor_fixed_rows']=sum(not r['fixed'] and r['status'] not in ['같음','제외'] for r in rows)
supplement={str(p.relative_to(R)).replace('\\','/'):sha(p) for p in O.glob('battle-round7-boundary*') if p.is_file()}
round7={'new_equal_ids':sorted(mapping),'excluded_ids':hosts,'fixed_evidence_ids':sorted(fixed),'checks':checks,'before_replay':before_stats,'suite':S.name,'supplement_sha256':supplement,'functional_rule':'HTML/저장 매체 자체는 다름의 사유가 아님. 호스트 3행은 제외. 실제 수치·난수·순서·로그와 원본 저장 재개 기능은 그대로 비교.','limitations':'169행 같음은 이번 대상 212행의 함수별 근거다. 전 봇 완성도나 6320판에서 모든 문자열/시간까지 전수 비교했다는 뜻이 아니다. 40행은 시작/종결·공격 전체·훅 합성·일부 개인/페르소나 기술·행동/렌더·저장 재개 경계가 남는다.'}
new_tools=[str(p.relative_to(R)).replace('\\','/') for folder in ['tools','project/tests'] for p in (R/folder).glob('*') if p.is_file() and p.suffix in ['.py','.gd','.mjs','.lua'] and manifest['initial_files'].get(str(p.relative_to(R)).replace('\\','/'))!=sha(p)]
write(O/'battle.json',{**prior,'summary':summary,'rows':rows,'round7':round7,'test_tool_files':sorted(set(prior.get('test_tool_files',[])+new_tools)),'target_tests':prior['target_tests']+[{'name':'battle-round7'+suffix,'checks':p['checks'],'failures':0} for suffix,p in packs.items()]})
write(O/'battle-round7.json',read(O/'battle.json'));write(O/'summary.json',summary)
write(S/'final-verification.json',{'passed':True,'groups':len(suite),'battles':battles,'records':records,'assets':96,'protected_verified':True,'code_locked':True,'source_inputs_locked':True,'boundary_supplement':supplement})
if not (R/'R23-battle-round6.md').exists():shutil.copyfile(R/'R23-battle.md',R/'R23-battle-round6.md')
groups=[]
for name in sorted({r['feature_group'] for r in rows}):
 rs=[r for r in rows if r['feature_group']==name];groups.append(f'| {name} | {sum(r["status"]=="같음" for r in rs)} | {sum(r["status"]=="제외" for r in rs)} | {sum(r["status"] not in ["같음","제외"] for r in rs)} |')
lines=['# R23-battle 7차 보고','',f'대상 212행: 같음 169(+16), 호스트 제외 3, 남음 40. 이번 수정 근거 10행(기존 수정 행과 중복), 누적 수정 근거 {summary["fixed_rows"]}행. 남은 40행이 있어 전 기능 완료는 아니다.','',f'신규 묶음 대조 {checks:,}개(전투 1,418 + 페르소나 5,903 + 방어 경계 13), 실패 0. 누적 신규 대조 {summary["new_checks"]:,}개, 실패 0. 전체 프로젝트 {len(suite)}/{len(expected)}그룹과 import/로컬 클라우드 서버 통과. 기존 6,320판·219,785기록 차이 0.','',f'원본 Lua 26종을 함수/then/else/do 진입 계측으로 다시 실행했다. 계측 전후 반환 결과가 같고, 기존 6,320판 원본 trace도 저장된 기준과 같았다. 함수 {coverage["called_functions"]}/212 호출, 기준 미검증 진입 {coverage["newly_entered_baseline_entries"]}/157 도달(6차 100). 조건 조합 전수 검증 수치는 아니다. coverage/에는 새 oracle 중복 사본을 만들지 않고 메모리에서 비교한다.','', '반격·피격 후 지연·적 DOT·소환·충전 취소·단계 전환의 실제 전투 경로에서 원본 사건, 필드 시간 이력, 로그 문구와 T를 기록하도록 보완했다. 컷인에는 원본 skill id별 대사와 이름을 기록한다. 페르소나 연구의 임시 조합 우선순위·전체 조각 비교·dirty·변경 서술 배열을 원본과 대조하고 기존 연구 경로에 공통 helper를 연결했다. persona_world.gd는 이 연결 두 줄만 바꿨다.','',f'실패 확인: 작업 시작 시 보존한 Battle/Enemy 파일과 최종 동일 입력으로 656개를 재생해 {before_stats["differences"]}개 관측 차이를 확인했다. '+str(before_stats['by_operation'])+'. 같은 경로는 수정 후 통과한다. 이는 이전 전체 빌드가 아니라 보존한 두 파일의 실제 실행이다. 새 API 부재 guard는 수치 버그 수로 세지 않았다.','', '전체 검사 중 독립 _tick/DOT 호출이 기록장 없이 시작하는 오류를 확인해 초기화를 보완했다. 관련 A6 251개 통과 후 코드와 기본 입력 SHA를 다시 고정하여 suite-round7-final-v2 전체 검사를 재실행했다. 이전 중간 결과는 최종 통과 수에 섞지 않았다. Windows root certificate store 진단만 환경 메시지로 제외하고 Script error와 다른 ERROR는 실패로 셌다.','', '검사 도구도 수정했다. 빈 병렬 실행 그룹이 전체 검사를 중복 실행하던 경로를 막고, 이미 시작한 자체 검사에는 파일 기반 중단 표식을 적용했다. 최초 로컬 서버는 긴 임시 경로에서 시작 오류가 났으나 짧은 worktree 내부 .p7tmp로 옮긴 실제 serve.mjs/D1 서버로 최종 검사를 통과했다. 서버 종료 확인은 final-v2/local-server-result.json에 있다.','', '기능 등가 규칙을 재적용했다. 채팅 검색(P1596), 재렌더 callback(P3502), 채팅 변수 load/bind/act/save 호스트 묶음(P3505)을 제외했다. B.act 자체는 여전히 남음이다. B.load/save는 저장 매체가 달라서 남긴 것이 아니라 원본 기록을 native에서 같은 진행으로 재개하는 직접 왕복·손상 입력 대조가 부족하여 남겼다.','', '| 묶음 | 같음 | 제외 | 남음 |','| --- | ---: | ---: | ---: |',*groups,'', '각 행의 원래 id·원본 위치·6차 상태·시험명·제품 파일:줄·남은 이유: verification/parity-r23/battle.json. 남은 범위는 fresh/again/redo·battle_start 전체, fire/chain 합성, strike/abyss·공격/종결/run·버튼 전체, 일부 개인/종족·페르소나 기술과 연구 행동/장면, 행동 패널/최상위 렌더, 원본 저장 재개다. 이번 중립/무장비 부수 출력 대조를 장비 혼합 전투의 전체 문자열/시간 대조로 확대하지 않는다.','', '원본 이미지 96개 해시 일치. 작업 시작 manifest 대비 docs/assets/server 해시 불변. 사용자 저장을 열거나 지우지 않았다. Web export·버전 갱신·git 명령 없음. r17~r20과 컷인 렌더 5장을 직접 열어 확인했고, 전수 프레임/실기기/Web/WASM은 확인하지 않았다. 새 대조 파일은 battle- 접두사이며 모두 40 MiB 미만이다.','', '바꾼 제품 파일:',*['- '+p for p in products],'', '재실행: oracle_battle_r23_round7_loader.mjs(기본/환경 R23_ROUND7_PACK=persona,boundary) → coverage_battle_r23.py → verify_battle_r23_round7.py → 별도 battle-round7-boundary-test.gd 및 prepare_battle_r23_round7_before.py → 렌더 확인 → report_battle_r23_round7.py.']
lines[12:12]=['final-v2 실행 중 enemy_regression의 직접 phase_check 시험에도 같은 begin_ev 전제 누락이 있었다. 기대값은 유지하고 시험 준비 두 줄만 보정해 30항목을 재실행했다. 제품 코드는 그 전후 SHA가 모두 같으며 다른 117그룹의 입력/코드도 불변이다. fixture-correction-audit.json에 이전 시험/로그, 유일한 변경과 재실행을 보존했다. 실행기의 최종 코드 guard는 이 시험 파일 변경을 검출해 종료 1을 반환했으며, 별도 finalize_battle_r23_round7.py가 제품 불변·유일한 fixture 변경·118그룹 결과를 검증해 최종 lock을 확정했다.','']
lines+=['','바꾼 시험/도구:',*['- '+p for p in new_tools]]
(R/'R23-battle.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
write(O/'battle-round7-report-summary.json',summary)
print(json.dumps({k:summary[k] for k in ['round7_newly_equal_rows','newly_equal_rows','excluded_rows','remaining_rows','round7_checks','fixed_rows','suite_groups','parity_battles','parity_records']},ensure_ascii=False))
