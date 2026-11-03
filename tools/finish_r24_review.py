"""Compact review pages for native after captures, keeping individual PNGs."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,hashlib
R=Path(__file__).resolve().parents[1];O=R/'verification/finish-r24';D=O/'review';D.mkdir(exist_ok=True)
paths=sorted((O/'after').glob('*.png'));font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
pages=[]
for start in range(0,len(paths),8):
    sheet=Image.new('RGB',(1440,1670),'#dcd8ce');draw=ImageDraw.Draw(sheet)
    for i,p in enumerate(paths[start:start+8]):
        im=Image.open(p).convert('RGB');im.thumbnail((344,785));x=(i%4)*360+8;y=(i//4)*830+32
        sheet.paste(im,(x,y));draw.text((x,y-24),p.stem,font=font,fill='#111715')
    p=D/f'page-{start//8+1:02}.jpg';sheet.save(p,quality=94);pages.append(p.relative_to(R).as_posix())
(O/'visual-review-pending.json').write_text(json.dumps({'captures':len(paths),'pages':pages,'viewed':False,'files':[{'path':p.relative_to(R).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths]},indent=2),encoding='utf-8')
print(json.dumps({'captures':len(paths),'pages':len(pages)}))
