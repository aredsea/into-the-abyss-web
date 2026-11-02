"""Exercise the exported WASM with actual pointer input on a local-only server."""
from pathlib import Path
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
import threading,json,os,tempfile,sys
from playwright.sync_api import sync_playwright
if '--town-r21' in sys.argv:
 from town_r21_round9_web import run
 run()
 raise SystemExit(0)
R=Path(__file__).resolve().parents[1]; O=R/'verification/ui-r20/web'; O.mkdir(parents=True,exist_ok=True)
town_r21='--town-r21' in sys.argv
commerce_only='--commerce-only' in sys.argv
if town_r21:
 O=R/'verification/town-r21/web';O.mkdir(parents=True,exist_ok=True)
if commerce_only:
 O=R/'verification/town-r21/round3/web-commerce';O.mkdir(parents=True,exist_ok=True)
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
  configurations=[(390,844,False),(360,780,False),(360,780,True),(390,664,False),(1280,800,False)]
  if town_r21: configurations.append((430,932,False))
  for width,height,reduced in configurations:
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
   town_screens=[]
   stable_default_checked=False
   if town_r21 and (width,height)==(390,844):
    page.goto(f'http://127.0.0.1:{server.server_port}/')
    page.wait_for_function('window.__abyssWorld && !window.__abyssWorld.town_r21_preview',timeout=90000)
    click('nav:party');page.wait_for_function('window.__abyssWorld.screen==="party"')
    click('nav:town');page.wait_for_function('window.__abyssWorld.screen==="town"')
    page.screenshot(path=str(O/'stable-default-390.png'))
    stable_default_checked=True
   if town_r21:
    # Completed routes must work without the comparison flag. No save reset or
    # JavaScript state writes: every action below is real pointer input.
    assert not page.evaluate('window.__abyssWorld.town_r21_preview')
    for id,expected in [('nav:bag','bag'),('item:hp_s','bag'),('item_cancel','bag'),('nav:depart','depart'),('departure_member:hildegard','formation'),('nav:journal','journal'),('nav:town','town')]:
     click(id);page.wait_for_function('(s)=>window.__abyssWorld.screen===s',arg=expected)
     town_screens.append('default:'+expected)
     if expected=='bag' and id=='item:hp_s': assert page.evaluate('window.__abyssWorld.controls.use_selected.disabled')
   if town_r21:
    assert page.evaluate('window.__abyssWorld.ui_build')=='r21-d-town-20261102e'
    assert not page.evaluate('window.__abyssWorld.town_r21_preview')
    for id,expected in [('nav:party','party'),('member:hildegard','member'),('tab:skills','skills'),('back','party'),('nav:town','town')]:
     click(id)
     page.wait_for_function('(s)=>window.__abyssWorld.screen===s',arg=expected)
     town_screens.append(expected)
     town_text_errors=page.evaluate('window.__abyssWorld.town_text.filter(t=>t.needed>t.available+1)')
     assert not town_text_errors,(expected,town_text_errors)
     page.screenshot(path=str(O/(f'town-{expected}-{width}x{height}'+('-reduced' if reduced else '')+'.png')))
    # Facilities, source shop ledger, equipment, research, and the existing
    # signature playback all work on the default URL, by pointer only.
    for id,expected in [('guild','guild'),('guild:recruit','recruit'),('back','guild'),('guild:research','research'),('nav:town','town'),('shop','shop'),('shop_equipment','shop'),('shop_bag','equipment'),('equipment_smithy','smithy'),('nav:town','town'),('inn','inn'),('nav:town','town')]:
     click(id);page.wait_for_function('(s)=>window.__abyssWorld.screen===s',arg=expected)
     town_screens.append('default:'+expected)
    # Round 7: actual authored dialogue, committed reaction, daily limit and reload.
    click('inn');click('inn:talk')
    dialogue_before=page.evaluate('window.__abyssWorld.state')
    assert dialogue_before['dialogue_r21']['pending']['who']=='hildegard'
    assert all(page.evaluate('(k)=>!!window.__abyssWorld.controls[k]',arg='dialogue_choice:'+c) for c in ['c1','c2','c3'])
    page.screenshot(path=str(O/f'dialogue-choices-{width}x{height}.png'))
    click('dialogue_choice:c1')
    dialogue_after=page.evaluate('window.__abyssWorld.state')
    assert not dialogue_after['dialogue_r21']['pending']
    assert dialogue_after['acts']['hildegard_talk']==dialogue_after['day']
    page.reload();page.wait_for_function('window.__abyssWorld?.controls.dialogue_done',timeout=90000)
    assert page.evaluate('window.__abyssWorld.state.members.hildegard.aff')==dialogue_after['members']['hildegard']['aff']
    page.screenshot(path=str(O/f'dialogue-response-{width}x{height}.png'))
    click('dialogue_done');assert page.evaluate('window.__abyssWorld.controls["inn:talk"].disabled')
    town_screens.append('source:dialogue-choice-reload');click('nav:town')
    click('guild');click('guild:research');click('research_editor')
    assert page.evaluate('window.__abyssWorld.controls.ps_save.disabled')
    for pick,field,value in [('ps_part:prefixes','prefix','strike'),('ps_part:suffixes','suffix','bane')]:
     click(pick);page.screenshot(path=str(O/f'dropdown-{field}-{width}x{height}.png'))
     page.keyboard.press('ArrowDown');page.wait_for_timeout(200);page.keyboard.press('Enter');page.wait_for_timeout(200)
     try:
      page.wait_for_function('(v)=>window.__abyssWorld.state.research_editor_r21.hildegard?.draft[v[0]]===v[1]',arg=[field,value],timeout=5000)
     except Exception:
      page.screenshot(path=str(O/f'dropdown-failure-{field}-{width}x{height}.png'))
      (O/'dropdown-failure.json').write_text(json.dumps(page.evaluate('window.__abyssWorld'),ensure_ascii=False,indent=2),encoding='utf-8')
      raise
    before_research=page.evaluate('window.__abyssWorld.state')
    click('ps_up:prefix');paid_research=page.evaluate('window.__abyssWorld.state')
    assert paid_research['gold']==before_research['gold']-60
    assert not paid_research['research']['hildegard']['prefix']
    click('ps_save');confirmed=page.evaluate('window.__abyssWorld.state')
    assert confirmed['research']['hildegard']['prefix_lv']['strike']==1
    assert confirmed['gold']==paid_research['gold']
    assert page.evaluate('window.__abyssWorld.controls.ps_save.disabled')
    assert not page.evaluate('window.__abyssWorld.town_text.filter(t=>t.needed>t.available+1)')
    page.screenshot(path=str(O/(f'research-confirmed-{width}x{height}'+('-reduced' if reduced else '')+'.png')))
    town_screens.append('source:research-confirmed');click('nav:town')
    click('shop');click('shop_equipment')
    stock=page.evaluate('window.__abyssWorld')
    available=[k for k,v in stock['controls'].items() if k.startswith('buygear:') and not v['disabled']]
    assert available,'source daily stock must offer a common weapon'
    click(available[0]);sold=page.evaluate('window.__abyssWorld')
    assert sold['controls'][available[0]]['disabled'],'purchased daily item becomes sold out'
    click('shop_bag');inventory=page.evaluate('window.__abyssWorld')
    equippable=[k for k,v in inventory['controls'].items() if k.startswith('equip:') and not v['disabled']]
    assert equippable;click(equippable[0]);click('nav:town')
    click('nav:party');click('member:hildegard');click('tab:skills');click('signature_preview')
    page.wait_for_function('window.__abyssWorld.art_preview==="hildegard"')
    click('art_close');click('nav:town')
    if commerce_only:
     final=page.evaluate('window.__abyssWorld')
     text_errors=[t for t in final.get('town_text',[]) if t['needed']>t['available']+1]
     assert not errors and not text_errors,(errors,text_errors)
     results.append({'width':width,'height':height,'reduced':reduced,'ui_build':final['ui_build'],'town_screens':town_screens,'errors':errors,'text_errors':text_errors,'source_purchase':True,'sold_out':True,'source_equipped':True})
     context.close();print('PASS source commerce',width,height,reduced,flush=True);continue
   if town_r21:
    for id in ['depart','start_run']:click(id)
    for step in range(20):
     world=page.evaluate('window.__abyssWorld')
     if world['screen']=='battle':break
     if 'dialogue_continue' in world['controls']:
      click('dialogue_continue');continue
     click('final_battle' if world['state']['run']['phase']=='rest' else 'advance')
    page.wait_for_function('window.__abyssWorld.screen==="battle"',timeout=30000)
   else:
    for id in ['depart','start_run']:click(id)
    for step in range(20):
     world=page.evaluate('window.__abyssWorld')
     if world['screen']=='battle':break
     if 'dialogue_continue' in world['controls']:
      click('dialogue_continue');continue
     click('final_battle' if world['state']['run']['phase']=='rest' else 'advance')
   page.wait_for_function('window.__abyssPreview && !window.__abyssPreview.busy',timeout=30000)
   tag=f'{width}'+('' if (width,height) in [(390,844),(360,780)] else f'x{height}')+('-reduced' if reduced else '')
   def capture(mode):page.screenshot(path=str(O/f'{mode}-{tag}.png'))
   capture('base'); initial=page.evaluate('window.__abyssPreview')
   assert initial['ui_build']=='r21-a-data-20261031'
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
   if town_r21 or (width,height)==(390,844):
    # Complete a real battle to exercise the battle-only viewport's cleanup.
    for turn in range(80):
     report=page.evaluate('window.__abyssPreview')
     if report['result']:break
     enemies=[e for e in report['enemy_hp'] if e['hp']>0]
     target=min(enemies,key=lambda e:e['hp'])['id']
     click('action:attack',True);click('enemy:'+target,True)
     page.wait_for_function('!window.__abyssPreview.busy',timeout=45000)
    assert page.evaluate('window.__abyssPreview.result')=='victory'
    if town_r21:
     page.wait_for_function('window.__abyssWorld.controls.result_continue',timeout=10000)
     capture('victory-shell');click('result_continue')
    else:click('retry',True)
    page.wait_for_function('window.__abyssWorld.screen!="battle"',timeout=10000)
    after_viewport=page.evaluate('window.__abyssWorld.viewport')
    restored=all(abs(a-b)<1 for a,b in zip(town_viewport,after_viewport))
    assert restored,(town_viewport,after_viewport)
    capture('return')
   assert not errors,errors
   results.append({'width':width,'height':height,'viewport':initial['viewport'],'reduced':reduced,'ui_build':final['ui_build'],'town_ui_build':'r21-d-town-20261102e' if town_r21 else None,'town_screens':town_screens,'stable_default_checked':stable_default_checked,'errors':errors,'viewport_restored_after_victory':restored,'personal_actions_before':initial['state']['units']['hildegard']['actions'],'personal_actions_after':final['state']['units']['hildegard']['actions'],'text_errors':[t for t in final['text'] if t['needed']>t['available']+1 or t['missing_glyphs']]})
   context.close(); print('PASS',tag,flush=True)
  browser.close()
finally:
 server.shutdown();server.server_close()
 (O/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
assert len(results)==(6 if town_r21 else 5) and all(not r['text_errors'] for r in results)
