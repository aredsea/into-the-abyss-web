"""Remove only the baked Korean subtitle from the existing victory title trace."""
from pathlib import Path
import cv2,numpy as np,json,hashlib
from PIL import Image
R=Path(__file__).resolve().parents[1];V=R/'verification/town-r21/round5'
src=R/'verification/town-r21/panels/11-battle-results-1.png'
crop=(8,41,382,279);ar=np.array(Image.open(src).convert('RGB'));exclude=np.zeros(ar.shape[:2],np.uint8)
# Measured slanting subtitle band, wholly below the large English letters.
polygon=[(84,264),(310,241),(313,269),(84,289)]
cv2.fillPoly(exclude,[np.array(polygon,np.int32)],1)
ar=ar[crop[1]:crop[3],crop[0]:crop[2]];exclude=exclude[crop[1]:crop[3],crop[0]:crop[2]].astype(bool)
layers=[];counts={}
for kind,color in [('ink','#111715'),('red','#d83219')]:
    mask=(ar.max(2)<108) if kind=='ink' else ((ar[:,:,0]>165)&(ar[:,:,1]<125)&(ar[:,:,2]<95))
    if kind=='ink':mask &= ~exclude
    cs,_=cv2.findContours(mask.astype('uint8'),cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE);parts=[]
    for c in cs:
        if cv2.contourArea(c)<.22:continue
        pts=cv2.approxPolyDP(c,.16,True)[:,0,:];parts.append('M'+' L'.join(f'{x},{y}' for x,y in pts)+' Z')
    counts[kind]=len(parts);layers.append(f'<path fill="{color}" fill-rule="evenodd" d="'+ ' '.join(parts)+'"/>')
(R/'project/assets/ui-r21/title-victory.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="374" height="238" viewBox="0 0 374 238">'+''.join(layers)+'</svg>',encoding='utf-8')
(V/'title-provenance.json').write_text(json.dumps({'source':str(src),'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'crop':crop,'ink_subtitle_excluded_polygon':polygon,'contours':counts,'approximation_px':.16,'production_title_rasters':0},indent=2),encoding='utf-8')
print('Victory subtitle removed from vector trace',counts)
