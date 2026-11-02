from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
r=Path.cwd();o=r/'verification/town-r21';v=o/'round9';c=v/'compare';c.mkdir(exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',14)
specs=[('command-four','원정 준비 · 지휘'),('participate-four','원정 준비 · 자기 참전')]
sheet=Image.new('RGB',(1200,1320),'#f4efe3')
for i,(name,title) in enumerate(specs):
 pair=Image.new('RGB',(780,880),'#f4efe3');d=ImageDraw.Draw(pair)
 d.text((8,5),title+' | 승인 시안                          게임',fill='#111715',font=font)
 for j,p in enumerate([o/'panels/03-preparation-0.png',v/'render'/f'{name}-390x844.png']):pair.paste(Image.open(p).convert('RGB').resize((390,844)),(j*390,30))
 pair.save(c/f'{name}.png');sheet.paste(pair.resize((600,677),Image.Resampling.LANCZOS),(i*600,0))
sheet=sheet.crop((0,0,1200,677))
for q in range(94,8,-2):
 sheet.save(o/'owner-zoom-9.jpg',quality=q,optimize=True,progressive=True)
 if (o/'owner-zoom-9.jpg').stat().st_size<=300000:break
(v/'comparison.json').write_text(json.dumps({'pairs':specs,'size':list(sheet.size),'bytes':(o/'owner-zoom-9.jpg').stat().st_size,'quality':q,'direct_review':'pending','rules':'탐색 5회 → 휴식 → 층 보스; existing bg-explore/rest/departure only'},ensure_ascii=False,indent=2),encoding='utf-8')
print((o/'owner-zoom-9.jpg').stat().st_size)
