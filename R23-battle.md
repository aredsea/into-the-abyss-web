# R23-battle 3차 작업 보고

대상 212행: 이번 같음 +30, 누적 같음 65, 남음 147. 이번 수정 6행, 누적 수정 근거 27행이며 같음과 17행 중복한다. 원본 전 기능 이식 완료는 아니다.

이번 묶음 4,538개 / 실패 0. 누적 신규 대조 23,418개 / 실패 0. 기존 6,320판 · 219,785기록 / 차이 0.

프로젝트 검사 90/90그룹, 실패 0, 미실행 0, 실행 중 0. 최종 코드 검사 완료.

## 직접 대조와 수정

원본 18종 oracle를 함수/then/else/do 진입 계측으로 재실행했다. 계측 전후 관측값 일치. 대상 함수 166/212 호출, 기존 미검증 진입 68/157 도달(2차 58). 진입 수만으로 승격한 행은 없다. 원본과 96개 원본 이미지의 해시를 직접 확인했다.

원본 local closure는 로드 사본에서 실제 closure를 노출한다. 정렬 comparator도 원래 본문을 이름 붙인 closure로 바꿔 export하며, 복사한 대체 함수를 oracle로 쓰지 않는다. Boolean/빈 Lua map의 표현만 명시적으로 정규화한다. 일반 실수 오차 1e-7, 정수·RNG는 정확 비교한다.

|새 근거|행 수|
|---|---:|
|옛 능력치·편성·균열·층 계획|5|
|이름·조사·동사·기술명·비율 문구|11|
|보스 설명·적 방어·시작/차례 시작|4|
|개인 특성·부식·시전자 정리·방어 상수|6|
|시너지 표시/생존 표식/경험치/DOT 정리|4|

행별 원본 위치·이전 상태·시험 라벨·제품 파일:줄·남은 사유는 verification/parity-r23/battle.json에 있다.

수정한 계약: 부식의 저장 K 우선값과 floor epsilon; 군힐트의 같은 행동/다른 표적 무보너스; 바르굿의 당김 없음·음수/0일 때 signed 게이지와 상태 보존; 빈 유닛/비문자열 표식 제외; 옛 적 수치 API의 별 인덱스 기본값. 원본 기대 수치는 변경하지 않았다.

수정 전 증거를 구분한다. 첫 1,392개 중 실패 1,186개는 API 부재 guard 1,152개와 기존 부식 수치 실패 34개다. 문자열 API 추가 전에는 177개 guard 실패를 보존했다. 별 입력 확장에서는 378개 실패 중 252개가 typed kind API guard, 126개가 새 호환 API의 실제 fallback 수치 불일치다. 생명주기 확장 전 99개 실패는 API guard 98개와 empty 표식 수치 실패 1개다.

군힐트·바르굿의 이전 인라인 절은 별도 사본에서 재구성해 90입력 중 15개 불일치를 재현했다(round3-before-inline.gd/.json). 전체 수정 전 빌드가 아니며 다른 피해/차례 훅과 상위 함수 전체의 실패 수로 합산하지 않는다. 오래된 부분 log의 fixture/parse error가 있는 시도는 통과 검사나 실제 제품 실패 수에 넣지 않았다.

새 legacy foes_for/enemy_stats/floor_plan은 호환용 순수 API다. 기존 native 저장 이관이나 시작 흐름 전체의 동치를 뜻하지 않는다. 원래 floor_enc의 dn.kind는 유지한다. 문구 helper를 옮긴 것만으로 상위 로그 전체가 같다고 세지 않았다. 신규 저장 형식·버전은 도입하지 않았고 사용자 저장은 열지 않았다.

## 변경 파일

- project/game/battle_stats_r23.gd
- project/game/battle_v3.gd
- project/game/combat_display_r22.gd
- project/game/dungeon_enemy_r21.gd
- project/game/dungeon_rules_r21.gd
- project/game/personal_rules_r22.gd
- project/game/trait_rules_r22.gd

