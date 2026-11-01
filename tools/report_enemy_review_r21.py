"""Publish third-pass evidence without rewriting first/second-pass history."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/data-r21'
read = lambda name: json.loads((OUT / name).read_text(encoding='utf-8-sig'))
suite = read('suite-all.json')
action = read('enemy-action-results.json')
review = read('enemy-review-latest.json')
regression = read('enemy-regression-latest.json')
probes = read('sample-probes-final.json')
audit = read('source-audit.json')
integration = read('integration.json')
ui = read('ui-results.json')
assert len(suite) == 21 and all(row['passed'] for row in suite)
assert action['failures'] == 0 and not review['failures'] and not regression['failures']
assert len(probes) == 4 and all(row['rejected'] for row in probes)
assert audit['failures'] == 0
before = read('third-protected-before.json')
changes = [name for name, sha in before.items()
           if not Path(name).is_file() or hashlib.sha256(Path(name).read_bytes()).hexdigest() != sha]
assert not changes, changes
protected = {'files_checked': len(before), 'changed_files': changes,
             'docs_files': sum(name.startswith('docs\\') or name.startswith('docs/') for name in before),
             'original_assets': audit['original_assets'], 'asset_changes': audit['changed_assets']}
(OUT / 'third-protected-after.json').write_text(json.dumps(protected, indent=2) + '\n', encoding='utf-8')
(OUT / 'suite-third-final.json').write_text(json.dumps(suite, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
evidence = review['evidence']
rows = '\n'.join(f"| `{row['test']}` | 통과 | 0 |" for row in suite)
section = f'''<!-- R21_THIRD_START -->
## 3차 — 재검수 4건 재현·수정

2026-11-01. 지적 4건 모두 수정했으며 기각은 없다. 구현을 바꾸기 전에 `enemy_review_r21_test.gd`를 실행해 **20항목 중 7항목 실패**를 확인했다(`verification/data-r21/enemy-review-before.json`). 표본 검사는 별도 음성 시험 4건 모두 종료 코드 0으로 잘못 통과하는 것을 먼저 확인했다(`sample-probes-before.json`). 그 뒤 구현과 검사를 보강했으며, 최종 **21종 검사 모두 통과·실패 0**이다. 아래 1·2차 절은 해당 차수 당시의 기록이다.

| 지적 | 먼저 재현한 결과 → 수정 | 원본 근거 |
|---|---|---|
| 1. DOT 일반 피해 경로 누락 | 직접 HP·보호막을 깎아 duty·치명 피해 버팀·피해 후 훅이 실행되지 않았다. DOT 합계를 1회 `_incoming_strike(..., fixed=true)`로 보내 일반 적 공격과 피해 감소·보호막·버팀·피해 후 처리를 공유한다. 고정 피해는 방어 자세·공격 회피·공격자 반사·가시 반격을 거치지 않는다. take와 duty 반올림 순서도 원본처럼 처리한다. | `31-foes.lua:145–159`, `30-engine.lua:330–407` |
| 2. 순수 DOT 회피 누락 | 회피 100%여도 중첩이 들어가고, 회피용 RNG 1회가 빠졌다. 대상 결정 뒤 캐릭터 회피 → 국가·장비 합산 회피 → 적중 시 중첩 → 다음 대상 추첨 순서로 처리한다. 확률 0인 전역 회피는 RNG를 소비하지 않는다. | `31-foes.lua:305–315`, `32-personal-a.lua:215–227`, `34-traits.lua:321–330` |
| 3. 저장 후 예고 변경 | 실제 행동이 2차례 진행된 첫 재현에서 저장 대상 `executor`가 불러오면 `hildegard`로 바뀌었다. 이제 roster에 `target_id`를 저장·검증·복원한다. 강화한 중립 파티 검사에서도 {evidence['turn_count']}차례 후 `{evidence['saved_target']}` → `{evidence['loaded_target']}`로 유지된다. 다음 행동 후 전체 snapshot도 JSON 숫자 타입을 정규화한 값으로 정확히 일치한다. | `battle_v3.gd` snapshot/restore, `dungeon_enemy_r21.gd` roster/hydrate/initialize_targets |
| 4. 표본 0개 통과 | 실제로 `checks=0, failures=0, gear_samples=120`으로 성공했다. 행동 ≥1,221개, 정본 적 100종 각각 ≥12차례, 침묵 ≥200개·10직업 각각 ≥20개, 장비 ≥120개를 실행 전에 단언한다. `gear_samples`는 읽은 배열 크기다. 빈 전체·적 1종 누락·침묵 0·장비 0의 네 입력을 모두 실패로 거부한다. | 기존 oracle 생성 범위와 정본 적 목록 |

추가 원본 대조에서 보호막 파괴 회복(`pa_echo`)이 치명 피해 버팀보다 먼저 실행되어 쓰러진 동료를 잘못 되살릴 수 있는 경우도 재현했다(`enemy-review-echo-before.json`, 2건 실패). 고정 피해에서는 버팀과 피해 후 훅을 처리한 뒤 살아 있는 동료에게만 회복한다. 일반 r20 적 공격의 기존 처리 순서는 유지했다.

| 핵심 수치 | 최종 결과 |
|---|---:|
| 새 재현·저장·훅·RNG 검사 | {review['checks']}항목 / 실패 0 |
| 원본 실제 DOT 훅 대조 | 6/6 일치: duty·보호막, 마지막 성벽·상처, 최후의 저항, 사제 버팀, 파괴 회복의 생존·사망 |
| 원본 실제 회피·중첩·RNG·다음 대상 대조 | 120/120 일치: 회피 0/15/100% × 국가 없음/나에린 × 20씨앗 |
| 표본 누락 음성 시험 | 4/4 정상 거부 |
| 적 행동 검사 | {action['checks']:,}항목 / 실패 0 |
| 적 / 개별 행동 / 연속 행동 | {action['enemies']}종 / {action['matched']:,}/{action['samples']:,} / {action['continuous_matched']:,}/{action['samples']:,} |
| 침묵 / 장비 표본 | {action['silence_samples']} / {action['gear_samples']} / 불일치 0 |
| 기존 재현 검사 | {regression['checks']}항목 / 실패 0 |
| 던전 통합 | {integration['checks']:,}항목 / 실패 0 |
| 1~420층 강제 종결 경로 | 승리 {integration['outcomes']['victory']} / 패배 {integration['outcomes']['defeat']} |
| 1~60층 자연 전투 표본 | 승리 {integration['outcomes']['natural_victory']} / 패배 {integration['outcomes']['natural_defeat']} |
| UI 이름표 | {ui['nameplates']:,}개 / 넘침 {ui['overflow']} |
| 원본 자산 / 데이터·원본 변경 | 96/96 보존 / 불일치 0·원본 변경 0 |
| 보호 파일 해시 대조 | {len(before)}개 / 변경 0 (`docs/` {protected['docs_files']}개 포함) |

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
{rows}

<!-- R21_THIRD_END -->
'''
path = ROOT / 'DATA-R21.md'
old = path.read_text(encoding='utf-8-sig')
start, end = '<!-- R21_THIRD_START -->', '<!-- R21_THIRD_END -->'
if start in old:
    old = old[:old.index(start)] + old[old.index(end) + len(end):]
title, body = old.split('\n', 1)
path.write_text(title + '\n\n' + section + '\n' + body.lstrip(), encoding='utf-8')
summary = {'report': str(path), 'issues_fixed': 4, 'suite_count': len(suite), 'suite_failures': 0,
           'review_checks': review['checks'], 'action_checks': action['checks'],
           'enemies': action['enemies'], 'matched': action['matched'],
           'continuous_matched': action['continuous_matched'], 'negative_probes': len(probes),
           'original_assets': audit['original_assets'], 'protected_changes': changes}
(OUT / 'third-pass-summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
