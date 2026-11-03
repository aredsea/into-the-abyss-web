"""Publish R23 round 8 only from the final locked suite and hashed oracles."""
from pathlib import Path
from collections import Counter
import hashlib,json,shutil
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round8-final-v7'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
prior=read(O/'battle-round8-prior.json');coverage=read(O/'coverage.json');cov={r['id']:r for r in coverage['rows']}
packs={}
for suffix,test in [('', 'battle_r23_round8_test'),('-outcome','battle_r23_round8_outcome_test'),('-persona','battle_r23_round8_persona_test')]:
 stem='battle-round8'+suffix;m=read(O/(stem+'-oracle.json'));a=read(O/(stem+'-latest.json'));oracle_count=sum(p['rows'] for p in m['parts'])
 assert a['checks']==oracle_count+(1 if suffix=='-outcome' else 0)==len(a['rows']) and not a['failures'] and all(r['ok'] for r in a['rows'])
 for p in m['parts']:assert sha(O/p['file'])==p['sha256'] and (O/p['file']).stat().st_size==p['bytes']<40*1024*1024
 for name,h in m['provenance'].items():assert sha(Path('C:/Clauede Code/dungeon-bot/bot/src')/name)==h
 packs[suffix]={'test':test,'counts':m['counts'],'checks':a['checks'],'source_checks':oracle_count,'oracle':'verification/parity-r23/'+stem+'-oracle.json','observations':'verification/parity-r23/'+stem+'-latest.json'}
assert len(coverage['runs'])==29 and all(r['exit']==0 for r in coverage['runs'])
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
suite=[read(p) for p in (S/'rows').glob('*.json')];assert {r['test'] for r in suite}==expected
assert all(r['passed'] and not r['errors'] for r in suite)
assert read(S/'final-code-verification.json')['unchanged'] and read(S/'local-server-result.json')['exit']==0
lock=read(S/'final-code-lock.json');assert lock['sha256']==read(S/'tested-code.json')
assert all(sha(R/n)==h for n,h in {**lock['sha256'],**lock['inputs']}.items())
assert all(p.stat().st_mtime>=lock['time'] for p in (S/'rows').glob('*.json'))
assert (S/'final-code-verification.json').stat().st_mtime>=lock['time']
assert read(S/'group-exits.json')==[0,0,0,0]
parity=[]
for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
 a=read(R/'verification/data-r21'/(name+'.json'));assert a['battles']==a['equal_battles'] and a['source_actions']==a['actual_actions']==a['matched_actions'];parity.append(a)
p2=read(R/'verification/data-r21/p2-full-battles.json');assert p2['different_actions']==0
battles=sum(a['battles'] for a in parity)+p2['battles'];records=sum(a['source_actions'] for a in parity)+p2['compared_actions'];assert (battles,records)==(6320,219785)
start=read(O/'battle-round8-start-manifest.json');protected={}
for folder in ['docs','project/assets','server']:
 old={n:h for n,h in start.items() if n.startswith(folder+'/')}
 now={p.relative_to(R).as_posix():sha(p) for p in (R/folder).rglob('*') if p.is_file()}
 assert old==now,folder
 protected[folder]={'files':len(now),'changed':[]}
