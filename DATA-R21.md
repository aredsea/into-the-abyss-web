# DATA-R21 — A 갈래 던전·적 데이터 이관

<!-- R21_FOURTH_START -->
## 4차 — Opus 지적 8건 재현·수정

2026-11-01. **8건 모두 수정, 기각 0건.** 먼저 원본 Lua 하네스 대조 행과 Godot 시험을 추가하고, 구현을 바꾸기 전에 **343항목 중 163항목 실패**를 확인했다(`enemy-review-fourth-before.json`). 펠리체의 추가 경계 검사에서도 죽은 차례의 행동 횟수·회피 스캔·적 지원 행동 종료를 구별하지 못하는 3건의 실패를 확인한 뒤 수정했다(`enemy-review-fourth-scan-before.json`). 일반 적 공격의 다음 회피 스캔도 별도 1건 실패를 확인하고 연결했다(`enemy-review-fourth-attack-scan-before.json`). 최종 재현·저장·훅·RNG 검사는 **354항목, 실패 0**, 필수 검사는 **21종 모두 통과, 실패 0**이다. 아래 1~3차 절은 당시 기록이며, 3차의 “GD duty = 원본 psguard” 해석은 이 절에서 바로잡는다.

| 지적 | 원본 대조·수정 전 실패 → 수정 | 원본 근거 |
|---|---|---|
| 1. duty/guard 위치 반전 | 실제 전술 suffix guard의 DOT 100 피해가 100, 힐데 duty 중 DOT 10 피해가 7이었다 → 각각 **90 / 6**. 방어 자세 `guard`와 전술 `psguard`를 분리했다. 힐데 `duty`는 `red25`에 대응해 take 반올림 전에 적용하고, `psguard`는 fixed·일반 공격 모두 take 반올림 뒤에 따로 곱하고 반올림한다. fixed는 방어 자세만 건너뛴다. | `29-persona-skill.lua:125`, `30-engine.lua:333–336`, `32-personal-a.lua:626,662–667` |
| 2. 오라클의 같은 오매핑 | 기존 duty 행은 중립 동료의 psguard를 실행해 잘못 통과했다 → Lua는 **hildegard + red25 .25 + DOT 10**, GD도 힐데 `duty .25`로 대조한다. 별도의 중립 `psguard .1 + DOT 100` 행을 추가했다. 수정한 두 행 모두 구현 수정 전에 실패했다. | `tools/oracle_enemy_review_r21.mjs`, `enemy-review-fourth-before.json` |
| 3. 순수 DOT의 콜레트 봉인 누락 | 봉인된 마법 DOT가 중첩되고 전역 회피 RNG도 소비했다 → 살아 있는 개인 훅을 **파티 슬롯 순서**로 순회하고 봉인된 마법 행동은 회피로 처리한다. 이전 훅의 true 뒤에도 뒤쪽 사야 훅은 실행하고, 전역 회피만 생략한다. 콜레트 위치·마법/물리·봉인 유무·사야 유무의 **24행**에서 중첩·RNG·다음 대상이 일치한다. 정본 순수 DOT 6행은 모두 `magic:true`다. | `30-engine.lua:86–103`, `32-personal-b.lua:176–181,225–233`, `34-traits.lua:323` |
| 4. 자기 차례 마지막 성벽 수명 | 자기 DOT로 발동한 wall_party가 같은 시작 틱에서 2→1로 줄었다 → 자기 차례 발동은 +1을 넣어 3→2로 유지한다. 타인 차례 발동은 원래 수명이다. 원본 gw는 발동 직후 자기 차례 3 / 다른 차례 2이며, Godot의 시작 틱과 원본 종료 틱의 차이는 검사에 명시했다. | `81-gear.lua:650–656,971–975` |
| 5. DOT 사망 당일 즉시 소생·행동 | DOT로 쓰러진 틱에서 즉시 HP 250으로 소생했다 → **그 틱 HP 0**, 다음 스캔에서 250. 쓰러진 차례는 CTB 선택만 이어가며 행동 횟수·turn_count를 더 올리지 않는다. 펠리체는 다음 아군 turn_end·회피 훅에서 스캔하며 적 지원 행동의 enemy_end는 스캔하지 않는다. 소생 때 효과·보호막·충전을 지운다. 대기 중 JSON 저장·복원과 이어하기도 일치한다. | `30-engine.lua:1072–1074`, `32-personal-a.lua:448–485` |
| 6. 사야 반격 난수열 | 회피 뒤 반격의 치명 판정이 기존 전투 RNG를 사용해 원본 적 난수열에서 1회가 빠졌다 → 반격의 치명 굴림을 같은 원본 난수열에서 1회 소비한다. **20씨앗**에서 회피·원본 RNG·다음 대상이 일치하고 기존 별도 RNG는 변하지 않는다. 씨앗 1은 **490999122**다. 반격 피해 자체는 기존 아군 공격 구현을 유지한다. | `32-personal-a.lua:217–223`, `30-engine.lua:313` |
| 7. 구원 보호막의 장비 보너스·수호 오발동 | 마르셀린·사제 구원 보호막에 피해자 장비 shield +20%와 guardian이 적용되고 RNG를 소비했다 → 스킬 보너스 없는 원시 보호막 경로를 사용한다. 두 경우 모두 **보호막 150**, 마르셀린 HP 251 / 사제 기적 HP 600이며 RNG 소비 0이다. | `30-engine.lua:1156,376` |
| 8. 자하르 fixed의 zdn 누락 | DOT 100이 zdn 중에도 62였다 → `zdn`을 일반 방어 약화와 분리하고 원본 K·방어 비율 보정을 take 안에 넣었다. 원본 재현과 같은 방어 31.350784·K 40에서 **62→68**, 방어 40에서는 원본처럼 **69**다. fixed·일반 공격 × zdn 0/.2 × 방어 2종 **8행**이 일치한다. | `32-personal-b.lua:313–331` |

### 일반 공격 값 변화와 검증 범위

실제 GD 전술 함수를 실행해 방어 자세 보존과 별도 psguard 생성을 검사했다. fixed·일반 × 중립/힐데 × 원시 피해 7종 × 방어 자세 유무의 **56행 전체**가 원본 `B.strike`와 일치한다. 이 중 일반 공격 28행에서 **17행의 값이 바뀌었다**(`fourth-normal-changes.json`). 예: 중립 raw 100 + 방어 자세 .4 + 전술 guard .1은 **90→54**, 힐데 duty .25 + 전술 guard .1의 raw 100은 **57→58**, 같은 조건에 방어 자세까지 있으면 **57→34**다. 기존 구현은 전술 guard가 방어 자세를 덮어썼고, take·psguard 반올림도 잘못했다. 변경 후 값은 모두 Lua 실행 결과다.

