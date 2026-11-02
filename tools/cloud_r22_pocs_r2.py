"""Run supplied, unmodified round-two scripts against local workerd, never deploy."""
from pathlib import Path
import concurrent.futures, json, os, subprocess
root=Path(__file__).resolve().parents[1]
out=root/'verification/cloud-r22/p9c';out.mkdir(parents=True,exist_ok=True)
source=Path('C:/Users/asone/AppData/Local/Temp/claude/C--Clauede-Code/8827866b-4906-44ba-b235-c0148a886034/scratchpad/r2poc')
env=os.environ.copy();env.setdefault('ABYSS_NODE_MODULES','C:/Users/asone/AppData/Local/npm-cache/_npx/c943b712072b77c4/node_modules');env['NODE_PATH']=env['ABYSS_NODE_MODULES']
def run(name):
    p=subprocess.run(['node',str(source/(name+'.mjs')),str(root)],cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=240)
    stdout=p.stdout.decode('utf-8',errors='replace');stderr=p.stderr.decode('utf-8',errors='replace')
    (out/(name+'.stdout.log')).write_text(stdout,encoding='utf-8');(out/(name+'.stderr.log')).write_text(stderr,encoding='utf-8')
    try:
        assert p.returncode==0,(p.returncode,stderr)
        v=json.loads(stdout)
        if name=='dos_bytes':
            assert v['sameMinute'] and v['victimSmallPut']['status']==200 and v['otherUserCreate']['status']==201
            assert v['attackerPutStatuses'].get(429, v['attackerPutStatuses'].get('429',0))>0
        elif name=='dos_requests':
            assert v['sameMinute'] and v['victimRankGet']==v['victimConnect']==v['victimDownload']==200
            assert v['victimCreate'].get('code') and v['attackerStatuses'].get('429',0)>0
        elif name=='toctou':
            assert v['concurrentRightLast']==v['sequentialRightAfter']==429
            assert v['concurrentWrong'].get('403')==20 and max(v['authfailCounter'])<=20
            assert v['concurrentAbsent150Ms']<v['sequentialAbsent150Ms']*2.5+200
        elif name=='misc':
            assert v['control_legit_v3']['accepted']
            for k in ['v3_extra_blob','v2_extra_blob','effects_number','acts_free_text_key']:assert not v[k]['accepted'],k
            assert v['v2Create']==422 and v['ownerDownload']==v['ownerHistory']==v['ownerRankView']==v['ownerConnect']==200
            assert v['after1day_best146'].get('submitted') and v['after70days_best9999'].get('error')=='rank_ineligible'
        elif name=='migr':
            assert v['savePreserved'] and v['ranksAfter']==0 and not v['fkCheck']
            assert v['oldConnect']==v['oldPut']==200 and v['oldRank5000']['error']=='rank_ineligible'
            assert v['ownerPutAfterArchive']['status']==v['ownerDeleteAfterArchive']==410 and v['archiveStillThere']==0
        elif name=='fill':
            assert v['statuses'].get('429',0)>0 and v['storedBytes']['c']<=28
        elif name=='proto2':
            for k in ['constructorTop','protoTop','prototypeTop']:assert v[k+'_injected'] and v[k]!='accepted'
        elif name=='vtime':
            assert all(v[k]>=0 for k in ['big_ms','town_ms','largest_legit_ms'])
        row={'script':name+'.mjs','exit':p.returncode,'passed':True,'result':v}
    except Exception as e:row={'script':name+'.mjs','exit':p.returncode,'passed':False,'error':str(e),'stdout':stdout[-3000:]}
    print(name,'PASS' if row['passed'] else 'FAIL',flush=True)
    return row
names=['dos_bytes','dos_requests','toctou','misc','migr','fill','proto2','vtime']
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(run,names))
report={'checks':len(results),'failures':sum(not r['passed'] for r in results),'results':results,
        'notes':['fill: old per-minute projections do not model the new daily limits; distributed IP storage pressure remains an operational concern.',
                 'proto2: a lone surrogate in a bounded name is text, not executable input; remains allowed.',
                 'vtime: timing diagnostic, not an exploit or a production CPU guarantee.']}
(out/'poc-results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
raise SystemExit(1 if report['failures'] else 0)
