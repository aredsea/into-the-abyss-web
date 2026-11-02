// Test-only preload for the exact server/abyss-save/test/serve.mjs entry point.
// Provide fresh quotas and an archived fixture on the same real D1 instance.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire,registerHooks} from 'node:module';
// The previous local test server may still own 8787. Select an independent
// loopback port without changing the server source or that existing process.
if(process.env.ABYSS_TEST_PORT){
 const port=Number(process.env.ABYSS_TEST_PORT);
 if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Invalid local test port');
 registerHooks({load(url,context,nextLoad){
  const result=nextLoad(url,context);
  if(url.replaceAll('\\','/').endsWith('/server/abyss-save/test/serve.mjs'))return {...result,source:String(result.source).replace('runtime(8787)',`runtime(${port})`)};
  return result;
 }});
}
const req=createRequire(path.join(process.env.ABYSS_NODE_MODULES,'package.json'));
const {Miniflare}=req('miniflare');
const original=Miniflare.prototype.getD1Database;
const root=process.cwd(),out=path.join(root,'verification/parity-r23');
const control=process.env.R23_CLOUD_CONTROL||'cloud-control';
if(!/^[a-z0-9-]+$/.test(control))throw Error('Invalid local control file');
let db,mf,busy=false,last='';
Miniflare.prototype.getD1Database=async function(...args){
 const value=await original.apply(this,args);db=value;mf=this;return value;
};
setInterval(async()=>{
 if(!db||busy)return;
 const input=path.join(out,control+'.json');if(!fs.existsSync(input))return;
 let c;try{c=JSON.parse(fs.readFileSync(input,'utf8'));}catch{return;}
 if(c.id===last)return;last=c.id;busy=true;
 try{
  if(c.shutdown){await mf.dispose();fs.writeFileSync(path.join(out,control+'-result.json'),JSON.stringify({id:c.id,ok:true,shutdown:true}));process.exit(0);}
  await db.prepare('DELETE FROM counters').run();
  if(c.archive){
   const save=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json'),'utf8')).town;
   const r=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({save})});
   if(r.status!==201)throw Error('archive fixture create '+r.status);
   const a=await r.json();
   await db.prepare('UPDATE accounts SET updated=0 WHERE code=?').bind(a.code).run();
   await (await mf.getWorker()).scheduled({cron:'17 * * * *'});
   fs.writeFileSync(path.join(root,'verification/cloud-r22/p9c/archived-fixture.json'),JSON.stringify({code:a.code,pin:a.pin}));
   await db.prepare('DELETE FROM counters').run();
  }
  fs.writeFileSync(path.join(out,control+'-result.json'),JSON.stringify({id:c.id,ok:true}));
 }catch(e){fs.writeFileSync(path.join(out,control+'-result.json'),JSON.stringify({id:c.id,ok:false,error:String(e)}));}
 finally{busy=false;}
},100).unref();
