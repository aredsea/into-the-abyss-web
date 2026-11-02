// Test-only preload for the exact server/abyss-save/test/serve.mjs entry point.
// Provide fresh quotas and an archived fixture on the same real D1 instance.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
const req=createRequire(path.join(process.env.ABYSS_NODE_MODULES,'package.json'));
const {Miniflare}=req('miniflare');
const original=Miniflare.prototype.getD1Database;
const root=process.cwd(),out=path.join(root,'verification/parity-r23');
let db,mf,busy=false,last='';
Miniflare.prototype.getD1Database=async function(...args){
 const value=await original.apply(this,args);db=value;mf=this;return value;
};
setInterval(async()=>{
 if(!db||busy)return;
 const input=path.join(out,'cloud-control.json');if(!fs.existsSync(input))return;
 let c;try{c=JSON.parse(fs.readFileSync(input,'utf8'));}catch{return;}
 if(c.id===last)return;last=c.id;busy=true;
 try{
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
  fs.writeFileSync(path.join(out,'cloud-control-result.json'),JSON.stringify({id:c.id,ok:true}));
 }catch(e){fs.writeFileSync(path.join(out,'cloud-control-result.json'),JSON.stringify({id:c.id,ok:false,error:String(e)}));}
 finally{busy=false;}
},100).unref();
