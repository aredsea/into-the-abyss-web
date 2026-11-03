"""Run the package's complete local Worker/D1 tests and retain fresh logs."""
from pathlib import Path
import subprocess,json,time,sys,os
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/parity-r23/server';OUT.mkdir(exist_ok=True)
package=json.loads((ROOT/'server/abyss-save/package.json').read_text(encoding='utf-8'))
result=[]
temp=ROOT/'.p6tmp';temp.mkdir(exist_ok=True)
env={**os.environ,**{key:str(temp) for key in ['TEMP','TMP','TMPDIR']}}
for command in package['scripts']['test'].split(' && '):
    args=command.split();name=Path(args[-1]).stem;start=time.monotonic()
    with (OUT/(name+'.log')).open('wb') as log:p=subprocess.run(args,cwd=ROOT/'server/abyss-save',env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
    text=(OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace')
    row={'test':name,'command':command,'exit':p.returncode,'seconds':round(time.monotonic()-start,2),'summary':text.splitlines()[-5:]}
    result.append(row);(OUT/'results.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(row),flush=True)
sys.exit(any(r['exit'] for r in result))
