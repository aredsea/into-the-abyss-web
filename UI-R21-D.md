# UI-R21-D

## 13차 — 동료 30명 대사 전수 연결 검증 · Web b

30명 전원의 기존 동적 재생기를 실제 여관·원정 화면과 통합 저장 모델로 검증했다. 대사 JSON은 읽기만 했으며 전투·A 데이터·적·초상·서버 보안 로직은 바꾸지 않았다. 최종 결과는 `verification/town-r21/round13/summary.json`이다.

|항목|결과|
|---|---:|
|동료 / 여관 / 선택지|30 / 840 / 2,520|
|던전 14상황·3구간·2변형 / 단계 변화|2,520 / 420|
|새 통합 대사 검사 / 실패|17,670 / 0|
|360·430폭 × ko/en 여관 상태|18,480|
|같은 구성의 던전·단계 변화 상태|11,760|
|Native 전체 상태 / 실제 글자 치수 검사|30,240 / 199,920|
|Native UI 검사 / 실패 / 넘침|612,368 / 0 / 0|
|서버 D1 integration / 전체 npm test|6,739 / 7,980 · 실패 0|
|새 실제 native 저장 / D1 왕복|120 / 120|
|import 포함 전체 Godot 그룹 / 실패|61 / 0|
|Web ko/en 구성 / 실제 전투 승리 / 오류|7 / 29 / 0|
|보호 파일 / 원본 에셋 / 변경|1,931 / 96 / 0|
|직접 연 4명 360폭 합본|204,132 bytes · 300KB 이하|

### 표시와 실행

대사 본문·상황·선택지·반응·단계 변화는 UI 번역기에 넣지 않고 JSON 원문을 그대로 표시한다. 영어 설정에서도 대사는 한국어다. 이름표는 기존 정본 영어 사전을 사용한다. 진행·취소·여관 복귀 버튼은 원본 `05-gen.lua`의 `계속한다 → Continue`, `취소 → Cancel`, `아랫마을 여관 → Lower Town Inn`을 재사용한다. 새 영문 대사를 만들지 않았다.

긴 도입은 본문 높이를 100→132로 늘리고 선택지 시작을 561→573으로 조정했다. 본문 18px·선택지 15px를 유지했다. 취소 버튼 높이는 46→48로 늘려 360폭에서도 실제 높이 44px 이상이다. 응답·선택·취소·복귀 버튼의 뷰포트 이탈·겹침, 글자 폭·높이와 본문 간격을 실제 Native 렌더에서 측정했다. 대사 840개의 최초 도입·seen 도입·모든 선택 반응, 420개 변화 장면을 양쪽 폭·언어에서 전수 검사했다. 별도 원정 화면에서도 2,520개 짧은 말과 420개 변화 장면을 같은 구성으로 모두 그렸다.

30명 각각 실제 여관 버튼→선택→반응→복귀·하루 제한을 합성 포인터로 조작했다. 실행 검사는 840장면의 2,520선택, 14상황의 모든 구간·변형, 인접 7경계 상승·하락 420장면을 포함한다. 호감 수식·게임 RNG·금화·하루 제한·중복 지급 방지와 연대기 사실 한 번 기록을 확인했다. `speech.address_terms`는 표시용 발화로 오인하지 않으며 30명 모두 중첩 형식 그대로 읽힌다.

`stats.json`의 30명 이름을 대사 데이터와 직접 대조해 불일치 0이다. 기존 표시 보정 `힐데가르트→힐데가`, `베렝가→베렌가`, `바르구트→바르굿`을 유지하며 원본 저장·로그 문자열을 다시 쓰지 않는다.

### 저장·서버

각 동료의 선택 전·응답·원정 단계 변화·짧은 말, 합계 120종을 실제 통합 모델에서 생성했다. Native restore·입력 불변·진행 상태 왕복 뒤 실제 Worker/D1의 계정 생성→읽기→PUT→구 rev 409→최신 읽기를 모두 통과했다. 표본에는 동료별 seen 28장면도 들어 있다. 기존 옛 저장 이관·클라우드 HTTP·보관·보안 검사는 전체 회귀에서 함께 돌렸다.

기존 서버 카탈로그가 시범 3명(84장면·42변화)에 머물러 있었으므로 `npm run generate`로 **840장면·420변화**를 반영했다. 원문에서 생성한 소유자·선택 ID·변화 경계를 정확히 대조했고 Worker 번들도 재생성했다. `validate.js`, `index.js`, rate limit·Turnstile·보관·인증·migration은 수정하지 않았다. 서버 허용 규칙을 느슨하게 하지 않았다. 최종 PCK에도 30개 JSON 경로와 각각의 원문 바이트가 모두 있음을 `pack-dialogue-inventory.json`으로 확인했다.

### 직접 확인·빌드·검사 기록

최종 [owner-zoom-13.jpg](verification/town-r21/owner-zoom-13.jpg)를 직접 열어 힐데가·베렌가·바르굿·우르다의 서로 다른 화계와 이름표·선택지·취소 버튼을 확인했다. 베렌가 영어 원정 변화 화면과 최종 Web의 한국어·영어 선택/반응도 직접 열었다. 모든 자동 검사 상태를 사람이 개별 열람했다고 주장하지 않는다. 기존 픽셀 시안 차이·물리 휴대폰·스크린리더는 이번 작업의 새 검증 범위가 아니다.

지정 Godot Web export와 `update_version.py`를 완료했다. **ui_build=r21-d-town-20261103b**, PCK **66,764,420 bytes**, SHA-256 `febb8b822df8bcc208331b4a13a43dc57b7561d9757b04ff6b130c7ff7d04b7a`. 최종 패키지로 `python tools/web_smoke_r19.py --town-r21`을 실행해 영어 360폭과 한국어 6구성, IndexedDB 이관·재로드·대화·시설·연대기·실제 전투·복귀를 확인했다. 원격 배포는 하지 않았다.

첫 시도와 수정 과정도 보존했다. 전수 검사에서 발견한 마르셀린·테이리스 도입 넘침은 UI 공간을 늘려 해결했다. 초기 경계 fixture의 음수 경계·150 이상 감속값과 JSON 숫자 직렬화 비교 오류, 테스트 전용 저장 디렉터리 누락을 바로잡았다. 첫 로그는 `first-attempt-*`, 8건 넘침의 완주 결과는 `overflow-attempt-*`에 있다. 영어 `Continue`가 로컬 사전에 없는 문제는 정본 영어를 직접 재사용해 고쳤으며 실패 결과는 `english-continue-attempt-*`에 보존했다. 영어 버튼 보완 전·최종 export 전 중단한 Web 실행도 별도 로그로 남겼고 최종 7구성 결과만 합산했다.

기존 대화 시험을 3→30명으로 확대했다. 실제 바르굿 콘텐츠가 생겨 사라진 '파일 없음' 시험은 캐시를 잠시 빈 값으로 주입해 기존 fallback 동작을 계속 검사한다. 게임 수치 기대값은 바꾸지 않았다. 빌드 식별자 기대값은 지시된 b로 갱신했다. 공통 회귀의 인증서 저장소 환경 경고 61회는 기능 실패와 분리해 원시 로그에 보존했다.

Impeccable detector 결과는 `[]`이다. Godot canvas 본문은 DOM 검사로 측정되지 않으므로 Native 글꼴 치수·렌더·Web 캡처로 검수했다. 기존 DESIGN.md와 sidecar의 drift는 범위를 넓혀 수정하지 않았으며 별도 `document` 작업으로 동기화할 수 있다. 성적·친밀 장면은 추가하지 않았다.

### 변경 파일과 재현

- UI: `project/ui/{town_screen_r21,world_screen}.gd`.
- 검사: `project/tests/{dialogue_player_r21_test,dialogue_roster_r21_test,ui_dialogue_roster_r21_test,ui_dialogue_journey_roster_r21_test}.gd`.
- 서버: `server/abyss-save/src/known.json`, `dist/worker.mjs`, `test/{integration,godot-r13}.mjs`.
- 도구: `tools/{update_version,town_r21_round9_web,town_r21_round13_run,town_r21_round13_audit,town_r21_round13_report}.py`.
- 산출: `docs/**`, `verification/town-r21/round13/**`, `owner-zoom-13.jpg`, 기존 검사 재생성 결과와 이 문서.

```powershell
python -X utf8 tools/town_r21_round13_run.py dialogue_roster_r21_test ui_dialogue_roster_r21_test ui_dialogue_journey_roster_r21_test
cd server/abyss-save
npm run generate
npm run build
npm test
cd ../..
node server/abyss-save/test/godot-r13.mjs
python tools/godot_r17.py --headless --export-release Web ../docs/index.html
python tools/update_version.py
python tools/web_smoke_r19.py --town-r21
python -X utf8 tools/town_r21_round13_report.py
```

## 12차 — 클라우드 최종 보안 2건 · 운영 배포 준비

작업 지시서와 공통 규칙, `DEPLOYMENT-SECURITY.md`, cloudfix의 P9c 절을 UTF-8로 읽고 후속 수정했다. 원격 배포·migration·운영 토큰 사용·웹 export는 수행하지 않았다. 아래 근거는 `verification/cloud-r22/round12/`에 모았다.

### 수정과 재현

- `summary`와 `dungeon_r21.last`는 `expedition_version`이 없으면 `steps`·`first`·`aff`·`fell`의 존재 자체를 거절한다. 객체뿐 아니라 숫자·불리언·빈 객체도 거절하며, 정상 구형 정산과 옛 저장 이관은 유지한다.
- 신규 가입의 전역 UTC 일일 상한 두 개를 추가했다. `GLOBAL_NEW_PER_DAY=10000`, `GLOBAL_NEW_BYTES_PER_DAY=268435456`(256MiB)이다. IP별·/48별·분별 예산과 같은 D1 원자 문장에서 예약하므로 회전 IP와 동시 가입으로 초과할 수 없다. 429에서는 모든 카운터가 불변이고, cron은 당일 전역 일일 카운터를 보존한다. 기존 계정 읽기·PUT은 이 신규 가입 예산을 쓰지 않는다.
- 운영 `TURNSTILE_ENABLED=true`, 별도 `development` 환경은 false로 분리했다. 개발 환경에는 별도 D1 바인딩과 전체 vars를 명시했다. 클라이언트의 사이트 키·서버 주소는 빈 값으로 유지했다. `npm run check:deployment`와 `predeploy`는 운영 false를 거절한다. 실제 Wrangler 설정 해석 및 false 설정의 비정상 종료도 시험했다.
- 운영 `workers_dev=true`는 유지했다. 전용 도메인·WAF 연결 시 false 전환, hostname·CORS 변경, 실제 사이트 키·secret 설정을 배포 체크리스트에 명시했다.
- `npm run generate`로 원본 데이터 이름과 SHA256을 반영한 `known.json`을 재생성했다. Miniflare는 P9c와 같은 `5.20261012.0-beta`로 이미 정확히 고정돼 있음을 확인하고 `npm install --package-lock-only --ignore-scripts --offline`으로 lockfile을 재생성했다. Worker 번들도 다시 빌드했다.

시험을 먼저 추가해 수정 전 **5그룹 실패**를 `security-red.json`·`security-red.log`에 남겼다. 정산 구멍 1그룹과 전역 일일 예산 4그룹이다. 같은 시험의 수정 후 결과는 실패 0이다. 새 정산 시험은 `legacy_00`를 사용해 두 경로·네 키를 독립 변이하고 정상 구형 정산 대조군도 검사한다. 기존 시험의 기대값은 바꾸지 않았다.

### 검사 수치

|검사|결과|근거|
|---|---:|---|
|기존 Worker + 실제 D1 integration|5,659 / 실패 0|`integration-results.json`|
|기존 보안 1차 / Siteverify / 보안 2차|423 / 7 / 119 · 실패 0|`security-r1-results.json`, `siteverify-results.json`, `security-r2-results.json`|
|새 보안 3차|670 · 6그룹 / 실패 0|`security-results.json`|
|운영·개발 설정 / 배포 거부 검사|22 / 실패 0|`deployment-results.json`, `deployment-gate.log`|
|서버 `npm test` 합계|**6,900 / 실패 0**|`npm-test.log`|
|제공 `settle_blob.mjs`|**계정 생성 422**, 변이 모두 거절|`settle_blob.stdout.log`|
|정상 저장 표본|**154 / 154 수용**, 입력 불변|`security-results.json`|
|제공 `scan2`|948경로·353노드·322후보, **임의 객체 수용 0곳**|`scan2.stdout.log`|
|Godot 전체 회귀 + import|**58그룹 / 실패 0**|`regression.json`, `godot-run.log`, `godot-rerun.log`|
|Godot 클라우드 HTTP / 보관 / UI|27 / 5 / 700 · **합계 732 / 실패 0**|`native-{service,archive,ui}-results.json`|
|마을 round11 의미 통합|**148 / 실패 0**, 옛 저장 11·통합 표본 23|`town_r21_round11_test.log`|
|마을 round11 UI|**5,380 / 실패 0**, 170장|`ui_town_r21_round11_test.log`|
|보호 파일 / 원본 에셋|**1,889 / 96 · 변경 0**|`audit.json`|
|재생성 카탈로그 / Worker 번들|원본 JSON 7개 SHA 일치 / 현재 소스와 바이트 일치|`audit.json`|

전체 집계는 `summary.json`이다. 실행기는 `test/serve.mjs`와 같은 실제 workerd/D1 runtime을 빈 포트에 띄우고 시험 그룹마다 quota를 초기화한다. 사용자 컴퓨터의 기존 서버를 종료하지 않았다. Windows의 기존 root certificate store 진단은 로그에 남기고 스크립트·검사 실패와 구분했다.

첫 전체 실행에서 `town_r21_round11_test`만 8787 주소를 하드코딩해 HTTP 연결 검사 3개가 실패했다. 다른 클라우드 시험처럼 `ABYSS_TEST_SERVER`를 따르도록 시험 주소만 수정했다. 기대값은 유지했고 재실행은 148개 모두 통과했다. 첫 시도 로그·전체 집계는 `town_r21_round11-first-attempt.log`·`regression-first-attempt.json`에 보존했다.

클라우드 35장과 마을 round11 170장을 각각 5개 크기의 연락판으로 만들어 **10개 연락판을 직접 열었다**. 보관·삭제 확인 데스크톱 원본과 390×664 충돌 원본도 열어 읽었다. 클라우드의 보관 안내·저장 비활성·충돌 선택은 보이며, 짧은 화면의 하단 동작은 스크롤이 필요하다. 마을·편성·출발·상점·정산 화면의 기존 배치가 유지된다. 나머지 회귀 UI는 자동 검사 결과로 확인했으며 모든 개별 원본 캡처를 열었다고 주장하지 않는다.

`settle_blob.mjs`는 제공 원문을 그대로 실행했다. `scan2`는 오래된 scratch 사본을 하드코딩하므로 **기준 디렉터리 한 곳만 현재 worktree로 바꾼 사본**으로 실행했다. 스캔 논리와 5개 표본 집합은 그대로이며 원문 두 파일은 수정하지 않았다. 원문 SHA256과 사본은 `poc-results.json`·`scan2-local.mjs`에 남겼다.

### 변경 파일과 남은 운영 작업

- 서버: `src/{validate.js,index.js,known.json}`, `dist/worker.mjs`, `wrangler.toml`, `package.json`, `package-lock.json`, `check-deployment.mjs`, `DEPLOYMENT-SECURITY.md`.
- 검사: `server/abyss-save/test/{security-r3.mjs,deployment.mjs,godot-r3.mjs}`, `project/tests/town_r21_round11_test.gd`, `tools/cloud_r22_round12_{pocs,audit}.py` 및 `verification/cloud-r22/round12/`.
- 보고: 이 문서의 12차 절. 게임 규칙·저장 형식·클라이언트 소스·원본 에셋은 변경하지 않았다.

전역 일일 값은 실측 이용량이 아닌 초기 비용 예산이다. 신규 계정의 최초 payload 예산이며 기존 PUT 이력·인덱스·백업을 포함한 D1 전체 비용의 상한은 아니다. 실패한 Siteverify도 예약된 입장 예산을 소비한다. 운영 관측 뒤 담당자가 비용과 트래픽에 맞춰 조정해야 한다.

Claude가 실제 DB id·사이트 키·secret·서버 주소를 넣은 뒤 배포하고, 실제 Turnstile·HTTPS CORS·두 기기 흐름을 확인해야 한다. 이번 결과는 로컬 workerd/D1·모의 Siteverify 검증이다. 웹 export는 지시대로 생략했다.

```powershell
cd server/abyss-save
npm test
node test/godot-r3.mjs
npm run check:deployment
npm run generate
npm run build
cd ../..
python tools/cloud_r22_round12_pocs.py
python tools/cloud_r22_round12_audit.py
```

## 11차 — P9b·P5·P6 병합 · 통합 저장 허용 목록 · 정수 표시와 영어 제목

충돌을 파일 내용으로 해결하고 8~10차의 준비 화면·설정·P7/P10 복귀 흐름 위에 원정·시설·클라우드를 연결했다. 정본 영어가 없는 문구는 한국어로 유지한다. 운영 클라우드는 배포하지 않았다.

|항목|최종 결과|
|---|---:|
|충돌 표시|0|
|전체 검사 그룹 / 실패|57 / 0|
|새 의미 통합 검사 / 실패|148 / 0|
|실제 옛 저장 이관|11표본|
|새 통합 저장 표본|23종|
|서버 D1 integration / 실패|5,659 / 0|
|P9b 보안 integration / 실패|422 / 0|
|Turnstile 로컬 검증 / 실패|7 / 0|
|서버 검사 합계 / 실패|6,088 / 0|
|새 native UI 검사 / 실패|5,380 / 0|
|native 캡처|170장 · 5크기|
|Web 구성 / 실제 전투 승리 / 오류|7 · ko/en / 30 / 0|
|보호 파일 / 변경|1,889 / 0|
|원본 자산 / 변경|96 / 0|
|읽기 전용 원본 파일 / 변경|51 / 0|

### 통합과 저장

`persona_sortie_screen.gd`는 기존 초상 전·후열 편성, 대기 필터, 참전/지휘, 그림 경로, 의뢰 출발과 재시도를 유지한다. 층 선택에는 P5의 6층 페이지·잠긴 다음 층·선택 층의 권장/적 레벨·별을 연결했다. 새 별은 Web 글꼴 누락을 피하는 SVG다. `world_screen.gd`는 P6 시설 영수증·이동 잠금과 원정 보급품·결과 화면, 클라우드 화면을 기존 설정·P7/P10 경로와 결합했다. 연대기 화면에 실제 클라우드 진입 버튼도 추가했다.

최종 모델은 `settings_world_r22 → town_chronicle_world_r22 → facilities_world_r22 → expedition_world_r22 → persona_world`다. 기존 `chronicle_world_r22`는 원래 바이트를 유지해 P1의 이전 원정 계약 검사도 보존했다. 통합 facade는 실제 P5 정산과 시설 영입을 P10 관측 경계로 감싼다. 구 원정에는 P5 버전을 소급해서 붙이지 않는다. 클라우드 다운로드는 이 전체 모델의 임시 인스턴스로 검증하며, UI가 모델을 교체하면 클라우드가 참조하는 모델도 갱신한다.

시설 합류에서 세 가지 결함을 고쳤다. P6가 넘기는 폐기 장비 값은 P5 정산이 요구하는 개수로 맞췄다. schema 3의 성장 표시 mirror가 불러오기마다 새 이관 기록을 만들지 않도록 했고, 실제 성장값과 다른 옛 값은 기존 P6 보관 필드에 남긴다. 통합 모델은 중복 성장 mirror와 스크롤의 옛 최상위 `lv`를 저장하지 않는다. 마을 장비 화면에도 페르소나 선택을 연결했다. 승인 초상이 없어 중립 칸을 사용한다.

새 흐름은 새 시작 → 만들기 → 첫 만남 → 선택 대화 → 영입 → 탐색 5회 → 휴식 → 보스 → 정산 → 다음 층 → 귀환 → 상점·가공·제련·스크롤 → 로컬 D1 업로드/다운로드다. 탐색 중 XP 지급 없음, 정산에서 P1 XP 한 번, P10 레벨·돌파·다음 층 기록 한 번, 중복 정산 무변화를 검사했다. Native 전투 종결은 생산용 serializer/validator를 쓰는 통제 snapshot fixture다. Web의 30회 승리는 수치나 적을 바꾸지 않은 실제 전투다.

11개 원문 저장의 입력 보존·D 성장 권위(Lv17/XP2 선택, Lv25 원문 보관)·반복 이관·왕복을 확인했다. 이관 기록과 제련 상태, P7 패널/즐겨찾기, 설정, 연대기, 진행 중 P5 원정을 한 payload에 함께 담은 `merged_legacy_expedition` 표본도 검사했다. 별도 IndexedDB 문맥에서 v1·백업 바이트 보존, 읽기만 할 때 v3 쓰기 없음, 실제 행동 뒤 v3 우선 재로드를 확인했다. 실제 사용자 프로필은 사용하지 않았다.

### 서버 검증 범위

`server/abyss-save/src/validate.js`의 저장 허용 목록과 검증 범위를 확장했다. P5 run/maxima/summary/dungeon last, P6 코드별 제련·옛 성장 보관·큰 재고/금화, P7 favs/panels, P8 설정·전투별 배율, P10 연대기·귀환 선택, 기존 dialogue/npc_aff 및 D 이관 기록을 검증한다. 페르소나 HP/MP는 장비 보너스도 반영해 수용한다. 장착품을 제외한 가방 2,000칸과 안전한 JSON 정수 범위를 반영했다.

