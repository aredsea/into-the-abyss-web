import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {runtime,root} from './runtime.mjs';
import {validate} from '../src/validate.js';
const out=path.join(root,'verification/cloud-r22/round12');fs.mkdirSync(out,{recursive:true});
const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
const fx=read('verification/cloud-r22/fixtures.json');
const merged=read('verification/town-r21/round11/save-specimens.json');
const legacy={result:'clear',gold:0,xp:0,wins:0,lost:0,gains:[]};
const blob={zz:{yy:[1,'q',{x:true}]}};
const now=Math.floor(Date.now()/86400000)*86400+3600;
const results=[];let checks=0;
async function group(name,fn,bindings={},extra={}){
 const {mf,db}=await runtime(undefined,bindings,{testNow:now,...extra});
 const call=async(save=fx.town,ip='192.0.2.1',expected=201)=>{
  const r=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json','CF-Connecting-IP':ip},body:JSON.stringify({save,...(bindings.TURNSTILE_ENABLED==='true'?{turnstile:'synthetic'}:{})})});
  const value=await r.json();assert.equal(r.status,expected,JSON.stringify({status:r.status,value}));checks++;return value;
 };
 try{await fn({mf,db,call});results.push({name,passed:true});console.log('PASS',name);}
 catch(e){results.push({name,passed:false,error:String(e.stack)});console.log('FAIL',name,e.message);}
 finally{await mf.dispose();}
}
await group('legacy_00 and legacy dungeon last reject expedition-only fields independently',async({call})=>{
 for(const target of ['summary','dungeon_r21.last'])for(const key of ['steps','first','aff','fell'])for(const value of [blob,key==='aff'?{}:key==='steps'?0:false]){
  const s=structuredClone(merged.legacy_00);
  const parent=target==='summary'?s:s.dungeon_r21;
  parent[target==='summary'?'summary':'last']={...legacy,[key]:structuredClone(value)};
  assert.throws(()=>validate(s),e=>e.path===(target==='summary'?'summary':'dungeon.last')+'.'+key);checks++;
  await call(s,'192.0.2.1',422);
 }
 await call(merged.legacy_00,'192.0.2.2');
 const s=structuredClone(merged.legacy_00);s.dungeon_r21.last=structuredClone(legacy);await call(s,'192.0.2.3');
});
await group('all 154 legitimate samples retain accepted HTTP migration and immutable input',async({call})=>{
 const files=['verification/town-r21/round11/save-specimens.json','verification/expedition-r22/save-specimens.json','verification/facilities-r22/save-specimens.json','verification/cloud-r22/p9b/legitimate-fixtures.json','verification/cloud-r22/fixtures.json'];
 let i=0;
 for(const file of files)for(const save of Object.values(read(file))){
  const before=JSON.stringify(save);const expected=validate(save);assert.equal(JSON.stringify(save),before);checks++;
  const a=await call(save,`198.51.100.${++i}`);assert.equal(a.rev,1);assert.equal(expected.schema,3);checks+=2;
 }
 assert.equal(i,154);checks++;
});
await group('global daily signup cap survives rotating IP and minute buckets, rejection is atomic',async({call,db,mf})=>{
 await call(fx.town,'192.0.2.1');await call(fx.town,'198.51.100.1');
 await db.prepare("DELETE FROM counters WHERE bucket NOT LIKE 'daily:%'").run();
 const before=(await db.prepare('SELECT * FROM counters ORDER BY bucket,minute').all()).results;
 await call(fx.town,'203.0.113.1',429);
 assert.deepEqual((await db.prepare('SELECT * FROM counters ORDER BY bucket,minute').all()).results,before);checks++;
 assert.equal((await db.prepare('SELECT COUNT(*) n FROM accounts').first()).n,2);checks++;
 // Cron preserves today's global counters, removes the previous UTC day's row.
 await db.prepare("INSERT INTO counters(bucket,minute,n) VALUES('daily:global:new',?,2)").bind((Math.floor(now/86400)-1)*1440).run();
 await (await mf.getWorker()).scheduled({cron:'17 * * * *'});
 assert.equal((await db.prepare("SELECT COUNT(*) n FROM counters WHERE bucket='daily:global:new'").first()).n,1);checks++;
 await call(fx.town,'203.0.114.1',429);
 // Move the used rows to yesterday, simulating an unspent next UTC day.
 await db.prepare("UPDATE counters SET minute=minute-1440 WHERE bucket LIKE 'daily:%'").run();
 await call(fx.town,'203.0.115.1');
},{GLOBAL_NEW_PER_DAY:'2'});
const bytes=Buffer.byteLength(JSON.stringify(validate(fx.town)));
await group('global daily new-save byte cap exact boundary and rotating IP',async({call,db})=>{
 await call(fx.town,'192.0.2.1');await call(fx.town,'198.51.100.1');
 await db.prepare("DELETE FROM counters WHERE bucket NOT LIKE 'daily:%'").run();
 await call(fx.town,'203.0.113.1',429);
 assert.equal((await db.prepare("SELECT n FROM counters WHERE bucket='daily:global:newbytes'").first()).n,bytes*2);checks++;
 assert.equal((await db.prepare("SELECT n FROM counters WHERE bucket='daily:global:new'").first()).n,2);checks++;
},{GLOBAL_NEW_BYTES_PER_DAY:String(bytes*2)});
await group('global daily concurrent rotating networks cannot overdraw',async({mf,db})=>{
 const rs=await Promise.all(Array.from({length:8},(_,i)=>mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json','CF-Connecting-IP':`198.51.${i}.1`},body:JSON.stringify({save:fx.town})})));
 assert.deepEqual(rs.map(r=>r.status).sort(),[201,201,201,429,429,429,429,429]);checks++;
 assert.equal((await db.prepare('SELECT COUNT(*) n FROM accounts').first()).n,3);checks++;
 assert.equal((await db.prepare("SELECT n FROM counters WHERE bucket='daily:global:newbytes'").first()).n,bytes*3);checks++;
},{GLOBAL_NEW_PER_DAY:'3',GLOBAL_NEW_BYTES_PER_DAY:String(bytes*3)});
let outgoing=0;
await group('global daily denial precedes one-use Turnstile verification',async({call})=>{
 await call(fx.town,'192.0.2.1');await call(fx.town,'198.51.100.1',429);
 assert.equal(outgoing,1);checks++;
},{GLOBAL_NEW_PER_DAY:'1',TURNSTILE_ENABLED:'true',TURNSTILE_SECRET:'local-test-only'},{outboundService:async()=>{outgoing++;return new Response(JSON.stringify({success:true,action:'account',hostname:'aredsea.github.io'}));}});
const report={checks,failures:results.filter(r=>!r.passed).length,groups:results};
fs.writeFileSync(path.join(out,process.env.R12_RED?'security-red.json':'security-results.json'),JSON.stringify(report,null,2));
console.log('R3 CHECKS',checks,'FAILURES',report.failures);process.exitCode=report.failures?1:0;
