"""Read-only source inventory and procedural UI assets, never character artwork."""
from pathlib import Path
import hashlib,json,re,urllib.parse
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1]; O=R/'verification/reskin-r24'; O.mkdir(parents=True,exist_ok=True)
A=R/'project/assets/ui-r24'; A.mkdir(parents=True,exist_ok=True)
protected=list((R/'project/game').rglob('*'))+list((R/'project/data').rglob('*'))
protected += [R/'project/ui'/n for n in ['portrait_layout_r24.gd','character_portrait.gd','town_portrait_r21.gd','battle_face_r17.gd','portrait_rules_r22.gd','resource_gauge_r24.gd']]
protected += list((R/'project/assets/portraits-r24').rglob('*'))
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
if not (O/'protected-before.json').exists():
 (O/'protected-before.json').write_text(json.dumps({str(p.relative_to(R)):digest(p) for p in protected if p.is_file()},indent=2),encoding='utf-8')
inventory=[]
for p in sorted((R/'project/ui').glob('*.gd')):
 if 'screen' not in p.name:continue
 t=p.read_text(encoding='utf-8');inventory.append({'file':str(p.relative_to(R)),'functions':re.findall(r'^func (\w+)\(',t,re.M),'branches':sorted(set(re.findall(r'(?:screen|phase|scene|tab)=="([^"]+)"',t))),'states':[s for s in ['is_empty','disabled','confirm','save_error','pending','response','conflict','busy','locked','empty'] if s in t]})
(O/'source-inventory.json').write_text(json.dumps(inventory,ensure_ascii=False,indent=2),encoding='utf-8')
# All icons come from the approved stroke set; extensions share its 24-unit grid.
ref=R.parent/'r24-reskin-ref'; symbols=(ref/'icons.html').read_text(encoding='utf-8')
for name,paths in re.findall(r'<symbol id="i-([^"]+)"[^>]*>(.*?)</symbol>',symbols,re.S):
 (A/(name+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#16130F" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">'+paths+'</svg>',encoding='utf-8')
extras={'back':'<path d="M20 12H5m5.5-5.5L5 12l5.5 5.5"/>','shield':'<path d="m12 3 8 3v6c0 4-4 7-8 9-4-2-8-5-8-9V6z"/>','sword':'<path d="m5 19 3-3m-3-3 6 6M8 16 20 4l-1 6-8 8"/>','star':'<path d="m12 3 2.8 5.6L21 9.5 16.5 14l1.1 6.2L12 17.3l-5.6 2.9L7.5 14 3 9.5l6.2-.9z"/>','close':'<path d="m6 6 12 12M6 18 18 6"/>','person':'<circle cx="12" cy="7.5" r="3.2"/><path d="M5 21v-2a7 7 0 0 1 14 0v2"/>'}
for name,paths in extras.items():(A/(name+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#16130F" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">'+paths+'</svg>',encoding='utf-8')
# Bake the exact reference wash SVG with Chromium (SVG turbulence included).
from playwright.sync_api import sync_playwright
css=(ref/'base.css').read_text(encoding='utf-8');wash=urllib.parse.unquote(re.search(r'\.wash\{background:url\("data:image/svg\+xml;utf8,([^\"]+)',css).group(1))
(A/'wash.svg').write_text(wash,encoding='utf-8')
with sync_playwright() as pw:
 browser=pw.chromium.launch(headless=True);page=browser.new_page(viewport={'width':400,'height':280},device_scale_factor=1)
 page.set_content('<html style="background:transparent"><body style="margin:0;background:transparent"><img style="width:400px;height:280px" src="data:image/svg+xml,'+urllib.parse.quote(wash)+'"></body></html>')
 page.screenshot(path=str(A/'wash.png'),omit_background=True);browser.close()
# Tiny deterministic paper fibre tile, not an illustration or generated artwork.
import random
rng=random.Random(24);im=Image.new('RGBA',(160,160));pixels=im.load()
for y in range(160):
 for x in range(160):pixels[x,y]=(78,70,59,rng.choice([0,0,0,2,3,4,6,8]))
im.save(A/'paper-grain.png')
print('Inventoried',len(inventory),'screen files; protected',len(json.loads((O/'protected-before.json').read_text(encoding='utf-8'))),'files')
