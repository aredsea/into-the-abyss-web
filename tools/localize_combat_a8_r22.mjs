// Add only exact canonical keys reached by combat; keep all existing P8 keys.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const source='C:/Clauede Code/dungeon-bot';
const files=['05-gen.lua','01-game.lua','10-data.lua'];
const {mkSim}=await import(pathToFileURL(source+'/bot/lua_sim.mjs'));
const {L}=await mkSim({policy:false,extra:files.map(f=>fs.readFileSync(source+'/bot/src/'+f,'utf8')).join('\n')});
const pack=await L('B.EN=nil;B.UI={};return {words=B.en_dict(),ui=B.ui_pack("en")}');
const words={},ui=JSON.parse(fs.readFileSync(source+'/design/i18n/ui/en.json','utf8'));
for(const f of fs.readdirSync(source+'/design/i18n/en').sort())if(f!=='intimacy.json')Object.assign(words,JSON.parse(fs.readFileSync(source+'/design/i18n/en/'+f,'utf8')));
Object.assign(words,JSON.parse(fs.readFileSync(source+'/design/i18n/names.json','utf8')),pack.words);Object.assign(ui,pack.ui);
const target=['project/ui/battle_screen.gd','project/game/battle_state.gd','project/game/battle_v3.gd','project/game/combat_display_r22.gd','project/ui/combat_presentation.gd','project/ui/signature_sequence.gd'];
const reachable=new Set(),literals=[];
for(const file of target){
 const text=fs.readFileSync(file,'utf8');
 for(const match of text.matchAll(/"((?:[^"\\]|\\.)*)"/g)){
  try{const value=JSON.parse('"'+match[1]+'"');reachable.add(value);if(/[가-힣]/.test(value))literals.push({file,line:text.slice(0,match.index).split('\n').length,text:value});}catch{}
 }
}
const walk=x=>{if(typeof x==='string')reachable.add(x);else if(x&&typeof x==='object')Object.values(x).forEach(walk);};
for(const f of ['world.json','battle_scene.json','enemies-r21.json'])if(fs.existsSync('project/data/'+f))walk(JSON.parse(fs.readFileSync('project/data/'+f,'utf8')));
for(const value of [...reachable])for(const part of value.split(/\n| · /))reachable.add(part);
const skeleton=s=>s.replace(/\{[A-Za-z0-9_]+(?::[^{}]*)?\}|%[-+0-9.]*[dsf]/g,'#');
const shapes=new Set([...reachable].map(skeleton));
const data=JSON.parse(fs.readFileSync('project/data/localization-r22.json','utf8'));
const added={ui:[],words:[]};
for(const [kind,dict] of [['ui',ui],['words',words]])for(const [k,v] of Object.entries(dict)){
 if(reachable.has(k)||(kind==='ui'&&shapes.has(skeleton(k)))){if(!Object.hasOwn(data[kind],k))added[kind].push(k);data[kind][k]=v;}
}
// The combined skill name and description are supplied by *_en fields / 29 Lua.
fs.writeFileSync('project/data/localization-r22.json',JSON.stringify(data,null,2)+'\n');
for(const row of literals)row.exact=Object.hasOwn(data.ui,row.text)?'ui':Object.hasOwn(data.words,row.text)?'words':null;
const town=JSON.parse(fs.readFileSync('../r21-d-town/verification/settings-r22/untranslated.json','utf8'));
const candidates=town.battle_deferred;
for(const row of candidates){
 row.canonical_exact=ui[row.text]||words[row.text]||null;
 row.canonical_templates=Object.keys(ui).filter(k=>skeleton(k)===skeleton(row.text));
}
fs.writeFileSync('verification/data-r21/a8-localization.json',JSON.stringify({added,counts:{ui:Object.keys(data.ui).length,words:Object.keys(data.words).length},literals,town_candidates:candidates,provenance:files.map(f=>({file:f,sha256:crypto.createHash('sha256').update(fs.readFileSync(source+'/bot/src/'+f)).digest('hex')}))},null,2)+'\n');
console.log(JSON.stringify({added:{ui:added.ui.length,words:added.words.length},literal_candidates:literals.length,exact:literals.filter(x=>x.exact).length,town:candidates.length}));
process.exit(0);
