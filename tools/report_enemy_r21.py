"""Prepend the second-pass report without overwriting historical first-pass evidence."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'verification/data-r21'
read=lambda n:json.loads((OUT/n).read_text(encoding='utf-8-sig'))
action=read('enemy-action-results.json')
regression=read('enemy-regression-latest.json')
suite=read('suite-all.json')
# Keep the complete run and any failed attempt intact; aggregate the latest
# direct run of each required check, including narrow reruns after final fixes.
latest={r['test']:r for r in suite}
for evidence in sorted(OUT.glob('suite-*.json'),key=lambda p:p.stat().st_mtime):
    if 'retry-needed' in evidence.name or evidence.name=='suite-final.json': continue
    for row in json.loads(evidence.read_text(encoding='utf-8-sig')):
        if row['test'] in latest: latest[row['test']]=row
suite=[latest[r['test']] for r in suite]
integration=read('integration.json')
ui=read('ui-results.json')
audit=read('source-audit.json')
assert action['failures']==0 and not regression['failures'] and audit['failures']==0
assert len(suite)==20 and all(r['passed'] for r in suite)
(OUT/'suite-final.json').write_text(json.dumps(suite,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
start='<!-- R21_SECOND_START -->'
end='<!-- R21_SECOND_END -->'
path=ROOT/'DATA-R21.md'
old=path.read_text(encoding='utf-8-sig')
if start in old:
    old=old[:old.index(start)]+old[old.index(end)+len(end):]
title,body=old.split('\n',1)
body=body.lstrip()
historic='## 1차 기록 (이하 수치는 1차 완료 당시의 기록)\n\n'
if body.startswith(historic): body=body[len(historic):]
rows='\n'.join(f"| `{r['test']}` | 통과 | 0 |" for r in suite)
section=f'''{start}
## 2차 — 검수 8건 수정 및 적 행동 원본 실행 대조

2026-10-31. 지시서의 8건을 모두 수정했다. 기각은 없다. 수정 전에 재현 검사를 실행하여 **12항목 중 10항목 실패**를 확인했다(`enemy-regression-before.json`). 이후 대상·수명·저장·해제·중복 정산 검사를 보강한 최종 재현 검사는 **{regression['checks']}항목, 실패 0**이다. 기존 공통 검사의 기대값은 바꾸지 않았다.

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
| 원본 적 / 적마다 이어진 차례 | {action['enemies']}종 / 12~15차례 |
| 원본 Lua 행동 표본 | {action['samples']:,} |
| 같은 입력 상태에서 개별 차례 재생 | {action['matched']:,}/{action['samples']:,}, 100% |
| GDScript 상태를 계속 이어간 연속 차례 대조 | {action['continuous_matched']:,}/{action['samples']:,}, 100% |
| 10직업 침묵 선택 추가 표본 | {action['silence_samples']}, 전부 일치 |
| 엘리트 의뢰 장비 코드 추가 표본 | {action['gear_samples']}, 전부 일치 |
| 새 행동 대조 검사 | {action['checks']:,}항목, 실패 0 |
| 재현·수명·저장·해제 검사 | {regression['checks']}항목, 실패 0 |
| 편성·능력치·탐색 기존 Lua 대조 | 7,493항목, 실패 0 |
| 던전 통합 | {integration['checks']:,}항목, 실패 0 |
| 1~420층 종결 | 승리 420 / 패배 420 |
| 1~60층 자연 전투 표본 | 승리 {integration['outcomes']['natural_victory']} / 패배 {integration['outcomes']['natural_defeat']} |
| UI 이름표 | {ui['nameplates']:,}개, 넘침 {ui['overflow']} |
| 원본 자산 / 데이터·원본 변경 | 96/96 보존 / 불일치 0·원본 변경 0 |
| import + 공통·기존·신규 검사 | 20종 통과, 실패 0 |

`tools/oracle_enemy_r21.mjs`가 원본 하네스의 wasmoon으로 **실제 `20-state.lua`, `30-engine.lua`, `31-foes.lua`를 다시 적재해 직접 실행**한다. GDScript를 번역해 만든 가짜 oracle은 없다. 파일 목록과 입력·출력은 `enemy-action-oracle.json`, 개별 적의 표본 수와 불일치 목록은 `enemy-action-results.json`에 남겼다. 새로 조사한 `30-engine.lua`·`70-town.lua`의 해시도 `source-inventory.json`에 추가했다.

아군은 양쪽 모두 같은 HP·방어·생존 상태인 중립 fixture다. 캐릭터·종족·장비의 개별 훅을 끄고 적 행동을 분리했다. 정해진 차례에 도발, 아군 이탈, 2단계 진입, 충전 고갈을 양쪽에 똑같이 넣는다. 첫 대조는 각 원본 입력에서 한 차례씩 재생한다. 두 번째 대조는 각 적의 첫 상태만 넣은 뒤 **게임 상태를 덮어쓰지 않고** 12~15차례를 이어가며, 아군·다른 적 보유자의 실제 틱도 실행한다. 대상 예고와 효과의 실제 대상, HP·피해·회복·보호막·지연, 행동 순번·충전·고갈·단계·약점, 오라 시전자와 버프·DOT 수명, 보호·은신, 원본 행동 RNG를 비교한다. 정수·식별자는 정확 비교, 실수 산술은 절대 오차 `1e-8` 이내다. empty Lua table의 JSON `[]`와 GDScript `{{}}`만 같은 빈 값으로 정규화한다.

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
{rows}

{end}
'''
path.write_text(title+'\n\n'+section+'\n'+historic+body,encoding='utf-8')
summary={k:v for k,v in action.items() if k not in ['mismatches','continuous_mismatches','coverage']}
summary.update(regression_checks=regression['checks'],suite_count=len(suite),suite_failures=sum(not r['passed'] for r in suite),report=str(path))
(OUT/'second-pass-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False))
