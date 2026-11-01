// Execute reviewed DOT paths with the canonical character/global/equipment hooks.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const source=process.env.R21_BOT || 'C:/Clauede Code/dungeon-bot';
const {mkSim}=await import(pathToFileURL(path.join(source,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua'];
// Reset the bundled hook table before reloading traits/gear, avoiding double wrappers.
const extra=files.map(f=>`${f==='34-traits.lua'?'\nB.GH={}\n':''}\ndo\n${fs.readFileSync(path.join(source,'bot/src',f),'utf8')}\nend\n`).join('');
const {L}=await mkSim({policy:false,extra});
const result=await L(`
local function fresh()
 local run=B.run; B.run=function() end
 local st=B.fresh(1,nil,{enc={fl={"apprentice_doll"},fg={""},ne=1,star=1,raid=false},el=1})
 B.run=run; st.seed=12345; st.n=0; st.cur=1
 for i=1,4 do
  local d,u=B.DEF[i],st.u[i]; d.cid="neutral"; d.clsid="sanctioned"
  u.hp=1000; u.mhp=1000; u.sh=0; u.rc=""; u.na=""; u.ln=""; u.gq=nil; u.gu=nil; u.bf={}; u.x={}; u.tau=0
 end
 B.ACT=nil; B.begin_ev(st)
 return st
end
local out={dots={},evades={}}
for _,kind in ipairs({"duty","wall_scar","last_stand","priest","echo_saved","echo_dead"}) do
 local st=fresh(); local u=st.u[1]
 if kind=="duty" then u.df=1; B.badd(u,"psguard",.5,3); u.sh=20 end
 if kind=="wall_scar" then u.hp=50; u.gu={{key="wa_last",v={20,2,30}},{key="wa_scar",v={50,50}}} end
 if kind=="last_stand" then u.hp=250; u.gu={{key="last_stand",x=20,n=2}} end
 if kind=="priest" then u.hp=50; B.DEF[2].clsid="priest" end
 if kind=="echo_saved" or kind=="echo_dead" then
  u.hp=50; u.sh=20; st.u[2].gu={{key="pa_echo",v={50}}}; st.gk={pa_echo=1}
  if kind=="echo_saved" then u.gu={{key="wa_last",v={20,2,30}}} end
 end
 B.edot_add(st,1,5,kind=="duty" and 40 or 100,3)
 if kind~="last_stand" then B.edot_add(st,1,5,kind=="duty" and 60 or 100,3) end
 B.edot_tick(st,1)
 out.dots[#out.dots+1]={kind=kind,hp=u.hp,shield=u.sh,scar=u.x.scr or 0,saved=u.x.wlu==1,stood=u.x.lsd==1}
end
for _,evade in ipairs({0,15,100}) do for _,nation in ipairs({"","naerin"}) do for seed=1,20 do
 local st=fresh(); st.seed=seed*7919; local u=st.u[1]; u.gq={evade=evade}; u.na=nation
 B.DEF[5].acts={{kind="dot",name="dot",m=1,tick=.3,turns=3}}; st.u[5].ia=1; st.u[5].it=1
 B.enemy_turn(st,5)
 out.evades[#out.evades+1]={seed=st.seed,evade=evade,nation=nation,stack=#(u.edot or {})>0,rng=st.rs,target=st.u[5].it}
end end end
return out
`);
fs.writeFileSync('verification/data-r21/enemy-review-oracle.json',JSON.stringify({files,...result},null,2)+'\n');
console.log(JSON.stringify({dots:result.dots.length,evades:result.evades.length}));
process.exit(0);
