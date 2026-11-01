"""Lossless C-slot deduplication. Original PNG assets are read-only.

Each AtlasTexture has exactly the original slot's dimensions and RGBA bytes.
WebP is decoded and compared, including RGB under fully transparent pixels.
"""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
O=R/'verification/town-r21/round3';O.mkdir(parents=True,exist_ok=True)
A=R/'project/assets/portraits-r21-web';(A/'masters').mkdir(parents=True,exist_ok=True);(A/'slots').mkdir(exist_ok=True)
placements=json.loads((R/'verification/portraits-r21/preview-placement.json').read_text(encoding='utf-8'))
ids=sorted({p['id'] for p in placements});rows=[]
for id in ids:
    src=R/'project/assets/portraits-r21'/f'{id}-upperbody.png'
    im=Image.open(src).convert('RGBA');dest=A/'masters'/f'{id}.webp'
    im.save(dest,lossless=True,quality=100,method=6,exact=True)
    decoded=Image.open(dest).convert('RGBA')
    assert np.array_equal(np.array(im),np.array(decoded)),f'{id}: WebP changed RGBA'
    rows.append({'id':id,'png_bytes':src.stat().st_size,'webp_bytes':dest.stat().st_size,'size':list(im.size),'rgba_sha256':hashlib.sha256(im.tobytes()).hexdigest()})
slot_rows=[]
for p in placements:
    id=p['id'];slot=p['slot'];x0,y0,x1,y1=p['source_crop_xyxy'];x0+=25;x1+=25
    image=Image.open(A/'masters'/f'{id}.webp').convert('RGBA').crop((x0,y0,x1,y1))
    source=Image.open(R/p['output']).convert('RGBA')
    assert source.size==image.size and source.tobytes()==image.tobytes(),f'{id}/{slot}: crop changed'
    path=A/'slots'/f'{id}-{slot}.tres'
    path.write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/portraits-r21-web/masters/'+id+'.webp" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2('+f'{x0}, {y0}, {x1-x0}, {y1-y0}'+')\nfilter_clip = true\n',encoding='utf-8')
    slot_rows.append({'id':id,'slot':slot,'size':list(image.size),'region':[x0,y0,x1-x0,y1-y0],'rgba_equal':True})
(R/'project/data/portrait-slots-r21.json').write_text(json.dumps(placements,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
report={'characters':len(ids),'slots':len(slot_rows),'failures':0,'png_slot_bytes':sum((R/p['output']).stat().st_size for p in placements),'png_master_bytes':sum(x['png_bytes'] for x in rows),'webp_bytes':sum(x['webp_bytes'] for x in rows),'masters':rows,'slot_checks':slot_rows}
(O/'portrait-pack.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['masters','slot_checks']}))
