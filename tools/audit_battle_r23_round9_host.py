"""Separate the research state contract from explicitly excluded RisuAI calls."""
from pathlib import Path
from collections import Counter
import hashlib
import json

root = Path(__file__).resolve().parents[1]
out = root / 'verification/parity-r23'
source = Path('C:/Clauede Code/dungeon-bot/bot/src')
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
manifest = read(out / 'battle-round8-persona-oracle.json')
actual = read(out / 'battle-round8-persona-latest.json')
assert actual['checks'] == 16038 and not actual['failures']
assert all(r['ok'] for r in actual['rows'])
counts = Counter()
successful_saves = 0
for part in manifest['parts']:
    path = out / part['file']
    assert sha(path) == part['sha256']
    for row in read(path)['rows']:
        counts[row['input']['arg']] += 1
        if row['input']['arg'] == 'ps_save' and row.get('host_pending'):
            successful_saves += 1
            assert row['expected']['draft'] == {} and row['expected']['spent'] == 0
            assert row['host_pending'].startswith('[Persona skill confirmed]')
for name, digest in manifest['provenance'].items():
    assert sha(source / name) == digest
game = (source / '01-game.lua').read_text(encoding='utf-8').splitlines()
research = (source / '29-persona-skill.lua').read_text(encoding='utf-8').splitlines()
assert 'getChatLength' in '\n'.join(game[203:209])
assert 'addChat' in '\n'.join(game[221:231])
assert 'B.pend_hard' in '\n'.join(research[214:227])
result = {
    'rule': 'r21-common.md: RisuAI chat, AI calls and lorebook host-only behavior excluded',
    'ids': ['P1688', 'P1692'], 'checks_reused': actual['checks'],
    'save_inputs': counts['ps_save'], 'successful_saves': successful_saves,
    'source_contract': 'saved skill, draft/spent deletion, gold, ready/dirty/busy decisions and Korean/English message',
    'excluded_host_calls': [
        {'file': 'bot/src/01-game.lua', 'symbol': 'B.pend_busy', 'line': 204,
         'reason': 'RisuAI getChatLength gates an outstanding AI conversation'},
        {'file': 'bot/src/01-game.lua', 'symbol': 'B.pend_hard', 'line': 222,
         'reason': 'Only sets AI prompt bookkeeping and invokes RisuAI addChat'},
        {'file': 'bot/src/29-persona-skill.lua', 'symbol': 'save', 'line': 215,
         'reason': 'AI reaction prompt and user chat injection excluded; game state and messages directly compared'}],
    'oracle': 'verification/parity-r23/battle-round8-persona-oracle.json',
    'actual': 'verification/parity-r23/battle-round8-persona-latest.json',
    'source_sha256': {name: sha(source / name) for name in ['01-game.lua', '29-persona-skill.lua']},
    'limits': 'No native AI dialogue equivalence claimed. No new runtime checks added to the total.'}
(out / 'battle-round9-host-contract.json').write_text(
    json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'checks_reused': actual['checks'], 'save_inputs': counts['ps_save'],
                  'successful_saves': successful_saves}))