P5 5종 + P6 6종 + 새 통합 23종, **합계 34종**을 실제 Worker·D1으로 계정 생성 → 읽기 → PUT → 오래된 rev의 409 → 최신 읽기까지 왕복했다. 새 필드의 타입·범위·참조·임의 객체·prototype 장비 코드 등 37개 변조를 직접 validator와 HTTP 양쪽에서 거절했다. 기존 P9b 보안 422개와 로컬 siteverify 7개도 통과했다.

서버 `index.js`, known 카탈로그, migration, Wrangler 설정, 보안 검사 파일은 바이트 불변이다. 인증·PIN·속도 제한·순위·보관 정책은 변경하지 않았다. 기존 64 KiB HTTP payload 제한도 유지한다. 매우 큰 가방 전체가 그 제한 안에 들어간다는 주장은 하지 않는다. `dist/worker.mjs`를 다시 빌드하고 현재 소스 bundle과 일치함을 확인했다.

### 표시·정본 영어 목록

정본 `65-codex.lua`의 `PX.num`과 `66-status.lua`의 표시 규칙은 정수 반올림이다. ko/en 상태창은 HP 118, MP 33, Strength 21, Agility 6처럼 표시하며, 동료의 Defend 17.68은 18로 표시한다. 내부 전투 수치는 바꾸지 않았다. 영어 도감 필터는 360폭에서 `Recruited`를 포함한 네 탭 모두 줄바꿈 0이다. 일반 한글 라벨의 ‘추천 1층’을 잘못된 영문 floor template이 삼키는 문제도 숫자 캡처 제한으로 수정했다.

원본 `B.en_dict()` / `B.ui_pack("en")`과 공개 영어 사전을 직접 읽었다. 새 영문 제목은 정본 문구를 배송 display 글꼴로 그린 뒤 윤곽 SVG로 추적하고 기존 dry-brush 결을 적용했다. 기존 한국어 제목 SVG는 수정하지 않았다.

|화면의 제목|처리|
|---|---|
|INTO THE ABYSS|기존 영문 유지|
|장비 보관함|정본 대응 없음 · 유지|
|장비 보관함|정본 대응 없음 · 유지|
|연출 미리보기|정본 대응 없음 · 유지|
|의뢰|정본 대응 없음 · 유지|
|동료 소개|Companion introductions · 새 SVG|
|전술 연구|정본 대응 없음 · 유지|
|마렌토 상회|Marento Trading House · 새 SVG|
|한나의 대장간|Hanna's Smithy · 새 SVG|
|여관|정본 대응 없음 · 유지|
|모험 기록|정본 대응 없음 · 유지|
|토르바로 귀환|정본 대응 없음 · 유지|
|탐색 지도|정본 대응 없음 · 유지|
|봉인된 보관함|정본 대응 없음 · 유지|
|닫힌 휴게실|정본 대응 없음 · 유지|
|토르바로 귀환할까요?|정본 대응 없음 · 유지|

하단의 **마을·원정·기록은 정확한 정본 영문이 없음**을 확인해 유지했다. 동료/가방의 정본 `Ally`/`Bag`와 함께 부분 영어 상태로 남는다. 임의로 Town/Expedition/Journal을 새 번역으로 넣지 않았다. 전체 목록과 native 한국어 관측은 [translation-inventory.json](verification/town-r21/round11/translation-inventory.json)에 있다. 이는 전체 번역률이나 모든 대사의 영문화 완료를 뜻하지 않는다.

### 직접 확인·Web·한계

360×780 / 390×844 / 390×664 / 430×932 / 1280×800의 연락판 5개를 직접 열었다. 360폭 ko/en 능력치, 도감 탭, 준비, 새 영문 제목, 페르소나 장비, 클라우드와 실제 WASM 상태·준비·정산도 확인했다. 새 native UI 검사는 34상태 × 5크기 = 170캡처다. Native PopupMenu는 별도 OS 창이므로 P5 선택 검사는 기존 P6처럼 공개 선택 signal을 사용하고, Web 장비 selector는 실제 포인터로 첫 항목을 선택했다. 물리 휴대폰·스크린리더는 시험하지 않았다.

지정 export와 `tools/update_version.py` 완료: **ui_build=r21-d-town-20261103a**, PCK **65,205,184 bytes**, SHA-256 `a84fb88019cf8d0895f001da35d502371fc6521a09dd040671e6ef3c83f0825c`. `python tools/web_smoke_r19.py --town-r21`의 한국어 6구성과 영어 360폭 1구성 모두 실패 0이며 PCK 해시가 최종 export와 일치한다.

배송 `cloud-r22.json`의 서버 URL·Turnstile 사이트 키는 원래 빈 값이다. 로컬 Worker/D1 시험만 했고 원격 배포·실서비스 Turnstile·운영 CPU/cron은 검증하지 않았다. AI 대화 호스트 기능, `79-sex.lua`와 성적 친밀도 장면·장미 골목/창관·성적 제안은 이식하지 않았다. 원본 봇 전체 기능 동등성이나 시안 픽셀 일치 완료를 주장하지 않는다.

Impeccable 검사 지적은 0이다. 기존 DESIGN.md보다 오래된 디자인 sidecar 진단은 기록만 했으며, 별도 `document` 작업으로 동기화할 수 있다. 자세한 검수 기록은 [visual-review.json](verification/town-r21/round11/visual-review.json)이다.

### 파일·재현

기존 파일 변경:

- `project/data/localization-r22.json`
- `project/game/cloud_store_r22.gd`
- `project/game/facilities_world_r22.gd`
- `project/game/localization_r22.gd`
- `project/game/settings_world_r22.gd`
- `project/tests/ui_expedition_r22_test.gd`
- `project/ui/codex_screen_r22.gd`
- `project/ui/facilities_screen_r22.gd`
- `project/ui/journal_screen_r22.gd`
- `project/ui/panel_screen_r22.gd`
- `project/ui/persona_sortie_screen.gd`
- `project/ui/town_screen_r21.gd`
- `project/ui/world_screen.gd`
- `server/abyss-save/src/validate.js`
- `server/abyss-save/test/integration.mjs`
- `tools/town_r21_round9_web.py`
- `tools/update_version.py`

새 프로젝트 파일(자동 UID/import 제외):

- `project/assets/ui-r21/floor-star.svg`
- `project/assets/ui-r21/title-recruit-en.svg`
- `project/assets/ui-r21/title-shop-en.svg`
- `project/assets/ui-r21/title-smithy-en.svg`
- `project/game/town_chronicle_world_r22.gd`
- `project/tests/town_r21_round11_test.gd`
- `project/tests/ui_town_r21_round11_test.gd`

새 도구는 `tools/town_r21_round11_{source.mjs,titles.py,verify.py,finish.py,report.py}`다. 근거는 `verification/town-r21/round11/`, Web 캡처는 `verification/town-r21/web/`, 서버 결과는 `verification/cloud-r22/`와 round11의 서버 로그에 있다. 이전 실패 진단은 최종 통과 결과와 구별한다. `regression.json`에 57그룹의 종료값·검사 오류·수치를 보관했다. fixture와 읽기 전용 전투 자산 생성기는 실행 대상으로 세지 않았다.

재현 순서: 로컬 시험 서버(`node tools/facilities_r22_local_server.mjs`, 설치된 Miniflare의 `ABYSS_NODE_MODULES` 지정) → `python tools/town_r21_round11_verify.py` → `node server/abyss-save/test/integration.mjs` / `security.mjs` / `turnstile.mjs` → 지정 Web export → `python tools/update_version.py` → `python tools/web_smoke_r19.py --town-r21` → `python tools/town_r21_round11_finish.py` → `python tools/town_r21_round11_report.py`.

서버 기존 테스트에서 바뀐 수치 기대값은 금화의 옛 100,000,000 상한 거부를 안전 정수 초과 거부로 옮긴 한 항목이다(P6의 정본 무상한 재고/금화 계약). P5 native UI 검사의 층 선택 입력은 기존 폼 버튼에서 보존된 준비 화면의 페이지 selector로 바꿨으며 선택 결과 7층은 그대로다. 게임 규칙·전투 수치 기대값 변경은 0이다. 기존 Windows root certificate store 환경 진단은 로그에 남겼고 검사 오류와 분리했다. Git 명령·다른 worktree 쓰기·사용자 저장 삭제·원격 배포는 0이다.

## 10차 — P8 충돌 해결 · 설정 의미 통합 · 정본 영어 적용

8·9차의 준비 화면·초상 편성·원정 경로와 P7/P10 복귀 흐름을 유지하면서 P8 설정·사전·조사를 결합했다. **완전한 영어판은 아니다.** 정본 영어가 없는 native 문구와 그림 안의 한국어는 유지하며, 관측 목록을 갱신했다. 전투 파일의 번역·수정은 하지 않았다.

|항목|최종 결과|
|---|---:|
|충돌 표시|0|
|전체 실행 그룹 / 실패 그룹|49 / 0|
|새 통합 검사 / 실패|218 / 0|
|초기화 통합 보관·수동 복원 표본|11|
|새 영어 native 검사 / 실패|4,055 / 0|
|native 상태·크기·캡처|30 / 5 / 150|
|P8 규칙 검사 / 실패|205,194 / 0|
|P8 설정 등 UI 검사 / 실패·캡처|3,630 / 0 · 95|
|정본 Lua oracle 표본|22,460|
|Web 구성 / 언어 / 오류|7 / ko·en / 0|
|Web 실제 전투 승리|9|
|영어 360폭 native 글자 경계 실패 / Web 관측 넘침|0 / 0|
|보호 파일 / 변경|1,875 / 0|
|원본 자산 / 변경|96 / 0|
|원본 읽기 파일 / 변경|51 / 0|
|배송 UI·문구 사전 키|159 / 2,784|
|부분 한국어 관측 문자열 합집합|195|
|전투 정적 문구 후보 / 별도 구 이름 로그|97 / 1|

### 충돌과 흐름

`create_screen.gd`는 8차의 풍경·한국어 SVG 제목·붓 버튼을 유지한다. 영어 제목에는 정본 `New adventurer` / `First meeting`을 사용하며 우측 설정 버튼과 겹치지 않는다. 선택 붓 버튼은 기존 그림을 P8의 `#c62b15`로 틴트해 작은 흰 글자의 대비 보완도 유지했다. 만들기 단계와 첫 만남 선택은 설정을 다녀와도 그대로다.

`panel_screen_r22.gd` / `journal_screen_r22.gd`는 번역·제목 맞춤을 적용하되 `panels_return` / `journal_return`과 `remember_entry=false`를 유지한다. 마을·동료·가방에서 들어간 경로, 패널 간 이동, 연대기에서 복귀하는 경로가 9차와 같다. `persona_sortie_screen.gd`는 Create 폼으로 되돌리지 않고 Town 상속의 내부 준비 화면으로 남겼다. 전·후열, 초상 한 번씩 표시, 대기 필터, 자기 참전/지휘, 출발 제한, 수락 의뢰와 저장 재시도 위치를 유지한다.

### 설정·이름·저장

P8 난이도는 원본 0.8 / 1 / 1.25와 전투별 고정 배율을 그대로 사용한다. 같은 전투에서 누적 배율이 생기지 않고, 설정 변경은 다음 전투부터 적용되며 snapshot 재로드와 소환/단계 변경 경계까지 기존 P8 규칙 검사를 통과했다. 전투 엔진·적 어댑터를 수정하지 않았다. 공용 `josa_r22`와 `L.u`의 조사·영어 빈 조사도 원본 Lua 전체 음절 대조를 다시 실행했다.

현재 model·P7 cast·대사 이름표는 **힐데가 / 베렌가 / 바르굿**, 영어는 **Hildegard / Berenga / Bargut**이다. P8의 `world.json` 이름 변경은 이미 병합 입력에 있었고 이번에는 그 데이터 파일을 고치지 않았다. 과거 native 이름이 들어 있는 라벨과 연대기 이름 변환에는 표시 단계의 정규화를 추가했다. 저장 원문이나 대사 JSON을 다시 쓰지 않는다.

초기화 보관 구현은 수정할 필요가 없었다. 실제 옛 저장 11개에 8차 성장 충돌 이관과 9차 `favs/panels_r22/chronicle_r22`, 설정을 함께 넣어 복원·v3 저장·두 번째 저장·초기화를 실행했다. 보관 JSON 전체가 연대기 queue를 flush한 당시 메모리와 같고, `persona_migration_r21` 원문·선택 성장값·패널 상태·즐겨찾기·연대기가 모두 있으며, `.disk`와 `.disk.bak`는 초기화 직전 두 세대 바이트와 같다. 보관 JSON을 수동으로 restore해 전체 동등성도 확인했다. 원래 메모리 모델은 변하지 않았다. P8 검사에는 보관 실패 시 초기화 차단도 포함한다. 실제 사용자 프로필은 열지 않았다.

### 영어 적용과 한계

원본 `design/i18n`과 현재 `05-gen.lua`의 `B.en_dict()` / `B.ui_pack("en")`을 Lua 하네스로 읽었다. oracle 도구의 도달 가능 native 대상에 마을을 추가하고 줄바꿈·가운뎃점 조합 필드를 추출한다. 이전 P8 대비 UI 30키·문구 5키가 더해졌으며, 정본 문구를 새로 쓰거나 저장 키를 영어로 바꾸지 않았다. 마을 공용 label/action, 동료 이름·직업·시설·상거래, 준비 화면 층 선택과 탐색·휴식·정산에 도달하는 사전 호출을 연결했다.

검수 중 `{action}{cost}`처럼 변수만 있는 원본 틀이 미등록 한국어를 임의로 분해하는 문제를 발견했다. 직접 `L.u` 호출 계약은 유지하면서 자동 문자열 인식에서는 이런 틀을 제외했다. `개요/원정/기술/마을/추가` 미등록 라벨 보존을 새 회귀 검사로 고정했다. 정본에 없는 단어를 그럴듯한 영어로 만드는 방식은 쓰지 않았다.

관측 목록은 [untranslated.json](verification/settings-r22/untranslated.json) / [untranslated.md](verification/settings-r22/untranslated.md)이다. 195종은 신규 30상태와 P8 19상태에서 한국어를 포함한 문자열의 합집합이다. 기존 72종보다 검토 범위가 넓어졌으므로 번역률의 분모로 쓰지 않는다. 합성 필드 일부만 영어인 문구도 포함한다. `뒤로`, `원정 준비`, `마을 장소`, native 저장 안내, 생성 질문과 기존 2차 대사 등 정본 대응 없는 부분, SVG 안의 한국어는 그대로다. `{{user}} → 당신`도 호스트 이름이 없는 기존 대체다.

전투 정적 후보 97행은 목록만 만들었다. 읽기 전용 `project/game/battle_state.gd:261`의 **“첫 번째 펭귄 · 힐데가르트가 대신 받음”**도 별도 후속 항목이다. 따라서 모든 과거 전투 고정 로그의 이름까지 정리됐다고 주장하지 않는다. 일반 전투 이름표는 P8의 정본 model 이름을 사용한다. 성적 장면·클라우드 서버·A 데이터/규칙·대사 데이터·적·초상은 수정하지 않았다.

### 직접 검수와 Web

영어 native 30상태 × 5크기는 360×780 / 390×844 / 390×664 / 430×932 / 1280×800이다. 마을·동료·기술·장비·시설·P7/P10·만들기·첫 만남 외에 빈/보유 카드, 장비 상점, 탐색, 휴식, 퇴각 확인, 귀환 정산을 포함한다. 기존 metrics의 큰 가용 폭 값에 의존하지 않고 실제 Label/Button의 글꼴 치수·내용 여백·줄바꿈·높이를 별도로 검사했다. 설정·도감 단어가 잘리던 버튼, 마을 층/구역 높이, 대장간 제목 폭을 보완했다. 게임 수치와 기존 검사 기대값은 바꾸지 않았다.

최종 [5크기 연락판](verification/town-r21/round10/contact-360x780.jpg)을 모두 직접 열었고, 실제 WASM의 영어 360폭 마을·준비·만들기, native 설정·초기화 화면을 원본 크기로 열었다. 준비 화면의 시안 구조와 그림은 유지되며 페르소나 초상 없음, 부분 한국어, 좁은 P7 영어 단어 줄바꿈은 남는다. 물리 휴대폰·스크린리더 검증이나 전 화면 번역 완료를 주장하지 않는다. 검수 기록은 `round10/visual-review.json`이다.

지정 Web export와 `tools/update_version.py` 완료. **ui_build=r21-d-town-20261102f**, PCK **65,115,708 bytes**, SHA-256 `673fbd668eaf9ab2573f73c132bc739d926b3de0c5b912fa4c04fd6354521ca0`. 한국어 6구성(5크기와 360 reduced-motion) + 영어 360×780 1구성을 실제 포인터로 실행했다. 만들기 → 첫 만남 → 대화 확정/재로드 → 영입 → 연구/장비 → P7/P10 왕복 → 출전 → 전투 승리 → 레벨업 → 퇴각 정산/재로드를 검증했다. 영어 구성의 마을 13캡처 지점에서 추가 metrics 검사를 통과했다. 모든 구성의 PCK 해시가 최종 export와 일치한다.

별도 IndexedDB fixture에서도 v1·백업 바이트 보존, 불러오기만 할 때 v3 쓰기 없음, 실제 행동 뒤 v3 우선 재로드, Lv17/XP2 선택·Lv25 원문 보관, 9차 확장 보존과 옛 저장 지휘 모드를 확인했다. 원격 배포는 하지 않았다.

### 검사와 파일

전체 실행은 import + 실제 검사/통합/라이선스 47종 + 읽기 전용 balance probe 1종, 합계 49그룹이다. `enemy_action_fixture_r21.gd`는 검사에 사용되는 상속 fixture이며 단독 MainLoop가 아니다. `build_ink_r20b.gd`는 전투 자산을 다시 만드는 생성기라 읽기 전용 전투 범위에 따라 실행하지 않았다. Windows root certificate store 환경 진단은 별도이며 SCRIPT ERROR·검사 실패는 0이다. 테스트 수치·원본 규칙 기대값 변경은 0이다.

|실행|exit|검사 오류|
|---|---:|---:|
|affection_r21_test|0|0|
|art_test|0|0|
|balance_probe|0|0|
|chronicle_r22_test|0|0|
|data_r21_test|0|0|
|dialogue_player_r21_test|0|0|
|dungeon_r21_test|0|0|
|enemy_action_r21_test|0|0|
|enemy_regression_r21_test|0|0|
|enemy_review_r21_test|0|0|
|expansion_test|0|0|
|export_licenses|0|0|
|import|0|0|
|motion_asset_test|0|0|
|motion_r18_integration|0|0|
|motion_r9_integration|0|0|
|motion_test|0|0|
|panels_r22_test|0|0|
|persona_r22_test|0|0|
|persona_research_r21_test|0|0|
|persona_town_r21_round8_test|0|0|
|recruit_r21_test|0|0|
|route_test|0|0|
|settings_r22_test|0|0|
|state_test|0|0|
|town_commerce_r21_test|0|0|
|town_r21_round10_test|0|0|
|town_r21_round9_test|0|0|
|town_r21_test|0|0|
|ui_battle_r17_test|0|0|
|ui_battle_r18_test|0|0|
|ui_battle_r19_test|0|0|
|ui_battle_r20_test|0|0|
|ui_chronicle_r22_test|0|0|
|ui_data_r21_test|0|0|
|ui_dialogue_r21_test|0|0|
|ui_panels_r22_test|0|0|
|ui_persona_r22_test|0|0|
|ui_persona_town_round8_test|0|0|
|ui_settings_r22_test|0|0|
|ui_town_r21_round10_test|0|0|
|ui_town_r21_round2_test|0|0|
|ui_town_r21_round3_test|0|0|
|ui_town_r21_round4_test|0|0|
|ui_town_r21_round5_test|0|0|
|ui_town_r21_round9_test|0|0|
|ui_town_r21_test|0|0|
|ui_town_result_r21_test|0|0|
|world_test|0|0|

변경한 기존 프로젝트 파일:

- `project/data/localization-r22.json`
- `project/game/chronicle_store_r22.gd`
- `project/game/localization_r22.gd`
- `project/ui/create_screen.gd`
- `project/ui/journal_screen_r22.gd`
- `project/ui/panel_screen_r22.gd`
- `project/ui/persona_sortie_screen.gd`
- `project/ui/town_screen_r21.gd`
- `project/ui/world_screen.gd`

추가 검사: `project/tests/{town_r21_round10_test,ui_town_r21_round10_test}.gd`와 UID. 도구 변경: `tools/{settings_r22_oracle.mjs,town_r21_round9_web.py,update_version.py}`. 새 도구: `tools/town_r21_round10_{verify,finish,report}.py`. 부속 결과는 `verification/town-r21/round10/**`, 새 Web 결과는 `verification/town-r21/web/**`, 갱신된 P8 oracle·규칙/UI 로그·미대응 목록은 `verification/settings-r22/**`, export는 `docs/**`다.

재현: `node tools/settings_r22_oracle.mjs`, `python tools/town_r21_round10_verify.py`, 지정 export → `python tools/update_version.py` → `python tools/web_smoke_r19.py --town-r21`, `python tools/town_r21_round10_finish.py`, `python tools/town_r21_round10_report.py`. 보고서의 이전 차수 절은 보존했다. git 명령·다른 worktree 쓰기·클라우드 쓰기는 0이다.

## 9차 — P7·P10 의미 통합 · 전후열 편성·그림 경로

