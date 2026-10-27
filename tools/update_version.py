"""Run after exporting Web to update the public build identity and SHA-256."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[1]
config=json.loads((root/'project/data/world.json').read_text(encoding='utf-8'))
version={'build':config['build'],'engine':'Godot 4.7.2',
         'pck_sha256':hashlib.sha256((root/'docs/index.pck').read_bytes()).hexdigest(),
         'wasm_sha256':hashlib.sha256((root/'docs/index.wasm').read_bytes()).hexdigest()}
(root/'docs/version.json').write_text(json.dumps(version,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(version))
