"""Contact sheets for direct visual review of all round-nine UI states."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
R=Path(__file__).resolve().parents[1];V=R/'verification/town-r21/round9'
data=json.loads((V/'ui-results.json').read_text(encoding='utf-8'))
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',13)
for size in ['360x780','390x844','430x932','390x664','1280x800']:
    files=[p for p in data['captures'] if p.endswith('-'+size+'.png')]
    sheet=Image.new('RGB',(1040,1260),'#f4efe3');d=ImageDraw.Draw(sheet)
    for i,name in enumerate(files):
        x=(i%4)*260;y=(i//4)*420
        img=Image.open(V/'render'/name).convert('RGB');img.thumbnail((252,390),Image.Resampling.LANCZOS)
        sheet.paste(img,(x+(260-img.width)//2,y+24));d.text((x+4,y+3),name.replace('-'+size+'.png',''),font=font,fill='#111715')
    sheet.save(V/f'contact-{size}.jpg',quality=92)
    print(V/f'contact-{size}.jpg')
