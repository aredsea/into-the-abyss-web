"""Trace only vermilion background ink; never trace faces or ship raster ink."""
from pathlib import Path
from PIL import Image
import cv2,numpy as np,json,hashlib
R=Path(__file__).resolve().parents[1];O=R/'project/assets/ui-r21';O.mkdir(exist_ok=True)
p=R/'verification/town-r21/panels/01-companions-1.png'
a=np.array(Image.open(p).convert('RGB'))
mask=((a[:,:,0]>185)&(a[:,:,1]<105)&(a[:,:,2]<65)&(np.arange(844)[:,None]<485)).astype('uint8')*255
# Isolated structural type/tabs are outside this clipping region. The threshold
# excludes the original dark red costume and all face/skin colors.
contours,_=cv2.findContours(mask,cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE)
parts=[];vertices=0
for c in contours:
    if cv2.contourArea(c)<1.5:continue
    pts=cv2.approxPolyDP(c,.45,True)[:,0,:];vertices+=len(pts)
    parts.append('M'+' L'.join(f'{x},{y}' for x,y in pts)+' Z')
(O/'town-vermilion.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="390" height="485" viewBox="0 0 390 485"><path fill="#d83219" fill-rule="evenodd" d="'+' '.join(parts)+'"/></svg>',encoding='utf-8')
(R/'verification/town-r21/measure/ink-trace.json').write_text(json.dumps({'source':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'mask':'R>185 G<105 B<65 y<485','contours':len(parts),'vertices':vertices,'approximation_px':.45,'production_raster_ink':False},indent=2),encoding='utf-8')
print('Vector ink:',len(parts),'contours,',vertices,'vertices')
for name,key,rect in [('trait-penguin','01-companions-1',(24,690,123,754)),('signature-guard','01-companions-2',(23,340,152,505))]:
    source=R/f'verification/town-r21/panels/{key}.png'
    im=Image.open(source).convert('RGB').crop(rect); a=np.array(im);h,w=a.shape[:2]
    layers=[];counts={}
    for kind,color,mask in [
        ('paper','#f4efe3',np.min(a,axis=2)>175),
        ('ink','#111715',np.max(a,axis=2)<105)]:
        contours,_=cv2.findContours(mask.astype('uint8')*255,cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE)
        parts=[]
        for c in contours:
            if cv2.contourArea(c)<1:continue
            pts=cv2.approxPolyDP(c,.3,True)[:,0,:]
            parts.append('M'+' L'.join(f'{x},{y}' for x,y in pts)+' Z')
        counts[kind]=len(parts)
        layers.append('<path fill="'+color+'" fill-rule="evenodd" d="'+' '.join(parts)+'"/>')
    (O/f'{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><path fill="#d83219" d="M0 0H{w}V{h}H0Z"/>'+''.join(layers)+'</svg>',encoding='utf-8')
    (R/f'verification/town-r21/measure/{name}-trace.json').write_text(json.dumps({'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'crop_xyxy':rect,'output_size':[w,h],'layers':counts,'approximation_px':.3,'production_raster':False,'meaning':'generated comp ink silhouette only; no game rule or original portrait derived'},indent=2),encoding='utf-8')
