# R23-ui · 4차 기능 등가 대조

남은 54행 전부 검토: **같음 +19 · 수정/보완 27행(같음과 중복) · 남음 35행**.
누적 **같음 84/144 · 대체 21 · 제외 4 · 남음 35**. 기존 완료 90행의 JSON 객체는 그대로 보존했다.

행 id·원본 위치·기존 판정 사유·이전 상태·새 시험·남은 이유: [ui.json](verification/parity-r23/ui.json). 이번 54행만: [ui-row-review.json](verification/parity-r23/ui-phase4/ui-row-review.json). 원본 재감사의 작업 items도 ui-original-work-items.json에 보존했다.

## 고친 내용

- 원본의 공개 UI 사전 894키와 데이터 번역 사전 3184키를 별도로 싣고, 전체 집합 및 한영 lookup/변수 치환을 실제 Lua와 대조했다. native 전용 번역·일반 render와 U/T 계약을 분리해 같은 한국어가 메뉴 동작과 능력치 이름에서 다르게 번역되는 경우를 바로잡았다. 성인 키 647개는 목록만 남겼다.
- 도감의 페르소나 버튼 순서·호감 막대·즐겨찾기 표식, 즐겨찾기 카드의 속성·호감 문구·HP/MP·순서를 맞췄다. Godot ProgressBar의 기본 간격이 99/200을 0.500으로 만들던 실제 차이를 0.495로 고쳤다.
- 전체 30명×한영 상세의 태그·스킬·직업/종족/출신 패시브·계통 표시를 직접 대조했다. 여우/늑대는 개과, 표범은 고양이과라는 정본의 표시 분류를 적용했다. 정본에 실제 존재하는 특성 아이콘 4개를 새 경로로 바이트 그대로 복사했다. 다른 26개는 새로 지어내지 않았다.
- 가방 90개 목록 상태와 상세 212개 상태를 대조했다. 없는 비교 효과의 `-`, 강화 표지·직업/부위·고유 효과·판매 확인 순서, 빈 비교 대상·여러 비교 대상·없는 장착 대상·모든 등급/직업·레벨 1/40을 확인했다. 사라진 선택은 원본처럼 목록으로 돌아가며 재개 뒤에도 정리가 유지된다.
- 2,000칸 가방의 장비 교환, 1,999/2,000칸 해제, 중복 코드 수량, 이미 팔린 장비의 판매/장착, UID 장착 및 재개를 실제 native 어댑터로 비교했다. 빈 장비 해제 오류와 불필요한 성공 알림, 판매 후 선택 정리, 판매된 장비 장착 오류를 고쳤다.
- 설정의 언어/난이도/연대기 32개 상태와 원본 레이블/선택/공개 설명을 비교했다. 확인 중에도 설정이 남고 난이도 변경으로 초기화 확인이 닫힌다. 설정에서 기존 클라우드 대체 계정 화면으로 들어갈 수 있게 연결했다. 채팅/AI host 설명은 공통 제외 기준에 따라 공개 기능 설명만 남겼다.

## 직접 실행 결과

|검사|결과|
|---|---:|
|새 Lua/native 규칙·이름·사전·초상·저장 경계|10,955 / 실패 0|
|새 실제 UI·포인터·레이아웃|6,661 / 실패 0|
|새 캡처|27장 / 360×780·390×844·430×932 × 한영|
|현재 프로젝트 import·전체 시험·trace|134종 / 실패 0 / 누락 0|
|실제 로컬 Worker/D1 package 시험|9종 / 실패 0|
|전투 대조|6,320 / 6,320판 일치|
|보호 원본 자산|96개 / 변경 0|

전체 결과는 ui-regression.json, ui-suite-coverage.json, server/ui-results.json에 있다. 서버는 기존 serve.mjs를 메모리 포트 어댑터로 실행해 기존 리스너와 충돌하지 않게 했다. 의존성은 다른 작업 공간의 기존 설치를 읽기만 하고, wrangler 해석도 런타임 모듈 hook으로 연결했다. 서버 디스크 수정/원격 배포는 없다. Windows 인증서 저장소 진단은 분리 기록했으며 SCRIPT ERROR나 검사 실패를 제외하지 않았다.

