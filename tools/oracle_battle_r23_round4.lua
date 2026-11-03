local H=B.__batch
local out={rows={},counts={}}
local function add(op,input,expected)
 out.rows[#out.rows+1]={op=op,input=input,expected=expected};out.counts[op]=(out.counts[op] or 0)+1
end
local function cp(v)return json.decode(json.encode(v))end
local function ordered(t)
 local keys={};for k in pairs(t) do keys[#keys+1]=k end;table.sort(keys)
 local n=0;return function() n=n+1;local k=keys[n];if k then return k,t[k] end end
end
local levels={false,true,'', 'bad',-1,0,.9,1.99,10,11,' 3.9 ','0xA','-0x1','+0X1.fp+2','0x.8p+3','1e3','0x1p-1','1_0','NaN','inf',{}, {x=2}}
for _,v in ipairs(levels) do
 add('ps_level',{value=v},H.ps_lvl({strike=v},'strike'))
 for _,raw in ipairs({false,{prefix='strike',suffix='bleed',prefix_lv={strike=v,element=v},suffix_lv={bleed=v,abyss=v}},{prefix='heal',suffix='bane',prefix_lv={heal=v},suffix_lv={bane=v}}}) do
  add('ps_clean',{raw=raw},B.ps_clean(raw))
  local p,s,w=B.ps_parts(raw);add('ps_parts',{raw=raw},{p=p or false,s=s or false,v=w})
 end
end
for _,p in ipairs(B.PERSONA.prefixes) do for _,s in ipairs(B.PERSONA.suffixes) do
 for _,n in ipairs({0,1,9,10}) do for _,lang in ipairs({'ko','en'}) do for _,force in ipairs({false,true}) do
  B.LANG=lang;local raw={prefix=p.id,suffix=s.id,prefix_lv={[p.id]=n},suffix_lv={[s.id]=n}}
  add('ps_meta',{raw=raw,lang=lang,force=force},{name=B.ps_name(raw,force),desc=B.ps_desc(raw,force),skill=B.ps_skill(raw) or false})
 end end end
end end
for _,raw in ipairs({false,{}, {prefix='bad',suffix='bad'},{prefix='strike',suffix='regen'}}) do for _,lang in ipairs({'ko','en'}) do
 B.LANG=lang;add('ps_meta',{raw=raw,lang=lang,force=false},{name=B.ps_name(raw),desc=B.ps_desc(raw),skill=B.ps_skill(raw) or false})
end end
B.LANG='ko'
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,list in ipairs({B.PERSONA.prefixes,B.PERSONA.suffixes}) do for _,v in ipairs(list) do add('ps_label',{node=v,lang=lang},H.ps_label(v)) end end
end
B.LANG='ko'
local keys={'human','elf','demon','halfelf','nox','beast','seredia','karashin','solen','marento','naerin','morgas','kern','border','missing'}
for _,key in ipairs(keys) do add('pnode',{key=key},H.pnode(key) or false) end
local snippets={'unchanged','{missing.x%}','{human.hp2%} {human.hp3} {elf.mp}','{var.priest_cap} {var.priest_heal%}','{assassin.crit} {assassin.extra%}','{human.nope} {human.hp2%%}','{Human.hp2%} {human-hp2} {human.hp2%}',false,12}
for _,s in ipairs(snippets) do add('ptx',{value=s},B.ptx(s)) end
for _,group in ipairs({'races','nations'}) do for _,node in ordered(B.PASSIVES[group]) do
 for _,value in ordered(node) do if type(value)=='string' then add('ptx',{value=value},B.ptx(value)) elseif type(value)=='table' then for _,s in ipairs(value) do if type(s)=='string' then add('ptx',{value=s},B.ptx(s)) end end end end
end end
for _,key in ipairs(keys) do for n=0,4 do for bits=0,15 do
 local st=fresh()
 for i=1,4 do
  st.u[i].rc=i<=n and key or '';st.u[i].na='';st.u[i].al=(bits//2^(i-1))%2;st.u[i].bx=99
 end
 H.refresh(st);local bx={};for i=1,4 do bx[i]=st.u[i].bx end
 add('refresh',{key=key,n=n,bits=bits},{sy=st.sy,bx=bx})
 for _,lang in ipairs({'ko','en'}) do B.LANG=lang;add('syn_full',{key=key,n=n,bits=bits,lang=lang},B.syn(st)) end
end end end
B.LANG='ko'
for bits=0,31 do for _,n in ipairs({-1,0,1,2,3}) do for _,src in ipairs({false,0,1,2,5}) do
 local u={};if bits~=0 then u.bf={} end
 for j,k in ipairs({'atk','def','adn','red20'}) do if bits%2^j>=2^(j-1) then u.bf[k]={v=.1*j,n=n,f=bits>=16 and true or nil,src=src~=false and src or nil,d=1,keep='yes'} end end
 B.btick(u);add('tick',{bits=bits,n=n,src=src},u.bf or false)
end end end
for _,grade in ipairs({'mob','elite','chief','boss','core'}) do for _,hp in ipairs({299,300,301,1000}) do for _,rd in ipairs({20,21,30,40}) do for _,raid in ipairs({false,true}) do for _,am in ipairs({.5,1,1.7}) do
 local st=fresh();st.rd=rd;st.raid=raid and 1 or 0;st.u[5].hp=hp;st.u[5].am=am;B.DEF[5].grade=grade;B.DEF[5].rules={hp_atk={thr=.3,amount=.2}};B.badd(st.u[5],'atk',.1,2)
 local m,tags=B.foe_atk_mul(st,5);add('attack_split',{grade=grade,hp=hp,rd=rd,raid=raid,am=am},{value=m,tags=tags or false,combined=m*am})
end end end end end
for _,v in ipairs({-100,-.875,-.375,-.125,-.005,-.0001,0,.005,.125,.25,.375,.75,.875,.9999,100,100.123456}) do
 add('f2',{value=v},{fx=H.fx_f2(v),hud=H.hud_f2(v),raid=H.raid_f2(v)})
 for _,m in ipairs({-1,0,1,100}) do add('ratio',{v=v,m=m},H.hud_pct(v,m)) end
end
for _,s in ipairs({'','ordinary','약점 화염','고갈','여우불','고갈 약점','여우불 고갈','critical'}) do add('tagcls',{value=s},H.tagcls(s)) end
for _,k in ipairs({false,-1,0,1,1.1,2}) do add('kx',{value=k},H.kx(k)) end
for _,n in ipairs({0,1,4,6,16}) do for _,logged in ipairs({0,1,6,7,12}) do for _,active in ipairs({false,true}) do
 local state={u={},log={},q={3,1,6}}
 for i=1,n do state.u[i]={hp=i*10,mp=i,sh=0,ay=30,keep='yes'} end
 for i=1,logged do B.say(state,'log '..i,i/10) end
 local initial=cp(state)
 if active then B.begin_ev(state) end
 local steps={}
 for i=1,n do for _,f in ipairs({'hp','mp','sh','ay','custom'}) do for _,at in ipairs({false,0,.7}) do
  local input={i=i,f=f,v=i*7,at=at};steps[#steps+1]=input;B.setf(state,i,f,input.v,at)
 end end end
 local payloads={}
 if active then
  for _,k in ipairs({'atk','trait','shield'}) do
   local e={k=k,a=1,t=.3,ht=.8,tg={{i=5,d=12,sh=4,tags={'keep'},ab=3,list={{i=6,n=1}}}},nm='raw',keep={x=1}}
   local r=B.push(state,e);r.after='same';payloads[#payloads+1]=cp(e)
  end
 end
 add('record',{initial=initial,logged=logged,active=active,steps=steps,payloads=payloads},state)
end end end
for _,at in ipairs({false,0,.3}) do for _,ab in ipairs({false,0,2.5}) do for _,text in ipairs({'','test','특성'}) do
 local st={u={},log={},q={}};B.begin_ev(st);B.trait_line(st,2,text,at,ab)
 local one=cp(st.ev.list);st.ev.list={};H.trait(st,2,text,at)
 add('trait_payload',{at=at,ab=ab,text=text},{direct=one,wrapper=st.ev.list})
end end end
for _,variant in ipairs({0,1,2,3}) do for _,boost in ipairs({false,-.2,0,.6}) do for _,cached in ipairs({false,-.1,0,.4}) do for _,hasopt in ipairs({false,true}) do
 local st=fresh();local old=B.GEN.tr.miko.variant;B.GEN.tr.miko.variant=variant
 st.u[2].x={keep=7}
 if boost then st.u[2].x.mk=boost end
 local opt=hasopt and {} or nil;if opt and cached then opt.mkv=cached end
 local tags={'keep'};local value=B.TR.miko.deal(st,1,2,5,2,tags,opt)
 B.GEN.tr.miko.variant=old
 add('miko_deal',{variant=variant,boost=boost,cached=cached,hasopt=hasopt},{value=value or false,x=st.u[2].x,opt=opt or false,tags=tags})
end end end end
for _,variant in ipairs({0,1,2,3}) do for bits=0,15 do for _,mode in ipairs({0,1,2,3}) do
 local st=fresh();local old=B.GEN.tr.miko.variant;B.GEN.tr.miko.variant=variant
 st.log={}
 for i=1,4 do
  st.u[i].al=(bits//2^(i-1))%2;st.u[i].g=mode==0 and 10000 or mode==1 and (i*500) or mode==2 and -2000 or 0
  st.u[i].sp=mode==3 and i*100 or 100;B.DEF[i].name='unit'..i
 end
 B.TR.miko.round(st,1);B.GEN.tr.miko.variant=old
 local gs={};for i=1,4 do gs[i]=st.u[i].g end
 add('miko_round',{variant=variant,bits=bits,mode=mode},{g=gs,events=st.ev.list,log=st.log,T=st.ev.T})
end end end
for _,variant in ipairs({1,2}) do for _,boost in ipairs({0,.6}) do for _,volley in ipairs({false,true}) do
 local st=fresh();st.rs=12345;st.u[1].x.mk=boost;B.DEF[2].cid='miko'
 local old=B.GEN.tr.miko.variant;B.GEN.tr.miko.variant=variant
 local opt={m=1,brk=0,el='none',name='test',hit=.45,dur=1.3}
 if volley then B.volley(st,1,opt) else B.attack(st,1,5,opt) end
 B.GEN.tr.miko.variant=old
 add('miko_attack',{variant=variant,boost=boost,volley=volley},{hp={st.u[5].hp,st.u[6].hp},mk=st.u[1].x.mk,rs=st.rs})
end end end
for bits=0,15 do for rows=0,7 do for _,named in ipairs({false,true}) do
 local st=fresh();st.log={};B.ACT=st.u[1]
 for i=1,4 do st.u[i].al=(bits//2^(i-1))%2;B.DEF[i].name='unit'..i;B.DEF[i].row=(i==1 or (rows//2^(i-2))%2==1) and '전열' or '후열' end
 B.PRUN.haldric(st,1,2,{name=named and 'test' or nil})
 local buffs={};for i=1,4 do buffs[i]=st.u[i].bf end
 add('haldric',{bits=bits,rows=rows,named=named},{buffs=buffs,events=st.ev.list,log=st.log,T=st.ev.T})
 B.ACT=nil
end end end
for bits=0,255 do
 local st=fresh();st.log={};B.DEF[1].name='unit1';B.DEF[2].name='unit2'
 for j,k in ipairs({'atk','def','red20','red25'}) do
  if (bits//2^(j-1))%2==1 then st.u[2].bf[k]={v=(j<=2 and .4 or .6),n=3,src=4,keep='yes',d=(bits//2^(j+3))%2==1 and 1 or nil} end
 end
 B.PRUN.urda(st,1,2,{name='test'})
 add('urda',{bits=bits},{buffs=st.u[2].bf,events=st.ev.list,log=st.log,T=st.ev.T})
end
for _,actor in ipairs({false,0,1,4,5,7}) do for _,n in ipairs({0,1,2,3,4}) do for bits=0,15 do for _,full in ipairs({false,true}) do
 local st=fresh();st.log={};for i=1,4 do st.u[i].rc=i<=n and 'demon' or '';st.u[i].al=(bits//2^(i-1))%2;st.u[i].hp=st.u[i].al==1 and (full and 1000 or 500) or 0;st.u[i].mp=full and 100 or 99;B.DEF[i].name='unit'..i end
 B.SKON=true;B.kill_credit(st,actor or nil,.4);local restored=B.SKON==true;B.SKON=nil
 local us={};for i=1,4 do us[i]={hp=st.u[i].hp,mp=st.u[i].mp} end
 add('kill_full',{actor=actor,n=n,bits=bits,full=full},{units=us,h=st.ev.h,events=st.ev.list,T=st.ev.T,skill_restored=restored})
end end end end
for _,actor in ipairs({1,4,5}) do for _,n in ipairs({0,2,3,4}) do for bits=0,15 do for _,dbl in ipairs({false,true}) do for _,roll in ipairs({0,.039999,.04,1}) do
 local st=fresh();st.log={};st.sy={keep=7};for i=1,4 do st.u[i].rc=i<=n and 'beast' or '';st.u[i].al=(bits//2^(i-1))%2;st.u[i].bx=99;B.DEF[i].name='unit'..i end
 st.u[actor].x.dbl=dbl and 1 or 0
 local original=B.rnd;local calls=0;B.rnd=function()calls=calls+1;return roll end
 B.GH.turn_end(st,actor);B.rnd=original
 local bx={};for i=1,4 do bx[i]=st.u[i].bx end
 add('double_full',{actor=actor,n=n,bits=bits,dbl=dbl,roll=roll},{g=st.u[actor].g,dbl=st.u[actor].x.dbl,sy=st.sy or false,bx=bx,events=st.ev.list,log=st.log,T=st.ev.T,calls=calls})
end end end end end
out.constants={txn=B.TXN,pass=B.PASS,var=B.VAR,passives=B.PASSIVES}
for _,variant in ipairs({1,2}) do for _,target in ipairs({1,2}) do for _,hp in ipairs({0,500,1000}) do for _,g in ipairs({-1,0,1000,12000}) do
 local st=fresh();B.DEF[1].cid='miko';st.u[target].hp=hp;st.u[target].al=hp>0 and 1 or 0;st.u[target].g=g
 local old=B.GEN.tr.miko.variant;B.GEN.tr.miko.variant=variant;B.PRUN.miko(st,1,target,{name='test'});B.GEN.tr.miko.variant=old
 add('miko_run',{variant=variant,target=target,hp=hp,g=g},{hp=st.u[target].hp,g=st.u[target].g,mk=st.u[target].x.mk or false})
end end end end
for _,qkind in ipairs({'missing','false','zero','string','map','array'}) do for _,kind in ipairs({'nil','false','number','string','map','true'}) do for _,atkind in ipairs({'nil','false','zero','true'}) do
 local q={['false']=false,zero=0,string='',map={keep=7},array={1,3}}
 local values={['false']=false,number=5,string='',map={keep=7},['true']=true}
 local ats={['false']=false,zero=0,['true']=true}
 local state={u={{hp=5,keep=7}},log={},ev=false}
 if qkind~='missing' then state.q=q[qkind] end
 B.setf(state,1,'hp',7,0);B.say(state,values[kind],ats[atkind]);B.begin_ev(state);B.setf(state,1,'hp',nil,0)
 local nilret=B.push(state,nil)==nil
 for _,v in ipairs({false,true,5,{keep=7}}) do B.push(state,v) end
 add('record_edge',{qkind=qkind,kind=kind,atkind=atkind},{state=state,nilret=nilret})
end end end
return out
