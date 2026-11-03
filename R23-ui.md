# R23-ui · 3차 기능 등가 재판정

3차 잔여 99행 검토: **같음 +20, 수정·보완 25행(같음과 중복), 대체 21, 호스트 제외 4, 잔여 54행**.
누적 **같음 65/144 · 대체 21 · 제외 4 · 남음 54**. 전체 이식 완료는 아니다. 기존 같음 45행은 판정/근거를 변경하지 않았다.

행별 기존 상태·정본 위치·새 시험·대응 기능·구체적인 잔여 이유는 [ui.json](verification/parity-r23/ui.json), 이번 99행만은 [ui-row-review.json](verification/parity-r23/ui-phase3/ui-row-review.json). 이전 보고서는 ui-phase3/ui-report-before.md에 보존했다.

## 구현과 직접 대조

- 공용 표시 함수를 실제 도감/가방/상태 화면에 연결했다. 단계별 HTML을 비교하는 대신 표시 글·순서·버튼 action/선택/비활성·막대 값을 원본 Lua 실행 결과에서 추출했다.
- 도감 하위 필터 선택 표시와 원본 ‘모두’/가방 ‘전체’ 문구, 누락 속성, 소수 능력치, 최대 레벨/현재 경험치 막대를 보완했다. 장비 기본/무작위/고유 효과의 순서·수치·한영 문구를 1,030종 실제 native 어댑터와 비교했다.
- 정본 장비 아이콘 220개(278,882바이트)를 새 경로에 그대로 복사했다. 1,030종 전체의 아이콘 선택/리소스·등급·이름/Lv/선택지 유무·한영 장착 문구를 비교하고 가방/도감 후보/장비 카드에 연결했다. 후보는 원본처럼 슬롯당 최대 4개와 더 보기 안내로 제한한다. 아이콘을 추가한 뒤 import를 갱신하고 새 검사·실제 화면을 재확인했다.
- 도감 구성요소는 원본처럼 전투 중에도 후보를 조회할 수 있게 하고 장착 handler는 거절 안내를 낸다. 조회만 전투 변경 가드와 분리했으며 실제 장착/해제는 기존 가드로 거절되고 장비가 보존되는지 시험했다. **실제 전투 화면에서 패널에 진입하는 전체 경로는 미검증/잔여**다. 전투 규칙은 변경하지 않았다.
- 패시브는 정본 passives.json과 같은 원문을 사용하고 번역 뒤 변수 치환을 적용한다. 수인 dog/cat/미선택, 빈 node/미선택 직업, 2·3인 단계/준비 중 분기를 검사했다. persona_rules 파일은 읽기만 했다.
- table-only JSON getter는 객체/배열/스칼라/오류/파일 읽기 불가를 실제 파일 저장·재읽기로 비교하고 클라우드 preferences 읽기에 연결했다. 사용자 게임 저장 형식은 바꾸지 않았다.
- 원본 cloud_button의 취소/잘못된 코드·PIN/404/429/500/망가진 응답·저장/지원 버전/성공/통신 오류 26분기를 실행했다. native 입력/실패/복원/재개 40검사와 실제 Worker/D1 왕복·PIN 거부·읽기 전용·충돌·순위·cache 재개 시험을 ‘대체’ 근거로 썼다. 행별 대응은 ui.json의 replacement_mapping이다.

## 직접 실행 결과

|검사|결과|
|---|---:|
|새 원본/native 의미 대조 + 실제 장비 어댑터 + JSON getter|15,618 / 실패 0|
|새 native 화면/포인터/저장 재개|1,374 / 실패 0 / 12캡처|
|새 클라우드 대응 분기|40 / 실패 0|
|현재 프로젝트 import·전체 시험·전투 trace|116종 / 실패 0 / 누락 0|
|로컬 Worker/D1 전체 package 시험|9종 / 실패 0|
|전투 대조|6,320 / 6,320판 일치|
|보호 원본 자산|96개 / 변경 0|

