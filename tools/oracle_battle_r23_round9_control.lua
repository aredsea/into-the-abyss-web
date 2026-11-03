local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,c,v)out.rows[#out.rows+1]={op=op,input=cp(c),expected=cp(v)};out.counts[op]=(out.counts[op]or 0)+1 end
local originalTR,originalGH=B.TR,B.GH
-- Synthetic callbacks expose dispatch order, nil/false/zero composition,
-- argument forwarding, input-array mutation and SKON restoration separately.
for _,op in ipairs({'fire','chain','chain_at'})do for bits=0,31 do for _,mode in ipairs({'nil','false','zero','number'})do
 local s=fresh();local trace={};B.TR={};B.GH={};B.SKON='active'
 for i=1,4 do B.DEF[i]={cid='h'..i};s.u[i].al=bits//(2^(i-1))%2;local owner=i
  B.TR['h'..i]={probe=function(st,o,v,a,b)
   trace[#trace+1]={owner=o,value=v,one=a,two=b,skill=B.SKON or false}
   if mode=='false'then return false elseif mode=='zero'then return 0 elseif mode=='number'then return (type(v)=='number'and v or 0)+owner end
  end}
 end
 if bits>=16 then B.GH.probe=function(st,v,a,b)trace[#trace+1]={owner=0,value=v,one=a,two=b,skill=B.SKON or false};return mode=='number'and 99 or nil end end
 local c={bits=bits,mode=mode,state=cp(s),defs=cp(B.DEF),method=op};local args={7,'payload',false};local result
 if op=='fire'then B.fire(s,'probe',table.unpack(args))elseif op=='chain'then result=B.chain(s,'probe',7,'payload',false)else result=B.chain_at(s,'probe',1,args)end
 add('hook_dispatch',c,{trace=trace,value=result==nil and 'nil' or result,args=args,skill=B.SKON})
end end end
B.TR=originalTR;B.GH=originalGH;B.SKON=nil
-- Isolate B.act's control decisions from the independently tested player/run
-- engine. The original function itself still supplies every branch decision.
local player,run,again,can,begin=B.player,B.run,B.again,B.can_use,B.begin_ev
for _,action in ipairs({'','bad','cancel','reset','sk_0','sk_1','sk_2','sk_3','sk_99','tg_0','tg_1','tg_2','tg_4','tg_5','tg_6','tg_7','SK_1','sk_-1','tg_1x'})do for bits=0,63 do
 B.begin_ev=begin
 local s=fresh();local calls={};s.cur=1;s.pend=bits%3;s.pid='old';s.imenu=bits//4%2;s.ipk='hp_s'
 s.over=bits//8%2==1 and 'win' or '';s.qid=bits//16%2==1 and 'quest' or nil;s.u[2].al=bits//32%2;s.u[5].al=bits//32%2
 local sk={{id='atk',tgt='enemy'},{id='heal',tgt='ally',cid=bits%2==1 and 'marceline' or 'neutral'},{id='defend',tgt='none'}};B.SK[1]=sk
 local allowed=bits//2%2==1
 B.can_use=function(st,i,k)return allowed end
 B.begin_ev=function(st)calls[#calls+1]={'begin'};st.ev={fresh=true}end
 B.player=function(st,n,t)calls[#calls+1]={'player',n,t}end
 B.run=function(st)calls[#calls+1]={'run'}end
 B.again=function(st)calls[#calls+1]={'again'};return {restarted=true}end
 local c={state=cp(s),skills=cp(B.SK),action=action,allowed=allowed};local result=B.act(s,action)
 add('act_control',c,{state=result,calls=calls})
end end
B.player=player;B.run=run;B.again=again;B.can_use=can;B.begin_ev=begin
-- Cover the remaining initializer/phase/legacy/automatic-release branches in
-- one source execution. These observations remain explicitly source-only
-- until the native full-state contract is available.
local source={}
do
 local s=fresh();s.u[1].hp=0;s.u[1].al=1;s.u[1].sh=10;s.u[1].shT=2
 local before=cp(s);local result=B.strike(s,1,1,.2,nil,5)
 source[#source+1]={op='damaged_alive_flag_with_zero_hp',input=before,result=result,state=cp(s)}
end
do
 local s=fresh();s.n=320
 for i=1,4 do s.u[i].hp=100000;s.u[i].mhp=100000;s.u[i].g=1000000000 end
 for i=5,6 do s.u[i].g=0;B.DEF[i].acts={{kind='guard',name='guard'}};s.u[i].ia=1 end
 local before=cp(s);B.run(s)
 source[#source+1]={op='run_guard_80_end',input=before,state=cp(s)}
end
for _,legacy in ipairs({false,true})do
 local s
 if legacy then local saved=B.run;B.run=function()end;s=B.fresh(1);B.run=saved;B.bind(s)else s=fresh()end
 B.begin_ev(s);s.u[1].tau=2;s.u[1].hp=1000;s.u[1].g=-100;s.u[1].chg=1;s.rs=1
 if not legacy then s.gb={t=1,d=10};s.u[1].gu={{key='pa_echo',v={50}}};B.strike(s,1,1,.2,nil,5)end
 if legacy then s.u[8].ia=5;B.enemy_turn(s,8)else
  B.DEF[5].ph2={wk={},acts={{kind='guard',name='phase'}}};s.u[5].ph=1;s.u[5].hp=1;s.u[5].mhp=1000
  B.strike(s,5,100,.2);s.u[5].ph=2
 end
 B.run(s);source[#source+1]=cp(s)
end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,prefix in ipairs({'','strike','heal'})do for _,level in ipairs({0,10})do
  local saved={prefix='strike',suffix='fire',prefix_lv={},suffix_lv={}}
  local draft={prefix=prefix,suffix=prefix=='heal'and 'regen'or 'fire',prefix_lv={[prefix]=level},suffix_lv={fire=level,regen=level}}
  source[#source+1]={op='research_tab',html=B.ps_guild_tab({persona={skill=saved},ui={psd=draft},gold=0})}
 end end
end
out.source_only=source;B.LANG='ko'
return out
