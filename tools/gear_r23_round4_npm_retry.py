"""Rerun only npm after its local undici connection reset; retain both logs."""
from pathlib import Path
import os,subprocess,json,re
R=Path(__file__).resolve().parents[1];S=R/'verification/parity-r23/gear-suite-round4'
temp=R/'.p6tmp';temp.mkdir(exist_ok=True)
env={**os.environ,'ABYSS_NODE_MODULES':str(R/'server/abyss-save'),'TEMP':str(temp),'TMP':str(temp),'TMPDIR':str(temp)}
with (S/'npm-retry.log').open('wb') as f:
    code=subprocess.call(['cmd','/c','npm','test'],cwd=R/'server/abyss-save',env=env,stdout=f,stderr=subprocess.STDOUT)
log=(S/'npm-retry.log').read_text(encoding='utf-8',errors='replace')
result={'exit':code,'checks':sum(map(int,re.findall(r'(?:CHECKS |"checks":)(\d+)',log))),'reason':'Initial npm run ended with undici terminated / ECONNRESET during the 64 KiB streaming-limit case. No server or test-source changes.'}
(S/'npm-retry-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result),flush=True)
raise SystemExit(code)
