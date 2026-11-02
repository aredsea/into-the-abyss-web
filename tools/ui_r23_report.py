"""Build a conservative row ledger; source calls alone never promote a row."""
from pathlib import Path
from collections import Counter
import json,hashlib,re,sys
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/parity-r23'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
audit=read(ROOT.parent/'r21-parity/verification/parity-r21/audit-r22b.json')
groups=[g for g in audit['remaining_work'] if g['feature_group'].startswith(('계정','클라우드'))]
prior={r['id']:r for r in audit['rows']};items=[i for g in groups for i in g['items']]
write(OUT/'ui-worklist.json',{'baseline_commit':audit['commit'],'groups':groups,'prior_reasons':{i['id']:prior[i['id']]['evidence']['reason'] for i in items}})
calls=read(OUT/'source-calls.json');rules=read(OUT/'ui-results.json')
def location(file,needle):
    for n,s in enumerate((ROOT/file).read_text(encoding='utf-8').splitlines(),1):
        if needle in s:return f'{file}:{n}'
    raise ValueError((file,needle))
same={}
def add(ids,file,needle,test):
    for id in ids.split():same[id]={'file':location(file,needle),'test':test}
add('P0103','project/game/panels_rules_r22.gd','static func recruited','P0103.has')
add('P2390 P2391','project/game/persona_rules.gd','func scenarios','P2390.P2391.scens')
add('P2392','project/game/persona_rules.gd','func view','P2392.view')
add('P2394','project/game/persona_rules.gd','func prepare','P2394.prepare')
for id,fn,t in [('P2484','level','P2484.lv'),('P2487','shown_aff','P2487.aff'),('P2493','num','P2493.num'),('P2495','first','P2495.first'),('P2505','slot_ok','P2505.slot_ok'),('P2507','fnum','P2507.fnum'),('P2571','normalize_bg','P2571.bgs'),('P2573','member_class','P2573.mcls')]:add(id,'project/game/panels_rules_r22.gd','static func '+fn+'(',t)
add('P2503 P2504','project/game/panels_state_r22.gd','func candidates','P2503.items_for')
for id,fn,t in [('P2508','effect_def','P2508.fx_def'),('P2509','effect_value','P2509.fx_val'),('P2510','effect_name','P2510.fx_name')]:add(id,'project/game/panel_gear_r22.gd','static func '+fn+'(',t)
add('P2582 P2583','project/game/panels_state_r22.gd','func members','P2582.P2583.members')
for id,fn,t in [('P3718','has_asset','P3718.has'),('P3719','asset_name','P3719.name'),('P3720','pick','P3720.pick')]:add(id,'project/ui/portrait_rules_r22.gd','static func '+fn+'(',t)
for id,fn,t in [('P3813','enabled','P3813.mem_on'),('P3814','cut','P3814.mem_cut'),('P3815','length','P3815.mem_len')]:add(id,'project/game/chronicle_store_r22.gd','static func '+fn+'(',t)
for ids,fn,t in [('P2699','decode_key','P2699.key'),('P2700','enabled','P2700.enabled'),('P2703','sha256','P2703.sha256'),('P2704','hmac','P2704.hmac'),('P2705 P2706','hex','P2705.P2706.hex'),('P2708','b64','P2708.b64'),('P2714','code','P2714.code'),('P2715','bounded','P2715.bounded')]:add(ids,'project/game/cloud_legacy_r23.gd','static func '+fn+'(',t)
fixed={
 'P0090':('project/game/localization_r22.gd','if not vars.has','null 값은 미지정 자리처럼 원문 토큰 유지'),
 'P0091':('project/game/localization_r22.gd','if not vars.has','치환 callback의 null 분기 보강'),
 'P2394':('project/game/persona_rules.gd','func prepare','잘못된 stats/bonus_custom/총량 기본값 보정'),
 'P2503':('project/game/panels_state_r22.gd','func candidates','아이템 레벨 필터 및 잘못된 동료·부위 입력 차단; 12개 모두 표시'),
 'P2507':('project/game/panels_rules_r22.gd','static func fnum','원본 소수 한 자리·정확한 이진수 동점 반올림'),
 'P2509':('project/game/panel_gear_r22.gd','static func effect_value','효과 값 소수 자릿수·부호·단위 대조'),
 'P2539':('project/game/panels_rules_r22.gd','elif arg.begins_with("pg_")','지수 표기 페이지 입력 처리; 표시 시 페이지를 실제 범위로 보정'),
 'P2593':('project/game/panels_state_r22.gd','func bg_action','메시지 보존과 장착·판매·일괄 판매 원문/조사 복구; 페이지 변환'),
 'P2735':('project/game/cloud_store_r22.gd','var cached=saved.get','계정별 순위 캐시와 실패 조회 시각을 재시작 뒤에도 유지'),
 'P2737':('project/ui/cloud_screen_r22.gd','var pct=','조회 층과 현재 층이 다르거나 백분위가 숫자가 아니면 표시 차단'),
 'P2740':('project/game/cloud_store_r22.gd','if not Legacy.rank_due','299/300초 경계와 시계 역행, 실패 요청의 재시도 제한'),
 'P3718':('project/ui/portrait_rules_r22.gd','static func has_asset','이름표의 정확한 true만 허용'),
 'P3720':('project/ui/portrait_rules_r22.gd','static func pick','truthy 비논리 값으로 잘못된 초상을 부르는 경우 차단'),
 'P3731':('project/game/town_places_r22.gd','static func label','장소 HUD 이름의 정본 영어 문맥을 시나리오 번역과 분리'),
 'P3813':('project/game/chronicle_store_r22.gd','static func enabled','설정은 숫자 0일 때만 꺼짐'),
 'P3814':('project/game/chronicle_store_r22.gd','static func cut','불완전 UTF-8의 바이트 자르기 fallback 보강'),
 'P3815':('project/game/chronicle_store_r22.gd','static func length','불완전 UTF-8의 바이트 길이 fallback 보강')}
