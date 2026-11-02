"""Measure workerd process CPU and request wall time without cloud credentials."""
from pathlib import Path
import subprocess,os,json,psutil
root=Path(__file__).resolve().parents[1];env=os.environ.copy()
env.setdefault('ABYSS_NODE_MODULES','C:/Users/asone/AppData/Local/npm-cache/_npx/c943b712072b77c4/node_modules')
p=subprocess.Popen(['node','server/abyss-save/test/pbkdf2-bench.mjs'],cwd=root,env=env,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,encoding='utf-8')
results=[]
try:
    line=p.stdout.readline();assert line, p.stderr.read()
    ready=json.loads(line);assert ready['ready'],ready
    workers=[x for x in psutil.Process(p.pid).children(recursive=True) if 'workerd' in x.name().lower()]
    assert workers, 'workerd process not found'
    def cpu():return sum(x.cpu_times().user+x.cpu_times().system for x in workers)
    for n in [0,5000,100000]:
        before=cpu();p.stdin.write(str(n)+'\n');p.stdin.flush()
        value=json.loads(p.stdout.readline());value['workerd_cpu_mean_ms']=(cpu()-before)*1000/value['n'];results.append(value)
    p.stdin.write('quit\n');p.stdin.flush();p.wait(timeout=30);assert p.returncode==0,p.stderr.read()
finally:
    if p.poll() is None:p.terminate()
out=root/'verification/cloud-r22/p9b/pbkdf2-results.json'
out.write_text(json.dumps({'samples':results,'measurement':'Windows workerd process user+system CPU / 100 requests; dedicated Worker running the shipped hash function; local CPU, not Cloudflare production CPU','default_iterations':5000},indent=2),encoding='utf-8')
print(json.dumps(results))
