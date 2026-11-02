"""Summarize fresh round-12 evidence and verify protected bytes without Git."""
from pathlib import Path
import hashlib,json,subprocess,re,shutil
root=Path(__file__).resolve().parents[1];out=root/'verification/cloud-r22/round12'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,v):(out/name).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assets=read(root/'ASSET-HASHES.json')
base=read(root/'verification/town-r21/round11/baseline.json')
allowed_game={'project/game/cloud_store_r22.gd','project/game/settings_world_r22.gd','project/game/facilities_world_r22.gd','project/game/localization_r22.gd'}
protected={p:h for p,h in base.items() if p.startswith('project/assets/') or p.startswith('project/data/') and p!='project/data/localization-r22.json' or p.startswith('project/game/') and p not in allowed_game or p.startswith('project/ui/battle')}
changed=[p for p,h in protected.items() if not (root/p).exists() or sha(root/p)!=h]
asset_changed=[a['path'] for a in assets if sha(root/a['path'])!=a['sha256']]
known=read(root/'server/abyss-save/src/known.json')
provenance={name:sha(root/'project/data'/(name+'.json'))==h for name,h in known['provenance'].items()}
code="import fs from 'node:fs';import {bundle} from './server/abyss-save/build.mjs'; console.log(JSON.stringify({matches:fs.readFileSync('server/abyss-save/dist/worker.mjs','utf8')===bundle()}));"
p=subprocess.run(['node','--input-type=module','-e',code],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True)
bundle= json.loads(p.stdout)
client=read(root/'project/data/cloud-r22.json')
pkg=read(root/'server/abyss-save/package.json');lock=read(root/'server/abyss-save/package-lock.json')
audit={'protected_count':len(protected),'protected_changed':changed,'original_assets':len(assets),'original_assets_changed':asset_changed,'known_provenance':provenance,'worker_matches_source':bundle['matches'],'miniflare_package':pkg['devDependencies']['miniflare'],'miniflare_lock':lock['packages']['node_modules/miniflare']['version'],'client_server_url_blank':client['server_url']=='','client_site_key_blank':client['turnstile_site_key']=='','remote_actions':0,'web_exports':0}
write('audit.json',audit)
server=[]
for label,file in [('integration','verification/cloud-r22/server-results.json'),('security-r1','verification/cloud-r22/p9b/security-results.json'),('siteverify','verification/cloud-r22/p9b/siteverify-results.json'),('security-r2','verification/cloud-r22/p9c/security-results.json'),('security-r3','verification/cloud-r22/round12/security-results.json'),('deployment','verification/cloud-r22/round12/deployment-results.json')]:
    v=read(root/file)
    if not file.startswith('verification/cloud-r22/round12/'):
        shutil.copyfile(root/file,out/(label+'-results.json'))
    server.append({'name':label,'checks':v['checks'],'failures':v.get('failures',sum(not x['passed'] for x in v.get('groups',[])))})
suite=read(out/'regression.json');poc=read(out/'poc-results.json')
cloud_service=read(root/'verification/cloud-r22/native-service-results.json')
cloud_ui=read(root/'verification/cloud-r22/native-ui-results.json')
cloud_archive=read(root/'verification/cloud-r22/p9c/native-archive-results.json')
for label,v in [('native-service',cloud_service),('native-ui',cloud_ui),('native-archive',cloud_archive)]:write(label+'-results.json',v)
summary={'server':server,'server_checks':sum(v['checks'] for v in server),'server_failures':sum(v['failures'] for v in server),'regression_groups':len(suite),'regression_failed_groups':sum(bool(v['exit_code'] or v['errors']) for v in suite),'cloud_checks':sum(v['checks'] for v in [cloud_service,cloud_ui,cloud_archive]),'cloud_failures':sum(len(v['failures']) for v in [cloud_service,cloud_ui,cloud_archive]),'cloud_ui_captures':len(cloud_ui['captures']),'legitimate_samples':poc['scan2']['result']['samples'],'opaque_replace_accepted':len(poc['scan2']['result']['replaceAccepted']),'opaque_add_accepted':len(poc['scan2']['result']['addAccepted']),'settle_blob_create':poc['settle_blob']['result']['create'],'assets_unchanged':len(assets)-len(asset_changed)}
write('summary.json',summary)
print(json.dumps(summary,ensure_ascii=False,indent=2))
assert not any([changed,asset_changed,summary['server_failures'],summary['regression_failed_groups'],summary['cloud_failures']])
assert all(provenance.values()) and bundle['matches'] and audit['client_server_url_blank'] and audit['client_site_key_blank']