special={
 'P0017':'native schema 3의 새 게임은 원본 v1 전체 객체와 다르다. 제외된 성적 칸·호스트 상태를 새로 실행하지 않으며 기존 저장 보존 계약을 유지한다.',
 'P0084':'옛 native 저장의 fight=0·4인 편성·추가 필드 보존 이관은 원본 G_migrate의 fight=1 기본값과 다르다. 기존 이관을 바꾸지 않았다.',
 'P0085':'RisuAI getChatVar 및 exp_settle/gear_restrict 후 재저장과 native 파일/백업 복원의 전체 계약이 다르다.',
 'P0097':'dk_game/dk_chron 두 채팅 변수 저장과 native 원자적 파일·큐 저장의 매체/반환 계약이 다르다.',
 'P0101':'os.time/os.clock/math.random 조합 씨앗은 native 로컬 RNG 씨앗과 다르다. 진행 중 저장의 난수열은 변경하지 않았다.',
 'P2539':'페이지·즐겨찾기·필터 분기 대조는 통과. 원본 un_/eq_ 코드는 native UID 직접 장착/해제 경로로 연결되며 동일한 전체 G 반환은 미확정.',
 'P2593':'한글·영어 메시지/선택 경계 70개와 기존 거래 fixture는 통과. 코드↔UID·보존용 overflow/옛 장비·전투 중 거부·HTML 이스케이프 전체 계약은 동일 판정하지 않았다.',
 'P3731':'town/시설/잘못된 장소 180표본은 통과. dungeon 장면의 ex_label 위임은 원정 담당 범위여서 이 행 전체는 일부 유지.',
 'P2712':'원본 v1 필드/가방 문자열·초안 금화 환불·호스트 이름 제거와 native schema 3 전체 저장의 프로토콜이 다르다.',
 'P2713':'원본이 만든 실제 payload 바이트의 HMAC/URL 조립은 일치. native 저장→원본 payload 변환 및 /s 배포 수신 흐름은 연결하지 않았다.',
 'P2716':'원본 v1 복원 정규화와 native schema 3 복원은 서로 다른 저장 계약이다. 사용자 저장·장비·완료 원정 보존 규칙을 강제 변경하지 않았다.',
 'P2717':'원본 cloud_apply 안의 코드/장착 칸 검증은 native UID 복원과 일대일 대응을 확정하지 못했다. 장비 규칙 파일은 수정하지 않았다.',
 'P2721':'원본 AI 여관 회상 지시문 생성·pending 장면은 native 클라우드 복원에 없다. 과거 사실·숫자를 지어내는 장면으로 대체하지 않았다.',
 'P2722':'cloud_recap 내부의 레벨→출전자→경험치 점수 선택 전체가 native AI 회상 흐름에 없다.',
 'P2723':'cloud_recap 내부 호스트 이름/AI 번역은 native 회상 흐름에 없다.',
 'P2701':'native SHA-256 결과는 원본과 일치하나 내부 ror는 엔진 해시 구현에 위임한다. 별도 원본 ror 함수 경계가 같은 것으로 승격하지 않았다.',
 'P2711':'native는 사용자 저장의 알 수 없는 필드를 보존하는 복사를 사용한다. Lua JSON 재인코딩 copy의 모든 타입/정밀도 손실까지 같게 만들지 않았다.',
 'P3816':'연대기 저장 재개는 시험했으나 getChatVar 예외를 pcall로 삼키는 호스트 JSON getter는 native 파일 복원과 동일 경계가 아니다.',
 'P3817':'getChatVar를 호출하는 원본 익명 callback의 호스트 예외 계약을 native 함수 동등성으로 확정하지 않았다.'}
