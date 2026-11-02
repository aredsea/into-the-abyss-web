"""Append conservative phase-2 evidence without reclassifying phase-1 successes."""
from pathlib import Path
from collections import Counter
import json,hashlib,subprocess,sys
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/parity-r23';P2=OUT/'phase2'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def loc(file,needle):
    for n,line in enumerate((ROOT/file).read_text(encoding='utf-8').splitlines(),1):
        if needle in line:return f'{file}:{n}'
    raise ValueError((file,needle))
base=read(P2/'ui-before.json');result=read(P2/'results.json');native=read(P2/'native-results.json');cloud=read(P2/'cloud-results.json');oracle=read(P2/'oracle.json')
prior_evidence={r['id']:len(r['new_evidence']) for r in base['rows']}
assert not result['failures'] and not native['failures'] and not cloud['failures']
assert read(P2/'dependencies.json')['shipped_values_equal']
life=read(OUT/'server-lifecycle.json');assert life['ready'] and life['clean_shutdown'] and not life['forced_shutdown']
assert read(ROOT/'project/data/persona-text-r23.json')==oracle['public_dictionary']['values']
assert read(ROOT/'project/data/cloud-recap-r23.json')==oracle['recap_dictionary']
spec={
 'P0089':('project/game/localization_r22.gd','static func ui_pack','P0089.ui_pack','오류 JSON·원시값·배열·미지정 언어·원문 교체 후 캐시 유지'),
 'P0090':('project/game/localization_r22.gd','static func u','P0090.P0091.u','null 인수, 알 수 없는 언어, false/빈 번역·치환·조사 경계'),
 'P0091':('project/game/localization_r22.gd','for m in re.search_all(tpl)','P0090.P0091.u','반복·중첩·미지정·숫자 이름 토큰과 조사 callback'),
 'P0092':('project/game/localization_r22.gd','static func en_dict','P0092.en_dict','사전 JSON 오류·스칼라 fallback 및 재호출 캐시'),
 'P0095':('project/game/localization_r22.gd','static func t','P0095.t','문자열만 번역하고 숫자·논리값은 타입 유지'),
 'P0102':('project/game/panels_rules_r22.gd','static func escape','P0102.esc','nil/false와 숫자·유니코드·HTML 특수 문자 escaping'),
 'P0110':('project/game/panels_rules_r22.gd','static func hud_action','P0110.hd','close/동일 패널 토글/알 수 없는 패널과 선택 보존·초기화'),
 'P2415':('project/game/persona_rules.gd','func syn_text','P2415.syn_text','종족·계통·국가 시너지 raw 수치 치환·언어·누락 fallback'),
 'P2446':('project/game/persona_rules.gd','func create_action','P2446.create','지수·소수 프리셋/이동, 소수 페이지 보존, 영어 원문 알림'),
 'P2539':('project/game/panels_rules_r22.gd','static func cx_action','P2539.cx','즐겨찾기 중복·상한과 언어별 알림; 기존 un/eq 규칙 보존'),
 'P2572':('project/game/panels_rules_r22.gd','static func member_name','P2572.mname','전 동료·미지정 이름·호스트 토큰·특수 문자 이름과 언어'),
 'P2611':('project/game/panels_rules_r22.gd','static func status_action','P2611.st','전투 중 가방 거부, 상태 탭과 무효 버튼'),
 'P2721':('project/game/cloud_recap_r23.gd','static func recap','P2721.P2722.P2723.recap','원본 여관 회상 지시문 생성·저장 복원 후 native 사실 투영'),
 'P2722':('project/game/cloud_recap_r23.gd','static func score','P2721.P2722.P2723.recap','레벨·출전·경험치 가중 합, 동점과 경험치 역전 경계'),
 'P2723':('project/game/cloud_recap_r23.gd','static func name','P2721.P2722.P2723.recap','전 동료 이름과 알 수 없는/비문자 id의 원본 AI 이름 변환'),
 'P3731':('project/game/town_places_r22.gd','static func label','P3731.place_label','원정 표시 위임 유무·층 0/음수/문자/빈 값; 원정 규칙 미수정')}