P7 도감·상태·장비 가방과 P10 장소·인물·연대기를 8차 페르소나 흐름에 연결했다. 선택지 대화의 실제 호감 확정 직후 공용 `Chronicle.affection_changed()`를 호출한다. 준비 화면은 **전열/후열을 분리하고 선택한 동료 초상을 한 번씩만** 보여 준다. 원정 진행은 원본의 **탐색 5회 → 휴식 → 층 보스**를 유지하고 기존 그림 3칸으로 표시한다.

|항목|결과|
|---|---:|
|import·공통·기존 r21·P1·round8·P7·P10·새 검사 그룹 / 실패|44 / 0|
|새 의미 통합 검사 / 실패|1,573 / 0|
|실제 선택지 호감 경계 조합|153|
|실제 옛 저장 통합 이관·왕복 표본|11|
|새 native UI 검사 / 실패|7,225 / 0|
|새 native 화면 / 크기|55 / 5|
|Web 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|Web 실제 전투 승리 합계|9|
|IndexedDB 옛 저장·백업 바이트 보존 / v3 우선 재로드|통과 / 통과|
|보호 파일 / 변경|1,155 / 0|
|원본 자산 / 변경|96 / 0|
|원본 Lua·설계·공개 인물 파일 / 변경|118 / 0|
|owner-zoom-9 비교판|1200×677 / 294,954 bytes|
|Web PCK|64,811,296 bytes|

### 의미 통합과 저장

`chronicle_world_r22.gd`의 선택지 진입점이 부모의 선택 확정을 성공한 뒤에만 호감 전후 값을 공용 연대기로 전달한다. 잘못된 선택·하루 제한·반응 재확인·같은 단계 변화에는 기록을 추가하지 않는다. 세 동료 × 17개 경계 값 × 선택지 3개, 합계 153건을 실제 선택지 경로로 실행하고 선택 전/후 JSON 복원, 입력 불변, 상승·하락·무변화와 재실행을 검사했다. 대화 JSON과 2차 대사는 수정하거나 병합하지 않았다.

첫 만남·영입·P1 전투 직후의 레벨업·귀환 정산이 P10 facade를 통과하도록 실행했다. 원본 레벨 경계 직전의 native fixture에서 통제된 실제 전투 승리를 만들고 중첩 경험치 호출에도 레벨업 기록 1개, 퇴각 기록 1개, 반복 정산 추가 기록 0개를 확인했다. 영입 레벨은 성장한 `s.persona`와 같다. 이 native fixture의 공격 능력치 조정은 테스트 입력이며 게임 데이터 변경이 아니다. Web에서는 적·능력치·보상을 바꾸지 않고 실제 전투로 레벨업했다. 기존 P10 검사도 돌파·구역 보스·의뢰·전설 장비·귀환·직접 다음 층과 중복 방지를 다시 확인했다.

실제 옛 저장 11표본 각각을 원문 그대로 복원하고 기존 활동 로그와 소급 기록 없음, 입력 바이트 보존을 확인했다. 같은 표본에 D 충돌 성장 값과 P7 `favs/panels_r22`, P10 `chronicle_r22`를 함께 담아 Lv17/XP2 선택, 원문 Lv25 보관, 반복 이관 불변, 패널 page/bg 복원, 큐 flush와 디스크 왕복까지 확인했다. schema3·`world_v3.json`·백업·옛 `world_v1.json` fallback 정책은 유지한다. 임시 native fixture와 새 Chromium 문맥만 사용했다.

### 진입·뒤로 가기·화면

도감·상태·장비 가방은 들어온 화면으로 돌아간다. 마을 도감 → 상태 → 뒤로는 마을, 동료 도감 상세 → 뒤로는 동료, 가방 장비 → 상태 → 기록 → 뒤로 → 뒤로는 상태 → 가방이다. 뒤로 가기는 새 진입으로 기록하지 않아 순환을 막는다. 장소·인물·연대기 탭도 최초 진입 화면을 유지한다. 하단 탭 이름을 마을·동료·원정·가방·기록으로 통일하고 도감/상태는 동료, 장비 가방은 가방, 장소/인물/연대기는 기록을 활성 표시한다. 새 진입 버튼과 기존 버튼의 겹침을 5크기에서 검사했다. 첫 동료 테이리스의 긴 직업명이 마을에서 잘리던 문제도 이름 아래 별도 줄로 수정했다.

편성 초상은 전열/후열 두 영역으로 나뉘고 선택 해제는 해당 초상을 누른다. 아래 목록에는 대기 동료만 보여 준다. 한 열에 3~4명이 몰리면 그 열만 가로 스크롤하며, 네 번째 초상을 실제 입력으로 해제하는 검사도 포함했다. 필터는 대기 동료만 바꾸므로 선택된 후열도 화면과 해제 입력을 유지한다. 기존 8차 UI 검사 **한 항목**을 이 새 행동에 맞춰 변경했다. 원본 규칙·수치 기대값은 바꾸지 않았다.

경로 그림은 `bg-explore.webp`, `bg-rest.webp`, `bg-departure.webp`의 기존 자산만 사용한다. 시안의 갈림길/집필실/귀환 문구는 게임 규칙으로 가져오지 않았다. 수락 의뢰가 있으면 기존처럼 별도 의뢰 출발 행동을 보여 준다. 하단 원정 활성선은 글자 아래로 내리고 아이콘·라벨도 고정 영역 안에 맞췄다. 저장 실패 재시도와 의뢰 출발은 같은 자리를 동시에 차지하지 않는다.

비교판 [owner-zoom-9.jpg](verification/town-r21/owner-zoom-9.jpg), 5크기 native 연락판 및 주요 원본 크기 화면, 실제 Web 준비 화면을 직접 열었다. 최종 검토는 `round9/visual-review.json`에 기록했다. 남는 차이는 페르소나에 승인 초상이 없어 문자 칸인 점, 새 모드/필터 때문에 시안과 세로 비율이 다른 점, 3칸 그림이 시안 삽화와 다르고 실제 규칙 이름을 쓰는 점이다. 새 그림은 만들지 않았다. P7/P10 읽기 화면의 폼/스크롤 문법과 영어 연대기 본문은 기존 구현/원본 계약을 유지하며 전체 봇 동등성을 뜻하지 않는다.

### 검사·export 근거

|검사|실행 결과|
|---|---|
|import|exit 0|
|world_test|WORLD TESTS: 44 checks, 0 failures|
|state_test|COMBAT CHECKS: 54; FAILURES: 0|
|route_test|ROUTE TESTS: 41 checks, 0 failures|
|expansion_test|EXPANSION CHECKS 3350 FAILURES 0|
|motion_test|MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta|
|motion_asset_test|MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings|
|art_test|PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion|
|export_licenses|Exported Godot and bundled library license notices.|
|town_r21_test|TOWN R21 CHECKS 2675 FAILURES 0 LUA SAMPLES 2544|
|data_r21_test|DATA_R21 checks=7493 failures=0 composition=1028 stats=700 exploration=300|
|dungeon_r21_test|3018 checks / 0 failures|
|enemy_action_r21_test|2878 checks / 0 failures|
|enemy_regression_r21_test|30 checks / 0 failures|
|enemy_review_r21_test|354 checks / 0 failures|
|town_commerce_r21_test|TOWN COMMERCE R21 CHECKS 14714 FAILURES 0 LUA 8520 / 8520|
|persona_research_r21_test|PERSONA RESEARCH R21 CHECKS 13889 FAILURES 0 LUA 13843 / 13843|
|affection_r21_test|AFFECTION R21 CHECKS 400 FAILURES 0 LUA SAMPLES 200|
|dialogue_player_r21_test|DIALOGUE PLAYER R21 CHECKS 5771 FAILURES 0|
|recruit_r21_test|RECRUIT R21 CHECKS 14991 FAILURES 0 LUA 2496|
|persona_r22_test|PERSONA R22 CHECKS 4005 FAILURES 0|
|persona_town_r21_round8_test|PERSONA TOWN ROUND8 CHECKS 1037 FAILURES 0|
|panels_r22_test|PANELS R22 CHECKS 7345 FAILURES 0|
|chronicle_r22_test|CHRONICLE R22 CHECKS 7911 FAILURES 0|
|town_r21_round9_test|TOWN ROUND9 CHECKS 1573 FAILURES 0 DIALOGUE 153 LEGACY 11|
|ui_battle_r17_test|R17 BATTLE UI 6085 CHECKS / 0 FAILURES|
|ui_battle_r18_test|R18: 4592 checks / 0 failures; 30 distinct effect hashes|
|ui_battle_r19_test|R19: 859 checks / 0 failures|
|ui_battle_r20_test|R20: 1659 checks / 0 failures|
|motion_r9_integration|R9 INTEGRATION: 944 checks / 0 failures|
|motion_r18_integration|R18 STATE INTEGRATION: 3540 checks / 0 failures|
|ui_town_r21_test|TOWN UI R21 CHECKS 1646 FAILURES 0 OVERFLOW 0|
|ui_town_r21_round2_test|TOWN ROUND2 UI CHECKS 4458 FAILURES 0|
|ui_data_r21_test|UI_DATA_R21 checks=9608 failures=0 nameplates=3200 overflow=0|
|ui_town_r21_round3_test|TOWN ROUND3 UI CHECKS 8360 FAILURES 0 PORTRAIT SLOTS 300 ENEMY FALLBACKS 0|
|ui_town_result_r21_test|TOWN RESULT R21 CHECKS 235 FAILURES 0|
|ui_town_r21_round4_test|TOWN ROUND4 UI CHECKS 10473 FAILURES 0|
|ui_town_r21_round5_test|TOWN ROUND5 UI CHECKS 2270 FAILURES 0|
|ui_dialogue_r21_test|DIALOGUE UI R21 CHECKS 9078 FAILURES 0|
|ui_persona_r22_test|PERSONA UI R22 CHECKS 1383 FAILURES 0 CAPTURES 60|
|ui_persona_town_round8_test|PERSONA TOWN UI ROUND8 CHECKS 5595 FAILURES 0 CAPTURES 45|
|ui_panels_r22_test|PANELS UI R22 CHECKS 12959 FAILURES 0 CAPTURES 75|
|ui_chronicle_r22_test|CHRONICLE UI R22 CHECKS 3603 FAILURES 0 CAPTURES 75|
|ui_town_r21_round9_test|TOWN UI ROUND9 CHECKS 7225 FAILURES 0 CAPTURES 55|

대화 JSON 검사 오류 0, selftest 58개 실패 0, Impeccable detector `[]`. native·Web 크기는 360×780 / 390×844 / 430×932 / 390×664 / 1280×800이며 Web에는 360폭 reduced-motion을 더했다. 원본 P7·P10 oracle fixture를 현재 병합 코드에서 다시 실행했으며 원본 Lua fixture를 새로 추출한 것은 아니다. Windows root certificate store 진단은 기존 환경 경고로 별도 분류했다. SCRIPT ERROR·기능 검사 실패는 0이다.

지정 명령 `python tools/godot_r17.py --headless --export-release Web ../docs/index.html` 및 `python tools/update_version.py` 완료. **ui_build=r21-d-town-20261102e**, PCK SHA-256 `d8b1c16c13c0c52c9d93ddd350e773cc6856be37418d956fb0436182d5859cef`. Web 6구성 모두 이 PCK 해시와 일치한다. 원격 배포는 하지 않았다.

근거: `verification/town-r21/common-results.json`, `round9/{integration-results,ui-results,indexeddb-results,audit,summary,comparison,visual-review}.json`, `web/results.json` 및 검사 원문 로그. 비교 도구는 `tools/town_r21_round9_compare.py`, Web 흐름은 `tools/town_r21_round9_web.py`다.

전투 파일·A 데이터/규칙·대화 JSON·적/초상·원본 파일 변경 0, 다른 worktree/클라우드 쓰기 0이다. 지시서 내용이 도착하기 전 읽기 전용 `git status`를 한 번 시도했으나 소유권 오류로 실패했다. 금지 규칙을 읽은 뒤 git 명령은 실행하지 않았으며 git 변경 명령은 0이다. 기존 DESIGN.md/sidecar 드리프트는 수정 범위 밖으로 유지했다.

### 변경 파일

- `project/game/chronicle_world_r22.gd`
- `project/tests/ui_persona_town_round8_test.gd`
- `project/ui/journal_screen_r22.gd`
- `project/ui/panel_screen_r22.gd`
- `project/ui/persona_sortie_screen.gd`
- `project/ui/town_screen_r21.gd`
- `project/ui/world_screen.gd`
- `tools/town_r21_verify.py`
- `tools/update_version.py`
- `tools/web_smoke_r19.py`
- `project/tests/town_r21_round9_test.gd`
- `project/tests/town_r21_round9_test.gd.uid`
- `project/tests/ui_town_r21_round9_test.gd`
- `project/tests/ui_town_r21_round9_test.gd.uid`
- `tools/town_r21_round9_compare.py`
- `tools/town_r21_round9_contacts.py`
- `tools/town_r21_round9_report.py`
- `tools/town_r21_round9_web.py`

추가 산출물: `verification/town-r21/round9/**`, 검사·캡처·Web 결과, `owner-zoom-9.jpg`, `docs/**`, 이 보고서.

## 8차 — P1 페르소나 의미 통합 · 원정 준비·만들기·첫 만남

P1의 `s.persona`를 실제 게임의 단일 성장 상태로 연결했다. 영입은 같은 레벨을 읽고, 전투 직후/정산은 `award_persona_exp()`를 사용한다. 준비 화면은 기존 시안의 폐허·종이·초상 열을 복구하고 그 안에 자기 참전/지휘와 동료 3/4명 제한을 배치했다. **시안과 완전히 같다는 판정은 아니다.** 새 만들기·첫 만남에는 개별 승인 시안이 없어 기존 마을 문법을 적용했다.

|항목|최종 수치|
|---|---:|
|공통·기존·P1·신규 Godot 검사 그룹 / 실패|38 / 0|
|P1 규칙·저장 검사 / 실패|4,005 / 0|
|P1 native UI 검사 / 실패|1,383 / 0|
|신규 의미 통합·이관 검사 / 실패|1,037 / 0|
|신규 native 화면 검사 / 실패|7,065 / 0|
|신규 화면 캡처 / 크기|45 / 5|
|Web 새 시작 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|실제 Web 전투 승리 합계|10|
|IndexedDB 옛 저장·백업 보존 및 v3 우선 재로드|1 / 통과|
|보호 파일 / 변경|1,106 / 0|
|원본 자산 / 변경|96 / 0|
|직접 연 비교 4쌍|1200×1342 / 296,038 bytes|
|Web PCK|64,281,468 bytes|

### 단일 성장 상태와 이관 근거

원본 `74-level.lua:2–5, 22–28, 89–125`는 페르소나 한 명의 lv/exp, 출전자 전량, 미출전 페르소나 50% 내림, 비출전 동료 0, 정산 키 중복 방지를 규정한다. `72-guild.lua`의 영입도 그 페르소나 레벨을 사용한다. 원본에 native 두 필드의 충돌 이관 규칙은 없다. 따라서 값을 합산하거나 최댓값을 고르지 않고, 이전 코드의 **실제 갱신 주체**를 근거로 다음 정책을 적용했다.

- schema 1·2: 7차 `town_world_r21.settle()`이 갱신하던 `persona_progress_r21`을 가져온다. 함께 있는 `persona`는 이 코드에서 갱신하지 않던 원본 이관 값이므로 레벨·XP만 성장 기록으로 교체하고 나머지 필드는 보존한다.
- schema 3: P1이 실제 갱신하는 `s.persona`를 유지한다. 7차 상속 코드의 성장 기록은 같은 원정의 두 번째 지급 경로였으므로 더하지 않는다.
- 양쪽 원문과 선택 근거는 `persona_migration_r21`에 보존하고 기존 이름이 있으면 `_`를 덧붙인다. 활성 `persona_progress_r21`은 없앤다. 재로드는 다시 이관하지 않는다. 원본 곡선보다 넘친 XP는 기존 `exp_settle` 방식으로 정리하며 이전 값도 `experience_before_r22`에 보존한다.

40개 레벨 × 반대쪽 레벨 3개에서 양방향 충돌·원문 보존·입력 불변·반복 복원을 검사했다. schema3의 작은 레벨이 이기는 경우도 포함한다. JSON이 schema를 float로 읽으면 배열 멤버십으로 정수 schema를 고르는 판정이 달라지는 버그도 찾아 숫자 동등 비교로 고쳤고, 120개 옛 저장의 JSON 왕복을 추가했다. 진행 중 옛 원정에는 페르소나 편성 스냅샷이 없으므로 동료만 출전한 원정으로 이어 받고, 귀환 때 원본의 미출전 50%를 지급한다. P1 원정은 전투 때 지급한 XP를 귀환에서 다시 주지 않는다. 기존 schema1/2 모델은 옛 저장 검증용 호환 경로로 남고, 실제 월드는 항상 P1 schema3이다.

첫 만남 호감 0 → 여관 선택/반응·하루 제한 → 영입 → 편성 → 출전 → 승리 → 정산 → 레벨업과 그 뒤 영입 레벨을 연결했다. native 의미 검사는 통제된 전투 입력을 사용하며, Web 6구성은 능력치·적·보상 변경 없이 실제 포인터 전투로 Lv.2 이상까지 진행했다. 기본 보너스 20점·직업 추천 배분은 원본의 선택 범위다.

### 저장 파일과 IndexedDB

기존 `world_v1.json`/`.bak` 읽기 전용 fallback과 새 `world_v3.json`/`.bak` 쓰기를 유지했다. 실제 사용자 프로필은 열지 않았고, native fixture 경로와 임시 Chromium 문맥만 사용했다. Web에서 schema2 성장 Lv.17/XP2와 원본 이관 값 Lv.25/XP3을 함께 심은 fixture를 로드해 **17/2**를 확인했다. 불러오기만 해서는 v3 파일이 생기지 않았고 v1·백업 바이트도 그대로였다. 실제 여관 대화로 저장한 뒤 v3가 생성됐고, 재로드는 그 선택 전 대화를 복원하므로 v3 우선순위도 확인했다. 근거: `round8/indexeddb-results.json`.

P1의 기존 저장 보존 검사는 필드 삭제를 허용하도록 느슨하게 바꾸지 않았다. 활성 성장 기록의 위치가 바뀌는 한 항목만 새 보존 위치를 검사하도록 갱신했다. JSON 숫자의 int/float 표현은 값으로 대조한다. 원본 Lua 수식·게임 수치 기대값은 바꾸지 않았다. 기존 `ui_persona_r22_test`는 Create 상속 화면만 폼 치수를 검사하므로 준비 화면이 Town 상속으로 바뀐 뒤 1,383개로 줄었다. 새 UI 검사는 준비 화면의 실제 글자 치수·겹침·뷰포트·44px 터치·원정 연결을 별도로 검사한다.

### 화면·실제 검수와 차이

`persona_sortie_screen.gd`는 폼 상속을 제거하고 기존 `town_screen_r21`의 종이·폐허·배경·초상·버밀리언 버튼·하단 이동을 사용한다. 4칸 중 첫 칸이 자기 참전 페르소나이며, 지휘에서는 동료 4명이다. 빈 칸·전열 없음·보유 동료 정렬/필터·최대 인원·빈 출발 차단·페르소나 단독 출발·수락 의뢰의 별도 출발을 유지했다. 390×664에서도 새 주요 버튼의 실측 높이는 44px 이상이다. 후보가 많으면 해당 영역만 스크롤한다. 생성 클래스 정보가 없는 옛 저장은 자기 참전을 막고 이유를 표시하며 기존 지휘·4인 파티를 유지한다. 직업을 임의로 채우거나 옛 동료를 다시 생성하지 않는다. 이 저장에 새로 생성 정보를 지정하는 편집 흐름은 이번 범위에 넣지 않았다.

만들기 5단계는 기존 글꼴의 SVG 윤곽 제목, 수묵 마을 배경, 종이, 선택/진행의 버밀리언을 쓴다. SVG는 기존 글꼴에서 생성한 것이며 승인 시안 글자를 추적한 것이라고 주장하지 않는다. 첫 만남은 선택한 동료의 기존 `detail-overview` 초상을 크게 놓고 원문 장면을 스크롤로 읽는다. 준비 화면 초상도 기존 `party-tall`/`formation-face` 칸의 배치·크롭만 조절했고 새 초상은 그리지 않았다.

[owner-zoom-8.jpg](verification/town-r21/owner-zoom-8.jpg)의 4쌍과 실제 WASM 360폭 준비 화면을 직접 열었다. 원정 준비는 `03-preparation-0`과 자기 참전/지휘를 비교했다. 만들기·첫 만남은 개별 시안이 없으므로 비교판에 “개별 시안 없음, 마을/길드 문법 참고”라고 표시했다. 확대 합본의 초상 크기를 보고 기존 슬롯의 표시 크롭을 보완한 뒤 다시 열었다. 시안 속 Lv.20/금화/2층 숫자를 복제하지 않고 실제 상태를 쓴다.

남는 외형 차이는 준비 화면에 새 모드 전환·후보 목록이 들어가 원래의 전열/후열 얼굴 줄과 경로 삽화 대신 필터·후보·짧은 경로 안내를 쓰는 점, 페르소나가 초상 없는 문자 칸인 점, 제목이 기존 r21 글꼴 윤곽인 점이다. 새 초상 생성·전투 파일 수정으로 이 차이를 숨기지 않았다. 독립 페르소나의 종족/직업 특성·장비/고유기술 전체 동등성 등 P1 후속 묶음은 이번 검증 범위가 아니다. 기존 카드 정본 없음·나머지 대화 콘텐츠 부족도 이 차수에서 추가 구현하지 않았다.

