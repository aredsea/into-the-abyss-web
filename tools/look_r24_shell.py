"""Render the source shell without exporting WASM or changing docs/."""
from pathlib import Path
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
import threading,sys,re,json
from playwright.sync_api import sync_playwright
R=Path(__file__).resolve().parents[1]
phase=sys.argv[1] if len(sys.argv)>1 else 'after'
O=R/'verification/look-r24'/phase;O.mkdir(parents=True,exist_ok=True)
source=(R/'project/web_shell.html').read_text(encoding='utf-8')
# Engine is a test double only for download callbacks. The unmodified DOM/CSS
# and both real shell scripts run, including failure and challenge cancellation.
source=source.replace('$GODOT_PROJECT_NAME','Into the Abyss').replace('$GODOT_HEAD_INCLUDE','').replace('$GODOT_CONFIG','{}').replace('$GODOT_THREADS_ENABLED','false')
source=source.replace('<script src="$GODOT_URL" onerror="abyssLoadingFailed()"></script>', '''<script>
class Engine {static getMissingFeatures(){return []} startGame(c){window.shellProgress=c.onProgress;c.onProgress(37,100);return new Promise(()=>{})}}
</script>''')
if phase=='after':(O.parent/'shell-preview.html').write_text(source,encoding='utf-8')
class Handler(SimpleHTTPRequestHandler):
 def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(R),**kwargs)
 def log_message(self,*args):pass
 def do_GET(self):
  if self.path.split('?')[0]=='/':
   body=source.encode();self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.end_headers();self.wfile.write(body)
  else:
   # Old shell resources also remain available for the before evidence.
   if self.path.startswith('/ui-r11/'):self.path='/docs'+self.path
   super().do_GET()
server=ThreadingHTTPServer(('127.0.0.1',0),Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
results=[]
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True)
  configs=[(390,844,False),(1280,800,False)] if phase=='before' else [(360,780,False),(390,664,False),(390,844,False),(430,932,False),(1280,800,False),(360,780,True)]
  for w,h,reduced in configs:
   context=browser.new_context(viewport={'width':w,'height':h},reduced_motion='reduce' if reduced else 'no-preference')
   page=context.new_page();errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
   page.goto(f'http://127.0.0.1:{server.server_port}/');page.evaluate('document.fonts.ready');page.wait_for_timeout(200)
   for state in ['loading','indeterminate','starting','error','challenge']:
    page.evaluate("document.getElementById('progress').hidden=false;document.getElementById('retry').hidden=true")
    if state=='loading':page.evaluate('shellProgress(37,100)')
    elif state=='indeterminate':page.evaluate('shellProgress(0,0)')
    elif state=='starting':page.evaluate('shellProgress(100,100)')
    elif state=='error':page.evaluate('abyssLoadingFailed()')
    elif state=='challenge':page.evaluate("document.getElementById('cloud-challenge').showModal()")
    suffix='-reduced' if reduced else ''
    name=f'loading-{state}-{w}x{h}{suffix}.png';page.screenshot(path=str(O/name))
    issues=page.evaluate('''() => {
     const issues=[]; for(const e of document.querySelectorAll('h1,h2,p,button,.status-box,progress')){
      if(!e.getClientRects().length)continue;const r=e.getBoundingClientRect();
      if(r.width && (r.left<-.5||r.right>innerWidth+.5||e.scrollWidth>e.clientWidth+1||e.scrollHeight>e.clientHeight+1))issues.push(e.id||e.tagName);
     }return issues;
    }''')
    layout=page.evaluate('''() => {
     const poster=document.querySelector('.poster'),box=document.querySelector('.status-box');
     if(!poster)return null;
     const p=poster.getBoundingClientRect(),b=box.getBoundingClientRect();
     return {poster_bottom:p.bottom,status_top:b.top,gap:b.top-p.bottom,mask:getComputedStyle(poster).maskImage!=='none'};
    }''')
    if phase=='after' and (not layout or not layout['mask'] or not 0<=layout['gap']<=9):issues.append('poster/brush/status spacing')
    results.append({'file':name,'issues':issues,'errors':list(errors),'layout':layout})
    if state=='challenge':
     page.click('#cloud-challenge-cancel');assert not page.evaluate("document.getElementById('cloud-challenge').open")
   context.close()
  browser.close()
finally:server.shutdown()
(O.parent/(phase+'-shell-results.json')).write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'captures':len(results),'failures':sum(bool(r['issues'] or r['errors']) for r in results)}))
sys.exit(any(r['issues'] or r['errors'] for r in results))
