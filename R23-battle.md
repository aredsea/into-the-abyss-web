# R23-battle 8차 보고

대상 212행: 같음 179(+10), 호스트 제외 3, 남음 30(−10). 이번 수정 근거 13행(중복 포함), 신규 수정 근거 13행, 누적 수정 근거 74행. 전 기능 완료는 아니다.

신규 27,531개 검사 중 원본 Lua 직접 대조 27,530개와 native 저장 경계 1개, 실패 0. 누적 신규 검사 93,799개. 전체 프로젝트 121/121그룹(import 포함), 로컬 serve.mjs/D1 클라우드 시험 통과. 기존 6,320판·219,785기록 차이 0.

원본 Lua 19개에 함수/then/else/do 진입 계측을 적용하고 oracle 29묶음을 실행했다. 계측 전후 결과는 같고 기존 6,320판 원본 trace도 저장된 기준과 같다. 함수 200/212 호출, 기준 미검증 진입 142/157 도달(7차 112). 진입 도달은 조건 조합 전수 증명이 아니다. coverage/에는 oracle 중복 사본 없음.

묶음별로 차례 종료 384, DOT 90, abyss 512, 기술 사용 조건 7,936, 적 단일/전체 공격 256, 주디스 42, 요르드 256, 사망 효과 정리 64, 경험치 1,440, finish/check_end 512, 연구 행동 16,038개를 실행했다. native 저장 1개는 보호막 만료 뒤 실제 snapshot 재개 여부다.

실제 공격과 개인 기술에서 원본의 심연/고갈·전염 list·부식/출혈 사건·필드 이력·시각·로그를 기록하도록 보완했다. 단일 적 공격 본문은 attacked/counter 훅보다 먼저 기록하고 전체 공격 본문은 대상별 훅 뒤에 기록한다. 차례 끝에는 침묵·서약·공격 배율·보호막을 원본 규칙으로 만료하며 native 저장에 0턴 효과를 남기지 않는다. 죽은 아델린의 재생 제거와 미등록 개인 기술 거절도 연결했다.

페르소나 연구는 saved/draft/spent/gold/message core 전이만 한영 직접 비교했다. 영어 메시지 누락을 수정했고 persona_world.gd는 언어 전달 한 줄만 연결했다. 원본 pending 지시/채팅은 oracle에 별도 보존하며 native 대화 재개와 같다고 세지 않았다. 해당 2행은 남음이다.

수정 전 재생: 시작 시 보존한 battle/personal/enemy 모듈과 최종 동일 입력으로 8,324개를 실행하여 122개 차이를 확인했다: {'judith': 42, 'jorund': 64, 'can_use': 16}. 새 API 부재 guard는 수치 버그로 세지 않았다. 이는 전체 옛 빌드 재현이 아니라 보존한 모듈 조합의 실제 실행이다. 연구 메시지·새 정산 기록·저장 경계 검사는 이 차이 수에서 제외했다.

최초 전체 실행에서 손상 x=false 입력을 native에 옮기는 시험 준비가 Dictionary.has를 잘못 호출해 중단했다. 기대값은 유지하고 fixture의 타입 가드 두 곳만 고친 뒤, 새 suite-round8-final-v7에서 전체 검사를 처음부터 재실행했다. 최종 제품/시험/입력 SHA는 모두 잠겨 있다. 중간 실패·취소 실행은 최종 통과 수에 섞지 않았다. Windows root certificate store 메시지만 환경 진단으로 제외했다.

전체 회귀 중 축약 편성 정산의 4칸 경계와 전체 공격 도중 소생한 다음 아군 칸을 빠뜨리는 차이도 발견했다. 결과 projection에 빈 아군 칸을 채우고, 전체 공격은 각 칸에 도달할 때 생존 여부를 확인하도록 고쳤다. 원래 실패하던 장비 176판이 기대값 변경 없이 통과했다.

기존 7차 대조의 70건은 사망 뒤 cover_turns=0을 불필요하게 남긴 차이였다. 원본처럼 제거한 뒤 1,418개가 재통과했다. expansion_test에서 옛 전투가 r21 전용 기록 객체를 부르는 오류도 확인해 보존한 기존 abyss 처리로 분리했다. 기존 3,350개 수치·저장 회귀를 통과한 뒤, 최종 코드를 다시 잠가 121그룹 전체를 실행했다.