### 검사·export 근거

|검사|결과|
|---|---|
|world_test|WORLD TESTS: 44 checks, 0 failures|
|state_test|COMBAT CHECKS: 54; FAILURES: 0|
|route_test|ROUTE TESTS: 41 checks, 0 failures|
|expansion_test|EXPANSION CHECKS 3350 FAILURES 0|
|motion_test|MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta|
|motion_asset_test|MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings|
|art_test|PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion|
|export_licenses|Exported Godot and bundled library license notices.|
|town_r21_test|TOWN R21 CHECKS 2675 FAILURES 0 LUA SAMPLES 2544|
|data_r21_test|DATA_R21 checks=7493 failures=0 composition=1028 stats=700 exploration=300|
|dungeon_r21_test|3018 checks / 0 failures|
|enemy_action_r21_test|2878 checks / 0 failures|
|enemy_regression_r21_test|30 checks / 0 failures|
|enemy_review_r21_test|354 checks / 0 failures|
|town_commerce_r21_test|TOWN COMMERCE R21 CHECKS 14714 FAILURES 0 LUA 8520 / 8520|
|persona_research_r21_test|PERSONA RESEARCH R21 CHECKS 13889 FAILURES 0 LUA 13843 / 13843|
|affection_r21_test|AFFECTION R21 CHECKS 400 FAILURES 0 LUA SAMPLES 200|
|dialogue_player_r21_test|DIALOGUE PLAYER R21 CHECKS 5771 FAILURES 0|
|recruit_r21_test|RECRUIT R21 CHECKS 14991 FAILURES 0 LUA 2496|
|ui_battle_r17_test|R17 BATTLE UI 6085 CHECKS / 0 FAILURES|
|ui_battle_r18_test|R18: 4592 checks / 0 failures; 30 distinct effect hashes|
|ui_battle_r19_test|R19: 859 checks / 0 failures|
|ui_battle_r20_test|R20: 1659 checks / 0 failures|
|motion_r9_integration|R9 INTEGRATION: 944 checks / 0 failures|
|motion_r18_integration|R18 STATE INTEGRATION: 3540 checks / 0 failures|
|ui_town_r21_test|TOWN UI R21 CHECKS 1553 FAILURES 0 OVERFLOW 0|
|ui_town_r21_round2_test|TOWN ROUND2 UI CHECKS 4404 FAILURES 0|
|ui_data_r21_test|UI_DATA_R21 checks=9608 failures=0 nameplates=3200 overflow=0|
|ui_town_r21_round3_test|TOWN ROUND3 UI CHECKS 8205 FAILURES 0 PORTRAIT SLOTS 300 ENEMY FALLBACKS 0|
|ui_town_result_r21_test|TOWN RESULT R21 CHECKS 235 FAILURES 0|
|ui_town_r21_round4_test|TOWN ROUND4 UI CHECKS 10213 FAILURES 0|
|ui_town_r21_round5_test|TOWN ROUND5 UI CHECKS 2270 FAILURES 0|
|ui_dialogue_r21_test|DIALOGUE UI R21 CHECKS 9078 FAILURES 0|
|persona_r22_test|PERSONA R22 CHECKS 4005 FAILURES 0|
|persona_town_r21_round8_test|PERSONA TOWN ROUND8 CHECKS 1037 FAILURES 0|
|ui_persona_r22_test|PERSONA UI R22 CHECKS 1383 FAILURES 0 CAPTURES 60|
|ui_persona_town_round8_test|PERSONA TOWN UI ROUND8 CHECKS 7065 FAILURES 0 CAPTURES 45|
|import|exit 0|

대화 JSON 검사 오류 0, selftest 58개 실패 0, impeccable detector `[]`를 확인했다. 기존 Windows root certificate store 진단은 환경 경고로 별도 기록했다. 5크기는 360×780·390×844·430×932·390×664·1280×800이며 360폭 reduced-motion을 더해 Web 6구성이다. 모든 구성에서 선택/반응 재로드, 첫 동료 0, 영입 레벨, 모드 전환, 빈 편성 차단, 전투 승리·레벨업, 귀환 XP 중복 없음, 정산 재로드, 전투 후 뷰포트 복원을 검사했다. 상점 스크롤 검사는 실제 조상 ScrollContainer의 표시 범위를 읽고 실제 휠로 이동한다.

요청한 `godot_r17.py --headless --export-release Web ../docs/index.html` 및 `update_version.py` 실행 완료. `ui_build=r21-d-town-20261102d`, PCK SHA-256 `65be77a8a9bed274380e61c4063923f7f76a9518b7bbf9229a17b0b45f516f65`. 원격 배포는 하지 않았다. 결과는 `verification/town-r21/common-results.json`, `web/results.json`, `round8/{integration-results,ui-results,indexeddb-results,audit,comparison}.json`과 원문 로그에 있다.

전투·A 데이터/규칙·대화 JSON·기존 적/초상·원본 Lua 96파일은 변경하지 않았다. 사용자 저장 삭제/덮어쓰기, git 명령, 다른 worktree 쓰기, 외부 메시지, 성적 장면 이식은 하지 않았다. 기존 DESIGN.md와 `.impeccable/design.json`의 메타데이터 드리프트는 남겨 두었다.

### 변경 파일

- `project/game/persona_save_adapter.gd`
- `project/game/persona_world.gd`
- `project/game/town_world_r21.gd`
- `project/tests/persona_r22_test.gd`
- `project/ui/create_screen.gd`
- `project/ui/persona_sortie_screen.gd`
- `project/ui/town_screen_r21.gd`
- `project/ui/world_screen.gd`
- `tools/town_r21_verify.py`
- `tools/update_version.py`
- `tools/web_smoke_r19.py`
- `project/assets/ui-r21/title-create.svg`
- `project/assets/ui-r21/title-meeting.svg`
- `project/tests/persona_town_r21_round8_test.gd`
- `project/tests/persona_town_r21_round8_test.gd.uid`
- `project/tests/ui_persona_town_round8_test.gd`
- `project/tests/ui_persona_town_round8_test.gd.uid`
- `tools/town_r21_round8_assets.py`
- `tools/town_r21_round8_compare.py`
- `tools/town_r21_round8_report.py`
- `tools/town_r21_round8_web.py`

추가 산출물: `verification/town-r21/round8/**`, 검사 결과·native/Web 캡처, `owner-zoom-8.jpg`, `docs/**`, 이 보고서.

## 6차 — 선택지 대화·호감 훅·원본 영입 (7차 지시)

**선택지 재생기·호감 훅·영입 주선은 연결하고 검사했다. 카드 사건은 현재 정본에 규칙이 없어 이식 완료로 세지 않는다.** 원본의 HTML 정보 패널을 뜻하는 `*_card`와 기존 웹 시제품의 소모성 카드를 구분했다. 카드 정본 감사까지 마친 뒤 영입으로 진행했다.

|항목|이번 결과|
|---|---:|
|공통·기존·신규 Godot 검사 그룹 / 실패|34 / 0|
|대화·호감 실행 검사 / 실패|5,771 / 0|
|새 UI 검사 / 실패·넘침|9,078 / 0·0|
|영입 검사 / 실패|14,991 / 0|
|원본 Lua 여관·파티·NPC 표본|768 + 70 + 5|
|원본 Lua 영입 결과 대조|2,496 / 2,496|
|원본 카드 감사 / 탐색 실행|96파일 / 8,000회|
|Web 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|보호 파일 / 변경|1,109 / 0|
|원본 자산 / 변경|96 / 0|
|직접 연 대화 4장 합본|1440×810 / 260,485 bytes|
|최종 PCK|64,156,908 bytes|

### 선택지 대화와 호감

`dialogue_player_r21.gd`가 읽기 전용 JSON을 ID별로 불러온다. 현재 8단계의 장면 중 본 횟수가 가장 적은 것을 먼저 고르며, 전부 본 뒤에는 `seen` 도입과 기존 선택지를 쓴다. 여관의 실제 대화 버튼 → 3개 선택지 → 반응 → 실제 호감 변화 → 단계 변화 장면 → 여관 복귀를 연결했다. 선택지의 aff는 기존 talk +1을 **대체**한다. 원본 `inn()` API는 콘텐츠 없는 동료의 기존 +1 경로로 유지하며, UI는 `begin_dialogue()`를 사용한다.

선택을 마칠 때만 하루 제한과 본 장면 횟수를 확정한다. 고르기 전 취소는 비용·호감·하루 제한을 소모하지 않는다. 재시작하면 선택 전 장면 또는 결제 완료 반응을 복원하며 같은 선택을 두 번 지급하지 않는다. 장면 선택·짧은 말 변형은 게임 RNG를 소비하지 않는다. -100~200, 100 초과 양수 몫 ×0.4, 원본 반올림·8단계·여러 경계를 건널 때 최종 도착 경계 한 장면을 적용했다. 없는 동료 파일은 기존 동작으로 돌아간다.

여관 식사·숙박은 도로테아 +1, 대화·선물은 도로테아 변화 없음이다. 상점 구매는 피에트로, 의뢰 수락·영입은 페넬라, 가공·강화는 한나의 성공한 행동에 +1을 준다. NPC 행동 호감은 100에서 멈추고 이미 100을 넘는 값은 줄이지 않는다. 동료 여관 행동은 하루 제한·비용·숙박 날짜를 원본대로 유지한다. 원정에서는 정산 한 번에 승리×1 + 보스3, 의뢰2를 반영하고 솔렌 성왕국 3명 편성의 ×1.2도 원본 `aff_party/tx_aff`와 대조했다. 패배는 동료 호감을 주지 않는다.

출발·층 진입·발견·전투 시작·승리·보스 전/후·아군 위기·자신의 부상·쓰러짐·휴식·보관함·귀환·패배의 14상황을 연결했다. 전투 저장 스냅샷은 읽어서 위기/쓰러짐을 한 전투·동료마다 한 번만 기록한다. 전투 시작 전과 결과 확인 후의 별도 대사 화면에서 읽으며 전투 화면 파일은 바꾸지 않았다. 진행 중 전투를 재로드하면 전투부터 복원하고, 대기 대사는 전투 밖에서 이어 본다. 보관함은 기존 옛 지도 경로에만 존재하며 새 원정 사건으로 만들지 않았다.

### 카드 정본 감사 — 규칙 없음

`bot/src`와 `design`의 현재 96개 Lua/JSON/Markdown 파일을 UTF-8로 검색하고 SHA를 기록했다. `77-explore.lua`의 원본 `ex_roll`을 Wasmoon으로 8,000회 실행한 결과는 battle 4,952 / elite 619 / coin 1,209 / item 854 / equip 366이다. `head_card`, `last_card`, `party_card`, `gear_card`는 HTML 정보 패널 함수다. 검색된 “봉인 해제”는 적의 기술이며 소모성 카드가 아니다. `76-dungeon.lua`, `77-explore.lua`, `78-battle-item.lua`와 원본 마을 하네스에 웹판 `key/camp` 카드 지급·보관함 해제 규칙은 없다.

따라서 카드 지급 확률·사용 효과·보유 상한·정산 규칙을 새로 정하지 않았다. 기존 웹 시제품의 `key/camp`와 사용자 저장의 손패는 보존했다. 원본 Git 이력이나 별도 옛 버전은 조사하지 않았으므로 “과거에도 없었다”는 뜻은 아니다. 근거는 `round7/card-audit.json`, 재현 도구는 `tools/town_r21_card_audit.mjs`다. 이 항목은 **정본 규칙 없음 / 추가 이식 없음**으로 인계한다.

### 영입 주선과 저장 이관

`72-guild.lua`의 `CAST_ORDER` 후보 순서, 미영입자 필터, 비용 100+20×횟수, `floor(G_rnd×후보수)` 한 번을 그대로 사용한다. 게시판과 같은 `town_r21.counter`를 공유하므로 의뢰 갱신 사이에 영입해도 다음 난수 번호가 이어진다. 전원 보유·돈 부족·원정 중에는 돈·명단·카운터가 바뀌지 않는다. 새 동료는 즉시 소유 목록에 추가하고 aff/XP를 0으로, 합류 레벨은 페르소나 기준으로 정한다. 8개 seed × 4개 시작 RNG 번호 × 3개 레벨 × 26명 = 2,496결과를 원본 meet 핸들러와 대조했다.

이 게임에는 독립 페르소나 전투 주체가 아직 없으므로 `persona_progress_r21`에 **비출전 성장 기록만** 추가했다. 원본 `persona.lv/exp`가 저장에 있으면 이관하고, 없으면 원본 기본값 Lv.1/XP0이다. 파티 최고 레벨을 대신 쓰지 않는다. 이후 원정 정산 시 원본의 비출전 XP `floor(total/2)`와 레벨 비용을 적용한다. 독립 페르소나 전투·행동·클래스 구현 완료로 세지 않는다. 이미 진행한 과거 원정의 누락 경험치를 추정하여 소급하지 않는다.

schema2·사용자 저장 경로는 유지한다. `dialogue_r21`, `npc_aff_r21`, `persona_progress_r21`만 추가하고, 없는 옛 저장은 기본 상태로 이관한다. schema1의 날짜·손패·행동 기록과 schema2의 진행 중 전투·연구 draft를 보존하는 검사, 선택 전/후 JSON roundtrip, 입력 저장 불변, 불량 상태의 원자적 거절을 포함한다. 테스트는 전용 fixture 경로와 임시 브라우저 문맥만 사용했다. 사용자 저장을 삭제·덮어쓰지 않았다. 이미 웹 RNG로 결정된 옛 영입을 다시 뽑거나 과거 RNG 사용 이력을 추정하지 않는다. 저장된 마을 카운터 다음부터 원본 순서를 적용한다.

### 실제 렌더와 Web

360×780·390×844·430×932·390×664·1280×800에서 새 흐름을 검사했다. 세 동료의 84장면 전체와 선택지 252개는 360·430 양끝 폭에서 모두 실제 렌더 치수를 검사했고, 단계·반응·포인터·전투 전 대사 확인도 검사했다. 새 선택지는 기준 높이 58이며 검사 크기에서 실제 클릭 높이 44px 이상이다.

힐데가·마르셀린·테이리스 선택지 및 힐데가 19→21 단계 변화 4장 합본 [owner-zoom-6.jpg](verification/town-r21/owner-zoom-6.jpg)를 직접 열었다. 배경에 묻히던 이름/호감 표시는 종이색 면으로 보완한 뒤 다시 열었다. 실제 WASM 360폭 선택지 화면도 직접 열었다. 원본 대사 이름 힐데가와 기존 게임 표시명 힐데가르트 차이는 데이터 읽기 전용 조건대로 유지했다. 이 검수는 기존 마을 전체 시안의 미완성 부분까지 해결했다는 뜻은 아니다.

요청 명령으로 로컬 Web export 후 `update_version.py`를 실행했다. `ui_build=r21-d-town-20261102c`, PCK SHA-256 `19ffc365942b2f54b030c070fd79eedbc02992deec5661d3538106846cbce8bf`. 원격 배포는 하지 않았다. `web_smoke_r19.py --town-r21` 6구성이 실제 포인터로 대화 선택·반응 저장·재로드·하루 제한, 기존 상점/연구, 자연 전투 승리·결과 확인·뷰포트 복원을 통과했다. 결과는 `verification/town-r21/web/results.json`, export 로그는 `round7/export.log`다.

### 검사와 보호 경계

|검사|최종 결과|
|---|---|
|world_test|WORLD TESTS: 44 checks, 0 failures|
|state_test|COMBAT CHECKS: 54; FAILURES: 0|
|route_test|ROUTE TESTS: 41 checks, 0 failures|
|expansion_test|EXPANSION CHECKS 3350 FAILURES 0|
|motion_test|MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta|
|motion_asset_test|MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings|
|art_test|PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion|
|export_licenses|Exported Godot and bundled library license notices.|
|data_r21_test|DATA_R21 checks=7493 failures=0 composition=1028 stats=700 exploration=300|
|dungeon_r21_test|3018 checks / 0 failures|
|enemy_action_r21_test|2878 checks / 0 failures|
|enemy_regression_r21_test|30 checks / 0 failures|
|enemy_review_r21_test|354 checks / 0 failures|
|ui_battle_r17_test|R17 BATTLE UI 6085 CHECKS / 0 FAILURES|
|ui_battle_r18_test|R18: 4592 checks / 0 failures; 30 distinct effect hashes|
|ui_battle_r19_test|R19: 859 checks / 0 failures|
|ui_battle_r20_test|R20: 1659 checks / 0 failures|
|motion_r9_integration|R9 INTEGRATION: 944 checks / 0 failures|
|motion_r18_integration|R18 STATE INTEGRATION: 3540 checks / 0 failures|
|ui_town_r21_test|TOWN UI R21 CHECKS 1553 FAILURES 0 OVERFLOW 0|
|ui_town_result_r21_test|TOWN RESULT R21 CHECKS 235 FAILURES 0|
|ui_town_r21_round4_test|TOWN ROUND4 UI CHECKS 10213 FAILURES 0|
|ui_town_r21_round5_test|TOWN ROUND5 UI CHECKS 2270 FAILURES 0|
|import|exit 0|
|ui_town_r21_round2_test|TOWN ROUND2 UI CHECKS 4404 FAILURES 0|
|ui_data_r21_test|UI_DATA_R21 checks=9608 failures=0 nameplates=3200 overflow=0|
|ui_town_r21_round3_test|TOWN ROUND3 UI CHECKS 8205 FAILURES 0 PORTRAIT SLOTS 300 ENEMY FALLBACKS 0|
|town_r21_test|TOWN R21 CHECKS 2675 FAILURES 0 LUA SAMPLES 2544|
|town_commerce_r21_test|TOWN COMMERCE R21 CHECKS 14714 FAILURES 0 LUA 8520 / 8520|
|persona_research_r21_test|PERSONA RESEARCH R21 CHECKS 13889 FAILURES 0 LUA 13843 / 13843|
|affection_r21_test|AFFECTION R21 CHECKS 400 FAILURES 0 LUA SAMPLES 200|
|recruit_r21_test|RECRUIT R21 CHECKS 14991 FAILURES 0 LUA 2496|
|ui_dialogue_r21_test|DIALOGUE UI R21 CHECKS 9078 FAILURES 0|
|dialogue_player_r21_test|DIALOGUE PLAYER R21 CHECKS 5771 FAILURES 0|

`dialogue_r21_check.py` 오류 0, `dialogue_r21_selftest.py` 58검사 실패 0, impeccable detector `[]`도 확인했다. Godot의 기존 Windows root certificate store 오류는 각 원문 로그와 common-results의 환경 경고 필드에 따로 남겼다. 이를 기능 검사 실패에 섞거나 숨기지 않았다.

기존 round2/3/4 UI 검사는 새 대사의 “계속”을 실제로 누른 뒤 종전 화면을 검사하도록 보완했다. 게임 수치 기대값은 바꾸지 않았고, 웹 빌드 식별자 기대값만 c로 갱신했다. 구형 DungeonWorld를 주입한 화면에도 대화 상태가 없으면 기존 동작을 유지하도록 고쳤다. 원본 Lua 수식/결과 기대값은 변경하지 않았다. 보호 파일 SHA·변경 목록은 `round7/audit.json`이다.

성적 장면·79-sex 행동·AI 생성은 이식하지 않았다. 79 파일에서는 비성적 NPC 호감 함수만 원본 대조용으로 읽었다. 전투/A 데이터/초상/적/대화 JSON 쓰기, 다른 worktree 쓰기, git 명령, 외부 메시지 송신을 하지 않았다. 독립 페르소나 전투 전체, 정본이 확인되지 않은 카드 사건, 나머지 동료의 미작성 콘텐츠, 이전 보고서의 전체 시안 차이는 남는다. 기존 DESIGN.md와 .impeccable/design.json의 메타데이터 드리프트도 유지되며 별도 `document` 작업으로 정리할 수 있다.

### 변경 파일

- `project/game/town_world_r21.gd`
- `project/tests/ui_town_r21_round2_test.gd`
- `project/tests/ui_town_r21_round3_test.gd`
- `project/tests/ui_town_r21_round4_test.gd`
- `project/ui/town_screen_r21.gd`
- `project/ui/world_screen.gd`
- `tools/town_r21_verify.py`
- `tools/update_version.py`
- `tools/web_smoke_r19.py`
- `project/game/dialogue_player_r21.gd`
- `project/game/dialogue_player_r21.gd.uid`
- `project/tests/dialogue_player_r21_test.gd`
- `project/tests/dialogue_player_r21_test.gd.uid`
- `project/tests/recruit_r21_test.gd`
- `project/tests/recruit_r21_test.gd.uid`
- `project/tests/ui_dialogue_r21_test.gd`
- `project/tests/ui_dialogue_r21_test.gd.uid`
- `tools/town_r21_card_audit.mjs`
- `tools/town_r21_hooks_oracle.mjs`
- `tools/town_r21_recruit_oracle.mjs`
- `tools/town_r21_round7_report.py`

추가 산출물: `verification/town-r21/round7/**`, 공통/기존 검사 재생성 결과, `owner-zoom-6.jpg`, `docs/**`, 본 보고서.

## 이전 6차 — 호감 단계 판정 부분 인계

