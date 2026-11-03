local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,c,v)out.rows[#out.rows+1]={op=op,input=cp(c),expected=cp(v)};out.counts[op]=(out.counts[op]or 0)+1 end
local old={load=B.load,save=B.save,send=B.send_result,apply=B.it_apply,ending=B.end_turn,run=B.run,rbegin=B.rbegin,begin=B.begin_ev,have=B.ex_have,bag=B.ex_bag,take=B.ex_take}
local args={'','open','cancel','pick_hp_s','pick_mp_m','pick_bandage','pick_missing','pick_return_scroll','pick_HP_s','pick_hp_s_x','to_0','to_1','to_4','to_5','to_11'}
for _,arg in ipairs(args)do for bits=0,63 do
 B.run=old.run;B.begin_ev=old.begin
 local st=fresh();st.bag={hp_s=bits%2};st.imenu=bits//2%2;st.ipk=bits//4%2==1 and 'hp_s' or 'bandage'
 st.cur=bits//8%2==1 and 4 or 1;st.u[1].hp=bits//16%2==1 and 500 or 1000
 if bits>=32 then st.u[4].al=0;st.u[4].hp=0 end
 if bits==0 then st.bag=nil elseif bits==1 then st.cur=5 elseif bits==2 then st.over='win'end
 local G={scene=bits==3 and 'town' or 'battle',items={hp_s=bits%2,bandage=bits//4%2,mp_m=bits//8%2}}
 local input={state=cp(st),world=cp(G),defs=cp(B.DEF),arg=arg};local calls={};B.ACT='before';B.SKON='old'
 B.load=function()return st end
 B.save=function(id,s)calls[#calls+1]={'save'}end
 B.send_result=function(id,s)calls[#calls+1]={'send'}end
 B.begin_ev=function(s)calls[#calls+1]={'begin'};s.ev={fresh=true}end
 B.rbegin=function(s)calls[#calls+1]={'rbegin',s.n}end
 B.it_apply=function(s,id,t)calls[#calls+1]={'apply',id,t,B.ACT==s.u[s.cur],B.SKON or false}end
 B.end_turn=function(s,cur,cost)calls[#calls+1]={'end_turn',cur,cost}end
 B.run=function(s)calls[#calls+1]={'run'}end
 B.H.it(G,arg,'fixture')
 add('item_handler',input,{state=st,world=G,calls=calls,actor=B.ACT==nil and 'nil' or B.ACT,skill=B.SKON==nil and 'nil' or B.SKON})
end end
B.load=old.load;B.save=old.save;B.send_result=old.send;B.it_apply=old.apply;B.end_turn=old.ending;B.run=old.run;B.rbegin=old.rbegin;B.begin_ev=old.begin;B.ACT=nil;B.SKON=nil
return out
