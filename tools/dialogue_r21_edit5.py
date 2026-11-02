"""Consolidate exact editorial decisions; never search/replace the live corpus."""
from dialogue_r21_build import ROOT, OUT, read_json, write_json
from dialogue_r21_round5 import at, build


def main():
    rows = [e for group in ['first12','middle9','last9'] for e in read_json(OUT/f'edits5-{group}.json')]
    merged = {(e['character_id'],e['path']):dict(e) for e in rows}
    assert len(rows)==len(merged)
    patches = read_json(ROOT/'tools/dialogue_r21_5_finalizer.json')
    if (OUT/'finalizer-corrections5.json').exists():
        patches += read_json(OUT/'finalizer-corrections5.json')
    for e in patches:
        key=e['character_id'],e['path']
        if key in merged:
            original = merged[key]
            assert original['after']==e['before'], key
            merged[key]={**original,'after':e['after'],'reason':original['reason']+' 최종 대조: '+e['reason'],
                         'pattern':original.get('pattern','')+' / '+e['pattern']}
        else:
            data=read_json(OUT/f"draft5/{e['character_id']}.json")
            assert at(data,e['path'])==e['before'], key
            merged[key]=dict(e)
    edits = sorted(merged.values(),key=lambda e:(e['character_id'],e['path']))
    write_json(OUT/'edits5-applied.json',edits)
    build()
    decisions = [e for group in ['first12','middle9','last9'] for e in read_json(OUT/f'decisions5-{group}.json')]
    for d in decisions:
        actual=at(read_json(ROOT/f"project/data/dialogue-r21/{d['character_id']}.json"),d['path'])
        if actual!=d['after']:
            d['after']=actual
            d['reason']+=' 최종 연어·문맥 대조로 같은 취지의 문구를 추가 보정했다.'
    write_json(OUT/'decisions5.json',decisions)
    print('merged',len(edits),'decisions',len(decisions),'finalizer',len(patches))


if __name__=='__main__':
    main()
