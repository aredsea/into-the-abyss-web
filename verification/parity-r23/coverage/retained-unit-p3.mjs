import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import crypto from 'node:crypto';
const root=process.env.R21_BOT || 'C:/Clauede Code/dungeon-bot';
const {mkSim:mkSimBase}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const mkSim=async(o)=>{const sim=await mkSimBase({...o,extra:'B.__r23_cov={calls={},branches={}}\n'+o.extra});const original=sim.L;return {...sim,L:async(code)=>{const pack=await original('B.__r23_cov={calls={},branches={}};local __result=(function()\n'+code+'\nend)();return {result=__result,coverage=B.__r23_cov}');fs.writeFileSync('verification/parity-r23/coverage/retained-unit-p3.json',JSON.stringify(pack.coverage));return pack.result;}};};
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua'];
const extra=files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(path.join('C:/Users/asone/Documents/Codex/2026-10-30/into-the-abyss-handoff/work/r21-a-data/verification/parity-r23/coverage/instrumented',f),'utf8')}\nend`).join('\n');
const {L}=await mkSim({policy:false,extra});
const result=await L(fs.readFileSync('tools/oracle_combat_p3_r22.lua','utf8'));
result.catalog=await L(`local out={}; for id,c in pairs(B.CAST) do if B.PRUN[id] and id~="persona" then
 local hooks={};for _,k in ipairs({"can","start","deal","take","save","hit_after","hp_cost","abyss_mul","abyss_after","turn_end","round","evade","damaged","enemy_end","enemy_dead","attacked","ally_down"}) do if B.TR[id] and B.TR[id][k] then hooks[#hooks+1]=k end end
 out[#out+1]={id=id,name=c.name,skill_id=B.PSK[id].id,mp=c.skill_mp,target=B.PSK[id].tgt or c.skill_tgt,trait=B.GEN.tr[id],hooks=hooks}
end end;table.sort(out,function(a,b)return a.id<b.id end);return out`);
result.provenance={};
for(const name of [...files.map(f=>'src/'+f),'harness_personal_a.mjs','harness_personal_b.mjs','harness_traits.mjs','harness_regen_mix.mjs']) {
 const bytes=fs.readFileSync(path.join(root,'bot',name));
 result.provenance[name]={sha256:crypto.createHash('sha256').update(bytes).digest('hex'),lines:bytes.toString('utf8').split('\n').length};
}
fs.writeFileSync('verification/parity-r23/coverage/retained-unit-p3-p3-oracle.json',JSON.stringify({files,...result},null,2)+'\n');
console.log(JSON.stringify({personal:result.personal.length,characters:result.catalog.length,traits:result.traits.length,class_skills:result.class_skills.length,deaths:result.deaths.length,regen_orders:result.regen_mix.length,dot_credit:result.dot_credit.length}));
process.exit(0);
