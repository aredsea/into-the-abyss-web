"""Content/name/asset and bundle audit, with no Git operations."""
from pathlib import Path
import hashlib,json,subprocess,re
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round13'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
base=read(O/'baseline.json')
changed=[p for p,h in base.items() if not (R/p).exists() or sha(R/p)!=h]
protected={p:h for p,h in base.items() if p.startswith(('project/game/','project/data/','project/assets/','project/ui/battle'))}
broken=[p for p,h in protected.items() if not (R/p).exists() or sha(R/p)!=h]
assets=read(R/'ASSET-HASHES.json')
asset_changes=[a['path'] for a in assets if sha(R/a['path'])!=a['sha256']]
source=Path('C:/Clauede Code/dungeon-bot/design/stats.json')
names={c['id']:c['name'] for c in read(source)['companions']}
dialogues=[read(p) for p in (R/'project/data/dialogue-r21').glob('*.json')]
name_errors=[d['character_id'] for d in dialogues if names.get(d['character_id'])!=d['name']]
bot=Path('C:/Clauede Code/dungeon-bot/bot/src/05-gen.lua').read_text(encoding='utf-8')
source_ui=json.loads(re.search(r'B.UI_RAW = \{ en = \[====\[(.*?)\]====\]',bot,re.S)[1])
buttons={k:source_ui[k] for k in ['계속한다','취소','아랫마을 여관']}
ui_source=(R/'project/ui/town_screen_r21.gd').read_text(encoding='utf-8')
button_errors=[k for k,v in buttons.items() if '"'+v+'"' not in ui_source]
known=read(R/'server/abyss-save/src/known.json')
scenes={s['id']:{'who':d['character_id'],'choices':[c['id'] for c in s['choices']]} for d in dialogues for s in d['inn']}
transitions={t['id']:{'who':d['character_id'],'from':t['from'],'to':t['to'],'direction':t['direction']} for d in dialogues for t in d['transitions']}
script="import fs from 'node:fs';import {bundle} from './server/abyss-save/build.mjs';console.log(fs.readFileSync('server/abyss-save/dist/worker.mjs','utf8')===bundle());"
bundle=subprocess.run(['node','--input-type=module','-e',script],cwd=R,stdout=subprocess.PIPE,check=True).stdout.strip()==b'true'
v=read(R/'docs/version.json')
out={'protected_count':len(protected),'protected_changes':broken,'assets_count':len(assets),'asset_changes':asset_changes,'dialogue_files':len(dialogues),'dialogue_changes':[p for p in changed if p.startswith('project/data/dialogue-r21/')],'source_names_checked':len(names),'name_errors':name_errors,'source_stats_sha256':sha(source),'known_scenes':len(known['dialogueScenes']),'known_transitions':len(known['dialogueTransitions']),'catalogue_scenes_exact':scenes==known['dialogueScenes'],'catalogue_transitions_exact':transitions==known['dialogueTransitions'],'worker_matches_source':bundle,'changed_files':changed,'ui_build':v['ui_build'],'pck_bytes':(R/'docs/index.pck').stat().st_size,'pck_sha256':sha(R/'docs/index.pck'),'version_matches_pack':v['pck_sha256']==sha(R/'docs/index.pck'),'owner_jpg_bytes':(R/'verification/town-r21/owner-zoom-13.jpg').stat().st_size}
out.update(source_english_buttons=buttons,button_translation_errors=button_errors)
(O/'audit.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(out,ensure_ascii=False,indent=2))
assert not (broken or asset_changes or name_errors or button_errors)
assert out['dialogue_files']==30 and scenes==known['dialogueScenes'] and transitions==known['dialogueTransitions'] and bundle and out['version_matches_pack']
assert out['owner_jpg_bytes']<=300000
