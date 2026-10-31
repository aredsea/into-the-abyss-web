// Execute canonical source, without writing to the source bot.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const source=process.env.R21_BOT || 'C:/Clauede Code/dungeon-bot';
const {mkSim}=await import(pathToFileURL(path.join(source,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','31-foes.lua','72-guild.lua'];
const extra=files.map(f=>`\ndo\n${fs.readFileSync(path.join(source,'bot/src',f),'utf8')}\nend\n`).join('');
const {L}=await mkSim({policy:false,extra});
const guild=await L('return B.GUILD.elite');
const cfg=JSON.parse(fs.readFileSync('project/data/dungeons-r21.json','utf8'));
cfg.quest_elite=guild;
cfg.enemy_skill_order=await L('local out={} for cls,kit in pairs(B.KIT) do local a={} for _,sk in ipairs(kit) do if sk.id~="atk" and sk.id~="df" then a[#a+1]=sk.id end end a[#a+1]="personal"; out[cls]=a end return out');
fs.writeFileSync('project/data/dungeons-r21.json',JSON.stringify(cfg,null,2)+'\n');
const gear=await L(`local out={} for seed=1,40 do for _,kind in ipairs({"토벌","구조","회수"}) do
 local q={id="q"..seed,kind=kind,difficulty="엘리트"}; local G={seed=seed*7919}; local pm={{id="persona",cls="warrior"},{id="persona",cls="priest"}}
 local n=B.GUILD.elite.gear_min+math.floor(B.ex_mix(G.seed+seed,1,9,0)*(B.GUILD.elite.gear_max-B.GUILD.elite.gear_min+1))
 local codes={} for j=1,n do codes[j]=B.gd_gear(G,q,pm,j) end
 out[#out+1]={seed=G.seed,quest=q,classes={"warrior","priest"},codes=codes}
end end return out`);
fs.mkdirSync('verification/data-r21',{recursive:true});
fs.writeFileSync('verification/data-r21/elite-gear-oracle.json',JSON.stringify(gear,null,2)+'\n');
if(fs.existsSync('tools/oracle_enemy_r21.lua')) {
 const result=await L(fs.readFileSync('tools/oracle_enemy_r21.lua','utf8'));
 fs.writeFileSync('verification/data-r21/enemy-action-oracle.json',JSON.stringify({files,...result},null,2)+'\n');
 console.log(JSON.stringify({enemies:result.enemies,turns:result.samples.length,gear:gear.length}));
} else console.log(JSON.stringify({guild,gear:gear.length}));
process.exit(0);
