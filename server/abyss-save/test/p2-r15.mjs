import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {runtime,root} from './runtime.mjs';
import {validate} from '../src/validate.js';

const out=path.join(root,'verification/town-r21/round15');
fs.mkdirSync(out,{recursive:true});
const files=['town-r21/round14/save-specimens.json','town-r21/round13/save-specimens.json','town-r21/round11/save-specimens.json','expedition-r22/save-specimens.json','facilities-r22/save-specimens.json','cloud-r22/p9b/legitimate-fixtures.json','cloud-r22/fixtures.json'];
const samples=files.flatMap(file=>Object.entries(JSON.parse(fs.readFileSync(path.join(root,'verification',file),'utf8'))).map(([name,save])=>({name:file+':'+name,save})));
const base=samples.find(s=>s.name.endsWith(':midfight_2')).save;
const first=base.run.persona_party[0],foe=base.run.battle.selected_enemy;
const B=s=>s.run.battle;
const dot={turns:3,amount:20,stacks:[10,10],lifetimes:[2,3],owners:[first,first],bursts:[0,10],initial_turns:[2,3],orders:[1,2],fresh:true,order:2};
const regen={turns:2,amount:1,heals:Array.from({length:400},()=>({amount:1,turns:1,action:1}))};
function v2(s){
 const b=B(s);b.schema_version=2;
 for(const k of ['extra_state','inventory','selected_ally','ctb'])delete b[k];
 for(const u of Object.values(b.units)){u.remaining=Math.max(0,u.remaining);u.effects={};}
}
const cases=[];
const add=(name,mutate,accepted=false)=>cases.push({name,mutate,accepted});
for(const id of ['attack','guard','personal','pshield','hshield','acid','chaoswave'])add('silenced_known_'+id,s=>B(s).extra_state[first].silenced_id=id,true);
for(const [name,id] of Object.entries({free80:'https://evil.example/'+'Q'.repeat(59),unknown:'unknown_skill',unit:foe,empty:'',long:'a'.repeat(41),digit:'skill_1',uppercase:'Attack',object:{id:'attack'}}))add('silenced_'+name,s=>B(s).extra_state[first].silenced_id=id);
add('v2_plain',v2,true);
add('v3_dot_meta',s=>B(s).units[foe].effects.dot=structuredClone(dot),true);
add('v3_regen_heals400',s=>B(s).units[first].effects.regen=structuredClone(regen),true);
add('v2_dot_meta',s=>{v2(s);B(s).units[foe].effects.dot=structuredClone(dot);});
add('v2_regen_heals400',s=>{v2(s);B(s).units[first].effects.regen=structuredClone(regen);});
for(const [key,value] of Object.entries(dot).filter(([k])=>!['turns','amount'].includes(k)))add('v2_dot_'+key,s=>{v2(s);B(s).units[foe].effects.dot={turns:3,amount:20,...(!['stacks','fresh','order'].includes(key)?{stacks:[10,10]}:{}),[key]:value};});
// Exercise the shared code parser at every storage location: gear, loot, receipts, commerce and UI.
const code=base.gear[0].code;
const setters={
 gear:(s,c)=>s.gear[0].code=c,
 loot:(s,c)=>s.run.loot_gear=[c],
 settlement:(s,c)=>s.summary={result:'retreat',gold:0,xp:0,wins:0,lost:0,gains:[],gear:[c]},
 bought:(s,c)=>s.commerce_r21.bought={[c]:true},
 forge:(s,c)=>s.commerce_r21.forge_codes_r22={[c]:{forge:0,tries:0}},
 selection:(s,c)=>s.panels_r22={bg:{sel:c}},
 confirmation:(s,c)=>s.panels_r22={bg:{conf:c}}
};
const [id,seed,version]=code.split('.');
for(const [location,set]of Object.entries(setters)){
 add('code_canonical_'+location,s=>set(s,code),true);
 add('code_leading_zero_'+location,s=>set(s,id+'.000000'+seed+'.'+version));
 add('code_version_zero_pad_'+location,s=>set(s,id+'.'+seed+'.000'+version));
}

const {mf,db}=await runtime();let checks=0;const failures=[],rows=[];
const check=(name,fn)=>{checks++;try{fn();}catch(e){failures.push({name,error:e.message});}};
async function request(method,url,body){
 const r=await mf.dispatchFetch('http://localhost'+url,{method,headers:{'content-type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});
 return {status:r.status,value:await r.json()};
}
async function quotas(){await db.prepare('DELETE FROM counters').run();}
try{
 check('393 normal specimens',()=>assert.equal(samples.length,393));
 for(const {name,save}of samples){
  const before=JSON.stringify(save);
  check(name,()=>assert.ok(validate(save).schema===3));
  check(name+' input unchanged',()=>assert.equal(JSON.stringify(save),before));
 }
 await quotas();const account=await request('POST','/v1/account',{save:base});
 check('control create',()=>assert.equal(account.status,201));
 let rev=1,current=base;
 for(const {name,mutate,accepted}of cases){
  const save=structuredClone(base);mutate(save);const before=JSON.stringify(save);
  check(name+' validator',()=>accepted?assert.deepEqual(validate(save),save):assert.throws(()=>validate(save)));
  check(name+' input unchanged',()=>assert.equal(JSON.stringify(save),before));
  await quotas();const create=await request('POST','/v1/account',{save});
  check(name+' POST',()=>assert.equal(create.status,accepted?201:422));
  await quotas();const put=await request('PUT','/v1/save',{code:account.value.code,pin:account.value.pin,rev,save});
  check(name+' PUT',()=>assert.equal(put.status,accepted?200:422));
  // Track actual revisions too, so a vulnerable pre-fix server can finish all probes.
  if(put.status===200){rev++;current=save;}
  await quotas();const read=await request('GET','/v1/save/'+account.value.code);
  check(name+' GET status',()=>assert.equal(read.status,200));
  check(name+' persisted state',()=>assert.deepEqual(read.value.save,current));
  check(name+' revision',()=>assert.equal(read.value.rev,rev));
  rows.push({name,accepted,post:create.status,put:put.status});
 }
 const result={checks,failures:failures.length,normal_samples:samples.length,cases:cases.length,rows,errors:failures};
 const filename=process.argv.includes('--before')?'p2-before.json':'p2-results.json';
 fs.writeFileSync(path.join(out,filename),JSON.stringify(result,null,2)+'\n');
 console.log(JSON.stringify({checks,failures:failures.length,normal_samples:samples.length,cases:cases.length,failed_cases:[...new Set(failures.map(f=>f.name.replace(/ (validator|POST|PUT)$/,'')))]}));
 process.exitCode=failures.length?1:0;
}finally{await mf.dispose();}