promoted=set('P0102 P0110 P2415 P2446 P2572 P2611 P2721 P2722 P2723 P3731'.split())
locale=set('P0089 P0090 P0091 P0092 P0095'.split())
fixed=set(spec)|{'P2586'}
# Relocate historical anchors after inserting helpers; do not redo classifications.
anchors={}
for ids,file,needle in [
 ('P0103','project/game/panels_rules_r22.gd','static func recruited'),
 ('P2390 P2391','project/game/persona_rules.gd','func scenarios'),
 ('P2392','project/game/persona_rules.gd','func view'),
 ('P2394','project/game/persona_rules.gd','func prepare'),
 ('P2503 P2504','project/game/panels_state_r22.gd','func candidates'),
 ('P2582 P2583','project/game/panels_state_r22.gd','func members'),
 ('P2593','project/game/panels_state_r22.gd','func bg_action')]:
    for id in ids.split():anchors[id]=loc(file,needle)
for id,fn in [('P2484','level'),('P2487','shown_aff'),('P2493','num'),('P2495','first'),('P2505','slot_ok'),('P2507','fnum'),('P2571','normalize_bg'),('P2573','member_class')]:anchors[id]=loc('project/game/panels_rules_r22.gd','static func '+fn+'(')
for r in base['rows']:
    if r['id'] in anchors:
        for e in r['new_evidence']:
            if e.get('implementation'):
                e['phase1_implementation']=e['implementation'];e['implementation']=anchors[r['id']]
        if r.get('modified'):
            r['phase1_modified']=r['modified'].copy();r['modified']['file']=anchors[r['id']]
review=[]
for r in base['rows']:
    if r['status']=='같음':continue
    id=r['id'];old=r['status'];entry=spec.get(id)
    r['phase2_previous_status']=old
    r['source_calls_phase2']=oracle['calls'].get(Path(r['source']['file']).name+':'+str(r['source']['start']),0)
    if entry:
        file,needle,group,change=entry;g=result['groups'][group];assert not g['failures']
        evidence={'test':'project/tests/ui_remaining_r23_test.gd','group':group,'checks':g['checks'],'implementation':loc(file,needle),'result':'verification/parity-r23/phase2/results.json','comparison_passed':id in promoted,'scope':change}
        r['new_evidence'].append(evidence)
        r['phase2_modified']={'file':loc(file,needle),'change':change}
        if r.get('modified') and not r.get('phase1_modified'):r['phase1_modified']=r['modified'].copy()
        r['modified']=r['phase2_modified']
    if id in promoted:
        assert r['source_calls_phase2']>0,(id,'source function not executed')
        r['status']='같음';r['remaining_reason']=''
    elif id in locale:
        r['remaining_reason']='원본 함수의 JSON 파싱·타입·캐시·치환 알고리즘 분기는 새 fixture와 일치한다. 제품은 승인된 공개 화면용 사전과 native 확장만 싣는다. 제외된 성적/호스트 전용 항목을 포함한 원본 전체 사전 반환·모든 키의 번역을 같음으로 승격하지 않는다.'
    elif id=='P2539':
        r['remaining_reason']='원본 312입력의 선택/필터/페이지/즐겨찾기/언어별 알림은 일치한다. 코드형 un_/eq_ 요청 전체와 native UID 장착/해제의 전체 G 반환 계약은 아직 다르다.'
    if id in {'P2415','P2446','P0110','P2611','P2572','P2586'}:
        r['new_evidence'].append({'test':'project/tests/ui_remaining_native_r23_test.gd','result':'verification/parity-r23/phase2/native-results.json','checks':native['checks'],'scope':'3개 휴대폰 크기 × 한글/영어. 실제 포인터·저장 재개; 전체 HTML/CBS 반환 비교라는 뜻은 아니다.'})
    if id=='P2586':
        r['status']='일부'
        r['phase2_modified']={'file':loc('project/ui/inventory_screen_r22.gd','func detail'),'change':'장착 대상 이름의 원본 fallback/영어·특수 문자 및 장착 문구를 실제 가방 화면에 연결'}
        r['modified']=r['phase2_modified']
        r['remaining_reason']='native 가방 상세의 실제 대상 선택·직접 장착·이름 표시·다시 불러오기를 원본 이름/문구 fixture와 연결해 일부로 확인했다. 전체 HTML/고유 효과/모든 장비 코드·보존용 overflow 경계의 동일성은 미확정.'
    if id in {'P2721','P2722','P2723'}:
        r['new_evidence'].append({'test':'project/tests/cloud_journey_r23_test.gd','result':'verification/parity-r23/phase2/cloud-results.json','checks':cloud['checks'],'scope':'정상/옛 버전 복원·파일 재개, 쓰기 실패/무효 원격값 보존. AI 호출과 pending 잠금 흐름은 P2724 잔여.'})
    if id=='P2446':
        r['new_evidence'].append({'test':'project/tests/persona_r22_test.gd','result':'verification/parity-r23/regression.json','checks':4005,'comparison_passed':True,'baseline':'verification/parity-r23/phase2/persona-numeric-baseline.log','scope':'전체 검사에서 잡힌 정수/실수 match 회귀 59건 수정 후 기존 원본 fixture 재통과; 기대값 유지.'})
    review.append({'id':id,'source':r['source'],'previous_status':old,'status':r['status'],'new_evidence':r['new_evidence'][prior_evidence[id]:],'remaining_reason':r['remaining_reason']})
