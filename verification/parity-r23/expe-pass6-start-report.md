# R23-expe — 5차 기능 등가 대조

남은 65행을 검토해 **같음 26행 추가, 누적 같음 70행, host 전용 제외 1행, 남음 38행**으로 기록했다. 수정·보강한 함수 행은 29행이며 이 중 5행은 전체 기능 차이가 남아 승격하지 않았다. 원본 전 기능 이식 완료는 아니다.

|항목|결과|
|---|---:|
|이번 검토 / 같음 승격 / 수정·보강 / 제외 / 남음|65 / 26 / 29 / 1 / 38|
|새 native 대조 단언|2,814, 실패 0|
|새 실제 UI 단언|1,236, 실패 0|
|실제 표시 입력을 Lua에 재입력한 화면 대조|24/24 일치|
|원본 실행 fixture 사례|1,704 (기본 1,464 + 경계 216 + 화면 24)|
|전체 프로젝트 검사 최종 집계|118/118 그룹, 실패 0|
|전투 대조|6,320판 / 219,785기록, 차이 0|
|저장 표본의 서버 validate|4/4|
|기존 같음 행 보존|44/44, 행 객체 변경 0|
|보호 이미지 / 정본 Lua|96개 변경 0 / 46개 변경 0|
|기존 전투 시험 파일 / 서버 / docs 변경|0 / 0 / 0|
|새 대조 파일 최대 크기|4,753,796 bytes, 50MB 이하|

행별 이전 상태·시험·수정 위치·남은 이유는 [expe.json](verification/parity-r23/expe.json)에 이어 기록했다. 이번 65행 검토는 [expe-pass5-row-audit.json](verification/parity-r23/expe-pass5-row-audit.json), 남은 38행은 [expe-pass5-remaining.json](verification/parity-r23/expe-pass5-remaining.json)이다. 4차 보고서와 ledger는 expe-pass5-start-report.md / expe-pass5-start-ledger.json에 보존했다.

## 바뀐 동작

경험치 지급을 실제 74-level.lua의 전체 상태·지급량·레벨업 문구·중복 호출·연대기 문구와 비교했다. 숫자 sid와 문자열 sid를 구분하고, pm 중복/빈 자리/알 수 없는 동료, 편성 fallback, persona 없음, 경험치 0·음수·숫자 문자열·잘못된 문자열을 다뤘다. 동료 레벨이 없는 상태에서는 persona를 먼저 레벨업한 뒤 그 시점의 persona 레벨로 동료의 누락 레벨을 정해야 했다. 실제 실패 결과 60건을 expe-pass5-branch-before-results.json에 보존했다(누락 레벨 관련 12건과 후보 호감도 표시 48건). 수정 후 전부 통과했다. source town 기본값은 transient 경계에서만 쓰며 native xp_r22에는 기존 지급 표식만 저장한다.

선택 층의 범위 정규화와 출발 직후 빈 last를 원본에 맞췄다. 탐색 문구·로그와 휴식 회복 안내에 원본 영어 언어 팩을 연결했다. 반복해서 직접 호출한 휴식은 원본처럼 다시 회복한다. 이 차이를 확인한 24개 Lua 사례를 근거로 기존 expedition_r22_test의 1회 회복 고정 기대값을 반복 호출의 회복 상한 계산으로 바꿨다. 중복 탐색·보스 출발·정산 차단은 기존 시험 그대로 통과한다.

마을 출전 이름에 참전 persona를 먼저 포함했다. 이름 fallback, 중복/알 수 없는 동료 이름, 번역된 tag 순서, town 기본값·동일 참조 반환을 직접 비교했다. 마을 전체 화면이나 시설 이동 handler를 이 일부 근거만으로 승격하지 않았다.

탐색·휴식 화면은 원본의 층/구역/심층/보스/적 레벨/금화/물건 수/경험치, 진행 표식, 긴 발견 문구, 파티 직업/레벨/HP/MP와 사용할 수 있는 물약을 native 노드로 표시한다. 물약의 원본 표시 이름·보유량·레벨 부족·쓰러진 대상·재고 없음 조건과 실제 버튼 사용 후 주머니 우선 소비를 확인했다. 퇴각 안내는 보스 보상/돌파 기록을 받지 못한다는 원문과 퇴각/계속 버튼 순서를 따른다. 정산은 원본의 정렬된 아이템·장비·경험치·레벨업·호감·손실 문구와 다음 층/귀환 선택지를 표시한다.

출정 후보 카드에는 출전 중인 동료도 정렬 순서대로 남기고 직업·열·레벨·속성·호감도를 표시했다. 원본 PX.aff는 소수를 내린 뒤 bar에 넣으므로 99.9의 표시도 맞췄다. 세 필터의 종류/순서/선택 상태와 빈 목록 안내, 출전 수/평균/적 레벨/전열 수/경고를 비교했다. 이미 보존된 이전 persona_world 테스트 경로는 시작 시점과 SHA-256이 같은 출정 화면을 별도 파일로 보존해 연결했다.

HTML 태그·style·class 문자열은 같음 판정에 쓰지 않았다. 실제 Lua 반환에서 text/action/활성 조건/표식/게이지를 추출하고 native가 그린 Label/Button 및 상태 변화를 비교했다. 같은 native 화면 입력을 정본 Lua로 다시 실행한 24건도 일치했다. 1·3·27·28·55·420층의 보스/심층 및 다음 층 허용 여부는 추가 216사례에서 비교했다. raw source 레코드는 비교와 표시를 위한 일시적 투영이며 native 저장 스키마를 대체하지 않는다.

