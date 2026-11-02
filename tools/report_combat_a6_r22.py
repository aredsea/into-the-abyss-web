"""Assemble A6 evidence without altering source data, assets, or repository state."""
from pathlib import Path
import hashlib,json,collections
R=Path(__file__).resolve().parents[1]; O=R/'verification/data-r21'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
write=lambda p,v:p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
suite={r['test']:r for r in read(O/'suite-all.json')}
for name in ['suite-combat_p2_r22_test.json','suite-combat_a6_r22_test-combat_p2_r22_test-combat_p2_r22_trace.json','suite-import.json']:
 if not (O/name).exists(): continue
 for row in read(O/name):
  if row.get('finished_at',0)>=suite.get(row['test'],{}).get('finished_at',0): suite[row['test']]=row
write(O/'suite-a6-final.json',list(suite.values()))
before={k.replace('\\','/'):v for k,v in read(O/'a6-before-hashes.json').items()}; allowed={'project/game/battle_v3.gd','project/game/dungeon_enemy_r21.gd','project/tests/enemy_review_r21_test.gd','tools/verify_data_r21.py'}
changed=[n for n,h in before.items() if not (R/n).is_file() or hashlib.sha256((R/n).read_bytes()).hexdigest()!=h]
protected=[n for n in before if n not in allowed and not n.startswith(('tools/oracle_combat_a6','tools/prepare_combat_a6','project/tests/combat_a6'))]
protection={'protected_files':len(protected),'protected_changes':[n for n in changed if n in protected],'docs_files':sum(n.startswith('docs/') for n in before),'docs_changes':[n for n in changed if n.startswith('docs/')],'modified_existing':changed}
write(O/'a6-protected-after.json',protection)
mixed=read(O/'a6-mixed-audit.json'); gaps=[]; counts=collections.Counter()
for row in mixed['reports']:
 first=row['first_difference']
 if not first: continue
 if row['party'][0]=='hildegard': category='P3: Bargut personal power / use conditions and resulting input divergence'
 elif first['input'].get('id') in ['shield','pshield']: category='P3: class party shield scale (base stat vs 2 * base stat)'
 elif 'sh' in first['fields']: category='P3: class party shield scale (base stat vs 2 * base stat)'
 elif first['input'].get('id')=='item:hp_s': category='P3: Marceline cover applied to each all-target hit'
 else: category='P3: Naran personal abyss weakness multiplier / later cast state'
 counts[category]+=1
 gaps.append({'party':row['party'],'foe':row['foe'],'seed_number':row['bn'],'category':category,'first_difference':first})
