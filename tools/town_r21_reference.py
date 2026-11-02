"""Read the raster authority; crop panels and measure actual colored/ink pixels.

ROIs name semantic areas only. Reported bounds come from threshold masks inside
those areas, never from a hand-entered estimate of a rectangle. White full-height
gutters are detected on each board independently. No production raster is made.
"""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
import cv2
R=Path(__file__).resolve().parents[1]
REF=R.parents[1]/'outputs/r13-b-all'
O=R/'verification/town-r21'; M=O/'measure'; M.mkdir(parents=True,exist_ok=True)
(O/'panels').mkdir(exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=O/'before.json'
if not before.exists():
    before.write_text(json.dumps({p.relative_to(R).as_posix():sha(p) for f in ['project/ui','project/game','project/data','project/assets'] for p in (R/f).rglob('*') if p.is_file() and p.suffix!='.import'},indent=2),encoding='utf-8')
def bounds(mask,roi):
    x,y,w,h=roi; yy,xx=np.where(mask[y:y+h,x:x+w])
    return [int(xx.min()+x),int(yy.min()+y),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)] if len(xx) else None
panels={}
for p in sorted(REF.glob('*.png')):
    if p.name[:2] in ['09','10']:continue
    im=Image.open(p).convert('RGB'); a=np.array(im); h,w=a.shape[:2]
    if p.name.startswith('00'):rects=[(0,0,w,h)]
    else:
        white=(np.mean(np.min(a,axis=2)>235,axis=0)>.99) | ((np.std(a,axis=0).mean(axis=1)<7)&(np.mean(a,axis=(0,2))>235))
        cuts=[]
        for frac in [1/3,2/3]:
            candidates=np.where(white & (np.abs(np.arange(w)-w*frac)<w*.06))[0]
            if not len(candidates):raise ValueError('no raster gutter '+p.name)
            cuts.append((int(candidates.min()),int(candidates.max()+1)))
        rects=[(0,0,cuts[0][0],h),(cuts[0][1],0,cuts[1][0],h),(cuts[1][1],0,w,h)]
    for i,rect in enumerate(rects):
        key=p.stem+'-'+str(i); panel=im.crop(rect).resize((390,844),Image.Resampling.LANCZOS)
        panel.save(O/'panels'/f'{key}.png'); panels[key]=panel
        b=np.array(panel); ink=np.max(b,axis=2)<90; red=(b[:,:,0]>160)&(b[:,:,1]<110)&(b[:,:,2]<85)
        paper=b[(np.min(b,axis=2)>190)&(np.max(b,axis=2)-np.min(b,axis=2)<40)]
        color=lambda mask:np.median(b[mask],axis=0).astype(int).tolist() if np.any(mask) else None
        out={'source':str(p),'sha256':sha(p),'source_size':[w,h],'crop_xyxy':rect,'normalized':[390,844],
             'method':'gutter: >235 on >99% rows OR mean>235 and column std<7; Lanczos normalization; color threshold pixel bounds in named ROI (overlapping imagery is included; not a glyph baseline)',
             'median_ink_rgb':color(ink),'median_vermilion_rgb':color(red),'median_paper_rgb':np.median(paper,axis=0).astype(int).tolist(),
             'elements':{}}
        # Preserve pixel-derived boxes on every remaining panel for follow-up
        # work, without pretending that generic segmentation identifies a UI.
        for kind,mask in [('ink',ink),('vermilion',red)]:
            count,_,stats,_=cv2.connectedComponentsWithStats(mask.astype('uint8'),8)
            components=[{'box':[int(v) for v in row[:4]],'pixels':int(row[4])} for row in stats[1:] if row[4]>=8]
            out[kind+'_components']=sorted(components,key=lambda c:c['pixels'],reverse=True)
            glyphs=[c['box'][3] for c in components if 3<=c['box'][2]<=28 and 4<=c['box'][3]<=30]
            out[kind+'_small_component_height_median']=float(np.median(glyphs)) if glyphs else None
        rois={}
        if key.startswith('00'):
            rois={'logo':('ink',[0,0,160,230]),'location':('ink',[10,242,100,44]),'party':('ink',[12,546,365,80]),'depart':('red',[10,626,370,78]),'navigation':('ink',[12,786,365,57])}
        if key=='01-companions-0':rois={'back_title':('ink',[15,14,90,35]),'navigation_rule':('ink',[15,758,360,8]),'filter':('ink',[190,14,190,35])}
        if key=='01-companions-1':rois={'name':('ink',[15,53,330,80]),'identity':('ink',[15,141,245,26]),'tabs':('red',[15,486,120,47]),'hpmp':('red',[15,548,180,40]),'stats':('ink',[15,611,360,57]),'navigation_rule':('ink',[15,758,360,8])}
        if key=='01-companions-2':rois={'tabs':('red',[130,282,120,43]),'skill_title':('ink',[162,333,214,32]),'preview':('red',[160,463,220,42]),'navigation_rule':('ink',[15,758,360,8])}
        for name,(kind,roi) in rois.items():
            mask=ink if kind=='ink' else red
            out['elements'][name]={'search_roi':roi,'mask':kind,'pixel_bounds':bounds(mask,roi)}
        (M/f'{key}.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(390*4,844),'#f4efe3')
for i,k in enumerate(['00-town-approved-direction-0','01-companions-0','01-companions-1','01-companions-2']):sheet.paste(panels[k],(390*i,0))
sheet.save(O/'reference-first-four.png')
print(json.dumps({k:json.loads((M/f'{k}.json').read_text(encoding='utf-8'))['elements'] for k in list(panels)[:4]},ensure_ascii=False,indent=2))