수정 전 표시 대조 실패 308건은 ui-native-baseline.log에 남겼다. 사전은 보존한 이전 데이터를 주입하는 ui-dictionary-baseline.json으로 재현한다. 상세/설정/장비 경계의 수정 전 로그도 별도 ui- 접두 파일에 있다. 최초 실험 중 import 미완료, Lua 빈 table의 배열 표현, 필수 장착 맵을 지운 fixture, 반복 parser 생성, 강제 전투 전환을 탄 fixture는 바로잡았다. 성인 설정을 끈 공개 fixture로 대조하며 성인 장면은 이식하지 않았다.

기존 settings_r22_test는 사전 순회 계약을 보완했다. 원본 실행 사전에 없는 native 시나리오 19개를 B.T 번역으로 기대하던 검사를 원본 U/T fallback 검사와 native render의 기존 영어값 보존 검사로 나눴다. 영어 번역 값은 바꾸지 않았다. 기존 207,781검사의 19실패는 ui-settings-dictionary-before.log에 보존했다. 최종 공개 사전 검사는 ui-regression.json의 settings_r22_test에 체크 수와 실패 0을 기록한다. 수치·난수·전투 기대값은 변경 0이다. 성인 전용 intimacy 사전은 공개 번역 파일과 공유하는 키만 남기고 이식 대상에서 제외했다.

## 남은 35행

생성 화면·시나리오·초기 상태·전체 저장 이관·전투/마을 HUD와 연결된 행은 이번 수정 금지 범위다. 허용 상세/가방 표시를 고쳤어도 옛 문자열 장착 저장이나 실제 전투 진입의 전체 관찰이 남은 복합 함수는 같이 승격하지 않았다. 각 행의 구체적인 사유와 파일은 ui-row-review.json에 있다. HTML 태그나 저장 매체가 다르다는 이유만으로 남긴 행은 없다.

주요 남은 의존성: create_screen.gd, persona_*, world_screen.gd, town_screen_r21.gd/town_world_r21.gd, gear_*, 전투 파일, cloud_screen_r22.gd. 이 파일·서버·docs는 변경 0이다. git 명령과 Web export도 실행하지 않았다. [ui-write-audit.json](verification/parity-r23/ui-phase4/ui-write-audit.json)에 변경 파일·자산 hash·대조 파일 크기를 기록했다.

새 영문 번역으로 드러난 대화창 호감 라벨 1,440건의 넘침은 localization의 글자 맞춤 함수에서 원래 슬롯 폭을 기준으로 계산해 고쳤다. 생성 직후 Label 폭이 162로 잠시 늘었다가 원래 148로 돌아오는 상태를 기존 metrics로 처리하며, 마을 파일은 변경하지 않았다. 수정 전은 ui-dialogue-overflow-before.log에 보존했다.

화면 직접 검수는 ui-visual-review.json에 기록한다. 새 27장만을 대상으로 하며 기존 회귀 검사 캡처 전체를 열었다는 뜻은 아니다. 영문 모드의 공통 HUD/뒤로 등 일부 원본 fallback은 남아 있고 해당 전역 화면은 동결 범위다. 디자인 기계 검사는 변경 화면 6개에서 0건. 기존 DESIGN.md와 .impeccable/design.json의 시차는 수정하지 않았으며 별도 `document`로 갱신할 수 있다.

재현: node tools/ui_r23_phase4_screens_oracle.mjs → node tools/ui_r23_phase4_edges_oracle.mjs → python tools/ui_r23_phase4_data.py → python tools/ui_r23_phase4_verify.py → python tools/ui_r23_phase4_server_tests.py → python tools/ui_r23_phase4_report.py.
