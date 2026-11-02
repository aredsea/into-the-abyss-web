"""Produce a conservative, row-addressable handoff. Never edits the audit baseline."""
from pathlib import Path
import json,hashlib,re,collections
root=Path(__file__).resolve().parents[1];out=root/'verification/parity-r23'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
work=read(out/'expe-worklist.json')['items']
W='project/game/expedition_world_r22.gd';D='project/game/dungeon_world_r21.gd'
S='project/game/expedition_supply_r22.gd'
def loc(file,symbol):
    lines=(root/file).read_text(encoding='utf-8').splitlines()
    return f'{file}:{next(i for i,s in enumerate(lines,1) if s.startswith("func "+symbol+"("))}'
same={
 'P3023':('sortie_filter',W,'sortie_filter'),
 'P3025':('sortie_order','project/game/persona_world.gd','sortie_candidates'),
 'P3070':('floor_access',D,'dungeon_max'),
 'P3072':('floor_access',D,'dungeon_allowed'),
 'P3074':('floor_view',D,'dungeon_floor_view'),
 'P3132':('log',W,'append_expedition_log'),
 'P3191':('gear_add',W,'append_expedition_gear'),
 'P3194':('gear_roll',W,'roll_expedition_gear'),
 'P3196':('bank_items',W,'bank_expedition_items'),
 'P3241':('outside_multiplier',W,'outside_item_multiplier'),
 'P3325':('bag',W,'supplies'),
 'P3319':('needs',S,'supply_need'),
 'P3326':('combat_targets',S,'has_supply_dot'),
 'P3328':('combat_targets',S,'supply_target_ok'),
 'P3329':('combat_parties',S,'any_supply_target'),
 'P3330':('combat_parties',S,'supply_level_blocked'),
 'P2991':('levels',W,'expedition_level'),
 'P2992':('levels',W,'expedition_experience'),
}
partial={
 'P3024':('sortie_order',W,'sortie_candidates','후보 ID 순서·유효/무효 필터는 대조했다. 원본 반환의 cid/on/lv/i 레코드 전체와 native UI 카드 계약을 같음으로 확대하지 않는다.'),
 'P3030':('sortie_summary',W,'sortie_summary','이미 해석된 적 레벨을 입력한 n/avg/elv/front/warns는 일치한다. 원본 q 전체와 gd_qlv 의 의뢰별 해석까지 이 함수의 native 출정 흐름에서 대조한 것은 아니다.'),
 'P3031':('sortie_summary','project/ui/persona_sortie_screen.gd','build','경고를 출정 화면에 연결했다. 원본 summary_card HTML 전체 반환은 native 캔버스와 다르다.'),
 'P3073':('initial_vitals','project/game/persona_world.gd','source_pm','1~4인·세 레벨 편성은 실행했다. pm 전체(장비·스킬 스냅샷), 빈/손상된 원본 G의 전체 dn_party 반환 계약은 별도 대조가 남았다.'),
 'P3079':('floor_view','project/ui/persona_sortie_screen.gd','build','층 정보 77건과 실제 페이지/경고 화면을 확인했다. dn_card HTML 전체·페이지 초과값의 정규화까지 동일하다고 세지 않는다.'),
 'P3124':('initial_vitals',W,'depart_dungeon','입장 자원 24건을 고쳤다. 원본 G_rnd의 소비 상태·sid·boss_name·pm 전체·빈 슬롯 전체를 포함한 ex_new 반환 전부는 같은 저장 ABI가 아니다.'),
 'P3140':('initial_vitals',W,'depart_dungeon','출발 상태는 대조했으나 이전 층 prev 목록·RisuAI pend_hard·메시지/장면 계약은 남는다.'),
 'P3145':('first_battle',W,'battle_data','첫 전투 전 자원 24건을 대조했다(B.run을 잠시 막아 전투 시작 뒤 적 행동과 분리). 전투 저장 매체·st 전부·원본 호스트 장면 전환의 동등성 증거는 아니다.'),
 'P3159':('rest',W,'enter_dungeon_rest','기존 원본 휴식 120건과 native 반복 입력 검사를 유지했다. native는 rested로 중복 회복을 차단하며 원본 enter_rest 직접 재호출·sx0/장면 지시/전체 로그는 다르다.'),
 'P3168':('discovery',W,'advance','실제 탐색 이벤트 9건과 기존 2100 roll/440 발견 보정 표본을 대조했다. R.last·로그 원문·pend 및 전투 진입 전체 저장 계약은 아직 일부다.'),
 'P3176':('snapshot',W,'snapshot_expedition_party','생존/사망·소수 HP/MP·최대치 내림을 대조했다. 원본 al/empty/real 배열 ABI와 native HP 기반 생사·wins 기반 이월 전체의 동일성을 주장하지 않는다.'),
 'P3189':('boss_guard',W,'final_battle','퇴각 확인 중에도 보스를 시작하고 ask를 지우도록 수정했다. B.ex_battle의 호스트 저장·메시지 전체가 native 버튼 경계와 같지는 않다.'),
 'P3202':('settlements',W,'settle','클리어/퇴각/패배 기존 9 Lua 정산과 native 45씨앗을 재검사했다. defeat 뒤 원본 run 제거/거점 이동과 native 완료 run 보관, 요약 필드·문구·호스트 계약 차이가 남는다.'),
 'P3223':('settlements',W,'finish_battle','native는 스냅샷 build/상태 검증을 사용한다. 원본 sid/bn 불일치 시 거점 복귀·메시지·legacy 분기 전체에 대한 함수 단위 일치는 미확정이다.'),
 'P3242':('outside_use',W,'use_item','레벨 1/14/15/29/30/40·11품목·6상태·출신 2종 792건의 HP/MP/거점/주머니는 일치한다. R.last 원문·로그/호스트 장면 필드까지 같은 함수는 아니다.'),
 'P3309':('migration',W,'migrate_expedition_items','거점/주머니의 potion/mana 합산·숫자 문자열·반복/JSON·입력 불변을 고쳤다. 음수/소수 등 원본이 산술적으로 받아들이는 값은 기존 native 저장 검증에서 원자적으로 거부한다.'),
 'P3311':('migration',W,'restore','별칭 이관은 보강했다. prev_migrate 전체 원본 저장 스키마 및 canonical G를 native 저장으로 직접 읽는 범용 이관은 미구현이며, 기존 native 저장 이관을 보존했다.'),
}
fixed={'P2991','P2992','P3023','P3024','P3030','P3031','P3079','P3124','P3145','P3176','P3189','P3309','P3311','P3319','P3326','P3328','P3329','P3330'}
reasons={
 'P3061':'원본 dn_G는 손상/누락 필드를 제자리 정규화한다. native는 자체 저장 스키마를 검증/거부하므로 손상 G 전체 계약이 다르다.',
 'P3076':'zone_title은 번역/HTML 탈출 전 표시 문자열이다. native는 zone.name과 별도 캔버스 라벨을 쓰며 심층 제목 원문 전체의 직접 반환 비교가 없다.',
 'P3119':'기존 ex_roll 표본은 유지했다. 내부 wt의 모든 item_from/item_w 누락·경계 입력에 대한 독립 직접 반환 fixture는 없다.',
 'P3120':'원본 ex_run은 dn_G를 호출하면서 원본 dungeon 구조도 정규화한다. native run 접근과 손상 상태의 부작용까지 같은 계약이 아니다.',
 'P3121':'원본 번역/희귀도/Lv/알 수 없는 장비 문자열 전체와 native 코드↔UID 표시를 직접 비교하지 않았다. 장비 규칙 파일은 수정 금지다.',
 'P3122':'영문 장비명/희귀도 번역 C1_en 전체 반환은 native 표시와 아직 대조되지 않았다. 장비/번역 범위를 임의로 확대하지 않았다.',
 'P3123':'zero4는 원본 고정 4슬롯 배열이며 native는 인물 ID 딕셔너리다. 입장 자원 투영의 일치를 이 내부 반환 배열 함수로 전파하지 않는다.',
 'P3129':'빈 이름/일반 이름 및 {{user}} 표시에 native의 별도 자리표시자 규칙이 있다. 함수 전체 문자열을 직접 대조하지 않았다.',
 'P3130':'원본은 알 수 없는 cid를 cid 그대로 돌려준다. native person 조회의 유효 인물 제약/이름 fallback 전체 직접 대조가 남는다.',
 'P3131':'원본 members는 빈 자리 포함 pm에서 {slot,m} 배열을 만든다. native expedition_ids의 ID 배열만으로 레코드/누락 슬롯 전체 같음을 세지 않는다.',
 'P3134':'원본 itname은 장비 코드와 소모품 및 알 수 없는 ID를 모두 처리한다. native 이름/UID/코드 fallback 전체 직접 대조가 없다.',
 'P3135':'원본 rar_of의 장비 코드/일반 품목/누락 ID 반환 전체는 장비 표시 규칙 영역에 걸리며 독립 fixture가 없다.',
 'P3138':'floor_label은 영문 AI 장면 지시용 문구다. native 제목은 별도 캔버스 문자열이며 원문을 임의로 같음/제외로 승격하지 않는다.',
 'P3182':'do_cont의 sid/bn/over/dn 무효 입력·적 이름 중복 제거·정예 로그/호스트 전환 전체를 native 스냅샷 continuation과 직접 비교하지 못했다.',
 'P3195':'가방 포화 시 원본은 버린다. native는 사용자 저장 보존을 위해 overflow에 코드를 남긴다. 장비 가방 규칙은 이번 수정 금지다.',
 'P3199':'exp_note의 award_exp 부재/예외/비표 반환에 대한 pcall fallback 및 전체 sum.lv 문자열 대조가 남는다. 레벨 모듈은 허용 파일 밖이다.',
 'P3201':'원본은 인물 이름+호감 문자열 배열, native는 ID별 증가량 딕셔너리를 저장한다. 유효 정산 숫자만으로 전체 반환을 같음으로 세지 않는다.',
 'P3225':'실제 옛 native 저장 11개를 보존해 불러오지만, 원본 st.dn.stage 1/2 저장을 직접 읽어 정산하는 전체 legacy ABI는 별개로 남는다.',
 'P3233':'원본은 R.ask가 있는 retreat_yes만 정산한다. native 확인은 상속 화면의 confirm 객체에 있어 저장된 ask/취소/낡은 버튼 전체 상태 계약이 다르다.',
 'P3248':'원본 equip_key는 pm 슬롯의 id 또는 nil을 반환한다. native는 인물 ID/UID 기반이며 빈/손상 pm 슬롯의 독립 반환 비교가 없다.',
 'P3249':'휴식 정비의 유효 동작은 기존 검사로 보존했다. 원본 장비 코드 버튼 인코딩·잘못된 슬롯·why 문자열·다른 소유자 장비 전체 분기는 장비 규칙 담당 범위다.',
 'P3251':'개별 탐색/아이템/보스 분기는 보강했다. H.ex 전체는 cont/next/home/선택 슬롯/장비 버튼·장면 지시를 포함하며 일부 host/UI 저장 계약이 남는다.',
 'P3307':'ex_label의 run 없음/잘못된 값 및 번역 언어별 전체 반환과 native 제목 문자열의 직접 비교가 없다.',
}
ui77={'P3273','P3274','P3275','P3277','P3278','P3280','P3281','P3282','P3287','P3290','P3293','P3296','P3299','P3303','P3304','P3305'}
def reason(i):
    f=i['source']['file']
    if i['id'] in reasons:return reasons[i['id']]
    if f.endswith('70-town.lua'):return '마을/시설/의뢰/호스트 함수가 섞인 행이다. 대응 town_world_r21·facilities 및 마을 화면은 이번 허용 목록 밖이므로 수정/전체 같음 승격을 하지 않았다. 전투/시설 담당 재감사가 필요하다.'
    if f.endswith('74-level.lua'):return '레벨/경험치 함수 전체는 persona_rules/persona_world 및 마을 지급/번호 표식에 걸친다. 허용 목록 밖이며 원정 정산 숫자 검사를 전체 함수 증거로 전파하지 않았다.'
    if f.endswith('75-sortie.lua'):return '원본 출정 HTML/버튼/메시지 전체와 native 캔버스 및 편성 저장 계약은 다르다. 후보 정렬·위험 경고의 부분 일치만으로 이 함수 전체를 승격하지 않는다.'
    if i['id'] in ui77:return '원본 HTML 전체 반환(태그·버튼·탈출·번역·없는 값 처리)과 native 캔버스는 다르다. 실제 화면·입력 회귀 통과를 HTML 함수 전체 일치로 세지 않았다.'
    if f.endswith('78-battle-item.lua'):return '전투 아이템의 기존 44 효과 표본은 재검사했다. 이 행의 무재고/무효 대상·메뉴 저장 재개·ev/T/pend/원문 문자열을 포함한 전체 ABI 직접 대조가 남는다. 전투 파일은 수정 금지다.'
    return '유효 원정 경로는 회귀 검사를 유지했으나 이 원본 함수의 모든 반환/부작용/무효 입력에 대한 직접 native 대조를 확정하지 못했다.'
