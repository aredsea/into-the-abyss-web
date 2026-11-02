local function fresh()
 local run=B.run; B.run=function() end
 local st=B.fresh(1,nil,{enc={fl={"apprentice_doll","apprentice_doll"},fg={"",""},ne=2,star=1,raid=false},el=1})
 B.run=run; st.seed=12345; st.n=0; st.cur=1; st.tk=0; st.rd=0
 for i,u in ipairs(st.u) do
  if i<=4 then B.DEF[i].cid="neutral"; B.DEF[i].clsid="warrior"; B.DEF[i].line="힘" end
  u.hp=1000; u.mhp=1000; u.mp=10; u.mmp=100; u.sh=0; u.rc=""; u.na=""; u.ln=""; u.gq=nil; u.gu=nil; u.bf={}; u.x={}; u.tau=0
  u.sp=100; u.g=10000
 end
 B.ACT=nil; B.begin_ev(st)
 return st
end
local out={clock={},round={},hit={},battles={},raid_battles={},ending={},raid={},enrage={}}
for case=1,16 do
 local st=fresh(); local input={g={},sp={},alive={},cur=1,cost=(case%3==0) and 20000 or 10000}
 for i,u in ipairs(st.u) do
  u.g=((case*137+i*311)%12000)-200; u.sp=83+(i*17+case*13)%91
  if case==1 then u.g=10000; u.sp=100 end
  if case==2 then u.g=(i==1) and -.25 or ((i==2) and 99.9 or 100); u.sp=100 end
  if case==3 then u.g=10000; u.sp=(i==1) and 99.99 or 100 end
  if case==4 then u.g=90000; u.sp=100 end
  if case==5 and (i==2 or i==5) then u.al=0; u.hp=0 end
  input.g[i]=u.g; input.sp[i]=u.sp; input.alive[i]=u.al==1
 end
 local preview=B.preview(st,8)
 B.end_turn(st,1,input.cost)
 local cur=B.advance(st); local g={}; for i,u in ipairs(st.u) do g[i]=u.g end
 out.clock[#out.clock+1]={input=input,preview=preview,cur=cur,g=g,tk=st.tk,rd=st.rd,next_preview=B.preview(st,8)}
end
for case=1,28 do
 local st=fresh(); local owner=(case%4)+1; local ticks=1+math.floor((case-1)/8)
 local kind=({"mp","urda","tove","halfelf","sorel","dead","miko"})[1+(case-1)%7]
 for i=1,4 do
  local u=st.u[i]; u.hp=300+i*100; u.mp=(i==2) and 99 or 10; u.cs=51; u.g=100000
  if i<=2 then B.DEF[i].line="지능" end
  if kind=="halfelf" then u.rc=(i<=3) and "halfelf" or ""; B.badd(u,"adn",.2,3); B.badd(u,"ddn",.2,3) end
 end
 if kind=="urda" then B.DEF[owner].cid="urda"; B.badd(st.u[1],"adn",.2,3); B.badd(st.u[1],"ddn",.2,3) end
 if kind=="tove" then B.DEF[owner].cid="tove"; st.u[owner].sh=250 end
 if kind=="sorel" then B.DEF[owner].cid="sorel"; for i=1,4 do st.u[i].x.rg={d=31,n=2} end end
 if kind=="miko" then B.DEF[owner].cid="miko" end
 if kind=="dead" then st.u[2].hp=0; st.u[2].al=0; B.DEF[owner].cid="urda"; if owner~=2 then st.u[owner].hp=0; st.u[owner].al=0 end end
 local input={kind=kind,owner=owner,ticks=ticks}
 for k=1,ticks do st.rd=st.rd+1; B.round_tick(st) end
 local units={}
 for i=1,4 do local u=st.u[i]; units[i]={hp=u.hp,mp=u.mp,sh=u.sh,g=u.g,adn=B.bhas(u,"adn"),ddn=B.bhas(u,"ddn"),regen=u.x.rg and u.x.rg.n or 0} end
 out.round[#out.round+1]={input=input,units=units}
end
for case=1,120 do
 local st=fresh(); local u,v=st.u[1],st.u[5]
 st.seed=case*7919; st.n=case%7; B.rbegin(st)
 u.cs=43.25; u.ag=17; u.cr=13; v.de=27.3; st.K=40
 B.DEF[1].el="fire"; B.DEF[5].wk=(case%2==0) and {"fire"} or {"ice"}
 local up=(case%3)*.1; local dn=(case%4)*.1; local df=(case%5)*.05
 B.badd(u,"atk",up,3); B.badd(u,"adn",dn,3); B.badd(v,"def",df,3); B.badd(v,"ddn",.1,3)
 v.mk=(case%3==0) and 1 or 0; v.dr=(case%5==0) and 1 or 0
 v.fx=(case%7==0) and 2 or 0; v.fb=.6; v.df=(case%4==0) and 1 or 0; v.sh=21
 local snipe=(case%2==0); local m=snipe and 2 or .8
 local input={seed=st.seed,n=st.n,up=up,dn=dn,df=df,mark=v.mk==1,broken=v.dr==1,fox=v.fx>0,guard=v.df==1,snipe=snipe,power=m}
 local res=B.attack(st,1,5,{m=m,cc=snipe and 70 or nil,cm=snipe and 2 or nil,name="oracle",brk=0})
 out.hit[#out.hit+1]={input=input,hp=v.hp,shield=v.sh,crit=res.c==1,rng=st.rs}
end
local parties={{"hildegard","bargut","teiris","berenga"},{"marceline","naran","levia","teiris"},{"sorel","adeline","tove","urda"}}
for pi,party in ipairs(parties) do for bn=1,4 do for ei,foe in ipairs({"apprentice_doll","rusted_shieldman","raging_lecturer","frost_contractor"}) do
 local pm={}
 for i,id in ipairs(party) do local c=B.cls_of(B.CAST[id].cls); pm[i]={id=id,cls=c.id,L=10} end
 local run0=B.run; B.run=function() end
 local raid=ei>2; local fl=raid and {foe} or {foe,foe}; local ne=raid and 3 or 2
 local st=B.fresh(bn,nil,{pm=pm,enc={fl=fl,fg={},ne=ne,star=1,raid=raid,zk="academy_upper"},el=10})
 B.run=run0
 local trace={}; local last_ev=nil; local last_event=0
 local function dump(i)
  local hp,mp,sh,g,targets,abyss,broken={},{},{},{},{},{},{}
  for j,u in ipairs(st.u) do hp[j]=u.hp; mp[j]=u.mp; sh[j]=u.sh; g[j]=(u.empty==1) and 0 or u.g; targets[j]=u.it; abyss[j]=(u.empty==1) and 0 or u.ay; broken[j]=u.dr==1 end
  if last_ev~=st.ev then last_ev=st.ev; last_event=0 end
  local hits={}
  for pos=last_event+1,#st.ev.list do
   local ev=st.ev.list[pos]
   if ev.k=="atk" or ev.k=="eatk" or ev.k=="eall" then
    for _,r in ipairs(ev.tg or {}) do hits[#hits+1]={actor=ev.a,target=r.i,damage=r.d or 0,shield=r.sh or 0,critical=r.c==1} end
   end
  end
  last_event=#st.ev.list
  return {n=st.n,actor=i,hp=hp,mp=mp,sh=sh,g=g,rng=st.rs,targets=targets,hits=hits,tk=st.tk,rd=st.rd,abyss=abyss,broken=broken}
 end
 local end0=B.end_turn
 B.end_turn=function(s,i,cost) end0(s,i,cost); trace[#trace+1]=dump(i) end
 local initial={}
 for i,u in ipairs(st.u) do initial[i]={hp=u.hp,mhp=u.mhp,mp=u.mp,mmp=u.mmp,sp=u.sp,cs=u.cs,de=u.de,ag=u.ag,cr=u.cr} end
 B.begin_ev(st); B.run(st)
 local guard=0
 while st.over=="" and guard<500 do
  guard=guard+1; local tgt
  for j=5,#st.u do if st.u[j].al==1 then tgt=j; break end end
  B.begin_ev(st); B.player(st,1,tgt); B.run(st)
 end
 B.end_turn=end0
 local rows=raid and out.raid_battles or out.battles
 rows[#rows+1]={party=party,foe=foe,bn=bn,seed=st.seed,initial=initial,trace=trace,result=st.over,raid=raid,fl=fl,ne=ne}
end end end
for _,n in ipairs({0,399,400,401}) do for _,alive_a in ipairs({true,false}) do for _,alive_e in ipairs({true,false}) do
 local st=fresh(); st.n=n
 for i,u in ipairs(st.u) do if (i<=4 and not alive_a) or (i>4 and not alive_e) then u.hp=0; u.al=0 end end
 B.check_end(st)
 out.ending[#out.ending+1]={n=n,alive_a=alive_a,alive_e=alive_e,result=st.over}
end end end
for _,id in ipairs(B.FOE_ORDER) do
 local f=B.FOES[id]
 if f.grade=="boss" or f.grade=="chief" or f.grade=="core" then
  for _,phase in ipairs({1,2}) do
   if phase==1 or f.ph2 then
    local run=B.run; B.run=function() end
    local st=B.fresh(1,nil,{enc={fl={id},fg={""},ne=1,star=1,raid=true},el=1})
    B.run=run; B.begin_ev(st)
    if phase==2 then st.u[5].hp=1; B.phase_check(st) end
    st.u[5].hp=st.u[5].mhp
    for _,rd in ipairs({0,20,21,30,40}) do
     st.rd=rd; local mult=B.foe_atk_mul(st,5)
     out.enrage[#out.enrage+1]={id=id,phase=phase,round=rd,mult=mult}
    end
    for ia,a in ipairs(B.DEF[5].acts) do for _,charged in ipairs({false,true}) do
     local u=st.u[5]; u.ia=ia; u.cq=charged and 1 or 0
     local n,name=B.raid_charge_info(st,5)
     out.raid[#out.raid+1]={id=id,phase=phase,ia=ia,charged=charged,turns=n or 0,name=name or ""}
    end end
   end
  end
 end
end
return out
