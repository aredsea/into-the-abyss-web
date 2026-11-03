local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function base()
 local s=fresh();s.rs=12345
 for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i;B.DEF[i].wk={};s.u[i].x={};s.u[i].edot={} end
 return s
end
local fields={'hp','mhp','mp','sh','shT','g','al','df','am','bt','ay','ym','dr','ia','it','tau','oath','oT','mk','chg','bf','x','sp','sil','dot','edot','lf'}
local function observe(s,v)
 local us={};for i,u in ipairs(s.u)do local w={};for _,k in ipairs(fields)do if u[k]~=nil then w[k]=cp(u[k])end end;us[i]=w end
 return {units=us,events=s.ev and s.ev.list or false,h=s.ev and s.ev.h or false,log=s.log,T=s.ev and s.ev.T or false,rng=s.rs,value=v or false,nd=s.nd,kill=s.kill}
end
local function invoke(op,s,c,fn)
 c.state=cp(s);c.defs=cp(B.DEF);local v=fn();out.rows[#out.rows+1]={op=op,input=cp(c),expected=observe(s,v)};out.counts[op]=(out.counts[op]or 0)+1
end
-- A whole personal-skill call, including its attack options and failure text.
for _,speed in ipairs({90,100,110})do for bits=0,15 do
 local s=base();B.DEF[1].cid='bargut';s.u[2].sp=speed;s.u[5].sp=speed;s.u[5].rd=bits%2;s.u[6].al=bits//2%2;s.u[6].hp=s.u[6].al*1000
 if bits//4%2==1 then s.u[2].al=0;s.u[2].hp=0 end
 s.u[1].cr=bits//8%2*100
 invoke('bargut',s,{name='test'},function()B.PRUN.bargut(s,1,5,{name='test'})end)
end end
-- Every legal signature pair, both attack and support, all suffix levels.
for _,p in ipairs(B.PERSONA.prefixes)do for _,q in ipairs(B.PERSONA.suffixes)do
 if B.ps_compatible(p,q)then
  for _,level in ipairs({0,3,10})do for bits=0,7 do
   local s=base();B.DEF[1].cid='persona';B.DEF[1].skill={prefix=p.id,suffix=q.id,prefix_lv={[p.id]=level},suffix_lv={[q.id]=level}}
   s.u[2].hp=bits%2==1 and 500 or 1000;s.u[2].al=bits//2%2;s.u[5].hp=bits//4%2==1 and 1 or 1000
   if s.u[2].al==0 then s.u[2].hp=0 end
   s.u[2].sh=20;s.u[2].shT=2
   invoke('persona',s,{raw=cp(B.DEF[1].skill),target=2,name='test'},function()B.PRUN.persona(s,1,(p.kind=='attack' or p.kind=='volley')and 5 or 2,{name='test'})end)
  end end
 end
end end
-- Callback composition. The original extra-hit body is retained: only the
-- recursive attack is observed at its public boundary for options/RNG order.
-- Lower-level calls can supply another owner's definition. Levia's existing
-- abyss_after is the production callback that appends a non-empty spread list.
for _,p in ipairs({'strike','sweep'})do for _,level in ipairs({0,10})do
 local s=base();B.DEF[1].cid='levia';B.DEF[1].skill={prefix=p,suffix='abyss',prefix_lv={[p]=level},suffix_lv={abyss=level}}
 invoke('persona',s,{raw=cp(B.DEF[1].skill),target=2,name='test',lower_level_owner=true},function()B.PRUN.persona(s,1,5,{name='test'})end)
end end
local attack=B.attack
for bits=0,63 do for _,seed in ipairs({1,12345,2147483646})do
 local s=base();local a=bits%2==1 and 5 or 1;B.DEF[a].clsid=bits//2%2==1 and 'assassin' or 'warrior'
 if bits//4%2==1 then s.u[a].al=0;s.u[a].hp=0 end
 if bits//8%2==1 then s.u[6].al=0;s.u[6].hp=0 end
 if bits//16%2==1 then s.u[a].gu={{key='as_shadow',v={100}}}end
 s.rs=seed;local calls={};B.attack=function(st,i,t,o)calls[#calls+1]={i=i,t=t,opt=cp(o)}end
 local c={actor=a,extra=bits>=32,seed=seed,killed=bits//8%2}
 invoke('extra_hit',s,c,function()B.GH.extra_hit(s,a,6,{extra=c.extra,el='fire'},{kill=c.killed},.5);return {calls=calls}end)
end end
B.attack=attack
-- A taunt contributes the otherwise unvisited enemy-attack tag branches.
for _,all in ipairs({false,true})do for _,taunt in ipairs({0,2})do for _,m in ipairs({0,.01,1,100})do
 local s=base();s.u[1].tau=taunt
 local a={kind='atk',id='test',name='test',ic='attack',vb='때렸다',m=m,all=all}
 invoke('enemy_attack',s,{action=a,miss=false},function()B.e_attack(s,5,a)end)
end end end
return out
