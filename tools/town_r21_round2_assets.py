"""Trace approved ink/architecture and icons into vectors; never trace portraits/type."""
from pathlib import Path
import json, hashlib
import cv2
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
O=R/'verification/town-r21'; A=R/'project/assets/ui-r21'
baseline=O/'round2-before.json'
if not baseline.exists():
    baseline.write_text(json.dumps({p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for base in ['project','tools'] for p in (R/base).rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.import','.pyc']},indent=2),encoding='utf-8')
specs=[]
def trace(name,key,rect,layers=('ink',),exclude=()):
    source=O/'panels'/f'{key}.png'; a=np.array(Image.open(source).convert('RGB').crop(rect)); h,w=a.shape[:2]
    paths=[]; counts={}
    for kind in layers:
        mask=(np.max(a,axis=2)<125) if kind=='ink' else ((a[:,:,0]>170)&(a[:,:,1]<125)&(a[:,:,2]<95))
        for x,y,r,b in exclude: mask[y:b,x:r]=False
        contours,_=cv2.findContours(mask.astype('uint8'),cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE)
        parts=[]
        for c in contours:
            if cv2.contourArea(c)<.6:continue
            points=cv2.approxPolyDP(c,.22,True)[:,0,:]
            parts.append('M'+' L'.join(f'{x},{y}' for x,y in points)+' Z')
        counts[kind]=len(parts)
        paths.append('<path fill="'+('#111715' if kind=='ink' else '#d83219')+'" fill-rule="evenodd" d="'+' '.join(parts)+'"/>')
    content=''.join(paths)
    if name.startswith('nav-'): content=content.replace('#111715','#ffffff').replace('#d83219','#ffffff')
    (A/f'{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'+content+'</svg>',encoding='utf-8')
    specs.append(dict(name=name,source=str(source),sha256=hashlib.sha256(source.read_bytes()).hexdigest(),crop_xyxy=rect,excluded_xyxy=exclude,layers=counts,approximation_px=.22))
for name,x in [('home',42),('party',118),('gate',195),('bag',274),('journal',349)]:
    trace('nav-'+name,'01-companions-1',(x-14,773,x+14,800),('red',) if name=='party' else ('ink',))
trace('town-city-left','00-town-approved-direction-0',(0,330,103,458))
trace('town-city-right','00-town-approved-direction-0',(335,254,390,455),('ink','red'))
trace('town-depart','00-town-approved-direction-0',(135,631,376,698),('ink',))
trace('detail-city','01-companions-1',(286,0,390,141),('ink','red'))
trace('preparation-ruins','03-preparation-0',(0,48,390,267),('ink','red'),[(0,0,212,138)])
for name,rect in [('attack',(23,542,84,599)),('taunt',(23,615,84,672)),('guard',(23,688,84,745))]:
    trace('skill-'+name,'01-companions-2',rect)
for i,name in enumerate(['guild','shop','inn','smithy']):
    trace('facility-'+name,'00-town-approved-direction-0',(14+i*92,721,101+i*92,758),('ink',))
(O/'measure/round2-traces.json').write_text(json.dumps({'production_raster_ink':False,'traces':specs},ensure_ascii=False,indent=2),encoding='utf-8')
print('Traced',len(specs),'SVG assets; original portraits untouched')
