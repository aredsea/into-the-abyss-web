from pathlib import Path
import json,hashlib,re
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1];OUT=R/'verification/data-r21';SUITE=OUT/'a8-suite'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
base=read(OUT/'a8-before.json')
changed=[p for p,h in base.items() if not (R/p).exists() or hashlib.sha256((R/p).read_bytes()).hexdigest()!=h]
protected={k:sum(p.startswith(k) for p in base) for k in ['docs/','project/assets/']}
protected['changed']=[p for p in changed if p.startswith(('docs/','project/assets/'))]
protected['legacy_specimens']=len(read(R/'verification/persona-r22/legacy-specimens.json'))
protected['legacy_changed']=[s['path'] for s in read(R/'verification/persona-r22/legacy-specimens.json') if hashlib.sha256((R/'project'/s['path'].removeprefix('res://')).resolve().read_bytes()).hexdigest()!=s['sha256']]
source=read(OUT/'a8-oracle.json');rows=source['battles']+source['raid_battles']
death=revive=casts=0;coverage=set()
for row in rows:
 previous=row['initial'][0]['hp'];coverage.add((row['pm'][0]['cls'],*row['combo']))
 for trace in row['trace']:
  hp=trace['hp'][0];death+=previous>0 and hp==0;revive+=previous==0 and hp>0;previous=hp
 casts+=sum(d['id']=='persona_skill' for d in row['decisions'])
locale=read(OUT/'a8-localization.json');ui=read(OUT/'a8-ui-results.json')
remaining=[x for x in locale['town_candidates'] if not x['canonical_exact'] and not x['canonical_templates']]
hangul=re.compile('[\uac00-\ud7a3]')
observed=sorted(set(s for s in ui['observed'] if hangul.search(s)))
inventory={'scope':'Canonical whole keys/templates only; composite fields may be partially English. This is not a translation-rate denominator.','static_candidates':locale['town_candidates'],'without_whole_canonical_key_or_template':remaining,'observed_partial_korean':observed}
(OUT/'a8-untranslated.json').write_text(json.dumps(inventory,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# A8 전투 영어 미대응 목록','',f'마을 10차 정적 후보 {len(locale["town_candidates"])}행 중 전체 정본 키/틀 미대응 {len(remaining)}행. 복합 필드 일부만 영어로 표시되는 경우를 포함한다. 번역률로 해석하지 않는다.','', '|파일:원래 줄|문구|','|---|---|']
for row in remaining:lines.append('|'+row['file']+':'+str(row['line'])+'|'+row['text'].replace('|','\\|').replace('\n',' / ')+'|')
lines+=['','## 실제 화면에 남은 한국어','']+[f'- {s.replace(chr(10)," / ")}' for s in observed]
(OUT/'a8-untranslated.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
contacts=[]
for size in ['360x780','390x844','390x664','430x932','1280x800']:
 names=[f'{c}-{size}-{state}.png' for c in ['warrior','archer','priest','alchemist','chaos'] for state in ['base','skills']]
 canvas=Image.new('RGB',(1000,910),'#ded9cc');draw=ImageDraw.Draw(canvas)
 for i,name in enumerate(names):
  im=Image.open(OUT/'a8-ui'/name).convert('RGB');im.thumbnail((194,420));x=(i%5)*200;y=(i//5)*455
  canvas.paste(im,(x+(194-im.width)//2,y+22));draw.text((x+3,y+3),name.split('-')[0]+' '+name.split('-')[-1][:-4],fill='black')
 target=OUT/'a8-ui'/('contact-'+size+'.jpg');canvas.save(target,quality=90);contacts.append(target.relative_to(R).as_posix())
audit_path=OUT/'a8-audit.json'
if not audit_path.exists():print('Prepared inventory/contacts; full battle audit still running.');raise SystemExit(0)
audit=read(audit_path)
results=read(SUITE/'results.json')
summary={'parity':{k:v for k,v in audit.items() if k not in ['reports','actual_inputs']},'persona':read(OUT/'a8-persona-results.json'),'save':read(OUT/'a8-save-results.json'),'ui':{k:v for k,v in ui.items() if k not in ['captures','observed']},'regression':{'groups':len(results),'failed':[r for r in results if not r['passed']]},'coverage':{'class_combinations':len(coverage),'source_persona_casts':casts,'source_persona_deaths':death,'source_persona_revives':revive},'localization':{'shipping':locale['counts'],'candidates':len(locale['town_candidates']),'whole_unsupported':len(remaining),'observed_partial_korean':len(observed)},'protected':protected,'before_files':len(base),'modified_existing':changed,'contacts':contacts}
(OUT/'a8-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'battles':audit['equal_battles'],'total':audit['battles'],'records':audit['matched_actions'],'suite':len(results),'failed':len(summary['regression']['failed']),'protected':protected},ensure_ascii=False))