def reason(i):
    id=i['id'];file=i['source']['file'];symbol=i['source_symbol']
    if id in special:return special[id]
    if file.endswith('68-cloud.lua'):return '호스트 alertInput/async/request·6자리 PIN·원본 /l 응답/메시지/AI 장면과 native /v1 계정·10자리 PIN·CAS가 다르다. 로컬 계정/복원 검사는 통과하나 원본 전체 반환 계약·운영 배포는 미확정.'
    if file.endswith('69-rank.lua'):return '원본 dk_rank/공개 /r/best/호스트 callback과 native 계정별 /v1/rank는 다르다. 캐시 재개·42개 시간 경계·21개 층/백분위 입력은 별도 통과. 운영 순위 계약 전체는 일부 유지.'
    if file.endswith('01-game.lua') and any(t in symbol for t in ['ui_pack','B.U','en_dict','B.T']):return '공개 범위의 언어/치환·fallback 대조는 통과. 원본 전체 언어 사전에는 제외한 성적/호스트 전용 화면도 있어 사전 전체 반환·캐시가 같다고 판정하지 않았다.'
    if file.endswith('01-game.lua'):return 'native Control/파일/화면 전환과 RisuAI HTML/CBS·채팅/페르소나 이미지·잠금 callback의 전체 반환 계약이 다르다. 원본 렌더 및 native 경로 증거와 함수 전체 동일 판정을 구분했다.'
    if file.endswith('60-create.lua'):return '현재 Lua의 생성·시나리오 fixture 및 native 생성 경로는 통과. HTML/CSS 반환·호스트 이름/이미지·첫 만남 AI/pending 문맥까지 같은 계약은 미확정.'
    if file.endswith(('65-codex.lua','66-status.lua')):return '현재 Lua의 필터/수치/거래 및 native 화면·포인터 검사는 통과. 원본 전체 HTML/CSS/버튼 값과 native Control/UID, 또는 전투 인원 패널/호스트 얼굴의 전체 반환은 일치 확정하지 않았다.'
    if file.endswith('67-settings.lua'):return '언어/난이도/기록/초기화 보존 검사는 통과. 원본 HTML 폼·호스트 그림·AI 장 요약/프롬프트 다이어트·제외 설정 및 원본 공유 링크와 전체 동일한 설정 화면은 아니다.'
    if file.endswith('85-portrait.lua'):return '이름표 선택은 별도 행에서 대조했다. 이 함수의 RisuAI asset 토큰 HTML 반환과 native 승인된 로컬 그림/실루엣은 같은 반환 형식이 아니다.'
    return '이 함수 전체의 원본 상태/반환을 native 대응과 같은 것으로 확정하지 못했다.'
