from pathlib import Path
from collections import Counter
import hashlib,json,re
R=Path(__file__).resolve().parents[1];OUT=R/'verification/data-r21'
read=lambda p:json.loads((OUT/p).read_text(encoding='utf-8'))
suite=read('a9-suite/results.json')
target=read('a9-part1-latest.json');before=read('a9-part1-before.json')
native=[read(f'a9-native-{lv}-audit.json') for lv in [10,40]]
oracles=[read(f'a9-native-{lv}-oracle.json') for lv in [10,40]]
rows=[r for o in oracles for r in o['battles']+o['raid_battles']]
coverage=dict(sum((Counter(r['coverage']) for r in rows),Counter()))
rarity=dict(sum((Counter(r['rarity']) for r in rows),Counter()))
start=read('a9-start-manifest.json')
changed=[n for n,h in start.items() if not (R/n).exists() or hashlib.sha256((R/n).read_bytes()).hexdigest()!=h]
protected={folder:{'files':sum(n.startswith(folder+'/') for n in start),'current_files':sum(p.is_file() for p in (R/folder).rglob('*')),'changed':[n for n in changed if n.startswith(folder+'/')]} for folder in ['docs','project/assets']}
parity=[]
for label,file in [('A7','a7-gear-audit.json'),('A7 balanced','a7-gear-balanced-audit.json'),('A9 native10','a9-native-10-audit.json'),('A9 native40','a9-native-40-audit.json')]:
 o=read(file);parity.append({'name':label,**{k:o[k] for k in ['battles','equal_battles','source_actions','actual_actions','matched_actions']}})
gaps=[{'level':lv,'party':r['party'],'foe':r['foe'],'bn':r['bn'],'difference':r['first_difference']} for lv,o in zip([10,40],native) for r in o['reports'] if r['first_difference']]
summary={'suite_groups':len(suite),'suite_failures':sum(not r['passed'] for r in suite),'before_checks':before['checks'],'before_failures':len(before['failures']),'target_checks':target['checks'],'target_failures':len(target['failures']),'parity':parity,'gear_battles':sum(r['battles'] for r in parity),'gear_records':sum(r['source_actions'] for r in parity),'native_coverage':coverage,'native_rarity_equipped':rarity,'native_equipped_slots':sum(rarity.values()),'native_initialization_units':len(rows)*4,'native_gaps':len(gaps),'changed_manifest_files':changed,'protected':protected,'source_audit':read('source-audit.json')}
legacy=[]
for name,file in [('A6','a6-mixed-audit.json'),('P3','p3-mixed-audit.json'),('A8','a8-audit.json')]:
 o=read(file);legacy.append({'name':name,**{k:o[k] for k in ['battles','equal_battles','source_actions','actual_actions','matched_actions']}})
