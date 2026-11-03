"""Append pass-three direct evidence, preserving every already-equal row."""
from pathlib import Path
import json,hashlib,re
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-expe-pass3-final'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
old=read(O/'expe-pass2-ledger.json');ledger=read(O/'expe-pass2-ledger.json')
native=read(O/'expe-pass3-results.json');coverage=read(O/'expe-pass3-coverage.json')
format_result=read(O/'expe-format-results.json')
assert not format_result['failures']
native_assertions=native['checks']+format_result['checks']
assert not native['failures'] and coverage['instrumentation_output_equal']
assert coverage['remaining_rows']==coverage['called']==75
assert not [r for r in read(O/'expe-pass3-oracle.json')['source_flow'] if not r['ok']]
assert all(r['passed'] for r in read(O/'expe-pass3-save-validation.json'))
assert read(O/'expe-pass3-cloud-probe.json')['roundtrip_equal']
validation=read(O/'expe-pass3-save-validation-provenance.json')
assert sha(R/validation['file'])==validation['sha256']
assert sha(R/validation['validator'])==validation['validator_sha256']
checks=[read(p) for p in sorted((S/'rows').glob('*.json'))]
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
assert {r['test'] for r in checks}==expected
assert all(r['passed'] for r in checks),[r for r in checks if not r['passed']]
assert not read(S/'code-lock-result.json')['changed']
assert read(S/'server-result.json')['exit']==0
lock=read(O/'expe-pass3-code-lock.json');assert all(sha(R/p)==h for p,h in lock.items())
refinement=read(O/'expe-pass3-refinement.json');cut=(O/'expe-pass3-code-lock.json').stat().st_mtime_ns
for row in checks:
 p=S/'rows'/(row['test']+'.json')
 if row['test'] in refinement['selected'] or row['test']=='import':assert p.stat().st_mtime_ns>cut,row['test']
 else:assert p.read_bytes()==(O/'suite-expe-pass3-main/rows'/p.name).read_bytes(),row['test']
assert all(sha(R/'project'/p)==h for p,h in refinement['dependency_hashes'].items())
before=read(O/'expe-pass3-before.json');changed=[p for p,h in before.items() if not (R/p).is_file() or sha(R/p)!=h]
for folder in ['docs','server']:
 expected_paths={p for p in before if p.startswith(folder+'/')}
 actual_paths={p.relative_to(R).as_posix() for p in (R/folder).rglob('*') if p.is_file() and 'node_modules' not in p.parts and '.godot' not in p.parts}
 assert actual_paths==expected_paths,(folder,sorted(actual_paths-expected_paths),sorted(expected_paths-actual_paths))
