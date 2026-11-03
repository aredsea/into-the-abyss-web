# R23-battle 4차 작업 보고

대상 212행. 이번 같음 +30, 누적 같음 95, 남음 117. 이번 수정 근거 18행(같음 17, 일부 유지 1), 누적 수정 근거 45행. 같음과 수정은 중복한다. 원본 전 기능 완료는 아니다.

이번 묶음 9,941개 / 실패 0, 누적 신규 대조 33,359개 / 실패 0. 기존 6,320판 · 219,785기록 / 차이 0.

프로젝트 검사 91/91그룹, 실패 0, 미실행 0, 실행 중 0. 최종 코드 검사 완료.

## 이번 근거

19종 실제 원본 oracle를 재실행했다. 계측 전후 출력 일치. 대상 함수 170/212 호출, 기존 미검증 진입 77/157 도달(3차 68). 원본 함수·then/else/do 진입은 실행 근거이며 조건 조합의 완전성을 뜻하지 않는다. 승격 대상은 모든 명시 진입에 도달했고 같은 입력의 계약 출력을 직접 비교했다.

- 기록 ABI·trait payload 6행: 6줄 journal, 전체 pre/h/q0, HP/MP/보호막/심연 및 임의 필드, 중첩 payload와 반환 참조. 실제 native 전체 시간 이력까지 완료한 것은 아니다.
- 개인 기술·시너지: 할드리크/우르다 전체 buff/event/HTML log/T, 미코 deal/round, 2회 행동·처치의 전체 부수 효과. 실제 공격/다중 표적에서 variant1 강화와 캐시도 비교했다.
- 연구 단계·parts·문구·skill·label 6행: 모든 조합과 단계/언어/force, 공백·16진 소수·p지수 입력. persona_research_r21.gd는 이 공유 계산·문구 경계 연결만 수정했다. 마을/시설 화면 파일은 수정하지 않았다.
- placeholder/node/refresh, 버프 tick과 aura 청소 분리, 적 배율과 자기 강화 am 분리, 소수·비율·태그·CSS 배율 문자열을 함께 대조했다.

같음 30행의 원본 id/위치/이전 상태/새 시험·라벨/제품 파일:줄과 117행의 남은 사유는 verification/parity-r23/battle.json에 있다. 숫자·Boolean·nil·빈 map/array는 스키마로 구분하고, 실수 허용 오차 1e-7 이외 문자열과 RNG 소비 수는 그대로 비교한다.

## 실패와 수정 근거

최초 5,592입력은 4,887실패였다. 그중 API 부재 guard 4,246개를 실제 수치 실패와 구분한다. 단계 4개, 파생 clean/parts 16개, 언어 출력 516개가 기존 함수의 직접 비교 차이였다. tick 105개는 유효하지 않은 native source id로 후속 aura 삭제까지 비교한 fixture 오류였다. source/수명 계약을 분리한 최종 800개로 대체했다. 이 105개를 제품 버그 수에 넣지 않았다.

미코 새 함수 호출 전 384개 guard 실패를 별도로 보존했다. 기존 mk 미적용·기술의 mk 부여 누락은 이전 해당 절을 별도 코드 사본에서 재구성해 56입력 중 26개 차이를 재현했다(round4-before-miko-core.gd·round4-before-miko-personal.gd / round4-miko-inline-before.json). 전체 과거 빌드가 아니며 나머지 기능의 수정 전 증거로 확대하지 않는다.

소수 표기는 첫 새 구현의 일반 Godot 포맷터가 정확한 ±0.125에서 Lua/C printf와 달랐다. 해당 절 재구성 16입력 중 2차이를 보존하고 짝수 반올림으로 통과시켰다. 기존 제품 전체의 수정 전 수치 실패로 세지 않는다. 최초 fixture의 인자 수 parse error, 초기 미코 fixture의 nil/빈 상태/이전 시작 log 불일치, 처음 원본 ptx 입력 순서가 pairs 때문에 달랐던 계측 시도는 통과 검사나 제품 실패로 세지 않았다. 이후 입력 키 순서를 고정하고 19종 모두 계측 전후 출력 일치를 확인했다.
새 기록 ABI의 nil/Boolean/scalar 경계 시험은 최초 helper에서 Script error로 중단됐다(round4-record-before.log). 이를 실패 횟수로 꾸미지 않고 최종 144개 통과를 기록했다. 이 네 함수도 이번 수정 근거에 포함한다.

## 제품 연결과 제한

