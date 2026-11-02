"""Real pointer first-run smoke and isolated IDBFS migration. No user profile."""
from pathlib import Path
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
import json,threading,os,tempfile,time,sys
from playwright.sync_api import sync_playwright
R=Path(__file__).resolve().parents[1]
O=R/'verification/town-r21/web'
BUILD='r21-d-town-20261102e'

def idb_files(page):
 return page.evaluate('''async()=>{
  const dbs=await indexedDB.databases();const out=[];
  for(const info of dbs){
   const db=await new Promise((ok,no)=>{const r=indexedDB.open(info.name);r.onsuccess=()=>ok(r.result);r.onerror=()=>no(r.error)});
   if(!db.objectStoreNames.contains('FILE_DATA')){db.close();continue}
   const tx=db.transaction('FILE_DATA','readonly'),st=tx.objectStore('FILE_DATA');
   const [keys,values]=await Promise.all([new Promise(ok=>{st.getAllKeys().onsuccess=e=>ok(e.target.result)}),new Promise(ok=>{st.getAll().onsuccess=e=>ok(e.target.result)})]);
   keys.forEach((path,i)=>{if(path.endsWith('.json')||path.endsWith('.bak'))out.push({db:info.name,path,mode:values[i].mode,text:new TextDecoder().decode(values[i].contents)})});db.close();
  }return out;
 }''')

def wait_idb(page,filename):
 for _ in range(60):
  rows=idb_files(page)
  found=[x for x in rows if x['path'].endswith('/'+filename)]
  if found:return found[0]
  page.wait_for_timeout(100)
 raise AssertionError('IDBFS did not persist '+filename)

