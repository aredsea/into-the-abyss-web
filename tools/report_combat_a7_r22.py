from pathlib import Path
import json,hashlib,collections,datetime
R=Path(__file__).resolve().parents[1]; O=R/'verification/data-r21'
read=lambda p:json.loads((R/p).read_text(encoding='utf-8'))
suite=read('verification/data-r21/a7-suite/results.json')
gear=[read('verification/data-r21/'+name) for name in ['a7-gear-audit.json','a7-gear-balanced-audit.json']]
oracle=read('verification/data-r21/a7-gear-oracle.json'); defs=read('project/data/gear-r22.json')
accessories=collections.Counter(m['eq']['acc'].split('.')[0] for row in oracle['battles']+oracle['raid_battles'] for m in row['pm'])
effects=collections.Counter(defs['items'][code.split('.')[0]].get('unique',{}).get('key','none') for row in oracle['battles']+oracle['raid_battles'] for m in row['pm'] for code in m['eq'].values())
protected=read('verification/data-r21/a7-protected.json')
changed=[p for p,h in protected.items() if not (R/p).is_file() or hashlib.sha256((R/p).read_bytes()).hexdigest()!=h]
docs=[p for p in protected if p.replace('\\','/').startswith('docs/')]
new_docs=sorted(str(p.relative_to(R)) for p in (R/'docs').rglob('*') if p.is_file() and str(p.relative_to(R)) not in protected)
gaps=[{'set':i,'party':r['party'],'foe':r['foe'],'bn':r['bn'],'first_difference':r['first_difference']} for i,g in enumerate(gear) for r in g['reports'] if r['first_difference']]
baseline=read('verification/data-r21/a7-part1-pinned-before.json'); before_gear=read('verification/data-r21/a7-gear-pinned-before.json')
part1=read('verification/data-r21/a7-part1-latest.json'); flow=read('verification/data-r21/a7-flow.json')
summary={'suite_groups':len(suite),'suite_failed':[r for r in suite if not r['passed']],'gear_battles':sum(g['battles'] for g in gear),'gear_equal_battles':sum(g['equal_battles'] for g in gear),'gear_source_records':sum(g['source_actions'] for g in gear),'gear_matched_records':sum(g['matched_actions'] for g in gear),'legendary_accessories':dict(sorted(accessories.items())),'accessory_min_appearances':min(accessories.values()),'unique_effects':dict(sorted(effects.items())),'part1_checks':part1['checks'],'part1_failures':part1['failures'],'flow_checks':flow['checks'],'flow_failures':flow['failures'],'baseline_checks':baseline['checks'],'baseline_failures':baseline['failures'],'baseline_gear_equal':before_gear['equal_battles'],'protected_files':len(protected),'docs_files':len(docs),'protected_changes':changed,'parity_gaps':gaps}
summary['new_docs']=new_docs
(O/'a7-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'a7-parity-gaps.json').write_text(json.dumps(gaps,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
source=Path('C:/Clauede Code/dungeon-bot/bot/src')
provenance={name:{'sha256':hashlib.sha256((source/name).read_bytes()).hexdigest(),'lines':len((source/name).read_text(encoding='utf-8').splitlines())} for name in ['20-state.lua','30-engine.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','77-explore.lua','81-gear.lua']}
(O/'a7-source-provenance.json').write_text(json.dumps(provenance,indent=2)+'\n',encoding='utf-8')
today=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).date().isoformat()
section=f'''<!-- R22_A7_START -->
## A7 — 재검수 종결 · P4 실제 전투 연결

{today}(한국 시간). 장비 포함 **{summary['gear_equal_battles']}/{summary['gear_battles']}전투·{summary['gear_matched_records']:,}/{summary['gear_source_records']:,}개 기록 일치**. 전설 장신구 **30종**, 각 **최소 {summary['accessory_min_appearances']}회** 착용. 최종 import·프로젝트 검사 **{len(suite)}그룹 / 실패 {len(summary['suite_failed'])}**. A7 사건 단위 **{part1['checks']}항목**, 실제 정산/가방/전투/저장 흐름 **{flow['checks']}항목**, 실패 **{len(part1['failures'])+len(flow['failures'])}**. 세부 정본은 `verification/data-r21/a7-summary.json`, 검사별 로그는 `a7-suite/`다.

### 1부: 유효한 수정 전 재현과 변경

지시된 병합 커밋 **973a1464e46f820a5e0d825e32e96b9e7080d3f5**의 loose object를 읽기 전용으로 직접 해제해 전투·개인·특성·적 모듈을 고정했다. git 명령은 실행하지 않았다. `a7-baseline-provenance.json`의 blob/SHA-256과 `a7_baseline_*.gd`로 재현한다. 고정 기준선 **7항목 중 3실패**, 현재 **9항목 실패 0**이다. 추가 2항목은 장비 파티 피해의 최댓값 단일 적용과 알탄 시작 보호막의 직접 setf 경계다. 알탄은 첫 슬롯의 보호막 장비가 잘못 적용되는 실패를 먼저 기록한 뒤 수정했다(`a7-altan-before.json`). 최초 임시 시험의 보스 `phase=0`은 원본 조건이 아니므로 유효한 수정 전 근거에서 제외했다. 보스와 일반 DOT가 모두 새 결함이었다는 초기 진단을 바로잡았다.

|지적|973a146 실제 결과와 처리|원본 근거|
|---|---|---|
|P1-a 일반 공격 DOT|활성 TraitRules 경로는 이미 **3턴**, 틱 **[24,24,24,0]**. 회귀 시험으로 기해소 확인. 반환 뒤 도달하지 않는 옛 분기의 r21 수명도 3으로 정리했으며 옛 원정의 4턴은 유지.|`34-traits.lua:407–410`, `81-gear.lua:689–712`|
|P1-b 연쇄 폭발/단계 보스|이미 `_incoming_strike → _flat_enemy → phase_guard`를 통해 **1440→719 생존**. 원본 Lua 실제 실행과 고정 기준선 모두 통과. 새 P4 bridge의 strike 재진입에서도 같은 보호를 유지.|`30-engine.lua:347–355`, `81-gear.lua:693–704`|
|P2-c 옛 전투 정수화|199.9999999999998의 옛 일반 공격이 **200→199**. epsilon은 r21에서만 사용. 추가 Lv40 대조에서 발견한 대신 맞기 350×0.7도 r21의 B.floor 보정으로 **244→245**.|`30-engine.lua:324,333–336`; 옛 모델은 보정 전 floor 계약|
|P2-d 보호막에 전부 막힌 피격|HP100·보호막1000에서 raw100: 소렐이 잘못 회복하던 **300→100**, 구조 횟수 **1→0**. HP 손실 >0일 때만 개인 damaged와 장비 damaged.|`30-engine.lua:405`|
|Nit-e 옛 합산 DOT|실제 현재 cap(5 또는 모르가스 3인일 때 6)으로 이관 개수를 제한. 6줄 합산 600의 일반 편성 이관은 **5줄**, 총합 보존.|`34-traits.lua` DOT cap/trim, 기존 저장 보존 계약|

### 2부: P4의 실제 호출·재진입·중복 제거

`gear_battle_r22.gd`가 P4 ABI를 실제 HP/MP/보호막/CTB/효과와 동기화한다. heal/strike/kill_credit/badd는 전투 엔진으로 돌아간 뒤 다시 동기화한다. 중첩 회복은 현재 ACT/SKON을 읽는다. 개인 TR → 기존 특성 GH → 장비 GH 순서를 지키며, deal/take 개인 값 체인의 SKON 임시 해제를 유지했다. 13 GH 슬롯(deal, crit, take, heal, shield, abyss_mul, hit_after, damaged, attacked, turn_end, enemy_dead, round, abyss_after)과 P4의 직접 호출 경계를 연결했다. 세부 호출 위치의 정본은 기존 `P4-R22.md`와 `verification/gear-r22/integration-calls.json`이다.

- 시작: 종족/출신 이후 pre-equipment 능력치에서 `gear_init_native` 또는 `gear_init` **하나**만 적용한다. 표시용 장비 수치를 다시 곱하지 않는다. 상처·영창 축적·첫 행동·광기·처치·행동 반환과 성벽 상태도 실제 전투 수명으로 이어진다.
- 행동: 재시드 → first_action → gear_mpc → MP 차감 → gear_echo → ACT/SKON → 기술 → SKON 해제 → gear_skill → 기본 턴 비용 → 개인/특성 → 장비 turn_end. crit는 강제 치명이어도 기본 난수를 소비한다.
- 피해/회복: 장비 피해는 원본처럼 합산하고 파티 피해는 살아 있는 최대 한 명만 적용한다. 기존 r20 gear_fx 분기와 겹치는 효과는 r21에서 중복하지 않는다. 보호막 파괴·반사·가시는 fixed strike로 재진입한다. 반사도 표식을 소비한다. 장비로 오른 주 능력치(cs)와 치명 확률용 원래 민첩(ag)을 분리했다.
- 보호막/심연/DOT: 클래스 파티 보호막의 GH는 시전자 기준 **한 번** 호출한다. 리네트 개인 보호막은 원본의 직접 setf이므로 GH를 통과시키지 않는다. 장비 abyss_mul은 기존 GH를 덮어쓰는 계약을 지킨다. DOT 변환·즉시 연쇄·독 만료·중복 소유자 제거·tick 후 처치 순서를 연결했다.
- 기존 개인 기술도 장비와 함께 재검증했다. 셀바의 복리 고정 피해 처치는 원본처럼 장비 kill_credit를 따로 부르지 않는다. Lv40 전체 공격 도중 펠리체가 다음 슬롯 동료를 소생시키면, 그 동료도 같은 공격의 다음 슬롯에서 다시 판정한다.
- 페르소나 1인 편성은 bridge 안에서만 빈 4슬롯을 채운다. 실제 전투/화면 슬롯은 원래 편성 크기로 다시 변환한다. 장비 표는 읽기 전용으로 공유하고 bridge 소유자는 약한 참조로 연결해 반복 전투의 중복 로딩·참조 순환을 피했다. 기존 P4의 bridge 대입 ABI도 유지했다.

### 전체 전투 대조

P3의 기존 3파티 + 30명 전원 출전 8파티, 적 4편성, 씨앗 4개의 **176전투 정책**을 사용한다. 각 엔진이 개인/직업 기술·물약의 사용 가능 여부와 대상을 독립적으로 고른다. 원본 `gear_code/gear_roll/gear_init`로 만든 동일 코드·씨앗·강화 입력을 전달한다. 착용자의 Lv40 원본 pre-equipment 능력치를 고정하여 P1 생성 차이를 분리한다.

|대조 묶음|범위|결과|
|---|---|---|
|A7 장비 기본|Lv40 착용자 / 기존 Lv10 적 정책|**176전투·2,932개 기록 일치**|
|A7 장비 동레벨 확장|착용자·적 모두 Lv40|**176전투·6,279개 기록 일치**|
|기존 A6/P3 장비 없는 혼합 정책|48+128전투|**176전투·7,466개 기록 일치**|
|기존 P2 기본 공격|48전투|**1,468개 기록 일치**|
|고정 기준선의 장비 입력|동일 A7 기본 176전투|**0/176 일치**; 미연결 상태의 대조 근거|

행동 번호/행동자/HP/MP/보호막/CTB 게이지·틱·라운드/타깃/각 타격의 피해·치명·흡수/RNG/심연·고갈/최종 결과를 비교했다. 실수 게이지의 기존 허용 오차 **1e-7**, 정수 피해·HP·RNG는 정확 일치다. 차이 목록 `a7-parity-gaps.json`은 현재 **{len(gaps)}건**이다. 장신구 30종과 기존 고유 효과 10종은 실제 장비 조합에 포함됐고, 남은 party_dmg는 Lua 사건 단위 시험으로 두 착용자의 최대 한 번 적용을 확인했다. 이는 모든 장비·씨앗·강화·전투 조합의 전수 검증은 아니다.

### 정산·가방·저장 호환

실제 `advance` 탐색 장비 생성 → `settle(retreat)` → 코드·source_r21·UID 보존 → 기존 P7 equip → 다음 원정 battle_data → 실제 Battle의 원본 옵션 반영을 한 흐름으로 시험했다. 출전/휴식 뒤에는 현재 장착 목록을 다시 읽는다. 과거 두 칸짜리 loot 토큰은 종전 native RNG로 처리하며 versioned 새 코드만 source_r21으로 만든다. 가방이 찬 정산 코드는 overflow에 보존한다(원본의 버림과 다른, 저장 삭제 금지 지시에 따른 차이).

schema **3 유지**. 성벽·보호막 파괴 임시 상태는 선택적 gear_* 필드이며 소유자/숫자/형식을 검증한다. 옛 scar/charge_damage/stood/wall_saved와 표시 효과는 원본 장비 상태에 이관한다. 실제 장비 전투·활성 성벽·상처·현재 원정 전체의 JSON 왕복과 잘못된 장비 소유자 거부를 통과했다. 사용자 저장은 열거나 덮어쓰지 않았고 UI 시험의 user:// 파일은 격리 runtime에만 생성했다.

### 검사·파일·남은 범위

최종 결과는 `a7-suite/results.json` **{len(suite)}그룹 / 실패 {len(summary['suite_failed'])}**이다. 기존 기대 수치는 바꾸지 않았다. `ui_persona_r22_test.gd`의 저장 경로만 폭·높이·프로세스별로 격리했다. 기존 경로가 같은 폭(390)의 다음 사례에서 앞 사례의 진행 중 전투를 자동 복원하던 간섭을 제거한 것이다. 최초 중간 실패는 `a7-suite-initial.json`; 최종 수치를 그 목록과 합산하지 않는다. OS root certificate store 메시지만 기존 환경 진단으로 분리했다.

제품 변경: `battle_v3.gd`, 새 `gear_battle_r22.gd`, `gear_hooks_r22.gd`, `personal_rules_r22.gd`, `trait_rules_r22.gd`, `dungeon_enemy_r21.gd`, `dungeon_world_r21.gd`. 검사/도구: `combat_a7_{{r22_test,flow_test,gear_audit,gear_balanced}}.gd`, 고정 기준선 fixture, `ui_persona_r22_test.gd`, `oracle_combat_a7*`, `prepare_combat_a7*`, `verify_combat_a7_r22.py`, `run_a7_case.py`, `report_combat_a7_r22.py`와 import UID. 그 외 변경은 verification 결과다.

보호 manifest **{len(protected):,}파일 / 변경 {len(changed)}**, `docs/` **{len(docs)}파일**. 원본 그림 **96/96**, 원본 데이터/Lua 감사 실패 **0**. 직접 연 이미지는 `verification/ui-r20/base-390.png`, `verification/persona-r22/render/persona-battle-390x844.png`다. 4인 전투 카드/HP/명령 배치와 1인 페르소나 HUD를 확인했으며 모든 캡처의 전수 육안 검수나 원본 HTML 픽셀 동일성은 주장하지 않는다.

마을 화면·대사·초상·적 그림·Web export·docs·버전 갱신은 수정/실행하지 않았다. 마을 정예 의뢰 보상/대장간 버튼의 별도 연결, 성적 콘텐츠는 이번 범위가 아니다. 정본과 다른 남은 전투 기록은 현재 0건이며, 모든 proc 연출 callback의 시각 전수 동일성은 별도 검증하지 않았다.

```powershell
node tools/oracle_combat_a7_r22.mjs
python tools/prepare_combat_a7_gear.py
node tools/oracle_combat_a7_gear.mjs
node tools/oracle_combat_a7_gear_balanced.mjs
python tools/prepare_combat_a7_baseline.py
python tools/godot_r17.py --headless --script res://tests/combat_a7_baseline.gd       # expected failure 3
python tools/godot_r17.py --headless --script res://tests/combat_a7_gear_baseline.gd  # expected mismatch 176
python tools/verify_combat_a7_r22.py
python tools/audit_data_r21.py
python tools/report_combat_a7_r22.py
```
<!-- R22_A7_END -->

'''
p=R/'DATA-R21.md'; text=p.read_text(encoding='utf-8')
if '<!-- R22_A7_START -->' in text:
 start=text.index('<!-- R22_A7_START -->'); end=text.index('<!-- R22_A7_END -->',start)+len('<!-- R22_A7_END -->')
 text=text[:start]+text[end:].lstrip('\n')
header,rest=text.split('\n',1); p.write_text(header+'\n\n'+section+rest.lstrip('\n'),encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['legendary_accessories','unique_effects']},ensure_ascii=False))