allowed={'project/game/expedition_world_r22.gd','project/game/dungeon_world_r21.gd','project/ui/expedition_screen_r22.gd','project/tests/battle_r23_test.gd'}
assert not set(changed)-allowed,changed
assets=read(R/'ASSET-HASHES.json');assert all(sha(R/a['path'])==a['sha256'] for a in assets)
source=Path('C:/Clauede Code/dungeon-bot')
assert all(sha(source/f['file'])==f['sha256'] for f in read(O/'expe-pass3-provenance.json')['files'])
same={
 'P3061':('project/game/dungeon_world_r21.gd','normalize_dungeon_record',['normalize'],
  '원본 dn_G의 손상/누락 dungeon 교체, 숫자 문자열·음수·소수 경계, mode 숫자/문자 구분, cleared_bosses/run 정규화와 추가 필드 보존. 직접 source-record API는 원본 모양을 사용하며 native 저장 검증·allowlist를 바꾸지 않는다.'),
 'P3073':('project/game/expedition_world_r22.gd','expedition_party',['party'],
  '빈 편성/1~4인, 미상·중복·초과 동료, 참전/지휘, 직업 fallback, 장비 코드·제련 사전·종족/능력치 및 선택적 기술을 포함한 전체 pm/n/avg를 64입력에서 직접 비교. source pm은 transient이고 저장 pm은 기존 schema를 보존한다.'),
 'P3119':('project/game/expedition_world_r22.gd','expedition_item_weight',['weights','weighted_roll'],
  '원본 ex_roll 안의 wt closure를 노출. ITEM_FROM/ITEM_W의 누락 ID와 0/1/7/8/17/18/420층 가중치 49건 및 실제 선택 1440건 비교. 실제 advance가 동일 helper를 사용한다. 데이터/장비 규칙 수정 없음.'),
 'P3123':('project/game/expedition_world_r22.gd','expedition_zero4',['zero4'],
  '직접 원본 zero4 두 호출의 전체 네 슬롯, 별도 배열 참조 보존을 비교. native 실제 snapshot_party 어댑터가 이 초기 배열을 사용한다.'),
 'P3138':('project/game/expedition_world_r22.gd','expedition_floor_context',['floor_context'],
  'floor 0/1/3/27/28/54/55/420과 원본 영문 구역·심층 문자열 전체 비교. 영문 탐색 기록의 실제 위치 표시에 연결했다. Risu AI 생성 기능의 동등성으로 확대하지 않는다.'),
 'P3176':('project/game/expedition_world_r22.gd','snapshot_expedition_record',['snapshot'],
  '4슬롯 empty 16조합×DOWN_HP 0/0.2×HP 5값×MP 4값=640건. al/empty로 생존·빈 슬롯을 구분하고 음수 MP/소수 내림, 최대치, fell/real 및 무관 필드까지 직접 비교. 실제 전투 결과의 native hp 생사 규약을 al로 변환해 같은 함수를 호출한다.'),
 'P3199':('project/game/expedition_world_r22.gd','expedition_exp_note',['exp_fallback','exp_actual'],
  '의존 함수 없음/실패/비표/빈 표/목록, 음수·0·양수 경험치의 sum.exp/lv reset와 전체 exp/pm/sid 전달을 직접 비교. 실제 지급 120입력에서 레벨/경험치/번호 중복 방지와 원문 레벨업 배열도 비교. Lua pcall은 Godot의 명시적 {ok,value} provider ABI에 매핑하며 Godot 예외 포착을 주장하지 않는다.'),
 'P3201':('project/game/expedition_world_r22.gd','expedition_aff_note',['aff','aff_fallback'],
  'ko/en×clear/retreat/defeat×0/1/5승×호감 6경계×시너지 유무=216입력의 전체 aff 문자열 배열과 지급 후 동료 값 비교. 실제 솔렌 3명 이상 +20%도 포함. 의존 함수/상수 없음·실패·비표·빈 표·중복/미상/페르소나 got 레코드도 비교. 실제 정산과 저장 뒤 재계산하는 표시 함수에 연결했다. 독립 의존 모듈의 연대기 부작용은 그 행의 판정에 남긴다.'),
 'P3307':('project/game/expedition_world_r22.gd','expedition_label',['labels'],
  '진행 없음과 floor 0/1/3/27/28/54/55/420의 한·영 ex_label 원문 전체. 탐색 기록 머리에 연결한다.'),
}
fixed=set(same)-{'P3119'}
def line(file,name):
 for n,s in enumerate((R/file).read_text(encoding='utf-8').splitlines(),1):
  if s.startswith('func '+name+'('):return f'{file}:{n}'
 raise AssertionError(name)
