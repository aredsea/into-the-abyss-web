"""Validate fifth-pass prose-only edits, reproducibility and review evidence."""
from collections import Counter
import subprocess
import sys
from dialogue_r21_build import ROOT, OUT, CANON, IDS, read_json, write_json, display_fields
from dialogue_r21_round5 import at, digest, structural


def main():
    checks = []
    def check(name,ok):
        checks.append(dict(name=name,passed=bool(ok)))
    manifest = read_json(OUT/'delivery-manifest5.json')
    hashes = {c+'.json':digest(ROOT/f'project/data/dialogue-r21/{c}.json') for c in IDS}
    p = subprocess.run([sys.executable,'-X','utf8','tools/dialogue_r21_build.py'],cwd=ROOT,capture_output=True)
    check('rebuild-exit',p.returncode==0)
    check('rebuild-all-30-identical',hashes=={c+'.json':digest(ROOT/f'project/data/dialogue-r21/{c}.json') for c in IDS})
    lint = read_json(OUT/'check5.json')
    check('lint-zero',lint['error_count']==0)
    check('lint-matches-final',lint['input_sha256']==hashes)
    check('sample-files-30',len(list(OUT.glob('sample5-*.md')))==30)
    edits = read_json(OUT/'edits5-applied.json')
    check('edit-paths-unique',len({(e['character_id'],e['path']) for e in edits})==len(edits))
    metrics = read_json(OUT/'metrics5.json')
    review = (OUT/'review-5.md').read_text(encoding='utf8')
    for cid in IDS:
        before = read_json(OUT/f'draft5/{cid}.json')
        after = read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
        check(cid+'-structure-and-aff-exact',structural(before)==structural(after))
        fields = {p:t for p,t,_ in display_fields(after)}
        local = [e for e in edits if e['character_id']==cid]
        check(cid+'-applied-evidence',all(at(before,e['path'])==e['before'] and at(after,e['path'])==e['after'] and e['reason'] for e in local))
        before_fields = {p:t for p,t,_ in display_fields(before)}
        changed = {p for p in fields if fields[p]!=before_fields[p]}
        check(cid+'-all-display-edits-accounted',changed=={e['path'] for e in local if e['path'] in fields})
        check(cid+'-five-real-pairs',len(changed)>=5)
        check(cid+'-openings-and-transitions',all(len(s['lines'])==3 for s in after['inn']) and all(len(s['lines'])==2 for s in after['transitions']))
        sample = (OUT/f'sample5-{cid}.md').read_text(encoding='utf8')
        scenes = [next(s for s in after['inn'] if s['id']==sid) for sid in metrics[cid]['sample_scene_ids']]
        check(cid+'-sample-stages',[s['stage'] for s in scenes]==['낯섦','유대','운명'])
        strings = []
        for s in scenes:
            strings += [s['id'],s['situation'],s['seen'],*s['lines']]
            for c in s['choices']:
                strings += [c['text'],c['reason'],*c['response']]
        check(cid+'-sample-exact',all(t in sample for t in strings))
        part=review.split(f'### {IDS[cid]} · {cid}\n',1)[1].split('\n### ',1)[0]
        check(cid+'-five-review-pairs',sum(s.startswith('| `') for s in part.splitlines())==5)
    references = [d for n in [2,3,4] for d in read_json(OUT/f'kreview-{n}.json')]
    decisions = read_json(OUT/'decisions5.json')
    check('all-66-review-ids',len(decisions)==66 and {d['id'] for d in decisions}=={d['id'] for d in references})
    check('no-duplicate-review-ids',len({d['id'] for d in decisions})==66)
    for d in decisions:
        ref = next(r for r in references if r['id']==d['id'])
        data = read_json(ROOT/f"project/data/dialogue-r21/{d['character_id']}.json")
        check(d['id']+'-before-reference-exact',d['before']==ref['before'])
        check(d['id']+'-after-final-exact',at(data,d['path'])==d['after'])
        check(d['id']+'-reason-and-table',d['reason'] and d['id'] in review)
        if ref['severity']=='고침':
            check(d['id']+'-mandatory-fixed',d['status'].startswith('반영') and d['after']!=d['before'])
    for key,num in [('inn_scenes',840),('choices',2520),('dungeon_variants',2520),('transition_scenes',420)]:
        check('total-'+key,sum(m[key] for m in lint['characters'].values())==num)
    base = read_json(OUT/'baseline5.json')
    for group,root in [('protected',ROOT),('canon',CANON),('reviews',ROOT),('historical',ROOT)]:
        check(group+'-unchanged',all((root/p).is_file() and digest(root/p)==h for p,h in base[group].items()))
    report = (ROOT/'DIALOGUE-R21.md').read_bytes()
    check('report-five-first',report.startswith('# 5차\n'.encode('utf8')))
    check('report-history-exact',report.endswith((OUT/'original-report4.md').read_bytes()))
    for name in ['selftest5.json','selftest5-registers.json']:
        check(name,read_json(OUT/name)['failures']==0)
    regression = read_json(OUT/'regression5/regression-summary.json')
    check('godot-15-success',regression['runs']==15 and not any(regression[k] for k in ['nonzero_exits','assertion_failures','unclassified_errors','protected_changes']))
    check('retry-initial-evidence-retained',(OUT/'regression5/retry5.json').is_file() and (OUT/'regression5/godot-ui_battle_r18_test-attempt1.log').is_file())
    images = read_json(OUT/'regression-images5.json')
    check('six-current-image-hashes',len(images)==6 and all(digest(ROOT/i['file'])==i['sha256'] for i in images))
    run=ROOT/'_workspace/2026-11-03-001-8495'
    skill=read_json(OUT/'humanize-gates5/summary.json')
    check('skill-99-chunk-gates',skill['chunks']==99 and skill['errors']==0 and not skill['warning_chunks'])
    chunk_manifest=read_json(run/'chunk_manifest.json')
    chunk_hashes=read_json(OUT/'humanize-gates5/input-hashes.json')
    check('skill-gated-inputs-match',len(chunk_hashes)==99 and all(
        digest(run/f"01_chunk_{row['index']:02d}_original.txt")==row['before'] and
        digest(run/chunk_manifest['chunks'][row['index']-1]['rewritten_file'])==row['after'] for row in chunk_hashes))
    final=(run/'final.md').read_text(encoding='utf8')
    expected=(run/'expected-final.txt').read_text(encoding='utf8')
    check('skill-reassembly-exact',final.startswith(expected) and (run/'03_reassembled.md').read_text(encoding='utf8')==expected)
    check('skill-one-summary',final.count('<!-- HUMANIZE-SUMMARY -->')==1)
    finalized=read_json(run/'09_finalize.json')
    check('finalizer-corrected-no-fidelity-hold',finalized['status']=='corrected' and not finalized['fidelity_violations_unresolved'])
    for path,h in manifest['files'].items():
        check('manifest-'+path,(ROOT/path).is_file() and digest(ROOT/path)==h)
    result = dict(checks=len(checks),failures=sum(not c['passed'] for c in checks),results=checks)
    write_json(OUT/'delivery-check5.json',result)
    print({k:v for k,v in result.items() if k!='results'})
    for c in checks:
        if not c['passed']:
            print('FAIL',c['name'])
    return int(bool(result['failures']))


if __name__ == '__main__':
    raise SystemExit(main())
