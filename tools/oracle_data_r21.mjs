// Read-only execution of the canonical bot through its existing wasmoon harness.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL, fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source=process.env.R21_BOT || 'C:/Clauede Code/dungeon-bot';
const {mkSim}=await import(pathToFileURL(path.join(source,'bot/lua_sim.mjs')).href);
// Reload the actual requested source files; do not rely on a possibly old dist formula.
const files=['05-gen.lua','24-stats.lua','26-start.lua','27-compose.lua','31-foes.lua','72-guild.lua','74-affection.lua','76-dungeon.lua','77-explore.lua'];
const extra=files.map(f=>`\ndo\n${fs.readFileSync(path.join(source,'bot/src',f),'utf8')}\nend\n`).join('');
const {L}=await mkSim({policy:false,extra});
const constants=await L('local g=B.gear(); local items={} for _,id in ipairs(g.order) do local i=g.items[id]; items[#items+1]={id=id,cls=i.cls,slot=i.slot,rarity=i.rarity} end return {EX=B.EX,AFF=B.AFF,quest_rifts=B.QUEST_RIFTS,quest_difficulty=B.GD_DIFFICULTY, item_order=B.IT.order, zone_order=B.ZONE_ORDER, foe_order=B.FOE_ORDER,gear_items=items,gear_version=g.v,gear_drop=g.fx.drop}');
constants.quest_elite=await L('return B.GUILD.elite');
constants.enemy_skill_order=await L('local out={} for cls,kit in pairs(B.KIT) do local a={} for _,sk in ipairs(kit) do if sk.id~="atk" and sk.id~="df" then a[#a+1]=sk.id end end a[#a+1]="personal"; out[cls]=a end return out');
const samples=await L(`
local out={}
local function sample(ctx,seed,avg,explore)
 local e=B.compose(seed,ctx)
 if e.floor then e.dn={floor=e.floor,kind=explore and "explore" or "boss",party_n=ctx.party_n} end
 local el=e.floor and B.floor_level(avg,B.floor_info(e.floor)) or avg
 local st={el=el,star=e.star,dk=e.dk,dc=e.dc,zk=e.zk,enc=e,fl=e.fl,fg=e.fg}
 local stats,defs={},{}
 for j=1,#e.fl do local d=B.foe_def(st,j); defs[j]={name=d.name,grade=d.grade,srole=d.srole,lvn=d.lvn}; stats[j]=B.foe_stats(st,d) end
 out[#out+1]={ctx=ctx,seed=seed,avg=avg,explore=explore,enc=e,el=el,defs=defs,stats=stats,
 gold=e.floor and B.dn_gold(e.floor,e.kind) or 0}
end
for f=1,60 do for n=1,4 do for _,k in ipairs({"battle","elite","boss"}) do
 local ck=k=="boss" and B.floor_boss_kind(B.floor_info(f)) or k
 sample({floor=f,kind=ck,party_n=n},f*7919+n*101+17,math.min(40,f*1.5),k~="boss")
end end end
for _,f in ipairs({81,108,135,270,420}) do for _,k in ipairs({"battle","elite","chief","boss"}) do
 sample({floor=f,kind=k,party_n=4},f*313+7,40,false)
end end
for _,id in ipairs(B.RIFT_ORDER) do for star=1,4 do for n=1,4 do for _,k in ipairs({"battle","elite","rift_core"}) do
 sample({rift_id=id,stars=star,kind=k,party_n=n},star*7919+n*31,star*8,false)
end end end end
return out`);
const rolls=await L(`local a={} for f=1,60 do for s=1,5 do
 local seed=f*7919+13
 a[#a+1]={seed=seed,floor=f,step=s,elites=s%3,mix=B.ex_mix(seed,f,s,1),roll=B.ex_roll(seed,f,s,s%3,{"warrior","assassin","sanctioned","priest"}),battle_seed=math.floor(B.ex_mix(seed,f,s,9)*2147483646)+1}
end end return a`);
const allStats=await L(`local a={} for _,id in ipairs(B.FOE_ORDER) do for _,f in ipairs({1,2,3,27,28,55,420}) do
 local e={floor=f,order=B.floor_info(f).ord,dn={kind="explore",party_n=4}}
 local st={el=math.min(40,f+1),star=B.floor_star(B.floor_info(f)),dk=B.floor_info(f).dk,zk=B.floor_info(f).zone,enc=e,fl={id},fg={""}}
 local d=B.foe_def(st,1); a[#a+1]={id=id,floor=f,el=st.el,stats=B.foe_stats(st,d)}
end end return a`);
const quests=await L(`local a={} for lv=1,40 do for _,d in ipairs({"낮음","중간","높음","엘리트"}) do for _,k in ipairs({"토벌","구조","회수"}) do
 local q={lv=lv,gold=100,reward_v=2,difficulty=d,kind=k}; a[#a+1]={quest=q,mult=B.lv_reward(lv),gold=B.gd_gold({},q),fight=B.gd_fight(q)}
end end end return a`);
const out=path.join(root,'verification/data-r21'); fs.mkdirSync(out,{recursive:true});
fs.writeFileSync(path.join(out,'lua-oracle.json'),JSON.stringify({constants,samples,rolls,allStats,quests},null,2)+'\n');
console.log(JSON.stringify({samples:samples.length,rolls:rolls.length,allStats:allStats.length,source_files:files}));
process.exit(0);
