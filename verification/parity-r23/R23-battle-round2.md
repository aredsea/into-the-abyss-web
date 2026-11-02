# R23-battle 2차 작업 보고

대상 212행: 이번 같음 +26행, 누적 같음 35행, 수정 근거 21행(이번 9행), 남음 177행. 수정과 같음 10행은 중복이다. 원본 전 기능 이식 완료는 아니다.

새 묶음 대조 10,827개 / 실패 0. 1차 포함 새 대조 18,880개 / 실패 0. 기존 6,320판 · 219,785기록 / 차이 0.

프로젝트 검사 89/89그룹, 실패 0, 미실행 0, 실행 중 0. 전체 검사 완료.

## 원본 실행과 근거

정본 bot/src는 읽기 전용으로 실행했다. Boolean 함수/then/else/do 진입 계측 전후 출력은 동일하다. 기존 6,320판 원본 oracle도 재실행해 보존 기준과 동일함을 확인했다. 총 17종 oracle. 대상 함수 161/212 호출, 기존 미검증 진입 58/157 도달(1차 55). 진입만으로 같음 승격하지 않았다.

원본 local 함수는 로드 사본에 접근문을 추가해 실제 closure를 호출한다. DFS/셔플의 캡처 변수를 경계 입력으로 설정하고 원래 본문을 실행한다. 같은 입력으로 Godot 실제 제품 함수의 반환·변경 배열·예산·다음 정수 RNG를 비교한다. 능력치 내부 st는 반올림 전 6실수도 직접 대조했다.

일반 실수 허용 오차 1e-7, 정수/RNG는 한 정수 차이도 실패한다. nil 슬롯→0, nil 선택→false, Lua 빈 map→Dictionary만 명시적으로 정규화했다. 전체 원본 위치·이전 상태·새 시험·제품 파일:줄·남은 이유는 verification/parity-r23/battle.json에 있다.

|원본 함수|새 같음 행|
|---|---:|
|능력치·캐시|5 (P1599, P1600, P1601, P1602, P1613)|
|편성·RNG|8 (P1630, P1631, P1645, P1647, P1650, P1651, P1652, P1653)|
|전투 보조|4 (P1702, P1705, P1706, P1726)|
|DOT·개인·시너지|9 (P1882, P1948, P1950, P1951, P1994, P2132, P2181, P2242, P2245)|

## 실패 재현과 수정

기본 묶음 1,628개 중 원시 실패 212. 53비트 입력 JSON 직렬화 손실 1개를 제외한 비교 불일치 211개이며 raw 관측은 batch-before.json에 보존했다. 이 묶음 일부는 API 부재를 adapter guard로 실패 표시하거나 이전 식을 인라인 관측한 것이며, 전체 수정 전 빌드 실행으로 합산하지 않는다. 16진수 입력 확장 6,437개 중 실제 제품 함수 실패 334개(씨앗 4·능력치 330)는 batch-numeric-before.json에 있다. 최종 묶음은 batch-latest.json 전체 일치. 원본 기대 수치를 바꿔 맞춘 항목은 없다.

잘못된 x와 빈 선택은 수정 전 메서드 본문을 별도 사본에서 사후 재실행하여 Godot Script error 4개를 확인했다(before-contracts.gd/.log/.json). 이는 보존된 전체 수정 전 빌드가 아니라 이번 편집에서 복원한 본문임을 명시한다.

직업 조회의 동일 정의 참조도 실패 20개를 재현한 뒤 수정했다(batch-class-before.json). 최종 관측에서는 모든 새 경계가 통과한다.

수정한 동작: 빈 선택의 RNG 소비, tcount(0 포함) 우선, Lua 씨앗 변환(기본값·음수 floor·16진 소수), 잘못된 x 초기화/같은 참조, 부식 만료 cor 정리, 레벨 숫자 문자열 변환, 직업 정의 참조 보존.

능력치 식은 battle_stats_r23.gd로 공유한다. 허용 파일 밖 world_state.gd는 기존 base stats를 이 함수에 잇는 최소 연결만 바꾸고 HP/MP 정수 형태를 보존했다. 종족·국가·장비 보정 순서는 기존 경로 그대로다. 전투 방어 상수는 호출자의 formula/curve를 전달한다. 장비 규칙·저장 schema·이관은 변경하지 않았다.

