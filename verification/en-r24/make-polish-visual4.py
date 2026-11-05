"""Make small contact sheets from the new UI test captures for visual QA."""
from PIL import Image, ImageDraw
from polish4 import *
sys.stdout.reconfigure(encoding='utf-8')
run=json.loads((OUT/'polish-checks/run.json').read_text(encoding='utf-8'))
target=OUT/'polish-visual'
target.mkdir(exist_ok=True)
ids=['haldric','levia','marceline','teiris','urda','zahar']
meta=[]
for cid in ids:
 paths=sorted((OUT/'render').glob(cid+'-*-en-*.png'))
 assert len(paths)==5
 assert all(p.stat().st_mtime>=run['started'] for p in paths)
 ims=[Image.open(p).convert('RGB') for p in paths]
 sheet=Image.new('RGB',(sum(i.width for i in ims),max(i.height for i in ims)+32),'#151515')
 draw=ImageDraw.Draw(sheet);x=0
 for p,im in zip(paths,ims):
  draw.text((x+4,5),p.stem,fill='white');sheet.paste(im,(x,32));x+=im.width;im.close()
 path=target/(cid+'.jpg');sheet.save(path,quality=92)
 meta.append(dict(id=cid,sheet=str(path.relative_to(ROOT)),captures=[str(p.relative_to(ROOT)) for p in paths]))
(target/'index.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf-8')
print('6 sheets / 30 fresh captures')
