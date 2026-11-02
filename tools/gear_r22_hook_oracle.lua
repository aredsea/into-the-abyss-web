-- Test primitive ABI; not a second implementation of any gear hook.
P4_FIXTURES={}
local function cp(x)return json.decode(json.encode(x))end
local function record(st,k,...)st.calls[#st.calls+1]={k=k,args={...}}end
B.trait_line=function(st,i,txt,at)record(st,'trait_line',i,txt,at)end
B.setf=function(st,i,k,v,at)st.u[i][k]=v;record(st,'setf',i,k,v,at)end
B.heal=function(st,i,amt,at)
 record(st,'heal',i,amt,at,B.SKON or false)
 local u=st.u[i];local h=math.max(0,math.min(u.mhp-u.hp,math.floor(amt+.5)))
 u.hp=u.hp+h;return h
end
B.say=function(st,txt,at)record(st,'say',txt,at)end
B.push=function(st,x)record(st,'push',x)end
B.strike=function(st,i,d,at,unused,src)
 record(st,'strike',i,d,at,src or false)
 local u=st.u[i];u.hp=math.max(0,u.hp-d);if u.hp==0 then u.al=0 end
 return {i=i,d=d,kill=u.hp==0 and 1 or 0}
end
B.kill_credit=function(st,i,at)record(st,'kill_credit',i,at)end
B.badd=function(u,k,v,n)u.bf[k]={v=v,n=n}end
local defs={}
for i=1,7 do defs[i]={name='시험'..i,full='시험 인물 '..i,row=i==1 and '후열' or '전열',kind=i==5 and 'elite' or 'mob'}end
B.DEF=defs
local function state(mode)
 local st={u={},cur=mode%2==0 and 1 or 2,n=7,rs=12345,ev={T=2},calls={}}
 for i=1,7 do st.u[i]={hp=mode==1 and 20 or 90,mhp=100,mp=10,mmp=100,sh=mode==2 and 0 or 20,shT=1,sp=15,cs=40,de=25,cr=5,g=20000,al=1,dr=mode==3 and 0 or 1,chg=mode==2 and 0 or 1,tau=mode==2 and 0 or 2,x={},dot={{d=10,n=3,k=1},{d=11,n=2,k=1},{d=12,n=1,k=1}},bf={}} end
 if mode==4 then st.u[1].al=0;st.u[3].al=0 end
 return st
end
local function fixture(st,method,args,actor,sk,meta)
 B.ACT=actor and st.u[actor] or nil;B.SKON=sk
 local before=cp(st);local before_args=cp(args);local r
 if method=='gear_init' then B.gear_init(st,st.u[1],args[1])
 elseif method=='gear_buff' then r=B.gear_buff(table.unpack(args))
 elseif method=='gear_mpc' then r=B.gear_mpc(st.u[1],args[1])
 elseif method=='gear_dotchain' then B.gear_dotchain(st,st.u[args[1]],args[2])
 elseif method:sub(1,5)=='gear_' then r=B[method](st,table.unpack(args))
 else r=B.GH[method](st,table.unpack(args)) end
 if method=='gear_dot' then local a,b=B.gear_dot(before,args[1],args[2]);r={a,b or false} end
 P4_FIXTURES[#P4_FIXTURES+1]={method=method,args=before_args,after_args=args,act=actor or 0,skill=sk or false,before=before,value=cp(st),result=r==nil and 'nil' or r,defs=defs,meta=meta or ''}
end
local specs={{key='none'}}
for _,k in ipairs({'dmg','heal','shield','buff','dr','def','stat','crit','critdmg','spd','hp','mp','mpreg','reflect','dot','abyss','elite','lowhp','shdmg','healrecv','first','killmp','evade'}) do specs[#specs+1]={q=k}end
local seen={}
for _,id in ipairs(B.gear().order) do local e=B.gear().items[id].unique;if e and not seen[e.key] then seen[e.key]=true;specs[#specs+1]={e=e} end end
local methods={
 {'deal',{1,5,100,{}, {k='burst',name='혼돈 파동'}}}, {'crit',{1,5,{}}}, {'take',{1,100,5}},
 {'heal',{2,100}}, {'shield',{1,100}}, {'abyss_mul',{1,5,20}},
 {'hit_after',{1,5,{d=50,kill=0},{},3}}, {'damaged',{1,30,5,3}}, {'attacked',{1,5,{d=50},3}},
 {'turn_end',{1}}, {'enemy_dead',{5}}, {'round',{}}, {'abyss_after',{1,5,20,3,{}}},
 {'gear_kill',{1,3}}, {'gear_skill',{1,'taunt'}}, {'gear_skill',{1,'pshield'}}, {'gear_skill',{1,'heal'}},
 {'gear_mpc',{{id='snipe',mp=17}}}, {'gear_save',{1,3}}, {'gear_splash',{1,6,.35}},
 {'gear_dottick',{{1,1,2},3}}, {'gear_dotchain',{5,1}}, {'gear_begin',{1}}, {'gear_echo',{1,20}},
 {'gear_dot',{1,100}}, {'gear_shbreak',{1,30,5}}, {'gear_pecho',{1,3}}, {'gear_buff',{.15}}
}
for _,spec in ipairs(specs) do for mode=1,4 do for _,job in ipairs(methods) do
 local st=state(mode);local w=st.u[1]
 if spec.q then w.gq={[spec.q]=50} end
 if spec.e then w.gu={cp(spec.e)};st.gk={[spec.e.key]=true} end
 if mode~=2 then w.x={f1=7,ch=20,chk=6,sws=30,blc=2,hbk=6,scr=15,lmc=20,fzn=2,fzx=15,kg=1,lsn=2,wwn=2,adv=1000,sgs=15};st.gb={t=1,d=40};st.gt={t=1,e=5,d=40,x=50,n=7};st.gw={who=1,n=2,p=20} end
 local actor=1;local sk=job[1]=='gear_buff' and 'bless' or 'snipe'
 if mode==2 then actor=nil end
 if mode==3 then sk=nil end
 fixture(st,job[1],cp(job[2]),actor,sk,(spec.q or (spec.e and spec.e.key) or 'none')..':'..mode)
end end end
-- RNG failures and no gear cases, replayed calls for once-per-action latches.
for _,key in ipairs({'frenzy','heal_haste','guardian','echo'}) do for _,p in ipairs({0,100}) do
 local st=state(1);st.u[1].gu={{key=key,p=p,x=30,n=2}}
 for repeat_n=1,3 do
  local job=key=='frenzy' and methods[7] or (key=='heal_haste' and methods[4] or (key=='guardian' and methods[5] or methods[24]))
  fixture(st,job[1],cp(job[2]),1,'heal',key..':'..p..':'..repeat_n)
 end
end end
-- Every item, class/level validation and three-slot aggregation.
for _,id in ipairs(B.gear().order) do for _,lv in ipairs({1,20,40}) do
 local it=B.gear().items[id];local code=B.gear_code(id,8734567)
 local st=state(1);fixture(st,'gear_init',{{cls=it.cls,L=lv,eq={[it.slot]=code},forge={[code]={lv=5}}}},nil,nil,id..':'..lv)
end end
for _,cls in ipairs(B.CLASSES) do
 local eq={};for _,id in ipairs(B.gear().order) do local it=B.gear().items[id];if it.cls==cls.id and it.rarity=='legend' then eq[it.slot]=B.gear_code(id,77) end end
 fixture(state(1),'gear_init',{{cls=cls.id,L=40,eq=eq}},nil,nil,cls.id..':all')
 fixture(state(1),'gear_init',{{cls='bogus',L=40,eq=eq}},nil,nil,cls.id..':unknown_class')
end

local function unique(key)
 for _,id in ipairs(B.gear().order) do local e=B.gear().items[id].unique;if e and e.key==key then return cp(e) end end
end
local function equipped(key)
 local st=state(1);st.u[1].gu={unique(key)};st.gk={[key]=true};st.cur=1;return st
end
-- Persistent state and per-action/per-battle limits; each before state also goes
-- through the JSON save bridge, so these fixtures cover resume as well.
for _,key in ipairs({'wa_wall','wa_scar','wa_last','as_hunt','un_blood','gl_king','sa_ward'}) do
 local st=equipped(key)
 if key=='wa_wall' then
  fixture(st,'gear_skill',{1,'taunt'},1,'taunt',key..':arm')
  for n=1,5 do fixture(st,'turn_end',{1},nil,nil,key..':decay'..n) end
 elseif key=='wa_scar' then
  for n=1,4 do fixture(st,'damaged',{1,1000,5,3},nil,nil,key..':cap'..n) end
  for n=1,2 do fixture(st,'deal',{1,5,100,{},{}},1,'strike',key..':spend'..n) end
 elseif key=='wa_last' then
  fixture(st,'gear_save',{1,3},nil,nil,key..':save')
  fixture(st,'gear_save',{1,3},nil,nil,key..':once')
  fixture(st,'turn_end',{2},nil,nil,key..':other')
  fixture(st,'round',{},nil,nil,key..':alive_round')
  for n=1,4 do fixture(st,'turn_end',{1},nil,nil,key..':own'..n) end
  st=equipped(key);st.cur=5;fixture(st,'gear_save',{1,3},nil,nil,key..':enemy_turn')
  st.u[1].al=0;for n=1,3 do fixture(st,'round',{},nil,nil,key..':dead_round'..n) end
 elseif key=='as_hunt' then
  for n=1,5 do fixture(st,'gear_kill',{1,3},1,'strike',key..':limit'..n) end
  fixture(st,'turn_end',{1},nil,nil,key..':deferred')
  st.n=st.n+1;for n=1,2 do fixture(st,'deal',{1,5,100,{},{}},1,'strike',key..':bonus_all_hits'..n) end
  st.n=st.n+1;fixture(st,'deal',{1,5,100,{},{}},1,'strike',key..':expired')
 elseif key=='un_blood' then
  for n=1,5 do fixture(st,'gear_dottick',{{1,1,1},3},nil,nil,key..':limit'..n) end
  for n=1,2 do fixture(st,'deal',{1,5,100,{},{}},1,'strike',key..':bonus_all_hits'..n) end
  st.n=st.n+1;fixture(st,'deal',{1,5,100,{},{}},1,'strike',key..':expired')
 elseif key=='gl_king' then
  for n=1,6 do fixture(st,'enemy_dead',{5},nil,nil,key..':cap'..n) end
  st.u[1].al=0;fixture(st,'enemy_dead',{6},nil,nil,key..':dead_skip')
 else
  for n=1,7 do fixture(st,'take',{1,100,5},nil,nil,key..':cap'..n) end
  fixture(st,'deal',{1,5,100,{}, {k='burst'}},1,'burst',key..':spend')
  fixture(st,'deal',{1,5,100,{}, {k='burst'}},1,'burst',key..':spent')
 end
end
for _,key in ipairs({'pa_echo','party_dmg'}) do for _,dead in ipairs({false,true}) do
 local st=equipped(key);st.u[2].gu={unique(key)};st.u[2].gu[1][key=='pa_echo' and 'v' or 'x']=key=='pa_echo' and {80} or 80
 if dead then st.u[2].al=0 end
 if key=='pa_echo' then
  fixture(st,'gear_shbreak',{1,40,'fixed'},nil,nil,key..':fixed')
  fixture(st,'gear_pecho',{1,3},nil,nil,key..':max'..tostring(dead))
  fixture(st,'gear_pecho',{1,3},nil,nil,key..':once')
 else fixture(st,'deal',{1,5,100,{},{}},1,'strike',key..':max'..tostring(dead)) end
end end

for _,key in ipairs({'heal_haste','pr_bless','ar_chain'})do
 local st=equipped(key);st.u[1].gq={buff=50,heal=50}
 fixture(st,'gear_buff',{.15},1,true,key..':anonymous_skill')
 fixture(st,'heal',{2,50},1,true,key..':anonymous_heal')
 fixture(st,'gear_kill',{1,3},1,true,key..':anonymous_kill')
end
do
 local st=equipped('last_stand');st.u[1].hp=1
 fixture(st,'damaged',{1,30,5,3},nil,nil,'last_stand:below_threshold')
 for n=1,5 do fixture(st,'turn_end',{1},nil,nil,'last_stand:decay'..n)end
 fixture(st,'damaged',{1,30,5,3},nil,nil,'last_stand:once_per_battle')
 local g=B.gear();local code=B.gear_code(g.by.warrior.weapon[1],77)
 fixture(state(1),'gear_init',{{cls='priest',L=40,eq={weapon=code}}},nil,nil,'wrong_valid_class')
end
return true
