local out={rows={},counts={}}
local function cp(v) if type(v)~="table" then return v end;local o={};for k,x in pairs(v) do o[k]=cp(x) end;return o end
local function bit(v,n)return math.floor(v/2^n)%2==1 end
local function add(op,c,expected)
 for _,key in ipairs({'u','icwf','hit','hk','cls','vars','lun','trg','drn','spawn'}) do
  local converted={};for k,v in pairs(c.L[key] or {}) do converted[tostring(k)]=v end;c.L[key]=converted
 end
 local vis={};for k,v in pairs(c.visible or {}) do vis[tostring(k)]=v end;c.visible=vis
 out.rows[#out.rows+1]={op=op,input=cp(c),expected=expected};out.counts[op]=(out.counts[op] or 0)+1
end
local bossids={};for id,f in pairs(B.FOES) do if f.ph2 then bossids[#bossids+1]=id end end;table.sort(bossids)
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for bits=0,255 do
  local st=fresh();local boss=bossids[bits%#bossids+1];st.fl={boss,'apprentice_doll'};st.fg={bit(bits,0) and 'eliteb' or 'boss','minion'};st.ne=2;st.el=40;st.dk=bit(bits,1) and 1 or 0
  st.u[5].ph=bit(bits,2) and 2 or 1;st.u[5].cwk={'fire','dark'};B.bind(st)
  st.pend=bit(bits,3) and 1 or 0;st.cur=1;st.over=bit(bits,4) and 'win' or ''
  st.u[5].al=bit(bits,5) and 0 or 1;st.u[5].hp=st.u[5].al==0 and 0 or 37;st.u[5].dr=bit(bits,6) and 1 or 0;st.u[5].ia=bits%#B.DEF[5].acts+1;st.u[5].cq=bit(bits,7) and 1 or 0;st.u[5].ym=100;st.u[5].ay=37;st.u[5].mhp=100
  if bits==255 then st.u[5].empty=1 end
  B.begin_ev(st);if bit(bits,0) then st.ev.h[5]={{f='hp',t=0,v=0},{f='hp',t=.8,v=0}} end
  if bit(bits,1) then st.ev=nil end
  local L={u={},icwf={},hit={},hk={},cls={},vars={},lun={},trg={},drn={},spawn={},field='<b>field</b>',taunt=.125}
  if bit(bits,2) then L.u[5]='<b>fx</b>';L.hit[5]=.125;L.hk[5]=2 end
  if bit(bits,3) then L.lun[5]=0;L.spawn[5]=.5 end
  if bit(bits,4) then L.drn[5]=.25 end
  local K={{},{},{},{},{},{}};if bit(bits,5) then K[5]={hp='kh',ay='ka'} end
  local vis=bit(bits,7) and {[5]=true} or {}
  local d={};for i=1,6 do d[i]=B.DEF[i] end
  local input={state=st,L=L,K=K,visible=vis,defs=d,skills=B.SK,lang=lang,slot=5}
  local normal=B.r_enemy(st,5,L,K,vis);local big=B.r_boss(st,5,L,K,vis);local field=B.raid_field(st,L,K,vis,bit(bits,6))
  add('enemy_tile',cp(input),normal);add('boss_tile',cp(input),big);local c=cp(input);c.target=bit(bits,6);add('raid_field',c,field)
 end
 for bits=0,127 do for _,slot in ipairs({1,4}) do
  local st=fresh();st.pm[slot]={id=bit(bits,0) and 'persona' or 'marceline',cls=bit(bits,1) and 'priest' or 'assassin',L=40};B.bind(st)
  local w=st.u[slot];w.chg=bit(bits,2) and 1 or 0;w.al=bit(bits,3) and 0 or 1;w.sh=bit(bits,4) and 17 or 0;w.ps=bit(bits,5) and 1 or 0
  st.cur=slot;st.pend=bit(bits,6) and B.sk_slot(slot,'p_marceline') or 0;st.pend=st.pend or 0;st.n=bits
  -- Explicit ally-selection metadata, including self-forbidden Marceline.
  B.SK[slot][1]={id='fixture',tgt='ally',cid=bit(bits,1) and 'marceline' or 'missing'};st.pend=bit(bits,6) and 1 or 0
  st.imenu=1;st.ipk='hp_s';st.bag={hp_s=1}
  local L={u={},icwf={},hit={},hk={},cls={},vars={},lun={},trg={},drn={},spawn={},field=''}
  if bit(bits,0) then L.hit[slot]=0;L.cls[slot]=' extra';L.vars[slot]='--fixture:1';L.u[slot]='<b>fx</b>' end
  if bit(bits,1) then L.icwf[slot]=.125;L.trg[slot]=.25 end
  if bits==0 then B.DEF[slot].empty=true end
  local K={{},{},{},{},{},{}};if bit(bits,2) then K[slot]={hp='kh',mp='km',sh='ks'} end
  local d={};for i=1,6 do d[i]=B.DEF[i] end
  local c={state=st,L=L,K=K,visible={},defs=d,skills=B.SK,lang=lang,slot=slot,item_ok=B.it_ok(st,st.ipk,slot)}
  add('ally_tile',c,B.r_ally(st,slot,L,K))
 end end
end
return out
