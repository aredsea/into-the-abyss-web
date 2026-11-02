from pathlib import Path
import subprocess,sys,json,hashlib,re
root=Path(__file__).resolve().parents[1];folder=root/'verification/panels-r22'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--editor','--import','--quit'],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
log=p.stdout.decode('utf-8',errors='replace');(folder/'import.log').write_text(log,encoding='utf-8')
errors=[s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
import_result={'exit':p.returncode,'errors':errors,'baseline_diagnostic':'Failed to read the root certificate store' if 'root certificate store' in log else ''}
(folder/'import-result.json').write_text(json.dumps(import_result,indent=2),encoding='utf-8')
original=json.loads((root/'ASSET-HASHES.json').read_text(encoding='utf-8'))
portraits=json.loads((folder/'portrait-hashes.json').read_text(encoding='utf-8'))
source=json.loads((folder/'provenance.json').read_text(encoding='utf-8'))['files']
protected={
 'original_assets':{'checked':len(original),'changed':[e['path'] for e in original if sha(root/e['path'])!=e['sha256']]},
 'r21_portrait_files':{'checked':len(portraits),'changed':[e['path'] for e in portraits if sha(root/e['path'])!=e['sha256']],'baseline':'Captured during this session before the final validation round; no P7 tool writes asset paths.'},
 'source_lua':{'checked':len(source),'changed':[e['name'] for e in source if sha(Path('C:/Clauede Code/dungeon-bot/bot/src')/e['name'])!=e['sha256']]}}
(folder/'protected.json').write_text(json.dumps(protected,ensure_ascii=False,indent=2),encoding='utf-8')
scope=[]
for line in (root/'PARITY-R21.md').read_text(encoding='utf-8').splitlines():
    if re.match(r'^\|P\d+\|(?:65-codex|66-status|74-affection|85-portrait|86-portrait-have)\.lua:',line):scope.append(line)
(folder/'parity-scope.json').write_text(json.dumps({'baseline_rows':scope,'count':len(scope),'judgment':'Scope preserved, not bulk relabelled as complete. See P7-R22.md for native/source differences and remaining integration.'},ensure_ascii=False,indent=2),encoding='utf-8')
suite=json.loads((folder/'regression.json').read_text(encoding='utf-8'));rules=json.loads((folder/'results.json').read_text(encoding='utf-8'));ui=json.loads((folder/'ui-results.json').read_text(encoding='utf-8'))
summary={'groups':len(suite)+1,'failed_groups':sum(bool(r['exit'] or r['errors']) for r in suite)+bool(p.returncode or errors),'rules_checks':rules['checks'],'rules_failures':len(rules['failures']),'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'oracle_cases':sum(rules['oracle_counts'].values()),'oracle_counts':rules['oracle_counts'],'native_sizes':5,'captures':len(ui['captures']),'parity_baseline_rows':len(scope),'protected':protected,'import':import_result}
(folder/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True,indent=2))
sys.exit(1 if summary['failed_groups'] or summary['rules_failures'] or summary['ui_failures'] or any(v['changed'] for v in protected.values()) else 0)
