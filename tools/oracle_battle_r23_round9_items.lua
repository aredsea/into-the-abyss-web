local out={rows={},counts={},constants={items={},order=B.IT.order,english={},names={},kinds=B.POTION.kinds}}
local function cp(v)return json.decode(json.encode(v))end
for _,id in ipairs(B.IT.order)do out.constants.items[id]=B.ITEMS[id]end
for id,def in pairs(B.ITEMS)do if id~='charm_potion'then out.constants.names[id]=def.name end end
do
 B.LANG='en'
 for _,text in ipairs({'물약','아이템 {n}개, 쓰면 이번 차례를 씁니다','남은 아이템이 없다','{name} / {item}','쓰러진 아군을 누르세요','대상 아군을 누르세요','취소','다른 행동을 고릅니다','{description} (보유 {n})','<b>Lv {lv}부터 쓸 수 있습니다</b>. {description}','<b>쓸 대상이 없습니다</b>. {description}','행동 고르기로 돌아간다','{name} / 아이템','무엇을 쓸까요? 쓰면 이번 차례를 씁니다'})do out.constants.english[text]=B.U(text)end
 for _,id in ipairs(B.IT.order)do local d=B.ITEMS[id];out.constants.english[d.name]=B.T(d.name);out.constants.english[d.d]=B.T(d.d)end
 for id,name in pairs(out.constants.names)do out.constants.english[name]=B.T(name)end
 B.LANG='ko'
end
local function add(op,c,v)out.rows[#out.rows+1]={op=op,input=cp(c),expected=cp(v)};out.counts[op]=(out.counts[op]or 0)+1 end
local function base()
 local s=fresh();s.rs=12345;s.bag={}
 for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i;s.u[i].x={} end
 return s
end
local fields={'hp','mhp','mp','sh','shT','g','al','df','am','bt','ay','ym','dr','ia','it','tau','oath','oT','mk','chg','bf','x','sp','dot','edot','lf','fx','sil'}
local function observe(s,v)
 local us={};for i,u in ipairs(s.u)do local w={};for _,k in ipairs(fields)do if u[k]~=nil then w[k]=cp(u[k])end end;us[i]=w end
 return {units=us,events=s.ev.list,h=s.ev.h,log=s.log,T=s.ev.T,rng=s.rs,value=v,nd=s.nd,kill=s.kill}
end
for _,iid in ipairs(B.IT.order)do for _,cur in ipairs({1,2,4})do for t=1,4 do for bits=0,15 do
 local s=base();s.cur=cur;local u=s.u[t];u.hp=bits%2==1 and 990 or 1;u.mp=bits%2==1 and 99 or 0
 u.sh=bits//2%2*999;u.shT=2;u.g=123;u.tau=2;u.df=1;u.chg=1;u.mk=1;u.dr=1
 u.dot={{d=7,n=2,k=1,by=1},{d=3,n=1,bld=1,by=2}};u.edot={{d=2,n=2,by=5}};u.fx=2;u.bf.atk={v=.2,n=2}
 if bits>=8 then u.x.psrg={d=7,n=2,s=0};u.sil='blood'end
 if bits>=4 then s.u[1].na='marento';s.u[2].na='marento' end
 if iid=='bandage'then u.al=0;u.hp=0 end
 if cur==4 then s.u[3].na='solen';s.u[4].na='solen'end
 local c={state=cp(s),defs=cp(B.DEF),iid=iid,target=t};add('item_apply',c,observe(s,B.it_apply(s,iid,t)))
end end end end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,iid in ipairs(B.IT.order)do for bits=0,63 do
  local s=base();s.cur=bits%4+1
  for i=1,4 do local u=s.u[i];u.hp=bits%2==1 and 500 or 1000;u.mp=bits//2%2==1 and 40 or 100;u.sh=bits//4%2*1000
   if bits//8%2==1 then u.dot={{d=1,n=2}};u.fx=1 end
   if bits//16%2==1 then u.al=0;u.hp=0 end
   B.DEF[i].lv=bits>=32 and 40 or 1
  end
  s.bag[iid]=2
  local flags={};for i=0,5 do flags[#flags+1]={state=B.it_state_ok(s,iid,i),ok=B.it_ok(s,iid,i)}end
  local c={state=cp(s),defs=cp(B.DEF),iid=iid,lang=lang}
  add('item_targets',c,{flags=flags,any=B.it_any(s,iid),blocked=B.it_blocked(s,iid)})
  add('item_menu',c,{html=B.r_items(s,'')})
 end end
 for _,bag in ipairs({false,{}, {hp_s=0,bandage=0}, {hp_s='2',mp_m=3,bandage=1}, {hp_s=-2,mp_s=1}, {hp_s='bad'}, {hp_s=.5,sh_l=1}})do
  local s=base();s.bag=bag or nil;add('item_button',{state=cp(s),defs=cp(B.DEF),lang=lang},{html=B.it_button(s)})
 end
 for _,id in ipairs(B.IT.order)do for _,cur in ipairs({1,4})do
  local s=base();s.cur=cur;s.ipk=id
  add('item_menu',{state=cp(s),defs=cp(B.DEF),iid=id,lang=lang},{html=B.r_items(s,'')})
 end end
end
B.LANG='ko'
for _,cur in ipairs({0,1,2,3,4,5,8})do add('cur_i',{cur=cur},B.__nine.cur_i({cur=cur}))end
local item_ids={};for id in pairs(out.constants.names)do item_ids[#item_ids+1]=id end;table.sort(item_ids)
for _,id in ipairs(item_ids)do add('item_name',{id=id},B.__nine.itname(id))end
for _,id in ipairs({'missing','', 'return_scroll','levelup_scroll'})do add('item_name',{id=id},B.__nine.itname(id))end
for _,iid in ipairs(B.IT.order)do for _,level in ipairs({false,0,-1,1,14.9,15,29.9,30,'15','0xf','bad',''})do
 local s=base();for i=1,4 do B.DEF[i].lv=level;s.u[i].hp=500;s.u[i].mp=0 end
 local flags={};for i=0,5 do flags[#flags+1]={state=B.it_state_ok(s,iid,i),ok=B.it_ok(s,iid,i)}end
 add('item_targets',{state=cp(s),defs=cp(B.DEF),iid=iid,lang='ko'},{flags=flags,any=B.it_any(s,iid),blocked=B.it_blocked(s,iid)})
end end
for _,iid in ipairs({'sh_s','sh_m','sh_l'})do for _,cur in ipairs({1,2,4})do for t=1,4 do for _,bonus in ipairs({0,25,50})do
 local s=base();s.cur=cur
 for i=1,4 do s.u[i].gq={shield=0}end
 s.u[cur].gq.shield=bonus
 local input={state=cp(s),defs=cp(B.DEF),iid=iid,target=t,gear=true}
 add('item_apply',input,observe(s,B.it_apply(s,iid,t)))
end end end end
return out
