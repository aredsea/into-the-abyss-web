"""All 28 current pairs; final human judgements are written after opening them."""
from pathlib import Path
import ast,json,math
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';V=O/'round4';C=O/'compare-round4';C.mkdir(exist_ok=True)
tree=ast.parse((R/'tools/town_r21_round3_report.py').read_text(encoding='utf-8'))
specs=next(ast.literal_eval(x.value) for x in tree.body if isinstance(x,ast.Assign) and any(isinstance(n,ast.Name) and n.id=='specs' for n in x.targets))
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',14)
screens=[];pairs=[]
for key,old,*_ in specs:
 name={'legacy-research':'research','legacy-cache':'cache'}.get(old,old)
 path=R/'verification/ui-r18/frames/hildegard-cutin-390.png' if name=='cutin' else (O/'round3' if name in ['art','victory','defeat'] else V)/'render'/f'{name}-390.png'
 ref=Image.open(O/'panels'/f'{key}.png').convert('RGB');actual=Image.open(path).convert('RGB');assert actual.size==ref.size==(390,844)
 pair=Image.new('RGB',(780,872),'#f4efe3');d=ImageDraw.Draw(pair);d.text((8,3),key+' · 시안 | 게임',font=font,fill='#111715');pair.paste(ref,(0,28));pair.paste(actual,(390,28));pair.save(C/f'{key}-side-by-side.png')
 pairs.append(pair);screens.append({'panel':key,'name':name,'render':path.relative_to(R).as_posix(),'comparison':(C/f'{key}-side-by-side.png').relative_to(R).as_posix()})
for b in range(7):
 review=Image.new('RGB',(1560,1744),'#f4efe3')
 for j in range(4):review.paste(pairs[4*b+j],((j%2)*780,(j//2)*872))
 review.save(C/f'review-{b+1}.jpg',quality=88)
def jpeg_budget(im,path,limit):
 q=90
 while True:
  im.save(path,quality=q,optimize=True,progressive=True)
  if path.stat().st_size<=limit:return {'size':list(im.size),'bytes':path.stat().st_size,'quality':q}
  q-=2;assert q>=8
sheet=Image.new('RGB',(1170,10*459),'#f4efe3');d=ImageDraw.Draw(sheet)
for i,pair in enumerate(pairs):sheet.paste(pair.resize((390,436),Image.Resampling.LANCZOS),((i%3)*390,(i//3)*459))
sheet=sheet.resize((900,round(sheet.height*900/1170)),Image.Resampling.LANCZOS);outputs={'owner_sheet':jpeg_budget(sheet,O/'owner-sheet.jpg',400000),'zooms':[]}
groups=[['shop','inn','research','recruit'],['depart','explore','cache','rest'],['summary','retreat','victory','defeat']]
for number,names in enumerate(groups,1):
 im=Image.new('RGB',(1200,1342),'#f4efe3')
 for j,name in enumerate(names):im.paste(pairs[next(i for i,x in enumerate(screens) if x['name']==name)].resize((600,671),Image.Resampling.LANCZOS),((j%2)*600,(j//2)*671))
 outputs['zooms'].append({'name':f'owner-zoom-{number}.jpg','panels':names,**jpeg_budget(im,O/f'owner-zoom-{number}.jpg',300000)})
(C/'comparison.json').write_text(json.dumps({'screens':screens,'outputs':outputs,'judgement':'pending direct visual review; no automatic same/different threshold'},ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(outputs,ensure_ascii=False))
