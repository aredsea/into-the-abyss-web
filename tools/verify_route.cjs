const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('fs'),path=require('path'),assert=require('assert');
const out=path.join(__dirname,process.env.QA_OUT||'../verification/route');fs.mkdirSync(out,{recursive:true});
const url=process.argv[2]||'http://127.0.0.1:8000/';
const read=p=>p.evaluate(()=>window.__abyssWorld);
const pause=(p,n=300)=>p.waitForTimeout(n);
async function click(p,id){
 for(let i=0;i<12;i++){
  const r=await read(p),v=r.controls[id];assert(v,'Missing control '+id+' on '+r.screen);assert(!v.disabled,'Disabled '+id);
  const [x,y,w,h]=v.rect,canvas=await p.locator('canvas').boundingBox(),scale=canvas.height/r.viewport[1];
  const bottom=r.viewport[1]-75.5;
  if(id.startsWith('nav:')||(y>=76&&y+h<=bottom)){
   await p.mouse.click(canvas.x+(x+w/2)*canvas.width/r.viewport[0],canvas.y+(y+h/2)*scale);await pause(p);return;
  }
  await p.mouse.move(canvas.x+canvas.width/2,canvas.y+canvas.height/2);
  await p.mouse.wheel(0,y<76?-350:350);await pause(p);
 }
 throw Error('Could not scroll to '+id);
}
async function shot(p,name,w){await pause(p);const r=await read(p);if(r.screen!=='battle')for(const [id,b] of Object.entries(r.controls)){assert(b.rect[0]>=-.5&&b.rect[0]+b.rect[2]<=r.viewport[0]+.5,'Horizontal bounds '+id);assert(b.rect[2]>=44&&b.rect[3]>=44,'Touch size '+id);assert(b.needed<=b.rect[2]+1,'Button text overflow '+id);}await p.screenshot({path:path.join(out,name+'_'+w+'.png')});}
async function battleClick(p,id){
 const r=await p.evaluate(()=>window.__abyssPreview),v=r.controls[id]?.rect;assert(v,'Missing combat '+id);
 const c=await p.locator('canvas').boundingBox();await p.mouse.click(c.x+(v[0]+v[2]/2)*c.width/r.viewport[0],c.y+(v[1]+v[3]/2)*c.height/r.viewport[1]);await pause(p,160);
}
async function combat(p,w,saveCheck=false){
 await p.waitForFunction(()=>window.__abyssPreview&&!window.__abyssPreview.busy,null,{timeout:30000});
 if(saveCheck){
  await battleClick(p,'action:attack');await battleClick(p,'confirm');
  await p.waitForFunction(()=>!window.__abyssPreview.busy,null,{timeout:30000});await pause(p,1600);
  const before=await p.evaluate(()=>window.__abyssPreview.state);
  await p.reload({waitUntil:'networkidle'});await p.waitForFunction(()=>window.__abyssPreview,null,{timeout:45000});
  assert.deepStrictEqual(await p.evaluate(()=>window.__abyssPreview.state),before,'In-combat campaign reload');
 }
 for(let i=0;i<80;i++){
  await p.waitForFunction(()=>!window.__abyssPreview.busy,null,{timeout:30000});
  const r=await p.evaluate(()=>window.__abyssPreview);
  if(r.result){assert.equal(r.result,'victory');await shot(p,'battle_victory',w);await battleClick(p,'retry');await pause(p,400);return;}
  const target=r.enemy_hp.find(e=>e.hp>0);await battleClick(p,'enemy:'+target.id);
  await battleClick(p,'action:attack');await battleClick(p,'confirm');
 }
 throw Error('Combat timed out');
}
(async()=>{
 const browser=await chromium.launch({...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{}),headless:true,args:['--enable-unsafe-swiftshader']});
 const results=[];
 for(const [width,height] of [[390,844],[360,780]]){
  const context=await browser.newContext({viewport:{width,height},locale:'ko-KR',hasTouch:true,reducedMotion:'reduce'});
  const p=await context.newPage(),errors=[];
  p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
  await p.goto(url,{waitUntil:'networkidle'});await p.waitForFunction(()=>window.__abyssWorld,null,{timeout:60000});await pause(p,500);
  assert.equal((await read(p)).build,'world-route-20261027-r2');
  assert.equal(await p.locator('#status').count(),0,'Real loader removed after engine start');
  await click(p,'depart');await shot(p,'departure',width);await click(p,'start_run');await shot(p,'map_entry',width);
  assert.deepStrictEqual(Object.keys((await read(p)).controls).filter(x=>x.startsWith('travel:')),['travel:archive','travel:patrol']);
  await click(p,'travel:archive');assert.deepStrictEqual((await read(p)).state.hand,['key']);await shot(p,'map_archive',width);
  await click(p,'travel:cache');await shot(p,'map_cache',width);
  await pause(p,1600);const saved=(await read(p)).state;
  await p.reload({waitUntil:'networkidle'});await p.waitForFunction(()=>window.__abyssWorld,null,{timeout:60000});
  assert.deepStrictEqual((await read(p)).state,saved,'Route and unresolved cache persist');
  await click(p,'unlock');await click(p,'cancel');assert.deepStrictEqual((await read(p)).state.hand,['key']);
  await click(p,'unlock');await click(p,'accept');assert.equal((await read(p)).state.items.hp_s,3);assert.equal((await read(p)).state.hand.length,0);
  await click(p,'travel:rest');await shot(p,'map_rest',width);await click(p,'rest');assert((await read(p)).controls.rest.disabled);
  await click(p,'travel:gate');await combat(p,width,true);let r=await read(p);
  assert.equal(r.screen,'summary');assert.equal(r.state.summary.gold,40);assert.equal(r.state.summary.wins,1);await shot(p,'map_summary',width);
  await pause(p,1500);const ended=r.state;await p.reload({waitUntil:'networkidle'});await p.waitForFunction(()=>window.__abyssWorld,null,{timeout:60000});assert.deepStrictEqual((await read(p)).state,ended,'Settlement once');
  await click(p,'summary_home');await click(p,'depart');await click(p,'start_run');await click(p,'travel:patrol');await combat(p,width);
  r=await read(p);assert.equal(r.state.hand.length,2,'Cards carried from prior expedition plus battle gain');
  await click(p,'cards');await shot(p,'route_cards',width);await click(p,'card:camp');await click(p,'accept');assert.equal((await read(p)).state.hand.length,1);
  await click(p,'cards_back');await click(p,'travel:supplies');assert.equal((await read(p)).state.hand.length,2);await shot(p,'map_supplies',width);
  await click(p,'travel:rest');await click(p,'skip_rest');assert(!(await read(p)).state.run.rested);
  await click(p,'retreat');await click(p,'cancel');assert.equal((await read(p)).state.run.phase,'explore');await click(p,'retreat');await click(p,'accept');
  r=await read(p);assert.equal(r.state.summary.result,'retreat');assert.equal(r.state.gold,280);assert.equal(r.state.members.hildegard.level,2);
  assert.equal(r.save_error,0);assert(!errors.length,errors.join('\n'));assert(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
  results.push({width,height,errors,build:r.build,checks:['two map branches','large destination controls','card gain/use/cancel','exploration reload','real CTB battles','combat reload','rest and skip','retreat cancel/settle','hand retained','reward once','no horizontal overflow']});
  console.log('PASS '+width+'x'+height);await context.close();
 }
 fs.writeFileSync(path.join(out,'qa.json'),JSON.stringify({url,results,physicalMobileTested:false},null,2),'utf8');await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