reviews=[]
for row in ledger['rows']:
 if row['status']=='같음':continue
 rid=row['id'];cov=next(r for r in coverage['rows'] if r['id']==rid)
 previous={'status':row['status'],'fixed':row['fixed'],'remaining_reason':row['remaining_reason']}
 ev={'previous':previous,'source_review':True,'called':cov['called'],'source_groups':cov['groups'],
  'explicit_entries':cov['explicit_entries'],'entered':cov['entered'],'remaining_entries':cov['remaining_entries'],
  'coverage_file':'verification/parity-r23/expe-pass3-coverage.json','instrumented_output_equal':True,
  'direct_native_contract':rid in same,'source_only_is_not_parity':True}
 if rid in same:
  file,name,groups,detail=same[rid]
  assert cov['called'] and not cov['remaining_entries']
  assert all(native['groups'][g]['failures']==0 for g in groups)
  row['status']='같음';row['remaining_reason']='';row['fixed']=row['fixed'] or rid in fixed
  row['implementation']=list(dict.fromkeys(row.get('implementation',[])+[line(file,name)]))
  for g in groups:row['tests'].append(f'expe_pass3_r23_test::{g} ({native["groups"][g]["checks"]} assertions)')
  if rid=='P3201':
   row['tests'].append(f'expe_format_r23_test ({format_result["checks"]} assertions; 12/605 source differences before fix)')
   detail+=' 추가 직접 fixture에서 -300~300의 0.01 간격 60,001표시 및 실제 한·영 quarter 지급 문자열을 비교했다. native 호감 차이의 유효 범위는 [-300,300]이며 이진 double의 C printf 반올림을 맞췄다.'
  row['equality_domain']='명시한 source-record/native projection ABI. Lua empty table은 필드 schema로 map/array를 구분한다. 콜백 성공/실패는 명시적 envelope로 매핑한다. 다른 함수/호스트 전체 동등성을 전파하지 않는다.'
  ev.update(groups=groups,detail=detail)
 else:
  ev['detail']='원본 함수 실행/분기 계측을 추가했으나 native 전체 반환·부작용 직접 비교가 미완료. '+row['remaining_reason']
  row['remaining_reason']+=' 3차: 원본 호출 및 명시 진입 %d/%d 확인. 계측 실행만으로 같음 승격하지 않음.'%(cov['entered'],cov['explicit_entries'])
 row['pass3_evidence']=ev;reviews.append({'id':rid,**ev,'status':row['status'],'remaining_reason':row['remaining_reason']})
for r in old['rows']:
 if r['status']=='같음':assert r==next(x for x in ledger['rows'] if x['id']==r['id'])
assert len(reviews)==75
traces=[]
for name,file in [('combat_p2_r22_trace','p2-full-battles.json'),('combat_a6_mixed_audit','a6-mixed-audit.json'),('combat_p3_mixed_audit','p3-mixed-audit.json'),('combat_a7_gear_audit','a7-gear-audit.json'),('combat_a7_gear_balanced','a7-gear-balanced-audit.json'),('combat_a8_audit','a8-audit.json'),('combat_a9_native_10_audit','a9-native-10-audit.json'),('combat_a9_native_40_audit','a9-native-40-audit.json')]:
 p=R/'verification/data-r21'/file;t=read(p)
 equal=t.get('equal_battles',sum(not r.get('mismatches') and r.get('source_result')=={'victory':'win','defeat':'lose'}.get(r.get('godot_result'),'') for r in t.get('reports',[])))
 assert equal==t['battles']
 if 'source_actions' in t:assert t['source_actions']==t['actual_actions']==t['matched_actions']
 else:assert t['different_actions']==0 and t['matched_actions']==t['compared_actions']
 traces.append({'test':name,'file':p.relative_to(R).as_posix(),'sha256':sha(p),'battles':t['battles'],'equal':equal,'records':t['matched_actions']})
assert sum(t['battles'] for t in traces)==6320
summary={'reviewed_rows':75,'promoted_same':len(same),'implementation_rows':len(fixed),'remaining_rows':sum(r['status']!='같음' for r in ledger['rows']),
 'native_assertions':native_assertions,'native_failures':0,'source_functions_called':75,'source_explicit_entries_entered':coverage['entered'],'source_explicit_entries':coverage['entries'],
 'regression_groups':len(checks),'failed_groups':[],'changed_existing_files':changed,'outside_allowed_changed':[],
 'assets_checked':len(assets),'asset_changes':[],'trace_battles':6320,'trace_equal_battles':6320,'trace_records':sum(t['records'] for t in traces)}
