"""Compare protected bytes, collect final verification, and publish a local audit."""
from pathlib import Path
import hashlib,json,shutil
r=Path(__file__).resolve().parents[1]; out=r/'verification/ui-r18'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=json.loads((out/'before.json').read_text(encoding='utf-8'))
changed=[p for p,h in before['hashes'].items() if not (r/p).is_file() or sha(r/p)!=h]
protected=[p for p in before['hashes'] if p.startswith(('project/game/','project/data/'))]
preserved=[p for p in protected if p not in changed]
manifest=json.loads((r/'ASSET-HASHES.json').read_text(encoding='utf-8'))
asset_errors=[p['path'] for p in manifest if sha(r/p['path'])!=p['sha256']]
allowed_ui={'battle_screen.gd','combat_presentation.gd','combat_fx.gd','signature_sequence.gd','motion_library.gd'}
unexpected=[p for p in changed if p.startswith('project/ui/') and Path(p).name not in allowed_ui]
steps={mode:json.loads((out/f'{mode}.json').read_text(encoding='utf-8')) for mode in ['checks','input','motion','state','render','export']}
errors=[{'mode':m,'result':j} for m,jobs in steps.items() for j in jobs if j['exit_code'] or j['engine_errors']]
current=(r/'docs/index.pck').stat().st_size
version=json.loads((r/'docs/version.json').read_text(encoding='utf-8'))
new=[str(p.relative_to(r)).replace('\\','/') for base in ['project/ui','project/tests','tools'] for p in (r/base).glob('*') if p.is_file() and str(p.relative_to(r)).replace('\\','/') not in before['hashes']]
report={'changed_baseline_files':changed,'new_source_files':new,'protected_game_data_files':len(protected),'protected_game_data_preserved':len(preserved),'protected_changes':[p for p in changed if p in protected],'original_assets_checked':len(manifest),'original_asset_hash_errors':asset_errors,'unexpected_shared_ui_changes':unexpected,'world_screen_unchanged':'project/ui/world_screen.gd' not in changed,'pck_before_bytes':before['pck_bytes'],'pck_after_bytes':current,'pck_delta_bytes':current-before['pck_bytes'],'pck_delta_percent':round((current/before['pck_bytes']-1)*100,4),'version':version,'pck_matches_version':sha(r/'docs/index.pck')==version['pck_sha256'],'wasm_matches_version':sha(r/'docs/index.wasm')==version['wasm_sha256'],'verification_steps':steps,'errors':errors,'known_environment_message':'Windows root certificate store unavailable; network behavior not tested.'}
for file in ['battle-input-results.json','ink-text-results.json']:
 shutil.copyfile(r/'verification/ui-r17'/file,out/file)
shutil.copyfile(r/'verification/ui-r17/motion-r9/results.json',out/'motion-r9-results.json')
render=json.loads((out/'r18-results.json').read_text(encoding='utf-8'))
summary={'render_checks':render['checks'],'render_failures':render['failures'],'input':json.loads((out/'battle-input-results.json').read_text(encoding='utf-8')),'motion_r9':json.loads((out/'motion-r9-results.json').read_text(encoding='utf-8')),'motion_r18':json.loads((out/'state-integration/results.json').read_text(encoding='utf-8')),'original_assets_preserved':len(manifest)-len(asset_errors),'game_data_preserved':len(preserved),'previews':json.loads((out/'previews.json').read_text(encoding='utf-8')),'pck_before_bytes':before['pck_bytes'],'pck_after_bytes':current,'build':version}
(out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
(out/'preservation-and-build.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
assert len(protected)==len(preserved) and not asset_errors and not unexpected and not errors
assert report['pck_matches_version'] and report['wasm_matches_version']
print(json.dumps({k:report[k] for k in ['protected_game_data_files','original_assets_checked','pck_before_bytes','pck_after_bytes','pck_delta_bytes','pck_delta_percent','errors']},indent=2))
