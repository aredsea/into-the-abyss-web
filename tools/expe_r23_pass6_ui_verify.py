from pathlib import Path
import json,importlib.util
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
spec=importlib.util.spec_from_file_location('expe5',R/'tools/expe_r23_pass5_project.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
rows=json.loads((O/'expe-pass6-ui-source.json').read_text(encoding='utf8'));diffs=[]
for i,r in enumerate(rows):
 source=m.Visible(r['html']).result()
 if source!=r['visible']:diffs.append({'index':i,'kind':r['kind'],'lang':r['lang'],'source':source,'native':r['visible']})
result={'cases':len(rows),'failures':len(diffs),'diffs':diffs}
(O/'expe-pass6-ui-source-results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(json.dumps({'cases':len(rows),'failures':len(diffs)}));raise SystemExit(bool(diffs))
