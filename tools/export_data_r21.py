from pathlib import Path
import subprocess,sys,json,hashlib
R=Path(__file__).resolve().parents[1]; out=R/'verification/data-r21'
with (out/'export.log').open('wb') as f:
 p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--export-release','Web','../docs/index.html'],cwd=R,stdout=f,stderr=subprocess.STDOUT)
if p.returncode: raise SystemExit(p.returncode)
subprocess.run([sys.executable,'tools/update_version.py'],cwd=R,check=True)
pack=(R/'docs/index.pck').read_bytes()
required=['data/dungeons-r21.json','data/enemies-r21.json','game/dungeon_rules_r21.gd','game/dungeon_world_r21.gd','game/dungeon_enemy_r21.gd','game/dungeon_view_r21.gd']
missing=[name for name in required if name.encode() not in pack]
log=(out/'export.log').read_text(encoding='utf-8',errors='replace')
errors=[l for l in log.splitlines() if (l.startswith('ERROR:') or 'SCRIPT ERROR:' in l) and 'root certificate store' not in l]
report={'exit_code':p.returncode,'missing_resources':missing,'engine_errors':errors,'pck_bytes':len(pack),'pck_sha256':hashlib.sha256(pack).hexdigest(),'ui_build':json.loads((R/'docs/version.json').read_text(encoding='utf-8'))['ui_build']}
(out/'export-results.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report)); raise SystemExit(1 if missing or errors else 0)
