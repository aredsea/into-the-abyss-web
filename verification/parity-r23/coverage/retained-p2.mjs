// Canonical source functions execute inside the original read-only wasmoon harness.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const source=process.env.R21_BOT || 'C:/Clauede Code/dungeon-bot';
const {mkSim:mkSimBase}=await import(pathToFileURL(path.join(source,'bot/lua_sim.mjs')).href);
const mkSim=async(o)=>{const sim=await mkSimBase({...o,extra:'B.__r23_cov={calls={},branches={}}\n'+o.extra});const original=sim.L;return {...sim,L:async(code)=>{const pack=await original('B.__r23_cov={calls={},branches={}};local __result=(function()\n'+code+'\nend)();return {result=__result,coverage=B.__r23_cov}');fs.writeFileSync('verification/parity-r23/coverage/retained-p2.json',JSON.stringify(pack.coverage));return pack.result;}};};
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua'];
const extra=files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(path.join('C:/Users/asone/Documents/Codex/2026-10-30/into-the-abyss-handoff/work/r21-a-data/verification/parity-r23/coverage/instrumented',f),'utf8')}\nend`).join('\n');
const {L}=await mkSim({policy:false,extra});
const result=await L(fs.readFileSync('tools/oracle_combat_p2_r22.lua','utf8'));
fs.writeFileSync('verification/parity-r23/coverage/retained-p2-p2-oracle.json',JSON.stringify({files,...result},null,2)+'\n');
console.log(JSON.stringify(Object.fromEntries(Object.entries(result).map(([k,v])=>[k,v.length]))));
process.exit(0);
