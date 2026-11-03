from pathlib import Path
import json,importlib.util
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
spec=importlib.util.spec_from_file_location('expe5',R/'tools/expe_r23_pass5_project.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
d=json.loads((O/'expe-pass6-oracle-raw.json').read_text(encoding='utf8'))
locale=d.pop('locale')
(R/'project/data/expe-ui-pass6-r23.json').write_text(json.dumps(locale,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
for r in d['view']+d['face']:r['visible']=m.Visible(r['html']).result()
(O/'expe-pass6-oracle.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print({k:len(v) for k,v in d.items()})
