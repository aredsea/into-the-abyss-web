"""Publish conservative row-level evidence only after final checks complete."""
from pathlib import Path
import json,hashlib,re
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-gear-round3'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
base=read(O/'round2-gear.json');coverage=read(O/'gear-coverage-round3.json');cov={r['id']:r for r in coverage['rows']}
final=read(S/'final-verification.json');assert final=={'project_exit':0,'npm_exit':0,'code_lock_unchanged':True}
suite=read(S/'results.json')
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
assert {r['test'] for r in suite}==expected
assert all(r['passed'] for r in suite)
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==sha for p,sha in read(S/'code-lock.json').items())
assert all(r['output_unchanged'] for r in coverage['runs'])
direct=read(O/'round3-results.json');ui=read(O/'round3-ui-results.json')
assert not direct['failures'] and not ui['failures']
npmlog=(S/'npm-test.log').read_text(encoding='utf-8');npm_checks=sum(map(int,re.findall(r'(?:CHECKS |"checks":)(\d+)',npmlog)))
assert 'GEAR R23 SERVER {"checks":259,"failures":0,"cases":36}' in npmlog
parity=[]
for name in ['p2-full-battles','a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
 d=read(R/'verification/data-r21'/(name+'.json'))
 actions=d.get('source_actions',d.get('compared_actions'));actual=d.get('actual_actions',d.get('compared_actions'))
 equal=d.get('equal_battles',d['battles'] if d.get('different_actions')==0 else 0)
 assert equal==d['battles'] and actions==actual==d['matched_actions']
 parity.append({'name':name,'battles':d['battles'],'same_battles':equal,'matched_actions':actions})
assert sum(p['battles'] for p in parity)==6320
initial=read(O/'round3-initial-files.json')
changed=[p for p,sha in initial.items() if not (R/p).exists() or hashlib.sha256((R/p).read_bytes()).hexdigest()!=sha]
allowed={'project/game/gear_rules_r22.gd','project/game/smithy_rules_r22.gd','project/game/town_rules_r21.gd','project/game/town_world_r21.gd','project/game/facilities_world_r22.gd','project/ui/town_screen_r21.gd','project/ui/facilities_screen_r22.gd'}
protected=[p for p in changed if p.startswith(('project/game/','project/ui/','project/assets/','project/data/','server/','docs/')) and p not in allowed]
assert not protected,protected
hashes=read(R/'ASSET-HASHES.json');asset_result={'checked':len(hashes),'matched':0,'mismatches':[]}
for h in hashes:
 if hashlib.sha256((R/h['path']).read_bytes()).hexdigest()==h['sha256']:asset_result['matched']+=1
 else:asset_result['mismatches'].append(h['path'])
assert asset_result['checked']==asset_result['matched']==96
(O/'asset-hashes-round3.json').write_text(json.dumps(asset_result,indent=2),encoding='utf-8')
promoted={'P3684','P3686','P2946'};fixed={'P3540','P3684','P3686','P2946','P2981'}
tests={'P3684':'fx_return / fx_state / native source effect slots','P3686':'pct (exact IEEE inputs, C %g output) / native rate labels','P2946':'act_visible / native ordinary action controls','P3540':'restrict_return / restrict_state / restrict_written_raw / restrict_bag','P2981':'aff_result / aff_state / aff_callback / native_inn_aff'}
locations={'P3684':('project/game/smithy_rules_r22.gd','func fx_clear('),'P3686':('project/game/smithy_rules_r22.gd','func pct('),'P2946':('project/game/town_rules_r21.gd','static func inn_act_visible('),'P3540':('project/game/gear_rules_r22.gd','func gear_restrict('),'P2981':('project/game/town_rules_r21.gd','static func aff_add_source(')}
rows=base['rows'];reviewed=[]
for r in rows:
 if isinstance(r.get('source_observation'),str):
  r['source_observation']=r['source_observation'].replace('parity-r23/oracle.json','parity-r23/gear-oracle.json').replace('parity-r23/round2-oracle.json','parity-r23/gear-round2-oracle.json')
 r['evidence_tests']=[s.replace('parity-r23/oracle.json','parity-r23/gear-oracle.json').replace('parity-r23/round2-oracle.json','parity-r23/gear-round2-oracle.json') for s in r['evidence_tests']]
 r['round3_previous_status']=r['new_status'];r['round3_coverage']=cov[r['id']]
 if r['new_status']=='같음':continue
 reviewed.append(r['id']);r['round3_reviewed']=True
 evidence=['verification/parity-r23/gear-coverage-round3.json::'+r['id'],'verification/parity-r23/gear-round3-oracle.json']
 if r['id'] in tests:evidence+=['project/tests/gear_r23_round3_test.gd::'+tests[r['id']]]
 else:evidence+=r.get('round2_evidence',[])
 if r['id'] in promoted:evidence+=['project/tests/ui_gear_r23_round3_test.gd']
 r['round3_evidence']=evidence;r['evidence_tests']+=evidence
 if r['id'] in tests:r['source_observation']='verification/parity-r23/gear-round3-oracle.json'
 if r['id'] in promoted:
  assert cov[r['id']]['called'] and not cov[r['id']]['remaining_entries']
  r['new_status']='같음';r['remaining_reason']=''
 if r['id'] in fixed:
  r['fixed']=True;file,needle=locations[r['id']]
  line=next(i for i,s in enumerate((R/file).read_text(encoding='utf-8').splitlines(),1) if s.startswith(needle))
  r['round3_fix_location']=f'{file}:{line}';r['fix_location']=f'{file}:{line}'
 if r['id']=='P3540':r['remaining_reason']='무효 장착 테이블의 반환 false→nil을 원본처럼 수정. 원본 raw 쓰기와 재조회 필터를 분리해 비교했다. native UID 저장의 부적합 장착 검증/가방 회수 전체 계약은 여전히 다름.'
 if r['id']=='P2981':r['remaining_reason']='source-shaped aff_add_source에서 잘못된 aff 테이블 초기화, 알 수 없는 cid, 16진 문자열, 선택적 chron_aff 호출 순서·동일 g 참조를 직접 비교했고 보유 동료의 실제 native 증감에도 연결했다. native 공개 aff_add의 owned 제한과 대화 전이 큐는 남아 전체 함수 같음으로 세지 않음.'
 if r['id']=='P2961':r['remaining_reason']+=' act_visible은 정본에서 상수 true여서 73-inn.lua:98의 거절 then은 도달 불가. 이를 인위적으로 원본을 바꿔 실행하지 않았다.'
 r['round3_scope']='함수 호출/명시 진입은 실행 증거. 새 판정은 해당 함수의 직접 반환·상태 비교에 한정하며 HTML/호스트/저장 계약에 전파하지 않음.'
same=[r for r in rows if r['new_status']=='같음'];remaining=[r for r in rows if r['new_status']!='같음']
assert len(reviewed)==40 and len(same)==40 and len(remaining)==37
assert all(r['remaining_reason'] for r in remaining)
summary={'assigned':77,'round3_reviewed':40,'round3_promoted_same':len(promoted),'round3_fixed_rows':len(fixed),'round3_new_fixed_rows':sum(not r['fixed'] for r in read(O/'round2-gear.json')['rows'] if r['id'] in fixed),'promoted_same':len(same),'fixed_rows':sum(r['fixed'] for r in rows),'remaining':len(remaining),'suite_groups':len(suite),'suite_failed':0,'suite_failed_assertions':0,'round3_direct_checks':direct['checks'],'round3_ui_checks':ui['checks'],'round3_new_checks':direct['checks']+ui['checks'],'round3_failures':0,'new_checks':base['summary']['new_checks']+direct['checks']+ui['checks'],'npm_checks':npm_checks,'npm_failures':0,'battle_count':6320,'equal_battles':6320,'matched_actions':sum(p['matched_actions'] for p in parity),'parity':parity,'coverage':{k:v for k,v in coverage.items() if k not in ['rows','runs']},'changed_existing_files':changed,'protected_changes':protected,'asset_hashes':asset_result,'code_lock_unchanged':True,'full_original_parity_complete':False}
ledger={**base,'summary':summary,'round2_snapshot':'verification/parity-r23/round2-gear.json','rows':rows}
(O/'gear.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'summary-round3.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
table='\n'.join(f"|{r['id']}|{r['round3_previous_status']} → {r['new_status']}|{'수정' if r['id'] in fixed else '대조'}|{r['remaining_reason'] or tests.get(r['id'],'기존 직접 대조 유지')}|" for r in rows if r.get('round3_reviewed'))
report=f'''# R23-gear — 3차 장비·시설 함수 대조

남은 **40행 전부 재검토**, 이번 같음 **+3행**, 수정 근거 **5행**(새 수정 표기 {summary['round3_new_fixed_rows']}행, 기존 수정행 추가 해결 1행). 누적 **77행 중 같음 40행·수정 {summary['fixed_rows']}행·남음 37행**. 수정과 같음은 겹친다. 원본 전 기능 완료는 아니다.

전체 프로젝트 **{len(suite)}그룹 / 실패 0**, 서버 npm test **{npm_checks:,}항목 / 실패 0**. 이번 직접 대조 **{direct['checks']:,}항목**, 실제 화면 **{ui['checks']}항목**, 합계 **{direct['checks']+ui['checks']:,}항목 / 실패 0**. 누적 R23 직접/화면 대조 **{summary['new_checks']:,}항목**(서버 신규 259 별도). 전투 **6,320/6,320판 · {summary['matched_actions']:,}기록 일치**.

행 id·원본 위치·이전 판정·새 근거·남은 사유는 [gear.json](verification/parity-r23/gear.json)에 이어 기록했다. 이전 [2차 ledger](verification/parity-r23/round2-gear.json), [2차 보고](verification/parity-r23/round2-report.md)를 보존했다. [요약 수치](verification/parity-r23/summary-round3.json).

## 바꾼 규칙과 직접 근거

- **P3540**: gear_restrict의 비테이블 장착 입력 반환을 false에서 원본 nil로 수정했다. 처음 6개 반환 차이를 실제로 확인한 후 통과했다. 원본은 구문상 유효한 미등록 코드를 잠깐 dk_bag에 쓸 수 있고 다음 bag_load에서 거른다. raw 쓰기·조회 필터를 구분해 비교했으며 native 복구 전체 계약이 다르므로 일부를 유지했다.
- **P3684**: fx_clear를 원본 두 필드(forge_fx/proc_fx) 제거로 이식했다. native smithy_fx는 두 필드의 계산된 뷰다. 기존 탭 변경·다음 작업·완료·퇴장·restore의 빈 대입이 모두 같은 제거 경로를 쓴다. 무효/빈/정상 이펙트의 반환·그 외 필드 보존, 실제 가공→탭 변경을 비교했다.
- **P3686**: 원본 C/Lua %g의 여섯 유효 숫자·짝수 반올림·지수 전환·음수 0·최소 subnormal·최대 double·inf/nan을 직접 비교했다. 입력은 Lua string.pack의 IEEE 8바이트를 보존했다. native 가공 확률 레이블이 이 함수를 사용한다. 정수인 현행 확률표만으로 일반 포맷 일치를 주장하지 않았다.
- **P2946**: 상수 true인 원본 act_visible을 직접 이식하고 native 여관 표시/실행 경로에 연결했다. 알 수 없는 행동/id 등 96입력 반환과 실제 일반 행동 네 버튼을 확인했다. 부모 여관의 보내기·AI 계약으로 판정을 확장하지 않았다.
- **P2981**: source-shaped aff_add_source의 테이블 초기화·알 수 없는 cid·숫자/16진 문자열·0 증감·선택적 chron_aff 부수 효과·g 참조를 비교했다. native 보유 동료 증감이 이 함수를 사용한다. 공개 native aff_add의 owned 제한과 고정 대화 전이 큐는 남아 일부다.

신규 소스 실행기 [gear_r23_round3.mjs](tools/gear_r23_round3.mjs), [직접 시험](project/tests/gear_r23_round3_test.gd), [화면 시험](project/tests/ui_gear_r23_round3_test.gd). 제품 변경은 {', '.join('`'+p+'`' for p in changed if p in allowed)}.

## 원본 분기 계측

[계측 결과](verification/parity-r23/gear-coverage-round3.json), [러너](tools/coverage_gear_r23.py). 실제 원본 여섯 실행 묶음에서 **77/77함수 호출**, 행별 명시 진입 합계 **{coverage['entered']}/{coverage['explicit_entries']}**, 기존 미도달 **{coverage['newly_entered_baseline']}/{coverage['baseline_missing']}곳 도달**. 중첩 함수 범위가 겹치는 진입은 합계에 중복될 수 있다. 조건의 모든 값 조합이나 native 같음 수치가 아니다.

원본 소스는 읽기만 하고 worktree에 계측 사본을 만들었다. probe 없는 실행과 probe 실행의 전체 결과를 그대로 비교했다. Lua pairs의 상회 직업 버튼 순서는 새 Wasmoon마다 달라져 그 단일 테이블의 열거 순서를 두 실행에 똑같이 고정했다. 결과 HTML을 사후 정렬해 맞추지 않았다. 상수 true인 act_visible의 false 거절 진입은 원본을 바꿔 만들지 않았다. 나머지 이미 완료된 함수의 일부 미도달 진입은 이번 승격 근거로 삼지 않았다.

## 실패 기록과 한계

[수정 전](verification/parity-r23/round3-before.log)은 미구현 경계 API 네 guard 실패와 gear_restrict 반환 6차이를 포함한다. 처음 추가한 fixture의 미등록 코드 재조회 차이 1건은 raw/조회 매체 혼동이어서 제품 결함 수에 넣지 않았다. `%g` 초기 입력은 JSON/문자열 변환에서 double 정밀도를 잃거나 음수 0이 사라졌다. Lua IEEE 바이트를 사용한 뒤 전체 입력이 통과했다. 마지막 chron_aff fixture가 뒤의 source 화면 실행에 의해 변한 관찰 배열도 복사해서 격리했다. 초안의 GDScript 정적 has_method 호출·Lua Boolean map 키 직렬화 실패는 fixture 오류이며 통과 검사나 제품 버그 수로 세지 않았다. 실제 원본 숫자·확률·기대 문구를 바꿔 맞추지 않았다.

남은 **37행**은 dk_bag 호스트 읽기/쓰기·예외와 native UID/전체 JSON 저장, 임의 선행 GH 콜백의 전체 합성 ABI, 시제품 삭제 대신 보존하는 이관, HTML 반환과 native Controls, pending/addChat/보내기와 고정 대화/영수증의 차이다. 계측에서 원본 분기를 실행했어도 이 계약을 native에 구현한 것으로 세지 않았다. 원본 호스트·AI 기능 전체 완료에는 이 차이를 해소하는 구현이 추가로 필요하다. 행별 사유는 아래와 ledger에 있다.

## 최종 검사와 보존

[전체 검사](verification/parity-r23/suite-gear-round3/results.json), [서버 npm 로그](verification/parity-r23/suite-gear-round3/npm-test.log), [코드 잠금](verification/parity-r23/suite-gear-round3/code-lock.json), [종료 결과](verification/parity-r23/suite-gear-round3/final-verification.json). 모든 *_test, 필수 integration/export_licenses, 전투 여덟 묶음을 포함한다.

최초 전체 검사에서 장비·전투가 공유하던 oracle.json/round3-oracle.json의 충돌로 전투 두 시험에 Script error가 났다. 장비 fixture를 gear-* 이름으로 격리하고 장비 시험 세 개의 참조를 바꿨다. 전투 두 fixture는 실제 원본 Lua에서 복구했다. 영향을 받은 다섯 시험은 모두 다시 실행해 통과했다. 다른 통과 그룹은 제품 코드가 동일함을 검증해 유지했다. 최초 검사기의 코드 잠금도 시험 참조 변경을 감지해 중단됐으며 이 결과를 최종 성공으로 간주하지 않았다. [실패 로그와 수정 전후 잠금](verification/parity-r23/suite-gear-round3/fixture-collision/), [최종 검증기](tools/finalize_gear_r23_round3.py)가 제품 코드 불변·수정 후 다섯 시험 통과·전체 112그룹의 최신 결과를 검증한다. 예전 gear 출처의 공용 oracle 경로는 최신 ledger에서 gear-* 경로로 바로잡았다.

클라우드는 실제 node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs를 고유 loopback 포트에서 실행했다. 자신이 띄운 서버만 종료했고 npm/임시 파일/모듈은 자기 worktree에 격리했다.

직접 연 이미지는 [대장간 390×844](verification/parity-r23/render-round3/smithy-process-390x844.png), [여관 360×780](verification/parity-r23/render-round3/inn-actions-360x780.png)다. 다섯 등급 확률·가공 버튼·여관 네 행동 버튼과 작은 폭 레이블을 확인했다. 다른 회귀 이미지를 모두 열었다고 주장하지 않는다.

docs·원본 자산·데이터·서버·전투/원정 코드의 시작 manifest 대비 변경 **0개**, 원본 이미지 해시 **96/96 일치**([해시 결과](verification/parity-r23/asset-hashes-round3.json)). Web export·버전 갱신·Git 명령·커밋 없음. 사용자 저장을 읽거나 지우거나 덮어쓰지 않았고 저장 schema는 바꾸지 않았다. Windows root certificate store 진단만 환경 메시지로 제외하고 다른 ERROR/Script error는 실패로 처리했다.

## 이번 재검토 40행

|행|2차 → 3차|이번 처리|근거 또는 남은 이유|
|---|---|---|---|
{table}
'''
(R/'R23-gear.md').write_text(report,encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True,indent=2))