results=read(out/'expe-results.json')
supply_results=read(out/'expe-supply-results.json')
level_results=read(out/'expe-level-results.json')
rows=[]
for item in work:
    i=item['id'];row={k:item[k] for k in ['id','feature','source_symbol','source','unverified_branches']}
    row.update(prior_status=item['status'],status=item['status'],prior_reason=item['prior_evidence']['reason'],fixed=i in fixed,tests=[],implementation=[],remaining_reason=reason(item))
    if i in same:
        group,file,symbol=same[i];test='expe_level_r23_test' if group=='levels' else 'expe_supply_r23_test' if file==S else 'expe_r23_test'
        row.update(status='같음',tests=[f'{test}::{group}'],implementation=[loc(file,symbol)],remaining_reason='')
        row['scope']='유효 native 저장 상태/원본 입력의 대응 투영. ID/슬롯 및 sh_↔shield_ 표기를 명시적으로 변환하며, HTML/호스트/손상 저장 전체를 포함하지 않는 순수 함수 계약.'
    elif i in partial:
        group,file,symbol,why=partial[i];row.update(status='일부',tests=[f'expe_r23_test::{group}' if group in results['groups'] else f'expedition_r22_test::{group}'],implementation=[loc(file,symbol)],remaining_reason=why)
    if i in ['P3031','P3079']:row['tests'].append('ui_expedition_r22_test::source-warning-and-paged-selection')
    rows.append(row)
