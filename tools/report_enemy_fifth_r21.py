"""Record fifth-review source comparisons, changed normal strikes and checks."""
from pathlib import Path
import collections
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/data-r21'
read = lambda name: json.loads((OUT / name).read_text(encoding='utf-8-sig'))
write = lambda name, value: (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
suite = read('suite-fifth-initial.json')
# The full run passed; these are the latest affected checks after the last fix.
for name in ['suite-enemy_review_r21_test-enemy_regression_r21_test-enemy_action_r21_test.json',
             'suite-import-data_r21_test-dungeon_r21_test-ui_data_r21_test.json']:
    for row in read(name):
        suite = [row if old['test'] == row['test'] else old for old in suite]
assert len(suite) == 21 and all(r['passed'] for r in suite)
before = read('enemy-review-fifth-before.json')
synergy_before = read('enemy-review-fifth-synergy-before.json')
review = read('enemy-review-latest.json')
oracle = read('enemy-review-oracle.json')
action = read('enemy-action-results.json')
regression = read('enemy-regression-latest.json')
integration = read('integration.json')
ui = read('ui-results.json')
audit = read('source-audit.json')
assert not review['failures'] and not regression['failures']
assert action['failures'] == 0 and action['matched'] == action['continuous_matched'] == 1221
assert integration['failures'] == ui['failures'] == ui['overflow'] == audit['failures'] == 0
assert len(before['failures']) == 94 and len(synergy_before['failures']) == 1
fifth = oracle['fifth']
assert sum(map(len, fifth.values())) == 120
assert {k: len(v) for k, v in fifth.items()} == {k: len(v) for k, v in review['evidence']['fifth'].items()}
protected = read('fifth-protected-before.json')
changed = [name for name, sha in protected.items()
           if not (ROOT / name).is_file() or hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != sha]
assert not changed, changed
guard = {'files_checked': len(protected), 'changed_files': changed,
         'docs_files': sum(n.startswith(('docs/', 'docs\\')) for n in protected)}
write('fifth-protected-after.json', guard)
write('suite-fifth-final.json', suite)
write('enemy-review-fifth-final.json', review)
normal = []
for group, rows in before['evidence']['fifth'].items():
    for old, new in zip(rows, review['evidence']['fifth'][group]):
        assert old['input'] == new['input']
        if not new['input'].get('fixed', True) and old != new:
            normal.append({'group': group, 'before': old, 'after': new})
assert len(normal) == 44
unchanged = [r for r in review['evidence']['fourth']['strikes'] if not r['input']['fixed']]
assert len(unchanged) == 28 and all(r['actual_loss'] == r['input']['loss'] for r in unchanged)
write('fifth-normal-changes.json', normal)
counts = dict(collections.Counter(r['group'] for r in normal))
rows = '\n'.join(f"| `{r['test']}` | 통과 | 0 |" for r in suite)
section = f'''<!-- R21_FIFTH_START -->
## 5차 — 남은 원본 전투 차이 6건 수정

2026-11-02. **6건 수정, 미완료 0건.** 원본 Lua 하네스 대조 행과 Godot 검사를 먼저 추가해 구현 수정 전 **{before['checks']}항목 / 실패 {len(before['failures'])}**를 확인했다. 실패 분포는 회복 56, 사망·출처 제거 8, 구원 순서 4, 성벽 반올림 6, 사제 8, DOT 시작 순서 12다. 사망 시 시너지 갱신을 보강하면서 아델린 피해 감소 버프의 하프엘프 지속시간도 **495항목 중 1건 실패**로 재현한 뒤 수정했다. 최종 **{review['checks']}항목 / 실패 0**, 필수 **21종 / 실패 0**이다. 아래 1~4차 절은 각 차수 당시 기록이며, 4차의 여섯 범위 밖 항목은 이 절의 결과로 대체한다.

| 항목 | 원본 대조와 수정 결과 | 원본 근거 |
|---|---|---|
| 1. `pa_echo` | 고정·일반 피해 모두 구원·사망·damaged 뒤에 공통 회복 경로를 실행한다. 인간 3명, 받는 회복량, 정수 반올림·상한과 사망 대상을 처리한다. `heal`·넘친 회복 보호막은 스킬 문맥에서만 적용한다. 반향 착용자·피해자의 `heal`을 임의로 시전자 보너스로 쓰지 않는다. 반향 64행, raw/skill 회복 8행, 구원·소렐·죽은 착용자 순서 8행 일치. | `30-engine.lua:582–589`, `34-traits.lua:334–336`, `81-gear.lua:753–774,838–874` |
| 2. `ally_down` / `drop_src` | 정본 Lua 45파일을 검색했다. 직접 등록된 훅은 `34-traits.lua`의 시너지 갱신·직업 DOT 한도 축소이며, `32-personal-b.lua`에는 별도의 damaged 정리 래퍼가 있다. 사망 즉시 살아 있는 인원 기준 시너지를 반영하고, 모르가스 3→2에서 가장 오래된 직업 DOT만 6→5개로 줄인다. 도발·충전·대신 맞기·보호막을 정리하고 전 유닛의 해당 시전자 출처 효과를 제거한다. 할드리크·아델린 실제 시전과 아델린 재생 제거, 다른 시전자 효과 보존, 저장 후 동일 동작도 검사했다. 하프엘프 2→1의 지속시간도 원본과 일치한다. | `30-engine.lua:389–418`, `34-traits.lua:197–208,373,443–457`, `32-personal-b.lua:579–606` |
| 3. 구원 순서 | 개인 save → 마지막 성벽 → 첫 생존 사제 순서. 마르셀린+성벽의 첫 치명타는 HP 251·보호막 150·성벽 미사용, 두 번째는 성벽으로 HP 200이다. 고정·일반 두 경로 일치. | `30-engine.lua:355–383,1146–1160` |
| 4. 성벽 반올림 | `max(1,floor(mhp*비율+.5))`. 최대 HP 1·3·7·1,003의 8행 일치. 최대 HP 1,003에서는 200→201, 최대 HP 1에서는 0→1이다. | `81-gear.lua:650–656` |
| 5. 사제 자기 구원 | lethal HP 0을 쓰기 전의 생존 목록을 유지해 피해자인 사제도 save 후보에 포함한다. 혼자 남은 사제와 여러 사제의 슬롯 우선순위도 처리한다. 최대 HP 1,003의 자기 구원 HP는 502이며, 뒤 슬롯 기적 장비가 첫 사제를 덮어쓰지 않는다. 8행 일치. | `30-engine.lua:363–383` |
| 6. DOT 사망 뒤 회복 | 도발 감소 → 기본·장비 MP 회복과 유효한 도발 회복 → DOT 수명 감소·합산 피격 순서. 사망하면 같은 시작 틱을 즉시 끝내 regen·우르다·토베·에르데네 회복으로 되살리지 않는다. 에르데네 만료 정산은 살아 있는 자신의 turn_end에서 실행한다. 12행의 HP·MP·보호막·다른 아군 HP·막은 피해·DOT 수명 일치. | `30-engine.lua:248–260,1070–1087`, `31-foes.lua:145–159`, `81-gear.lua:715–728`, `32-personal-a.lua:134–159` |

### 수치와 일반 공격 값 변화

| 항목 | 결과 |
|---|---:|
| 새 원본 Lua 대조 행 | 120/120 일치 |
| 최종 재현·저장·훅·RNG 검사 | {review['checks']}항목 / 실패 0 |
| 기존 원본 DOT / 회피 표본 | 7/7 / 120/120 일치 |
| 기존 take·psguard 일반 공격 대조 | 28/28 일치 / 값 변화 0 |
| 새 일반 공격 비교 중 변화 | 44행 / 모두 원본과 일치 |
| 기존 적 행동 검사 | {action['checks']:,}항목 / 실패 0 |
| 적 / 개별 행동 / 연속 행동 | 100종 / 1,221/1,221 / 1,221/1,221 |
| 침묵 / 장비 표본 | 200 / 120 / 불일치 0 |
| 기존 적 회귀 검사 | {regression['checks']}항목 / 실패 0 |
| 던전 통합 | {integration['checks']:,}항목 / 실패 0 |
| 1~420층 강제 종결 | 승리 {integration['outcomes']['victory']} / 패배 {integration['outcomes']['defeat']} |
| 1~60층 자연 전투 표본 | 승리 {integration['outcomes']['natural_victory']} / 패배 {integration['outcomes']['natural_defeat']} |
| UI 이름표 | {ui['nameplates']:,}개 / 넘침 {ui['overflow']} |
| 보호 파일 / `docs/` 파일 | {guard['files_checked']} / {guard['docs_files']}개 / 변경 0 |
| 원본 그림 / 정본 원본 변경 | 96/96 보존 / 변경 0 |
| 필수 검사 / 스크립트·엔진 오류 | 21종 통과 / 0 |

일반 공격 변화 행은 반향 32, 사망 상태 정리 3, 구원 순서 1, 성벽 3, 사제 4, 직업 DOT 축소 1이다(`fifth-normal-changes.json`, 분포 `{counts}`). 이 중 HP·보호막 변화는 40행이며 나머지 4행은 사망 후 상태·중첩 값이다. 예를 들어 HP 500·보호막 21·raw 40·인간 3명·healrecv 25%의 반향은 **491→495**, HP 50·보호막 21·raw 100의 구원 없는 반향은 **10→0**이다. 마르셀린+성벽 첫 구원은 **HP 200·보호막 0 → HP 251·보호막 150**, 사제 자기 구원은 **0→502**다. 기존 비치명 take·psguard 28행은 그대로 원본과 일치한다. 변화 행의 기대값은 Lua 실행값이며, 기존 1,221행 오라클과 공통 검사의 기대값은 바꾸지 않았다.

### 저장 호환·검증 경계

저장 schema 3을 유지한다. 효과에 선택적인 `source`와 직업 DOT의 `stacks` 메타데이터를 추가했다. JSON 왕복 후 시전자 사망·DOT 한도 축소가 같으며, 잘못된 출처·음수·문자열·과다 중첩·합계 불일치는 거부한다. 이 필드가 없는 기존 저장도 읽고 합산 DOT 값을 보존한다. 과거 저장은 DOT별 생성 순서와 일부 버프의 시전자 정보를 기록하지 않았으므로 그 정보를 복원했다고 주장하지 않는다. 기존 합산 DOT는 새 중첩을 더할 때 하나의 보존된 합산 항목으로 이어받고, 새 적용부터 개별 양과 출처를 기록한다. 사용자 저장 파일을 지우거나 덮지 않았다.

이 결과는 이번 여섯 경로와 명시한 fixture의 동등성이다. 전체 CTB·라운드 경계·아군 전체 공격식·모든 개인/종족/장비 훅·난수열을 원본 엔진으로 교체한 것은 아니다. 기존 아군 DOT의 모든 개별 수명·특수 DOT와 기존 시작 틱에 배치된 생존자 재생/라운드 훅 전체까지 원본과 같다고 주장하지 않는다. 전투 전체 승률 동등성도 검증하지 않았다. 새 적 그림과 성적 콘텐츠 이관은 하지 않았다(`79-sex.lua`는 기존 목록만 유지).

### 실행·시각 확인·변경 파일

```powershell
node tools/oracle_enemy_review_r21.mjs
python tools/verify_data_r21.py
python tools/verify_data_r21.py enemy_review_r21_test enemy_regression_r21_test enemy_action_r21_test
python tools/verify_data_r21.py import data_r21_test dungeon_r21_test ui_data_r21_test
python tools/audit_data_r21.py
python tools/report_enemy_fifth_r21.py
```

원본 하네스의 wasmoon으로 정본 10파일을 다시 적재하고 원본 `B.strike/B.heal/B.begin_turn/B.edot_tick/B.fire/B.PRUN`을 실행했다. 새 Lua 파일은 입력과 관측만 정의한다. 전체 훅 검색 근거는 `fifth-hook-inventory.json`, 수정 전 근거는 `enemy-review-fifth-before.json`, 추가 실패는 `enemy-review-fifth-synergy-before.json`, 최종 결과는 `enemy-review-fifth-final.json`이다. 첫 21종 전체 실행은 모두 통과했고, 마지막 보강 후 영향받는 검사를 재실행했다. 최종 표는 각 최신 실행을 합친 `suite-fifth-final.json`이다. 반복되는 OS 인증서 저장소 메시지는 기존 환경 진단으로 분리했다.

직접 연 이미지: `verification/data-r21/battle-360-7.png`, `verification/ui-r20/all-states-360.png`. 7칸 적 이름표·HP, 아군 카드와 전투 명령·기술/보급품/기록 시트를 확인했다. 모든 결과 이미지를 각각 연 것은 아니다. UI 배치·컷인·잉크·이펙트 파일은 수정하지 않았다.

구현: `project/game/battle_v3.gd`, `project/game/dungeon_enemy_r21.gd`. 검사: `project/tests/enemy_review_r21_test.gd`(fixture 이름 변경 시 선택·예고 ID도 일관되게 갱신). 도구: `tools/oracle_enemy_review_r21.mjs`, 새 `tools/oracle_enemy_review_fifth_r21.lua`, 새 `tools/report_enemy_fifth_r21.py`. 보고·근거: `DATA-R21.md`, `verification/data-r21/**`와 공통 검사가 재생성한 verification·라이선스 산출물.

Web export·버전 갱신은 실행하지 않았다. `docs/`·정본 봇·다른 worktree에는 쓰지 않았다. 최초 규칙 읽기와 함께 조회한 `git status --short`는 소유권 오류로 실패했다. 그 이후 git 명령이나 git 설정 변경은 하지 않았다.

| 최종 검사 | 결과 | 실패 |
|---|---|---:|
{rows}

<!-- R21_FIFTH_END -->
'''
report = ROOT / 'DATA-R21.md'
text = report.read_text(encoding='utf-8')
start, end = '<!-- R21_FIFTH_START -->', '<!-- R21_FIFTH_END -->'
if start in text:
    a = text.index(start); z = text.index(end, a) + len(end)
    text = text[:a] + section.rstrip() + text[z:]
else:
    title, rest = text.split('\n', 1)
    text = title + '\n\n' + section + rest
report.write_text(text, encoding='utf-8')
print(json.dumps({'report': str(report), 'fixed': 6, 'checks': review['checks'], 'failures': 0,
                  'required_suites': len(suite), 'new_oracle_rows': 120, 'oracle_matched': action['matched'],
                  'normal_changed': len(normal), 'protected_files': len(protected)}, ensure_ascii=False))
