"""Independent PNG/DOM versus real Godot paint-layer captures. No golden rewrites."""
from pathlib import Path
import csv, json, hashlib
import cv2
import numpy as np
from PIL import Image
from scipy.ndimage import binary_erosion, distance_transform_edt
from trace_ink_r20 import layers, REF, STATES

R=Path(__file__).resolve().parents[1]; O=R/'verification/ui-r20'
geometry=json.loads((O/'ink-metadata.json').read_text(encoding='utf-8'))
native=json.loads((O/'r20-results.json').read_text(encoding='utf-8'))
dom=json.loads((O/'reference-dom.json').read_text(encoding='utf-8'))
source_cache={}; capture_cache={}

def source(name, layer, dim):
    key=(name,layer,tuple(dim))
    if key not in source_cache:
        color,coverage=layers(REF/(name+'.png'))[layer]
        source_cache[key]=(color,cv2.resize(coverage,tuple(dim),interpolation=cv2.INTER_LINEAR))
    return source_cache[key]

def actual(name,layer):
    key=(name,layer)
    if key not in capture_cache:
        capture_cache[key]=np.asarray(Image.open(O/f'layers/{name}-{layer}.png').convert('RGBA'))[:,:,3]/255.
    return capture_cache[key]

def metrics(ref,got):
    a=ref>=.5; b=got>=.5
    boundary_a=a^binary_erosion(a); boundary_b=b^binary_erosion(b)
    if not a.any() and not b.any(): return {'iou':1.,'hausdorff_px':0.,'reference_pixels':0,'native_pixels':0}
    if not a.any() or not b.any(): return {'iou':0.,'hausdorff_px':999.,'reference_pixels':int(a.sum()),'native_pixels':int(b.sum())}
    hd=max(distance_transform_edt(~boundary_a)[boundary_b].max(),distance_transform_edt(~boundary_b)[boundary_a].max())
    return {'iou':float((a&b).sum()/(a|b).sum()),'hausdorff_px':float(hd),'reference_pixels':int(a.sum()),'native_pixels':int(b.sum())}

