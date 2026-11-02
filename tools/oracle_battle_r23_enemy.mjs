import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua'];
const extra=files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(path.join(root,'bot/src',f),'utf8')}\nend`).join('\n');
const {L}=await mkSim({policy:false,extra});
const dump=fs.readFileSync('tools/oracle_enemy_r21.lua','utf8').split('for ordinal,id')[0];
const rows=await L(dump+'\n'+fs.readFileSync('tools/oracle_battle_r23_enemy.lua','utf8'));
const provenance=Object.fromEntries(files.map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'bot/src',f))).digest('hex')]));
fs.writeFileSync('verification/parity-r23/enemy-oracle.json',JSON.stringify({rows,provenance},null,2)+'\n');console.log(JSON.stringify({cases:rows.length}));process.exit(0);
