from pathlib import Path
import subprocess,sys,json,hashlib,re
root=Path(__file__).resolve().parents[1];folder=root/'verification/persona-r22'
p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--editor','--import','--quit'],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
log=p.stdout.decode('utf-8',errors='replace');(folder/'import.log').write_text(log,encoding='utf-8')
errors=[s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
import_result={'exit':p.returncode,'errors':errors,'baseline_diagnostic':'Failed to read the root certificate store' if 'root certificate store' in log else ''}
(folder/'import-result.json').write_text(json.dumps(import_result,indent=2),encoding='utf-8')
hashes=json.loads((root/'ASSET-HASHES.json').read_text(encoding='utf-8'))
assets={'checked':len(hashes),'mismatches':[h['path'] for h in hashes if hashlib.sha256((root/h['path']).read_bytes()).hexdigest()!=h['sha256']]}
source=json.loads((folder/'provenance.json').read_text(encoding='utf-8'))['files']
source_changed=[h['name'] for h in source if hashlib.sha256((Path('C:/Clauede Code/dungeon-bot/bot/src')/h['name']).read_bytes()).hexdigest()!=h['sha256']]
specs=json.loads((folder/'legacy-specimens.json').read_text(encoding='utf-8'))
legacy_changed=[h['source'] for h in specs if hashlib.sha256(Path(h['source']).read_bytes()).hexdigest()!=h['sha256']]
copy_changed=[h['path'] for h in specs if hashlib.sha256((root/h['path'].removeprefix('res://../')).read_bytes()).hexdigest()!=h['sha256']]
protected={'assets':assets,'source_lua':{'checked':len(source),'changed':source_changed},'historical_copies':{'checked':len(specs),'changed':copy_changed},'historical_source_drift':{'note':'Read-only external worktrees are live; migration tests use the immutable local copies with capture-time SHA256. No source path is a write target of these tools.','changed_since_capture':legacy_changed}}
(folder/'protected.json').write_text(json.dumps(protected,ensure_ascii=False,indent=2),encoding='utf-8')
suite=json.loads((folder/'regression.json').read_text(encoding='utf-8'));rules=json.loads((folder/'results.json').read_text(encoding='utf-8'));ui=json.loads((folder/'ui-results.json').read_text(encoding='utf-8'))
summary={'groups':len(suite)+1,'failed_groups':sum(bool(r['exit'] or r['errors']) for r in suite)+bool(p.returncode or errors),'rules_checks':rules['checks'],'rules_failures':len(rules['failures']),'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'oracle_cases':sum(rules['oracle_counts'].values()),'legacy_specimens':len(specs),'native_sizes':5,'flow_captures':len(ui['captures']),'additional_battle_captures':2,'protected':protected,'import':import_result}
(folder/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
sys.exit(1 if summary['failed_groups'] or assets['mismatches'] or source_changed or copy_changed else 0)
