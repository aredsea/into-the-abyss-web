const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('fs'),path=require('path'),assert=require('assert');
const out=path.join(__dirname,process.env.QA_OUT||'../verification/route');
const url=process.argv[2]||'http://127.0.0.1:8000/';
const read=p=>p.evaluate(()=>window.__abyssWorld);
async function click(p,id){
 for(let n=0;n<15;n++){
  const r=await read(p),b=r.controls[id];assert(b&&!b.disabled,id);const c=await p.locator('canvas').boundingBox();
  if(id.startsWith('nav:')||(b.rect[1]>=76&&b.rect[1]+b.rect[3]<=r.viewport[1]-75.5)){
   await p.touchscreen.tap(c.x+(b.rect[0]+b.rect[2]/2)*c.width/r.viewport[0],c.y+(b.rect[1]+b.rect[3]/2)*c.height/r.viewport[1]);await p.waitForTimeout(350);return;
  }
  await p.mouse.move(180,370);await p.mouse.wheel(0,b.rect[1]<76?-330:330);await p.waitForTimeout(300);
 }
 throw Error('Scroll failed '+id);
}
(async()=>{
 const browser=await chromium.launch({...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{}),headless:true,args:['--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:{width:360,height:780},hasTouch:true,locale:'ko-KR'}),p=await context.newPage(),errors=[];
 p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 const version=await(await p.request.get(new URL('version.json',url).href)).json().catch(()=>null);
 await p.goto(url,{waitUntil:'networkidle'});await p.waitForFunction(()=>window.__abyssWorld,null,{timeout:45000});
 const local=new URL(url).hostname==='127.0.0.1';
 if(!local)assert.equal((await read(p)).build,version.build);
 await click(p,'nav:party');const initial=(await read(p)).state.party;
 await click(p,'swap:0');assert.deepStrictEqual((await read(p)).state.party,[initial[1],initial[0],initial[2],initial[3]]);
 // Actual synthetic touch gesture, no DOM/state mutation.
 const beforeScroll=(await read(p)).controls['member:hildegard'].rect[1];
 const cdp=await context.newCDPSession(p);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:170,y:630}]});
 for(let y=600;y>=180;y-=35){await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:170,y}]});await p.waitForTimeout(25);}
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await p.waitForTimeout(600);
 const afterScroll=(await read(p)).controls['member:hildegard'].rect[1];
 assert(afterScroll<beforeScroll-100,'Touch scroll moved list '+beforeScroll+' -> '+afterScroll);
 await p.screenshot({path:path.join(out,'touch_party_360.png')});
 await click(p,'nav:town');await click(p,'inn');await click(p,'inn:rest');await click(p,'accept');assert.equal((await read(p)).state.day,2);assert.equal((await read(p)).state.gold,180);
 await click(p,'nav:bag');await click(p,'item:hp_s');await click(p,'use:hildegard');assert.equal((await read(p)).state.items.hp_s,2,'Full HP does not consume from UI');
 await click(p,'nav:town');await click(p,'depart');await click(p,'start_run');await click(p,'travel:archive');await click(p,'retreat');await click(p,'cancel');assert((await read(p)).state.run.phase==='explore');
 await click(p,'retreat');await click(p,'accept');let r=await read(p);assert.equal(r.screen,'summary');assert.equal(r.state.summary.result,'retreat');assert.equal(r.state.gold,180);assert.deepStrictEqual(r.state.hand,['key']);
 await p.waitForTimeout(1800);const saved=r.state;await p.reload({waitUntil:'networkidle'});await p.waitForFunction(()=>window.__abyssWorld,null,{timeout:45000});assert.deepStrictEqual((await read(p)).state,saved);
 await p.screenshot({path:path.join(out,local?'retreat_360.png':'public_touch_360.png')});
 assert(!errors.length,errors.join('\n'));
 fs.writeFileSync(path.join(out,local?'edges-qa.json':'public-touch-qa.json'),JSON.stringify({url,version,errors,physicalRemoteDeviceTested:false,checks:['HTTPS build identity','formation saved','synthetic touch scrolling','inn overnight cost and day','invalid item use has no cost','retreat cancel','retreat settles once','retreat IndexedDB reload']},null,2),'utf8');
 await browser.close();console.log('PASS edge UI checks '+url);
})().catch(e=>{console.error(e);process.exit(1)});

