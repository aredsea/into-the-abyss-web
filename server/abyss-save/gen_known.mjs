import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const here=path.dirname(fileURLToPath(import.meta.url)), root=path.resolve(here,'../..');
const names=['world','gear','gear_effects','persona-r22','persona_skill','dungeons-r21','town-r21-rules'];
const data=Object.fromEntries(names.map(n=>[n,JSON.parse(fs.readFileSync(path.join(root,'project/data',n+'.json'),'utf8'))]));
const fixtures=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json'),'utf8'));
const known={world:data.world,gear:data.gear,gearRules:data.gear_effects,persona:data['persona-r22'],research:data.persona_skill,
 zones:data['dungeons-r21'].zone_order || data['dungeons-r21'].zones.filter(z=>z.kind==='dungeon').map(z=>z.id),
 rifts:data['dungeons-r21'].rifts, questDifficulty:data['dungeons-r21'].quest_difficulty, rankLevels:data['dungeons-r21'].zones.filter(z=>z.kind==='dungeon'&&z.boss).map(z=>z.lv_lo), rules:data['town-r21-rules'], defaults:fixtures.legacy2,
 provenance:Object.fromEntries(names.map(n=>[n,createHash('sha256').update(fs.readFileSync(path.join(root,'project/data',n+'.json'))).digest('hex')]))};
// Battle snapshot field vocabulary is extracted from the shipped engine, never from a request.
const engine=['battle_state','battle_v3','dungeon_enemy_r21','dungeon_rules_r21','personal_rules_r22','trait_rules_r22','persona_combat_r22','gear_battle_r22'].map(n=>fs.readFileSync(path.join(root,'project/game',n+'.gd'),'utf8')).join('\n');
known.battleKeys=[...new Set([...engine.matchAll(/\.([A-Za-z_]\w*)|["']([A-Za-z_]\w*)["']\s*:/g)].map(m=>m[1]||m[2]))].sort();
known.battleEffects=[...new Set(['windup','persona_regen','pscrit','gear_guard',...[...engine.matchAll(/(?:_effect|effect|fx)\([^,\n]+,["']([a-z_]+)["']|effects\.(?:has|get|erase)\(["']([a-z_]+)["']/g)].map(m=>m[1]||m[2])])].sort();
const dialogue=fs.readdirSync(path.join(root,'project/data/dialogue-r21')).filter(n=>n.endsWith('.json')).map(n=>JSON.parse(fs.readFileSync(path.join(root,'project/data/dialogue-r21',n),'utf8'))).filter(d=>d.character_id);
known.dialogueScenes=Object.fromEntries(dialogue.flatMap(d=>d.inn.map(s=>[s.id,{who:d.character_id,choices:s.choices.map(c=>c.id)}])));
known.dialogueEvents=[...new Set(dialogue.flatMap(d=>d.dungeon.map(s=>s.event)))];
known.dialogueStages=[...new Set(dialogue.flatMap(d=>d.stage_order))];
known.dialogueTransitions=Object.fromEntries(dialogue.flatMap(d=>d.transitions.map(t=>[t.id,{who:d.character_id,from:t.from,to:t.to,direction:t.direction}])));
known.npcs=[...new Set([...fs.readFileSync(path.join(root,'project/game/town_world_r21.gd'),'utf8').matchAll(/npc_like\("([a-z]+)"\)/g)].map(m=>m[1]))];
known.battleIds=[...JSON.parse(fs.readFileSync(path.join(root,'project/data/battle_scene.json'),'utf8')).enemies.map(e=>e.id),...JSON.parse(fs.readFileSync(path.join(root,'project/data/enemies-r21.json'),'utf8')).enemies.map(e=>e.id)];
fs.mkdirSync(path.join(here,'src'),{recursive:true});
fs.writeFileSync(path.join(here,'src/known.json'),JSON.stringify(known)+'\n');
console.log(JSON.stringify({companions:known.world.companions.length,gear:known.gear.items.length,items:known.world.items.length,zones:known.zones.length}));
