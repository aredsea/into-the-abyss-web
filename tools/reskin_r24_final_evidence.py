from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1];O=R/'verification/reskin-r24'
def read(p):
 raw=p.read_bytes();return json.loads(raw.decode('utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8-sig'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
result=read(R/'verification/town-r21/round13/ui-dialogue-results.json')
native=read(O/'resumed-observer.log')
assert native['exit']==0 and native['passed'] and not native['errors']
assert not result['failures'] and result['overflow']==0
ids=[c['id'] for c in read(R/'project/data/world.json')['companions']]
expected={f'{cid}:{lang}:{width}' for cid in ids for lang in ['ko','en'] for width in [360,430]}
assert set(result['completed_prefixes'])==expected and len(expected)==120
native['note']='Full unchanged dialogue assertions covered in completed prefix blocks from the initial native run plus its continuation; 120/120 companion/language/viewport blocks. Initial wrapper timed out; completed-block proof and native continuation exit 0 are retained.'
native['completed_prefixes']=120;native['resumed_prefixes']=len(result['resumed_prefixes'])
write(O/'late-results.json',[native])
write(O/'dialogue-continuation.json',{'completed':120,'continued':120-len(result['resumed_prefixes']),'previously_completed':len(result['resumed_prefixes']),'new_checks':result['checks'],'assertion_failures':result['failures'],'overflow':result['overflow'],'actual_continuation_exit':native['exit'],'source_log':{'file':'verification/reskin-r24/dialogue-partial.log','sha256':hashlib.sha256((O/'dialogue-partial.log').read_bytes()).hexdigest()},'continuation_log':'verification/reskin-r24/dialogue-resumed.log','native_exit_observation':'verification/reskin-r24/resumed-observer.log','completed_prefixes':sorted(expected)})
print('Dialogue blocks 120/120, native continuation exit 0, failures 0')
