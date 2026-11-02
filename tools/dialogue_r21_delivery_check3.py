"""Verify third-pass delivery against actual bytes and preserved prior content."""
import subprocess
import sys
from dialogue_r21_build import ROOT, CANON, IDS, read_json, write_json
from dialogue_r21_round3 import NEW_IDS, OUT, digest

def at(data,path):
    for part in path.split('/'):
        data=data[int(part)] if isinstance(data,list) else data[part]
    return data

def main():
    checks=[]
    def check(name,ok):checks.append(dict(name=name,passed=bool(ok)))
    manifest=read_json(OUT/'delivery-manifest3.json')
    before={cid:digest(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in IDS}
    run=subprocess.run([sys.executable,'tools/dialogue_r21_build.py'],cwd=ROOT,capture_output=True)
    check('offline-rebuild-exit',run.returncode==0)
    check('offline-rebuild-identical-all-21',before=={cid:digest(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in IDS})
    check('lint-input-hashes',read_json(OUT/'check3.json')['input_sha256']=={cid+'.json':h for cid,h in before.items()})
    check('nine-sample-files',len(list(OUT.glob('sample3-*.md')))==9)
    review=(OUT/'review-3.md').read_text(encoding='utf-8')
    edits=read_json(OUT/'edits3-applied.json')
    for cid in NEW_IDS:
        data=read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
        sample=(OUT/f'sample3-{cid}.md').read_text(encoding='utf-8')
        scenes=[s for s in data['inn'] if s['id'] in sample]
        check(cid+'-sample-three-stages',[s['stage'] for s in scenes]==['낯섦','유대','운명'])
        strings=[]
        for s in scenes:
            strings.extend([s['situation'],s['seen'],*s['lines']])
            for c in s['choices']:strings.extend([c['text'],c['reason'],*c['response']])
        check(cid+'-sample-final-content',all(t in sample for t in strings))
        part=review.split(f'## {IDS[cid]} · {cid}\n',1)[1].split('\n## ',1)[0]
        pair_count=sum(l.startswith('| `') for l in part.splitlines())
        check(cid+'-review-pairs',pair_count==manifest['review_pairs'][cid] and pair_count>=10)
        draft=read_json(OUT/f'draft3/{cid}.json')
        check(cid+'-edits-before-and-after',all(at(draft,e['path'])==e['before'] and at(data,e['path'])==e['after']
                                             for e in edits if e['character_id']==cid))
    for name,h in manifest['files'].items():
        p=ROOT/name;check('manifest-'+name,p.is_file() and digest(p)==h)
    base=read_json(OUT/'baseline3.json')
    check('baseline-workspace-unchanged',all((ROOT/p).is_file() and digest(ROOT/p)==h for p,h in base['workspace'].items()))
    check('canonical-sources-unchanged',all(digest(CANON/p)==h for p,h in base['canon'].items()))
    report=(ROOT/'DIALOGUE-R21.md').read_text(encoding='utf-8')
    check('report-starts-third-pass',report.startswith('# 3차\n'))
    check('historical-report-text-preserved',report.endswith((OUT/'original-report2.md').read_text(encoding='utf-8').rstrip()+'\n'))
    result={'checks':len(checks),'failures':sum(not c['passed'] for c in checks),'results':checks}
    write_json(OUT/'delivery-check3.json',result)
    print({k:v for k,v in result.items() if k!='results'})
    for c in checks:
        if not c['passed']:print('FAIL',c['name'])
    return int(bool(result['failures']))

if __name__=='__main__':raise SystemExit(main())
