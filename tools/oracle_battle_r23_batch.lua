local H=B.__batch
local out={rows={},counts={}}
local function add(op,input,expected)
 out.rows[#out.rows+1]={op=op,input=input,expected=expected};out.counts[op]=(out.counts[op] or 0)+1
end
local function slot(i) return i or 0 end
local function copy(x) return json.decode(json.encode(x)) end
for _,seed in ipairs({false,true,'bad','', ' 2 ', '1e2','-2.1',-1.1,0,1,2147483646,9007199254740991,'0x10','-0Xff','0x1p2','0x1.8p-1'}) do
 local r=B.mkrng(seed);local states={};for i=1,12 do states[i]=math.floor(r()*2147483647+.5) end
 add('rng',{seed=type(seed)=='number' and math.abs(seed)>1e12 and string.format('%.0f',seed) or seed},states)
end
do local r=B.mkrng();local v={};for i=1,12 do v[i]=math.floor(r()*2147483647+.5) end;add('rng',{},v) end
for _,list in ipairs({{},{'a'},{'a','b','c'}}) do for _,roll in ipairs({0,.1,.333333333,.999999,1}) do
 local n=0;local v=H.pickl(function() n=n+1;return roll end,list)
 add('pick',{list=list,roll=roll},{value=v or false,calls=n})
end end
for _,n in ipairs({-2,0,1,2,3,4,5}) do for order=0,4 do for _,roll in ipairs({0,.349999,.35,1}) do for _,override in ipairs({false,0,1,5,8}) do
 local calls=0;local v=H.party_target(n,order,function() calls=calls+1;return roll end,override or nil)
 add('party_target',{n=n,order=order,roll=roll,override=override},{value=v,calls=calls})
end end end end
-- Ordinary inputs capture the real nested closures, including the DFS fallback.
for f=1,80 do for _,kind in ipairs({'battle','elite'}) do
 local result=B.compose(f,{floor=f,party_n=4,kind=kind})
 add('compose',{seed=f,ctx={floor=f,party_n=4,kind=kind}},result)
end end
assert(H.dfs,'ordinary inputs did not enter DFS')
for _,kind in ipairs({'battle','elite'}) do
 B.compose(1,{floor=1,party_n=4,kind=kind})
 for _,t in ipairs(B.TEMPLATES) do for tc=0,8 do
  add('slots',{template=t,tc=tc,elite=kind=='elite'},H.build_slots(t,tc))
 end end
end
for _,seed in ipairs({0,1,777,2147483646}) do for _,list in ipairs({{},{'a'},{'a','b'},{'a','b','c','d','e'}}) do
 add('shuffle',{seed=seed,list=list},H.shuffle_run(seed,copy(list)))
end end
for _,roll in ipairs({0,.5,1}) do for _,list in ipairs({{}, {'a'}, {'a','b','c','d'}}) do
 add('shuffle_roll',{roll=roll,list=list},H.shuffle_roll(roll,copy(list)))
end end
local pool={'apprentice_doll','rusted_shieldman','raging_lecturer'}
for _,seed in ipairs({0,1,777}) do for _,budget in ipairs({0,1,2,8,100}) do for _,limit in ipairs({0,3,100}) do for _,umin in ipairs({0,3,4,7}) do for _,borrowed in ipairs({false,true}) do
 local opts={mobs=pool,elites={'raging_lecturer'},borrowed=borrowed,limit=limit,umin=umin}
 local sl={{role={'돌격'}},{grade={'elite'}}}
 local input={seed=seed,slots=sl,k=1,fl={},fg={},budget=budget,opts=opts}
 add('dfs',input,H.dfs(seed,sl,1,{},{},{n=budget},opts))
end end end end end
for _,sl in ipairs({{},{{role={'absent'}}}}) do
 local opts={mobs={},elites={},borrowed=false,limit=0,umin=0}
 add('dfs',{seed=1,slots=sl,k=1,fl={},fg={},budget=10,opts=opts},H.dfs(1,sl,1,{},{},{n=10},opts))
end
for _,ctx in ipairs({{floor=28,kind='battle'},{floor=3,kind='boss'},{zone='bottom',kind='chief'}}) do
 local ok=pcall(B.compose,1,ctx)
 if ok then for _,fl in ipairs({{}, {'apprentice_doll'}, {'raging_lecturer'},{'apprentice_doll','raging_lecturer'}}) do
  add('result',{base=H.result({}, {},'probe',false),fl=fl,fg={},raid=false},H.result(fl,{},'probe',false))
 end end
end
for bits=0,63 do
 local st=fresh();for j=1,6 do st.u[j].al=(bits//2^(j-1))%2;st.u[j].hp=st.u[j].al*1000 end
 add('foes',{bits=bits},H.foes(st))
 for t=5,6 do for _,row in ipairs({'전열','후열'}) do
  B.DEF[t].row=row;add('behind',{bits=bits,t=t,row=row},slot(H.behind(st,t)))
 end end
end
for _,value in ipairs({false,1,'bad',{}, {keep=17}}) do
 local st=fresh();st.u[1].x=copy(value);local x=H.xs(st,1);local same=x==st.u[1].x;x.changed=7
 add('xs',{value=value},{same=same,value=x,again=H.xs(st,1)==x})
end
for _,value in ipairs({false,{}, {keep=17}}) do for _,live in ipairs({false,true}) do
 local st=fresh();st.u[5].x=copy(value);if type(st.u[5].x)=='table' then st.u[5].x.cor=2 end
 st.u[5].dot=live and {{d=2,n=1,c=1}} or {}
 local n=H.cor_live(st.u[5]);add('cor_live',{value=value,live=live},{value=n,cor=type(st.u[5].x)=='table' and st.u[5].x.cor or false})
end end
for _,magic in ipairs({false,true}) do for _,acts in ipairs({{},{{kind='atk'}},{{magic=true}},{{ic='spell'}},{{kind='spell'}},{{ic='attack'},{ic='spell'}}}) do
 local st=fresh();B.DEF[5].magic=magic;B.DEF[5].acts=acts
 add('magic',{magic=magic,acts=acts},H.has_magic(5))
 for ia=1,#acts+1 do st.u[5].ia=ia;add('casting',{acts=acts,ia=ia},H.casting(st,5)) end
end end
for bits=0,15 do for _,isfresh in ipairs({false,true}) do for n=-1,3 do
 local u={bf={}};for i,k in ipairs({'atk','ddn','red20','psguard'}) do if (bits//2^(i-1))%2==1 then u.bf[k]={v=.2,n=n,f=isfresh or nil,src=2,db=true,keep='value'} end end
 B.btick(u);add('btick',{bits=bits,fresh=isfresh,n=n},u.bf)
end end end
for count=0,4 do for _,per in ipairs({-3,0,1,7}) do for n=-1,3 do
 local st=fresh();for i=1,count do B.edot_add(st,1,5,i,i) end;B.edot_add(st,1,6,per,n)
 add('edot',{count=count,per=per,n=n},st.u[1].edot)
end end end
for _,el in ipairs({false,'none','fire','ice','bolt','light','dark','wind'}) do for _,wk in ipairs({false,{}, {'fire'},{'ice','fire','fire'}}) do
 local st=fresh();B.DEF[5].wk=wk or nil;add('weak',{el=el,wk=wk},B.isweak(5,el or nil))
end end
for _,n in ipairs({-1,0,1,2,3,4,100}) do add('sy_level',{n=n},H.lv(n)) end
for _,value in ipairs({false,1,'bad',{}, {keep=17}}) do
 local u={x=copy(value)};local x=H.tr_xs(u);local same=x==u.x;x.changed=7
 add('tr_xs',{value=value},{same=same,value=x,again=H.tr_xs(u)==x})
end
local cids={'','unknown','persona'};for id in pairs(B.CAST) do cids[#cids+1]=id end;table.sort(cids)
local classes={};for id in pairs(B.CLS) do classes[#classes+1]=id end;table.sort(classes)
for _,id in ipairs(classes) do local c=B.CLS[id]
 for _,id in ipairs({c.id,c.name}) do add('class',{id=id},B.cls_of(id)) end
 for _,id in ipairs({c.id,c.name}) do add('class_ref',{id=id,canonical=c.id},B.cls_of(id)==B.cls_of(c.id)) end
 for _,L in ipairs({false,'bad',' 3 ','1e1','0x10','0x1.8p-1',-1,0,1,10,40,99,2.7}) do
  for _,id in ipairs(cids) do
   add('stats',{cls=c.id,L=L,cid=id},B.party_stats(c.id,L,id))
   local v={};for _,pair in ipairs({{'str','atk'},{'agi','atk'},{'int','atk'},{'hp','hp'},{'mp','mp'},{'def','def'}}) do v[#v+1]=H.stat(pair[1],pair[2]) end
   add('stat',{cls=c.id,L=L,cid=id},v)
  end
 end
end
do local u={};B.btick(u);add('btick',{bits=0,fresh=false,n=1,missing=true},u.bf or {}) end
for _,id in ipairs({'unknown','',false,12}) do add('class',{id=id},B.cls_of(id) or false);add('stats',{cls=id,L=1,cid=''},B.party_stats(id,1) or false) end
for _,L in ipairs({0,1,2,2.7,10,40,99}) do add('K',{L=L},B.K_of(L)) end
add('K',{},B.K_of())
for _,kind in ipairs({'normal','chief','boss','unknown'}) do
 B.floor_final_reset();local a={B.floor_final(12,kind)}
 local curve=B.CURVE[kind] or B.CURVE.normal;local old=curve.pts[1][2];curve.pts[1][2]=old*2
 local cached={B.floor_final(12,kind)};B.floor_final_reset();local changed={B.floor_final(12,kind)}
 curve.pts[1][2]=old;B.floor_final_reset()
 add('reset',{kind=kind},{first=a,cached=cached,changed=changed})
end
for n=0,4 do
 local st=fresh();local ids={}
 for i=1,4 do B.DEF[i].cid=i<=n and ({'levia','naran','levia','felice'})[i] or '';ids[i]=B.DEF[i].cid end
 for i=0,9 do add('cid',{ids=ids,i=i},B.cid(i)) end
 for _,id in ipairs({'','naran','levia','felice','missing'}) do add('slot_of',{ids=ids,id=id},B.slot_of(st,id) or 0) end
end
for _,foe in ipairs({false,{}, {5},{5,6},{5,6,7,8,9,10}}) do
 add('enemy0',{foe=foe},B.enemy0({foe=foe or nil}))
end
return out

