// Direct canonical Lua execution through the original Wasmoon harness. Read-only source.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..');
const source='C:/Clauede Code/dungeon-bot/bot';
const names=['05-gen.lua','10-data.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','74-level.lua','74-affection.lua','75-sortie.lua','76-dungeon.lua','77-explore.lua','78-battle-item.lua'];
const raw=names.map(n=>fs.readFileSync(path.join(source,'src',n),'utf8'));
const {mkSim}=await import(pathToFileURL(source+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:raw.map(x=>'do\n'+x+'\nend').join('\n')});
const constants=await L(`return {traits=B.TXN,nations={['신성 세레디아 제국']='seredia',['대카라쉰']='karashin',['솔렌 성왕국']='solen',['마렌토 공화국']='marento',['나에린']='naerin',['모르가스 신관국']='morgas',['케른 연방']='kern',['경계도시']='border'},page=B.DN.PAGE}`);
const fixtures=await L(`
local out={modifiers={},rolls={},discoveries={},rest={},recommended={},pouch={},amounts={},drops={},combat_items={},settlements={},regen_mix={}}
local nations={'신성 세레디아 제국','대카라쉰','솔렌 성왕국','마렌토 공화국','나에린','모르가스 신관국','케른 연방','경계도시'}
for _,nat in ipairs(nations) do for n=0,4 do
 local pm={} for i=1,4 do pm[i]={id=i<=n and 'persona' or '',nat=nat,race='인간',cls='warrior',L=20} end
 local units={} for i=1,4 do units[i]={al=1,empty=i>n,na=i<=n and B.tr_ids(pm[i]) or ''};local _,_,natid=B.tr_ids(pm[i]);units[i].na=i<=n and natid or '' end
 local hp,mp=B.tx_rest(pm);local coin,dup,herb=B.tx_find(pm);local loss,keep=B.tx_defeat(pm)
 local old_pm=B.battle_pm;B.battle_pm=function()return pm end;local shop=B.tx_shop({});B.battle_pm=old_pm
 out.modifiers[#out.modifiers+1]={pm=pm,value={rest_hp=hp,rest_mp=mp,aff=B.tx_aff(pm),coin=coin,dup=dup,herb=herb,loss=loss,keep=keep,gold=B.reward_gold({pm=pm},100)/100,item=B.item_mul({pm=pm,u=units}),exp=B.GH.exp({pm=pm}),shop=shop}}
end end
for floor=1,420 do for step=1,5 do
 local seed=floor*7919+13;local elites=step%3;local classes={'warrior','assassin','sanctioned','priest'}
 out.rolls[#out.rolls+1]={seed=seed,floor=floor,step=step,elites=elites,classes=classes,value=B.ex_roll(seed,floor,step,elites,classes)}
end end
for _,row in ipairs(out.modifiers) do
 for seed=1,35 do
  local G=B.G_new();G.scene='dungeon';G.persona.cls='전사';G.dungeon={best=20,sel=20};local R=B.ex_new(G,20,row.pm,4,20,1);G.dungeon.run=R;R.seed=seed
  local raw=B.ex_roll(seed,20,1,0,B.gear_party_cls(row.pm))
  if raw.kind~='battle' and raw.kind~='elite' then
   B.H.ex(G,'go','p5-oracle')
   out.discoveries[#out.discoveries+1]={pm=row.pm,seed=seed,floor=20,step=1,raw=raw,gold=R.loot.gold,items=R.loot.items,gear=R.loot.gear}
  end
 end
 for _,max in ipairs({101,800,1001}) do
  local R={pm=row.pm,mhp={max,max,max,max},mmp={71,71,71,71},hp={0,1,50,80},mp={0,1,10,20},log={},step=5,floor=20}
  local G=B.G_new();G.scene='dungeon';B.ex_enter_rest(G,'p5-oracle',R)
  out.rest[#out.rest+1]={pm=row.pm,max=max,hp=R.hp,mp=R.mp}
 end
end
for _,avg in ipairs({1,1.5,2,4,5,10,20,39,40}) do for _,mx in ipairs({1,6,27,60,420}) do out.recommended[#out.recommended+1]={avg=avg,mx=mx,value=B.dn_rec_floor(avg,mx)} end end
for _,a in ipairs({0,1,3}) do for _,p in ipairs({0,1,3}) do
 local G={items={hp_s=a},dungeon={run={phase='explore',loot={items={hp_s=p}}}}};local seq={}
 for i=1,5 do local ok=B.ex_take(G,'hp_s');seq[#seq+1]={ok=ok,bank=G.items.hp_s or 0,pouch=G.dungeon.run.loot.items.hp_s or 0,have=B.ex_have(G,'hp_s')} end
 out.pouch[#out.pouch+1]={bank=a,pouch=p,value=seq}
end end
for _,iid in ipairs(B.IT.order) do if B.ITEMS[iid].kind=='hp' or B.ITEMS[iid].kind=='mp' or B.ITEMS[iid].kind=='sh' then for _,max in ipairs({101,800,1001}) do for _,mul in ipairs({1,1.1}) do out.amounts[#out.amounts+1]={id=iid,max=max,mul=mul,value=B.it_amount(iid,{mhp=max,mmp=max},mul),need=B.it_need(iid)} end end end end
for _,f in ipairs({1,3,8,18,27,60,420}) do for _,kind in ipairs({'elite','chief','boss'}) do for seed=1,5 do
 local R={floor=f,pm={{id='persona',cls='warrior'}},loot={gear={}}};local raw=B.ex_mix(seed,f,kind=='elite' and 3 or 99,kind=='elite' and 21 or 22)
 local code=B.ex_gear_roll(R,kind,raw)
 out.drops[#out.drops+1]={floor=f,kind=kind,seed=seed,value=code or ''}
end end end

for _,iid in ipairs(B.IT.order) do for _,tags in ipairs({'neutral','human','marento','solen'}) do
 local pm={} for i=1,4 do pm[i]={id='persona',cls='warrior',L=40,race='엘프',nat='경계도시'} end
 local st=B.fresh(1,nil,{pm=pm,el=1,star=1});B.bind(st);B.begin_ev(st);st.cur=1
 for i=1,4 do st.u[i].rc=tags=='human' and 'human' or '';st.u[i].na=(i<=2 and (tags=='marento' or tags=='solen')) and tags or '' end
 local u=st.u[1];u.mhp=1001;u.mmp=101;u.hp=1;u.mp=1;u.sh=0;u.shT=0
 if iid=='bandage' then u.hp=0;u.al=0;u.chg=1;u.bf={adn={v=.1,n=2}} end
 if iid=='antidote' then u.dot={{d=5,n=2}};u.edot={{d=4,n=2}};u.fx=2 end
 local amount=B.it_apply(st,iid,1)
 out.combat_items[#out.combat_items+1]={id=iid,tags=tags,amount=amount,hp=u.hp,mp=u.mp,shield=u.sh,alive=u.al,charging=u.chg,shield_turns=u.shT,dot=#(u.dot or {}),enemy_dot=#(u.edot or {}),fox=u.fx or 0}
end end
for _,order in ipairs({{'sorel','adeline'},{'adeline','sorel'}}) do
 local pm={{id='sorel',cls='alchemist',L=20},{id='adeline',cls='priest',L=20},{id='marceline',cls='paladin',L=20},{id='haldric',cls='warrior',L=20}}
 local st=B.fresh(1,nil,{pm=pm,el=1,star=1});B.bind(st);local used=0
 for _,name in ipairs(order) do local at=name=='sorel' and 1 or 2;st.n=st.n+1;st.cur=at;B.begin_ev(st);B.PRUN[name](st,at,nil,{name=name});used=used+1 end
 local copy=json.decode(json.encode(st))
 out.regen_mix[#out.regen_mix+1]={order=order,used=used,serializable=type(copy.u)=='table'}
end
for _,result in ipairs({'clear','retreat','defeat'}) do for _,nat in ipairs({'경계도시','케른 연방','솔렌 성왕국'}) do
 local G=B.G_new();G.scene='dungeon';G.gold=300;G.persona.cls='전사';G.persona.fight=1;G.persona.nation=nat;G.persona.race='인간'
 G.roster={'marceline','naran','teiris'};G.party=G.roster;G.lvl={marceline=1,naran=1,teiris=1};G.items={};G.dungeon={best=2,sel=3,mode=1,pg=1}
 local pm=B.battle_pm(G);local R=B.ex_new(G,3,pm,4,1,11);G.dungeon.run=R;R.seed=7;R.wins=2;R.step=5;R.loot.gold=101;R.loot.items.hp_s=4;R.exp=250
 if result=='retreat' then R.ask=true;B.H.ex(G,'retreat_yes','p5-oracle') else
  R.phase='battle';R.cur_bn=12;R.cur_kind='boss'
  B.dn_settle(G,'p5-oracle',{dn={kind='boss'},sid=11,bn=12,over=result=='clear' and 'win' or 'lose',rg=203,exp=127,star=B.floor_star(B.floor_info(3))})
 end
 local sum=R.summary
 out.settlements[#out.settlements+1]={result=result,nat=nat,pm=pm,gold=G.gold,items=G.items,summary=sum,aff=G.aff,persona=G.persona,lvl=G.lvl,exp=G.exp}
end end
return out`);
const folder=path.join(root,'verification/expedition-r22');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(root,'project/data/expedition-r22.json'),JSON.stringify(constants,null,2)+'\n');
fs.writeFileSync(path.join(folder,'oracle.json'),JSON.stringify(fixtures)+'\n');
fs.writeFileSync(path.join(folder,'provenance.json'),JSON.stringify({files:names.map((n,i)=>({name:n,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')})),contracts:['harness_expedition.mjs','harness_regen_mix.mjs','harness_raid.mjs'],method:'Direct reloaded canonical Lua functions and handlers; source harness contracts read in full. No original writes or host LLM.'},null,2)+'\n');
console.log(Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])));
if(sim.close)await sim.close();
