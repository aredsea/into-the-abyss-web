-- Inputs and observations only; canonical B functions supply all expected values.
local function fresh()
 local run=B.run; B.run=function() end
 local st=B.fresh(1,nil,{enc={fl={"apprentice_doll","apprentice_doll"},fg={"",""},ne=2,star=1,raid=false},el=1})
 B.run=run; st.cur=1; st.tk=0; st.rd=0
 for i,u in ipairs(st.u) do
  if i<=4 then B.DEF[i].cid="neutral"; B.DEF[i].clsid="warrior"; B.DEF[i].line="힘" end
  u.hp=1000; u.mhp=1000; u.sh=0; u.mp=0; u.mmp=100; u.rc=""; u.na=""; u.ln=""; u.gq=nil; u.gu=nil
  u.bf={}; u.x={}; u.sp=100; u.g=10000; u.tau=0; u.df=0; u.de=0; u.cs=100; u.ag=0; u.cr=0
 end
 B.ACT=nil; B.SKON=nil; B.begin_ev(st); return st
end
local out={mp={},ruin={},ruin_kill={},scar={},order={},round={},effects={},migration={},events={},display={},chips={},dots={},regen={},supplies={},delays={},walls={}}
do
 local st=fresh(); st.cur=2; st.u[1].g=0; st.u[1].hp=1
 B.edot_add(st,1,5,100,3); B.run(st)
 out.mp[1]={hp=st.u[1].hp,mp=st.u[1].mp,cur=st.cur,n=st.n}
