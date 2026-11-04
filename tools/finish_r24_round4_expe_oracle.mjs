import fs from 'node:fs';
let loader=fs.readFileSync('tools/expe_r23_pass3_oracle.mjs','utf8').split('try {')[0].replace("path.resolve(import.meta.dirname,'..')",'process.cwd()');
loader+=`
try{
 const out=await L(\`
local P=json.decode([=[\${JSON.stringify(persona)}]=])
local out={views={},actions={}};local function cp(v)return json.decode(json.encode(v))end
local oldget,oldset=getChatVar,setChatVar;local stored='';B.VID='finish4'
getChatVar=function(id,key)if key=='dk_bag'then return stored end;return oldget(id,key)end
setChatVar=function(id,key,value)if key=='dk_bag'then stored=value else oldset(id,key,value)end end
local function base(lv,sel,n)
 local g=B.G_new();g.persona=cp(P);g.persona.name='';g.persona.cls='전사';g.persona.lv=lv;g.persona.exp=0;g.persona.fight=1;g.roster={'teiris'};g.party={'teiris'};g.lvl={teiris=lv};g.exp={};g.equip={persona={weapon='wa01.9.1'},teiris={}};g.scene='dungeon'
 local pm,pn,avg=B.dn_party(g);g.dungeon={best=2,sel=1,mode=1,pg=1,runs=0,cleared_bosses={}};g.dungeon.run=B.ex_new(g,1,pm,pn,avg,7);local r=g.dungeon.run;r.phase='rest';r.sel=sel;r.last='unchanged'
 local bag={};for i=1,n do bag[#bag+1]='wa01.'..string.format('%x',i)..'.1'end
 bag[#bag+1]='sa01.1.1';bag[#bag+1]='aa01.1.1';bag[#bag+1]='wa80.1.1';stored=table.concat(bag,';')
 return g,r,bag
end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,lv in ipairs({1,40})do for _,sel in ipairs({0,1,2,3,4,9})do for _,n in ipairs({0,2,16})do
  local g,r,bag=base(lv,sel,n);local before=cp(g)
  local h=B.R23P3.gear(g,r)
  out.views[#out.views+1]={lang=lang,lv=lv,sel=sel,n=n,G=before,R=cp(r),bag=bag,html=h}
 end end end
 for _,phase in ipairs({'rest','explore','battle'})do for _,sel in ipairs({1,2,3})do
  for _,arg in ipairs({'who_1','who_2','who_4','who_0','eq_weapon_wa01_1_1','eq_armor_wa01_1_1','eq_weapon_wa80_1_1','eq_weapon_wa01_9_1','eq_weapon_sa01_1_1','eq_nonsense_wa01_1_1','eq_weapon_bad','un_weapon','un_acc','un_unknown'})do
   local g,r,bag=base(1,sel,2);r.phase=phase;local before=cp(g)
   B.H.ex(g,arg,'finish4')
   out.actions[#out.actions+1]={lang=lang,arg=arg,G=before,bag=bag,after=cp(g),after_bag=B.bag_load('finish4')}
  end
 end end
end
return out
 \`);
 const plain=s=>s.replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/\\s+/g,' ').trim();
 for(const row of out.views){row.text=plain(row.html);row.buttons=[...row.html.matchAll(/<button\\b([^>]*)>([\\s\\S]*?)<\\/button>/g)].map(m=>({id:m[1].match(/risu-btn="([^"]*)"/)[1],text:plain(m[2]),disabled:/\\boff\\b/.test(m[1]),selected:/\\bon\\b|\\bpick\\b/.test(m[1])}));delete row.html;}
 out.sources=raw.map(f=>({file:f.name,sha256:crypto.createHash('sha256').update(f.text).digest('hex')}));
 fs.writeFileSync('verification/finish-r24/round4/expe-oracle.json',JSON.stringify(out));console.log(JSON.stringify({views:out.views.length,actions:out.actions.length}));
}finally{sim.close()}
`;
await import('data:text/javascript;base64,'+Buffer.from(loader).toString('base64'));
