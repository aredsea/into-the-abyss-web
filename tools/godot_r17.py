"""Run Godot with all runtime writes inside this work tree. No git operations."""
from pathlib import Path
import os,subprocess,sys,shutil
root=Path(__file__).resolve().parents[1]
exe=Path('C:/Users/asone/Documents/Codex/2026-10-18/into-the-abyss-c-clauede-code/work/godot-toolchain/Godot_v4.7.2-stable_win64_console.exe')
# A self-contained engine writes beside its executable. Isolate even those writes
# inside the only user-authorized tree, including editor settings and templates.
engine_home=root/'verification/ui-r17/runtime/engine'
engine_home.mkdir(parents=True,exist_ok=True)
local_exe=engine_home/exe.name
if not local_exe.exists(): shutil.copyfile(exe,local_exe)
main_exe=exe.with_name(exe.name.replace('_console',''))
if not (engine_home/main_exe.name).exists(): shutil.copyfile(main_exe,engine_home/main_exe.name)
(engine_home/'_sc_').touch()
template_source=exe.parent/'editor_data/export_templates/4.7.2.stable'
template_target=engine_home/'editor_data/export_templates/4.7.2.stable'
if not template_target.exists(): shutil.copytree(template_source,template_target)
exe=local_exe
env=os.environ.copy()
for key,folder in [('APPDATA','runtime'),('LOCALAPPDATA','runtime-local'),('TEMP','tmp'),('TMP','tmp')]:
    p=root/'verification/ui-r17'/folder; p.mkdir(parents=True,exist_ok=True); env[key]=str(p)
# Tests drive real battles; never play their combat sounds on the owner's speakers.
args=sys.argv[1:] if '--audio-driver' in sys.argv else ['--audio-driver','Dummy',*sys.argv[1:]]
sys.exit(subprocess.call([str(exe),'--path',str(root/'project'),*args],cwd=exe.parent,env=env))