assets=read(R/'ASSET-HASHES.json');assert len(assets)==96 and all(sha(R/a['path'])==a['sha256'] for a in assets)
before=read(O/'battle-round8-before-replay.json');assert before['checks']==8324
before_counts=Counter(r['label'].split('/')[1] for r in before['rows'] if not r['ok']);assert len(before['failures'])==sum(before_counts.values())
audit=read(R.parent/'r21-parity/verification/parity-r21/audit-r22b.json');original={r['id']:r for g in audit['remaining_work'] for r in g['items']}
assert all(r['id'] in original and r['source']==original[r['id']]['source'] for r in prior['rows'])
# Evidence is per function; execution coverage alone never promotes a row.
mapping={
 'P1737':('', 'end_turn','battle_v3.gd','func end_turn_state','384개 직접 차례 종료의 oath/bt/shT·fresh buff·침묵·0/기본/긴 비용과 필드 이력. 기존 개인 turn_end/regen 회귀와 실제 finish 연결 유지.'),
 'P1760':('', 'abyss','personal_rules_r22.gd','static func abyss_result','512개에서 무효/고갈/사망·반올림·전염·반환 n/list·nd·사건/로그/필드 시각 비교. 실제 일반 공격과 개인/페르소나 기술에 같은 경로 연결. 장비 합성 수치는 기존 대조 유지.'),
 'P1789':('', 'dot_push','battle_v3.gd','func _push_class_dot','cap 5/6, 0/4/5/6/9 기존 줄, 혼합 출혈·소유자 없음/1/4·수명 0/1/3의 배열·순서·반환 전체 90개. A6 옛 집계형/장비 독·폭발 회귀 함께 통과.'),
 'P1806':('', 'can_use','battle_v3.gd','func unavailable','개인 기술 30인+미등록, nil·일반/혈욕/개인 기술, MP 4경계·HP 4경계·사용 플래그·침묵의 7936개 Boolean. 기존 장비 MP 할인 회귀 유지.'),
 'P1824':('-outcome','experience','combat_outcome_r23.gd','func experience','옛 고정/조합, ★1/3/9·Lv1/10/40·레이드·8등급(미등록 포함)·빈 칸·의뢰/심층/층/누적 EXP·출전자 보너스 1440개.'),
 'P1830':('-outcome','check_end','combat_outcome_r23.gd','func check_end','256개에서 이미 종료·적 전멸 우선·아군 전멸·399/400 행동·finish 전 부수 효과와 반환을 전체 상태로 직접 비교. native _check_end의 동일 종료 우선순위/실제 정산 연결 회귀.'),
 'P1842':('', 'abyss','personal_rules_r22.gd','static func abyss_result','512개 abyss 묶음 안의 레비아 소유자 조건·0/1 반올림·적 사망/고갈·전염 list·nd·필드/사건 시각. 기본 공격에서도 같은 helper 실행.'),
 'P1945':('-outcome','experience','combat_outcome_r23.gd','func experience','1440개 묶음의 조합 절반에서 원래 등급/하수인/빈 칸·레이드·층·심층·의뢰/출전자 배수·누적 경험치 반환. 소환 하수인의 EXP=0 정본 유지.'),
 'P2004':('', 'judith','personal_rules_r22.gd','static func judith','42개에서 재시전·slow 만료 라운드·보스 감경·손상 x(false/숫자)·부식 순서·전체 사건/로그/필드 이력/T 직접 비교.'),
 'P2171':('', 'jorund','personal_rules_r22.gd','static func hit_after','256개 직접 훅: 기존 줄 없음/만료·0~3중첩·사망/보스·기존 지연 합성·폭발·kill credit·로그/사건 시각까지 비교.'),
}
fixed={'P1737','P1760','P1806','P1811','P1812','P1825','P1830','P1842','P2004','P2171','P2220','P1688','P1692'}
partial={
 'P1811':('', 'enemy_attack','단일/전체 256입력: 회피·대신 맞기·사망·사격·강타·HP 공격 보정·지연·흡혈·DOT·강화 제거 전체 상태/기록. 여러 개인/장비 반격 훅이 섞인 모든 사건 문자열·순서의 직접 대조는 남음.'),
 'P1812':('', 'enemy_attack','단일/전체 256입력의 대상별 시각·사망·보호자 상태·tags·피격 후 효과 비교. 다중 반격/장비 훅 혼합의 전체 사건/로그 대조는 남음.'),
 'P1825':('-outcome','finish','256개 직접 원본 모양 정산에서 결과문·부상자·EXP·로그·종료 이벤트·cur/q·재호출 일치. 실제 native world의 모든 의뢰 rg/qmult·출처 메타데이터가 결과 기록에 들어오는 연결 대조는 남음.'),
 'P2220':('', 'damaged_cleanup','64개에서 생존 소유자/시전자 사망·src별 red/red20·adeline 전 칸 areg 제거 확인. old damaged callback(특히 Sorel 회복)과 모든 전투 훅을 합친 전체 대조는 남음.'),
 'P1688':('-persona','research_action','16038개 core(saved/draft/spent/gold/message) 전이 묶음에서 저장 조건/ready/dirty/busy 및 한영 문구 비교. 원본 pending 장면 지시·chat transport는 별도 관측만 했으며 native 대화 재개 대응 검증은 남음.'),
 'P1692':('-persona','research_action','16038개: 모든 prefix/suffix·무효 arg·0/9/10 강화·금화 부족·draft/spent 제거·저장 조건, 한영 core 전이 일치. ps_save의 장면 pending/대화 연계 전체는 남음.'),
}
partial['P1825']=('-outcome','finish','256개 직접 원본 모양 정산에서 결과문·부상자·EXP·로그·종료 이벤트·cur/q·재호출 일치. 실제 native world의 모든 의뢰 rg/qmult·출처 연결과 저장 재개 뒤 nd/마지막 일격 기록 복구는 남음.')
v=list(mapping['P1824']);v[-1]=v[-1].replace('8등급(미등록 포함)','10등급(무효 식별자 포함)');mapping['P1824']=tuple(v)
rows=[]
for old in prior['rows']:
 r={**old,'round7_status':old['status'],'branch_coverage':cov[old['id']]}
 if r['id'] in mapping:
  suffix,op,file,symbol,contract=mapping[r['id']];assert old['status']!='같음' and cov[r['id']]['called'] and not cov[r['id']]['remaining_entries'],r['id']
  r.update(status='같음',remaining_reason=None,unverified_branches=[],native_evidence={'file':'project/game/'+file,'symbol':symbol,'line':next(i+1 for i,l in enumerate((R/'project/game'/file).read_text(encoding='utf-8').splitlines()) if symbol in l)})
 elif r['id'] in partial:
  suffix,op,contract=partial[r['id']];r['remaining_reason']=contract;r['status']='일부'
  file,symbol={'P1811':('dungeon_enemy_r21.gd','func attack_action'),'P1812':('dungeon_enemy_r21.gd','func attack_action'),'P1825':('combat_outcome_r23.gd','func finish'),'P2220':('battle_v3.gd','func damaged_caster_cleanup'),'P1688':('persona_research_r21.gd','static func transition'),'P1692':('persona_research_r21.gd','static func transition')}[r['id']]
  r['native_evidence']={'file':'project/game/'+file,'symbol':symbol,'line':1}
 else:suffix=op=contract=None
 if contract:
  p=packs[suffix];r['new_evidence']=r['new_evidence']+[{'test':p['test'],'labels':['round8/'+op],'checks':p['counts'][op],'contract':contract,'oracle':p['oracle'],'observations':p['observations'],'log':str((S/(p['test']+'.log')).relative_to(R)).replace('\\','/')}]
 if r['id'] in fixed:
  r['fixed']=True;r['round8_fix']='전투 기록·시각/만료/효과 정리·정산 연결 또는 한영 연구 메시지/기술 등록 검증 보완. 새 API 부재를 수치 버그 수로 세지 않음.';r['fix']=(r.get('fix')+' / ' if r.get('fix') else '')+r['round8_fix']
 if r.get('native_evidence'):
  ref=dict(r['native_evidence']);ref['line']=next(i+1 for i,l in enumerate((R/ref['file']).read_text(encoding='utf-8').splitlines()) if ref['symbol'] in l);r['native_evidence']=ref
 r['unverified_branches']=[] if r['status']=='??' else cov[r['id']]['remaining_baseline']
 rows.append(r)
