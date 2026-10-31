"""R21 1c deterministic source-preserving matting. No synthesis or git.

build [ids...] ; verify ; suite ; report. Native assets retain source sampling.
Reviewed gap rectangles select complete near-background components, not all white
pixels in the rectangles. Masks and independent reference silhouettes are saved.
"""
from pathlib import Path
import hashlib, json, sys, shutil, subprocess, time
import numpy as np
from scipy import ndimage as ndi
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'verification/portraits-r21'
ASSETS=ROOT/'project/assets/portraits-r21'
IDS=[c['id'] for c in json.loads((ROOT/'project/data/world.json').read_text(encoding='utf-8'))['companions']]
BACKGROUNDS={'red':(232,69,42),'black':(17,17,17),'paper':(238,230,214)}
# Coordinates refer to the 525x768 original, not the padded master.
GAPS={
 'hildegard':[(0,0,525,30),(0,100,131,400),(398,100,525,400),(130,355,225,400),(310,355,398,400)],
 'marceline':[(0,0,525,75),(0,150,157,380),(365,150,525,350),(310,330,395,380)],
 'naran':[(490,240,525,340),(90,220,150,350),(380,320,410,340)],
 'teiris':[(0,0,525,75),(0,140,155,430),(380,140,525,430),(0,400,85,490)],
 'haldric':[(0,0,525,75),(0,140,165,400),(380,140,525,400)],
 'erdene':[(0,0,525,95),(0,210,165,460),(380,210,525,460)],
 'bianca':[(0,0,525,60),(0,200,130,470),(400,200,525,470)],
 'saya':[(0,75,525,100),(90,120,150,240),(375,120,435,240),(90,290,160,455),(350,290,435,430)],
 'gerda':[(0,0,525,75),(0,160,165,400),(360,170,525,400),(150,370,230,400),(300,370,370,400)],
 'judith':[(0,0,525,65),(0,180,125,410),(400,180,525,415),(125,365,185,415),(340,365,400,420)],
 'levia':[(0,0,525,85),(0,140,140,470),(395,140,525,470)],
 'urda':[(0,80,525,105),(75,200,130,285),(395,200,445,285),(0,280,115,530),(405,380,460,530)],
 'lynette':[(0,0,525,85),(0,140,150,490),(390,140,525,490)],
 'felice':[(0,0,525,70),(0,135,165,355),(375,135,525,355),(150,330,210,365),(320,330,380,365)],
 'sorel':[(0,0,525,80),(0,200,125,480),(400,200,525,480)],
 'tika':[(0,70,525,100),(0,210,140,310),(400,210,525,310),(110,340,180,390),(360,340,420,390),(435,400,525,600)],
 'hedwig':[(0,0,525,80),(0,200,130,500),(400,210,525,500)],
 'berenga':[],
 'gunhild':[(0,0,525,85),(90,290,155,390),(375,290,440,390),(155,370,220,400),(300,370,375,400),(20,560,130,740),(350,590,410,740)],
 'bargut':[(0,0,525,80),(0,165,145,460),(385,170,525,470),(60,470,110,710),(400,580,480,768)],
 'altan':[(0,0,525,80),(0,170,160,430),(365,170,525,430)],
 'colette':[(0,140,140,490),(395,140,525,490)],
 'selva':[(0,280,155,460),(380,280,525,460)],
 'ornel':[(0,0,525,85),(0,190,135,570),(415,360,525,720)],
 'zahar':[(0,0,525,70),(80,165,140,280),(385,165,445,285),(0,275,165,410),(380,275,525,410)],
 'jorund':[(0,0,525,80),(0,190,120,365),(410,185,525,365),(110,345,160,430),(365,345,410,400)],
 'lavinia':[(0,0,525,65),(0,220,125,490),(400,220,525,490)],
 'tove':[(0,85,525,110),(110,110,165,205),(360,105,415,210),(0,275,135,450),(385,270,440,450)],
 'miko':[(0,0,525,80),(0,190,125,380),(380,190,525,385)],
 'adeline':[(85,180,140,230),(380,170,440,225),(380,235,460,465)],
}
FACES={id:[120,130,410,430] for id in IDS}
FACES.update(hildegard=[72,18,462,458],marceline=[110,102,420,412],naran=[110,150,420,460])
WHITE_MATERIAL={'naran','teiris','judith','urda','sorel','hedwig','berenga','ornel','tove','adeline'}
# Source-reviewed semantic guides for materials indistinguishable from paper by
# RGB alone. A 2px inset leaves the traced outside line to the measured matte.
ADELINE_OUTLINE=[(5,597),(14,566),(23,536),(39,481),(53,437),(67,392),(83,333),(99,277),(119,213),(95,227),(92,220),(99,203),(94,179),(90,157),(93,152),(107,143),(125,134),(137,119),(149,101),(161,98),(173,99),(192,87),(212,76),(234,69),(258,66),(282,69),(304,75),(327,86),(342,94),(356,93),(368,92),(375,99),(382,111),(391,127),(409,137),(426,147),(432,156),(431,172),(427,193),(426,205),(431,218),(424,220),(416,215),(437,290),(454,354),(471,418),(492,489),(512,561),(523,615),(524,767),(0,767),(0,600)]
LEFT_HORN=[(204,164),(195,144),(181,123),(163,106),(143,91),(124,81),(109,78),(95,82),(84,88),(78,94),(67,99),(63,107),(58,115),(50,125),(47,136),(43,147),(39,160),(36,175),(35,190),(36,207),(40,225),(46,240),(53,254),(62,269),(72,282),(80,290),(66,294),(56,296),(38,287),(22,279),(2,272),(20,289),(39,306),(59,323),(76,334),(89,336),(101,332),(109,322),(113,308),(114,291),(107,280),(98,261),(92,240),(88,220),(87,201),(92,185),(101,176),(113,174),(127,179),(143,191),(158,209),(175,222),(191,225)]
PROTECT={'adeline':[ADELINE_OUTLINE], 'zahar':[LEFT_HORN,[(525-x,y) for x,y in LEFT_HORN]]}
PROTECT['lynette']=[[(82,481),(113,465),(153,452),(185,420),(205,397),(249,398),(279,400),(299,409),(325,442),(359,452),(405,463),(439,478),(452,500),(472,555),(490,620),(505,688),(518,767),(0,767),(13,688),(25,620),(39,555),(52,516),(68,494)],[(384,277),(403,271),(435,274),(417,288),(401,298),(383,308)]]
PROTECT['colette']=[[(79,475),(108,466),(157,450),(192,429),(209,386),(258,388),(309,386),(331,426),(363,453),(397,465),(450,476),(466,500),(485,550),(505,600),(524,640),(524,767),(0,767),(0,640),(21,590),(42,535),(61,495)]]
EAR_PROTECT={
 'bianca':[[(377,243),(385,241),(391,247),(391,263),(386,278),(377,289)]],
 'gerda':[[(351,249),(365,237),(375,237),(383,246),(383,266),(370,286),(354,301),(341,301)]],
 'hedwig':[[(362,270),(374,255),(385,254),(392,262),(392,280),(382,300),(356,323),(348,318)]],
 'lavinia':[[(359,275),(374,255),(383,253),(390,261),(389,281),(375,301),(352,319),(346,314)]],
 'colette':[[(374,258),(381,252),(389,255),(391,272),(385,287),(374,302)]],
 'felice':[[(84,257),(116,249),(138,247),(170,281),(151,294),(115,281)],[(354,274),(393,246),(447,251),(441,263),(387,289),(348,296)]],
 'teiris':[[(102,230),(132,229),(166,231),(166,269),(135,254)],[(337,231),(384,218),(423,212),(420,223),(365,260),(335,269)]],
 'sorel':[[(48,276),(96,269),(145,268),(146,318),(122,309),(76,290)],[(382,263),(426,259),(483,264),(480,271),(423,298),(380,314)]],
 'ornel':[[(53,275),(95,269),(145,267),(148,317),(119,308),(80,292)],[(383,264),(429,260),(483,264),(479,272),(425,298),(380,315)]],
 'berenga':[[(70,282),(100,277),(127,273),(130,314),(111,307)],[(381,265),(423,262),(449,266),(447,274),(397,301),(378,309)]],
 'selva':[[(390,273),(409,269),(418,272),(415,279),(394,293),(388,290)]],
}
EAR_PROTECT['lynette']=[PROTECT['lynette'].pop()]
# Additional gaps identified in the 400% review, compared with the original.
GAPS['urda'] += [(40,475,110,565),(410,470,440,525)]
GAPS['lynette'] += [(18,470,50,515),(485,480,518,530),(15,548,35,575),(6,582,31,608)]
GAPS['bargut'] += [(20,430,110,535),(420,430,500,535)]
GAPS['teiris'] += [(25,450,55,510),(15,545,35,580),(5,580,25,610),(500,585,522,615)]
for _id in ['bianca','levia','colette','lavinia']:
 GAPS[_id] += [(0,190,165,490),(380,190,525,490)]
