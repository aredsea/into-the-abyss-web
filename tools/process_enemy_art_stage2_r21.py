"""Stage two: approved deterministic pixel processing and 100-enemy contact sheets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import json,hashlib,math
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/enemy-art-r21';ASSETS=ROOT/'project/assets/enemies-r21'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def save(p,obj):p.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def components(m):
 h,w=m.shape;seen=np.zeros_like(m);groups=[]
 for y,x in zip(*np.where(m)):
  if seen[y,x]:continue
  stack=[(y,x)];seen[y,x]=True;g=[]
  while stack:
   yy,xx=stack.pop();g.append((yy,xx))
   for dy,dx in [(1,0),(-1,0),(0,1),(0,-1)]:
    ny,nx=yy+dy,xx+dx
    if 0<=ny<h and 0<=nx<w and m[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;stack.append((ny,nx))
  groups.append(g)
 return groups
def measure(p):
 im=Image.open(p);a=np.array(im.convert('RGBA'));m=a[:,:,3]==255;bb=im.getbbox();c=np.unique(a[:,:,:3][m],axis=0);pal=set(map(tuple,read(OUT/'style-spec.json')['target']['palette_rgb']))
 return {'size':list(im.size),'mode':im.mode,'bytes':p.stat().st_size,'sha256':sha(p),'opaque_bbox':list(bb),'bbox_size':[bb[2]-bb[0],bb[3]-bb[1]],'baseline_y':bb[3]-1,'opaque_pixels':int(m.sum()),'rgb_colors':len(c),'partial_alpha_pixels':int(((a[:,:,3]>0)&(a[:,:,3]<255)).sum()),'transparent_nonzero_rgb_pixels':int(((a[:,:,3]==0)&(a[:,:,:3].max(2)>0)).sum()),'exact_grid_10px':np.array_equal(a,np.repeat(np.repeat(a[::10,::10],10,0),10,1)),'palette_membership':all(tuple(v) in pal for v in c),'logical_components':len(components(m[::10,::10]))}
def process(req,rec,spec,plan):
 id=req['id'];raw=OUT/'generated-originals/stage2'/f"{id}-a{rec['attempt']}.png";im=Image.open(raw).convert('RGBA');a=np.array(im);a[:,:,3]=np.where(a[:,:,3]>=128,255,0);a[a[:,:,3]==0,:3]=0;clean=Image.fromarray(a);bb=clean.getbbox()
 if not bb:raise ValueError(id+' empty alpha')
 crop=clean.crop(bb);grade=req['grade'];maxw,maxh=spec['grade_bbox_targets'][grade];scale=min(maxw/crop.width,maxh/crop.height);lw=max(1,round(crop.width*scale/10));lh=max(1,round(crop.height*scale/10));cap={'mob':175000,'chief':450000,'boss':680000}[grade]
 while True:
  a=np.array(crop.resize((lw,lh),Image.Resampling.NEAREST));m=a[:,:,3]>=128
  if m.sum()*100<=cap or min(lw,lh)<=2:break
  factor=min(.99,math.sqrt(cap/(m.sum()*100)));lw=max(1,int(lw*factor));lh=max(1,int(lh*factor))
 removed=0
 for group in components(m):
  if len(group)<3:
   for y,x in group:m[y,x]=False
   removed+=len(group)
 pal=np.array(spec['palette_rgb'],dtype=np.int32);rgb=a[:,:,:3].astype(np.int32);idx=((rgb[:,:,None,:]-pal[None,None,:,:])**2).sum(3).argmin(2);rgba=np.zeros((lh,lw,4),dtype=np.uint8);rgba[:,:,:3]=pal[idx].astype(np.uint8);rgba[:,:,3]=m.astype(np.uint8)*255;pad=np.pad(m,1);inside=pad[1:-1,1:-1]&pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:];rgba[m&~inside,:3]=pal[0];rgba[~m,:3]=0;low=Image.fromarray(rgba);low=low.crop(low.getbbox());canvas=Image.new('RGBA',(112,140));canvas.paste(low,((112-low.width)//2,133-low.height));dest=ASSETS/f'{id}.png';canvas.resize((1120,1400),Image.Resampling.NEAREST).save(dest,optimize=True);e=req['source']
 return {'id':id,'name':e['name'],'family':e['family'],'sample_grade':grade,'source_grade':e['grade'],'is_zone_chief':req['is_zone_chief'],'zone':e['zone'],'role':e['role'],'weakness_metadata':e['weak'],'intrinsic_element':'없음 (weak is metadata only)','source_description':e['looks'],'source_record':e,'source_paths':[{'path':plan['source_path'],'selector':f'enemies[id={id}]','sha256':plan['source_sha256']}],'prompt':rec['prompt'],'reference_paths':rec['reference_paths'],'generation_tool':rec['generation_tool'],'attempt':rec['attempt'],'original_tool_file':rec['original_tool_file'],'generated_original_file':raw.relative_to(ROOT).as_posix(),'generated_original_sha256':sha(raw),'generated_original_size':list(im.size),'raw_foreground_bbox':list(bb),'raw_foreground_touches_canvas':bb[0]==0 or bb[1]==0 or bb[2]==im.width or bb[3]==im.height,'output':dest.relative_to(ROOT).as_posix(),'postprocess':{'alpha_threshold':128,'transparent_rgb':0,'aspect_preserved':True,'grade_max_bbox':[maxw,maxh],'area_cap_pixels':cap,'logical_size_before_cleanup':[lw,lh],'removed_tiny_component_pixels':removed,'minimum_component_area':3,'quantization':'nearest shared 32 RGB, no dither','inner_outline_blocks':1,'baseline_y':1329,'nearest_upscale':10},'measurements':measure(dest)}
def sheet(entries,path,cols,cw,ch,scale):
 im=Image.new('RGB',(cols*cw,math.ceil(len(entries)/cols)*ch),(40,37,42));draw=ImageDraw.Draw(im);small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',9 if cols==10 else 11)
 for i,e in enumerate(entries):
  x,y=(i%cols)*cw,(i//cols)*ch;sprite=Image.open(ROOT/e['output']).convert('RGBA')
  if cols==10:
   sprite=sprite.crop(sprite.getbbox());factor=min((cw-12)/sprite.width,(round(1400*scale)-8)/sprite.height);thumb=sprite.resize((max(1,round(sprite.width*factor)),max(1,round(sprite.height*factor))),Image.Resampling.NEAREST);py=y+round(1400*scale)-4-thumb.height
  else:thumb=sprite.resize((round(1120*scale),round(1400*scale)),Image.Resampling.NEAREST);py=y
  im.paste(thumb,(x+(cw-thumb.width)//2,py),thumb);ty=y+round(1400*scale);size=10 if cols==10 else 13;font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',size)
  while draw.textlength(e['name'],font=font)>cw-4 and size>7:size-=1;font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',size)
  draw.text((x+3,ty),e['name'],font=font,fill=(241,224,191))
  if cols!=10:
   draw.text((x+3,ty+20),e['id'],font=small,fill=(193,181,168));draw.text((x+3,ty+38),f"{e['sample_grade']} / {e['measurements']['opaque_pixels']:,} px",font=small,fill=(193,181,168))
  draw.line((x,y+ch-1,x+cw-1,y+ch-1),fill=(75,65,59))
 quality=90
 while True:
  im.save(path,quality=quality,optimize=True,subsampling=0)
  if path.stat().st_size<=500000 or quality<=35:break
  quality-=5
 return {'path':path.relative_to(ROOT).as_posix(),'size':list(im.size),'bytes':path.stat().st_size,'sha256':sha(path),'scale':scale if cols!=10 else 'per-foreground fit to 108x139 for identification; native PNGs retain tier areas','quality':quality}
def main():
 plan=read(OUT/'stage2-generation-requests.json');spec=read(OUT/'style-spec.json')['target'];old=read(OUT/'stage1/manifest.json');entries=list(old['samples']);missing=[]
 for e in entries:assert sha(ROOT/e['output'])==plan['samples_preserved'][e['id']],e['id']
 for req in plan['requests']:
  recs=[read(p) for p in (OUT/'stage2-generation-records').glob(req['id']+'-a*.json')];recs=[r for r in recs if r['status']=='generated']
  if not recs:missing.append(req['id']);continue
  entries.append(process(req,max(recs,key=lambda r:r['attempt']),spec,plan))
 source=read(Path(plan['source_path']));order={e['id']:i for i,e in enumerate(source['enemies'])};entries.sort(key=lambda e:order[e['id']]);folder=OUT/'sheets';folder.mkdir(exist_ok=True);sheets=[]
 for f in source['families']:
  group=[e for e in entries if e['family']==f['id']]
  if group:sheets.append({'family':f['id'],'name':f['name'],'ids':[e['id'] for e in group],**sheet(group,folder/f"family-{f['id']}.jpg",min(4,len(group)),260,330,.19)})
 allsheet=sheet(entries,OUT/'all-100.jpg',10,120,166,.105)
 manifest={**old,'stage':2,'status':'generated_pending_visual_review' if not missing else 'generation_in_progress','final_sample_count':3,'final_enemy_count':len(entries),'remaining_not_generated':len(missing),'missing_ids':missing,'generator_calls_stage1':4,'generator_calls_stage2':len(list((OUT/'stage2-generation-records').glob('*.json'))),'generation_mode':'built-in image_gen only; one call per enemy or correction','postprocess_script':'tools/process_enemy_art_stage2_r21.py','grade_mapping':plan['grade_mapping'],'samples':old['samples'],'enemies':entries,'family_sheets':sheets,'all_100_sheet':allsheet}
 save(OUT/'manifest.json',manifest);ranges={}
 for grade in ['mob','chief','boss']:
  group=[e for e in entries if e['sample_grade']==grade];ranges[grade]={'count':len(group),'min':min(e['measurements']['opaque_pixels'] for e in group),'max':max(e['measurements']['opaque_pixels'] for e in group)}
 print(json.dumps({'processed':len(entries),'missing':len(missing),'area_ranges':ranges,'raw_edge_contact':[e['id'] for e in entries if e.get('raw_foreground_touches_canvas')],'sheet':allsheet},ensure_ascii=True))
if __name__=='__main__':main()