end
for _,chain in ipairs({false,true}) do
 local st=fresh(); B.DEF[1].clsid="unsanctioned"; B.DEF[1].line="지능"
 for i=5,6 do st.u[i].hp=10000; st.u[i].mhp=10000; B.DEF[i].wk={} end
 if chain then st.u[1].gu={{key="un_chain",v={3,20}}} end
 for step=1,3 do
  B.RUN.ruin(st,1)
  local v=st.u[5]; local sum,n=0,0
  for _,d in ipairs(v.dot or {}) do sum=sum+d.d; if d.k==1 then n=n+1 end end
  out.ruin[#out.ruin+1]={chain=chain,step=step,hp=v.hp,amount=sum,count=n}
 end
end
do
 local st=fresh(); B.DEF[1].clsid="unsanctioned"
 for i=5,6 do st.u[i].hp=1 end
 B.RUN.ruin(st,1); out.ruin_kill[1]={count=#(st.u[5].dot or {})}
end
for _,fixed in ipairs({false,true}) do
 local st=fresh(); st.u[1].hp=1; st.u[1].gu={{key="wa_scar",v={50,50}}}
 B.strike(st,1,100,0,nil,fixed and "fixed" or 5)
 out.scar[#out.scar+1]={fixed=fixed,hp=st.u[1].hp,scar=st.u[1].x.scr or 0}
 local st=fresh(); st.u[1].hp=250; st.u[2].cs=100; B.DEF[2].cid="sorel"
 st.u[1].gu={{key="last_stand",x=20,n=2}}
 B.strike(st,1,100,0,nil,fixed and "fixed" or 5)
 out.order[#out.order+1]={fixed=fixed,hp=st.u[1].hp,stood=st.u[1].x.lsd==1,rescue=st.u[2].x.gt or 0}
end
do
 local st=fresh(); local v=st.u[5]
 for i=1,4 do B.dot_push(st,v,25,3,1) end
 B.dot_push(st,v,20,3,1)
 local sum=0; for _,d in ipairs(v.dot) do sum=sum+d.d end
 out.migration[1]={amount=sum,count=#v.dot}
end
for _,repeat_cast in ipairs({false,true}) do for rd=0,5 do
 local st=fresh(); B.DEF[1].cid="judith"; st.u[5].sp=101
 B.PRUN.judith(st,1,5,{name="test"})
 if repeat_cast then st.rd=1; B.PRUN.judith(st,1,5,{name="test"}) end
 st.rd=rd; B.round_tick(st)
 out.round[#out.round+1]={kind="judith",repeat_cast=repeat_cast,rd=rd,sp=st.u[5].sp,speed=B.spd(st,5),slow=st.u[5].x.slow~=nil}
end end
for _,dead_owner in ipairs({false,true}) do for n=1,3 do
 local st=fresh(); B.DEF[1].cid="persona"; st.u[2].hp=500; st.u[2].x.psrg={d=31,n=2,s=0}
 if dead_owner then st.u[1].hp=0; st.u[1].al=0 end
 for k=1,n do st.rd=k; B.round_tick(st) end
 out.round[#out.round+1]={kind="persona",dead_owner=dead_owner,n=n,hp=st.u[2].hp,left=st.u[2].x.psrg and st.u[2].x.psrg.n or 0}
end end
for _,g in ipairs({-1,0,1,100,101,9000}) do for _,elapsed in ipairs({0,1,2,90}) do
 local st=fresh(); B.DEF[2].cid="felice"; st.u[1].g=g; st.u[1].hp=1
 B.strike(st,1,100,0,nil,"fixed"); st.tk=elapsed; B.fire(st,"turn_end",3)
 out.round[#out.round+1]={kind="felice",g=g,elapsed=elapsed,hp=st.u[1].hp,gauge=st.u[1].g,used=st.u[2].x.rv or 0}
end end
for n=0,3 do
 local st=fresh(); st.gw={n=2,p=30,who=1}; st.u[1].hp=0; st.u[1].al=0
 for k=1,n do st.rd=k; B.round_tick(st) end
 out.round[#out.round+1]={kind="wall",n=n,left=st.gw and st.gw.n or 0}
end
for _,own in ipairs({false,true}) do
 local st=fresh(); B.ACT=own and st.u[1] or st.u[2]; B.badd(st.u[1],"atk",.2,2); B.ACT=nil
 for n=0,3 do
  if n>0 then B.end_turn(st,1,10000) end
  out.effects[#out.effects+1]={own=own,n=n,left=st.u[1].bf.atk and st.u[1].bf.atk.n or 0}
 end
end
local function events(st,input)
 input.rows={}; for i,d in ipairs(B.DEF) do input.rows[i]=d.row end
 local ev={}
 for _,e in ipairs(st.ev.list) do
  local targets={}; for _,t in ipairs(e.tg or {}) do targets[#targets+1]=t.i end
  ev[#ev+1]={k=e.k,a=e.a or 0,t=e.t,ht=e.ht or -1,targets=targets}
 end
 out.events[#out.events+1]={input=input,events=ev,T=st.ev.T}
end
for _,kind in ipairs({"guard","buff","debuff","heal","heal_full","protect","charge","dot","special","atk","all","summon"}) do
 local st=fresh(); st.cur=5; st.u[5].it=1; st.u[5].ia=1
 local act={kind=kind,name="test",m=1,stat="atk",amount=.2,turns=2,tick=.3,enemy="apprentice_doll",count=1}
 if kind=="heal_full" then act.kind="heal" else st.u[6].hp=500 end
 if kind=="all" then act.kind="atk"; act.all=true end
 B.DEF[5].acts={act}; B.enemy_turn(st,5)
 events(st,{kind="enemy",id=kind,act=act})
end
for _,id in ipairs({"atk","df","guard2","taunt","shield","pshield","snipe","burst","ruin","bless","heal","defdn","tonic","blood","rift","wave","release"}) do
 local st=fresh(); for i=1,4 do st.u[i].hp=500 end
 for i=5,6 do st.u[i].mhp=10000; st.u[i].hp=10000; st.u[i].ay=10000; B.DEF[i].wk={} end
 if id=="release" then B.release(st,1,false) else B.RUN[id](st,1,id=="tonic" and 2 or 5) end
 events(st,{kind="class",id=id})
end
for _,cid in ipairs({"levia","marceline","naran","teiris","haldric","erdene","bianca","saya","gerda","judith","urda","lynette","sorel","tika","hedwig","hildegard","felice","selva","gunhild","jorund","bargut","berenga","altan","colette","ornel","zahar","tove","miko","adeline","lavinia"}) do
 local st=fresh(); B.DEF[1].cid=cid
 for i=1,4 do st.u[i].hp=500 end
 for i=5,6 do st.u[i].mhp=10000; st.u[i].hp=10000; st.u[i].ay=10000; B.DEF[i].wk={} end
 local sk={id=B.PSK[cid].id,name="test"}
 B.cutin(st,1,sk.id,sk.name); B.PRUN[cid](st,1,B.CAST[cid].skill_tgt=="ally" and 2 or 5,sk)
 events(st,{kind="personal",id=cid})
end
for _,id in ipairs({"hp_s","mp_s","sh_s","antidote","bandage"}) do
 local st=fresh(); st.u[2].hp=500; st.u[2].mp=0
 if id=="bandage" then st.u[2].hp=0; st.u[2].al=0 end
 if id=="antidote" then B.edot_add(st,2,5,10,3) end
 if B.ITEMS[id] then B.it_apply(st,id,2); events(st,{kind="item",id=id}) end
end
for _,id in ipairs({"deplete","recover","cancel","adot","end","phase"}) do
 local st=fresh()
 if id=="deplete" then st.u[5].ay=10; B.abyss(st,1,5,100,"none",st.ev.T)
 elseif id=="recover" or id=="cancel" then st.cur=5; st.u[5].dr=1; st.u[5].cq=id=="cancel" and 1 or 0; B.lost_turn(st,5)
 elseif id=="adot" then B.edot_add(st,1,5,20,3); B.edot_tick(st,1)
 elseif id=="end" then for i=5,6 do st.u[i].al=0; st.u[i].hp=0 end; B.check_end(st)
 elseif id=="phase" then
  local run=B.run; B.run=function() end
  st=B.fresh(1,nil,{enc={fl={"tome_librarian"},fg={""},ne=1,star=1,raid=true},el=1}); B.run=run; B.begin_ev(st)
  st.u[5].hp=1; B.phase_check(st)
 end
 events(st,{kind="boundary",id=id})
end
do
 local st=fresh(); for i=5,6 do st.u[i].hp=10000; st.u[i].mhp=10000 end
 B.RUN.burst(st,1,5); B.e_charge(st,5,{name="test"}); B.release(st,1,false)
 st.u[5].cq=0; B.lost_turn(st,5)
 events(st,{kind="batch",id="charge_enemy_release_recover"})
end
for _,kind in ipairs({"atk","snipe","wave","burst","eatk","shield","taunt","def","oath","mark","rev","chg","cut","trait","deplete","recover","edef","ebuff","eall","edeb","eheal","item","esum","echg","ecut","phase","adot","end"}) do
 local st=fresh(); local target=(kind=="eatk" or kind=="eall" or kind=="adot") and 1 or 5
 local e={k=kind,a=(target==1) and 5 or 1,t=.15,ht=.6,nm="test",d=10,win=1,el="fire",tg={{i=target,d=10,sh=0,c=0,kill=0,ab=0,tags={},f="hp"},{i=(target==1) and 2 or 6,d=10,sh=0,c=0,kill=0,ab=0,tags={},f="hp"}}}
 local observed={}; local saved={}
 for name,fn in pairs({fx_result="hit",fx_dn="number",fx_cn="critical",fx_cutin="cut",fx_plaque="plaque"}) do
  local old=B[name]; saved[name]=old; local tag=fn
  B[name]=function(...)
   local args={...}; local at=(tag=="hit") and args[3] or ((tag=="cut") and args[5] or args[2])
   observed[#observed+1]={kind=tag,t=at}
   return old(...)
  end
 end
 local L={u={},panel="",party="",field="",cls={},vars={},bz={},icwf={},hit={},hk={},lun={},trg={},drn={},cuts={},muzzle={}}
 B.fx_event(st,e,L)
 for name,fn in pairs(saved) do B[name]=fn end
 out.display[#out.display+1]={event=e,observed=observed}
end
for _,kind in ipairs({"empty","down","shield","taunt","guard","charge","protect","hidden","silence","oath","rift","mark","fox","atk","def","adn","ddn","spd","sdn","bl","g2","bs","dot","edot","amp","seal","save"}) do
 local st=fresh(); local u=st.u[1]
 if kind=="down" then u.al=0 end
 if kind=="shield" then u.sh=21 end
 if kind=="taunt" then u.tau=2 end
 if kind=="guard" then u.df=1 end
 if kind=="charge" then u.chg=1 end
 if kind=="protect" then u.pt=2 end
 if kind=="hidden" then u.hid=1 end
 if kind=="silence" then u.sil="test" end
 if kind=="oath" then u.oath=2 end
 if kind=="rift" then u.rv=1 end
 if kind=="mark" then u.mk=1 end
 if kind=="fox" then u.fx=3 end
 if kind=="amp" then u.am=1.2 end
 if kind=="seal" then u.seal=1 end
 if kind=="save" then u.lf=1 end
 if kind=="dot" then u.dot={{d=10,n=2},{d=10,n=3}} end
 if kind=="edot" then B.edot_add(st,1,5,10,3) end
 if ({atk=1,def=1,adn=1,ddn=1,spd=1,sdn=1,bl=1,g2=1,bs=1})[kind] then B.badd(u,kind,.2,2) end
 local labels={}; for label in B.chips(st,1):gmatch('>(.-)</span>') do labels[#labels+1]=label end
 out.chips[#out.chips+1]={kind=kind,labels=labels,names={B.sn(1),B.sn(2)}}
end
for _,burst in ipairs({false,true}) do
 local st=fresh(); local v=st.u[5]; v.hp=10000; v.mhp=10000
 if burst then st.u[1].gu={{key="dot_burst",x=50}} end
 B.dot_push(st,v,10,2,1); B.dot_push(st,v,20,3,2)
 for n=1,4 do
  B.dot_tick(st,5); local sum=0; for _,d in ipairs(v.dot or {}) do sum=sum+d.d end
  out.dots[#out.dots+1]={burst=burst,n=n,hp=v.hp,count=#(v.dot or {}),amount=sum}
 end
end
do
 local st=fresh(); for i=1,2 do st.u[i].na="morgas" end; B.fire(st,"start")
 local v=st.u[5]; v.hp=10000; v.mhp=10000; B.dot_push(st,v,30,3,1); B.dot_tick(st,5)
 out.dots[#out.dots+1]={morgas=true,hp=v.hp,count=#v.dot,amount=v.dot[1].d}
end
do
 local st=fresh(); B.DEF[1].cid="adeline"; for i=1,4 do st.u[i].hp=100 end
 for n=1,6 do
  st.n=n
  if n==1 or n==3 then B.PRUN.adeline(st,1,0,{name="test"}) end
  B.fire(st,"turn_end",2)
  local rg=st.u[2].x.areg or {}; local left={}; for _,r in ipairs(rg) do left[#left+1]=r.n end
  out.regen[#out.regen+1]={n=n,hp=st.u[2].hp,left=left}
 end
end
for _,id in ipairs({"hp_s","mp_s","sh_s","bandage","antidote"}) do for _,humans in ipairs({0,3}) do for _,marento in ipairs({0,2}) do
 local st=fresh(); local u=st.u[2]; u.hp=500; u.mhp=1003; u.mp=0; u.mmp=103
 for i=1,humans do st.u[i].rc="human" end
 for i=1,marento do st.u[i].na="marento" end
 u.gq={healrecv=25}; st.u[1].gq={shield=20}
 B.fire(st,"start"); st.n=1; B.rbegin(st); B.ACT=st.u[1]; B.SKON=nil
 if id=="bandage" then u.hp=0; u.al=0; u.g=1; B.edot_add(st,2,5,10,3) end
 if id=="antidote" then B.edot_add(st,2,5,10,3); u.fx=3 end
 B.it_apply(st,id,2)
 out.supplies[#out.supplies+1]={id=id,humans=humans,marento=marento,seed=st.seed,hp=u.hp,mp=u.mp,shield=u.sh,g=u.g,clean=(not u.edot or #u.edot==0) and (u.fx or 0)==0,rng=st.rs}
end end end
do
 local st=fresh(); local u=st.u[2]; u.hp=500; u.mhp=1003; u.mp=0; u.mmp=103; u.gq={healrecv=25}; st.u[1].gq={shield=20}
 st.u[2].na="solen"; st.u[3].na="solen"; B.fire(st,"start"); st.n=1; B.rbegin(st); B.ACT=st.u[1]; B.SKON=nil
 B.it_apply(st,"sh_s",2)
 out.supplies[#out.supplies+1]={id="sh_s",humans=0,marento=0,solen=true,seed=st.seed,hp=u.hp,mp=u.mp,shield=u.sh,g=u.g,clean=true,rng=st.rs}
end
for _,boss in ipairs({false,true}) do
 local st=fresh(); st.u[5].rd=boss and 1 or 0; B.RUN.burst(st,1,5)
 out.delays[#out.delays+1]={boss=boss,g=st.u[5].g}
end
do
 local st=fresh(); for i=1,2 do st.u[i].hp=1; st.u[i].gu={{key="wa_last",v={20,2,30}}}; B.strike(st,i,10000,0,nil,"fixed") end
 B.strike(st,3,100,0,nil,"fixed"); out.walls[1]={hp=st.u[3].hp}
end
return out
