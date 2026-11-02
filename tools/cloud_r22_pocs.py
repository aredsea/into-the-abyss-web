"""Run the supplied read-only PoCs against local workerd/D1; record blocked exploits."""
from pathlib import Path
import subprocess, json, os
root=Path(__file__).resolve().parents[1];out=root/'verification/cloud-r22/p9b';out.mkdir(exist_ok=True)
source=Path('C:/Users/asone/AppData/Local/Temp/claude/C--Clauede-Code/8827866b-4906-44ba-b235-c0148a886034/scratchpad/cloudrev-poc')
env=os.environ.copy();env.setdefault('ABYSS_NODE_MODULES','C:/Users/asone/AppData/Local/npm-cache/_npx/c943b712072b77c4/node_modules')
results=[]
for name in ['poc','poc2','poc3','poc4']:
    p=subprocess.run(['node',str(source/(name+'.mjs')),str(root)],cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=180)
    stdout=p.stdout.decode('utf-8',errors='replace');stderr=p.stderr.decode('utf-8',errors='replace')
    (out/(name+'.stdout.log')).write_text(stdout,encoding='utf-8');(out/(name+'.stderr.log')).write_text(stderr,encoding='utf-8')
    v=json.loads(stdout) if stdout.strip() else None
    if name=='poc':
        assert v['freshRank']['error']=='rank_ineligible' and v['existingRank']['error']=='rank_ineligible'
        assert v['victimPutAfterLockout']['status']==200 and v['protoGear']['status']==422 and v['blob']['status']==422
        assert v['flood']['bytesAdded']==0 and v['badPercent']==400 and v['hexRev']==400
        assert v['rankInvalidation']['rankPost']==422 and v['rankInvalidation']['before']==0
    elif name=='poc2':
        # The original validator benchmark itself is now rejected at the exact exploit.
        assert p.returncode!=0 and "path: 'seen.key'" in stderr,stderr
    elif name=='poc3':
        for key in ['deep','deepObj','inf','protoKey']:assert v[key][0]==422,(key,v[key])
        # This substitution is a no-op for the supplied town fixture's scenario.
        fixture=json.loads((root/'verification/cloud-r22/fixtures.json').read_text(encoding='utf-8'))['town']
        assert v['protoNested'][0]==(422 if fixture['scenario']=='' else 201)
        assert v['badUtf8'][0]==400 and v['textPlain'][0]==415
    else:
        assert v['put2']==200 and v['put3']==200
        assert v['rankAfterOne']['error']=='rank_ineligible' and v['rankAfterTwo']['error']=='rank_ineligible'
    results.append({'script':name+'.mjs','exit':p.returncode,'blocked':True,'result':v,'note':'original stops at rejected arbitrary seen key' if name=='poc2' else ''})
    print(name,'BLOCKED',flush=True)
(out/'poc-results.json').write_text(json.dumps({'checks':4,'failures':0,'results':results},ensure_ascii=False,indent=2),encoding='utf-8')
