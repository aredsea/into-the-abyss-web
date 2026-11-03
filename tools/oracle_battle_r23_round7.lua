local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,input,expected)
 out.rows[#out.rows+1]={op=op,input=cp(input),expected=cp(expected)};out.counts[op]=(out.counts[op] or 0)+1
end
local function base()
 local s=fresh()
 for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i;s.u[i].x={};s.u[i].edot={} end
 s.rs=12345;s.u[5].it=1;s.u[5].ia=1
 return s
end
local fields={'hp','mhp','mp','sh','shT','g','al','df','am','bt','ay','ym','dr','ia','it','cq','ph','rd','add','empty','tau','oath','oT','mk','chg','sil','bf','x','edot','cwk'}
local function observe(s,value)
 local units={};for i,u in ipairs(s.u) do local v={};for _,k in ipairs(fields) do if u[k]~=nil then v[k]=u[k] end end;units[i]=v end
 return {units=units,events=s.ev and s.ev.list or false,h=s.ev and s.ev.h or false,pre=s.ev and s.ev.pre or false,q0=s.ev and s.ev.q0 or false,log=s.log,T=s.ev and s.ev.T or false,rng=s.rs,value=value or false}
end
local function invoke(op,s,c,fn)
 c.state=cp(s);c.defs={};for i=1,#s.u do c.defs[i]=cp(B.DEF[i]) end
 local value=fn();add(op,c,observe(s,value))
end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,name in ipairs({'되치기','방패','불꽃','<raw>'}) do for bits=0,31 do for _,target in ipairs({1,4}) do
  local s=base();local r={i=target,d=bits%2==1 and 1 or 999,kill=bits//2%2,sh=bits//4%2==1 and 17 or 0}
  if bits//8%2==1 then r.tags={'되치기','약점'} end
  local a={name=name};invoke('foe_line',s,{action=a,result=r,lang=lang},function()return B.foe_line(s,5,a,r)end)
 end end end
end
B.LANG='ko'
for _,hp in ipairs({1,1000}) do for _,sh in ipairs({0,50,100}) do for bits=0,15 do for _,at in ipairs({0,.125,2}) do
 local s=base();local u=s.u[1];u.hp=hp;u.sh=sh;u.shT=sh>0 and 2 or 0;u.df=bits%2;s.u[5].am=bits>=8 and 1.2 or 1
 if bits//2%2==1 then u.bf.def={v=.2,n=2};u.de=50 end
 if bits//4%2==1 then s.u[5].bf.adn={v=.2,n=2} end
 local c={m=bits%3==0 and .6 or 0};B.begin_ev(s)
 invoke('counter',s,{counter=c,at=at},function()return B.e_counter(s,5,1,c,at)end)
end end end end
for bits=0,31 do for _,at in ipairs({0,.125,2}) do
 local s=base();local R={};if bits%2==1 then R.weak_hit_delay={el='fire',amount=.2} end
 if bits//2%2==1 then R.counter_when_guard={m=.6} end
 B.DEF[5].rules=R;s.u[5].df=bits//4%2;s.u[5].rd=bits//8%2
 if bits>=16 then s.u[1].hp=0;s.u[1].al=0 end
 invoke('foe_hit_after',s,{rules=R,at=at,element='fire'},function()return B.foe_hit_after(s,1,5,{kill=0},{el='fire'},at)end)
end end
for _,n in ipairs({0,1,2,4}) do for _,hp in ipairs({1,50,1000}) do for _,sh in ipairs({0,20}) do for _,life in ipairs({-1,0,1,3}) do
 local s=base();s.u[1].hp=hp;s.u[1].sh=sh;s.u[1].shT=sh>0 and 3 or 0;s.u[1].df=1
 for j=1,n do s.u[1].edot[j]={d=j%2==0 and 0 or 10,n=life,by=5} end
 B.begin_ev(s);invoke('edot_tick',s,{},function()return B.edot_tick(s,1)end)
end end end end
local oldevade=B.GH.evade
for _,miss in ipairs({false,true}) do for _,m in ipairs({false,0,.5,2}) do for _,turns in ipairs({false,0,1,4}) do for _,count in ipairs({0,4}) do
 local s=base();local act={kind='dot',name='test',ic='shoot'};if m~=false then act.m=m end;if turns~=false then act.turns=turns end
 for j=1,count do s.u[1].edot[j]={d=j,n=3,by=6} end
 B.GH.evade=function()return miss or nil end
 invoke('e_dot',s,{action=act,miss=miss},function()return B.e_dot(s,5,act)end)
end end end end
B.GH.evade=oldevade
for _,kind in ipairs({'missing','','atk','buff','guard','charge'}) do
 local s=base();local a={kind=kind,name='test',ic='defend',stat='atk',amount=.2,m=1}
 -- B.e_act intentionally dispatches only support vocabulary; atk/guard are
 -- handled by enemy_turn and must be no-ops at this exact entry point.
 invoke('dispatch',s,{action=a},function()return B.e_act(s,5,a)end)
end
local cancelids={'apprentice_doll'}
for id,f in pairs(B.FOES) do if f.rules and f.rules.break_self then cancelids[#cancelids+1]=id end end;table.sort(cancelids)
for _,id in ipairs(cancelids) do for _,hp in ipairs({1,2,1000}) do for _,sh in ipairs({0,40}) do for _,index in ipairs({1,2}) do
 local s=base();s.fl[1]=id;B.bind_foes(s);B.DEF[5].name='unit5';B.DEF[5].full='unit5';s.u[5].hp=hp;s.u[5].sh=sh;s.u[5].shT=sh>0 and 2 or 0;s.u[5].cq=1;s.u[5].ia=index
 B.begin_ev(s);invoke('charge_cancel',s,{foe=id},function()return B.charge_cancel(s,5)end)
end end end end
for bits=0,31 do for _,count in ipairs({0,1,3,6}) do
 local s=base();s.ne=6
 for j=7,10 do s.u[j]=cp(s.u[6]);s.fl[j-4]='';s.fg[j-4]='';s.u[j].hp=0;s.u[j].al=0;s.u[j].empty=1 end
 s.u[6].al=bits%2;s.u[6].hp=s.u[6].al==1 and 1000 or 0;s.u[6].add=bits//2%2
 for j=7,10 do if bits//4%2==1 then s.u[j].empty=nil;s.u[j].add=1;s.fl[j-4]='apprentice_doll';s.fg[j-4]='minion';s.u[j].al=bits//8%2;s.u[j].hp=s.u[j].al==1 and 1000 or 0 end end
 B.bind_foes(s);for j=5,10 do if s.u[j].empty~=1 then B.DEF[j].name='unit'..j;B.DEF[j].full='unit'..j end end
 B.begin_ev(s);if bits>=16 then for j=6,10 do s.ev.h[j]={{f='hp',v=0,t=.1}} end end
 local a={kind='summon',name='test',enemy='apprentice_doll',count=count}
 invoke('summon',s,{action=a},function()return B.e_summon(s,5,a)end)
end end
local phases={};for id,f in pairs(B.FOES) do if f.ph2 then phases[#phases+1]=id end end;table.sort(phases)
for _,id in ipairs(phases) do for bits=0,15 do
 local s=base();s.fl={id,id};s.fg={'boss','boss'};s.raid=1;B.bind_foes(s)
 for j=5,6 do s.u[j].ph=bits%2+1;s.u[j].rd=1;s.u[j].cq=1;s.u[j].ay=1;s.u[j].ym=150;s.u[j].dr=1;s.u[j].al=bits//4%2;s.u[j].hp=s.u[j].al==1 and (bits//2%2==1 and 500 or 501) or 0 end
 if bits>=8 then s.ev=nil end
 invoke('phase',s,{foe=id},function()return B.phase_check(s)end)
end end
-- Isolated cutin entry, consumed by the actual native begin-action path.
for _,id in ipairs({'rev','oath','mark','note','levia','marceline','naran','teiris','missing',''}) do for _,name in ipairs({'','test'}) do for _,T in ipairs({0,.125,2}) do
 local s=base();s.ev.T=T;invoke('cutin',s,{id=id,name=name},function()return B.cutin(s,1,id,name)end)
end end end
return out
