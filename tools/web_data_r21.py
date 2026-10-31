"""Real pointer input against the exported WASM; reload a live source encounter."""
from pathlib import Path
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
import threading,json,os,tempfile
from playwright.sync_api import sync_playwright
R=Path(__file__).resolve().parents[1]; O=R/'verification/data-r21/web'; O.mkdir(parents=True,exist_ok=True)
runtime=O/'runtime';runtime.mkdir(exist_ok=True);tempfile.tempdir=str(runtime)
for key in ['TEMP','TMP','TMPDIR']:os.environ[key]=str(runtime)
class Handler(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
 def end_headers(self):
  self.send_header('Cross-Origin-Opener-Policy','same-origin');self.send_header('Cross-Origin-Embedder-Policy','require-corp');super().end_headers()
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(R/'docs')))
threading.Thread(target=server.serve_forever,daemon=True).start(); results=[]
def same_state(a,b):
 if isinstance(a,dict):return isinstance(b,dict) and a.keys()==b.keys() and all(same_state(v,b[k]) for k,v in a.items())
 if isinstance(a,list):return isinstance(b,list) and len(a)==len(b) and all(same_state(x,y) for x,y in zip(a,b))
 if isinstance(a,(int,float)) and not isinstance(a,bool):return isinstance(b,(int,float)) and abs(a-b)<1e-8
 return a==b
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True,args=['--enable-unsafe-swiftshader'])
  for width,height in [(390,844),(360,780)]:
   context=browser.new_context(viewport={'width':width,'height':height},locale='ko-KR',device_scale_factor=1,reduced_motion='reduce')
   page=context.new_page(); errors=[]
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
   page.goto(f'http://127.0.0.1:{server.server_port}/');page.wait_for_function('window.__abyssWorld',timeout=90000)
   def click(id,battle=False):
    report=page.evaluate('window.__abyssPreview' if battle else 'window.__abyssWorld');q=report['controls'][id]['rect'];canvas=page.locator('canvas').bounding_box()
    page.mouse.click(canvas['x']+(q[0]+q[2]/2)*canvas['width']/report['viewport'][0],canvas['y']+(q[1]+q[3]/2)*canvas['height']/report['viewport'][1]);page.wait_for_timeout(250)
   click('depart');assert 'dungeon_floor' in page.evaluate('window.__abyssWorld.controls')
   page.screenshot(path=str(O/f'selector-{width}.png'));click('start_run')
   for _ in range(7):
    state=page.evaluate('window.__abyssWorld.state.run')
    if state['phase']=='battle':break
    click('final_battle' if state['phase']=='rest' else 'advance')
   page.wait_for_function('window.__abyssPreview && !window.__abyssPreview.busy',timeout=45000)
   initial=page.evaluate('window.__abyssPreview');assert initial['ui_build']=='r21-a-data-20261031'
   assert page.evaluate('window.__abyssWorld.state.run.data_version')==21
   click('action:attack',True);click('enemy:executor',True)
   page.wait_for_function('!window.__abyssPreview.busy',timeout=45000)
   before=page.evaluate('window.__abyssPreview');assert before['state']['turn_count']>initial['state']['turn_count']
   page.screenshot(path=str(O/f'battle-{width}.png'));page.reload()
   page.wait_for_function('window.__abyssPreview && !window.__abyssPreview.busy',timeout=90000)
   after=page.evaluate('window.__abyssPreview')
   (O/f'reload-{width}.json').write_text(json.dumps({'before':before,'after':after,'world':page.evaluate('window.__abyssWorld'),'errors':errors},ensure_ascii=False,indent=2),encoding='utf-8')
   assert same_state(after['state']['units'],before['state']['units']) and after['state']['rng']==before['state']['rng']
   assert page.evaluate('window.__abyssWorld.restored') is True
   text_errors=[t for t in after['text'] if t['needed']>t['available']+1 or t['missing_glyphs']]
   assert not text_errors,text_errors
   # Finish through real input and exercise World._leave_battle and settlement.
   for _ in range(100):
    report=page.evaluate('window.__abyssPreview')
    if report['result']:break
    target=min((e for e in report['enemy_hp'] if e['hp']>0),key=lambda e:e['hp'])['id']
    click('action:attack',True);click('enemy:'+target,True)
    page.wait_for_function('!window.__abyssPreview.busy',timeout=45000)
   final=page.evaluate('window.__abyssPreview');assert final['result']=='victory'
   click('retry',True);page.wait_for_function('window.__abyssWorld.screen!="battle"',timeout=10000)
   returned=page.evaluate('window.__abyssWorld');assert returned['state']['run']['gold']>0
   page.screenshot(path=str(O/f'return-{width}.png'))
   assert not errors,errors
   results.append({'width':width,'height':height,'ui_build':after['ui_build'],'turns_before_reload':before['state']['turn_count'],'reload_state_match':True,'float_tolerance':1e-8,'victory_return':True,'earned_gold':returned['state']['run']['gold'],'errors':errors,'text_errors':text_errors})
   context.close(); print('WEB_R21 PASS',width,flush=True)
  browser.close()
finally:
 server.shutdown();server.server_close();(O/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