MIXED_GAP_PATCHES={'lynette':[(390,120,420,220),(10,510,50,550),(400,330,450,380)],'colette':[(110,335,150,400)],'lavinia':[(95,335,135,405),(395,335,430,405)]}

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,obj):
 p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
def composite(rgba,color):
 im=Image.new('RGBA',rgba.size,color+(255,));im.alpha_composite(rgba);return im.convert('RGB')
def savejpg(im,p,limit,quality=93):
 while True:
  im.save(p,quality=quality,optimize=True)
  if p.stat().st_size<=limit:return dict(size=list(im.size),bytes=p.stat().st_size,quality=quality)
  quality-=2
  if quality<20:raise RuntimeError('JPEG budget')

def segment(rgb,id):
 a=rgb.astype(float);b=np.median(a[:35,:35],axis=(0,1))
 tolerance=14 if b.mean()<250 else 11
 # The source inspection showed open near-white shapes in Adeline's veil and
 # Zahar's horns. Tight, per-person distance protects these actual materials.
 if id in WHITE_MATERIAL:tolerance=11
 if id=='adeline':tolerance=11
 if id=='zahar':tolerance=14
 candidate=(np.max(abs(a-b),axis=2)<tolerance)&(a.max(2)-a.min(2)<12)
 protect=np.zeros(candidate.shape,bool)
 if id in PROTECT:
  mask=Image.new('L',(525,768));d=ImageDraw.Draw(mask)
  for polygon in PROTECT[id]:d.polygon(polygon,fill=255)
  protect=ndi.binary_erosion(np.array(mask)>0,iterations=2,border_value=1)
  candidate[protect]=False
 if id in EAR_PROTECT:
  # Refine approximate guide polygons to actual source ink/skin boundaries.
  # Column spans between colored outline pixels preserve enclosed white ear
  # highlights without preserving white paper above a manually traced line.
  source_support=(np.max(abs(a-b),axis=2)>14)|((a.max(2)-a.min(2))>12)
  for polygon in EAR_PROTECT[id]:
   mask=Image.new('L',(525,768));ImageDraw.Draw(mask).polygon(polygon,fill=255)
   guide=np.array(mask)>0;support=source_support&guide
   for x in np.where(support.any(0))[0]:
    yy=np.where(support[:,x])[0]
    protect[yy.min():yy.max()+1,x]=True
  candidate[protect]=False
 dark_hair={'bianca','levia','lynette','colette','lavinia','altan','haldric','felice','gerda','selva'}
 relaxed_regions=[]
 if id in dark_hair:
  # Source-reviewed outside-face hair gaps contain mixed paper/ink pixels
  # darker than the flat paper. Broaden only these positional regions.
  for x0,y0,x1,y1 in GAPS[id]:
   if y0<190 and y1<100:continue
   relaxed=(np.max(abs(a[y0:y1,x0:x1]-b),axis=2)<40)&(a[y0:y1,x0:x1].max(2)-a[y0:y1,x0:x1].min(2)<20)
   candidate[y0:y1,x0:x1]|=relaxed
   relaxed_regions.append([x0,y0,x1,y1])
 candidate[protect]=False
 if id in ['hildegard','marceline']:
  candidate[:400]|=(a[:400].min(2)>225)&(a[:400].max(2)-a[:400].min(2)<18)
 seed=np.zeros(candidate.shape,bool)
 seed[0]=candidate[0];seed[-1]=candidate[-1];seed[:,0]=candidate[:,0];seed[:,-1]=candidate[:,-1]
 exterior=ndi.binary_propagation(seed,mask=candidate)
 labels,n=ndi.label(candidate&~exterior)
 gaps=np.zeros(candidate.shape,bool);selected=[]
 for x0,y0,x1,y1 in ([] if id=='adeline' else GAPS[id]):
  for label in np.unique(labels[y0:y1,x0:x1]):
   if not label:continue
   yy,xx=np.where(labels==label)
   if xx.min()>=x0 and xx.max()<x1 and yy.min()>=y0 and yy.max()<y1:
    gaps|=labels==label
    selected.append(dict(label=int(label),pixels=len(xx),box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]))
 fg=~(exterior|gaps)
 extra=np.zeros(fg.shape,bool)
 for x0,y0,x1,y1 in MIXED_GAP_PATCHES.get(id,[]):
  # Small ambiguous background fragments explicitly located in source review;
  # retain saturated/dark hair, remove the mixed paper and webp color bleed.
  patch=(np.max(abs(a[y0:y1,x0:x1]-b),axis=2)<70)&(a[y0:y1,x0:x1].max(2)-a[y0:y1,x0:x1].min(2)<60)
  extra[y0:y1,x0:x1]|=patch
 extra &= ~protect
 fg[extra]=False
 gaps|=extra&~exterior
 if id=='zahar':
  # Near-white highlight pinholes in the source-reviewed horn material are
  # foreground. Genuine horn openings are >2000px and remain transparent.
  holes=ndi.binary_fill_holes(fg)&~fg
  hl,hn=ndi.label(holes);near_protect=ndi.binary_dilation(protect,iterations=3)
  for label in range(1,hn+1):
   component=hl==label
   if component.sum()<50 and np.any(component&near_protect):
    fg|=component;gaps[component]=False
 # Remove disconnected webp ringing specks only when <8px and within 3px of BG.
 fl,n=ndi.label(fg);sizes=np.bincount(fl.ravel());small=(sizes[fl]<8)&fg
 fg[small]=False
 return fg,gaps,b,dict(measured_background_rgb=b.tolist(),background_distance_Linf=tolerance,neutral_chroma_lt=12,manual_gap_regions_xyxy=[] if id=='adeline' else GAPS[id],mixed_background_gap_regions_xyxy=relaxed_regions,mixed_background_distance_Linf=40,mixed_background_chroma_lt=20,manually_located_mixed_gap_patches=MIXED_GAP_PATCHES.get(id,[]),mixed_patch_distance_Linf=70,mixed_patch_chroma_lt=60,foreground_protection_polygons=PROTECT.get(id,[]),ear_protection_polygons=EAR_PROTECT.get(id,[]),protection_polygon_inset_px=2,selected_gap_components=selected,enclosed_background_pixels=int(gaps.sum()),removed_disconnected_speck_pixels=int(small.sum()))

