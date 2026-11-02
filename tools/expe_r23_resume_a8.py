"""Continue a timed-out strict A8 audit after a proven zero-gap checkpoint.

The original audit prints its checkpoint only AFTER checking every trace field,
trace length and final result. At progress N it has even compared row N+1; we
conservatively retain just the first N rows, and rerun the whole suffix from N.
Prefix per-battle vectors are not reconstructed: the preserved native log is
their aggregate evidence. The suffix preserves its actual per-battle vectors.
"""
from pathlib import Path
import subprocess,sys,json,re,hashlib,time
root=Path(__file__).resolve().parents[1];out=root/'verification/parity-r23'
logfile=out/'combat_a8_audit.log';log=logfile.read_text(encoding='utf-8')
assert 'SCRIPT ERROR:' not in log
assert not any(s.startswith('ERROR:') and 'root certificate store' not in s for s in log.splitlines())
points=[tuple(map(int,m)) for m in re.findall(r'A8 progress (\d+) / (\d+) gaps (\d+)',log)]
assert points and all(gaps==0 for _,_,gaps in points)
offset,total,_=points[-1];assert 0<offset<total
(out/'a8-prefix.log').write_bytes(log.encode('utf-8'))
fixture=root/'verification/data-r21/a8-oracle.json'
assert fixture.stat().st_mtime<=logfile.stat().st_ctime,'Input must not change while the prefix is running'
input_bytes=fixture.read_bytes();oracle=json.loads(input_bytes);rows=oracle['battles']+oracle['raid_battles'];assert len(rows)==total
source=root/'project/tests/combat_a8_audit.gd';text=source.read_text(encoding='utf-8')
assert source.stat().st_mtime<=logfile.stat().st_ctime
assert 'if first.is_empty(): equal_battles+=1' in text
assert 'reports.size()-equal_battles+1' in text
assert 'if i>=b.trace.size() or i>=row.trace.size()' in text
assert 'final_result' in text
tail=text.replace('var rows=oracle.battles+oracle.raid_battles',f'var rows=(oracle.battles+oracle.raid_battles).slice({offset})')
tail=tail.replace('res://../verification/data-r21/a8-audit.json','res://../verification/parity-r23/a8-tail.json')
tail=tail.replace('"A8 persona parity "','"A8 remaining parity "')
target=root/'project/tests/combat_a8_r23_tail.gd';target.write_text(tail,encoding='utf-8')
actual_log=out/'a8-tail.log';started=time.monotonic()
with actual_log.open('wb') as f:
    p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--script','res://tests/combat_a8_r23_tail.gd'],cwd=root,stdout=f,stderr=subprocess.STDOUT,timeout=600)
assert p.returncode==0,'Suffix native audit failed'
suffix_log=actual_log.read_text(encoding='utf-8')
assert 'SCRIPT ERROR:' not in suffix_log
assert not any(s.startswith('ERROR:') and 'root certificate store' not in s for s in suffix_log.splitlines())
suffix=json.loads((out/'a8-tail.json').read_text(encoding='utf-8'))
assert fixture.read_bytes()==input_bytes
assert suffix['battles']==total-offset and suffix['equal_battles']==suffix['battles']
assert suffix['source_actions']==suffix['actual_actions']==suffix['matched_actions']
prefix_actions=sum(len(r['trace']) for r in rows[:offset])
result={'battles':total,'equal_battles':offset+suffix['equal_battles'],'source_actions':prefix_actions+suffix['source_actions'],'actual_actions':prefix_actions+suffix['actual_actions'],'matched_actions':prefix_actions+suffix['matched_actions'],
 'prefix':{'range':[0,offset],'battles':offset,'matched_actions':prefix_actions,'proof':'Strict zero-gap checkpoint after per-battle trace-field, length and outcome checks; no fabricated prefix vectors. Progress N has compared N+1 rows, but only N are counted.','log':'verification/parity-r23/a8-prefix.log','log_sha256':hashlib.sha256(log.encode('utf-8')).hexdigest()},
 'suffix':{'range':[offset,total],'battles':suffix['battles'],'matched_actions':suffix['matched_actions'],'native_report':'verification/parity-r23/a8-tail.json','log':'verification/parity-r23/a8-tail.log','exit':p.returncode,'seconds':round(time.monotonic()-started,2)},
 'fixture_sha256':hashlib.sha256(input_bytes).hexdigest(),'comparison_script_sha256':hashlib.sha256(text.encode('utf-8')).hexdigest(),'tail_script_sha256':hashlib.sha256(tail.encode('utf-8')).hexdigest(),
 'changes_to_comparison':'Only row slice, output report path and final print label; same comparison code and fixtures.'}
assert result['source_actions']==result['actual_actions']==result['matched_actions']==sum(len(r['trace']) for r in rows)
(out/'a8-composed.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:result[k] for k in ['battles','equal_battles','source_actions','actual_actions','matched_actions']}),flush=True)
