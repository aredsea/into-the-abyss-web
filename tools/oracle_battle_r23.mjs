import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';
const {mkSim}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua'];
const extra=files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(path.join(root,'bot/src',f),'utf8')}\nend`).join('\n');
const {L}=await mkSim({policy:false,extra});
const cases=JSON.parse(fs.readFileSync('verification/parity-r23/inputs.json','utf8'));
const fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
const probe=fs.readFileSync('tools/oracle_battle_r23.lua','utf8');
const result=await L(fresh+'\nlocal cases=json.decode([==['+JSON.stringify(cases)+']==])\n'+probe);
// The source JSON encoder represents an empty Lua table as []; the Godot
// effect map is a Dictionary. Normalize only this explicitly named map.
for(const row of result)for(const u of row.expected.units||[])if(Array.isArray(u.buffs)&&u.buffs.length===0)u.buffs={};
for(const row of result)if(row.op==='persona_meta')for(const key of ['prefix_lv','suffix_lv'])if(Array.isArray(row.expected.value[key])&&row.expected.value[key].length===0)row.expected.value[key]={};
const provenance=Object.fromEntries(files.map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'bot/src',f))).digest('hex')]));
fs.writeFileSync('verification/parity-r23/oracle.json',JSON.stringify({provenance,rows:result},null,2)+'\n');
console.log(JSON.stringify({cases:result.length}));process.exit(0);
