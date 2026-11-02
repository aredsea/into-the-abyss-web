"""Append second-pass evidence to the original 109-row ledger; never resets pass one."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[1]
out=root/'verification/parity-r23'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
first=out/'expe-pass1-ledger.json'
if not first.exists():
    first.write_bytes((out/'expe.json').read_bytes())
    (out/'expe-pass1-report.md').write_bytes((root/'R23-expe.md').read_bytes())
old=read(first)
results=read(out/'expe-pass2-results.json')
ui=read(out/'expe-pass2-ui-results.json')
reg=read(out/'expe-pass2-regression.json')+read(out/'expe-pass2-balance.json')+read(out/'expe-pass2-refinements.json')
reg={r['test']:r for r in reg}
audits=['combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
expected={'import','balance_probe',*audits}
expected.update(p.stem for p in (root/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration'])
assert set(reg)==expected,(sorted(expected-set(reg)),sorted(set(reg)-expected))
assert not results['failures'] and not ui['failures']
assert all(r['passed'] for r in reg.values()),[r for r in reg.values() if not r['passed']]
same={
 'P2998':('level_who','expedition_member_name'),
 'P3013':('pname','expedition_member_name'),
 'P3014':('prow','sortie_persona_role'),
 'P3015':('members','sortie_members'),
 'P3024':('ordered','sortie_candidate_records'),
 'P3030':('summary','sortie_quest_summary'),
 'P3076':('zone_title','dungeon_zone_title'),
 'P3121':('gear_label','expedition_gear_label'),
 'P3122':('gear_label_en','expedition_gear_label'),
 'P3129':('explore_pname','expedition_member_name'),
 'P3130':('member_name','expedition_member_name'),
 'P3131':('run_members','expedition_members'),
 'P3135':('rar_of','expedition_item_rarity'),
 'P3233':('retreat','expedition_retreat'),
 'P3242':('use_text','use_expedition_item'),
 'P3248':('equip_key','expedition_equip_key'),
}
# Count actual behavior corrections plus record views newly connected to real
# callers. Pure already-equivalent name/slot projections are test additions.
fixed={'P3013','P3014','P3015','P3024','P3030','P3076','P3121','P3122','P3129','P3134','P3135','P3159','P3168','P3233','P3242'}
partial_tests={'P3134':['itname'],'P3159':['rest_text'],'P3168':['discovery_text'],'P3251':['retreat','use_text','equip_key'],'P3277':['discovery_text','rest_text','use_text'],'P3282':['retreat_resume'],'P3303':['retreat'],'P3293':['equip_key','gear_label']}
specific={
 'P2998':'문자열 인물 ID, 미상/빈 ID 및 동료 30인 전체와 이름 5종을 원본 who로 실행했다. native 표시 이름 어댑터로 직접 대조했다.',
 'P3013':'빈 이름/일반 이름/HTML 문자/공백/{{user}}를 원문 그대로 반환한다. 빈 이름만 당신으로 바꾼다.',
 'P3014':'10직업과 미상/빈 직업의 row·cls 두 반환값을 native 레코드로 대조했다. 없는 직업의 row는 빈 문자열이다.',
 'P3015':'12직업 입력×참전/지휘×4편성. 중복/미영입/미상 ID 제거 및 cap 정리 부작용과 id/name/cls/row/lv 전체를 대조했다.',
 'P3024':'cid/on/lv/i 전체 레코드, 원본 인물 순서의 1기준 i, 유효/무효 필터와 선택 우선 정렬을 직접 대조했다.',
 'P3030':'실제 72-guild.gd_qlv를 로드한 의뢰 없음/빈 의뢰/숫자 문자열/소수/상하한/손상 lv/4난이도/별 fallback의 한·영 168입력. native 출정 경고와 수락 의뢰 버튼에 연결했다.',
 'P3076':'1~420층, ko/en 원문 제목 840건. 심층/구역 순환/번역을 실제 dungeon_title에서 사용한다.',
 'P3121':'1,030종×3씨앗, 원본 ITEMS 전체 38개, 잘못된 코드/미상 입력을 포함한 3,142건의 한국어/영어 UI 장비명/희귀도/Lv/미상 반환을 대조했다. 실제 주머니·정산 표시에서 사용한다.',
 'P3122':'동일 3,142코드/ID의 C1_en 영문명과 희귀도·미상 반환을 한·영 UI 상태에서 모두 대조했다. native 영문 표시에서 사용한다.',
 'P3129':'출정 pname과 별도로 원본 탐색 pname도 노출하여 이름 5종을 대조했다.',
 'P3130':'동료 전체 30인, 페르소나 이름 5종, 미상/빈 ID fallback을 직접 대조했다.',
 'P3131':'4슬롯의 점유/빈 자리 16조합에서 slot/m 레코드 전체와 추가 snapshot 필드 보존을 대조했다. 활성 원정 인물 순서가 이 함수를 사용한다.',
 'P3134':'원본 ITEMS 전수를 열거해 귀환 두루마리/레벨업 스크롤의 표시 이름까지 보강했다(효과/상점 규칙 추가 없음). 79-sex 전용 charm_potion(매혹의 비약)은 지시대로 목록만 남기고 이름/장면을 이식하지 않았으므로 이 함수 전체는 일부로 남긴다. 이 1입력은 이름 같음 단언에서 명시적으로 제외하며 나머지 3,141입력은 직접 일치한다.',
 'P3135':'동일 3,142입력의 rarity 또는 nil을 직접 대조했다(nil은 native null). 장비 생성·가방 규칙은 바꾸지 않았다.',
 'P3159':'휴식 자원·R.last·로그 원문 16입력을 추가로 일치시켰다. 원본 직접 재호출의 반복 회복과 native rested 중복 방지, 호스트 pend 및 이번 이식 제외 대상의 sx0 필드는 남는다.',
 'P3168':'200개의 실제 원본 H.ex(go)를 실행해 phase/step/elites/last/log/금화/아이템/장비/HP/MP 전체 투영이 같아졌다. 전투 초기화를 관찰할 때 B.run만 멈췄다. AI pending 누적·Risu 호스트 저장은 native에 없어 일부로 유지한다.',
 'P3233':'원본 do_retreat의 4phase×ask×요청/취소/확인 24전이를 대조했다. 확인 없는 yes·낡은 phase를 거부하고 ask를 저장/복구한다. 정산의 별도 함수 finish_run 전체 동등성으로 확대하지 않는다.',
 'P3242':'기존 792자원 표본에 72품목/phase/생사 표본을 추가. 자원·재고·last·로그 불변까지 같다. native done/town 일반 사용과 별개인 실제 활성 원정 호출 경계 use_expedition_item을 대조했다.',
 'P3248':'0~5슬롯 및 16점유 조합의 원본 id/nil을 native id/빈 문자열로 정규화해 96건 대조했다. 휴식 장착 가능 판정의 실제 호출 경로에 연결했다.',
 'P3251':'퇴각 요청/취소/저장 재개와 아이템·슬롯 경계를 보강했다. cont/next/home의 Risu 메시지·note·장면 및 전체 버튼 문자열 ABI는 남는다.',
 'P3277':'R.last 자체는 발견/휴식/아이템 288입력에서 원본 문구를 일치시켰다. last_card의 빈 문자열/HTML 탈출·태그 전체 반환은 native 캔버스와 다르다.',
 'P3282':'퇴각 확인의 실제 입력/저장 재개/취소/중복 거부는 5크기 UI 210검사에서 통과했다. 원본 HTML 안내/버튼 반환 계약은 남는다.',
 'P3293':'정비 슬롯과 장비 라벨의 직접 대조를 추가했다. gear_card의 R.sel 정규화·HTML 전체와 원본 장비 버튼 후보 반환은 별도 경계다.',
 'P3303':'원정 정산과 이름/장비 표시를 보강했다. done_screen의 전체 HTML·정렬/보존/유실 표시 및 native summary 배열/사전 ABI가 다르다.',
}
W='project/game/expedition_world_r22.gd';D='project/game/dungeon_world_r21.gd'
def line(file,symbol):
    for i,text in enumerate((root/file).read_text(encoding='utf-8').splitlines(),1):
        if text.startswith('func '+symbol+'('):return f'{file}:{i}'
    raise AssertionError(symbol)
rows=old['rows'];reviews=[]
source_root=Path('C:/Clauede Code/dungeon-bot')
for r in rows:
    if r['status']=='같음':continue
    rid=r['id'];r['pass1_status']=r['status'];r['pass1_fixed']=r['fixed']
    src=source_root/r['source']['file'];raw=src.read_text(encoding='utf-8-sig').splitlines()
    excerpt='\n'.join(raw[r['source']['start']-1:r['source']['end']])
    review={'id':rid,'source':r['source'],'source_sha256':digest(src),'excerpt_sha256':hashlib.sha256(excerpt.encode()).hexdigest(),'pass1_status':r['status']}
    groups=[same[rid][0]] if rid in same else partial_tests.get(rid,[])
    if rid=='P3121':groups.append('gear_label_ui_en')
    if rid=='P3122':groups.append('gear_label_en_ko')
    for group in groups:
        assert results['groups'][group]['failures']==0
        evidence=f'expe_pass2_r23_test::{group} ({results["groups"][group]["checks"]} checks)'
        if evidence not in r['tests']:r['tests'].append(evidence)
    if rid in same:
        assert r['status']!='같음'
        r['status']='같음';r['remaining_reason']=''
        location=line(D if rid=='P3076' else W,same[rid][1])
        r['implementation']=list(dict.fromkeys(r.get('implementation',[])+[location]))
        r['equality_domain']='원본 문자열 ID/유효한 native 상태 투영. m 슬롯·nil·레벨/재고 별칭을 명시적으로 매핑하며 HTML/호스트는 이 행의 계약에 포함되지 않는다.'
    elif rid in specific:
        r['remaining_reason']=specific[rid]
        if rid=='P3134':r['status']='일부'
    if rid in fixed:r['fixed']=True
    r['pass2_evidence']={'source_review':True,'source_sha256':review['source_sha256'],'source_excerpt_sha256':review['excerpt_sha256'],'groups':groups,'direct_function_comparison':rid in same,'execution_scope':'direct mapped function' if rid in same else 'dependency/partial flow only' if groups else 'source review only; unresolved','detail':specific.get(rid,r['remaining_reason'])}
    review.update(status=r['status'],direct_function_comparison=rid in same,groups=groups,remaining_reason=r['remaining_reason'])
    reviews.append(review)
assert len(reviews)==91 and len(rows)==109
# Compare against a newly read frozen ledger, not the mutated working rows.
frozen=read(first)
assert all(next(r for r in rows if r['id']==p['id'])==p for p in frozen['rows'] if p['status']=='같음')
before=read(out/'expe-pass2-before.json')
changed=[p for p,h in before.items() if not (root/p).is_file() or digest(root/p)!=h]
allowed={W,D,'project/ui/persona_sortie_screen.gd','project/ui/expedition_screen_r22.gd'}
assets=read(root/'ASSET-HASHES.json');asset_changes=[a['path'] for a in assets if digest(root/a['path'])!=a['sha256']]
outside=[p for p in changed if p not in allowed]
assert not outside,outside
assert not asset_changes,asset_changes
traces=[]
for name,file in zip(audits,['p2-full-battles.json','a6-mixed-audit.json','p3-mixed-audit.json','a7-gear-audit.json','a7-gear-balanced-audit.json','a8-audit.json','a9-native-10-audit.json','a9-native-40-audit.json']):
    p=root/'verification/data-r21'/file;t=read(p)
    equal=t.get('equal_battles',sum(not r.get('mismatches') and r.get('source_result')=={'victory':'win','defeat':'lose'}.get(r.get('godot_result'),'') for r in t.get('reports',[])))
    traces.append({'test':name,'file':p.relative_to(root).as_posix(),'sha256':digest(p),'battles':t['battles'],'equal':equal,'records':t['matched_actions']})
assert sum(r['battles'] for r in traces)==sum(r['equal'] for r in traces)==6320
pass2={'reviewed_rows':91,'promoted_same':len(same),'fixed_rows':len(fixed),'remaining_rows':sum(r['status']!='같음' for r in rows),'oracle_checks':results['checks'],'oracle_failures':len(results['failures']),'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'ui_captures':len(ui['captures']),'regression_groups':len(reg),'failed_groups':[],'protected_snapshot_files':len(before),'changed_existing_files':changed,'outside_allowed_changed':outside,'assets_checked':len(assets),'asset_changes':asset_changes,'trace_battles':6320,'trace_equal_battles':6320,'trace_records':sum(r['records'] for r in traces)}
summary={**old['summary'],'promoted_same':sum(r['status']=='같음' for r in rows),'fixed_rows':sum(r['fixed'] for r in rows),'fixed_still_remaining':sum(r['fixed'] and r['status']!='같음' for r in rows),'remaining_rows':pass2['remaining_rows'],'oracle_checks':old['summary']['oracle_checks']+results['checks'],'oracle_failures':0,'regression_groups':len(reg),'failed_groups':[],'changed_existing_files':sorted(set(old['summary']['changed_existing_files']+changed)),'trace_battles':6320,'trace_equal_battles':6320,'trace_records':pass2['trace_records'],'pass2':pass2}
document={**old,'summary':summary,'rows':rows,'checks':list(reg.values()),'trace_reports':traces,'passes':[{'pass':1,'summary':frozen['summary'],'ledger':'verification/parity-r23/expe-pass1-ledger.json'},{'pass':2,'summary':pass2,'row_review':'verification/parity-r23/expe-pass2-row-audit.json'}]}
original_same_locations={
 'P2991':(W,'expedition_level'),'P2992':(W,'expedition_experience'),
 'P3023':(W,'sortie_filter'),'P3025':(W,'sortie_candidate_records'),
 'P3070':(D,'dungeon_max'),'P3072':(D,'dungeon_allowed'),'P3074':(D,'dungeon_floor_view'),
 'P3132':(W,'append_expedition_log'),'P3191':(W,'append_expedition_gear'),'P3194':(W,'roll_expedition_gear'),
 'P3196':(W,'bank_expedition_items'),'P3241':(W,'outside_item_multiplier'),
 'P3319':('project/game/expedition_supply_r22.gd','supply_need'),
 'P3325':('project/game/expedition_supply_r22.gd','supply_target_state_ok'),
 'P3326':('project/game/expedition_supply_r22.gd','has_supply_dot'),
 'P3328':('project/game/expedition_supply_r22.gd','supply_target_ok'),
 'P3329':('project/game/expedition_supply_r22.gd','any_supply_target'),
 'P3330':('project/game/expedition_supply_r22.gd','supply_level_blocked')}
assert set(original_same_locations)=={r['id'] for r in frozen['rows'] if r['status']=='같음'}
document['current_implementation_lines']={rid:line(file,symbol) for rid,(file,symbol) in original_same_locations.items()}
write(out/'expe-pass2-row-audit.json',reviews);write(out/'expe-pass2-checks.json',list(reg.values()));write(out/'expe.json',document)
reason_rows='\n'.join(f'|{r["id"]}|{r["source_symbol"].replace("|","/")}|{r["status"]}|{r["remaining_reason"]}|' for r in rows if r['status']!='같음')
report=f'''# R23-expe — 2차 원본 대조

1차의 같음 18행을 그대로 보존하고 남은 **91행 전부를 다시 검토**했다. 이번에 **{len(same)}행을 추가로 같음**, 누적 **{summary['promoted_same']}/109행 같음**, **{summary['remaining_rows']}행 남음**이다. 행별 원본 위치·이전 상태·시험·구현 줄·남은 이유는 [expe.json](verification/parity-r23/expe.json)에 이어 기록했다. 남은 행을 구현 완료로 세지 않았다.

|구분|2차|누적/최종|
|---|---:|---:|
|이번 검토|91|109|
|같음으로 승격|{len(same)}|{summary['promoted_same']}|
|수정·구현·실제 호출 연결한 행(승격과 겹침)|{len(fixed)}|{summary['fixed_rows']}|
|남은 행|{summary['remaining_rows']}|{summary['remaining_rows']}|
|원본 Lua 대조 단언|{results['checks']:,}|{summary['oracle_checks']:,}|
|원본 대조 실패|0|0|
|전체 회귀 검사 그룹|{len(reg)}|실패 0|
|새 퇴각 UI 단언/캡처|{ui['checks']} / {len(ui['captures'])}|실패 0|
|전투 대조|6,320판|6,320판 일치 / {pass2['trace_records']:,}기록|
|보호 자산|96개|변경 0|
|허용 범위 밖 기존 파일 변경|0|0|

2차 승격: {', '.join(same)}.

## 바뀐 동작과 근거

- 빈 이름만 `당신`으로 대체하고 `{{{{user}}}}`·공백·특수문자 이름은 원본대로 보존한다. 동료 전체 30인 및 미상 ID 이름도 직접 대조했다. 10직업+미상/빈 직업, 참전/지휘, 중복/미영입 인물의 편성 정리와 전체 멤버 레코드, 후보의 cid/on/lv/i 레코드를 실제 출정 경로에 연결했다.
- 의뢰의 적 레벨을 `72-guild.lua`의 실제 `gd_qlv`로 계산한 원본과 비교했다. 의뢰 없음, 빈 의뢰, 소수/숫자 문자열/손상 값, 1~40 경계, 네 난이도와 별 fallback을 포함한다. 수락 의뢰 버튼에도 해당 위험 경고를 연결했다.
- 탐색 결과의 `last`와 로그를 원본 문구로 맞췄다. 1/3/18/28층의 실제 탐색 200입력에서 분기·자원·주머니·장비·휴식 진입을 함께 대조했다. 휴식의 자세한 회복 문구와 별도 로그, 전투 밖 아이템 사용의 문구 및 로그 불변도 맞췄다.
- 장비 1,030종×3씨앗, 원본 ITEMS 전체 38개와 무효 코드/미상 ID를 포함한 3,142입력에서 희귀도·한국어/영어 UI 표시·영문 C1 표시를 비교했다. 이름은 제외 대상 charm_potion 1건을 뺀 3,141입력을 일치시켰으며 해당 함수 P3134는 일부로 남겼다. 귀환 두루마리/레벨업 스크롤은 표시 이름만 보강했고 효과나 상점 규칙은 추가하지 않았다. 실제 주머니/정산 화면에 쓰며 장비 규칙이나 가방은 고치지 않았다. 1~420층의 한·영 구역/심층 제목 840건도 고정했다.
- 원본의 퇴각 `ask`를 요청·취소·확인 전이에 연결했다. 저장 후 화면을 다시 열면 확인창을 복구하고, 취소는 저장된 `ask`를 지우며, 확인 없는 yes와 중복 정산을 거부한다. 4phase×ask×3입력과 실제 UI 5크기로 확인했다. 정비 슬롯은 16점유 조합과 범위 밖 슬롯을 포함해 비교하고 활성 인물 경로에서 사용한다.

`tools/expe_r23_pass2_oracle.mjs`는 원본 `lua_sim.mjs`/Wasmoon과 현재 Lua를 실행한다. 원본 파일은 고치지 않고 로드한 청크에 local 참조만 노출한다. 전투 진입 표본의 `B.run` 억제는 초기화 후 자동 적 행동을 섞지 않기 위한 관찰 경계이며, 이 표본으로 전투 결과를 주장하지 않는다. [provenance](verification/parity-r23/expe-pass2-provenance.json)에 원본 SHA와 표본 수, [row-audit](verification/parity-r23/expe-pass2-row-audit.json)에 미완료 91행의 원본 파일/행 및 발췌 SHA를 남겼다.

초기 실패는 `expe-pass2-before-results.json`, 장비/구역 제목/탐색의 추가 실패는 `expe-pass2-*-before.json`에 보존했다. 누락된 레코드 API 시험과 실제 동작 불일치를 구별한다. Lua JSON의 빈 표가 `[]`로 나오는 점, 소비 후 없어진 재고 키는 0으로 투영하는 점, 시험 객체에 settings가 처음 없던 점을 하네스에서 바로잡았다. 이 하네스 수정은 게임 수정 건수에 넣지 않았다.

품목 입력도 전투 목록+옛 장비 35개에서 원본 `B.ITEMS` 전체 38개로 확대했다. 세 추가 품목에서 이름 불일치를 먼저 보존한 뒤 두 표시 이름을 보완했다. 남은 charm_potion 이름 1건은 공통 규칙의 성적 콘텐츠 제외에 해당해 단언에서 제외하고 P3134를 일부로 남겼다. 이 제외를 통과/같음 근거로 세지 않았고, 원본 기대 문자열을 native 값으로 바꾸지 않았다.

## 검사와 실행 조건

최종 검사: `tools/expe_r23_verify.py`의 전체 프로젝트 검사·import·UI/모션·전투 8대조와 별도 `balance_probe`. 결과는 [expe-pass2-checks.json](verification/parity-r23/expe-pass2-checks.json). A8는 이번 전체 5,120판의 실제 완료 보고서를 사용하며 1차의 prefix/suffix 합성 보고서를 재사용하지 않았다. 이번 전투 8보고서의 SHA는 `expe.json.trace_reports`에 있다.

무거운 전체 검사는 한 번 실행했다. 한·영 경고/장비 표시 보강 뒤 해당 원본 대조 검사를 다시 실행했다. 전체 회귀 중 기존 PersonaWorld를 쓰는 출정 화면의 원정 전용 API 무조건 호출 오류를 발견해 지원 여부를 확인하도록 고쳤다. 멈춰 있던 해당 검사 프로세스만 종료하고 Persona UI와 원정 UI를 재검사했다. 첫 실패 로그는 `expe-pass2-persona-ui-before.log`와 전체 실행 원장에 남겼으며, 최신 `expe-pass2-refinements.json` 결과를 최종 집계에 사용했다. 기대값이나 기존 검사는 완화하지 않았다.

클라우드용 기본 `node server/abyss-save/test/serve.mjs`는 의존성 경로 설정 뒤에도 포트 충돌로 실패했다. 8787은 다른 갈래 `r21-d-town`의 workerd가 사용 중이므로 종료하지 않았다. `ABYSS_NODE_MODULES`를 기존 설치로 지정하고 다음처럼 **동일 serve.mjs 및 실제 Worker/D1**을 임시 루프백 포트에서 실행했다.

```
node --import ./tools/expe_r23_server_preload.mjs server/abyss-save/test/serve.mjs
```

preload는 메모리 안에서 런처의 `runtime(8787)`만 `runtime()`으로 바꾸고, 그 D1에 보관 계정 표본을 준비한다. 서버 파일·핸들러·마이그레이션·검사 단언은 바꾸지 않았다. 변환 내용은 `expe-pass2-server-adapter.json`, 실제 주소는 `verification/cloud-r22/local-server-ready.json`에 기록했다. 검사에는 `ABYSS_TEST_SERVER`로 그 주소를 넘겼다. cloud 27/27, archive 5/5 및 전투 저장 검사가 모두 같은 로컬 서비스에서 통과했다. Windows root certificate store 환경 메시지는 검사 실패와 구별했다.

## 변경 파일과 화면 확인

기존 파일 변경: {', '.join('`'+p+'`' for p in changed)}. 새 도구/검사는 `tools/expe_r23_pass2_*.mjs`, `tools/expe_r23_pass2_report.py`, `tools/expe_r23_server_preload.mjs`, `project/tests/expe_pass2_r23_test.gd`, `project/tests/ui_expe_pass2_r23_test.gd`이다.

새 화면 캡처 {len(ui['captures'])}장 중 직접 연 파일은 `pass2-render/retreat-resumed-390x664.png`, `pass2-render/retreat-settled-390x844.png`이다. 작은 높이의 복원 확인창과 정산 화면에서 문구/보상/취소·확인·귀환 버튼이 잘리지 않는 것을 확인했다. 나머지 이미지는 자동 검사 범위이며 직접 눈으로 모두 봤다고 세지 않는다.

1차 원장은 `expe-pass1-ledger.json`, 1차 보고서는 `expe-pass1-report.md`로 보존했다. 기존 같음 18행의 기록은 바꾸지 않았다. 그 행의 당시 구현 줄번호와 별도로 현재 위치를 `expe.json.current_implementation_lines`에 남겼다. 성적/친밀 장면, 전투 파일, 장비/시설 규칙, 서버, 원본 봇, docs는 수정하지 않았다. git 명령·커밋·Web export를 실행하지 않았고 사용자 저장을 지우지 않았다.

이식 제외 목록: `charm_potion`(매혹의 비약), `79-sex.lua`의 관련 장면·사용 경로. 원본 자료와 표본에는 존재하지만 native 코드로 옮기지 않았으며 완료 수에 넣지 않았다.

## 남은 {summary['remaining_rows']}행과 이유

HTML 전체 반환·RisuAI 호스트 저장/메시지, 원본 G의 손상값 제자리 정규화 및 직접 이관, 원본 장비 가방과 native overflow 보존, 허용 목록 밖의 마을/레벨/전투 함수가 남는다. 허용 범위의 수치 일치나 화면 통과를 이 함수 전체 같음으로 전파하지 않았다. 아래는 각 행의 현재 잔여 사유다.

|ID|원본 함수|상태|남은 이유|
|---|---|---|---|
{reason_rows}
'''
(root/'R23-expe.md').write_text(report,encoding='utf-8')
print(json.dumps({'summary':summary,'new_same':list(same),'report':'R23-expe.md'},ensure_ascii=False))