ledger['summary'].update(promoted_same=sum(r['status']=='같음' for r in ledger['rows']),remaining_rows=summary['remaining_rows'],fixed_rows=sum(r['fixed'] for r in ledger['rows']),
 fixed_still_remaining=sum(r['fixed'] and r['status']!='같음' for r in ledger['rows']),oracle_checks=old['summary']['oracle_checks']+native_assertions,regression_groups=len(checks),failed_groups=[],pass3=summary)
symbols={'P2991':'expedition_level','P2992':'expedition_experience','P3023':'sortie_filter','P3025':'sortie_candidate_records',
 'P3070':'dungeon_max','P3072':'dungeon_allowed','P3074':'dungeon_floor_view','P3132':'append_expedition_log',
 'P3191':'append_expedition_gear','P3194':'roll_expedition_gear','P3196':'bank_expedition_items','P3241':'outside_item_multiplier',
 'P3319':'supply_amount','P3325':'supply_need','P3326':'has_supply_dot','P3328':'supply_target_state_ok','P3329':'supply_target_ok','P3330':'any_supply_target'}
for rid,symbol in symbols.items():
 file=ledger['current_implementation_lines'][rid].rsplit(':',1)[0]
 ledger['current_implementation_lines'][rid]=line(file,symbol)
for rid,(file,symbol,_,_) in same.items():ledger['current_implementation_lines'][rid]=line(file,symbol)
ledger['passes'].append({'pass':3,'summary':summary,'row_review':'verification/parity-r23/expe-pass3-row-audit.json'})
ledger['checks']=checks;ledger['trace_reports']=traces
write(O/'expe-pass3-row-audit.json',reviews);write(O/'expe-pass3-summary.json',summary);write(O/'expe.json',ledger)
write(O/'expe-pass3-integrity.json',{'changed_existing':changed,'outside_allowed':[],'assets_checked':len(assets),'asset_changes':[],
 'source_hashes_unchanged':True,'code_lock_unchanged':True,'server_disk_unchanged':True,'docs_unchanged':True,'cloud_save_specimens_passed':3})
failed_attempts=[]
for folder in ['suite-expe-pass3-first-attempt','suite-expe-pass3-second-attempt']:
 rows=[read(p) for p in (O/folder/'rows').glob('*.json')]
 failed_attempts.append({'folder':folder,'completed':len(rows),'failed':[r['test'] for r in rows if not r['passed']],'interrupted':True,'counted_in_final':False})
write(O/'expe-pass3-attempts.json',failed_attempts)
remaining={}
for row in ledger['rows']:
 if row['status']!='같음':
  key=row['source']['file'];remaining.setdefault(key,[]).append(row['id'])
