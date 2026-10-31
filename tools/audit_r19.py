"""Finalize R19 protected-byte, test, and local Web-build evidence."""
from pathlib import Path
import hashlib,json,shutil
R=Path(__file__).resolve().parents[1]; O=R/'verification/ui-r19'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=json.loads((O/'before.json').read_text(encoding='utf-8'))
changed=[p for p,h in before['hashes'].items() if not (R/p).is_file() or sha(R/p)!=h]
protected=[p for p in before['hashes'] if p.startswith(('project/game/','project/data/'))]
manifest=json.loads((R/'ASSET-HASHES.json').read_text(encoding='utf-8'))
asset_errors=[p['path'] for p in manifest if sha(R/p['path'])!=p['sha256']]
allowed={'battle_screen.gd','battle_face_r17.gd','battle_ink_r17.gd'}
unexpected=[p for p in changed if p.startswith('project/ui/') and Path(p).name not in allowed]
steps={mode:json.loads((O/f'{mode}.json').read_text(encoding='utf-8')) for mode in ['checks','input','motion','state','r18','render','export']}
errors=[{'mode':m,'result':j} for m,jobs in steps.items() for j in jobs if j['exit_code'] or j['engine_errors']]
for src,name in [('verification/ui-r17/battle-input-results.json','r17-input-results.json'),('verification/ui-r17/ink-text-results.json','ink-text-results.json'),('verification/ui-r17/motion-r9/results.json','r9-results.json'),('verification/ui-r18/r18-results.json','r18-results.json'),('verification/ui-r18/state-integration/results.json','r18-integration-results.json')]:shutil.copyfile(R/src,O/name)
version=json.loads((R/'docs/version.json').read_text(encoding='utf-8'))
new=[p.relative_to(R).as_posix() for base in ['project/ui','project/tests','project/assets/ui-r17','project/assets/fonts','tools'] for p in (R/base).glob('*') if p.is_file() and p.relative_to(R).as_posix() not in before['hashes']]
report={'changed_baseline_files':changed,'source_inventory':new,'protected_game_data_files':len(protected),'protected_changes':[p for p in changed if p in protected],'original_assets_checked':len(manifest),'original_asset_hash_errors':asset_errors,'unexpected_shared_ui_changes':unexpected,'world_screen_unchanged':'project/ui/world_screen.gd' not in changed,'pck_before_bytes':before['pck_bytes'],'pck_after_bytes':(R/'docs/index.pck').stat().st_size,'version':version,'pck_matches_version':sha(R/'docs/index.pck')==version['pck_sha256'],'wasm_matches_version':sha(R/'docs/index.wasm')==version['wasm_sha256'],'verification_steps':steps,'errors':errors,'known_environment_message':'Windows root certificate store unavailable. Network behavior not tested.'}
report['pck_delta_bytes']=report['pck_after_bytes']-report['pck_before_bytes']
report['pck_delta_percent']=round(report['pck_delta_bytes']/report['pck_before_bytes']*100,4)
(O/'preservation-and-build.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
summary={name:json.loads((O/file).read_text(encoding='utf-8')) for name,file in [('r17','r17-input-results.json'),('r9','r9-results.json'),('r18','r18-results.json'),('r18_integration','r18-integration-results.json')]}
summary['r19']={k:v for k,v in json.loads((O/'r19-results.json').read_text(encoding='utf-8')).items() if k!='measurements'}
summary['comparison']=json.loads((O/'comparison-summary.json').read_text(encoding='utf-8'))
summary['web']=json.loads((O/'web/results.json').read_text(encoding='utf-8'))
summary['preservation']={k:v for k,v in report.items() if k not in ['verification_steps','source_inventory']}
(O/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
assert not report['protected_changes'] and not asset_errors and not unexpected and not errors
assert report['pck_matches_version'] and report['wasm_matches_version']
assert all(not summary[k]['failures'] for k in ['r17','r9','r18','r18_integration','r19'])
assert len(summary['web'])==3 and all(not v['errors'] and not v['text_errors'] for v in summary['web'])
assert summary['web'][0]['viewport_restored_after_victory']
print(json.dumps({k:report[k] for k in ['protected_game_data_files','original_assets_checked','pck_before_bytes','pck_after_bytes','pck_delta_bytes','errors']},indent=2))
