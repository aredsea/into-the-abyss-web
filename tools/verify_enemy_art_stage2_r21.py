"""Stage-two all-enemy checks; original Godot tests run in an isolated copy."""
from pathlib import Path
from PIL import Image
import numpy as np
import json,hashlib,shutil,subprocess,sys,time,os,re,certifi
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/enemy-art-r21';BOX=OUT/'validation-worktree';LOGS=OUT/'checks-stage2'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def save(p,obj):p.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def source_files():return {p.relative_to(ROOT).as_posix():sha(p) for folder in ['project/game','project/ui','project/data','project/scenes','project/tests','project/licenses','project/assets/src'] for p in (ROOT/folder).rglob('*') if p.is_file()}
def regression():
 LOGS.mkdir(parents=True,exist_ok=True);before=source_files();save(OUT/'stage2-production-source-hashes-before.json',before);BOX.mkdir(parents=True,exist_ok=True);shutil.copytree(ROOT/'project',BOX/'project',dirs_exist_ok=True);(BOX/'tools').mkdir(exist_ok=True);shutil.copyfile(ROOT/'tools/godot_r17.py',BOX/'tools/godot_r17.py')
 mismatch=[p for p,h in before.items() if sha(BOX/p)!=h];assert not mismatch,mismatch
 save(OUT/'stage2-validation-copy-proof.json',{'copied_source_files':len(before),'mismatches':mismatch,'runner_sha256':sha(ROOT/'tools/godot_r17.py'),'copied_runner_sha256':sha(BOX/'tools/godot_r17.py'),'note':'Unchanged source copy. All Godot executions through godot_r17.py, isolated APPDATA, Dummy audio, offscreen windows.'})
 (BOX/'project/override.cfg').write_text('[network]\ntls/certificate_bundle_override='+json.dumps(Path(certifi.where()).as_posix())+'\n',encoding='utf-8');settingspath=BOX/'verification/ui-r17/runtime/engine/editor_data/editor_settings-4.7.tres';settingspath.parent.mkdir(parents=True,exist_ok=True);settings=settingspath.read_text(encoding='utf-8') if settingspath.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n';line='network/tls/editor_tls_certificates = '+json.dumps(Path(certifi.where()).as_posix());settings=re.sub(r'^network/tls/editor_tls_certificates\s*=.*$',line,settings,flags=re.M) if re.search(r'^network/tls/editor_tls_certificates\s*=',settings,re.M) else settings+'\n'+line+'\n';settingspath.write_text(settings,encoding='utf-8')
 jobs=[('import',['--headless','--editor','--import','--quit'])]+[(n,['--headless','--script','res://tests/'+n+'.gd']) for n in ['world_test','state_test','route_test','expansion_test','motion_test','motion_asset_test','art_test','export_licenses']]+[(n,['--position','-10000,-10000','--script','res://tests/'+n+'.gd']) for n in ['ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test','motion_r9_integration','motion_r18_integration']]
 if '--import-only' in sys.argv:jobs=jobs[:1]
 results=[]
 for name,args in jobs:
  started=time.monotonic();print('START '+name,flush=True);cmd=[sys.executable,'tools/godot_r17.py',*args]
  try:
   r=subprocess.run(cmd,cwd=BOX,capture_output=True,timeout=240,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0));out=r.stdout.decode('utf-8',errors='replace');err=r.stderr.decode('utf-8',errors='replace');code=r.returncode
  except subprocess.TimeoutExpired as e:out=(e.stdout or b'').decode('utf-8',errors='replace');err=(e.stderr or b'').decode('utf-8',errors='replace')+'\nTIMEOUT';code=None
  (LOGS/(name+'.log')).write_text(out+'\n--- STDERR ---\n'+err,encoding='utf-8');bad=[l for l in (out+'\n'+err).splitlines() if any(t in l for t in ['SCRIPT ERROR:','ERROR:','Assertion failed','FAIL '])];marker=name in ['import','export_licenses'] or bool(re.search(r'\bPASS\b|\b0\s+failures\b|\bfailures[: ]+0\b',out,re.I));passed=code==0 and not bad and marker
  item={'name':name,'command':'python tools/godot_r17.py '+' '.join(args),'exit_code':code,'passed':passed,'elapsed_seconds':round(time.monotonic()-started,2),'error_lines':bad,'pass_lines':[l for l in out.splitlines() if any(t in l.upper() for t in ['PASS','CHECKS','EXPORTED'])],'log':(LOGS/(name+'.log')).relative_to(ROOT).as_posix()};results.append(item);save(OUT/('stage2-import-result.json' if '--import-only' in sys.argv else 'stage2-regression-results.json'),{'completed':len(results),'expected':len(jobs),'passed':sum(r['passed'] for r in results),'failed':sum(not r['passed'] for r in results),'results':results});print('END '+name+' '+str(passed),flush=True)
 after=source_files();save(OUT/'stage2-production-source-hashes-after.json',after);assert before==after,'Production source changed'
 return all(r['passed'] for r in results)
