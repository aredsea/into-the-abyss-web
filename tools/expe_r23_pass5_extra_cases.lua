local P=json.decode([=[__PERSONA__]=]);local out={}
local function cp(x)return json.decode(json.encode(x))end
local function base(f)
 local G=B.G_new();G.persona=cp(P);G.persona.name='가온';G.persona.lv=10;G.persona.fight=1;G.party={'lynette'};G.roster={'lynette'};G.lvl={lynette=15};G.exp={};G.items={};G.dungeon={sel=f,best=f-1,mode=1,pg=1,runs=0,cleared_bosses={}}
 local pm,n,avg=B.dn_party(G);local R=B.ex_new(G,f,pm,n,avg,7);G.dungeon.run=R;return G,R
end
local function add(kind,G,R,html)out[#out+1]={kind=kind,lang=B.LANG,G=cp(G),R=cp(R),html=html}end
for _,lang in ipairs({'ko','en'})do for _,f in ipairs({1,3,27,28,55,420})do for _,phase in ipairs({'explore','rest'})do
 B.LANG=lang;local G,R=base(f);R.loot.items={hp_s=2};R.loot.gear={'wa01.1.1'};R.step=5;R.phase=phase
 add('head',G,R,B.R23P3.head(G,R,phase=='rest'and B.U('휴식')or B.U('탐색 {step}/{total}',{step=5,total=5})))
 for _,note in ipairs({false,'confirmed'})do for _,allowed in ipairs({false,true})do
  R.note=note or nil;G.dungeon.best=allowed and f or f-1
  R.summary={result='clear',floor=f,gold=0,exp=0,items={},lv={},aff={},gear={'invalid'},gear_lost=0,steps=5,wins=0}
  add('done_act',G,R,B.R23P3.done_act(G,R,R.summary));add('done',G,R,B.R23P3.done(G,R))
 end end
end end end
return out