**미완료.** 원본 `74-affection.lua`의 8단계 경계를 `town_rules_r21.gd`에 추가하고 여관 동료 카드에 단계와 호감 수치를 표시했다. 기존 호감 증감 함수는 변경하지 않았다. 원본 Wasmoon 하네스에서 수정 없는 Lua 함수를 실행해 200개 입력의 단계·증감 400항목을 대조했고 실패 0이다. 입력에는 음수 경계, 100 감속 경계, 200 상한과 소수 반올림이 포함된다. 원본 SHA 및 표본은 `verification/town-r21/round6/affection-{provenance,oracle}.json`에 있다.

기존 여관 행동의 비용·날짜·호감 계산은 5차 이전에 구현된 범위다. 이번 변경은 저장 형식을 바꾸지 않는다. 360×780과 430×932 기본 호감 0의 실제 여관 렌더를 직접 열어 단계 표시를 확인했다. 다른 단계 및 새 대화 화면의 실제 렌더는 확인하지 않았다. Godot 캔버스라 HTML 요소 검사기로 내부 텍스트를 측정하지 못한다.

### 남은 일

- 카드 사건의 지급·사용·보유·정산과 원본 RNG 전체.
- 영입 주선 원본 난수 순서와 페르소나 기준 합류 레벨.
- 여관 NPC 호감 및 전투·보스·의뢰의 원본 호감 훅 대조와 연결.
- 대화 JSON 재생, 3개 선택지·반응·기록·단계 변화, 던전 짧은 말과 대화 없는 동료의 대체 동작.
- 요청한 세 동료의 실제 대화 화면 4장과 `owner-zoom-6.jpg`: 대화 재생이 없어 생성하지 않았다.

### 변경 파일 및 검증

- `project/game/town_rules_r21.gd`, `project/ui/town_screen_r21.gd`: 단계 판정·표시.
- `tools/town_r21_affection_oracle.mjs`, `project/tests/affection_r21_test.gd`: 원본 대조와 검사.
- `project/ui/world_screen.gd`, `tools/update_version.py`, `tools/web_smoke_r19.py`: 요청한 빌드 식별자.
- `verification/town-r21/round6/**`, Web export `docs/**`, 이 보고서.

새 검사 `AFFECTION R21 CHECKS 400 FAILURES 0 LUA SAMPLES 200`. `dialogue_r21_check.py` 오류 0, `dialogue_r21_selftest.py` 58검사 실패 0. Web 로컬 export 식별자 `r21-d-town-20261102b`, PCK SHA-256 `b67ccc519f695f4b0c6b09805199cd09f29ceba6ba835d1d917deb3aebfe091f`. 원격 배포는 하지 않았다. 실행 중 Windows root certificate store 경고가 발생했다.

공통·기존 r21 검사는 import 포함 30그룹 모두 종료 코드 0·검출 실패 0이다. 여기에는 `persona_research_r21_test` 13,886검사와 `ui_town_r21_round5_test` 2,270검사가 포함된다. 결과·로그는 `verification/town-r21/common-results.json`과 같은 디렉터리의 검사별 로그에 있다. 기존 기대값은 변경하지 않았다. `tools/web_smoke_r19.py --town-r21`은 390×844, 360×780, 360×780 reduced-motion, 390×664, 1280×800, 430×932에서 6/6 통과했다. 기록은 `verification/town-r21/web/results.json`이다. 이 통과는 미구현 대화·카드 기능의 검증을 뜻하지 않는다.

## 5차 — 결과 문구 복구·원본 연구 편집 규칙 부분 이식

**부분 인계다.** 패배 문구 잘림과 승리 부제 중복/가림을 고쳤고, 원본 연구의 마을 편집·강화·저장 규칙을 기존 동료별 전술 슬롯에 연결했다. 원본의 독립 페르소나 전투 주체와 전투 실행 전체를 이식한 것은 아니다. 카드 사건 전체, 영입 원본 난수 순서, NPC 호감 훅은 이번 차수에서 구현하지 않았다. 지시서의 “범위가 너무 크면 위 순서대로 하고, 끝낸 데까지 검사 통과 상태로 멈추고 남은 것을 적어라”에 따라 이 범위에서 검사 실패 0인 상태로 인계한다.

### 핵심 수치

|항목|5차 최종|
|---|---:|
|공통·추가 검사 그룹 / 실패|30 / 0|
|새 연구 규칙 검사 / 실패|13,886 / 0|
|새 원본 Lua 대조 / 일치|13,843 / 13,843|
|표본 구성|정제 7 + 비용 12 + 조합/단계 7,744 + 행동 전이 6,080|
|새 연구 UI 검사 / 실패|2,270 / 0|
|결과 UI 검사 / 실패|235 / 0|
|Web 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|원본 자산 SHA / 변경|96 / 0|
|전투·A 데이터·적·C 산출물 변경|0|
|owner-zoom-5.jpg|1200×1342 / 299,499 bytes|
|최종 PCK / 착수 실물 대비|63,966,212 / +10,468 bytes|

### 결과 화면

`town_result_r21.gd`에서 결과 문구를 불투명 종이 영역 위의 실제 Label로 분리했다. 패배 “부상으로 전투에서 이탈했습니다.” 전체가 보이며, 승리 “적을 모두 쓰러뜨렸습니다.”와 “전투 승리 · …”는 서로 다른 줄에 있다. 승리 제목 SVG에 섞였던 기울어진 한글 부제 조각은 원본 시안에서 그 영역만 제외해 벡터로 다시 추적했다. 원본 시안·배경 그림은 수정하지 않았다. 제외 다각형·SHA·추적 허용치는 `round5/title-provenance.json`에 있다.

360×780·390×844의 승리/패배 4쌍을 [owner-zoom-5.jpg](verification/town-r21/owner-zoom-5.jpg)로 직접 열었고, 나머지 3크기는 native 실제 결과 시험으로 검사했다. 전체 시안 일치는 아니다. 파티 포즈·폐허 구조·HP/MP 칸·제목의 기울기/마모 차이는 그대로 남는다. 종이 문구 영역은 시안보다 각이 지며 승리 상세 한 줄 때문에 더 높다. 전투 파일은 읽기만 했고 기존 결과 확인/중복 보상 방지 핸들러를 유지했다.

### 연구: 실제 구현 범위와 원본 대비 차이

정본은 읽기 전용 `C:/Clauede Code/dungeon-bot/bot/src/29-persona-skill.lua`, 난수/공용 보조를 포함한 `01-game.lua`, `design/persona_skill.json`이다. 기존 프로젝트 `persona_skill.json`과 원본은 공백/줄바꿈 바이트가 다르지만 JSON 의미는 같다. 이 데이터 파일은 변경하지 않았다.

새 `persona_research_r21.gd`는 접두 8종·접미 8종의 호환, 비정상 입력 정제, 0~10단계, 단계별 이름·한/영 설명·스킬 메타데이터, 임시 조합, 변경 감지, 강화 즉시 지출, 저장 전 기존 장착 유지, 준비 완료 시 저장 확정을 구현한다. 접두를 바꿔 호환이 깨지면 접미가 비워지며 다른 조각의 강화 단계는 남는다. 비용은 **다음 단계 n에 대해 40+20×n²**이므로 첫 강화는 60금화다. 옛 동료 전술 관리의 강화 단축 경로도 이 비용을 사용하도록 고쳤다. 기존 expansion_world의 예전 규칙/검사 기대값은 손대지 않았다.

마을의 전술 연구 → “조각 조합 · 편집 후 저장”으로 열며, 기존 동료 전술 관리도 유지했다. 새 편집기는 동료별로 draft·지출액을 저장하고 저장 버튼을 눌러야 기존 전술 슬롯에 반영한다. 저장된 슬롯은 기존 battle_data/tactic 경로로 전달되는 것을 검사했다. native에서 5크기로 실제 강화/저장 포인터·조합 선택 이벤트·재로드를 검사했고, Web에서도 키보드로 실제 드롭다운을 선택하고 실제 포인터로 강화·확정했다. [시안과 편집/저장 상태 비교](verification/town-r21/compare-round5/research-review.jpg)를 직접 열었다. 합성 카드 삽화와 원본 손을 든 자세는 재현하지 않았다.

**원본과 다른 연결 경계:** 원본은 `G.persona.skill` 한 개이고 이 게임은 기존 `s.research[동료]` 30슬롯이다. 이 구조를 독립 사용자 페르소나로 바꾸지는 않았다. 원본 `B.PRUN.persona`·라운드 훅·클래스 속성 실행은 이번 새 시험의 검증 범위가 아니다. 기존 battle_v3의 전술 실행을 그대로 쓴다. 기존 전술의 즉시 장착/해제 단축 경로도 호환용으로 남으므로 원본의 전체 UI 흐름과 동일하다고 세지 않는다. 원본 길드 나가기의 미저장 변경 차단도 적용하지 않았고, 임시 작업은 화면을 나가도 저장에 남는다. AI 장면, pending 대화 생성/송신과 성적 장면은 제외했다. 정본의 busy 저장 거절은 순수 규칙에서 표본 대조했지만 게임은 AI 대화 대기 상태를 만들지 않는다.

### 원본 하네스와 저장 호환

`tools/town_r21_persona_oracle.mjs`가 기존 Wasmoon `lua_sim.mjs` 위에서 원본 Lua 함수를 수정 없이 실행한다. AI/외부 송신을 막기 위해 `pend_busy`만 fixture 값으로, `pend_hard`만 로컬 no-op으로 대체했다. 저장 메시지까지 원본과 대조하지만 게임에는 “보내기” 대화 버튼을 추가하지 않았다. Lua 빈 테이블이 JSON에서 빈 배열로 나오는 차이만 시험에서 빈 사전으로 정규화하고, 숫자 정수/실수의 저장 표현은 값으로 비교한다. 원본 계산 기대값은 변경하지 않았다. 표본·SHA·대체 경계는 `round5/persona-oracle.json`·`persona-provenance.json`·`persona-results.json`에 있다.

schema2·사용자 저장 경로를 유지하고 `research_editor_r21`만 추가했다. 없으면 빈 사전으로 이관한다. 입력 저장 불변, 기존 모든 필드 보존, 결제한 임시 단계의 JSON roundtrip, 진행 중 원정과 draft 동시 복원, 불량 지출/단계/소유자 원자적 거절, 돈 부족/원정 중 행동 거절을 검사했다. 테스트는 격리 엔진의 fixture 파일과 임시 Web 브라우저 문맥만 썼고, 사용자 저장을 삭제·덮어쓰거나 초기화하지 않았다.

### 남은 작업 — 이식 완료로 세지 않음

1. 페르소나 전술 **전체**: 독립 사용자 페르소나 주체와 원본 전투 실행/라운드 훅을 연결해야 한다. 금지된 전투 파일을 이번 작업에서 고치지 않았다.
2. 카드 사건 전체: 원본 `76-dungeon.lua`·`77-explore.lua`·`78-battle-item.lua`의 사건/획득/사용/RNG를 A 원정에 연결하는 작업과 Lua 대조 시험이 남았다. 기존 key/camp·옛 봉인 보관함만 유지한다.
3. 영입 원본 RNG: `72-guild.lua`의 `gd_candidates`/`gd_rnd`/주선 순서와 `74-level.lua`의 페르소나 기준 합류 레벨은 미이식. 기존 웹 RNG/파티 최고 레벨을 유지한다. 비용/미영입 중 1명/중복 없음만 종전 수준이다.
4. NPC 호감: `73-inn.lua`·`74-affection.lua`·시설별 `npc_like` 훅을 새로 이식하거나 표본 시험하지 않았다. 기존 동료 여관 호감 규칙만 유지한다. 79-sex.lua·성적 친밀도 장면·AI 대사는 제외다.

### 직접 실행한 검사

|검사|결과 원문|실패|
|---|---|---:|
|import|exit 0|0|
|world_test|WORLD TESTS: 44 checks, 0 failures|0|
|state_test|COMBAT CHECKS: 54; FAILURES: 0|0|
|route_test|ROUTE TESTS: 41 checks, 0 failures|0|
|expansion_test|EXPANSION CHECKS 3350 FAILURES 0|0|
|motion_test|MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta|0|
|motion_asset_test|MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings|0|
|art_test|PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion|0|
|export_licenses|Exported Godot and bundled library license notices.|0|
|town_r21_test|TOWN R21 CHECKS 2675 FAILURES 0 LUA SAMPLES 2544|0|
|data_r21_test|DATA_R21 checks=7493 failures=0 composition=1028 stats=700 exploration=300|0|
|dungeon_r21_test|DUNGEON_R21 {"art_fallbacks":0,"checks":3018,"details":[],"enemies":100,"failures":0,"floors":420,"outcomes":{"defeat":420,"natural_defeat":53,"natural_victory":141,"victory":420}}|0|
|enemy_action_r21_test|ENEMY_ACTION_R21 {"checks":2878,"continuous_matched":1221,"enemies":100,"failures":0,"gear_samples":120,"matched":1221,"samples":1221,"silence_samples":200}|0|
|enemy_regression_r21_test|ENEMY_REGRESSION_R21 {"checks":30,"failures":[]}|0|
|enemy_review_r21_test|ENEMY_REVIEW_R21 {"checks":148,"evidence":{"initial_target":"neutral_0","loaded_target":"neutral_1","saved_target":"neutral_1","turn_count":3},"failures":[]}|0|
|town_commerce_r21_test|TOWN COMMERCE R21 CHECKS 14714 FAILURES 0 LUA 8520 / 8520|0|
|persona_research_r21_test|PERSONA RESEARCH R21 CHECKS 13886 FAILURES 0 LUA 13843 / 13843|0|
|ui_battle_r17_test|R17 BATTLE UI 6085 CHECKS / 0 FAILURES|0|
|ui_battle_r18_test|R18: 4592 checks / 0 failures; 30 distinct effect hashes|0|
|ui_battle_r19_test|R19: 859 checks / 0 failures|0|
|ui_battle_r20_test|R20: 1659 checks / 0 failures|0|
|motion_r9_integration|R9 INTEGRATION: 944 checks / 0 failures|0|
|motion_r18_integration|R18 STATE INTEGRATION: 3540 checks / 0 failures|0|
|ui_town_r21_test|TOWN UI R21 CHECKS 1553 FAILURES 0 OVERFLOW 0|0|
|ui_town_r21_round2_test|TOWN ROUND2 UI CHECKS 4394 FAILURES 0|0|
|ui_data_r21_test|UI_DATA_R21 checks=9608 failures=0 nameplates=3200 overflow=0|0|
|ui_town_r21_round3_test|TOWN ROUND3 UI CHECKS 8185 FAILURES 0 PORTRAIT SLOTS 300 ENEMY FALLBACKS 0|0|
|ui_town_result_r21_test|TOWN RESULT R21 CHECKS 235 FAILURES 0|0|
|ui_town_r21_round4_test|TOWN ROUND4 UI CHECKS 10188 FAILURES 0|0|
|ui_town_r21_round5_test|TOWN ROUND5 UI CHECKS 2270 FAILURES 0|0|

각 실행 종료 코드 0·스크립트 오류 0. 격리 Windows의 기존 root certificate store 경고만 분리했고 원문 로그를 보존했다. 이번 차수는 기존 공통 검사 기대값을 바꾸지 않았다. 결과 UI 검사는 완전 문구, 종이 영역 포함 관계, 그리기 순서, 승리 두 줄 비중첩을 추가했다. Web build 식별자 기대값만 요청된 날짜로 바꿨다.

### Web와 산출물

`python tools/godot_r17.py --headless --export-release Web ../docs/index.html` 후 `python tools/update_version.py` 실행. `ui_build=r21-d-town-20261102`, PCK SHA-256 `85ffdff802a0a033b9146d63506662144344716b6fb6cba2105df59898820c9a`. 시작 PCK 63,955,744 bytes → 최종 63,966,212 bytes. `round5/export.log`에 내보내기 원문이 있다. 로컬 export이며 원격 배포는 하지 않았다.

`tools/web_smoke_r19.py --town-r21`은 390×844·360×780·390×664·1280×800·430×932와 360×780 reduced-motion에서 실행했다. 전부 새 연구 확정, 기존 상점/장비/시설/고유기, 자연 승리 결과와 viewport 복귀를 통과했다. `web/results.json` 및 `round5/web-results.json`에 6구성·오류 0이 기록됐다. 변경 화면은 canvas이므로 DOM/CSS inspector로 내부 레이아웃을 측정할 수 없다. native Label/Control 실제 치수 검사와 WASM 포인터 검사로 대체했고, impeccable 기계 검출 결과는 `[]`였다. 시각 합격을 자동 검사 수치로 대신하지 않았다.

### 변경 파일

- `project/assets/ui-r21/title-victory.svg`
- `project/game/town_world_r21.gd`
- `project/tests/ui_town_result_r21_test.gd`
- `project/ui/town_result_r21.gd`
- `project/ui/town_screen_r21.gd`
- `project/ui/world_screen.gd`
- `tools/town_r21_verify.py`
- `tools/update_version.py`
- `tools/web_smoke_r19.py`
- `project/game/persona_research_r21.gd`
- `project/game/persona_research_r21.gd.uid`
- `project/tests/persona_research_r21_test.gd`
- `project/tests/persona_research_r21_test.gd.uid`
- `project/tests/ui_town_r21_round5_test.gd`
- `project/tests/ui_town_r21_round5_test.gd.uid`
- `tools/town_r21_persona_oracle.mjs`
- `tools/town_r21_round5_compare.py`
- `tools/town_r21_round5_export.py`
- `tools/town_r21_round5_report.py`
- `tools/town_r21_round5_titles.py`
- `tools/town_r21_round5_baseline.py (착수 SHA 캡처 전에 생성)`

추가 산출물: `verification/town-r21/round5/**`, `compare-round5/**`, `owner-zoom-5.jpg`, `docs/**`, 본 보고서. `round5/audit.json`은 착수 직전 SHA와 최종 파일을 Git 없이 비교한다. 원본 자산 96개와 전투/A/B/C 보호 파일 변경은 0이다. 모든 쓰기는 본 worktree 안에서 수행했고 git 명령·다른 worktree 쓰기·외부 메시지 송신은 하지 않았다.

기존 DESIGN.md와 .impeccable/design.json의 드리프트는 여전히 남는다. 요청 범위 밖 문서를 고치지 않았으며 필요하면 별도 document 작업으로 갱신할 수 있다.


## 4차 — 큰 제목·배경·노드 지도 적용, 시안 전패널 일치 미완료

27개 마을/결과/외곽 패널에 시안형 외형을 연결하고, 금지된 전투 컷인 1패널은 유지했다. 기존 화면이던 연구와 봉인 보관함도 외형을 교체했다. 고정 제목 SVG 18종, image_gen 배경 편집 19종, 실제 원본 진행만 표시하는 노드 지도를 적용했다. **28쌍을 직접 비교했으며, 초상 포즈·크롭·패널 비율·배경 세부 형태가 여전히 다르다. 전패널 동일·시안 느낌 완성으로 보고하지 않는다.** 지시서의 “다 못 끝내면 끝낸 데까지 검사 통과 상태” 조항에 따른 부분 인계다.

### 핵심 수치

|항목|4차 최종|
|---|---:|
|외형 적용 / 기존 전투 유지|27 / 1 패널|
|직접 연 시안-게임 비교|28쌍|
|고정 제목 SVG / 배경 WebP|18 / 19|
|배경 파일 합계 / 실제 PCK 기여|1,914,116 / 1,938,948 bytes|
|배경 제한|10,000,000 bytes 이하|
|공통·추가 검사 그룹 / 실패|27 / 0|
|마을 UI 검사 / 실패|24,335 / 0|
|마을 규칙 / Lua 대조|17,389 / 11,064 일치|
|Web 구성 / 다른 크기 / 오류|6 / 5 / 0|
|원본 SHA / 변경|96 / 0|
|금지된 전투·A·B·C 파일 변경|0|
|최종 PCK|63,955,744 bytes|
|owner-sheet|900×3531 / 388,821 bytes|

### 적용과 보존 경계

고정 제목은 승인 패널의 검정/빨강 획을 OpenCV 윤곽으로 추적한 순수 SVG 경로다. 로고 THE의 E는 시안 인물에 가려져 있어 기하 벡터로 보완했으며 원본 보이는 픽셀과 동일하다고 세지 않았다. 가변 동료·던전·층 제목은 전투의 기존 AbyssDisplayR19를 크게 사용하고 폭을 맞췄다. 큰 검정 가변 활자 위에는 시안에서 추적한 작은 종이색 마모 SVG를 얹었다. 장식 붓 띠 7종·카드 그림·버튼도 SVG다. 생산용 래스터 제목/독립 잉크 파일은 추가하지 않았다.

풍경은 해당 시안의 영역을 image_gen 내장 편집 도구에 넣고 인물·문자·UI를 지운 뒤 같은 건축을 메우도록 요청했다. 초기 편집본의 붉은 그래픽 띠/군중은 추가 편집으로 제거하고 그래픽 띠는 별도 SVG로 배치했다. 원본 인물·적 도트는 생성 도구에 다시 그리도록 요청하지 않았다. 배경의 원본 가려진 부분을 메우면서 비가림 부분의 세부 구조·종이 마모도 재해석된 곳이 있다. 따라서 “그 부분만 변경·풍경 픽셀 그대로”는 미달이다. 홈/동료 상세에는 공용 도시 배경을 사용해 시안의 성채 위치와 다르다. 원본 배경·편집본·프롬프트·SHA·크롭은 `round4/asset-provenance.json`, `imagegen-files.json`, `background-pack.json`, `accent-provenance.json`에 기록했다. 최종 배경은 `project/assets/ui-r21/bg-*.webp` 19장이다.

