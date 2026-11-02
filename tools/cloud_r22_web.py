"""Local WASM + actual Worker/D1. Every game action uses pointer or keyboard input."""
from pathlib import Path
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from functools import partial
import json, threading, os, tempfile,sys
from playwright.sync_api import sync_playwright
R=Path(__file__).resolve().parents[1];O=R/'verification/cloud-r22';challenge='--turnstile-test' in sys.argv;W=O/('web-turnstile' if challenge else 'web')
runtime=O/'browser';runtime.mkdir(exist_ok=True);tempfile.tempdir=str(runtime)
for k in ['TEMP','TMP','TMPDIR']:os.environ[k]=str(runtime)
class Handler(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
 def end_headers(self):
  self.send_header('Cross-Origin-Opener-Policy','same-origin');self.send_header('Cross-Origin-Embedder-Policy','require-corp');super().end_headers()
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(W)))
threading.Thread(target=server.serve_forever,daemon=True).start()
checks=[]
def state(p):return p.evaluate('window.__abyssWorld')
def wait(p,expr):
 try:p.wait_for_function(expr,timeout=90000)
 except Exception:
  p.screenshot(path=str(O/'web-failure.png'));(O/'web-failure.json').write_text(json.dumps({'errors':errors,'state':state(p),'body':p.locator('body').inner_text()},ensure_ascii=False,indent=2),encoding='utf-8');raise
def click(p,key):
 for _ in range(18):
  s=state(p);assert key in s['controls'],(key,list(s['controls']))
  b=s['controls'][key];assert not b['disabled'],(key,s.get('cloud'))
  x,y,w,h=b['rect'];canvas=p.locator('canvas').bounding_box();sx=canvas['width']/s['viewport'][0];sy=canvas['height']/s['viewport'][1]
  if y+h/2<76 or y+h/2>s['viewport'][1]-20:
   p.mouse.move(canvas['x']+canvas['width']/2,canvas['y']+canvas['height']*.65);p.mouse.wheel(0,500 if y>76 else -500);p.wait_for_timeout(180);continue
  p.mouse.click(canvas['x']+(x+w/2)*sx,canvas['y']+(y+h/2)*sy);p.wait_for_timeout(300);return
 raise AssertionError('Cannot scroll to '+key)
def field(p,key,value):
 s=state(p);x,y,w,h=s['cloud']['inputs'][key];c=p.locator('canvas').bounding_box()
 p.mouse.click(c['x']+(x+w/2)*c['width']/s['viewport'][0],c['y']+(y+h/2)*c['height']/s['viewport'][1]);p.keyboard.type(value);p.wait_for_timeout(150)
def create(p,existing=False):
 p.goto(f'http://127.0.0.1:{server.server_port}/');wait(p,'window.__abyssWorld?.controls.cr_race_human')
 if existing:
  click(p,'cloud_open');wait(p,'window.__abyssWorld.screen==="cloud"');return
 nation=json.loads((R/'project/data/persona-r22.json').read_text(encoding='utf-8'))['nations'][0]['id']
 for key in ['cr_race_human','cr_next','cr_nat_'+nation,'cr_next','cr_cls_warrior','cr_next','cr_auto','cr_next','cr_done','sc_pick_marceline','sc_go']:click(p,key)
 wait(p,'window.__abyssWorld.state.scene==="town"');click(p,'nav:journal');click(p,'cloud_open');wait(p,'window.__abyssWorld.screen==="cloud"')
