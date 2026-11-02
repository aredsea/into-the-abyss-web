# R23-ui · 2차 이어하기

**2차: 잔여 109행 중 같음 +10행, 수정·구현 17행, 미확인→일부 1행. 잔여 99행.**
누적 **같음 45/144행**, 수정·구현 30행(같음과 중복), 잔여 {'없음': 2, '일부': 89, '미확인': 8}다. 전체 기능 이식 완료로 판정하지 않았다.

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
|프로젝트 전체 import·시험·현재 대조 entrypoint|89종 / 실패 0 / 누락 0|
|2차 원본 Lua 함수 대조|3,220건 / 실패 0|
|2차 native 화면·포인터·저장 재개|777건 / 실패 0 / 12캡처|
|2차 복원/쓰기 실패/회상 재개|8건 / 실패 0|
|1·2차 원본 규칙 대조 합계|14,069건 / 실패 0|
|로컬 Worker/D1 서버 시험|8종 / 실패 0|
|전투 trace|6,320/6,320판 일치|
|보호 원본 자산|96개 / 변경 0|

전체 검사는 한 번 실행하고, 발견된 생성 단계 회귀 59건을 수정해 해당 기존 4,005개 검사와 새 3,220개 대조를 다시 통과시켰다. 최초 전체 실행 이력은 `phase2/regression-full-initial.json`, 생성 회귀 원문은 `phase2/persona-numeric-baseline.log`에 보존한다. 원인은 GDScript `match`의 정수/실수 타입 구분이었으며 Lua처럼 숫자값을 비교하도록 고쳤다. 일반 클라우드 시험은 지시된 `node server/abyss-save/test/serve.mjs`를 사용했다. 만료 표본은 기존 `godot-r3.mjs` 전용 wrapper가 준비한다. Windows 인증서 저장소 진단은 기존 환경 진단으로 분리했으며 SCRIPT ERROR와 시험 실패를 숨기지 않았다. 2차 초기 불일치/미구현 검출은 `phase2/baseline.json`의 2,403건 중 422건이며 보존했다. 새 fixture에서 발견한 빈 Lua table의 JSON 배열 표현과 nil 반환도 최종 검사에 포함한다. 기존 시험 기대값은 바꾸지 않았다.

전체 검사 뒤 로컬 서버의 Windows `taskkill` 종료가 한 번 시간 초과했다. 검사 도구에만 stdin 종료 preload를 더해 원래 `serve.mjs`의 SIGINT/Miniflare dispose를 호출하도록 고쳤으며, 준비 여부도 새 자식 프로세스의 ready 출력으로 확인한다. 기존 서버 부모/자식은 작업 경로·명령·생성 시각을 확인해 정리했다(`phase2/runtime-cleanup.json`). 실제 클라우드 27개 검사와 복원 8개를 다시 통과했고 최종 서버는 요청한 SIGINT로 정상 종료했다(코드 130 포함). 강제 종료 없음·8787 포트 해제도 확인했다(`server-lifecycle.json`). 서버 제품 파일은 수정하지 않았다.

## 남은 것

남은 99행은 HTML/CBS 전체 반환, RisuAI 이미지/채팅/비동기 callback, 전체 언어 사전·설정, 전투 상태창, 원본 v1 코드 가방/장비와 native UID/schema 3의 전체 보존 계약, /s·/l·6자리 PIN과 native /v1·10자리 PIN·CAS 및 운영 순위 계약이다. 단순 Lua 실행이나 native 회귀 통과를 전체 동일성으로 승격하지 않았다. 내부 ror는 엔진 SHA 구현 위임, copy는 저장 미지정 필드 보존 정책의 차이로 없음 2행을 유지했다. 성적 장면은 제외했다. 배포·운영 HTTPS/Turnstile·물리적 두 기기 검사는 하지 않았다.

실제 화면은 360×780·390×844·430×932, 한글·영어를 검사했다. 직접 연 캡처와 관찰은 `phase2/visual-review.json`이다. 영어 모드의 일부 한국어 fallback을 포함한 전체 번역 완성도는 잔여이며, 모든 기존 회귀 캡처를 직접 검토했다는 뜻은 아니다.

전투·장비 규칙·원정 규칙·원본 프로젝트·다른 worktree·docs 쓰기, git 명령, Web export와 배포는 수행하지 않았다. 쓰기 경계는 `phase2/write-audit.json`, 1차 포함 경계는 `write-audit.json`에 있다. Impeccable 기계 검사 결과는 0건이지만 Godot의 실제 시각 검증은 캡처/포인터 시험을 근거로 한다. 디자인 보조 파일 `.impeccable/design.json`이 DESIGN.md보다 오래되었다는 기존 진단은 기록만 했다. 별도 요청 시 `document`로 갱신할 수 있다.

재현: `node tools/ui_r23_phase2_oracle.mjs` → `python tools/ui_r23_phase2_data.py` → `node tools/ui_r23_phase2_dependencies.mjs` → `python tools/ui_r23_verify.py` → `python tools/ui_r23_server_tests.py` → `python tools/ui_r23_snapshot.py` → `python tools/ui_r23_phase2_report.py`.
