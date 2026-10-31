"""Exercise the exported WASM with actual pointer input on a local-only server."""
from pathlib import Path
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
import threading,json,os,tempfile
from playwright.sync_api import sync_playwright
R=Path(__file__).resolve().parents[1]; O=R/'verification/ui-r20/web'; O.mkdir(parents=True,exist_ok=True)
runtime=O.parent/'runtime/browser';runtime.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(runtime)
for key in ['TEMP','TMP','TMPDIR']:os.environ[key]=str(runtime)
class Handler(SimpleHTTPRequestHandler):
    def log_message(self,*args):pass
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy','same-origin')
        self.send_header('Cross-Origin-Embedder-Policy','require-corp')
        super().end_headers()
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(R/'docs')))
threading.Thread(target=server.serve_forever,daemon=True).start()
results=[]
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True,args=['--enable-unsafe-swiftshader'])
  for width,height,reduced in [(390,844,False),(360,780,False),(360,780,True),(390,664,False),(1280,800,False)]:
   context=browser.new_context(viewport={'width':width,'height':height},locale='ko-KR',device_scale_factor=1,reduced_motion='reduce' if reduced else 'no-preference')
   page=context.new_page(); errors=[]
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
   page.goto(f'http://127.0.0.1:{server.server_port}/')
   page.wait_for_function('window.__abyssWorld',timeout=90000)
   town_viewport=page.evaluate('window.__abyssWorld.viewport')
   def click(id,battle=False):
    report=page.evaluate('window.__abyssPreview' if battle else 'window.__abyssWorld')
    q=report['controls'][id]['rect']; canvas=page.locator('canvas').bounding_box()
    page.mouse.click(canvas['x']+(q[0]+q[2]/2)*canvas['width']/report['viewport'][0],canvas['y']+(q[1]+q[3]/2)*canvas['height']/report['viewport'][1])
    page.wait_for_timeout(250)
   for id in ['depart','start_run','travel:patrol']:click(id)
   page.wait_for_function('window.__abyssPreview && !window.__abyssPreview.busy',timeout=30000)
   tag=f'{width}'+('' if (width,height) in [(390,844),(360,780)] else f'x{height}')+('-reduced' if reduced else '')
   def capture(mode):page.screenshot(path=str(O/f'{mode}-{tag}.png'))
   capture('base'); initial=page.evaluate('window.__abyssPreview')
   assert initial['ui_build']=='battle-r20b-20261031'
   # Phone portrait: 1:1 CSS px, never below 360x780. Wider pages keep the town's scaled canvas.
   if width<=480 and height>width:
    k=max(1,780/height,360/width); expected=(width*k,height*k)
   else:
    expected=tuple(town_viewport)
   assert abs(initial['viewport'][0]-expected[0])<=1.5 and abs(initial['viewport'][1]-expected[1])<=1.5,(initial['viewport'],expected)
   assert initial['viewport'][1]>=779,initial['viewport']
   click('action:attack',True); assert page.evaluate('window.__abyssPreview.pending_action')=='attack'; capture('target')
   click('cancel-action',True); assert not page.evaluate('window.__abyssPreview.pending_action')
   click('ally:berenga',True); assert page.evaluate('window.__abyssPreview.ally_open')=='berenga';capture('status');click('close',True)
   click('supplies',True);assert page.evaluate('window.__abyssPreview.items_open');capture('supplies');click('cancel-action',True)
   click('log',True);assert page.evaluate('window.__abyssPreview.log_open');capture('log');click('close',True)
   click('action:personal',True);capture('personal')
   page.wait_for_function('!window.__abyssPreview.busy',timeout=45000)
   final=page.evaluate('window.__abyssPreview')
   assert final['state']['units']['hildegard']['actions']==initial['state']['units']['hildegard']['actions']+1
   assert final['motion_reduced']==reduced
   click('log',True);capture('journal')
   assert any(t['text']=='전방 근무 개시' for t in page.evaluate('window.__abyssPreview.text'))
   click('close',True)
   restored=None
   if (width,height)==(390,844):
    # Complete a real battle to exercise the battle-only viewport's cleanup.
    for turn in range(40):
     report=page.evaluate('window.__abyssPreview')
     if report['result']:break
     enemies=[e for e in report['enemy_hp'] if e['hp']>0]
     target=min(enemies,key=lambda e:e['hp'])['id']
     click('action:attack',True);click('enemy:'+target,True)
     page.wait_for_function('!window.__abyssPreview.busy',timeout=45000)
    assert page.evaluate('window.__abyssPreview.result')=='victory'
    click('retry',True)
    page.wait_for_function('window.__abyssWorld.screen!="battle"',timeout=10000)
    after_viewport=page.evaluate('window.__abyssWorld.viewport')
    restored=all(abs(a-b)<1 for a,b in zip(town_viewport,after_viewport))
    assert restored,(town_viewport,after_viewport)
    capture('return')
   assert not errors,errors
   results.append({'width':width,'height':height,'viewport':initial['viewport'],'reduced':reduced,'ui_build':final['ui_build'],'errors':errors,'viewport_restored_after_victory':restored,'personal_actions_before':initial['state']['units']['hildegard']['actions'],'personal_actions_after':final['state']['units']['hildegard']['actions'],'text_errors':[t for t in final['text'] if t['needed']>t['available']+1 or t['missing_glyphs']]})
   context.close(); print('PASS',tag,flush=True)
  browser.close()
finally:
 server.shutdown();server.server_close()
 (O/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
assert len(results)==5 and all(not r['text_errors'] for r in results)
