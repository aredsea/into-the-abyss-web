"""Compose real Godot captures into review sheets and 360px animated WebP."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
r=Path(__file__).resolve().parents[1]; out=r/'verification/ui-r18'
catalog=json.loads((r/'project/data/character-art-r4.json').read_text(encoding='utf-8'))
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
sheets=[]
for width,height,field_h in [(390,844,288),(360,780,224)]:
 for offset in range(0,30,5):
  ids=list(catalog)[offset:offset+5]
  sheet=Image.new('RGB',(width*2+30,5*(field_h+32)+12),'#e3ded2'); d=ImageDraw.Draw(sheet)
  for row,id in enumerate(ids):
   y=12+row*(field_h+32)
   d.text((10,y),id+' / '+catalog[id]['fx']+' : cutin | contact',font=font,fill='#111715')
   for col,phase in enumerate(['cutin','impact']):
    im=Image.open(out/f'frames/{id}-{phase}-{width}.png').convert('RGB').crop((0,94,width,94+field_h))
    sheet.paste(im,(10+col*(width+10),y+24))
  file=f'contact-{width}-{offset//5+1:02d}.png';sheet.save(out/file);sheets.append(file)
sheet=Image.new('RGB',(360*5,264*6),'#111715');d=ImageDraw.Draw(sheet)
for i,id in enumerate(catalog):
 x=(i%5)*360;y=(i//5)*264
 sheet.paste(Image.open(out/f'frames/{id}-fx-only.png').convert('RGB'),(x,y+24))
 d.text((x+8,y+3),id+' / '+catalog[id]['fx'],font=font,fill='#f3efe3')
sheet.save(out/'all-30-effects.png')
previews=[]
for id,action in [('teiris','personal'),('naran','personal'),('hildegard','attack')]:
 paths=sorted((out/'previews').glob(f'{id}-{action}-*.png'))
 frames=[Image.open(p).convert('RGB') for p in paths]
 file=out/f'{id}-{action}-360.webp'
 frames[0].save(file,format='WEBP',save_all=True,append_images=frames[1:],duration=50,loop=0,quality=78,method=5)
 assert file.stat().st_size<=1500000
 check=Image.open(file); assert check.width==360 and check.n_frames>1
 previews.append({'file':file.name,'bytes':file.stat().st_size,'frames':check.n_frames,'source_frames':len(frames),'duration_ms':len(frames)*50,'width':check.width,'height':check.height,'source_fps':20,'source':'Godot framebuffer PNGs'})
 strip=Image.new('RGB',(360*4,780),'#111715')
 contact={'teiris':.887,'naran':1.1,'hildegard':.325}[id]
 for j,index in enumerate([5 if action=='personal' else 0,round((contact-.10)*20),round((contact+.09)*20),len(frames)-1]):
  strip.paste(frames[min(max(0,index),len(frames)-1)],(j*360,0))
 strip.save(out/f'{id}-{action}-preview-strip.png')
(out/'previews.json').write_text(json.dumps(previews,indent=2),encoding='utf-8')
html='<!doctype html><meta charset="utf-8"><title>R18 Godot review</title><style>body{background:#e3ded2;color:#111715;font:16px Arial;margin:24px}img{max-width:100%;height:auto}figure{display:inline-block;margin:10px}a{color:#9b2615}</style><h1>R18 · Godot frame captures</h1><p>360×780 animated previews, 20 fps. All visual effects are code drawn.</p>'
for p in previews: html+=f'<figure><img width="360" src="{p["file"]}"><figcaption>{p["file"]} · {p["bytes"]:,} bytes</figcaption></figure>'
html+='<p><a href="r18-results.json">Render / layout / timing results</a> · <a href="preservation-and-build.json">Preservation and export audit</a></p>'
for width in [390,360]: html+=f'<figure><img src="base-{width}.png"><figcaption>{width}px baseline</figcaption></figure>'
for file in sheets+['all-30-effects.png']: html+=f'<p><a href="{file}">{file}</a></p>'
(out/'index.html').write_text(html,encoding='utf-8')
print(json.dumps(previews,indent=2)); print(len(sheets),'contact sheets, all-30-effects.png, review index')
