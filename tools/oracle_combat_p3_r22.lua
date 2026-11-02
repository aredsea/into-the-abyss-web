-- Input/observation shell. Rules and expected values come from original B functions.
local ids={}; for id in pairs(B.CAST) do if B.PRUN[id] and id~="persona" then ids[#ids+1]=id end end; table.sort(ids)
local function fresh(cid,case)
 local party={cid}; for _,id in ipairs({"marceline","naran","teiris","haldric"}) do if id~=cid and #party<4 then party[#party+1]=id end end
 local pm={}; for i,id in ipairs(party) do pm[i]={id=id,cls=B.cls_of(B.CAST[id].cls).id,L=10} end
 local run=B.run; B.run=function() end
 local st=B.fresh(1,nil,{pm=pm,enc={fl={"apprentice_doll","apprentice_doll"},fg={"",""},ne=2,star=1,raid=false},el=10})
 B.run=run; B.ACT=nil; B.SKON=nil; st.cur=1; st.n=0; st.tk=0; st.rd=0; st.rs=1; st.seed=12345
 for i,u in ipairs(st.u) do
  u.hp=i<=4 and 600 or 5000; u.mhp=i<=4 and 1000 or 5000; u.al=1; u.mp=1000; u.mmp=1000; u.sh=0; u.shT=0; u.bf={}; u.x={}; u.rc="";u.na="";u.ln="";u.gu=nil;u.gq=nil; u.dot={}
  u.g=10000;u.sp=100;u.cs=50;u.ag=50;u.cr=7;u.de=30;u.rd=0;u.ay=100;u.ym=100;u.fx=0;u.mk=0;u.rv=0;u.df=0;u.tau=0;u.oath=0;u.oT=0;u.lf=0;u.ps=0
  if i>1 and i<=4 then B.DEF[i].cid="neutral"; B.DEF[i].clsid="warrior"; B.DEF[i].line="힘" end
  if i>4 then B.DEF[i].wk={}; B.DEF[i].kind="mob"; B.DEF[i].grade="mob"; B.DEF[i].rules={}; B.DEF[i].acts={{kind="atk",ic="spell",magic=true,m=1,name="test"}}; u.ia=1 end
 end
 if case==2 then st.u[1].hp=200;st.u[2].hp=150;st.u[5].hp=350; B.DEF[5].wk={B.DEF[1].el} end
 if case==3 then B.badd(st.u[2],"atk",.2,3);B.badd(st.u[2],"def",.15,3);B.badd(st.u[1],"atk",.1,3) end
 if case==5 then B.badd(st.u[5],"adn",.2,3); B.badd(st.u[5],"ddn",.15,3) end
 if case==6 then st.u[5].rd=1;B.DEF[5].kind="boss";B.DEF[5].grade="boss";B.DEF[5].wk={B.DEF[1].el} end
 return st,party
end
local buffkeys={atk="attack_up",def="defense_up",adn="attack_down",ddn="defense_down",spd="haste",red20="contract",red25="duty",red="adeline_guard",zdn="zdn",bl="blood",g2="fortified_guard"}
local function dump(st)
 local all={}
 for i,u in ipairs(st.u) do
  local buffs={}; for k,key in pairs(buffkeys) do local q=u.bf[k]; if q then buffs[key]={amount=q.v,turns=q.n,doubled=q.d==1} end end
  local dots={class=0,corrosion=0,bleed=0};for _,d in ipairs(u.dot or {}) do local key=d.c==1 and "corrosion" or d.bld==1 and "bleed" or "class"; dots[key]=dots[key]+d.d end
  local rg=u.x.rg or {};local regen=0;for _,r in ipairs(u.x.areg or {}) do regen=regen+r.a end
  all[i]={hp=u.hp,mp=u.mp,shield=u.sh,g=u.g,tau=u.tau,guard=u.df==1,mark=u.mk==1,fox=u.fx,rift=u.rv==1,once=u.seal==1,shield_turns=u.shT,buffs=buffs,dots=dots,regen=regen,sorel=rg.d or 0,sorel_turns=rg.n or 0}
 end
 return {units=all,rng=st.rs}
end
local out={personal={},traits={},class_skills={},deaths={},regen_mix={},dot_credit={},counters={}}
for _,cid in ipairs(ids) do for case=1,6 do
 local st,party=fresh(cid,case);local steps={}
 for step=1,(case==4 and 3 or 1) do
  local slot,sk;for j,s in ipairs(B.SK[1]) do if s.pv then slot=j;sk=s end end
  local can=B.can_use(st,1,sk)
  if can then B.begin_ev(st); B.player(st,slot,sk.tgt=="ally" and 2 or sk.tgt=="none" and 0 or 5) end
  steps[#steps+1]={can=can,state=dump(st)}
 end
 out.personal[#out.personal+1]={id=cid,case=case,party=party,steps=steps}
end end
local races={human="인간",elf="엘프",demon="악마",halfelf="하프엘프",nox="녹스",beast="수인"}
local nations={seredia="신성 세레디아 제국",karashin="대카라쉰",solen="솔렌 성왕국",marento="마렌토 공화국",naerin="나에린",morgas="모르가스 신관국",kern="케른 연방",border="경계도시"}
local tags={"human","elf","demon","halfelf","nox","beast","seredia","karashin","solen","marento","naerin","morgas","kern","border"}
local classes={"warrior","paladin","assassin","archer","sanctioned","unsanctioned","priest","alchemist","gladiator","chaos"}
for _,tag in ipairs(tags) do for tier=1,3 do for ci,cls in ipairs(classes) do
 local st,party=fresh("marceline",1)
 for i=1,4 do
  B.DEF[i].cid="neutral"; B.DEF[i].clsid=(i==1) and cls or "warrior"; B.DEF[i].line=(i==1 and (cls=="archer" or cls=="assassin")) and "민첩" or ((i==1 and (cls=="priest" or cls=="alchemist" or cls=="sanctioned" or cls=="unsanctioned" or cls=="chaos")) and "지능" or "힘")
  st.u[i].rc=(i<=tier and races[tag]) and tag or ""; st.u[i].na=(i<=tier and nations[tag]) and tag or ""
  st.u[i].ln=(tag=="beast" and i<=tier) and (i==1 and "dog" or "cat") or ""
 end
 st.u[1].hp=(ci%2==0) and 200 or 600; st.u[1].tau=2
 if ci%3==0 then st.u[5].hp=30 end
 st.n=1; B.rbegin(st);B.begin_ev(st);B.GH.start(st)
 B.badd(st.u[1],"adn",.2,3);B.badd(st.u[1],"def",.15,2)
 B.RUN.atk(st,1,5)
 B.strike(st,1,150,0,nil,"fixed");B.heal(st,1,31.5,0)
 if cls=="paladin" or cls=="priest" then B.party_shield(st,1,cls=="paladin" and 1.2 or 1.0,"test") end
 B.end_turn(st,1,10000)
 local state=dump(st);state.speeds={}; for i=1,6 do state.speeds[i]=B.spd(st,i) end
 out.traits[#out.traits+1]={tag=tag,tier=tier,cls=cls,ci=ci,race=races[tag] or "",nation=nations[tag] or "",state=state}
end end end
for _,cls in ipairs(classes) do
 local skills={{id="atk",mp=0},{id="df",mp=0}}; for _,sk in ipairs(B.KIT[cls]) do skills[#skills+1]=sk end
 for _,sk in ipairs(skills) do
  local st,party=fresh("marceline",1)
  for i=1,4 do B.DEF[i].cid="neutral";B.DEF[i].clsid=(i==1) and cls or "warrior" end
  st.u[1].hp=200; st.n=1;B.rbegin(st);B.begin_ev(st);B.ACT=st.u[1];B.SKON=sk.id;st.u[1].mp=st.u[1].mp-sk.mp
  local cost=B.RUN[sk.id](st,1,sk.tgt=="ally" and 2 or 5,sk);B.SKON=nil;B.end_turn(st,1,cost or 10000);B.ACT=nil
  out.class_skills[#out.class_skills+1]={cls=cls,id=sk.id,state=dump(st)}
 end
end
for _,cid in ipairs(ids) do
 local st,party=fresh(cid,3); B.DEF[2].cid="berenga"
 local slot,sk; for j,s in ipairs(B.SK[1]) do if s.pv then slot=j;sk=s end end
 if B.can_use(st,1,sk) then B.begin_ev(st);B.player(st,slot,sk.tgt=="ally" and 2 or sk.tgt=="none" and 0 or 5) end
 for hit=1,3 do B.strike(st,1,99999,0,nil,"fixed") end
 out.deaths[#out.deaths+1]={id=cid,party=party,case=3,state=dump(st)}
end
for _,order in ipairs({{1,2},{2,1}}) do
 local st,party=fresh("sorel",1);B.DEF[2].cid="adeline";B.DEF[2].clsid="priest";B.DEF[2].line="지능"
 local states={}
 for _,i in ipairs(order) do
  st.cur=i;st.n=st.n+1;B.rbegin(st);B.begin_ev(st);B.ACT=st.u[i];B.SKON="test"
  B.PRUN[B.DEF[i].cid](st,i,5,{name="test"});B.SKON=nil;B.end_turn(st,i,10000);B.ACT=nil;states[#states+1]=dump(st)
 end
 for r=1,3 do
  st.rd=r;B.round_tick(st);states[#states+1]=dump(st)
  st.cur=3;st.n=st.n+1;B.end_turn(st,3,10000);states[#states+1]=dump(st)
 end
 out.regen_mix[#out.regen_mix+1]={order=order,states=states}
end
for _,reverse in ipairs({false,true}) do for _,dead in ipairs({false,true}) do
 local st,party=fresh("marceline",1);for i=1,4 do B.DEF[i].cid="neutral";st.u[i].mp=0;st.u[i].rc=i<=3 and "demon" or "" end
 st.u[5].hp=50;st.u[5].dot=reverse and {{d=80,n=1,c=1,by=2},{d=70,n=1,k=1,by=1}} or {{d=70,n=1,k=1,by=1},{d=80,n=1,c=1,by=2}}
 if dead then st.u[reverse and 1 or 2].hp=0;st.u[reverse and 1 or 2].al=0 end
 B.begin_ev(st);B.dot_tick(st,5)
 out.dot_credit[#out.dot_credit+1]={reverse=reverse,dead=dead,state=dump(st)}
end end
for _,kind in ipairs({"saya","kern"}) do for seed=1,60 do
 local st,party=fresh(kind=="saya" and "saya" or "jorund",1)
 if kind=="kern" then for i=1,4 do B.DEF[i].cid="neutral";st.u[i].na=i<=3 and "kern" or "" end end
 st.seed=seed*7919;st.n=1;B.rbegin(st);B.begin_ev(st);st.u[5].it=1
 B.e_attack(st,5,B.DEF[5].acts[1])
 out.counters[#out.counters+1]={kind=kind,seed=seed,party=party,state=dump(st)}
end end
do
 local st=fresh("sorel",1);st.cur=2;st.u[2].hp=300;B.DEF[2].clsid="gladiator";st.n=1;B.rbegin(st);B.begin_ev(st);B.ACT=st.u[2]
 B.RUN.blood(st,2);B.end_turn(st,2,10000);B.ACT=nil;out.blood_sorel=dump(st)
end
return out
