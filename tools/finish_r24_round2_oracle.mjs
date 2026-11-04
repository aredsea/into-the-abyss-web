// Execute the unmodified canonical functions; export only the lexical fight row.
import fs from 'node:fs';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const source='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','24-stats.lua','34-traits.lua','60-create.lua','70-town.lua','74-level.lua','75-sortie.lua','76-dungeon.lua','77-explore.lua','81-gear.lua'];
const raw=names.map(n=>fs.readFileSync(`${source}/src/${n}`,'utf8'));
const extra=raw.map((s,i)=>{
 if(names[i]==='75-sortie.lua')s=s.replace('  -- ④ 후보 카드 그리드','  B.finish_fight_row = fight_row\n  -- ④ 후보 카드 그리드');
 return `assert(load(${JSON.stringify(s)},${JSON.stringify('@'+names[i])},'t',_ENV))()`;
}).join('\n');
const {mkSim}=await import(pathToFileURL(source+'/lua_sim.mjs'));
const {L,sim}=await mkSim({policy:false,extra});
try {
 const result=await L(`
 local out={bank={},fight={}}
 local get,set=getChatVar,setChatVar;local stored=''
 getChatVar=function(id,key)if key=='dk_bag'then return stored end;return get(id,key)end
 setChatVar=function(id,key,value)if key=='dk_bag'then stored=value else set(id,key,value)end end
 for _,size in ipairs({0,1999,2000,2001})do
  for _,codes in ipairs({{'zz99.1.1'},{'invalid'},{'zz99.1.1','wa01.2.1','zz99.1.1','wa01.3.1'},{'wa01.2.1','wa01.3.1'},{'wa01.0.1','wa01.0001.1','wa01.1.99'},{false,7,'wa01.1.1'}})do
   local bag={};for i=1,size do bag[i]='wa01.1.1'end;stored=table.concat(bag,';')
   local got,lost=B.ex_gear_bank(B.G_new(),'finish',codes)
   out.bank[#out.bank+1]={size=size,codes=codes,got=got,lost=lost,after=#B.bag_load('finish')}
  end
 end
 getChatVar,setChatVar=get,set
 for _,lang in ipairs({'ko','en'})do B.LANG=lang
  for _,cls in ipairs({'','전사','마법사'})do for _,fight in ipairs({0,1})do
   for _,party in ipairs({{}, {'teiris'},{'teiris','hildegard','bargut','marceline'}})do
    local g=B.G_new();g.scene='sortie';g.persona.cls=cls;g.persona.fight=fight;g.roster={'teiris','hildegard','bargut','marceline'};g.party=party
    local before=json.decode(json.encode(g));local html=B.finish_fight_row(g);B.H.so(g,'fight_1','finish')
    out.fight[#out.fight+1]={lang=lang,cls=cls,fight=fight,party=before.party,html=html,after={fight=g.persona.fight,party=g.party,msg=g.ui.msg}}
   end
  end end
 end
 return out
 `);
 const plain=s=>s.replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/\s+/g,' ').trim();
 for(const row of result.fight){
  row.text=plain(row.html);
  row.buttons=[...row.html.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/g)].map(m=>({id:m[1].match(/risu-btn="([^"]*)"/)[1],label:plain(m[2]),selected:/\bon\b/.test(m[1]),enabled:!(/\boff\b/.test(m[1]))}));
  delete row.html;
 }
 result.sources=names.map((n,i)=>({file:'bot/src/'+n,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')}));
 fs.writeFileSync('verification/finish-r24/round2/oracle.json',JSON.stringify(result));
 console.log(JSON.stringify({bank:result.bank.length,fight:result.fight.length}));
}finally{sim.close()}