def idle(p):wait(p,'window.__abyssWorld.cloud && !window.__abyssWorld.cloud.busy')
try:
 with sync_playwright() as pw:
  browser=pw.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True,args=['--enable-unsafe-swiftshader'])
  contexts=[browser.new_context(viewport={'width':390,'height':844},locale='ko-KR') for _ in range(2)]
  if challenge:
   for context in contexts:context.add_init_script("window.turnstile={render(el,options){window.widgetOptions=options;window.widgetRenderCount=(window.widgetRenderCount||0)+1;el.textContent='테스트 인증 위젯';return 'local-widget'},remove(){},reset(){}}")
  pages=[c.new_page() for c in contexts];a,b=pages;errors=[]
  for index,p in enumerate(pages):
   p.on('pageerror',lambda e:errors.append(str(e)))
   p.on('console',lambda m:errors.append(m.text) if m.type=='error' and not m.text.startswith('Failed to load resource:') else None)
   p.on('response',lambda r:errors.append(f'HTTP {r.status} {r.url}') if r.status>=400 and not (r.status==409 and '/v1/save' in r.url) else None)
   create(p,existing=index==1)
  if challenge:
   click(a,'cloud_create');a.wait_for_function('window.widgetRenderCount===1');a.keyboard.press('Escape');idle(a)
   assert not state(a)['cloud']['code'];checks.append('Godot-challenge-cancel-keeps-local-adventure')
  with a.expect_response(lambda r:r.url.endswith('/v1/account') and r.request.method=='POST') as response:
   click(a,'cloud_create')
   if challenge:
    a.wait_for_function('window.widgetRenderCount===2 && window.widgetOptions?.action==="account"');assert a.locator('#cloud-challenge').is_visible()
    a.screenshot(path=str(O/'p9b/web-turnstile.png'))
    a.evaluate("widgetOptions.callback('synthetic-local-web-token')")
  issued=response.value.json();assert response.value.status==201,issued;idle(a);checks.append('first-save-account-PIN')
  if challenge:
   assert response.value.request.post_data_json['turnstile']=='synthetic-local-web-token';checks.append('Godot-HTML-token-in-account-POST')
  a.screenshot(path=str(O/'web-credentials.png'))
  field(b,'code',issued['code']);field(b,'pin',issued['pin']);click(b,'cloud_connect');idle(b)
  assert state(b)['cloud']['rev']==1;checks.append('second-browser-connect')
  assert state(b)['controls']['cloud_save']['disabled'] and state(b)['controls']['cloud_auto']['disabled'];checks.append('linked-until-download-upload-disabled')
  click(b,'cloud_load');click(b,'cloud_confirm');idle(b)
  assert state(a)['state']==state(b)['state'];checks.append('second-browser-load')
  click(a,'cloud_noted');click(a,'cloud_save');idle(a);assert state(a)['cloud']['rev']==2
  click(b,'cloud_save');idle(b);assert state(b)['cloud']['conflict'];b.screenshot(path=str(O/'web-conflict.png'));checks.append('actual-409')
  click(b,'cloud_keep_local');idle(b);assert state(b)['cloud']['rev']==3 and not state(b)['cloud']['conflict'];checks.append('choose-this-device')
  click(a,'cloud_save');idle(a);assert state(a)['cloud']['conflict']
  click(a,'cloud_keep_server');click(a,'cloud_confirm');idle(a);assert state(a)['cloud']['rev']==3;checks.append('choose-server-latest')
  click(a,'cloud_history');idle(a);click(a,'cloud_rev:1');click(a,'cloud_confirm');idle(a);assert state(a)['cloud']['rev']==3
  click(a,'cloud_save');idle(a);assert state(a)['cloud']['rev']==4;checks.append('history-new-revision')
  click(a,'cloud_rank');click(a,'rank_refresh');idle(a);a.screenshot(path=str(O/'web-rank.png'));checks.append('rank-query')
  click(a,'rank_back');click(a,'cloud_delete');click(a,'cloud_confirm');idle(a);assert not state(a)['cloud']['code'];assert state(a)['state']['gold']==300;checks.append('delete-retains-local')
  assert not errors,errors
  (O/('p9b/web-turnstile-results.json' if challenge else 'web-results.json')).write_text(json.dumps({'checks':checks,'failures':0,'contexts':2,'errors':errors,'provider':'local test double' if challenge else 'disabled / empty site key'},ensure_ascii=False,indent=2),encoding='utf-8')
  print('WEB CHECKS',len(checks),'FAILURES 0',flush=True);browser.close()
finally:server.shutdown()
