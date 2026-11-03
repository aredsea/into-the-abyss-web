local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,input,s)
 local units={}
 for i=1,6 do local u=s.u[i];units[i]={hp=u.hp,df=u.df,sh=u.sh,shT=u.shT,g=u.g,am=u.am,bt=u.bt,bf=u.bf,pt=u.pt or false,cq=u.cq or 0,sil=u.sil or '',hid=u.hid or 0,x=u.x} end
 out.rows[#out.rows+1]={op=op,input=cp(input),expected=cp({units=units,events=s.ev.list,h=s.ev.h,log=s.log,T=s.ev.T,rng=s.rs})};out.counts[op]=(out.counts[op] or 0)+1
end
local function base(bits)
 local s=fresh()
 for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i;B.DEF[i].cid='missing';B.DEF[i].clsid='warrior';B.DEF[i].rules={};s.u[i].am=1;s.u[i].bt=0;s.u[i].shT=0;s.u[i].x={} end
 for i=5,6 do s.u[i].mhp=100;s.u[i].hp=bits%2==1 and 100 or (i==5 and 30 or 10);s.u[i].al=i==6 and math.floor(bits/2)%2 or 1;s.u[i].g=bits>=4 and -100 or 10000;B.DEF[i].row=i==6 and '후열' or '전열' end
 for i=1,4 do s.u[i].mhp=100;s.u[i].hp=100;s.u[i].al=1;s.u[i].g=10000;B.SK[i]={{id='atk'},{id='df'}} end
 if s.u[6].al==0 then s.u[6].hp=0 end
 s.u[5].it=1;s.u[1].tau=bits>=4 and 2 or 0
 B.begin_ev(s);return s
end
for _,stat in ipairs({'atk','def','spd','shield','pull','unknown'}) do for _,target in ipairs({'self','ally','allies','unknown'}) do for _,amt in ipairs({false,0,.2,1.5}) do for bits=0,7 do for _,aura in ipairs({false,true}) do
 local s=base(bits);local act={kind='buff',name='test',stat=stat,target=target,until_down=aura,amount=amt or nil,turns=bits%3==0 and nil or bits%3}
 local c={state=cp(s),action=act};B.e_buff(s,5,act);add('buff',c,s)
end end end end end
for _,stat in ipairs({'atk','def','spd','delay','unknown'}) do for _,target in ipairs({'all','one'}) do for _,amt in ipairs({false,0,.3}) do for bits=0,7 do
 local s=base(bits);local act={kind='debuff',name='test',stat=stat,target=target,amount=amt or nil,turns=bits%3==0 and nil or bits%3};local c={state=cp(s),action=act}
 B.e_debuff(s,5,act);add('debuff',c,s)
end end end end
for _,target in ipairs({'self','allies','unknown'}) do for _,amt in ipairs({false,0,.2,2}) do for bits=0,7 do
 local s=base(bits);local act={kind='heal',name='test',target=target,amount=amt or nil};local c={state=cp(s),action=act};B.e_heal(s,5,act);add('heal',c,s)
end end end
for _,guard in ipairs({false,true}) do for bits=0,7 do
 local s=base(bits);local act={kind='protect',name='test',guard=guard};local c={state=cp(s),action=act};B.e_protect(s,5,act);add('protect',c,s)
end end
for _,fx in ipairs({'silence','unknown',''}) do for bits=0,7 do
 local s=base(bits);local act={kind='special',name='test',fx=fx};local c={state=cp(s),action=act};B.e_special(s,5,act);add('special',c,s)
end end
for _,big in ipairs({false,true}) do for _,turns in ipairs({1,2,3,4}) do for _,hide in ipairs({false,2}) do for _,dr in ipairs({false,.7}) do
 local s=base(0);local act={kind='atk',name='test',big=big};s.u[5].cq=1;s.u[5].tn=turns;B.DEF[5].rules={hide_every=hide or nil,ranged_dr=dr or nil};local c={state=cp(s),action=act,rules=B.DEF[5].rules};B.foe_turn_end(s,5,act);add('turn_end',c,s)
end end end end
for _,cls in ipairs({'warrior','paladin','archer','assassin','sanctioned','unsanctioned','priest','alchemist','gladiator','chaos'}) do for _,seed in ipairs({1,127773,998123,2147483646,-1}) do
 local s=base(0);s.rs=math.max(1,seed);local ids={'levia','marceline','naran','teiris'}
 for i=1,4 do B.DEF[i].cid=ids[i];B.DEF[i].clsid=cls;B.SK[i]=B.member_skills(B.DEF[i]) end
 local act={kind='special',name='test',fx='silence'};local c={state=cp(s),action=act,skill_lists=cp(B.SK),class_id=cls}
 local rnd=B.rnd;if seed==-1 then c.forced_roll=1;B.rnd=function() return 1 end end
 B.e_special(s,5,act);B.rnd=rnd;add('special_choices',c,s)
end end
return out
