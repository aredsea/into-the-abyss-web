"""Project path-specific JSON edits into the skill's lossless text chunks."""
from dialogue_r21_build import ROOT, OUT, IDS, read_json, write_json, display_fields


def main():
    run = ROOT/'_workspace/2026-11-03-001-8495'
    source = (run/'01_input.txt').read_text(encoding='utf8')
    manifest = read_json(run/'chunk_manifest.json')
    changes = []
    for cid in IDS:
        before = dict((p,t) for p,t,_ in display_fields(read_json(OUT/f'draft5/{cid}.json')))
        after = dict((p,t) for p,t,_ in display_fields(read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')))
        assert set(before)==set(after)
        for path, old in before.items():
            if old != after[path]:
                prefix = cid+'/'+path+'\n'
                changes.append((prefix+old,prefix+after[path]))
    expected = source
    for old,new in changes:
        assert expected.count(old)==1
        expected=expected.replace(old,new,1)
    count = 0
    for chunk in manifest['chunks']:
        body = source[chunk['start']:chunk['end']]
        for old,new in changes:
            if old in body:
                assert body.count(old)==1
                body=body.replace(old,new,1)
                count+=1
        (run/chunk['rewritten_file']).write_text(body,encoding='utf8')
    assert count==len(changes), 'chunk boundary bisects an edit'
    (run/'expected-final.txt').write_text(expected,encoding='utf8')
    write_json(run/'chunk-editorial-map.json',dict(edited_fields=len(changes),chunks=manifest['body_chunk_count'],
        method='인물별 전체 문맥을 읽은 편집 결과를 원문의 경로로 청크에 투영한다. 재조립 뒤 최종 JSON 문구와 일치를 확인한다.'))
    print('humanize chunks',manifest['body_chunk_count'],'edits',len(changes))


if __name__=='__main__':
    main()
