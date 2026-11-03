import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim:mkSimBase}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const mkSim=async(o)=>{const sim=await mkSimBase({...o,extra:'B.__r23_cov={calls={},branches={}}\n'+o.extra});const original=sim.L;return {...sim,L:async(code)=>{const pack=await original('B.__r23_cov={calls={},branches={}};local __result=(function()\n'+code+'\nend)();return {result=__result,coverage=B.__r23_cov}');fs.writeFileSync('verification/parity-r23/coverage/battle-round6.json',JSON.stringify(pack.coverage));return pack.result;}};};
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
const patches={
 '20-state.lua':[['function B.blank_u','B.__batch.unit0=unit0\nfunction B.blank_u']],
 '32-personal-a.lua':[['B.TR.felice =','B.__batch.felice_scan=felice_scan\nB.TR.felice =']],
};
const extra='B.__batch={}\n'+raw.map((s,i)=>{s=s.replaceAll('\r\n','\n');for(const [a,b] of patches[files[i]]||[]){if(!s.includes(a))throw Error(a);s=s.replace(a,b);}return (files[i]==='34-traits.lua'?'B.GH={}':'')+'\ndo\n'+s+'\nend';}).join('\n');
const {L,sim}=await mkSim({policy:false,extra});
const fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
let result;try{result=await L(fresh+'\n'+fs.readFileSync('tools/oracle_battle_r23_round6.lua','utf8'));}catch(e){console.log(sim.errors,sim.logs);throw e;}
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
// Convert only fields whose Lua contract is a map; never coerce scalar values.
const map=v=>Array.isArray(v)&&!v.length?{}:v;
function normalize(s){if(s&&typeof s==='object'){for(const u of s.u||[]){if(u&&typeof u==='object'){for(const k of ['bf','x'])if(k in u)u[k]=map(u[k]);}}}return s;}
for(const r of result.rows){r.input=map(r.input);if(r.input.state)normalize(r.input.state);normalize(r.expected);if(r.op==='migrate')normalize(r.expected);if(r.op==='felice_full')for(const u of r.expected.units){u.bf=map(u.bf);u.x=map(u.x);}if(r.op==='unit0'){r.expected.bf=map(r.expected.bf);r.expected.x=map(r.expected.x);}if(r.op==='bind'){r.expected.defs=r.expected.defs.map(v=>v);}}
const output={...result,provenance};
const data=JSON.stringify(output,null,2)+'\n';if(Buffer.byteLength(data)>50*1024*1024)throw Error('split oracle before writing');
fs.writeFileSync('verification/parity-r23/battle-round6-oracle.json',data);
console.log(JSON.stringify({cases:result.rows.length,counts:result.counts,bytes:Buffer.byteLength(data)}));process.exit(0);