연구는 기존 전술 선택/장착/해제/강화 핸들러와 저장 형식을 그대로 사용한다. 원본 페르소나 연구 전체 규칙으로 확장하지 않았다. 봉인 보관함은 옛 지도 저장의 봉인 해제/지나가기/이동을 새 외형에 연결했다. 새 A 원정에서 보관함 사건이나 카드 지급을 추가하지 않았다. 원본 초상 및 C 마스터/300칸, B 적 100종과 전투·A 데이터 파일은 바이트 변경 0이다. 결과의 4인·편성은 기존 CharacterSprite의 준비 도트를 재사용하고 패배 결과만 표시 셰이더로 회색화했다. 사용자 저장 경로·schema·진행 규칙을 바꾸지 않았다. UI 시험은 전용 fixture 경로만 사용한다. 성적 장면/79-sex.lua는 실행·이식하지 않았다.

### 탐색 지도가 시안과 달라야 하는 이유

읽기 전용으로 원본 `C:/Clauede Code/dungeon-bot/bot/src/77-explore.lua`, A의 `dungeon_world_r21.gd`·`dungeon_view_r21.gd`를 대조했다. 원본은 층마다 5회 순차 탐색→자동 휴식→층 보스이며, 시안의 서가/순찰로/보관함/회랑/야영지 갈림길을 선택하는 규칙은 없다. 새 `town_map_r21.gd`는 입구+실제 5탐색+휴식+보스의 8표지만 단일 선으로 연결한다. 완료 길과 현재 위치를 강조하고 미래 탐색은 일반 나침반으로 표시한다. 미래 전투/발견을 미리 결정하거나 새 선택 버튼을 만들지 않았다. 지도 구성은 상태·RNG를 바꾸지 않는지 0~5단계 모두 검사했다.

### PCK 전후와 웹

작업 시작 docs PCK 실측은 53,240,156 bytes다. 3차 보고서의 61,934,348 bytes와 일치하지 않는 오래된 export였으므로 둘을 섞지 않았다. 최종 63,955,744 bytes, 시작 실물 대비 +10,715,588, 3차 보고 수치 대비 +2,021,396 bytes다. 초기 무손실 가져오기는 71,517,648 bytes였고, 새 배경 19장만 Godot Lossy/0.85로 가져와 용량을 줄였다.
동일 최종 코드에서 배경 19장만 제외한 측정용 PCK는 62,016,796 bytes다. 최종과의 차이 1,938,948 bytes가 실제 배경 패킹 증가분이며 10MB 이하다. `budget-no-background`는 실행용이 아닌 용량 측정용 불완전 export다. 최종 실행본은 docs이다. 필터는 측정 후 원래 바이트로 복원했다. `round4/export-sizes.json`과 export 로그에 근거를 보존했다.
최종 `ui_build=r21-d-town-20261101b`, PCK SHA-256 `727baf6ea15b9d814b7914d8614e5067700fb67b6aa5ea74f254d30770ce61f6`. `python tools/godot_r17.py --headless --export-release Web ../docs/index.html` 후 `python tools/update_version.py`로 갱신했다. 원격 배포는 하지 않았다.
`tools/web_smoke_r19.py --town-r21`을 390×844, 360×780, 390×664, 1280×800, 430×932 및 360×780 reduced-motion에서 실행했다. 실제 포인터로 기본 마을·시설·연구·영입 경로·원본 장비 구매/품절/장착·연출·실제 전투·결과 확인·viewport 복귀를 검사했다. 6/6 통과, 콘솔/페이지/텍스트 오류 0. 결과는 `verification/town-r21/web/results.json`이다.

### 직접 실행한 검사

|검사|최종 결과|
|---|---|
|world_test|WORLD TESTS: 44 checks, 0 failures · exit 0 / errors 0|
|state_test|COMBAT CHECKS: 54; FAILURES: 0 · exit 0 / errors 0|
|route_test|ROUTE TESTS: 41 checks, 0 failures · exit 0 / errors 0|
|expansion_test|EXPANSION CHECKS 3350 FAILURES 0 · exit 0 / errors 0|
|motion_test|MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta · exit 0 / errors 0|
|motion_asset_test|MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings · exit 0 / errors 0|
|art_test|PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion · exit 0 / errors 0|
|export_licenses|Exported Godot and bundled library license notices. · exit 0 / errors 0|
|town_r21_test|TOWN R21 CHECKS 2675 FAILURES 0 LUA SAMPLES 2544 · exit 0 / errors 0|
|data_r21_test|DATA_R21 checks=7493 failures=0 composition=1028 stats=700 exploration=300 · exit 0 / errors 0|
|dungeon_r21_test|DUNGEON_R21 {"art_fallbacks":0,"checks":3016,"details":[],"enemies":100,"failures":0,"floors":420,"outcomes":{"defeat":420,"natural_defeat":53,"natural_victory":140,"victory":420}} · exit 0 / errors 0|
|enemy_action_r21_test|ENEMY_ACTION_R21 {"checks":2762,"continuous_matched":1221,"enemies":100,"failures":0,"gear_samples":120,"matched":1221,"samples":1221,"silence_samples":200} · exit 0 / errors 0|
|enemy_regression_r21_test|ENEMY_REGRESSION_R21 {"checks":30,"failures":[]} · exit 0 / errors 0|
|town_commerce_r21_test|TOWN COMMERCE R21 CHECKS 14714 FAILURES 0 LUA 8520 / 8520 · exit 0 / errors 0|
|ui_battle_r17_test|R17 BATTLE UI 6085 CHECKS / 0 FAILURES · exit 0 / errors 0|
|ui_battle_r19_test|R19: 859 checks / 0 failures · exit 0 / errors 0|
|ui_battle_r20_test|R20: 1659 checks / 0 failures · exit 0 / errors 0|
|motion_r9_integration|R9 INTEGRATION: 944 checks / 0 failures · exit 0 / errors 0|
|motion_r18_integration|R18 STATE INTEGRATION: 3540 checks / 0 failures · exit 0 / errors 0|
|ui_town_r21_round2_test|TOWN ROUND2 UI CHECKS 4379 FAILURES 0 · exit 0 / errors 0|
|ui_data_r21_test|UI_DATA_R21 checks=9608 failures=0 nameplates=3200 overflow=0 · exit 0 / errors 0|
|ui_battle_r18_test|R18: 4592 checks / 0 failures; 30 distinct effect hashes · exit 0 / errors 0|
|ui_town_r21_test|TOWN UI R21 CHECKS 1553 FAILURES 0 OVERFLOW 0 · exit 0 / errors 0|
|import| · exit 0 / errors 0|
|ui_town_r21_round3_test|TOWN ROUND3 UI CHECKS 8185 FAILURES 0 PORTRAIT SLOTS 300 ENEMY FALLBACKS 0 · exit 0 / errors 0|
|ui_town_result_r21_test|TOWN RESULT R21 CHECKS 190 FAILURES 0 · exit 0 / errors 0|
|ui_town_r21_round4_test|TOWN ROUND4 UI CHECKS 10028 FAILURES 0 · exit 0 / errors 0|

r18 UI는 첫 실행에서 검사 4,592개 실패 0이었지만 종료 리소스 오류 1개/객체 경고 2개가 발생했다. 같은 검사 단독 재실행은 4,592개 실패 0·종료 오류 0으로 재현되지 않았다. 이를 숨기거나 오류 필터를 완화하지 않았고 `round4/r18-initial-exit-note.json`에 적었다. root certificate store 경고만 기존 격리 환경 경고로 계속 분리한다. 기존 검사 기대값은 변경하지 않았다. 공개 build 식별자 검사만 새 b 문자열로 갱신했다. Label을 SVG로 옮겨 기존 UI의 글자 검사 수가 줄었으며 시각 합격으로 해석하지 않는다.

### 직접 연 비교와 남은 작업

[28패널 제목·배경·구성·초상 같음/다름 표](verification/town-r21/compare-round4/comparison.md). `review-1..7.jpg`를 최종 가져오기 후 모두 직접 열었다. [전체 시트](verification/town-r21/owner-sheet.jpg)와 확대 비교 [1](verification/town-r21/owner-zoom-1.jpg) · [2](verification/town-r21/owner-zoom-2.jpg) · [3](verification/town-r21/owner-zoom-3.jpg)도 확인했다. 기계 수치로 같음을 대신하지 않았다.

남은 외형은 동료 콜라주의 큰 얼굴/사선/명패, 상세·기술의 성채 배경, 편성의 투시 프레임과 하단 상세, 장비/대장간의 전용 장비 그림, 연구의 합성 카드 그림과 결과 띠, 기록의 사건별 삽화 타임라인, 정산/귀환의 4인 뒷모습, 휴게실의 앉은 포즈, 빈 상태의 하단 정물, 컷인과 결과의 정확한 인물 구도다. 배경 재해석과 제목 가림 흔적·소수 픽셀 잔흔, 버튼 질감 차이도 남는다. 원본에 없는 자세를 새로 그리거나 전투 파일을 수정해 해결하지 않았다. 정본 규칙에 따른 지도 단일 진행과 실제 이름/레벨/재고/보상 차이는 유지해야 한다. 3차의 원본 페르소나 연구/영입 RNG/카드 사건 전체/연대기 미이식도 그대로 남는다.

디자인 검수는 design-taste-frontend의 직접 비교/수정 절차를 적용했으며 사용자가 정한 B 시안이 방향이므로 새 방향 추첨은 하지 않았다. Godot canvas 대상이라 DOM/CSS 검사기 대신 native 5크기와 실제 WASM 포인터 검사를 사용했다. 시각 자평은 10점 중 제목 7·배경 6·구성 5·초상 구도 4다. 이 점수는 사장님 승인이 아니다.

### 변경 파일