assert len(review)==109 and len(promoted)==10
suite=read(OUT/'regression.json');server=read(OUT/'server/results.json')
expected=subprocess.check_output([sys.executable,'tools/ui_r23_verify.py','list'],cwd=ROOT,text=True,encoding='utf-8').splitlines()
missing=sorted(set(expected)-{r['test'] for r in suite})
assert not missing and len(suite)==len(expected) and all(r['passed'] for r in suite)
assert all(r['exit']==0 for r in server)
battles=[]
for name in ['p2-full-battles.json','a6-mixed-audit.json','p3-mixed-audit.json','a7-gear-audit.json','a7-gear-balanced-audit.json','a8-audit.json','a9-native-10-audit.json','a9-native-40-audit.json']:
    v=read(ROOT/'verification/data-r21'/name);n=v['battles'];equal=v.get('equal_battles',n if not v.get('field_differences') else 0)
    battles.append({'file':name,'battles':n,'matched':equal})
assert sum(b['battles'] for b in battles)==sum(b['matched'] for b in battles)==6320
assets=read(ROOT/'ASSET-HASHES.json');changed=[a['path'] for a in assets if hashlib.sha256((ROOT/a['path']).read_bytes()).hexdigest()!=a['sha256']]
assert not changed
remaining=Counter(r['status'] for r in base['rows'] if r['status']!='같음')
current_rules=read(OUT/'ui-results.json');current_native=read(OUT/'ui-native-results.json')
assert not current_rules['failures'] and not current_native['failures']
s=base['summary'];s.update({'promoted_same':sum(r['status']=='같음' for r in base['rows']),'fixed_rows':sum(r.get('modified') is not None for r in base['rows']),'remaining_rows':sum(remaining.values()),'remaining_counts':dict(remaining),'rule_checks':s['rule_checks']+result['checks'],'native_ui_checks':s['native_ui_checks']+native['checks'],'native_ui_captures':s['native_ui_captures']+len(native['captures']),'project_groups':len(suite),'project_failed_groups':0,'server_groups':len(server),'server_failed_groups':0,'combat_battles':6320,'combat_matched':6320,'phase2':{'reviewed_rows':109,'promoted_same':10,'fixed_rows':len(fixed),'unverified_to_partial':1,'remaining_rows':sum(remaining.values()),'rule_checks':result['checks'],'native_checks':native['checks'],'native_captures':len(native['captures']),'cloud_checks':cloud['checks']}})
s['rule_checks']=current_rules['checks']+result['checks'];s['native_ui_checks']=current_native['checks']+native['checks'];s['native_ui_captures']=len(current_native['captures'])+len(native['captures'])
s['fixed_and_promoted']=sum(bool(r.get('modified')) and r['status']=='같음' for r in base['rows']);s['fixed_remaining_partial']=sum(bool(r.get('modified')) and r['status']!='같음' for r in base['rows'])
base['method']+=' Phase 2 preserves phase-1 completed rows. JSON cache/lookup algorithms tested with supplied public inputs do not promote whole source dictionaries. Recap rows cover generation only, not AI delivery.'
write(OUT/'ui.json',base);write(OUT/'summary.json',{**s,'combat':battles});write(P2/'row-review.json',review)
write(OUT/'suite-coverage.json',{'expected':expected,'executed':[r['test'] for r in suite],'missing':missing,'failed':[],'note':'Executable tests and current audit entrypoints; fixtures/helpers/old baselines are dependencies, not separate suites.'})
report=f'''# R23-ui · 2차 이어하기

**2차: 잔여 109행 중 같음 +10행, 수정·구현 17행, 미확인→일부 1행. 잔여 {s['remaining_rows']}행.**
누적 **같음 {s['promoted_same']}/144행**, 수정·구현 {s['fixed_rows']}행(같음과 중복), 잔여 {dict(remaining)}다. 전체 기능 이식 완료로 판정하지 않았다.

행별 id·정본 위치·기존 사유·새 시험/파일:줄·잔여 이유는 `verification/parity-r23/ui.json`이다. 2차 109행 검토 결과만은 `verification/parity-r23/phase2/row-review.json`, 1차 보고서 원문은 `verification/parity-r23/phase2/report-before.md`에 보존했다. 완료된 1차 35행의 판정을 다시 수행하지 않았다.

## 2차 변경

- 생성의 `tot_1e1`, `tot_5.0`, `go_1e0`, 소수 페이지 및 영어 실패 알림을 Lua에 맞췄다. 기존 저장의 알 수 없는 필드·수치·진행 난수열은 유지한다.
- 번역 팩의 JSON 오류/스칼라/배열/미지정 언어/반복 호출 캐시, 문자열만 번역하는 경계를 추가했다. 공개 표시 문자열만 정본에서 추출했다. 전체 사전 5행은 일부를 유지했다.
- 종족·계통·국가 시너지의 원문 변수 치환을 생성 화면에 연결했다. 참조 상수도 `34-traits.lua`를 직접 실행해 현재 제품 데이터와 같음을 확인했다(`phase2/dependencies.json`). 가방의 페르소나 빈 이름·전 동료 이름·영어 장착 문구·특수 문자를 원본대로 처리했다.
- HUD 패널 전환/닫기와 상태 탭 함수를 실제 화면 전환에 연결하고 선택·탭 저장 재개를 확인했다. 기존 패널의 알 수 없는 필드를 잃는 문제는 실제 저장/재개 6개 실패를 먼저 확인한 뒤, 알려진 칸만 병합해 보존하도록 고쳤다(`phase2/save-preservation-baseline.json`).
- 원정 규칙을 건드리지 않고 장소 이름의 탐색 표시 위임을 대조했다. 함수 반환은 원정 표시 미등록/층 0/음수/문자/빈 값까지 비교했다.
- 저장 복원 뒤 여관 회상 지시문 생성 함수를 구현했다. 레벨→출전→경험치 가중 합, 동점/역전, 호감도, 원본 이름과 보스 사실을 그대로 쓴다. 정상·옛 버전 복원 시에만 메모리의 `recap_context`를 갱신하며, 쓰기 실패/무효 저장은 기존 모험·회상·CAS 커서를 보존한다. **AI 호출·채팅·pending 잠금 장면은 구현하지 않았으며 P2724 등은 잔여다.**

## 직접 실행한 최종 검사

|검사|결과|
|---|---:|
|프로젝트 전체 import·시험·현재 대조 entrypoint|{len(suite)}종 / 실패 0 / 누락 0|
|2차 원본 Lua 함수 대조|{result['checks']:,}건 / 실패 0|
|2차 native 화면·포인터·저장 재개|{native['checks']:,}건 / 실패 0 / {len(native['captures'])}캡처|
|2차 복원/쓰기 실패/회상 재개|{cloud['checks']}건 / 실패 0|
|1·2차 원본 규칙 대조 합계|{s['rule_checks']:,}건 / 실패 0|
|로컬 Worker/D1 서버 시험|{len(server)}종 / 실패 0|
|전투 trace|6,320/6,320판 일치|
|보호 원본 자산|{len(assets)}개 / 변경 0|

전체 검사는 한 번 실행하고, 발견된 생성 단계 회귀 59건을 수정해 해당 기존 4,005개 검사와 새 3,220개 대조를 다시 통과시켰다. 최초 전체 실행 이력은 `phase2/regression-full-initial.json`, 생성 회귀 원문은 `phase2/persona-numeric-baseline.log`에 보존한다. 원인은 GDScript `match`의 정수/실수 타입 구분이었으며 Lua처럼 숫자값을 비교하도록 고쳤다. 일반 클라우드 시험은 지시된 `node server/abyss-save/test/serve.mjs`를 사용했다. 만료 표본은 기존 `godot-r3.mjs` 전용 wrapper가 준비한다. Windows 인증서 저장소 진단은 기존 환경 진단으로 분리했으며 SCRIPT ERROR와 시험 실패를 숨기지 않았다. 2차 초기 불일치/미구현 검출은 `phase2/baseline.json`의 {read(P2/'baseline.json')['checks']:,}건 중 {len(read(P2/'baseline.json')['failures']):,}건이며 보존했다. 새 fixture에서 발견한 빈 Lua table의 JSON 배열 표현과 nil 반환도 최종 검사에 포함한다. 기존 시험 기대값은 바꾸지 않았다.

전체 검사 뒤 로컬 서버의 Windows `taskkill` 종료가 한 번 시간 초과했다. 검사 도구에만 stdin 종료 preload를 더해 원래 `serve.mjs`의 SIGINT/Miniflare dispose를 호출하도록 고쳤으며, 준비 여부도 새 자식 프로세스의 ready 출력으로 확인한다. 기존 서버 부모/자식은 작업 경로·명령·생성 시각을 확인해 정리했다(`phase2/runtime-cleanup.json`). 실제 클라우드 27개 검사와 복원 8개를 다시 통과했고 최종 서버는 요청한 SIGINT로 정상 종료했다(코드 130 포함). 강제 종료 없음·8787 포트 해제도 확인했다(`server-lifecycle.json`). 서버 제품 파일은 수정하지 않았다.

## 남은 것

남은 {s['remaining_rows']}행은 HTML/CBS 전체 반환, RisuAI 이미지/채팅/비동기 callback, 전체 언어 사전·설정, 전투 상태창, 원본 v1 코드 가방/장비와 native UID/schema 3의 전체 보존 계약, /s·/l·6자리 PIN과 native /v1·10자리 PIN·CAS 및 운영 순위 계약이다. 단순 Lua 실행이나 native 회귀 통과를 전체 동일성으로 승격하지 않았다. 내부 ror는 엔진 SHA 구현 위임, copy는 저장 미지정 필드 보존 정책의 차이로 없음 2행을 유지했다. 성적 장면은 제외했다. 배포·운영 HTTPS/Turnstile·물리적 두 기기 검사는 하지 않았다.

실제 화면은 360×780·390×844·430×932, 한글·영어를 검사했다. 직접 연 캡처와 관찰은 `phase2/visual-review.json`이다. 영어 모드의 일부 한국어 fallback을 포함한 전체 번역 완성도는 잔여이며, 모든 기존 회귀 캡처를 직접 검토했다는 뜻은 아니다.

전투·장비 규칙·원정 규칙·원본 프로젝트·다른 worktree·docs 쓰기, git 명령, Web export와 배포는 수행하지 않았다. 쓰기 경계는 `phase2/write-audit.json`, 1차 포함 경계는 `write-audit.json`에 있다. Impeccable 기계 검사 결과는 0건이지만 Godot의 실제 시각 검증은 캡처/포인터 시험을 근거로 한다. 디자인 보조 파일 `.impeccable/design.json`이 DESIGN.md보다 오래되었다는 기존 진단은 기록만 했다. 별도 요청 시 `document`로 갱신할 수 있다.

재현: `node tools/ui_r23_phase2_oracle.mjs` → `python tools/ui_r23_phase2_data.py` → `node tools/ui_r23_phase2_dependencies.mjs` → `python tools/ui_r23_verify.py` → `python tools/ui_r23_server_tests.py` → `python tools/ui_r23_snapshot.py` → `python tools/ui_r23_phase2_report.py`.
'''
(ROOT/'R23-ui.md').write_text(report,encoding='utf-8')
print(json.dumps(s,ensure_ascii=True,indent=2))
