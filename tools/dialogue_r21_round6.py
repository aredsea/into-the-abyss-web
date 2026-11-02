"""Replay only reviewed sixth-pass text fields over the frozen fifth pass."""
from dialogue_r21_build import ROOT, OUT, IDS, read_json, write_json, replace_at
from dialogue_r21_round5 import at, digest, structural


def build():
    baseline = read_json(OUT / 'baseline6.json')
    edits = read_json(OUT / 'edits6-applied.json')
    assert len({(e['character_id'], e['path']) for e in edits}) == len(edits)
    for cid in IDS:
        source = OUT / f'draft6/{cid}.json'
        assert digest(source) == baseline['data'][cid + '.json'], cid
        data = read_json(source)
        for edit in edits:
            if edit['character_id'] == cid:
                assert at(data, edit['path']) == edit['before'], edit
                replace_at(data, edit['path'], edit['after'])
        assert structural(data) == structural(read_json(source)), cid
        write_json(ROOT / f'project/data/dialogue-r21/{cid}.json', data)
    print('round6 characters', len(IDS), 'edited fields', len(edits))


if __name__ == '__main__':
    build()
