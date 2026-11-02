local out={}
local keys={atk='attack_up',def='defense_up',adn='attack_down',ddn='defense_down',spd='haste',sdn='slow',red20='contract',red25='duty',red='adeline_guard',g2='fortified_guard',bs='backstep',bl='blood',psguard='psguard',pscrit='pscrit',zdn='zdn'}
local function project(st)
 local us={}
 for i,u in ipairs(st.u) do
  local bf={}; for k,key in pairs(keys) do local v=u.bf[k]; if v then bf[key]={v.v,v.n,v.d==1} end end
  local dots={}; for _,d in ipairs(u.dot or {}) do dots[#dots+1]={d=d.d,n=d.n,by=d.by or 0,k=d.k or 0,c=d.c or 0,bld=d.bld and 1 or 0} end
  us[i]={hp=u.hp,mp=u.mp,sh=u.sh,g=u.g,ay=u.ay,broken=u.dr==1,sp=u.sp,buffs=bf,dots=dots,tau=u.tau>0,cover=u.oath or 0,charging=u.chg==1,regen={u.x.psrg and u.x.psrg.d or 0,u.x.psrg and u.x.psrg.n or 0}}
 end
 return {units=us,rng=st.rs}
end
for _,c in ipairs(cases) do
 local st=fresh(); st.seed=c.seed or 12345; st.n=1; B.rbegin(st)
 for i,u in ipairs(st.u) do
  if i>4 then u.ay=10000; u.ym=10000 end; B.DEF[i].row=(i%2==1) and '전열' or '후열'
  if i<=4 then B.DEF[i].clsid='warrior'; B.DEF[i].line='힘' else B.DEF[i].rules={}; B.DEF[i].grade='mob'; B.DEF[i].wk={}; u.rd=0; u.ph=0 end
 end
 local a,e=st.u[1],st.u[5]; local got
 if c.op=='speed' then
  for i=1,4 do st.u[i].rc=(i<=c.n) and c.race or '' end
  if not c.alive then st.u[4].al=0; st.u[4].hp=0 end
  a.sp=100.137; a.hp=333; B.DEF[1].clsid=c.cls; st.u[2].na='karashin'; B.DEF[2].clsid='alchemist'
  B.badd(a,c.buff>=0 and 'spd' or 'sdn',math.abs(c.buff),3)
  got={speed=B.spd(st,1),other=B.spd(st,2)}
 elseif c.op=='target' then
  for i=1,4 do local u=st.u[i]; u.al=(i<=c.alive) and 1 or 0; u.hp=(i<=c.alive) and 200 or 0 end
  B.DEF[5].acts={{kind=c.native_alias and 'atk' or c.kind,low=c.low}}; e.ia=1
  local rnd=B.rnd;if c.force_random then B.rnd=function()return c.force_random end end
  got={target=B.pick_target(st,5),rng=st.rs};B.rnd=rnd
 elseif c.op=='defense' then
  B.DEF[1].line=c.melee and '힘' or '지능'; e.hid=c.hidden and 1 or 0
  if not c.other then st.u[6].al=0;st.u[6].hp=0 end
  local r={}; if c.rule=='melee' or c.rule=='all' then r.melee_dr=.2 end
  if c.rule=='ranged' or c.rule=='all' then r.ranged_dr=.3 end
  if c.rule=='ally' or c.rule=='all' then r.dr_while_ally={enemy='apprentice_doll',mult=.5} end
  B.DEF[5].rules=c.rule=='none' and nil or r
  got={mult=B.foe_defense(st,1,5,{}, {})}
 elseif c.op=='kill' then
  for i=1,4 do st.u[i].rc=(i<=c.n) and 'demon' or '';st.u[i].mp=99 end
  a.hp=c.full and 1000 or 500; if not c.alive then a.hp=0;a.al=0 end
  B.kill_credit(st,1,0);got=project(st)
 elseif c.op=='double' then
  for i=1,4 do st.u[i].rc=(i<=c.n) and 'beast' or '' end
  if not c.alive then a.hp=0;a.al=0 end
  a.x.dbl=c.double and 1 or 0; B.GH.turn_end(st,1)
  got={g=a.g,double=a.x.dbl==1,rng=st.rs}
 elseif c.op=='personal' or c.op=='can' then
  B.DEF[1].cid=c.cid
  local v=c.variant
  for i=1,4 do st.u[i].hp=(v==1) and 1000 or 500;st.u[i].mp=100 end
  for i=5,6 do st.u[i].hp=10000;st.u[i].mhp=10000 end
  B.DEF[5].acts={{kind='atk',ic=(v==7) and 'spell' or 'attack'}}
  if v==2 then st.u[6].al=0;st.u[6].hp=0 end
  if v==3 then B.DEF[2].row='후열';B.DEF[3].row='후열';B.DEF[4].row='후열' end
  if v==4 then e.rd=1;B.DEF[5].grade='boss';e.ph=0 end
  if v==5 then e.hp=1;st.u[6].hp=1 end
  if v==6 then B.badd(st.u[2],'atk',.2,2);B.badd(st.u[2],'red20',.4,2) end
  if v==8 then B.badd(st.u[2],'adn',.2,2); B.badd(st.u[2],'ddn',.1,2) end
  if v==9 then a.sp=99;st.u[2].sp=101 end
  if v==10 then a.hp=100;a.seal=1;a.x.inch=1 end
  if v==11 then a.mp=0;a.sil=B.PSK[c.cid].id end
  local sk={id=B.PSK[c.cid].id,name='test',pv=true,cid=c.cid,mp=0}
  if c.op=='personal' then B.PRUN[c.cid](st,1, ((B.PSK[c.cid].tgt or B.CAST[c.cid].skill_tgt)=='ally') and 2 or 5,sk);got=project(st)
  else got={can=B.can_use(st,1,sk)} end
 elseif c.op=='strike' then
  a.hp=c.hp;a.sh=c.shield;a.df=c.guard and 1 or 0
  if c.priest then B.DEF[2].clsid='priest' end
  B.strike(st,1,100,0,nil,c.fixed and 'fixed' or 5);got=project(st)
 elseif c.op=='atk_mult' then
  B.DEF[5].grade=c.grade;B.DEF[5].rules={hp_atk={thr=.3,amount=.2}};st.raid=1;st.rd=c.rd;e.hp=c.hp
  B.badd(e,'atk',c.buff,2);got={mult=B.foe_atk_mul(st,5)}
 elseif c.op=='persona' then
  B.DEF[1].cid='persona';B.DEF[1].skill=c.raw
  for i=1,4 do st.u[i].hp=500 end
  if c.variant==1 then st.u[2].hp=0;st.u[2].al=0 end
  if c.variant==2 then st.u[6].pt=5 end
  if c.variant==3 then for i=5,6 do st.u[i].hp=1 end end
  if c.variant==4 then B.badd(e,'adn',.2,2) end
  if c.variant==5 then st.u[2].sh=9999 end
  local p=B.ps_parts(c.raw)
  B.PRUN.persona(st,1,(p and (p.kind=='attack' or p.kind=='volley')) and 5 or 2,{name='test'})
  got=project(st)
 elseif c.op=='persona_meta' then
	if c.level_case=='nan' then c.raw.prefix_lv.strike=0/0;c.raw.suffix_lv.bane=0/0 end
  local p,s,v=B.ps_parts(c.raw)
  got={value=v,parts={p or false,s or false},ready=B.ps_ready(c.raw),name=B.ps_name(c.raw),desc=B.ps_desc(c.raw),name_en=B.ps_name(c.raw,true),desc_en=B.ps_desc(c.raw,true),skill=B.ps_skill(c.raw) or false}
 elseif c.op=='enemy_speed' then
  e.hp=c.hp;e.sp=c.base;B.DEF[5].rules=c.rule and {hp_spd={thr=.3,amount=.2}} or {}
  B.badd(e,c.buff>=0 and 'spd' or 'sdn',math.abs(c.buff),3);got={speed=B.spd(st,5)}
 elseif c.op=='pack_speed' then
  for i=1,4 do st.u[i].na=(i<=c.n) and 'karashin' or '' end
  st.ks=c.kills;if not c.alive then st.u[4].al=0;st.u[4].hp=0 end
  got={speed=B.spd(st,1)}
 elseif c.op=='debuff' then
  if c.bits%2==1 then B.badd(e,'adn',.2,2) end
  if math.floor(c.bits/2)%2==1 then B.badd(e,'ddn',.2,2) end
  if math.floor(c.bits/4)%2==1 then e.fx=2 end
  if c.dot~='none' then e.dot={{d=10,n=2,k=(c.dot=='class') and 1 or nil,c=(c.dot=='corrosion') and 1 or nil,bld=(c.dot=='bleed') and 1 or nil}} end
  got={debuff=B.has_debuff(e)}
 elseif c.op=='counter' then
  local v=c.variant;B.DEF[5].rules={counter_when_guard={m=.6}};e.df=1;e.cs=100
  if v==1 then a.gq={evade=100} end
  if v==2 then B.badd(e,'atk',.5,3) end
  if v==3 then B.DEF[5].rules.hp_atk={thr=1,amount=.2} end
  if v==4 then B.DEF[5].grade='chief';e.hp=299 end
  if v==5 then B.DEF[2].cid='marceline';st.u[2].oath=1 end
  if v==6 then B.DEF[1].cid='saya';st.seed=1;B.rbegin(st) end
  if v==7 then st.cgd=1 end
  if v==8 then e.am=1.2 end
  if v==9 then B.badd(e,'adn',.2,3) end
  if v==10 then a.df=1 end
  if v==11 then a.sh=30 end
  if v==12 then B.DEF[5].grade='boss';st.raid=1;st.rd=40 end
  if v==13 then e.am=1.2;B.badd(e,'atk',.5,3);B.badd(e,'adn',.2,3) end
  if v==14 then e.cs=0 end
  if v==15 then a.al=0;a.hp=0 end
  if v==16 then e.al=0;e.hp=0 end
  B.foe_hit_after(st,1,5,{}, {el='none'},0);got=project(st)
 elseif c.op=='element_delay' then
  B.DEF[1].el=c.actor;B.DEF[5].rules={weak_hit_delay=c.rule}
  if c.boss then e.rd=1;B.DEF[5].grade='boss' end
  if c.lethal then e.hp=1 end
  B.attack(st,1,5,{m=1,brk=0,el=c.element,name='test'});got=project(st)
 end
 out[#out+1]={case=c.case,op=c.op,expected=got}
end
return out
