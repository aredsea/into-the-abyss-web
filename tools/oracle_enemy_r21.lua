-- Controlled enemy-turn replays. Real 20/30/31 Lua executes every action.
-- Neutral allies suppress character/race/equipment hooks, shared by the GD fixture.
local out={enemies=0,samples={},silence={}}
local keys={atk="attack_up",def="defense_up",spd="haste",adn="attack_down",ddn="defense_down",sdn="slow"}
local function dump(st)
 local a={}
 for i,u in ipairs(st.u) do
  local d=B.DEF[i]; local fx={}
  for k,v in pairs(u.bf or {}) do
   if keys[k] then fx[keys[k]]={amount=v.v,turns=v.n,source=v.src or 0} end
  end
  if u.bt>0 then fx.enemy_attack_self={amount=u.am-1,turns=u.bt,source=0} end
  local dots={} for _,v in ipairs(u.edot or {}) do dots[#dots+1]={amount=v.d,turns=v.n,by=v.by} end
  a[i]={foe=d.foe or "",grade=d.grade or "",hp=u.hp,mhp=u.mhp,attack=u.cs,defense=u.de,speed=u.sp,
   remaining=u.g,gauge=u.ay,max=u.ym,phase=u.ph==2 and 2 or 1,act_index=u.ia-1,target=u.it,
   charged=u.cq==1,broken=u.dr==1,weak=d.wk or {},effects=fx,dots=dots,
   turns=u.tn or 0,protect=u.pt or 0,hidden=u.hid==1,guard=u.df==1,shield=u.sh,
   shield_turns=u.shT,silence=u.sil and u.sil~="" and "personal" or "",row=d.row}
  if u.sil and u.sil~="" and u.sil=="burst" then a[i].silence="burst" end
 end
 return a
end
for ordinal,id in ipairs(B.FOE_ORDER) do
 out.enemies=out.enemies+1
 local enc={fl={id,"apprentice_doll","rusted_shieldman"},fg={"","",""},ne=5,star=1,raid=false,zk="academy_upper",kind="battle"}
 local run=B.run; B.run=function() end
 local st=B.fresh(1,nil,{enc=enc,el=1,pm=B.DEFAULT_PM})
 B.run=run; st.seed=12345+ordinal*7919; st.n=0
 for i=1,4 do
  B.DEF[i]={name="a"..i,full="a"..i,cid="neutral",clsid="sanctioned",line="힘",row=i<=2 and "전열" or "후열",wk={}}
  B.SK[i]=B.member_skills(B.DEF[i])
  local u=st.u[i]; u.hp=({100000,60000,30000,80000})[i]; u.mhp=100000; u.de=20; u.cs=10
  u.rc=""; u.na=""; u.ln=""; u.bx=0; u.gq=nil; u.gu=nil; u.bf={}; u.sh=0
 end
 for i=5,7 do st.u[i].hp=math.max(1,math.floor(st.u[i].mhp*({.7,.8,.2})[i-4])) end
 B.rbegin(st)
 for i=5,7 do st.u[i].it=B.pick_target(st,i) end
 local count=math.max(12,#B.DEF[5].acts*3)
 for turn=1,count do
  B.begin_ev(st)
  -- Each sixth turn exercises taunt; dead allies are excluded on the tenth.
  st.u[2].tau=(turn%6==0) and 2 or 0
  st.u[4].al=(turn==10) and 0 or 1; if turn==10 then st.u[4].hp=0 else st.u[4].hp=80000 end
  -- Explicit phase transition, and a charge break, exercise both paths.
  if turn==7 and B.DEF[5].ph2 then
   st.u[5].hp=math.floor(st.u[5].mhp*.4); B.rbegin(st); B.phase_check(st)
  end
  if st.u[5].cq==1 and turn%2==0 then B.deplete(st,5,0) end
  B.begin_turn(st,5)
  local before=dump(st)
  local n=st.n; local rng=st.rs
  if st.u[5].dr==1 then B.lost_turn(st,5) else B.enemy_turn(st,5) end
  B.end_turn(st,5,10000)
  out.samples[#out.samples+1]={id=id,turn=turn,seed=st.seed,action_no=n,input=before,rng=rng,output=dump(st),output_rng=st.rs}
  -- Advance holder lifetimes and DOTs through their real Lua turn functions.
  for i=1,4 do
   if st.u[i].al==1 then
    B.begin_turn(st,i)
    if st.u[i].edot and #st.u[i].edot>0 then B.edot_tick(st,i) end
    B.end_turn(st,i,10000)
   end
  end
  for i=6,#st.u do if st.u[i].al==1 then B.begin_turn(st,i); B.end_turn(st,i,10000) end end
 end
end
local classes={"warrior","assassin","archer","sanctioned","unsanctioned","paladin","priest","alchemist","gladiator","chaos"}
for _,cls in ipairs(classes) do for seed=1,20 do
 local run=B.run; B.run=function() end
 local st=B.fresh(1,nil,{enc={fl={"echo_of_bottom"},fg={""},ne=1,star=1,raid=false},el=1})
 B.run=run; st.seed=seed*7919; st.n=0
 for i=1,4 do
  B.DEF[i]={cid="neutral",clsid=cls,name="a"..i}; B.SK[i]=B.member_skills(B.DEF[i]); st.u[i].sil=""; st.u[i].al=1
 end
 B.DEF[5].acts={{kind="special",fx="silence",name="silence"}}
 B.begin_ev(st)
 B.enemy_turn(st,5)
 for i=1,4 do if st.u[i].sil and st.u[i].sil~="" then
  out.silence[#out.silence+1]={class=cls,seed=st.seed,target=i,skill=st.u[i].sil=="p_neutral" and "personal" or st.u[i].sil}
 end end
end end
return out
