// The only new save fields in r24: bounded depletion count and a known killer ID.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {runtime,root} from './runtime.mjs';
import {validate} from '../src/validate.js';
import K from '../src/known.json' with {type:'json'};
const base=JSON.parse(fs.readFileSync(path.join(root,'verification/town-r21/round14/save-specimens.json'),'utf8')).midfight_2;
const cases=[];
const add=(name,mutate,accepted=false)=>cases.push({name,mutate,accepted});
add('legacy missing both',s=>{delete s.run.battle.depletions;delete s.run.battle.last_kill;},true);
for(const n of [0,1,3,400,400*28])add('depletions '+n,s=>s.run.battle.depletions=n,true);
for(const id of ['',...K.world.companions.map(c=>c.id),'persona'])add('last_kill '+id,s=>s.run.battle.last_kill=id,true);
add('both present',s=>Object.assign(s.run.battle,{depletions:3,last_kill:'teiris'}),true);
for(const [i,n]of [-1,.5,400*28+1,Number.MAX_SAFE_INTEGER,'3',true,null,[],{},NaN,Infinity,-Infinity].entries())add('invalid depletion '+i,s=>s.run.battle.depletions=n);
for(const [i,id]of ['fake','enemy_1','테이리스','teiris'.repeat(8),'teiris\u0000',1,true,null,[],{}].entries())add('invalid killer '+i,s=>s.run.battle.last_kill=id);
for(const key of ['depletions','last_kill'])add('schema2 '+key,s=>{const b=s.run.battle;b.schema_version=2;for(const k of ['extra_state','inventory','selected_ally','ctb','depletions','last_kill'])delete b[k];for(const u of Object.values(b.units)){u.remaining=Math.max(0,u.remaining);u.effects={};}b[key]=key==='depletions'?0:'';});
// Real Godot snapshot from project/tests/battle_slot_snapshot_r24_test.gd: a fight with a fifth enemy slot.
const slotSave=JSON.parse(fs.readFileSync(new URL('./battle-slot-r24.json',import.meta.url),'utf8'));
assert.ok(Object.hasOwn(slotSave.run.battle.units,'r21_slot_5'));
add('real fifth enemy slot',s=>{for(const k of Object.keys(s))delete s[k];Object.assign(s,structuredClone(slotSave));},true);
for(const n of ['5','28'])add('enemy slot '+n,s=>{const u=s.run.battle.units;u['r21_slot_'+n]=structuredClone(u.executor);},true);
for(const id of ['r21_slot_4','r21_slot_29','r21_slot_05','r21_slot_x','r21_slot_','R21_SLOT_5','r21_slot_5 '])add('invalid enemy slot '+id,s=>{const u=s.run.battle.units;u[id]=structuredClone(u.executor);});
add('unknown field still rejected',s=>s.run.battle.depletion_counter=0);
const {mf,db}=await runtime();let checks=0;const rows=[];
const eq=(a,b)=>{assert.deepEqual(a,b);checks++;};
const request=async(method,url,body)=>{const r=await mf.dispatchFetch('http://localhost'+url,{method,headers:{'content-type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});return {status:r.status,body:await r.json()};};
try{
 const account=await request('POST','/v1/account',{save:base});eq(account.status,201);
 let rev=1,stored=base;
 for(const c of cases){
  const save=structuredClone(base);c.mutate(save);const before=JSON.stringify(save);
  if(c.accepted)eq(validate(save),save);else{assert.throws(()=>validate(save));checks++;}
  eq(JSON.stringify(save),before);
  await db.prepare('DELETE FROM counters').run();
  const post=await request('POST','/v1/account',{save});eq(post.status,c.accepted?201:422);
  await db.prepare('DELETE FROM counters').run();
  const put=await request('PUT','/v1/save',{code:account.body.code,pin:account.body.pin,rev,save});eq(put.status,c.accepted?200:422);
  if(c.accepted){rev++;stored=save;}
  await db.prepare('DELETE FROM counters').run();
  const get=await request('GET','/v1/save/'+account.body.code);eq(get.status,200);eq(get.body.save,stored);eq(get.body.rev,rev);
  rows.push({name:c.name,accepted:c.accepted,post:post.status,put:put.status});
 }
 const result={checks,failures:0,cases:cases.length,rows};
 const out=path.join(root,'verification/finish-r24/round3');fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'server-fields.json'),JSON.stringify(result,null,2));
 console.log('FINISH R24 SERVER',JSON.stringify({checks,failures:0,cases:cases.length}));
}finally{await mf.dispose();}