- project/ui/town_art_r21.gd
- project/ui/town_result_r21.gd
- project/ui/town_screen_r21.gd
- project/ui/world_screen.gd
- tools/town_r21_verify.py
- tools/update_version.py
- tools/web_smoke_r19.py
- project/tests/ui_town_r21_round4_test.gd
- project/ui/town_map_r21.gd
- tools/town_r21_round4_accents.py
- tools/town_r21_round4_audit.py
- tools/town_r21_round4_compare.py
- tools/town_r21_round4_export.py
- tools/town_r21_round4_finish_assets.py
- tools/town_r21_round4_report.py
- project/assets/ui-r21/title-*.svg (18종), accent-*.svg (7종), card-*.svg, button-ink.svg, type-drybrush.svg
- project/assets/ui-r21/bg-*.webp 및 .import (19종, 새 배경만 Lossy/0.85)
- verification/town-r21/round4/**, compare-round4/**, owner-sheet.jpg, owner-zoom-1..3.jpg
- docs/** (최종 local Web export)

모든 프로젝트 쓰기는 현재 worktree 안에서 했고 git 명령·다른 갈래 쓰기·원격 배포·타인에게 메시지 송신은 하지 않았다. 내장 image_gen의 기본 저장 위치 결과는 원래 위치에 남기고 최종 프로젝트 자산은 이 worktree에 저장했다.

## 이전 차수 기록

# UI-R21-D

## 3차 — 검증 통과 부분 인계 · 시안 전패널 일치 미완료

시안형 화면 **25 / 28패널**을 기본 동선에 연결했다(기존 기본6 + 미리보기8 활성화 + 추가11). 전투 컷인 1패널은 기존 r18~20을 유지했다. **연구·봉인 보관함 2패널은 기존 UI**이며, 원본 페르소나 연구/영입 레벨·영입 RNG·카드 사건 전체 이식은 남았다. 시안형 25개도 그림 비율·배경·질감 차이가 남아 있고 전패널 동일이나 2px 일치로 승인하지 않는다. 지시서의 부분 인계 조항에 따라 검사 실패 0인 상태로 인계한다.

### 핵심 수치

|항목|3차 최종|
|---|---:|
|시안형 기본 동선 / 전체|25 / 28|
|원본 Lua 대조|11064 / 11064|
|마을 규칙 검사 / 실패|17389 / 0|
|마을 UI 검사 / 실패|14718 / 0|
|공통·추가 검사 그룹 / 실패|26 / 0|
|적 그림 / 대체|100 / 0|
|C 초상 / 동일 RGBA 칸|30명 / 300칸|
|PCK / 2차 대비 증가|61,934,348 / +8,694,192 bytes|
|Web 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|owner-sheet.jpg|900×3531, 389,435 bytes|
|원본 SHA / 변경|96 / 0|
|금지된 전투·A/B/C 원본 파일 변경|0|

### 웹 용량·C 칸·B 적 연결

이전 docs PCK는 53,240,156 bytes, A/B/C 합류 파일을 필터 없이 다시 내보낸 PCK는 106,570,612 bytes였다. 최종 61,934,348 bytes로 무필터 대비 44,636,264 bytes 줄었고, 이전판 대비 증가 8,694,192 bytes는 15,000,000 제한 이하다. 전후 로그와 SHA는 round3/export-sizes.json·export-before.log·export-after.log에 있다.
`pack_portrait_slots_r21.py`는 C의 576×768 마스터 30장을 같은 크기의 무손실 WebP로 바꾸고, 300칸을 C가 기록한 원본 좌표의 AtlasTexture로 묶는다. 투명 RGB까지 포함한 마스터 RGBA와 300칸의 RGBA·크기를 원본 PNG와 직접 대조했다. 바뀐 픽셀 0. 원본 PNG는 그대로 보존한다. WebP 30장 합계 7,156,102 bytes. export 필터로 중복 PNG 칸 300장·마스터 30장을 제외하고 실제 UI에서 사용하는 10종×30명 AtlasTexture만 내보낸다. 내보내기 로그에 Atlas 300개, 원본 슬롯 PNG 0개를 검사한다.
`town_portrait_r21.gd`는 이 C 크롭 Atlas를 최우선으로 선택한다. native에서 30명×10칸을 전부 로드하고 원본 해상도를 검사했다. A의 art_for는 100종 모두 B의 실제 파일을 반환하며 fallback 0이다. Web 기본 진입에서도 C Atlas와 B 그림을 사용한다.

### 원본 규칙과 저장 이관

추가 oracle은 현재 원본 01-game/71-shop/81-gear/82-smithy/74-level.lua를 Wasmoon으로 직접 실행했다. 상점 480표본(10직업×3부위×4일×4씨앗), 가공 1,200표본(1~40레벨), 강화 660표본, 옵션 6,180표본(장비 1,030종×2씨앗×3레벨) = 8,520 / 8,520 일치. 원본 Lua와 입력·출력·SHA·호스트 대체 범위는 round3/commerce-oracle.json·commerce-provenance.json·commerce-results.json이다. 기존 2,544표본도 다시 검사했다.
상점은 계정 씨앗·날짜별 고정 진열/원본 40bit 코드/착용 레벨 제한/할인 반올림/당일 품절을 적용한다. 직업 선택 UI는 보유 동료 기준이며 원본의 모든 10직업 직접 선택 메뉴는 남았다(순수 진열 함수는 10직업 모두 대조). 가공은 보유 동료 직업 풀과 최고 레벨 구간, 계정 씨앗·회차로 정한다. 강화는 코드 해시·시도 수·다음 단계로 원본과 같이 정한다. 재로드로 결과를 재추첨할 수 없다. 돈/용량 부족·중복 구매는 원자적으로 거절한다.
저장 schema2와 기존 파일 경로를 유지했다. 추가 commerce_r21(process_n,sold_day,bought)은 옛 저장에서 결정적으로 초기화한다. 새 상점/가공 장비에만 source_r21=true를 추가해 원본 옵션 계산을 적용한다. **기존 장비·A의 기존 장비 드롭은 이전 옵션 계산을 유지**해 저장을 불러왔을 때 능력치가 바뀌지 않는다. 이 예외는 원본 완전 일치로 세지 않는다. 기존 장비 인스턴스·장착·rng·보유량·진행 중 전투를 보존하고 입력 불변/이관/roundtrip/불량 저장 원자적 거절/재로드 결정론을 검사했다. 사용자 저장 초기화·삭제·덮어쓰기 없음, UI 시험은 fixture 경로에만 쓴다.
여관과 길드 의뢰·정산은 앞선 원본 대조를 다시 통과했다. 성적 콘텐츠(79-sex.lua, 친밀도 장면, 매혹 비약)·AI 대화·NPC 장면 송신은 옮기거나 실행하지 않았다. 상점/대장간 NPC 호감 부가 훅은 미이식이다. 현재 게임에 페르소나 데이터가 없어 가공 기준은 실제 보유 동료만 사용하며, 원본 oracle도 페르소나 직업 없음/레벨1 입력으로 맞춰 비교했다. 영입은 여전히 기존 웹 RNG와 파티 최고 레벨이다.

### UI와 전투 경계

홈·동료·탐색·휴식·카드·빈 상태는 기본 URL에서 열린다. URL 미리보기 플래그를 읽는 코드를 제거했고, 옛 공개 지표 town_r21_preview는 호환용 false만 남겼다. 5내비의 원정은 진행 중 원정을 계속한다. 콜라주 기하 경계와 명패/글자 회전을 함께 보정했다.
상회·길드 접수/소개·여관·장비·대장간·귀환 확인·연출 외곽을 새 UI에 연결했다. 전투 결과는 world_screen 외곽의 결과 뷰이며 전투의 기존 retry/session_finished 핸들러를 호출한다. 표시만으로 보상을 지급하지 않고, 원정 상태에 한 번 반영한다. 전투 busy가 끝난 뒤에만 보여 컷인을 가리지 않는다. 전투 내부 z_index보다 높은 외곽층에서 결과를 그린다. victory/defeat를 5크기로 자연 전투 결과와 실제 포인터를 통해 검사했다. 전투·연출 파일은 읽기만 했다.

### 직접 실행한 검사

|검사|결과|
|---|---|
|import| (exit 0, errors 0)|
|world_test|WORLD TESTS: 44 checks, 0 failures (exit 0, errors 0)|
|state_test|COMBAT CHECKS: 54; FAILURES: 0 (exit 0, errors 0)|
|route_test|ROUTE TESTS: 41 checks, 0 failures (exit 0, errors 0)|
|expansion_test|EXPANSION CHECKS 3350 FAILURES 0 (exit 0, errors 0)|
|motion_test|MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta (exit 0, errors 0)|
|motion_asset_test|MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings (exit 0, errors 0)|
|art_test|PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion (exit 0, errors 0)|
|export_licenses|Exported Godot and bundled library license notices. (exit 0, errors 0)|
|town_r21_test|TOWN R21 CHECKS 2675 FAILURES 0 LUA SAMPLES 2544 (exit 0, errors 0)|
|data_r21_test|DATA_R21 checks=7493 failures=0 composition=1028 stats=700 exploration=300 (exit 0, errors 0)|
|dungeon_r21_test|DUNGEON_R21 {"art_fallbacks":0,"checks":3016,"details":[],"enemies":100,"failures":0,"floors":420,"outcomes":{"defeat":420,"natural_defeat":53,"natural_victory":140,"victory":420}} (exit 0, errors 0)|
|enemy_action_r21_test|ENEMY_ACTION_R21 {"checks":2762,"continuous_matched":1221,"enemies":100,"failures":0,"gear_samples":120,"matched":1221,"samples":1221,"silence_samples":200} (exit 0, errors 0)|
|enemy_regression_r21_test|ENEMY_REGRESSION_R21 {"checks":30,"failures":[]} (exit 0, errors 0)|
|town_commerce_r21_test|TOWN COMMERCE R21 CHECKS 14714 FAILURES 0 LUA 8520 / 8520 (exit 0, errors 0)|
|ui_battle_r17_test|R17 BATTLE UI 6085 CHECKS / 0 FAILURES (exit 0, errors 0)|
|ui_battle_r18_test|R18: 4592 checks / 0 failures; 30 distinct effect hashes (exit 0, errors 0)|
|ui_battle_r19_test|R19: 859 checks / 0 failures (exit 0, errors 0)|
|ui_battle_r20_test|R20: 1659 checks / 0 failures (exit 0, errors 0)|
|motion_r9_integration|R9 INTEGRATION: 944 checks / 0 failures (exit 0, errors 0)|
|motion_r18_integration|R18 STATE INTEGRATION: 3540 checks / 0 failures (exit 0, errors 0)|
|ui_town_r21_test|TOWN UI R21 CHECKS 1580 FAILURES 0 OVERFLOW 0 (exit 0, errors 0)|
|ui_data_r21_test|UI_DATA_R21 checks=9608 failures=0 nameplates=3200 overflow=0 (exit 0, errors 0)|
|ui_town_r21_round2_test|TOWN ROUND2 UI CHECKS 4373 FAILURES 0 (exit 0, errors 0)|
|ui_town_r21_round3_test|TOWN ROUND3 UI CHECKS 8545 FAILURES 0 PORTRAIT SLOTS 300 ENEMY FALLBACKS 0 (exit 0, errors 0)|
|ui_town_result_r21_test|TOWN RESULT R21 CHECKS 220 FAILURES 0 (exit 0, errors 0)|

고립된 Windows root certificate store 경고는 기존 환경 경고로 분리했고 로그를 보존했다. 전투·공통 데이터 기대값은 바꾸지 않았다. 마을 UI 시험의 1차 기대값 한 곳만 “후보가 기본에서 꺼져 있음”에서 “3차 기본 동선”으로 변경했다. JSON roundtrip은 JSON의 float 표현과 비교하고 40bit 씨앗은 별도로 정수 일치를 검사한다.
추가 `web_smoke_r19.py --town-r21 --commerce-only`도 같은 6구성/5크기에서 구매→당일 품절→장비 장착을 실제 포인터로 검사했다. 6 / 6 통과, 오류0. 결과는 round3/web-commerce/results.json이다.
Web build는 `r21-d-town-20261101`, PCK SHA-256 `5d1b767591f9a5e9bcb05f030ee300c0b874efc7bf604f762e26af13b9a8f877`. 로컬 export이며 원격 배포 없음. Web은 390×844, 360×780, 390×664, 1280×800, 430×932 및 360×780 reduced-motion. 기본 URL의 마을/동료/가방/편성/원정/기록/상회/장비/길드/소개/기존 연구/여관/대장간/연출·실제 전투·결과 확인·viewport 복귀를 포인터로 검사했다. JS 상태 변경 브리지는 추가하지 않았다.

28패널의 기본 동선·구현 수준·남은 차이 표는 이 파일 맨 끝에 있다.

모든 패널의 나란히·차분·위치 오차 표: [compare-round3](verification/town-r21/compare-round3/comparison.md). 원시 좌표와 색 마스크 한계를 comparison.json에 보존했다. [owner-sheet.jpg](verification/town-r21/owner-sheet.jpg)는 폭900·400KB 이하의 28화면 시트다. 실제 생성 이미지를 열어 확인했으며 시각 승인은 받지 않았다.

### 남은 작업

연구 시안·페르소나 연구 전체 규칙, 원본 카드/사건 전체와 시안형 보관함, 영입 레벨/RNG, 원본 모험 연대기·NPC 호감 부가 훅이 남았다. 기존 저장 장비와 A 드롭의 옵션은 보존 예외다. 새 시안형도 배경 삽화·아이템 전용 그림·초상 자세/비율·타이포 질감·사선 구성에서 차이가 남는다. 전체 동일·전패널 2px 달성으로 보고하지 않는다. DESIGN.md와 sidecar의 기존 r11 문맥은 오래되어 작업 범위를 넓혀 수정하지 않았고, 별도 document 갱신 대상이다. 디자인 detector 결과 []는 GDScript 시각 완성의 증거가 아니다.

### 변경 파일

- project/export_presets.cfg
- project/data/portrait-slots-r21.json
- project/game/town_world_r21.gd
- project/tests/ui_town_r21_test.gd
- project/ui/town_portrait_r21.gd
- project/ui/town_screen_r21.gd
- project/ui/world_screen.gd
- tools/town_r21_verify.py
- tools/update_version.py
- tools/web_smoke_r19.py
- project/game/commerce_rules_r21.gd
- project/tests/town_commerce_r21_test.gd
- project/tests/ui_town_r21_round3_test.gd
- project/tests/ui_town_result_r21_test.gd
- project/ui/town_art_r21.gd
- project/ui/town_diagonal_r21.gd
- project/ui/town_result_r21.gd
- tools/pack_portrait_slots_r21.py
- tools/town_r21_commerce_oracle.mjs
- tools/town_r21_export.py
- tools/town_r21_round3_report.py
- tools/town_r21_round3_baseline.py
- project/assets/portraits-r21-web/masters/*.webp (30개)
- project/assets/portraits-r21-web/slots/*.tres (300개)

검사·비교·보고 산출물은 verification/town-r21/**, export는 docs/**. 모든 쓰기는 현재 worktree 안에서 했다. 원본 SHA96개와 금지된 전투/A/B/C 파일 변경0을 직접 확인했다.

## 이전 차수 기록

# UI-R21-D

## 2차 — 부분 인계, 28패널 전체 완료 아님

새 시안형 화면은 **14 / 28패널**까지 만들었다(기존 후보4 재작업 + 신규10). 그중 출발·편성·가방·대상·기록·정산 **6패널은 기본 동선**, 홈/동료4 및 탐색/휴식/카드/카드 빈 상태 **8패널은 `?town_r21_preview=1` 뒤**다. 나머지 **14패널은 시안 재구축 미완료**이며 기존 기능 화면을 유지한다. 시각 승인은 받지 않았다. 전체 시안 동일·≤2px 목표를 달성했다고 보고하지 않는다.

### 수치

|항목|2차 최종|
|---|---:|
|원본 Lua 대조|2544 / 2544 (100%)|
|마을 규칙 검사 / 실패|2675 / 0|
|마을 UI 검사 합계 / 실패|4932 / 0|
|공통 및 새 검사 그룹 / 실패|21 / 0|
|Web 구성 / 서로 다른 크기 / 콘솔·페이지 오류|6 / 5 / 0|
|후보4의 기존18 ROI 중 ≤2px|13 / 18 (1차 5 / 18)|
|원본 자산 SHA / 변경|96 / 0|
|읽기 전용 전투·A 데이터 변경|0|
|owner-sheet.jpg|900×3531, 393,937 bytes (400,000 이하)|

### 화면별 같음·다름과 기본 동선

|시안 패널|게임 캡처|기본/플래그|같은 점·차이와 이유|
|---|---|---|---|
|00-town-approved-direction-0|town|후보·플래그|로고·도시·CTA·내비 벡터 보정. 초상 비율·질감·라틴 활자 차이.|
|01-companions-0|party|후보·플래그|칸별 크롭과 차등 배치. 대각 콜라주·초상 스케일·명패 회전 미달.|
|01-companions-1|member|후보·플래그|이름·HP/MP 막대·탭 좌표 보정. 원본 방어17.68·특성 문구 유지. 그림 밀도 차이.|
|01-companions-2|skills|후보·플래그|텍스트형 활성 탭·기술 아이콘·제목 폭 보정. 원본 설명·초상·배경 차이.|
|02-equipment-0|formation|기본·새 화면|편성/부위 관리 경로와 4자리·보유 동료 선택. 시안의 공간 투시·초상 스케일 차이.|
|02-equipment-1|legacy-equipment|기본·기존 화면|시안 재현 미구현. 기존 장착/판매/비교. 장비 옵션은 기존 웹 RNG.|
|02-equipment-2|legacy-art|기본·기존 화면|전투/연출 파일 수정 금지. 기존 미리보기 유지, 시안형 외곽 UI 미구현.|
|03-preparation-0|depart|기본·새 화면|시안 유적을 벡터 추적. 실제 선택층·출전4명·HP/MP 규칙·층 보스 동선. 2층 고정 숫자는 복제하지 않음.|
|03-preparation-1|bag|기본·새 화면|3탭·스크롤·보유량·레벨 제약·실제 보급품 사용. 시안 4품목 대신 원본 전체 목록.|
|03-preparation-2|target-selected|기본·새 화면|4대상·선택/회복 예고·사용/취소. 실제 Lv.1·보유량·회복 반올림. 라디오/선택 세부 문법 차이.|
|04-guild-0|legacy-guild|기본·기존 화면|시안 재현 미구현. 원본 의뢰 생성·균열 출정·정산을 기존 UI에 연결.|
|04-guild-1|legacy-recruit|기본·기존 화면|별도 소개 화면 미구현. 현재 길드 화면을 대체 현황으로 캡처. 영입 레벨은 기존 파티 최고 레벨.|
|04-guild-2|legacy-research|기본·기존 화면|시안 재현·원본 페르소나 연구 전체 이식 미구현. 기존 전술 슬롯 유지.|
|05-commerce-0|legacy-shop|기본·기존 화면|시안 재현 미구현. 기존 원본 가격 반올림 보정 유지.|
|05-commerce-1|legacy-shopgear|기본·기존 화면|시안 재현·원본 일일 장비 진열/품절/옵션 전체 이식 미구현.|
|05-commerce-2|legacy-smithy|기본·기존 화면|시안 재현·원본 강화/가공 RNG 전체 이식 미구현.|
|06-town-life-0|legacy-inn|기본·기존 화면|시안 재현 미구현. 일반 여관 수치의 기존 Lua 대조 유지. 성적/AI 장면 제외.|
|06-town-life-1|journal|기본·새 화면|기록 제목·타임라인·빈 상태·스크롤. 기존 40줄 기록, 원본 모험 연대기 전체 아님.|
|06-town-life-2|summary|기본·새 화면|실제 금화/경험치·일수·4인 레벨 변화·중복 지급 방지. 유적/초상 구도·세부 질감 차이.|
|07-exploration-0|explore|후보·플래그|A의 탐색5회/발견/전투로 연결. 시안의 8노드 지도와 실제 원본 층 상태가 달라 새 지도 구도 미완료.|
|07-exploration-1|legacy-cache|기본·기존 저장 전용|시안형 보관함·원본 전체 카드 사건 미구현. 옛 8노드 저장의 기존 보관함을 캡처.|
|07-exploration-2|rest|후보·플래그|A의 자동 HP30%·MP60% 회복/보스 이동. 시안의 휴게실 그림·배치 미달.|
|08-cards-states-0|cards|후보·플래그|카드 보기 UI 후보. 기존 저장의 2종 카드만 유지, 원본 전체 카드 생성/사건 미이식.|
|08-cards-states-1|retreat|기본·기존 확인창|시안형 귀환 확인 미구현. 실제 보수/경험치 확인·취소/정산은 기존 확인창.|
|08-cards-states-2|cards-empty|후보·플래그|카드 빈 상태와 복귀. 시안의 빈 가방 그림/가방 전용 구도는 미구현.|
|11-battle-results-0|cutin|기본·기존 전투|r18~20 연출 유지. 이 작업의 전투 파일 변경 없음.|
|11-battle-results-1|legacy-victory|기본·기존 전투|기존 전투 결과 패널. 시안의 VICTORY/파티 구도 미구현.|
|11-battle-results-2|legacy-defeat|기본·기존 전투|기존 전투 결과 패널. 시안의 DEFEAT/파티 구도 미구현.|

### 2px 미달 원인과 수정

좌표·테마 문제: 홈 로고 y/높이·개요 이름 폭·HP/MP 막대·탭 높이/밑줄·솔리드 내비/기술 아이콘을 보정했다. 17개 새 장식은 시안 색 마스크에서 SVG로 벡터 추적했다. 생산 래스터 잉크는 없다. 생성 시안의 글자 자체는 추적하지 않고 r19 실제 글꼴을 쓴다.
초상/구도 문제: `town_portrait_r21.gd`는 C의 `slots/<id>-<slot>.png` 10종 이름을 우선한다. C의 preview-placement.json을 출처 그대로 project/data/portrait-slots-r21.json에 기록했다. 파일이 없으면 기존 원본 cutout의 해당 안쪽 크롭, 이후 원본 메시 초상으로 돌아간다. D에는 C의 그림 파일을 복사하지 않았다. 현재 D가 사용하는 fallback에서 머리·의상·RGB를 다시 그리지 않았다. 27명에게는 아직 C 개별 크롭이 없어 힐데가르트 칸 프레임을 원본 범위 안에 적용한다.
시안/데이터 문제: 생성 이미지의 Lv20·2층·보급품 수량·짧은 특성 문구는 정답 데이터가 아니다. 게임은 실제 저장의 레벨·선택층·재고·원본 설명/방어17.68을 표시한다. 그림 질감과 원본 초상의 얼굴·옷 비율 차이, 동료 콜라주, 지도/휴게실/빈 상태 그림과 전체 문법은 아직 남아 있다.
측정 한계: 기존18 ROI와 28패널의 공통 ROI는 색 마스크 경계다. 겹친 그림과 글자가 함께 들어가므로 글자 베이스라인이나 모든 의미 요소의 2px 합격으로 해석하면 안 된다. 원시 좌표·차분·잔차를 보존했다.

### 데이터·원본 규칙·저장

`dungeon_catalog()`는 A의 9대던전·층 범위·개방 여부를 반환한다. 출발 화면은 실제 개방층을 선택하고 `depart_dungeon`으로 출발한다. A의 최소 출발 UI 대신 새 기본 출발 화면을 사용한다. 기본 탐색은 A의 기능 화면이며 새 지도 시안 후보만 플래그 뒤다.
길드는 01-game.lua의 splitmix64 G_rnd와 72-guild.lua의 gd_new를 이식했다. 4난이도·2개 원본 의뢰 균열·종류·중복 재추첨·레벨·엘리트 강도·의뢰번호가 원본과 맞는다. A의 6균열 정의 중 원본 길드가 의뢰를 생성하는 것은 남서 설산/남동 숲 2곳이다. 길드 UI가 A의 depart_rift_quest를 호출하고 수락 원본 계약을 run.source_quest에 보존한다.
마렌토 보수 보너스와 원본 정예 확정 장비 수/등급·직업·부위·코드·40bit 시드를 이식하고 Lua 대조했다. 승리·패배 시 수락 의뢰 제거/게시판 보충/갱신 비용 초기화, 포기 시 해당 의뢰 교체, 중복 정산 거절을 검사했다. A의 이미 지급한 기본 보수를 다시 더하지 않는다. 장비 코드의 생성 일치와 장비 옵션 계산 일치는 별개이며 **장비 roll/일일 진열/강화/가공은 기존 웹 규칙**이다.
저장 schema/path를 유지하고 additive town_r21(seed,counter,qn)을 추가했다. 옛 저장은 기존 rng에서 결정적으로 초기화하며 이미 존재하는 source_id의 번호를 이어간다. 기존 의뢰는 저장 이름·레벨·보수 값을 유지한 계약으로 출발한다. 옛 schema1→2 이관, 입력 불변, 진행 중 v3/원본층·균열 전투 roundtrip, 잘못된 RNG 원자적 거절을 시험했다. 사용자 저장은 삭제/초기화하지 않았다. UI 시험은 user://*fixture.json에만 쓴다.
Lua 원본을 Python/JS로 번역한 정답은 사용하지 않았다. tools/town_r21_oracle.mjs가 읽기 전용 원본을 Wasmoon으로 실행한다. 출처 SHA/호스트 대체는 oracle-provenance.json, 모든 입력과 Lua/Godot 결과는 rules-results.json이다. 성적 콘텐츠·79-sex.lua 장면·친밀도 장면·AI 송신은 실행/이식하지 않는다.

### 검사·산출물

|검사|결과|
|---|---|
|import| (exit 0, errors 0)|
|world_test|WORLD TESTS: 44 checks, 0 failures (exit 0, errors 0)|
|state_test|COMBAT CHECKS: 54; FAILURES: 0 (exit 0, errors 0)|
|route_test|ROUTE TESTS: 41 checks, 0 failures (exit 0, errors 0)|
|expansion_test|EXPANSION CHECKS 3350 FAILURES 0 (exit 0, errors 0)|
|motion_test|MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta (exit 0, errors 0)|
|motion_asset_test|MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings (exit 0, errors 0)|
|art_test|PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion (exit 0, errors 0)|
|export_licenses|Exported Godot and bundled library license notices. (exit 0, errors 0)|
|town_r21_test|TOWN R21 CHECKS 2675 FAILURES 0 LUA SAMPLES 2544 (exit 0, errors 0)|
|data_r21_test|DATA_R21 checks=7493 failures=0 composition=1028 stats=700 exploration=300 (exit 0, errors 0)|
|dungeon_r21_test|DUNGEON_R21 {"art_fallbacks":100,"checks":3069,"details":[],"enemies":100,"failures":0,"floors":420,"outcomes":{"defeat":420,"natural_defeat":52,"natural_victory":147,"victory":420}} (exit 0, errors 0)|
|ui_battle_r17_test|R17 BATTLE UI 6085 CHECKS / 0 FAILURES (exit 0, errors 0)|
|ui_battle_r18_test|R18: 4592 checks / 0 failures; 30 distinct effect hashes (exit 0, errors 0)|
|ui_battle_r19_test|R19: 859 checks / 0 failures (exit 0, errors 0)|
|ui_battle_r20_test|R20: 1659 checks / 0 failures (exit 0, errors 0)|
|motion_r9_integration|R9 INTEGRATION: 944 checks / 0 failures (exit 0, errors 0)|
|motion_r18_integration|R18 STATE INTEGRATION: 3540 checks / 0 failures (exit 0, errors 0)|
|ui_town_r21_test|TOWN UI R21 CHECKS 1580 FAILURES 0 OVERFLOW 0 (exit 0, errors 0)|
|ui_data_r21_test|UI_DATA_R21 checks=9608 failures=0 nameplates=3200 overflow=0 (exit 0, errors 0)|
|ui_town_r21_round2_test|TOWN ROUND2 UI CHECKS 3352 FAILURES 0 (exit 0, errors 0)|

모든 엔진 실행은 tools/godot_r17.py를 썼다. 격리 Windows의 기존 root certificate store 경고는 로그에 보존하고 검사 오류와 구분했다. 공통 전투 기대값은 변경하지 않았다. 마을 검사의 1곳 고정 catalog 기대는 실제9곳/개방 조건으로 바꿨다. Web의 옛 travel:patrol 경로와 battle-r20b 기대는 실제 A 탐색/전투 build로 교체했다.
Web은 390×844, 360×780, 390×664, 1280×800, 430×932 + 360×780 reduced-motion이다. 기본 URL에서 가방/대상 취소/출발/편성/기록, 플래그에서 후보4, 실제 원본 층 전투 진입·공격·대상·보급·기록·고유기·승리 후 뷰포트 복귀를 실제 포인터로 검사했다. 상태 변경 JavaScript 브리지는 추가하지 않았다.
Web export ui_build: **r21-d-town-20261031**. PCK SHA-256 `c473ffb3dab4fef374e7e87c131bce3c3dd5a9fd0233ff80a4e55e4d4359d350`. 로컬 내보내기이며 원격 배포하지 않았다.
시안/게임 28쌍과 차분: [compare-round2](verification/town-r21/compare-round2/comparison.md). 후보4 세부18 ROI: [compare](verification/town-r21/compare/comparison.md). 확인용 [owner-sheet.jpg](verification/town-r21/owner-sheet.jpg). 현재 결과를 직접 열어 검수했으며 시각 승인/전 패널 일치라고 판단하지 않는다.

### 남은 일

기본 연결6도 전체 픽셀 일치가 아니다. 후보8의 구성 보정, 장비/연출 외곽·길드3·상회3·여관·보관함·귀환 확인·전투 결과3의 시안 재구축14, 원본 장비 RNG/전술 연구/페르소나 영입 레벨/카드와 사건 전체·모험 연대기/가변 파티 이식이 남았다. 전투 화면 파일은 허용 범위 밖이라 그대로 유지했다. 이번 작업은 지시서의 “한 번에 다 못 끝내면 끝낸 데까지 검사 통과 상태로 멈추고 남은 것을 적어라”에 따른 부분 인계다.

### 2차 변경 파일

- project/game/town_world_r21.gd
- project/tests/town_r21_test.gd
- project/ui/town_portrait_r21.gd
- project/ui/town_screen_r21.gd
- project/ui/world_screen.gd
- tools/town_r21_compare.py
- tools/town_r21_oracle.mjs
- tools/town_r21_round2_assets.py
- tools/town_r21_verify.py
- tools/web_smoke_r19.py
- project/assets/ui-r21/detail-city.svg
- project/assets/ui-r21/facility-guild.svg
- project/assets/ui-r21/facility-inn.svg
- project/assets/ui-r21/facility-shop.svg
- project/assets/ui-r21/facility-smithy.svg
- project/assets/ui-r21/nav-bag.svg
- project/assets/ui-r21/nav-gate.svg
- project/assets/ui-r21/nav-home.svg
- project/assets/ui-r21/nav-journal.svg
- project/assets/ui-r21/nav-party.svg
- project/assets/ui-r21/preparation-ruins.svg
- project/assets/ui-r21/skill-attack.svg
- project/assets/ui-r21/skill-guard.svg
- project/assets/ui-r21/skill-taunt.svg
- project/assets/ui-r21/town-city-left.svg
- project/assets/ui-r21/town-city-right.svg
- project/assets/ui-r21/town-depart.svg
- project/data/portrait-slots-r21.json
- project/game/guild_rules_r21.gd
- project/tests/ui_town_r21_round2_test.gd
- tools/town_r21_round2_report.py

비교/로그/요약/Web export 산출물은 verification/town-r21/** 및 docs/**. 모든 쓰기는 이 worktree 안에서 했다. 최초 읽기 쉘에 금지된 git status --short를 잘못 포함했으나 소유권 오류로 실패했고 이후 Git 명령/설정 변경은 하지 않았다. 디자인 스킬 detector는 GDScript 대상에서 []였지만 시각 완성의 근거로 사용하지 않는다. DESIGN.md의 r11 토큰과 sidecar는 오래되어 보고만 하고 범위 밖 문서는 바꾸지 않았다.

## 1차 기록 — 아래 수치는 1차 당시 상태

# UI-R21-D — 부분 인계 / 시안 일치 미완료

작업 지시서와 공통 규칙을 UTF-8로 읽고 r21-d-town 안에서 작업했다. **마을 전체 완료가 아니다.** 새 화면 후보 4개를 구현·검사했지만 시안 재현은 미달이며, 나머지 24개 패널은 미구현이다. 시안 대조 18개 영역 중 5개만 ≤2px이다. 검수 disposition은 **rebuild**다.

“반쯤 된 화면을 연결한 채 두지 말 것”에 따라 새 후보 화면은 **기본 게임 내비게이션에서 껐다.** 기본 URL은 기존의 기능 완결된 화면을 사용하며, 일반 규칙 보정·5개 내비·뒤로·보급품 미리보기·장비 비교를 적용한다. 비교 후보는 명시적인 `?town_r21_preview=1` URL에서만 열린다. 이 플래그는 저장하지 않는다. native 테스트는 격리된 객체에서만 켠다. 기본 URL·미리보기 URL 모두 검수했으며 자동 조작용 상태 변경 브리지는 추가하지 않았다.

## 핵심 수치

|항목|실측|
|---|---:|
|대응표/패널 크롭/색·픽셀 분할 측정|28패널|
|새 화면 후보 / 기본 배포에서 연결한 시안 화면|4 / 0|
|미구현 시안 패널|24|
|원본 Lua 대조|390 / 390 일치 (100%)|
|새 규칙 검사|410건 / 실패 0|
|최신 마을 UI 검사|1607건 / 실패 0|
|공통 검사 포함 실행 그룹|17 / 실패 0|
|Web 실브라우저 구성 / 서로 다른 해상도|6 / 5|
|Web 페이지·콘솔 오류 / 전투 글자 검사 오류|0 / 0|
|고정 후보의 가로 글자 넘침 / 표시 버튼 경계·겹침 검사 실패|0 / 0|
|시안 대비 ≤2px|5 / 18 측정 영역|
|ASSET-HASHES 원본|96 / 변경 0|

UI 검사는 native 390×844·360×780·1280×800에서 후보 4화면, 30인 목록 접근, 실제 포인터로 탭·뒤로·상세·편성 이동, 줄바꿈 높이, 5개 내비를 검증한다. 마지막에는 기본 동선에서 후보가 꺼지는지와 기존 11개 화면의 5개 내비도 검증한다. “넘침 0”은 이 검사 범위의 수치이며 **24개 미구현 시안의 레이아웃 통과를 의미하지 않는다.** 긴 원본 설명은 명시적 말줄임 미리보기와 전체 상세를 구분한다.

## 원본 대조와 규칙

`tools/town_r21_oracle.mjs`는 기존 읽기 전용 Wasmoon/RisuSim을 이용하고, 현행 `70-town.lua`, `71-shop.lua`, `72-guild.lua`, `73-inn.lua`, `74-affection.lua`, `74-level.lua`를 그대로 다시 실행한다. 번역한 Python/JS 수식을 정답으로 사용하지 않는다. 출처 SHA와 호스트 대체 범위는 [oracle-provenance.json](verification/town-r21/oracle-provenance.json), 모든 입력/원본/이식 출력은 [rules-results.json](verification/town-r21/rules-results.json)에 있다.

|원본 함수/행동 표본군|표본|일치|
|---|---:|---:|
|affection|99|99|
|inn|96|96|
|level|46|46|
|level_scroll|12|12|
|price|75|75|
|recruit_cost|31|31|
|refresh_cost|31|31|

수정한 규칙은 상점 할인 가격의 `max(1, floor(price*mult+0.5))` 반올림, 여관 호감 100 경계의 구간별 계산(99.5+1 → 100.2), 일반 여관 행동 비용·하루 제한·날짜와 원본처럼 숙박 시 의뢰 갱신 횟수를 유지하는 동작이다. 기존 상점 99개 상한은 제거했다. 단, 원본에는 없는 **기존 저장 검증의 10,000개 한도**는 유지해 해당 한도에서 구매를 원자적으로 거절한다.

레벨 필요 경험치·길드 소개/갱신 비용은 원본과 같은 함수를 공통화했다. 레벨업 스크롤 실제 소비·경험치 초기화·Lv40 거절과 여관 실제 핸들러 연속 행동을 대조했다. 이 결과를 장비 난수·모든 길드 규칙의 원본 일치율로 확대 해석하면 안 된다.

보급품 대상 미리보기는 실제 사용의 반올림·부활·레벨·보유량 조건과 대조한다. 장비 비교는 교체 부위의 전/후/차이를 계산하고 상태를 바꾸지 않는다. **장비 옵션 계산은 여전히 기존 웹판 RNG**이며 Lua 원본 일치로 주장하지 않는다. `shop.json`, `gear.json` 등 기존 데이터는 고치지 않았다.

## 저장과 합류 경계

저장 스키마와 경로를 변경하지 않았고 사용자 저장을 삭제하거나 초기화하지 않았다. 기존 schema1 → schema2 이관을 그대로 사용한다. 새 시험에서 옛 저장 입력 불변·이관·schema2 보존·잘못된 저장의 원자적 거절·진행 중 v3 전투 스냅샷 보존·전투 중 마을 행동 거절을 확인했다. 전투 파일·원본 데이터는 수정하지 않았다.

갈래 A는 `project/game/town_world_r21.gd::dungeon_catalog()`만 교체해 목적지 목록을 연결할 수 있다. 현재 반환값은 기존 학술원 폐허 상층 검수 원정 1곳이며, 원본 대던전 10곳을 구현했다고 표시하지 않는다. 갈래 C는 `res://assets/portraits-r21/<id>-face.png` / `<id>-bust.png` 우선 규칙을 사용한다. 없으면 원본 r10 face/cutout, 이후 기존 원본 메시 초상으로 폴백한다. 원본 96개 파일의 SHA는 전부 그대로다.

## 화면별 같음·다름과 미완료

|시안|이번 상태|같은 점 / 남은 차이와 이유|
|---|---|---|
|00 홈|비교 후보, 기본 연결 안 함|파티4·금화·날짜·시설·5내비·CTA 작동. 원본 초상과 r19 활자 사용. 시안의 대형 영문 조판·도시/잉크 일체감·시설/출발 삽화·종이 질감·솔리드 아이콘 미달. 기존 도시 그림 사용.|
|01 좌 동료 목록|비교 후보, 기본 연결 안 함|보유/전체30·선택·파티표시·스크롤 작동. 시안의 연속적인 대각 콜라주·스케일 차이를 충분히 재현하지 못함. 원본 얼굴·비율 보존.|
|01 중 개요|비교 후보, 기본 연결 안 함|원본 능력치·레벨·특성·탭·전체상세. 방어17.68은 출신 시너지 실제값이며 시안17로 고치지 않음. 초상 크롭·제목·메타데이터 종이 띠·배경 밀도 차이. 확대 초상이 신분행을 가리는 회귀는 최종 수정·재확인.|
|01 우 기술|비교 후보, 기본 연결 안 함|원본 기술/MP·방어 도발 의미·미리보기·상세 복귀. 헤더 분리·가독성 보정. 시안의 텍스트형 활성 탭과 달리 면형 탭, 얼굴 프레이밍·일반기 아이콘·종이 질감 차이.|
|02 편성·장비·연출|시안 재현 미구현|기존 기능 유지. 편성/장비 명시 경로·장비 수치 비교 추가. 생성 장비명을 실제 데이터로 만들지 않음. 원본 RNG·일일 진열·품절·가공·장착 제약 완전 이식 안 됨.|
|03 준비·가방·대상|시안 재현 미구현|기존 기능 유지. 목적지 경계와 대상별 회복 미리보기·불가 사유·취소 추가. 목적지 목록/그림 배치·파티 공간편성 미완료.|
|04 길드·소개·연구|시안 재현/완전 규칙 이식 미구현|비용만 대조. 기존 단순화 의뢰·파티 최고 레벨 영입·전술 슬롯 유지. 페르소나·원본 의뢰 생성/전투 연결/정산·조각 체계가 같다고 주장하지 않음.|
|05 상회·직업 장비·대장간|시안 재현/완전 규칙 이식 미구현|가격 반올림과 구매 한도 보정 외 기존 기능 유지. 장비 원본 난수·코드·일일 재고·강화·가공 표본 이식 미완료.|
|06 여관·기록·정산|시안 재현 미구현|일반 여관 행동 수치는 대조·보정. 기록40줄/검수 정산 유지. AI 대화·모험 연대기·원본 손실/보상/경험치 분배 전체 이식 미완료.|
|07 지도·보관함·휴식|시안 재현/원본 전체 이식 미구현|기존8노드 검수 경로 유지. A의 데이터나 전투 파일 변경 없음.|
|08 카드·귀환·빈 상태|시안 재현/원본 전체 이식 미구현|기존2카드·귀환 확인·빈 상태 유지. 전체 원본 카드/이벤트 체계 아님.|
|11 고유기·승리·패배|시안 재현 미구현|기존 r18~20 전투/결과 동작 유지. 전투 파일 수정 없이 회귀 검사만 수행.|

일반 여관 수치 외 성적 콘텐츠와 친밀도 장면은 제외했다. 제외 목록: 79-sex.lua 장면·장미 골목/창관·여관/던전 제안·매혹의 비약/피에트로 덤. 새 성적 UI나 재화·가챠·무기·캐릭터를 추가하지 않았다.

## 측정과 직접 열람

[coverage.md](verification/town-r21/coverage.md)는 착수 전의 시안 → 기능 → Lua/디자인 위치 → 기존 구현 대응표다. [measure](verification/town-r21/measure)는 모든 28패널의 정규화 크롭·출처 SHA·색 중앙값·색 마스크 연결요소 상자/높이를 저장한다. 이름을 붙인 18개 영역은 4개 후보에 한정한다. 색 분할 경계에는 겹친 그림도 들어가므로 이것을 정밀 글자 베이스라인이나 모든 UI 요소 측정으로 주장하지 않는다. 나머지 패널의 의미 단위 박스/활자 치수·실제 렌더 대조는 남은 작업이다.

새 잉크·펭귄·방어형 실루엣은 시안 색 마스크를 SVG 경로로 트레이스했다(추적 조건·허용 오차는 measure의 trace JSON). 생산 래스터 잉크 파일은 없다. 새 그림으로 원본 초상을 다시 칠하지 않았다. 폰트는 AbyssDisplayR19 / AbyssTextR19W850 / AbyssNotoText500, 색은 종이 #f4efe3 / 잉크 #111715 / 버밀리언 #d83219를 재사용한다.

4개의 나란히/차분 PNG와 [요소 오차 표](verification/town-r21/compare/comparison.md), [시안 위·렌더 아래](verification/town-r21/compare/first-four-reference-above-render-below.png)를 저장하고 직접 열었다. 검수 에이전트는 native 12캡처와 4기준 패널을 모두 열었다. 본 작업에서도 합본·차분·360 홈·1280 기술 및 Web 기본 홈을 직접 열었다. 시각 승인 판정은 아니다.

|후보|RGB 평균 절대 오차(0~255)|채널 오차>30인 픽셀 비율|
|---|---:|---:|
|town|56.286|49.14%|
|party|70.088|61.477%|
|member|57.878|43.548%|
|skills|43.059|35.788%|

전체 시안 재현·2px 목표는 미달이다. [초기 검수](verification/town-r21/finish-review.md)와 [보정 후 검수](verification/town-r21/finish-verdict.md)는 **rebuild**를 유지한다. 헤더·그림 판·편성 경로·상세 복귀·내비 잘림·신분행 가림 회귀는 보정했으나 구성 자체의 차이는 남았다. 그래서 기본 동선에서 후보를 비활성화했다.

## 검사와 Web

모든 Godot 실행은 격리된 `tools/godot_r17.py`를 사용했다. 공통 기대값 변경은 없다. 공통 로그의 root certificate store 오류는 이 Windows 격리 계정의 기존 엔진 환경 경고이며, 스크립트 오류·assert 실패와 분리해 원문을 보존했다. import/export와 각 검사 종료 코드는 0이다.

|검사|결과 원문|실패|
|---|---|---:|
|import|exit 0|0|
|world_test|WORLD TESTS: 44 checks, 0 failures|0|
|state_test|COMBAT CHECKS: 54; FAILURES: 0|0|
|route_test|ROUTE TESTS: 41 checks, 0 failures|0|
|expansion_test|EXPANSION CHECKS 3350 FAILURES 0|0|
|motion_test|MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta|0|
|motion_asset_test|MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings|0|
|art_test|PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion|0|
|export_licenses|Exported Godot and bundled library license notices.|0|
|town_r21_test|TOWN R21 CHECKS 410 FAILURES 0 LUA SAMPLES 390|0|
|ui_battle_r17_test|R17 BATTLE UI 6085 CHECKS / 0 FAILURES|0|
|ui_battle_r18_test|R18: 4592 checks / 0 failures; 30 distinct effect hashes|0|
|ui_battle_r19_test|R19: 859 checks / 0 failures|0|
|ui_battle_r20_test|R20: 1659 checks / 0 failures|0|
|motion_r9_integration|R9 INTEGRATION: 944 checks / 0 failures|0|
|motion_r18_integration|R18 STATE INTEGRATION: 3540 checks / 0 failures|0|
|ui_town_r21_test|TOWN UI R21 CHECKS 1607 FAILURES 0 OVERFLOW 0|0|

Web: 390×844, 360×780, 390×664, 1280×800, 430×932 다섯 해상도 + 360×780 reduced-motion 추가 구성. [web/results.json](verification/town-r21/web/results.json)에 실제 포인터로 마을 후보·동료·개요·기술·출발·탐색·전투·대상·보급품·기록·고유기 및 승리 뒤 뷰포트 복원 결과를 기록했다. 390×844에서는 **기본 URL이 후보를 사용하지 않음**도 별도로 검증했다. 내부 Godot 뷰포트는 짧은 화면 390×664에서 459×781, 데스크톱에서 1248×780로 스케일되며 CSS 해상도와 구분한다.

실행 재현:
```
"C:/Program Files/nodejs/node.exe" tools/town_r21_oracle.mjs
python tools/town_r21_verify.py
python tools/town_r21_reference.py
python tools/town_r21_trace.py
python tools/town_r21_compare.py
python tools/godot_r17.py --headless --export-release Web ../docs/index.html
python tools/update_version.py
python tools/web_smoke_r19.py --town-r21
python tools/town_r21_report.py
```

`docs/version.json`: ui_build **r21-d-town-20261031**. PCK SHA-256 `0b6a47149db7db9599e8db9ef7ef8b443dc98657f9a539ea8029d9130daf94dd`. 로컬 Web export이며 원격 게시/배포는 하지 않았다.

## 변경 파일과 인계

- 기존 소스: `project/ui/world_screen.gd`만 변경. `tools/update_version.py`, `tools/web_smoke_r19.py` 확장, README 맨 위 한 줄.
- 새 규칙: `project/game/town_rules_r21.gd`, `town_world_r21.gd`, `project/data/town-r21-rules.json`.
- 새 UI: `project/ui/town_theme_r21.gd`, `town_portrait_r21.gd`, `town_screen_r21.gd`; `project/assets/ui-r21/*.svg` 3개. 엔진 생성 uid/import 메타데이터 포함.
- 새 시험: `project/tests/town_r21_test.gd`, `ui_town_r21_test.gd`.
- 새 도구: `tools/town_r21_reference.py`, `town_r21_trace.py`, `town_r21_oracle.mjs`, `town_r21_verify.py`, `town_r21_compare.py`, `town_r21_report.py`.
- 산출물: `verification/town-r21/**`, 본 보고서, 지시된 `docs/` Web export. 공통 검사 자체가 다른 verification 폴더와 라이선스 산출물을 재생성한다.

다음 작업은 홈/동료 후보 4개의 rebuild 판정부터 해결하고, 허용된 순서대로 02/03 출발·편성·장비 이후 화면을 원본 규칙과 함께 이식하는 것이다. 아직 후보를 기본 동선에 켜면 안 된다. A 병합은 catalog 함수 경계, C 병합은 face/bust 파일 경계로 연결한다.

기존 DESIGN.md와 sidecar는 r11 청백자/고운바탕 문서라 실제 새 토큰과 다르다. [문서 감사](verification/town-r21/documentation-audit.md)에 남기고 허용 범위 밖의 문서는 고치지 않았다. 별도 `document` 작업으로 갱신 가능하다. 감사/초기 검수에 남은 이전 1277/1595 검사 수치는 당시 스냅샷이며, 최종 수치는 이 보고서와 `summary.json`/`ui-results.json`이다.

절차 이탈: 첫 규칙 읽기 쉘 호출에 읽기 전용 `git status --short`를 함께 넣었다가 저장소 소유권 오류로 실패했다. 규칙을 확인한 뒤 Git 호출·설정 변경·커밋·브랜치 조작은 하지 않았다. 원본 파일 변경은 없다.



## 3차 최종 28패널 표

|시안 패널|기본 동선 / 시안 일치 정도|남은 차이와 이유|
|---|---|---|
|00-town-approved-direction-0|기본 · 시안형 · 부분 일치 · 미승인|C 원본 크롭·로고·CTA·시설·5내비. 초상 비율·도시 배경·활자 질감 차이.|
|01-companions-0|기본 · 시안형 · 부분 일치 · 미승인|C 칸·대각 경계·명패와 글자 함께 회전·30인 스크롤. 참조의 얼굴 확대·사선 각도 차이.|
|01-companions-1|기본 · 시안형 · 부분 일치 · 미승인|C 상세 칸·실제 수치·개요/기술/편성. 원본 초상 자세·그림 밀도 차이.|
|01-companions-2|기본 · 시안형 · 부분 일치 · 미승인|C 기술 칸·원본 설명·연출 연결. 실제 설명 길이·초상 비율 차이.|
|02-equipment-0|기본 · 시안형 · 부분 일치 · 미승인|원본 4인 편성·보유 동료 선택·장비 관리. 시안 공간 투시·크롭 크기 차이.|
|02-equipment-1|기본 · 시안형 · 부분 일치 · 미승인|초상·HP/MP·3부위·장착/해제/판매·전후 수치. 새 저장 장비 없음은 원본 보유 상태, 무기 그림은 공용 벡터.|
|02-equipment-2|기본 · 새 외곽 · 부분 일치 · 미승인|마을 종이/먹색 외곽·30명 이전/재생/다음·닫기. 내부 원본 고유기 재사용, 컷인/무기 수정 없음.|
|03-preparation-0|기본 · 시안형 · 부분 일치 · 미승인|실제 층 선택·출전 4인·HP/MP 회복·균열 의뢰 출발. 시안 고정 Lv20/2층 대신 실제 저장.|
|03-preparation-1|기본 · 시안형 · 부분 일치 · 미승인|3탭·보유량·원본 모든 보급품·스크롤. 시안 4품목과 실제 품목 수 차이.|
|03-preparation-2|기본 · 시안형 · 부분 일치 · 미승인|명시적 대상 선택·회복 예고·사용/취소. 실제 Lv1/재고, 세부 라디오 문법 차이.|
|04-guild-0|기본 · 시안형 · 부분 일치 · 미승인|접수 초상·3탭·원본 생성 의뢰·수락/포기/출발/갱신. 원본 NPC 초상 자세와 시안 배경 차이.|
|04-guild-1|기본 · 시안형 · 부분 일치 · 미승인|별도 소개 탭·보유 수·금화·소개비·실제 영입. 페르소나 영입 레벨·원본 영입 RNG는 미이식.|
|04-guild-2|기본 · 기존 화면 · 미재구축|원본 페르소나 연구 전체 이식과 시안 재구축 미완료. 기존 동료별 전술 슬롯 유지.|
|05-commerce-0|기본 · 시안형 · 부분 일치 · 미승인|피에트로·2탭·금화·보급품 그림/가격/구입. 원본 초상·건축·아이템 그림이 시안과 다름.|
|05-commerce-1|기본 · 시안형 · 부분 일치 · 미승인|직업/부위·원본 일일 진열·레벨 제한·품절·40bit 코드. 목록 구도·장비 그림 차이.|
|05-commerce-2|기본 · 시안형 · 부분 일치 · 미승인|한나·원본 가공 가격/확률/회차·제련/단계/비용. 신규 저장 장비 없음, 전용 장비 그림·공방 배경 미재현.|
|06-town-life-0|기본 · 시안형 · 부분 일치 · 미승인|도로테아·동료 선택·호감·4행동·일일 제한·실제 원본 핸들러. 원본 초상 자세와 실내 배경 차이.|
|06-town-life-1|기본 · 시안형 · 부분 일치 · 미승인|실제 기록·타임라인·스크롤. 원본 모험 연대기 전체 대신 기존 40줄 로그.|
|06-town-life-2|기본 · 시안형 · 부분 일치 · 미승인|실제 금화/경험치/일수·4인 변화·중복 지급 방지. 유적·파티 구도와 질감 차이.|
|07-exploration-0|기본 · 시안형 · 부분 일치 · 미승인|원본 5탐색·전투·발견 동선. 시안 8노드 대신 실제 원본 5단계, 지도/배경 그림 미달.|
|07-exploration-1|옛 저장만 · 기존 화면 · 미재구축|원본 A는 발견품 자동 적립이다. 시안형 봉인 보관함/원본 카드 사건 전체 미이식, 옛 저장의 보관함 보존.|
|07-exploration-2|기본 · 시안형 · 부분 일치 · 미승인|실제 HP30%/MP60% 자동 회복·보스 도전. 휴게실 삽화·파티 배치 차이.|
|08-cards-states-0|기본 · 시안형 · 부분 일치 · 미승인|보관한 카드·사용 가능 조건·복귀. 원본 전체 카드 생성/사건 미이식, 기존 카드 2종 보존.|
|08-cards-states-1|기본 · 시안형 · 부분 일치 · 미승인|원정 누적 금화/경험치·취소/정산·원자적 취소. 시안 유적 구도·그림 질감 차이.|
|08-cards-states-2|기본 · 시안형 · 부분 일치 · 미승인|카드 빈 상태·복귀. 시안의 빈 가방 그림/구도는 미재현.|
|11-battle-results-0|기본 · 기존 전투 유지 · 기존 전투 유지|r18~20 컷인·연출·잉크 유지. 마을 작업에서 내부 연출 파일 변경 없음.|
|11-battle-results-1|기본 · 새 외곽 · 부분 일치 · 미승인|VICTORY·유적·실제 전투 후 HP·기존 결과 확인 핸들러. 시안 파티 포즈·배경 그림 차이, 보상은 기존 원정 정산 시점.|
|11-battle-results-2|기본 · 새 외곽 · 부분 일치 · 미승인|DEFEAT·유적·실제 전투 후 HP·정산 연결. 시안 파티 포즈·배경 그림 차이, 원본 패배 규칙은 기존 핸들러.|

