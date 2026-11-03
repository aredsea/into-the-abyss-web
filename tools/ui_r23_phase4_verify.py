"""Run the full repository suite using the established local Worker adapter."""
from pathlib import Path
import subprocess,sys,os
R=Path(__file__).resolve().parents[1]
os.environ.setdefault('ABYSS_NODE_MODULES',str(R.parent/'r21-d-town/server/abyss-save'))
source=(R/'tools/ui_r23_verify.py').read_text(encoding='utf-8')
source=source.replace("OUT=ROOT/'verification/parity-r23'","OUT=ROOT/'verification/parity-r23/ui-phase4'")
source=source.replace("(name+'.log')","('ui-'+name+'.log')")
for name in ['regression.json','local-server.log','server-lifecycle.json']:
    source=source.replace(name,'ui-'+name)
# The original tool resolves its root from __file__; execute it with that context.
exec(compile(source,str(R/'tools/ui_r23_verify.py'),'exec'),{'__file__':str(R/'tools/ui_r23_verify.py'),'__name__':'__main__'})
