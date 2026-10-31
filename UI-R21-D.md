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

