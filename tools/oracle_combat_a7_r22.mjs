import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';
const {mkSim}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua'];
const extra=files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(path.join(root,'bot/src',f),'utf8')}\nend`).join('\n');
const {L}=await mkSim({policy:false,extra});
let fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
const result=await L(fresh+`
local out={ticks={},shield={}}
do
 local st=fresh(); st.u[1].gq={shield=100}; st.u[1].gu={{key="guardian",p=100,x=50,n=1}}
 B.DEF[2].cid="altan"; B.TR.altan.start(st,2); out.altan_start=st.u[1].sh
end
do
 local st=fresh(); st.u[2].gu={{key="party_dmg",x=5}}; st.u[3].gu={{key="party_dmg",x=10}}
 out.party_damage=B.GH.deal(st,1,5,100,{},{});
end
do
 local st=fresh(); B.DEF[1].clsid="unsanctioned"; B.DEF[1].line="지능"
 B.attack(st,1,5,{name="일반 공격",id="atk",m=1,ab=0}); out.dot_life=st.u[5].dot[1].n
 for n=1,4 do local hp=st.u[5].hp; B.dot_tick(st,5); out.ticks[n]=hp-st.u[5].hp end
end
do
 local st=fresh(); st.u[5].hp=100000; st.u[5].mhp=100000; st.u[1].gu={{key="un_chain",v={3,20}}}
 B.DEF[1].clsid="unsanctioned"; B.DEF[1].line="지능"
 for n=1,3 do B.attack(st,1,5,{name="일반 공격",id="atk",m=0,ab=0}) end
 out.chain_hp=st.u[5].hp
end
do
 local run=B.run; B.run=function() end
 local st=B.fresh(1,nil,{enc={fl={"tome_librarian"},fg={},ne=1,star=1,raid=true},el=1})
 B.run=run; B.begin_ev(st); st.u[5].hp=1440; st.u[5].mhp=1440
 st.u[1].gu={{key="un_chain",v={3,20}}}
 for n=1,3 do B.dot_push(st,st.u[5],500,3,1) end
 out.phase_hp=st.u[5].hp
end
for _,fixed in ipairs({false,true}) do
 local st=fresh(); B.DEF[2].cid="sorel"; st.u[1].hp=100; st.u[1].sh=1000
 st.u[1].gu={{key="last_stand",x=20,n=2}}
 B.strike(st,1,100,0,nil,fixed and "fixed" or 5)
 out.shield[#out.shield+1]={fixed=fixed,hp=st.u[1].hp,rescue=st.u[2].x.gt or 0,stood=st.u[1].x.lsd==1}
end
return out`);
fs.writeFileSync('verification/data-r21/a7-oracle.json',JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result)); process.exit(0);