def run():
 O.mkdir(parents=True,exist_ok=True)
 artifact=json.loads((R/'docs/version.json').read_text(encoding='utf-8'))
 runtime=R/'verification/town-r21/round9/browser';runtime.mkdir(parents=True,exist_ok=True)
 tempfile.tempdir=str(runtime)
 for key in ['TEMP','TMP','TMPDIR']:os.environ[key]=str(runtime)
 class Handler(SimpleHTTPRequestHandler):
  def log_message(self,*args):pass
  def end_headers(self):
   self.send_header('Cross-Origin-Opener-Policy','same-origin');self.send_header('Cross-Origin-Embedder-Policy','require-corp');super().end_headers()
 server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(R/'docs')))
 threading.Thread(target=server.serve_forever,daemon=True).start()
 url=f'http://127.0.0.1:{server.server_port}/';results=[];migration=[]
 idb_only='--idb-only' in sys.argv
 if idb_only:results=json.loads((O/'results.json').read_text(encoding='utf-8'))
 try:
  with sync_playwright() as p:
   browser=p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True,args=['--enable-unsafe-swiftshader'])
   template=None
   for width,height,reduced in ([] if idb_only else [(390,844,False),(360,780,False),(360,780,True),(390,664,False),(1280,800,False),(430,932,False)]):
    context=browser.new_context(viewport={'width':width,'height':height},locale='ko-KR',device_scale_factor=1,reduced_motion='reduce' if reduced else 'no-preference')
    page=context.new_page();errors=[];tag=f'{width}x{height}'+('-reduced' if reduced else '')
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
    page.goto(url);page.wait_for_function('window.__abyssWorld',timeout=90000)
    def world():return page.evaluate('window.__abyssWorld')
    def capture(name):page.screenshot(path=str(O/f'{name}-{tag}.png'))
    def click(key,battle=False):
     report=page.evaluate('window.__abyssPreview' if battle else 'window.__abyssWorld')
     assert key in report['controls'],(key,report.get('screen'),list(report['controls']))
     for _ in range(24):
      q=report['controls'][key]['rect'];canvas=page.locator('canvas').bounding_box();sx=canvas['width']/report['viewport'][0];sy=canvas['height']/report['viewport'][1]
      x=canvas['x']+(q[0]+q[2]/2)*sx;y=canvas['y']+(q[1]+q[3]/2)*sy
      if not battle and 'clip' in report['controls'][key]:
       clip=report['controls'][key]['clip'];top=canvas['y']+clip[1]*sy;bottom=top+clip[3]*sy
       if y<top or y>bottom:
        distance=abs(y-bottom if y>bottom else y-top)/sy
        page.mouse.move(canvas['x']+(clip[0]+clip[2]/2)*sx,(top+bottom)/2);page.mouse.wheel(0,min(90,max(20,distance))*(1 if y>bottom else -1));page.wait_for_timeout(250);report=world();continue
      page.mouse.click(x,y);page.wait_for_timeout(300);return
     raise AssertionError('cannot scroll to '+key)
    assert world()['state']['scene']=='create' and not world()['restored']
    assert world()['ui_build']==BUILD
    capture('create')
    for key in ['cr_race_human','cr_next','cr_nat_border','cr_next','cr_cls_warrior','cr_next','cr_tot_20','cr_auto','cr_next','cr_done','sc_pick_teiris']:click(key)
    capture('meeting');click('sc_go')
    initial=world();assert initial['state']['owned']==['teiris'] and initial['state']['members']['teiris']['aff']==0 and initial['state']['gold']==300
    assert 'persona_progress_r21' not in initial['state']
    town_viewport=initial['viewport']
    stored=wait_idb(page,'world_v3.json');template=stored
    page.reload();page.wait_for_function('window.__abyssWorld?.restored',timeout=90000)
    assert world()['state']['owned']==['teiris']
    for key in ['nav:party','member:teiris','tab:skills','back','nav:town','inn','inn:talk']:click(key)
    assert world()['state']['dialogue_r21']['pending']['who']=='teiris'
    capture('dialogue-choices');click('dialogue_choice:c1');committed=world()['state']
    assert committed['members']['teiris']['aff']!=0
    page.wait_for_timeout(600);page.reload();page.wait_for_function('window.__abyssWorld?.controls.dialogue_done',timeout=90000)
    assert world()['state']['members']['teiris']['aff']==committed['members']['teiris']['aff']
    capture('dialogue-response');click('dialogue_done');assert world()['controls']['inn:talk']['disabled']
    for key in ['nav:town','guild','guild:recruit','recruit']:click(key)
    recruited=world()['state']['owned'][-1]
    assert len(world()['state']['owned'])==2 and world()['state']['members'][recruited]['level']==world()['state']['persona']['lv']
    capture('recruit')
    for key in ['nav:town','guild','guild:research','research_editor']:click(key)
    for key in ['ps_part:prefixes','ps_part:suffixes']:
     click(key);page.keyboard.press('ArrowDown');page.keyboard.press('Enter');page.wait_for_timeout(200)
    gold=world()['state']['gold'];click('ps_up:prefix');assert world()['state']['gold']==gold-60
    click('ps_save');assert world()['controls']['ps_save']['disabled'];capture('research-confirmed')
    for key in ['nav:town','shop','shop_equipment']:click(key)
    affordable=[k for k,v in world()['controls'].items() if k.startswith('buygear:') and not v['disabled']]
    if affordable:
     click(affordable[0]);assert world()['controls'][affordable[0]]['disabled']
     click('shop_bag');gear=[k for k,v in world()['controls'].items() if k.startswith('equip:') and not v['disabled']]
     assert gear;click(gear[0])
    click('nav:town');click('panels');click('p7_select_teiris');click('p7_fav')
    assert world()['state']['favs']==['teiris']
    click('p7_tab_status');capture('p7-status');click('p7_back');assert world()['screen']=='town'
    click('nav:bag');click('bag_tab:equipment');click('p7_tab_status');click('nav:journal')
    click('p10_back');assert world()['screen']=='status'
    click('p7_back');assert world()['screen']=='bag'
    click('nav:town');click('town_places');click('p10_place_archive');click('p10_resident_isolde');capture('p10-resident')
    click('p10_tab_journal');capture('p10-journal');click('p10_back');assert world()['screen']=='town'
    entries=world()['state']['chronicle_r22']['list']
    assert sum('First met' in x for x in entries)==1 and sum('guild introduction' in x for x in entries)==1
    click('depart');capture('participate')
    click('so_fight_0');assert world()['state']['persona']['fight']==0;capture('command')
    click('so_tg_teiris');assert world()['controls']['start_run']['disabled']
    click('so_fight_1');assert not world()['controls']['start_run']['disabled']
    click('so_tg_teiris');click('so_tg_'+recruited)
    assert len(world()['state']['party'])==2
    click('start_run')
    battles=0;actions=0;restored_viewport=True;battle_text_errors=[]
    # Actual source encounters and unmodified stats: continue until a level-up.
    for step in range(40):
     report=world()
     if report['screen']!='battle' and 'dialogue_continue' in report['controls']:click('dialogue_continue');continue
     if report['screen']=='battle':
      page.wait_for_function('window.__abyssPreview && !window.__abyssPreview.busy',timeout=45000)
      capture('battle')
      for turn in range(120):
       b=page.evaluate('window.__abyssPreview')
       if b['result']:break
       if turn==0:
        assert b['motion_reduced']==reduced
        click('ally:persona',True);capture('persona-status');click('close',True)
        click('action:attack',True);assert page.evaluate('window.__abyssPreview.pending_action')=='attack';click('cancel-action',True)
       enemies=[e for e in b['enemy_hp'] if e['hp']>0];target=min(enemies,key=lambda e:e['hp'])['id']
       click('action:attack',True);click('enemy:'+target,True);actions+=1
       page.wait_for_function('!window.__abyssPreview.busy',timeout=45000)
      b=page.evaluate('window.__abyssPreview');assert b['result']=='victory',b['result']
      battle_text_errors.extend([t for t in b['text'] if t['needed']>t['available']+1 or t['missing_glyphs']])
      page.wait_for_function('window.__abyssWorld.controls.result_continue',timeout=10000)
      capture('victory-shell');click('result_continue');battles+=1
      page.wait_for_function('window.__abyssWorld.screen!=="battle"',timeout=10000)
      restored_viewport &= all(abs(a-b)<1 for a,b in zip(town_viewport,world()['viewport']))
      if world()['state']['persona']['lv']>1:break
      continue
     click('final_battle' if report['state']['run']['phase']=='rest' else 'advance')
    if not battles or world()['state']['persona']['lv']<=1:
     capture('flow-failure');(O/'flow-failure.json').write_text(json.dumps(world(),ensure_ascii=False,indent=2),encoding='utf-8')
    assert battles>0 and world()['state']['persona']['lv']>1
    for _ in range(8):
     if 'dialogue_continue' in world()['controls']:click('dialogue_continue')
     else:break
    paid=world()['state']['persona'].copy()
    if world()['state']['run']['phase']!='done':
     click('retreat');click('accept')
     for _ in range(8):
      if 'dialogue_continue' in world()['controls']:click('dialogue_continue')
      else:break
    final=world();assert (final['state']['persona']['lv'],final['state']['persona']['exp'])==(paid['lv'],paid['exp'])
    assert 'persona_progress_r21' not in final['state'] and restored_viewport
    capture('settled');page.wait_for_timeout(700);page.reload();page.wait_for_function('window.__abyssWorld?.restored',timeout=90000)
    assert world()['state']['persona']['lv']==paid['lv'] and world()['state']['persona']['exp']==paid['exp']
    assert world()['state']['favs']==['teiris'] and world()['state']['panels_r22']==final['state']['panels_r22']
    assert world()['state']['chronicle_r22']==final['state']['chronicle_r22']
    text_errors=[t for t in final.get('town_text',[]) if t['needed']>t['available']+1]+battle_text_errors
    assert not errors and not text_errors,(errors,text_errors)
    results.append({'width':width,'height':height,'reduced':reduced,'ui_build':BUILD,'pck_sha256':artifact['pck_sha256'],'new_start':True,'first_affection':0,'recruited':recruited,'battles':battles,'actions':actions,'persona_level':paid['lv'],'persona_xp':paid['exp'],'indexeddb_reload':True,'viewport_restored_after_victory':restored_viewport,'errors':errors,'text_errors':text_errors})
    context.close();print('PASS first-run',tag,battles,'battles, persona level',paid['lv'],flush=True)
   # A separate temporary browser context imports two legacy files by IDBFS.
   if template is None:
    context=browser.new_context(viewport={'width':390,'height':844});page=context.new_page();page.goto(url);page.wait_for_function('window.__abyssWorld',timeout=90000)
    report=page.evaluate('window.__abyssWorld');q=report['controls']['cr_race_human']['rect'];c=page.locator('canvas').bounding_box();page.mouse.click(c['x']+(q[0]+q[2]/2)*c['width']/report['viewport'][0],c['y']+(q[1]+q[3]/2)*c['height']/report['viewport'][1])
    template=wait_idb(page,'world_v3.json');context.close()
   context=browser.new_context(viewport={'width':390,'height':844});page=context.new_page();page.goto(url);page.wait_for_function('window.__abyssWorld',timeout=90000)
   # A real action persists the IDBFS parent directories in this fixture-only
   # context. Seeding files alone leaves no parent directory records to mount.
   report=page.evaluate('window.__abyssWorld');q=report['controls']['cr_race_human']['rect'];c=page.locator('canvas').bounding_box();page.mouse.click(c['x']+(q[0]+q[2]/2)*c['width']/report['viewport'][0],c['y']+(q[1]+q[3]/2)*c['height']/report['viewport'][1]);wait_idb(page,'world_v3.json')
   page.goto(url+'version.json');page.wait_for_timeout(300)
   raw=json.loads((R/'verification/town-r21/round8/web-legacy-v1.json').read_text(encoding='utf-8'))
   raw['favs']=raw['owned'][:3]
   raw['panels_r22']={'tab':'rec','sel':'','page':2,'msg':'','panel':'status','bg':{'pg':2,'cls':'','slot':'','rar':'','sel':'','cmp':'','conf':''}}
   raw['chronicle_r22']={'list':['Day 1: Historical fixture confirmed.'],'queue':[]}
   source=json.dumps(raw,ensure_ascii=False,separators=(',',':'))
   page.evaluate('''async({entry,source})=>{
    const db=await new Promise((ok,no)=>{let r=indexedDB.open(entry.db);r.onsuccess=()=>ok(r.result);r.onerror=()=>no(r.error)});
    await new Promise((ok,no)=>{const tx=db.transaction('FILE_DATA','readwrite'),st=tx.objectStore('FILE_DATA');
     for(const suffix of ['', '.bak', '.tmp'])st.delete(entry.path+suffix);
     for(const suffix of ['', '.bak'])st.put({timestamp:new Date(),mode:entry.mode,contents:new TextEncoder().encode(source)},entry.path.replace('world_v3.json','world_v1.json')+suffix);
     tx.oncomplete=ok;tx.onerror=()=>no(tx.error)});db.close();
   }''',{'entry':template,'source':source})
   page.goto(url)
   try:page.wait_for_function('window.__abyssWorld?.restored',timeout=15000)
   except Exception:
    (R/'verification/town-r21/round9/indexeddb-failure.json').write_text(json.dumps({'template':template,'files':idb_files(page),'world':page.evaluate('window.__abyssWorld')},ensure_ascii=False,indent=2),encoding='utf-8');page.screenshot(path=str(O/'legacy-idb-failure.png'));raise
   migrated=page.evaluate('window.__abyssWorld');assert migrated['state']['persona']['lv']==17 and migrated['state']['persona']['exp']==2
   assert migrated['state']['persona_migration_r21']['persona']['lv']==25
   assert all(migrated['state'][k]==raw[k] for k in ['favs','panels_r22','chronicle_r22'])
   before=idb_files(page);assert all(x['text']==source for x in before if 'world_v1.json' in x['path'])
   assert not any(x['path'].endswith('/world_v3.json') for x in before)
   # Use the actual inn talk button to save schema3, then reload from v3.
   for key in ['inn','inn:talk']:
    report=page.evaluate('window.__abyssWorld');q=report['controls'][key]['rect'];c=page.locator('canvas').bounding_box();page.mouse.click(c['x']+(q[0]+q[2]/2)*c['width']/report['viewport'][0],c['y']+(q[1]+q[3]/2)*c['height']/report['viewport'][1]);page.wait_for_timeout(250)
   saved=wait_idb(page,'world_v3.json');assert json.loads(saved['text'])['schema']==3
   page.reload();page.wait_for_function('window.__abyssWorld?.restored && window.__abyssWorld.controls["dialogue_choice:c1"]',timeout=90000)
   after=idb_files(page);assert all(x['text']==source for x in after if 'world_v1.json' in x['path'])
   assert all(page.evaluate('window.__abyssWorld.state')[k]==raw[k] for k in ['favs','panels_r22','chronicle_r22'])
   for key in ['dialogue_cancel','nav:depart']:
    report=page.evaluate('window.__abyssWorld');q=report['controls'][key]['rect'];c=page.locator('canvas').bounding_box();page.mouse.click(c['x']+(q[0]+q[2]/2)*c['width']/report['viewport'][0],c['y']+(q[1]+q[3]/2)*c['height']/report['viewport'][1]);page.wait_for_timeout(300)
   legacy_ui=page.evaluate('window.__abyssWorld');assert legacy_ui['controls']['so_fight_1']['disabled'] and not legacy_ui['controls']['start_run']['disabled']
   assert legacy_ui['state']['party']==raw['party']
   migration.append({'legacy_schema':2,'legacy_level':17,'stale_persona_level':25,'loaded_level':17,'v1_and_backup_unchanged':True,'read_did_not_write_v3':True,'action_saved_v3':True,'v3_priority_on_reload':True,'legacy_commander_ui':True,'combined_extensions':True})
   print('PASS IndexedDB legacy + backup unchanged, canonical 17/2, v3 priority',flush=True)
   page.screenshot(path=str(O/'legacy-indexeddb-migration.png'));context.close();browser.close()
 finally:
  server.shutdown();server.server_close()
  (O/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
  (R/'verification/town-r21/round9/indexeddb-results.json').write_text(json.dumps(migration,ensure_ascii=False,indent=2),encoding='utf-8')
 assert len(results)==6 and migration