rows=[]
for i in items:
    id=i['id'];key=Path(i['source']['file']).name+':'+str(i['source']['start']);entry=same.get(id)
    ev=[]
    if entry:
        group=rules['groups'].get(entry['test']);assert group and not group['failures'],(id,entry)
        ev=[{'test':'project/tests/ui_rules_r23_test.gd','group':entry['test'],'checks':group['checks'],'implementation':entry['file']}]
    elif any(bucket.get(key,0) for bucket in calls.values()):
        native_tests=[]
        for test in prior[id]['evidence'].get('tests',[]):
            match=re.search(r'project/tests/[^:]+\.gd',test)
            if match and (ROOT/match[0]).exists():native_tests.append(match[0])
        ev.append({'source_execution':'verification/parity-r23/source-calls.json','source_outputs':['verification/parity-r23/source-renders.json','verification/parity-r23/source-surrounding.json'],'native_regressions':native_tests,'comparison_passed':False,'note':'원본 실행/회귀 근거이며 함수 전체 동등성 증거로 승격하지 않음'})
    if id=='P2593':ev.append({'test':'project/tests/panel_messages_r23_test.gd','result':'verification/parity-r23/messages-results.json'})
    if id in ['P2735','P2740']:ev.append({'test':'project/tests/cloud_compat_r23_test.gd','result':'verification/parity-r23/cloud-compat-results.json'})
    fix=fixed.get(id)
    row={**i,'previous_status':i['status'],'status':'같음' if entry else i['status'],'prior_reason':prior[id]['evidence']['reason'],'new_evidence':ev,'source_calls':{name:bucket.get(key,0) for name,bucket in calls.items()},'modified':{'file':location(fix[0],fix[1]),'change':fix[2]} if fix else None,'remaining_reason':'' if entry else reason(i)}
    rows.append(row)
suite=read(OUT/'regression.json');server=read(OUT/'server/results.json')
native=read(OUT/'ui-native-results.json');msgs=read(OUT/'messages-results.json');cloud=read(OUT/'cloud-compat-results.json')
assert not rules['failures'] and not native['failures'] and not msgs['failures'] and not cloud['failures']
fresh=read(OUT/'fresh-oracles/results.json')
battle=[]
for file in ['p2-full-battles.json','a6-mixed-audit.json','p3-mixed-audit.json','a7-gear-audit.json','a7-gear-balanced-audit.json','a8-audit.json','a9-native-10-audit.json','a9-native-40-audit.json']:
    d=read(ROOT/'verification/data-r21'/file);n=d['battles'];eq=d.get('equal_battles',n if not d.get('field_differences') else 0)
    battle.append({'file':'verification/data-r21/'+file,'battles':n,'matched':eq})