write(O/'a6-parity-gaps.json',{'diagnostic_only':True,'battles':mixed['battles'],'equal_battles':mixed['equal_battles'],'different_battles':len(gaps),'categories':dict(counts),'notes':['Classification identifies first observed divergences, not all downstream causes.','Equipment generation and all-equipment combinations belong to P4 and are not exercised by the equal-initial-stat battle fixture.','Both policies exclude invalid ally/self targets; skill availability is evaluated by each actual engine.'],'gaps':gaps})
oracle=read(O/'a6-oracle.json'); latest=read(O/'a6-latest.json'); audit=read(O/'source-audit.json'); basic=read(O/'p2-full-battles.json')
summary={'checks':latest['checks'],'failures':len(latest['failures']),'required_suites':len(suite),'suite_failures':sum(not r['passed'] for r in suite.values()),'oracle_rows':sum(len(v) for k,v in oracle.items() if k!='files'),'oracle_groups':{k:len(v) for k,v in oracle.items() if k!='files'},'basic_battles':basic['battles'],'basic_actions':basic['compared_actions'],'basic_differences':basic['different_actions'],'mixed_battles':mixed['battles'],'mixed_source_actions':mixed['source_actions'],'mixed_actual_actions':mixed['actual_actions'],'mixed_equal_battles':mixed['equal_battles'],'mixed_gaps':len(gaps),'mixed_categories':dict(counts),'original_assets':audit['original_assets'],'source_audit_failures':audit['failures'],**protection}
write(O/'a6-summary.json',summary)
start='<!-- R22_A6_START -->'; end='<!-- R22_A6_END -->'; report=R/'DATA-R21.md'; old=report.read_text(encoding='utf-8')
if start in old: old=old[:old.index(start)]+old[old.index(end)+len(end):]
table='\n'.join('| `'+name+'` | '+('통과' if row['passed'] else '실패')+' | '+str(len(row['engine_errors'])+(row['exit_code']!=0))+' |' for name,row in suite.items())
section=f'''{start}
## A6 — 검수 6건 종결 · P2 훅/사건 계약 확장 · 혼합 전투 차이 목록

2026-11-02. **1부 6건 종결(현재 P2에서 기해소 1건, 나머지 5건 수정). 새 검사 {latest['checks']}항목 / 실패 {len(latest['failures'])}. 공통·기존·신규 {len(suite)}종 / 실패 {summary['suite_failures']}**. P3/P4 전체 전투 구현 완료를 뜻하지 않는다. 아래 P2·5차 절은 이전 차수 기록이며 이번 절의 변경 사항이 우선한다.

### 1부 — 원본 Lua와 실제 경로 재현

| 지적 | 재현 및 결과 | 근거 |
|---|---|---|
| P1-1 DOT 사망자 MP | 현재 P2의 실제 `_finish_turn` → DOT 사망 → 다음 생존자 선택에서 원본과 같은 MP **5**. 이 경로는 이미 해소되어 있었다. 별도 회귀 시험으로 닫았고 불필요한 예전 MP 원복 장치도 제거했다. | `30-engine.lua:248–260,1053–1087`; `a6-oracle.json:mp` |
| P1-2 옛 전투 피격 | r21 피격 경로와 옛 전투를 분리했다. **72bf1b2의 실제 blob**에서 읽은 피격 함수를 보존하고 반향·구원·사제·상처·소렐·반올림 6조건을 비교한다. | `a6-legacy-source.json`, `combat_a6_legacy_fixture.gd` |
| P1-3 ruin 중복 DOT·연쇄 폭발 | 직업 DOT 패시브는 살아 있는 적에게 일반 공격을 했을 때만 적용한다. ruin은 대상별 한 줄, 원본의 `floor(cs*2*.5)`를 쓴다. 매 push에서 연쇄 폭발을 판정하며 각 줄의 잔여 수명을 합산한다. 연쇄 폭발 없는/있는 ruin 3회씩 일치. | `34-traits.lua:407–410`, `30-engine.lua:652–676`, `81-gear.lua:689–712` |
| P2-4 쓰러진 피격자 상처 | 사망 여부와 무관하게 damaged의 상처 누적. 일반·고정 피해 모두 원본 50과 일치. | `81-gear.lua:919–931` |
| P2-5 옛 합산 DOT 중첩 | 저장된 `dot_stacks` 개수를 유지하며 새 줄을 더한다. 옛 4줄 총합 100 → 새 줄 20은 **5줄·120**. 저장에 없던 개별 금액·순서는 복구할 수 없으므로 동등 분배로 이관한다. 총합·개수는 유지하되 이후 오래된 줄 제거의 정확한 과거 금액 복원은 보장하지 않는다. | 원본 `B.dot_push`; `a6-oracle.json:migration` |
| P2-6 소렐/최후의 저항 순서 | 개인 damaged를 먼저, 장비 damaged를 나중에 적용한다. HP 250에서 raw 100 → 소렐 회복 후 **HP 350, 저항 미발동**, 일반·고정 모두 일치. | `30-engine.lua:77–85`, `81-gear.lua:919–931` |

수정 전 유효한 1부 회귀는 **20항목 중 15실패**, 수정 후 20항목 실패 0이다(`a6-part1-before.json`, `a6-part1-after.json`). 최초 임시 fixture의 행동자 기대와 JSON 배열 int/float 비교 문제는 원본 값 변경 없이 바로잡았다. 이후 실패 재현은 `a6-hooks-before.json`, `a6-render-dot-before.json`, `a6-regen-supply-before.json`, `a6-clock-wall-before.json`, `a6-batch-before.json`에 보존했다. 각 산출물은 그 단계의 범위이며 합산 실패 수로 쓰지 않는다.

### 2부 — 남은 P2 범위

1. **라운드·대기·효과 수명**: 유디트의 원래 속도/만료 라운드와 재적용, 페르소나의 `set_persona_regen` 경계 함수(살아 있는 페르소나 round 훅만 실행), 펠리체의 `death_tick + ceil(max(remaining,0)/base_speed)` 대기/슬롯 우선 소생, 죽은 성벽 착용자 수명, 새 성벽의 이전 파티 성벽 교체를 연결했다. 일반 버프는 보유자 차례 끝에 감소하고 자기 시전 버프는 첫 감소를 건너뛴다. 보호막은 자기 차례 끝도 센다. DOT 각 줄의 소유자·수명·만료 폭발, 아델린 중복 재생의 적용 행동 번호와 각 줄 수명도 분리했다. 모르가스 DOT 배수는 문구의 옛 숫자 대신 실행 코드의 **+10%**를 쓴다. 구역 보스의 충전 지연 절반도 고쳤다.
2. **사건·표시 계약**: `combat_events_r22.gd`가 종류·행동자·대상 슬롯·발생 순서·시작/명중 시각을 내보낸다. 개인 30명, 직업/공통 17행동, 아이템 5종, 적 지원/공격 12조건, 고갈/회복/취소/DOT/종료/단계 및 연속 자동 행동을 포함한 **{len(oracle['events'])}개 실제 실행 표본**을 Lua와 비교했다. 원본 한 입력의 자동 행동들은 같은 사건 시계를 이어 간다. `combat_display_r22.gd`는 40-fx의 **28종**에 대해 명중·숫자·이름표·컷인 callback 시각을 대조하고 50-render 상태칩 **27표본**을 비교한다. r21 `effects_text`도 같은 칩 계약을 사용한다. r17~r20의 아트·잉크·컷인·배치 파일은 수정하지 않았다.
3. **능동 기술·보급품 포함 정책**: 기본 공격 외에 사용할 수 있는 개인/직업 기술과 소형 HP/MP 물약을 선택한다. 원본의 대상·자기 지정 제한을 지키며 두 엔진이 각자 실제 사용 가능 여부를 판단한다. 파티 3조합 × 적 4편성 × 씨앗 4개의 **48전투**를 양쪽 모두 종결했다. 원본 **{mixed['source_actions']:,}행동**, Godot **{mixed['actual_actions']:,}행동**. 전투 전체 일치는 **{mixed['equal_battles']}/48**, 차이 **{len(gaps)}건**이다. 이는 실패 0으로 포장하지 않은 진단 결과다. 최초 차이별 P3 원인 목록은 `a6-parity-gaps.json`이며, 뒷부분의 연쇄 차이를 별개 원인이라고 세지 않는다.

| 혼합 전투 최초 차이 분류 | 전투 수 |
|---|---:|
| 바르굿 개인 기술 계수/사용 조건과 입력 분기(P3) | {counts.get('P3: Bargut personal power / use conditions and resulting input divergence',0)} |
| 나란 개인 기술의 약점 심연 배수/이후 시전 상태(P3) | {counts.get('P3: Naran personal abyss weakness multiplier / later cast state',0)} |
| 직업 파티 보호막 계수: stat 대신 2×stat 기반(P3) | {counts.get('P3: class party shield scale (base stat vs 2 * base stat)',0)} |
| 마르셀린 대신 맞기의 전체 공격 적용(P3) | {counts.get('P3: Marceline cover applied to each all-target hit',0)} |

혼합 정책의 불일치가 전체 아군 기술·특성·장비 조합을 검증했다는 뜻은 아니다. 원본과 같은 초기 능력치를 고정해 P1/P4의 생성·장비 초기화는 분리했다. P4 전 장비 조합은 미실행이다. 사건 검증은 위 실제 표본의 종류/대상/시계와 원본 callback 관측 계약이며, 원본 HTML/CSS의 픽셀 동일성 또는 아직 P3/P4가 옮기지 않은 모든 proc 경로의 사건 전수 동등성을 주장하지 않는다.

### 저장·보호·검사

schema 3을 유지하고 선택적인 DOT `lifetimes/owners/bursts/initial_turns`, 재생 `heals` 및 유디트/펠리체 숫자 메타데이터를 읽고 쓴다. 옛 메타데이터 없는 효과도 읽는다. 새 배열 길이·소유자·양수 수명·재생 구조를 검증하며, 잘못된 저장은 적용하지 않는다. 유디트 속도는 roster 재구성 뒤 저장된 원래 속도에서 복구한다. 실제 JSON 왕복·잘못된 메타데이터 거부·진행 중 소생 대기는 시험했다. 사용자 저장 파일에는 쓰지 않았다.

- 새 검사: **{latest['checks']} / 실패 {len(latest['failures'])}**. Lua 관측 행 **{summary['oracle_rows']}**, 분포 `a6-summary.json`.
- 기본 공격 전체 trace: **{basic['battles']}전투·{basic['compared_actions']:,}행동 / 불일치 {basic['different_actions']}**.
- 적 행동·리뷰·던전 및 공통/화면/motion 검사: 아래 최신 결과 **{len(suite)}종 / 실패 {summary['suite_failures']}**.
- 원본 그림 **96/96**, 데이터/정본 감사 실패 **{audit['failures']}**. 보호 파일 **{len(protected)}개 / 변경 {len(protection['protected_changes'])}**, `docs/` **{protection['docs_files']}개 / 변경 {len(protection['docs_changes'])}**.
- 직접 연 이미지: `verification/data-r21/battle-360-7.png`, `verification/ui-r20/all-states-360.png`. 적 이름표/HP, 아군 카드, 명령/기술/보급품/기록 시트 배치를 확인했다. 모든 결과 이미지를 각각 연 것은 아니다.

첫 전체 실행의 r18 종료 리소스 잔류 1건과 추가 실행의 직접 소환 fixture에서 빠진 `kind` 접근 1건은 수정/재검사했다. 진단 요약은 `a6-intermediate-failures.json`이며, 개별 로그는 최신 실행으로 갱신됐다. r18의 간헐적 종료 경고 원인은 특정하지 못했지만 다음 전체 실행은 오류 0이었다. 최신 결과는 `suite-a6-final.json`이다. OS 인증서 저장소 진단만 기존 환경 메시지로 분리했다.

| 최종 검사 | 결과 | 실패/엔진 오류 |
|---|---|---:|
{table}

### 파일과 재실행

구현: `project/game/battle_v3.gd`, `dungeon_enemy_r21.gd`, 새 `combat_events_r22.gd`, `combat_display_r22.gd`. 검사: 새 `combat_a6_r22_test.gd`, `combat_a6_r22_fixture.gd`, `combat_a6_legacy_fixture.gd`, `combat_a6_mixed_audit.gd`; 기존 `enemy_review_r21_test.gd`. 기존 시험은 일반 공격의 `action_id`를 명시하고, 시작 틱 대신 원본 종료 틱에서 성벽을 확인하며, 소생 훅 격리 fixture의 사망 게이지를 원본과 같은 0으로 두었다. Lua 기대 숫자는 구현에 맞춰 바꾸지 않았다.

도구: `oracle_combat_a6_r22.mjs/.lua`, `oracle_combat_a6_mixed.mjs`, `prepare_combat_a6_r22.py`, `report_combat_a6_r22.py`, `verify_data_r21.py`. 증거: `verification/data-r21/a6-*`, `suite-a6-final.json`. 기존 검사 산출물도 재생성됐다.

```powershell
node tools/oracle_combat_a6_r22.mjs
node tools/oracle_combat_a6_mixed.mjs
python tools/verify_data_r21.py
python tools/godot_r17.py --headless --script res://tests/combat_a6_mixed_audit.gd
python tools/audit_data_r21.py
python tools/report_combat_a6_r22.py
```

Web export·버전 갱신은 실행하지 않았다. 원본 봇·다른 worktree·`docs/`에는 쓰지 않았다. 첫 규칙 읽기와 묶여 있던 `git status --short`는 소유권 오류로 실패했다. 이후 git 명령/설정 변경은 하지 않았으며 72bf1b2는 읽기 전용 객체 파일을 직접 읽었다. 성적 콘텐츠는 옮기지 않았다(`79-sex.lua`는 기존 참조 목록 유지).
{end}
'''
title='# DATA-R21 — A 갈래 던전·적 데이터 이관'
assert old.startswith(title)
report.write_text(title+'\n\n'+section+old[len(title):].lstrip('\r\n'),encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['modified_existing','oracle_groups','mixed_categories']},ensure_ascii=False))
assert not latest['failures'] and not summary['suite_failures'] and not protection['protected_changes'] and not audit['failures']