CombatRecord는 gear 경계와 같은 원본 모양의 순수 기록 ABI다. CombatEvents가 이를 실제 action 시작·타격 필드·특성 payload에 연결한다. 포팅한 개인/시너지 함수는 원본 전체 payload와 문구를 기록한다. 아직 옮기지 않은 일반 native 로그를 원본 로그로 가장하지 않으며, 기록은 transient이고 저장 schema/version은 바꾸지 않았다. 모든 native 변경 필드가 원본과 같은 시각으로 기록된다고 주장하지 않는다.

UI의 r17~r20 연출 event 목록/원본 이미지 바이트는 유지했다. source-shaped 기록만으로 render/HUD/버튼/카메라 전체를 승격하지 않았다. 미코 PRUN은 회복·당김·variant1 상태를 고쳤지만 전체 로그/이력이 남아 일부로 유지했다. 저장 가능한 상태에서 부가 sy/bx 표식은 시작/라운드/이탈/restore 때 다시 계산하며 옛 저장의 필드를 요구하지 않는다. 사용자 저장은 열지 않았다.

이번 변경 제품 파일:

- project/game/battle_v3.gd
- project/game/combat_display_r22.gd
- project/game/combat_events_r22.gd
- project/game/combat_passives_r23.gd
- project/game/combat_record_r23.gd
- project/game/dungeon_enemy_r21.gd
- project/game/persona_combat_r22.gd
- project/game/persona_research_r21.gd
- project/game/personal_rules_r22.gd
- project/game/trait_rules_r22.gd

원본 passive 수치는 실제 Lua가 내보낸 데이터에서 tools/sync_battle_passives_r23.py로 가져왔다. 출처 해시를 확인하고 결과값 fixture를 제품 규칙으로 복사하지 않았다. 원정/장비 규칙/서버/마을 화면 파일 수정은 없다.

## 검사·보존

전체 로그: verification/parity-r23/suite-round4-final/. import, 모든 *_test, 필수 integration/export_licenses, 전투 8묶음을 포함한다. 검사 중 추가한 변경보다 먼저 시작한 검사는 코드 잠금 이후 재실행했다. first-pass/와 final-recheck-plan.json/final-code-lock.json/final-verification.json에 근거가 있다.

클라우드 시험은 node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs를 실제 실행했다. 실행별 고유 loopback 포트/제어 파일, worktree 임시 디렉터리, D1 스키마 완료 대기, 정상 종료를 사용했다. 다른 프로세스/포트는 건드리지 않았다.

docs/·project/assets/·server/는 이번 시작 manifest 대비 파일 추가/삭제/바이트 변경 0. 원본 이미지 해시 96개 일치. Web export·버전 갱신·git 명령·커밋 없음. 전투 결과 이미지 3개를 직접 열었고 HUD/대상/버튼/컷인을 확인했다. 작은 폭의 많은 적 이름은 잘림 표시가 보인다. 전수 이미지·실기기·Web/WASM은 시험하지 않았다.
첫 전체 검사에서 이름 없는 내부 할드리크 호출 3건의 Script error를 발견했다. 원본처럼 nm/skill 변수를 생략하도록 보완한 뒤 해당 입력 128개도 대조했다. 이전 잠금 후 코드가 바뀌었으므로 최초 잠금 검증은 의도대로 거부했다. 수정 완료 후 다시 잠그고 전체를 재실행했다. Windows root certificate store 메시지만 환경 진단으로 제외하고 Script error 및 다른 ERROR는 실패로 센다.

## 남은 행

- 30인 개인 기술·개별 특성: 같음 23, 남음 8.
- CTB·공격·종결·전투 버튼: 같음 13, 남음 22.
- 적 방어·반격·소환·단계: 같음 8, 남음 22.
- 전투 사건 연출·HUD·대상·로그: 같음 5, 남음 36.
- 전투 상태·능력치·편성: 같음 27, 남음 20.
- 종족·출신·직업 시너지: 같음 12, 남음 1.
- 페르소나 단일 연구 기술: 같음 7, 남음 8.

남은 핵심은 원본 VER2/채팅 저장/pend·pid 재개, 시작·종결의 전체 상태, 적 소환/단계/방어/공격 전체 로그, 개인 기술의 나머지 부수 효과, HUD·대상·버튼·카메라 전체 의미 출력이다. 개별 이유는 ledger 각 행을 유지했다.

재실행: node tools/oracle_battle_r23_round4.mjs → python tools/coverage_battle_r23.py → python tools/verify_battle_r23_round4.py → python tools/finalize_battle_r23_round4.py → python tools/report_battle_r23_round4.py. 3차 보고/ledger는 R23-battle-round3.md 및 battle-round3.json으로 보존했다.
