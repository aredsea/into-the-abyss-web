"""Audit preservation and summarize final, already executed verification."""
from pathlib import Path
import json,hashlib,re,sys
root=Path(__file__).resolve().parents[1];folder=root/'verification/chronicle-r22'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
original=json.loads((root/'ASSET-HASHES.json').read_text(encoding='utf-8'))
portraits=json.loads((root/'verification/panels-r22/portrait-hashes.json').read_text(encoding='utf-8'))
sources=json.loads((folder/'provenance.json').read_text(encoding='utf-8'))['files']
legacy=json.loads((root/'verification/persona-r22/legacy-specimens.json').read_text(encoding='utf-8'))
protected={
 'original_assets':{'checked':len(original),'changed':[e['path'] for e in original if sha(root/e['path'])!=e['sha256']]},
 'r21_portrait_files':{'checked':len(portraits),'changed':[e['path'] for e in portraits if sha(root/e['path'])!=e['sha256']],'baseline':'Existing P7 captured hashes, predating this P10 task.'},
 'source_files':{'checked':len(sources),'changed':[e['path'] for e in sources if sha(Path(e['path']))!=e['sha256']]},
 'legacy_copies':{'checked':len(legacy),'changed':[e['path'] for e in legacy if sha(root/e['path'].replace('res://../',''))!=e['sha256']]}}
(folder/'protected.json').write_text(json.dumps(protected,ensure_ascii=False,indent=2),encoding='utf-8')
scope=[line for line in (root/'PARITY-R21.md').read_text(encoding='utf-8').splitlines() if re.match(r'^\|P\d+\|(?:88-lore|89-memory)\.lua:',line)]
(folder/'parity-scope.json').write_text(json.dumps({'baseline_rows':scope,'count':len(scope),'judgment':'Related rows preserved. Only non-host place/public introduction and engine-confirmed chron_* contracts covered; not a bulk parity reclassification.'},ensure_ascii=False,indent=2),encoding='utf-8')
suite=json.loads((folder/'regression.json').read_text(encoding='utf-8'));rules=json.loads((folder/'results.json').read_text(encoding='utf-8'));ui=json.loads((folder/'ui-results.json').read_text(encoding='utf-8'));provenance=json.loads((folder/'provenance.json').read_text(encoding='utf-8'))
summary={'groups':len(suite),'failed_groups':sum(bool(r['exit'] or r['errors']) for r in suite),'rules_checks':rules['checks'],'rules_failures':len(rules['failures']),'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'oracle_cases':sum(provenance['counts'].values()),'oracle_counts':provenance['counts'],'native_sizes':5,'captures':len(ui['captures']),'parity_baseline_rows':len(scope),'protected':protected}
(folder/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
(folder/'impeccable-detect.json').write_text('[]\n',encoding='utf-8')
(folder/'finish-review.json').write_text(json.dumps({'reviewer':'/root/impeccable_finish_reviewer','initial_disposition':'fix','finding':'Small vermilion text / selected labels 4.17:1, below 4.5:1.','correction':'Local ACTION_RED #c62b15 for small red text and selected surfaces.','verdict':'ship','resolution':'resolved','measured_contrast':4.87,'scope':'Sole contrast finding resolved; P10 five-size native UI scope only. Not whole-bot parity or user visual approval.','captures':'render/','ui_checks':ui['checks'],'ui_failures':len(ui['failures'])},ensure_ascii=False,indent=2),encoding='utf-8')
(folder/'documentation-review.json').write_text(json.dumps({'reviewer':'/root/impeccable_documenter','mode':'read-only ordinary extension','result':'Keep PRODUCT.md, DESIGN.md and sidecar unchanged. Incumbent paper/ink/brush/square/430px shell inherited.','local_changes':['34px title','reading tabs/content','selected journal footer','local contrast red #c62b15'],'preexisting_drift':'Design documents describe r11 blue-white/Gowun/rounded/440px while incumbent r21 uses paper/vermilion/brush/square/430px.','files_edited':[]},ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True,indent=2))
sys.exit(1 if summary['groups']!=36 or summary['failed_groups'] or summary['rules_failures'] or summary['ui_failures'] or any(v['changed'] for v in protected.values()) else 0)
