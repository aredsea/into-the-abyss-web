"""Collect final native evidence and integrity without touching protected sources."""
from pathlib import Path
import json,hashlib
from PIL import Image,ImageOps,ImageDraw
root=Path(__file__).resolve().parents[1]
folder=root/'verification/expedition-r22';render=folder/'render'
for dim in ['360x780','390x844','390x664','430x932','1280x800']:
    tags=['floors','floor-page','entry','discovery','log','supplies','targets','rest','equipment','retreat-confirm','settlement','next-floor','combat-supplies']
    sheet=Image.new('RGB',(1560,4*874),'#e5e5e5');draw=ImageDraw.Draw(sheet)
    for i,tag in enumerate(tags):
        f=render/f'{tag}-{dim}.png';im=ImageOps.contain(Image.open(f).convert('RGB'),(390,844));x=(i%4)*390;y=(i//4)*874
        sheet.paste(im,(x+(390-im.width)//2,y+26));draw.text((x+8,y+6),f.stem,fill='black')
    sheet.save(render/f'review-{dim}.jpg',quality=90)
before=json.loads((folder/'protected-before.json').read_text(encoding='utf-8'))
protected={'count':len(before),'changed':[p for p,h in before.items() if not Path(p).is_file() or hashlib.sha256(Path(p).read_bytes()).hexdigest()!=h]}
assets=json.loads((root/'ASSET-HASHES.json').read_text(encoding='utf-8'))
integrity={'count':len(assets),'changed':[x['path'] for x in assets if hashlib.sha256((root/x['path']).read_bytes()).hexdigest()!=x['sha256']]}
regression=json.loads((folder/'regression.json').read_text(encoding='utf-8'))
rules=json.loads((folder/'results.json').read_text(encoding='utf-8'));ui=json.loads((folder/'ui-results.json').read_text(encoding='utf-8'))
summary={'regression_groups':len(regression),'failed_groups':[r['test'] for r in regression if r['exit'] or r['errors']],'rules_checks':rules['checks'],'rules_failures':len(rules['failures']),'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'native_captures':len(ui['captures']),'oracle_rows':sum(len(v) for v in json.loads((folder/'oracle.json').read_text(encoding='utf-8')).values()),'protected':protected,'assets':integrity,'p9_boundary':json.loads((folder/'p9-boundary.json').read_text(encoding='utf-8'))}
(folder/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
