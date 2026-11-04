"""Reuse the project's real Worker/D1 harness on an independent loopback port."""
from pathlib import Path
import os,sys
R=Path(__file__).resolve().parents[1]
os.environ['R23_RUNTIME_SLOT']='reskin-main'
(R/'verification/reskin-r24/cloud').mkdir(parents=True,exist_ok=True)
(R/'verification/reskin-r24/tmp').mkdir(parents=True,exist_ok=True)
source=(R/'tools/look_r24_cloud.py').read_text(encoding='utf-8')
source=source.replace('verification/look-r24/cloud','verification/reskin-r24/cloud').replace('verification/look-r24/tmp','.p9tmp')
source=source.replace("'tools/godot_r17.py','--headless','--script'","'tools/godot_r17.py',*(['--position','-10000,-10000'] if name.startswith('ui_') else ['--headless']),'--script'")
if len(sys.argv)==1:
 sys.argv += sorted(p.stem for p in (R/'project/tests').glob('*_test.gd') if 'cloud' in p.stem)+['town_combat_r21_round14_test','town_r21_round11_test']
exec(compile(source,str(R/'tools/look_r24_cloud.py'),'exec'),{'__file__':str(R/'tools/look_r24_cloud.py'),'__name__':'__main__'})
