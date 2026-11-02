"""Build the P2 handoff from recorded final checks; never infer a pass."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/data-r21'
read = lambda name: json.loads((OUT / name).read_text(encoding='utf-8-sig'))
write = lambda name, value: (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
suite = read('suite-all.json')
for row in read('suite-combat_p2_r22_test-enemy_action_r21_test-enemy_review_r21_test-dungeon_r21_test-combat_p2_r22_trace-ui_battle_r18_test.json'):
    suite = [row if old['test'] == row['test'] else old for old in suite]
row = read('p2-r18-isolated.json')
suite = [row if old['test'] == row['test'] else old for old in suite]
assert len(suite) == 23 and all(r['passed'] for r in suite), suite
checks = read('p2-latest.json')
trace = read('p2-full-battles.json')
audit = read('source-audit.json')
action = read('enemy-action-results.json')
integration = read('integration.json')
ui = read('ui-results.json')
assert not checks['failures'] and trace['different_actions'] == 0
assert trace['battles'] == 48 and trace['matched_actions'] == trace['compared_actions']
assert audit['failures'] == action['failures'] == integration['failures'] == ui['failures'] == 0
protected = read('p2-protected-before.json')
changed = [p for p, sha in protected.items() if not (ROOT / p).is_file() or hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != sha]
assert not changed, changed
guard = {'checked': len(protected), 'docs_files': sum(p.startswith('docs/') for p in protected), 'changed': changed}
write('p2-protected-after.json', guard)
write('p2-suite-final.json', suite)
write('p2-final.json', {'status': 'partial: core engine verified; remaining presentation and hook contracts listed in DATA-R21.md', 'checks': checks['checks'], 'failures': 0, 'battles': trace['battles'], 'actions': trace['compared_actions'], 'different_actions': 0, 'suites': len(suite), 'protected': guard})
rows = '\n'.join(f"| `{r['test']}` | 통과 | 0 |" for r in suite)
section = f'''<!-- R22_P2_START -->
## P2 — CTB·난수·라운드 핵심 이관 / 표시·일부 훅은 미완료

2026-11-02. **P2 일부 완료.** CTB, 기본 공격·치명 난수, 주요 라운드 훅, 400행동 종료, 저장 재개, 레이드 충전 예고·단계 전환 연결을 수정했다. **새 검사 {checks['checks']}항목 / 실패 0**, 원본 파티 3조합 × 적 4편성 × 씨앗 4개의 **{trace['battles']}전투·{trace['compared_actions']:,}행동 / 불일치 0**이다. 공통·기존·새 검사 **{len(suite)}종 / 실패 0**. 아래 ‘남은 범위’를 포함한 P2 전체 완료를 뜻하지 않는다. 아래 1~5차 기록의 CTB·난수 검증 경계는 이번에 명시한 범위만큼 확장된다.

### 바뀐 동작과 원본 근거

| 단위 | 변경·대조 | 정본 |
|---|---|---|
| CTB | `ceil(max(g,0)/speed)`·슬롯 우선 동률·음수 초과 게이지 보존·행동 비용 가산·현재 차례 포함 8칸 예측. 속도 소수 둘째 자리 반올림, 연금술사 가속 1회 적용. 새 전투도 실제 게이지로 첫 차례를 정한다. | `30-engine.lua:125–140,188–245,262–279`, `34-traits.lua:224–238` |
| 라운드 | 100틱 경계마다 지능 계열 2명 MP +4 → 살아 있는 개인 훅의 슬롯 순서 → 전역 훅. 우르다 회복·약화 정화, 토베 보호막, 소렐 2라운드 재생, 미코 variant 2의 최장 대기 동료 당김, 하프엘프 정화를 연결했다. 한 번에 여러 라운드를 넘는 경우도 실행한다. | `20-state.lua:21–27`, `30-engine.lua:172–210`, `32-personal-a/b.lua`, `34-traits.lua:358–370` |
| 공격·난수 | 아군 입력·충전 해방에도 `(seed*31+n*977+13)%2147483646+1` 재시드, 적과 같은 16807 난수열. 보장된 치명도 1회 소비한다. 공격 약화·적 방어 버프, 방어 자세의 정수 절사 위치, 약점 심연 깎기 반올림을 맞췄다. 슬롯 이름 executor를 일반 적의 정예 보정 근거로 쓰던 오류를 제거했다. | `20-state.lua:3–10`, `30-engine.lua:284–326,330–337,433–447,781–808` |
| 예고·고갈·레이드 | 힐데가의 예고별 스캔이 정규화된 공격 6종을 모두 읽고 같은 난수를 소비한다. 구역 보스의 공인 마법사 지연은 절반이다. 충전 전 2차례/충전 중 1차례의 큰 기술 이름, 고갈 우선 경고, 단계 전환을 행동 끝 뒤 CTB 전에 반영한다. 소환은 하수인 등급·수치로 만든다. 장기전은 적 행동 횟수 대신 실제 라운드를 읽는다. | `31-foes.lua`, `32-personal-a.lua:635–660`, `34-traits.lua:400–405`, `51-raid.lua:10–20,48–60` |
| 종료·저장 | 적 전멸 승리 우선 → 아군 전멸 → 400행동 패배. 생존자가 있는 제한 패배도 저장·복원한다. schema 3을 유지하며 선택적 `ctb.tick/round`와 소환 등급을 기록한다. 음수 게이지·유효하지 않은 시계·실제 JSON 재개·옛 소환 HP 보존을 검사했다. | `30-engine.lua:1044–1049`, `20-state.lua:328–360` |

### 실행 증거와 수치

- 원본 `lua_sim.mjs`의 wasmoon에서 정본 12파일을 재적재했다. 새 Lua는 입력·관측만 정의하며 `B.advance/preview/round_tick/attack/player/run/check_end/raid_charge_info`를 직접 실행한다. 정본 봇·다른 worktree는 읽기만 했다.
- 단위 oracle: CTB 16, 라운드 28, 공격 120, 종료 16, 충전 예고 168, 장기전 120행. `p2-oracle.json`, `p2-latest.json`.
- 수정 전 재현: CTB 핵심 48항목 중 37실패, 라운드 포함 176항목 중 58실패, 공격 포함 416항목 중 236실패, 충전 포함 648항목 중 99실패, 미코 포함 784항목 중 9실패. `p2-*-before*.json`. 초기 예측 배열 비교의 int/float 문제를 바로잡았고 CTB의 수정 전 수치는 비교가 유효한 시간·게이지·행동자 48항목만 보고한다. 원본 기대 숫자를 구현에 맞춰 바꾸지 않았다.
- 전체 전투: 힐데가·바르굿·테이리스·베렌가 / 마르셀린·나란·레비아·테이리스 / 소렐·아델린·토베·우르다, Lv10. 적은 연습 인형 2명, 녹슨 방패병 2명, 폭주 강사 레이드, 서리 계약자 레이드. 각 전투 번호 1~4, 같은 원본 씨앗, 살아 있는 첫 적에 기본 공격하는 입력이다. 아군 초기 수치는 정본 값으로 고정해 P1/P4의 생성·장비 초기화를 분리했다.
- 행동마다 행동자, 각 타격의 대상·피해·치명·보호막 흡수, HP·MP·보호막, CTB 게이지·틱·라운드, 다음 표적, 심연·고갈, RNG를 비교했다. 연속 실수 게이지 오차 허용은 1e-7이며 HP·피해·RNG의 정수 차이는 허용하지 않는다. 미사용 소환 예약 칸의 내부 sentinel만 0으로 정규화했다. `p2-full-battles.json`: **{trace['compared_actions']:,}/{trace['compared_actions']:,} 일치**, 불일치 0.
- 기존 적 행동 **{action['checks']:,}항목**, 개별·연속 **1,221/1,221씩 일치**. 던전 **{integration['checks']:,}항목**, 420층 승리/패배 강제 종결 각각 420회, 자연 전투 승리 {integration['outcomes']['natural_victory']} / 패배 {integration['outcomes']['natural_defeat']}. UI 이름표 {ui['nameplates']:,}개 / 넘침 {ui['overflow']}.
- 원본 그림 **96/96**, 보호 파일 **{guard['checked']}개** 및 `docs/` **{guard['docs_files']}개** 변경 0. 원본 데이터 대조·정본 원본 변경 0. `source-audit.json`, `p2-protected-after.json`.

### 저장 호환과 검사 입력 조정

기존 schema 3에서 시계가 없으면 HP·MP·게이지·효과·RNG·선택을 그대로 보존하고, 새 시계는 0부터 시작한다. 옛 저장은 과거 시간·라운드를 기록하지 않았으므로 원래의 경계를 복원했다고 주장하지 않는다. 옛 소환은 저장 당시의 등급 해석으로 읽고 이후 저장에 그 등급을 기록한다. 잘못된 mob 수치로 저장되어 수정된 하수인 최대 HP보다 현재 HP가 큰 경우도 깎거나 거부하지 않는 시험을 추가했다. 사용자 저장 파일을 지우거나 덮지 않았다.

펠리체 enemy_end 분리 시험은 다음 차례를 1틱 안에 두어 라운드 훅이 섞이지 않게 했다. 420층 강제 승리 시험은 적 공격력을 0으로 두었다. 원본 CTB에서는 적 여러 명이 먼저 행동할 수 있어, 거대한 아군 공격력만으로 승리를 보장하던 옛 입력이 더는 유효하지 않기 때문이다. 기대 결과는 바꾸지 않았다. 고층 정본 DOT가 100,000을 넘는 합법 저장을 드러내 해당 DOT의 수치 검증 한도만 넓혔다. 다른 효과의 한도는 그대로다.

### 남은 범위 — 다음 작업자가 이어갈 것

1. **40-fx·50-render 전체 사건/칩 계약**: 28개 사건 종류 중 기본 타격·고갈/회복·적 충전/취소·단계/소환·종료의 엔진 발생은 위 전투에서 검증했다. 지원·개인·아이템 연출 등 나머지 18종의 원본 표시 시점, 전체 상태칩, 컷인·다중 타격 표시 계약은 미완료다. `p2-event-contract.json`에 종류별 근거·보류를 기록했다. 기존 UI 검사는 r17~r20 외형 회귀를 확인하며, 원본 HTML 연출과의 전수 동등성 증거가 아니다.
2. **남은 라운드/대기 훅**: 유디트의 라운드 기반 원래 속도 복원, 페르소나 라운드 재생, 펠리체의 양수 잔여 게이지에 따른 소생 대기, 죽은 성벽 착용자의 라운드 수명 등을 원본 대조 fixture로 이어가야 한다. 모든 효과의 시작/종료 틱도 완전히 교체한 것은 아니다.
3. **아군 전체 기술·특성·장비 조합**: 이번 전체 전투 정책은 기본 공격이다. 모든 능동 기술·30명 전체 특성·장비 proc 순서까지 검증한 것은 아니다. P3/P4의 남은 구현을 연결한 뒤 같은 전체 trace를 확장해야 한다. 보급품 행동의 재시드·개인 특수 DOT·혼합 재생 전수 대조도 남아 있다.

### 파일·재실행·시각 확인

구현: `project/game/combat_clock_r22.gd` 신규, `battle_v3.gd`, `dungeon_enemy_r21.gd`. 검사: `combat_p2_r22_test.gd`, `combat_p2_r22_trace.gd`, `combat_p2_r22_trace_fixture.gd` 신규; 기존 `enemy_action_fixture_r21.gd`, `enemy_review_r21_test.gd`, `dungeon_r21_test.gd`의 격리 입력 조정. 도구: `oracle_combat_p2_r22.mjs/.lua`, `report_combat_p2_r22.py` 신규, `verify_data_r21.py`에 새 검사 등록. 근거: `verification/data-r21/p2-*`, 재생성된 검사 산출물.

```powershell
node tools/oracle_combat_p2_r22.mjs
python tools/verify_data_r21.py
python tools/audit_data_r21.py
python tools/report_combat_p2_r22.py
```

직접 연 이미지: `verification/data-r21/battle-360-7.png`, `verification/ui-r20/all-states-360.png`. 7칸 적 이름표·HP·행동 순서, 아군 카드·명령·기술·보급품·기록 시트의 배치를 확인했다. 모든 결과 이미지를 각각 연 것은 아니다. UI·마을·대사·초상·적 그림 파일은 수정하지 않았다. Web export·버전 갱신·git 명령은 실행하지 않았다.

UI r18에서 간헐적으로 종료 시 리소스 잔류 1건이 나왔다. 마지막 전체 실행과 마지막 단독 verbose 실행(4,592항목)은 리소스·엔진 오류 0이었다. 원인은 특정하지 못했으며 `p2-r18-verbose.log`와 이전 실패 로그를 남겼다. 아래 표는 마지막 전체 실행·영향 검사·단독 재확인 결과다. 반복되는 OS 인증서 저장소 진단은 기존 환경 메시지로 분리했다.

| 최종 검사 | 결과 | 실패 |
|---|---|---:|
{rows}

<!-- R22_P2_END -->
'''
report = ROOT / 'DATA-R21.md'
text = report.read_text(encoding='utf-8')
start, end = '<!-- R22_P2_START -->', '<!-- R22_P2_END -->'
if start in text:
    a = text.index(start); z = text.index(end, a) + len(end)
    text = text[:a] + section.rstrip() + text[z:]
else:
    title, rest = text.split('\n', 1)
    text = title + '\n\n' + section + rest
report.write_text(text, encoding='utf-8')
print(json.dumps({'report': str(report), 'status': 'partial', 'checks': checks['checks'], 'battles': trace['battles'], 'actions': trace['compared_actions'], 'failures': 0, 'suites': len(suite)}, ensure_ascii=False))