expedition_rules_r22.gd는 기존 EXP 계산을 읽기 전용 대조했으며 수정하지 않았다. 새 시험은 battle_r23_round3_test.gd, oracle는 tools/oracle_battle_r23_round3.mjs/.lua와 생성된 loader다. 전체 재실행은 tools/verify_battle_r23_round3.py, 최종 수정 전 시작한 검사를 재실행하는 도구는 tools/finalize_battle_r23_round3.py다.

## 검사·보존

전체 검사 로그: verification/parity-r23/suite-round3-final/. import, 모든 *_test 및 필수 integration/export_licenses와 전체 전투 8묶음을 포함한다. 수정 전 시작한 프로세스의 검사는 시작 시각으로 골라 최종 코드에서 재실행하고 첫 로그/결과는 first-pass/에 보존한다. 판단 근거는 final-recheck-plan.json 및 final-code-lock.json이다.

클라우드는 node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs로 실제 Worker/D1 서버를 실행했다. 빈 loopback 포트와 이 worktree의 임시 디렉터리를 사용하며, 기존 다른 포트/프로세스는 종료하지 않는다. 자체 제어 파일로 이번 서버를 정상 종료한다. 서버 제품 파일 수정은 없다.

docs/·project/assets/·server/는 이번 시작 manifest 기준 변경 0. Web export·버전 갱신·git 명령·커밋 없음. 결과 이미지 3개를 직접 확인했으며 경로/해시는 visual-review-round3.json에 있다. 전수 이미지·실기기·Web/WASM 시험은 하지 않았다. Windows root certificate store 메시지만 환경 진단으로 제외하고 Script error/그 밖의 ERROR는 검사 실패로 센다.

초기 fixture 실행 1개가 Script error 뒤 종료되지 않아 런타임 프로세스가 남았다. 해당 프로세스에 대한 종료 명령은 OS 접근 거부로 실패했다. 이후 단독 실험에는 quit-after 제한을 사용했다. 다른 기존 런타임 프로세스는 건드리지 않았다.

## 남은 작업

- 30인 개인 기술·개별 특성: 같음 19, 남음 12.
- CTB·공격·종결·전투 버튼: 같음 11, 남음 24.
- 적 방어·반격·소환·단계: 같음 6, 남음 24.
- 전투 사건 연출·HUD·대상·로그: 같음 0, 남음 41.
- 전투 상태·능력치·편성: 같음 23, 남음 24.
- 종족·출신·직업 시너지: 같음 5, 남음 8.
- 페르소나 단일 연구 기술: 같음 1, 남음 14.

최종 재검사의 첫 클라우드 묶음은 이전 shutdown 제어 파일을 읽어 서버 시작이 실패했고, 다음 시도는 D1 스키마 준비 전에 시험을 요청했다. 시험 도구를 실행별 고유 제어 파일과 runtime 완료 대기로 고치고 해당 28개 그룹을 모두 재실행했다. 원시 실패 로그는 recheck-*-failed-*.log, 복구 결과는 cloud-group-recovery.log 및 final-verification.json에 남겼다. 서버 제품 코드 수정은 없다.

RNG=1 약점 순환 경계는 수정 전 실제 제품에서 비교 실패 1개와 범위 초과 Script error를 재현한 뒤 clamp하여 통과시켰다. round3-cycle-before.json/.log는 fixture 오류와 구분한 실제 제품 경계 실패 근거다.

원본 VER2·채팅 변수·pend/pid 저장 재개, 사건의 모든 필드 시간 이력/payload, 훅 합성과 측정용 변형, 상위 기술/종결의 전체 로그, HUD·대상·버튼·카메라의 의미상 전체 출력은 계속 남는다. 전투 수치가 같다는 이유로 상위 함수를 승격하지 않았다.

재실행: node tools/oracle_battle_r23_round3.mjs → python tools/coverage_battle_r23.py → python tools/verify_battle_r23_round3.py → python tools/finalize_battle_r23_round3.py → python tools/report_battle_r23_round3.py. 이전 차수 보고/ledger는 R23-battle-round2.md 및 battle-round2.json으로 보존했다.
