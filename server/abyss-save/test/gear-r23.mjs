// Exercise the real validator and Worker/D1 on the two narrowly allowed fields.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {runtime,root} from './runtime.mjs';
import {validate} from '../src/validate.js';
const base=JSON.parse(fs.readFileSync(path.join(root,'verification/parity-r23/shop-save.json'),'utf8'));
const cases=[];
const add=(name,mutate,accepted=false)=>cases.push({name,mutate,accepted});
add('actual_shop_bonus',()=>{},true);
add('legacy_without_both',s=>{delete s.items.charm_potion;delete s.commerce_r21.pietro_buys;},true);
add('bonus_only',s=>{delete s.commerce_r21.pietro_buys;},true);
add('counter_only',s=>{delete s.items.charm_potion;},true);
for(const n of [0,1,98,99])add('bonus_'+n,s=>s.items.charm_potion=n,true);
for(const n of [0,1,1e6,Number.MAX_SAFE_INTEGER])add('counter_'+n,s=>s.commerce_r21.pietro_buys=n,true);
for(const [key,values]of Object.entries({bonus:[-1,.5,100,Number.MAX_SAFE_INTEGER,'1',true,null,[],{count:1}],counter:[-1,.5,Number.MAX_SAFE_INTEGER+1,'1',true,null,[],{count:1}]})){
 for(const [i,n]of values.entries())add(key+'_tamper_'+i,s=>{if(key==='bonus')s.items.charm_potion=n;else s.commerce_r21.pietro_buys=n;});
}
add('unknown_bonus_reference',s=>s.items.charm_potion_fake=1);
add('unknown_commerce_field',s=>s.commerce_r21.pietro_buys_fake=1);
add('bonus_in_battle_inventory',s=>{s.run=structuredClone(JSON.parse(fs.readFileSync(path.join(root,'verification/town-r21/round14/save-specimens.json'),'utf8')).midfight_2.run);s.runs=s.run.id;s.run.battle.inventory.charm_potion=1;});
add('unknown_forge_reference',s=>s.commerce_r21.forge_codes_r22={'fake.1.1':{forge:0,tries:0}});
add('mismatched_forge_reference',s=>s.commerce_r21.forge_codes_r22={'wa01.1.1':{forge:2,tries:1}});
for(const [name,save]of Object.entries(JSON.parse(fs.readFileSync(path.join(root,'verification/parity-r23/bonus-save-specimens.json'),'utf8'))))cases.push({name:'actual_bonus_'+name,save,mutate:()=>{},accepted:true});
const {mf,db}=await runtime();let checks=0;const errors=[],rows=[];
const check=(name,f)=>{checks++;try{f();}catch(e){errors.push({name,error:e.message});}};
async function request(method,url,body){
 const r=await mf.dispatchFetch('http://localhost'+url,{method,headers:{'content-type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});
 return {status:r.status,value:await r.json()};
}
async function quotas(){await db.prepare('DELETE FROM counters').run();}
try{
 const account=await request('POST','/v1/account',{save:base});
 check('control account',()=>assert.equal(account.status,201));
 let rev=1,current=base;
 for(const {name,mutate,accepted,save:template=base}of cases){
  const save=structuredClone(template);mutate(save);const before=JSON.stringify(save);
  check(name+' validator',()=>accepted?assert.deepEqual(validate(save),save):assert.throws(()=>validate(save)));
  check(name+' input unchanged',()=>assert.equal(JSON.stringify(save),before));
  await quotas();const post=await request('POST','/v1/account',{save});
  check(name+' POST',()=>assert.equal(post.status,accepted?201:422));
  await quotas();const put=await request('PUT','/v1/save',{code:account.value.code,pin:account.value.pin,rev,save});
  check(name+' PUT',()=>assert.equal(put.status,accepted?200:422));
  if(put.status===200){rev++;current=save;}
  await quotas();const get=await request('GET','/v1/save/'+account.value.code);
  check(name+' GET',()=>assert.equal(get.status,200));
  check(name+' stored bytes',()=>assert.deepEqual(get.value.save,current));
  check(name+' revision',()=>assert.equal(get.value.rev,rev));
  rows.push({name,accepted,post:post.status,put:put.status});
 }
 for(const [field,values]of Object.entries({bonus:[NaN,Infinity,-Infinity],counter:[NaN,Infinity,-Infinity]}))for(const n of values){
  const save=structuredClone(base);if(field==='bonus')save.items.charm_potion=n;else save.commerce_r21.pietro_buys=n;
  check(field+' nonfinite '+String(n),()=>assert.throws(()=>validate(save)));
 }
 const result={checks,failures:errors.length,cases:cases.length,rows,errors};
 fs.writeFileSync(path.join(root,'verification/parity-r23/server-results.json'),JSON.stringify(result,null,2)+'\n');
 console.log('GEAR R23 SERVER',JSON.stringify({checks,failures:errors.length,cases:cases.length}));
 process.exitCode=errors.length?1:0;
}finally{await mf.dispose();}