일반 공격의 방어 자세·대신 맞기 절사 위치도 take 이전으로 맞췄다. r21 적의 원시 공격 피해는 원본처럼 먼저 정수로 절사한다. 원본의 모든 take 훅·모든 장비 조합·전체 CTB 및 전투 난수열 동등성을 주장하지 않는다. 특히 사야 반격 피해량은 기존 아군 공격식을 유지하며, 이번 난수 대조는 회피·반격 치명 1회·다음 대상 추첨 범위다. 펠리체 검증은 자기 차례 DOT 사망처럼 원본 게이지가 0인 경우다. 일반 피격 사망의 시간·게이지 대기 전체를 원본 엔진으로 교체한 것은 아니다.

| 핵심 수치 | 최종 결과 |
|---|---:|
| 수정 / 기각 | 8 / 0 |
| 수정 전 재현 검사 | 343항목 / 실패 163 |
| 최종 재현·저장·훅·RNG 검사 | 354항목 / 실패 0 |
| 원본 DOT 훅 / 기존 회피 표본 | 7/7 / 120/120 일치 |
| take·psguard / 봉인 슬롯 순서 / 사야 / 자하르 | 56 / 24 / 20 / 8, 전부 일치 |
| 적 행동 검사 | 2,878항목 / 실패 0 |
| 적 / 개별 행동 / 연속 행동 | 100종 / 1,221/1,221 / 1,221/1,221 |
| 침묵 / 장비 표본 | 200 / 120 / 불일치 0 |
| 기존 재현 검사 | 30항목 / 실패 0 |
| 던전 통합 | 3,059항목 / 실패 0 |
| 1~420층 강제 종결 | 승리 420 / 패배 420 |
| 1~60층 자연 전투 표본 | 승리 141 / 패배 53 |
| UI 이름표 | 3,200개 / 넘침 0 |
| 원본 자산 / 데이터·원본 변경 | 96/96 보존 / 불일치 0·원본 변경 0 |
| 보호 파일 해시 | 711개 / 변경 0 (`docs/` 249개 포함, 기존 1,221행 오라클 포함) |
| 필수 검사 / 스크립트·엔진 오류 | 21종 통과 / 0 |

### 남은 원본 차이 — 이번 범위 밖

지시서에 따라 다음 여섯 항목은 이번에 수정하지 않았다.

1. `pa_echo` 회복이 원본 `B.heal` 경로를 거치지 않는다.
2. 아군 사망 시 원본 `ally_down` / `drop_src` 전체 처리가 없다.
3. 구원 순서가 원본과 다르다(마지막 성벽 대 동료 save).
4. 마지막 성벽의 회복 HP가 원본 반올림 대신 `int` 절사다.
5. 사제 자기 구원이 원본처럼 되지 않는다.
6. DOT 사망 뒤 같은 `_tick`의 regen 등 나머지 처리 순서는 원본과 다르다.

새 적 그림·성적 콘텐츠·Web export는 이번에 수행하지 않았다. 저장 schema 3을 유지하고 사용자 저장을 지우거나 덮지 않았다. 기존 전술 guard가 이미 `guard`로 저장된 옛 상태는 방어 자세와 구분할 정보가 없어 자동 추정 이관하지 않는다. 새로 건 전술 효과는 별도 `psguard`로 저장되고 기존 저장도 그대로 읽는다. 기존 1,221행 행동·침묵·장비 오라클의 기대값과 공통 검사의 기대값은 바꾸지 않았다. 보강 재현 검사에서만 잘못된 duty fixture를 원본 의미로 고쳤다.

### 실행·시각 확인·변경 파일

```powershell
node tools/oracle_enemy_review_r21.mjs
python tools/verify_data_r21.py
python tools/audit_data_r21.py
python tools/report_enemy_fourth_r21.py
```

원본 Lua는 기존 하네스의 wasmoon에서 정본 10파일을 다시 적재해 실행한다. 새 `oracle_enemy_review_fourth_r21.lua`는 입력 fixture와 관측만 정의하고 원본 전투·훅 함수를 호출한다. 검수자의 Lua 재현 스크립트도 읽기 전용으로 실행해 90/6/68·성벽 3·사야 490999122를 별도 확인했다(`reviewer-reference-fourth.json`). 수정 전·경계 보강 전·최종 JSON과 전체 실행 로그는 `verification/data-r21/`에 보존했다.

직접 연 이미지: `verification/data-r21/battle-360-7.png`, `verification/ui-r20/all-states-360.png`. 7칸 이름표·HP·아군 카드·전투 명령·기술/보급품/기록 시트의 배치를 확인했다. 모든 결과 이미지를 각각 연 것은 아니다.

구현 변경: `project/game/battle_v3.gd`. 검사 변경: `project/tests/enemy_review_r21_test.gd`. 도구 변경·추가: `tools/oracle_enemy_review_r21.mjs`, `tools/oracle_enemy_review_fourth_r21.lua`, `tools/report_enemy_fourth_r21.py`. 보고·근거: `DATA-R21.md`, `verification/data-r21/**` 및 필수 검사에서 재생성한 기존 verification·라이선스 결과.

`docs/`·원본 봇·다른 worktree에는 쓰지 않았고 Web export·버전 갱신도 하지 않았다. 규칙을 읽기 전 최초 조회에 포함한 `git status --short`는 소유권 오류로 실패했다. 이후 git 명령과 git 설정 변경은 하지 않았다. 반복되는 OS 인증서 저장소 메시지는 기존 환경 진단으로 분리했다.

첫 전체 실행은 21종 모두 통과했다(`suite-fourth-initial.json`). 스캔 경계를 보강한 뒤 전체 재실행 중 r18의 `World preview completes` 1건이 실패했다. 해당 회차와 로그는 `suite-fourth-retry-needed.json`, `ui_battle_r18_test-fourth-preview-failure.log`에 보존했다. 그 검사 코드를 바꾸지 않고 단독 재검사해 통과했다. 마지막 일반 공격 스캔 연결 후 영향받는 import·데이터·던전·적 행동·회귀·검수·데이터 UI와 r18을 다시 실행했다. 최종 21종 표는 각 검사의 최신 실행을 합친 `suite-fourth-final.json`이며, 스크립트·엔진 오류는 0이다.

| 최종 검사 | 결과 | 실패 |
|---|---|---:|
| `import` | 통과 | 0 |
| `world_test` | 통과 | 0 |
| `state_test` | 통과 | 0 |
| `route_test` | 통과 | 0 |
| `expansion_test` | 통과 | 0 |
| `motion_test` | 통과 | 0 |
| `motion_asset_test` | 통과 | 0 |
| `art_test` | 통과 | 0 |
| `export_licenses` | 통과 | 0 |
| `data_r21_test` | 통과 | 0 |
| `dungeon_r21_test` | 통과 | 0 |
| `enemy_regression_r21_test` | 통과 | 0 |
| `enemy_action_r21_test` | 통과 | 0 |
| `enemy_review_r21_test` | 통과 | 0 |
| `ui_battle_r17_test` | 통과 | 0 |
| `ui_battle_r18_test` | 통과 | 0 |
| `ui_battle_r19_test` | 통과 | 0 |
| `ui_battle_r20_test` | 통과 | 0 |
| `motion_r9_integration` | 통과 | 0 |
| `motion_r18_integration` | 통과 | 0 |
| `ui_data_r21_test` | 통과 | 0 |

