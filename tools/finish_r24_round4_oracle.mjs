// Execute canonical Lua copies, retaining source hashes for every fixture.
import fs from 'node:fs';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const src='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','24-stats.lua','34-traits.lua','60-create.lua','70-town.lua','71-shop.lua','72-guild.lua','73-inn.lua','74-level.lua','74-affection.lua','75-sortie.lua','76-dungeon.lua','77-explore.lua','81-gear.lua'];
const raw=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const extra=raw.map((s,i)=>`assert(load(${JSON.stringify(s)},${JSON.stringify('@'+names[i])},'t',_ENV))()`).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {L,sim}=await mkSim({policy:false,extra});
try{
 const out=await L(`
local out={pages={},totals={},scenarios={},inn_routes={}}
local function cp(x)return json.decode(json.encode(x))end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 local function page(kind,p,fn)out.pages[#out.pages+1]={kind=kind,lang=lang,p=cp(p),html=fn(p)}end
 for _,race in ipairs({'','human','elf','beast','dwarf','demon','unknown'})do
  for _,lineage in ipairs({'','dog','cat','unknown'})do
   local p=B.CR.view(B.G_new());local r=B.CR.by(B.CR.RACES,'id',race);local l=B.CR.by(B.CR.LINEAGES,'id',lineage)
   p.race=r and r.name or race;p.lineage=l and l.name or lineage
   page('race',p,B.CR.pg_race)
   for _,nation in ipairs({'','border','seredia','unknown'})do
    local n=B.CR.by(B.CR.NATIONS,'id',nation);p.nation=n and n.name or nation
    page('nation',p,B.CR.pg_nation)
   end
  end
 end
 for _,n in ipairs(B.CR.NATIONS)do for _,c in ipairs(B.CLASSES)do
  local p=B.CR.view(B.G_new());p.nation=n.name;p.cls=c.name
  page('class',p,B.CR.pg_cls)
 end end
 for _,name in ipairs({'','unknown'})do local p=B.CR.view(B.G_new());p.cls=name;page('class',p,B.CR.pg_cls);page('stats',p,B.CR.pg_stats)end
 for _,n in ipairs({0,1,5,10,20,98,99})do for _,custom in ipairs({0,1})do
  local p=B.CR.view(B.G_new());p.cls=B.CLASSES[1].name;p.bonus_total=n;p.bonus_custom=custom
  out.totals[#out.totals+1]={lang=lang,p=cp(p),html=B.CR.tot_ui(p)}
  for _,c in ipairs(B.CLASSES)do
   p.cls=c.name;p.bonus={str=0,agi=0,int=0,def=0,spd=0};page('stats',p,B.CR.pg_stats)
   local g=B.G_new();g.persona=p;B.H.cr(g,'auto','finish');page('stats',p,B.CR.pg_stats)
  end
 end end
 for _,sc in ipairs(B.CR.scens())do
  local g=B.G_new();g.scene='scenario';g.ui.sel=sc.id
  out.scenarios[#out.scenarios+1]={lang=lang,selected=sc.id,html=B.SCREENS.scenario(g,'finish')}
 end
end
return out
 `);
 const plain=s=>s.replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/\s+/g,' ').trim();
 for(const key of ['pages','totals','scenarios'])for(const row of out[key]){
  if(row.kind==='stats')row.bars=[...row.html.matchAll(/class="cr-(tot|b0)" style="transform:scaleX\(([^)]+)\)/g)].map(m=>({kind:m[1],ratio:Number(m[2])}));
  row.text=plain(row.html);
  row.buttons=[...row.html.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/g)].map(m=>({id:m[1].match(/risu-btn="([^"]*)"/)?.[1]??'',text:plain(m[2]),disabled:/\boff\b/.test(m[1]),selected:/\bon\b|\bpick\b/.test(m[1])}));
  delete row.html;
 }
 out.sources=names.map((n,i)=>({file:'bot/src/'+n,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')}));
 fs.writeFileSync('verification/finish-r24/round4/oracle.json',JSON.stringify(out));
 console.log(JSON.stringify({pages:out.pages.length,totals:out.totals.length,scenarios:out.scenarios.length}));
}finally{sim.close()}
