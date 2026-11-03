"""Adjudicate every assigned row after the one full project run and npm retry."""
from pathlib import Path
import json,hashlib,re
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'gear-suite-round4'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
baseline=read(O/'gear-round3-ledger.json');rows=baseline['rows']
final=read(O/'gear-round4-adjudication.json');suite=read(O/'gear-round4-final-suite.json');lock=read(O/'gear-round4-final-code-lock.json')
assert final['project_exit']==0 and final['final_delta_verified']
initial_npm_exit=1
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in lock.items())
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
assert {r['test'] for r in suite}==expected and all(r['passed'] for r in suite)
npm_retry=read(S/'npm-retry-result.json');assert npm_retry['exit']==0
direct=read(O/'gear-round4-results.json');actions=read(O/'gear-round4-actions-results.json');ui=read(O/'gear-round4-ui-results.json')
assert not direct['failures'] and not actions['failures'] and not ui['failures']
initial=read(O/'gear-round4-start.json')
changed=[p for p,h in initial.items() if not (R/p).exists() or hashlib.sha256((R/p).read_bytes()).hexdigest()!=h]
allowed={'project/game/facilities_world_r22.gd','project/ui/facilities_screen_r22.gd'}
protected=[p for p in changed if p.startswith(('project/game/','project/ui/','server/','docs/','project/assets/','project/data/')) and p not in allowed]
assert not protected,protected
assets=read(R/'ASSET-HASHES.json');assert len(assets)==96
assert all(hashlib.sha256((R/h['path']).read_bytes()).hexdigest()==h['sha256'] for h in assets)
parity=[]
for name in ['p2-full-battles','a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
    d=read(R/'verification/data-r21'/(name+'.json'))
    actions_n=d.get('source_actions',d.get('compared_actions'));actual=d.get('actual_actions',d.get('compared_actions'))
    equal=d.get('equal_battles',d['battles'] if d.get('different_actions')==0 else 0)
    assert equal==d['battles'] and actions_n==actual==d['matched_actions'],name
    parity.append({'name':name,'battles':d['battles'],'same_battles':equal,'matched_actions':actions_n})
assert sum(p['battles'] for p in parity)==6320
storage={'P3532','P3533','P3536','P3537','P3549','P3552','P3553','P3554','P3555'}
presentation={'P3687':'smithy_forge / forge:','P3689':'smithy_process / process: / 2,060 source equipment cards','P3693':'smithy_tabs / selected / labels','P2892':'guild_quest_card / quest: / button availability','P2896':'guild_board / board: / empty / active / refresh','P2900':'recruit_cell / cell:','P2901':'recruit_result / all 30 companions / missing id / busy / host tail excluded','P2902':'recruit_roster / 0,1,2,30 companions / newest-first / codex','P2909':'guild_tabs / all source labels / selected / ko,en'}
promoted=storage|set(presentation)|{'P3701','P2912','P2981'}
excluded={'P2921','P2976'}
fixed=set(presentation)|{'P3701'}
reasons={
'P3540':'2,000개 가방에서 부적합한 유효 장비를 착용 중인 손상·옛 입력: 원본 gear_restrict는 가방 반환에 실패해 장착을 유지하지만 native 가져오기는 장착을 해제하고 overflow에 보존한다. 6개 실제 source/native probe 중 4개 일치·2개 차이. 정상·1,999개는 일치. 단순 저장 매체 차이가 아니다. native 복구/전투 적용 경계는 별도 검토가 필요하다.',
'P3639':'선행 damaged 후 장비 효과의 상태·호출 순서는 기존 checkpoint 대조와 전체 전투로 확인. 임의 선행 콜백이 포함된 native 실제 호출 전체를 새 직접 대조하지 못했으므로 일부 유지. 전투 소유자 파일은 이번 수정 금지.',
'P3644':'선행 attacked 후 장비 효과의 상태·호출 순서는 기존 checkpoint 대조와 전체 전투로 확인. 임의 선행 콜백이 포함된 native 실제 호출 전체를 새 직접 대조하지 못했으므로 일부 유지. 전투 소유자 파일은 이번 수정 금지.',
'P3647':'선행 turn_end 후 장비 효과의 상태·호출 순서는 기존 checkpoint 대조와 전체 전투로 확인. 임의 선행 콜백이 포함된 native 실제 호출 전체를 새 직접 대조하지 못했으므로 일부 유지. 전투 소유자 파일은 이번 수정 금지.',
'P3659':'선행 abyss_after 후 장비 효과의 상태·호출 순서는 기존 checkpoint 대조와 전체 전투로 확인. 임의 선행 콜백이 포함된 native 실제 호출 전체를 새 직접 대조하지 못했으므로 일부 유지. 전투 소유자 파일은 이번 수정 금지.',
'P3691':'제련·가공 본문/탭/실행은 직접 일치. 전체 화면에는 원본 장소 설명·NPC 역할·완료/귀환 버튼의 보조 문구가 빠져 있고, native의 장비 장착하기 선택지가 추가된다. AI 장면 자체는 제외하며 이 표시/선택 차이만 남긴다.',
'P2826':'native NPC 영웅 그림은 표시되지만, 원본 tw_npcs의 그림 없음/잘못된 그림이면 해당 행 생략 및 NPC_G가 있을 때 역할 끝 호감 표시를 같은 helper 계약으로 검증·연결하지 못했다. HTML 태그 모양은 사유에서 제외.',
'P2828':'원본 스크롤 대상은 Lv.40 미만만 노출하지만 native 대상 화면은 Lv.40도 사용 불가로 노출한다. 상품 상세 문구·원본의 단일 상품→장비 순서와 native 분리 탭의 순서도 남아 있다. 비매품의 성인 사용 장면은 이식 범위에서 제외.',
'P2841':'구입·스크롤·장비·할인·덤·영구 저장은 시험됨. 원본 접두 버튼의 전체 잘못된 선택/피드백을 native의 선택 위젯과 직접 같은 dispatcher로 대조하지 못했다. pend_hard/addChat와 저장 매체 차이는 남은 사유에서 제외.',
'P2904':'소개비 셀·최근 카드·명단·금화/RNG/합류는 직접 일치. 전체 소개 탭의 설명→셀→최근 결과→소개 행동→명단 표시 순서와 진행 막대, 부족/대기 보조 안내의 전체 화면 대조는 남음. AI 보내기 문구는 제외.',
'P2907':'의뢰판·영입 하위 helper 및 탭은 직접 일치. 전체 길드의 장소 설명·접수/길드장 두 NPC 역할·파티 선택 안내가 누락되고 native 페이지 간 헤더/귀환 동선이 다르다. HTML 반환 형식은 사유에서 제외.',
'P2922':'의뢰 수락/거절/포기/갱신·영입 경제는 기존 대조 유지. 전체 버튼 해석 및 ps_* 연구 위임/저장 안 한 편집 이탈 거절의 합성, 거절 시 전체 안내 문구를 새 source/native 일괄 대조하지 못함. 연구/마을 소유자 파일은 이번 수정 금지. AI 호스트 전송은 제외.',
'P2954':'원본 초기 동료 목록→선택 화면과 native 자동 선택+드롭다운의 순서가 다르고 종족·행동 설명 일부가 빠져 있다. native의 자금 부족 비활성 조건도 원본의 하루 완료 전용 비활성 조건과 다르다. HTML 형식/AI 장면 차이는 사유에서 제외.',
'P2961':'공개 native inn의 금화/날짜/호감/하루 제한과 재개는 대조됨. 실제 native 대화하기 버튼은 고정 대화 선택을 먼저 열고, 원본 일반 talk는 누르는 즉시 호감+1을 확정한다. 원본에 없는 확인 단계/화면과 거절 안내 차이가 남음. RisuAI 보내기/AI 지시는 제외.'}
assert len(promoted)==21 and len(reasons)==14
location_needles={
'P3687':('project/ui/facilities_screen_r22.gd','func smithy_forge('),'P3689':('project/ui/facilities_screen_r22.gd','func smithy_process('),'P3693':('project/ui/facilities_screen_r22.gd','func smithy_tabs('),'P2892':('project/ui/facilities_screen_r22.gd','func guild_quest_card('),'P2896':('project/ui/facilities_screen_r22.gd','func guild_board('),'P2900':('project/ui/facilities_screen_r22.gd','func recruit_cell('),'P2901':('project/ui/facilities_screen_r22.gd','func recruit_result('),'P2902':('project/ui/facilities_screen_r22.gd','func recruit_roster('),'P2909':('project/ui/facilities_screen_r22.gd','func guild_tabs('),'P3701':('project/game/facilities_world_r22.gd','func smithy_action(')}
for row in rows:
    row['round4_previous_status']=row['new_status']
    if row['new_status']=='같음':continue
    ident=row['id'];row['round4_reviewed']=True
    evidence=['verification/parity-r23/gear-round4-provenance.json','verification/parity-r23/gear-round4-assigned-items.json::'+ident]
    if ident in storage:evidence+=['project/tests/gear_r23_round4_test.gd::native_observable / file_roundtrip / next_action / migration_active / migration_again','project/tests/gear_r23_round2_test.gd::source_transaction / native_transaction_resume','project/tests/gear_r23_test.gd::bag_load / bag_save / bag_result / migrate_active']
    elif ident in presentation:evidence+=['project/tests/ui_gear_r23_round4_test.gd::'+presentation[ident],'verification/parity-r23/gear-round4-semantics.json']
    elif ident=='P3701':evidence+=['project/tests/gear_r23_round4_actions_test.gd::smithy_* / smithy_persisted','project/tests/ui_facilities_r22_test.gd::pointer forge / process / completion']
    elif ident=='P2912':evidence+=['project/tests/gear_r23_round4_test.gd::recruit_observable / recruit_values / recruit_file_resume','project/tests/recruit_r21_test.gd','verification/parity-r23/gear-round4-oracle.json::host']
    elif ident=='P2981':evidence+=['project/tests/gear_r23_round4_test.gd::aff_function_result / aff_function_state','project/tests/gear_r23_round3_test.gd::aff_result / aff_state / aff_callback / native_inn_aff']
    elif ident=='P3540':evidence+=['verification/parity-r23/gear-round4-restriction-gaps.json','project/tests/gear_r23_round4_test.gd::restriction probe']
    elif ident in excluded:evidence+=['verification/parity-r23/gear-round4-oracle.json::host / ok,false,error']
    else:evidence+=['verification/parity-r23/gear-round4-semantics.json::screens',*row.get('round3_evidence',[])]
    row['round4_evidence']=evidence;row['evidence_tests']+=evidence
    row['round4_scope']='기능 등가: 정보·수치·문구·순서·선택 조건·상태 및 저장 재개를 판정. HTML/UID/채팅 매체 형식은 비교 대상 아님. AI·RisuAI 전용 호출은 제외. 하위 함수 같음을 부모 전체 함수에 전파하지 않음.'
    if ident in promoted:row['new_status']='같음';row['remaining_reason']=''
    elif ident in excluded:
        row['new_status']='제외';row['remaining_reason']='';row['exclusion_reason']='RisuAI addChat(id, role, text)의 pcall 익명 콜백. 호스트 전용으로 제외. ok/false/exception을 원본에서 실행했고, 부모의 확정된 경제 결과가 native 저장 재개에서도 유지됨을 별도 확인.'
    else:row['remaining_reason']=reasons[ident]
    if ident in fixed:
        row['fixed']=True;file,needle=location_needles[ident]
        line=next(i for i,s in enumerate((R/file).read_text(encoding='utf-8').splitlines(),1) if s.startswith(needle))
        row['round4_fix_location']=f'{file}:{line}';row['fix_location']=row['round4_fix_location']
summary={'assigned':77,'round4_reviewed':37,'round4_promoted_same':21,'round4_excluded':2,'round4_fixed_rows':len(fixed),'round4_new_fixed_rows':sum(not r['fixed'] for r in read(O/'gear-round3-ledger.json')['rows'] if r['id'] in fixed),'same':sum(r['new_status']=='같음' for r in rows),'fixed_rows':sum(r['fixed'] for r in rows),'excluded':sum(r['new_status']=='제외' for r in rows),'remaining':sum(r['new_status'] not in ['같음','제외','대체'] for r in rows),'suite_groups':len(suite),'suite_failed':0,'round4_direct_checks':direct['checks'],'round4_action_checks':actions['checks'],'round4_ui_checks':ui['checks'],'round4_checks':direct['checks']+actions['checks']+ui['checks'],'new_checks':baseline['summary']['new_checks']+direct['checks']+actions['checks']+ui['checks'],'failures':0,'npm_checks':npm_retry['checks'],'npm_initial_exit':final['npm_exit'],'npm_retry_exit':0,'battle_count':6320,'equal_battles':6320,'matched_actions':sum(p['matched_actions'] for p in parity),'parity':parity,'changed_existing_files':changed,'new_product_files':['project/game/gear_locale_r23.gd'],'protected_changes':protected,'asset_hashes':{'checked':96,'matched':96},'code_lock_unchanged':True,'full_original_parity_complete':False}
assert (summary['same'],summary['excluded'],summary['remaining'])==(61,2,14)
summary['npm_initial_exit']=initial_npm_exit
summary['code_lock_unchanged']=False
summary['final_delta_verified']=True
ledger={**baseline,'round3_snapshot':'verification/parity-r23/gear-round3-ledger.json','summary':summary,'rows':rows}
(O/'gear.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'gear-round4-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'gear-round4-final-verification.json').write_text(json.dumps({'project_groups':len(suite),'project_failed':0,'npm_final_exit':0,'npm_initial_exit':initial_npm_exit,'npm_retry':'gear-suite-round4/npm-retry-result.json','initial_full_run_failures':2,'full_run_code_lock_unchanged':False,'final_delta_verified':True,'retry_groups':final['retry_groups'],'asset_hashes':96,'protected_changes':0},indent=2),encoding='utf-8')
table='\n'.join(f"|{r['id']}|{r['source']['symbol']}|{r['round4_previous_status']} → {r['new_status']}|{r.get('round4_fix_location','') or ('저장·재개' if r['id'] in storage else '직접 대조')}|{r['remaining_reason'] or r.get('exclusion_reason','') or presentation.get(r['id'],'반환·관찰 상태·재개 직접 비교')}|" for r in rows if r.get('round4_reviewed'))
report=f'''# R23-gear — 4차 기능 등가 대조

이전 남은 **37행 전부 재검토**. 이번 **같음 +21행 · 호스트 전용 제외 2행 · 수정 근거 10행**(새 수정 표기 {summary['round4_new_fixed_rows']}행). 누적 **77행 중 같음 61 · 제외 2 · 남음 14**, 누적 수정 {summary['fixed_rows']}행(같음과 중복). 원본 전 기능 완료는 아니다.

전체 프로젝트 **{len(suite)}그룹 / 실패 0**, 서버 npm **{summary['npm_checks']:,}항목 / 최종 실패 0**. 이번 직접 {direct['checks']:,} + 대장간 실행 {actions['checks']:,} + 실제 화면 {ui['checks']:,} = **{summary['round4_checks']:,}항목 / 실패 0**. 누적 R23 직접·화면 {summary['new_checks']:,}항목. 전투 **6,320/6,320판 · {summary['matched_actions']:,}기록 일치**. 원본 자산 **96/96 해시 일치**, 금지 제품 파일 변경 **0개**.

행별 원본 id/위치/이전 상태/새 시험/남은 이유는 [gear.json](verification/parity-r23/gear.json), [요약](verification/parity-r23/gear-round4-summary.json). 이전 원장·보고서는 [3차 원장](verification/parity-r23/gear-round3-ledger.json), [3차 보고](verification/parity-r23/gear-round3-report.md)로 보존했다. 원본 audit-r22b의 두 작업 묶음 **46+31=77행**을 직접 읽고 id·source 위치가 원장과 전부 같음을 확인했다([작업 목록](verification/parity-r23/gear-round4-assigned-items.json)).

## 바꾼 기능과 대조 범위

- 가방 **0/1/1,999/2,000개**에서 추가·제거·장착·해제·판매·일괄 판매를 원본 Lua로 실행하고 native의 소지 코드/장착/금화를 비교했다. 실제 WorldStore 파일에 쓰고 새 World로 읽은 뒤 다음 구입도 비교했다. 중복 코드는 UID의 바이트가 아닌 소지·착용 결과로 판정했다. 손상 문자열/잘못된 형식, 손상 JSON의 백업, 거절의 원자성, 시제품 1회 이관 후 재개도 시험했다. 시제품·불명 토큰을 보존하는 숨은 기록은 사용자 소지·착용 목록에 다시 노출하지 않는다.
- 대장간 제련은 빈 목록/+10/금화 부족/중복 코드/장착품/성공·실패 표시, 가공은 **1/10/11/20/21/30/31/40레벨 경계**와 금화/빈·무효·정상 결과를 대조했다. 누락된 가공 결과 장비 상세 카드를 복원하고 **장비 1,030종 × 한·영 = 2,060카드**의 이름·등급·레벨·기본/무작위/고유 효과 문구·값·순서를 원본과 직접 비교했다.
- 의뢰 카드의 전체 제목·별·종류·적 레벨·적 강도·보상을 복원했다. 빈 의뢰판과 채우기, 활성 의뢰, 갱신 비용/안내도 대조했다. 원본처럼 제련과 의뢰 포기는 누르면 바로 확정된다. 기존 UI 회귀의 추가 확인 클릭 두 곳을 제거한 이유다. 기대 숫자/난수/원본 문구는 바꾸지 않았다.
- 영입의 소개비/보유 금화/명단 셀, 최근 동료 카드 **30명 전원**의 종족·계통·국가·직업·전열/후열·속성·호감·개인 스킬/특성, **0/1/2/30명**의 최신 역순 명단/도감 버튼을 한·영으로 비교했다. 레비아의 무속성 표시와 누락된 시설 번역을 원본 번역으로 보완했다. 최근 영입 표시는 기존 저장 필드 town_r21.meet를 사용한다. AI 이어쓰기 보조 문구만 제외했다.
- 대장간 접두 버튼에 장면 가드/정렬된 1부터 시작하는 인덱스 dispatcher를 연결했다. 성공·거절·무효 인덱스·잘못된 탭·작업 전/후 완료·퇴장·금화/가방 한계와 저장 재개 **{actions['checks']}항목**을 원본 H.sm과 대조했다. 새 작업과 탭 이동이 효과를 지우며, 가공 결과 코드를 transient 효과에 보유한다.
- 호감 함수의 실제 대응인 aff_add_source는 임의 cid/잘못된 테이블/숫자 문자열/0 증감/선택적 chron_aff까지 기존 직접 대조와 새 반환·상태 시험을 근거로 같음 처리했다. owned facade의 별도 UI 동선까지 같다고 확장하지 않았다. 영입은 addChat 성공/false/예외 어느 경우에도 확정 결과가 유지되고 파일 재개 뒤에도 같은 것을 비교했다. addChat만 수행하는 두 익명 함수는 공통 기준에 따라 제외했다.

제품 수정은 [facilities_world_r22.gd](project/game/facilities_world_r22.gd), [facilities_screen_r22.gd](project/ui/facilities_screen_r22.gd), 신규 [gear_locale_r23.gd](project/game/gear_locale_r23.gd). 공유 번역표·저장 schema·서버 허용 목록은 바꾸지 않았다. [원본 실행기](tools/gear_r23_round4.mjs)는 원본을 읽기만 하고 기존 lexical helper를 export했다. [원본 해시/건수](verification/parity-r23/gear-round4-provenance.json), [HTML에서 관찰한 텍스트/버튼](verification/parity-r23/gear-round4-semantics.json). 태그/class/style/asset macro는 비교하지 않고 실제 보이는 텍스트와 버튼을 비교했다.

## 남은 14행

저장 매체나 HTML 형식만으로 남긴 행은 없다. **P3540**은 포화 가방에서 원본이 부적합 장착을 유지하고 native가 overflow에 보관하는 실제 차이(6 probe 중 2 차이)다. **4개 장비 훅**은 임의 선행 콜백까지 native 실제 호출로 합성하는 추가 직접 근거가 남아 있으며, 전투 파일 수정 금지를 지켰다. 나머지 **9행**은 전체 시설 화면의 누락 정보/선택 순서/안내, 상위 dispatcher/연구 위임, 여관 talk의 즉시 확정과 선택 대화 차이다. 이번 leaf helper 통과를 부모 전체 같음으로 올리지 않았다. 각 사유와 원본 위치는 아래 표 및 원장에 적었다.

[포화 가방 차이 관찰](verification/parity-r23/gear-round4-restriction-gaps.json)은 의도적으로 남은 차이를 기록한 진단이다. 이를 일치 시험으로 세지 않았다. 원본 AI/호스트 호출이나 성인 장면 자체는 남은 수에 넣지 않았다.

## 검사·실패 이력과 보존

[최종 검사 집계](verification/parity-r23/gear-round4-final-suite.json), [최종 코드 잠금](verification/parity-r23/gear-round4-final-code-lock.json), [최종 검증](verification/parity-r23/gear-round4-final-verification.json). import, 모든 *_test, 필수 integration/export_licenses, 전투 8묶음을 포함한다. 로컬 클라우드는 독립 포트의 **node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs**로 실행했고 자신이 띄운 PID만 종료했다.

최초 전체 실행은 [원본 집계](verification/parity-r23/gear-suite-round4/results.json)에 **실패 2그룹**을 그대로 남겼다. A8은 3,584/5,120판까지 차이 0 뒤 오류 메시지 없이 exit -1로 조기 종료되어, 원본 시험을 별도 runtime에서 그대로 재실행했다([A8 재실행](verification/parity-r23/gear-a8-round4-retry/results.json)). 새 UI 시험의 실패 2항목은 레비아 무속성 번역에서 원본 B.U의 “No element” 대신 B.T의 “None”을 쓴 실제 차이였다. 해당 **UI 한 식만** source_u로 고쳤고, 관련 시설·마을 UI **11그룹**을 재실행했다([UI 재실행](verification/parity-r23/gear-ui-round4-retry/results.json)). 전체 검사 도중 코드가 바뀌어 최초 잠금 검증은 실패했으며 이를 통과로 덮지 않았다. [최종 판정기](tools/gear_r23_round4_finalize.py)가 수정 전 파일 해시·정확한 1식 diff·그 외 제품/시험 불변·A8 원본 시험 불변·12개 재검사 통과를 확인한 뒤 최신 결과만 합쳤다([근거](verification/parity-r23/gear-round4-adjudication.json)). 최종 실패 0은 이 집계 기준이다.

첫 npm 실행은 64 KiB streaming-limit 사례에서 undici **ECONNRESET/terminated**로 종료됐다. [첫 로그](verification/parity-r23/gear-suite-round4/npm-test.log)를 보존했고 서버/시험 소스를 바꾸지 않고 npm만 재실행해 전부 통과했다([재실행](verification/parity-r23/gear-suite-round4/npm-retry.log), [결과](verification/parity-r23/gear-suite-round4/npm-retry-result.json)). 전체 Godot 검사는 한 번 실행했다. Windows root certificate store 진단만 환경 메시지로 제외했으며 다른 ERROR/Script error는 실패로 처리했다.

개발 중 새 fixture의 dbg_out 호스트 변수 보존 누락·settings 초기화·빈 process_n 접근은 시험 오류로 수정했다. UI 직접 비교는 누락 번역, helper가 이미 가공된 sub를 재번역하는 오류, 무속성을 발견해 수정하고 통과했다. 초기 비교 로그 [1](verification/parity-r23/gear-round4-ui-first.log), [2](verification/parity-r23/gear-round4-ui-second.log)을 보존했다. 확인하지 않은 원본 분기 전체 커버리지 수치를 새로 주장하지 않는다.

실제 확인한 화면과 한계는 [화면 검수](verification/parity-r23/gear-round4-visual-review.json)에 기록했다. 기존 인물·배경·색·글꼴·전투 화면을 보존했고 Impeccable 검사 결과는 위반 0개다. 스킬은 DESIGN.md 대비 .impeccable/design.json 메타데이터가 오래됐다고 알렸으며, 범위 밖 갱신은 하지 않았다(document 명령으로 별도 동기화 가능).

docs/Web export/버전 갱신/Git 명령/커밋 없음. 사용자 저장은 건드리지 않았고 시험 전용 파일만 격리된 runtime에 썼다. 원본·서버·금지 마을/원정/페르소나/전투 코드·자산은 시작 hash와 동일하다. 신규 대조 JSON은 전부 gear- 접두이며 각 40 MB 미만이다.

|행|원본 함수|3차 → 4차|수정 또는 처리|근거·남은 사유|
|---|---|---|---|---|
{table}
'''
(R/'R23-gear.md').write_text(report,encoding='utf-8');print(json.dumps(summary,ensure_ascii=True))
