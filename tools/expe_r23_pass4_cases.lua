local P=json.decode([=[__PERSONA__]=])
local out,cov={},{}
local function cp(x)return json.decode(json.encode(x))end
local function group(k)B.__expe_cov={calls={},branches={}};cov[k]=B.__expe_cov;out[k]={}end
local function base()
 local G=B.G_new();G.persona=cp(P);G.persona.cls='전사';G.persona.lv=10;G.persona.exp=0;G.persona.fight=1;G.persona.name='가온';G.persona.race='인간';G.persona.nation='경계도시'
 G.scene='dungeon';G.roster={'lynette','marceline','urda','haldric'};G.party={'lynette'};G.lvl={lynette=15,marceline=9,urda=10,haldric=40};G.exp={};G.items={};G.aff={};G.dungeon={best=2,sel=1,mode=1,pg=1,runs=0,cleared_bosses={}};G.town.xp_bn=nil
 return G
end
local function run(G)local pm,n,avg=B.dn_party(G);G.dungeon.run=B.ex_new(G,1,pm,n,avg,7);return G.dungeon.run end
local function probe(k,fn)local ok,v=pcall(fn);out[k][#out[k]+1]={ok=ok,value=ok and (v or false) or tostring(v)}end
-- Restore every substituted dependency even after a failing source probe.
local function with(patches,fn)
 local old={};for k,v in pairs(patches)do old[k]=B[k];B[k]=v end
 local ok,v=pcall(fn);for k in pairs(patches)do B[k]=old[k]end
 if not ok then error(v)end;return v
end
group('names')
for _,iid in ipairs({'hp_s','sh_m','bandage','unknown','eq_w_iron_sword','wa01.1.1','aa01.2.1','ca01.z.1',''})do
 out.names[#out.names+1]={id=iid,value=B.R23P3.name(iid)}
end
group('new')
local oldrnd=B.G_rnd
for _,sample in ipairs({0,0.00001,0.25,0.5,0.999999999})do for _,floor in ipairs({1,3,27,28,55,420})do for _,kind in ipairs({'normal','throw','number','empty_slots'})do
 local G=base();local pm,n,avg=B.dn_party(G);if kind=='empty_slots'then pm={{id='unknown',cls='warrior',L=1},{id='',cls='',L=1}};n=1;avg=1 end
 local calls={};local rnd=0;local stats=B.party_stats
 local value=with({G_rnd=function(g)rnd=rnd+1;g.fixture_rng=(g.fixture_rng or 0)+1;return sample end,party_stats=function(cls,lv,id)
  calls[#calls+1]={cls=cls,lv=lv,id=id or false};if kind=='throw'then error('fixture')elseif kind=='number'then return 7 else return stats(cls,lv,id)end
 end},function()return B.ex_new(G,floor,pm,n,avg,7)end)
 out.new[#out.new+1]={sample=sample,floor=floor,kind=kind,pm=pm,n=n,avg=avg,value=value,calls=calls,rnd=rnd,rng=G.fixture_rng,aliased=rawequal(value.pm,pm)}
end end end
group('run_record')
for _,raw in ipairs({false,7,'bad',{}, {best=-2.7,sel='0',run='bad'}, {run={phase='rest',extra={keep=true}}}})do
 local G={dungeon=cp(raw)};local value=B.ex_run(G);out.run_record[#out.run_record+1]={input=raw,value=value or false,after=G,aliased=type(value)=='table' and rawequal(value,G.dungeon.run)}
end
group('new_actual')
for _,seed in ipairs({1,7,20261027,2147483646})do for _,counter in ipairs({0,4,100})do for _,floor in ipairs({1,3})do
 local G=base();G.seed=seed;G.n=counter;local pm,n,avg=B.dn_party(G)
 local value=B.ex_new(G,floor,pm,n,avg,1)
 out.new_actual[#out.new_actual+1]={seed=seed,counter=counter,floor=floor,value=value,after_seed=G.seed,after_counter=G.n}
end end end
group('resume_actual')
for _,seed in ipairs({1,7,20261027,2147483646})do
 local G=base();G.seed=seed;G.n=4;local pm,n,avg=B.dn_party(G)
 G.dungeon.run=B.ex_new(G,1,pm,n,avg,1);local saved=cp(G);local resumed=cp(saved)
 local second=B.ex_new(resumed,1,pm,n,avg,2)
 out.resume_actual[#out.resume_actual+1]={seed=seed,counter=4,first=saved.dungeon.run,second=second,after_counter=resumed.n}
end
group('award')
for _,kind in ipairs({'not_table','no_exp','zero','no_persona','fallback_fight','fallback_command','empty_pm','duplicate_pm','old_sid','old_bn','replay','bad_pm'})do
 local G=base();local st={exp=1000,sid=7,pm={{id='persona'},{id='lynette'}}};G.town.bn=11
 if kind=='not_table'then st=false elseif kind=='no_exp'then st.exp=nil elseif kind=='zero'then st.exp=0 elseif kind=='no_persona'then G.persona=false
 elseif kind=='fallback_fight'then st.pm=nil elseif kind=='fallback_command'then st.pm=nil;G.persona.fight=0 elseif kind=='empty_pm'then st.pm={}
 elseif kind=='duplicate_pm'then st.pm={'lynette','lynette','','unknown','persona',false,{id='urda'}} elseif kind=='old_sid'then st.sid=nil
 elseif kind=='old_bn'then st.sid=nil;G.town.bn='bad';st.bn=19 elseif kind=='replay'then G.town.xp_bn=7 elseif kind=='bad_pm'then st.pm={{id='unknown'}}end
 local before=cp(G);local chron={};local lines,gains
 with({chron_add=function(_,line)chron[#chron+1]=line end},function()lines,gains=B.award_exp(G,st)end)
 out.award[#out.award+1]={kind=kind,input=st,before=before,lines=lines,gains=gains,after=G,chron=chron}
end
group('town')
probe('town',function()local G={town={},guild={quests=false}};B.tw_T(G);return G end)
for _,portrait in ipairs({'none','throw','bad','html'})do probe('town',function()return with({portrait=portrait=='none' and false or function()if portrait=='throw'then error('fixture')elseif portrait=='bad'then return 'x'else return '<img src="fixture">'end end},function()return B.tw_face('lynette','fixture')end)end)end
local function quest(G,difficulty)
 local q={id='q991',name='Test',title='Test',d='A&B',kind='수색',difficulty=difficulty or '낮음',stars=1,lv=10,gold=20,reward_v=2};G.guild.quests={q};G.guild.active=q.id;return q
end
for _,scene in ipairs({'town','battle'})do for _,arg in ipairs({'return','sortie','dungeon','rose'})do
 -- Sexual scene is excluded; do not execute the rose branch.
 if arg~='rose'then probe('town',function()local G=base();G.scene=scene;quest(G);B.H.tw(G,arg,'expe4');return G.scene end)end
end end
for _,scene in ipairs({'unknown','town','guild','battle'})do probe('town',function()local G=base();G.scene=scene;quest(G);if scene=='town'then B.place_set(G,'smithy')end;return B.CTX['20-town'](G)end)end
probe('town',function()local G=base();G.scene='town';quest(G);return B.SCREENS.town(G,'expe4')end)
for _,kind in ipairs({'no_id','no_town','load_throw','not_table','ongoing','explore','boss','lose','quest'})do probe('town',function()
 local G=base();G.scene='battle';G.town.bn=1;local st={over=kind=='ongoing' and '' or kind=='lose' and 'lose' or 'win',rg=3,dn={kind=kind=='explore' and 'explore' or 'boss',floor=1}}
 if kind=='quest'then st.dn=nil;quest(G)elseif kind=='no_town'then G.town=nil end
 return with({load=function()if kind=='load_throw'then error('fixture')elseif kind=='not_table'then return 7 end;return st end},function()return B.R23town_hud(G,kind=='no_id' and nil or 'expe4')end)
end)end
group('quest_settle')
for _,kind in ipairs({'ongoing','dungeon','win','elite','bag_full','fallback_gold','lose','no_quest'})do probe('quest_settle',function()
 local G=base();G.scene='battle';local q=quest(G,(kind=='elite' or kind=='bag_full')and '엘리트' or '낮음');if kind=='no_quest'then G.guild.active=''end
 local pm=B.dn_party(G);local st={over=kind=='ongoing'and ''or kind=='lose'and 'lose'or 'win',rg=kind=='fallback_gold'and false or 77,exp=50000,pm=pm,sid=7}
 if kind=='dungeon'then st.dn={stage=1,floor=1}end
 local result=with({load=function()return st end,bag_add=function()return kind~='bag_full'end,npc_like=false,pend_hard=function(g,note)g.pending=note end},function()B.tw_settle(G,'expe4');return {scene=G.scene,msg=G.ui.msg}end)
 return result
end)end
group('sortie')
for _,kind in ipairs({'empty_filter','toggle_add','full','fight_trim','empty_dn','go_dn','empty_quest','go_quest','legacy','legacy_v1','dn_battle'})do probe('sortie',function()
 local G=base();G.scene='sortie';G.party={};local arg='go';G.dungeon.mode=0
 if kind=='empty_filter'then G.roster={'marceline'};G.ui.tab='front';return B.R23_sortie.cards(G)
 elseif kind=='toggle_add'then arg='tg_urda' elseif kind=='full'then G.party={'lynette','marceline','urda'};arg='tg_haldric'
 elseif kind=='fight_trim'then G.persona.fight=0;G.party={'lynette','marceline','urda','haldric'};arg='fight_1'
 elseif kind=='empty_dn'then G.dungeon.mode=1;G.persona.fight=0 elseif kind=='go_dn'or kind=='dn_battle'then G.dungeon.mode=1
 elseif kind=='empty_quest'then quest(G);G.persona.fight=0 else local q=quest(G);if kind=='legacy_v1'then q.reward_v=1 end end
 local patches={run=function()end,pend_hard=function()end}
 if kind=='legacy'or kind=='legacy_v1' then patches.battle_start=false elseif kind=='dn_battle'then patches.dn_start=function(g)g.scene='battle'end end
 return with(patches,function()B.H.so(G,arg,'expe4');return {scene=G.scene,msg=G.ui.msg,party=G.party,fight=G.persona.fight}end)
end)end
group('start')
for _,invalid in ipairs({false,true})do for _,prev in ipairs({false,true})do probe('start',function()
 local G=base();G.dungeon.sel=invalid and 99 or 1;if prev then local R=run(G);R.pm[3]={id='urda',cls='knight',L=10}end
 return with({pend_hard=function(g,note)g.pending=note end},function()B.dn_start(G,'expe4','prefix','line');return {scene=G.scene,prev=G.dungeon.prev or false,floor=G.dungeon.run.floor}end)
end)end end
group('explore')
for _,scene in ipairs({'town','dungeon'})do for _,phase in ipairs({'explore','rest'})do for _,ask in ipairs({false,true})do probe('explore',function()
 local G=base();local R=run(G);G.scene=scene;R.phase=phase;R.ask=ask;return with({run=function()end},function()B.R23P3.step(G,'expe4');return R.step end)end)
end end end
for _,kind in ipairs({'item','coin','gear'})do for _,step in ipairs({1,5})do probe('explore',function()
 local G=base();local R=run(G);R.step=step-1
 return with({ex_roll=function()return {kind=kind,item='hp_s',gold=3,code='wa01.1.1'}end,tx_find=function()return 1.4,1,1 end},function()B.R23P3.step(G,'expe4');return {loot=R.loot,step=R.step,phase=R.phase}end)
end)end end
group('battle')
for _,over in ipairs({'win','lose'})do probe('battle',function()
 local G=base();local R=run(G);local fresh=B.fresh
 return with({fresh=function(...)local st=fresh(...);st.over=over;return st end,run=function()end},function()B.ex_battle(G,'expe4','battle',1);return G.scene end)
end)end
group('continue')
for _,step in ipairs({1,5})do for seed=1,24 do probe('continue',function()
 local G=base();local R=run(G);R.seed=seed;R.step=step
 return with({run=function()end},function()
 B.ex_battle(G,'expe4','elite',step);local st=B.load('expe4');B.bind(st);st.over='win';st.rg=11;st.exp=5;B.save('expe4',st);B.R23P3.cont(G,'expe4');return {step=R.step,phase=R.phase,gear=R.loot.gear}
 end)
end)end end
group('gear_bank')
for _,pattern in ipairs({'all','none','mixed','nil'})do
 local G=base();local calls={};local list=pattern~='nil' and {'wa01.1.1','aa01.2.1','wa01.1.1'}or nil;local value,lost
 with({bag_add=function(id,code)calls[#calls+1]={id=id,code=code};return pattern=='all'or pattern=='mixed'and #calls%2==1 end},function()value,lost=B.ex_gear_bank(G,'expe4',list)end)
 out.gear_bank[#out.gear_bank+1]={pattern=pattern,list=list or false,value=value,lost=lost,calls=calls}
end
group('finish')
for _,result in ipairs({'clear','retreat','defeat'})do for _,kind in ipairs({'normal','repeat','gear','overflow','levels','keep','keep_zero'})do probe('finish',function()
 local G=base();local R=run(G);R.floor=3;R.step=5;R.wins=2;R.exp=kind=='levels'and 50000 or 55;R.loot={gold=13,items={hp_s=3,mp_s=1},gear={'wa01.1.1','aa01.2.1','wa01.1.1'}};R.boss_name='보스';R.boss_kind='boss'
 if kind=='repeat'then R.phase='done'end
 return with({bag_add=function()return kind~='overflow'end,tx_defeat=function()return .7,(kind=='keep'or kind=='keep_zero')and .4 or 0 end,pend_hard=function(g,note)g.pending=note end,chap_mark=function()end},function()
 if kind=='keep_zero'then R.loot.gold=0;R.loot.items={hp_s=1};R.loot.gear={}end
 B.R23P3.finish(G,'expe4',R,result,{rg=17,exp=kind=='levels'and 50000 or 55,dn={kind='boss'},star=3,pm=R.pm,sid=7});return {scene=G.scene,summary=R.summary or false}
 end)
end)end end
group('settle')
for _,kind in ipairs({'none','sid','bn','phase','explore','win','lose','legacy'})do probe('settle',function()
 local G=base();local R=run(G);R.phase='battle';R.cur_bn=8;local st={over=kind=='lose'and 'lose'or 'win',sid=7,bn=8,rg=11,exp=5,dn={floor=1,kind=kind=='explore'and 'explore'or 'boss'}}
 if kind=='none'then G.dungeon.run=nil elseif kind=='sid'then st.sid=99 elseif kind=='bn' then st.bn=99 elseif kind=='phase'then R.phase='rest'elseif kind=='legacy'then st.dn.stage=2 end
 return with({bag_add=function()return true end,pend_hard=function()end,chap_mark=function()end},function()B.dn_settle(G,'expe4',st);return {scene=G.scene,phase=R.phase,msg=G.ui.msg}end)
end)end
group('handler')
for _,kind in ipairs({'no_run','no_note','locked','next','home','home_empty','who','use','equip','unequip'})do probe('handler',function()
 local G=base();local R=run(G);local arg='next';R.phase='done';R.note='confirmed'
 if kind=='no_run'then G.dungeon.run=nil elseif kind=='no_note'then R.note=nil elseif kind=='locked'then R.floor=420 elseif kind=='home'then arg='home'elseif kind=='home_empty'then arg='home';G.dungeon.run=nil
 elseif kind=='who'then R.phase='rest';arg='who_2'elseif kind=='use'then R.phase='rest';G.items.hp_s=1;R.hp[1]=1;arg='u_hp_s_1'elseif kind=='equip'then R.phase='rest';arg='eq_weapon_wa01_1_1'elseif kind=='unequip'then R.phase='rest';arg='un_weapon'end
 return with({pend_hard=function()end,chap_mark=function()end},function()B.H.ex(G,arg,'expe4');return {scene=G.scene,phase=R.phase,sel=R.sel}end)
end)end
group('screens')
for _,kind in ipairs({'use_hp','use_mp','down','equip','invalid_sel','empty_party','clear','defeat','no_run'})do probe('screens',function()
 local G=base();local R=run(G);G.items={hp_s=2,mp_s=2,bandage=2};R.hp[1]=1;R.mp[1]=0
 if kind=='use_mp'then R.pm[1].L=1 elseif kind=='down'then R.hp[1]=0 elseif kind=='equip'then R.phase='rest';G.equip={persona={weapon='wa01.1.1'}}
 elseif kind=='invalid_sel'then R.phase='rest';R.sel=4 elseif kind=='empty_party'then R.phase='rest';R.pm={}
 elseif kind=='clear'or kind=='defeat'then R.phase='done';R.note='confirmed';R.summary={result=kind,floor=1,gold=3,exp=4,items={hp_s=2},lv={'가온 Lv 1 → 2'},aff={'리네트 +1'},lost_items={},gear={'wa01.1.1'},gear_lost=2,kept_gear={'wa01.1.1'},lost_gear=2,lost_gold=3,penalty=4,steps=5,wins=2}
 elseif kind=='no_run'then G.dungeon.run=nil end
 if kind=='equip'then return with({bag_get=function()return {'aa01.2.1','wa01.1.1'}end},function()return B.SCREENS.dungeon(G,'expe4')end)end
 return B.SCREENS.dungeon(G,'expe4')
end)end
group('migration')
for _,kind in ipairs({'none','loot','old','invalid'})do probe('migration',function()
 local G=base();if kind~='none'then local R=run(G);R.loot.items={potion=2,mana=3,hp_s=4}end
 G.items={potion=2,mana=3};if kind=='invalid'then G.items.potion='bad'end
 local value=B.G_migrate(G);return {items=value.items,loot=value.dungeon and value.dungeon.run and value.dungeon.run.loot.items or false}
end)end
group('items')
probe('items',function()return B.it_button({bag=false})end)
for _,kind in ipairs({'no_scene','over','no_bag','no_stock','cancel','blocked','unknown','target','no_menu','empty_pick','no_target'})do probe('items',function()
 local G=base();G.scene=kind=='no_scene'and 'town'or 'battle';G.items.hp_s=2;local st=B.fresh(1);B.bind(st);st.cur=1;st.over='';st.bag={hp_s=2};st.imenu=1;st.ipk='hp_s';st.u[1].hp=1
 local arg='to_1';if kind=='over'then st.over='win'elseif kind=='no_bag'then st.bag=false elseif kind=='no_stock'then G.items={};arg='open'elseif kind=='cancel'then st.imenu=0;arg='cancel'elseif kind=='blocked'then st.bag={hp_l=1};st.u[1].L=1;st.ipk='';return B.r_items(st,'')elseif kind=='unknown'then arg='unknown'elseif kind=='no_menu'then st.imenu=0 elseif kind=='empty_pick'then st.ipk=''elseif kind=='no_target'then st.u[1].hp=st.u[1].mhp end
 B.save('expe4',st);return with({run=function()end},function()B.H.it(G,arg,'expe4');return {stock=G.items,imenu=B.load('expe4').imenu}end)
end)end
group('remaining')
probe('remaining',function()return B.R23cur({cur=3})end)
probe('remaining',function()return {B.tw_hd('pl-guild','title'),B.tw_hint('hint'),B.R23supply_name('hp_s')}end)
for _,mode in ipairs({0,1})do probe('remaining',function()local G=base();G.scene='sortie';G.dungeon.mode=mode;quest(G);return B.SCREENS.sortie(G,'expe4')end)end
probe('remaining',function()local G=base();G.roster={'lynette'};G.ui.tab='back';return B.R23_sortie.cards(G)end)
probe('remaining',function()local G=base();G.roster={'marceline'};G.ui.tab='back';return B.R23_sortie.cards(G)end)
probe('remaining',function()local G=base();G.scene='sortie';G.dungeon.mode=0;G.guild.active='';B.H.so(G,'go','expe4');return G.scene end)
probe('remaining',function()local G=base();local R=run(G);R.phase='rest';return with({run=function()end},function()B.H.ex(G,'boss','expe4');return R.phase end)end)
probe('remaining',function()local G=base();G.scene='town';return with({place_id=function()return 'smithy'end},function()return B.CTX['20-town'](G)end)end)
probe('remaining',function()local G=base();G.scene='battle';quest(G);local st={over='lose',rg=0};return with({load=function()return st end,npc_like=function(g,k)g.fixture_npc=k end,pend_hard=function()end},function()B.tw_settle(G,'expe4');return G.fixture_npc end)end)
for _,phase in ipairs({'rest','explore','done'})do probe('remaining',function()local G=base();local R=run(G);R.phase=phase;return with({run=function()end},function()B.R23P3.boss(G,'expe4');return R.phase end)end)end
for _,arg in ipairs({'retreat','retreat_yes','retreat_no','next','home'})do probe('remaining',function()local G=base();local R=run(G);if arg=='next'then R.phase='rest'elseif arg=='home'then G.scene='town'end;B.H.ex(G,arg,'expe4');return R.ask end)end
probe('remaining',function()local G=base();local R=run(G);R.phase='rest';return with({bag_load=function()return {'wa01.1.1'}end,VID='expe4'},function()return B.R23P3.slots(G,R,'persona')end)end)
probe('remaining',function()local G=base();local R=run(G);R.step=1;return with({run=function()end,ex_gear_roll=function()return 'wa01.1.1'end},function()B.ex_battle(G,'expe4','elite',1);local st=B.load('expe4');B.bind(st);st.over='win';B.save('expe4',st);B.R23P3.cont(G,'expe4');return R.last end)end)
probe('remaining',function()local G=base();G.scene='battle';local st=B.fresh(1);B.bind(st);st.cur=1;st.over='';st.bag={hp_s=2};st.imenu=1;st.ipk='hp_s';B.save('expe4',st);B.H.it(G,'to_1','expe4');return G.scene end)
probe('remaining',function()local G=base();G.scene='battle';G.items.eq_w_iron_sword=1;local st=B.fresh(1);B.bind(st);st.cur=1;st.over='';st.bag={hp_s=2};st.imenu=1;B.save('expe4',st);return with({it_any=function()return true end},function()B.H.it(G,'pick_eq_w_iron_sword','expe4');return B.load('expe4').imenu end)end)
return {result=out,coverage=cov}
