# Stage two preserves the original sample verifier below for historical reproduction.
if __name__ == '__main__':
 import json as _j, sys as _s
 from pathlib import Path as _P
 _m = _P(__file__).resolve().parents[1] / 'verification/enemy-art-r21/manifest.json'
 if _m.exists() and _j.loads(_m.read_text(encoding='utf-8')).get('stage') == 2:
  from verify_enemy_art_stage2_r21 import main as _stage2_main
  _s.exit(_stage2_main())
"""Run r21 asset checks and unchanged Godot regression scripts inside allowed paths."""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib,shutil,subprocess,sys,time,os,re,certifi
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/enemy-art-r21';BOX=OUT/'validation-worktree';LOGS=OUT/'checks';LOGS.mkdir(parents=True,exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,obj):p.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
def source_files():
 return {str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for folder in ['project/game','project/ui','project/data','project/scenes','project/tests','project/licenses','project/assets/src'] for p in (ROOT/folder).rglob('*') if p.is_file()}
before=source_files();save(OUT/'production-source-hashes-before.json',before)
# Copy the project, including its existing import cache, to keep imports/screenshots,
# editor data, license exports and all test side effects out of production paths.
BOX.mkdir(parents=True,exist_ok=True);shutil.copytree(ROOT/'project',BOX/'project',dirs_exist_ok=True)
(BOX/'tools').mkdir(exist_ok=True);shutil.copyfile(ROOT/'tools/godot_r17.py',BOX/'tools/godot_r17.py')
copy_mismatch=[p for p,h in before.items() if sha(BOX/p)!=h];assert not copy_mismatch,copy_mismatch
save(OUT/'validation-copy-proof.json',{'copied_source_files':len(before),'mismatches':copy_mismatch,'runner_sha256':sha(ROOT/'tools/godot_r17.py'),'copied_runner_sha256':sha(BOX/'tools/godot_r17.py'),'note':'Unmodified production source project copy. Validation-only override.cfg supplies certifi CA bundle because OS certificate store is unavailable. Every Godot launch is python tools/godot_r17.py, with its APPDATA isolation and Dummy audio; UI windows are offscreen. No source project writes.'})
jobs=[('import',['--headless','--editor','--import','--quit'])]+[(n,['--headless','--script','res://tests/'+n+'.gd']) for n in ['world_test','state_test','route_test','expansion_test','motion_test','motion_asset_test','art_test','export_licenses']]+[(n,['--position','-10000,-10000','--script','res://tests/'+n+'.gd']) for n in ['ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test','motion_r9_integration','motion_r18_integration']]
# Certificate storage is unavailable in this managed Windows environment. Override
# TLS CA location ONLY in the isolated validation project; no gameplay settings.
(BOX/'project/override.cfg').write_text('[network]\ntls/certificate_bundle_override='+json.dumps(Path(certifi.where()).as_posix())+'\n',encoding='utf-8')
editor_settings=BOX/'verification/ui-r17/runtime/engine/editor_data/editor_settings-4.7.tres'
editor_settings.parent.mkdir(parents=True,exist_ok=True)
settings=editor_settings.read_text(encoding='utf-8') if editor_settings.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
setting_line='network/tls/editor_tls_certificates = '+json.dumps(Path(certifi.where()).as_posix())
settings=re.sub(r'^network/tls/editor_tls_certificates\s*=.*$',setting_line,settings,flags=re.M) if re.search(r'^network/tls/editor_tls_certificates\s*=',settings,re.M) else settings+'\n'+setting_line+'\n'
editor_settings.write_text(settings,encoding='utf-8')
results=[]
for name,args in jobs:
 started=time.monotonic();cmd=[sys.executable,'tools/godot_r17.py',*args];print('START '+name,flush=True)
 try:
  r=subprocess.run(cmd,cwd=BOX,capture_output=True,timeout=240,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0));out=r.stdout.decode('utf-8',errors='replace');err=r.stderr.decode('utf-8',errors='replace');code=r.returncode;timed=False
 except subprocess.TimeoutExpired as e:
  out=(e.stdout or b'').decode('utf-8',errors='replace');err=(e.stderr or b'').decode('utf-8',errors='replace')+'\nTIMEOUT';code=None;timed=True
 (LOGS/(name+'.log')).write_text(out+'\n--- STDERR ---\n'+err,encoding='utf-8')
 bad=[l for l in (out+'\n'+err).splitlines() if any(t in l for t in ['SCRIPT ERROR:','ERROR:','Assertion failed','FAIL '])]
 success_marker = name in ['import','export_licenses'] or bool(re.search(r'\bPASS\b|\b0\s+failures\b|\bfailures[: ]+0\b',out,re.I))
 passed=code==0 and not bad and success_marker
 item={'name':name,'command':'python tools/godot_r17.py '+' '.join(args),'exit_code':code,'passed':passed,'elapsed_seconds':round(time.monotonic()-started,2),'error_lines':bad,'pass_lines':[l for l in out.splitlines() if any(t in l.upper() for t in ['PASS','CHECKS','EXPORTED'])],'log':str((LOGS/(name+'.log')).relative_to(ROOT)).replace('\\','/'),'timed_out':timed};results.append(item);save(OUT/'regression-results.json',{'completed':len(results),'expected':len(jobs),'passed':sum(r['passed'] for r in results),'failed':sum(not r['passed'] for r in results),'results':results});print('END '+name+' '+str(passed)+' '+str(item['elapsed_seconds']),flush=True)
manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'));spec=json.loads((OUT/'style-spec.json').read_text(encoding='utf-8'));palette=set(map(tuple,spec['target']['palette_rgb']));checks=[]
def check(label,ok,details=None):checks.append({'label':label,'passed':bool(ok),'details':details})
files=sorted((ROOT/'project/assets/enemies-r21').glob('*.png'));check('exactly 3 sample PNGs',len(files)==3)
source=json.loads(Path('C:/Clauede Code/dungeon-bot/design/enemies.json').read_text(encoding='utf-8'));ids={e['id']:e for e in source['enemies']};seenfamily=set();areas=[]
for e in manifest['samples']:
 p=ROOT/e['output'];a=np.array(Image.open(p).convert('RGBA'));m=a[:,:,3]==255;B=spec['target']['block_px'];check(e['id']+' original id',e['id'] in ids);check(e['id']+' source description',e['source_description']==ids[e['id']]['looks']);seenfamily.add(e['family']);check(e['id']+' 1120x1400 RGBA',a.shape==(1400,1120,4));check(e['id']+' no partial alpha',not ((a[:,:,3]>0)&(a[:,:,3]<255)).any());check(e['id']+' transparent RGB zero',not a[:,:,:3][~m].any());check(e['id']+' exact 10px grid',np.array_equal(a,np.repeat(np.repeat(a[::B,::B],B,0),B,1)));colors=np.unique(a[:,:,:3][m],axis=0);check(e['id']+' <=32 colors and shared palette',len(colors)<=32 and all(tuple(c) in palette for c in colors),len(colors));bb=Image.open(p).getbbox();check(e['id']+' shared baseline',bb[3]-1==1329);check(e['id']+' full silhouette padding',bb[0]>0 and bb[1]>0 and bb[2]<1120 and bb[3]<1400);check(e['id']+' output manifest hash',sha(p)==e['measurements']['sha256']);areas.append(int(m.sum()))
check('three different families',len(seenfamily)==3);check('mob < chief < boss opaque area',areas[0]<areas[1]<areas[2],areas);check('mob < chief < boss bounding height',all(manifest['samples'][i]['measurements']['bbox_size'][1]<manifest['samples'][i+1]['measurements']['bbox_size'][1] for i in range(2)));check('chief original elite mapping', 'chained_tome' in next(z for z in source['zones'] if z['id']=='academy_library')['chiefs']);sp=OUT/'sample-sheet.jpg';im=Image.open(sp);check('sheet <=1200px',im.width<=1200,im.size);check('sheet <=300KB',sp.stat().st_size<=300000,sp.stat().st_size);check('same scale seven panels',len(manifest['sample_sheet']['layout'])==7 and len({x['scale'] for x in manifest['sample_sheet']['layout']})==1)
assetrows=json.loads((ROOT/'ASSET-HASHES.json').read_text(encoding='utf-8'));mismatches=[r['path'] for r in assetrows if sha(ROOT/r['path'])!=r['sha256']];check('96 immutable source assets',len(assetrows)==96 and not mismatches,{'count':len(assetrows),'mismatches':mismatches})
after=source_files();changed=[p for p,h in before.items() if after.get(p)!=h];check('production code data reference images unchanged',before==after,{'compared':len(before),'changed':changed});save(OUT/'asset-checks.json',{'checks':len(checks),'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks),'results':checks});save(OUT/'production-source-hashes-after.json',after)
summary={'regression':{'passed':sum(r['passed'] for r in results),'failed':sum(not r['passed'] for r in results),'total':len(results)},'asset_checks':{'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks),'total':len(checks)},'immutable_assets':len(assetrows),'changed_immutable_assets':len(mismatches),'production_sources_compared':len(before),'production_sources_changed':len(changed)};save(OUT/'verification-summary.json',summary);print(json.dumps(summary),flush=True)
sys.exit(0 if all(r['passed'] for r in results) and all(c['passed'] for c in checks) else 1)
