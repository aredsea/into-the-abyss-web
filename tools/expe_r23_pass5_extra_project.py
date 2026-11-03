from expe_r23_pass5_project import Visible,O
import json
rows=json.loads((O/'expe-pass5-extra-oracle-raw.json').read_text(encoding='utf-8'))
for row in rows:row['visible']=Visible(row['html']).result()
(O/'expe-pass5-extra-oracle.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'extra_source_cases':len(rows)}))