<!-- R21_FOURTH_END -->

<!-- R21_THIRD_START -->
## 3차 — 재검수 4건 재현·수정

2026-11-01. 지적 4건 모두 수정했으며 기각은 없다. 구현을 바꾸기 전에 `enemy_review_r21_test.gd`를 실행해 **20항목 중 7항목 실패**를 확인했다(`verification/data-r21/enemy-review-before.json`). 표본 검사는 별도 음성 시험 4건 모두 종료 코드 0으로 잘못 통과하는 것을 먼저 확인했다(`sample-probes-before.json`). 그 뒤 구현과 검사를 보강했으며, 최종 **21종 검사 모두 통과·실패 0**이다. 아래 1·2차 절은 해당 차수 당시의 기록이다.

| 지적 | 먼저 재현한 결과 → 수정 | 원본 근거 |
|---|---|---|
| 1. DOT 일반 피해 경로 누락 | 직접 HP·보호막을 깎아 duty·치명 피해 버팀·피해 후 훅이 실행되지 않았다. DOT 합계를 1회 `_incoming_strike(..., fixed=true)`로 보내 일반 적 공격과 피해 감소·보호막·버팀·피해 후 처리를 공유한다. 고정 피해는 방어 자세·공격 회피·공격자 반사·가시 반격을 거치지 않는다. take와 duty 반올림 순서도 원본처럼 처리한다. | `31-foes.lua:145–159`, `30-engine.lua:330–407` |
| 2. 순수 DOT 회피 누락 | 회피 100%여도 중첩이 들어가고, 회피용 RNG 1회가 빠졌다. 대상 결정 뒤 캐릭터 회피 → 국가·장비 합산 회피 → 적중 시 중첩 → 다음 대상 추첨 순서로 처리한다. 확률 0인 전역 회피는 RNG를 소비하지 않는다. | `31-foes.lua:305–315`, `32-personal-a.lua:215–227`, `34-traits.lua:321–330` |
| 3. 저장 후 예고 변경 | 실제 행동이 2차례 진행된 첫 재현에서 저장 대상 `executor`가 불러오면 `hildegard`로 바뀌었다. 이제 roster에 `target_id`를 저장·검증·복원한다. 강화한 중립 파티 검사에서도 3차례 후 `neutral_1` → `neutral_1`로 유지된다. 다음 행동 후 전체 snapshot도 JSON 숫자 타입을 정규화한 값으로 정확히 일치한다. | `battle_v3.gd` snapshot/restore, `dungeon_enemy_r21.gd` roster/hydrate/initialize_targets |
| 4. 표본 0개 통과 | 실제로 `checks=0, failures=0, gear_samples=120`으로 성공했다. 행동 ≥1,221개, 정본 적 100종 각각 ≥12차례, 침묵 ≥200개·10직업 각각 ≥20개, 장비 ≥120개를 실행 전에 단언한다. `gear_samples`는 읽은 배열 크기다. 빈 전체·적 1종 누락·침묵 0·장비 0의 네 입력을 모두 실패로 거부한다. | 기존 oracle 생성 범위와 정본 적 목록 |

추가 원본 대조에서 보호막 파괴 회복(`pa_echo`)이 치명 피해 버팀보다 먼저 실행되어 쓰러진 동료를 잘못 되살릴 수 있는 경우도 재현했다(`enemy-review-echo-before.json`, 2건 실패). 고정 피해에서는 버팀과 피해 후 훅을 처리한 뒤 살아 있는 동료에게만 회복한다. 일반 r20 적 공격의 기존 처리 순서는 유지했다.

| 핵심 수치 | 최종 결과 |
|---|---:|
| 새 재현·저장·훅·RNG 검사 | 148항목 / 실패 0 |
| 원본 실제 DOT 훅 대조 | 6/6 일치: duty·보호막, 마지막 성벽·상처, 최후의 저항, 사제 버팀, 파괴 회복의 생존·사망 |
| 원본 실제 회피·중첩·RNG·다음 대상 대조 | 120/120 일치: 회피 0/15/100% × 국가 없음/나에린 × 20씨앗 |
| 표본 누락 음성 시험 | 4/4 정상 거부 |
| 적 행동 검사 | 2,878항목 / 실패 0 |
| 적 / 개별 행동 / 연속 행동 | 100종 / 1,221/1,221 / 1,221/1,221 |
| 침묵 / 장비 표본 | 200 / 120 / 불일치 0 |
| 기존 재현 검사 | 30항목 / 실패 0 |
| 던전 통합 | 3,059항목 / 실패 0 |
| 1~420층 강제 종결 경로 | 승리 420 / 패배 420 |
| 1~60층 자연 전투 표본 | 승리 141 / 패배 53 |
| UI 이름표 | 3,200개 / 넘침 0 |
| 원본 자산 / 데이터·원본 변경 | 96/96 보존 / 불일치 0·원본 변경 0 |
| 보호 파일 해시 대조 | 710개 / 변경 0 (`docs/` 249개 포함) |

### 저장 호환과 검증 범위

schema 3은 유지한다. 새 필드는 `r21_roster[]`의 선택적 `target_id`다. 값이 없는 옛 roster는 생성자에서 초기화한 예고를 대체값으로 유지한다. 값이 있으면 아군 ID·자기 ID·빈 비활성 대상만 허용하며, 숫자·객체·모르는 ID는 거부한다. 예고 대상인 아군이 이미 쓰러졌더라도 ID는 보존하고 실제 행동의 기존 대체 대상 규칙을 사용한다. 기존 단계·소환 복원과 schema 1·2 이관 검사도 통과했다. 사용자 저장 파일은 지우거나 덮어쓰지 않았다.

`tools/oracle_enemy_review_r21.mjs`는 원본 하네스에 정본 Lua 10파일을 다시 적재해 실행한다. 전역 훅 테이블은 장비 래퍼가 중복 적재되지 않도록 초기화한다. 입력·출력과 파일 목록은 `enemy-review-oracle.json`, 추가 출처 해시는 `source-inventory.json`에 있다. 기존 1,221행 oracle의 행동·침묵·장비 기대값은 바꾸지 않았다.

