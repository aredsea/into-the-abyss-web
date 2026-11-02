"""Four honest reference/game pairs; creation has a style anchor, no mockup."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';V=O/'round8';C=V/'compare';C.mkdir(exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',13)
specs=[('03-preparation-0','participate-four','원정 준비 · 자기 참전'),('03-preparation-0','command-four','원정 준비 · 지휘'),('00-town-approved-direction-0','create','만들기 · 개별 시안 없음, 마을 문법 참고'),('04-guild-1','meeting','첫 만남 · 개별 시안 없음, 길드 문법 참고')]
sheet=Image.new('RGB',(1200,1342),'#f4efe3');records=[]
for i,(ref,name,caption) in enumerate(specs):
 pair=Image.new('RGB',(780,872),'#f4efe3');d=ImageDraw.Draw(pair);d.text((8,4),caption+' | 게임',fill='#111715',font=font)
 for j,p in enumerate([O/'panels'/f'{ref}.png',V/'render'/f'{name}-390x844.png']):pair.paste(Image.open(p).convert('RGB').resize((390,844)),(j*390,28))
 pair.save(C/f'{name}.png');sheet.paste(pair.resize((600,671),Image.Resampling.LANCZOS),((i%2)*600,(i//2)*671))
 records.append({'reference':ref,'screen':name,'caption':caption})
for q in range(94,8,-2):
 sheet.save(O/'owner-zoom-8.jpg',quality=q,optimize=True,progressive=True)
 if (O/'owner-zoom-8.jpg').stat().st_size<=300000:break
(V/'comparison.json').write_text(json.dumps({'pairs':records,'size':list(sheet.size),'bytes':(O/'owner-zoom-8.jpg').stat().st_size,'quality':q,'direct_review':'pending'},ensure_ascii=False,indent=2),encoding='utf-8')
print('owner-zoom-8.jpg',sheet.size,(O/'owner-zoom-8.jpg').stat().st_size,'bytes')