checks=sum(p['checks'] for p in packs.values());source_checks=sum(p['source_checks'] for p in packs.values())
equal=sum(r['status']=='같음' for r in rows);excluded=sum(r['status']=='제외' for r in rows);remaining=len(rows)-equal-excluded
assert (len(rows),equal,excluded,remaining)==(212,179,3,30)
products=[p.relative_to(R).as_posix() for p in (R/'project/game').glob('*.gd') if start.get(p.relative_to(R).as_posix())!=sha(p)]
summary={**prior['summary'],'newly_equal_rows':equal,'remaining_rows':remaining,'excluded_rows':excluded,'statuses':dict(Counter(r['status'] for r in rows)),'fixed_rows':sum(r['fixed'] for r in rows),'fixed_and_equal_overlap':sum(r['fixed'] and r['status']=='같음' for r in rows),'round8_newly_equal_rows':len(mapping),'round8_fixed_evidence_rows':len(fixed),'round8_new_fixed_rows':sum(r['id'] in fixed and not r['fixed'] for r in prior['rows']),'round8_checks':checks,'round8_source_checks':source_checks,'new_checks':prior['summary']['new_checks']+checks,'new_failures':0,'suite_groups':len(suite),'expected_suite_groups':len(expected),'suite_failed_groups':0,'suite_missing':[],'suite_in_progress':[],'suite_final_code_complete':True,'suite_verification_method':'Fresh complete suite-round8-final-v7 on locked final product, tests and round7/8 source inputs; no replacement of failing rows.','called_functions':coverage['called_functions'],'newly_entered_baseline_entries':coverage['newly_entered_baseline_entries'],'fresh_oracle_runs':len(coverage['runs']),'parity_battles':battles,'parity_records':records,'round8_product_files_changed':products,'product_files_changed':sorted(set(prior['summary']['product_files_changed']+products)),'protected':protected}
summary['fixed_but_not_equal_rows']=sum(r['fixed'] and r['status'] not in ['같음','제외'] for r in rows);summary['neither_equal_nor_fixed_rows']=sum(not r['fixed'] and r['status'] not in ['같음','제외'] for r in rows)
round8={'new_equal_ids':sorted(mapping),'fixed_evidence_ids':sorted(fixed),'checks':checks,'source_checks':source_checks,'native_save_checks':1,'grade_fallback_before':{'observations':'verification/parity-r23/battle-round8-grade-before-latest.json','differences':72,'old_product_sha_verified_against':'suite-round8-final-v4/final-code-lock.json'},'before_replay':{'checks':before['checks'],'differences':len(before['failures']),'by_operation':dict(before_counts),'api_missing_guards_counted_as_numeric_bugs':False},'suite':S.name,'limitations':'30행이 남는다. 직접 함수 대조와 전체 6320판 숫자/난수/행동 대조를, 모든 혼합 전투의 모든 문자열/시각 전수 대조로 확대하지 않음. 페르소나 scene transport는 core 대조에 섞지 않음.'}
new_tools=[p.relative_to(R).as_posix() for folder in ['tools','project/tests'] for p in (R/folder).glob('*') if p.is_file() and p.suffix in ['.py','.gd','.mjs','.lua'] and (p.name.startswith(('oracle_battle_r23_round8','report_battle_r23_round8','verify_battle_r23_round8','prepare_battle_r23_round8','diff_battle_r23_round8','battle_r23_round8')) or p.name=='coverage_battle_r23.py')]
grade_before=read(O/'battle-round8-grade-before-latest.json');assert grade_before['checks']==1953 and len(grade_before['failures'])==72
visual=read(O/'battle-round8-visual-review.json');assert len(visual['opened'])>=4 and all(sha(R/x['file'])==x['sha256'] for x in visual['opened'])
write(O/'battle.json',{**prior,'summary':summary,'rows':rows,'round8':round8,'test_tool_files':sorted(set(prior.get('test_tool_files',[])+new_tools)),'target_tests':prior['target_tests']+[{'name':'battle-round8'+s,'checks':p['checks'],'failures':0} for s,p in packs.items()]})
write(O/'battle-round8.json',read(O/'battle.json'));write(O/'summary.json',summary);write(O/'battle-round8-report-summary.json',summary)
write(S/'final-verification.json',{'passed':True,'groups':len(suite),'battles':battles,'records':records,'assets':96,'protected_verified':True,'code_locked':True,'source_inputs_locked':True})
if not (R/'R23-battle-round7.md').exists():shutil.copyfile(R/'R23-battle.md',R/'R23-battle-round7.md')
group_rows=[]
for name in sorted({r['feature_group'] for r in rows}):
 rs=[r for r in rows if r['feature_group']==name];group_rows.append(f'| {name} | {sum(r["status"]=="같음" for r in rs)} | {sum(r["status"]=="제외" for r in rs)} | {sum(r["status"] not in ["같음","제외"] for r in rs)} |')
