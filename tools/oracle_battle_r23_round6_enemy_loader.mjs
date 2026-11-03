import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua','40-fx.lua','50-render.lua','80-press.lua'];
const raw=files.map(f=>fs.readFileSync(path.join(root,'bot/src',f),'utf8'));
const patches={
 '20-state.lua':[['function B.blank_u','B.__batch.unit0=unit0\nfunction B.blank_u']],
 '32-personal-a.lua':[['B.TR.felice =','B.__batch.felice_scan=felice_scan\nB.TR.felice =']],
};
const extra='B.__batch={}\n'+raw.map((s,i)=>{s=s.replaceAll('\r\n','\n');for(const [a,b] of patches[files[i]]||[]){if(!s.includes(a))throw Error(a);s=s.replace(a,b);}return (files[i]==='34-traits.lua'?'B.GH={}':'')+'\ndo\n'+s+'\nend';}).join('\n');
const {L,sim}=await mkSim({policy:false,extra});
const fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
let result;try{result=await L(fresh+'\n'+fs.readFileSync('tools/oracle_battle_r23_round6_enemy.lua','utf8'));}catch(e){console.log(sim.errors,sim.logs);throw e;}
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
// Convert only fields whose Lua contract is a map; never coerce scalar values.
const map=v=>Array.isArray(v)&&!v.length?{}:v;
function normalize(s){if(s&&typeof s==='object'){for(const u of s.u||[]){if(u&&typeof u==='object'){for(const k of ['bf','x'])if(k in u)u[k]=map(u[k]);}}}return s;}
for(const r of result.rows){r.input=map(r.input);normalize(r.input.state);for(const u of r.expected.units){u.bf=map(u.bf);u.x=map(u.x);}}
const output={...result,provenance};
const data=JSON.stringify(output,null,2)+'\n';if(Buffer.byteLength(data)>50*1024*1024)throw Error('split oracle before writing');
fs.writeFileSync('verification/parity-r23/battle-round6-enemy-oracle.json',data);
console.log(JSON.stringify({cases:result.rows.length,counts:result.counts,bytes:Buffer.byteLength(data)}));process.exit(0);
