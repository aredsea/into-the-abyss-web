"""Read loose historical objects directly, without invoking git or changing its state."""
from pathlib import Path
import zlib, hashlib, json
R=Path(__file__).resolve().parents[1]
G=Path((R/'.git').read_text().strip().split(': ',1)[1]).parent.parent
def obj(sha):
 raw=zlib.decompress((G/'objects'/sha[:2]/sha[2:]).read_bytes())
 assert hashlib.sha1(raw).hexdigest()==sha
 return raw.split(b'\0',1)[1]
commit=next((G/'objects/72').glob('bf1b2*')); sha='72'+commit.name
tree=obj(sha).splitlines()[0].decode().split()[1]
for part in ['project','game','battle_v3.gd']:
 raw=obj(tree); pos=0
 while pos<len(raw):
  end=raw.index(b'\0',pos); name=raw[pos:end].split(b' ',1)[1].decode(); ident=raw[end+1:end+21].hex(); pos=end+21
  if name==part: tree=ident; break
 else: raise ValueError(part)
source=obj(tree).decode('utf-8')
start=source.index('func _enemy_hit('); end=source.index('\nfunc effects_text',start)
body=source[start:end]
(R/'project/tests/combat_a6_legacy_fixture.gd').write_text('extends "res://game/battle_v3.gd"\n# Read-only baseline '+sha+' blob '+tree+'\n'+body,encoding='utf-8')
(R/'verification/data-r21/a6-legacy-source.json').write_text(json.dumps({'commit':sha,'blob':tree,'sha256':hashlib.sha256(source.encode()).hexdigest()},indent=2),encoding='utf-8')
paths=[p for base in ['project','tools','docs'] for p in (R/base).rglob('*') if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts]
baseline=R/'verification/data-r21/a6-before-hashes.json'
if not baseline.exists(): baseline.write_text(json.dumps({p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf-8')
print(sha,tree,len(paths))
