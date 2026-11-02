// Execute canonical Lua, exposing local functions only inside the loaded chunk.
// Never edits the bot or substitutes a translated implementation.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..');
const source='C:/Clauede Code/dungeon-bot/bot';
const names=['05-gen.lua','10-data.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','74-level.lua','74-affection.lua','75-sortie.lua','76-dungeon.lua','77-explore.lua','78-battle-item.lua'];
const raw=names.map(n=>fs.readFileSync(path.join(source,'src',n),'utf8'));
const extra=raw.map((s,i)=>'do\n'+(names[i]==='75-sortie.lua'?s.replace('  local function cards(G)','  B.SO.r23_ordered=ordered\n  B.SO.r23_filter=filt\n  local function cards(G)'):s)+(names[i]==='77-explore.lua'?'\nB.R23={members=members,zero4=zero4,push_log=push_log,out_mul=out_mul,snapshot=snapshot_party,bank_items=bank_items,do_use=do_use,do_boss=do_boss,equip_key=equip_key}\n':'')+'\nend').join('\n');
const {mkSim}=await import(pathToFileURL(source+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra});
const persona=JSON.parse(fs.readFileSync(path.join(root,'verification/expedition-r22/save-specimens.json'),'utf8')).entry.persona;
const fixtures=await L(`
local persona=json.decode([=[${JSON.stringify(persona)}]=])
local out={floors={},use={},boss={},snapshot={},logs={},bank={},bag={},migration={},discovery={},new_run={},drops={},sortie={},floor_view={},multipliers={},gear_add={},combat_targets={},combat_parties={},needs={},levels={}}
local function copy(x) return json.decode(json.encode(x)) end
local function base()
 local G=B.G_new();G.scene='dungeon';G.persona=copy(persona);G.persona.cls='전사';G.persona.race='인간';G.persona.nation='경계도시';G.persona.fight=1
 G.roster={'lynette'};G.party={'lynette'};G.lvl={lynette=1};G.exp={};G.items={};G.dungeon={best=0,sel=1,mode=1,pg=1,runs=0,cleared_bosses={}}
 return G
end
for _,pl in ipairs({-1e20,-2,0,1,14.9,40,41,1e20,'15','bad',false}) do for _,lv in ipairs({-1e20,-1,0,1,15.9,40,41,1e20,'20','bad',false}) do for _,xp in ipairs({-1,0,19.9,'25','bad',false}) do
 local G={persona={lv=pl,exp=xp},lv=9,roster={'lynette'},lvl={lynette=lv,urda=lv},exp={lynette=xp,urda=xp}}
 local values={};for _,id in ipairs({'persona','lynette','urda','unknown'}) do values[id]={level=B.lv_of(G,id),xp=B.exp_of(G,id)} end
 out.levels[#out.levels+1]={input=G,value=values}
end end end
for _,G in ipairs({{lv=7,roster={'lynette'}},{persona={},lv=8,roster={'lynette'}},{persona={lv=20},roster={'lynette'},lvl={},exp={}},{persona=false,lv=9,roster={}}}) do
 local values={};for _,id in ipairs({'persona','lynette','urda','unknown'}) do values[id]={level=B.lv_of(G,id),xp=B.exp_of(G,id)} end
 out.levels[#out.levels+1]={input=G,value=values}
end
for _,best in ipairs({0,1,2,26,27,28,419}) do for zone=0,#B.ZONE_ORDER do
 local G=base();G.dungeon.best=best
 if zone>0 then G.dungeon.cleared_bosses={B.ZONE_ORDER[zone]} end
 local mx=B.dn_max(G);local allowed={}
 for _,f in ipairs({-1,0,1,mx,mx+1}) do allowed[#allowed+1]={floor=f,value=B.dn_allowed(G,f)} end
 out.floors[#out.floors+1]={best=best,cleared=G.dungeon.cleared_bosses,max=mx,allowed=allowed}
end end
for _,f in ipairs({1,2,3,26,27,28,29,30,54,55,420}) do for _,avg in ipairs({1,1.49,1.5,10,20.5,39.5,40}) do
 out.floor_view[#out.floor_view+1]={floor=f,avg=avg,value=B.dn_floor_view(f,avg)}
end end
for fight=0,1 do for n=0,4-fight do for _,filter in ipairs({'','front','back','all','invalid'}) do for _,pattern in ipairs({'tied','mixed'}) do
 local G=base();G.persona.fight=fight;G.persona.lv=10;G.roster={'urda','lynette','marceline','haldric'};G.party={};G.lvl={urda=10,lynette=pattern=='mixed' and 15 or 10,marceline=pattern=='mixed' and 9 or 10,haldric=10};G.ui.tab=filter
 for i=1,n do G.party[i]=G.roster[i] end
 local ordered=B.SO.r23_ordered(G);local ids={};for _,m in ipairs(ordered) do ids[#ids+1]=m.cid end
 local members=B.SO.members(G);local summary=B.SO.summary(G,{lv=20},members);local summaries={}
 for _,enemy in ipairs({0,summary.avg+4,summary.avg+5,summary.avg+6}) do
  local quest=nil;if enemy~=0 then quest={lv=enemy} end
  summaries[#summaries+1]={enemy=enemy,value=B.SO.summary(G,quest,members)}
 end
 out.sortie[#out.sortie+1]={fight=fight,party=copy(G.party),roster=G.roster,levels=G.lvl,filter=filter,ordered=ids,normalized=B.SO.r23_filter(G),summary=summary,summaries=summaries}
end end end end
for _,nat in ipairs({'경계도시','마렌토 공화국','솔렌 성왕국'}) do for n=0,4 do
 local pm={};for i=1,4 do pm[i]={id=i<=n and 'persona' or '',nat=nat} end
 out.multipliers[#out.multipliers+1]={pm=pm,value=B.R23.out_mul({pm=pm})}
end end
for _,init in ipairs({true,false}) do
 local R={loot={}};if init then R.loot.gear={} end
 local values={'','unknown','wa01.1.1','wa01.1.1'}
 for _,code in ipairs(values) do B.ex_gear_add(R,code) end
 out.gear_add[#out.gear_add+1]={initialized=init,values=values,value=R.loot.gear}
end
for _,iid in ipairs(B.IT.order) do out.needs[#out.needs+1]={id=iid,value=B.it_need(iid)} end
out.needs[#out.needs+1]={id='unknown',value=B.it_need('unknown')}
local tested_items=copy(B.IT.order);tested_items[#tested_items+1]='unknown'
for _,lv in ipairs({1,14,15,29,30,40}) do for _,iid in ipairs(tested_items) do for _,stock in ipairs({0,1}) do for _,state in ipairs({'full','low','down','nomana','shield','dot','edot','fox','zerofox','empty'}) do
 local pm={{id='persona',cls='warrior',L=lv},{id='',cls='',L=1},{id='',cls='',L=1},{id='',cls='',L=1}}
 local run=B.run;B.run=function()end;local st=B.fresh(1,nil,{pm=pm,el=1,star=1});B.run=run;B.bind(st)
 local u=st.u[1];u.mhp=101;u.mmp=state=='nomana' and 0 or 71;u.hp=state=='down' and 0 or state=='low' and 1 or 101;u.mp=state=='low' and 1 or u.mmp;u.al=state=='down' and 0 or 1
 u.sh=state=='shield' and 0 or 1000;u.dot=state=='dot' and {{d=0,n=2}} or {};u.edot=state=='edot' and {{d=0,n=2}} or {};u.fx=state=='fox' and 2 or 0;u.empty=state=='empty' and 1 or 0
 local dot=(#u.dot>0 or #u.edot>0 or u.fx>0)
 out.combat_targets[#out.combat_targets+1]={level=lv,id=iid,stock=stock,state=state,hp=u.hp,mp=u.mp,mhp=u.mhp,mmp=u.mmp,shield=u.sh,dot=dot,value={ok=B.it_ok(st,iid,1),any=B.it_any(st,iid),blocked=B.it_blocked(st,iid)}}
end end end end
for n=0,4 do for _,layout in ipairs({'full','mixed','down'}) do for _,iid in ipairs(B.IT.order) do
 local pm={};local levels={14,15,29,30};for i=1,4 do pm[i]={id=i<=n and 'persona' or '',cls='warrior',L=levels[i]} end
 local run=B.run;B.run=function()end;local st=B.fresh(1,nil,{pm=pm,el=1,star=1});B.run=run;B.bind(st)
 local units={}
 for i=1,n do
  local u=st.u[i];u.mhp=101;u.mmp=71;u.hp=layout=='down' and 0 or (layout=='mixed' and i%2==1) and 1 or 101;u.mp=(layout=='mixed' and i%2==0) and 1 or 71;u.al=layout=='down' and 0 or 1
  u.sh=layout=='full' and 1000 or 0;u.dot={};u.edot={};u.fx=(layout=='mixed' and i==3) and 2 or 0
  units[i]={level=levels[i],hp=u.hp,mp=u.mp,mhp=101,mmp=71,shield=u.sh,fox=u.fx}
 end
 out.combat_parties[#out.combat_parties+1]={n=n,id=iid,layout=layout,units=units,value={any=B.it_any(st,iid),blocked=B.it_blocked(st,iid)}}
end end end
for _,lv in ipairs({1,14,15,29,30,40}) do for _,nat in ipairs({'경계도시','마렌토 공화국'}) do for _,iid in ipairs(B.IT.order) do for _,state in ipairs({'full','low','down','nomana','one','none'}) do
 local G=base();G.persona.lv=lv;G.persona.nation=nat;G.lvl.lynette=lv
 local pm,n,avg=B.dn_party(G);local R=B.ex_new(G,1,pm,n,avg,7);G.dungeon.run=R
 R.real=true;R.hp={state=='full' and 101 or state=='down' and 0 or 1,101,0,0};R.mp={state=='full' and 71 or 1,71,0,0};R.mhp={101,101,0,0};R.mmp={state=='nomana' and 0 or 71,71,0,0}
 if state=='nomana' then R.mp[1]=0 end
 G.items[iid]=state=='none' and 0 or 1;R.loot.items[iid]=state=='one' and 0 or state=='none' and 0 or 1
 local input={pm=copy(pm),hp=R.hp[1],mp=R.mp[1],mhp=R.mhp[1],mmp=R.mmp[1],bank=G.items[iid],pouch=R.loot.items[iid]}
 B.H.ex(G,'u_'..iid..'_1','r23')
 out.use[#out.use+1]={level=lv,nat=nat,id=iid,state=state,input=input,value={hp=R.hp[1],mp=R.mp[1],bank=G.items[iid] or 0,pouch=R.loot.items[iid] or 0}}
end end end end
for _,phase in ipairs({'explore','rest','battle','done'}) do for _,ask in ipairs({false,true}) do
 local G=base();local pm,n,avg=B.dn_party(G);local R=B.ex_new(G,1,pm,n,avg,7);G.dungeon.run=R;R.phase=phase;R.ask=ask
 B.H.ex(G,'boss','r23')
 out.boss[#out.boss+1]={phase=phase,ask=ask,value={phase=R.phase,ask=R.ask,started=G.scene=='battle'}}
end end
for _,alive in ipairs({0,1}) do for _,hp in ipairs({0,.9,1,50.9,100.9}) do
 local R={hp={101,0,0,0},mp={71,0,0,0},mhp={101,0,0,0},mmp={71,0,0,0},fell=false,real=false}
 local st={u={{empty=0,al=alive,hp=hp,mp=20.9,mhp=101.9,mmp=71.9},{empty=1},{empty=1},{empty=1}}}
 B.R23.snapshot(R,st)
 out.snapshot[#out.snapshot+1]={alive=alive,hp=hp,value=R}
end end
for n=0,12 do local R={log={}};for j=1,n do B.R23.push_log(R,'line '..j) end;out.logs[#out.logs+1]={n=n,value=R.log} end
for _,data in ipairs({{hp_s=2,mp_s=1,bandage=0},{hp_s=0,mp_s=-1},{hp_s=3,unknown=2}}) do
 local G={items={hp_s=5}};local list=B.R23.bank_items(G,data);out.bank[#out.bank+1]={input=data,items=G.items,list=list}
end
for _,f in ipairs({1,3,27,28,60,420}) do for _,kind in ipairs({'battle','elite','chief','boss','unknown'}) do for _,seed in ipairs({0,.73,1,2,3,7,100,2147483646}) do
 local G=base();local pm=B.battle_pm(G);local R={floor=f,pm=pm,loot={gear={}}}
 local code=B.ex_gear_roll(R,kind,seed)
 out.drops[#out.drops+1]={floor=f,kind=kind,seed=seed,pm=pm,value=code or '',gear=R.loot.gear}
end end end
for _,phase in ipairs({'explore','rest','battle','done'}) do
 local G=base();G.items={hp_s=2,sh_m=3};G.dungeon.run={phase=phase,loot={items={hp_s=4,sh_m=5}}}
 out.bag[#out.bag+1]={phase=phase,value=B.ex_bag(G)}
end
for _,data in ipairs({{potion=2,mana=3},{potion=2,mana=3,hp_s=5,mp_s=7},{potion=0,mana=0},{hp_s=4,mp_s=3},{potion='2',mana='3',hp_s='5',mp_s='7'}}) do
 local target=copy(data);B.ex_move_old_items(target);local twice=copy(target);B.ex_move_old_items(twice)
 out.migration[#out.migration+1]={input=data,value=target,twice=twice}
end
-- Exercise every real event at steps 1 and 5, including battle/elite transitions.
local seen={}
for seed=1,500 do for _,step in ipairs({1,5}) do
 local key=step..':'..B.ex_roll(seed,3,step,0,{'warrior','hunter'}).kind
 if not seen[key] then
  seen[key]=true;local G=base();G.dungeon.best=2;G.dungeon.sel=3;local pm,n,avg=B.dn_party(G)
  local R=B.ex_new(G,3,pm,n,avg,7);G.dungeon.run=R;R.seed=seed;R.step=step-1;local raw=B.ex_roll(seed,3,step,0,B.gear_party_cls(pm))
  B.H.ex(G,'go','r23');out.discovery[#out.discovery+1]={seed=seed,step=step,pm=pm,raw=raw,value={phase=R.phase,step=R.step,elites=R.elites,gold=R.loot.gold,items=R.loot.items,gear=R.loot.gear,ask=R.ask}}
 end
end end
for n=1,4 do for _,level in ipairs({1,15,40}) do for _,race in ipairs({'인간','엘프'}) do
 local G=base();G.persona.lv=level;G.persona.race=race;G.party={};G.roster={'lynette','marceline','urda'}
 for i=1,n-1 do G.party[i]=G.roster[i] end
 G.lvl={lynette=level,marceline=level,urda=level}
 local pm,pn,avg=B.dn_party(G);local R=B.ex_new(G,1,pm,pn,avg,7);G.dungeon.run=R
 local row={n=n,level=level,race=race,party=copy(G.party),pm=pm,seed=R.seed,value={hp=copy(R.hp),mp=copy(R.mp),mhp=copy(R.mhp),mmp=copy(R.mmp),step=R.step,phase=R.phase,ask=R.ask,elites=R.elites,wins=R.wins}}
 -- Isolate setup resources before B.run executes the opening enemy turns.
 local run=B.run;B.run=function()end;B.ex_battle(G,'r23','battle',1);B.run=run
 local st=B.load('r23');row.first={hp={},mp={},mhp={},mmp={}}
 for i=1,4 do for _,key in ipairs({'hp','mp','mhp','mmp'}) do row.first[key][i]=st.u[i].empty==1 and 0 or st.u[i][key] end end
 out.new_run[#out.new_run+1]=row
end end end
return out
`);
const folder=path.join(root,'verification/parity-r23');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(folder,'expe-oracle.json'),JSON.stringify(fixtures)+'\n');
fs.writeFileSync(path.join(folder,'expe-provenance.json'),JSON.stringify({method:'Canonical Lua in original lua_sim, read-only chunks; local exports only; no rewritten oracle rules.',files:names.map((n,i)=>({file:n,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')})),rows:Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length]))},null,2)+'\n');
console.log(Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])));
if(sim.close)await sim.close();