기존 중첩 산술 검사 3건은 이제 적용되는 힐데가르트 등의 피해 감소 때문에 처음 실패했다. 해당 부분과 저장 복사 fixture만 중립 파티로 바꿔 **4×per, 14, 12의 산술 기대값을 그대로 유지**했다. 피해 감소·버팀·피해 후 훅은 새 원본 대조에서 별도로 검증한다. 공통 검사의 기대값 변경은 없다. 첫 전체 실행의 실패는 `suite-third-initial.json`에 보존했고, 최종 전체 실행은 `suite-third-final.json`이다.

이번 대조는 명시한 DOT·회피·저장 경로의 검증이다. 기존 r20의 아군 공격·모든 캐릭터/장비 조합·전체 CTB 및 전체 전투 난수열을 원본 엔진과 같게 바꾼 것은 아니다. 특히 사야 회피 후 반격 피해 자체는 기존 아군 공격 경로를 사용하며 그 전체 난수열 동등성은 검증하지 않았다. 2차 절의 DOT 직접 차감 제한은 이번 수정으로 대체되며, 위에 나열하지 않은 원본 훅 조합까지 동등하다고 주장하지 않는다. 적 전용 그림 제작과 성적 콘텐츠 이관은 이번 작업에 추가하지 않았다.

### 실행·시각 확인·변경 파일

```powershell
node tools/oracle_enemy_review_r21.mjs
python tools/check_enemy_samples_r21.py final
python tools/audit_data_r21.py
python tools/verify_data_r21.py
python tools/report_enemy_review_r21.py
```

직접 연 이미지: `verification/ui-r20/all-states-360.png`, `verification/data-r21/battle-360-7.png`. 전투 명령·아군 카드·HP·기술/보급품/기록 시트와 7칸 적 이름표를 확인했다. 이름표의 기존 말줄임을 유지한다. 모든 결과 이미지를 각각 연 것은 아니다.

변경 구현: `project/game/battle_v3.gd`, `dungeon_enemy_r21.gd`. 변경 검사: `project/tests/enemy_action_r21_test.gd`, `enemy_regression_r21_test.gd`, 새 `enemy_review_r21_test.gd`와 `.uid`. 도구: `tools/verify_data_r21.py`, 새 `check_enemy_samples_r21.py`, `oracle_enemy_review_r21.mjs`, `report_enemy_review_r21.py`. 보고·근거: `DATA-R21.md`, `verification/data-r21/**` 및 필수 검사에서 재생성한 기존 verification·라이선스 결과.

Web export·버전 갱신은 실행하지 않았으며 `docs/`·원본 봇·다른 worktree에는 쓰지 않았다. 공통 규칙을 읽기 전에 `git status --short`를 호출한 실수가 있었고 소유권 오류로 실행에 실패했다. 그 뒤 git 명령은 사용하지 않았고 저장소 설정도 바꾸지 않았다. 최종 전체 실행의 스크립트·엔진 오류는 0이며, 반복되는 OS 인증서 저장소 진단은 기존 환경 메시지로 따로 분류했다.

| 최종 검사 | 결과 | 실패 |
|---|---|---:|
| `import` | 통과 | 0 |
| `world_test` | 통과 | 0 |
| `state_test` | 통과 | 0 |
| `route_test` | 통과 | 0 |
| `expansion_test` | 통과 | 0 |
| `motion_test` | 통과 | 0 |
| `motion_asset_test` | 통과 | 0 |
| `art_test` | 통과 | 0 |
| `export_licenses` | 통과 | 0 |
| `data_r21_test` | 통과 | 0 |
| `dungeon_r21_test` | 통과 | 0 |
| `enemy_regression_r21_test` | 통과 | 0 |
| `enemy_action_r21_test` | 통과 | 0 |
| `enemy_review_r21_test` | 통과 | 0 |
| `ui_battle_r17_test` | 통과 | 0 |
| `ui_battle_r18_test` | 통과 | 0 |
| `ui_battle_r19_test` | 통과 | 0 |
| `ui_battle_r20_test` | 통과 | 0 |
| `motion_r9_integration` | 통과 | 0 |
| `motion_r18_integration` | 통과 | 0 |
| `ui_data_r21_test` | 통과 | 0 |

<!-- R21_THIRD_END -->

<!-- R21_SECOND_START -->
## 2차 — 검수 8건 수정 및 적 행동 원본 실행 대조

2026-10-31. 지시서의 8건을 모두 수정했다. 기각은 없다. 수정 전에 재현 검사를 실행하여 **12항목 중 10항목 실패**를 확인했다(`enemy-regression-before.json`). 이후 대상·수명·저장·해제·중복 정산 검사를 보강한 최종 재현 검사는 **30항목, 실패 0**이다. 기존 공통 검사의 기대값은 바꾸지 않았다.

| 지적 | 재현 → 수정 | 정본 근거 |
|---|---|---|
| 1. 메아리 약점 | 2단계 진입·차례 순환이 실행되지 않음 → JSON의 `weak_cycle`을 읽는다. 서로 다른 속성 2개를 원본 순서로 추첨하고 저장·복원한다. | `31-foes.lua:206–214, 464–471`; JSON→Lua 생성물의 `ph2.cycle`과 구분 |
| 2. 침묵 후보 | Dictionary 삽입 순서에 따라 다른 기술 봉인 → 실제 `B.KIT` 배열의 직업 기술 순서 뒤에 개인 기술을 붙인다. `atk/df`는 제외한다. | `20-state.lua:84–107`, `31-foes.lua:410–420` |
| 3. 충전 고갈 | 고갈 뒤 큰 기술을 다시 실행 → 고갈 차례에 충전을 취소하고 큰 기술의 다음 순번으로 이동한다. 과열 자해도 그 시점에 적용한다. | `30-engine.lua`의 `lost_turn`; `31-foes.lua:440–450` |
| 4. 대상 | 전열·고정 대상·자기 버프 예고 오류 → 살아 있는 아군 무작위, `low`는 HP 비율 최저, 지원 행동 예고는 자기 자신. 실행 시 첫 번째 살아 있는 도발자가 우선하고, 예고 대상 이탈 시 첫 생존자로 대체한다. 예고 조회는 RNG를 소비하지 않는다. | `30-engine.lua:146–164`, `enemy_target` |
| 5. 깃발 오라 | 일반 버프처럼 소멸 → 원본의 99차례 값과 시전자 표식을 보존하고, 시전자 사망·고갈 즉시 제거한다. 재시전은 같은 키를 덮어쓴다. | `31-foes.lua:252–258`; `30-engine.lua`의 `drop_src/deplete` |
| 6. 약점 지연 | 구역 보스에게도 전량 지연 → `B.rdm`에 해당하는 구역 보스 감경 0.5를 곱한다. | `31-foes.lua:88–90`, `30-engine.lua:28` |
| 7. 지속 피해 | 마지막 1줄로 덮임 → 적이 건 피해를 최대 4줄로 보관, 초과 시 가장 오래된 줄 제거, 보유자 차례 시작에 합산하고 각각 수명을 줄인다. 방어·공격 약화·자기 강화가 적용된 원본의 DOT 산식도 사용한다. | `31-foes.lua:138–163, 314–315` |
| 8. 엘리트 보장 장비 | 핵 의뢰 등에 보장 장비가 없음 → 균열 의뢰 종류와 무관하게 엘리트 승리 시 원본의 개수·등급·직업·슬롯·장비 코드 추첨으로 1~2개 지급한다. 일반 던전 드롭은 별도 유지하고, 균열에는 던전 확률 드롭을 섞지 않는다. 재정산은 거부한다. | `70-town.lua:146–152`, `72-guild.lua`의 `gd_gear`, 의뢰 카드 187줄 |

