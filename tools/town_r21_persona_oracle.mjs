// Source functions run unmodified in the existing Wasmoon harness, no scene/AI call.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const bot='C:/Clauede Code/dungeon-bot';
const {mkSim}=await import(pathToFileURL(bot+'/bot/lua_sim.mjs').href);
const files=['bot/src/01-game.lua','design/persona_skill.json','bot/src/29-persona-skill.lua'];
const texts=files.map(f=>fs.readFileSync(path.join(bot,f),'utf8'));
const {sim,L}=await mkSim({policy:false,extra:texts[0]+'\nB.PERSONA_RAW=[==['+texts[1]+']==]\n'+texts[2]});
const result=await L(`
B.LANG='ko'
local out={clean={},skills={},actions={},cost={}}
local function cp(x) return json.decode(json.encode(x)) end
for n=0,11 do out.cost[#out.cost+1]={n=n,value=B.ps_cost(n)} end
local raws={false,17,'bad',{}, {prefix='strike',suffix='regen',prefix_lv={strike='2.9',bad=99},suffix_lv={regen=12}},
 {prefix='bad',suffix='bane',prefix_lv={strike=-5,sweep=99},suffix_lv={bane='bad'}},
 {prefix='mend',suffix='crit',prefix_lv={mend=true},suffix_lv={crit='4'}}}
for _,raw in ipairs(raws) do out.clean[#out.clean+1]={raw=raw,value=B.ps_clean(raw)} end
for _,p in ipairs(B.PERSONA.prefixes) do
 for _,s in ipairs(B.PERSONA.suffixes) do
  for a=0,10 do for b=0,10 do
   local raw={prefix=p.id,suffix=s.id,prefix_lv={[p.id]=a},suffix_lv={[s.id]=b}}
   out.skills[#out.skills+1]={raw=raw,value=B.ps_clean(raw),ready=B.ps_ready(raw),name=B.ps_name(raw),description=B.ps_desc(raw),name_en=B.ps_name(raw,true),description_en=B.ps_desc(raw,true),skill=B.ps_skill(raw) or false}
  end end
 end
end
-- Only pend host is replaced, to prevent generating or sending any narrative.
local busy=false;local pend_calls=0
B.pend_busy=function() return busy end
B.pend_hard=function() pend_calls=pend_calls+1 end
local function snapshot(G)
 return {saved=cp(G.persona.skill),draft=G.ui.psd and cp(G.ui.psd) or {},spent=G.ui.psd_gold or 0,gold=G.gold,message=G.ui.msg or ''}
end
local function act(G,arg,is_busy)
 busy=not not is_busy
 local input=snapshot(G);G.ui.msg=nil
 B.ps_guild_action(G,arg,'local-persona-oracle')
 out.actions[#out.actions+1]={input=input,arg=arg,busy=busy,value=snapshot(G)}
end
for _,gold in ipairs({0,59,60,119,1000000}) do
 for _,p in ipairs(B.PERSONA.prefixes) do for _,s in ipairs(B.PERSONA.suffixes) do
  if B.ps_compatible(p,s) then
   local G={persona={skill=B.ps_clean({})},ui={},gold=gold}
   act(G,'ps_save');act(G,'ps_suf_'..s.id);act(G,'ps_pre_'..p.id);act(G,'ps_save');act(G,'ps_suf_'..s.id)
   act(G,'ps_save',true)
   for n=1,11 do act(G,'ps_up_pre');act(G,'ps_up_suf') end
   act(G,'ps_save');act(G,'ps_save');act(G,'ps_pre_mend');act(G,'ps_suf_guard');act(G,'ps_pre_strike');act(G,'ps_suf_abyss');act(G,'ps_up_pre');act(G,'ps_save');act(G,'ps_bad_x');act(G,'ps_up_bad')
  end
 end end
end
out.pend_stub_calls=pend_calls
return out`);
const folder=path.join(root,'verification/town-r21/round5');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(folder,'persona-oracle.json'),JSON.stringify(result)+'\n','utf8');
fs.writeFileSync(path.join(folder,'persona-provenance.json'),JSON.stringify({method:'Unmodified source functions in Wasmoon; pend_busy fixture and pend_hard no-op replace scene host; no AI or adult handler invoked; Korean language',files:files.map((f,i)=>({path:path.join(bot,f),sha256:crypto.createHash('sha256').update(texts[i]).digest('hex')})),data_matches_project_bytes:texts[1]===fs.readFileSync(path.join(root,'project/data/persona_skill.json'),'utf8'),data_matches_project_semantic:JSON.stringify(JSON.parse(texts[1]))===JSON.stringify(JSON.parse(fs.readFileSync(path.join(root,'project/data/persona_skill.json'),'utf8')))},null,2)+'\n','utf8');
console.log(Object.fromEntries(Object.entries(result).map(([k,v])=>[k,Array.isArray(v)?v.length:v])));
if(sim.close)await sim.close();
