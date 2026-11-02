from pathlib import Path
import subprocess,sys,json,time
R=Path(__file__).resolve().parents[1]
name=sys.argv[1]; out=R/'verification/data-r21'; log=out/(name+'.log')
with log.open('wb') as f:
 p=subprocess.Popen([sys.executable,'tools/godot_r17.py','--headless','--script',f'res://tests/{name}.gd'],cwd=R,stdout=f,stderr=subprocess.STDOUT)
 try: code=p.wait(timeout=120)
 except subprocess.TimeoutExpired:
  subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True); code=-1
text=log.read_text(encoding='utf-8',errors='replace')
print(text[-14000:]); print('exit',code)
sys.exit(code)
