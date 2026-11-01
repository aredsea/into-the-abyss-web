"""Source-locked reference title vectors and background edit targets. No Git."""
from pathlib import Path
import json,hashlib
import cv2
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]; V=R/'verification/town-r21/round4'; A=R/'project/assets/ui-r21'
V.mkdir(parents=True,exist_ok=True); (V/'inputs').mkdir(exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
if not (V/'baseline.json').exists():
    files={p.relative_to(R).as_posix():sha(p) for f in ['project','tools'] for p in (R/f).rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.import','.pyc']}
    (V/'baseline.json').write_text(json.dumps({'files':files,'pck_bytes':(R/'docs/index.pck').stat().st_size},indent=2),encoding='utf-8')
specs=[
 ('formation','02-equipment-0',(18,50,227,96)),('equipment','02-equipment-1',(18,50,227,96)),('art','02-equipment-2',(18,50,280,96)),
 ('guild','04-guild-0',(18,53,159,195)),('recruit','04-guild-1',(18,53,158,247)),('research','04-guild-2',(18,53,147,242)),
 ('shop','05-commerce-0',(18,53,184,198)),('smithy','05-commerce-2',(18,53,214,198)),('inn','06-town-life-0',(14,61,181,188)),
 ('journal','06-town-life-1',(14,54,166,188)),('summary','06-town-life-2',(12,55,240,262)),
 ('explore','07-exploration-0',(18,0,204,66)),('cache','07-exploration-1',(18,39,270,93)),('rest','07-exploration-2',(18,39,234,93)),
 ('retreat','08-cards-states-1',(18,391,316,433)),
 ('victory','11-battle-results-1',(8,41,382,279)),('defeat','11-battle-results-2',(4,40,386,305)),
]
records=[]
for name,key,rect in specs:
    source=R/'verification/town-r21/panels'/f'{key}.png'; ar=np.array(Image.open(source).convert('RGB').crop(rect));h,w=ar.shape[:2];layers=[];counts={}
    for kind,color in [('ink','#111715'),('red','#d83219')]:
        mask=(ar.max(2)<108) if kind=='ink' else ((ar[:,:,0]>165)&(ar[:,:,1]<125)&(ar[:,:,2]<95))
        cs,_=cv2.findContours(mask.astype('uint8'),cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE);parts=[]
        for c in cs:
            if cv2.contourArea(c)<.22:continue
            pts=cv2.approxPolyDP(c,.16,True)[:,0,:]
            parts.append('M'+' L'.join(f'{x},{y}' for x,y in pts)+' Z')
        counts[kind]=len(parts); layers.append(f'<path fill="{color}" fill-rule="evenodd" d="'+ ' '.join(parts)+'"/>')
    (A/f'title-{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'+''.join(layers)+'</svg>',encoding='utf-8')
    records.append({'name':name,'source':key,'source_sha256':sha(source),'crop':rect,'contours':counts,'approximation_px':.16})
# These are inputs for image_gen removal, never production image cut-and-pastes.
backgrounds=[
 ('town','00-town-approved-direction-0',(0,0,390,530)),
 ('guild','04-guild-0',(0,0,390,447)),('recruit','04-guild-1',(0,0,390,505)),('research','04-guild-2',(0,0,390,447)),
 ('shop','05-commerce-0',(0,0,390,373)),('smithy','05-commerce-2',(0,0,390,482)),('inn','06-town-life-0',(0,0,390,430)),
 ('journal','06-town-life-1',(0,0,390,267)),('departure','03-preparation-0',(0,48,390,267)),
 ('explore','07-exploration-0',(0,98,390,505)),('cache','07-exploration-1',(0,94,390,482)),('rest','07-exploration-2',(0,97,390,482)),
 ('retreat','08-cards-states-1',(0,0,390,391)),('victory','11-battle-results-1',(0,279,390,590)),('defeat','11-battle-results-2',(0,305,390,590)),
 ('equipment','02-equipment-1',(0,0,390,190)),('cards','08-cards-states-0',(0,0,390,328)),('empty','08-cards-states-2',(0,0,390,435)),
]
for name,key,rect in backgrounds:
    Image.open(R/'verification/town-r21/panels'/f'{key}.png').crop(rect).save(V/'inputs'/f'{name}.png')
(V/'asset-provenance.json').write_text(json.dumps({'titles':records,'background_edit_targets':[{'name':n,'source':k,'crop':r} for n,k,r in backgrounds],'production_title_rasters':0},ensure_ascii=False,indent=2),encoding='utf-8')
print('Traced',len(records),'titles; prepared',len(backgrounds),'source edit inputs')
