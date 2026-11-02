local H=B.__batch
local out={rows={},counts={}}
local function add(op,input,expected)
 out.rows[#out.rows+1]={op=op,input=input,expected=expected};out.counts[op]=(out.counts[op] or 0)+1
end
local function cp(v) return json.decode(json.encode(v)) end
for _,kind in ipairs({'mob','elite','boss','chief','unknown','',false,true,5}) do for _,lv in ipairs({-1,0,1,2.7,10,40,42}) do for _,star in ipairs({0,1,2,3,4,5,2.7,.5,false,true,'2','0x2'}) do
 add('legacy_stats',{kind=kind,lv=lv,star=star},B.enemy_stats(kind,lv,star))
end end end
for bits=0,15 do
 local pm={};for i=1,4 do pm[i]={id=(bits//2^(i-1))%2==1 and 'levia' or ''} end
 add('legacy_foes',{pm=pm},B.foes_for(pm))
 local st=fresh();for i=1,4 do st.u[i].al=(bits//2^(i-1))%2;B.DEF[i].line='지능' end
 add('syn',{bits=bits},B.syn(st))
end
for _,v in ipairs({false,true,0,1,'','missing'}) do add('rift',{value=v},B.rift_id_of(v) or false) end
for _,id in ipairs(B.RIFT_ORDER) do local r=B.RIFTS[id]
 for _,v in ipairs({id,r.name,r.quest_name}) do add('rift',{value=v},B.rift_id_of(v) or false) end
end
for f=1,80 do for _,stage in ipairs({0,1,2,3}) do
 add('floor_plan',{f=f,avg=10,n=4,stage=stage,seed=f},B.floor_plan(f,10,4,stage,f))
end end
B.compose(7,{floor=2,kind='battle',party_n=4})
local front=H.front_list
for a=1,#front do for b=1,#front do add('front',{fl=front,a=a,b=b},H.front_before(a,b)) end end
for bits=0,15 do
 local st=fresh();for j=5,6 do st.u[j].al=(bits//2^(j-5))%2;st.u[j].rd=(bits//2^(j-3))%2 end
 add('boss_half',{bits=bits},B.boss_half(st))
end
-- Corrosion replacement: every other line survives and the new line is last.
for _,value in ipairs({false,{}, {cor=2},{cor=7}}) do for _,live in ipairs({false,true}) do for _,stack in ipairs({-1,0,1,2,4}) do for _,cs in ipairs({0,.1,100.9}) do for _,def in ipairs({0,123.4}) do
 local st=fresh();st.K=47;st.u[1].cs=cs;st.u[5].de=def;st.u[5].x=cp(value)
 st.u[5].dot={{d=3,n=7,k=1,by=2},{d=2,n=4,bld=1,by=3}}
 if live then table.insert(st.u[5].dot,2,{d=100,n=1,c=1,by=4}) end
 local n,per=H.corrode(st,1,5,stack)
 add('corrode',{value=value,live=live,stack=stack,cs=cs,def=def},{n=n,per=per,x=st.u[5].x,dot=st.u[5].dot})
end end end end end
for _,other in ipairs({false,true}) do for _,action in ipairs({3,4}) do for _,target in ipairs({5,6}) do for _,stacks in ipairs({0,1,9,10,20}) do
 local st=fresh();st.n=4;st.u[1].x={gn=action,gt=5,gs=stacks};local tags={'keep'}
 local v=B.TR.gunhild.deal(st,1,other and 2 or 1,target,2,tags)
 add('gunhild',{other=other,action=action,target=target,stacks=stacks},{value=v or false,x=st.u[1].x,tags=tags})
end end end end
for _,other in ipairs({false,true}) do for _,g in ipairs({-100,0,500,3000,12000}) do for _,pull in ipairs({false,-.1,0,.3,2}) do
 local st=fresh();st.u[1].g=g;if pull then st.u[1].x.pull=pull end
 B.TR.bargut.turn_end(st,1,other and 2 or 1)
 add('bargut_end',{other=other,g=g,pull=pull},{g=st.u[1].g,pull=st.u[1].x.pull or false})
end end end
for _,value in ipairs({false,1,'bad',{}, {keep=7}}) do for _,self in ipairs({false,true}) do
 local st=fresh();st.tk=321;st.u[2].x=cp(value)
 local v=B.TR.felice.save(st,1,self and 1 or 2,.7)
 add('felice_save',{value=value,self=self},{value=v or false,x=st.u[2].x})
end end
for _,source in ipairs({1,2,5}) do for bits=0,31 do
 local st=fresh()
 for i=1,4 do
  st.u[i].bf=nil
  if i~=4 then
   st.u[i].bf={keep={v=.7,n=9,src=source}}
   for j,k in ipairs({'red20','red','atk','red25'}) do if (bits//2^(j-1))%2==1 then st.u[i].bf[k]={v=.2,n=3,src=(bits//16)%2==1 and source or i,keep='ok'} end end
  end
 end
 H.drop_caster_buffs(st,source);local us={};for i=1,4 do us[i]={bf=st.u[i].bf or false} end
 add('drop',{source=source,bits=bits},us)
end end
for _,live in ipairs({false,true}) do for _,morgas in ipairs({0,2,3,4}) do for count=0,8 do
 local st=fresh();for i=1,4 do st.u[i].na=i<=morgas and 'morgas' or '' end
 st.u[5].al=live and 1 or 0;st.u[5].dot={}
 for i=1,count do st.u[5].dot[#st.u[5].dot+1]={d=i,n=i+1,k=1,by=1};st.u[5].dot[#st.u[5].dot+1]={d=i,n=2,c=1,by=2} end
 B.dot_trim(st);add('trim',{live=live,morgas=morgas,count=count},st.u[5].dot)
end end end
-- The same input pack covers whole-return metadata, including tag order.
for bits=0,31 do for _,melee in ipairs({false,true}) do
 local st=fresh();local R={};B.DEF[1].line=melee and '힘' or '지능';B.DEF[6].name='인형'
 if bits%2==1 then R.melee_dr=.2 end
 if (bits//2)%2==1 then R.ranged_dr=.3 end
 if (bits//4)%2==1 then R.dr_while_ally={enemy='apprentice_doll',mult=.5} end
 st.u[5].hid=(bits//8)%2;st.u[6].al=(bits//16)%2;B.DEF[5].rules=R
 local tags={'keep'};local v=B.foe_defense(st,1,5,{},tags)
 add('defense_tags',{bits=bits,melee=melee},{value=v,tags=tags})
end end
for _,grade in ipairs({'mob','elite','chief','boss','core'}) do for _,hp in ipairs({299,300,301,1000}) do for _,rd in ipairs({20,21,30,40}) do for _,raid in ipairs({false,true}) do
 local st=fresh();st.rd=rd;st.raid=raid and 1 or 0;st.u[5].hp=hp;B.DEF[5].grade=grade;B.DEF[5].rules={hp_atk={thr=.3,amount=.2}};B.badd(st.u[5],'atk',.1,2)
 local v,tags=B.foe_atk_mul(st,5);add('attack_tags',{grade=grade,hp=hp,rd=rd,raid=raid},{value=v,tags=tags or false})
end end end end
for _,value in ipairs({-1,-.005,0,.004999999,.005,.2,.999999999,1.001,2.555}) do
 add('pct',{value=value},{a=H.pct_a(value),b=H.pct_b(value),foes=H.pct_foes(value)})
end
for _,value in ipairs({'','test','기술 (메모)','기술(바깥(안쪽)) 후속 (추가)','a (broken','a ) end','a\t (b) c','(a)(b)',false,12}) do
 add('short',{value=value},{a=H.sn(value),b=H.short(value)})
end
local names={'인형','unknown','{{user}}','A','7'}
for _,c in pairs(B.CAST) do names[#names+1]=c.name end
for _,f in pairs(B.FOES) do names[#names+1]=f.name end
table.sort(names)
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,name in ipairs(names) do
  B.DEF[1].name=name
  add('names',{name=name,lang=lang},{engine=H.nm_engine(1),foes=H.nm_foes(1),personal=H.nm_b(1),sub=H.sub(1)})
  for _,key in ipairs({'이가','을를','은는','와과','으로','이다','에게'}) do add('bp',{name=name,key=key,lang=lang},H.bp(name,key)) end
 end
end
B.LANG='ko'
for _,value in ipairs({'베었다','찔렀다','때렸다','쐈다','했다','다','','test',false,123,'갔다','좋다','그었다','솟다'}) do add('vconn',{value=value},B.vconn(value) or false) end
for _,k in ipairs({false,0,1,123.4}) do for _,el in ipairs({false,0,1,10,40}) do
 local st={K=k or nil,el=el or nil};add('Kc',{K=k,el=el},H.Kc(st))
end end
for _,kind in ipairs({'missing','race','nation'}) do for _,n in ipairs({0,1,2,3,4}) do for bits=0,15 do
 local st=fresh();for i=1,4 do st.u[i].rc=i<=n and 'elf' or '';st.u[i].na=i<=n and 'border' or '';st.u[i].al=(bits//2^(i-1))%2 end
 add('live_level',{kind=kind,n=n,bits=bits},B.tlv(st,kind=='race' and 'elf' or kind=='nation' and 'border' or 'missing'))
end end end
local nationals={'','경계도시','신성 세레디아 제국'}
for _,fl in ipairs({false,true}) do for bits=0,15 do
 local st=fresh();if not fl then st.fl=nil end
 for j=5,6 do st.u[j].g=j*7;st.u[j].al=(bits//2^(j-5))%2;B.DEF[j].rules={first_move=(bits//2^(j-3))%2==1} end
 B.foe_start(st);add('foe_start',{fl=fl,bits=bits},{st.u[5].g,st.u[6].g})
end end
for _,cycle in ipairs({false,true}) do for _,phase in ipairs({1,2}) do for _,turns in ipairs({false,-1,0,1,3}) do for _,seed in ipairs({1,12345,2147483646}) do
 local st=fresh();local u=st.u[5];st.rs=seed;u.pt=6;u.hid=1;u.ph=phase;u.tn=turns or nil;u.cwk={'keep'};B.DEF[5].wk={'keep'};B.DEF[5].ph2=cycle and {cycle=true} or nil
 B.foe_turn_start(st,5)
 add('foe_turn_start',{cycle=cycle,phase=phase,turns=turns,seed=seed},{pt=u.pt,hid=u.hid,tn=u.tn,cwk=u.cwk,weak=B.DEF[5].wk,rs=st.rs})
end end end end
for _,roll in ipairs({0,.5,.999999999,1}) do
 local st=fresh();local u=st.u[5];st.rs=12345;u.pt=6;u.hid=1;u.ph=2;u.tn=1;u.cwk={'keep'};B.DEF[5].wk={'keep'};B.DEF[5].ph2={cycle=true}
 local original=B.rnd;local calls=0;B.rnd=function() calls=calls+1;return roll end
 B.foe_turn_start(st,5);B.rnd=original
 add('foe_turn_bound',{roll=roll},{pt=u.pt,hid=u.hid,tn=u.tn,cwk=u.cwk,weak=B.DEF[5].wk,rs=st.rs,calls=calls})
end
for _,value in ipairs({'elf',false,0,{},'','bad'}) do for _,empty in ipairs({false,true}) do
 local st=fresh();for i=1,4 do st.u[i].rc=i<3 and 'elf' or '' end
 st.u[3].rc=value;st.u[3].empty=empty
 add('broken_level',{value=value,empty=empty},B.tlv(st,'elf'))
end end
for code=0,80 do
 local n=code;local st=fresh();local pm={}
 for i=1,4 do local nat=nationals[(n%3)+1];n=math.floor(n/3);pm[i]={id='persona',nat=nat};st.u[i].al=0 end
 st.pm=pm;add('exp_mult',{pm=pm},B.GH.exp(st))
end
return out
