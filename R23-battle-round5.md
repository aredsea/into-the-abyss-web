# R23-battle 5차 작업 보고

대상 212행. 이번 같음 +35, 누적 같음 130, 남음 82. 이번 수정 근거 6행, 누적 수정 근거 47행. 같음과 수정은 중복한다. 원본 전 기능 완료는 아니다.

신규 대조 14,418개 / 실패 0, 누적 신규 대조 47,777개 / 실패 0. 기존 6,320판 · 219,785기록 / 차이 0. 전체 프로젝트 검사 92/92그룹 / 실패 0.

## 구현과 대조 범위

- 40-fx: 모든 사건 분기의 표시 text/class/style/대상/아트/전염/마커/카메라 후보와 전체 L을 source-record ABI로 옮겼다. 29종 사건(미지정 포함)과 1,536개 피격·1,536개 피해 결과를 비교했다. 페르소나 컷인은 인레이/data/http/https/무효/호스트 오류까지 88개를 비교했다.
- HUD primitives: HP/MP/보호막/심연 키프레임 CSS 전체, 상태 chip 4,096개, 기술 예고 352개, 행동 순서표 292개, header 320개와 직업 배지/레이드 단계/로그 전체를 비교했다.
- 실제 개인 훅: 미코 PRUN의 전체 shield/boost/HP 이력/로그/T, 우르다 라운드 회복·해제 우선순위/동률/생사, 힐데가 캐시/빈 행동/확률 경계/비table x와 전체 trait/RNG를 비교했다. 실제 run/_round_tick/_hg_scan에서 새 helper를 사용한다.
- 공용 소수 formatter: 곱셈에서 생기는 반올림 오차를 없애고 binary64 significand를 정수로 처리한다. 1.325→1.32 등 Lua/C printf 814개 경계가 일치한다.

20종 실제 oracle의 계측 전후 출력이 같았다. 대상 함수 190/212 호출, 기존 미검증 진입 90/157 도달(4차 77). 새 같음 35행은 모두 명시 함수/then/else/do 진입에 도달했다. 이는 단락 조건의 모든 조합을 전수 검증했다는 뜻이 아니다. 행 id·원본 위치·4차 상태·시험 라벨·제품 파일:줄·남은 이유는 verification/parity-r23/battle.json에 보존했다.

## 실패 확인과 한계

최초 API 추가 전 7,503개 모두 API 부재 guard로 실패했다. 이를 기존 수치 버그로 세지 않았다. 새 개인 훅 전 14,246개 중 226개가 실패했고 API 부재 guard는 160개였다. 이 관측은 native 훅 변경 전 실행이며 5차 시작 전체 빌드의 재현이라고 주장하지 않는다. 실제 5차 시작 formatter 파일을 보존해 같은 814개를 실행했고 64개 차이를 확인했다.

중간 fixture의 sparse Lua table 직렬화, 기록 입력의 언어 불일치, 첫 helper의 GDScript parse 오류는 최종 통과나 제품 버그 수로 세지 않았다. JSON map/array 변환은 지정 필드에만 적용하고 숫자·Boolean·문자열을 강제 변환하지 않는다. 숫자 비교는 기존 1e-7 오차, 문자열과 RNG 횟수는 정확 비교다.

새 CombatDisplay.source_frame/Battle.combat_display_frame은 원본 모양 기록을 HTML/layer/CSS로 돌려주는 호환 경계다. 저장 필드를 바꾸지 않으며 r17~r20 native scene renderer를 대체하지 않는다. 이 계층의 일치를 B.render/r_ally/r_enemy/버튼/저장 재개 전체 완료로 확대하지 않았다. tile/rail도 VID/프로필/호스트 오류 경계를 별도로 비교했다. 개인 훅 대조의 새 전체 payload는 명시된 중립·무장비 도메인이다. 기존 장비·혼합 6,320판의 수치/RNG 회귀도 유지한다.

번역·배지·단계 보스 id는 실제 원본 Lua의 데이터 정의를 tools/sync_battle_text_r23.py로 가져온 것이다. fixture 결과값을 제품 규칙으로 복사하지 않았다.

## 검사와 보존

검사 도중 프로필/false 기본값과 번역 데이터 범위를 보강했다. 첫 전체 검사의 코드 잠금은 변경을 감지해 거부되며, 마지막 수정 전에 시작한 검사와 import를 최종 코드로 다시 실행했다. final-recheck-plan.json과 first-pass/에 해당 목록·이전 결과를 보존했다.

전체 로그: verification/parity-r23/suite-round5-final/. import, 모든 *_test, 필수 UI/integration/export_licenses와 전투 8묶음을 실행했다. final-code-lock.json/tested-code.json/final-code-verification.json/final-verification.json으로 최종 코드 일치를 확인했다. 클라우드는 node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs를 고유 loopback 포트로 실행하고 D1 준비 완료 후 검사해 정상 종료했다.

docs/·project/assets/·server/의 추가/삭제/바이트 변경 0, 원본 이미지 96개 해시 일치. Web export·버전 갱신·커밋 없음. 초기 확인의 git status는 소유권 오류로 실패했으며 공통 규칙을 읽은 뒤 git 명령은 더 사용하지 않았다. 사용자 저장은 열지 않았고 모든 Godot 실행은 격리된 tools/godot_r17.py 경로를 사용했다.

전투 결과 이미지를 직접 열어 확인한 내용과 파일 해시는 verification/parity-r23/visual-review-round5.json에 있다. 원본 이미지 바이트와 기존 연출·배치는 유지했다. 전수 이미지·실기기·Web/WASM은 이번에 시험하지 않았다. Windows root certificate store 진단만 환경 메시지로 제외했고 Script error/나머지 ERROR는 실패로 센다.

이번 제품 변경 파일:

- project/game/battle_v3.gd
- project/game/combat_display_r22.gd
- project/game/combat_fx_r23.gd
- project/game/combat_hud_r23.gd
- project/game/combat_source_text_r23.gd
- project/game/combat_text_r23.gd
- project/game/personal_rules_r22.gd

## 남은 행

- 30인 개인 기술·개별 특성: 같음 26, 남음 5.
- CTB·공격·종결·전투 버튼: 같음 13, 남음 22.
- 적 방어·반격·소환·단계: 같음 9, 남음 21.
- 전투 사건 연출·HUD·대상·로그: 같음 36, 남음 5.
- 전투 상태·능력치·편성: 같음 27, 남음 20.
- 종족·출신·직업 시너지: 같음 12, 남음 1.
- 페르소나 단일 연구 기술: 같음 7, 남음 8.

남은 핵심은 VER2/채팅 저장/pend·pid 재개, 시작·종결의 전체 상태, 적 소환/단계/공격·방어의 전체 부수 효과, 남은 개인 기술, native 타일/버튼/최상위 렌더의 전체 의미 출력이다. 각 행의 이전 사유를 유지했다.

재실행: node tools/oracle_battle_r23_round5.mjs → python tools/sync_battle_text_r23.py → python tools/coverage_battle_r23.py → python tools/verify_battle_r23_round5.py → 이미지 검토 → python tools/report_battle_r23_round5.py. 4차 보고와 ledger는 R23-battle-round4.md/battle-round4.json으로 보존했다.
