from pathlib import Path
import sys,json,hashlib,collections,re
sys.stdout.reconfigure(encoding='utf-8');sys.dont_write_bytecode=True
from index_sources import mask
from audit_config import DECISIONS
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[1];BOT=Path('C:/Clauede Code/dungeon-bot')
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=0;failures=[]
def check(ok,msg):
 global checks
 checks+=1
 if not ok:failures.append(msg)
def main():
 report=read(OUT/'parity.json');index=read(OUT/'source-index.json');rows=report['rows'];md=(ROOT/'PARITY-R21.md').read_text(encoding='utf-8');byid={r['id']:r for r in rows}
 check(len(index)==45,'45 source Lua files');check(sum(f['lines'] for f in index)==18795,'source line sum');check(len(byid)==len(rows),'row IDs unique');check(6<=len(report['work_packages'])<=10,'6..10 work packages')
 check(len(re.findall(r'^\|P\d{4}\|',md,re.M))==len(rows),'MD contains exactly all rows')
 manifests={};changed_source=[]
 for f in index:
  p=BOT/'bot/src'/f['file'];text=p.read_text(encoding='utf-8-sig');ls=text.splitlines();group=[r for r in rows if r['source']['file']=='bot/src/'+f['file']]
  check(sha(p)==f['sha256'],f['file']+' unchanged source hash')
  check(len(ls)==f['lines'],f['file']+' line count')
  covering=set()
  for r in group:covering.update(range(r['source']['start'],r['source']['end']+1))
  masked=mask(text).splitlines();uncovered=[n for n,l in enumerate(masked,1) if l.strip() and n not in covering]
  check(not uncovered,f['file']+' executable line coverage '+str(uncovered))
  expected={(r['start'],r['end'],r['name'],r['kind']) for r in f['features']};actual={(r['source']['start'],r['source']['end'],r['source']['symbol'],r['kind']) for r in group}
  check(expected<=actual,f['file']+' all indexed features represented')
  fs=next(z for z in report['files'] if z['file']==f['file']);seen=[n for a,b in fs['read_ranges'] for n in range(a,b+1)]
  check(seen==list(range(1,f['lines']+1)),f['file']+' contiguous complete read ranges')
  check(fs['counts']=={s:sum(r['status']==s for r in group) for s in ['같음','일부','없음','제외','미확인']},f['file']+' status sums')
  manifests[f['file']]=f['sha256']
 for r in rows:
  s=r['source'];p=BOT/s['file'];length=next(f['lines'] for f in index if 'bot/src/'+f['file']==s['file'])
  check(1<=s['start']<=s['end']<=length,r['id']+' valid source range')
  check(bool(r['description']) and bool(r['evidence']['reason']),r['id']+' meaningful metadata')
  if r['implementation']:
   loc=r['implementation'];gp=ROOT/loc['file'];check(gp.is_file(),r['id']+' game exists')
   n=len(gp.read_text(encoding='utf-8-sig').splitlines()) if gp.exists() else 0
   check(1<=loc['start']<=loc['end']<=n,r['id']+' valid game range')
  if r['status']=='같음':
   ev=r['evidence'];check(bool(ev.get('tests')) or ev.get('comparison_passed') is True,r['id']+' same has direct test/data proof');check(r['implementation'] is not None,r['id']+' same has game location')
  if r['status']=='미확인':check(r.get('implementation_is_candidate') is True,r['id']+' unknown candidate flag')
  for h in r['original_harnesses']:check((BOT/'bot'/h['file']).is_file(),r['id']+' harness exists '+h['file'])
  check('\ufffd' not in json.dumps(r,ensure_ascii=False),r['id']+' no replacement characters')
 check(sum(report['summary']['counts'].values())==len(rows),'summary count sum')
 expected=['import','world_test','state_test','route_test','expansion_test','motion_test','motion_asset_test','art_test','export_licenses','ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test','motion_r9_integration','motion_r18_integration']
 suite=read(OUT/'checks.json');check(set(expected)<={x['name'] for x in suite},'all common checks present');check(all(x['exit_code']==0 and not x['errors'] for x in suite),'all suite checks pass')
 fresh=read(OUT/'fresh-checks.json');check(len(fresh)==10 and all(x['exit_code']==0 for x in fresh),'five actual source oracles plus five fresh differential checks pass')
 auxiliary=read(OUT/'auxiliary-index.json');aux_changed=[]
 for a in auxiliary:
  p=Path(a['path'])
  if sha(p)!=a['sha256']:aux_changed.append(a['path'])
 check(not aux_changed,'canonical design/harness/architecture unchanged')
 before=read(OUT/'workspace-before.json');after={}
 for p in ROOT.rglob('*'):
  if not p.is_file() or '.git' in p.relative_to(ROOT).parts or p.is_relative_to(OUT) or p.name=='PARITY-R21.md':continue
  after[p.relative_to(ROOT).as_posix()]=sha(p)
 changed=[p for p in sorted(set(before)|set(after)) if before.get(p)!=after.get(p)]
 check(not changed,'only allowed outputs changed '+str(changed))
 write={'files_checked':len(before),'changed_outside_allowed':changed,'canonical_lua_checked':len(index),'canonical_lua_changed':changed_source,'auxiliary_files_checked':len(auxiliary),'auxiliary_changed':aux_changed}
 (OUT/'write-audit.json').write_text(json.dumps(write,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 names={(f['file'],r['name']) for f in index for r in f['features']}
 unused=[{'file':a,'symbol':b} for a,b in DECISIONS if (a,b) not in names]
 result={'checks':checks,'failures':len(failures),'details':failures,'files':len(index),'source_lines':sum(f['lines'] for f in index),'rows':len(rows),'counts':report['summary']['counts'],'unused_manual_decisions':unused,'unverified_is_not_failure':True,'write_audit':write}
 (OUT/'validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print(json.dumps(result,ensure_ascii=False));sys.exit(1 if failures else 0)
if __name__=='__main__':main()
