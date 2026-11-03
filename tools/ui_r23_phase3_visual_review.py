"""Record only screenshots opened directly through view_image this turn."""
from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parents[1]/'verification/parity-r23/ui-phase3'
files=sorted((P/'render').glob('*.png'))
notes={
 'gear':'원본 반지 아이콘·등급/Lv·기본/무작위/고유 효과와 하단 비교 영역이 보인다. 360/390에서는 아래 비교 행이 스크롤 아래에 있으며, 430에서는 일부 행까지 보인다. 제목/아이콘/설명 겹침은 관찰하지 않았다.',
 'filter':'속성 그룹의 붉은 선택 상태와 화염 필터 선택 뒤 나란 한 명이 보인다. 얼굴/귀 프레이밍은 기존 native 초상 경로이며 전체 초상 등가 판정은 하지 않았다.'}
value={'opened_directly':len(files),'images':[{'path':f.relative_to(P).as_posix(),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'observation':notes['gear' if f.name.startswith('ui-gear') else 'filter']} for f in files],'scope':'360x780, 390x844, 430x932; ko/en; source semantics separately in ui-oracle.json. All 12 current captures opened through view_image.','remaining':['English mode retains Korean fallback in back/bag/nav/class/favorite labels. Some U labels match source fallback; whole B.T/render route is not promoted.','Equipment comparison still shows +0% for absent old effects instead of source -; P2586 remains partial.','No claim that every pre-existing regression screenshot was opened.'],'mechanical_detector':{'command':'impeccable.cmd detect --json project/ui/panel_screen_r22.gd project/ui/codex_screen_r22.gd project/ui/inventory_screen_r22.gd','issues':[]}}
(P/'ui-visual-review.json').write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Recorded direct visual review',len(files))
