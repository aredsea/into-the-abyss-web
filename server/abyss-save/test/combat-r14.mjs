import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {runtime,root} from './runtime.mjs';
import {validate} from '../src/validate.js';
const out=path.join(root,'verification/town-r21/round14');
const samples=JSON.parse(fs.readFileSync(path.join(out,'save-specimens.json'),'utf8'));
const {mf,db}=await runtime();let checks=0;let mutated=0;
const eq=(a,b)=>{assert.deepEqual(a,b);checks++;};
const bad=s=>{assert.throws(()=>validate(s));checks++;mutated++;};
const fields={effects:new Set(),extra:new Set()};
try{
 for(const[name,save]of Object.entries(samples)){
  const before=JSON.stringify(save);eq(validate(save),save);eq(JSON.stringify(save),before);
  for(const u of Object.values(save.run.battle?.units??{}))for(const [k,e]of Object.entries(u.effects)){fields.effects.add(k);for(const f of Object.keys(e))fields.effects.add(k+'.'+f);}
  for(const x of Object.values(save.run.battle?.extra_state??{}))for(const k of Object.keys(x))fields.extra.add(k);
  await db.prepare('DELETE FROM counters').run();
  const request=async(method,url,body,status)=>{const r=await mf.dispatchFetch('http://localhost'+url,{method,headers:{'content-type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});eq(r.status,status);return r.json();};
  const a=await request('POST','/v1/account',{save},201);
  eq((await request('GET','/v1/save/'+a.code,null,200)).save,save);
  await request('PUT','/v1/save',{code:a.code,pin:a.pin,rev:1,save},200);
  await request('PUT','/v1/save',{code:a.code,pin:a.pin,rev:1,save},409);
  eq((await request('GET','/v1/save/'+a.code,null,200)).save,save);
 }
 const base=structuredClone(samples.midfight_2),first=base.run.persona_party[0];
 const mutations=[s=>s.persona_research_r22={draft:s.persona.skill,spent:-1},s=>s.persona_research_r22={draft:{},spent:0},s=>s.persona_research_r22={opaque:1},s=>s.gear[0].code='fake.1.1',s=>s.gear[0].seed++,s=>s.run.battle.ctb.tick=-1,s=>s.run.battle.ctb.tick=.5,s=>s.run.battle.ctb.round++,s=>s.run.battle.ctb.opaque={},s=>s.run.battle.extra_state[first].opaque={},s=>s.run.battle.extra_state[first].source_rng=0,s=>s.run.battle.extra_state[first].dot_order='1',s=>s.run.battle.extra_state[first].gear_gw={n:1,p:30,who:999},s=>s.run.battle.extra_state[first].gear_gk={opaque:true},s=>s.run.battle.extra_state[first].gear_gt={t:1,e:5,d:1,x:20,n:1,opaque:1}];
 for(const mutate of mutations){const s=structuredClone(base);mutate(s);bad(s);await db.prepare('DELETE FROM counters').run();const r=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({save:s})});eq(r.status,422);}
 for(const archive of [{opaque:{}},{hp:-1},{hp:1.5},{hp:{}},{}]){const s=structuredClone(base);s.equipment_vitals_before_r14=archive;bad(s);await db.prepare('DELETE FROM counters').run();const r=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({save:s})});eq(r.status,422);}
 for(const e of [
  {turns:3,amount:20,stacks:[10]},
  {turns:3,amount:20,stacks:[10,10],owners:[first]},
  {turns:3,amount:20,stacks:[10,10],owners:[first,'fake']},
  {turns:3,amount:20,stacks:[10,10],orders:[1,.5]},
  {turns:3,amount:20,stacks:[10,10],lifetimes:[0,3]},
  {turns:3,amount:20,stacks:[10,10],bursts:[{},1]},
  {turns:3,amount:20,orders:[1,2]},
  {turns:3,amount:20,heals:[{amount:10,turns:2,action:1}]},
  {turns:3,amount:20,fresh:1},
  {turns:3,amount:20,by:'fake'}
 ]){const s=structuredClone(base);s.run.battle.units[s.run.battle.selected_enemy].effects.dot=e;bad(s);await db.prepare('DELETE FROM counters').run();const r=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({save:s})});eq(r.status,422);}
 // Every newly admitted object is shape checked, including arbitrary nested data.
 const probes=[
  s=>s.run.battle.extra_state[first].gear_gw={n:1,p:30,who:1},
  s=>s.run.battle.extra_state[first].gear_gk={pa_echo:true,gl_king:false},
  s=>s.run.battle.extra_state[first].gear_gb={t:1,d:10},
  s=>s.run.battle.extra_state[first].gear_gt={t:1,e:5,d:10,x:20,n:1},
  s=>s.persona_research_r22={draft:s.persona.skill,spent:60},
  s=>s.run.battle.units[first].effects.persona_regen={turns:2,amount:10},
  s=>s.run.battle.units[first].effects.psguard={turns:2,amount:.2},
  s=>s.run.battle.units[first].effects.pscrit={turns:2,amount:.2},
  s=>s.run.battle.units[first].effects.regen={turns:2,amount:10,source:first,heals:[{amount:10,turns:2,action:1}]},
  s=>s.run.battle.units[s.run.battle.selected_enemy].effects.dot={turns:3,amount:20,stacks:[10,10],lifetimes:[2,3],owners:[first,first],bursts:[0,10],initial_turns:[2,3],orders:[1,2],fresh:true,doubled:false,order:2}
 ];
 for(const set of probes){const s=structuredClone(base);set(s);eq(validate(s),s);const visit=(value,trail=[])=>{if(!value||typeof value!=='object')return;const changed=structuredClone(s);let p=changed;for(const k of trail.slice(0,-1))p=p[k];if(trail.length){p[trail.at(-1)]={opaque:{anything:[1,'x',true]}};bad(changed);}for(const k of Object.keys(value))if(value[k]&&typeof value[k]==='object')visit(value[k],[...trail,k]);};visit(s);}
 // Network listener (used by Godot) must also accept the same active battle.
 await db.prepare('DELETE FROM counters').run();
 const r=await fetch(String(await mf.ready).replace(/\/$/,'')+'/v1/account',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({save:base})});eq(r.status,201);
 const result={checks,failures:0,samples:Object.keys(samples).length,mutations:mutated,fields:Object.fromEntries(Object.entries(fields).map(([k,v])=>[k,[...v].sort()]))};
 fs.writeFileSync(path.join(out,'server-combat-results.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));
}finally{await mf.dispose();}
