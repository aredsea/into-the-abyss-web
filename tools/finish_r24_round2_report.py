"""Report only measured results. The server allowlist stop remains explicit."""
from pathlib import Path
from collections import Counter
import hashlib,json,re
R=Path(__file__).resolve().parents[1]
O=R/'verification/finish-r24/round2'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
done={'같음','대체','제외'}
extras={'export_licenses','motion_r9_integration','motion_r18_integration','balance_probe','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
focused=read(O/'focused-results.json') if (O/'focused-results.json').exists() else []
tests={x['test']:x for x in read(O/'regression.json')+read(O/'cloud/results.json')+focused}
write(O/'recheck-history.json',{'initial_failures':[x for x in read(O/'regression.json') if not x['passed']],'rechecked':focused})
assert expected<=tests.keys(),sorted(expected-tests.keys())
assert all(tests[n]['passed'] for n in expected),[n for n in expected if not tests[n]['passed']]
write(O/'all-tests.json',{'expected':len(expected),'passed':len(expected),'failures':0,'tests':[tests[n] for n in sorted(expected)]})
unit=read(O/'unit-results.json');ui=read(O/'ui-results.json')
assert not unit['failures'] and not ui['failures']
assert unit['counts']['P3195.bank.full']==24 and unit['counts']['P3020.fight.view']==36
block=read(O/'server-boundary.json');assert block['blocked'] and not block['native_resume']['equal']
scan=read(R/'verification/finish-r24/locale-scan.json')
assert not scan['defects'] and not scan['unsupported_data_macros']
authored=read(R/'verification/finish-r24/authored-language-audit.json')
review=read(O/'visual-review.json');assert review['viewed'] and review['captures']==12
assert all(sha(R/f['path'])==f['sha256'] for f in review['files']),'Reviewed capture changed; open it again'
battles=records=0
for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
    d=read(R/f'verification/data-r21/{name}.json')
    assert d['battles']==d['equal_battles'] and d['source_actions']==d['actual_actions']==d['matched_actions']
    battles+=d['battles'];records+=d['source_actions']
d=read(R/'verification/data-r21/p2-full-battles.json');assert d['different_actions']==0
battles+=d['battles'];records+=d['compared_actions'];assert (battles,records)==(6320,219785)
write(O/'battle-regression.json',{'battles':battles,'equal_battles':battles,'records':records,'differences':0})
before=read(O/'baseline.json')
changed=[name for name,h in before.items() if not (R/name).exists() or sha(R/name)!=h]
protected=[n for n in changed if n.startswith(('server/','docs/','project/assets/','project/data/dialogue-r21/')) or n in ['project/game/localization_r22.gd','project/ui/resource_gauge_r24.gd']]
assert not protected,protected
for folder in ['server','docs','project/assets','project/data/dialogue-r21']:
    added=[p.as_posix() for p in (R/folder).rglob('*') if p.is_file() and not any(s in p.parts for s in ['.godot','node_modules','__pycache__']) and p.relative_to(R).as_posix() not in before]
    assert not added,added
images=read(R/'ASSET-HASHES.json');assert len(images)==96 and all(sha(R/a['path'])==a['sha256'] for a in images)
write(O/'boundaries.json',{'changed_existing':changed,'protected_changes':protected,'original_images':96,'image_changes':0,'server_changes':0,'dialogue_changes':0,'english_display_changes':0,'resource_gauge_changes':0,'docs_changes':0,'git_commands':False,'web_export':False})
item_tests=read(R/'verification/parity-r23/battle-round9-items-latest.json')
handler_tests=read(R/'verification/parity-r23/battle-round9-handlers-latest.json')
assert not item_tests['failures'] and not handler_tests['failures']
for pack in ['items','handlers']:
    provenance=read(R/f'verification/parity-r23/battle-round9-{pack}-oracle.json')['provenance']
    assert all(sha(Path('C:/Clauede Code/dungeon-bot/bot/src')/n)==provenance[n] for n in ['78-battle-item.lua','71-shop.lua'])
battle_ledger=read(O/'battle-before.json');battle_rows={r['id']:r for r in battle_ledger['rows']}
promotions={
 'P3195':{'tests':['finish_round2_r24_test'],'results':['verification/finish-r24/round2/unit-results.json'],'detail':'원본 ex_gear_bank를 실행한 24개 입력에서 성공 코드 배열·버림 수·재조회 가방 수와 저장 재개를 직접 비교. 0/1999/2000/2001칸, 구문 유효 미등록 코드, 무효 코드·버전·타입, seed 0·선행 0, 혼합 입고를 포함한다. 새 unknown id는 원본의 다음 bag_load처럼 걸러지고 기존 넘친 장비는 보존한다.'},
 'P3020':{'tests':['finish_round2_r24_test','ui_finish_round2_r24_test'],'results':['verification/finish-r24/round2/unit-results.json','verification/finish-r24/round2/ui-results.json'],'detail':'원본 fight_row 한영·3직업(빈 직업 포함)·두 참전 모드·3편성의 36개 입력을 문구·버튼 순서·활성·선택으로 직접 대조. 실제 화면에서도 직업 없는 옛 저장의 버튼을 누르고 참전 상태 변경을 검사했다. 출발 handler 행의 판정은 전파하지 않는다.'}}
for rid in ['P3331','P3332','P3337','P3338','P3340','P3344']:
    assert battle_rows[rid]['status']=='같음'
    test='battle_r23_round9_handlers_test' if rid=='P3344' else 'battle_r23_round9_items_test'
    result='battle-round9-handlers-latest.json' if rid=='P3344' else 'battle-round9-items-latest.json'
    promotions[rid]={'tests':[test],'results':['verification/parity-r23/'+result], 'detail':'전투 표와 정확히 같은 원본 함수 행. 기존 통합된 직접 대조 시험을 이번 전체 검사에서 재실행해 일치를 확인했다. 전투 수정 금지가 해제되어 expe 표의 이관 표기를 해소한다. 다른 전투 함수의 판정은 전파하지 않는다.','battle_evidence':battle_rows[rid].get('new_evidence',[])}
audit=[];counts=[]
for name in ['expe','gear','ui','battle']:
    p=R/f'verification/parity-r23/{name}.json';d=read(p);old=read(O/(name+'-before.json'))
    previous={r['id']:r for r in old['rows']};key='new_status' if name=='gear' else 'status'
    unresolved=[r for r in old['rows'] if r[key] not in done]
    for row in d['rows']:
        rid=row['id'];prior=previous[rid]
        if prior[key] in done:continue
        src=row['source'];path=Path('C:/Clauede Code/dungeon-bot')/src['file']
        excerpt='\n'.join(path.read_text(encoding='utf-8').splitlines()[src['start']-1:src['end']])
        evidence={'stage':'finish round2','previous_status':prior[key],'previous_remaining_reason':prior.get('remaining_reason'),'source_sha256':sha(path),'source_excerpt_sha256':hashlib.sha256(excerpt.encode()).hexdigest()}
        if rid in promotions:
            row[key]='같음';row['remaining_reason']='';row['fixed']=rid in ['P3195','P3020']
            evidence.update({'disposition':'같음 승격','modified':rid in ['P3195','P3020'],**promotions[rid]})
        else:
            evidence.update({'disposition':'중단·남음','detail':'전투 파일 수정은 허용되었다. 서버 허용 목록 변경이 필요한 저장 재개 결함을 재현하여 지시서의 중단 조건을 적용했다. 기존 실제 차이/미검증 근거는 previous_remaining_reason에 보존하며 같음으로 승격하지 않는다.'})
            if rid in ['P1594','P1595','P1825']:
                row['remaining_reason']='저장 재개에서 심연 고갈 횟수와 마지막 일격 이름이 사라진다. 보존 필드는 현재 서버 battle 허용 목록에서 거절된다. server/ 수정 금지 및 허용 목록 변경 필요 시 중단 지시에 따라 미수정. 재현: verification/finish-r24/round2/server-boundary.json.'
                evidence['results']=['verification/finish-r24/round2/resume-probe.json','verification/finish-r24/round2/server-boundary.json']
        row.setdefault('finish',{})['round2']=evidence
        audit.append({'ledger':name,'id':rid,'status':row[key],**evidence})
    statuses=Counter(r[key] for r in d['rows'])
    c={'ledger':name,'initial_remaining':len(unresolved),'promoted_same':sum(r['id'] in promotions for r in unresolved),'modified':sum(r['id'] in ['P3195','P3020'] for r in unresolved),'remaining':sum(n for s,n in statuses.items() if s not in done),'statuses':dict(statuses)}
    d.setdefault('finish',{})['round2']={**c,'stopped_for_server_allowlist':True,'evidence':'verification/finish-r24/round2/row-audit.json'}
    if 'summary'in d:d['summary'].setdefault('finish',{})['round2']=c
    write(p,d);counts.append(c)
assert sum(c['initial_remaining'] for c in counts)==88
assert sum(c['promoted_same'] for c in counts)==8
write(O/'row-audit.json',{'counts':counts,'rows':audit,'stopped_for_server_allowlist':True})
report=R/'FINISH-R24.md';first=O/'first-pass-report.md'
if not first.exists():first.write_text(report.read_text(encoding='utf-8'),encoding='utf-8')
lines=['# FINISH-R24 · 2차','',
'**서버 허용 목록 변경이 필요한 결함을 재현하여 지시서대로 중단했다. 전체 기능 등가 완료가 아니다.** 전투 저장 재개에서 `depletions=3 → 0`, `last_kill=테이리스 → 빈 문자열`로 바뀐다. 기존 저장은 서버 검증을 통과하지만 두 필드를 추가한 저장은 각각 거절된다. 서버나 허용 목록은 수정하지 않았다. [재현 결과](verification/finish-r24/round2/server-boundary.json).',
'',f'전체 프로젝트 **{len(expected)}/{len(expected)}그룹 통과·실패 0**, 로컬 D1 클라우드 9그룹 포함. 원본 전투 **6,320/6,320판·219,785기록 일치**. 신규 직접 대조 **{unit["checks"]}개**, 신규 화면 검사 **{ui["checks"]}개** 통과. 일반 화면 언어·자리표시자 결함 **0건**. 보호 대상 고정 대사 영어 미지원 **{authored["untranslated"]:,}개**는 별도 집계하며 전체 언어 0건으로 보고하지 않는다.',
'','이번 지시의 시작 잔여는 expe 31 + gear 14 + ui 27 = 72행, battle 16행으로 총 88행이다. **같음 승격 8행(규칙 수정 2행 포함), 남음 80행**이다. 기존 1차 8행 승격과 중복 집계하지 않았다.','',
'| 대조표 | 시작 잔여 | 같음 승격 | 규칙 수정 | 남음 |','|---|---:|---:|---:|---:|']
for c in counts:lines.append(f'| {c["ledger"]} | {c["initial_remaining"]} | {c["promoted_same"]} | {c["modified"]} | {c["remaining"]} |')
lines+=['','수정과 승격:',
'','- P3195: 미등록 코드도 구문이 유효하면 원본처럼 입고 성공으로 응답한다. 다음 가방 읽기에서 원본처럼 제외하며 사용 가능한 새 장비를 만들지 않는다. 중간 facade가 이 규칙을 다시 거절하던 경로도 연결했다. 만석 신규 버림, 옛 초과 장비 보존, 제련 상태 복원은 유지한다.',
'- P3020: 직업이 빈 옛 저장에서도 참전 선택 버튼을 활성화하고 참전 상태를 바꾼다. 이 저장에서 참전 선택 뒤 실제 출발은 기존 직업 유효성 검사에 막힌다(지휘로 되돌리면 출발 가능). 원본의 기본 전사 전투 입력까지 잇는 출발 handler는 P3041/P1620의 미완료 범위로 남기며, 버튼 행의 판정을 전파하지 않는다.',
'- P3331/P3332/P3337/P3338/P3340/P3344: 통합 전투 표에 이미 있는 동일 함수의 직접 비교 결과를 재실행하고 expe의 중복 이관 상태를 해소했다.',
'','기존 신고 두 화면은 다시 촬영·확인했다. 연대기의 옛 영어 기록은 삭제하지 않고 설정 언어에 맞춰 표시한다. 레벨업 스크롤의 페르소나 자리표시자도 표시 때 치환한다. `390×844`, `1280×800`에서 한영·옛 저장 참전 화면을 포함한 after 12장을 직접 열어 보았다. [시각 검토](verification/finish-r24/round2/visual-review.json).',
'',f'언어 스캔은 메뉴/패널 {scan["screen_language_states"]}상태·{scan["rendered_strings"]:,}문자열과 데이터 {scan["data_files"]}파일·{scan["data_strings"]:,}문자열을 검사했다. 스캔 종료값은 보호된 영어 대사 미지원 때문에 1이며 숨기지 않았다. `project/data/dialogue-r21/*.json`, 영어 대사 표시 함수, `resource_gauge_r24.gd`, 승인 외형·원본 이미지 **96/96**, `server/`, `docs/`를 보존했다. git 명령·Web export·새 그림 없음.',
'','클라우드 실행기는 그룹별로 별도 실제 로컬 서버/D1을 시작한다. 하나의 서버를 공유하며 계정 생성에 실패했던 2그룹은 새 서버에서 원래 검사 그대로 통과했고 전체 9그룹도 격리 실행으로 재확인했다. 제품의 제한이나 검증 조건을 낮추지 않았다. Windows root certificate store 메시지는 기존 환경 진단으로 분리하고 나머지 ERROR/Script error는 실패로 센다. 기존 ui_persona_town_round8_test의 참전 버튼 비활성과 persona_town_r21_round8_test의 참전 거절 기대는 원본 fight_row/H.so의 허용 기대에 맞췄다. 선택 뒤에는 별도 원래 저장을 다시 읽어 지휘 출발·경험치·중복 정산 검사를 모두 유지했다. 새 36개 원본 대조 및 실제 포인터 클릭 시험도 추가했다. 초기 실패와 재검사는 recheck-history.json에 남긴다. 전투 수치 기대값은 바꾸지 않았다.',
'','다음 작업은 `battle_v3.gd` 저장/재개에 마지막 일격과 심연 고갈 횟수의 명시적 필드를 넣고, 서버 battle 검증 허용 목록·범위·옛 저장 기본값을 함께 이관하는 것이다. 이 서버 변경이 현재 금지되어 중단했다. 남은 80행의 이전 차이/미검증 이유는 아래와 각 표의 `finish.round2.previous_remaining_reason`에 보존했다. 다른 남은 행을 이 저장 결함만 고치면 자동 완료된다고 주장하지 않는다.',
'','검증: [전체 검사](verification/finish-r24/round2/all-tests.json) · [직접 대조](verification/finish-r24/round2/unit-results.json) · [원본 실행](verification/finish-r24/round2/oracle.json) · [전투 회귀](verification/finish-r24/round2/battle-regression.json) · [언어 스캔](verification/finish-r24/locale-scan.json) · [보호 경계](verification/finish-r24/round2/boundaries.json) · [행별 기록](verification/finish-r24/round2/row-audit.json) · [1차 보고 보존](verification/finish-r24/round2/first-pass-report.md).',
'','재실행: `node tools/finish_r24_round2_oracle.mjs` 후 PowerShell에서 `$env:R24_FINISH_OUTPUT="verification/finish-r24/round2"; python tools/finish_r24_verify.py` 및 `python tools/finish_r24_verify.py --cloud`. 진단은 `python tools/godot_r17.py --headless --script res://tests/finish_resume_r24_probe.gd` → `node tools/finish_r24_resume_boundary.mjs`. 보호 대사 감사와 스캔은 1차와 같은 도구를 사용하고, 보고서는 `python tools/finish_r24_round2_report.py`로 쓴다.',
'','시각 검토 제한: 영어 출정 상단의 긴 제목과 회복 안내는 기존 그림 영역에 빽빽하게 붙는다. 이번에는 승인 외형을 바꾸지 않았다. 디자인 스킬 context가 DESIGN.md와 .impeccable/design.json의 동기화 필요를 보고했다. 작업 범위 밖의 메타데이터는 수정하지 않았으며 `document`로 갱신할 수 있다.',
'','이번 변경 파일:','']+['- '+n for n in changed]
lines+=['','추가 시험·도구:','','- project/tests/finish_round2_r24_test.gd','- project/tests/ui_finish_round2_r24_test.gd','- project/tests/finish_resume_r24_probe.gd','- tools/finish_r24_round2_oracle.mjs','- tools/finish_r24_resume_boundary.mjs','- tools/finish_r24_round2_report.py','','남은 행과 이전 이유:','']
for a in audit:
    if a['id'] not in promotions:lines.append('- '+a['ledger']+' '+a['id']+' · '+(a['previous_remaining_reason'] or '원본 기능 전체 직접 대조 미완료'))
report.write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({'report':str(report),'tests':len(expected),'failed':0,'promoted':8,'modified':2,'remaining':80,'blocked':'server allowlist','authored_untranslated':authored['untranslated']},ensure_ascii=False))