## 검사와 보존

무거운 전체 검사는 로컬 node server/abyss-save/test/serve.mjs를 띄워 한 번 실행했다. 최초 118그룹 중 116그룹 통과, 2그룹은 영어 퇴각 안내의 줄바꿈 높이 초과를 보고했다. 최초 실패와 로그는 [expe-pass5-suite-final](verification/parity-r23/expe-pass5-suite-final)에 그대로 있다. 검사 도중 제품·시험 GDScript 변경은 없었다.

그 뒤 제품 변경은 expedition_screen_r22.gd의 안내 폭 118→354px 및 오른쪽 정렬 두 줄뿐이다. 원문을 유지해 한 줄에 들어가게 했고, 실패한 두 그룹을 포함한 관련 UI 6그룹을 다시 실행해 전부 통과했다. 전체 검사 반복 없이 최종 118그룹 실패 0을 집계했다. 최초 결과와 보정 실행을 구분한 근거는 [expe-pass5-final-checks.json](verification/parity-r23/expe-pass5-final-checks.json), 보정 실행은 [expe-pass5-ui-correction](verification/parity-r23/expe-pass5-ui-correction)에 있다. 전투 대조는 8개 원본 audit의 실제 새 결과를 합산했다.

360×780·390×844, 한국어·영어의 실제 포인터 입력/스크롤/저장 재개/취소/확정/재정산 거부를 확인했다. 전용 캡처 20장이 expe-pass5-render/에 있다. 직접 열어 본 이미지는 expe-pass5-visual-review.json에 기록한다. 처음 발견한 배경 위 문구 대비 문제는 정보 영역에 불투명한 바탕을 넣어 고쳤다. Web/WASM 내보내기·브라우저 실기기는 확인하지 않았다.

기존 파일 변경은 9개다. 게임 규칙: expedition_world_r22.gd, persona_rules.gd, persona_world.gd, town_rules_r21.gd, town_world_r21.gd. 화면: expedition_screen_r22.gd, persona_sortie_screen.gd, town_screen_r21.gd. 시험: expedition_r22_test.gd. 새 구현은 expedition_ui_r23.gd, expe-ui-r23.json과 앞서 보존한 expe_sortie_legacy_r23.gd이며, 새 시험/도구/대조 자료는 expe 접두로 추가했다. 새 번역은 정본 05-gen.lua의 언어 팩에서 해당 표시 키만 추출했다. source, 서버, 전투 코드·시험, docs, 보호 이미지 바이트를 시작 해시와 비교했다. 사용자 저장 접근/삭제, 저장 schema 변경, git 명령·커밋·Web export·버전 갱신은 없다.

## 남은 38행

원본별: 70-town.lua 9행, 75-sortie.lua 7행, 76-dungeon.lua 1행, 77-explore.lua 15행, 78-battle-item.lua 6행.

주요 실제 차이는 마을 본문/시설 설명/의뢰 카드 누락, 출정의 모드·슬롯·문구, ask 때 기존 파티 정보를 함께 남기는 구성, 휴식 정비의 선택지/순서, 패배 뒤 run 제거와 마을 이동, 포화 가방의 overflow 보존, canonical 원본 저장/옛 stage 입력 미지원이다. 전투 아이템·전투 snapshot의 전체 경계는 여전히 수정 금지인 전투 파일에 걸친다. 수정이 허용된 화면/마을/의뢰의 나머지 기능도 아직 완료하지 못했다. 이 38행에는 단순히 HTML/native 매체가 다르다는 이유만 남긴 행이 없다.

P2794는 AI에게 줄 문맥만 만드는 CTX 함수이므로 공통 기준에 따라 제외했다. P3134의 이름 비교는 명시적으로 제외한 79-sex 전용 charm_potion 분기를 빼고 같음으로 기록했으며, 해당 아이템/장면은 추가하지 않았다. 70행 같음은 이 묶음의 행 판정이며 프로젝트 전체 완성률이 아니다. 기존 316/318 명시 진입 수치를 이번 기능 대조의 전수 조합 증명으로 쓰지 않았다.

재현: node tools/expe_r23_pass5_oracle.mjs → python tools/expe_r23_pass5_project.py → python tools/godot_r17.py --headless --script res://tests/expe_pass5_r23_test.gd. 실제 화면은 ui_expe_pass5_r23_test.gd 실행 후 node tools/expe_r23_pass5_ui_oracle.mjs → python tools/expe_r23_pass5_ui_verify.py. 추가 층/정산은 node tools/expe_r23_pass5_extra.mjs → python tools/expe_r23_pass5_extra_project.py → Godot의 res://../verification/parity-r23/expe-pass5-extra.gd. 전체 검사 도구는 결과 덮어쓰기를 막는다. 재실행하려면 새 EXPE_SUITE_NAME을 지정한다.

도구 메모: Impeccable detector 결과는 []였다. 기존 DESIGN.md와 .impeccable/design.json의 갱신 시점 차이는 그대로 뒀으며, 필요하면 별도 document 작업으로 동기화할 수 있다.
