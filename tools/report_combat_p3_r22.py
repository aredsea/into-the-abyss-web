"""Summarize current observations, latest checks and protected-file hashes."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1];O=R/'verification/data-r21'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
before=read(O/'p3-before-hashes.json')
modified=[p for p,h in before.items() if not (R/p).exists() or hashlib.sha256((R/p).read_bytes()).hexdigest()!=h]
protected=[p for p in before if p.startswith(('project/ui/','project/assets/','project/scenes/'))]
docs=[p for p in before if p.startswith('docs/')]
protection={'protected_files':len(protected),'protected_changes':[p for p in protected if p in modified],'docs_files':len(docs),'docs_changes':[p for p in docs if p in modified],'modified_existing':modified}
(O/'p3-protected-after.json').write_text(json.dumps(protection,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
latest={}
names={r['test'] for r in read(O/'suite-all.json')}
for p in O.glob('suite-*.json'):
 rows=read(p)
 if not isinstance(rows,list):continue
 for row in rows:
  if row.get('test') not in names:continue
  if row.get('finished_at',0)>latest.get(row['test'],{}).get('finished_at',0):latest[row['test']]=row
suite=list(latest.values());(O/'suite-p3-final.json').write_text(json.dumps(suite,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
oracle=read(O/'p3-oracle.json');test=read(O/'p3-latest.json')
summary={'personal_characters':len(oracle['catalog']),'personal_conditions':len(oracle['personal']),'personal_observations':sum(len(r['steps']) for r in oracle['personal']),'trait_combinations':len(oracle['traits']),'class_skills':len(oracle['class_skills']),'caster_deaths':len(oracle['deaths']),'regen_orders':len(oracle['regen_mix']),'dot_credit':len(oracle['dot_credit']),'counters':len(oracle['counters']),'new_checks':test['checks'],'new_failures':len(test['failures']),'suite_tests':len(suite),'suite_failures':[r['test'] for r in suite if not r['passed']],'protected':protection}
for key,file in [('original_mixed','a6-mixed-audit.json'),('expanded_mixed','p3-mixed-audit.json')]:
 d=read(O/file);summary[key]={k:d[k] for k in ['battles','equal_battles','source_actions','actual_actions','matched_actions']}
gaps={}
for key,file in [('original_mixed','a6-mixed-audit.json'),('expanded_mixed','p3-mixed-audit.json')]:
 d=read(O/file);gaps[key]=[{'party':r['party'],'foe':r['foe'],'bn':r['bn'],'first_difference':r['first_difference']} for r in d['reports'] if r['first_difference']]
(O/'p3-parity-gaps.json').write_text(json.dumps({'gaps':gaps,'P4':'Full equipment combinations are outside P3; mixed traces fix canonical initial statistics.'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
summary['source_audit']=read(O/'source-audit.json')
(O/'p3-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['protected','source_audit']},ensure_ascii=False))
if summary['new_failures'] or summary['suite_failures'] or protection['protected_changes'] or protection['docs_changes']:raise SystemExit(1)