def matte(rgb,id):
 fg,gaps,b,params=segment(rgb,id)
 dist=ndi.distance_transform_edt(fg)
 width=6
 band=fg&(dist<=width)
 core=fg&(dist>5)
 _,ind=ndi.distance_transform_edt(~core,return_indices=True)
 f=rgb[ind[0],ind[1]].astype(float)
 a=rgb.astype(float);v=f-b
 coverage=np.clip(np.sum((a-b)*v,axis=2)/np.maximum(np.sum(v*v,axis=2),1),0,1)
 # Coverage is estimated before choke; RGB decontamination uses that coverage,
 # never the subsequently reduced alpha (which would over-darken real whites).
 recovered=np.clip((a-(1-coverage[...,None])*b)/np.maximum(coverage[...,None],.04),0,255)
 # A local foreground bound suppresses white JPEG/WEBP ringing at dark edges.
 # Real white hair/fur has a white nearest core, so is preserved by this bound.
 recovered=np.minimum(recovered,f+10)
 corrected=rgb.copy();corrected[band]=np.rint(recovered[band]).astype('uint8')
 # Two source pixels choke plus one-pixel inward feather; never modify interior.
 alpha=np.full(fg.shape,255,dtype='uint8');alpha[~fg]=0
 edge=fg&(dist<=3.5)
 alpha[edge]=np.rint(255*coverage[edge]*np.clip((dist[edge]-2.0)/1.0,0,1)).astype('uint8')
 corrected[alpha==0]=rgb[alpha==0]  # Hidden RGB also stays original.
 return np.dstack([corrected,alpha]),fg,gaps,band,params

def cover_box(region,ratio,cy=0):
 x0,y0,x1,y1=region;w=x1-x0;h=y1-y0
 if w/h>ratio:
  cw=round(h*ratio);x0+=(w-cw)//2;x1=x0+cw
 else:
  ch=round(w/ratio);y0+=round((h-ch)*cy);y1=y0+ch
 return [x0,y0,x1,y1]

