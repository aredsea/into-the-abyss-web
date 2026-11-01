"""Trace only isolated graphic paint; no source faces/characters in the masks."""
from pathlib import Path
import cv2,numpy as np,json,hashlib
from PIL import Image
R=Path(__file__).resolve().parents[1];A=R/'project/assets/ui-r21';V=R/'verification/town-r21/round4'
specs=[('recruit','04-guild-1',(0,0,390,505),[(0,65,174,257)]),('shop','05-commerce-0',(0,0,390,373),[(0,221,149,299)]),('smithy','05-commerce-2',(0,0,390,482),[(0,267,128,388)]),('journal','06-town-life-1',(0,0,390,267),[(0,0,390,267)]),('departure','03-preparation-0',(0,48,390,267),[(213,0,390,219),(0,147,213,219)]),('summary','06-town-life-2',(0,0,390,279),[(241,0,390,279),(0,0,241,42)]),('victory','11-battle-results-1',(0,0,390,590),[(0,0,390,41),(0,279,390,400),(0,41,9,279),(383,41,390,279)])]
records=[]
for n,key,crop,regions in specs:
 src=R/f'verification/town-r21/panels/{key}.png';ar=np.array(Image.open(src).convert('RGB').crop(crop));h,w=ar.shape[:2]
 mask=(ar[:,:,0]>185)&(ar[:,:,1]<130)&(ar[:,:,2]<90);region=np.zeros((h,w),np.uint8)
 for x,y,r,b in regions:region[y:b,x:r]=1
 mask=mask&region.astype(bool);cs,_=cv2.findContours(mask.astype('uint8'),cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE);paths=[]
 for c in cs:
  if cv2.contourArea(c)<.25:continue
  pts=cv2.approxPolyDP(c,.18,True)[:,0,:];paths.append('M'+' L'.join(f'{x},{y}' for x,y in pts)+' Z')
 (A/f'accent-{n}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><path fill="#d83219" fill-rule="evenodd" d="'+ ' '.join(paths)+'"/></svg>',encoding='utf-8')
 records.append(dict(name=n,source=key,regions=regions,sha256=hashlib.sha256(src.read_bytes()).hexdigest(),contours=len(paths)))
# Small dry-brush holes traced from actual fixed-title stock, used only over large dynamic lettering.
ar=np.array(Image.open(R/'verification/town-r21/panels/04-guild-0.png').convert('RGB').crop((20,54,154,192)));dark=(ar.max(2)<108).astype('uint8')
enclosed=cv2.morphologyEx(dark,cv2.MORPH_CLOSE,np.ones((3,3),np.uint8))-dark
cs,_=cv2.findContours(enclosed,cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE);paths=[]
for c in cs:
 if not .1<cv2.contourArea(c)<5:continue
 pts=cv2.approxPolyDP(c,.1,True)[:,0,:];paths.append('M'+' L'.join(f'{x},{y}' for x,y in pts)+' Z')
(A/'type-drybrush.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="134" height="138" viewBox="0 0 134 138"><path fill="#f4efe3" d="'+' '.join(paths)+'"/></svg>',encoding='utf-8')
(V/'accent-provenance.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
print('Traced',len(records),'accent plates and dynamic type grain')
