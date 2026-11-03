local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,s,c,fn)
 c.state=cp(s);c.defs=cp(B.DEF);local value=fn()
 out.rows[#out.rows+1]={op=op,input=cp(c),expected={state=cp(s),value=value or false}};out.counts[op]=(out.counts[op]or 0)+1
end
local function base()
 local s=fresh();for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i end
 return s
end
for _,legacy in ipairs({false,true})do for _,star in ipairs({1,3,9})do for _,lv in ipairs({1,10,40})do for _,raid in ipairs({0,1})do for _,grade in ipairs({'mob','swarm','elite','minion','chief','boss','core','missing','gold_ref','exp_ref_enemies'})do for _,bonus in ipairs({0,1,3,4})do
 local s=base();s.el=lv;s.star=star;s.raid=raid;s.qmult=bonus==4 and 1.5 or 1;s.pm={}
 for i=1,4 do s.pm[i]={id=i<=bonus and 'persona' or '',nat=i<=bonus and (bonus==3 and '신성 세레디아 제국' or '경계도시')or ''}end
 B.DEF[5].grade=grade;B.DEF[6].grade=grade;B.DEF[5].kind=grade=='elite' and 'elite'or'mob';B.DEF[6].kind='mob';B.DEF[5].lvn=nil;B.DEF[6].lvn=lv+2
 if legacy then s.fl=nil;s.dk=nil;s.dn=nil else s.dk=bonus==4 and 2 or 0;if bonus==3 then s.dn={floor=13,ae=77}end end
 if bonus==1 then s.u[6].empty=1;B.DEF[6].empty=true end
 add('experience',s,{},function()return B.exp_reward(s)end)
end end end end end end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,op in ipairs({'finish','check_end'})do for bits=0,63 do for _,result in ipairs({'win','lose'})do
  local s=base();s.n=bits>=32 and 400 or 399;s.nd=3;s.kill=bits%2==1 and 'unit1의 공격'or'';s.rg=bits//2%2==1 and 0 or 999
  if bits//4%2==1 then s.over='win';s.res='old';s.exp=88 end
  if bits//8%2==1 then for j=1,4 do s.u[j].al=0;s.u[j].hp=0 end end
  if bits//16%2==1 then for j=5,6 do s.u[j].al=0;s.u[j].hp=0 end end
  if bits%3==0 then s.dn={kind='explore',floor=13,ae=77};s.place='test' elseif bits%3==1 then s.dn={stage=1};s.place='test' else s.fl=nil end
  if bits%7==0 then s.ev=nil end
  if bits%5==0 then B.DEF[4].empty=true;s.u[4].empty=1;s.pm[4]={id='',cls='',L=1}end
  add(op,s,{lang=lang,result=result},function()if op=='finish'then B.finish(s,result)else return B.check_end(s)end end)
 end end end
end
B.LANG='ko';return out