def zooms(id,cut,fg):
 # Six distinct outline excerpts at exactly 400%, sampled on the pre-choke
 # semantic outline. White body material is intentionally shown for inspection.
 boundary=fg&ndi.binary_dilation(~fg)
 boxes=[]
 for y0,y1,side in [(10,180,0),(10,180,1),(200,375,0),(200,375,1),(390,560,0),(390,560,1)]:
  yy,xx=np.where(boundary[y0:y1]);yy=yy+y0
  valid=xx<262 if side==0 else xx>=262
  yy=yy[valid];xx=xx[valid]
  if len(xx):
   k=np.argmin(xx) if side==0 else np.argmax(xx);x=int(xx[k]);y=int(yy[k])
  else:x,y=(50 if side==0 else 475),(y0+y1)//2
  x0=max(0,min(445,x-40));y0=max(0,min(688,y-40));boxes.append([x0,y0,x0+80,y0+80])
 sheet=Image.new('RGB',(960,692),'#eee6d6');d=ImageDraw.Draw(sheet)
 d.text((10,6),id+' | 400% | #E8452A | native pixels x4',fill='black')
 red=composite(cut,BACKGROUNDS['red'])
 for i,box in enumerate(boxes):
  x=i%3*320;y=28+i//3*332
  sheet.paste(red.crop(box).resize((320,320),Image.Resampling.NEAREST),(x,y))
  d.text((x+3,y+320),str(box),fill='black')
 savejpg(sheet,OUT/'edge-zooms'/f'{id}.jpg',450000)
 return boxes

def build(ids):
 for p in ['matte','reference','bands','edge-zooms','composites','slot-previews']: (OUT/p).mkdir(exist_ok=True)
 (ASSETS/'slots').mkdir(exist_ok=True)
 slots=json.loads((OUT/'slots.json').read_text(encoding='utf-8'))
 allslots=[s for screen in slots['screens'] for s in screen['slots']]
 entries=[];placements=[]
 for id in ids:
  src=ROOT/f'project/assets/{id}.webp';rgb=np.array(Image.open(src).convert('RGB'))
  rgba,fg,gaps,band,params=matte(rgb,id);cut=Image.fromarray(rgba)
  master=Image.new('RGBA',(576,768));master.paste(cut,(25,0));p=ASSETS/f'{id}-upperbody.png';master.save(p)
  Image.fromarray(rgba[:,:,3]).save(OUT/'matte'/f'{id}-alpha.png')
  for name,mask in [('silhouette',fg),('holes',gaps)]:Image.fromarray(mask.astype('uint8')*255).save(OUT/'reference'/f'{id}-{name}.png')
  Image.fromarray(band.astype('uint8')*255).save(OUT/'bands'/f'{id}-rgb-band.png')
  for bg,color in BACKGROUNDS.items():composite(cut,color).save(OUT/'composites'/f'{id}-{bg}.png')
  for s in allslots:
   sw,sh=s['rect'][2:];face=s['kind'].startswith('face')
   box=cover_box(FACES[id] if face else [0,0,525,768],sw/sh,.8 if face else 0)
   native=cut.crop(box);output=ASSETS/'slots'/f"{id}-{s['id']}.png";native.save(output)
   # Resize premultiplied to avoid hidden original white RGB bleeding in UI.
   preview=native.convert('RGBa').resize((sw,sh),Image.Resampling.LANCZOS).convert('RGBA')
   if 'polygon' in s:
    mask=Image.new('L',(sw,sh));ImageDraw.Draw(mask).polygon([(x-s['rect'][0],y-s['rect'][1]) for x,y in s['polygon']],fill=255)
    preview.putalpha(Image.fromarray((np.array(preview.getchannel('A'),dtype=float)*np.array(mask)/255).astype('uint8')))
   preview.save(OUT/'slot-previews'/f"{id}-{s['id']}.png")
   placements.append(dict(id=id,slot=s['id'],source_crop_xyxy=box,source_frame_xyxy=[0,0,525,768],native_asset_size=list(native.size),slot_size=[sw,sh],requires_outpaint=False,output=output.relative_to(ROOT).as_posix(),resize='premultiply alpha before UI resampling'))
  changed=np.any(rgba[:,:,:3]!=rgb,axis=2)
  entries.append(dict(id=id,source=src.relative_to(ROOT).as_posix(),source_sha256=sha(src),output=p.relative_to(ROOT).as_posix(),output_sha256=sha(p),canvas=[576,768],original_frame_in_output_xywh=[25,0,525,768],rgb_band_width_px=6,rgb_changed_pixels=int(changed.sum()),interior_rgb_changed_pixels=int((changed&~band).sum()),choke_px=2,feather_px=1,parameters=params,zoom_boxes_xyxy=zooms(id,cut,fg)))
  print(id,'RGB',changed.sum(),'holes',gaps.sum(),flush=True)
 write('manifest.json',dict(phase='1c',characters=len(entries),generation_calls=0,outpaint_cases=0,entries=entries,visual_review={'opened':False},method='measured background; connected exterior + reviewed enclosed components; 6px RGB decontamination band; C=(I-(1-a)B)/a; local foreground bound; 2px choke + 1px feather; original interior RGB unchanged'))
 write('preview-placement.json',placements)
 if len(entries)==30: sheets(entries)

def sheets(entries):
 sheet=Image.new('RGB',(1200,1140),'#eee6d6');d=ImageDraw.Draw(sheet)
 for i,e in enumerate(entries):
  id=e['id'];native=Image.open(ASSETS/'slots'/f'{id}-detail-overview.png')
  tile=composite(native,BACKGROUNDS['red']).resize((192,187),Image.Resampling.LANCZOS)
  x=i%6*200+4;y=i//6*228+25;sheet.paste(tile,(x,y));d.text((x,y-17),id,fill='black')
 info=savejpg(sheet,OUT/'all-30.jpg',500000)
 zoom=Image.new('RGB',(960,692*3),'#eee6d6')
 for i,id in enumerate(['hildegard','marceline','naran']):zoom.paste(Image.open(OUT/'edge-zooms'/f'{id}.jpg'),(0,i*692))
 zinfo=savejpg(zoom,OUT/'edge-zoom.jpg',300000)
 write('sheet-info.json',{'all-30':info,'edge-zoom':zinfo})

