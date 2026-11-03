local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,input,value)
 out.rows[#out.rows+1]={op=op,input=cp(input),expected=cp(value)};out.counts[op]=(out.counts[op] or 0)+1
end
local specimens={false,{}, {prefix='missing',suffix='missing',prefix_lv={strike='2.9'},suffix_lv={fire=-1}}, {prefix='strike',suffix='fire',prefix_lv={strike=1,volley=7},suffix_lv={fire=3,bleed=2}}, {prefix='heal',suffix='regen',prefix_lv={heal=10},suffix_lv={regen=10}}}
for _,p in ipairs(B.PERSONA.prefixes) do for _,q in ipairs(B.PERSONA.suffixes) do if B.ps_compatible(p,q) then
 specimens[#specimens+1]={prefix=p.id,suffix=q.id,prefix_lv={[p.id]=0},suffix_lv={[q.id]=0}}
end end end
for _,saved in ipairs(specimens) do
 for _,draft in ipairs(specimens) do
  local ui={psd=cp(draft)};local G={persona={skill=cp(saved)},ui=ui}
  add('work',{saved=saved,ui=ui},B.__batch.work(G))
  add('dirty',{saved=saved,ui=ui},B.ps_dirty(G))
  local a,b=B.ps_clean(saved),B.ps_clean(draft)
  add('same',{a=a,b=b},B.__batch.same(a,b))
  add('changes',{a=a,b=b},B.__batch.changes(a,b))
 end
 for _,ui in ipairs({false,0,'',{}, {psd=false},{psd=3},{psd='bad'}}) do
  add('dirty',{saved=saved,ui=ui},B.ps_dirty({persona={skill=saved},ui=ui}))
  if type(ui)=='table' then add('work',{saved=saved,ui=ui},B.__batch.work({persona={skill=saved},ui=ui})) end
 end
end
for _,value in ipairs({false,-1,0,1,1.9,10,11,'3.9','bad','0x2'}) do
 local a=B.ps_clean({prefix='strike',suffix='fire'});local b=cp(a);a.prefix_lv.volley=value;b.prefix_lv.volley=1
 add('same',{a=a,b=b},B.__batch.same(a,b))
 add('changes',{a=a,b=b},B.__batch.changes(a,b))
end
return out
