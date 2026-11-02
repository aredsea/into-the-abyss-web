"""Audit protected inputs and report honest scoped P8 evidence. No source writes."""
from pathlib import Path
import hashlib,json,re,sys
root=Path(__file__).resolve().parents[1];folder=root/'verification/settings-r22'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assets=read(root/'ASSET-HASHES.json');portraits=read(root/'verification/panels-r22/portrait-hashes.json');legacy=read(root/'verification/persona-r22/legacy-specimens.json');sources=read(folder/'provenance.json')['files'];baseline=read(folder/'protected-before.json')
protected={
 'original_assets':{'checked':len(assets),'changed':[e['path'] for e in assets if sha(root/e['path'])!=e['sha256']]},
 'r21_portraits':{'checked':len(portraits),'changed':[e['path'] for e in portraits if sha(root/e['path'])!=e['sha256']]},
 'source_files':{'checked':len(sources),'changed':[e['path'] for e in sources if sha(Path(e['path']))!=e['sha256']]},
 'legacy_copies':{'checked':len(legacy),'changed':[e['path'] for e in legacy if sha(root/e['path'].replace('res://../',''))!=e['sha256']]},
 'task_baseline':{'checked':len(baseline),'changed':[p for p,h in baseline.items() if not (root/p).exists() or sha(root/p)!=h]}}
before=read(folder/'world-before.json');after=read(root/'project/data/world.json')
for c in before['companions']:c.pop('name')
for c in after['companions']:c.pop('name')
protected['world_non_name_fields']={'checked':1,'changed':[] if before==after else ['project/data/world.json']}
write(folder/'protected.json',protected)
scope=[line for line in (root/'PARITY-R21.md').read_text(encoding='utf-8').splitlines() if re.match(r'^\|P\d+\|(?:01-game|15-josa|67-settings|90-triggers)\.lua:',line)]
write(folder/'parity-scope.json',{'count':len(scope),'baseline_rows':scope,'judgment':'No bulk parity relabeling. Non-host settings, language helper, josa and names only; original exclusions remain.'})
data=read(root/'project/data/localization-r22.json');ui=read(folder/'ui-results.json');rules=read(folder/'results.json');suite=read(folder/'regression.json');provenance=read(folder/'provenance.json')
# Static literal inventory complements observed render strings; never guess translations.
targets=['create_screen.gd','persona_sortie_screen.gd','panel_screen_r22.gd','codex_screen_r22.gd','status_screen_r22.gd','inventory_screen_r22.gd','journal_screen_r22.gd','settings_screen_r22.gd']
literal=[]
for file in targets:
    for n,line in enumerate((root/'project/ui'/file).read_text(encoding='utf-8').splitlines(),1):
        for s in re.findall(r'"([^"\n]*[\uac00-\ud7a3][^"\n]*)"',line):
            if s not in data['ui'] and s not in data['words']:literal.append({'file':file,'line':n,'text':s,'status':'No exact whole-literal key. Joined fields/source template matching may translate part of this string.'})
write(folder/'untranslated.json',{'observed_count':len(ui['untranslated_observed']),'observed':ui['untranslated_observed'],'static_candidates':literal,'scope':'Only P1/P7/P10/settings; source-only fallback, not an invented English backlog. Observed list is 19 states, not every possible data/gear view.','placeholder':'Existing native {{user}} -> Korean fallback is retained even in English source prose; no host persona name is available.'})
lines=['# P8 English fallback inventory','','Source-only English. These rendered strings still contain Korean; some are partially translated compositions. The existing native persona placeholder uses Korean fallback. The observation covers the 19 captured states, not all possible data.','']
for s in ui['untranslated_observed']:lines.append('- '+s.replace('\n',' / '))
(folder/'untranslated.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
summary={'groups':len(suite),'failed_groups':sum(bool(r['exit'] or r['errors']) for r in suite),'rules_checks':rules['checks'],'rules_failures':len(rules['failures']),'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'native_sizes':5,'captures':len(ui['captures']),'oracle_cases':sum(provenance['counts'].values()),'oracle_counts':provenance['counts'],'display_names_changed':len(read(folder/'name-changes.json')),'untranslated_observed':len(ui['untranslated_observed']),'parity_scope_rows':len(scope),'protected':protected}
write(folder/'summary.json',summary)
print(json.dumps(summary,ensure_ascii=True,indent=2))
sys.exit(1 if summary['groups']!=38 or summary['failed_groups'] or summary['rules_failures'] or summary['ui_failures'] or any(v['changed'] for v in protected.values()) else 0)
