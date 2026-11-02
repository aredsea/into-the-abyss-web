"""Prepend round 11 and retain all previous report sections."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round11'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
s=read(O/'summary.json');a=read(O/'audit.json');src=read(O/'source-titles.json');ui=read(O/'ui-results.json')
assert s['groups']==57 and not s['failed_groups'] and s['web_configurations']==7 and s['web_artifact_matches']
inventory={'titles':src['rows'],'navigation':src['nav'],'untranslated_native_observed':ui['untranslated_observed'],
 'scope':'Exact source UI/en_dict and public English dictionaries only; retained Korean is not guessed. SVG text inventory is separate from Label observations.',
 'generated':['recruit','shop','smithy'],'already_english':['home'],'battle':'Read-only battle titles and dialogue data retained.'}
write(O/'translation-inventory.json',inventory)
review={'native_contacts_opened':[f'contact-{d}.jpg' for d in ['360x780','390x844','390x664','430x932','1280x800']],
 'native_360_opened':['status-en','status-ko','codex-en','member-en','shop-en','recruit-en','smithy-en','cloud-en','depart-en'],
 'web_360_opened':['p7-status','participate','settled'],
 'fixes':['Source integer rounding in ko/en status and member stats.','Recruited filter remains one line at 360 width.','Source-backed SVG titles: three.','Paged floor selector retained in illustrated preparation, with readable floor details.','Web missing star glyph replaced with SVG geometry.','Persona equipment is selectable from town facilities.'],
 'native_popup_test':'Native P5 picker opens by synthesized pointer; selection uses public OptionButton signal, matching the existing P6 test convention. Web equipment picker uses actual pointer input.',
 'limits':['Partial English remains where no exact canonical phrase exists.','No approved persona portrait; neutral placeholder retained.','No physical phone or screen-reader validation.'],
 'design_context':'Impeccable detector: zero findings. Existing DESIGN.md sidecar is stale; not changed. The document command can refresh it separately.'}
write(O/'visual-review.json',review)
title_rows='\n'.join('|'+r['ko']+'|'+(r['en']+' · 새 SVG' if r['en'] else '기존 영문 유지' if r['id']=='home' else '정본 대응 없음 · 유지')+'|' for r in src['rows'])
changes='\n'.join('- `'+p+'`' for p in a['changed_existing_files'])
new='\n'.join('- `'+p+'`' for p in a['new_project_files'] if not p.endswith(('.uid','.import')))
text=f'''## 11차 — P9b·P5·P6 병합 · 통합 저장 허용 목록 · 정수 표시와 영어 제목

충돌을 파일 내용으로 해결하고 8~10차의 준비 화면·설정·P7/P10 복귀 흐름 위에 원정·시설·클라우드를 연결했다. 정본 영어가 없는 문구는 한국어로 유지한다. 운영 클라우드는 배포하지 않았다.

|항목|최종 결과|
|---|---:|
|충돌 표시|0|
|전체 검사 그룹 / 실패|{s['groups']} / 0|
|새 의미 통합 검사 / 실패|{s['integration_checks']} / 0|
|실제 옛 저장 이관|{s['legacy_specimens']}표본|
|새 통합 저장 표본|{s['merged_specimens']}종|
|서버 D1 integration / 실패|{s['server_checks']:,} / 0|
|P9b 보안 integration / 실패|{s['security']['checks']} / 0|
|Turnstile 로컬 검증 / 실패|{s['turnstile']['checks']} / 0|
|서버 검사 합계 / 실패|{s['server_checks']+s['security']['checks']+s['turnstile']['checks']:,} / 0|
|새 native UI 검사 / 실패|{s['ui_checks']:,} / 0|
|native 캡처|{s['native_captures']}장 · 5크기|
|Web 구성 / 실제 전투 승리 / 오류|7 · ko/en / {s['web_battles']} / 0|
|보호 파일 / 변경|{a['protected_count']:,} / 0|
|원본 자산 / 변경|{a['original_assets']} / 0|
|읽기 전용 원본 파일 / 변경|{a['source_count']} / 0|

### 통합과 저장

`persona_sortie_screen.gd`는 기존 초상 전·후열 편성, 대기 필터, 참전/지휘, 그림 경로, 의뢰 출발과 재시도를 유지한다. 층 선택에는 P5의 6층 페이지·잠긴 다음 층·선택 층의 권장/적 레벨·별을 연결했다. 새 별은 Web 글꼴 누락을 피하는 SVG다. `world_screen.gd`는 P6 시설 영수증·이동 잠금과 원정 보급품·결과 화면, 클라우드 화면을 기존 설정·P7/P10 경로와 결합했다. 연대기 화면에 실제 클라우드 진입 버튼도 추가했다.

최종 모델은 `settings_world_r22 → town_chronicle_world_r22 → facilities_world_r22 → expedition_world_r22 → persona_world`다. 기존 `chronicle_world_r22`는 원래 바이트를 유지해 P1의 이전 원정 계약 검사도 보존했다. 통합 facade는 실제 P5 정산과 시설 영입을 P10 관측 경계로 감싼다. 구 원정에는 P5 버전을 소급해서 붙이지 않는다. 클라우드 다운로드는 이 전체 모델의 임시 인스턴스로 검증하며, UI가 모델을 교체하면 클라우드가 참조하는 모델도 갱신한다.

시설 합류에서 세 가지 결함을 고쳤다. P6가 넘기는 폐기 장비 값은 P5 정산이 요구하는 개수로 맞췄다. schema 3의 성장 표시 mirror가 불러오기마다 새 이관 기록을 만들지 않도록 했고, 실제 성장값과 다른 옛 값은 기존 P6 보관 필드에 남긴다. 통합 모델은 중복 성장 mirror와 스크롤의 옛 최상위 `lv`를 저장하지 않는다. 마을 장비 화면에도 페르소나 선택을 연결했다. 승인 초상이 없어 중립 칸을 사용한다.

새 흐름은 새 시작 → 만들기 → 첫 만남 → 선택 대화 → 영입 → 탐색 5회 → 휴식 → 보스 → 정산 → 다음 층 → 귀환 → 상점·가공·제련·스크롤 → 로컬 D1 업로드/다운로드다. 탐색 중 XP 지급 없음, 정산에서 P1 XP 한 번, P10 레벨·돌파·다음 층 기록 한 번, 중복 정산 무변화를 검사했다. Native 전투 종결은 생산용 serializer/validator를 쓰는 통제 snapshot fixture다. Web의 {s['web_battles']}회 승리는 수치나 적을 바꾸지 않은 실제 전투다.

11개 원문 저장의 입력 보존·D 성장 권위(Lv17/XP2 선택, Lv25 원문 보관)·반복 이관·왕복을 확인했다. 이관 기록과 제련 상태, P7 패널/즐겨찾기, 설정, 연대기, 진행 중 P5 원정을 한 payload에 함께 담은 `merged_legacy_expedition` 표본도 검사했다. 별도 IndexedDB 문맥에서 v1·백업 바이트 보존, 읽기만 할 때 v3 쓰기 없음, 실제 행동 뒤 v3 우선 재로드를 확인했다. 실제 사용자 프로필은 사용하지 않았다.

### 서버 검증 범위

`server/abyss-save/src/validate.js`의 저장 허용 목록과 검증 범위를 확장했다. P5 run/maxima/summary/dungeon last, P6 코드별 제련·옛 성장 보관·큰 재고/금화, P7 favs/panels, P8 설정·전투별 배율, P10 연대기·귀환 선택, 기존 dialogue/npc_aff 및 D 이관 기록을 검증한다. 페르소나 HP/MP는 장비 보너스도 반영해 수용한다. 장착품을 제외한 가방 2,000칸과 안전한 JSON 정수 범위를 반영했다.

P5 5종 + P6 6종 + 새 통합 {s['merged_specimens']}종, **합계 {11+s['merged_specimens']}종**을 실제 Worker·D1으로 계정 생성 → 읽기 → PUT → 오래된 rev의 409 → 최신 읽기까지 왕복했다. 새 필드의 타입·범위·참조·임의 객체·prototype 장비 코드 등 37개 변조를 직접 validator와 HTTP 양쪽에서 거절했다. 기존 P9b 보안 422개와 로컬 siteverify 7개도 통과했다.

서버 `index.js`, known 카탈로그, migration, Wrangler 설정, 보안 검사 파일은 바이트 불변이다. 인증·PIN·속도 제한·순위·보관 정책은 변경하지 않았다. 기존 64 KiB HTTP payload 제한도 유지한다. 매우 큰 가방 전체가 그 제한 안에 들어간다는 주장은 하지 않는다. `dist/worker.mjs`를 다시 빌드하고 현재 소스 bundle과 일치함을 확인했다.

### 표시·정본 영어 목록

정본 `65-codex.lua`의 `PX.num`과 `66-status.lua`의 표시 규칙은 정수 반올림이다. ko/en 상태창은 HP 118, MP 33, Strength 21, Agility 6처럼 표시하며, 동료의 Defend 17.68은 18로 표시한다. 내부 전투 수치는 바꾸지 않았다. 영어 도감 필터는 360폭에서 `Recruited`를 포함한 네 탭 모두 줄바꿈 0이다. 일반 한글 라벨의 ‘추천 1층’을 잘못된 영문 floor template이 삼키는 문제도 숫자 캡처 제한으로 수정했다.

원본 `B.en_dict()` / `B.ui_pack("en")`과 공개 영어 사전을 직접 읽었다. 새 영문 제목은 정본 문구를 배송 display 글꼴로 그린 뒤 윤곽 SVG로 추적하고 기존 dry-brush 결을 적용했다. 기존 한국어 제목 SVG는 수정하지 않았다.

|화면의 제목|처리|
|---|---|
{title_rows}

하단의 **마을·원정·기록은 정확한 정본 영문이 없음**을 확인해 유지했다. 동료/가방의 정본 `Ally`/`Bag`와 함께 부분 영어 상태로 남는다. 임의로 Town/Expedition/Journal을 새 번역으로 넣지 않았다. 전체 목록과 native 한국어 관측은 [translation-inventory.json](verification/town-r21/round11/translation-inventory.json)에 있다. 이는 전체 번역률이나 모든 대사의 영문화 완료를 뜻하지 않는다.

### 직접 확인·Web·한계

360×780 / 390×844 / 390×664 / 430×932 / 1280×800의 연락판 5개를 직접 열었다. 360폭 ko/en 능력치, 도감 탭, 준비, 새 영문 제목, 페르소나 장비, 클라우드와 실제 WASM 상태·준비·정산도 확인했다. 새 native UI 검사는 34상태 × 5크기 = 170캡처다. Native PopupMenu는 별도 OS 창이므로 P5 선택 검사는 기존 P6처럼 공개 선택 signal을 사용하고, Web 장비 selector는 실제 포인터로 첫 항목을 선택했다. 물리 휴대폰·스크린리더는 시험하지 않았다.

지정 export와 `tools/update_version.py` 완료: **ui_build={a['ui_build']}**, PCK **{a['pck_bytes']:,} bytes**, SHA-256 `{a['pck_sha256']}`. `python tools/web_smoke_r19.py --town-r21`의 한국어 6구성과 영어 360폭 1구성 모두 실패 0이며 PCK 해시가 최종 export와 일치한다.

배송 `cloud-r22.json`의 서버 URL·Turnstile 사이트 키는 원래 빈 값이다. 로컬 Worker/D1 시험만 했고 원격 배포·실서비스 Turnstile·운영 CPU/cron은 검증하지 않았다. AI 대화 호스트 기능, `79-sex.lua`와 성적 친밀도 장면·장미 골목/창관·성적 제안은 이식하지 않았다. 원본 봇 전체 기능 동등성이나 시안 픽셀 일치 완료를 주장하지 않는다.

Impeccable 검사 지적은 0이다. 기존 DESIGN.md보다 오래된 디자인 sidecar 진단은 기록만 했으며, 별도 `document` 작업으로 동기화할 수 있다. 자세한 검수 기록은 [visual-review.json](verification/town-r21/round11/visual-review.json)이다.

### 파일·재현

기존 파일 변경:

{changes}

새 프로젝트 파일(자동 UID/import 제외):

{new}

새 도구는 `tools/town_r21_round11_{{source.mjs,titles.py,verify.py,finish.py,report.py}}`다. 근거는 `verification/town-r21/round11/`, Web 캡처는 `verification/town-r21/web/`, 서버 결과는 `verification/cloud-r22/`와 round11의 서버 로그에 있다. 이전 실패 진단은 최종 통과 결과와 구별한다. `regression.json`에 57그룹의 종료값·검사 오류·수치를 보관했다. fixture와 읽기 전용 전투 자산 생성기는 실행 대상으로 세지 않았다.

재현 순서: 로컬 시험 서버(`node tools/facilities_r22_local_server.mjs`, 설치된 Miniflare의 `ABYSS_NODE_MODULES` 지정) → `python tools/town_r21_round11_verify.py` → `node server/abyss-save/test/integration.mjs` / `security.mjs` / `turnstile.mjs` → 지정 Web export → `python tools/update_version.py` → `python tools/web_smoke_r19.py --town-r21` → `python tools/town_r21_round11_finish.py` → `python tools/town_r21_round11_report.py`.

서버 기존 테스트에서 바뀐 수치 기대값은 금화의 옛 100,000,000 상한 거부를 안전 정수 초과 거부로 옮긴 한 항목이다(P6의 정본 무상한 재고/금화 계약). P5 native UI 검사의 층 선택 입력은 기존 폼 버튼에서 보존된 준비 화면의 페이지 selector로 바꿨으며 선택 결과 7층은 그대로다. 게임 규칙·전투 수치 기대값 변경은 0이다. 기존 Windows root certificate store 환경 진단은 로그에 남겼고 검사 오류와 분리했다. Git 명령·다른 worktree 쓰기·사용자 저장 삭제·원격 배포는 0이다.

'''
p=R/'UI-R21-D.md';old=p.read_text(encoding='utf-8');p.write_text('# UI-R21-D\n\n'+text+old[old.index('## 10차'):],encoding='utf-8')
print(str(p))
