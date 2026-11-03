import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL}from'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim:mkSimBase}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const mkSim=async(o)=>{const sim=await mkSimBase({...o,extra:'B.__r23_cov={calls={},branches={}}\n'+o.extra});const original=sim.L;return {...sim,L:async(code)=>{const pack=await original('B.__r23_cov={calls={},branches={}};local __result=(function()\n'+code+'\nend)();return {result=__result,coverage=B.__r23_cov}');fs.writeFileSync('verification/parity-r23/coverage/battle-round8-persona.json',JSON.stringify(pack.coverage));return pack.result;}};};
import {isDeepStrictEqual as __r23_equal} from 'node:util';
const __r23_write=fs.writeFileSync.bind(fs);
fs.writeFileSync=(file,data,...args)=>{const name=String(file).replaceAll('\\','/');
 if((name.startsWith('verification/parity-r23/')||name.startsWith('verification/data-r21/'))&&!name.includes('/coverage/')&&name.endsWith('.json')){
  const expected=JSON.parse(fs.readFileSync(file,'utf8')),got=JSON.parse(String(data));
  if(expected&&typeof expected==='object')delete expected.provenance;
  if(got&&typeof got==='object')delete got.provenance;
  for(const value of [expected,got])if(value?.parts)for(const part of value.parts){delete part.bytes;delete part.sha256;}
  if(!__r23_equal(expected,got))throw Error('Instrumentation changed oracle: '+name);
  return;
 }return __r23_write(file,data,...args);
};
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua','40-fx.lua','50-render.lua','80-press.lua'];
const raw=files.map(f=>fs.readFileSync(path.join('C:/Users/asone/Documents/Codex/2026-10-30/into-the-abyss-handoff/work/r21-a-data/verification/parity-r23/coverage/instrumented',f),'utf8'));
const extra=raw.map((s,i)=>(files[i]==='34-traits.lua'?'B.GH={}':'')+'\ndo\n'+s+'\nend').join('\n');
const {L,sim}=await mkSim({policy:false,extra});const fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
const pack=process.env.R23_ROUND8_PACK||'';if(!['','outcome','persona'].includes(pack))throw Error('invalid pack');const stem='battle-round8'+(pack?'-'+pack:'');
let result;try{result=await L(fresh+'\n'+fs.readFileSync('tools/oracle_battle_r23_round8'+(pack?'_'+pack:'')+'.lua','utf8'));}catch(e){console.log(sim.errors,sim.logs);throw e;}
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
for(const row of result.rows)for(const state of [row.input.state,row.expected.state||row.expected])for(const u of state?.u||state?.units||[])for(const k of ['bf','x'])if(Array.isArray(u[k])&&!u[k].length)u[k]={};
for(const row of result.rows)for(const holder of [row.input,row.expected])for(const key of ['saved','draft']){if(Array.isArray(holder[key])&&!holder[key].length)holder[key]={};const state=holder[key];if(state&&typeof state==='object')for(const k of ['prefix_lv','suffix_lv'])if(Array.isArray(state[k])&&!state[k].length)state[k]={};}
const parts=[];let rows=[],size=0;
function flush(){if(!rows.length)return;const file=`${stem}-oracle-${parts.length+1}.json`,data=JSON.stringify({rows,provenance});if(Buffer.byteLength(data)>40*1024*1024)throw Error('40 MiB limit');fs.writeFileSync('verification/parity-r23/'+file,data);parts.push({file,rows:rows.length,bytes:Buffer.byteLength(data),sha256:crypto.createHash('sha256').update(data).digest('hex')});rows=[];size=0;}
for(const row of result.rows){const n=Buffer.byteLength(JSON.stringify(row));if(n+size>30*1024*1024)flush();rows.push(row);size+=n;}flush();
fs.writeFileSync('verification/parity-r23/'+stem+'-oracle.json',JSON.stringify({counts:result.counts,parts,provenance},null,2));console.log(JSON.stringify({counts:result.counts,parts}));process.exit(0);
