-- Inputs and observations only: all rules run in the canonical Lua engine.
local function fresh()
  local run=B.run; B.run=function() end
  local st=B.fresh(1,nil,{enc={fl={"apprentice_doll"},fg={""},ne=1,star=1,raid=false},el=1})
  B.run=run; st.seed=1; st.n=0; st.cur=1; st.K=40
  for i=1,4 do
    local u,d=st.u[i],B.DEF[i]; d.cid="neutral"; d.clsid="sanctioned"
    u.hp=1000; u.mhp=1000; u.sh=0; u.rc=""; u.na=""; u.ln=""; u.gq=nil; u.gu=nil
    u.bf={}; u.x={}; u.tau=0; u.df=0; u.de=40; u.lf=0; u.ps=0; u.g=0; u.chg=0; u.al=1
  end
  B.ACT=nil; B.SKON=nil; B.begin_ev(st)
  return st
end
local function strike(st,raw,fixed) B.strike(st,1,raw,0,nil,fixed and "fixed" or 5) end
local out={echo={},death={},priority={},wall={},priest={},ticks={},trim={},heals={},echo_order={},synergy={}}
for _,fixed in ipairs({true,false}) do for _,hp in ipairs({50,500}) do
 for _,raw in ipairs({40,100}) do for _,humans in ipairs({0,3}) do
  for _,recv in ipairs({0,25}) do for _,heal in ipairs({0,40}) do
   local st=fresh(); local u=st.u[1]; u.hp=hp; u.sh=21; u.gq={healrecv=recv,heal=99}
   st.u[2].gu={{key="pa_echo",v={50}}}; st.u[2].gq={heal=heal}; st.gk={pa_echo=1}
   for i=1,humans do st.u[i].rc="human" end
   strike(st,raw,fixed)
   out.echo[#out.echo+1]={fixed=fixed,initial=hp,raw=raw,humans=humans,recv=recv,heal=heal,hp=u.hp,shield=u.sh}
  end end
 end end
end end
for _,fixed in ipairs({true,false}) do for _,cid in ipairs({"neutral","haldric","adeline"}) do
 local st=fresh(); local u=st.u[1]; u.hp=1; u.tau=3; u.chg=1; u.oath=2; u.oT=4
 B.DEF[1].cid=cid; B.DEF[2].cid="marceline"
 for j=1,5 do
  B.badd(st.u[j],"probe",.2,3); st.u[j].bf.probe.src=1
  B.badd(st.u[j],"keep",.3,3); st.u[j].bf.keep.src=2
 end
 strike(st,100,fixed)
 local removed,kept=0,0
 for j=1,5 do if not st.u[j].bf.probe then removed=removed+1 end; if st.u[j].bf.keep then kept=kept+1 end end
 out.death[#out.death+1]={fixed=fixed,cid=cid,hp=u.hp,removed=removed,kept=kept,taunt=u.tau,charging=u.chg,cover=u.oath}
end end
for _,fixed in ipairs({true,false}) do
 local st=fresh(); local u=st.u[1]; u.hp=50; B.DEF[1].cid="marceline"; u.gu={{key="wa_last",v={20,2,30}}}
 strike(st,100,fixed)
 local row={fixed=fixed,hp=u.hp,shield=u.sh,wall=u.x.wlu==1,saved=u.lf}
 strike(st,1000,fixed); row.second_hp=u.hp; row.second_wall=u.x.wlu==1
 out.priority[#out.priority+1]=row
end
for _,fixed in ipairs({true,false}) do for _,mhp in ipairs({1,3,7,1003}) do
 local st=fresh(); local u=st.u[1]; u.mhp=mhp; u.hp=math.min(50,mhp); u.gu={{key="wa_last",v={20,2,30}}}
 strike(st,1000,fixed); out.wall[#out.wall+1]={fixed=fixed,mhp=mhp,hp=u.hp}
end end
for _,fixed in ipairs({true,false}) do for _,kind in ipairs({"self","alone","first_plain","first_miracle"}) do
 local st=fresh(); local u=st.u[1]; u.hp=50; u.mhp=1003
 if kind=="self" or kind=="alone" then
  B.DEF[1].clsid="priest"
  if kind=="alone" then for i=2,4 do st.u[i].al=0; st.u[i].hp=0 end end
 else
  B.DEF[2].clsid="priest"; B.DEF[3].clsid="priest"
  st.u[kind=="first_miracle" and 2 or 3].gu={{key="pr_miracle",v={60,15}}}
 end
 strike(st,100,fixed); out.priest[#out.priest+1]={fixed=fixed,kind=kind,hp=u.hp,shield=u.sh,used=u.ps==1}
end end
for _,cid in ipairs({"neutral","erdene","urda","tove"}) do
 for _,raw in ipairs({100,200}) do for _,tau in ipairs({1,2}) do
  local st=fresh(); local u=st.u[1]; B.DEF[1].cid=cid; u.hp=50; u.tau=tau; u.mp=0; u.mmp=100
  u.gq={mpreg=7}; u.gu={{key="taunt_heal",p=100,x=10}}; u.x.blk=80
  u.x.rg={d=60,n=3}; st.u[2].hp=500
  B.begin_turn(st,1)
  local before=u.hp; B.edot_add(st,1,5,raw,3); local down=B.edot_tick(st,1)
  -- A down actor never reaches end_turn (B.run). No round is invented here.
  if raw==200 or cid=="neutral" or cid=="erdene" then
   out.ticks[#out.ticks+1]={cid=cid,raw=raw,tau=tau,before=before,hp=u.hp,mp=u.mp,shield=u.sh,other=st.u[2].hp,blocked=u.x.blk or 0,down=down,dot_n=u.edot[1].n}
  end
 end end
end
for _,fixed in ipairs({true,false}) do
 local st=fresh(); local u=st.u[1]; u.hp=1
 for i=1,3 do st.u[i].na="morgas" end
 B.fire(st,"start")
 st.u[5].dot={{d=77,n=3,c=1,by=2}}
 for i=1,6 do B.dot_push(st,st.u[5],i*10,4,2) end
 strike(st,100,fixed)
 local sum,n=0,0
 for _,d in ipairs(st.u[5].dot) do if d.k==1 then sum=sum+d.d; n=n+1 end end
 out.trim[#out.trim+1]={fixed=fixed,amount=sum,count=n,corrosion=st.u[5].dot[1].d,synergy=st.sy.morgas}
end
for _,skill in ipairs({false,true}) do for _,humans in ipairs({0,3}) do
 for _,recv in ipairs({0,25}) do
  local st=fresh(); local u=st.u[1]; u.hp=980; u.gq={healrecv=recv}
  st.u[3].gq={heal=40}; st.u[3].gu={{key="al_surge",v={50,3}}}
  for i=1,humans do st.u[i].rc="human" end
  if skill then B.ACT=st.u[3]; B.SKON="heal" end
  B.heal(st,1,21.5,0)
  out.heals[#out.heals+1]={skill=skill,humans=humans,recv=recv,hp=u.hp,shield=u.sh}
 end
end end
for _,fixed in ipairs({true,false}) do for _,kind in ipairs({"wall","priest","sorel","dead_owner"}) do
 local st=fresh(); local u=st.u[1]; u.hp=kind=="sorel" and 250 or 50; u.sh=21; u.gq={healrecv=25}
 st.u[2].gu={{key="pa_echo",v={50}}}; st.gk={pa_echo=1}
 if kind=="wall" then u.gu={{key="wa_last",v={20,2,30}}} end
 if kind=="priest" then B.DEF[2].clsid="priest" end
 if kind=="sorel" then B.DEF[2].cid="sorel"; st.u[2].cs=100; st.u[2].gq={heal=99} end
 if kind=="dead_owner" then st.u[2].al=0; st.u[2].hp=0; u.hp=250 end
 strike(st,100,fixed)
 out.echo_order[#out.echo_order+1]={fixed=fixed,kind=kind,hp=u.hp,shield=u.sh}
end end
for _,cid in ipairs({"haldric","adeline"}) do
 local st=fresh(); B.DEF[3].cid=cid; st.u[1].hp=1
 st.u[1].rc="halfelf"; st.u[2].rc="halfelf"; B.DEF[1].row="전열"; B.DEF[2].row="전열"; B.DEF[3].row="전열"
 B.fire(st,"start"); B.PRUN[cid](st,3,2,{name="probe"})
 local key=cid=="haldric" and "red20" or "red"
 local before=st.u[2].bf[key].n
 strike(st,1000,true); B.PRUN[cid](st,3,2,{name="probe"})
 out.synergy[#out.synergy+1]={cid=cid,before=before,after=st.u[2].bf[key].n}
end
return out
