local P=json.decode([=[__PERSONA__]=])
local out={award={},town={},view={},run={},step={},rest={},start={},sortie={}}
local function cp(x)return json.decode(json.encode(x))end
local function base()
 local G=B.G_new();G.persona=cp(P);G.persona.name='가온';G.persona.cls='전사';G.persona.lv=10;G.persona.exp=0;G.persona.fight=1
 G.persona.race='인간';G.persona.nation='경계도시';G.scene='dungeon';G.roster={'lynette','marceline','urda','haldric'};G.party={'lynette'}
 G.lvl={lynette=15,marceline=9,urda=10,haldric=40};G.exp={};G.items={};G.aff={};G.dungeon={best=2,sel=1,mode=1,pg=1,runs=0,cleared_bosses={}}
 return G
end
local function run(G)
 local pm,n,avg=B.dn_party(G);G.town.bn=7;G.town.xp_bn=nil;local R=B.ex_new(G,1,pm,n,avg,7);G.dungeon.run=R;return R
end
local chron=B.chron_add
for _,lang in ipairs({'ko','en'})do for _,amount in ipairs({-1,0,1,55,1000,50000,'55.9','bad',false})do for _,mode in ipairs({'normal','duplicates','fallback','unknown','no_persona','no_state','string_key','replayed','no_key','empty','party_only','missing_lvls'})do
 B.LANG=lang;local G=base();G.persona.lv=9;G.persona.exp=27;G.lvl.lynette=9;G.exp.lynette=27;G.town.bn=7;G.town.xp_bn=nil
 local st={exp=amount,sid=7,pm={{id='lynette'},{id='persona'},{id='urda'}}};local calls={}
 if mode=='duplicates'then st.pm={{id='lynette'},{id='lynette'},'',{id=''},'persona','persona','unknown',false}
 elseif mode=='fallback'then st.pm=nil;G.persona.fight=0;G.party={'lynette','lynette','unknown',''}
 elseif mode=='unknown'then st.pm={'unknown'}
 elseif mode=='no_persona'then G.persona=nil
 elseif mode=='no_state'then st=false
 elseif mode=='string_key'then st.sid='7';G.town.xp_bn='7'
 elseif mode=='replayed'then G.town.xp_bn=7
 elseif mode=='no_key'then st.sid=nil;G.town.bn=false;st.bn=nil
 elseif mode=='empty'then st.pm={}
 elseif mode=='party_only'then st.pm={'lynette'}
 elseif mode=='missing_lvls'then G.lvl=nil;G.exp=nil end
 local input={G=cp(G),st=cp(st)}
 B.chron_add=function(g,line)calls[#calls+1]=line end
 local lines,gains=B.award_exp(G,st)
 local after=cp(G);local a,b=B.award_exp(G,st)
 out.award[#out.award+1]={lang=lang,mode=mode,input=input,value={G=after,lines=lines,gains=gains},again={lines=a,gains=b},chron=calls}
end end end
B.chron_add=chron;B.LANG='ko'
for _,raw in ipairs({false,7,'bad',{}, {town=false,guild=false}, {town={bn=false,day=0,rr='2',acts=7,keep=true},guild={quests=7,active='q1',keep=true}}, {town={bn=4,day=7,rr=2,acts={eat=1}},guild={quests={{id='q1'}},active='q1'}}})do
 local G=type(raw)=='table' and cp(raw)or{town=raw,guild=raw};local input=cp(G);local T=B.tw_T(G)
 out.town[#out.town+1]={kind='normalize',input=input,value=G,alias=rawequal(T,G.town)}
end
for _,lang in ipairs({'ko','en'})do for _,name in ipairs({'','가온','A&B <tag>'})do for fight=0,1 do
 B.LANG=lang;local G=base();G.persona.name=name;G.persona.fight=fight;G.party={'lynette','unknown','lynette'}
 local names=B.tw_party(G)
 out.town[#out.town+1]={kind='party',lang=lang,name=name,fight=fight,party=G.party,value=names,html=B.tw_tags(names)}
end end end
for _,lang in ipairs({'ko','en'})do for _,cid in ipairs({'lynette','persona','unknown'})do
 B.LANG=lang;out.town[#out.town+1]={kind='name',lang=lang,id=cid,value=B.tw_name(cid),face=B.tw_face(cid,'A&B <tag>')}
end end
for _,lang in ipairs({'ko','en'})do
 B.LANG=lang
 for _,n in ipairs({0,1,3,7})do out.town[#out.town+1]={kind='stars',lang=lang,n=n,html=B.tw_stars(n)}end
 for _,text in ipairs({'','A&B <tag>','출전 인원'})do out.town[#out.town+1]={kind='heading',lang=lang,text=text,html=B.tw_hd('pl-guild',text),hint=B.tw_hint(text)}end
 out.town[#out.town+1]={kind='place',lang=lang,html=B.tw_pbtn('tw_guild','pl-guild','연합 길드 본관','의뢰판과 동료 소개 창구','go')}
end
B.LANG='ko'
local function view(kind,G,R,html,extra)
 out.view[#out.view+1]={kind=kind,lang=B.LANG,G=cp(G),R=cp(R),html=html,extra=extra or {}}
end
for _,lang in ipairs({'ko','en'})do for _,phase in ipairs({'explore','rest'})do for _,step in ipairs({0,1,4,5})do for _,ask in ipairs({false,true})do
 B.LANG=lang;local G=base();local R=run(G);R.phase=phase;R.step=step;R.ask=ask;R.loot.gold=21;R.loot.items={hp_s=2,mp_s=1};R.loot.gear={'wa01.1.1'};R.exp=55
 R.last=step==0 and '' or 'A&B <tag> "quotes"';R.real=step>0;G.items={hp_s=2,hp_l=1,mp_s=1,bandage=1}
 R.hp[1]=step==1 and 0 or math.floor(R.mhp[1]/2);R.mp[1]=0
 view('pips',G,R,B.R23P3.pips(R))
 local sub=phase=='rest'and B.U('휴식')or(step==0 and B.U('입장')or B.U('탐색 {step}/{total}',{step=step,total=B.EX.STEPS}))
 view('head',G,R,B.R23P3.head(G,R,sub))
 view('last',G,R,B.R23P3.last(R))
 view('party',G,R,B.R23P3.party(G,R,true))
 view('retreat',G,R,B.R23P3.retreat(R))
 for i,m in ipairs(R.pm)do if m.id~=''then view('use_row',G,R,B.R23P3.use_row(G,R,i,m,R.hp[i]<=0),{slot=i})end end
end end end end
for _,lang in ipairs({'ko','en'})do for _,have in ipairs({0,2})do for _,can in ipairs({false,true})do for _,why in ipairs({false,'Lv 30 필요'})do
 B.LANG=lang;local G=base();local R=run(G);G.items.hp_s=have
 view('use_btn',G,R,B.R23P3.use_btn(G,'hp_s',1,B.ITEMS.hp_s.name,can,why or nil),{id='hp_s',slot=1,can=can,why=why or ''})
end end end end
for _,cur in ipairs({-10,0,1,50,100,101,200})do for _,maximum in ipairs({-1,0,100})do
 local G=base();local R=run(G);view('bar',G,R,B.R23P3.bar('hp',cur,maximum),{kind='hp',cur=cur,maximum=maximum})
end end
for _,lang in ipairs({'ko','en'})do for _,result in ipairs({'clear','retreat','defeat'})do for _,first in ipairs({false,true})do for _,gear in ipairs({false,true})do
 B.LANG=lang;local G=base();local R=run(G);R.phase='done';R.step=5;R.boss_name='오염된 집행자';R.boss_kind='boss'
 R.summary={result=result,floor=1,gold=21,exp=55,items={mp_s=1,hp_s=2},lv={'가온 Lv 9 → 10'},aff={'리네트 +2'},first=first,steps=5,wins=3,lost_gold=21,penalty=50,lost_gear=gear and 2 or 0,gear_lost=gear and 1 or 0,gear=gear and{'wa01.1.1','invalid'}or{},kept_gear=gear and{'wa01.1.1'}or{}}
 view('done',G,R,B.R23P3.done(G,R));view('done_act',G,R,B.R23P3.done_act(G,R,R.summary))
end end end end
for _,raw in ipairs({false,7,'bad',{}, {best=-2.7,runs='4.9',sel='0',mode='1',pg=-1,cleared_bosses=5,run='bad',keep=1}, {best=9,run={phase='explore',floor=1,keep=true}}})do
 local G={dungeon=cp(raw)};local before=cp(G);local R=B.ex_run(G)
 out.run[#out.run+1]={input=before,value=G,run=R or false}
end
local function state(R)
 return {phase=R.phase,step=R.step,elites=R.elites,ask=R.ask,last=R.last,log=R.log,hp=R.hp,mp=R.mp,gold=R.loot.gold,exp=R.exp,items=R.loot.items,gear=R.loot.gear}
end
local oldrun=B.run;B.run=function()end
for _,lang in ipairs({'ko','en'})do for seed=1,60 do for _,step in ipairs({0,4})do for _,ask in ipairs({false,true})do
 B.LANG=lang;local G=base();local R=run(G);R.seed=seed;R.step=step;R.ask=ask
 B.H.ex(G,'go','expe5step');out.step[#out.step+1]={lang=lang,seed=seed,step=step,ask=ask,value=state(R)}
end end end end
B.run=oldrun
for _,lang in ipairs({'ko','en'})do for _,h in ipairs({0,1,50,101})do for _,repeat_count in ipairs({1,2,3})do
 B.LANG=lang;local G=base();local R=run(G);R.pm={R.pm[1],{id='',cls='',L=1},{id='',cls='',L=1},{id='',cls='',L=1}}
 R.hp={h,0,0,0};R.mp={0,0,0,0};R.mhp={101,0,0,0};R.mmp={71,0,0,0};R.step=5
 for _=1,repeat_count do B.ex_enter_rest(G,'expe5rest',R)end
 out.rest[#out.rest+1]={lang=lang,h=h,repeats=repeat_count,value=state(R)}
end end end
for _,selection in ipairs({0,1,3,999})do
 local G=base();G.dungeon.sel=selection;G.town.bn=7;B.dn_start(G,'expe5start')
 out.start[#out.start+1]={selection=selection,floor=G.dungeon.run.floor,last=G.dungeon.run.last,phase=G.dungeon.run.phase,scene=G.scene,panel=G.ui.panel}
end
for _,lang in ipairs({'ko','en'})do for fight=0,1 do for _,party in ipairs({{}, {'lynette'}, {'marceline','urda','haldric','lynette'}})do for _,filter in ipairs({'','front','back','invalid'})do for _,aff in ipairs({-100,0,99.9,200})do
 B.LANG=lang;local G=base();G.scene='sortie';G.persona.fight=fight;G.party=cp(party);G.ui.tab=filter;G.dungeon.sel=28
 for _,cid in ipairs(G.roster)do G.aff[cid]=aff end
 local m=B.SO.members(G);local _,_,avg=B.dn_party(G);local q={lv=B.dn_floor_view(28,avg).el}
 out.sortie[#out.sortie+1]={lang=lang,fight=fight,party=G.party,filter=filter,aff=aff,kind='cards',html=B.R23_sortie.cards(G)}
 out.sortie[#out.sortie+1]={lang=lang,fight=fight,party=G.party,filter=filter,aff=aff,kind='summary',html=B.R23_sortie.summary(G,q,m)}
end end end end end
B.LANG='en';out.locale={ui=B.ui_pack('en'),words=B.en_dict()};B.LANG='ko';return out
