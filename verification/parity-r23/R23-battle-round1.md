# R23-battle 작업 보고

대상 **212행**을 행별로 검토했다. 새로 **같음 9행**, 수정 근거가 있는 행 **12행**, 남은 행 **203행**이다. 같음과 수정은 1행이 겹친다. **원본 전 기능 이식 완료는 아니다.** 남은 함수와 사유를 `verification/parity-r23/battle.json`에 모두 기록했다.
수정했지만 전체 계약이 남은 11행도 남은 203행에 포함한다. 같음도 수정도 아닌 행은 192행이다.

새 대조 **8,053항목 / 실패 0**, 프로젝트 검사 **88그룹 / 실패 0**. 기존 **6,320전투 · 219,785개 기록 일치 / 차이 0**을 유지했다.

## 재현과 수정

|시험|수정 전 항목|실패|증거|
|---|---:|---:|---|
|기본 경계값|1,154|10|`verification/parity-r23/before.json`|
|소환/단계|91|8|`verification/parity-r23/enemy-before.json`|
|페르소나|2,314|24|`verification/parity-r23/persona-before.json`|
|carry|144|48|`verification/parity-r23/state-before.json`|
|표시 시각|280|12|`verification/parity-r23/display-before.json`|
|되치기|2,472|8|`verification/parity-r23/counter-before.json`|
|실제 타격 속성 지연|2,508|8|`verification/parity-r23/element-delay-before-corrected.json`|

페르소나 무효 조합 4개는 위 수치 실패와 별도로 script error도 재현했다(`persona-before.log`). 최초 fixture의 빈 Lua 표/Dictionary 표현, 아군 대상 선택, `seal` 필드, CTB round/tick 일관성은 제품 수정 전에 바로잡았다. RNG는 JSON 소수 자릿수 손실을 피하도록 정확한 Park-Miller 정수 상태를 비교했다. 원본 수치를 바꿔 맞춘 기대값 변경은 없다.

제품 변경은 다음 6파일이다.

- `project/game/battle_v3.gd`
- `project/game/combat_display_r22.gd`
- `project/game/combat_events_r22.gd`
- `project/game/dungeon_enemy_r21.gd`
- `project/game/gear_battle_r22.gd`
- `project/game/persona_combat_r22.gd`

수정한 동작은 10종이다: 규칙 없는 숨은 적의 감경 제거, 명시적 low/aimed 별칭/RNG 상한의 표적 선택, 빈 소환 칸 우선, 같은 사건의 사망 칸 재사용 금지, 미완성 페르소나 기술 무동작, 쓰러진 단일 지원 대상 제외, carry 사망 대기값과 저장 보존, 마지막 일격 히트스탑의 적용 범위 제한, 되치기의 고유 피해/대상/회피 경로, 실제 타격 속성에 따른 적 지연. 옛 schema-3 mob 등급 소환 칸은 계속 재사용할 수 있다.

## 새 증거 범위

|시험|항목|실패|
|---|---:|---:|
|latest|2,508|0|
|enemy-latest|91|0|
|state-latest|261|0|
|compose-latest|4,805|0|
|display-latest|280|0|
|clock-latest|108|0|

원본 Lua에 Boolean 진입 기록만 추가하여 재실행했다. 계측 전/후 oracle 결과가 모두 같은 것을 확인했다. 대상 함수 **158/212개 호출**, 기존 미검증 진입 **55/157개 도달**이다. 이 수치는 조건 조합 전수나 함수 완성도가 아니다. 원본 소스 해시, 계측 정보, 행별 미도달 목록은 `coverage.json`과 `coverage/`에 있다.

새 입력은 원본 `bot/src/*.lua`를 읽기 전용으로 Wasmoon/lua_sim에서 실행했다. 저장 가능한 입력과 명시된 무효/경계값의 반환·상태·RNG를 비교한다. 숫자 실수의 기존 허용 오차는 1e-7이며, 정수 피해·게이지·RNG 상태는 정확 비교한다. 편성 RNG 상태는 별도로 정수 동등성을 검사한다.

기존 6,320판의 원본 oracle도 새로 실행하여 기존 기준 JSON과 모든 관측값이 같음을 확인했다. 새 6종 oracle와 기존 전체 전투 8종·단위 2종, 총 16개 실행을 계측했다. 기준 파일을 덮지 않고 `coverage/retained-*-oracle.json`에 따로 보존했다.

실제 속성 지연 fixture는 양쪽 표적 약점 목록을 빈 목록으로 맞췄다. `element-delay-before-corrected.json`은 저장해 둔 수정 전 Godot 관측값을 보정한 짝 입력의 Lua 결과에 다시 비교한 것으로, 관측값은 바꾸지 않았다. raw before 파일과 두 자료의 해시도 남겼다.

## 남은 작업

