import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHmac,pbkdf2Sync} from 'node:crypto';
import {validate} from '../src/validate.js';
import {runtime,root} from './runtime.mjs';
const fx=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json')));
const results=[];let checks=0,serial=0;
const out=path.join(root,'verification/cloud-r22/p9b');fs.mkdirSync(out,{recursive:true});
async function group(name,fn,bindings={}){
 const {mf,db}=await runtime(undefined,bindings,{testNow:Math.floor(Date.now()/60000)*60+10});let ip='192.0.2.1';
 async function call(method,url,body,expected,extra={}){
  const r=await mf.dispatchFetch('http://localhost'+url,{method,headers:{'content-type':'application/json','CF-Connecting-IP':ip,...extra},...(body===undefined?{}:{body:JSON.stringify(body)})});
  const value=await r.json();if(expected!==undefined){assert.equal(r.status,expected,JSON.stringify({url,status:r.status,value}));checks++;}return {status:r.status,value};
 }
 const create=async(save=fx.town)=>{ip='198.51.'+Math.floor(++serial/250)+'.'+(serial%250+1);return (await call('POST','/v1/account',{save},201)).value;};
 try{await fn({mf,db,call,create,setip:v=>ip=v});results.push({name,passed:true});console.log('PASS',name);}
 catch(e){results.push({name,passed:false,error:String(e.stack)});console.log('FAIL',name,String(e.message));}
 finally{await mf.dispose();}
}
const strong=()=>{const s=structuredClone(fx.town);s.persona.lv=s.members.persona.level=40;s.persona.exp=s.members.persona.xp=0;s.dungeon_r21.best=s.dungeon_r21.runs=s.runs=9999;return s;};
await group('P1 rank: fresh 9999 and repeated identical PUT never establish progress',async({create,call,db})=>{
 const a=await create(strong());await call('POST','/v1/rank',{code:a.code,pin:a.pin},422);
 const b=await create();
 for(let rev=1;rev<=2;rev++){await call('PUT','/v1/save',{code:b.code,pin:b.pin,rev,save:strong()},200);await call('POST','/v1/rank',{code:b.code,pin:b.pin},422);}
 const row=await db.prepare('SELECT rank_best,rank_level FROM accounts WHERE code=?').bind(b.code).first();assert.equal(row.rank_best,0);assert.equal(row.rank_level,1);checks+=2;
 // A legitimate aged account can progress, but repeating submissions cannot bank burst allowance.
 await db.prepare('UPDATE accounts SET created=created-1200,rank_at=rank_at-1200 WHERE code=?').bind(b.code).run();
 const s=structuredClone(fx.town);s.persona.lv=s.members.persona.level=3;s.dungeon_r21.best=s.dungeon_r21.runs=s.runs=1;
 await call('PUT','/v1/save',{code:b.code,pin:b.pin,rev:3,save:s},200);await call('POST','/v1/rank',{code:b.code,pin:b.pin},200);
 await db.prepare('DELETE FROM counters').run();
 for(let best=2;best<=5;best++){s.persona.lv=s.members.persona.level=5;s.dungeon_r21.best=s.dungeon_r21.runs=s.runs=best;await call('PUT','/v1/save',{code:b.code,pin:b.pin,rev:best+2,save:s},200);await call('POST','/v1/rank',{code:b.code,pin:b.pin},best<=4?200:422);}
});
await group('P1 global account cap, denial has no counter writes even with rotating IP',async({call,db,setip})=>{
 for(let i=1;i<=2;i++){setip('203.0.113.'+i);await call('POST','/v1/account',{save:fx.town},201);}
 const before=(await db.prepare('SELECT * FROM counters ORDER BY bucket,minute').all()).results;
 for(let i=3;i<=5;i++){setip('203.0.113.'+i);await call('POST','/v1/account',{save:fx.town},429);}
 assert.deepEqual((await db.prepare('SELECT * FROM counters ORDER BY bucket,minute').all()).results,before);checks++;
},{GLOBAL_NEW_PER_MINUTE:'2'});
await group('P1 concurrent admissions never overdraw global creation cap',async({call,db,setip})=>{
 const rs=await Promise.all(Array.from({length:8},(_,i)=>{setip('203.0.113.'+(i+1));return call('POST','/v1/account',{save:fx.town});}));
 assert.equal(rs.filter(r=>r.status===201).length,2);assert.equal(rs.filter(r=>r.status===429).length,6);
 assert.equal((await db.prepare("SELECT SUM(n) n FROM counters WHERE bucket='global:new'").first()).n,2);checks+=3;
 assert.equal((await db.prepare("SELECT SUM(n) n FROM counters WHERE bucket='global:requests'").first()).n,null);checks++;
},{GLOBAL_NEW_PER_MINUTE:'2'});
await group('P1 global UTF-8 write bytes bounded across IPs',async({call,db,setip})=>{
 setip('203.0.113.1');const a=(await call('POST','/v1/account',{save:fx.town},201)).value;
 const before=(await db.prepare('SELECT * FROM counters ORDER BY bucket,minute').all()).results;
 setip('203.0.113.2');await call('PUT','/v1/save',{code:a.code,pin:a.pin,rev:1,save:fx.town},200);
 await call('PUT','/v1/save',{code:a.code,pin:a.pin,rev:2,save:fx.town},429);
 assert.equal((await db.prepare("SELECT n FROM counters WHERE bucket='global:bytes'").first()).n,Buffer.byteLength(JSON.stringify(fx.town)));checks++;
},{GLOBAL_WRITE_BYTES_PER_MINUTE:String(Buffer.byteLength(JSON.stringify(fx.town))+10)});
await group('P1 IPv6 /64 normalized and saturated IP rejects without updates',async({call,setip,db})=>{
 for(let i=0;i<60;i++){setip(i%2?'2001:db8:0:0::abcd':'2001:0db8::1');await call('GET','/v1/rank',undefined,200);}
 const before=(await db.prepare('SELECT * FROM counters ORDER BY bucket,minute').all()).results;
 setip('2001:db8::ffff');await call('GET','/v1/rank',undefined,429);
 assert.deepEqual((await db.prepare('SELECT * FROM counters ORDER BY bucket,minute').all()).results,before);checks++;
 setip('2001:db8:0:1::1');await call('GET','/v1/rank',undefined,200);
});
await group('P1 inactive cron preserves last save before account cascade; archives expire separately',async({create,db,mf})=>{
 const a=await create(),b=await create();await db.prepare('UPDATE accounts SET updated=updated-181*86400 WHERE code=?').bind(a.code).run();await db.prepare('UPDATE accounts SET updated=updated-179*86400 WHERE code=?').bind(b.code).run();
 const before=await db.prepare('SELECT payload FROM saves WHERE code=?').bind(a.code).first();
 await (await mf.getWorker()).scheduled({cron:'17 * * * *'});
 assert.equal(await db.prepare('SELECT code FROM accounts WHERE code=?').bind(a.code).first(),null);
 assert.ok(await db.prepare('SELECT code FROM accounts WHERE code=?').bind(b.code).first());
 const archived=await db.prepare('SELECT * FROM inactive_archives WHERE code=?').bind(a.code).first();assert.equal(archived.payload,before.payload);assert.equal(archived.expires-archived.archived,30*86400);checks+=4;
 await db.prepare('UPDATE inactive_archives SET expires=0').run();await (await mf.getWorker()).scheduled({cron:'17 * * * *'});assert.equal((await db.prepare('SELECT COUNT(*) n FROM inactive_archives').first()).n,0);checks++;
});
await group('P1 inactive and archive retention settings are applied',async({create,db,mf})=>{
 const a=await create();await db.prepare('UPDATE accounts SET updated=updated-3*86400 WHERE code=?').bind(a.code).run();
 await (await mf.getWorker()).scheduled({cron:'17 * * * *'});
 assert.equal(await db.prepare('SELECT code FROM accounts WHERE code=?').bind(a.code).first(),null);
 const archive=await db.prepare('SELECT * FROM inactive_archives WHERE code=?').bind(a.code).first();assert.equal(archive.expires-archive.archived,7*86400);checks+=2;
},{INACTIVE_DAYS:'2',ARCHIVE_DAYS:'7'});
await group('P2 failed PIN uses code+IP only; owner remains able to save',async({call,create,setip,db})=>{
 const a=await create();setip('203.0.113.99');
 for(let i=0;i<20;i++)await call('POST','/v1/account/connect',{code:a.code,pin:'0000000000'},403);
 await call('POST','/v1/account/connect',{code:a.code,pin:'0000000000'},429);
 assert.equal(await db.prepare('SELECT n FROM counters WHERE bucket=?').bind('account:'+a.code).first(),null);checks++;
 setip('203.0.113.100');await call('PUT','/v1/save',{code:a.code,pin:a.pin,rev:1,save:fx.town},200);
 for(let i=0;i<19;i++)await call('POST','/v1/account/connect',{code:a.code,pin:a.pin},200);
 const before=(await db.prepare('SELECT * FROM counters ORDER BY bucket,minute').all()).results;
 setip('203.0.113.101');await call('POST','/v1/account/connect',{code:a.code,pin:a.pin},429);
 assert.deepEqual((await db.prepare("SELECT * FROM counters WHERE bucket LIKE 'account:%' ORDER BY bucket,minute").all()).results,before.filter(r=>r.bucket.startsWith('account:')));checks++;
});
await group('P2 inherited equipment names and bought codes rejected independently',async({call,setip})=>{
 for(const id of ['constructor','toString','__proto__','hasOwnProperty'])for(const bought of [false,true]){
  const s=structuredClone(fx.town);if(bought)s.commerce_r21.bought={[id+'.1.1']:true};else{s.serial=1;s.gear=[{id,uid:1,seed:1,forge:0,tries:0}];}
  setip('203.0.113.'+(++serial%250+1));await call('POST','/v1/account',{save:s},422);
 }
});
await group('P2 all reported opaque fields reject arbitrary objects',async({call,setip})=>{
 const mutations=[s=>s.lv={blob:1},s=>s.experience_before_r22=[{blob:1}],s=>s.experience_before_r22=[{id:'fake',level:1,xp:0}],s=>s.dialogue_r21.seen={'ARBITRARY-1':1},s=>s.dialogue_r21.bark_counts={'ARBITRARY-1':1},s=>s.summary={...fx.run.summary,title:{blob:1}},s=>s.run={...fx.run.run,battle:{round:{blob:1}}},s=>s.run={...fx.run.run,battle:{round:'nonsense'}},s=>s.dialogue_r21.pending={who:s.owned[0],scene:{blob:1},day:s.day},s=>s.dialogue_r21.response={who:s.owned[0],scene:'fake',text:{blob:1}},s=>s.summary={...fx.run.summary,penalty:{blob:1}}];
 for(const mutate of mutations){setip('203.0.113.'+(++serial%250+1));const s=structuredClone(fx.town);mutate(s);await call('POST','/v1/account',{save:s},422);}
});
try{
 await assert.rejects(runtime(undefined,{IP_HASH_PEPPER:''}),/runtime.*failed|pepper/i);checks++;
 results.push({name:'P2 missing pepper prevents Worker startup',passed:true});
}catch(e){results.push({name:'P2 missing pepper prevents Worker startup',passed:false,error:String(e)});}
await group('P2 PBKDF2 configurable, recorded per account and old hashes remain usable',async({create,call,db})=>{
 const a=await create();const row=await db.prepare('SELECT pin_iterations FROM accounts WHERE code=?').bind(a.code).first();assert.equal(row.pin_iterations,6000);checks++;
 await call('POST','/v1/account/connect',{code:a.code,pin:a.pin},200);
 const salt='legacy-upgrade-test';const digest=pbkdf2Sync(a.pin,salt,100000,32,'sha256').toString('hex');
 await db.prepare('UPDATE accounts SET pin_hash=?,salt=?,pin_iterations=100000 WHERE code=?').bind(digest,salt,a.code).run();
 await call('POST','/v1/account/connect',{code:a.code,pin:a.pin},200);
 assert.equal((await db.prepare('SELECT pin_iterations FROM accounts WHERE code=?').bind(a.code).first()).pin_iterations,100000);checks++;
},{PIN_PBKDF2_ITERATIONS:'6000'});
await group('P2 stored IP key is peppered HMAC; IPv4 mapped variants share one key',async({call,db,setip})=>{
 setip('2001:db8::9');await call('GET','/v1/rank',undefined,200);
 const row=await db.prepare("SELECT * FROM counters WHERE bucket LIKE 'ip:%'").first();
 const expected=createHmac('sha256','local-integration-only-not-a-production-secret').update(row.minute+':2001:0db8:0000:0000::/64').digest('hex');
 assert.equal(row.bucket,'ip:'+expected);checks++;
 for(const ip of ['192.0.2.8','::ffff:192.0.2.8','0:0:0:0:0:ffff:c000:208']){setip(ip);await call('GET','/v1/rank',undefined,200);}
 const v4=createHmac('sha256','local-integration-only-not-a-production-secret').update(row.minute+':192.0.2.8').digest('hex');
 assert.equal((await db.prepare('SELECT n FROM counters WHERE bucket=?').bind('ip:'+v4).first()).n,3);checks++;
});
await group('P2 deletion preserves cache and concurrent expiry has one generation',async({call,create,db,mf})=>{
 const a=await create();await call('GET','/v1/rank',undefined,200);const cache=await db.prepare('SELECT * FROM rank_cache WHERE id=1').first();
 await call('DELETE','/v1/account',{code:a.code,pin:a.pin},200);assert.deepEqual(await db.prepare('SELECT * FROM rank_cache WHERE id=1').first(),cache);checks++;
 await db.prepare('UPDATE rank_cache SET expires=0').run();
 const rs=await Promise.all(Array.from({length:8},(_,i)=>mf.dispatchFetch('http://localhost/v1/rank',{headers:{'CF-Connecting-IP':'192.0.2.'+(i+20)}})));assert.ok(rs.every(r=>r.status===200));
 const updated=await db.prepare('SELECT * FROM rank_cache WHERE id=1').first();assert.equal(updated.generation,cache.generation+1);checks+=2;
});
await group('P2 malformed URL encoding, hex revision, production localhost denied',async({create,call})=>{
 const a=await create();await call('GET','/v1/save/%E0%A4%A',undefined,400);await call('GET','/v1/save/'+a.code+'?rev=0x1',undefined,400);await call('GET','/v1/rank',undefined,403,{Origin:'http://localhost:8765'});
},{ALLOW_LOCALHOST:'false'});
await group('P2 configured HTTPS domain is exact and production localhost cannot be opted in accidentally',async({call})=>{
 await call('GET','/v1/rank',undefined,200,{Origin:'https://game.example'});
 await call('GET','/v1/rank',undefined,403,{Origin:'https://game.example.evil.example'});
 await call('GET','/v1/rank',undefined,403,{Origin:'http://localhost:8765'});
},{ALLOW_LOCALHOST:'false',CORS_ORIGINS:'https://game.example,http://localhost:8765'});
await group('P2 legitimate native dialogues, transitions, battle snapshots and settlements remain valid',async({call,setip})=>{
 const specimens=JSON.parse(fs.readFileSync(path.join(out,'legitimate-fixtures.json')));
 for(const[name,save]of Object.entries(specimens)){
  assert.deepEqual(validate(save),save,name);checks++;
  setip('198.18.'+Math.floor(++serial/250)+'.'+(serial%250+1));await call('POST','/v1/account',{save},201);
 }
},{GLOBAL_NEW_PER_MINUTE:'1000',GLOBAL_WRITE_BYTES_PER_MINUTE:'16777216'});
const report={checks,failures:results.filter(x=>!x.passed).length,groups:results};
fs.writeFileSync(path.join(out,process.env.P9B_RED?'security-red.json':'security-results.json'),JSON.stringify(report,null,2));console.log('SECURITY CHECKS',checks,'FAILED GROUPS',report.failures);process.exitCode=report.failures?1:0;
