local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function base()
 local s=fresh();s.rs=12345
 for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i;B.DEF[i].wk={};s.u[i].x={};s.u[i].edot={} end
 return s
end
local fields={'hp','mhp','mp','sh','shT','g','al','df','am','bt','ay','ym','dr','ia','it','tau','oath','oT','mk','chg','bf','x','sp','sil','dot','edot','lf'}
local function observe(s,value)
 local units={};for i,u in ipairs(s.u) do local v={};for _,k in ipairs(fields) do if u[k]~=nil then v[k]=cp(u[k])end end;units[i]=v end
 return {units=units,events=s.ev and s.ev.list or false,h=s.ev and s.ev.h or false,log=s.log,T=s.ev and s.ev.T or false,rng=s.rs,value=value or false,nd=s.nd,kill=s.kill}
end
local function invoke(op,s,c,fn)
 c.state=cp(s);c.defs=cp(B.DEF);local v=fn()
 out.rows[#out.rows+1]={op=op,input=cp(c),expected=observe(s,v)};out.counts[op]=(out.counts[op]or 0)+1
end
for _,who in ipairs({'neutral','levia'})do for _,brk in ipairs({0,.1,1,7,8,15,40,100})do for bits=0,31 do
 local s=base();B.DEF[1].cid=who;s.u[5].ay=bits%2==0 and 1 or 30;s.u[6].ay=bits//2%2==0 and 1 or 30
 s.u[5].dr=bits//4%2;s.u[6].dr=bits//8%2;s.u[6].al=bits//16%2;s.u[6].hp=s.u[6].al==1 and 1000 or 0
 invoke('abyss',s,{who=who,brk=brk,at=.125},function()local n,list=B.abyss(s,1,5,brk,'fire',.125);return {n=n,list=list or false}end)
end end end
for _,i in ipairs({1,5})do for bits=0,63 do for _,cost in ipairs({0,10000,20000})do
 local s=base();local u=s.u[i];u.oT=bits%3;u.oath=2;u.bt=bits//3%3;u.am=1.2;u.shT=bits//9%3;u.sh=bits%2*30
 u.sil=bits>=32 and 'blood' or '';u.bf.atk={v=.2,n=bits%3,f=bits//2%2==1 or nil};u.bf.def={v=.1,n=2};u.g=-100
 invoke('end_turn',s,{slot=i,cost=cost},function()B.end_turn(s,i,cost)end)
end end end
for _,cap in ipairs({5,6})do for _,count in ipairs({0,4,5,6,9})do for _,by in ipairs({false,1,4})do for _,turns in ipairs({0,1,3})do
 local s=base();local v=s.u[5];v.dot={{d=99,n=2,bld=1,by=2}}
 for j=1,count do v.dot[#v.dot+1]={d=j,n=j%3,k=1,by=j%4+1}end
 if cap==6 then for j=1,3 do s.u[j].na='morgas'end end
 invoke('dot_push',s,{cap=cap,by=by,turns=turns,amount=7},function()B.dot_push(s,v,7,turns,by or nil)end)
end end end end
for _,repeat_cast in ipairs({false,true})do for _,rd in ipairs({0,2,3,4,6})do for _,hp in ipairs({1,1000})do for _,boss in ipairs({0,1})do
 local s=base();B.DEF[1].cid='judith';s.u[5].sp=101;s.u[5].rd=boss;s.u[5].hp=hp
 if repeat_cast then B.PRUN.judith(s,1,5,{name='test'});s.rd=1;B.begin_ev(s)end
 invoke('judith',s,{repeat_cast=repeat_cast,round=rd},function()B.PRUN.judith(s,1,5,{name='test'});s.rd=rd;B.round_tick(s)end)
end end end end
for _,bad in ipairs({false,3})do
 local s=base();B.DEF[1].cid='judith';s.u[5].x=bad
 invoke('judith',s,{repeat_cast=false,round=0},function()B.PRUN.judith(s,1,5,{name='test'});B.round_tick(s)end)
end
for _,n in ipairs({0,1,2,3})do for bits=0,31 do for _,hp in ipairs({1,1000})do
 local s=base();B.DEF[1].cid='jorund';local w=s.u[5];w.x.bn=n;w.x.jd=bits%2==1 and .1 or 0;w.rd=bits//2%2;w.hp=hp
 w.dot={{d=11,n=2,k=1,by=2}};if bits//4%2==1 then w.dot[#w.dot+1]={d=10,n=2,bld=1,by=1}end
 if bits//8%2==1 then w.hp=0;w.al=0 end
 invoke('jorund',s,{killed=bits//16%2},function()B.TR.jorund.hit_after(s,1,1,5,{kill=bits//16%2},{},.125)end)
end end end
for _,who in ipairs({'hildegard','judith','haldric','felice'})do for bits=0,15 do
 local s=base();B.DEF[1].cid=who;s.u[1].al=bits%2;s.u[1].hp=s.u[1].al*1000
 B.DEF[2].cid='adeline';s.u[2].al=bits//2%2;s.u[2].hp=s.u[2].al*1000
 for j=1,4 do s.u[j].bf.red={v=.1,n=2,src=bits//4%2==1 and 2 or 1};s.u[j].bf.red20={v=.2,n=2,src=2};s.u[j].x.areg={d=10,n=2,src=2}end
 invoke('damaged_cleanup',s,{who=who},function()B.fire(s,'damaged',2,10,5,.125)end)
end end
local evade=B.GH.evade
for _,all in ipairs({false,true})do for bits=0,63 do for _,hp in ipairs({1,1000})do
 local s=base();local miss=bits%2==1;B.GH.evade=function()return miss or nil end
 for j=1,4 do s.u[j].hp=hp;s.u[j].sh=bits//2%2*30;s.u[j].shT=s.u[j].sh>0 and 2 or 0;s.u[j].df=bits//4%2 end
 if bits//8%2==1 then B.DEF[2].cid='marceline';s.u[2].oath=1;s.u[2].oT=3;s.u[2].lf=1 end
 if bits//16%2==1 then s.u[4].hp=0;s.u[4].al=0 end
 local a={kind='atk',id='test',name='test',ic='attack',vb='때렸다',m=1,all=all,shoot=bits>=32 or nil,big=bits//4%2==1 or nil}
 if bits//2%2==1 then a.push=.1;a.drain=.5;a.dot={m=.1,turns=2};a.strip=true;s.u[1].bf.atk={v=.1,n=2};s.u[5].hp=500 end
 if bits>=32 then B.DEF[5].rules=B.DEF[5].rules or {};B.DEF[5].rules.hp_atk={thr=1,amount=.2}end
 invoke('enemy_attack',s,{action=a,miss=miss},function()B.e_attack(s,5,a)end)
end end end
B.GH.evade=evade
local ids={};for id in pairs(B.PRUN)do if id~='persona'then ids[#ids+1]=id end end;table.sort(ids);ids[#ids+1]='missing'
for _,id in ipairs(ids)do for _,mp in ipairs({0,1,20,99})do for _,hp in ipairs({1,100,151,1000})do for bits=0,3 do
 local s=base();local cls=B.CAST[id] and B.cls_of(B.CAST[id].cls).id or 'warrior';B.DEF[1].cid=id;B.DEF[1].clsid=cls
 s.u[1].mp=mp;s.u[1].hp=hp;s.u[1].seal=bits%2;s.u[1].nu=bits%2;s.u[1].sil=bits>=2 and 'blood' or '';s.u[1].x.inch=bits%2==1 and 1 or nil
 local skills={{id='blood',mp=20},{id='spell',mp=24},{id='personal',mp=25,pv=true,cid=id},false}
 for _,sk in ipairs(skills)do
  local value=B.can_use(s,1,sk or nil);local input={state=cp(s),defs=cp(B.DEF),skill=sk,who=id,cls=cls}
  out.rows[#out.rows+1]={op='can_use',input=input,expected={value=value}};out.counts.can_use=(out.counts.can_use or 0)+1
 end
end end end end
return out
