const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('fs'),path=require('path'),assert=require('assert');
const url=process.argv[2]||'http://127.0.0.1:8000/';
const out=path.join(__dirname,process.env.QA_OUT||'../verification/route');fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=await chromium.launch({...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{}),headless:true,args:['--enable-unsafe-swiftshader']});
 const results=[];
 for(const [width,height] of [[390,844],[360,780]]){
  const c=await browser.newContext({viewport:{width,height},locale:'ko-KR'}),p=await c.newPage();
  let release;const gate=new Promise(r=>release=r);
  await p.route('**/*.wasm',async r=>{await gate;await r.continue()});
  await p.goto(url,{waitUntil:'domcontentloaded'});
  await p.locator('.art').evaluate(img=>img.decode());await p.waitForTimeout(700);
  assert(await p.locator('#status').isVisible());
  assert(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
  const bounds=await p.locator('.status-box').boundingBox();assert(bounds.y+bounds.height<=height+1);
  await p.screenshot({path:path.join(out,'loading_'+width+'.png')});
  release();await p.waitForFunction(()=>window.__abyssWorld,null,{timeout:60000});assert.equal(await p.locator('#status').count(),0);
  results.push({width,height,downloadScreenshot:true,actualEngineStarted:true});await c.close();
 }
 const c=await browser.newContext({viewport:{width:360,height:780},locale:'ko-KR'}),p=await c.newPage();
 await p.route('**/index.js',r=>r.abort('failed'));
 await p.goto(url,{waitUntil:'networkidle'});assert(await p.locator('#retry').isVisible());
 assert.equal(await p.locator('#percent').textContent(),'');assert(await p.locator('#progress').isHidden());
 await p.screenshot({path:path.join(out,'loading_error_360.png')});
 await p.unroute('**/index.js');await p.locator('#retry').click();await p.waitForFunction(()=>window.__abyssWorld,null,{timeout:60000});
 await p.route('**/academy-loading-v1.png',r=>r.abort('failed'));await p.reload({waitUntil:'networkidle'});await p.waitForFunction(()=>window.__abyssWorld,null,{timeout:60000});
 assert.equal(await p.locator('#status').count(),0);await c.close();
 fs.writeFileSync(path.join(out,'loader.json'),JSON.stringify({url,results,engineScriptFailure:true,retryStartedActualGame:true,artFailureDoesNotBlock:true,physicalMobileTested:false},null,2),'utf8');
 await browser.close();console.log('PASS loader screenshots, missing engine retry, missing artwork fallback');
})().catch(e=>{console.error(e);process.exit(1)});