lines=['# R23-battle 8차 보고','',f'대상 212행: 같음 {equal}(+10), 호스트 제외 {excluded}, 남음 {remaining}(−10). 이번 수정 근거 {len(fixed)}행(중복 포함), 신규 수정 근거 {summary["round8_new_fixed_rows"]}행, 누적 수정 근거 {summary["fixed_rows"]}행. 전 기능 완료는 아니다.','',f'신규 {checks:,}개 검사 중 원본 Lua 직접 대조 {source_checks:,}개와 native 저장 경계 4개, 실패 0. 누적 신규 검사 {summary["new_checks"]:,}개. 전체 프로젝트 {len(suite)}/{len(expected)}그룹(import 포함), 로컬 serve.mjs/D1 클라우드 시험 통과. 기존 6,320판·219,785기록 차이 0.','',f'원본 Lua {len(coverage["runs"])}종을 함수/then/else/do 진입 계측 후 실행했다. 계측 전후 결과는 같고 기존 6,320판 원본 trace도 저장된 기준과 같다. 함수 {coverage["called_functions"]}/212 호출, 기준 미검증 진입 {coverage["newly_entered_baseline_entries"]}/157 도달(7차 112). 진입 도달은 조건 조합 전수 증명이 아니다. coverage/에는 oracle 중복 사본 없음.','', '묶음별로 차례 종료 384, DOT 90, abyss 512, 기술 사용 조건 7,936, 적 단일/전체 공격 256, 주디스 42, 요르드 256, 사망 효과 정리 64, 경험치 1,440, finish/check_end 512, 연구 행동 16,038개를 실행했다. native 저장 4개는 고갈 횟수/마지막 일격 보존·옛 저장·손상 거절·보호막 만료 뒤 저장 가능 여부다.','', '실제 공격과 개인 기술에서 원본의 심연/고갈·전염 list·부식/출혈 사건·필드 이력·시각·로그를 기록하도록 보완했다. 단일 적 공격 본문은 attacked/counter 훅보다 먼저 기록하고 전체 공격 본문은 대상별 훅 뒤에 기록한다. 차례 끝에는 침묵·서약·공격 배율·보호막을 원본 규칙으로 만료하며 native 저장에 0턴 효과를 남기지 않는다. 죽은 아델린의 재생 제거와 미등록 개인 기술 거절도 연결했다.','', '페르소나 연구는 saved/draft/spent/gold/message core 전이만 한영 직접 비교했다. 영어 메시지 누락을 수정했고 persona_world.gd는 언어 전달 한 줄만 연결했다. 원본 pending 지시/채팅은 oracle에 별도 보존하며 native 대화 재개와 같다고 세지 않았다. 해당 2행은 남음이다.','',f'수정 전 재생: 시작 시 보존한 battle/personal/enemy 모듈과 최종 동일 입력으로 {before["checks"]:,}개를 실행하여 {len(before["failures"])}개 차이를 확인했다: {dict(before_counts)}. 새 API 부재 guard는 수치 버그로 세지 않았다. 이는 전체 옛 빌드 재현이 아니라 보존한 모듈 조합의 실제 실행이다. 연구 메시지와 새 정산/저장 기능을 이 차이 수에 더하지 않았다.','', '최초 전체 실행에서 손상 x=false 입력을 native에 옮기는 시험 준비가 Dictionary.has를 잘못 호출해 중단했다. 기대값은 유지하고 fixture의 타입 가드 두 곳만 고친 뒤, 새 suite-round8-final-v2에서 전체 검사를 처음부터 재실행했다. 최종 제품/시험/입력 SHA는 모두 잠겨 있다. 중간 실패·취소 실행은 최종 통과 수에 섞지 않았다. Windows root certificate store 메시지만 환경 진단으로 제외했다.','', '| 묶음 | 같음 | 제외 | 남음 |','| --- | ---: | ---: | ---: |',*group_rows,'', '같음 승격: '+', '.join(sorted(mapping))+'. 각 행의 원본 id·위치·이전 상태·시험·제품 파일:줄·남은 이유는 verification/parity-r23/battle.json.','', '남은 30행: 시작/재시작·battle_pm/quest/battle_start, 원본 저장 직접 재개, 임의 훅 fire/chain/chain_at, strike·적 차례/run·버튼/행동 패널/최상위 render, 일부 개인/종족·페르소나 기술, 연구 화면/대화 연계와 native 결과 컨텍스트 전체 연결. 직접 finish 상태는 일치해도 모든 world의 rg/qmult·출처 연결은 별도로 남겼다.','', '원본 이미지 96개 해시 일치. docs/assets/server 해시 불변. 사용자 저장은 열거나 지우지 않았으며 Web export·버전 갱신·git 명령 없음. 저장의 combat_meta는 선택 필드로 추가하고 없던 옛 저장은 기본값으로 재개한다.','', '렌더 QA는 verification/parity-r23/battle-round8-visual-review.json에 직접 연 파일·SHA·관찰을 기록한다. 전수 프레임/실기기/Web/WASM은 확인하지 않았다. 새 대조 파일은 battle- 접두, 각각 40 MiB 미만.','', '바꾼 제품 파일:',*['- '+p for p in products],'', '재실행: oracle_battle_r23_round8_loader.mjs (기본, R23_ROUND8_PACK=outcome/persona) → coverage_battle_r23.py → verify_battle_r23_round8.py (R23_FINAL_SUITE=suite-round8-final-v7) → prepare_battle_r23_round8_before.py 및 before-test.gd → 렌더 확인 → report_battle_r23_round8.py.','', '바꾼 시험/도구:',*['- '+p for p in new_tools]]
clean=[]
for line in lines:
 line=line.replace('native 저장 경계 4개','native 저장 경계 1개')
 line=line.replace('native 저장 4개는 고갈 횟수/마지막 일격 보존·옛 저장·손상 거절·보호막 만료 뒤 저장 가능 여부다.','native 저장 1개는 보호막 만료 뒤 실제 snapshot 재개 여부다.')
 line=line.replace('저장의 combat_meta는 선택 필드로 추가하고 없던 옛 저장은 기본값으로 재개한다.','기존 저장 스키마를 유지한다. 정산의 nd/마지막 일격 기록을 저장 재개 뒤 복구하는 범위는 남음이다.')
 line=line.replace('suite-round8-final-v2','suite-round8-final-v7').replace('새 정산/저장 기능','새 정산 기록과 저장 경계 검사')
 line=line.replace('연구 메시지와 새 정산 기록과 저장 경계 검사을 이 차이 수에 더하지 않았다.','연구 메시지·새 정산 기록·저장 경계 검사는 이 차이 수에서 제외했다.')
 if line.startswith('원본 Lua '):
  line=f'원본 Lua 19개에 함수/then/else/do 진입 계측을 적용하고 oracle 29묶음을 실행했다. 계측 전후 결과는 같고 기존 6,320판 원본 trace도 저장된 기준과 같다. 함수 {coverage["called_functions"]}/212 호출, 기준 미검증 진입 {coverage["newly_entered_baseline_entries"]}/157 도달(7차 112). 진입 도달은 조건 조합 전수 증명이 아니다. coverage/에는 oracle 중복 사본 없음.'
 clean.append(line)
 if line in ['바꾼 제품 파일:','바꾼 시험/도구:']:clean.append('')