### 행동 대조 수치와 범위

| 항목 | 결과 |
|---|---:|
| 원본 적 / 적마다 이어진 차례 | 100종 / 12~15차례 |
| 원본 Lua 행동 표본 | 1,221 |
| 같은 입력 상태에서 개별 차례 재생 | 1,221/1,221, 100% |
| GDScript 상태를 계속 이어간 연속 차례 대조 | 1,221/1,221, 100% |
| 10직업 침묵 선택 추가 표본 | 200, 전부 일치 |
| 엘리트 의뢰 장비 코드 추가 표본 | 120, 전부 일치 |
| 새 행동 대조 검사 | 2,762항목, 실패 0 |
| 재현·수명·저장·해제 검사 | 30항목, 실패 0 |
| 편성·능력치·탐색 기존 Lua 대조 | 7,493항목, 실패 0 |
| 던전 통합 | 3,057항목, 실패 0 |
| 1~420층 종결 | 승리 420 / 패배 420 |
| 1~60층 자연 전투 표본 | 승리 140 / 패배 53 |
| UI 이름표 | 3,200개, 넘침 0 |
| 원본 자산 / 데이터·원본 변경 | 96/96 보존 / 불일치 0·원본 변경 0 |
| import + 공통·기존·신규 검사 | 20종 통과, 실패 0 |

`tools/oracle_enemy_r21.mjs`가 원본 하네스의 wasmoon으로 **실제 `20-state.lua`, `30-engine.lua`, `31-foes.lua`를 다시 적재해 직접 실행**한다. GDScript를 번역해 만든 가짜 oracle은 없다. 파일 목록과 입력·출력은 `enemy-action-oracle.json`, 개별 적의 표본 수와 불일치 목록은 `enemy-action-results.json`에 남겼다. 새로 조사한 `30-engine.lua`·`70-town.lua`의 해시도 `source-inventory.json`에 추가했다.

아군은 양쪽 모두 같은 HP·방어·생존 상태인 중립 fixture다. 캐릭터·종족·장비의 개별 훅을 끄고 적 행동을 분리했다. 정해진 차례에 도발, 아군 이탈, 2단계 진입, 충전 고갈을 양쪽에 똑같이 넣는다. 첫 대조는 각 원본 입력에서 한 차례씩 재생한다. 두 번째 대조는 각 적의 첫 상태만 넣은 뒤 **게임 상태를 덮어쓰지 않고** 12~15차례를 이어가며, 아군·다른 적 보유자의 실제 틱도 실행한다. 대상 예고와 효과의 실제 대상, HP·피해·회복·보호막·지연, 행동 순번·충전·고갈·단계·약점, 오라 시전자와 버프·DOT 수명, 보호·은신, 원본 행동 RNG를 비교한다. 정수·식별자는 정확 비교, 실수 산술은 절대 오차 `1e-8` 이내다. empty Lua table의 JSON `[]`와 GDScript `{}`만 같은 빈 값으로 정규화한다.

대조 중 추가로 확인한 보호 대상(후열 우선·HP 비율 최저), 회복·단일 아군 버프 대상(HP 비율 최저), 자기 공격 강화와 오라의 곱셈, 지원 버프 수명 틱, 소환 직후 대상 추첨도 수정했다. 공격이 빗나가면 흡혈·DOT·밀기·강화 해제를 적용하지 않는다. 새 DOT는 정화 물약과 저장·복원에 연결했고 UI에는 한국어 효과명을 표시한다.

### 저장과 통합 계약

저장 schema는 3을 유지한다. DOT는 기존 `effects` 아래 최대 4개 레코드, 오라는 기존 효과 레코드의 시전자, 원본 적 RNG는 기존 `extra_state`의 숫자로 보관한다. 옛 저장에 이 필드가 없어도 읽는다. 새 RNG의 유효 범위를 Park–Miller 범위로 검사하고, 기존의 가변 `extra_state` 키를 허용하는 모양 검사를 유지한다. 원본 오라·DOT의 JSON 왕복, 단계/소환 복원, 기존 schema 1·2 원정 이관과 결정론 이어하기를 검사했다. 사용자 저장을 지우거나 덮어쓰지 않았다.

엘리트 장비의 원본 `G.seed`는 웹 월드의 저장된 입장 RNG로 대응해 run에 고정한다. D 갈래가 원본 마을 씨앗을 보유하면 `source_quest.town_seed`로 넘길 수 있다. 이 값과 의뢰 ID·파티 직업이 같을 때 원본 장비 코드 120/120이 일치한다. 옛 진행 중 의뢰에 `quest_seed`가 없으면 기존 `run.seed`를 사용한다. 기존 r20 연구 기술처럼 원본 `B.SK`와 다른 추가 기술은 원본 침묵 후보를 임의로 늘리지 않으며, 실제 존재하는 대응 직업·개인 기술만 봉인한다.

### 전투 엔진 구조 때문에 남기는 차이

행동 fixture의 불일치는 0이다. 이것을 원본 전투 전체의 동등성으로 확대하지 않는다.

1. r20 CTB는 실수 시간으로 다음 차례를 고르고 원본 `B.advance`는 `ceil(g/sp)`와 누적 시간 라운드를 쓴다. 레이드 장기전은 현재 r20의 적 행동 횟수 근사치를 유지하므로 원본 20라운드 경계와 다를 수 있다. 전투 순서·승률 대조는 이번 행동 검사가 아니다.
2. 아군 공격·특성·종족·장비·연구 기술은 r20 구현을 유지한다. 원본 `B.fire/B.chain` 훅 전체가 이식된 것은 아니다. 적 공격은 r20의 아군 회피·피해 감소·보호·부활 처리를 거친다. 새 적 RNG는 원본의 행동별 씨앗·16807 곱을 사용하지만 아군의 RNG와 전체 전투의 소비 순서는 원본으로 교체하지 않았다. 아군 행동으로 발생한 단계 전환까지 포함하는 전체 난수열 동등성은 검증하지 않았다.
3. 새 적 DOT의 중첩·기본 피해·수명·보호막은 옮겼지만 원본 `B.strike`의 모든 장비·종족·피격·사망 훅을 새 DOT 틱에서 재실행하는 것은 아니다. 중립 fixture 밖의 그 훅 조합은 동등성 보장 범위에서 제외한다.
4. B 갈래의 적 전용 그림은 이번 작업 범위에 없다. 현재 대체 그림은 100/100이고 원본 그림 바이트는 유지했다. 성적 콘텐츠는 추가 이관하지 않았다(`79-sex.lua`는 기존 목록만 유지).

