"""Certify a single fixture prerequisite correction after a full product-code run."""
from pathlib import Path
import hashlib,json,shutil,time
R=Path(__file__).resolve().parents[1];S=R/'verification/parity-r23/suite-round7-final-v2'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert all(c==0 for c in read(S/'group-exits.json')),'Suite must finish first'
assert read(S/'local-server-result.json')['exit']==0
old=read(S/'final-code-lock.json');tested=read(S/'tested-code.json');assert tested==old['sha256']
current={name:sha(R/name) for name in tested}
changed=[name for name in tested if tested[name]!=current[name]]
fixture='project/tests/enemy_regression_r21_test.gd';assert changed==[fixture],changed
before=S/'before-fixture-correction/enemy_regression_r21_test.gd'
assert sha(before)==tested[fixture]
insertion="\t# Direct phase_check has the same begin_ev prerequisite as the Lua oracle.\n\tb.combat_events.begin_record(b)\n"
assert (R/fixture).read_text(encoding='utf-8')==before.read_text(encoding='utf-8').replace('\tb.current_id=b.data.enemies[0].id\n','\tb.current_id=b.data.enemies[0].id\n'+insertion,1)
row=read(S/'rows/enemy_regression_r21_test.json');assert row['passed'] and not row['errors']
assert (S/'rows/enemy_regression_r21_test.json').stat().st_mtime-row['seconds']>(R/fixture).stat().st_mtime
assert all(sha(R/name)==h for name,h in old['inputs'].items())
rows=[read(p) for p in (S/'rows').glob('*.json')];assert len(rows)==118 and all(r['passed'] for r in rows)
audit={'product_code_unchanged':True,'only_changed_test':fixture,'before_sha256':tested[fixture],'after_sha256':current[fixture],'change':'Add the original begin_ev prerequisite to a direct phase_check test fixture; no expected values changed.','rerun':row,'unchanged_other_files':len(current)-1,'time':time.time()}
shutil.copyfile(S/'final-code-lock.json',S/'initial-code-lock.json');shutil.copyfile(S/'tested-code.json',S/'initial-tested-code.json')
write(S/'fixture-correction-audit.json',audit)
write(S/'final-code-lock.json',{**old,'sha256':current,'fixture_correction':audit})
write(S/'tested-code.json',current)
write(S/'final-code-verification.json',{'unchanged':True,'product_code_unchanged':True,'files':len(current),'inputs':len(old['inputs']),'test_fixture_only_recheck':audit})
print(json.dumps({'passed':True,'groups':len(rows),'product_code_unchanged':True,'fixture_rechecked':fixture}))
