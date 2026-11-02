import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source='C:/Clauede Code/dungeon-bot/bot/src/';
const files=['01-game.lua','72-guild.lua','74-level.lua'];
const raw=Object.fromEntries(files.map(f=>[f,fs.readFileSync(source+f,'utf8')]));
const rng=raw['01-game.lua'].match(/function B\.G_rnd\(G\)[\s\S]*?\nend/)[0];
const {mkSim}=await import(pathToFileURL('C:/Clauede Code/dungeon-bot/bot/lua_sim.mjs').href);
const {sim,L}=await mkSim({policy:false,extra:rng+'\n'+raw['74-level.lua']+'\n'+raw['72-guild.lua']});
const result=await L(`
B.pend_busy=function() return false end
local rows={};local ids={"hildegard","bargut","teiris","berenga"}
for _,seed in ipairs({1,2,42,777,4242,20261008,20261027,2147483646}) do
 for _,n in ipairs({0,4,17,10000}) do
  for _,lv in ipairs({1,17,40}) do
   local G={scene="guild",seed=seed,n=n,gold=100000,roster={},aff={},lvl={},exp={},persona={lv=lv,exp=0},guild={quests={},active="",done=0,recruits=0,tickets=0},town={bn=0,day=1,acts={},rr=0},ui={},settings={nsfw=0}}
   for _,id in ipairs(ids) do G.roster[#G.roster+1]=id end
   for i=1,26 do
    local cands=B.gd_candidates(G);local before=G.n;local money=G.gold
    B.H.gd(G,"meet","k")
    local id=G.roster[#G.roster]
    rows[#rows+1]={seed=seed,n=before,lv=lv,recruits=i-1,candidates=cands,id=id,after_n=G.n,cost=money-G.gold,aff=G.aff[id],level=G.lvl[id],xp=G.exp[id],npc=B.npc_aff(G,"fenella")}
   end
   local before=G.n;B.H.gd(G,"meet","k")
   assert(G.n==before and #G.roster==30,"full roster consumed random")
  end
 end
end
return {rows=rows,cast_order=B.CAST_ORDER}`);
const dir=path.join(root,'verification/town-r21/round7');fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'recruit-oracle.json'),JSON.stringify(result)+'\n');
fs.writeFileSync(path.join(dir,'recruit-provenance.json'),JSON.stringify({sources:files.map(f=>({file:source+f,sha256:crypto.createHash('sha256').update(raw[f]).digest('hex')})),method:'Unmodified source gd meet handler, candidates, G_rnd, join_level; pend_busy=false; 96 full rosters / 2496 introductions.'},null,2)+'\n');
console.log('RECRUIT LUA',result.rows.length);
if(sim.close)await sim.close();
