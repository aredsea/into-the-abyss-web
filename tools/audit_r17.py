from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[1]
out=root/'verification/ui-r17'
before=json.loads((out/'before.json').read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
changed=[p.replace('\\','/') for p,h in before['hashes'].items() if not (root/p).is_file() or sha(root/p)!=h]
forbidden=[p for p in changed if p.startswith(('project/game/','project/data/','project/assets/')) or (p.startswith('project/ui/') and p!='project/ui/battle_screen.gd')]
manifest=json.loads((root/'ASSET-HASHES.json').read_text(encoding='utf-8'))
asset_errors=[p['path'] for p in manifest if sha(root/p['path'])!=p['sha256']]
logs=['import-final.log','input.log','motion-integration.log','export.log']
engine_errors={}
for name in logs:
    raw=(out/name).read_bytes()
    lines=raw.decode('utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8-sig').splitlines()
    errors=[l for l in lines if ('ERROR:' in l or 'SCRIPT ERROR' in l) and 'root certificate store' not in l and 'CategoryInfo' not in l]
    engine_errors[name]=errors
current=(root/'docs/index.pck').stat().st_size
pass1=json.loads((out/'pass2-build-before.json').read_text(encoding='utf-8'))['pck_bytes']
report={'changed_baseline_files':changed,'forbidden_changes':forbidden,'asset_hashes_checked':len(manifest),'asset_hash_errors':asset_errors,'pck_before_bytes':before['pck_bytes'],'pck_after_bytes':current,'pck_delta_bytes':current-before['pck_bytes'],'pck_delta_percent':round((current/before['pck_bytes']-1)*100,4),'pck_sha256':sha(root/'docs/index.pck'),'engine_errors_except_certificate_store':engine_errors,'certificate_store_warning':'Godot cannot read the Windows root certificate store in this execution environment; no network functionality was tested.','render_sizes':{f'{state}-{width}.png':__import__('PIL.Image',fromlist=['Image']).open(out/f'{state}-{width}.png').size for state in ['base','target','status','skills','supplies','log'] for width in [390,360]}}
report.update({'pck_pass1_bytes':pass1,'pck_pass2_delta_bytes':current-pass1,'pck_pass2_delta_percent':round((current/pass1-1)*100,4)})
(out/'preservation-and-build.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
assert not forbidden and not asset_errors and not any(engine_errors.values()), report
print(json.dumps({k:report[k] for k in ['asset_hashes_checked','pck_before_bytes','pck_after_bytes','pck_delta_bytes','pck_delta_percent']}))
