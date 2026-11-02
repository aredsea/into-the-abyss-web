"""Build review sheets and audit the final merged delivery, without Git."""
from pathlib import Path
import hashlib,json,re,sys
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round11'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
ui=read(O/'ui-results.json')
for dim in ['360x780','390x844','390x664','430x932','1280x800']:
    files=sorted(n for n in ui['captures'] if n.endswith('-'+dim+'.png'))
    cw,ch=190,420;sheet=Image.new('RGB',(cw*6,ch*((len(files)+5)//6)), '#dedbd0');draw=ImageDraw.Draw(sheet)
    for i,name in enumerate(files):
        im=Image.open(O/'render'/name).convert('RGB');im.thumbnail((cw-6,ch-25),Image.Resampling.LANCZOS)
        x=(i%6)*cw;y=(i//6)*ch;sheet.paste(im,(x,y+22));draw.text((x+2,y+3),name.removesuffix('-'+dim+'.png'),fill='black')
    sheet.save(O/f'contact-{dim}.jpg',quality=92)
if '--contacts-only' in sys.argv:sys.exit(0)
base=read(O/'baseline.json');changed=[p for p,h in base.items() if not (R/p).exists() or sha(R/p)!=h]
allowed_game={'project/game/cloud_store_r22.gd','project/game/settings_world_r22.gd','project/game/facilities_world_r22.gd','project/game/localization_r22.gd'}
protected={p:h for p,h in base.items() if p.startswith('project/assets/') or p.startswith('project/data/') and p!='project/data/localization-r22.json' or p.startswith('project/game/') and p not in allowed_game or p.startswith('project/ui/battle')}
assets=read(R/'ASSET-HASHES.json');sources=read(R/'verification/settings-r22/provenance.json')['files']
markers=[]
for folder in ['project','server/abyss-save/src']:
    for p in (R/folder).rglob('*'):
        if p.is_file() and p.suffix in ['.gd','.js'] and '.godot' not in p.parts:
            for n,line in enumerate(p.read_text(encoding='utf-8').splitlines(),1):
                if re.match(r'^(<<<<<<<|=======|>>>>>>>)',line):markers.append([str(p.relative_to(R)),n])
audit={'changed_existing_files':changed,'new_project_files':[p.relative_to(R).as_posix() for p in (R/'project').rglob('*') if p.is_file() and '.godot' not in p.parts and p.relative_to(R).as_posix() not in base],
 'protected_count':len(protected),'protected_changed':[p for p,h in protected.items() if not (R/p).exists() or sha(R/p)!=h],
 'original_assets':len(assets),'original_assets_changed':[x['path'] for x in assets if sha(R/x['path'])!=x['sha256']],
 'source_count':len(sources),'source_changed':[x['path'] for x in sources if sha(Path(x['path']))!=x['sha256']],
 'security_files_unchanged':all(sha(R/p)==h for p,h in base.items() if p.startswith('server/abyss-save/') and p not in ['server/abyss-save/src/validate.js','server/abyss-save/test/integration.mjs']),
 'conflict_markers':markers,'ui_build':read(R/'docs/version.json')['ui_build'],'pck_bytes':(R/'docs/index.pck').stat().st_size,'pck_sha256':sha(R/'docs/index.pck')}
write(O/'audit.json',audit)
suite=read(O/'regression.json');web=read(R/'verification/town-r21/web/results.json');logic=read(O/'integration-results.json');server=read(R/'verification/cloud-r22/server-results.json')
security=read(R/'verification/cloud-r22/p9b/security-results.json');turn=read(R/'verification/cloud-r22/p9b/siteverify-results.json')
summary={'groups':len(suite),'failed_groups':sum(bool(x['exit_code'] or x['errors']) for x in suite),'integration_checks':logic['checks'],'integration_failures':len(logic['failures']),'legacy_specimens':logic['legacy_specimens'],'merged_specimens':len(logic['samples']),
 'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'native_captures':len(ui['captures']),'server_checks':server['checks'],'server_failures':server['failures'],'security':security,'turnstile':turn,
 'web_configurations':len(web),'web_languages':sorted(set(x.get('lang','ko') for x in web)),'web_battles':sum(x['battles'] for x in web),'web_errors':sum(len(x['errors'])+len(x['text_errors']) for x in web),'web_artifact_matches':all(x['pck_sha256']==audit['pck_sha256'] for x in web)}
write(O/'summary.json',summary)
print(json.dumps({k:v for k,v in summary.items() if k not in ['security','turnstile']},indent=2))
assert not any([summary['failed_groups'],summary['integration_failures'],summary['ui_failures'],summary['web_errors'],server['failures'],audit['protected_changed'],audit['original_assets_changed'],audit['source_changed'],audit['conflict_markers']])
assert len(web)==7 and summary['web_artifact_matches'] and audit['security_files_unchanged']
