"""Resolve reviewed edits against actual draft fields; reject nonexistent quotes."""
from dialogue_r21_build import ROOT, read_json, write_json, section_rows, display_fields
from dialogue_r21_round4 import NEW_IDS, OUT

def main():
    result=[]
    for cid,row in section_rows(ROOT/'tools/dialogue_r21_4_edit.txt'):
        assert cid in NEW_IDS and len(row) in [3,4],(cid,row)
        before,after,reason,*path=row
        draft=read_json(OUT/'draft4'/f'{cid}.json')
        matches=[p for p,t,_ in display_fields(draft) if t==before and (not path or p==path[0])]
        assert len(matches)==1,(cid,before,matches)
        assert before!=after and len(after)<=64
        result.append(dict(character_id=cid,path=matches[0],before=before,after=after,reason=reason))
    keys=[(e['character_id'],e['path']) for e in result]
    assert len(set(keys))==len(keys),'duplicate edit target'
    assert all(sum(e['character_id']==cid for e in result)>=10 for cid in NEW_IDS)
    write_json(ROOT/'tools/dialogue_r21_4_edits.json',result)
    print('actual edits',len(result))

if __name__=='__main__':main()
