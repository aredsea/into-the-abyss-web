"""Evidence inventory and contact sheets only. No git, export, or source edits."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib
root=Path(__file__).resolve().parents[1];out=root/'verification/facilities-r22'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
baseline=json.loads((out/'baseline.json').read_text(encoding='utf-8'))
changed=[name for name,sha in baseline.items() if not (root/name).exists() or digest(root/name)!=sha]
protected=[name for name in baseline if name.startswith(('server/','docs/','project/game/battle','project/game/combat','project/ui/battle','project/ui/combat')) or name=='project/ui/town_screen_r21.gd']
assets=json.loads((root/'ASSET-HASHES.json').read_text(encoding='utf-8'))
bad_assets=[row['path'] for row in assets if digest(root/row['path'])!=row['sha256']]
provenance=json.loads((out/'provenance.json').read_text(encoding='utf-8'))
bad_source=[row['path'] for row in provenance['sources']+provenance['harnesses'] if digest(Path(row['path']))!=row['sha256']]
audit={'changed_existing':changed,'protected_count':len(protected),'protected_changed':[p for p in changed if p in protected],'original_assets':len(assets),'asset_changes':bad_assets,'source_and_harness_count':len(provenance['sources']+provenance['harnesses']),'source_changes':bad_source,'unexpected_existing_changes':[p for p in changed if p!='project/ui/world_screen.gd']}
(out/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
tags=['shop','scroll-targets','ten-classes','shop-receipt','smithy-forge','smithy-process','smithy-result','smithy-blocked','smithy-receipt','guild','guild-active','inn','inn-empty']
for dim in ['360x780','390x844','390x664','430x932','1280x800']:
    sheet=Image.new('RGB',(1100,1480),'#dedbd4');draw=ImageDraw.Draw(sheet)
    for i,tag in enumerate(tags):
        im=Image.open(out/'render'/f'{tag}-{dim}.png').convert('RGB')
        if dim=='1280x800':im=im.crop((452,0,828,800))
        im.thumbnail((215,455));x=(i%5)*220;y=(i//5)*490
        sheet.paste(im,(x,y+22));draw.text((x+3,y+3),tag,fill='#111111')
    sheet.save(out/'render'/f'contact-{dim}.jpg',quality=90)
rules=json.loads((out/'results.json').read_text(encoding='utf-8'));ui=json.loads((out/'ui-results.json').read_text(encoding='utf-8'));regression=json.loads((out/'regression.json').read_text(encoding='utf-8'));boundary=json.loads((out/'p9-boundary.json').read_text(encoding='utf-8'))
summary={'regression_groups':len(regression),'failed_groups':[r['test'] for r in regression if r['exit'] or r['errors']],'rules_checks':rules['checks'],'rules_failures':len(rules['failures']),'lua_samples':rules['lua_samples'],'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'native_captures':len(ui['captures']),'native_sizes':5,'actual_legacy_specimens':11,'p9_accepted':sum(r['accepted'] for r in boundary['rows']),'p9_samples':len(boundary['rows']),**audit}
(out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
if summary['failed_groups'] or rules['failures'] or ui['failures'] or audit['unexpected_existing_changes'] or audit['protected_changed'] or bad_assets or bad_source:raise SystemExit(1)
