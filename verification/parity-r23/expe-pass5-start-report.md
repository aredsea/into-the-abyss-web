# R23-expe — 4차 원본 대조

기존 같음 43행을 보존하고 남은 66행 전부를 실행·검토했다. 이번 **같음 +1(P3124), 누적 44/109행, 남은 65행**이다. 구현·대조 경계를 보강한 행은 2행이며, 실제 RNG 불일치 수정 1행과 장비 입고 비교 경계 보강 1행으로 구분한다. 원본 전 기능 이식 완료는 아니다.

|항목|결과|
|---|---:|
|이번 검토 / 같음 승격 / 수정·보강 / 남음|66 / 1 / 2 / 65|
|새 native 단언|475, 실패 0|
|누적 대조·검사 단언|101,173|
|이번 원본 함수 호출|66/66|
|기존 318개 명시 진입 누적|211 → 316, +105|
|남은 명시 진입|2, 모두 제외한 장미 골목 이동|
|전체 프로젝트 검사|116/116 그룹, 실패 0|
|전투 대조|6,320판 / 219,785기록, 차이 0|
|마을·진행·정산 저장의 서버 validate|3/3|
|보호 이미지 / 전투 시험 파일 변경|96개 변경 0 / 변경 0|
|허용 밖 기존 파일 변경|0|

행별 원본 위치·이전 상태·시험명·구현 줄·남은 이유는 [expe.json](verification/parity-r23/expe.json), 이번 검토는 [expe-pass4-row-audit.json](verification/parity-r23/expe-pass4-row-audit.json)에 기록했다. 이전 보고서는 [expe-pass4-start-report.md](verification/parity-r23/expe-pass4-start-report.md)에 보존했다.

## 바뀐 동작과 근거

대던전의 seed 미지정 출발이 native의 별도 Park–Miller 상태를 소비하던 것을 원본 G_rnd의 저장된 seed/counter 계약으로 맞췄다. town_r21.seed/counter의 기존 저장 필드를 사용하며 성공한 출발만 카운터를 1 올린다. 명시 seed, 이미 진행 중인 도전, 무효 층은 난수를 소비하지 않는다. 실제 Lua G_rnd를 사용한 24입력에서 씨앗/카운터 차이 48건을 먼저 기록(expe-pass4-rng-before-results.json)하고 수정 후 전부 통과했다. 4개의 저장 재개 입력에서도 다음 출발의 난수가 원본과 같았다.

새 층 생성기의 전체 반환을 120입력에서 비교했다. 0~1 직전 RNG 경계, 1/3/27/28/55/420층, 정상·통계 호출 실패·비표 반환·짧은/빈 슬롯 편성을 포함한다. hp/mp/mhp/mmp, boss_seed/name/kind, sid, seed, loot, 모든 초기 필드와 pm 참조, 통계 호출 순서/인수를 비교했다. 실제 출발 초기 자원도 같은 생성기를 쓴다. Lua pcall은 명시적 성공/값 envelope로 대응한다. 구조가 깨져 Lua 자체가 오류를 내는 입력 전부의 동등성을 주장하지 않는다.

장비 입고의 bag_add 경계를 분리해 동일 콜백의 전체 성공/전체 실패/교차 성공/빈 목록을 직접 비교했다. 잘못된 코드의 입고 실패도 lost에 세도록 했다. 중복 코드는 따로 입고되고 포화 때 기존 overflow 보존을 유지한다. 원본은 포화 장비를 버리므로 P3195는 일부로 남긴다. 장비 규칙 파일은 수정하지 않았다.

아이템 이름은 유효 장비 코드 분기를 포함한 9건을 직접 비교했다. 이전 전수 검사에 남아 있던 charm_potion 제외는 그대로 유지하므로 P3134는 승격하지 않았다.

## 검사와 보존

