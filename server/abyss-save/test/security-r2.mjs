import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {runtime,root} from './runtime.mjs';
const out=path.join(root,'verification/cloud-r22/p9c');fs.mkdirSync(out,{recursive:true});
const fx=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json')));
const legit=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/p9b/legitimate-fixtures.json')));
const results=[];let checks=0;
async function group(name,fn,bindings={},extra={}){
 const {mf,db}=await runtime(undefined,bindings,{...extra,testNow:Math.floor(Date.now()/60000)*60+10});
 const call=async(method,url,body,ip='192.0.2.1',expected)=>{
  const r=await mf.dispatchFetch('http://localhost'+url,{method,headers:{'content-type':'application/json','CF-Connecting-IP':ip},...(body===undefined?{}:{body:JSON.stringify(body)})});
  const value=await r.json();if(expected!==undefined){assert.equal(r.status,expected,JSON.stringify({url,status:r.status,value}));checks++;}return {status:r.status,value};
 };
 const create=async(ip='192.0.2.1',save=fx.town)=>(await call('POST','/v1/account',{save},ip,201)).value;
 try{await fn({mf,db,call,create});results.push({name,passed:true});console.log('PASS',name);}
 catch(e){results.push({name,passed:false,error:String(e.stack)});console.log('FAIL',name,e.message);}
 finally{await mf.dispose();}
}
await group('1 IP/account byte budgets isolate victim and creation',async({create,call,db})=>{
 const a=await create(),v=await create('192.0.2.2');
 for(let i=0;i<2;i++)await call('PUT','/v1/save',{code:a.code,pin:a.pin,rev:i+1,save:fx.town},'192.0.2.1',200);
 await call('PUT','/v1/save',{code:a.code,pin:a.pin,rev:3,save:fx.town},'192.0.2.1',429);
 await call('PUT','/v1/save',{code:a.code,pin:a.pin,rev:3,save:fx.town},'192.0.2.3',429);
 await call('PUT','/v1/save',{code:v.code,pin:v.pin,rev:v.rev,save:fx.town},'192.0.2.2',200);
 await create('192.0.2.4');
 // PUT cannot spend the separate signup emergency budget.
 assert.ok(await db.prepare("SELECT n FROM counters WHERE bucket='global:newbytes'").first());checks++;
},{IP_WRITE_BYTES_PER_MINUTE:String(Buffer.byteLength(JSON.stringify(fx.town))*2),ACCOUNT_WRITE_BYTES_PER_MINUTE:String(Buffer.byteLength(JSON.stringify(fx.town))*2)});
await group('2 no shared request ceiling; IPv6 /48 auxiliary limit',async({call,db})=>{
 for(let i=0;i<5;i++)await call('GET','/v1/rank',undefined,'192.0.2.1',200);
 await call('GET','/v1/rank',undefined,'192.0.2.2',200);
 for(let i=0;i<4;i++)await call('GET','/v1/rank',undefined,`2001:db8:1:${i}::1`,200);
 await call('GET','/v1/rank',undefined,'2001:db8:1:abcd::1',429);
 await call('GET','/v1/rank',undefined,'2001:db8:2::1',200);
 assert.equal(await db.prepare("SELECT * FROM counters WHERE bucket='global:requests'").first(),null);checks++;
},{GLOBAL_REQUESTS_PER_MINUTE:'2',IPV6_48_REQUESTS_PER_MINUTE:'4'});
await group('2 daily signup persists across minute windows',async({create,call,db})=>{
 await create();
 await db.prepare("DELETE FROM counters WHERE bucket NOT LIKE 'daily:%'").run();
 await call('POST','/v1/account',{save:fx.town},'192.0.2.1',429);
 await create('192.0.2.2');
},{NEW_PER_IP_PER_DAY:'1'});
await group('3 atomic pre-PBKDF2 admission rejects concurrent correct PIN last',async({create,call,db})=>{
 const a=await create();
 const rs=await Promise.all(Array.from({length:21},(_,i)=>call('POST','/v1/account/connect',{code:a.code,pin:i===20?a.pin:'0000000000'},'192.0.2.5')));
 assert.equal(rs[20].status,429);assert.equal(rs.filter(r=>r.status===403).length,20);checks+=2;
 const counts=(await db.prepare("SELECT n FROM counters WHERE bucket LIKE 'authfail:%'").all()).results;assert.deepEqual(counts.map(r=>r.n),[20]);checks++;
 await call('POST','/v1/account/connect',{code:a.code,pin:a.pin},'192.0.2.6',200);
},{PIN_PBKDF2_ITERATIONS:'100000'});
await group('4 public read code+IP and authenticated download account isolation',async({create,call,db})=>{
 const a=await create();
 for(let i=0;i<60;i++)await call('GET','/v1/save/'+a.code,undefined,'192.0.2.9',200);
 await call('GET','/v1/save/'+a.code,undefined,'192.0.2.10',200);
 await call('POST','/v1/save/read',{code:a.code,pin:a.pin},'192.0.2.11',200);
 await call('POST','/v1/save/read',{code:a.code,pin:a.pin,history:true},'192.0.2.11',200);
 await call('POST','/v1/save/read',{code:a.code,pin:'0000000000'},'192.0.2.12',403);
 assert.equal((await db.prepare('SELECT n FROM counters WHERE bucket=?').bind('account:'+a.code).first()).n,2);checks++;
});
await group('5 v2 battle rejects v3-only keys independently and effects must be object',async({create,call})=>{
 const base=Object.entries(legit).find(([n])=>n.startsWith('battle_150_0'))[1];
 for(const key of ['extra_state','inventory','selected_ally']){
  const s=structuredClone(base);s.run.battle.schema_version=2;
  for(const k of ['extra_state','inventory','selected_ally'])delete s.run.battle[k];
  s.run.battle[key]={blob:'payload'};await call('POST','/v1/account',{save:s},'192.0.2.1',422);
 }
 const s=structuredClone(base);Object.values(s.run.battle.units)[0].effects=12345;
 await call('POST','/v1/account',{save:s},'192.0.2.1',422);
 const v2=structuredClone(base);v2.run.battle.schema_version=2;for(const k of ['extra_state','inventory','selected_ally'])delete v2.run.battle[k];await create('192.0.2.2',v2);
});
await group('6 rank elapsed capped at 24h for aged and migrated baselines',async({create,call,db})=>{
 const s=structuredClone(fx.town);s.persona.lv=s.members.persona.level=40;s.persona.exp=s.members.persona.xp=0;s.dungeon_r21.best=s.dungeon_r21.runs=s.runs=9999;
 const a=await create('192.0.2.1',s);await db.prepare('UPDATE accounts SET created=created-70*86400,rank_at=rank_at-70*86400 WHERE code=?').bind(a.code).run();
 await call('POST','/v1/rank',{code:a.code,pin:a.pin},'192.0.2.1',422);
 s.dungeon_r21.best=s.dungeon_r21.runs=s.runs=146;await call('PUT','/v1/save',{code:a.code,pin:a.pin,rev:a.rev,save:s},'192.0.2.1',200);
 await call('POST','/v1/rank',{code:a.code,pin:a.pin},'192.0.2.1',200);
});
await group('7 archived PIN verification, 410 response and owner erasure',async({create,call,db,mf})=>{
 const a=await create();await db.prepare('UPDATE accounts SET updated=0 WHERE code=?').bind(a.code).run();await (await mf.getWorker()).scheduled({cron:'17 * * * *'});
 await call('PUT','/v1/save',{code:a.code,pin:a.pin,rev:a.rev,save:fx.town},'192.0.2.1',410);
 await call('DELETE','/v1/account',{code:a.code,pin:'0000000000'},'192.0.2.1',403);
 const r=await call('DELETE','/v1/account',{code:a.code,pin:a.pin},'192.0.2.1',410);assert.equal(r.value.error,'archived');assert.equal(r.value.deleted,true);checks+=2;
 assert.equal(await db.prepare('SELECT * FROM inactive_archives WHERE code=?').bind(a.code).first(),null);checks++;
});
await group('Nit acts keys restrict syntax without changing field allowlists',async({call})=>{
 const s=structuredClone(fx.town);s.day=5;s.acts={[s.owned[0]+'_arbitrary attacker text']:1};await call('POST','/v1/account',{save:s},'192.0.2.1',422);
});
let outgoing=0;
await group('Nit 422/429 do not consume Turnstile and enabled requires challenge',async({call,db})=>{
 await call('POST','/v1/account',{save:{},turnstile:'synthetic'},'192.0.2.1',422);assert.equal(outgoing,0);checks++;
 await call('POST','/v1/account',{save:fx.town},'192.0.2.1',403);
 await call('POST','/v1/account',{save:fx.town,turnstile:'synthetic'},'192.0.2.1',201);
 await call('POST','/v1/account',{save:fx.town,turnstile:'synthetic'},'192.0.2.1',429);assert.equal(outgoing,1);checks++;
},{TURNSTILE_ENABLED:'true',TURNSTILE_SECRET:'local-test-only',NEW_PER_IP_PER_DAY:'1'},{outboundService:async()=>{outgoing++;return new Response(JSON.stringify({success:true,action:'account',hostname:'aredsea.github.io'}));}});
const report={checks,failures:results.filter(r=>!r.passed).length,groups:results};fs.writeFileSync(path.join(out,process.env.P9C_RED?'security-red.json':'security-results.json'),JSON.stringify(report,null,2));console.log('R2 CHECKS',checks,'FAILURES',report.failures);process.exitCode=report.failures?1:0;
