"""Check final data, actual edits, samples, hashes and unchanged prior work."""
from collections import Counter
import subprocess
import sys
from dialogue_r21_build import ROOT, CANON, IDS, read_json, write_json, display_fields
from dialogue_r21_round4 import NEW_IDS, OUT, digest
from dialogue_r21_report4 import SAMPLES

def at(data,path):
    for p in path.split('/'):
        data=data[int(p)] if isinstance(data,list) else data[p]
    return data

def main():
    checks=[]
    def check(name,ok):checks.append(dict(name=name,passed=bool(ok)))
    manifest=read_json(OUT/'delivery-manifest4.json')
    before={cid+'.json':digest(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in IDS}
    p=subprocess.run([sys.executable,'-X','utf8','tools/dialogue_r21_build.py'],cwd=ROOT,capture_output=True)
    check('offline-rebuild-exit',p.returncode==0)
    check('offline-rebuild-identical-all-30',before=={cid+'.json':digest(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in IDS})
    lint=read_json(OUT/'check4.json')
    check('lint-zero-errors',lint['error_count']==0)
    check('lint-inputs-match-final-bytes',lint['input_sha256']==before)
    check('all-30-registered',len(before)==30 and set(lint['characters'])==set(IDS))
    for key,num in [('inn_scenes',840),('choices',2520),('dungeon_variants',2520),('transition_scenes',420)]:
        check('total-'+key,sum(m[key] for m in lint['characters'].values())==num)
    check('nine-sample-files',len(list(OUT.glob('sample4-*.md')))==9)
    review=(OUT/'review-4.md').read_text(encoding='utf-8')
    edits=read_json(OUT/'edits4-applied.json')
    check('applied-edit-count',len(edits)==manifest['editorial_records'])
    for cid in NEW_IDS:
        data=read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
        draft=read_json(OUT/f'draft4/{cid}.json')
        sample=(OUT/f'sample4-{cid}.md').read_text(encoding='utf-8')
        scenes=[data['inn'][i] for i in SAMPLES[cid]]
        check(cid+'-sample-stages',[s['stage'] for s in scenes]==['낯섦','유대','운명'])
        strings=[]
        for scene in scenes:
            strings.extend([scene['id'],scene['situation'],scene['seen'],*scene['lines']])
            for c in scene['choices']:strings.extend([c['text'],c['reason'],*c['response']])
        check(cid+'-sample-final-text',all(t in sample for t in strings))
        local=[e for e in edits if e['character_id']==cid]
        check(cid+'-at-least-ten-actual-edits',len(local)==manifest['review_pairs'][cid] and len(local)>=10)
        check(cid+'-before-after-evidence',all(at(draft,e['path'])==e['before'] and at(data,e['path'])==e['after'] for e in local))
        part=review.split(f'## {IDS[cid]} · {cid}\n',1)[1].split('\n## ',1)[0]
        check(cid+'-review-shows-every-edit',sum(l.startswith('| `') for l in part.splitlines())==len(local)
            and all(e['before'] in part and e['after'] in part for e in local))
        counts=Counter(s['stage'] for s in data['inn'])
        check(cid+'-per-stage-counts',list(counts.values())==[2,2,4,4,4,4,4,4])
        check(cid+'-all-opening-three-lines',all(len(s['lines'])==3 for s in data['inn']))
        check(cid+'-all-transition-two-lines',all(len(s['lines'])==2 for s in data['transitions']))
        check(cid+'-choice-reasons-full-sentences',all(len(c['reason'])>=8 and c['reason'].endswith('.') for s in data['inn'] for c in s['choices']))
        check(cid+'-choice-values',all(sorted(c['aff'] for c in s['choices'])==[-2,0,2] for s in data['inn']))
        check(cid+'-choice-order-varies',len({tuple(c['aff'] for c in s['choices']) for s in data['inn']})==3)
    baseline=read_json(OUT/'baseline4.json')
    check('baseline-workspace-unchanged',all((ROOT/p).is_file() and digest(ROOT/p)==h for p,h in baseline['workspace'].items()))
    old={p:h for p,h in baseline['workspace'].items() if 'data/dialogue-r21' in p.replace('\\','/')}
    check('all-21-old-characters-unchanged',len(old)==21 and all(digest(ROOT/p)==h for p,h in old.items()))
    reviews={p:h for p,h in baseline['workspace'].items() if 'kreview' in p}
    check('all-initial-independent-reviews-unchanged',bool(reviews) and all(digest(ROOT/p)==h for p,h in reviews.items()))
    observed=read_json(OUT/'independent-reviews-observed4.json')
    check('observed-independent-reviews-unchanged',all((ROOT/p).is_file() and digest(ROOT/p)==h for p,h in observed.items()))
    check('canonical-baseline-unchanged',all(digest(CANON/p)==h for p,h in baseline['canon'].items()))
    check('canonical-complete-inventory-unchanged',all(digest(CANON/s['file'])==s['sha256'] for s in read_json(OUT/'source-manifest4.json')))
    report=(ROOT/'DIALOGUE-R21.md').read_bytes()
    check('report-fourth-pass-first',report.startswith('# 4차\n'.encode('utf-8')))
    check('historical-report-byte-suffix-preserved',report.endswith((OUT/'original-report3.md').read_bytes()))
    for p,h in manifest['files'].items():
        check('manifest-'+p,(ROOT/p).is_file() and digest(ROOT/p)==h)
    check('line-inventory-final',len(read_json(OUT/'review-lines4.json')['records'])==manifest['new_counts']['display_lines'])
    for name in ['selftest4.json','selftest4-registers.json']:
        check(name+'-zero-failures',read_json(OUT/name)['failures']==0)
    regression=read_json(OUT/'regression4/regression-summary.json')
    check('regression-15-runs-zero-failures',regression['runs']==15 and all(regression[k]==0 for k in ['nonzero_exits','assertion_failures','unclassified_errors']))
    check('regression-protected-unchanged',not regression['protected_changes'])
    check('raw-logs-present',all((OUT/'regression4'/('godot-'+r['name']+'.log')).is_file() for r in regression['results']))
    images=read_json(OUT/'regression-images4.json')
    check('six-current-render-images',len(images)==6 and all(digest(ROOT/i['file'])==i['sha256'] for i in images))
    result={'checks':len(checks),'failures':sum(not c['passed'] for c in checks),'results':checks}
    write_json(OUT/'delivery-check4.json',result)
    print({k:v for k,v in result.items() if k!='results'})
    for c in checks:
        if not c['passed']:print('FAIL',c['name'])
    return int(bool(result['failures']))

if __name__=='__main__':raise SystemExit(main())