- 전투 상태·능력치·편성: 같음 4, 남음 43.
- CTB·공격·종결·전투 버튼: 같음 4, 남음 31.
- 적 방어·반격·소환·단계: 같음 0, 남음 30.
- 30인 개인 기술·개별 특성: 같음 0, 남음 31.
- 종족·출신·직업 시너지: 같음 0, 남음 13.
- 페르소나 단일 연구 기술: 같음 1, 남음 14.
- 전투 사건 연출·HUD·대상·로그: 같음 0, 남음 41.

전체 상태/반환/부수 효과를 검증하지 못한 행은 일부 또는 미확인으로 유지했다. 특히 원본 저장 버전·pend/pid 이관, 모든 사건의 필드별 시간 이력과 payload, 훅 합성/측정용 변형, 다국어 설명과 로그, HUD·버튼·대상의 의미상 출력 대조가 남는다. 여러 통합 전투가 통과했다는 이유만으로 이 함수들을 같음으로 세지 않았다. 행별 기존 판정 사유·원본 위치·baseline 미검증 분기와 이번 결과를 함께 보존했다.

## 검사와 보존

`node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs`로 원래 로컬 Worker/D1 서버를 실행했다. Miniflare 설치본은 기존 다른 worktree의 의존성을 읽기 전용으로 참조했다. 시험 전용 preload가 같은 DB에 보관 계정 fixture와 독립 quota를 준비한다. 서버 제품 파일은 수정하지 않았다.

`docs/` 249개, `project/assets/` 1,784개, `server/` 29개에서 manifest 기준 변경 0. Web export·버전 갱신을 하지 않았다. 사용자 저장은 열거나 덮지 않았고 모든 Godot 실행은 격리 wrapper를 사용했다. schema_version은 3 그대로다. 기존 사망자의 유한 대기값은 그대로 불러오며, 새 10^9 sentinel은 HP=0 아군에만 허용한다.

공통 문서 로딩과 같은 첫 도구 호출에서 `git status --short`를 한 번 시도했으나 소유권 오류로 실패했다. 이후 git 명령·설정 변경·커밋은 하지 않았다.

Windows root certificate store 진단은 기존 환경 메시지로 분리했다. Script error와 기타 ERROR는 통과로 세지 않는다. 모든 결과 이미지의 육안 전수 검증·모바일 실기기·새 Web/WASM 검증은 하지 않았다. 직접 연 이미지는 `visual-review.json`에 별도로 기록한다.

로컬 서버는 별도 터미널에서 다음과 같이 준비한다.

```powershell
$env:ABYSS_NODE_MODULES=(Resolve-Path '..\r21-d-town\server\abyss-save').Path
$env:TEMP=(Join-Path (Get-Location) '.p6tmp')
$env:TMP=$env:TEMP
$env:TMPDIR=$env:TEMP
node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs
```

재실행:

```powershell
python tools/prepare_battle_r23.py
node tools/oracle_battle_r23.mjs
node tools/oracle_battle_r23_enemy.mjs
node tools/oracle_battle_r23_state.mjs
node tools/oracle_battle_r23_display.mjs
node tools/oracle_battle_r23_compose.mjs
node tools/oracle_battle_r23_clock.mjs
python tools/coverage_battle_r23.py
$env:R23_SUITE_NAME='suite-final'
python tools/run_battle_r23.py
python tools/report_battle_r23.py
```

## 시험·도구 파일

- `project/tests/battle_r23_clock_test.gd`
- `project/tests/battle_r23_clock_test.gd.uid`
- `project/tests/battle_r23_compose_test.gd`
- `project/tests/battle_r23_compose_test.gd.uid`
- `project/tests/battle_r23_display_test.gd`
- `project/tests/battle_r23_display_test.gd.uid`
- `project/tests/battle_r23_enemy_test.gd`
- `project/tests/battle_r23_enemy_test.gd.uid`
- `project/tests/battle_r23_random_fixture.gd`
- `project/tests/battle_r23_random_fixture.gd.uid`
- `project/tests/battle_r23_state_fixture.gd`
- `project/tests/battle_r23_state_fixture.gd.uid`
- `project/tests/battle_r23_state_test.gd`
- `project/tests/battle_r23_state_test.gd.uid`
- `project/tests/battle_r23_test.gd`
- `project/tests/battle_r23_test.gd.uid`
- `tools/cloud_battle_r23_preload.mjs`
- `tools/coverage_battle_r23.py`
- `tools/oracle_battle_r23.lua`
- `tools/oracle_battle_r23.mjs`
- `tools/oracle_battle_r23_clock.mjs`
- `tools/oracle_battle_r23_compose.mjs`
- `tools/oracle_battle_r23_display.lua`
- `tools/oracle_battle_r23_display.mjs`
- `tools/oracle_battle_r23_enemy.lua`
- `tools/oracle_battle_r23_enemy.mjs`
- `tools/oracle_battle_r23_state.lua`
- `tools/oracle_battle_r23_state.mjs`
- `tools/prepare_battle_r23.py`
- `tools/report_battle_r23.py`
- `tools/run_battle_r23.py`