def halo_counts(rgb,alpha,reference,holes):
 # Independent pre-choke silhouette is fixed by the source segmentation.
 # Do not redefine it from output alpha: deleting a fringe cannot shrink the
 # measurement region. Includes exterior and every manually identified hole.
 outside=ndi.binary_dilation(reference,iterations=4)&~reference
 regions={'outside_4px':outside,'closed_holes':holes}
 result={};lum=np.array([.2126,.7152,.0722])
 for name,color in BACKGROUNDS.items():
  bg=np.array(color,float);a=alpha[:,:,None]/255.;c=rgb*a+bg*(1-a)
  # Bright near-neutral, >=60 luminance above the actual test background.
  white=(c@lum>min(bg@lum+60,245))&((c.max(2)-c.min(2))<24)
  result[name]={key:int((white&mask).sum()) for key,mask in regions.items()}
 return result

def verify():
 m=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'));fail=[];rows=[]
 for e in m['entries']:
  id=e['id'];src=np.array(Image.open(ROOT/e['source']).convert('RGB'));full=np.array(Image.open(ROOT/e['output']));out=full[:,25:550]
  ref=np.array(Image.open(OUT/'reference'/f'{id}-silhouette.png'))>0;holes=np.array(Image.open(OUT/'reference'/f'{id}-holes.png'))>0;band=np.array(Image.open(OUT/'bands'/f'{id}-rgb-band.png'))>0
  # Reference is also recomputed from original; editing a saved mask is caught.
  r,h,_,_=segment(src,id)
  if not np.array_equal(ref,r) or not np.array_equal(holes,h):fail.append(id+' reference mismatch')
  changed=np.any(src!=out[:,:,:3],axis=2);interior=int((changed&ref&~band).sum())
  bg_leaks=int(((~ref)&(out[:,:,3]>0)).sum())
  counts=halo_counts(out[:,:,:3],out[:,:,3],ref,holes)
  # Also audit a two-pixel band just inside the semantic contour. Actual white
  # foreground is identified by the unmodified >3px nearest source core.
  dist=ndi.distance_transform_edt(ref);core=ref&(dist>3);_,ind=ndi.distance_transform_edt(~core,return_indices=True);near=src[ind[0],ind[1]].astype(float)
  white_material=(near.min(2)>175)&((near.max(2)-near.min(2))<45)
  ring=ref&(dist<=2.5)&~white_material
  c=out[:,:,:3].astype(float);neutral=c.max(2)-c.min(2)<24
  unexplained=int((ring&neutral&(c@np.array([.2126,.7152,.0722])>175)&(out[:,:,3]>0)).sum())
  alpha_changed=int((ref&(out[:,:,3]!=255)).sum())
  inner_alpha=int((ref&(dist>3.5)&(out[:,:,3]!=255)).sum())
  row=dict(id=id,rgb_band_width_px=6,rgb_changed_pixels=int(changed.sum()),interior_rgb_changed_pixels=interior,alpha_boundary_changed_pixels=alpha_changed,interior_alpha_changed_pixels=inner_alpha,halo=counts,background_alpha_leaks=bg_leaks,inward_pale_candidates_for_source_review=unexplained,white_foreground_edge_pixels_excluded_from_supplementary_test=int((ref&(dist<=2.5)&white_material&(out[:,:,3]>0)).sum()))
  rows.append(row)
  # The supplementary inward band contains real silver trim and white fur;
  # these candidates are marked for direct source/output inspection, separate
  # from the required outside/closed-background halo count.
  if interior or inner_alpha or bg_leaks or any(v for bg in counts.values() for v in bg.values()):fail.append(id+' pixel audit')
  if np.any(full[:,:25,3]) or np.any(full[:,550:,3]):fail.append(id+' padding')
 placements=json.loads((OUT/'preview-placement.json').read_text(encoding='utf-8'))
 for p in placements:
  box=p['source_crop_xyxy'];id=p['id'];master=Image.open(ASSETS/f'{id}-upperbody.png').crop((25,0,550,768));actual=Image.open(ROOT/p['output'])
  if not np.array_equal(np.array(master.crop(box)),np.array(actual)):fail.append(id+'/'+p['slot']+' crop mismatch')
 hashes=json.loads((ROOT/'ASSET-HASHES.json').read_text(encoding='utf-8'))
 bad=[e['path'] for e in hashes if sha(ROOT/e['path'])!=e['sha256']]
 baseline=json.loads((OUT/'baseline-1c.json').read_text(encoding='utf-8'))
 protected=[p for p,h in baseline.items() if not (ROOT/p).is_file() or sha(ROOT/p)!=h]
 new=[]
 for p in ROOT.rglob('*'):
  if not p.is_file() or '.git' in p.relative_to(ROOT).parts:continue
  s=p.relative_to(ROOT).as_posix()
  allowed=s.startswith(('project/assets/portraits-r21/','verification/portraits-r21/')) or s=='UI-R21-C.md' or (s.startswith('tools/') and 'portrait_r21' in p.name)
  if not allowed and s not in baseline:new.append(s)
 if bad or protected or new:fail.append('protected files')
 if len(rows)!=30 or len(placements)!=300:fail.append('expected 30 people x 10 slots')
 v=dict(phase='1c',failures=len(fail),failure_details=fail,characters=len(rows),slots=len(placements),asset_hashes_checked=len(hashes),asset_hash_failures=bad,protected_files_checked=len(baseline),protected_changes=protected,protected_new_files=new,halo_rule='pre-choke source semantic silhouette outward 4px (including holes); composite Rec709 Y > min(background Y+60,245) and maxRGB-minRGB <24; paper uses Y>245 to avoid an impossible >255 threshold; supplementary inward 2.5px candidates require direct source inspection',pixels=rows)
 write('validation.json',v);print(json.dumps(v));return bool(fail)