### 실행·시각 확인·바꾼 파일

```powershell
node tools/oracle_data_r21.mjs
python tools/import_data_r21.py
node tools/oracle_enemy_r21.mjs
python tools/audit_data_r21.py
python tools/verify_data_r21.py
python tools/report_enemy_r21.py
```

Web export와 버전 갱신은 실행하지 않았고 `docs/`는 수정하지 않았다. git 명령, 다른 worktree 쓰기, 원본 봇 쓰기를 하지 않았다. 검사에서 반복되는 OS 인증서 저장소 진단은 기존과 같은 환경 메시지다. 전체 재검사 중 r18 화면 검사는 4,592개 기능 검사가 통과한 뒤 종료 시 리소스 1개 미해제 진단을 한 번 냈다. 해당 로그(`ui_battle_r18_test-shutdown-warning.log`)와 실패한 회차(`suite-second-pass-retry-needed.json`)를 보존하고 단독 재실행했다. 최종 회차의 스크립트·엔진 오류는 0이며, 각 검사 최신 실행의 합계는 `suite-final.json`이다.

직접 연 이미지: `verification/data-r21/battle-360-7.png`, `battle-390-5.png`, `verification/ui-r18/base-360.png`, `verification/ui-r20/all-states-360.png`. 이름표 말줄임·HP·아군 카드·전투 명령·기술/보급품/기록 시트의 배치를 확인했다. 전체 생성 이미지 각각을 눈으로 확인한 것은 아니다.

바꾼 구현: `project/game/dungeon_enemy_r21.gd`, `dungeon_world_r21.gd`, `dungeon_rules_r21.gd`, `battle_v3.gd`; 정본 추가 설정·출처: `project/data/dungeons-r21.json`, `enemies-r21.json`; 검사: `enemy_regression_r21_test.gd`, `enemy_action_r21_test.gd`, `enemy_action_fixture_r21.gd`; 도구: `oracle_enemy_r21.mjs/.lua`, `oracle_data_r21.mjs`, `import_data_r21.py`, `verify_data_r21.py`, `report_enemy_r21.py`; 보고·근거: `DATA-R21.md`, `verification/data-r21/**`. 공통 검사 결과와 라이선스 파일도 재생성됐다.

| 최종 검사 | 결과 | 실패 |
|---|---|---:|
| `import` | 통과 | 0 |
| `world_test` | 통과 | 0 |
| `state_test` | 통과 | 0 |
| `route_test` | 통과 | 0 |
| `expansion_test` | 통과 | 0 |
| `motion_test` | 통과 | 0 |
| `motion_asset_test` | 통과 | 0 |
| `art_test` | 통과 | 0 |
| `export_licenses` | 통과 | 0 |
| `data_r21_test` | 통과 | 0 |
| `dungeon_r21_test` | 통과 | 0 |
| `enemy_regression_r21_test` | 통과 | 0 |
| `enemy_action_r21_test` | 통과 | 0 |
| `ui_battle_r17_test` | 통과 | 0 |
| `ui_battle_r18_test` | 통과 | 0 |
| `ui_battle_r19_test` | 통과 | 0 |
| `ui_battle_r20_test` | 통과 | 0 |
| `motion_r9_integration` | 통과 | 0 |
| `motion_r18_integration` | 통과 | 0 |
| `ui_data_r21_test` | 통과 | 0 |

<!-- R21_SECOND_END -->

## 1차 기록 (이하 수치는 1차 완료 당시의 기록)

2026-10-31 · 작업 공간 `work/r21-a-data` · `ui_build: r21-a-data-20261031`

## 결과 수치

| 항목 | 결과 |
|---|---:|
| 적 / 계열 | 100 / 30 |
| 지역 / 실제 던전 구역 / 균열 | 10 / 9 / 6 |
| 원본 데이터 필드 불일치 | 0 |
| 편성·능력치 대조 조건 | 1,028개, 100% 일치 |
| 별도 개별 적 능력치 / 탐색 / 의뢰 규칙 대조 | 700 / 300 / 480개, 모두 일치 |
| Lua 대조 검사 항목 | 7,493개, 실패 0 |
| 던전 통합 검사 | 3,069개, 실패 0 |
| 1~420층 종결 경로 | 승리 420 / 패배 420 |
| 1~60층 자연 전투 표본 | 승리 147 / 패배 52 |
| 390·360 폭 이름표 | 3,200개, 넘침 0 |
| 원본 그림 바이트 보존 | 96/96, 변경 0 |
| 새 적 그림 미도착 시 역할별 대체 | 100/100 |
| 공통·신규 Godot 검사 | 18종 통과, 실패 0 |
| 실제 Web 입력·전투 복원·승리 후 원정 복귀 | 390·360, 2/2 통과 |
| Web export | 성공, 필수 리소스 누락 0 |

지역 10개에는 `common` 공통 적 풀이 포함된다. 원본의 실제 던전 구역은 아홉 개다. 숫자를 맞추려고 열 번째 던전을 만들지 않았다.

## 옮긴 데이터와 규칙

