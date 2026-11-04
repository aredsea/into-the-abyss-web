"""Local source-preserving R24 portraits. All writes stay in this worktree."""
from pathlib import Path
import os, sys, json, hashlib, time
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'verification/portrait-r24'
ASSET=ROOT/'project/assets/portraits-r24'
SOURCES=json.loads((OUT/'source-map.json').read_text(encoding='utf-8'))
IDS=[e['id'] for e in SOURCES]
BG={'red':(232,69,42),'black':(17,17,17),'paper':(238,230,214)}
def write(path,obj):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def comp(im,b):
    bg=Image.new('RGBA',im.size,(*b,255));bg.alpha_composite(im);return bg.convert('RGB')
def jpg(im,p,limit=490000):
    p.parent.mkdir(parents=True,exist_ok=True)
    for q in range(93,19,-2):
        im.save(p,quality=q,optimize=True)
        if p.stat().st_size<=limit:break
def model():
    cache=OUT/'cache';cache.mkdir(parents=True,exist_ok=True)
    for key in ['NUMBA_CACHE_DIR','TEMP','TMP']:os.environ[key]=str(cache)
    import onnxruntime as ort
    os.environ['OMP_NUM_THREADS']='4'
    opts=ort.SessionOptions();opts.intra_op_num_threads=4;opts.inter_op_num_threads=1
    session=ort.InferenceSession(str(Path.home()/'.u2net/isnet-anime.onnx'),sess_options=opts,providers=['CPUExecutionProvider'])
    (OUT/'model').mkdir(parents=True,exist_ok=True)
    for row in SOURCES:
        p=OUT/'model'/f"{row['id']}.png"
        if p.exists():continue
        start=time.time();im=Image.open(row['matches'][0]).convert('RGB')
        arr=np.array(im.resize((1024,1024),Image.Resampling.LANCZOS)).astype('float32')
        arr=arr/max(float(arr.max()),1e-6)-np.array([.485,.456,.406],dtype='float32')
        pred=session.run(None,{session.get_inputs()[0].name:arr.transpose(2,0,1)[None]})[0][0,0]
        pred=(pred-pred.min())/max(float(pred.max()-pred.min()),1e-6)
        mask=Image.fromarray((pred*255).astype('uint8')).resize(im.size,Image.Resampling.LANCZOS)
        mask.save(p)
        print(row['id'],round(time.time()-start,2),flush=True)
    write(OUT/'model.json',{'model':'isnet-anime','model_sha256':sha(Path.home()/'.u2net/isnet-anime.onnx'),'providers':ort.get_available_providers(),'used':'CPUExecutionProvider'})

