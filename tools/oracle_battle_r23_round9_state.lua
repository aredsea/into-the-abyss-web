local out={rows={},counts={},constants={tune=B.TUNE,tune_star=B.TUNE_STAR}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,c,v)out.rows[#out.rows+1]={op=op,input=cp(c),expected=cp(v)};out.counts[op]=(out.counts[op]or 0)+1 end
local classes={};for id in pairs(B.CLS)do classes[#classes+1]=id end;table.sort(classes)
-- Entire initializer, including trait and equipment hooks. No B.run is used.
for _,cls in ipairs(classes)do for _,L in ipairs({1,15,40})do for bits=0,31 do
 local m={id='persona',cls=cls,L=L,race=bits%2==1 and '엘프' or '인간',nat=bits//2%2==1 and '신성 세레디아 제국' or '',ps={hp='137',mp='71',str=bits//4%2==1 and '0' or '23',agi='19.5',int='17',def='13',spd='92.5'}}
 if bits//8%2==1 then m.ps={str=1,mp='bad',hp=false,spd='bad'}end
 if bits>=16 then
  m.eq={};m.forge={};local keys={};for id,d in pairs(B.gear().items)do if d.cls==cls then keys[#keys+1]=id end end;table.sort(keys)
  for _,id in ipairs(keys)do local d=B.gear().items[id];if not m.eq[d.slot]then local code=B.gear_code(id,12345+bits);m.eq[d.slot]=code;m.forge[code]={lv=2}end end
 end
 local s={pm={m,{id='persona',cls='warrior',L=1,race='인간'},{id='persona',cls='warrior',L=1,race='인간'},{id='',cls='',L=1}}}
 B.bind(s);local before=cp(s);local result=B.blank_u(s,1);add('blank_unit',{state=before,slot=1},{unit=result,state=cp(s)})
end end end
for _,id in ipairs({'levia','hildegard','bargut','missing',''})do for _,L in ipairs({1,40})do
 local s={pm={{id=id,cls='warrior',L=L},{id='',cls='',L=1},{id='',cls='',L=1},{id='',cls='',L=1}}};B.bind(s)
 for i=1,4 do local before=cp(s);local result=B.blank_u(s,i);add('blank_unit',{state=before,slot=i},{unit=result,state=cp(s)})end
end end
for _,legacy in ipairs({false,true})do for _,dm in ipairs({false,{hp=0,atk=0},{hp=.001,atk=.5},{hp=2,atk=3}})do for _,el in ipairs({1,40})do
 local s={pm=B.DEFAULT_PM,el=el,star=2,dm=dm or nil}
 if legacy then s.foe={1,3,4}else s.fl={'apprentice_doll','','demon_king'};s.fg={'','', 'boss'};s.ne=3;s.zk='';s.dk=0 end
 B.bind(s)
 for i=5,legacy and 8 or 7 do local before=cp(s);local result=B.blank_u(s,i);add('blank_unit',{state=before,slot=i},{unit=result,state=cp(s)})end
end end end
-- Exercise the actual local r closure, with independent denominator and value
-- boundaries, after obtaining it through the real persona initializer.
for _,den in ipairs({false,0,-1,1,10,'2','bad'})do for _,value in ipairs({false,0,-1,1,10,'2.5','0x10','bad'})do
 local m={id='persona',cls='warrior',L=1,ps={str=1,hp=value}}
 local s={pm={m}};B.bind(s);B.blank_u(s,1);B.__nine.rbase.hp=den
 add('persona_ratio',{base=den,value=value},B.__nine.r('hp'))
end end
return out