임시 combat_meta 저장 필드는 기존 서버 검증기에 422로 거절됨을 확인했다(battle-round8-cloud-meta-rejection.json). 서버를 바꾸지 않고 해당 저장 필드 증설을 제거했다. 기존 로컬/클라우드 저장 스키마를 유지하며, 정산 메타데이터의 저장 재개는 남음으로 기록한다.

무효 등급이 보상 설정의 다른 키 이름과 겹치는 경계도 추가했다. v4에 잠긴 이전 정산 코드 SHA와 같은 파일을 재생하면 72개 차이가 나며, 명시적인 3종 레이드 등급만 조회하도록 수정한 뒤 전체 1,952개 정산 대조가 일치한다.

| 묶음 | 같음 | 제외 | 남음 |
| --- | ---: | ---: | ---: |
| 30인 개인 기술·개별 특성 | 29 | 0 | 2 |
| CTB·공격·종결·전투 버튼 | 23 | 2 | 10 |
| 적 방어·반격·소환·단계 | 30 | 0 | 0 |
| 전투 사건 연출·HUD·대상·로그 | 38 | 0 | 3 |
| 전투 상태·능력치·편성 | 36 | 1 | 10 |
| 종족·출신·직업 시너지 | 12 | 0 | 1 |
| 페르소나 단일 연구 기술 | 11 | 0 | 4 |

같음 승격: P1737, P1760, P1789, P1806, P1824, P1830, P1842, P1945, P2004, P2171. 각 행의 원본 id·위치·이전 상태·시험·제품 파일:줄·남은 이유는 verification/parity-r23/battle.json.

남은 30행: 시작/재시작·battle_pm/quest/battle_start, 원본 저장 직접 재개, 임의 훅 fire/chain/chain_at, strike·적 차례/run·버튼/행동 패널/최상위 render, 일부 개인/종족·페르소나 기술, 연구 화면/대화 연계와 native 결과 컨텍스트 전체 연결. 직접 finish 상태는 일치해도 모든 world의 rg/qmult·출처 연결은 별도로 남겼다.

원본 이미지 96개 해시 일치. docs/assets/server 해시 불변. 사용자 저장은 열거나 지우지 않았으며 Web export·버전 갱신·git 명령 없음. 기존 저장 스키마를 유지한다. 정산의 nd/마지막 일격 기록을 저장 재개 뒤 복구하는 범위는 남음이다.

렌더 QA는 verification/parity-r23/battle-round8-visual-review.json에 직접 연 파일·SHA·관찰을 기록한다. 전수 프레임/실기기/Web/WASM은 확인하지 않았다. 새 대조 파일은 battle- 접두, 각각 40 MiB 미만.

바꾼 제품 파일:

- project/game/battle_v3.gd
- project/game/combat_outcome_r23.gd
- project/game/dungeon_enemy_r21.gd
- project/game/personal_rules_r22.gd
- project/game/persona_research_r21.gd
- project/game/persona_world.gd

재실행: oracle_battle_r23_round8_loader.mjs (기본, R23_ROUND8_PACK=outcome/persona) → coverage_battle_r23.py → verify_battle_r23_round8.py (R23_FINAL_SUITE=suite-round8-final-v7) → prepare_battle_r23_round8_before.py 및 before-test.gd → 렌더 확인 → report_battle_r23_round8.py.

바꾼 시험/도구:

- tools/coverage_battle_r23.py
- tools/diff_battle_r23_round8.py
- tools/oracle_battle_r23_round8.lua
- tools/oracle_battle_r23_round8_loader.mjs
- tools/oracle_battle_r23_round8_outcome.lua
- tools/oracle_battle_r23_round8_persona.lua
- tools/prepare_battle_r23_round8_before.py
- tools/report_battle_r23_round8.py
- tools/verify_battle_r23_round8.py
- project/tests/battle_r23_round8_outcome_test.gd
- project/tests/battle_r23_round8_persona_test.gd
- project/tests/battle_r23_round8_test.gd
