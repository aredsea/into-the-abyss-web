"""Export the local verification build without writing docs or retaining a dev URL."""
from pathlib import Path
import json,re,shutil,subprocess,sys
root=Path(__file__).resolve().parents[1];p=root/'project/data/cloud-r22.json';original=p.read_bytes()
challenge='--turnstile-test' in sys.argv
out=root/('verification/cloud-r22/web-turnstile' if challenge else 'verification/cloud-r22/web');out.mkdir(parents=True,exist_ok=True)
try:
 value=json.loads(original);value['server_url']='http://127.0.0.1:8787'
 if challenge:value['turnstile_site_key']='local-site-key-for-bridge-test'
 p.write_text(json.dumps(value,ensure_ascii=False),encoding='utf-8')
 r=subprocess.run(['python','tools/godot_r17.py','--headless','--export-release','Web','../'+out.relative_to(root).as_posix()+'/index.html'],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 (out.parent/('export-turnstile.log' if challenge else 'export.log')).write_bytes(r.stdout)
 if r.returncode:raise RuntimeError('export failed: see export.log')
 shell=(out/'index.html').read_text(encoding='utf-8')
 for rel in set(re.findall(r'(?:src=["\']|url\(["\'])(ui-[^"\']+)',shell)):
  target=out/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/'docs'/rel,target)
 print('LOCAL WEB EXPORT OK',flush=True)
finally:p.write_bytes(original)
