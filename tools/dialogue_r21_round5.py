"""Replay the fifth-pass, path-specific editorial patch over frozen round four."""
from collections import Counter
from copy import deepcopy
import hashlib
from dialogue_r21_build import ROOT, OUT, IDS, read_json, write_json, replace_at, display_fields, lexicon, mentioned_names


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def at(data, path):
    for key in path.split('/'):
        data = data[int(key)] if isinstance(data, list) else data[key]
    return data


def leaves(data, path=''):
    if isinstance(data, dict):
        for key, value in data.items():
            yield from leaves(value, path+'/'+key if path else key)
    elif isinstance(data, list):
        for i, value in enumerate(data):
            yield from leaves(value, path+'/'+str(i))
    else:
        yield path, data


def structural(data):
    """Exclude only prose editable in this pass and the derived name inventory."""
    d = deepcopy(data)
    for path, _, _ in display_fields(d):
        replace_at(d, path, '<text>')
    for s in d['inn']:
        for c in s['choices']:
            c['reason'] = '<reason>'
    d['proper_nouns'] = []
    return d


def build():
    edits = read_json(OUT/'edits5-applied.json')
    base = read_json(OUT/'baseline5.json')
    dictionary = lexicon()
    seen = set()
    counts = Counter()
    for cid in IDS:
        source = OUT/f'draft5/{cid}.json'
        assert digest(source) == base['historical'][str(source.relative_to(ROOT))], cid
        d = read_json(source)
        for e in edits:
            if e['character_id'] != cid:
                continue
            key = (cid, e['path'])
            assert key not in seen, key
            seen.add(key)
            assert at(d, e['path']) == e['before'], key
            replace_at(d, e['path'], e['after'])
            counts[cid] += 1
        d['proper_nouns'] = sorted(mentioned_names('\n'.join(t for _, t, _ in display_fields(d)), dictionary))
        assert structural(d) == structural(read_json(source)), cid
        write_json(ROOT/f'project/data/dialogue-r21/{cid}.json', d)
    assert len(seen) == len(edits)
    print('round5 characters', len(IDS), 'edited fields', sum(counts.values()))


if __name__ == '__main__':
    build()
