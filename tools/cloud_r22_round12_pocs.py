"""Run the supplied settlement PoC and scan locally. No remote operations."""
from pathlib import Path
import hashlib,json,subprocess,re
root=Path(__file__).resolve().parents[1]
out=root/'verification/cloud-r22/round12';out.mkdir(parents=True,exist_ok=True)
scratch=Path('C:/Users/asone/AppData/Local/Temp/claude/C--Clauede-Code/8827866b-4906-44ba-b235-c0148a886034/scratchpad')
poc=scratch/'r3-poc/settle_blob.mjs'
scan=scratch/'r3-fixcheck/scan2.mjs'
source=scan.read_text(encoding='utf-8')
# The provided scanner hardcodes a stale scratch copy. Change only its base
# directory so both validator and all specimens come from this worktree.
local,n=re.subn(r"const B='[^']+';",'const B='+json.dumps(root.as_posix()+'/')+';',source,count=1)
assert n==1
adapted=out/'scan2-local.mjs';adapted.write_text(local,encoding='utf-8')
results={}
for name,args in [('settle_blob',[str(poc),str(root)]),('scan2',[str(adapted)])]:
    p=subprocess.run(['node',*args],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=600)
    stdout=p.stdout.decode('utf-8',errors='replace');stderr=p.stderr.decode('utf-8',errors='replace')
    (out/(name+'.stdout.log')).write_text(stdout,encoding='utf-8');(out/(name+'.stderr.log')).write_text(stderr,encoding='utf-8')
    assert p.returncode==0,(name,p.returncode,stderr)
    v=json.loads(stdout)
    if name=='settle_blob':
        assert v['create']==422
        assert all(not value['accepted'] for value in v.values() if isinstance(value,dict) and 'accepted' in value)
    else:
        assert v['samples']==154 and not v['replaceAccepted'] and not v['addAccepted']
    results[name]={'exit':p.returncode,'passed':True,'result':v}
    print(name,'PASS',flush=True)
results['source_sha256']={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in [poc,scan]}
results['scan_adaptation']='Only the hardcoded base directory is replaced with this worktree; original files unchanged.'
(out/'poc-results.json').write_text(json.dumps({'checks':2,'failures':0,**results},ensure_ascii=False,indent=2),encoding='utf-8')