p2=read('p2-full-battles.json')
summary['retained_parity']=legacy
summary['all_battles']=summary['gear_battles']+sum(r['battles'] for r in legacy)+p2['battles']
summary['all_records']=summary['gear_records']+sum(r['source_actions'] for r in legacy)+p2['compared_actions']
ui=re.search(r'COMBAT A8 UI CHECKS (\d+) FAILURES (\d+) OVERFLOW (\d+) CAPTURES (\d+)',(OUT/'a9-suite/ui_combat_a8_test.log').read_text(encoding='utf-8'))
assert ui
summary['ui_a8']=dict(zip(['checks','failures','overflow','captures'],map(int,ui.groups())))
visual=read('a9-visual-review.json')
assert all(r['viewed'] and hashlib.sha256((R/r['path']).read_bytes()).hexdigest()==r['sha256'] for r in visual['images'])
summary['directly_viewed_images']=len(visual['images'])
(OUT/'a9-parity-gaps.json').write_text(json.dumps(gaps,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'a9-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
assert len(suite)==58 and all(r['passed'] for r in suite)
assert not target['failures'] and not gaps
assert all(r['battles']==r['equal_battles'] and r['source_actions']==r['actual_actions']==r['matched_actions'] for r in parity)
assert all(coverage[k]>0 for k in ['drain_reflect_hits','counters','skill_kill_heal_gear'])
assert set(rarity)=={'common','fine','rare','epic','legend'}
assert not any(p['changed'] or p['files']!=p['current_files'] for p in protected.values()) and summary['source_audit']['failures']==0
assert summary['ui_a8']['failures']==summary['ui_a8']['overflow']==0
assert all(r['battles']==r['equal_battles'] and r['source_actions']==r['actual_actions']==r['matched_actions'] for r in legacy) and p2['different_actions']==0
section=f'''<!-- R22_A9_START -->
## A9 — 피격 뒤 순서·원본 타격 결과·처치 회복 문맥 수정

2026-11-03(한국 시간). 장비 포함 **{summary['gear_battles']:,}/{summary['gear_battles']:,}전투·{summary['gear_records']:,}/{summary['gear_records']:,}개 기록 일치**, 불일치 **0**. 새 native 장비 대조 **624전투·14,933개 기록**을 포함한다. import·공통·기존·신규 검사 **{len(suite)}그룹 / 실패 0**, A9 개별 **{target['checks']}항목 / 실패 0**. P2/A6/P3/A7/A8/A9 전체는 **{summary['all_battles']:,}전투·{summary['all_records']:,}개 기록 일치**다.

집계: [a9-summary.json](verification/data-r21/a9-summary.json), 차이: [a9-parity-gaps.json](verification/data-r21/a9-parity-gaps.json), 검사별 로그: [a9-suite/results.json](verification/data-r21/a9-suite/results.json).

### 수정 전 재현과 정본 근거

원본 Lua를 Wasmoon에서 직접 실행하고 입력과 관측값만 Godot 시험에 옮겼다. 초기 **16항목 중 8실패**를 `a9-part1-before.json`에 보존했다. 지시된 `scratchpad/rv7` 파일과 `rv7_n.gd`·`rv7_n2.gd`는 읽을 수 있는 프로젝트/원본/작업 루트에서 찾지 못해, 지시서의 조건과 수치를 새 `combat_a9_r22_test.gd`에 재현했다. 그 파일을 그대로 복사했다고 주장하지 않는다. Lua 원본 15파일 SHA-256은 각 A9 oracle의 `provenance`에 있다.

|문제|수정 전 → 수정 후 / Lua 정본|원본 행|
|---|---|---|
|피격 후 흡혈보다 반사가 먼저|적 HP1000에서 **1000→990**, HP5에서 **35→45**. 거짓 처치로 오르던 아군 HP **930→900**, MP **2→0**.|`30-engine.lua:863–864`, `31-foes.lua:169–191`|
|보호막 흡수량을 뺀 흡혈|raw100·보호막60, 적 HP500에서 **520→550**. 흡혈은 살아 있고 최대 HP 미만인 적에게만 적용.|`31-foes.lua:176–182`, `30-engine.lua`의 `B.strike res.d`|
|악마 처치 회복에 기술 보너스/난수 적용|회복 장비에서 **560→530**, 축복의 바람이 끌던 게이지 **5000→10000**, 난수는 Lua와 같은 **1회**. 원래 SKON은 복원.|`34-traits.lua:415–439`|
|케른 반격 뒤 마지막 타격을 반사 기준으로 사용|적 HP **831→836**, 반사 **15→10**. 반격의 타격 기록 대신 원래 적 피격의 `d/sh`를 따로 전달.|`81-gear.lua:935–946`|
|강화 제거의 기존 목록 불일치|추가 **9조건 중 7실패**를 `a9-strip-before.json`에 기록 후 수정. 공격·방어·후퇴·피의 갈증·굳건한 방어·아델린·면책·책무 순으로 하나만 제거. 가속/보호막은 제거 목록에서 제외.|`31-foes.lua:10,187–191`|

`dungeon_enemy_r21.turn`은 밀기 → 흡혈 → DOT → 강화 제거 → 특성 attacked → 장비 attacked 순서를 따른다. 피격 결과는 보호막 흡수 전 피해를 보존하며, 반격과 장비 재진입이 새 기록을 추가해도 원래 결과를 읽는다. 복합 조건에서 적 HP **386**, 밀린 게이지 **12000**, DOT **30×3턴**도 일치한다. 처치 회복은 gear kill 훅 뒤 SKON을 잠시 비우므로 장비의 기술 회복%·축복의 바람만 억제하고 피회복 보너스 등은 유지한다.

### native 장비 전체 전투 대조와 추가로 발견한 조건

기존 A7의 독립적인 기술/아이템 선택 정책을 **13파티 × 6적 편성 × 4씨앗 × 적 Lv10·40 = 624전투**로 확장했다. 동료 30명, 케른 3인 이상 파티, 악마 3인 파티, 늪 거머리 떼 단독/방패병 혼합을 포함한다. 원본에 적 자체의 반사 규칙은 없어 장비 반사와 흡혈 몹의 조합을 검증했다.

Godot 입력에는 코드형 `eq`를 넣지 않고 **`native_eq`만** 전달하여 실제 게임의 `gear_init_native` 분기를 강제한다. 원본 Lua는 같은 코드·씨앗·강화의 `B.gear_init/gear_roll`을 사용한다. pre-equipment 능력치는 기존 A7처럼 원본 Lv40 값으로 고정하며, **2,496명**의 초기 HP/MP·주 능력치·방어·속도·치명·별도 민첩·합산 옵션·고유 효과도 비교했다. 장착 **7,488칸**: common **1,354**, fine **1,356**, rare **1,356**, epic **1,348**, legend **2,074**. 원본 장비만 사용하며 시험용 옵션을 제품 데이터에 만들지 않았다.

실제 전투 관측은 흡혈+장비 반사 **{coverage['drain_reflect_hits']}회**, 케른 반격 **{coverage['counters']}회**, 회복%/축복의 바람 장비를 낀 악마 편성의 기술 처치 **{coverage['skill_kill_heal_gear']}회**다. 초기 확장에서는 Lv10 **3전투**, Lv40 **9전투**가 달랐으며 `a9-native-10-before.json`·`a9-native-40-before.json`에 원본/실제 기록을 보존했다.

그중 요르드 개인 기술이 대신 맞은 대상의 계약 표식을 읽던 조건을 고쳤다. 원본 `32-personal-b.lua:351–358`처럼 선택한 대상의 표식을 공격 전에 고정하고, 본 타격의 처치 결과로 원래 대상의 새 표식을 결정한다. 전체 공격 중 반격이 생기는 나머지 기록 차이는 시험의 직렬화 차이였다. Lua가 `eall`을 반격 사건 뒤 한 묶음으로 기록하므로 trace fixture도 그 묶음 순서로 비교한다(`30-engine.lua:869–900`). 실제 피해 처리 순서나 화면 사건은 바꾸지 않았다. 원본 기대 수치·정수 허용 오차를 바꿔 맞춘 항목은 **0**이다.

|대조|전투|일치 기록|
|---|---:|---:|
|기존 A7 Lv10 / Lv40|176 + 176|2,932 + 6,279|
|신규 A9 native Lv10 / Lv40|312 + 312|4,806 + 10,127|
|기존 P2 / A6 / P3|48 + 48 + 128|1,468 + 2,537 + 4,929|
|기존 A8 페르소나|5,120|186,707|

비교는 초기값, 행동자·번호·HP/MP/보호막·CTB 게이지/틱/라운드·적 표적·각 타격 피해/흡수/치명·난수·심연/고갈·최종 결과다. 기존 실수 허용 오차 **1e-7**, 정수 수치와 RNG는 정확 일치다. 모든 적·장비·씨앗의 전수 조합 검증은 아니다.

### 검사·파일·보존과 한계

제품 변경은 `project/game/{{battle_v3,dungeon_enemy_r21,trait_rules_r22,personal_rules_r22}}.gd` **4파일**이다. 기존 시험은 `combat_p2_r22_trace_fixture.gd`의 사건 직렬화만 수정했다. 새 시험 `combat_a9_r22_test.gd`, `combat_a9_native_{{10,40}}_audit.gd`와 UID, 새 도구 `prepare_combat_a9_r22.py`, `prepare_combat_a9_native.py`, `oracle_combat_a9_r22.{{mjs,lua}}`, `oracle_combat_a9_native.mjs`, `run_combat_a9_r22.py`, `report_combat_a9_r22.py`, 증거는 `verification/data-r21/a9-*`다.

초기 manifest는 제품 수정 전에 기록했으며 먼저 만든 A9 재현용 파일도 포함한다. **{len(start):,}파일** 중 `docs/` **{protected['docs']['files']}개**, `project/assets/` **{protected['project/assets']['files']:,}개** 변경 **0**. 원본 자산 **96/96**, 원본 데이터/Lua 감사 실패 **0**. schema **3**과 저장 계약은 유지했고 사용자 저장을 읽거나 덮어쓰지 않았다. git 명령·Web export·버전 갱신·다른 worktree 쓰기는 하지 않았다.

공통 world/state/route/expansion/motion/motion_asset/art/export_licenses, ui_battle_r17~r20, motion_r9/r18와 기존 A6/P3/A7/A8 및 프로젝트 검사 전체가 포함된다. A8 UI 재검사는 **{summary['ui_a8']['checks']:,}항목·{summary['ui_a8']['captures']}캡처 / 글자 폭 넘침 0**이다. 기존 Windows root certificate store 진단만 검사 오류에서 분리했다. 중간 실패와 컴파일 오류를 최종 통과 수에 합산하지 않았다. 화면 배치·아트·컷인·모션 구현은 수정하지 않았으며, 직접 연 결과 이미지 2개는 `a9-visual-review.json`에 기록했고 재검사 후 같은 해시를 확인했다. 모든 PNG와 모든 효과 callback의 육안 전수 검증, 물리 휴대폰 검증, 새 Web/WASM 검증은 하지 않았다.

```powershell
node tools/oracle_combat_a9_r22.mjs
python tools/prepare_combat_a9_native.py
$env:A9_ENEMY_LEVEL='10'; node tools/oracle_combat_a9_native.mjs
$env:A9_ENEMY_LEVEL='40'; node tools/oracle_combat_a9_native.mjs
python tools/run_combat_a9_r22.py
python tools/audit_data_r21.py
python tools/report_combat_a9_r22.py
```
<!-- R22_A9_END -->

'''
report=R/'DATA-R21.md';text=report.read_text(encoding='utf-8')
if '<!-- R22_A9_START -->' in text:
 start_at=text.index('<!-- R22_A9_START -->');end_at=text.index('<!-- R22_A9_END -->')+len('<!-- R22_A9_END -->')
 text=text[:start_at]+section+text[end_at:].lstrip('\n')
else:
 heading,body=text.split('\n',1);text=heading+'\n\n'+section+body.lstrip('\n')
report.write_text(text,encoding='utf-8')