전체 검사 전에 import에서 기존 facilities의 단일 인자 override와 새 bag callback 인자 수가 충돌했다. 실패 import만 expe-pass4-suite-final/에 보존했다. 공개 메서드의 원래 인자 수를 유지하고 비교 경계를 별도 메서드로 옮긴 뒤, 최종 전체 검사를 expe-pass4-suite-complete/에서 한 번 실행했다. 그 뒤 제품·시험 코드는 잠금 해시와 같았다. 기존 테스트의 기대값·단언·전투 fixture 경로를 변경하지 않았다.

새 API 부재 2단언 실패를 expe-pass4-before-results.json에 보존했다. 초기 시험 중 통계 fixture가 모르는 동료를 native UI 인물 조회에 전달한 오류, Godot String/bool 비교 오류, persona level mirror를 맞추지 않은 저장 fixture 오류는 고쳤다. 별도 source probe의 노출 이름 충돌도 수정했다. 최종 source probe 오류 0, 계측 전후 전체 JSON 동일이다. 이 도구·fixture 오류를 제품 수치 결함으로 합산하지 않았다.

로컬 클라우드 서버는 node server/abyss-save/test/serve.mjs를 기존 preload로 실행하고 고유 loopback 포트에서 클라우드 검사·쿼터 초기화·정상 종료를 확인했다. 새 저장 3개는 수정하지 않은 서버 validator를 통과했고 native JSON 전체 왕복도 같았다. 저장 schema/version 변경과 기존 사용자 저장 접근은 없다. root certificate store 진단 외 Script error/ERROR는 실패로 판정했다.

기존 제품 변경은 project/game/expedition_world_r22.gd 하나다. 새 파일은 tools/expe_r23_pass4_*, project/tests/expe_pass4_r23_test.gd 및 verification/parity-r23/expe-pass4*이다. 정본 Lua 46개, server/, docs/, 전투 시험 파일, 보호 이미지 바이트를 시작 해시와 비교했다. git 명령·커밋·Web export·버전 갱신 없음. 새 대조 파일은 50MB 이하다.

이번 UI 검사로 생성한 정산 390px·탐색 기록 360px·저장 재개 퇴각 360px 화면 3장을 직접 열었다. 정산의 다음 층/귀환 버튼, 기록의 수확량과 돌아가기 버튼, 재개한 퇴각의 금화/경험치와 계속/정산 버튼을 확인했다. 정산 안내 끝의 짧은 마지막 줄과 fixture의 페르소나 placeholder 표시는 그대로 보인다. 사진 목록·해시는 expe-pass4-visual-review.json에 있다. 전수 이미지·Web/WASM·실기기는 확인하지 않았다.

## 남은 범위

나머지 65행은 원본 HTML 전체 반환과 Risu pending/메시지·장면 계약, 기존 저장 이관의 입력 허용 차이, 전투 상태/시설/장비 가방의 허용 밖 규칙이 남아 있다. 66함수의 실행 및 316/318 진입은 조건 조합 완전성이나 native 전체 일치율이 아니다. 특히 포화 가방의 overflow와 음수·소수·잘못된 문자열 저장 거절 규칙은 사용자 저장 보존을 위해 유지했다. 성적 콘텐츠는 추가 이식하지 않았다.

원본별 남은 행 수: 70-town.lua 14, 74-level.lua 2, 75-sortie.lua 10, 76-dungeon.lua 1, 77-explore.lua 32, 78-battle-item.lua 6. 상세 이유는 [expe-pass4-remaining.json](verification/parity-r23/expe-pass4-remaining.json)에 있다.

재현: python tools/expe_r23_pass4_coverage.py → python tools/godot_r17.py --headless --script res://tests/expe_pass4_r23_test.gd → node tools/expe_r23_pass4_saves.mjs. 전체 검사는 보존된 결과 위에 덮어쓰지 않도록 도구가 보호하며 재실행 시 별도 suite 경로를 지정해야 한다.
