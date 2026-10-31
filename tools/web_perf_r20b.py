"""Cold first-battle vector preparation, real Chrome with CDP 4x CPU throttle."""
from pathlib import Path
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
import threading,json,os,tempfile,statistics,sys,shutil
from playwright.sync_api import sync_playwright
R=Path(__file__).resolve().parents[1]; O=R/'verification/ui-r20'
runtime=O/'runtime/perf-browser';runtime.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(runtime)
for k in ['TEMP','TMP','TMPDIR']:os.environ[k]=str(runtime)
class Handler(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
 def end_headers(self):
  self.send_header('Cross-Origin-Opener-Policy','same-origin')
  self.send_header('Cross-Origin-Embedder-Policy','require-corp')
  super().end_headers()
debug_memory='--memory-debug' in sys.argv
if debug_memory:
 (O/'memory-web/ui-r11').mkdir(parents=True,exist_ok=True)
 for name in ['torva-daylight.png','GowunBatang-loading.woff2']:
  shutil.copyfile(R/'docs/ui-r11'/name,O/'memory-web/ui-r11'/name)
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(O/'memory-web' if debug_memory else R/'docs')))
threading.Thread(target=server.serve_forever,daemon=True).start()
samples=[]
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True,args=['--enable-unsafe-swiftshader'])
  for trial in range(3 if debug_memory else 5):
   context=browser.new_context(viewport={'width':390,'height':844},device_scale_factor=1,locale='ko-KR')
   page=context.new_page();errors=[]
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
   cdp=context.new_cdp_session(page)
   cdp.send('Emulation.setCPUThrottlingRate',{'rate':4})
   page.goto(f'http://127.0.0.1:{server.server_port}/')
   page.wait_for_function('window.__abyssWorld',timeout=120000)
   def click(id):
    report=page.evaluate('window.__abyssWorld');q=report['controls'][id]['rect'];canvas=page.locator('canvas').bounding_box()
    page.mouse.click(canvas['x']+(q[0]+q[2]/2)*canvas['width']/report['viewport'][0],canvas['y']+(q[1]+q[3]/2)*canvas['height']/report['viewport'][1])
    page.wait_for_timeout(300)
   for id in ['depart','start_run']:click(id)
   assert not page.evaluate('Boolean(window.__abyssInkPrep)')
   click('travel:patrol')
   page.wait_for_function('window.__abyssInkPrep',timeout=60000)
   result=page.evaluate('window.__abyssInkPrep');result.update(trial=trial+1,cpu_throttle_rate=4,errors=errors)
   samples.append(result)
   print(json.dumps(result),flush=True)
   context.close()
  version=browser.version;browser.close()
finally:server.shutdown();server.server_close()
report={'browser_version':version,'viewport':[390,844],'cpu_throttle_rate':4,'cold_contexts':len(samples),'debug_memory_build':debug_memory,'samples':samples,
        'median_total_ms':statistics.median(s['total_ms'] for s in samples),'max_total_ms':max(s['total_ms'] for s in samples),
        'median_static_delta_bytes':statistics.median(s['static_delta_bytes'] for s in samples),
        'method':'Fresh browser contexts, no prior battle/ink load. CDP Emulation.setCPUThrottlingRate rate=4 before navigation. A contiguous synchronous timer covers first resource load/decompression plus compilation and GPU buffer submission of all three initially visible assets. End is render-ready mesh/cache creation; normal first-paint frame scheduling and unrelated battle UI are excluded. No texture baking or GPU readback. OS.get_static_memory_usage brackets the same ink-only work; release export has this counter disabled, so debug export measures static allocation separately. Packed-array and initial mesh buffer byte counts are exact payload sizes, exclude allocator/dictionary/GPU driver overhead. No network time: data is already in mounted PCK.'}
report['within_150ms']=report['max_total_ms']<=150
(O/('r20b-memory-debug.json' if debug_memory else 'r20b-performance.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
assert len(samples)==(3 if debug_memory else 5) and not any(s['errors'] for s in samples)
if debug_memory: assert all(s['static_counter_available'] for s in samples)