초기 새 표시 경계 미구현 4,546실패는 ui-phase3/ui-baseline.json에 보존했다. 원본 빈 Lua table의 JSON 배열 표현은 table 등가로 처리한다. 새 fixture 개발 중 잘못된 settings fixture·동종 비교·누락된 battle 구조·존재하지 않는 host 속성 가정도 수정했고 최종 SCRIPT ERROR 0을 확인했다. 실제 전투 패널 진입은 시험했다고 주장하지 않는다.

기존 ui_parity_r23_test의 ‘도감에 후보 12개 모두 표시’ 기대값은 정본 65-codex.lua의 PX.CX_CAND=4에 맞춰 ‘4개 미리보기 + 나머지는 가방에서 접근’으로 수정했다. 4번째 미리보기와 12번째 장비를 실제 가방 페이지/포인터로 장착하고 저장 재개까지 검사한다. 변경 전 실패 로그는 ui-phase3/ui-candidate-expectation-before.log, 최초 전체 검사 집계는 ui-phase3/ui-regression-full-initial.json에 보존했다. 다른 기존 기대값은 바꾸지 않았다.

전체 검사 전 첫 서버 실행은 기존 8787 리스너에 내부 proxy가 붙어 401로 종료했다. 기존 프로세스는 건드리지 않았다. tools/ui_r23_phase3_server.mjs가 **원본 serve.mjs를 실행하면서 runtime(8787)만 메모리에서 runtime()으로 바꿔** 별도 포트를 배정한다. Worker/서버/시험 원본 디스크 파일은 변경 0. TEMP도 workspace 안에 격리했다. 최종 lifecycle: ready=True, clean=True, forced=False. Windows root certificate store 진단은 별도 기록하고 SCRIPT ERROR/실패를 숨기지 않았다.

## 남은 범위

남은 54행은 원본/현재 표시 항목 차이 또는 아직 직접 대조하지 않은 구체적인 분기를 각 id에 적었다. 예: 생성 단계 번호/특성·확정 설명, 개인 특성 아이콘과 전체 장착 경계, 상세 비교의 ‘-’ 대 ‘+0%’, 즐겨찾기 속성/호감 표시, 전체 공개 번역 키, 전투 상태 패널, 원본 v1 상태의 관찰 투영. HTML/CSS 반환·저장 매체·호스트 차이만으로 남기지 않았다.

수정 금지 persona_rules/persona_world/town/전투/원정 경로가 필요한 행은 해당 파일을 명시했다. **허용 UI 경로에도 미완료 표시 대조가 남아 있으며 이 차수에서 모두 고쳤다고 주장하지 않는다.** 원본 AI/채팅/아바타 수집 4행만 호스트 제외로 옮겼다. 복합 화면의 공개 기능까지 함께 제외하지 않았다. 성적 장면은 구현하지 않았다.

실제 화면은 360×780·390×844·430×932 × 한영. 직접 연 화면과 관찰은 ui-phase3/ui-visual-review.json에 있다. 장비 아이콘이 연결되어도 전체 언어/화면 이식 완성이나 사용자 시각 승인을 뜻하지 않는다. Impeccable 기계 검사는 변경 UI 3개에서 0건. 기존 .impeccable/design.json이 DESIGN.md보다 오래되었다는 진단은 기록만 했으며 `document`로 별도 갱신할 수 있다.

주요 변경: game/ui_semantics_r23.gd·ui_json_r23.gd·cloud_store_r22.gd·panels_state_r22.gd, ui/panel_screen_r22.gd·codex_screen_r22.gd·inventory_screen_r22.gd, data/localization-r22.json·ui-passives-r23.json·ui-gear-icons-r23.json, assets/ui-gear-r23/ 및 새 시험/도구. 전체 경로와 경계 감사는 ui-phase3/ui-write-audit.json. git 명령·Web export·docs 쓰기·서버 디스크 변경·원본 자산 변경 없음.

재현: node tools/ui_r23_phase3_oracle.mjs → python tools/ui_r23_phase3_data.py → python tools/ui_r23_verify.py → python tools/ui_r23_server_tests.py → python tools/ui_r23_phase3_report.py.
