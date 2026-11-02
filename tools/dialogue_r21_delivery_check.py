"""Check that report, review evidence and samples describe the delivered bytes."""
import hashlib
import re
import subprocess
import sys
from dialogue_r21_build import ROOT, OUT, IDS, read_json, write_json
from dialogue_r21_report2 import SAMPLES

def main():
    if (OUT/'delivery-manifest4.json').exists():
        from dialogue_r21_delivery_check4 import main as current
        return current()
    if (OUT/'delivery-manifest3.json').exists():
        from dialogue_r21_delivery_check3 import main as current
        return current()
    checks=[]
    def check(name, result):
        checks.append({'name':name,'passed':bool(result)})
    manifest=read_json(OUT/'delivery-manifest2.json')
    hashes={cid:hashlib.sha256((ROOT/f'project/data/dialogue-r21/{cid}.json').read_bytes()).hexdigest() for cid in IDS}
    p=subprocess.run([sys.executable,'tools/dialogue_r21_build.py'],cwd=ROOT,capture_output=True)
    check('offline-rebuild-exit',p.returncode==0)
    check('offline-rebuild-byte-identical',all(hashlib.sha256((ROOT/f'project/data/dialogue-r21/{cid}.json').read_bytes()).hexdigest()==h for cid,h in hashes.items()))
    check('content-hashes-match-lint',read_json(OUT/'check.json')['input_sha256']=={cid+'.json':h for cid,h in hashes.items()})
    check('content-hashes-match-delivery',manifest['content_sha256']=={cid+'.json':h for cid,h in hashes.items()})
    check('twelve-sample-files',len(list(OUT.glob('sample2-*.md')))==12)
    review=(OUT/'review-2.md').read_text(encoding='utf-8')
    for cid in IDS:
        d=read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
        sample=(OUT/f'sample2-{cid}.md').read_text(encoding='utf-8')
        scenes=[d['inn'][i] for i in SAMPLES[cid]]
        check(cid+'-sample-stages',[s['stage'] for s in scenes]==['낯섦','유대','운명'])
        strings=[]
        for s in scenes:
            strings += [s['id'],s['situation'],s['seen'],*s['lines']]
            for c in s['choices']:
                strings += [c['text'],*c['response'],c['reason']]
        check(cid+'-samples-match-final-content',all(t in sample for t in strings))
        part=review.split(f'## {IDS[cid]} · {cid}\n',1)[1].split('\n## ',1)[0]
        pairs=sum(line.startswith('| `') for line in part.splitlines())
        check(cid+'-real-review-pair-count',pairs==manifest['review_pairs'][cid] and pairs>=10)
    for r in manifest['files']:
        p=ROOT/r['file']
        check(r['file']+'-manifest-hash',p.exists() and hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'])
    check('report-starts-with-second-pass',(ROOT/'DIALOGUE-R21.md').read_text(encoding='utf-8').startswith('# 2차\n'))
    result={'checks':len(checks),'failures':sum(not c['passed'] for c in checks),'results':checks}
    write_json(OUT/'delivery-check.json',result)
    print({k:v for k,v in result.items() if k!='results'})
    for c in checks:
        if not c['passed']: print('FAIL',c['name'])
    return int(bool(result['failures']))

if __name__=='__main__':
    raise SystemExit(main())