- `project/data/enemies-r21.json`: 원본 JSON의 적 100종과 계열·역할·등급·속성·행동·규칙·단계·tune·threat·templates를 원형대로 보존했다. 각 적에 원본 파일·JSON pointer·SHA-256과 `res://assets/enemies-r21/<id>.png`를 추가했다.
- `project/data/dungeons-r21.json`: zones 10·rifts 6, 원본 순서, 표준 적·성장 곡선·★·레벨 상한, 탐색 상수, 장비 발견용 순서·가중치, 호감·의뢰 보상 상수를 담았다. 출처와 해시를 넣었다.
- 1~27층은 아홉 구역을 3층씩 진행한다. 28층부터 27층 주기로 구역을 되풀이하고 `dk/dc`, ‘깊은’ 접두사, Lv40 하한, 심층 보상을 적용한다.
- 파티 평균 반올림 + 구역 안 순서 0~2, 구역 하한, Lv40 상한을 그대로 옮겼다.
- Park–Miller 난수 워밍업 4회, 가중 템플릿, 인원별 적 수, 전열·지원·소환·충전·공통·중복·위협·약점 합집합 제한, 40회 재시도, DFS와 `relaxed`, 빌려 온 정예·우두머리, 호위와 소환 예약 칸을 옮겼다.
- 능력치는 `stat_role`과 등급·개별 gauge를 반영한다. 층 log 곡선·단조 캐시, 구역별 우두머리/보스 보정, 심층 보스 `deep`, 탐색 전용 곡선, 3층 보정·초입 완화·소인원 완화를 반영했다.
- 탐색 5회 → 휴식 → 층 보스 → 정산을 구현했다. 전투 70%, 3층·3번째 탐색부터 정예 20%·최대 2회, 발견 50/35/15, SplitMix 방식의 int64 wrap·논리 시프트, 보스/전투 씨앗을 옮겼다.
- HP·MP 이어받기, 쓰러진 동료 HP 20%, 휴식 진입 때 전원 HP 30%·MP 60%, 금화·경험치 누적, 아이템/장비 정산, 패배 시 미정산 수확 소실·기본 소지 금화 손실, 최심층·첫 구역 보스·지름길을 연결했다.
- 균열은 한 번의 전투다. `depart_rift_quest(q, seed)`가 원본 의뢰 형식의 `rift/kind/stars/lv/gold/reward_v/difficulty/cmp/strength`를 받아 일반·정예·핵 편성, 보상, 엘리트 배율로 연결한다. 의뢰판과 마을 시설 UI는 D 갈래가 연결할 대상이다.
- 기존 r20 전투 모델에 새 적 행동 어휘, 소환 예약 칸, 보스 단계·약점 변경, 봉인·보호·고갈·기본 고유 규칙을 연결했다. 화면 렌더러의 칸 ID는 그대로 두고 원본 ID는 `foe_id`로 보존한다.
- 새 art 파일이 있으면 즉시 사용한다. 없으면 지원·소환→등불, 사격·주술→수정구, 방어/근접 정예·보스→집행 인형, 나머지 근접→견습 인형을 사용한다. `art_fallback`으로 셀 수 있다.
- 마을 파일은 모델 교체·출정/탐색 위임·현재 장소 제목 정도만 고쳤다. 기존 컨트롤을 재사용하는 최소 출정 UI는 `game/dungeon_view_r21.gd`에 있다. 전투는 이름·역할·층·빌드 표기와 긴 이름의 말줄임표/전체 툴팁, 큰 HP 숫자의 칸 안 맞춤을 바꿨다. 7칸 표본 이미지를 직접 열었을 때 HP가 이웃 칸과 겹쳐, 새 데이터 조건에서만 숫자를 가로로 맞추고 정확한 숫자는 보존했다. r20 잉크·컷인·효과·배치 자산은 수정하지 않았다.

## 저장과 기존 시험

기존 schema 1·2 저장을 읽는다. 진행 중인 옛 원정·기존 네 적 전투는 해당 원정이 끝날 때까지 기존 모델을 사용한다. 새 원정은 기존 schema 2에 `dungeon_r21`과 run의 `data_version=21`을 추가한다. 저장 파일을 지우거나 초기화하지 않는다. 새 전투의 단계와 소환 roster도 저장·복원한다.

검사에는 schema 1, schema 2의 진행 중 전투, 새 원정 JSON 왕복, 같은 씨앗의 이어하기, 단계 2 + 하수인 2명 복원, 잘못된 층·roster·진행 정보 거부를 포함했다. 기존 시험의 기대값은 바꾸지 않았다.

JSON은 숫자를 float로 읽고 GDScript Dictionary 키에는 StringName도 있으므로 새 이어하기 검사는 저장 형식의 타입 차이를 정규화하고 숫자 값은 정확히 비교한다. Web 진단 JSON에는 CTB remaining 값의 약 1e-11 반올림 차이가 있어 해당 브라우저 비교만 절대 오차 1e-8을 허용했다. HP·MP·RNG·차례·게임 결과는 보존했다.

## 원본 조사와 대조 방식

정본 루트: `C:/Clauede Code/dungeon-bot`. JSON은 전체 파싱·필드 대조했고, Lua는 원본 하네스의 wasmoon으로 실행하면서 아래 파일과 관련 함수 구간을 검토했다. 파일별 정확한 해시는 `verification/data-r21/source-inventory.json`, 출처 pointer는 새 데이터에 남겼다.

| 조사 파일 | 파일 범위 |
|---|---|
| `design/enemies.json` | 1–5533 |
| `design/ENEMIES.md` | 1–803 |
| `design/DUNGEON.md` | 1–346 |
| `design/EXPEDITION.md` | 1–166 |
| `design/stats.json` | 1–2561 |
| `bot/src/20-state.lua` | 1–370 |
| `bot/src/24-stats.lua` | 1–184 |
| `bot/src/26-start.lua` | 1–86 |
| `bot/src/27-compose.lua` | 1–403 |
| `bot/src/31-foes.lua` | 1–545 |
| `bot/src/72-guild.lua` | 1–370 |
| `bot/src/74-affection.lua` | 1–65 |
| `bot/src/76-dungeon.lua` | 1–117 |
| `bot/src/77-explore.lua` | 1–924 |
| `bot/src/51-raid.lua` | 1–99 |
| `bot/src/81-gear.lua` | 1–1204 |

주요 검토 구간: `24-stats` 전체, `27-compose` 전체, `20-state`의 `foe_def/blank_u/fresh`, `31-foes`의 행동·단계·보상, `76-dungeon` 전체, `77-explore` 14–76(상수·추첨), 98–120(입장 씨앗), 199–525(전투·휴식·정산), 650–924(진행 버튼·화면·이관), `51-raid` 전체, `72-guild`의 전투 종류·레벨 보상·의뢰 금화, `81-gear`의 `gear_drop/gear_code`이다. 문서에서는 `DUNGEON` 101–145의 확정 흐름과 `ENEMIES`의 조합·심층·레이드·최신 튜닝을 우선했다. 폐기된 갈림길 설계를 되살리지 않았다.

`tools/oracle_data_r21.mjs`는 원본 `lua_sim.mjs`/RisuSim/wasmoon을 읽기 전용으로 사용하며, 원본 src를 다시 올려 실행한다. 원본 파일을 생성·빌드·수정하지 않는다. 각 표본의 ctx·seed·enc·el·stats·탐색/의뢰 결과는 `lua-oracle.json`에 남겼다.

편성 표본은 1~60층 × 1~4인 × 일반/정예/층 보스, 81·108·135·270·420층 추가 표본, 균열 6개 × ★1~4 × 1~4인 × 일반/정예/핵이다. 개별 적은 100종 × 1·2·3·27·28·55·420층이다. 탐색은 60층 × 5회, 의뢰는 Lv1~40 × 난이도 4 × 목표 3이다. 편성·레벨·금화·아이템/장비 코드 등 이산 값은 정확히 같고, Lua JSON이 표시하는 능력치 실수는 상대 오차 1e-12/절대 1e-10 이내로 대조했다.

