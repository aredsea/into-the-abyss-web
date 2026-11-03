from pathlib import Path
import os
R=Path(__file__).resolve().parents[1]
os.environ.setdefault('ABYSS_NODE_MODULES',str(R.parent/'r21-d-town/server/abyss-save'))
os.environ['NODE_OPTIONS']='--import '+(R/'tools/ui_r23_phase4_modules.mjs').as_uri()
source=(R/'tools/ui_r23_server_tests.py').read_text(encoding='utf-8').replace("OUT=ROOT/'verification/parity-r23/server'","OUT=ROOT/'verification/parity-r23/ui-phase4/server'")
source=source.replace("OUT.mkdir(exist_ok=True)","OUT.mkdir(exist_ok=True,parents=True)").replace("(name+'.log')","('ui-'+name+'.log')").replace("results.json","ui-results.json")
exec(compile(source,str(R/'tools/ui_r23_server_tests.py'),'exec'),{'__file__':str(R/'tools/ui_r23_server_tests.py'),'__name__':'__main__'})
