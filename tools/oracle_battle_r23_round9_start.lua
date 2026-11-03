local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function add(op,c,v)out.rows[#out.rows+1]={op=op,input=cp(c),expected=cp(v)};out.counts[op]=(out.counts[op]or 0)+1 end
local classes={'missing','warrior','사제'}
for _,cls in ipairs(classes)do for _,fight in ipairs({false,0,1,2})do for bits=0,15 do
 local G=B.G_new();G.persona.cls=cls;G.persona.fight=fight;G.persona.lv=bits%2==1 and '17.9' or 1;G.persona.race='엘프';G.persona.lineage='고양이';G.persona.nation='경계도시';G.persona.stats=bits//2%2==1 and {str='23',hp=171} or false
 G.persona.skill=bits//4%2==1 and {prefix='strike',suffix='abyss'}or {};G.roster={'levia','felice','naran','hildegard'};G.party={'missing','levia','levia','felice','naran','hildegard'};G.lvl={levia='40.9',felice=0};G.equip={levia={weapon='source.code',acc=3},persona={weapon=' ',armor='bad'}}
 if bits>=8 then G.party={};G.forge=nil;G.equip={}end
 local before=cp(G);add('battle_pm',{world=before},{party=B.battle_pm(G),world=G})
end end end
for _,lv in ipairs({false,0,'','bad'})do for _,mirror in ipairs({1,17,'19.9'})do
 local G=B.G_new();G.persona.cls='warrior';G.persona.lv=lv;G.lv=mirror
 local before=cp(G);add('battle_pm',{world=before},{party=B.battle_pm(G),world=G})
end end
local rifts={'missing'};for _,id in ipairs(B.RIFT_ORDER)do rifts[#rifts+1]=B.RIFTS[id].quest_name end
for _,rift in ipairs(rifts)do for _,kind in ipairs({'토벌','구조','회수'})do for _,stars in ipairs({0,2,'4'})do for _,cmp in ipairs({false,0,1})do
 local G={seed=12345,n=3};local pm={{id='levia'},{id=''},{id='felice'},{id=''}};local q={rift=rift,kind=kind,stars=stars,cmp=cmp}
 local before=cp(G);local enc=B.quest_compose(G,q,pm)
 add('quest_compose',{world=before,quest=q,party=pm},{enc=enc or false,world=G})
end end end end
-- Fresh/retry/save/start are executed as a batch, but their complete native
-- state observations remain separate from the two direct contracts above.
local states={}
for _,bn in ipairs({0,7})do
 local s=B.fresh(bn);s.rg=123;s.qid='quest';s.place='place';s.sid=19
 local again=B.again(s);local redo=B.redo(s)
 B.save('r23-battle-round9',s);local loaded=B.load('r23-battle-round9')
 states[#states+1]={op='retry_save',initial=s,again=again,redo=redo,loaded=loaded}
end
for _,raw in ipairs({'bad','null','{}','{"ver":2,"u":[],"pm":[]}','{"ver":99}'})do
 setChatVar('r23-battle-round9',B.KEY,raw);states[#states+1]={op='load_invalid',raw=raw,loaded=B.load('r23-battle-round9')}
end
do
 local G=B.G_new();G.scene='town';G.persona.cls='warrior';G.persona.stats={str=18,hp=118};G.town={bn=3};G.pending='before';G.pending_at=4;G.pend_soft=1
 local q={id='quest',rift=B.RIFTS[B.RIFT_ORDER[1]].quest_name,kind='구조',stars=1,lv=1,gold=100,cmp=1}
 local before=cp(G);B.battle_start(G,'r23-battle-round9',q)
 states[#states+1]={op='battle_start',world=G,before=before,state=B.load('r23-battle-round9')}
end
out.source_only=states
return out
