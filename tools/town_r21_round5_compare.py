"""Reviewable reference|game pairs for both phone widths and the new editor."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';V=O/'round5';C=O/'compare-round5';C.mkdir(exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',15)
pairs=[];records=[]
specs=[('victory',390,'11-battle-results-1'),('defeat',390,'11-battle-results-2'),('victory',360,'11-battle-results-1'),('defeat',360,'11-battle-results-2'),('research-draft',390,'04-guild-2'),('research-saved',390,'04-guild-2')]
for name,width,refname in specs:
    source=(O/'round3' if name in ['victory','defeat'] else V)/'render'/f'{name}-{width}.png'
    actual=Image.open(source).convert('RGB');ref=Image.open(O/'panels'/f'{refname}.png').convert('RGB')
    (V/'render').mkdir(exist_ok=True)
    if name in ['victory','defeat']:actual.save(V/'render'/source.name)
    pair=Image.new('RGB',(780,872),'#f4efe3');ImageDraw.Draw(pair).text((8,3),f'{name} · {width}px · 시안 | 게임',font=font,fill='#111715')
    pair.paste(ref.resize((390,844)),(0,28));pair.paste(actual.resize((390,844)),(390,28))
    pair.save(C/f'{name}-{width}-pair.png');pairs.append(pair)
    records.append({'name':name,'width':width,'reference':refname,'render':source.relative_to(R).as_posix(),'pair':(C/f'{name}-{width}-pair.png').relative_to(R).as_posix()})
owner=Image.new('RGB',(1200,1342),'#f4efe3')
for i,pair in enumerate(pairs[:4]):owner.paste(pair.resize((600,671),Image.Resampling.LANCZOS),((i%2)*600,(i//2)*671))
q=90;dest=O/'owner-zoom-5.jpg'
while True:
    owner.save(dest,quality=q,optimize=True,progressive=True)
    if dest.stat().st_size<=300000:break
    q-=2
    assert q>8
research=Image.new('RGB',(1560,872),'#f4efe3');research.paste(pairs[4],(0,0));research.paste(pairs[5],(780,0));research.save(C/'research-review.jpg',quality=90)
(C/'comparison.json').write_text(json.dumps({'pairs':records,'owner_zoom':{'path':dest.relative_to(R).as_posix(),'bytes':dest.stat().st_size,'quality':q,'size':list(owner.size)},'status':'await direct review'},ensure_ascii=False,indent=2),encoding='utf-8')
print(dest,dest.stat().st_size)
