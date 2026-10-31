from pathlib import Path
from PIL import Image
from collections import Counter
import numpy as np,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'verification/enemy-art-r21'
def measure(p):
 im=Image.open(p).convert('RGBA');a=np.array(im);m=a[:,:,3]>=128;rgb=a[:,:,:3]; h,w=m.shape
 colors,cts=np.unique(rgb[m],axis=0,return_counts=True)
 q=im.convert('RGB').quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE);qa=np.array(q); qc=Counter(qa[m].tolist());pal=q.getpalette()
 runs=Counter();alpha_runs=Counter()
 for axis in [0,1]:
  z=qa if axis==0 else qa.T;mask=m if axis==0 else m.T
  for row,maskrow in zip(z,mask):
   changes=np.flatnonzero(np.r_[True,(row[1:]!=row[:-1])|(maskrow[1:]!=maskrow[:-1]),True]);
   for s,e in zip(changes[:-1],changes[1:]):
    if maskrow[s] and 3<=e-s<=24:runs[int(e-s)]+=1
   changes=np.flatnonzero(np.r_[True,maskrow[1:]!=maskrow[:-1],True])
   for s,e in zip(changes[:-1],changes[1:]):
    if maskrow[s] and 3<=e-s<=24:alpha_runs[int(e-s)]+=1
 bbox=Image.fromarray((m*255).astype('uint8')).getbbox()
 return dict(file=str(p.relative_to(ROOT)).replace('\\','/'),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),size=[w,h],opaque_bbox=list(bbox),baseline_y=bbox[3]-1,baseline_fraction=round((bbox[3]-1)/h,5),opaque_pixels=int(m.sum()),partial_alpha_pixels=int(((a[:,:,3]>0)&(a[:,:,3]<255)).sum()),exact_rgb_colors=int(len(colors)),effective_palette_32=[{'hex':'#'+''.join(f'{v:02x}' for v in pal[k*3:k*3+3]),'weight':round(v/int(m.sum()),6)} for k,v in qc.most_common()],color_run_histogram_3_24=dict(sorted(runs.items())),silhouette_run_histogram_3_24=dict(sorted(alpha_runs.items())))
refs=[measure(ROOT/f'project/assets/src/{n}-v2.png') for n in ['executor','apprentice','orb','lantern']]
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'style-measurements.json').write_text(json.dumps(refs,ensure_ascii=False,indent=2),encoding='utf-8')



# Lossy/generated v2 references have no exact global integer grid. Estimate visible
# stair steps from the run length of extremal alpha-contour coordinates.
def visible_metrics(p):
 a=np.array(Image.open(p).convert('RGBA'));m=a[:,:,3]>=128;hist=Counter();edge=Counter()
 for mask,rgb in [(m,a[:,:,:3]),(m.T,a[:,:,:3].transpose(1,0,2))]:
  for reverse in [False,True]:
   z=mask[:,::-1] if reverse else mask;r=rgb[:,::-1] if reverse else rgb
   x=np.where(z.any(1),z.argmax(1),-1);cuts=np.flatnonzero(np.r_[True,x[1:]!=x[:-1],True])
   for s,e in zip(cuts[:-1],cuts[1:]):
    if x[s]>=0 and 5<=e-s<=16:hist[int(e-s)]+=1
   for row,k in enumerate(x):
    if k<0:continue
    length=0
    for px,valid in zip(r[row,k:],z[row,k:]):
     if not valid or max(px)>75:break
     length+=1
    if 3<=length<=32:edge[length]+=1
 pix=a[:,:,:3][m]; swatch=Image.fromarray(pix.reshape(1,-1,3))
 errors={}
 for k in [16,24,32,48]:
  q=swatch.quantize(colors=k,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
  errors[str(k)]=round(float(np.abs(np.array(swatch).astype(float)-np.array(q.convert('RGB')).astype(float)).mean()),3)
 return dict(block_estimate_px=hist.most_common(1)[0][0],block_histogram=dict(sorted(hist.items())),outline_dark_run_median_px=int(np.median(list(edge.elements()))),outline_dark_run_histogram=dict(sorted(edge.items())),palette_mean_absolute_rgb_error=errors)
allpix=[]
for r in refs:
 p=ROOT/r['file'];r.update(visible_metrics(p));a=np.array(Image.open(p).convert('RGBA'));pix=a[:,:,:3][a[:,:,3]>=128];allpix.append(pix[::7][pix[::7].max(axis=1)>=35])
pix=np.concatenate(allpix); swatch=Image.fromarray(pix.reshape(1,-1,3));q=swatch.quantize(colors=31,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE);palette=[[19,12,19]]+[q.getpalette()[i*3:i*3+3] for i in range(31)]
colors=sorted(palette,key=lambda c:sum(c));values=sorted([round(.2126*c[0]+.7152*c[1]+.0722*c[2],2) for c in palette])
for r in refs:
 r['outline_and_shading_note']='Outline is estimated from inward dark runs (all RGB channels <=75), not a claim of exact stroke width. Shading is measured through palette luminance distribution; material ramp observations are visual.'
spec={'references':refs,'measurement_notes':['All measurements use alpha>=128 foreground. v2 sources have generated gradients, partial alpha and irregular grids; exact native palette/grid is absent.','block_estimate_px = modal 5..16 px extremal silhouette plateau; target is rounded median across four references.','Raw color counts are not claimed to be a limited authored palette; 32-color quantization is the reproducible production approximation.','Existing source bytes are immutable; cleanup applies only to new images.'], 'target':{'canvas':[1120,1400],'block_px':int(round(np.median([r['block_estimate_px'] for r in refs]))),'palette_max_colors':32,'palette_rgb':palette,'palette_luminances':values,'outline_blocks':[1,2],'material_shading_bands':[3,7],'lighting':'upper left, broad stepped highlights and lower-right shadow, as visually checked in references','baseline_y':1329,'baseline_fraction':.95,'alpha_values':[0,255],'dither':False,'grade_bbox_targets':{'mob':[680,670],'chief':[790,980],'boss':[1040,1240]},'grade_note':'Art-direction size targets for preview, not source gameplay numbers. chief uses original elite id listed by zone.chiefs.'}}
(OUT/'style-spec.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'target':spec['target'],'measurements':[{k:r[k] for k in ['file','block_estimate_px','outline_dark_run_median_px','palette_mean_absolute_rgb_error']} for r in refs]},indent=2))
patches={'executor':(600,450,730,620),'apprentice':(260,200,420,350),'orb':(350,300,600,600),'lantern':(450,700,540,900)}
for r in refs:
 n=Path(r['file']).stem.replace('-v2',''); region=patches[n]; a=np.array(Image.open(ROOT/r['file']).convert('RGBA').crop(region));rgb=a[:,:,:3][a[:,:,3]>=128];lum=rgb@np.array([.2126,.7152,.0722]);hist=np.histogram(lum,bins=np.arange(0,289,32))[0];active=[{'luminance_bin':[int(i*32),int(i*32+31)],'fraction':round(int(v)/len(rgb),4)} for i,v in enumerate(hist) if v/len(rgb)>=.05]
 r['shading_probe']={'region':list(region),'method':'32-luminance-wide bins with >=5% opaque area','effective_bands':len(active),'bands':active}
spec['references']=refs
spec['target']['material_shading_bands_measured']=[r['shading_probe']['effective_bands'] for r in refs]
(OUT/'style-spec.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2),encoding='utf-8')
print('shade probes',[(Path(r['file']).stem,r['shading_probe']['effective_bands']) for r in refs])
