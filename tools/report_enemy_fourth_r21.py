"""Record the fourth review independently of earlier review history."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/data-r21'
read = lambda name: json.loads((OUT / name).read_text(encoding='utf-8-sig'))
suite = read('suite-all.json')
before = read('enemy-review-fourth-before.json')
review = read('enemy-review-latest.json')
action = read('enemy-action-results.json')
regression = read('enemy-regression-latest.json')
oracle = read('enemy-review-oracle.json')
audit = read('source-audit.json')
integration = read('integration.json')
ui = read('ui-results.json')
assert len(suite) == 21 and all(row['passed'] for row in suite)
assert not review['failures'] and action['failures'] == 0 and not regression['failures']
assert action['matched'] == action['continuous_matched'] == action['samples'] == 1221
assert audit['failures'] == 0
assert integration['failures'] == 0 and ui['failures'] == 0 and ui['overflow'] == 0
protected = read('fourth-protected-before.json')
changed = [name for name, sha in protected.items()
           if not (ROOT / name).is_file() or hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != sha]
assert not changed, changed
guard = {'files_checked': len(protected), 'changed_files': changed,
         'docs_files': sum(name.startswith(('docs/', 'docs\\')) for name in protected),
         'original_assets': audit['original_assets'], 'asset_changes': audit['changed_assets']}
(OUT / 'fourth-protected-after.json').write_text(json.dumps(guard, indent=2) + '\n', encoding='utf-8')
(OUT / 'suite-fourth-final.json').write_text(json.dumps(suite, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
(OUT / 'enemy-review-fourth-final.json').write_text(json.dumps(review, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
old = before['evidence']['fourth']['strikes']
new = review['evidence']['fourth']['strikes']
normal_changes = [{'input': y['input'], 'before': x['actual_loss'], 'after': y['actual_loss']}
                  for x, y in zip(old, new)
                  if not y['input']['fixed'] and x['actual_loss'] != y['actual_loss']]
assert all(y['actual_loss'] == y['input']['loss'] for y in new)
(OUT / 'fourth-normal-changes.json').write_text(json.dumps(normal_changes, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
fourth = oracle['fourth']
rows = '\n'.join(f"| `{row['test']}` | 통과 | 0 |" for row in suite)
section = f'''<!-- R21_FOURTH_START -->
## 4차 — Opus 지적 8건 재현·수정

2026-11-01. **8건 모두 수정, 기각 0건.** 먼저 원본 Lua 하네스 대조 행과 Godot 시험을 추가하고, 구현을 바꾸기 전에 **{before['checks']}항목 중 {len(before['failures'])}항목 실패**를 확인했다(`enemy-review-fourth-before.json`). 펠리체의 추가 경계 검사에서도 죽은 차례의 행동 횟수·회피 스캔·적 지원 행동 종료를 구별하지 못하는 3건의 실패를 확인한 뒤 수정했다(`enemy-review-fourth-scan-before.json`). 일반 적 공격의 다음 회피 스캔도 별도 1건 실패를 확인하고 연결했다(`enemy-review-fourth-attack-scan-before.json`). 최종 재현·저장·훅·RNG 검사는 **{review['checks']}항목, 실패 0**, 필수 검사는 **21종 모두 통과, 실패 0**이다. 아래 1~3차 절은 당시 기록이며, 3차의 “GD duty = 원본 psguard” 해석은 이 절에서 바로잡는다.

| 지적 | 원본 대조·수정 전 실패 → 수정 | 원본 근거 |
|---|---|---|
| 1. duty/guard 위치 반전 | 실제 전술 suffix guard의 DOT 100 피해가 100, 힐데 duty 중 DOT 10 피해가 7이었다 → 각각 **90 / 6**. 방어 자세 `guard`와 전술 `psguard`를 분리했다. 힐데 `duty`는 `red25`에 대응해 take 반올림 전에 적용하고, `psguard`는 fixed·일반 공격 모두 take 반올림 뒤에 따로 곱하고 반올림한다. fixed는 방어 자세만 건너뛴다. | `29-persona-skill.lua:125`, `30-engine.lua:333–336`, `32-personal-a.lua:626,662–667` |
| 2. 오라클의 같은 오매핑 | 기존 duty 행은 중립 동료의 psguard를 실행해 잘못 통과했다 → Lua는 **hildegard + red25 .25 + DOT 10**, GD도 힐데 `duty .25`로 대조한다. 별도의 중립 `psguard .1 + DOT 100` 행을 추가했다. 수정한 두 행 모두 구현 수정 전에 실패했다. | `tools/oracle_enemy_review_r21.mjs`, `enemy-review-fourth-before.json` |
| 3. 순수 DOT의 콜레트 봉인 누락 | 봉인된 마법 DOT가 중첩되고 전역 회피 RNG도 소비했다 → 살아 있는 개인 훅을 **파티 슬롯 순서**로 순회하고 봉인된 마법 행동은 회피로 처리한다. 이전 훅의 true 뒤에도 뒤쪽 사야 훅은 실행하고, 전역 회피만 생략한다. 콜레트 위치·마법/물리·봉인 유무·사야 유무의 **{len(fourth['seals'])}행**에서 중첩·RNG·다음 대상이 일치한다. 정본 순수 DOT 6행은 모두 `magic:true`다. | `30-engine.lua:86–103`, `32-personal-b.lua:176–181,225–233`, `34-traits.lua:323` |
| 4. 자기 차례 마지막 성벽 수명 | 자기 DOT로 발동한 wall_party가 같은 시작 틱에서 2→1로 줄었다 → 자기 차례 발동은 +1을 넣어 3→2로 유지한다. 타인 차례 발동은 원래 수명이다. 원본 gw는 발동 직후 자기 차례 3 / 다른 차례 2이며, Godot의 시작 틱과 원본 종료 틱의 차이는 검사에 명시했다. | `81-gear.lua:650–656,971–975` |
| 5. DOT 사망 당일 즉시 소생·행동 | DOT로 쓰러진 틱에서 즉시 HP 250으로 소생했다 → **그 틱 HP 0**, 다음 스캔에서 250. 쓰러진 차례는 CTB 선택만 이어가며 행동 횟수·turn_count를 더 올리지 않는다. 펠리체는 다음 아군 turn_end·회피 훅에서 스캔하며 적 지원 행동의 enemy_end는 스캔하지 않는다. 소생 때 효과·보호막·충전을 지운다. 대기 중 JSON 저장·복원과 이어하기도 일치한다. | `30-engine.lua:1072–1074`, `32-personal-a.lua:448–485` |
| 6. 사야 반격 난수열 | 회피 뒤 반격의 치명 판정이 기존 전투 RNG를 사용해 원본 적 난수열에서 1회가 빠졌다 → 반격의 치명 굴림을 같은 원본 난수열에서 1회 소비한다. **20씨앗**에서 회피·원본 RNG·다음 대상이 일치하고 기존 별도 RNG는 변하지 않는다. 씨앗 1은 **490999122**다. 반격 피해 자체는 기존 아군 공격 구현을 유지한다. | `32-personal-a.lua:217–223`, `30-engine.lua:313` |
| 7. 구원 보호막의 장비 보너스·수호 오발동 | 마르셀린·사제 구원 보호막에 피해자 장비 shield +20%와 guardian이 적용되고 RNG를 소비했다 → 스킬 보너스 없는 원시 보호막 경로를 사용한다. 두 경우 모두 **보호막 150**, 마르셀린 HP 251 / 사제 기적 HP 600이며 RNG 소비 0이다. | `30-engine.lua:1156,376` |
| 8. 자하르 fixed의 zdn 누락 | DOT 100이 zdn 중에도 62였다 → `zdn`을 일반 방어 약화와 분리하고 원본 K·방어 비율 보정을 take 안에 넣었다. 원본 재현과 같은 방어 31.350784·K 40에서 **62→68**, 방어 40에서는 원본처럼 **69**다. fixed·일반 공격 × zdn 0/.2 × 방어 2종 **{len(fourth['zahar'])}행**이 일치한다. | `32-personal-b.lua:313–331` |

### 일반 공격 값 변화와 검증 범위

실제 GD 전술 함수를 실행해 방어 자세 보존과 별도 psguard 생성을 검사했다. fixed·일반 × 중립/힐데 × 원시 피해 7종 × 방어 자세 유무의 **{len(fourth['strikes'])}행 전체**가 원본 `B.strike`와 일치한다. 이 중 일반 공격 28행에서 **{len(normal_changes)}행의 값이 바뀌었다**(`fourth-normal-changes.json`). 예: 중립 raw 100 + 방어 자세 .4 + 전술 guard .1은 **90→54**, 힐데 duty .25 + 전술 guard .1의 raw 100은 **57→58**, 같은 조건에 방어 자세까지 있으면 **57→34**다. 기존 구현은 전술 guard가 방어 자세를 덮어썼고, take·psguard 반올림도 잘못했다. 변경 후 값은 모두 Lua 실행 결과다.

일반 공격의 방어 자세·대신 맞기 절사 위치도 take 이전으로 맞췄다. r21 적의 원시 공격 피해는 원본처럼 먼저 정수로 절사한다. 원본의 모든 take 훅·모든 장비 조합·전체 CTB 및 전투 난수열 동등성을 주장하지 않는다. 특히 사야 반격 피해량은 기존 아군 공격식을 유지하며, 이번 난수 대조는 회피·반격 치명 1회·다음 대상 추첨 범위다. 펠리체 검증은 자기 차례 DOT 사망처럼 원본 게이지가 0인 경우다. 일반 피격 사망의 시간·게이지 대기 전체를 원본 엔진으로 교체한 것은 아니다.

| 핵심 수치 | 최종 결과 |
|---|---:|
| 수정 / 기각 | 8 / 0 |
| 수정 전 재현 검사 | {before['checks']}항목 / 실패 {len(before['failures'])} |
| 최종 재현·저장·훅·RNG 검사 | {review['checks']}항목 / 실패 0 |
| 원본 DOT 훅 / 기존 회피 표본 | 7/7 / 120/120 일치 |
| take·psguard / 봉인 슬롯 순서 / 사야 / 자하르 | {len(fourth['strikes'])} / {len(fourth['seals'])} / {len(fourth['saya'])} / {len(fourth['zahar'])}, 전부 일치 |
| 적 행동 검사 | {action['checks']:,}항목 / 실패 0 |
| 적 / 개별 행동 / 연속 행동 | 100종 / 1,221/1,221 / 1,221/1,221 |
| 침묵 / 장비 표본 | 200 / 120 / 불일치 0 |
| 기존 재현 검사 | {regression['checks']}항목 / 실패 0 |
| 던전 통합 | {integration['checks']:,}항목 / 실패 0 |
| 1~420층 강제 종결 | 승리 {integration['outcomes']['victory']} / 패배 {integration['outcomes']['defeat']} |
| 1~60층 자연 전투 표본 | 승리 {integration['outcomes']['natural_victory']} / 패배 {integration['outcomes']['natural_defeat']} |
| UI 이름표 | {ui['nameplates']:,}개 / 넘침 {ui['overflow']} |
| 원본 자산 / 데이터·원본 변경 | 96/96 보존 / 불일치 0·원본 변경 0 |
| 보호 파일 해시 | {guard['files_checked']}개 / 변경 0 (`docs/` {guard['docs_files']}개 포함, 기존 1,221행 오라클 포함) |
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
{rows}

<!-- R21_FOURTH_END -->
'''
report = ROOT / 'DATA-R21.md'
text = report.read_text(encoding='utf-8')
start, end = '<!-- R21_FOURTH_START -->', '<!-- R21_FOURTH_END -->'
if start in text:
    a = text.index(start); z = text.index(end, a) + len(end)
    text = text[:a] + section.rstrip() + text[z:]
else:
    title, rest = text.split('\n', 1)
    text = title + '\n\n' + section + rest
report.write_text(text, encoding='utf-8')
print(json.dumps({'report': str(report), 'fixed': 8, 'checks': review['checks'],
                  'failures': 0, 'required_suites': len(suite), 'oracle_matched': action['matched'],
                  'normal_changed': len(normal_changes), 'protected_files': len(protected)}, ensure_ascii=False))