assets=read(ROOT/'ASSET-HASHES.json');changed_assets=[a['path'] for a in assets if hashlib.sha256((ROOT/a['path']).read_bytes()).hexdigest()!=a['sha256']]
summary={'rows':len(rows),'promoted_same':len(same),'fixed_rows':len(fixed),'fixed_and_promoted':len(set(fixed)&set(same)),'fixed_remaining_partial':len(set(fixed)-set(same)),'remaining_rows':len(rows)-len(same),'remaining_counts':dict(Counter(r['status'] for r in rows if r['id'] not in same)),'rule_checks':rules['checks'],'native_ui_checks':native['checks'],'native_ui_captures':len(native['captures']),'message_checks':msgs['checks'],'cloud_compat_checks':cloud['checks'],'project_groups':len(suite),'project_failed_groups':sum(not r['passed'] for r in suite),'server_groups':len(server),'server_failed_groups':sum(bool(r['exit']) for r in server),'combat_battles':sum(r['battles'] for r in battle),'combat_matched':sum(r['matched'] for r in battle),'assets':len(assets),'changed_assets':changed_assets,'source_render_cases':len(read(OUT/'source-renders.json')['cases']),'source_render_failures':sum(not r['ok'] for r in read(OUT/'source-renders.json')['cases']),'source_rows_executed':sum(any(r['source_calls'].values()) for r in rows)}
write(OUT/'ui.json',{'baseline_commit':audit['commit'],'method':'Current source Lua via lua_sim; JSON float fixture inputs include IEEE-754 bytes; source calls alone do not promote rows. 같음 is the tested function boundary, not whole-screen or deployed service parity. No commits or production deployment.','summary':summary,'rows':rows})
write(OUT/'summary.json',{**summary,'combat':battle,'fresh_oracles':fresh})
report=f'''# R23-ui · 계정·화면·설정 함수 대조

담당 **{len(rows)}행**을 모두 목록화하고 정본 Lua 함수를 직접 실행했다. **같음 승격 {len(same)}행**, 재현 또는 원본 분기로 수정한 행 **{len(fixed)}행**(승격과 중복 {summary['fixed_and_promoted']}행), **잔여 {summary['remaining_rows']}행**이다. 잔여 판정은 {summary['remaining_counts']}다. 전체 기능 이식 완료라는 뜻은 아니다.

행별 원본 위치·기존 판정 사유·새 시험명·구현 파일:줄·남은 이유는 `verification/parity-r23/ui.json`, 입력 목록 원문은 `ui-worklist.json`이다. 기존 PARITY-R21 판정 파일은 일괄 수정하지 않았다.

## 수정

- 생성 상태의 잘못된 능력치/총량/직접 입력 표시를 원본대로 보정하고, 화면 읽기 기본값과 시나리오 map 정렬을 추가했다.
- 장비 후보에 빠졌던 아이템 레벨 필터를 복구했다. 잘못된 인물/부위를 거부하며, 원본 최대 12개를 모두 표시하고 12번째 장착·저장 재개를 확인했다. 장비 규칙/가격/효과 계산은 바꾸지 않았다.
- 효과는 원본 소수 한 자리로 표시한다. 1.25→1.2 같은 정확한 이진 부동소수점 경계를 원본 Lua와 대조했다. oracle JSON 숫자 직렬화가 입력 정밀도를 잃지 않도록 IEEE-754 바이트를 함께 기록한다.
- 초상 이름표는 정확한 `true`만 인정한다. 초상 선택 규칙·누락 fallback·표정 모듈·숨김 조건을 대조했으며 이미지 바이트는 바꾸지 않았다.
- 페이지의 지수 표기와 범위 보정, 장착/판매 원문 메시지와 한국어 조사, 미지정 null 치환을 보강했다. UI 라우터의 알림 초기화와 원본 함수 단독 호출의 알림 보존을 구분했다.
- 기록 토글은 숫자 0일 때만 꺼진다. UTF-8 글자 수와 손상된 바이트 문자열 fallback도 원본을 실행해 대조했다.
- 서버 배포 없이 원본 SHA-256/HMAC/hex/base64url/계정 코드/서명 링크 조립을 대조했다. 제품에 운영 서명 키를 넣지 않았다. 원본 /s·/l과 native /v1 저장 계약은 같음 처리하지 않았다.
- 순위 조회 시각과 결과를 계정별 기기 설정에 추가 저장한다. 실패 요청도 제한 시간을 소비하며 299/300초와 시계 역행을 대조했다. 실패 뒤 이전 백분위, 층수가 다른 백분위, 잘못된 타입은 표시하지 않는다.
- 장소 HUD 영어는 런타임 정본을 별도 문맥으로 쓴다. 첫 만남의 공식 영어 장소 문구와 기존 전투 번역은 보존했다.

## 직접 실행한 검사

|검사|결과|
|---|---:|
|프로젝트 import·공통·전체 실행 시험/대조 그룹|{summary['project_groups']}종 / 실패 {summary['project_failed_groups']}|
|새 원본 함수 대조|{rules['checks']:,}개 / 실패 {len(rules['failures'])}|
|새 native 화면·포인터·저장 재개|{native['checks']:,}개 / 실패 {len(native['failures'])}; {len(native['captures'])}캡처|
|새 원본 가방 메시지|{msgs['checks']}개 / 실패 {len(msgs['failures'])}|
|새 순위 캐시/실패 재시도 재개|{cloud['checks']}개 / 실패 {len(cloud['failures'])}|
|로컬 Worker/D1 서버 시험|{len(server)}종 / 실패 {summary['server_failed_groups']}|
|전투 전체 trace 대조|{summary['combat_matched']:,}/{summary['combat_battles']:,}판 일치|
|현재 원본 HTML 조립|{summary['source_render_cases']}입력 / 오류 {summary['source_render_failures']}|
|원본 보호 자산 해시|{len(assets)}개 / 변경 {len(changed_assets)}|

새 UI 검사는 360×780·390×844·430×932의 한글/영어를 다룬다. 도감 첫 화면, 360px 영어 12번째 후보, 430px 한글 12번째 후보, 360px 순위 화면을 직접 열어 확인했다. 검토한 파일과 관찰은 `visual-review.json`에 있으며, 모든 회귀 이미지를 직접 검토했다는 뜻은 아니다.

`tools/ui_r23_verify.py`는 일반 클라우드 시험에 지시된 `node server/abyss-save/test/serve.mjs`를 사용한다. 만료 계정 시험은 기존 `godot-r3.mjs`가 실제 D1에 만료 표본을 만든 뒤 실행한다. 초기 일반 서버 실행에서는 이 표본이 없어 4개가 실패했고, 올바른 fixture로 재실행한 최종 결과를 위에 기록했다. Windows 인증서 저장소 진단은 검사 오류와 별도 기록했다.

초기 대조 실패는 `ui-baseline.json`, 알림의 수정 전 12개 실패는 `messages-baseline.json`, 지수 표기 선택 실패는 `messages-boundary-baseline.json`에 보존했다. 통과 수치로 덮지 않았다. 기존 시험 기대값은 바꾸지 않았다. 생성/도감/기록/설정 oracle 4종도 복제 작업 공간에서 현재 Lua로 재실행했다. 생성된 모든 공개 필드는 현재 데이터와 같고, 기존 전투 번역 UI 20키/단어 5키는 삭제하지 않았다. 실행 대상 86종의 누락 0과 보조/과거 기준판 파일 목록은 `suite-coverage.json`에 있다.

## 잔여 범위와 저장 보존

RisuAI HTML/CBS, 호스트 이름·초상·채팅/AI 잠금 callback, 전투 상태창 전체, 제외 설정/언어 사전 전체는 native Control과 같은 반환으로 판정하지 않았다. 원본 v1 코드형 장비/가방과 native schema 3 UID/옛 저장 보존 계약, 공유 링크/PIN/CAS 및 운영 순위도 잔여 이유를 각 행에 적었다. 운영 HTTPS/Turnstile/두 기기 실배포는 수행하지 않았다. 성적 장면은 구현하지 않았다.

사용자 게임 저장과 기존 이관 정책은 유지한다. 새 순위 캐시만 기기 설정에 가산했다. 전투·장비 규칙·원정 규칙, 원본 프로젝트, 다른 worktree, `docs/`에는 쓰지 않았다. git 명령·커밋·Web export·배포는 실행하지 않았다. 변경 파일과 금지 파일 검사는 `write-audit.json`에 있다.

실행: `python tools/ui_r23_refresh.py`, `node tools/ui_r23_oracle.mjs`, `python tools/ui_r23_verify.py`, `python tools/ui_r23_server_tests.py`, `python tools/ui_r23_snapshot.py`.
'''
(ROOT/'R23-ui.md').write_text(report,encoding='utf-8');print(json.dumps(summary,ensure_ascii=False,indent=2))
if '--final' in sys.argv:
    assert summary['project_failed_groups']==0 and summary['server_failed_groups']==0
    assert summary['combat_battles']==6320 and summary['combat_matched']==6320 and not changed_assets
    assert summary['source_rows_executed']==144
    assert not read(OUT/'write-audit.json')['forbidden_changed']
    assert not read(OUT/'suite-coverage.json')['missing']