reg={r['test']:r for r in read(out/'expe-regression.json')} if (out/'expe-regression.json').exists() else {}
if (out/'expe-followup.json').exists():reg.update({r['test']:r for r in read(out/'expe-followup.json')})
for file in ['expe-supply-after.json','expe-supply-final.json','expe-picker-final.json','expe-level-final.json','expe-level-boundary-final.json']:
    if (out/file).exists():reg.update({r['test']:r for r in read(out/file)})
# The archive specimen must be created in the very D1 runtime used by its test.
cloudlog=(out/'cloud-isolated.log').read_text(encoding='utf-8',errors='replace') if (out/'cloud-isolated.log').exists() else ''
for name in ['cloud_r22_test','cloud_archive_r22_test']:
    if name+' PASS' in cloudlog:
        f=root/'verification/town-r21/round14'/f'{name}.log';text=f.read_text(encoding='utf-8',errors='replace')
        reg[name]={'test':name,'exit':0,'errors':[],'passed':True,'summary':[s for s in text.splitlines() if 'CHECKS' in s],'harness':'node server/abyss-save/test/godot-r14.mjs cloud_r22_test cloud_archive_r22_test','log':str(f.relative_to(root)).replace('\\','/')}
townlog=(out/'town-combat-isolated.log').read_text(encoding='utf-8',errors='replace') if (out/'town-combat-isolated.log').exists() else ''
if 'town_combat_r21_round14_test PASS' in townlog:
    f=root/'verification/town-r21/round14/town_combat_r21_round14_test.log';text=f.read_text(encoding='utf-8',errors='replace')
    reg['town_combat_r21_round14_test']={'test':'town_combat_r21_round14_test','exit':0,'errors':[],'passed':True,'summary':[s for s in text.splitlines() if 'CHECKS' in s],'harness':'node server/abyss-save/test/godot-r14.mjs town_combat_r21_round14_test','log':str(f.relative_to(root)).replace('\\','/')}
