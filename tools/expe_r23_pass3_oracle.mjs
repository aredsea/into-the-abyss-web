// Canonical Lua execution. Probes are inserted into copies; source stays read-only.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),source='C:/Clauede Code/dungeon-bot/bot';
const names=['05-gen.lua','10-data.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','70-town.lua','72-guild.lua','74-level.lua','74-affection.lua','75-sortie.lua','76-dungeon.lua','77-explore.lua','78-battle-item.lua'];
const instrument=process.env.EXPE_PROBE_DIR;
const raw=names.map(name=>({name,text:fs.readFileSync(path.join(source,'src',name),'utf8')}));
const extra='B.__expe_cov={calls={},branches={}}\n'+raw.map(({name,text})=>{
 if(instrument)text=fs.readFileSync(path.join(instrument,name),'utf8');
 if(name==='77-explore.lua')text=text.replace('    for _, iid in ipairs(B.IT.order)', '    B.R23_weight=wt\n    for _, iid in ipairs(B.IT.order)');
 if(name==='75-sortie.lua')text=text.replace('  B.SCREENS.sortie =', '  B.R23_sortie={face=face,quest=quest_card,slots=slots,fight=fight_row,cards=cards,summary=summary_card}\n  B.SCREENS.sortie =').replace('  B.H.so =','  B.R23_sortie.legacy=legacy_start\n  B.H.so =');
 return 'do\n'+text+(name==='70-town.lua'?'\nB.R23town_hud=B.HUD_EXTRA[#B.HUD_EXTRA]\n':'')+(name==='78-battle-item.lua'?'\nB.R23supply_name=itname\n':'')+(name==='77-explore.lua'?'\nB.R23P3={zero=zero4,snapshot=snapshot_party,exp=exp_note,floor_label=floor_label,finish=finish_run,cont=do_cont,boss=do_boss,rest=enter_rest,pips=pips,last=last_card,head=head_card,use_btn=use_btn,use_row=use_row,party=party_card,retreat=retreat_card,explore=explore_screen,gear=gear_card,slots=slot_row,rest_screen=rest_screen,done_act=done_act,done=done_screen}\n':'')+'\nend';
}).join('\n')+'\nB.sx_rest_card=nil;B.sx_potion_card=nil;B.sx_rose_card=nil\n';
const {mkSim}=await import(pathToFileURL(source+'/lua_sim.mjs'));
const {sim,L}=await mkSim({lua:path.join(source,'dist/bot.lua'),policy:false,extra});
const persona=JSON.parse(fs.readFileSync(path.join(root,'verification/expedition-r22/save-specimens.json'),'utf8')).entry.persona;
try {
const pack=await L(`
local P=json.decode([=[${JSON.stringify(persona)}]=])
local out={snapshot={},party={},exp_fallback={},exp_actual={},aff={},aff_fallback={},labels={},normalize={},weights={},screens={},transitions={},migration={},zero={},weighted_roll={},source_flow={}}
local cov={}
local function cp(x)return json.decode(json.encode(x))end
local function group(k) B.__expe_cov={calls={},branches={}};cov[k]=B.__expe_cov end
local function base()
 local G=B.G_new();G.persona=cp(P);G.persona.cls='전사';G.persona.lv=10;G.persona.exp=0;G.persona.fight=1;G.persona.name='가온';G.persona.race='인간';G.persona.nation='경계도시'
 G.scene='dungeon';G.roster={'lynette','marceline','urda','haldric'};G.party={'lynette'};G.lvl={lynette=15,marceline=9,urda=10,haldric=40};G.exp={};G.items={};G.aff={};G.dungeon={best=2,sel=1,mode=1,pg=1,runs=0,cleared_bosses={}};G.town.xp_bn=nil
 return G
end
local function run(G)
 local pm,n,avg=B.dn_party(G);G.dungeon.run=B.ex_new(G,1,pm,n,avg,7);return G.dungeon.run
end
group('snapshot')
out.zero={B.R23P3.zero(),B.R23P3.zero()}
for mask=0,15 do for _,down in ipairs({0,0.2})do for _,hp in ipairs({0,0.9,1,17.8,101.9})do for _,mp in ipairs({-2,0,1.9,71.9})do
 local R={hp={11,22,33,44},mp={1,2,3,4},mhp={21,22,23,24},mmp={31,32,33,34},real=false,fell=false,keep='unchanged'}
 local st={u={}};for i=1,4 do st.u[i]={empty=(mask & (1 << (i-1)))~=0 and 1 or 0,al=i%2,hp=hp,mp=mp,mhp=101.9,mmp=71.9}end
 local old=B.EX.DOWN_HP;B.EX.DOWN_HP=down;B.R23P3.snapshot(R,st);B.EX.DOWN_HP=old
 out.snapshot[#out.snapshot+1]={mask=mask,down=down,hp=hp,mp=mp,value=R}
end end end end
group('party')
for _,cls in ipairs({'전사','사수','unknown',''})do for fight=0,1 do for _,party in ipairs({{}, {'lynette'}, {'unknown','lynette','lynette','urda','marceline','haldric'}, {'marceline','urda','haldric','lynette'}})do for _,equipped in ipairs({false,true})do
 local G=base();G.persona.cls=cls;G.persona.fight=fight;G.party=cp(party)
 if equipped then G.equip={persona={weapon='wa01.1.1'},lynette={armor='aa01.2.1'}};G.forge={['wa01.1.1']={lv=2,tries=3}} end
 local pm,n,avg=B.dn_party(G);out.party[#out.party+1]={cls=cls,fight=fight,party=party,equipped=equipped,value={pm=pm,n=n,avg=avg}}
end end end end
group('exp_fallback')
local award=B.award_exp
for _,kind in ipairs({'missing','throw','number','false','string','empty','list'})do for _,exp in ipairs({-1,0,1,25})do
 local G=base();local R=run(G);local S={exp=99,lv={'stale'},keep=true};local calls={}
 if kind=='missing' then B.award_exp=nil else B.award_exp=function(g,st)calls[#calls+1]=cp(st);g.oracle_touched=true;if kind=='throw'then error('fixture')elseif kind=='number'then return 7 elseif kind=='false'then return false elseif kind=='string'then return 'bad' elseif kind=='empty'then return {}else return {'first','second'}end end end
 B.R23P3.exp(G,R,exp,S);out.exp_fallback[#out.exp_fallback+1]={kind=kind,exp=exp,value=S,calls=calls,touched=G.oracle_touched or false}
end end
B.award_exp=award
group('exp_actual')
for _,lv in ipairs({1,9,10,29,39,40})do for _,exp in ipairs({0,1,55,1000,50000})do for fight=0,1 do for _,replay in ipairs({false,true})do
 local G=base();G.persona.lv=lv;G.persona.fight=fight;G.lvl.lynette=lv;local R=run(G);if replay then G.town.xp_bn=R.sid end
 local S={};B.R23P3.exp(G,R,exp,S)
 out.exp_actual[#out.exp_actual+1]={lv=lv,exp=exp,fight=fight,replay=replay,value=S,persona={lv=G.persona.lv,exp=G.persona.exp},level=G.lvl.lynette,xp=G.exp.lynette or 0,xp_bn=G.town.xp_bn or false}
end end end end
group('aff')
for _,lang in ipairs({'ko','en'})do for _,result in ipairs({'clear','retreat','defeat'})do for _,wins in ipairs({0,1,5})do for _,aff in ipairs({-100,0,99.9,100,199.9,200})do for _,nation in ipairs({'경계도시','솔렌 성왕국'})do
 local G=base();B.LANG=lang;G.persona.nation=nation;G.party={'lynette','urda','marceline'}
 if nation=='솔렌 성왕국'then G.roster[#G.roster+1]='colette';G.roster[#G.roster+1]='adeline';G.party={'marceline','colette','adeline'}end
 for _,id in ipairs(G.roster)do G.aff[id]=aff end
 local R=run(G);R.wins=wins;local S={};B.ex_aff_note(G,R,result,S)
 out.aff[#out.aff+1]={lang=lang,result=result,wins=wins,aff=aff,nation=nation,pm=R.pm,roster=G.roster,value=S.aff,after=G.aff}
end end end end end
B.LANG='ko'
group('aff_fallback')
local aff_party=B.aff_party;local AFF=B.AFF
for _,kind in ipairs({'missing','no_constants','throw','number','empty','got'})do for _,wins in ipairs({0,2})do
 local G=base();local R=run(G);R.wins=wins;R.pm={{id='lynette'},{id='persona'},{id='lynette'},{id='unknown'}}
 B.AFF=AFF;if kind=='no_constants'then B.AFF=nil end
 if kind=='missing'then B.aff_party=nil else B.aff_party=function()if kind=='throw'then error('fixture')elseif kind=='number'then return 7 elseif kind=='empty'then return {}else return {lynette=1.6,persona=0,unknown=0.04}end end end
 local S={aff={'stale'}};B.ex_aff_note(G,R,'retreat',S);out.aff_fallback[#out.aff_fallback+1]={kind=kind,wins=wins,value=S.aff}
 B.AFF=AFF
end end
B.aff_party=aff_party
group('labels')
for _,lang in ipairs({'ko','en'})do for _,floor in ipairs({false,0,1,3,27,28,54,55,420})do
 B.LANG=lang;local G=base();if floor==false then G.dungeon=nil else G.dungeon.run={floor=floor}end
 out.labels[#out.labels+1]={lang=lang,floor=floor,label=B.ex_label(G),context=floor and B.R23P3.floor_label({floor=floor}) or false}
end end
B.LANG='ko'
group('normalize')
for _,raw in ipairs({false,7,'bad',{}, {best=-2.7,runs='4.9',sel='0',mode='1',pg=-1,cleared_bosses=5,run='bad',extra={keep=true}}, {best='9.9',runs=-7,sel='3.9',mode=1,pg='2.9',cleared_bosses={'iron_tombs'},run={keep=true}}})do
 local G={dungeon=cp(raw)};local D=B.dn_G(G);local same=rawequal(D,G.dungeon);local R=B.ex_run(G)
 out.normalize[#out.normalize+1]={input=raw,value=D,same=same,run=R or false}
end
group('weights')
for _,floor in ipairs({0,1,7,8,17,18,420})do
 for seed=1,1000 do B.ex_roll(seed,floor,1,0,{});if B.R23_weight then break end end
 local G={};for _,iid in ipairs({'hp_s','hp_m','hp_l','mp_m','sh_l','bandage','unknown'})do G[iid]=B.R23_weight(iid)end
 out.weights[#out.weights+1]={floor=floor,value=G};B.R23_weight=nil
end
for _,floor in ipairs({1,7,8,17,18,420})do for seed=1,80 do for _,step in ipairs({1,3,5})do
 out.weighted_roll[#out.weighted_roll+1]={floor=floor,seed=seed,step=step,value=B.ex_roll(seed,floor,step,0,{'warrior'})}
end end end
group('screens')
local function screen(name,fn)
 local ok,value=pcall(fn);out.screens[#out.screens+1]={name=name,ok=ok,value=ok and value or tostring(value)}
end
for _,lang in ipairs({'ko','en'})do for _,phase in ipairs({'explore','rest','done'})do for _,ask in ipairs({false,true})do for _,step in ipairs({0,4,5})do
 B.LANG=lang;local G=base();local R=run(G);R.phase=phase;R.ask=ask;R.step=step;R.last=step==0 and '' or 'A&B <tag> "quotes"';R.loot.items={hp_s=2};R.real=step>0
 R.summary={result='retreat',floor=R.floor,gold=3,exp=2,items={hp_s=2},lv={},lost_items={},steps=step,wins=0};R.note='entry'
 screen(lang..':'..phase..':'..tostring(ask)..':'..step,function()return B.SCREENS.dungeon(G,'pass3')end)
end end end end
for _,lang in ipairs({'ko','en'})do for fight=0,1 do for _,party in ipairs({{}, {'lynette'}, {'marceline','urda','haldric','lynette'}})do for _,filter in ipairs({'','front','back'})do
 B.LANG=lang;local G=base();G.scene='sortie';G.persona.fight=fight;G.party=cp(party);G.ui.tab=filter;G.dungeon.pg=999;G.dungeon.sel=999
 screen('sortie:'..lang..':'..fight..':'..#party..':'..filter,function()return B.SCREENS.sortie(G,'pass3')end)
end end end end
B.LANG='ko'
group('transitions')
for _,scene in ipairs({'town','sortie','battle'})do for _,arg in ipairs({'back','mode_0','mode_1','fl_0','fl_1','fl_999','pg_0','pg_999','f_all','f_front','f_back','f_invalid','rm_persona','rm_lynette','rm_unknown','tg_unknown','tg_lynette','tg_urda','fight_0','fight_1','invalid','go'})do
 local G=base();G.scene=scene;G.party={'lynette','marceline','urda','haldric'};local old=B.run;B.run=function()end;local ok,e=pcall(B.H.so,G,arg,'pass3');B.run=old
 out.transitions[#out.transitions+1]={scene=scene,arg=arg,ok=ok,error=not ok and tostring(e) or false,value={party=G.party,fight=G.persona.fight,scene=G.scene,msg=G.ui.msg,tab=G.ui.tab,dungeon={sel=G.dungeon.sel,pg=G.dungeon.pg,mode=G.dungeon.mode}}}
end end
group('migration')
for _,raw in ipairs({false,{}, {potion=2,mana=3,hp_s=4,mp_s=5,other=9}, {potion='2',mana='bad',hp_s='3'}, {potion=-2.5,mana=false,hp_s=7}})do
 local t=cp(raw);B.ex_move_old_items(t);out.migration[#out.migration+1]={input=raw,value=t}
end
-- Source-only flow probes retain the unmapped HTML/host boundary explicitly.
-- These are execution evidence; no native-equality credit is awarded for them.
local function probe(name,fn)
 local ok,value=pcall(fn);out.source_flow[#out.source_flow+1]={name=name,ok=ok,value=ok and (value or false) or tostring(value)}
end
group('source_flow')
for _,scene in ipairs({'town','sortie','battle'})do for _,arg in ipairs({'guild','shop','inn','smithy','town','sortie','dungeon','unknown'})do
 probe('town:'..scene..':'..arg,function()local G=base();G.scene=scene;B.H.tw(G,arg,'pass3');return G.scene end)
end end
for fight=0,1 do
 local G=base();G.scene='town';G.persona.fight=fight;if fight==0 then G.party={}end
 probe('town-screen:'..fight,function()return B.SCREENS.town(G,'pass3')end)
 probe('town-ctx:'..fight,function()return B.CTX['20-town'](G)end)
 probe('town-hud:'..fight,function()return B.R23town_hud(G)end)
 probe('town-hd',function()return B.tw_hd('pl-guild','A&B')end)
 probe('town-stars',function()return B.tw_stars(3)end)
 probe('town-hint',function()return B.tw_hint('A&B')end)
end
probe('town-normalize',function()local G={town=false,guild=false};return B.tw_T(G)end)
probe('town-face',function()return B.tw_face('lynette','sample')end)
probe('town-settle-guard',function()local G=base();G.scene='town';B.tw_settle(G,'pass3');return G.scene end)
for _,hasq in ipairs({false,true})do
 local G=base();G.scene='sortie';G.dungeon.mode=0;local q=hasq and {id='fixture',name='Test',title='Test',d='A&B',kind='수색',difficulty='낮음',stars=1,lv=10,gold=20} or nil
 probe('quest-card:'..tostring(hasq),function()return B.R23_sortie.quest(G,q)end)
 if q then
  for _,v in ipairs({1,2})do q.reward_v=v;probe('legacy-start:'..v,function()B.R23_sortie.legacy(G,'pass3',q);return G.scene end)end
 end
end
for _,roster in ipairs({{}, {'marceline'}})do
 local G=base();G.roster=roster;G.party={};G.ui.tab='front'
 probe('candidate-empty:'..#roster,function()return B.R23_sortie.cards(G)end)
end
for _,floor in ipairs({1,3,28})do for _,result in ipairs({'clear','retreat','defeat'})do
 probe('finish:'..floor..':'..result,function()
  local G=base();local R=run(G);R.floor=floor;R.step=5;R.wins=2;R.loot.gold=13;R.loot.items={hp_s=2};R.exp=55;R.boss_name='보스';R.boss_kind=floor==3 and 'boss' or 'chief'
  B.R23P3.finish(G,'pass3',R,result,{rg=17,exp=55,dn={star=1},pm=R.pm,sid=R.sid});return {scene=G.scene,phase=R.phase,summary=R.summary}
 end)
end end
for _,phase in ipairs({'explore','rest','battle','done'})do
 probe('boss:'..phase,function()local G=base();local R=run(G);R.phase=phase;local old=B.run;B.run=function()end;B.R23P3.boss(G,'pass3');B.run=old;return R.phase end)
 probe('rest:'..phase,function()local G=base();local R=run(G);R.phase=phase;B.R23P3.rest(G,'pass3',R);return R.phase end)
end
for _,floor in ipairs({1,8,18,28})do for seed=1,50 do
 probe('explore:'..floor..':'..seed,function()local G=base();local R=run(G);R.floor=floor;R.seed=seed;R.step=seed%5;local old=B.run;B.run=function()end;B.H.ex(G,'go','pass3');B.run=old;return {phase=R.phase,step=R.step}end)
end end
for _,arg in ipairs({'who_0','who_1','who_4','who_9','eq_weapon_unknown','un_weapon','eq_invalid_unknown','unknown','home','next','cont'})do for _,phase in ipairs({'rest','explore','done'})do
 probe('handler:'..phase..':'..arg,function()local G=base();local R=run(G);R.phase=phase;B.H.ex(G,arg,'pass3');return R.phase end)
end end
for _,over in ipairs({'','win','lose'})do for stage=1,2 do
 probe('legacy-settle:'..over..':'..stage,function()local G=base();G.scene='battle';local R=run(G);B.dn_settle_legacy(G,'pass3',{over=over,dn={floor=3,stage=stage},rg=11,exp=5,pm=R.pm,sid=7});return G.scene end)
 probe('settle:'..over..':'..stage,function()local G=base();G.scene='battle';local R=run(G);B.dn_settle(G,'pass3',{over=over,dn={floor=3,stage=stage},rg=11,exp=5,pm=R.pm,sid=99,bn=99});return G.scene end)
end end
for _,mismatch in ipairs({'none','sid','bn','over','kind','scene','phase'})do
 probe('continue:'..mismatch,function()
  local G=base();local R=run(G);local old=B.run;B.run=function()end;B.ex_battle(G,'pass3','battle',1);B.run=old
  local st=B.load('pass3');B.bind(st);st.over='win';st.dn.kind='explore';st.rg=11;st.exp=5
  if mismatch=='sid'then st.sid=99 elseif mismatch=='bn'then st.bn=99 elseif mismatch=='over'then st.over='lose' elseif mismatch=='kind'then st.dn.kind='boss' elseif mismatch=='scene'then G.scene='town' elseif mismatch=='phase'then R.phase='rest'end
  B.save('pass3',st);B.R23P3.cont(G,'pass3');return {phase=R.phase,wins=R.wins,scene=G.scene}
 end)
end
probe('migrate',function()local G=base();local R=run(G);G.items={potion=2,mana=3};R.loot.items={potion=1};return B.G_migrate(G).items end)
for _,iid in ipairs(B.IT.order)do
 probe('apply:'..iid,function()
  local G=base();local pm=B.battle_pm(G);local st=B.fresh(1,nil,{pm=pm,el=10,star=1});B.bind(st);st.cur=1;local u=st.u[1];u.hp=1;u.mp=0;u.sh=0;u.dot={{d=1,n=2}};u.edot={};u.fx=2
  if iid=='bandage'then u.al=0;u.hp=0 end
  B.begin_ev(st);local amount=B.it_apply(st,iid,1);return {amount=amount,hp=u.hp,mp=u.mp,sh=u.sh,T=st.ev.T}
 end)
 probe('item-name:'..iid,function()return B.R23supply_name(iid)end)
end
for _,stock in ipairs({0,1})do for _,pick in ipairs({'','hp_s','bandage'})do
 probe('item-screen:'..stock..':'..pick,function()local G=base();local st=B.fresh(1);B.bind(st);st.cur=1;st.bag={hp_s=stock};st.ipk=pick;return {button=B.it_button(st),screen=B.r_items(st,'')}end)
end end
for _,arg in ipairs({'open','cancel','pick_hp_s','pick_unknown','to_1','unknown'})do
 probe('item-handler:'..arg,function()
  local G=base();G.scene='battle';G.items.hp_s=2;local st=B.fresh(1);B.bind(st);st.cur=1;st.over='';st.bag={hp_s=2};st.imenu=1;st.ipk='hp_s';st.u[1].hp=1;B.save('pass3',st)
  local old=B.run;B.run=function()end;B.H.it(G,arg,'pass3');B.run=old;return B.load('pass3').imenu
 end)
end
return {result=out,coverage=cov}
`);
const folder=path.join(root,'verification/parity-r23');
const stem=instrument?'expe-pass3-instrumented':'expe-pass3';
fs.writeFileSync(path.join(folder,stem+'-oracle.json'),JSON.stringify(pack.result,null,2)+'\n');
if(instrument)fs.writeFileSync(path.join(folder,'expe-pass3-coverage-raw.json'),JSON.stringify(pack.coverage,null,2)+'\n');
else fs.writeFileSync(path.join(folder,'expe-pass3-provenance.json'),JSON.stringify({excluded_hooks:['sx_rest_card','sx_potion_card','sx_rose_card'],exclusion_reason:'79-sex scenes excluded by task; no HTML equality claims',files:[...raw.map(f=>({file:'bot/src/'+f.name,sha256:crypto.createHash('sha256').update(f.text).digest('hex')})),...['dist/bot.lua','lua_sim.mjs'].map(f=>({file:'bot/'+f,sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(source,f))).digest('hex')}))],counts:Object.fromEntries(Object.entries(pack.result).map(([k,v])=>[k,v.length]))},null,2)+'\n');
console.log(JSON.stringify(Object.fromEntries(Object.entries(pack.result).map(([k,v])=>[k,v.length]))));
} finally {if(sim.close)await sim.close();}
