local samples={}
local function make(id)
 local run=B.run;B.run=function()end
 local st=B.fresh(1,nil,{enc={fl={id,'apprentice_doll','rusted_shieldman'},fg={'','',''},ne=5,star=1,raid=false,zk='academy_upper'},el=1})
 B.run=run;st.seed=12345;st.n=0;st.cur=5
 for i=1,4 do
  B.DEF[i]={name='a'..i,full='a'..i,cid='neutral',clsid='sanctioned',line='힘',row=i<=2 and '전열' or '후열',wk={}}
  B.SK[i]=B.member_skills(B.DEF[i]);local u=st.u[i]
  u.hp=100000;u.mhp=100000;u.de=20;u.cs=10;u.rc='';u.na='';u.ln='';u.bx=0;u.gq=nil;u.gu=nil;u.bf={};u.sh=0
 end
 B.rbegin(st);B.begin_ev(st);return st
end
local function record(st,op,input)
 local pre=dump(st);local rs=st.rs
 if op=='summon' then B.e_summon(st,5,{name='test',enemy='apprentice_doll',count=input.count})
 elseif op=='phase' then B.phase_check(st)
 elseif op=='guard' then B.strike(st,5,input.raw,0,nil,'fixed');B.phase_check(st)
 elseif op=='cancel' then B.lost_turn(st,5) end
 samples[#samples+1]={id=input.id,turn=1,seed=st.seed,action_no=0,input=pre,rng=rs,op=op,params=input,output=dump(st),output_rng=st.rs}
end
for _,variant in ipairs({'empty','full','dead_before_empty','two_dead','just_died'}) do for _,count in ipairs({0,1,2,3,9}) do
 local st=make('raging_lecturer')
 if variant~='empty' then
  B.summon_one(st,5,'apprentice_doll');B.summon_one(st,5,'apprentice_doll')
  if variant=='dead_before_empty' then st.u[8].al=0;st.u[8].hp=0;st.fl[5]='';st.fg[5]='';B.DEF[9]=B.foe_def(st,5);st.u[9]=B.blank_u(st,9)
  elseif variant=='two_dead' then for i=8,9 do st.u[i].al=0;st.u[i].hp=0 end
  elseif variant=='just_died' then st.u[8].al=0;st.u[8].hp=0 end
 end
 B.begin_ev(st)
 if variant=='just_died' then B.setf(st,8,'hp',0,0) end
 record(st,'summon',{id='raging_lecturer',variant=variant,count=count})
end end
for _,id in ipairs(B.FOE_ORDER) do if B.FOES[id].ph2 then
 for _,ratio in ipairs({0,.49,.5,.500001,1}) do
  local st=make(id);st.u[5].hp=math.max(1,B.floor(st.u[5].mhp*ratio));record(st,'phase',{id=id,ratio=ratio})
 end
 for _,raw in ipairs({1,100000000}) do
  local st=make(id);record(st,'guard',{id=id,raw=raw})
 end
end end
for _,id in ipairs(B.FOE_ORDER) do if B.FOES[id].rules and B.FOES[id].rules.break_self then
 for _,ratio in ipairs({.01,.5,1}) do
  local st=make(id);local u=st.u[5];u.cq=1;u.dr=1;u.ay=0;u.hp=math.max(1,B.floor(u.mhp*ratio));record(st,'cancel',{id=id,ratio=ratio})
 end
end end
return samples