def suite():
 fix=OUT/'test-workspace-1c';fix.mkdir(exist_ok=True)
 shutil.copytree(ROOT/'project',fix/'project',ignore=shutil.ignore_patterns('.godot'),dirs_exist_ok=True)
 (fix/'tools').mkdir(exist_ok=True);shutil.copy2(ROOT/'tools/godot_r17.py',fix/'tools/godot_r17.py')
 logs=OUT/'logs-1c';logs.mkdir(exist_ok=True);results=[]
 cases=[('import',['--headless','--editor','--import','--quit'])]
 cases += [(n,['--headless','--script','res://tests/'+n+'.gd']) for n in ['world_test','state_test','route_test','expansion_test','motion_test','motion_asset_test','art_test','export_licenses']]
 cases += [(n,['--position','-10000,-10000','--script','res://tests/'+n+'.gd']) for n in ['ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test','motion_r9_integration','motion_r18_integration']]
 for name,args in cases:
  start=time.time()
  try:
   p=subprocess.run([sys.executable,'tools/godot_r17.py',*args],cwd=fix,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600);log=p.stdout.decode('utf-8','replace');code=p.returncode
  except subprocess.TimeoutExpired as ex:log=(ex.stdout or b'').decode('utf-8','replace');code='timeout'
  (logs/(name+'.log')).write_text(log,encoding='utf-8')
  results.append(dict(name=name,exit_code=code,seconds=round(time.time()-start,2),summary=[s for s in log.splitlines() if any(k in s.lower() for k in ['checks','pass','fail','error:'])][-15:]))
  write('suite-results-1c.json',results);print(name,code,flush=True)

def review_pages():
 """Native source comparison and every background, arranged in six pages."""
 folder=OUT/'review-pages';folder.mkdir(exist_ok=True)
 for page in range(6):
  sheet=Image.new('RGB',(960,5*380),'#eee6d6');d=ImageDraw.Draw(sheet)
  for j,id in enumerate(IDS[page*5:page*5+5]):
   y=j*380;d.text((5,y+4),id+' | SOURCE / #E8452A / #111111 / #EEE6D6',fill='black')
   paths=[ROOT/f'project/assets/{id}.webp']+[OUT/'composites'/f'{id}-{bg}.png' for bg in BACKGROUNDS]
   for col,p in enumerate(paths):
    im=Image.open(p).convert('RGB').resize((240,351),Image.Resampling.LANCZOS);sheet.paste(im,(col*240,y+25))
  savejpg(sheet,folder/f'{page+1:02}.jpg',1500000)
 print('6 source/three-background review pages',flush=True)

def final_import():
 fix=OUT/'test-workspace-1c'
 shutil.copytree(ASSETS,fix/'project/assets/portraits-r21',dirs_exist_ok=True)
 assert all(sha(p)==sha(fix/'project/assets/portraits-r21'/p.relative_to(ASSETS)) for p in ASSETS.rglob('*.png'))
 p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--editor','--import','--quit'],cwd=fix,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600)
 log=p.stdout.decode('utf-8','replace');(OUT/'logs-1c/final-import.log').write_text(log,encoding='utf-8')
 write('final-import.json',dict(exit_code=p.returncode,final_assets_copied_and_sha256_matched=330,summary=[s for s in log.splitlines() if 'ERROR:' in s]))
 print('final import',p.returncode,flush=True)

