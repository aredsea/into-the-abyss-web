"""Trace the shipped display face into SVG; source English wording stays exact."""
from pathlib import Path
import json, hashlib, re
from PIL import Image, ImageDraw, ImageFont
import cv2, numpy as np
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round11'
font=R/'project/assets/fonts/AbyssDisplayR19.ttf'
source=json.loads((O/'source-titles.json').read_text(encoding='utf-8'))
specs={'recruit':(140,194,['Companion','introductions']),
       'shop':(166,145,['Marento','Trading','House']),
       'smithy':(196,145,["Hanna's",'Smithy'])}
rows=[]
for name,(w,h,lines) in specs.items():
    canonical=next(r['en'] for r in source['rows'] if r['id']==name)
    assert ' '.join(lines)==canonical
    scale=4;parts=[];heights=[]
    for line in lines:
        size=160
        while True:
            f=ImageFont.truetype(str(font),size);box=f.getbbox(line)
            if box[2]-box[0]<=(w-2)*scale:break
            size-=1
        heights.append((f,box))
    total=sum(b[3]-b[1] for _,b in heights);gap=max(4*scale,int((h*scale-total)/(len(lines)+1)))
    y=0
    for i,(line,(f,b)) in enumerate(zip(lines,heights)):
        im=Image.new('L',(w*scale,h*scale));ImageDraw.Draw(im).text((-b[0],y-b[1]),line,font=f,fill=255)
        contours,_=cv2.findContours((np.array(im)>100).astype('uint8'),cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE)
        paths=[]
        for c in contours:
            if cv2.contourArea(c)<1:continue
            pts=cv2.approxPolyDP(c,.35,True)[:,0,:]/scale
            paths.append('M'+' L'.join(f'{x:g},{yy:g}' for x,yy in pts)+' Z')
        parts.append('<path fill="'+('#d83219' if i==len(lines)-1 else '#111715')+'" fill-rule="evenodd" d="'+' '.join(paths)+'"/>')
        y+=b[3]-b[1]+gap
    # The same source-traced dry-brush negative space used by live town headings.
    grain=(R/'project/assets/ui-r21/type-drybrush.svg').read_text(encoding='utf-8')
    content=re.search(r'<path.*?/>',grain)[0]
    parts.append(f'<g transform="scale({w/134:g} {h/138:g})">{content}</g>')
    target=R/f'project/assets/ui-r21/title-{name}-en.svg'
    target.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'+''.join(parts)+'</svg>',encoding='utf-8')
    rows.append({'id':name,'canonical':canonical,'lines':lines,'svg':str(target.relative_to(R)),'font_sha256':hashlib.sha256(font.read_bytes()).hexdigest(),'contour_tolerance_px':.0875})
(O/'title-provenance.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print('English traced SVG titles',len(rows))