def phash(im,crop=False):
 im=im.convert('RGBA')
 if crop:im=im.crop(im.getbbox())
 bg=Image.new('RGBA',im.size,(40,37,42,255));bg.alpha_composite(im);gray=np.asarray(bg.convert('L').resize((32,32),Image.Resampling.LANCZOS),dtype=float);x=np.arange(32);u=np.arange(8)[:,None];mat=np.cos((2*x[None,:]+1)*u*np.pi/64);mat[0]*=1/np.sqrt(2);freq=(mat@gray@mat.T).ravel()[1:];bits=freq>np.median(freq);return sum(int(b)<<i for i,b in enumerate(bits))
def art_checks():
 plan=read(OUT/'stage2-generation-requests.json');m=read(OUT/'manifest.json');spec=read(OUT/'style-spec.json');source=read(Path(plan['source_path']));ids={e['id']:e for e in source['enemies']};entries=m.get('enemies',[]);palette=set(map(tuple,spec['target']['palette_rgb']));checks=[]
 def check(label,ok,details=None):checks.append({'label':label,'passed':bool(ok),'details':details})
 check('100 canonical PNGs',len(list((ROOT/'project/assets/enemies-r21').glob('*.png')))==100);check('100 canonical manifest ids',len(entries)==100 and {e['id'] for e in entries}==set(ids));check('canonical source hash unchanged',sha(Path(plan['source_path']))==plan['source_sha256'])
 hashes={};cropped={};byteshash={}
 for e in entries:
  id=e['id'];p=ROOT/e['output'];im=Image.open(p);a=np.array(im.convert('RGBA'));mask=a[:,:,3]==255;bb=im.getbbox();colors=np.unique(a[:,:,:3][mask],axis=0);area=int(mask.sum());hashes[id]=phash(im);cropped[id]=phash(im,True);byteshash[id]=sha(p)
  check(id+' source record',e['source_record']==ids[id]);check(id+' source description',e['source_description']==ids[id]['looks']);check(id+' RGBA 1120x1400',im.mode=='RGBA' and im.size==(1120,1400));check(id+' alpha only 0/255',not ((a[:,:,3]>0)&(a[:,:,3]<255)).any());check(id+' transparent RGB zero',not a[:,:,:3][~mask].any());check(id+' exact 10px grid',np.array_equal(a,np.repeat(np.repeat(a[::10,::10],10,0),10,1)));check(id+' shared <=32 palette',len(colors)<=32 and all(tuple(c) in palette for c in colors),len(colors));check(id+' baseline 1329',bb[3]-1==1329);check(id+' complete canvas margins',bb[0]>0 and bb[1]>0 and bb[2]<1120 and bb[3]<1400);check(id+' final hash',sha(p)==e['measurements']['sha256']);check(id+' measured area',area==e['measurements']['opaque_pixels']);check(id+' generated original hash',sha(ROOT/e['generated_original_file'])==e['generated_original_sha256']);check(id+' built-in generator',e['generation_tool']=='built-in image_gen.imagegen');check(id+' canonical visual tier',e['sample_grade']==('boss' if ids[id]['grade'] in ('boss','core') else 'chief' if ids[id]['grade']=='elite' else 'mob'))
  if id in plan['samples_preserved']:check(id+' approved bytes preserved',sha(p)==plan['samples_preserved'][id])
  else:
   check(id+' source description in exact recorded prompt',ids[id]['looks'] in e['prompt']);check(id+' retry limit',1<=e['attempt']<=4)
   raw=Image.open(ROOT/e['generated_original_file']).convert('RGBA');rawbb=raw.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox();check(id+' raw foreground has full margins',rawbb is not None and rawbb[0]>0 and rawbb[1]>0 and rawbb[2]<raw.width and rawbb[3]<raw.height)
 ranges={g:{'count':len(es:=[e for e in entries if e['sample_grade']==g]),'min':min(e['measurements']['opaque_pixels'] for e in es),'max':max(e['measurements']['opaque_pixels'] for e in es)} for g in ['mob','chief','boss']}
 check('ALL mob < ALL chief < ALL boss opaque areas',ranges['mob']['max']<ranges['chief']['min'] and ranges['chief']['max']<ranges['boss']['min'],ranges)
 pairs=[]
 for i,e in enumerate(entries):
  for other in entries[i+1:]:
   a,b=e['id'],other['id'];pairs.append({'a':a,'b':b,'distance':(hashes[a]^hashes[b]).bit_count(),'cropped_distance':(cropped[a]^cropped[b]).bit_count()})
 pairs.sort(key=lambda p:(p['distance'],p['cropped_distance']));mind=min(p['distance'] for p in pairs);mincrop=min(p['cropped_distance'] for p in pairs)
 check('100 distinct PNG byte hashes',len(set(byteshash.values()))==100);check('distinct full-canvas perceptual hashes',mind>0,{'minimum_hamming_distance':mind,'pair_count':len(pairs)});check('distinct normalized-foreground perceptual hashes',mincrop>0,{'minimum_hamming_distance':mincrop})
 save(OUT/'stage2-perceptual-hashes.json',{'method':'63-bit DCT pHash (32x32 grayscale composited on sheet background, DC omitted), full canvas and separately normalized foreground bbox','hashes':{id:{'canvas':f'{hashes[id]:016x}','cropped':f'{cropped[id]:016x}'} for id in hashes},'minimum_canvas_distance':mind,'minimum_cropped_distance':mincrop,'nearest_40':pairs[:40],'near_pairs_for_visual_review':[p for p in pairs if p['distance']<=8 or p['cropped_distance']<=8],'all_pairs':pairs})
 sheet=OUT/'all-100.jpg';im=Image.open(sheet);check('100 sheet 10x10',len(entries)==100 and im.size==(1200,1660));check('100 sheet width <=1200',im.width<=1200);check('100 sheet <=500KB',sheet.stat().st_size<=500000,sheet.stat().st_size);check('30 family sheets canonical coverage',{s['family'] for s in m['family_sheets']}=={e['family'] for e in source['enemies']});check('family sheet id coverage',sorted(id for s in m['family_sheets'] for id in s['ids'])==sorted(ids))
 rows=read(ROOT/'ASSET-HASHES.json');changes=[r['path'] for r in rows if sha(ROOT/r['path'])!=r['sha256']];check('96 immutable assets unchanged',len(rows)==96 and not changes,changes)
 before=read(OUT/'stage1'/'manifest.json');stage1hash=read(OUT/'production-source-hashes-before.json');now=source_files();check('production source identical to stage one',stage1hash==now,{'compared':len(now),'changed':[p for p,h in stage1hash.items() if now.get(p)!=h]})
 review=read(OUT/'stage2-visual-review.json') if (OUT/'stage2-visual-review.json').exists() else {};check('all 30 final family sheets directly opened',set(review.get('opened_final_family_sheets',[]))=={s['path'] for s in m['family_sheets']});check('all-100 final sheet directly opened',review.get('all_100_opened_sha256')==sha(sheet));check('no unresolved visual issues',not review.get('unresolved',[]) and review.get('complete') is True,review.get('unresolved'))
 result={'checks':len(checks),'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks),'area_ranges':ranges,'minimum_phash_distance':mind,'minimum_cropped_phash_distance':mincrop,'sheet_bytes':sheet.stat().st_size,'immutable_asset_changes':len(changes),'results':checks};save(OUT/'stage2-asset-checks.json',result);print(json.dumps({k:v for k,v in result.items() if k!='results'}),flush=True);return result['failed']==0
def main():
 if '--regression-only' in sys.argv or '--import-only' in sys.argv:return 0 if regression() else 1
 game=True if '--art-only' in sys.argv else regression();art=art_checks();return 0 if game and art else 1
if __name__=='__main__':sys.exit(main())

