local P=json.decode([=[__PERSONA__]=])
local out={view={},face={},handler={},finish={}}
local function cp(x)return json.decode(json.encode(x))end
local function same(a,b)
 if type(a)~=type(b)then return false end
 if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local function base()
 local G=B.G_new();G.persona=cp(P);G.persona.name='가온';G.persona.cls='전사';G.persona.lv=10;G.persona.exp=0;G.persona.fight=1;G.persona.race='인간';G.persona.nation='경계도시'
 G.scene='sortie';G.roster={'lynette','marceline','urda','haldric'};G.party={'lynette'};G.lvl={lynette=15,marceline=9,urda=10,haldric=40};G.exp={};G.aff={};G.items={};G.dungeon={best=2,sel=1,mode=1,pg=1,runs=0,cleared_bosses={}}
 return G
end
local function view(kind,G,html,extra)out.view[#out.view+1]={kind=kind,lang=B.LANG,G=cp(G),html=html,extra=extra or {}}end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,n in ipairs({0,1,2,4,7})do local G=base();view('stars',G,B.tw_stars(n),{n=n})end
 for _,s in ipairs({'','A&B "quotes"','출전 인원'})do local G=base();view('hint',G,B.tw_hint(B.esc(s)),{text=s});view('heading',G,B.tw_hd('pl-guild',B.esc(s)),{text=s,icon='pl-guild'})end
 local G=base();for _,p in ipairs(B.TW_PLACES)do view('place',G,B.tw_pbtn('tw_'..p.scene,p.ic,B.U(p.name),B.U(p.d)),{place=p})end
 for fight=0,1 do for _,party in ipairs({{}, {'lynette'}, {'urda','lynette','marceline','haldric'}, {'lynette','unknown','lynette'}})do for _,name in ipairs({'','가온','A&B "quotes"'})do
  local G=base();G.persona.name=name;G.persona.fight=fight;G.party=cp(party);local m=B.SO.members(G)
  view('slots',G,B.R23_sortie.slots(G,m));view('fight',G,B.R23_sortie.fight(G))
 end end end
 for _,difficulty in ipairs({'낮음','중간','높음','엘리트'})do for _,stars in ipairs({1,2,3,4})do
  local G=base();local q={id='q7',title='남서 설산 균열, 균열 핵 토벌',name='균열 핵 토벌',rift='남서 설산 균열',kind='토벌',d='A&B "quotes" 긴 의뢰 설명',stars=stars,lv=15,gold=100,reward_v=2,difficulty=difficulty}
  G.guild.quests={q};G.guild.active=q.id;view('quest',G,B.R23_sortie.quest(G,q),{q=q})
 end end
 local G=base();view('quest',G,B.R23_sortie.quest(G,nil),{q=false})
 for _,best in ipairs({0,2,8,27,54,419})do for _,pg in ipairs({1,2,99})do
  local G=base();G.dungeon.best=best;G.dungeon.sel=best+5;G.dungeon.pg=pg
  view('dungeon_card',G,B.dn_card(G))
 end end
end
local portrait=B.portrait
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,provider in ipairs({'missing','throw','number','plain','html'})do for _,cid in ipairs({'lynette','unknown'})do
  if provider=='missing'then B.portrait=nil else B.portrait=function()if provider=='throw'then error('fixture')elseif provider=='number'then return 7 elseif provider=='plain'then return 'not an image'else return '<img src="fixture.png">'end end end
  local html=B.tw_face(cid);out.face[#out.face+1]={kind='town',lang=lang,id=cid,provider=provider,html=html}
 end end
end
B.portrait=portrait
for _,lang in ipairs({'ko','en'})do for _,result in ipairs({'clear','retreat','defeat'})do for _,kern in ipairs({false,true})do
 B.LANG=lang;local G=base();G.gold=300;G.town.day=1;G.town.bn=7;G.ui.sel='stale';G.ui.tab='back'
 if kern then G.persona.nation='케른 연방';G.party={'haldric','urda'}end
 local pm,n,avg=B.dn_party(G);local R=B.ex_new(G,1,pm,n,avg,7);G.dungeon.run=R;R.step=5;R.wins=3;R.loot.gold=21;R.loot.items={hp_s=4};R.exp=55
 local old={gear=B.ex_gear_roll,pend=B.pend_hard,chap=B.chap_mark};B.ex_gear_roll=function()end;B.pend_hard=function()end;B.chap_mark=function()end
 B.R23P3.finish(G,'expe6finish',R,result,{rg=0,exp=0,star=1})
 local saved=cp(G);B.R23P3.finish(G,'expe6finish',R,result,{rg=0,exp=0,star=1})
 out.finish[#out.finish+1]={lang=lang,result=result,kern=kern,value={run_exists=G.dungeon.run~=nil,phase=G.dungeon.run and G.dungeon.run.phase or '',screen=G.scene=='town'and'town'or'summary',gold=G.gold,items=G.items.hp_s or 0,day=G.town.day,runs=G.dungeon.runs,best=G.dungeon.best,msg=result=='defeat'and G.ui.msg or '',tab=G.ui.tab,sel=G.ui.sel},replay_equal=same(saved,G)}
 B.ex_gear_roll=old.gear;B.pend_hard=old.pend;B.chap_mark=old.chap
end end end
B.LANG='en';out.locale={ui=B.ui_pack('en'),words=B.en_dict()};B.LANG='ko'
return out
