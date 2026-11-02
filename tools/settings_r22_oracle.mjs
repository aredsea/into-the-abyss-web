// Current source Lua is read-only. No AI requests, cloud calls or source builds.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'), src='C:/Clauede Code/dungeon-bot', folder=root+'/verification/settings-r22';
fs.mkdirSync(folder,{recursive:true});
const files=[],read=f=>{const t=fs.readFileSync(f,'utf8');files.push({path:f,sha256:crypto.createHash('sha256').update(t).digest('hex')});return t;};
const ui=JSON.parse(read(src+'/design/i18n/ui/en.json')), words={};
for(const f of fs.readdirSync(src+'/design/i18n/en').sort()){
 if(f==='intimacy.json')continue; // No sexual-content dictionary is shipped by P8.
 Object.assign(words,JSON.parse(read(src+'/design/i18n/en/'+f)));
}
Object.assign(words,JSON.parse(read(src+'/design/i18n/names.json')));
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','67-settings.lua','90-triggers.lua'];
const raw=names.map(f=>read(src+'/bot/src/'+f));
const {mkSim}=await import(pathToFileURL(src+'/bot/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:'local oracle_button=onButtonClick\n'+raw.join('\n')+'\nonButtonClick=oracle_button'});
// 05-gen also contains the original build's harvested UI pack. Do not replace
// it with the smaller manually maintained design/i18n/ui file.
const generated=await L('B.EN=nil;B.UI={};return {words=B.en_dict(),ui=B.ui_pack("en")}');
Object.assign(words,generated.words);Object.assign(ui,generated.ui);
const persona=JSON.parse(fs.readFileSync(root+'/project/data/persona-r22.json','utf8'));
const profiles={}, markdown=t=>t.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/,'').trim();
for(const sc of persona.scenarios){
 const t=read(src+'/bot/scenarios_en/'+sc.id+'.md');words[sc.text]=markdown(t);
 for(const k of ['title','teaser','place']){const v=t.match(new RegExp('^'+k+': (.*)$','m'))?.[1];if(v)words[sc[k]]=v;}
}
const publicProfiles=JSON.parse(fs.readFileSync(root+'/project/data/chronicle-r22.json','utf8')).profiles;
for(const id of Object.keys(publicProfiles)){
 const t=markdown(read(src+'/bot/lore_en/npcs/'+id+'.md'));let privateBlock=false;const lines=[];
 for(const line of t.split(/\r?\n/)){
  if(/hidden truth|private|비공개|숨은 진실/i.test(line)){privateBlock=true;continue;}
  if(privateBlock){if(/^#{1,3} /.test(line))privateBlock=false;else continue;}
  if(line.trim()&&!/^\s*>/.test(line))lines.push(line);
 }profiles[id]={name:words[publicProfiles[id].name]||publicProfiles[id].name,lines};
}
const stats=JSON.parse(read(src+'/design/stats.json'));
const display=Object.fromEntries(stats.companions.map(c=>[c.id,c.name]));
const data={ui,words,profiles,display,difficulties:await L('return B.DIFF')};
const fixtures=await L(`
local out={josa={},diff={},actions={},u={}}
local samples={'','나란','레비아','힐데가','베렌가','바르굿','서울','길','집','나란·','나란😀','레비아 ( )','L','m','n','r','A','B','Z','0','1','2','3','4','5','6','7','8','9','{{user}}','{{이름}}','😀','가'}
for cp=0xAC00,0xD7A3 do samples[#samples+1]=utf8.char(cp) end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,word in ipairs(samples) do
  local row={word=word,lang=lang,jong=B.jong(word),tails={}}
  for _,key in ipairs({'이가','을를','은는','와과','으로','이다','에게','invalid'}) do row.tails[key]=B.josa(word,key) end
  out.josa[#out.josa+1]=row
 end
 for _,text in ipairs({'설정','금화 {n}','{a:이가} 왔다','사전에 없는 말','{a:으로} 간다','{unknown} 그대로'}) do
  local vars={n=12,a='레비아'};out.u[#out.u+1]={src=text,vars=vars,lang=lang,value=B.U(text,vars)}
 end
end
for _,v in ipairs({-2,0,0.8,1,1.9,2,2.9,3,3.9,4,99,'bad','1','2','3'}) do out.diff[#out.diff+1]={input=v,value=B.DIFF_MUL({settings={diff=v}})} end
for _,action in ipairs({'lang_en','lang_ko','lang_fr','diff_1','diff_2','diff_3','diff_4','chron_0','chron_1','reset_yes','reset','reset_no','reset','reset_yes'}) do
 local G=B.G_new();G.gold=987;G.ui.tab='';B.H.op(G,action,'key');out.actions[#out.actions+1]={action=action,settings=G.settings,tab=G.ui.tab,gold=G.gold,scene=G.scene}
end
return out`);
fixtures.forms=[];
for(const value of ['1','2','3','0','4',1,true,['1'],null]){
 const payload=JSON.stringify({data:{dk_lang:'en',dk_diff:value,dk_chron:'0',dk_gold:'999',dk_reset:'yes'}});
 const result=await L(`local G=B.G_new();G.gold=987;B.G_save('key',G);onFormSubmit('key','dk_settings',${JSON.stringify(payload)});return B.G_load('key')`);
 fixtures.forms.push({data:{lang:'en',diff:value,chron:'0',gold:'999',reset:'yes'},settings:result.settings,gold:result.gold});
}
// Ship only keys reachable from existing public data and this scoped native UI.
// The source pack also contains excluded host/AI/sexual screens; do not bundle it wholesale.
const reachable=new Set(),walk=v=>{if(typeof v==='string')reachable.add(v);else if(v&&typeof v==='object')Object.values(v).forEach(walk);};
walk(data.difficulties);
for(const f of fs.readdirSync(root+'/project/data'))if(f.endsWith('.json')&&f!=='localization-r22.json')walk(JSON.parse(fs.readFileSync(root+'/project/data/'+f,'utf8')));
const targets=['town_screen_r21.gd','create_screen.gd','persona_sortie_screen.gd','panel_screen_r22.gd','codex_screen_r22.gd','status_screen_r22.gd','inventory_screen_r22.gd','journal_screen_r22.gd','settings_screen_r22.gd'];
for(const f of targets)for(const m of fs.readFileSync(root+'/project/ui/'+f,'utf8').matchAll(/"((?:[^"\\]|\\.)*)"/g)){
 try{reachable.add(JSON.parse('"'+m[1]+'"'));}catch{}
}
for(const f of ['persona_research_r21.gd','panels_state_r22.gd','panel_gear_r22.gd','affection_r22.gd'])for(const m of fs.readFileSync(root+'/project/game/'+f,'utf8').matchAll(/"((?:[^"\\]|\\.)*)"/g)){
 try{reachable.add(JSON.parse('"'+m[1]+'"'));}catch{}
}
for(const row of fixtures.u)reachable.add(row.src);
// Native labels join source-backed fields with these separators.
for(const value of [...reachable])for(const part of value.split(/\n| · /))reachable.add(part);
const skeleton=s=>s.replace(/\{[A-Za-z0-9_]+(?::[^{}]*)?\}|%[-+0-9.]*[dsf]/g,'#');
const shapes=new Set([...reachable].map(skeleton));
data.ui=Object.fromEntries(Object.entries(ui).filter(([k])=>reachable.has(k)||shapes.has(skeleton(k))));
data.words=Object.fromEntries(Object.entries(words).filter(([k])=>reachable.has(k)));
for(const sc of persona.scenarios)for(const key of ['text','title','place','teaser'])data.words[sc[key]]=words[sc[key]];
fs.writeFileSync(root+'/project/data/localization-r22.json',JSON.stringify(data,null,2)+'\n');
fs.writeFileSync(folder+'/oracle.json',JSON.stringify(fixtures)+'\n');
fs.writeFileSync(folder+'/provenance.json',JSON.stringify({files,contracts:['harness_i18n.mjs: B.U/B.T/language/josa','harness_settings_form.mjs: partial/invalid values','harness_panels.mjs: DIFF_MUL/reset confirmation'],counts:Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])),shipping:{ui_keys:Object.keys(data.ui).length,word_keys:Object.keys(data.words).length,filter:'Public existing data / native target literals and format skeletons. Full excluded source screen dictionaries are not shipped.'}},null,2));
console.log(Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])));sim.close?.();
