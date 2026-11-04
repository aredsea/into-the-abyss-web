"""Bake the approved wash and review the shared Godot portrait framing locally."""
import json, re, sys
from urllib.parse import unquote
import numpy as np
from PIL import Image, ImageDraw, ImageOps
import portrait_r24 as p

REF=p.ROOT.parent/'r24-reskin-ref'
KINDS={'party_card':(86,96),'list_row':(88,93),'chip':(64,64),
       'hero':(340,428),'detail':(240,240),'battle_card':(84,64)}

def bake():
    from playwright.sync_api import sync_playwright
    css=(REF/'base.css').read_text(encoding='utf-8')
    encoded=re.search(r'\.wash\{background:url\("data:image/svg\+xml;utf8,([^"\n]+)',css)[1]
    svg=unquote(encoded)
    with sync_playwright() as driver:
        browser=driver.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True,
            args=['--disable-gpu','--no-sandbox'],downloads_path=str(p.OUT/'cache'))
        page=browser.new_page(viewport={'width':800,'height':560},device_scale_factor=1)
        page.set_content('<style>html,body{margin:0;background:transparent}svg{width:800px;height:560px}</style>'+svg)
        page.screenshot(path=str(p.ASSET/'wash.png'),omit_background=True)
        browser.close()
    p.write(p.OUT/'wash-source.json',{'source':str(REF/'base.css'),'selector':'.wash',
        'svg':svg,'source_sha256':p.sha(REF/'base.css'),'png_sha256':p.sha(p.ASSET/'wash.png'),
        'renderer':'local Chrome SVG filters, transparent 800x560; no network'})

def frame(m,w,h):
    head=m['head_bounds_xyxy'];height=max((m['eye_y']-m['top_y'])/.32,(m['shoulder_y']-m['top_y'])/.57,(head[2]-head[0])/(w/h*.92))
    width=height*w/h;cx=max(head[2]-width*.46,min(m['center_x'],head[0]+width*.46))
    return [cx-width/2,m['top_y']-height*.1,cx+width/2,m['top_y']+height*.9]

def render(id,w,h):
    m=LANDMARKS[id];box=frame(m,w,h)
    # Premultiplied-alpha resampling avoids black fringes at the matte boundary.
    im=Image.open(p.ASSET/'masters'/f'{id}.png').convert('RGBa')
    im=im.transform((w,h),Image.Transform.EXTENT,box,Image.Resampling.BICUBIC).convert('RGBA')
    arr=np.array(im);t=np.clip((np.arange(h)/(h-1)-.70)/.30,0,1)
    arr[:,:,3]=np.rint(arr[:,:,3]*(1-t*t*(3-2*t))[:,None]).astype('uint8')
    out=Image.new('RGBA',(w,h));wash=Image.open(p.ASSET/'wash.png').resize((w,round(h*.76)),Image.Resampling.LANCZOS)
    out.alpha_composite(wash,(0,round(h*.22)));out.alpha_composite(Image.fromarray(arr))
    return out,box

LANDMARKS=json.loads((p.ASSET/'landmarks.json').read_text(encoding='utf-8'))
def presentation():
    placements=[]
    for kind,dims in KINDS.items():
        for bg in ['red','paper']:
            after=Image.new('RGB',(1200,1200),p.BG['paper']);pair=after.copy()
            da=ImageDraw.Draw(after);dp=ImageDraw.Draw(pair)
            for i,id in enumerate(p.IDS):
                x=i%6*200;y=i//6*240;w,h=dims
                # Render at review resolution while keeping each slot's actual aspect.
                k=min(196/w,210/h);rw,rh=round(w*k),round(h*k)
                im,box=render(id,rw,rh);tile=p.comp(im,p.BG[bg]);after.paste(tile,(x+(200-rw)//2,y+25));da.text((x+4,y+4),id,fill='black')
                legacy={'party_card':'party-tall','list_row':'target-face','chip':'town-party-face','hero':'town-main','detail':'detail-overview','battle_card':'town-party-face'}[kind]
                old=Image.open(p.ROOT/f'project/assets/portraits-r21/slots/{id}-{legacy}.png')
                k=min(98/w,190/h);tw,th=round(w*k),round(h*k)
                old=ImageOps.fit(old,(tw,th),Image.Resampling.LANCZOS,centering=(.5,0))
                new,_=render(id,tw,th)
                pair.paste(p.comp(old,p.BG[bg]),(x,y+40));pair.paste(p.comp(new,p.BG[bg]),(x+100,y+40))
                dp.text((x+3,y+3),id,fill='black');dp.text((x+3,y+17),'BEFORE / AFTER',fill='black')
                if bg=='red':
                    m=LANDMARKS[id];height=box[3]-box[1]
                    placements.append({'id':id,'kind':kind,'target':list(dims),'source_crop_xyxy':box,
                        'crown_ratio':.1,'eye_ratio':(m['eye_y']-box[1])/height,
                        'shoulder_ratio':(m['shoulder_y']-box[1])/height,'fade':[.7,1.]})
            p.jpg(after,p.OUT/'slots'/f'{kind}-{bg}.jpg')
            p.jpg(pair,p.OUT/'comparisons'/f'{kind}-{bg}.jpg')
            if kind=='detail' and bg=='red':p.jpg(after,p.OUT/'all-30-red.jpg');p.jpg(pair,p.OUT/'slots-before-after.jpg')
    p.write(p.OUT/'presentation-placements.json',placements)
    print('presentation',len(placements),'wash',p.sha(p.ASSET/'wash.png'))

if __name__=='__main__':
    if sys.argv[1]=='bake':bake()
    else:presentation()