lines=clean
at=lines.index('| 묶음 | 같음 | 제외 | 남음 |')
lines[at:at]=[
 '전체 회귀 중 축약 편성 정산의 4칸 경계와 전체 공격 도중 소생한 다음 아군 칸을 빠뜨리는 차이도 발견했다. 결과 projection에 빈 아군 칸을 채우고, 전체 공격은 각 칸에 도달할 때 생존 여부를 확인하도록 고쳤다. 원래 실패하던 장비 176판이 기대값 변경 없이 통과했다.','',
 '기존 7차 대조의 70건은 사망 뒤 cover_turns=0을 불필요하게 남긴 차이였다. 원본처럼 제거한 뒤 1,418개가 재통과했다. expansion_test에서 옛 전투가 r21 전용 기록 객체를 부르는 오류도 확인해 보존한 기존 abyss 처리로 분리했다. 기존 3,350개 수치·저장 회귀를 통과한 뒤, 최종 코드를 다시 잠가 121그룹 전체를 실행했다.','',
 '임시 combat_meta 저장 필드는 기존 서버 검증기에 422로 거절됨을 확인했다(battle-round8-cloud-meta-rejection.json). 서버를 바꾸지 않고 해당 저장 필드 증설을 제거했다. 기존 로컬/클라우드 저장 스키마를 유지하며, 정산 메타데이터의 저장 재개는 남음으로 기록한다.','',
 '무효 등급이 보상 설정의 다른 키 이름과 겹치는 경계도 추가했다. v4에 잠긴 이전 정산 코드 SHA와 같은 파일을 재생하면 72개 차이가 나며, 명시적인 3종 레이드 등급만 조회하도록 수정한 뒤 전체 1,952개 정산 대조가 일치한다.','']
(R/'R23-battle.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({k:summary[k] for k in ['round8_newly_equal_rows','newly_equal_rows','excluded_rows','remaining_rows','round8_checks','round8_source_checks','fixed_rows','suite_groups','parity_battles','parity_records']},ensure_ascii=False))
