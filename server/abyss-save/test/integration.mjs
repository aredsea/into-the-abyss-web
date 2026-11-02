import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {runtime,root} from './runtime.mjs';
import {validate,percentile,rankReasons} from '../src/validate.js';
const {mf,db}=await runtime();let checks=0;const results=[];
const fixtures=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json'),'utf8'));
const origin='http://localhost:8765';let ip=1;
async function request(method,url,b,expected=200,headers={}){
 const r=await mf.dispatchFetch('http://localhost'+url,{method,headers:{Origin:origin,'content-type':'application/json','CF-Connecting-IP':'192.0.2.'+ip,...headers},...(b===undefined?{}:{body:typeof b==='string'?b:JSON.stringify(b)})});
 const value=r.status===204?{}:await r.json();assert.equal(r.status,expected,JSON.stringify({url,expected,status:r.status,value}));checks++;return {r,value};
}
async function test(name,fn){await fn();results.push({name,passed:true});console.log('PASS',name);}
function nativeEqual(a,b,p='save'){
 if(typeof a==='number'&&typeof b==='number'){assert.ok(Number.isInteger(a)&&Number.isInteger(b)?a===b:Math.abs(a-b)<=1e-12*Math.max(1,Math.abs(a),Math.abs(b)),p);return;}
 if(a&&b&&typeof a==='object'&&typeof b==='object'){
  assert.equal(Array.isArray(a),Array.isArray(b),p);assert.deepEqual(Object.keys(a).sort(),Object.keys(b).sort(),p);
  for(const k of Object.keys(a))nativeEqual(a[k],b[k],p+'.'+k);return;
 }
 assert.equal(a,b,p);
}
try{
 await test('original bot rank oracle: percentiles and eligibility',async()=>{
  const oracle=await import(pathToFileURL(path.join(process.env.ABYSS_BOT_ROOT??'C:/Clauede Code/dungeon-bot','cloud/src/rank.js')).href);
  for(let n=1;n<=100;n++)for(let ahead=0;ahead<n;ahead++){assert.equal(percentile(ahead,n),oracle.percentile(ahead,n));checks++;}
  for(const best of [0,1,3,4,10,27,100,9999])for(const lv of [1,5,10,20,40]){
   const s=structuredClone(fixtures.town);s.persona.lv=lv;s.dungeon_r21.best=best;s.dungeon_r21.runs=best;
   const original={build:'dk-v1.0.1',persona:{lv,exp:0},dungeon:{best,runs:best},gold:s.gold,roster:s.owned};
   assert.deepEqual(rankReasons(s),oracle.rankReasons(original));checks++;
  }
 });
 await test('all 11 actual legacy saves equal native migration',async()=>{
  const expected=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/native-migrations.json'),'utf8'));
  for(const[name,want]of Object.entries(expected)){
   const before=JSON.parse(fs.readFileSync(path.join(root,'verification/persona-r22/legacy',name),'utf8'));
   nativeEqual(validate(before),want,name);checks++;
  }
  for(const name of ['fresh','town','run','gear','meal']){assert.deepEqual(validate(fixtures[name]),fixtures[name],name);checks++;}
 });
 let a;
 await test('create + salted PIN only + read without PIN',async()=>{
  a=(await request('POST','/v1/account',{save:fixtures.town},201)).value;
  assert.match(a.code,/^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/);assert.equal(a.pin.length,10);
  const row=await db.prepare('SELECT * FROM accounts WHERE code=?').bind(a.code).first();assert.notEqual(row.pin_hash,a.pin);assert.equal(row.pin_hash.length,64);
  const read=(await request('GET','/v1/save/'+a.code)).value;assert.deepEqual(read.save,fixtures.town);assert.ok(!JSON.stringify(read).includes(a.pin));checks+=5;
 });
 await test('bad PIN, score injection, unknown fields, malformed JSON',async()=>{
  await request('PUT','/v1/save',{...a,pin:'0000000000',save:fixtures.town},400); // response summary is not request input
  await request('PUT','/v1/save',{code:a.code,pin:'0000000000',rev:1,save:fixtures.town},403);
  await request('POST','/v1/rank',{code:a.code,pin:a.pin,score:999},400);
  await request('POST','/v1/account','{broken',400);
 });
 await test('strict schema mutations rejected',async()=>{
  const mutations=[s=>s.gold=-1,s=>s.gold=Number.MAX_SAFE_INTEGER+1,s=>s.members.marceline.level=41,s=>s.members.marceline.aff=201,s=>s.members.marceline.aff=-101,s=>s.items.fake=1,s=>s.persona.stats.str=999,s=>s.persona.bonus.str=99,s=>s.evil=true,s=>s.members.marceline.extra=1,s=>s.gear.push({id:'fake',uid:1,seed:1,forge:0,tries:0}),s=>s.party=['marceline','marceline'],s=>s.dungeon_r21.best=-1,s=>s.schema=4,s=>s.gold='300',s=>delete s.members.marceline,s=>s.members.marceline.hp=999999,s=>s.persona.exp=999999,s=>s.dungeon_r21.cleared_bosses=['fake'],s=>s.run={loot_gear:['fake.1.1']},s=>s.creation_r22.complete='true',s=>s.dungeon_r21.cleared_bosses=null];
  for(const mutate of mutations){ip++;const s=structuredClone(fixtures.town);mutate(s);await request('POST','/v1/account',{save:s},422);}
 });
 await test('64 KiB streaming limit and UTF-8 size',async()=>{
  ip++;await request('POST','/v1/account',JSON.stringify({padding:'한'.repeat(23000)}),413);
 });
 await test('real concurrent CAS gives one winner, one 409 + summary',async()=>{
  ip++;const b={code:a.code,pin:a.pin,rev:1,save:fixtures.run};
  const rs=await Promise.all([mf.dispatchFetch('http://localhost/v1/save',{method:'PUT',headers:{Origin:origin,'content-type':'application/json'},body:JSON.stringify(b)}),mf.dispatchFetch('http://localhost/v1/save',{method:'PUT',headers:{Origin:origin,'content-type':'application/json'},body:JSON.stringify(b)})]);
  assert.deepEqual(rs.map(r=>r.status).sort(),[200,409],JSON.stringify(await Promise.all(rs.map(r=>r.clone().json()))));const conflict=await rs.find(r=>r.status===409).json();assert.equal(conflict.rev,2);assert.equal(conflict.summary.gold,300);checks+=3;
 });
 await test('history ten, restore creates a new revision',async()=>{
  ip++;for(let rev=2;rev<13;rev++)await request('PUT','/v1/save',{code:a.code,pin:a.pin,rev,save:fixtures.town});
  const history=(await request('GET',`/v1/save/${a.code}/revs`)).value.revs;assert.equal(history.length,10);assert.equal(history[0].rev,13);assert.equal(history[9].rev,4);
  const old=(await request('GET',`/v1/save/${a.code}?rev=4`)).value;
  await request('PUT','/v1/save',{code:a.code,pin:a.pin,rev:13,save:old.save});await request('GET',`/v1/save/${a.code}?rev=1`,undefined,404);checks+=3;
 });
 await test('schema 1/2 migrate to 3, input unchanged',async()=>{
  ip++;const before=JSON.stringify(fixtures.legacy2);const b=(await request('POST','/v1/account',{save:fixtures.legacy2},201)).value;
  const loaded=(await request('GET','/v1/save/'+b.code)).value;assert.equal(loaded.save.schema,3);assert.equal(loaded.save.persona.fight,0);assert.equal(before,JSON.stringify(fixtures.legacy2));checks+=3;
  const legacy=JSON.parse(fs.readFileSync(path.join(root,'verification/persona-r22/legacy/01-world_test_fixture.json'),'utf8'));ip++;
  const c=(await request('POST','/v1/account',{save:legacy},201)).value;assert.equal((await request('GET','/v1/save/'+c.code)).value.save.schema,3);checks++;
 });
 await test('server derived rank + source percentile ties + 300 second cache',async()=>{
  const accounts=[];
  for(const best of [1,1,2]){ip++;const s=structuredClone(fixtures.town);s.dungeon_r21.best=best;s.dungeon_r21.runs=best;s.runs=best;const b=(await request('POST','/v1/account',{save:s},201)).value;accounts.push(b);
   // Production now requires an aged account. Advance only this D1 fixture clock.
   await db.prepare('UPDATE accounts SET created=created-600,rank_at=rank_at-600 WHERE code=?').bind(b.code).run();
   await request('POST','/v1/rank',{code:b.code,pin:b.pin});}
  const r=(await request('GET','/v1/rank?code='+accounts[0].code)).value;assert.equal(r.best,1);assert.equal(r.pct,34);assert.equal(r.n,3);assert.equal(r.expires-r.at,300);assert.ok(!JSON.stringify(r).includes('name'));checks+=5;
  await db.prepare('UPDATE rank_cache SET expires=0').run();
  const top=(await request('GET','/v1/rank?code='+accounts[2].code)).value;assert.equal(top.pct,1);checks++;
  ip++;const invalid=structuredClone(fixtures.town);invalid.dungeon_r21.best=100;invalid.dungeon_r21.runs=100;const b=(await request('POST','/v1/account',{save:invalid},201)).value;await request('POST','/v1/rank',{code:b.code,pin:b.pin},422);
 });
 await test('CORS allowlist and preflight',async()=>{
  const r=await request('OPTIONS','/v1/save',undefined,204);assert.equal(r.r.headers.get('access-control-allow-origin'),origin);checks++;
  await request('GET','/v1/rank',undefined,403,{Origin:'https://evil.example'});
  await request('GET','/v1/rank',undefined,403,{Origin:'https://aredsea.github.io.evil.example'});
  const good=await request('GET','/v1/rank',undefined,200,{Origin:'https://aredsea.github.io'});assert.equal(good.r.headers.get('access-control-allow-origin'),'https://aredsea.github.io');checks++;
 });
 await test('account and IP per-minute limits',async()=>{
  ip++;for(let i=0;i<20;i++)await request('PUT','/v1/save',{code:'0000-0000-0000',pin:'0000000000',rev:1,save:fixtures.town},403);
  await request('PUT','/v1/save',{code:'0000-0000-0000',pin:'0000000000',rev:1,save:fixtures.town},429);
  ip++;for(let i=0;i<60;i++)await request('GET','/v1/rank');await request('GET','/v1/rank',undefined,429);
 });
 await test('authenticated deletion cascades revisions and ranks',async()=>{
  ip++;await db.prepare("DELETE FROM counters WHERE bucket=?").bind('account:'+a.code).run();
  await request('DELETE','/v1/account',{code:a.code,pin:'0000000000'},403);await request('DELETE','/v1/account',{code:a.code,pin:a.pin});await request('GET','/v1/save/'+a.code,undefined,404);
  for(const table of ['accounts','saves','ranks'])assert.equal((await db.prepare(`SELECT COUNT(*) n FROM ${table} WHERE code=?`).bind(a.code).first()).n,0);checks+=3;
 });
 await test('merged P5/P6/P7/P8/P10/D save specimens roundtrip through actual D1 and CAS',async()=>{
  const sets=['verification/expedition-r22/save-specimens.json','verification/facilities-r22/save-specimens.json','verification/town-r21/round11/save-specimens.json'];
  // Begin a fresh fixture quota window after the dedicated rate-limit tests.
  await db.prepare('DELETE FROM counters').run();
  for(const file of sets)for(const[name,save]of Object.entries(JSON.parse(fs.readFileSync(path.join(root,file),'utf8')))){
   ip++;assert.deepEqual(validate(save),save,file+':'+name);checks++;
   const a=(await request('POST','/v1/account',{save},201)).value;
   assert.deepEqual((await request('GET','/v1/save/'+a.code)).value.save,save);checks++;
   await request('PUT','/v1/save',{code:a.code,pin:a.pin,rev:1,save});
   await request('PUT','/v1/save',{code:a.code,pin:a.pin,rev:1,save},409);
   const latest=(await request('GET','/v1/save/'+a.code)).value;assert.equal(latest.rev,2);assert.deepEqual(latest.save,save);checks+=2;
  }
 });
 await test('merged extension mutations rejected without broadening opaque fields',async()=>{
  const merged=JSON.parse(fs.readFileSync(path.join(root,'verification/town-r21/round11/save-specimens.json'),'utf8'));
  const cases=[
   ['entry',s=>s.run.expedition_version=23],['entry',s=>s.run.maxima.persona.hp=1.5],['entry',s=>s.run.maxima.persona.injected={}],
   ['entry',s=>s.run.maxima.constructor={hp:1,mp:0}],['entry',s=>s.run.maxima.persona.hp=1000001],['entry',s=>s.run.fell=1],
   ['entry',s=>s.run.ask={}],['entry',s=>s.run.log=Array(9).fill('x')],['entry',s=>s.run.next_available=true],
   ['entry',s=>s.run.settings_battle_r22={key:'bad',multiplier:1}],['entry',s=>s.run.settings_battle_r22={key:'1:1:false',multiplier:2}],
   ['facilities',s=>s.commerce_r21.forge_codes_r22['constructor.1.1']={forge:0,tries:0}],
   ['facilities',s=>Object.values(s.commerce_r21.forge_codes_r22)[0].forge=11],
   ['facilities',s=>Object.values(s.commerce_r21.forge_codes_r22)[0].tries=-1],
   ['facilities',s=>Object.values(s.commerce_r21.forge_codes_r22)[0].payload={}],
   ['facilities',s=>s.commerce_r21.legacy_persona_progress_r22={level:3,xp:0,evil:{}}],
   ['facilities',s=>s.gold=Number.MAX_SAFE_INTEGER+1],['facilities',s=>s.items.hp_s=1.5],
   ['facilities',s=>s.settings.diff=4],['facilities',s=>s.settings.lang='xx'],['facilities',s=>s.settings.chron={}],
   ['facilities',s=>s.favs=['unknown']],['facilities',s=>s.favs=['teiris','teiris']],
   ['facilities',s=>s.panels_r22.bg.evil={}],['facilities',s=>s.panels_r22.bg.sel='constructor.1.1'],
   ['facilities',s=>s.panels_r22.page=0],['facilities',s=>s.chronicle_r22.queue=[{}]],
   ['facilities',s=>s.chronicle_r22.list=Array(61).fill('x')],['facilities',s=>s.place='unknown'],
   ['clear',s=>s.summary.aff.unknown=3],['clear',s=>s.summary.fell={}],['clear',s=>s.summary.items.fake=1],
   ['clear',s=>s.summary.gear=['constructor.1.1']],['clear',s=>s.dungeon_r21.last.injected={}],
   ['legacy_00',s=>s.persona_migration_r21.persona.evil={}],['legacy_00',s=>s.persona_migration_r21.progress.xp={}],
   ['legacy_00',s=>s.persona_migration_r21.authority='p1-persona']
  ];
  for(const[name,mutate]of cases){ip++;const save=structuredClone(merged[name]);mutate(save);assert.throws(()=>validate(save),/invalid_save/);checks++;await request('POST','/v1/account',{save},422);}
 });
 fs.mkdirSync(path.join(root,'verification/cloud-r22'),{recursive:true});fs.writeFileSync(path.join(root,'verification/cloud-r22/server-results.json'),JSON.stringify({checks,failures:0,groups:results},null,2));console.log(`SERVER CHECKS ${checks} FAILURES 0`);
}finally{await mf.dispose();}