text=f'''# R23-expe — 3차 원본 대조

기존 같음 34행을 그대로 보존하고 남은 75행 전부를 실행·검토했다. **이번 같음 +9, 누적 43/109행 같음, 66행 남음**이다. 이번 구현·연결 근거는 8행(같음 승격과 겹침)이며 단순 가중치 추출 1행은 동작 수정으로 세지 않았다. 원본 전 기능 완료는 아니다.

|항목|결과|
|---|---:|
|이번 검토 / 승격 / 구현·연결 / 남음|75 / 9 / 8 / 66|
|새 native 검사 단언|{native_assertions:,} / 실패 0|
|누적 대조·검사 단언|{ledger['summary']['oracle_checks']:,}|
|남은 원본 함수 호출|75 / 75|
|행별 명시 진입 도달(중첩 포함)|{coverage['entered']} / {coverage['entries']}|
|전체 프로젝트 검사|{len(checks)} / {len(checks)} 그룹, 실패 0|
|기존 전투 대조|6,320판 / {summary['trace_records']:,}기록, 차이 0|
|서버 검증을 통과한 새 저장 표본|3 / 3|
|보호 이미지|96개, 변경 0|
|허용 밖 기존 파일 변경|0|

승격: {', '.join(same)}. 행별 이전 상태·원본 위치·시험·구현 줄·동등성 범위·남은 이유는 [expe.json](verification/parity-r23/expe.json), 이번 75행 검토는 [expe-pass3-row-audit.json](verification/parity-r23/expe-pass3-row-audit.json)에 있다.

## 바뀐 동작과 대조

- 출전 편성의 전체 pm/n/avg를 장비 코드·제련 사전·선택적 기술까지 비교했다. 잘못된/중복/초과 인물과 빈 편성도 포함한다. 실제 출발의 초기 자원 계산이 이 transient 편성을 사용한다.
- 전투 후 이월을 원본의 al/empty/4슬롯 배열 계약으로 분리했다. 640입력에서 HP/MP 내림·부상자 이월·빈 슬롯 보존·fell/real을 직접 비교하고 실제 native 전투 결과에 연결했다.
- 경험치 정산은 의존 함수 부재·실패·비표·빈 표/목록과 실제 지급/중복 번호 120입력을 비교했다. 호감은 한·영 전체 문자열과 실제 지급 후 값, 솔렌 3인 이상 시너지, -100/99.9/100/199.9/200 경계를 포함했다. 명시적 provider envelope는 Lua pcall 결과를 표현하며 Godot 예외를 포착한다고 주장하지 않는다.
- 가중치 closure와 1,440개의 실제 선택, 독립 zero4 배열, 던전 정규화, 한·영 위치 라벨을 직접 비교했다. 탐색 기록과 정산 호감 표시에 연결했다.

## 실패 확인과 저장 보존

새 API 호출 전 6개 부재 guard 실패를 보존했다(expe-pass3-missing-api-before.json). 이를 기존 수치 버그 6개로 세지 않았다. 최초 새 fixture에는 Lua 빈 map/array 구분 오류와 미존재 장비 id로 만든 불완전 native entry가 있어 Script error가 났다. source-record schema를 명시해 fixture를 고쳤으며 실패 수를 제품 버그로 전파하지 않았다. 원본 계측의 closure 노출 위치 오류와 Lua nil 선택 fixture 오류도 최종 결과에 포함하지 않았다.

첫 전체 검사 시도에서 source 전용 mode/장비·제련/문구 필드를 저장에 넣으면 서버 allowlist와 충돌함을 확인했다. 기존 저장 ABI를 보존하고 source 기록과 표시 문자열을 transient 변환/재계산으로 옮겼다. 두 번째 시도에서 유효한 JSON 숫자를 float에서 int로 바꾸면 exact Dictionary 왕복 비교가 깨지는 1건을 확인해 유효 값의 자료형을 보존했다. 두 시도는 중단·보존했으며 최종 통과 그룹 수에 포함하지 않는다.

추가 호감 포맷 경계 605검사에서 12차이를 먼저 확인했다. ±0.25/1.45/1.95 등의 실제 이진 실수와 원본 C printf의 반올림을 맞췄다. 실제 native 호감 증감 범위 [-300,300]의 0.01 간격 60,001값 및 한·영 실제 정산 4검사는 총 60,005검사 / 실패 0이다. 이 수정은 단순 새 API 구현과 구분되는 실제 문자열 차이 수정이다.

기존 battle_r23_test와 gear_r23_test가 oracle.json을 공유해 전투 검사에 rows가 없는 fixture가 들어가는 사전 충돌도 발견했다. 전투 검사의 fixture 경로 1줄만 분리하고, 원래 oracle 도구는 수정하지 않은 채 in-memory 출력 경로만 바꾸는 wrapper로 실제 Lua 2,508입력을 재생성했다. 전투 제품·비교 기대값/단언 변경은 없다.

전체 111그룹 실행을 보존한 뒤, 마지막 포맷·fixture 경로 수정의 전이 GDScript 의존성과 각 실행 시작 시각을 대조했다. 수정 전에 시작한 영향 검사와 새 검사만 다시 실행했고, 그 외에는 변경 파일을 읽지 않거나 수정 뒤 새 engine으로 시작한 결과를 유지했다. 세부 목록·시각·해시는 expe-pass3-refinement.json, 원래 전체 실행은 suite-expe-pass3-main/, 최종 그룹별 결과는 suite-expe-pass3-final/에 있다. 최종 잠금은 재검사 중 변경 0이다.

추가 native 표본 검사 최초의 persona.member 오류는 숫자 대조 fixture가 persona.lv만 변경하고 native member mirror를 갱신하지 않은 fixture 문제였다. 별도 save probe에서 native 불변식을 맞춘 마을/진행/정산 3저장을 만들었고, 수정하지 않은 서버 validate로 전부 통과했다. native JSON 왕복 전체도 정확히 일치했다.

저장 schema/version 변경·기존 사용자 저장 접근 없음. 옛 저장 회귀도 전체 검사에 포함한다. 서버 파일은 변경하지 않았다.

## 실행 근거와 제한

원본 Lua는 정본 dist/bot.lua와 lua_sim/Wasmoon으로 실행했다. 지시에서 제외한 79-sex의 화면 hook 3개는 양쪽 oracle에서 비활성화했고 해당 HTML 동등성은 주장하지 않는다. source 복사본에 함수·then/else/do 진입 probe를 넣었고 계측 전후 출력이 정확히 같았다. 75함수 호출과 {coverage['entered']}/{coverage['entries']} 진입은 실행 근거이며 조건 조합 완전성이나 native 전체 일치를 뜻하지 않는다. 남은 HTML·호스트·전투/장비/시설 행에는 실행 근거만 추가했다.

원본 파일·docs/·server/·보호 이미지 바이트는 시작 manifest 대비 동일하다. Web export·버전 갱신·git 변경 명령·커밋 없음. 실제 D1 로컬 서버는 serve.mjs 진입점을 실행했고 loopback 고유 포트/격리 TEMP/제어 파일로 준비·쿼터 초기화·정상 종료를 확인했다. 긴 TEMP 경로에서 workerd 초기화가 실패해 기존 짧은 .p6tmp를 사용했다. root certificate store 진단만 제외하고 Script error/다른 ERROR는 실패로 센다.

정산·360px 탐색 기록·360px 저장 재개 퇴각 화면 3장을 직접 열었다. 정산 호감 문자열과 다음 층/귀환 버튼, 탐색 기록의 위치·물품 이름, 퇴각 확인/취소 버튼을 확인했다. 긴 정산 안내는 두 줄로 감긴다. 이미지 목록과 해시는 expe-pass3-visual-review.json에 있다. 전수 이미지·Web/WASM·실기기는 확인하지 않았다.

변경한 기존 제품 파일: {', '.join(p for p in changed if '/tests/' not in p)}. 기존 검사 변경은 project/tests/battle_r23_test.gd의 fixture 경로 1줄이다. 새로운 oracle/test/coverage/report/검사 도구는 tools/, project/tests/, verification/에 있다. 전체 로그: verification/parity-r23/suite-expe-pass3-final/. 새로 전부 재실행할 때는 python tools/coverage_expe_r23_pass3.py → node tools/expe_r23_format_oracle.mjs → node tools/expe_r23_battle_fixture.mjs → python tools/verify_expe_r23_pass3.py → python tools/expe_r23_pass3_save_verify.py → python tools/report_expe_r23_pass3.py.

남은 66행은 원본 HTML/버튼 전체 반환, Risu 호스트 pending·메시지/장면/옛 저장 ABI, 전투 기록·장비 가방·마을/시설 규칙의 허용 밖 작업이 핵심이다. 성적 콘텐츠는 이식하지 않았고 charm_potion 이름 등 제외 항목은 이전 이유를 유지했다. 세부 이유는 ledger 각 행에 있다.
'''
(R/'R23-expe.md').write_text(text,encoding='utf-8')
print(json.dumps({'promoted':len(same),'same':ledger['summary']['promoted_same'],'remaining':summary['remaining_rows'],'assertions':native_assertions,'groups':len(checks),'trace_records':summary['trace_records']},ensure_ascii=False))