def sheets(stage='model'):
    for page in range(5):
        sheet=Image.new('RGB',(1200,1000),BG['paper']);d=ImageDraw.Draw(sheet)
        for i,id in enumerate(IDS[page*6:(page+1)*6]):
            im=Image.open(ROOT/f'project/assets/{id}.webp').convert('RGBA')
            if stage=='model':im.putalpha(Image.open(OUT/'model'/f'{id}.png'))
            else:im=Image.open(ASSET/'masters'/f'{id}.png')
            x=i%3*400;y=i//3*500
            shot=comp(im,BG['red']);shot.thumbnail((340,470));sheet.paste(shot,(x+(400-shot.width)//2,y+25))
            d.text((x+8,y+5),id,fill='black')
        jpg(sheet,OUT/f'{stage}-page-{page+1}.jpg',700000)

# Manual source-space eyes and shoulder landmarks, read from source/model sheets.
EYES=[247,299,236,285,302,256,295,248,236,287,313,285,247,274,272,267,275,288,259,233,245,270,292,271,306,282,282,291,282,280]
SHOULDERS=[385,405,390,428,445,402,440,390,385,427,454,440,390,410,417,420,417,430,409,379,404,415,442,418,444,424,420,445,425,425]
def largest(mask):
    labels,n=ndi.label(mask,np.ones((3,3)))
    sizes=np.bincount(labels.ravel());sizes[0]=0
    return labels==sizes.argmax(),labels,sizes
def components(alpha):
    labels,n=ndi.label(alpha>0,np.ones((3,3)));sizes=np.bincount(labels.ravel())[1:]
    return {'total':n,'small':int((sizes<400).sum()),'sizes':sorted(map(int,sizes),reverse=True)}
def crop_box(lm,ratio,face):
    eye=lm['eye_y'];top=lm['top_y'];head=lm['head_bounds_xyxy'];ey=.44 if face else .42
    h=max((eye-top)/(ey-.06),(head[2]-head[0])/(ratio*.94))
    if not face:h=max(h,(lm['shoulder_y']-top)/.55)
    w=h*ratio;cx=lm['center_x']
    # Optical centering yields to full ear/horn preservation.
    cx=max(head[2]-w*.47,min(cx,head[0]+w*.47))
    return [round(cx-w/2),round(eye-ey*h),round(cx+w/2),round(eye+(1-ey)*h)]
def edge_counts(rgba,reference):
    band=ndi.binary_dilation(reference,iterations=4)&~reference
    rows={}
    for name,bg in BG.items():
        arr=np.array(comp(Image.fromarray(rgba),bg)).astype(float)
        y=arr@np.array([.2126,.7152,.0722]);yb=np.dot(bg,[.2126,.7152,.0722])
        rows[name]=int((band&(y>min(yb+60,245))&(np.ptp(arr,axis=2)<24)).sum())
    return rows
def selftest():
    if (ASSET/'masters/adeline.png').exists():
        a=np.array(Image.open(ASSET/'masters/adeline.png'));ref=np.array(Image.open(OUT/'reference/adeline.png'))>0
    else:
        a=np.zeros((160,180,4),dtype='uint8');a[40:140,60:140]=[60,40,30,255];ref=a[:,:,3]>0
    clean=edge_counts(a,ref);bad=a.copy()
    ring=ndi.binary_dilation(ref,iterations=2)&~ref;bad[ring]=[255,255,255,255]
    for i in range(10):bad[8+i//5*12:11+i//5*12,8+i%5*12:11+i%5*12]=[255,255,255,255]
    counts=edge_counts(bad,ref);parts=components(bad[:,:,3])
    assert all(x==0 for x in clean.values()) and all(x>0 for x in counts.values()) and parts['small']==10
    Image.fromarray(bad).save(OUT/'injected-defects.png')
    jpg(comp(Image.fromarray(bad),BG['red']),OUT/'injected-defects-red.jpg')
    write(OUT/'detector-selftest.json',{'clean':clean,'injected_ring':counts,'injected_fragments':parts['small'],'passed':True,'reference':'fixed before injected defects; not derived from tested alpha','paper_threshold':'min(background_luminance+60,245)'})
def build():
    import dehalo_portrait_r21 as old
    # Source comparison found a long paper slit between Ornel's two hair strands.
    # Its component crosses the old y=570 guide, so select the full source slit.
    old.GAPS['ornel'] += [(0,0,150,768),(395,0,525,768)]
    for folder in [ASSET/'masters',ASSET/'slots',OUT/'reference',OUT/'edge-zooms',OUT/'before']:
        folder.mkdir(parents=True,exist_ok=True)
    selftest();entries=[];landmarks={}
    for i,row in enumerate(SOURCES):
        id=row['id'];src=Path(row['matches'][0]);rgb=np.array(Image.open(src).convert('RGB'))
        before=ROOT/f'project/assets/portraits-r21/{id}-upperbody.png'
        if not (OUT/'before'/before.name).exists():Image.open(before).save(OUT/'before'/before.name)
        model=np.array(Image.open(OUT/'model'/f'{id}.png'))
        source_fg,gaps,b,params=old.segment(rgb,id)
        fg=(model>=128)&source_fg
        if id=='teiris':
            # Reviewed paper wedge between blonde strands, outside the face.
            patch=rgb[180:250,100:160]
            fg[180:250,100:160]&=~((patch.min(2)>225)&(np.ptp(patch,axis=2)<18))
        core,labels,sizes=largest(fg)
        # Keep only the largest body plus substantive source-confirmed tail.
        kept=[]
        for label in range(1,len(sizes)):
            if sizes[label]>=400 and not np.any(core&(labels==label)):
                yy,xx=np.where(labels==label)
                if id in ['selva','miko']:
                    core|=labels==label;kept.append({'pixels':int(sizes[label]),'box':[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)],'reason':'source tail; reviewed against original'})
        fg=core;reference=fg.copy()
        dist=ndi.distance_transform_edt(fg);inside=dist>5
        _,indices=ndi.distance_transform_edt(~inside,return_indices=True)
        f=rgb[tuple(indices)].astype(float);v=f-b;a=rgb.astype(float)
        coverage=np.clip(np.sum((a-b)*v,axis=2)/np.maximum(np.sum(v*v,axis=2),1),0,1)
        recovered=np.clip((a-(1-coverage[...,None])*b)/np.maximum(coverage[...,None],.08),0,255)
        recovered=np.minimum(recovered,f+8)
        edge=fg&(dist<=5);corrected=rgb.copy();corrected[edge]=np.rint(recovered[edge]).astype('uint8')
        alpha=np.rint(255*np.clip((dist-1.25)/1.25,0,1)).astype('uint8')
        feather=fg&(dist<=2.5);alpha[feather]=np.rint(alpha[feather]*coverage[feather]).astype('uint8')
        # Choke can detach fine hairs; discard all resulting small islands.
        main,labels,sizes=largest(alpha>0);allowed=main.copy()
        for label in range(1,len(sizes)):
            if sizes[label]>=400:allowed|=labels==label
        alpha[~allowed]=0
        corrected[alpha==0]=0
        rgba=np.dstack([corrected,alpha]);im=Image.fromarray(rgba)
        im.save(ASSET/'masters'/f'{id}.png')
        Image.fromarray(reference.astype('uint8')*255).save(OUT/'reference'/f'{id}.png')
        eye=EYES[i];upper=(alpha>127)&(np.indices(alpha.shape)[0]<eye+35)
        yy,xx=np.where(upper);head=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
        lm={'eye_y':eye,'shoulder_y':SHOULDERS[i],'top_y':int(yy.min()),'head_bounds_xyxy':head,'center_x':262.5,'method':'manual eyes/shoulders; head extent from connected final alpha; source pixel coordinates','uncertainty_px':5}
        landmarks[id]=lm
        changed=np.any(corrected!=rgb,axis=2)&(alpha>0)
        stats={'id':id,'source':str(src),'source_sha256':sha(src),'output_sha256':sha(ASSET/'masters'/f'{id}.png'),'before_components':components(np.array(Image.open(before))[:,:,3]),'after_components':components(alpha),'white_outer_band':edge_counts(rgba,reference),'interior_rgb_changed':int((changed&(dist>5)).sum()),'edge_rgb_changed':int(changed.sum()),'retained_detached':kept,'background_rgb':b.tolist(),'landmarks':lm,'method':'stage1 isnet-anime + reviewed source gaps + 1px choke + 5px RGB decontamination'}
        entries.append(stats)
        # Six native 80px outline excerpts, enlarged exactly 4x.
        old.OUT=OUT
        old.zooms(id,im,reference)
        print(id,stats['after_components'],stats['white_outer_band'],flush=True)
    write(ASSET/'landmarks.json',landmarks);write(OUT/'validation.json',{'characters':30,'entries':entries})
    slots=[s for page in json.loads((ROOT/'verification/portraits-r21/slots.json').read_text(encoding='utf-8'))['screens'] for s in page['slots']]
    placements=[]
    for id in IDS:
        im=Image.open(ASSET/'masters'/f'{id}.png')
        for slot in slots:
            w,h=slot['rect'][2:];box=crop_box(landmarks[id],w/h,slot['kind'].startswith('face'))
            im.crop(box).save(ASSET/'slots'/f"{id}-{slot['id']}.png")
            placements.append({'id':id,'slot':slot['id'],'target':[w,h],'box':box,'eye_ratio':.44 if slot['kind'].startswith('face') else .42})
    write(OUT/'placements.json',placements)
    sheets('after')
    for bg in ['red','paper']:
        for slot in slots:
            sheet=Image.new('RGB',(1200,1200),BG['paper']);d=ImageDraw.Draw(sheet)
            for i,id in enumerate(IDS):
                x=i%6*200;y=i//6*240
                tile=comp(Image.open(ASSET/'slots'/f"{id}-{slot['id']}.png"),BG[bg]);tile.thumbnail((196,214))
                sheet.paste(tile,(x+(200-tile.width)//2,y+22));d.text((x+4,y+3),id,fill='black')
            jpg(sheet,OUT/'slots'/f"{slot['id']}-{bg}.jpg")
    detail=Image.open(OUT/'slots/detail-overview-red.jpg');jpg(detail,OUT/'all-30-red.jpg')
    edge=Image.new('RGB',(960,6*346),BG['paper'])
    for i,id in enumerate(['adeline','bargut','naran','ornel','saya','selva']):
        z=Image.open(OUT/'edge-zooms'/f'{id}.jpg');edge.paste(z.crop((0,0,960,346)),(0,i*346))
    jpg(edge,OUT/'edge-zoom.jpg',290000)
    sheet=Image.new('RGB',(1200,700),BG['paper']);d=ImageDraw.Draw(sheet)
    oldplace=json.loads((ROOT/'verification/portraits-r21/preview-placement.json').read_text(encoding='utf-8'))
    for i,id in enumerate(IDS):
        x=i%6*200;y=i//6*140
        before=Image.open(OUT/'before'/f'{id}-upperbody.png').crop((25,0,550,768))
        box=next(p['source_crop_xyxy'] for p in oldplace if p['id']==id and p['slot']=='detail-overview')
        pair=[before.crop(box),Image.open(ASSET/'slots'/f'{id}-detail-overview.png')]
        for col,im in enumerate(pair):
            t=comp(im,BG['red']).resize((98,96),Image.Resampling.LANCZOS);sheet.paste(t,(x+col*100,y+32))
        d.text((x+3,y+3),id+' BEFORE / AFTER',fill='black')
    jpg(sheet,OUT/'slots-before-after.jpg')

def compare():
    slots=[s for page in json.loads((ROOT/'verification/portraits-r21/slots.json').read_text(encoding='utf-8'))['screens'] for s in page['slots']]
    for slot in slots:
        for name,bg in [('red',BG['red']),('paper',BG['paper'])]:
            sheet=Image.new('RGB',(1200,1200),BG['paper']);d=ImageDraw.Draw(sheet)
            for i,id in enumerate(IDS):
                x=i%6*200;y=i//6*240
                d.text((x+3,y+3),id,fill='black');d.text((x+3,y+16),'BEFORE / AFTER',fill='black')
                paths=[ROOT/f"project/assets/portraits-r21/slots/{id}-{slot['id']}.png",ASSET/'slots'/f"{id}-{slot['id']}.png"]
                for col,p in enumerate(paths):
                    im=comp(Image.open(p),bg);im.thumbnail((98,202),Image.Resampling.LANCZOS)
                    sheet.paste(im,(x+col*100+(98-im.width)//2,y+34))
            jpg(sheet,OUT/'comparisons'/f"{slot['id']}-{name}.jpg")
    for page in range(6):
        sheet=Image.new('RGB',(960,1900),BG['paper']);d=ImageDraw.Draw(sheet)
        for i,id in enumerate(IDS[page*5:page*5+5]):
            y=i*380;d.text((4,y+3),id+' SOURCE / RED / BLACK / PAPER',fill='black')
            raw=Image.open(ROOT/f'project/assets/{id}.webp').convert('RGB')
            master=Image.open(ASSET/'masters'/f'{id}.png')
            for col,im in enumerate([raw]+[comp(master,b) for b in BG.values()]):
                im=im.resize((240,351),Image.Resampling.LANCZOS);sheet.paste(im,(col*240,y+25))
        jpg(sheet,OUT/'source-review'/f'{page+1}.jpg',1300000)

if __name__=='__main__':
    {'model':model,'build':build,'compare':compare,'selftest':selftest,'sheets':lambda:sheets(sys.argv[2] if len(sys.argv)>2 else 'model')}[sys.argv[1]]()