def write(name,rows):
    (O/f'{name}.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
    with (O/f'{name}.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)

used=set(x['asset'] for s in STATES for x in native['measurements'][s+'-390']['inks'])
used={x.replace('battle-mask-','battle-mask-') for x in used}
asset_rows=[]
for name,a in geometry['assets'].items():
    assert hashlib.sha256((REF/a['source']).read_bytes()).hexdigest()==a['sha256']
    for i,layer in enumerate(a['layers']):
        got=actual(name,i); dim=[got.shape[1],got.shape[0]]
        color,ref=source(name,i,dim)
        m=metrics(ref,got)
        asset_rows.append({'asset':name,'layer':i,'color':color,'render_size':dim,
            'used':name in used,'polygons':layer['polygon_count'],'holes':layer['hole_count'],
            **m,'passed':m['iou']>=.97 and m['hausdorff_px']<=1.5})
write('asset-ink-metrics',asset_rows)

def reference_rect(state,kind):
    selector='img.edge-ink' if kind.startswith('edge-') else 'div.battle' if kind.startswith('mask-') else 'div.scene-gesture' if kind=='base' else 'img.target-bloom' if kind=='target-bloom' else 'div.sheet-gesture'
    return next(d['rect'] for d in dom[state] if d['selector'].startswith(selector))

def place(coverage,rect):
    x,y,w,h=rect
    # Warp pixel-center coordinates with linear alpha sampling. Border is
    # transparent; source and actual undergo exactly the same screen clipping.
    matrix=np.array([[w/coverage.shape[1],0,x],[0,h/coverage.shape[0],y]],np.float32)
    matrix[0,2]+=(w/coverage.shape[1]-1)/2
    matrix[1,2]+=(h/coverage.shape[0]-1)/2
    return cv2.warpAffine(coverage,matrix,(390,844),flags=cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)

state_rows=[]; position_rows=[]; overlap_rows=[]
for state in STATES:
    canvas=[{c:np.zeros((844,390)) for c in ['black','vermilion','paper']} for _ in range(2)]
    for ink in native['measurements'][state+'-390']['inks']:
        name=ink['asset']; a=geometry['assets'][name]; expected=reference_rect(state,ink['kind'])
        err=max(abs(v-w) for v,w in zip(expected,ink['rect']))
        position_rows.append({'state':state,'kind':ink['kind'],'reference_rect':expected,'native_rect':ink['rect'],'max_error_px':err,'passed':err<=.01})
        for i,layer in enumerate(a['layers']):
            got=actual(name,i); color,ref=source(name,i,[got.shape[1],got.shape[0]])
            pigment='paper' if name.startswith('battle-mask') else 'vermilion' if color[0]>100 else 'black'
            if pigment=='paper': ref=1-ref;got=1-got
            for j,(coverage,rect) in enumerate([(ref,expected),(got,ink['rect'])]):
                p=place(coverage,rect)
                # Each paint is an independently measured layer. Union the
                # same pigment's coverage; do not reclassify mixed black/red
                # pixels as a third paint color or erase the paper mask layer.
                canvas[j][pigment]=np.maximum(canvas[j][pigment],p)
    # Explicit paper backing on the actor heading is part of comp occlusion.
    # This is measured independently from Chromium, never inferred from ink.
    heading=next(d['rect'] for d in dom[state] if d['selector']=='h1.display')
    cover=place(np.ones((int(np.ceil(heading[3])),int(np.ceil(heading[2])))),heading)
    for c in canvas:
        for pigment in ['black','vermilion']:c[pigment]*=1-cover
    for pigment in canvas[0]:
        ref,got=canvas[0][pigment],canvas[1][pigment]
        m=metrics(ref,got)
        state_rows.append({'state':state,'color_layer':pigment,**m,'passed':m['iou']>=.97 and m['hausdorff_px']<=1.5})
        Image.fromarray(np.uint8(np.clip(ref,0,1)*255)).save(O/f'{state}-reference-{pigment}-coverage.png')
        Image.fromarray(np.uint8(np.clip(got,0,1)*255)).save(O/f'{state}-native-{pigment}-coverage.png')
    # Conservative full-label box intersections are allowed only within the
    # actual reference paint envelope. The R17 check separately asserts that
    # every glyph is in front of any intersecting ink.
    for text in native['measurements'][state+'-390']['labels']:
        x,y,w,h=text['rect']; x0=max(0,int(np.floor(x)));x1=min(390,int(np.ceil(x+w)))
        y0=max(0,int(np.floor(y)));y1=min(844,int(np.ceil(y+h)))
        if x1<=x0 or y1<=y0:continue
        ref=np.maximum(canvas[0]['black'],canvas[0]['vermilion'])>=.5
        got=np.maximum(canvas[1]['black'],canvas[1]['vermilion'])>=.5
        # A subpixel contour may round to a neighboring pixel, within the
        # required 1.5px edge tolerance. Larger new paint intrusions fail.
        envelope=cv2.dilate(ref.astype(np.uint8),np.ones((3,3),np.uint8)).astype(bool)
        extra=int((got&~envelope)[y0:y1,x0:x1].sum())
        overlap_rows.append({'state':state,'text':text['text'],'reference_box_ink_pixels':int(ref[y0:y1,x0:x1].sum()),'native_box_ink_pixels':int(got[y0:y1,x0:x1].sum()),'unexpected_pixels':extra,'passed':extra==0})
write('state-ink-metrics',state_rows);write('ink-position-errors',position_rows);write('ink-text-reference',overlap_rows)

old=json.loads((O/'r19-comparison-baseline.json').read_text(encoding='utf-8'))['pixel_comparison']
new=json.loads((O/'comparison-summary.json').read_text(encoding='utf-8'))['pixel_comparison']
mae=[{'state':a['state'],'r19_mae':b['mae_0_255'],'r20_mae':a['mae_0_255'],'reduction':b['mae_0_255']-a['mae_0_255'],'passed':a['mae_0_255']<b['mae_0_255']} for a,b in zip(new,old)]
write('mae-r19-r20',mae)
summary={'used_asset_layers':sum(r['used'] for r in asset_rows),'unused_assets':[k for k in geometry['assets'] if k not in used],
         'excluded_reference_assets':geometry.get('excluded_reference_assets',[]),
         'asset_failures':[r for r in asset_rows if r['used'] and not r['passed']],
         'state_failures':[r for r in state_rows if not r['passed']],
         'position_failures':[r for r in position_rows if not r['passed']],
         'text_failures':[r for r in overlap_rows if not r['passed']],
         'mae_failures':[r for r in mae if not r['passed']],
         'method':'Real Godot isolated paint captures from the production mesh renderer, registered with actual Control rectangles; source alpha unmixed from PNG palettes and independently positioned with approved Chromium DOM rectangles. Same-pigment layers form a set union before color compositing. Threshold 0.5; IoU on occupied pixels; symmetric Hausdorff on all boundary pixels, including every disconnected fleck and hole. Frame clipping and actor-heading paper backing retained. Full textured/glyph screenshot MAE is reported separately. Text test compares to the reference envelope with the 1.5px boundary allowance; R17 also verifies foreground stacking for every roster label.'}
(O/'ink-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
assert not any(summary[k] for k in ['asset_failures','state_failures','position_failures','text_failures','mae_failures'])
