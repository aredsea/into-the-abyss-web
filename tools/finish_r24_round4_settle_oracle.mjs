import fs from 'node:fs';
let loader=fs.readFileSync('tools/expe_r23_pass3_oracle.mjs','utf8').split('try {')[0].replace("path.resolve(import.meta.dirname,'..')",'process.cwd()');
loader+=`
try{
 const out=await L(\`
local P=json.decode([=[\${JSON.stringify(persona)}]=]);local out={};local stored='';local oldget,oldset=getChatVar,setChatVar
getChatVar=function(id,key)if key=='dk_bag'then return stored end;return oldget(id,key)end
setChatVar=function(id,key,value)if key=='dk_bag'then stored=value else oldset(id,key,value)end end
B.ex_gear_roll=function()return nil end -- Already-paid exploration loot; boss drop RNG is covered separately.
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,result in ipairs({'clear','retreat','defeat'})do for _,kern in ipairs({false,true})do for _,n in ipairs({0,1999,2000,2001})do
  local G=B.G_new();G.persona=P;G.persona.name='';G.persona.cls='전사';G.persona.lv=1;G.persona.exp=0;G.persona.fight=1;G.persona.race='인간';G.persona.nation=kern and '케른 연방' or '경계도시';G.gold=300;G.scene='dungeon';G.roster=kern and {'haldric','urda'} or {'teiris'};G.party=G.roster;G.lvl={};G.exp={};G.aff={};G.items={hp_s=2};G.dungeon={best=2,sel=1,mode=1,pg=1,runs=0,cleared_bosses={}}
  for _,cid in ipairs(G.roster)do G.lvl[cid]=1;G.exp[cid]=0;G.aff[cid]=0 end
  local pm,pn,avg=B.dn_party(G);local R=B.ex_new(G,1,pm,pn,avg,7);G.dungeon.run=R;R.phase=result=='retreat' and 'rest' or 'battle';R.step=5;R.wins=3;R.loot={gold=21,items={hp_s=4,mp_s=3},gear={'wa01.2.1','wa01.3.1','wa01.4.1'}};R.exp=55
  local bag={};for i=1,n do bag[i]='wa01.1.1'end;stored=table.concat(bag,';')
  B.R23P3.finish(G,'finish4',R,result,{rg=0,exp=0,star=1})
  local list=B.bag_load('finish4');out[#out+1]={lang=lang,result=result,kern=kern,n=n,msg=G.ui.msg,gold=G.gold,items=G.items,summary=R.summary,bag=table.concat(list,';'),count=#list,day=G.town.day,best=G.dungeon.best,runs=G.dungeon.runs,run_exists=G.dungeon.run~=nil}
 end end end
end
return out
 \`);
 for(const row of out){row.bag_sha256=crypto.createHash('sha256').update(row.bag).digest('hex');delete row.bag;}
 fs.writeFileSync('verification/finish-r24/round4/settle-oracle.json',JSON.stringify({rows:out,sources:raw.map(f=>({file:f.name,sha256:crypto.createHash('sha256').update(f.text).digest('hex')}))}));console.log(JSON.stringify({settlements:out.length}));
}finally{sim.close()}
`;
await import('data:text/javascript;base64,'+Buffer.from(loader).toString('base64'));
