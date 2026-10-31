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
