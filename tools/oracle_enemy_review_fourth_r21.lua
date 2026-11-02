-- Run canonical hooks; fixtures only set inputs and observe engine output.
local function fresh()
  local run=B.run; B.run=function() end
  local st=B.fresh(1,nil,{enc={fl={"apprentice_doll"},fg={""},ne=1,star=1,raid=false},el=1})
  B.run=run; st.seed=1; st.n=0; st.cur=1
  for i=1,4 do
    local d,u=B.DEF[i],st.u[i]; d.cid="neutral"; d.clsid="sanctioned"
    u.hp=1000; u.mhp=1000; u.sh=0; u.rc=""; u.na=""; u.ln=""; u.gq=nil; u.gu=nil; u.bf={}; u.x={}; u.tau=0
    u.df=0; u.de=40; u.lf=0; u.ps=0; u.g=0; u.chg=0
  end
  st.K=40; B.ACT=nil; B.begin_ev(st)
  return st
end
local out={strikes={},seals={},saves={},revive={},revive_scans={},saya={},zahar={}}
for _,fixed in ipairs({true,false}) do
  for _,cid in ipairs({"neutral","hildegard"}) do
    for _,raw in ipairs({1,7,10,11,99,100,101}) do
      for _,stance in ipairs({0,1}) do
        local st=fresh(); local u=st.u[1]; B.DEF[1].cid=cid; u.df=stance
        if cid=="hildegard" then B.badd(u,"red25",.25,3) end
        B.badd(u,"psguard",.1,3)
        B.strike(st,1,raw,0,nil,fixed and "fixed" or 5)
        out.strikes[#out.strikes+1]={fixed=fixed,cid=cid,raw=raw,stance=stance,loss=1000-u.hp}
      end
    end
  end
end
-- Slot order matters: Colette does not stop later personal hooks such as Saya.
for _,colette in ipairs({1,2,4}) do for _,sealed in ipairs({true,false}) do
  for _,magic in ipairs({true,false}) do for _,saya in ipairs({true,false}) do
    local st=fresh(); local target=colette==1 and 2 or 1; local u=st.u[target]
    B.DEF[colette].cid="colette"; if saya then B.DEF[target].cid="saya" end
    u.gq={evade=15}; st.u[5].x.seal=sealed and st.tk+100000 or 0
    B.DEF[5].acts={{kind="dot",name="dot",m=1,tick=.3,turns=3,magic=magic}}; st.u[5].ia=1; st.u[5].it=target
    B.enemy_turn(st,5)
    out.seals[#out.seals+1]={colette=colette,target=target,sealed=sealed,magic=magic,saya=saya,stack=#(u.edot or {})>0,rng=st.rs,next=st.u[5].it}
  end end
end end
for _,kind in ipairs({"wall_own","wall_other","marceline","priest"}) do
  local st=fresh(); local u=st.u[1]; u.hp=50
  if kind=="wall_own" or kind=="wall_other" then
    u.gu={{key="wa_last",v={20,2,30}}}; if kind=="wall_other" then st.cur=2 end
  else
    u.gq={shield=20}; u.gu={{key="guardian",p=100,x=50}}
    if kind=="marceline" then B.DEF[1].cid="marceline"
    else B.DEF[2].clsid="priest"; st.u[2].gu={{key="pr_miracle",v={60,15}}} end
  end
  B.rbegin(st); local before=st.rs
  B.edot_add(st,1,5,100,3); B.edot_tick(st,1)
  out.saves[#out.saves+1]={kind=kind,hp=u.hp,shield=u.sh,rng_unchanged=st.rs==before,wall=st.gw and st.gw.n or 0}
end
do
  local st=fresh(); local u=st.u[1]; u.hp=50; B.DEF[2].cid="felice"
  B.edot_add(st,1,5,100,3); local down=B.edot_tick(st,1)
  out.revive={down=down,hp=u.hp,alive=u.al==1}
  B.fire(st,"turn_end",2)
  out.revive.after_scan_hp=u.hp; out.revive.after_scan_alive=u.al==1
end
for _,ev in ipairs({"turn_end","evade","enemy_end"}) do
  local st=fresh(); local u=st.u[1]; u.hp=50; B.DEF[2].cid="felice"
  B.edot_add(st,1,5,100,1); B.edot_tick(st,1)
  if ev=="evade" then B.chain(st,"evade",nil,3,5) else B.fire(st,ev,ev=="turn_end" and 2 or 5) end
  out.revive_scans[#out.revive_scans+1]={event=ev,hp=u.hp}
end
for seed=1,20 do
  local st=fresh(); st.seed=seed; local u=st.u[1]; B.DEF[1].cid="saya"
  B.DEF[5].acts={{kind="dot",name="dot",m=1,tick=.3,turns=3,magic=true}}; st.u[5].ia=1; st.u[5].it=1
  B.enemy_turn(st,5)
  out.saya[#out.saya+1]={seed=seed,stack=#(u.edot or {})>0,rng=st.rs,next=st.u[5].it}
end
for _,fixed in ipairs({true,false}) do for _,z in ipairs({0,.2}) do for _,de in ipairs({31.350784,40}) do
  local st=fresh(); local u=st.u[1]; B.DEF[1].cid="zahar"; u.de=de; B.badd(u,"zdn",z,2)
  B.strike(st,1,100,0,nil,fixed and "fixed" or 5)
  out.zahar[#out.zahar+1]={fixed=fixed,zdn=z,defense=u.de,k=st.K,loss=1000-u.hp}
end end end
return out
