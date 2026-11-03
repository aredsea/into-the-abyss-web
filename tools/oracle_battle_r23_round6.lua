local H=B.__batch
local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,input,expected)
 out.rows[#out.rows+1]={op=op,input=cp(input),expected=cp(expected)}
 out.counts[op]=(out.counts[op] or 0)+1
end
local function defs()
 local a={};for i=1,16 do a[i]=B.DEF[i] or false end;return a
end
out.constants={classes=B.CLS,cast=B.CAST,attack=B.ATK,kits=B.KIT,defend=B.DF,personal=B.PSK,legacy=B.EDEF,foes=B.FOES,grades=B.GRADES,version=B.VER,level_max=B.LEVEL_MAX}
add('unit0',{},H.unit0())
local ids={'persona','missing',''}
for k in pairs(B.CAST) do ids[#ids+1]=k end;table.sort(ids)
local classes={'missing',''};for k in pairs(B.CLS) do classes[#classes+1]=k end;table.sort(classes)
for _,id in ipairs(ids) do for _,cls in ipairs(classes) do
 local m={id=id,cls=cls,L=17,skill={pre='all',suf='heal',lv={}}}
 local d=B.member_def(m)
 add('member_def',{member=m},d)
 add('member_skills',{definition=d},B.member_skills(d))
end end
for _,cid in ipairs({'persona','missing','levia'}) do
 for _,value in ipairs({false,{}, {pre='all',suf='heal',lv={}}, {pre='strike',suf='fire',lv={strike=3,fire=2}}}) do
  local d=B.member_def({id=cid,cls='warrior',L=1,skill=value})
  add('member_skills',{definition=d},B.member_skills(d))
 end
end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,id in ipairs({'missing','', 'apprentice_doll','rusted_shieldman','demon_king'}) do
  for _,grade in ipairs({'','minion','chiefb','eliteb','boss','unknown'}) do for _,level in ipairs({1,40,99}) do
   for _,deep in ipairs({0,1}) do
    local s={fl={id},fg={grade},el=level,dk=deep,u={{},{},{},{},{ph=2,cwk={'fire','ice'}}}}
    add('foe_def',{state=s,slot=1,lang=lang},B.foe_def(s,1))
   end
  end end
 end
end
B.LANG='ko'
for _,cls in ipairs(classes) do for _,pid in ipairs({'atk','df','missing',''}) do for _,cur in ipairs({0,1,4}) do
 local s={pm={{id='levia',cls=cls,L=1},{id='',cls='',L=1},{id='missing',cls='warrior',L=40},{id='persona',cls='warrior',L=1}},fl={'apprentice_doll',''},fg={'',''},ne=2,el=40,u={},pend=99,pid=pid,cur=cur}
 for i=1,16 do B.DEF[i]={stale=true} end
 local original=cp(s);B.bind(s)
 add('bind',{state=original,original_pend=99}, {state=s,defs=defs(),skills={B.SK[1],B.SK[2],B.SK[3],B.SK[4]}})
 for i=1,4 do for _,key in ipairs({'atk','df','missing','p_levia'}) do add('sk_slot',{skills=B.SK,index=i,id=key},{value=B.sk_slot(i,key) or false}) end end
end end end
for _,level in ipairs({1,40,99}) do
 local s={el=level};for i=1,16 do B.DEF[i]={stale=true} end;B.bind_foes(s)
 add('bind_legacy',{state=s},defs())
end
for bits=0,31 do
 local s={ver=2,u={},pm={{id='levia',cls='chaos',L=1},{id='persona',cls='warrior',L=1,race='인간',nat='경계도시'},{id='',cls='',L=1},{id='missing',cls='missing',L=1}},keep={n=7}}
 for i=1,8 do
  s.u[i]={hp=13+i,rc=bits%2==0 and false or 'keep',ln=math.floor(bits/2)%2==0 and 4 or 'line',na=math.floor(bits/4)%2==0 and {} or 'nation',bx=math.floor(bits/8)%2==0 and '3' or 9,x=math.floor(bits/16)%2==0 and false or {keep=3}}
 end
 if bits==0 then s.u[2]=false;s.pm[4]=false end
 local before=cp(s);add('migrate',{state=before},B.migrate(s))
end
do
 local s={ver=2,u={},pm={unused=true},keep=13};for i=1,8 do s.u[i]={hp=i,rc=false,ln=false,na=false} end
 add('migrate',{state=cp(s)},B.migrate(s))
end
for _,v in ipairs({1,2,3,4}) do for _,n in ipairs({0,4,7,8,9}) do
 local s={ver=v,u={},pm={},keep=13};for i=1,n do s.u[i]={hp=1} end
 add('migrate',{state=cp(s)},B.migrate(s))
end end
for _,h in ipairs({false,-1,0,1,1.9,99,101,'12.9','bad','0x10'}) do
 for _,m in ipairs({false,-1,0,1,10.9,999,'7.9','bad'}) do for empty=0,1 do
  local s={u={}};for i=1,4 do s.u[i]={hp=90,mhp=100,mp=9,mmp=10,al=1,g=100,empty=i==4 and empty or 0,keep=i} end
  local carry={hp={h,h,h,h},mp={m,m,m,m}};local before=cp(s)
  B.apply_carry(s,carry);add('carry',{state=before,carry=carry},s)
 end end
end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,dn in ipairs({false,{kind='boss'},{stage=2},{stage=1},{kind='explore'}}) do
  for _,place in ipairs({false,'','<test>','대던전'}) do
   local s=fresh();s.fl={'a','b'};s.dn=dn or nil;s.place=place or nil
   B.DEF[5].name='고블린';B.DEF[6].name='고블린';B.DEF[7]={name='x',empty=true};B.DEF[8]={name='y'}
   s.u[7]={empty=0};s.u[8]={empty=1}
   add('result_context',{state=s,defs=defs(),lang=lang},{value=B.result_context(s) or false})
  end
 end
 local s=fresh();s.fl=nil;add('result_context',{state=s,defs=defs(),lang=lang},{value=B.result_context(s) or false})
 for _,verb in ipairs({'베었다','찔렀다','화살을 쐈다','마법을 썼다','때린다','찔렀음',''}) do
  for bits=0,31 do for _,slot in ipairs({2,5}) do
   local s=fresh();local r={i=slot,d=17,sh=bits%2==1 and 7 or 0,ab=math.floor(bits/2)%2==1 and 5 or 0,kill=math.floor(bits/4)%2,c=0,tags=math.floor(bits/8)%2==1 and {'치명','약점'} or {}}
   local opt={vb=verb,sk=math.floor(bits/16)%2==1 and '기술' or nil}
   add('dmg_line',{state=s,defs=defs(),result=r,options=opt,lang=lang},B.dmg_line(s,1,r,opt))
  end end
 end
end
B.LANG='ko'
-- Direct native hooks: every output includes the event payload, field timeline,
-- journal, RNG-independent timer and target state, not only resulting HP.
for bits=0,15 do for _,tick in ipairs({0,10,100}) do for used=0,1 do
 local s=fresh();for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i;B.DEF[i].cid=i==1 and 'felice' or 'missing';s.u[i].x={} end
 s.tk=tick;s.u[1].x.rv=used
 for i=2,4 do local u=s.u[i];u.al=math.floor(bits/2^(i-2))%2;u.hp=u.al==1 and 90 or 0;u.mhp=100;u.g=bits>=8 and 0 or 100;u.sp=100;u.sh=17;u.shT=3;u.bf={atk={v=.2,n=2},pscrit={v=.2,n=2}};u.tau=2;u.df=1;u.mk=1;u.chg=1;u.x={dtk=i==3 and -1 or 0,keep=i};u.dot={{d=3,n=2,k=1}} end
 if bits==0 and used==0 then s.u[2].x=false end
 B.begin_ev(s);local before=cp(s);H.felice_scan(s,1)
 local us={};for i=1,4 do local u=s.u[i];us[i]={hp=u.hp,al=u.al,g=u.g,sh=u.sh,shT=u.shT,tau=u.tau,df=u.df,mk=u.mk,chg=u.chg,bf=u.bf,x=u.x,dot=u.dot or {}} end
 add('felice_full',{state=before}, {units=us,events=s.ev.list,h=s.ev.h,log=s.log,T=s.ev.T})
end end end
for _,p in ipairs(B.PERSONA.prefixes) do for _,q in ipairs(B.PERSONA.suffixes) do if B.ps_compatible(p,q) then for _,level in ipairs({0,10}) do
 local skill={prefix=p.id,suffix=q.id,prefix_lv={[p.id]=level},suffix_lv={[q.id]=level}}
 local d=B.member_def({id='persona',cls='warrior',L=40,skill=skill})
 add('member_skills',{definition=d},B.member_skills(d))
end end end end
local phaseids={};for id,f in pairs(B.FOES) do if f.ph2 then phaseids[#phaseids+1]=id end end;table.sort(phaseids)
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,id in ipairs(phaseids) do for _,phase in ipairs({1,2}) do for _,cycle in ipairs({false,{'fire','dark'},{'ice'}}) do
  local s={fl={id},fg={'boss'},el=40,u={{},{},{},{},{ph=phase,cwk=cycle or nil}}}
  add('foe_def',{state=s,slot=1,lang=lang},B.foe_def(s,1))
 end end end
end
B.LANG='ko'
for _,mhp in ipairs({0,1,2,3,4,7,100,1003}) do for _,target in ipairs({1,2}) do for used=0,1 do
 local s=fresh();B.DEF[1].cid='marceline';for i=1,6 do B.DEF[i].name='unit'..i end
 s.u[1].mhp=mhp;s.u[1].hp=0;s.u[1].lf=used;B.begin_ev(s);local before=cp(s)
 local result=B.TR.marceline.save(s,1,target,.125)
 add('marceline_full',{state=before,target=target},{value=result or false,hp=s.u[1].hp,sh=s.u[1].sh,shT=s.u[1].shT,lf=s.u[1].lf,events=s.ev.list,h=s.ev.h,log=s.log,T=s.ev.T})
end end end
return out