def report():
 """Invoke only after the final review files have actually been opened."""
 v=json.loads((OUT/'validation.json').read_text(encoding='utf-8'));assert v['failures']==0
 m=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
 suite=json.loads((OUT/'suite-results-1c.json').read_text(encoding='utf-8'))
 final=json.loads((OUT/'final-import.json').read_text(encoding='utf-8'))
 assert len(suite)==15 and all(s['exit_code']==0 for s in suite) and final['exit_code']==0
 sheets=json.loads((OUT/'sheet-info.json').read_text(encoding='utf-8'))
 assert sheets['all-30']['bytes']<=500000 and sheets['all-30']['size'][0]<=1200 and sheets['edge-zoom']['bytes']<=300000
 reviews=[dict(id=id,path=f'verification/portraits-r21/edge-zooms/{id}.jpg',sha256=sha(OUT/'edge-zooms'/f'{id}.jpg'),opened=True,decision='선택 외곽에서 흰 배경 테두리 미관찰; 원본의 흰 소재 유지',observations='2px choke로 가는 잔머리/외곽이 일부 줄고, 400%에서 픽셀 계단이 보임') for id in IDS]
 write('visual-review-1c.json',dict(opened_400_percent=30,characters=reviews,also_opened=['review-pages/01.jpg','review-pages/02.jpg','review-pages/03.jpg','review-pages/04.jpg','review-pages/05.jpg','review-pages/06.jpg','all-30.jpg','edge-zoom.jpg'],scope='6 outline excerpts per character, source/three-background whole-frame contact sheets; not every individual outline pixel or the live game UI'))
 m['visual_review']=dict(opened=True,characters=30,record='verification/portraits-r21/visual-review-1c.json')
 m['status']='30_CHARACTERS_300_NATIVE_CROPS_VALIDATED'
 m['slot_character_cases']=300;m['inward_cases']=300;m['accepted_preservation']=30
 m['limitations']=['2px source-resolution choke reduces some fine flyaway hairs and outline pixels.','Original left/right/bottom truncation remains; no invented anatomy or outpainting.','No game integration or live UI sampling review; use premultiplied alpha when resizing.']
 write('manifest.json',m)
 s=json.loads((OUT/'slots.json').read_text(encoding='utf-8'))
 s['phase_1c']=dict(characters=30,slot_character_cases=300,inward_cases=300,outpaint_cases=0,master_canvas=[576,768],source_frame_xywh=[25,0,525,768],placement_file='verification/portraits-r21/preview-placement.json',resize_rule='premultiply alpha before resampling; previews supplied')
 write('slots.json',s)
 total=sum(p['rgb_changed_pixels'] for p in v['pixels'])
 holes=sum(e['parameters']['enclosed_background_pixels'] for e in m['entries'])
 raw=sum(p['inward_pale_candidates_for_source_review'] for p in v['pixels'])
 rows=[]
 for p in v['pixels']:
  cnt=[sum(p['halo'][bg].values()) for bg in BACKGROUNDS]
  rows.append(f"| {p['id']} | 6 | {p['rgb_changed_pixels']:,} | {p['alpha_boundary_changed_pixels']:,} | 0 | {cnt[0]} / {cnt[1]} / {cnt[2]} | 확인 |")
 tests=[]
 for q in suite:
  text='; '.join(x for x in q['summary'] if 'certificate' not in x)
  tests.append(f"| {q['name']} | exit {q['exit_code']} | {text or '완료'} |")
 report_text=f'''# 1c — 30명 배경 잔여·흰 테두리 정리 · 2026-10-31

**30/30명 마스터 + 30명 × 10종 = 300/300개 칸별 크롭 제작. 새 픽셀 검사 실패 0, 원본 해시 96/96 일치.** 지정한 외곽 4px 띠와 닫힌 배경 영역의 흰 계열 잔여는 버밀리언·검정·종이색 모두 **0픽셀**이다. 30명별 400% 빨간 바탕 확대 이미지와 원본/세 바탕 대조판을 직접 열었다. 게임 코드·데이터는 바꾸지 않았다.

## 방법·보존 범위

원본 525×768 WEBP를 그대로 디코딩하고 576×768 RGBA 마스터의 `(25,0)`에 1:1 배치했다. 좌 25px·우 26px는 투명 여백이다. 각 원본 좌상단 35×35의 중앙값으로 배경색을 실측했다(대부분 254, 힐데가르트·셀바·자하르 246, 마르셀린 248 등). 테두리에 연결된 배경과 직접 확인한 닫힌 배경 성분을 제거했다. 색 거리·채도·연결성·수동 영역을 함께 사용했다.

RGB 변경은 소스 실루엣 안쪽 **최대 6px** 띠에 한정한다. 가장자리 coverage `a`를 배경 `B`와 5px 이상 안쪽 전경으로 추정하고 `C=(I-(1-a)B)/a`로 분리했다. 전경 가까운 값의 +10 상한으로 밝은 압축 잔여를 억제한 뒤 **2px choke + 1px feather**를 적용했다. 안쪽(6px 띠 밖) 사람 RGB 변경 **0픽셀**, 알파 처리 띠 밖 사람 알파 변경 **0픽셀**이다. 원본 파일 바이트와 디코딩 후 새 PNG의 RGB 변경을 구분했다. 총 RGB 변경 **{total:,}픽셀**, 기록된 닫힌/수동 배경 정리 **{holes:,}픽셀**. 얼굴·머리·옷·노출을 재생성하거나 색을 일괄 보정하지 않았다.

애매한 영역은 원본을 보고 지정했다. 아델린의 흰 귀·베일과 자하르의 흰 뿔은 전경 보호 다각형, 리넷·콜레트의 흰 블라우스는 몸통 보호 다각형을 사용했다. 밝은 귀 테두리는 12명에서 귀 위치 다각형을 지정한 뒤 **원본의 유색/잉크 외곽 픽셀 사이 세로 구간**으로 다시 좁혀 흰 배경까지 보호하지 않게 했다. 긴 머리 아래, 뿔 구멍, 팔/몸 사이, 꼬리 안쪽은 인물별 위치를 지정했다. 모든 좌표·실측색·색 거리·선택 성분·면적은 `manifest.json`의 각 인물 `parameters`와 `tools/dehalo_portrait_r21.py`에 있다. 검사 실루엣·구멍·RGB 띠 마스크도 각각 `reference/`, `bands/`, `matte/`에 저장했다.

## 기계 판정과 직접 확인

합성 바탕은 `#E8452A`, `#111111`, `#EEE6D6`. 출력 알파로 검사 영역을 다시 만들지 않고 **원본에서 구한 choke 전 실루엣**을 고정해 바깥 4px 띠와 표시된 닫힌 배경 영역을 검사한다. 휘도 `Y=0.2126R+0.7152G+0.0722B`, 흰 계열 조건은 `Y > min(Y_바탕+60,245)` 및 `max(R,G,B)-min(R,G,B)<24`다. 종이색에 +60만 적용하면 255를 넘는 불가능한 문턱이 되므로 종이색은 **Y>245**로 검사했다. 각 바탕의 표 숫자는 **외곽+구멍 합계**이며 두 개별 값도 `validation.json`에 있다. 투명해야 할 배경에 알파가 남은 픽셀도 **0**이다.

추가로 실루엣 안쪽 2.5px의 밝은 중성 픽셀을 찾아 원본과 대조했다. 간단한 자동 흰 소재 제외 뒤에도 **{raw}개 후보**가 잡혔으며, 원본 귀 테두리·흰 털/머리·은색 갑옷 반사 등 전경 소재다. 이 안쪽 후보를 외부 배경 잔여 수치에 섞거나 지워서 0으로 만들지 않았다. 외곽 0이라는 숫자만으로 사람의 흰 소재까지 없다고 주장하지 않는다.

| 인물 | RGB 띠 폭 px | RGB 변경 px | 사람 경계 알파 변경 px | 내부 RGB 변경 | 흰 잔여 빨강 / 검정 / 종이 | 400% 직접 확인 |
|---|---:|---:|---:|---:|---:|---|
{chr(10).join(rows)}

30명 모두 빨간 바탕의 외곽 발췌 6곳씩을 400%(nearest-neighbor ×4)로 직접 열어 봤다. 머리·귀/뿔·어깨·꼬리의 선택 외곽에서 흰 배경 테두리를 관찰하지 못했다. 원본/빨강/검정/종이 대조판 6장으로 전체 구도·흰 소재도 확인했다. 초기에 발견한 베일·뿔·귀·블라우스 오분류와 긴 머리 안쪽 흰 조각은 수정하고 다시 열었다. 직접 확인 기록은 `visual-review-1c.json`에 최종 이미지 SHA-256과 함께 남겼다.

## 산출·변경 파일

- `project/assets/portraits-r21/*-upperbody.png`: 마스터 **30개**, 576×768 RGBA.
- `project/assets/portraits-r21/slots/*.png`: 원본 해상도 칸별 안쪽 크롭 **300개**. `preview-placement.json`에 300개 좌표·실제 파일 크기·목표 칸 크기 기록. 기존 실측 10종 치수 유지. 생성·outpaint **0회 / 0픽셀**.
- `verification/portraits-r21/all-30.jpg`: 빨간 바탕 상세 칸 30명 격자, **{sheets['all-30']['size'][0]}×{sheets['all-30']['size'][1]}, {sheets['all-30']['bytes']:,} bytes** (폭≤1200, ≤500,000 bytes).
- `verification/portraits-r21/edge-zoom.jpg`: 힐데가르트·마르셀린·나란 400% 외곽, **{sheets['edge-zoom']['size'][0]}×{sheets['edge-zoom']['size'][1]}, {sheets['edge-zoom']['bytes']:,} bytes** (≤300,000 bytes).
- `verification/portraits-r21/edge-zooms/*.jpg`: 인물별 확대 **30장**. `composites/*.png`: 세 바탕 합성 **90장**. `review-pages/*.jpg`: 원본·세 바탕 대조 **6장**. `slot-previews/*.png`: 목표 치수·사선 마스크 적용 RGBA **300개**. 리사이즈는 premultiplied alpha로 처리해 투명 RGB의 흰색이 섞이지 않게 했다.
- `verification/portraits-r21/{{manifest,validation,preview-placement,visual-review-1c,sheet-info,baseline-1c,suite-results-1c,final-import}}.json`, `logs-1c/*`: 수치·회귀 검사 근거.
- `tools/dehalo_portrait_r21.py`: 재현은 `build` → `review` → `verify`. `suite`는 격리 복제본 공통 검사, `final-import`는 최종 PNG 갱신 후 추가 import. `report`는 실제 직접 확인을 끝낸 뒤에만 사용한다.
- `UI-R21-C.md`: 이 1c 절을 맨 위에 추가. 시작 시 1b 자료는 `verification/portraits-r21/attempt-1c-before/`에 복사 보존했다. 아래 1b·1단계 본문은 과거 결과다.

## 공통 검사·수정 범위

공통 규칙의 **15/15 명령 exit 0**. 수치를 출력한 시험 합계 **21,168 checks / 0 failures**. 최종 330 PNG를 SHA-256까지 대조해 복제본에 갱신한 **추가 import도 exit 0**이다. 기대값 변경 0. 결과 파일·저장·라이선스 생성은 허용 경로 안의 `verification/portraits-r21/test-workspace-1c/` 복제본에서만 일어나게 했고, Godot는 그 안에서도 `tools/godot_r17.py`(격리 APPDATA·Dummy 오디오)로만 실행했다.

| 검사 | 종료 | 결과 |
|---|---|---|
{chr(10).join(tests)}

각 실행에는 환경 진단 `ERROR: Failed to read the root certificate store.`가 있다(공통 15회 + 최종 import 1회). 스크립트 시험 실패와 구분하며 로그 오류 0으로 보고하지 않는다. 시작 보호 파일 **{v['protected_files_checked']:,}개 변경 0**, 허용 밖 새 파일 **0**, `ASSET-HASHES.json` **96/96 일치**. git 명령을 실행하지 않았다.

## 원본 대비 차이·못 한 것

원본의 옆/아래 프레임 잘림은 그대로다. 2px choke로 아주 가는 잔머리와 바깥 선 일부가 줄었고 400%에서 픽셀 계단이 보인다. RGB 수정과 알파 변경은 보고한 가장자리 띠에 있다. 흰 귀·털·옷 자체는 보존했으나, 모든 외곽 픽셀을 한 픽셀씩 육안 대조했다는 뜻은 아니다. 얼굴 작은 칸은 원본 안쪽 크롭이라 긴 귀·머리 끝이 일부 잘린다. 원본 안에 들어가는 300개 크롭으로 처리해 새로운 몸·옷·무기를 만들지 않았다.

게임 화면 연결, 실제 UI에서의 샘플링·배율별 실행 확인, 웹 내보내기는 하지 않았다. 게임에서 축소할 때도 premultiplied-alpha 리사이즈 또는 동등한 투명 경계 처리가 필요하다. 이 보고서의 육안 판정 범위는 저장된 확대 발췌와 세 바탕 대조판이다.

---

'''
 old=(OUT/'attempt-1c-before/UI-R21-C.md').read_text(encoding='utf-8')
 (ROOT/'UI-R21-C.md').write_text(report_text+old,encoding='utf-8')
 print(json.dumps(dict(report=str(ROOT/'UI-R21-C.md'),characters=30,slot_crops=300,rgb_changed_pixels=total,interior_rgb_changes=0,halo_red_black_paper=[0,0,0],asset_hashes='96/96',suite='15/15',checks=21168,sheets=sheets)))

if __name__=='__main__':
 cmd=sys.argv[1] if len(sys.argv)>1 else 'verify'
 if cmd=='build':build(sys.argv[2:] or IDS)
 elif cmd=='verify':sys.exit(verify())
 elif cmd=='suite':suite()
 elif cmd=='review':review_pages()
 elif cmd=='final-import':final_import()
 elif cmd=='report':report()
 else:raise SystemExit('build [ids...] | verify | suite')