1~420층의 승리·패배 840건은 결과 경로를 모두 통과시키기 위해 공격력만 조절한 시험 fixture다. 별도로 1~60층에서는 수치를 바꾸지 않고 기본 공격 정책으로 탐색부터 종결까지 진행했다. 자연 전투 승패는 밸런스 목표나 원본 Lua 승률과의 동등성을 뜻하지 않는다. 끝없는 층 전체를 유한 검사로 전부 검증했다고 주장하지 않는다.

## 검사 결과

| 검사 | 결과 | 실패 |
|---|---|---:|
| import | 통과 | 0 |
| world_test | 통과 | 0 |
| state_test | 통과 | 0 |
| route_test | 통과 | 0 |
| expansion_test | 통과 | 0 |
| motion_test | 통과 | 0 |
| motion_asset_test | 통과 | 0 |
| art_test | 통과 | 0 |
| export_licenses | 통과 | 0 |
| data_r21_test | 통과 | 0 |
| dungeon_r21_test | 통과 | 0 |
| ui_battle_r17_test | 통과 | 0 |
| ui_battle_r18_test | 통과 | 0 |
| ui_battle_r19_test | 통과 | 0 |
| ui_battle_r20_test | 통과 | 0 |
| motion_r9_integration | 통과 | 0 |
| motion_r18_integration | 통과 | 0 |
| ui_data_r21_test | 통과 | 0 |

실행 명령과 전체 로그는 `verification/data-r21/`에 있다. 재현 명령:

```powershell
node tools/oracle_data_r21.mjs
python tools/import_data_r21.py
python tools/audit_data_r21.py
python tools/verify_data_r21.py
python tools/export_data_r21.py
python tools/web_data_r21.py
python tools/report_data_r21.py
```

Windows 격리 환경에서 Godot가 출력하는 `Failed to read the root certificate store`는 모든 실행에 반복되는 환경 진단이다. 검사/스크립트 오류와 분리해 기록했으며, 그 외 엔진 오류는 0이다. 네트워크 기능을 시험한 것은 아니다.

Web은 지시한 `python tools/godot_r17.py --headless --export-release Web ../docs/index.html` 뒤 `python tools/update_version.py`로 생성했다. PCK 53,576,236 bytes, SHA-256 `812d35e1fb38310ca1d71becd01e29fbc6e4ebe0794624ae2337bf77cf99bf0a`. 필수 JSON·게임 스크립트 6개 포함을 확인했다. 두 브라우저 폭에서 실제 포인터로 출정·탐색·공격·새로고침·승리 후 원정 복귀를 검증했다.

직접 연 이미지: `battle-390-5.png`, `battle-360-7.png`, Web의 `selector-360.png`, `battle-390.png`, `return-360.png`. 말줄임표와 전체 툴팁, 역할·약점·HP·층 표기를 확인했다. 새 적 전용 그림 100종은 아직 없으므로 대체 그림의 적별 외형 적합성까지 확인한 결과는 아니다.

## 원본 대비 차이·남은 통합

1. 데이터·편성·초기 능력치·탐색 추첨·기본 의뢰 보상은 위 Lua 표본과 일치한다. **전투 전체의 턴별 결과가 Lua와 같은 엔진으로 교체된 것은 아니다.** 기존 `battle_v3.gd`의 아군·CTB·난수 모델을 유지했다. 지속 피해 중첩/갱신, 광폭화 라운드 계산, 일부 고유 행동의 부가 효과·출신/장비 보상 훅 등은 웹 모델의 호환 구현이며 전체 Lua 전투 동등성은 검증하지 않았다.
2. 원본의 rest 정비·서사/채팅 게이트·다음 층 즉시 이동 UI와 길드 의뢰판 생성 전체는 이번 A UI에서 옮기지 않았다. 다음 열린 층은 출정 선택에서 고른다. 균열은 `depart_rift_quest` API로 연결하며, 원본 의뢰판에 현재 없는 네 균열의 해금 조건은 만들지 않았다. API의 원본 의뢰 스펙을 넘기지 않은 내부 균열 시험에는 고정 금화 보상 ‘없음’(0)으로 처리한다.
3. 원본 북동 화산의 데이터는 ★4지만 `compose`가 균열 ★를 3으로 누르는 원본 동작을 보존했다. 문서의 옛 곡선/드랍 설명과 현재 JSON·Lua 값이 다르면 현재 JSON·실행 코드를 따랐다.
4. 원본 `B.tx_*` 출신 시너지의 탐색 추가 수확·휴식 추가 회복·패배 보존과 원본 장비 효과의 모든 보상 훅은 추가 이관하지 않았다. 기본 파티/기본 규칙 기준 검증이며 이 훅을 포함한 결과 일치를 주장하지 않는다. 새 전투 전용 적 그림은 B 갈래 파일 도착 시 자동 선택한다.
5. 성적 콘텐츠는 이관하지 않았다. 해당 원본 파일 목록: `bot/src/79-sex.lua`(참조 목록만 기록). 성적 장면·친밀도 장면 생성이나 UI는 추가하지 않았다.

## 바꾼 파일과 D/B 갈래 연결 지점

- 데이터: `project/data/enemies-r21.json`, `project/data/dungeons-r21.json`.
- 게임: 새 `dungeon_rules_r21.gd`, `dungeon_world_r21.gd`, `dungeon_enemy_r21.gd`, `dungeon_view_r21.gd`; 기존 `battle_v3.gd`의 새 데이터 조건부 처리.
- UI: `project/ui/world_screen.gd`의 최소 진입/위임, `project/ui/battle_screen.gd`의 이름·역할·숫자 맞춤·빌드 표시. `_location()`의 기존 floor 지원을 새 데이터로 활성화했다.
- 검사: `project/tests/data_r21_test.gd`, `dungeon_r21_test.gd`, `ui_data_r21_test.gd`.
- 도구: `tools/oracle_data_r21.mjs`, `import_data_r21.py`, `audit_data_r21.py`, `verify_data_r21.py`, `export_data_r21.py`, `web_data_r21.py`, `report_data_r21.py`; 기존 `update_version.py`의 ui_build. README 맨 위 한 줄.
- 산출물: `verification/data-r21/**`, `DATA-R21.md`. 공통 검사/명시된 Web export가 요구한 기존 verification·라이선스·`docs/index.*`·`docs/version.json` 재생성도 포함한다. 새 게임/시험 스크립트의 Godot `.uid`는 자동 생성됐다.

B: `project/assets/enemies-r21/<원본 id>.png`를 넣으면 대체가 해제된다. D: `dungeon_world_r21.gd`를 모델로 사용하고 `depart_dungeon(floor, seed)` / `depart_rift_quest(source_quest, seed)` / `advance()` / `final_battle()` / `battle_data()` / `record_battle()` / `finish_battle()`를 호출하면 된다. 원본 수치 조회·순수 편성 검증은 `dungeon_rules`를 사용한다. 다른 worktree에는 쓰지 않았고 git 명령은 실행하지 않았다.