## 변경 파일

- project/game/battle_stats_r23.gd
- project/game/battle_v3.gd
- project/game/combat_display_r22.gd
- project/game/combat_events_r22.gd
- project/game/dungeon_enemy_r21.gd
- project/game/dungeon_rules_r21.gd
- project/game/gear_battle_r22.gd
- project/game/persona_combat_r22.gd
- project/game/personal_rules_r22.gd
- project/game/trait_rules_r22.gd
- project/game/world_state.gd

새 시험/도구: tools/oracle_battle_r23_batch.mjs 및 .lua, project/tests/battle_r23_batch_test.gd, tools/report_battle_r23_batch.py, tools/run_battle_r23_parallel.py. 기존 coverage/run/report/cloud preload와 Godot wrapper를 확장했다. 1차 보고/ledger는 verification/parity-r23/R23-battle-round1.md 및 battle-round1.json에 보존했다.

## 검사와 보존

검사 로그: verification/parity-r23/suite-round2-final/. 모든 프로젝트 검사·import·필수 motion integration·export_licenses와 기존 전체 전투 8종을 포함한다. Windows root certificate store만 환경 메시지로 분리하고 Script error 및 나머지 ERROR는 실패로 센다.

node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs 로 실제 로컬 Worker/D1을 실행했다. 기존 8787/18787 점유 프로세스는 건드리지 않고 빈 loopback 포트를 골랐다. 시험 loader가 serve.mjs 포트만 바꾸며 서버 제품 파일과 Worker/D1 구현은 그대로다. 제어 파일은 cloud-control-round2로 격리했다.

docs/ 249개, project/assets/ 1784개, server/ 29개 manifest 기준 변경 0. Web export·버전 갱신 없음. 사용자 저장을 열거나 덮지 않았다. Godot는 모두 격리 wrapper로 실행했다. 처음 실패한 git status 이후 git 명령·설정 변경·커밋은 하지 않았다.

최종 결과 이미지는 visual-review-round2.json에 기록한 파일만 직접 확인한다. 이미지 전수 육안·모바일 실기기·새 Web/WASM 검증은 하지 않았다.

검사 후 임시 엔진 폴더의 재귀 삭제는 자동 승인 검토에서 정책상 차단되어 실행하지 않았다. verification/ui-r17/.gitignore에 이번 격리 런타임 경로만 추가하여 보존·추적 제외했다. 이번에 띄운 로컬 서버는 종료했다.

## 남은 작업

- 30인 개인 기술·개별 특성: 같음 6, 남음 25.
- CTB·공격·종결·전투 버튼: 같음 8, 남음 27.
- 적 방어·반격·소환·단계: 같음 1, 남음 29.
- 전투 사건 연출·HUD·대상·로그: 같음 0, 남음 41.
- 전투 상태·능력치·편성: 같음 17, 남음 30.
- 종족·출신·직업 시너지: 같음 2, 남음 11.
- 페르소나 단일 연구 기술: 같음 1, 남음 14.

호스트 채팅 변수/옛 VER2 저장 이관·pend/pid 버튼 흐름, 사건 전 필드 시간 이력과 로그/HTML 전체, 측정용 변형·훅 합성, 모든 HUD·대상·연출의 의미상 출력 대조가 남는다. 수치만 비교한 상위 개인 기술·적 행동을 같음으로 확대하지 않았다. 행별 남은 사유를 유지한다.

## 재실행

node tools/oracle_battle_r23_batch.mjs
python tools/coverage_battle_r23.py
python tools/run_battle_r23_parallel.py
python tools/report_battle_r23.py

환경: R23_SUITE_NAME=suite-round2-final, R23_CLOUD_CONTROL=cloud-control-round2, ABYSS_TEST_SERVER=실제 로컬 서버 URL. 서버는 ABYSS_NODE_MODULES=기존 읽기 전용 Miniflare 경로, TEMP/TMP/TMPDIR=이 worktree의 .p6tmp, ABYSS_TEST_PORT=빈 포트로 설정한 뒤 위 serve.mjs 명령을 실행한다.
