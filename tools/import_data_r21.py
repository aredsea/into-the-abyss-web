"""Copy canonical values without modifying the bot; retain source hashes and pointers."""
from pathlib import Path
import hashlib, json, os
ROOT=Path(__file__).resolve().parents[1]
BOT=Path(os.environ.get('R21_BOT',r'C:\Clauede Code\dungeon-bot'))
FILES=['design/enemies.json','design/ENEMIES.md','design/DUNGEON.md','design/EXPEDITION.md','design/stats.json','bot/src/20-state.lua','bot/src/24-stats.lua','bot/src/26-start.lua','bot/src/27-compose.lua','bot/src/31-foes.lua','bot/src/72-guild.lua','bot/src/74-affection.lua','bot/src/76-dungeon.lua','bot/src/77-explore.lua','bot/src/51-raid.lua','bot/src/81-gear.lua']
sources={n:{'sha256':hashlib.sha256((BOT/n).read_bytes()).hexdigest(),'lines':len((BOT/n).read_text(encoding='utf-8-sig').splitlines())} for n in FILES}
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
enemy=read(BOT/'design/enemies.json')
oracle=read(ROOT/'verification/data-r21/lua-oracle.json')
stats=read(BOT/'design/stats.json')['meta']
enemy['source']={'root':str(BOT),'files':sources,'pointer':'design/enemies.json'}
for i,e in enumerate(enemy['enemies']):
 e['art']=f"res://assets/enemies-r21/{e['id']}.png"
 e['source']={'file':'design/enemies.json','pointer':f'/enemies/{i}','sha256':sources['design/enemies.json']['sha256']}
dungeon={'version':1,'source':enemy['source'],'zones':enemy['zones'],'rifts':enemy['rifts'],'zone_order':oracle['constants']['zone_order'],
 'stats':{k:stats[k] for k in ['level_max','curves','enemy_std','stars','formula']},'explore':oracle['constants']['EX'],'item_order':oracle['constants']['item_order'],
 'progression_source':'bot/src/76-dungeon.lua:10-73; bot/src/77-explore.lua:14-76,98-120,199-525',
 'gear_drop':oracle['constants']['gear_drop'],'gear_items':oracle['constants']['gear_items'],'gear_version':oracle['constants']['gear_version'],'affection':oracle['constants']['AFF'],
 'quest_rifts':oracle['constants']['quest_rifts'],'quest_difficulty':oracle['constants']['quest_difficulty']}
for name,d in [('enemies-r21.json',enemy),('dungeons-r21.json',dungeon)]:
 (ROOT/'project/data'/name).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(ROOT/'verification/data-r21/source-inventory.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'enemies':len(enemy['enemies']),'families':len(enemy['families']),'zones':len(enemy['zones']),'playable_zones':len(dungeon['zone_order']),'rifts':len(enemy['rifts'])}))
