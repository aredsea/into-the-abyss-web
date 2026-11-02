import json,re,sys
from pathlib import Path
sys.path.insert(0,'tools')
from dialogue_r21_build import display_fields
IDS=['hildegard','marceline','teiris','naran','haldric','erdene','bianca','saya','gerda','judith','levia','urda']
for cid in (sys.argv[1:] or IDS):
 d=json.loads(Path(f'project/data/dialogue-r21/{cid}.json').read_text(encoding='utf8'))
 print('\n###',cid)
 hits=[]
 for p,t,s in display_fields(d):
  if re.search(r'따로|다르|아니|빈칸|요점|확보|예민|우울|남아|행선|줄|자리|몫|이름|문턱|먼저',t):hits.append((p,t))
 for p,t in hits:
  if p.startswith('inn/') and '/situation' not in p: print(p,t)
 print('D/T flagged')
 for p,t in hits:
  if not p.startswith('inn/') and re.search(r'따로|다르|아니|빈칸|확보|줄|자리|몫|이름|문턱|남아',t):print(p,t)
