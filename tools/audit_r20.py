"""Final R20 byte preservation, regression, contour, and Web evidence audit."""
from pathlib import Path
import hashlib,json,struct

R=Path(__file__).resolve().parents[1];O=R/'verification/ui-r20'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=read(O/'before.json')
changed=[p for p,h in before['hashes'].items() if not (R/p).is_file() or sha(R/p)!=h]
protected=[p for p in before['hashes'] if p.startswith(('project/game/','project/data/'))]
manifest=read(R/'ASSET-HASHES.json')
asset_errors=[a['path'] for a in manifest if sha(R/a['path'])!=a['sha256']]
steps={m:read(O/f'{m}.json') for m in ['checks','input','motion','state','r18','render','r20','export']}
errors=[{'mode':m,'test':x} for m,jobs in steps.items() for x in jobs if x['exit_code'] or x['engine_errors']]
allowed_ui={'project/ui/battle_screen.gd','project/ui/battle_ink_r17.gd'}
unexpected=[p for p in changed if p.startswith('project/ui/') and p not in allowed_ui]
version=read(R/'docs/version.json')
report={'protected_game_data_files':len(protected),'protected_changes':[p for p in changed if p in protected],
        'original_assets_checked':len(manifest),'original_asset_hash_errors':asset_errors,
        'world_screen_unchanged':'project/ui/world_screen.gd' not in changed,
        'r18_signature_sequence_unchanged':'project/ui/signature_sequence.gd' not in changed,
        'unexpected_ui_changes':unexpected,'changed_baseline_files':changed,
        'pck_before_bytes':before['pck_bytes'],'pck_after_bytes':(R/'docs/index.pck').stat().st_size,
        'version':version,'pck_matches_version':sha(R/'docs/index.pck')==version['pck_sha256'],
        'wasm_matches_version':sha(R/'docs/index.wasm')==version['wasm_sha256'],
        'verification_steps':steps,'engine_errors':errors,
        'binary_vector_bytes':(R/'project/assets/ui-r20/ink-paths.res').stat().st_size,
        'raw_vector_json_bytes':0,'exported_vector_gzip_bytes':0}
report['pck_delta_bytes']=report['pck_after_bytes']-report['pck_before_bytes']
report['pck_delta_percent']=report['pck_delta_bytes']/report['pck_before_bytes']*100
packed=(R/'docs/index.pck').read_bytes()
assert packed[:4]==b'GDPC' and struct.unpack_from('<I',packed,4)[0]==4
base=struct.unpack_from('<Q',packed,24)[0];offset=struct.unpack_from('<Q',packed,32)[0]
count=struct.unpack_from('<I',packed,offset)[0];offset+=4;entries=[]
for _ in range(count):
 n=struct.unpack_from('<I',packed,offset)[0];offset+=4
 name=packed[offset:offset+n].rstrip(b'\0').decode();offset+=n
 pos,size=struct.unpack_from('<QQ',packed,offset);offset+=16
 digest=packed[offset:offset+16].hex();offset+=16
 flags=struct.unpack_from('<I',packed,offset)[0];offset+=4
 entries.append({'path':name,'bytes':size,'offset':pos,'md5':digest,'flags':flags})
 assert hashlib.md5(packed[base+pos:base+pos+size]).hexdigest()==digest,name
(O/'pck-manifest.json').write_text(json.dumps(entries,indent=2),encoding='utf-8')
ink_entries=[e for e in entries if e['path'].startswith('assets/ui-r20/') or 'target-outline.svg-' in e['path']]
report['pck_ink_entries']=ink_entries
report['pck_ink_payload_bytes']=sum(e['bytes'] for e in ink_entries)
report['pck_ink_with_alignment_and_directory_bytes']=sum((e['bytes']+15)//16*16+4+(len(e['path'].encode())+4)//4*4+36 for e in ink_entries)
report['no_legacy_vector_json_in_project']=not list((R/'project/assets/ui-r20').glob('*.json*'))
report['no_legacy_vector_json_in_pck']=not any('ink-paths.json' in e['path'] for e in entries)
report['r20b_before']=read(O/'r20b-before.json')
report['ink_under_half_megabyte']=report['pck_ink_with_alignment_and_directory_bytes']<=500000
summary={k:read(O/p) for k,p in {'r17':'r17-input-results.json','r9':'r9-results.json','r18':'r18-results.json',
         'r18_integration':'r18-integration-results.json','r19':'r19-results.json','r20':'r20-results.json',
         'comparison':'comparison-summary.json','ink':'ink-summary.json','web':'web/results.json',
         'performance':'r20b-performance.json','memory_debug':'r20b-memory-debug.json',
         'binary_roundtrip':'binary-roundtrip.json','r20b_visual':'r20b-visual-comparison.json'}.items()}
for name in ['r19','r20']:summary[name].pop('measurements',None)
summary['preservation']=report
(O/'preservation-and-build.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
(O/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
assert not report['protected_changes'] and not asset_errors and not unexpected and not errors
assert report['world_screen_unchanged'] and report['r18_signature_sequence_unchanged']
assert report['pck_matches_version'] and report['wasm_matches_version']
assert report['no_legacy_vector_json_in_project'] and report['no_legacy_vector_json_in_pck']
assert report['pck_ink_with_alignment_and_directory_bytes']<=1000000
assert report['ink_under_half_megabyte']
assert summary['binary_roundtrip']['roundtrip_equal'] and summary['binary_roundtrip']['assets']==18
assert summary['binary_roundtrip']['resource_sha256']==sha(R/'project/assets/ui-r20/ink-paths.res')
assert version['ui_build']=='battle-r20b-20261031'
assert summary['performance']['within_150ms'] and len(summary['performance']['samples'])==5
assert not any(s['errors'] for s in summary['performance']['samples'])
assert all(s['static_counter_available'] and s['static_delta_bytes']>0 and not s['errors'] for s in summary['memory_debug']['samples'])
assert all(not summary[k]['failures'] for k in ['r17','r9','r18','r18_integration','r19','r20'])
assert len(summary['web'])==5 and all(not x['errors'] and not x['text_errors'] for x in summary['web'])
assert summary['web'][0]['viewport_restored_after_victory']
assert all(not summary['ink'][k] for k in ['asset_failures','state_failures','position_failures','text_failures','mae_failures'])
assert all(c['outside_changed_pixels']==0 and c['inside_changed_pixels']>0 for c in summary['r20']['clipping'])
print(json.dumps({k:report[k] for k in ['protected_game_data_files','original_assets_checked','pck_before_bytes','pck_after_bytes','pck_delta_bytes','pck_delta_percent','engine_errors']},indent=2))