# A final oracle run supersedes the deliberately retained failing development run.
final=(out/'expe-final.log').read_text(encoding='utf-8',errors='replace') if (out/'expe-final.log').exists() else ''
if 'EXPE R23 CHECKS' in final and not results['failures']:
    reg['expe_r23_test']={'test':'expe_r23_test','exit':0,'errors':[],'passed':True,'summary':[s for s in final.splitlines() if 'EXPE R23 CHECKS' in s],'log':'verification/parity-r23/expe-final.log'}
composed=read(out/'a8-composed.json') if (out/'a8-composed.json').exists() else None
if composed and composed['battles']==composed['equal_battles']==5120 and composed['source_actions']==composed['actual_actions']==composed['matched_actions']:
    reg['combat_a8_audit']={'test':'combat_a8_audit','exit':0,'errors':[],'passed':True,'summary':[f"A8 exact prefix+suffix: {composed['equal_battles']}/{composed['battles']} battles, {composed['matched_actions']} records"],'log':'verification/parity-r23/combat_a8_audit.log','evidence':'verification/parity-r23/a8-composed.json','continuation':'Original strict audit zero-gap prefix + identical comparison code on remaining row slice. Timed-out full-run log retained.'}
before=read(out/'expe-before.json');changed=[p for p,h in before.items() if not (root/p).is_file() or hashlib.sha256((root/p).read_bytes()).hexdigest()!=h]
allowed={W,D,S,'project/ui/persona_sortie_screen.gd','project/tests/ui_expedition_r22_test.gd'}
assets=read(root/'ASSET-HASHES.json');asset_changes=[a['path'] for a in assets if hashlib.sha256((root/a['path']).read_bytes()).hexdigest()!=a['sha256']]
traces=[]
trace_tests=['combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
for file,test in zip(['p2-full-battles.json','a6-mixed-audit.json','p3-mixed-audit.json','a7-gear-audit.json','a7-gear-balanced-audit.json','a8-audit.json','a9-native-10-audit.json','a9-native-40-audit.json'],trace_tests):
    p=root/'verification/data-r21'/file
    if p.exists():
        if test=='combat_a8_audit' and composed:p=out/'a8-composed.json'
        t=read(p);traces.append({'file':str(p.relative_to(root)).replace('\\','/'),'fresh_test':test,'fresh_passed':bool(reg.get(test,{}).get('passed')),'battles':t.get('battles',0),'equal':t.get('equal_battles',sum(not r.get('mismatches') and r.get('source_result')=={'victory':'win','defeat':'lose'}.get(r.get('godot_result'),'') for r in t.get('reports',[]))),'records':t.get('matched_actions',0)})
summary={'reviewed_rows':len(rows),'promoted_same':sum(r['status']=='같음' for r in rows),'fixed_rows':len(fixed),'fixed_still_remaining':sum(r['fixed'] and r['status']!='같음' for r in rows),'remaining_rows':sum(r['status']!='같음' for r in rows),'oracle_checks':results['checks']+supply_results['checks']+level_results['checks'],'core_oracle_checks':results['checks'],'supply_oracle_checks':supply_results['checks'],'level_oracle_checks':level_results['checks'],'oracle_failures':len(results['failures'])+len(supply_results['failures'])+len(level_results['failures']),'regression_groups':len(reg),'failed_groups':[r['test'] for r in reg.values() if not r['passed']],'protected_snapshot_files':len(before),'changed_existing_files':changed,'outside_allowed_changed':[p for p in changed if p not in allowed],'assets_checked':len(assets),'asset_changes':asset_changes}
if len(traces)==8 and all(t['fresh_passed'] for t in traces):summary.update(trace_battles=sum(t['battles'] for t in traces),trace_equal_battles=sum(t['equal'] for t in traces),trace_records=sum(t['records'] for t in traces))
document={'task':'r23-expe','basis':'r21-expe-brief.md / r21-common.md; 109 items from audit-r22b.json remaining_work[7]','summary':summary,'rows':rows,'checks':list(reg.values()),'trace_reports':traces,'limits':['Some pure native functions use a normalized ID/slot ABI; claims are limited to the stated valid state projection.','First-battle initialization oracle suppresses B.run only to observe setup before automatic enemy actions.','No source bot, protected combat files, gear/facility rules, server, docs or Web export writes. Only the explicitly allowed supply adapter changed. No commits.']}
(out/'expe.json').write_text(json.dumps(document,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(out/'expe-checks.json').write_text(json.dumps(list(reg.values()),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
ui=read(root/'verification/expedition-r22/ui-results.json') if (root/'verification/expedition-r22/ui-results.json').exists() else {}
trace_line=(f"**{summary['trace_equal_battles']:,}/{summary['trace_battles']:,}판 · {summary['trace_records']:,}기록 일치**" if 'trace_battles' in summary else '아직 전체 fresh trace 검사가 끝나지 않았다. 기존 결과를 이번 통과로 세지 않는다.')
report=f'''# R23-expe — 탐색·원정·출정·정산

`r21-expe-brief.md`와 `r21-common.md`를 UTF-8로 읽고 `r21-cloud` 안에서 작업했다. 기준 원장은 `r21-parity/verification/parity-r21/audit-r22b.json`의 탐색·원정 묶음 109행이다. 행별 원본 위치·이전 판정 이유·새 시험·구현 줄·남은 이유는 [expe.json](verification/parity-r23/expe.json)에 있다.

## 처리 수치

|구분|수치|
|---|---:|
|검토한 행|{summary['reviewed_rows']}|
|새로 같음으로 올린 행|{summary['promoted_same']}|
|수정한 행|{summary['fixed_rows']}|
|남은 행|{summary['remaining_rows']}|
|새 원본 대조 단언|{summary['oracle_checks']:,}|
|새 원본 대조 실패|{summary['oracle_failures']}|
|이번 실행 검사 그룹|{summary['regression_groups']}|
|최종 실패 그룹|{len(summary['failed_groups'])}|
|원본 자산 해시|{summary['assets_checked']}개 / 변경 {len(summary['asset_changes'])}|
|허용 파일 밖 기존 파일 변경|{len(summary['outside_allowed_changed'])}|

수정 수는 같음/남음과 겹친다. 수정한 행 중 {summary['fixed_still_remaining']}행은 함수 전체 계약이 아직 같지 않아 일부로 남겼다. **109행 전체가 완성됐다는 보고가 아니다.** 함수 분기 진입률이나 봇 전체 완성도로 이 수치를 확대하지 않는다.

같음 행: {', '.join(same)}.

전투 대조: {trace_line}.

A8는 실행 제어기의 600초 제한 이후에도 native 자식이 계속 진행해, 안정적으로 보존한 불일치 0 체크포인트 {composed['prefix']['battles'] if composed else '미완료'}판과 같은 원본 입력/같은 비교 코드의 나머지 {composed['suffix']['battles'] if composed else '미완료'}판을 중복 없이 합쳤다. `a8-composed.json`에 범위·원본 입력 SHA·비교 코드 SHA·접두 로그·실제 뒷부분 보고서를 남겼다. 접두의 개별 실제 벡터를 원본에서 만들어 넣지 않았다. native 자식은 최종적으로 전체 5,120판·186,707기록 보고서도 완성했으며 그 원본 파일 SHA도 함께 보존했다. 별도 suffix 재실행 exit는 0이고, 원래 실행 제어기의 timeout 기록은 지우지 않았다. 전투 수·길이·각 필드·최종 결과 비교는 원래 audit와 같다.

## 고친 동작

- 원본 `ex_new`처럼 입장 때 HP/MP는 직업·동료의 기본 성장치로 만든다. 종족·개인 배분·장비·편성 보정은 첫 전투가 구성될 때 반영한다. 첫 전투에는 아직 이전 전투 carry가 없으므로 입장 표시 자원을 carry로 잘못 사용하지 않는다. 기존 진행 중 원정에 새 버전 필드를 강제로 붙이지 않았다.
- 원본 `lv_of`/`exp_of` 읽기를 원정에 연결했다. 영입 여부·페르소나/미영입/알 수 없는 인물·누락된 옛 레벨·숫자 문자열·음수/소수·40 상한을 원본 {level_results['oracle_rows']}입력, {level_results['checks']:,}단언으로 대조했다. 큰 레벨 값은 정수 변환 전에 상한 처리해 넘침을 막는다. 읽기만으로 옛 저장의 필드를 고치지 않는다.
- 퇴각 확인 중에도 보스 도전 입력을 받으면 원본처럼 도전을 시작하고 `ask`를 지운다.
- 옛 `potion`/`mana`를 `hp_s`/`mp_s`에 **합산**한다. 거점과 원정 주머니를 모두 처리하고 숫자 문자열도 받아들인다. 입력 사본에서 처리하므로 실패 시 원본 저장과 현재 상태가 바뀌지 않는다. 반복 불러오기/JSON 왕복에서 두 번 더하지 않는다. 음수·소수·손상 값은 기존 native 유효 저장 조건에 맞춰 거부한다.
- 출정 필터가 `front`/`back` 이외이면 원본처럼 전체 목록으로 되돌린다. 선택 여부 → 레벨 내림차순 → 원본 인물 순서 정렬을 90편성/필터 표본으로 고정했다.
- 출정 위험 경고를 계산하고 화면에 연결했다. 전열 없음과 적 레벨−파티 평균 레벨 ≥5를 경고하며 출발을 막지 않는다. 경계 차이 4/5/6과 의뢰 없음도 대조했다.
- 선택한 층이 현재 목록 쪽에 없을 때 첫 번째 층을 선택한 것처럼 표시하던 오류를 고쳤다. 28층을 선택한 채 1쪽을 보는 경우를 5크기에서 먼저 실패로 확인했고, 다른 쪽의 현재 선택임을 표시한다.
- 원본 전투 아이템의 필요 레벨·상태·대상 가능 여부·누군가 사용 가능한가·레벨 때문에 막혔는가를 재고 조건과 분리했다. 효과 0인 여우불만 남았는데도 해독약과 차례를 소비하던 차이를 고쳤으며 알 수 없는 아이템은 오류 없이 거부한다. 원본 전투 엔진을 수정하지 않고 명시적으로 허용된 `expedition_supply_r22.gd`에서 처리했다.
- 전투 뒤 HP/MP·최대치 내림, 생존 소수 HP의 최소 1, 사망자의 복귀 비율을 원본 `snapshot_party`와 맞췄다. 로그 8줄 제한·장비 추가 순서/중복·장비 드롭의 소수 씨앗 내림·양수 아이템 정렬 입금을 작은 실제 사용 함수로 분리해 직접 대조했다.

## 원본 실행과 검사

`tools/expe_r23_oracle.mjs`는 원본 `lua_sim.mjs`/Wasmoon에서 현재 Lua를 다시 실행한다. 원본 파일을 수정하지 않고 로드한 청크 안에서 local 함수 참조만 노출한다. 첫 전투 자원 표본은 `B.run`만 잠깐 막아 초기화 직후와 적의 자동 행동 뒤를 섞지 않았다. 공격/피해 결과를 이 초기화 표본으로 검증했다고 주장하지 않는다. 원본 SHA와 표본 수는 `expe-provenance.json`에 있다.

새 단언은 출정 정렬·경고, 층 진입/정보, 1~4인·Lv1/15/40·인간/엘프 초기 자원, 첫 전투 초기화, 아이템 792조건, 보스 입력, 로그, 이월, 장비 240조건, 입금, 합산 재고, 실제 탐색 이벤트, 옛 별칭 이관과 무효 입력을 포함한다. 핵심 원정 {results['checks']:,}단언 + 보급품 판정 {supply_results['checks']:,}단언 + 레벨/경험치 읽기 {level_results['checks']:,}단언 = **{summary['oracle_checks']:,}단언**이다. 보급품은 1,440 단일 대상 표본과 0~4인 혼합 표본 165건, 필요 레벨 12건을 실제 Lua로 만들었다. 재고 없음에도 상태만으로 사용 가능할 수 있는 원본 함수 계약, 레벨 14/15·29/30, 사망·빈 칸·MP 0·보호막·DOT/적 DOT·여우불 0, 무효 아이템, 검사 부작용 없음까지 확인했다. 기존 원정 검사는 4,786단언 실패 0으로 재통과했다. 기대값을 게임 구현에 맞춰 낮추지 않았다.

초기 실패는 `expe-before-fix-results.json`(4건), `expe-initial-before-results.json`, `expe-sortie-before-results.json`(필터 36/누락 경고 90), `expe-supply-before-results.json`(0 여우불 6조건 및 누락 판정 API), `expe-supply-invalid-before.log`(무효 아이템 접근 오류), `expe-picker-before.json`(5크기 표시 오류)에 보존했다. 개발 중 첫 전투의 자동 적 행동과 초기화를 섞은 표본, Lua의 `and nil or ...`로 의뢰 없음이 잘못 생성된 표본은 하네스 입력/관찰 시점을 고쳐 다시 실행했다. 이 두 하네스 오류를 게임 수정 건수로 세지 않는다.

전체 결과는 `expe-checks.json`과 각 로그에 있다. 최초 대사 검사는 180초 제한으로 끝났으나 제한을 늘려 **34,229단언 실패 0**으로 재통과했다. 클라우드는 고정 8787의 기존 서비스/표본과 섞인 첫 실행에서 보관 표본 및 전투 D1 요청이 실패했다. `serve.mjs` 시작도 해당 환경에서 실패했다. 서버 코드는 고치지 않고 동일 `runtime.mjs`를 쓰는 기존 `godot-r14.mjs` 하네스로 격리된 실제 Worker/D1을 띄워 cloud 27/27, 보관 계정 5/5, 전투 저장 576/576으로 재통과했다. 가짜 서버나 서버 단언 완화로 대체하지 않았다. 최종 집계는 이 재실행을 표시하며 첫 실패 로그도 남겼다. Windows root certificate store 진단은 별도 환경 메시지로 유지하고 GDScript/검사 실패와 구분했다.

## 화면과 변경 파일

원정 UI 자동 검사: {ui.get('checks','진행 중')}단언 / 실패 {len(ui.get('failures',[]))} / 캡처 {len(ui.get('captures',[]))}장. 360×780, 390×844, 390×664, 430×932, 1280×800에서 기존 원정 입력과 새 위험 경고를 검사한다. 실제 열어 본 최종 이미지는 아래 최종 검수 메모에 별도로 적는다. 캡처 수를 직접 눈으로 확인한 수와 혼동하지 않는다.

기존 파일 변경:

{chr(10).join('- `'+p+'`' for p in changed)}

추가 도구/검사: `tools/expe_r23_oracle.mjs`, `tools/expe_r23_verify.py`, `tools/expe_r23_report.py`, `tools/expe_r23_resume_a8.py`, `project/tests/expe_r23_test.gd`, `project/tests/expe_supply_r23_test.gd`, `project/tests/expe_level_r23_test.gd`, `project/tests/combat_a8_r23_tail.gd`. 근거 폴더: `verification/parity-r23/`.

## 남은 이유와 경계

{summary['remaining_rows']}행은 원장의 행별 이유를 따라 남겼다. 주요 경계는 마을 14함수·레벨 지급 3함수가 허용 파일 밖인 점, 원본 HTML/호스트 메시지와 native 캔버스 반환이 다른 점, 원본 장비 코드/가방과 native UID/overflow 보존 계약, 전체 전투 아이템 메뉴·ev/T/pend 저장 재개 계약, 원본 `st.dn.stage` 옛 저장의 직접 이관이다. 원정 정산 숫자나 화면 통과를 이 함수들의 전체 같음 근거로 전파하지 않았다. 특히 `SO.summary`는 해석된 적 레벨의 경고 값이 맞아도 의뢰 q 전체 해석까지 같은 것으로 승격하지 않았다.

성적/친밀 장면 코드는 옮기지 않았다. 원본 봇, 보호된 전투 파일, 장비/시설 규칙, 서버, `docs/`는 수정하지 않았고 Web export도 하지 않았다. 허용 목록의 보급품 어댑터만 전투 아이템 판정을 보강했다. 허용 파일 밖 변경 검사는 최초 기록한 기존 파일 1,007개 및 자산 96개를 대상으로 한다. 기존 데이터 파일은 oracle 재생성 중 순서만 달라졌으나 값 동일성과 최초 SHA를 확인한 사본으로 원래 바이트를 복원했다. 첫 규칙 읽기와 병행해 `git status`가 1회 시도되어 소유권 오류로 종료됐다. 이후 git 명령·설정·커밋은 실행하지 않았다.
'''
review=out/'expe-visual-review.txt'
if review.exists():report+='\n## 최종 검수 메모\n\n'+review.read_text(encoding='utf-8')+'\n'
(root/'R23-expe.md').write_text(report,encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False))
