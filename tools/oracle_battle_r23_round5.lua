local H=B.__batch
local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,input,expected)
 local function schema(L)
  for _,key in ipairs({'u','icwf','hit','hk','cls','vars','lun','trg','drn','spawn'}) do
   if L[key] then local t={};for k,v in pairs(L[key]) do t[tostring(k)]=v end;L[key]=t end
  end
 end
 if type(expected)=='table' then
  if expected.L then schema(expected.L) elseif expected.layers then schema(expected.layers) elseif expected.bz then schema(expected) end
 end
 out.rows[#out.rows+1]={op=op,input=input,expected=expected};out.counts[op]=(out.counts[op] or 0)+1
end
local function layers(cuts)
 local L={u={},icwf={},hit={},hk={},bz={},panel='',field='',party='',cls={},vars={},lun={},trg={},drn={}}
 if cuts then L.cuts={} end
 return L
end
local function defs()
 local st=fresh()
 for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].art='art'..i;B.DEF[i].clsid='warrior' end
 return st
end
local phase_foes={'apprentice_doll','missing'}
for id,f in pairs(B.FOES) do if f.ph2 then phase_foes[#phase_foes+1]=id end end;table.sort(phase_foes)
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,t in ipairs({-.125,0,.005,.125,1.999,12.375}) do
  for _,x in ipairs({false,'','left:0%;--k:2'}) do add('sv',{t=t,x=x},H.fx_sv(t,x or nil)) end
  for _,txt in ipairs({'',0,17,'<b>test</b>','피해'}) do
   for _,cls in ipairs({false,'','h','g special'}) do for _,left in ipairs({false,0,50}) do for _,top in ipairs({false,0,56}) do
    add('fx_dn',{txt=txt,t=t,cls=cls,left=left,top=top},B.fx_dn(txt,t,cls or nil,left or nil,top or nil))
   end end end
   add('fx_cn',{txt=txt,t=t,lang=lang},B.fx_cn(txt,t))
   for _,cls in ipairs({false,'','ab'}) do add('fx_plaque',{txt=txt,t=t,cls=cls},B.fx_plaque(txt,t,cls or nil)) end
  end
 end
end
B.LANG='ko'
for _,slot in ipairs({1,4,5,16}) do
 local L=layers(true);H.fx_put(L,slot,'first');H.fx_put(L,slot,'');H.fx_put(L,slot,'<b>next</b>');add('fx_put',{slot=slot},L)
end
for _,k in ipairs({false,0,1,2}) do for _,rank in ipairs({0,1,2.5,3}) do
  local L=layers(false);B.bz_add(L,'z6',.125,k or nil,rank);add('bz_add',{k=k,rank=rank,cuts=false},L)
end end
for _,slot in ipairs({1,4,5,16}) do for tier=0,2 do for flags=0,15 do for _,el in ipairs({'','fire','ice','bolt','wind','holy','dark','missing'}) do
 local L=layers(true);local o={tier=tier,el=el,arc=(flags%2==1) and 96 or nil,crit=(flags//2)%2==1,abfx=(flags//4)%2==1,k=flags>=8 and 2 or nil,r=0}
 local hs=B.fx_hit(L,slot,.5,o)
 -- A later hit must retain the first icwf/hit/hk even when stronger.
 if flags>=8 then B.fx_hit(L,slot,.8,{tier=2,k=3}) end
 add('fx_hit',{slot=slot,o=o,repeat_hit=flags>=8},{L=L,hs=hs})
end end end end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,slot in ipairs({1,5}) do for _,ab in ipairs({false,0,2.5}) do for n=0,3 do
  local L=layers(true);local r={i=slot,ab=ab or nil,list={}};for i=1,n do r.list[i]={i=4+i,n=i*7} end
  B.fx_abyss(L,r,.125);add('fx_abyss',{r=r,lang=lang},L)
 end end end
 for _,slot in ipairs({1,5}) do for _,d in ipairs({0,1,299,300,599,600}) do for _,sh in ipairs({0,1,300,600}) do for flags=0,15 do
  local L=layers(true);local r={i=slot,d=d,sh=sh,c=flags%2,ab=flags>=8 and 3 or 0,tags={}}
  if (flags//2)%2==1 then r.tags={'약점 화염','고갈','여우불','normal'} end
  local o={tier=0,last=(flags//4)%2==1,el='bolt',arc=92,r=24,abfx=flags>=8}
  B.fx_result(L,r,.5,o);add('fx_result',{r=r,o=o,lang=lang},L)
 end end end end
end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,cuts in ipairs({false,true}) do for _,line in ipairs({false,'','대사 <raw>'}) do
  defs();local L=layers(cuts);B.fx_cutin(L,2,'스킬',line or nil,.125)
  add('fx_cutin',{cuts=cuts,line=line,lang=lang},L)
 end end
 for _,cuts in ipairs({false,true}) do for _,vid in ipairs({false,true}) do for _,image in ipairs({false,17,'','{{inlayed::abc}}','{{inlayed::}}','data:image/png;base64,abc','http://x/a?b="&<\'','https://x/p','ftp://x','prefix https://x','host-error'}) do
  defs();local old=getChatVar;getChatVar=function()if image=='host-error' then error('fixture host unavailable') end;return image end;B.VID=vid and 'test' or nil
  local L=layers(cuts);B.fx_pcutin(L,1,'스킬',.125);getChatVar=old;B.VID=nil
  add('fx_pcutin',{cuts=cuts,vid=vid,image=image,lang=lang},L)
 end end end
end
local events={'atk','snipe','wave','burst','eatk','shield','taunt','def','oath','mark','rev','chg','cut','trait','deplete','recover','edef','ebuff','eall','edeb','eheal','item','esum','echg','ecut','phase','adot','end','unknown'}
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,kind in ipairs(events) do for v=0,15 do
  local st=defs();local L=layers(true);local e={k=kind,a=v%2==0 and 1 or 2,t=.125,ht=1.25,nm=v%2==0 and '일반 공격' or '스킬',el='fire',d=37,line=v%2==0 and '' or '대사',last=v%4==1,big=v%2,shoot=(v//2)%2,ab=v%2,pc=v%2==1,win=v%2,tg={}}
  if kind:sub(1,1)=='e' then e.a=5 end
  if kind=='cut' and e.pc then B.VID=nil end
  local n=(v//4)%4
  if kind=='atk' or kind=='snipe' or kind=='eatk' or kind=='taunt' or kind=='oath' or kind=='mark' or kind=='chg' or kind=='adot' then n=math.max(n,1) end
  for i=1,n do e.tg[i]={i=(kind=='eatk' or kind=='eall' or kind=='adot') and i or (kind=='oath' and e.a or 4+i),d=(v%4)*300,sh=(v//4)*100,c=v%2,ab=v%3,tags=v%2==0 and {} or {'약점','고갈'},f=({'mp','cure','sh','hp'})[i%4+1],list={{i=6,n=7}}} end
  if v>=8 then st.u[5].al=0;st.ev.pre[5].hp=v>=12 and 0 or 1 end
  local input={e=cp(e),state={u=cp(st.u),ev=cp(st.ev)},lang=lang}
  B.fx_event(st,e,L);add('fx_event',input,L)
 end end
end
B.LANG='ko'
do
 local st=defs();local L=layers(true);local seq={}
 for _,kind in ipairs({'shield','cut','atk','trait','esum','phase','end'}) do
  local e={k=kind,a=1,t=#seq*.7,ht=#seq*.7+.4,nm='스킬',line='대사',win=1,tg={{i=5,d=350,sh=10,c=0,ab=2,tags={'약점'}}}}
  seq[#seq+1]=cp(e);B.fx_event(st,e,L)
 end
 add('fx_sequence',{events=seq,state={u=cp(st.u),ev=cp(st.ev)},lang='ko'},L)
end
-- Render primitives exercise the same HP/MP/abyss record generated by the ABI.
for _,v in ipairs({-1,0,1,17}) do for _,k in ipairs({false,'','key'}) do add('numspan',{v=v,k=k},H.numspan(v,k or nil)) end end
for _,c in ipairs({'','x','g','r'}) do for _,txt in ipairs({'','raw <b>','보호막'}) do add('chip',{c=c,txt=txt},H.chip(c,txt)) end end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,v in ipairs({false,{}, {n=-1},{n=0},{n=.5},{n=3}}) do add('chip_tn',{v=v,lang=lang},B.chip_tn(v or nil)) end
 for n=0,5 do local v={};for i=1,n do v[i]={n=i%2==0 and -1 or i} end;v[#v+1]={};add('chip_dotn',{v=v},B.chip_dotn(v)) end
 for _,i in ipairs({1,4,5,8,9,16}) do for _,mode in ipairs({'missing','legacy','foe'}) do
  defs();if mode=='missing' then B.DEF[i]=nil elseif mode=='legacy' and i>4 then B.DEF[i]={name='legacy'} elseif mode=='foe' then B.DEF[i]={foe='x',name='적 이름'} end
  add('sn',{i=i,mode=mode,lang=lang},B.sn(i))
 end end
 for _,ic in ipairs({'summon','charge','heal','protect','atk','', 'custom'}) do add('icn',{ic=ic},B.icn(ic)) end
 for _,f in ipairs({'hp','mp','ay','sh'}) do for _,v in ipairs({0,29,30,31,100,125}) do for flags=0,15 do
  local u={hp=100,mhp=100,mp=100,mmp=100,ay=100,ym=100,sh=100};u[f]=v;local K={{}}
  if flags%2==1 then K[1][f]='k3u1'..f end
  local c={f=f,v=v,flags=flags,lang=lang};local cls=f=='ay' and 'ab' or f
  add('hp_stat',c,B.hp_stat('label',cls,u,f,100,K,1,(flags//2)%2==1,(flags//4)%2==1,flags>=8 and 50 or nil))
 end end end
end
-- CSS interval adjustment, recovery/damage, zero maximum, absent event and no history.
for _,D in ipairs({-1,0,.1,1,10}) do for mode=0,7 do
 local st={n=7,u={{hp=30,mhp=100,mp=5,mmp=10,ay=0,ym=30,sh=20}},ev={pre={{hp=100,mp=10,ay=30,sh=0}},h={{}}}}
 if mode==0 then st.ev=nil
 elseif mode>1 then
  for _,f in ipairs({'hp','mp','sh','ay'}) do
   for n=1,3 do st.ev.h[1][#st.ev.h[1]+1]={f=f,t=mode==2 and 0 or (mode==3 and 9 or 1/n),v=mode==4 and n*30 or (mode==5 and 100-n*20 or 0)} end
  end
  if mode==6 then st.u[1].mhp=0;st.u[1].mmp=0;st.u[1].ym=0 end
 end
 local s,K=B.dyn(st,D);add('dyn',{state=st,D=D},{css=s,K=K})
end end
for _,v in ipairs({-.005,-.125,.125,.375,1.125,1.325,1.425,2.675,12.375,.125+1.2,.125+1.3,.125+.05,.125+.1}) do
 add('printf',{v=v},{one=string.format('%.1f',v),two=string.format('%.2f',v)})
end
for n=-400,400 do local v=n/200;add('printf',{v=v},{one=string.format('%.1f',v),two=string.format('%.2f',v)}) end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,act in ipairs({false,true,0,''}) do add('kchip',{act=act,lang=lang},B.kchip(act)) end
 for n=0,8 do for _,at in ipairs({-1,0,.125,1.325}) do
  local st={log={}};for i=1,n do st.log[i]={h='log <b>'..i..'</b>',t=i%2==0 and at or -1} end
  add('log',{state=st,lang=lang},B.r_log(st))
 end end
 for _,cls in ipairs({'warrior','gladiator','archer','assassin','sanctioned','unsanctioned','paladin','priest','alchemist','chaos','missing',''}) do for _,used in ipairs({false,0,1,2}) do for _,al in ipairs({0,1}) do
  local st={u={{ps=used or nil,al=al}}};add('pbadges',{state=st,cls=cls,lang=lang},B.pbadges(st,1,{clsid=cls}))
 end end end
 for _,foe in ipairs(phase_foes) do for ph=0,2 do
  local st={u={{ph=ph}}};B.DEF[1]={foe=foe};add('pips',{foe=foe,ph=ph,lang=lang},H.pips(st,1))
 end end
 for _,slot in ipairs({1,5}) do for bits=0,255 do for mode=0,3 do
  local st=defs();local w=st.u[slot]
  w.al=mode==3 and 0 or 1;w.sh=bits%2==1 and 17 or 0;w.tau=(bits//2)%2;w.df=(bits//4)%2;w.chg=(bits//8)%2;w.cq=(bits//16)%2
  w.pt=(bits//32)%2==1 and 2 or 0;w.hid=(bits//64)%2;w.sil=bits>=128 and 'atk' or ''
  w.oath=mode>=1 and 4 or 0;w.rv=mode>=1 and 1 or 0;w.mk=mode>=2 and 1 or 0;w.fx=mode>=2 and 3 or 0;w.am=mode>=2 and 1.4 or 1;w.seal=mode>=2 and 1 or 0;w.lf=mode>=2 and 1 or 0
  w.bf={};for n,k in ipairs({'atk','def','adn','ddn','spd','sdn','bl','g2','bs'}) do if bits%2^(n%8+1)>=2^(n%8) then w.bf[k]={v=.2,n=mode==0 and 0 or 3} end end
  w.dot=mode>0 and {{n=2},{n=5}} or {};w.edot=mode>1 and {{n=3},{n=1}} or {}
  add('chips',{state={u=st.u},slot=slot,lang=lang},B.chips(st,slot))
 end end end
 for _,kind in ipairs({'atk','dot','special','debuff','buff','heal','summon','protect','charge','guard','missing'}) do for _,target in ipairs({'self','ally','allies','all'}) do for _,taunt in ipairs({false,true}) do for _,all in ipairs({false,true}) do
  local st=defs();st.u[5].it=2;st.u[1].tau=taunt and 2 or 0
  local act={kind=kind,target=target,all=all,ic=kind,name='행동'};local L={taunt=.125}
  add('intent',{state=st,act=act,lang=lang},B.intent_text(st,5,act,L))
 end end end end
end
-- Expose render-local functions through a real render, then call them directly.
do
 local st=defs();local old=table.sort;table.sort=function(list,fn)if fn then H.camera_before=fn end;return old(list,fn)end;B.render(st);table.sort=old
 for _,rank in ipairs({0,1,2.5,3}) do for _,other in ipairs({0,1,2.5,3}) do for _,t in ipairs({0,.25,.250001}) do
  local p={cls='z3',rank=rank,t=t};local q={cls='z6',rank=other,t=.25}
  add('camera_compare',{p=p,q=q},H.camera_before(p,q))
 end end end
 for _,x in ipairs({false,{cls='z3',t=0},{cls='z6',t=.125,k=0},{cls='zz',t=1.325,k=1},{cls='z6',t=.5,k=2}}) do add('bzo',{x=x},H.bzo('bpi',x or nil)) end
end
local function defview()
 local list={};for i=1,6 do local d=B.DEF[i];local out={};for _,k in ipairs({'name','art','clsid','cid','line','lv','empty','ic','glyph','elite'}) do out[k]=d[k] end;list[i]=out end;return list
end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,idx in ipairs({1,5,6}) do for _,pos in ipairs({1,2}) do for _,mark in ipairs({false,{'chg','충전'},{'adv','당김'}}) do for _,lost in ipairs({false,true}) do for mode=0,2 do
  local st=defs();B.DEF[idx].art=mode==0 and 'test' or '';B.DEF[idx].cid=mode==1 and 'persona' or '';B.DEF[idx].elite=mode==2
  if idx>=5 and mode==2 then B.DEF[idx].ic=nil;B.DEF[idx].glyph='glyph' end
  add('tile',{state=st,defs=defview(),idx=idx,pos=pos,mark=mark,lost=lost,lang=lang},H.tile(st,idx,pos,mark or nil,lost))
 end end end end end
 for bits=0,15 do for _,queue in ipairs({{}, {1}, {1,5,2,5,6,2,1}, {6,5,4,3,2,1}}) do for _,over in ipairs({'','win'}) do
  local st=defs();st.q=queue;st.cur=1;st.over=over
  for i=1,4 do st.u[i].chg=(bits//2^(i-1))%2 end
  st.u[5].dr=bits%2;st.u[6].dr=(bits//2)%2
  st.ev.list={{k='chg',tg={{i=2}}},{k='trait',a=1,nm='상대성 이론'},{k='trait',a=2,nm='상대성 이론'},{k='trait',a=3,nm='other'}}
  if bits>=8 then st.ev=nil end
  add('rail',{state=st,defs=defview(),lang=lang},B.r_rail(st))
 end end end
 for bits=0,31 do for n=0,4 do
  local st=defs();st.n=bits%2;st.star=(bits//2)%8+1;st.dk=bits>=16 and 1 or 0;st.dc=3;st.place=bits%2==0 and '장소 <&"\'>' or nil;st.el=1
  for i=1,4 do B.DEF[i].empty=i>n and true or nil;B.DEF[i].lv=i*3;B.DEF[i].cid=i==1 and bits%2==1 and 'persona' or 'other';B.DEF[i].line=i<=2 and '지능' or '힘';st.u[i].al=i<=n and 1 or 0;st.u[i].rc='halfelf';st.u[i].na='border' end
  add('head',{state=st,defs=defview(),lang=lang},B.r_head(st))
 end end
end
B.LANG='ko'
for _,active in ipairs({false,true}) do
 local st=defs();st.ev.list={{k='atk',a=1,t=.125,ht=.6,nm='일반 공격',tg={{i=5,d=300,sh=17,c=1,ab=3,tags={'약점'}}}},{k='cut',a=2,t=1.325,nm='기술',line='대사'}}
 st.ev.T=3;B.setf(st,5,'hp',700,.6);B.say(st,'<b>source log</b>',.8)
 if not active then st.ev=nil end
 local input={state=cp(st),defs=defview(),lang='ko'};local L=layers(true)
 if st.ev then for _,e in ipairs(st.ev.list) do B.fx_event(st,e,L) end end
 local css,K=B.dyn(st,st.ev and st.ev.T+.8 or 0)
 add('frame',input,{layers=L,dynamic={css=css,K=K},log=B.r_log(st)})
end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,vid in ipairs({false,true}) do for _,image in ipairs({false,17,'','{{inlayed::abc}}','data:image/png;base64,x','http://x/a?b="&<\'','https://x/p','ftp://x','host-error'}) do
  local st=defs();B.DEF[1].art='';B.DEF[1].cid='persona';st.q={1,1,2,5};st.over=''
  local old=getChatVar;getChatVar=function()if image=='host-error' then error('fixture host unavailable') end;return image end;B.VID=vid and 'test' or nil
  local input={state=st,defs=defview(),idx=1,pos=1,mark=false,lost=false,lang=lang,image=image,vid=vid}
  add('tile',input,H.tile(st,1,1,nil,false));add('rail',input,B.r_rail(st));getChatVar=old;B.VID=nil
 end end
end
B.LANG='ko'
do
 local L=layers(true);local o={tier=false,el=false,arc=0,r=false,k=false,crit=false,abfx=false}
 local hs=B.fx_hit(L,5,.5,o);add('fx_optional',{kind='hit'},{L=L,hs=hs})
 local r={i=5,d=1,sh=0,c=0,tags=false,ab=false,list=false};local L=layers(true);B.fx_result(L,r,.5,o);add('fx_optional',{kind='result'},L)
 local st=defs();local L=layers(true);B.fx_event(st,{k='atk',a=1,t=.125,ht=false,nm='일반 공격',tg={{i=5,d=1,sh=0,c=0}}},L);add('fx_optional',{kind='event'},L)
 add('chip_tn',{v={n=false},lang='ko'},B.chip_tn({n=false}))
end
-- Native personal hooks: preserve complete records, health and buff side effects.
B.LANG='ko'
for _,variant in ipairs({1,2}) do for _,target in ipairs({1,2}) do for _,hp in ipairs({0,500,999,1000}) do for _,g in ipairs({-1,0,1000,12000}) do
 local st=defs();st.log={};st.u[target].hp=hp;st.u[target].al=hp>0 and 1 or 0;st.u[target].g=g
 local old=B.GEN.tr.miko.variant;B.GEN.tr.miko.variant=variant
 B.PRUN.miko(st,1,target,{name='test (memo)'})
 B.GEN.tr.miko.variant=old
 add('miko_full',{variant=variant,target=target,hp=hp,g=g},{hp=st.u[target].hp,g=st.u[target].g,mk=st.u[target].x.mk or false,events=st.ev.list,h=st.ev.h,log=st.log,T=st.ev.T})
end end end end
for bits=0,15 do for mode=0,3 do for _,hp in ipairs({500,1000}) do
 local st=defs();st.log={}
 for i=1,4 do st.u[i].al=(bits//2^(i-1))%2;st.u[i].hp=st.u[i].al==1 and hp or 0
  if mode%2==1 then B.badd(st.u[i],'adn',.2,2) end
  if mode>=2 then B.badd(st.u[i],'ddn',.3,3) end
 end
 B.TR.urda.round(st,1)
 local units={};for i=1,4 do units[i]={hp=st.u[i].hp,bf=st.u[i].bf} end
 add('urda_round_full',{bits=bits,mode=mode,hp=hp},{units=units,events=st.ev.list,h=st.ev.h,log=st.log,T=st.ev.T})
end end end
for _,taunt in ipairs({false,true}) do for _,cached in ipairs({false,true}) do for _,target in ipairs({1,2}) do for _,kind in ipairs({'atk','guard','missing'}) do for _,roll in ipairs({0,.349999,.35,1}) do for _,xmap in ipairs({false,true}) do
 local st=defs();st.log={};st.u[1].tau=taunt and 1 or 0
 for j=5,6 do st.u[j].it=target;st.u[j].x=xmap and {keep=7,hg=1,hgk=cached and st.u[j].ia or 0} or false;B.DEF[j].acts=kind=='missing' and {} or {{kind=kind}} end
 local old=B.rnd;local calls=0;B.rnd=function()calls=calls+1;return roll end
 B.TR.hildegard.start(st,1);B.rnd=old
 local es={};for j=5,6 do es[#es+1]={it=st.u[j].it,x=st.u[j].x} end
 add('hildegard_full',{taunt=taunt,cached=cached,target=target,kind=kind,roll=roll,xmap=xmap},{enemies=es,events=st.ev.list,log=st.log,T=st.ev.T,calls=calls})
end end end end end end
local phase_ids={};for id,f in pairs(B.FOES) do if f.ph2 then phase_ids[#phase_ids+1]=id end end;table.sort(phase_ids)
local terms,seen={},{}
local function collect(v)
 if type(v)=='string' then terms[v]=true
 elseif type(v)=='table' and not seen[v] then seen[v]=true;for k,x in pairs(v) do collect(k);collect(x) end end
end
for _,v in ipairs({B.CAST,B.CLS,B.FOES,B.PASSIVES,B.KIT,B.ATK,B.DF,B.PSK,B.CUTLINE,B.PERSONA}) do collect(v) end
local list={};for k in pairs(terms) do list[#list+1]=k end;table.sort(list)
out.constants={ui=B.ui_pack('en'),words=B.en_dict(),pbadges=B.PBADGE,phase_ids=phase_ids,combat_terms=list}
return out
