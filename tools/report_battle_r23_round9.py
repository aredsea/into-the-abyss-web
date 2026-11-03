"""Publish round 9 evidence only after the complete frozen suite has passed."""
from pathlib import Path
from collections import Counter
import copy
import hashlib
import json
import os

R = Path(__file__).resolve().parents[1]
O = R / 'verification/parity-r23'
S = O / os.environ.get('R23_FINAL_SUITE', 'suite-round9-final-v4')
SAME, PARTIAL, UNKNOWN, EXCLUDED = '같음', '일부', '미확인', '제외'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def write(p, v):
    p.write_text(json.dumps(v, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def reference(file, symbol):
    path = R / file
    return {'file': file, 'symbol': symbol, 'line': next(
        i + 1 for i, line in enumerate(path.read_text(encoding='utf-8').splitlines())
        if symbol in line)}


prior = read(O / 'battle-round9-before/battle-prior-ledger.json')
coverage = read(O / 'coverage.json')
cov = {r['id']: r for r in coverage['rows']}
assert len(coverage['runs']) == 37 and all(r['exit'] == 0 for r in coverage['runs'])
assert (coverage['called_functions'], coverage['newly_entered_baseline_entries']) == (209, 157)

extras = {'balance_probe', 'export_licenses', 'motion_r9_integration', 'motion_r18_integration',
          'combat_p2_r22_trace', 'combat_a6_mixed_audit', 'combat_p3_mixed_audit',
          'combat_a7_gear_audit', 'combat_a7_gear_balanced', 'combat_a8_audit',
          'combat_a9_native_10_audit', 'combat_a9_native_40_audit'}
expected = {'import'} | {p.stem for p in (R / 'project/tests').glob('*.gd')
                        if p.stem.endswith('_test') or p.stem in extras}
suite = [read(p) for p in (S / 'rows').glob('*.json')]
assert {r['test'] for r in suite} == expected
assert all(r['passed'] and not r['errors'] for r in suite)
assert read(S / 'group-exits.json') == [0, 0, 0, 0]
assert read(S / 'final-code-verification.json')['unchanged']
assert read(S / 'local-server-result.json')['exit'] == 0
lock = read(S / 'final-code-lock.json')
tested = read(S / 'tested-code.json')
assert all(lock['sha256'][name] == h for name, h in tested.items())
assert all(sha(R / name) == h for name, h in {**lock['sha256'], **lock['inputs']}.items())
assert all(p.stat().st_mtime >= lock['time'] for p in (S / 'rows').glob('*.json'))

packs = {}
for name in ['core', 'items', 'state', 'control', 'handlers', 'start', 'enemyturn', 'damaged']:
    stem = 'battle-round9-' + name
    m, a = read(O / (stem + '-oracle.json')), read(O / (stem + '-latest.json'))
    assert a['checks'] == sum(p['rows'] for p in m['parts']) == len(a['rows'])
    assert not a['failures'] and all(r['ok'] for r in a['rows'])
    for p in m['parts']:
        assert sha(O / p['file']) == p['sha256']
        assert (O / p['file']).stat().st_size == p['bytes'] < 40_000_000
    for filename, h in m['provenance'].items():
        assert sha(Path('C:/Clauede Code/dungeon-bot/bot/src') / filename) == h
    packs[name] = {'test': 'battle_r23_round9_' + name + '_test', 'counts': m['counts'],
                   'checks': a['checks'], 'oracle': 'verification/parity-r23/' + stem + '-oracle.json',
                   'observations': 'verification/parity-r23/' + stem + '-latest.json'}
source_checks = sum(p['checks'] for p in packs.values())
assert source_checks == 11987
ui, cloud = read(O / 'battle-round9-ui-latest.json'), read(O / 'battle-round9-cloud-latest.json')
assert ui['checks'] == 2720 and not ui['failures'] and len(ui['captures']) == 20
assert cloud['checks'] == 10 and not cloud['failures']
checks = source_checks + ui['checks'] + cloud['checks']

parity = []
for name in ['a6-mixed-audit', 'p3-mixed-audit', 'a7-gear-audit', 'a7-gear-balanced-audit',
             'a8-audit', 'a9-native-10-audit', 'a9-native-40-audit']:
    a = read(R / 'verification/data-r21' / (name + '.json'))
    assert a['battles'] == a['equal_battles']
    assert a['source_actions'] == a['actual_actions'] == a['matched_actions']
    parity.append(a)
p2 = read(R / 'verification/data-r21/p2-full-battles.json')
assert p2['different_actions'] == 0
battles = sum(a['battles'] for a in parity) + p2['battles']
records = sum(a['source_actions'] for a in parity) + p2['compared_actions']
assert (battles, records) == (6320, 219785)

protected_start = read(O / 'battle-round9-protected.json')
protected = {}
for folder in ['docs', 'project/assets', 'server']:
    old = {n: h for n, h in protected_start.items() if n.startswith(folder + '/')}
    now = {p.relative_to(R).as_posix(): sha(p) for p in (R / folder).rglob('*') if p.is_file()}
    assert old == now, folder
    protected[folder] = {'files': len(now), 'changed': []}
assets = read(R / 'ASSET-HASHES.json')
assert len(assets) == 96 and all(sha(R / a['path']) == a['sha256'] for a in assets)
visual = read(O / 'battle-round9-visual-review.json')
assert len(visual['opened']) >= 4 and all(sha(R / a['file']) == a['sha256'] for a in visual['opened'])
assert all(p.stat().st_size < 40_000_000 for p in O.rglob('battle-round9*') if p.is_file())
assert not list((O / 'coverage').glob('*oracle*.json'))
snapshot_hashes = read(O / 'battle-round9-before/battle-before-sha256.json')['module_sha256']
assert all(sha(O / 'battle-round9-before' / name) == h for name, h in snapshot_hashes.items())

# Explicit function contracts. Parent functions retain unresolved integration;
# matching a protocol callback boundary does not prove its engine callees.
mapping = {
    'P1539': ('state', 'blank_unit', 'battle_source_state_r23.gd', 'func blank_unit',
              '1056개 원본 모양 초기 단위와 state 부수 효과 전체. 빈 슬롯·10직업·실장비·개인 생성 stats·종족·옛 고정/조합 적·dm HP 하한. fresh/battle_start 전체 연결은 별도 행에 남김.'),
    'P1542': ('state', 'persona_ratio', 'battle_stats_r23.gd', 'static func persona_ratio',
              '56개 비율 함수 직접 반환: 누락·0 분모·숫자/16진 문자열·무효 값. 실제 persona_stats와 persona_world 능력 산식에서 같은 helper 사용.'),
    'P1616': ('start', 'battle_pm', 'combat_party_r23.gd', 'static func battle_pm',
              '204개 source-shaped 함수의 반환 편성 및 입력 world 부수 효과 전체. persona fight·옛 G.lv fallback·빈 칸·누락 장비·roster/party·skill/stats. 실제 world→battle_start 전체 연결은 P1620에 남김.'),
    'P1619': ('start', 'quest_compose', 'combat_party_r23.gd', 'static func quest_compose',
              '189개 source-shaped 함수의 enc 반환·G.n/RNG 부수 효과: 균열 이름/별칭·cmp·종류·난이도·stars·빈 편성·seed. 기존 dungeon.compose 사용. 의뢰 UI→시작 연결은 P1620에 남김.'),
    'P1720': ('control', 'hook_dispatch', 'combat_hooks_r23.gd', 'func fire',
              '384개 dispatch 묶음 중 fire: 살아 있는 개인 소유자 슬롯 순서→전역 훅·인자·누락 훅. 합성 callback의 경계 직접 대조이며, 모든 실제 개인/장비 훅 조합 등가로 전파하지 않음.'),
    'P1721': ('control', 'hook_dispatch', 'combat_hooks_r23.gd', 'func chain(',
              '384개 dispatch 묶음 중 chain: nil 유지·false/0 채택·다중 소유자 값 전파·SKON 일시 억제/복구. 실제 모든 strike 훅 연결은 P1746/P1811/P1812에 남김.'),
    'P1722': ('control', 'hook_dispatch', 'combat_hooks_r23.gd', 'func chain_at',
              '384개 dispatch 묶음 중 chain_at: 지정 인자 위치 교체·후속 소유자 전달·nil/false/0·전역 호출·SKON 복구. 함수 callback 경계 비교.'),
    'P3492': ('control', 'act_control', 'combat_controls_r23.gd', 'static func act(',
              '1216개 B.act 제어 함수의 상태 전체와 begin/player/run/restart 호출열. reset/qid·over·item menu 닫기·cancel·손상 arg·pend/pid·enemy/ally 대상·자기 지정 제한. 엔진 primitives는 spy 경계이며 UI 행동 패널 전체는 P2353에 남김.'),
    'P2115': ('core', 'bargut', 'personal_rules_r22.gd', "'bargut':",
              '48개 실제 native 기술: 빠름/느림/동률·사망·보스·amb opt·성공/실패 원문·공격 본문/특성·필드 이력/시각·RNG. 일반 native 피해 및 SourceAttack 경로 연결.'),
    'P2280': ('core', 'extra_hit', 'trait_rules_r22.gd', 'static func extra_hit',
              '192개 extra/사망/처치·암살자/장비 확률·RNG 및 재귀 공격에 넘기는 일반 opt/시각의 직접 함수 대조. 재귀 B.attack은 호출 경계로 관찰; 실제 native hit_after 연결과 기존 6320판 유지.'),
    'P1674': ('core', 'persona', 'persona_combat_r22.gd', 'static func run(',
              '772개 실제 native 페르소나 실행: prefix/suffix·수준0/3/10·지원 사망 대상·컷인·공격/지원 원문·res/abyss list·필드 시간·로그·T·RNG. regen 생성 행동은 기존 effect.order로 저장.'),
    'P2220': ('damaged', 'damaged', 'personal_rules_r22.gd', 'static func damaged_dispatch',
              '992개 실제 native damaged dispatch: 31 소유자/순서·중복 CID와 별도 UID·Sorel 25% HP/2회 경계·회복 필드/시간/원문·시전자 사망 red/red20·죽은 Adeline areg 제거. callback wrapper 전체 반환과 상태 직접 대조.'),
    'P3331': ('items', 'cur_i', 'combat_items_r23.gd', 'static func current_actor',
              '7개 현재 행동자: 1~4, 없음·적 슬롯·0. native current_id와 원본 cur 슬롯의 관찰 대응.'),
    'P3332': ('items', 'item_apply', 'combat_items_r23.gd', 'static func apply(',
              '2220개 실제 native 효과와 actor 장비 보호막 배율·HP/MP/부활/붕대·로그/사건/필드 시각·T. 유효/무효 대상 1540개도 함께 비교. 붕대가 source regen/침묵/x 효과를 보존하도록 수정.'),
    'P3337': ('items', 'item_name', 'combat_items_r23.gd', 'static func item_name',
              '17개 이름/fallback 직접 반환. 성적 아이템을 제외한 원본 목록·알 수 없는 id·누락 이름 처리.'),
    'P3338': ('items', 'item_button', 'combat_items_r23.gd', 'static func button(',
              '14개 원본 버튼의 의미상 정보·무재고/활성 조건·행동과 한영 문구. native root control의 disabled 및 실제 메뉴 진입 회귀 포함.'),
    'P3340': ('items', 'item_menu', 'combat_items_r23.gd', 'static func menu(',
              '1452개 한영 원본 HTML의 의미상 제목/힌트·버튼 순서·선택/비활성·수량·이름·설명·대상 불가 이유 직접 대조. native 실제 item rows는 동일 API 사용; 20화면 검사.'),
    'P3344': ('handlers', 'item_handler', 'combat_controls_r23.gd', 'static func item(',
              '960개 원본 H.it 프로토콜 상태·소지품·actor/skill·begin/apply/end/run/send/save 호출 순서. 실제 eligibility API와 callback spy 경계, 효과는 별도2220개. native menu/pick/cancel 저장 재개와 실제 cloud 왕복10개를 함께 확인. RisuAI send는 호스트 경계.'),
}

partial = {
    'P1811': ('core', 'enemy_attack', 'dungeon_enemy_r21.gd', 'func attack_action',
              '기존256+추가16개 단일/전체 공격 기록에서 치명 taunt 원문/시간을 수정. 여러 개인/장비 반격 훅을 섞은 모든 사건·반환·시간 순서 직접 대조는 남음.'),
    'P1813': ('enemyturn', 'enemy_turn', 'dungeon_enemy_r21.gd', 'func source_enemy_turn',
              '100종 각 행동·건강/손상652개 조합 편성의 차례 전체 상태·사건·로그·다음 RNG 직접 일치. fl 없는 옛 고정 적 차례 전체와 다중 개인/장비 훅 혼합 직접 대조는 남음.'),
}
fixed = {'P1539', 'P1542', 'P1616', 'P1619', 'P1720', 'P1721', 'P1722', 'P3492',
         'P2115', 'P2280', 'P1674', 'P2220', 'P1811', 'P1813',
         'P3332', 'P3337', 'P3338', 'P3340', 'P3344'}
item_ids = {'P3331', 'P3332', 'P3337', 'P3338', 'P3340', 'P3344'}
expe = {r['id']: r for r in read(O / 'expe.json')['rows'] if r['id'] in item_ids}
assert set(expe) == item_ids and not (item_ids & {r['id'] for r in prior['rows']})
rows = copy.deepcopy(prior['rows']) + [copy.deepcopy(expe[id]) for id in sorted(item_ids)]
audit = read(R.parent / 'r21-parity/verification/parity-r21/audit-r22b.json')
original = {r['id']: r for g in audit['remaining_work'] for r in g['items']}
assert all(r['id'] in original and r['source'] == original[r['id']]['source'] for r in rows)
for r in rows:
    id = r['id']
    r['round8_status'] = r['status']
    if id in item_ids:
        r.update(transfer='expe 이관', transfer_from='verification/parity-r23/expe.json',
                 transfer_previous_status=r['status'], feature_group='전투 보급품 (expe 이관)')
        r['transfer_previous_remaining_reason'] = r.get('remaining_reason')
    if id in cov:
        r['branch_coverage'] = cov[id]
    if id in mapping or id in partial:
        pack, op, file, symbol, contract = (mapping | partial)[id]
        p = packs[pack]
        if id in mapping:
            r.update(status=SAME, remaining_reason=None, unverified_branches=[])
            if id in cov:
                assert cov[id]['called'] and not cov[id]['remaining_entries'], id
        else:
            r.update(status=PARTIAL, remaining_reason=contract)
        r['native_evidence'] = reference('project/game/' + file, symbol)
        r['round9_comparison_boundary'] = ('source-shaped API / callback boundary; parent integration remains separately unverified'
                                             if id in {'P1539', 'P1616', 'P1619', 'P1720', 'P1721', 'P1722', 'P3492', 'P3344'}
                                             else 'native implementation observed through the source normalization adapter')
        r.setdefault('new_evidence', []).append({
            'test': p['test'], 'labels': ['round9/' + op], 'checks': p['counts'][op],
            'contract': contract, 'oracle': p['oracle'], 'observations': p['observations'],
            'log': (S / (p['test'] + '.log')).relative_to(R).as_posix()})
    if id in fixed:
        r['fixed'] = True
        r['round9_fix'] = '직접 함수 포트 또는 native 실행의 기록/시각/순서/아이템/초기 stats 보완. 새 API 부재를 수치 버그 건수로 세지 않음.'
        r['fix'] = (r.get('fix') + ' / ' if r.get('fix') else '') + r['round9_fix']
    if r.get('native_evidence'):
        ref = r['native_evidence']
        r['native_evidence'] = reference(ref['file'], ref['symbol'])
    if r['status'] != SAME and id in cov:
        r['unverified_branches'] = cov[id]['remaining_baseline']
    r['round9_status'] = r['status']

# These rows already have complete directly compared non-host state contracts.
# Their sole remaining reason was RisuAI AI prompt/chat transport, explicitly
# excluded by r21-common.md. Do not count the reused checks as new tests.
host_audit = read(O / 'battle-round9-host-contract.json')
assert host_audit['checks_reused'] == 16038 and host_audit['save_inputs'] == 594
host_equal = {'P1688', 'P1692'}
assert set(host_audit['ids']) == host_equal
assert all(sha(Path('C:/Clauede Code/dungeon-bot/bot/src') / name) == digest
           for name, digest in host_audit['source_sha256'].items())
research_actual = read(O / 'battle-round8-persona-latest.json')
assert research_actual['checks'] == 16038 and not research_actual['failures']
for r in rows:
    if r['id'] not in host_equal:
        continue
    r['round8_remaining_reason'] = r.get('remaining_reason')
    r.update(status=SAME, round9_status=SAME, remaining_reason=None, unverified_branches=[])
    r['native_evidence'] = reference('project/game/persona_research_r21.gd', 'static func transition')
    r['round9_comparison_boundary'] = 'Direct game-state and message contract; RisuAI-only AI dialogue transport excluded by common rules'
    r['host_only_excluded'] = host_audit['excluded_host_calls']
    r.setdefault('new_evidence', []).append({
        'test': 'battle_r23_round8_persona_test', 'checks_reused': 16038,
        'save_inputs': 594, 'successful_saves': 256,
        'contract': '저장 skill·draft/spent 제거·gold·ready/dirty/busy·한영 문구 직접 일치. 유일한 잔여였던 RisuAI pending AI 프롬프트/채팅 삽입은 공통 규칙에 따라 호스트 제외.',
        'host_contract': 'verification/parity-r23/battle-round9-host-contract.json',
        'oracle': 'verification/parity-r23/battle-round8-persona-oracle.json',
        'observations': 'verification/parity-r23/battle-round8-persona-latest.json',
        'log': (S / 'battle_r23_round8_persona_test.log').relative_to(R).as_posix()})

# Source-only experiments enter missing branches but are never equality evidence.
source_only_links = {'P1553', 'P1587', 'P1589', 'P1594', 'P1595', 'P1620', 'P1831', 'P1682'}
for r in rows:
    if r['id'] in source_only_links:
        source_file = 'battle-round9-control-source-observations.json' if r['id'] in ['P1831', 'P1682'] else 'battle-round9-start-source-observations.json'
        r['round9_source_only_observation'] = 'verification/parity-r23/' + source_file
        r['round9_source_only_is_equality_evidence'] = False

equal = sum(r['status'] == SAME for r in rows)
excluded = sum(r['status'] == EXCLUDED for r in rows)
remaining = len(rows) - equal - excluded
assert (len(rows), equal, excluded, remaining) == (218, 199, 3, 16)
assert Counter(r['status'] for r in rows) == {SAME: 199, EXCLUDED: 3, PARTIAL: 12, UNKNOWN: 4}
old_fixed = {r['id'] for r in prior['rows'] if r['fixed']} | {id for id, r in expe.items() if r['fixed']}
products = ['project/game/' + n + '.gd' for n in [
    'battle_source_state_r23', 'battle_stats_r23', 'battle_v3', 'combat_attack_r23',
    'combat_controls_r23', 'combat_events_r22', 'combat_hooks_r23', 'combat_item_data_r23',
    'combat_items_r23', 'combat_party_r23', 'dungeon_enemy_r21', 'persona_combat_r22',
    'persona_world', 'personal_rules_r22', 'trait_rules_r22']] + ['project/ui/battle_screen.gd']
new_tools = sorted(p.relative_to(R).as_posix() for folder in ['tools', 'project/tests']
                   for p in (R / folder).glob('*') if p.is_file() and
                   ('round9' in p.name or p.name in ['coverage_battle_r23.py', 'sync_combat_items_r23.py',
                                                   'run_battle_r23.py', 'godot_r17.py',
                                                   'enemy_review_r21_test.gd']) and
                   p.suffix in ['.py', '.mjs', '.lua', '.gd'])
summary = {**prior['summary'], 'rows_reviewed': len(rows), 'newly_equal_rows': equal,
           'statuses': dict(Counter(r['status'] for r in rows)), 'remaining_rows': remaining,
           'excluded_rows': excluded, 'round9_newly_equal_rows': len(mapping) + len(host_equal),
           'round9_base_newly_equal_rows': len(mapping) + len(host_equal) - len(item_ids),
           'round9_imported_rows': len(item_ids), 'round9_fixed_evidence_rows': len(fixed),
           'round9_new_fixed_rows': len(fixed - old_fixed), 'fixed_rows': sum(r['fixed'] for r in rows),
           'fixed_and_equal_overlap': sum(r['fixed'] and r['status'] == SAME for r in rows),
           'fixed_but_not_equal_rows': sum(r['fixed'] and r['status'] not in [SAME, EXCLUDED] for r in rows),
           'neither_equal_nor_fixed_rows': sum(not r['fixed'] and r['status'] not in [SAME, EXCLUDED] for r in rows),
           'round9_checks': checks, 'round9_source_checks': source_checks,
           'round9_ui_checks': ui['checks'], 'round9_cloud_checks': cloud['checks'],
           'new_checks': prior['summary']['new_checks'] + checks, 'new_failures': 0,
           'called_functions': coverage['called_functions'], 'fresh_oracle_runs': len(coverage['runs']),
           'newly_entered_baseline_entries': 157, 'suite_groups': len(suite),
           'expected_suite_groups': len(expected), 'suite_failed_groups': 0, 'suite_missing': [],
           'suite_in_progress': [], 'suite_final_code_complete': True,
           'suite_verification_method': 'Fresh complete ' + S.name + '; final product, tests and source inputs stayed locked. Superseded runs are not combined.',
           'parity_battles': battles, 'parity_records': records, 'protected': protected,
           'round9_product_files_changed': products,
           'product_files_changed': sorted(set(prior['summary']['product_files_changed'] + products))}
assert (summary['fixed_rows'], summary['round9_new_fixed_rows']) == (90, 16)

before = read(O / 'battle-round9-core-before-replay.json')
assert before['checks'] == 1028 and len(before['failures']) == 1013
before_counts = Counter(r['label'].split('/')[1] for r in before['rows'] if not r['ok'])
assert dict(before_counts) == {'bargut': 48, 'persona': 772, 'extra_hit': 192, 'enemy_attack': 1}
preserve_before = read(O / 'battle-round9-items-preserve-before.json')
assert len(preserve_before['failures']) == 96
assert read(O / 'battle-round9-preserve-before-code.json')['matches']
assert len(read(O / 'battle-round9-start-mirror-before.json')['failures']) == 2
round9 = {'new_equal_ids': sorted(set(mapping) | host_equal), 'fixed_evidence_ids': sorted(fixed),
          'host_scope_reassessed_ids': sorted(host_equal),
          'transferred_ids': sorted(item_ids), 'transfer_note': 'expe 이관',
          'checks': checks, 'source_checks': source_checks, 'packs': packs, 'suite': S.name,
          'core_before_replay': {'checks': 1028, 'different_observations': 821,
                                 'api_unavailable_guards': 192, 'by_operation': dict(before_counts)},
          'preserve_before_differences': 96, 'legacy_level_before_differences': 2,
          'limits': '함수별 source-shaped 커널/프로토콜 경계와 실제 native 경로를 행마다 구분. source-only 관측은 같음 근거 아님. 부모 시작/저장/혼합 공격/연구 화면/전투 화면16행 남음.'}
write(O / 'battle.json', {**prior, 'scope': 'r22b remaining_work 전투 7묶음 + expe 이관 전투 보급품6행',
                        'summary': summary, 'rows': rows, 'round9': round9,
                        'test_tool_files': sorted(set(prior.get('test_tool_files', []) + new_tools)),
                        'target_tests': prior['target_tests'] +
                        [{'name': 'battle-round9-' + n, 'checks': p['checks'], 'failures': 0} for n, p in packs.items()] +
                        [{'name': 'battle-round9-ui', 'checks': ui['checks'], 'failures': 0},
                         {'name': 'battle-round9-cloud', 'checks': cloud['checks'], 'failures': 0}]})
write(O / 'summary.json', summary)
write(O / 'battle-round9-report-summary.json', summary)
write(S / 'final-verification.json', {'passed': True, 'groups': len(suite), 'battles': battles,
                                     'records': records, 'assets': 96, 'protected_verified': True,
                                     'code_locked': True, 'source_inputs_locked': True})

lines = ['# R23-battle 9차 보고', '',
         '전투 218행(기존212 + expe 이관6): 같음199·호스트 제외3·남음16(일부12/미확인4). 기존 전투14행을 같음으로 올리고 이관6행도 같음으로 처리했다. 기존 남음30→16. 전 기능 완료는 아니다.', '',
         f'신규 검사 {checks:,}개 실패0: 원본 Lua 직접 대조 {source_checks:,}, native 화면/재개 {ui["checks"]:,}, 실제 로컬 클라우드 {cloud["checks"]}개. 누적 신규 검사 {summary["new_checks"]:,}개. 전체 프로젝트 {len(suite)}/{len(expected)}그룹(import 포함) 실패0. 기존6320판·219785기록 차이0.', '',
         '원본 Lua19개를 함수/then/else/do 진입 Boolean으로 계측하고37묶음을 새로 실행했다. 계측 전후 oracle 출력과 보존6320판 원본 trace가 같았다. 함수209/212 호출(나머지3은 기존 호스트 제외), 기준 미도달 진입157/157 도달(8차142). 진입 도달은 조건 조합 전수나 native 전체 등가 증명이 아니다. coverage/에는 전체 oracle 중복 사본 없음.', '',
         '직접 대조: Bargut48, persona772, extra_hit192, 단일/전체 적 공격16, 아이템5250, blank_unit1056·비율56, dispatch384·act1216, item handler960, 편성204·의뢰189, 적 차례652, damaged992개. 아이템5250에는 효과2220·대상1540·메뉴1452·버튼14·행동자7·이름17이 포함된다.', '',
         '실제 전투에는 Bargut 성공/실패·persona 컷인/공격/지원·추가 타격의 원문·필드·사건 순서를 보완했다. 치명 taunt 로그가 맞은 뒤 사라지던 차이도 수정했다. Sorel의 피격 회복은 살아 있는 개인 소유자 순서,25% HP/2회 제한,원본 회복 시각·로그를 따르며 시전자 사망 효과 정리도 연결했다.', '',
         '아이템은 정본 순서·이름·설명·무재고/대상 불가·현재 행동자 장비 배율을 사용한다. 붕대가 유지해야 하는 침묵·재생·x 효과까지 지우던 차이를 수정했다. 메뉴와 선택 아이템을 기존 selected_action으로 저장하여 다시 연다. persona regen의 생성 행동은 기존 effect.order로 보존한다. 저장 스키마나 서버를 늘리지 않고 /v1/account→/v1/save 실제 왕복을 확인했다.', '',
         '같음은 행에 적은 함수 계약의 직접 대조 범위다. CombatHooks·CombatControls·CombatParty는 source-shaped 함수 API이며 일부 callback은 spy로 호출 경계를 관찰했다. 해당 API가 native의 모든 상위 호출자를 대체했다고 주장하지 않는다. blank_unit도 원본 모양 경계 비교다. 새 커널의 증거를 fresh/battle_start/run/strike/행동 패널 같은 부모 행으로 전파하지 않았다. 이관 H.it은 프로토콜960개, 별도 실제 효과2220개와 실제 화면 저장 재개·클라우드 왕복을 함께 근거로 삼았다.', '',
         '수정 근거19행(기존 중복 포함), 신규 수정 근거16행, 누적90행. 함수 포트·누락 API 보완도 포함하며 숫자 버그16개라는 뜻은 아니다. 원래 모듈8개를 보존하고 최종 core1028입력으로 재생하니 관찰 차이821개(Bargut48/persona772/적 공격1)와 extra_hit API 부재 guard192개였다. 전체 옛 빌드를 재현한 수치는 아니다. 별도로 실제 실행한 붕대 보존96개 실패 및 옛 G.lv fallback2개 실패가 수정 뒤 통과했다. 붕대 수정 전 파일 SHA는 중간 lock과 일치한다.', '',
         '초기 새 시험의 중복 character ID를 UID로 쓰던 fixture를 분리해 source와 같은 입력을 옮겼다. 클라우드 fixture는 금지 stats.crit 키를 제거하고 JSON 정수/실수의 수치 비교를 사용했다. 기대값을 바꾸거나 실패 사례를 버리지 않았다. 아이템 행동의 per-action RNG 재시드는 기존6320판 회귀가 보여 준 필요 조건대로 유지했다. v1은 붕대 경계 추가로 폐기했고, v2의 기존 battle_r23_test는 이름 없는 persona_skill 객체를 넘겨 새 기록 경로에서 오류를 냈다. 정본 기술 정의에서 누락 이름을 구하도록 제품을 고쳐 해당 시험과1028개 core를 재통과했다. 보급품 제목/안내/버튼도 의미 API에 연결한 뒤 v3 전체를 처음부터 실행했다. v2의 A8대조는4864판까지 차이0에서900초 제한으로 종료되어,5120판 시험의 시간 제한만1800초로 늘렸다. 최종 제품/시험/입력과 실행기 SHA 불변, 중간 실패·취소 실행을 최종 통과 수에 섞지 않았다.', '',
         '| 묶음 | 같음 | 제외 | 남음 |', '| --- | ---: | ---: | ---: |']
for name in sorted({r['feature_group'] for r in rows}):
    rs = [r for r in rows if r['feature_group'] == name]
    lines.append(f'| {name} | {sum(r["status"] == SAME for r in rs)} | {sum(r["status"] == EXCLUDED for r in rs)} | {sum(r["status"] not in [SAME, EXCLUDED] for r in rs)} |')
lines += ['', '같음 승격: ' + ', '.join(sorted(set(mapping) | host_equal)) + '.', '',
          '연구 저장 P1688/P1692는 공통 규칙의 호스트 제외 기준으로 재판정했다. 상태·금화·ready/dirty/busy·한영 문구 16038개(저장594입력/성공256)는 직접 비교했다. 남겨 두었던 B.pend_busy/getChatLength와 B.pend_hard/addChat 및 AI 반응 프롬프트는 RisuAI 전용이다(01-game.lua:204/222,29-persona-skill.lua:215). 이 호스트 부분을 게임 상태 미구현과 혼동하지 않는다. 기존 검사를 재사용했으므로 신규 검사 수에는 더하지 않았다. 근거: battle-round9-host-contract.json.', '',
          '남은16행과 구체적인 이유:', '']
for r in rows:
    if r['status'] not in [SAME, EXCLUDED]:
        lines.append(f'- {r["id"]} {r["source_symbol"]}: {r["remaining_reason"]}')
lines += ['', 'fresh/retry/redo/save/load/battle_start와 run·연구 화면의 새 원본 경계는 source-only 파일에 관측했다. Godot 직접 결과가 없는 관측을 같음으로 세지 않았다. 특히 저장/원정 출처/연구 대화의 실제 연계는 일부 소관 밖 파일이지만, 금지된 원정·시설·서버를 수정하지 않고 남은 이유를 보존했다.', '',
          '9차 재개 검증: v3의 combat_p3_r22_test와 enemy_review_r21_test에서 빈 기록 객체의 ev 접근 오류를 확인했다. 중단 직전 추가된 ensure_record 경로로 오류가 사라졌다. 이어 소렐 2건은 Lua의 cs=100에 대응하는 native fixture의 line이 맞지 않아 실패했다. 제품 산식과 원본 기대값은 유지하고 시험 입력의 line을 int로 맞춘 뒤 497개가 통과했다. 84736개 개인 기술 검사와 새 core1028·damaged992개도 통과했다. 이후 최종 v4 전체 검사를 새로 실행했다. 최종 수치는 v4 단일 실행만 사용한다.', '',
          'Windows root certificate store 진단만 기존 실행기의 환경 메시지 예외로 처리한다. SCRIPT ERROR와 그 밖의 ERROR는 종료 코드가 0이어도 실패로 센다. 원본 기대값은 변경하지 않았다.', '',
          '렌더는 한영5크기20장을 생성하고 그중4장을 직접 열었다. 보급품 제목/안내·원문·불가 이유·수량·선택 강조·MP 표시를 확인했다. 작은 높이에서 목록은 기존처럼 스크롤되고 영어 적 이름 일부는 기존 말줄임이 남는다. 영어 화면의 기존 차례 제목과 미선택 확인 버튼 일부는 한국어다. 이번 아이템 의미 API의 한영 문자열 대조와 전체 화면 번역 완료는 구분한다. 실기기/Web/WASM·전수 프레임은 확인하지 않았다. 확인 파일·SHA·관찰은 battle-round9-visual-review.json.', '',
          '원본 이미지96개 해시 일치, docs249/assets1784/server30개 해시 및 파일 목록 불변. 사용자 저장을 열거나 지우지 않았고 Web export/버전 갱신 없음. 재개 지시가 명시한 git status/diff만 읽기 전용으로 사용했다. dubious ownership은 명령별 safe.directory로 처리했으며 전역 설정이나 저장소 상태를 바꾸는 git 명령은 실행하지 않았다. 새 비교 파일은 battle- 접두이며 각40MB 미만이다. coverage/에 남아 있던 옛 oracle 사본23개는 provenance를 제외한 전체 JSON이 정본과 같음을 확인한 뒤 정리했다(218593871바이트). 완료된 격리 시험 폴더는 경로 검증 후 정리하며 기본 runtime은 남긴다.', '',
          '행별 원본 id·위치·이전 상태·새 시험·제품 파일:줄·범위·남은 이유: verification/parity-r23/battle.json. expe.json은 수정하지 않고6행 원문/이력을 복사하여 expe 이관을 표시했다.', '',
          '재실행: oracle_battle_r23_round9_loader.mjs (R23_ROUND9_PACK=core/items/state/control/handlers/start/enemyturn/damaged) → coverage_battle_r23.py → verify_battle_r23_round9.py (R23_FINAL_SUITE=suite-round9-final-v4) → prepare_battle_r23_round9_before.py 및 보존 모듈 재생 → 렌더 확인 → report_battle_r23_round9.py.', '',
          '이번 제품 파일:', '', *['- ' + p for p in products], '', '이번 시험/도구:', '', *['- ' + p for p in new_tools]]
if not (R / 'R23-battle-round8.md').exists():
    (R / 'R23-battle-round8.md').write_bytes((O / 'battle-round9-before/battle-prior-report.md').read_bytes())
(R / 'R23-battle.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
(R / 'R23-battle-round9.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(json.dumps({k: summary[k] for k in ['rows_reviewed', 'newly_equal_rows', 'excluded_rows',
      'remaining_rows', 'round9_checks', 'round9_source_checks', 'fixed_rows', 'suite_groups',
      'parity_battles', 'parity_records']}, ensure_ascii=False))
