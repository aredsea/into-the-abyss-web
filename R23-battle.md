# R23-battle 7차 보고

대상 212행: 같음 169(+16), 호스트 제외 3, 남음 40. 이번 수정 근거 10행(기존 수정 행과 중복), 누적 수정 근거 61행. 남은 40행이 있어 전 기능 완료는 아니다.

신규 묶음 대조 7,334개(전투 1,418 + 페르소나 5,903 + 방어 경계 13), 실패 0. 누적 신규 대조 66,268개, 실패 0. 전체 프로젝트 118/118그룹과 import/로컬 클라우드 서버 통과. 기존 6,320판·219,785기록 차이 0.

원본 Lua 26종을 함수/then/else/do 진입 계측으로 다시 실행했다. 계측 전후 반환 결과가 같고, 기존 6,320판 원본 trace도 저장된 기준과 같았다. 함수 198/212 호출, 기준 미검증 진입 112/157 도달(6차 100). 조건 조합 전수 검증 수치는 아니다. coverage/에는 새 oracle 중복 사본을 만들지 않고 메모리에서 비교한다.

반격·피격 후 지연·적 DOT·소환·충전 취소·단계 전환의 실제 전투 경로에서 원본 사건, 필드 시간 이력, 로그 문구와 T를 기록하도록 보완했다. 컷인에는 원본 skill id별 대사와 이름을 기록한다. 페르소나 연구의 임시 조합 우선순위·전체 조각 비교·dirty·변경 서술 배열을 원본과 대조하고 기존 연구 경로에 공통 helper를 연결했다. persona_world.gd는 이 연결 두 줄만 바꿨다.

실패 확인: 작업 시작 시 보존한 Battle/Enemy 파일과 최종 동일 입력으로 656개를 재생해 614개 관측 차이를 확인했다. {'counter': 288, 'foe_hit_after': 54, 'summon': 128, 'phase': 144}. 같은 경로는 수정 후 통과한다. 이는 이전 전체 빌드가 아니라 보존한 두 파일의 실제 실행이다. 새 API 부재 guard는 수치 버그 수로 세지 않았다.

final-v2 실행 중 enemy_regression의 직접 phase_check 시험에도 같은 begin_ev 전제 누락이 있었다. 기대값은 유지하고 시험 준비 두 줄만 보정해 30항목을 재실행했다. 제품 코드는 그 전후 SHA가 모두 같으며 다른 117그룹의 입력/코드도 불변이다. fixture-correction-audit.json에 이전 시험/로그, 유일한 변경과 재실행을 보존했다. 실행기의 최종 코드 guard는 이 시험 파일 변경을 검출해 종료 1을 반환했으며, 별도 finalize_battle_r23_round7.py가 제품 불변·유일한 fixture 변경·118그룹 결과를 검증해 최종 lock을 확정했다.

전체 검사 중 독립 _tick/DOT 호출이 기록장 없이 시작하는 오류를 확인해 초기화를 보완했다. 관련 A6 251개 통과 후 코드와 기본 입력 SHA를 다시 고정하여 suite-round7-final-v2 전체 검사를 재실행했다. 이전 중간 결과는 최종 통과 수에 섞지 않았다. Windows root certificate store 진단만 환경 메시지로 제외하고 Script error와 다른 ERROR는 실패로 셌다.

검사 도구도 수정했다. 빈 병렬 실행 그룹이 전체 검사를 중복 실행하던 경로를 막고, 이미 시작한 자체 검사에는 파일 기반 중단 표식을 적용했다. 최초 로컬 서버는 긴 임시 경로에서 시작 오류가 났으나 짧은 worktree 내부 .p7tmp로 옮긴 실제 serve.mjs/D1 서버로 최종 검사를 통과했다. 서버 종료 확인은 final-v2/local-server-result.json에 있다.

기능 등가 규칙을 재적용했다. 채팅 검색(P1596), 재렌더 callback(P3502), 채팅 변수 load/bind/act/save 호스트 묶음(P3505)을 제외했다. B.act 자체는 여전히 남음이다. B.load/save는 저장 매체가 달라서 남긴 것이 아니라 원본 기록을 native에서 같은 진행으로 재개하는 직접 왕복·손상 입력 대조가 부족하여 남겼다.

| 묶음 | 같음 | 제외 | 남음 |
| --- | ---: | ---: | ---: |
| 30인 개인 기술·개별 특성 | 27 | 0 | 4 |
| CTB·공격·종결·전투 버튼 | 16 | 2 | 17 |
| 적 방어·반격·소환·단계 | 29 | 0 | 1 |
| 전투 사건 연출·HUD·대상·로그 | 38 | 0 | 3 |
| 전투 상태·능력치·편성 | 36 | 1 | 10 |
| 종족·출신·직업 시너지 | 12 | 0 | 1 |
| 페르소나 단일 연구 기술 | 11 | 0 | 4 |

각 행의 원래 id·원본 위치·6차 상태·시험명·제품 파일:줄·남은 이유: verification/parity-r23/battle.json. 남은 범위는 fresh/again/redo·battle_start 전체, fire/chain 합성, strike/abyss·공격/종결/run·버튼 전체, 일부 개인/종족·페르소나 기술과 연구 행동/장면, 행동 패널/최상위 렌더, 원본 저장 재개다. 이번 중립/무장비 부수 출력 대조를 장비 혼합 전투의 전체 문자열/시간 대조로 확대하지 않는다.

원본 이미지 96개 해시 일치. 작업 시작 manifest 대비 docs/assets/server 해시 불변. 사용자 저장을 열거나 지우지 않았다. Web export·버전 갱신·git 명령 없음. r17~r20과 컷인 렌더 5장을 직접 열어 확인했고, 전수 프레임/실기기/Web/WASM은 확인하지 않았다. 새 대조 파일은 battle- 접두사이며 모두 40 MiB 미만이다.

바꾼 제품 파일:
- project/game/battle_v3.gd
- project/game/combat_events_r22.gd
- project/game/dungeon_enemy_r21.gd
- project/game/persona_research_r21.gd
- project/game/persona_world.gd

재실행: oracle_battle_r23_round7_loader.mjs(기본/환경 R23_ROUND7_PACK=persona,boundary) → coverage_battle_r23.py → verify_battle_r23_round7.py → 별도 battle-round7-boundary-test.gd 및 prepare_battle_r23_round7_before.py → 렌더 확인 → report_battle_r23_round7.py.

바꾼 시험/도구:
- tools/coverage_battle_r23.py
- tools/diff_battle_r23_round7.py
- tools/finalize_battle_r23_round7.py
- tools/godot_r17.py
- tools/oracle_battle_r23_round7.lua
- tools/oracle_battle_r23_round7_boundary.lua
- tools/oracle_battle_r23_round7_loader.mjs
- tools/oracle_battle_r23_round7_persona.lua
- tools/prepare_battle_r23_round7_before.py
- tools/report_battle_r23_round7.py
- tools/run_battle_r23_parallel.py
- tools/verify_battle_r23_round7.py
- project/tests/battle_r23_round7_fixture.gd
- project/tests/battle_r23_round7_persona_test.gd
- project/tests/battle_r23_round7_test.gd
- project/tests/enemy_action_r21_test.gd
- project/tests/enemy_regression_r21_test.gd
