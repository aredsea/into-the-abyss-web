from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
opened=['smithy-result-card-390x844.png','smithy-result-card-360x780.png','recruit-recent-card-360x780.png','guild-390x844.png']
result={'opened':[{'file':'verification/parity-r23/gear-render-round4/'+f,'sha256':hashlib.sha256((O/'gear-render-round4'/f).read_bytes()).hexdigest()} for f in opened],'notes':['실제 PNG를 직접 열어 제련/가공 탭, 완료 회복 버튼, 가공 결과 장비 이름·등급·레벨·기본 효과, 길드 전체 의뢰 제목·별·난이도·보상, 최근 영입 초상·풀네임·종족·국가·직업을 확인했다.','360×780에서도 결과 카드와 주요 버튼이 프레임 안에 보인다. 큰 인물 영역 때문에 본문과 세부 정보는 스크롤로 확인한다.','헤더·본문·버튼의 겹침/문자 잘림은 연 화면에서 발견하지 못했다. 모든 1,030종 카드의 픽셀 이미지 또는 회귀 이미지를 전부 열어 본 것은 아니다.','최근 영입 스크롤 probe는 이름 축약과 풀네임을 구분하도록 수정했다. 이 probe는 표시 위치 확인용이며 source parity 수치에 더하지 않았다.'],'probe_results':json.loads((O/'gear-round4-visual-probe-results.json').read_text(encoding='utf-8')),'design_detector':{'issues':[],'scope':'facilities_screen_r22.gd; final subsequent change is one source_u/source_t translation expression only.'}}
(O/'gear-round4-visual-review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
p=O/'gear-round4-provenance.json';d=json.loads(p.read_text(encoding='utf-8'));d['observer_exports']=['recruit_cell','recruit_roster','recruit_result','tab_board','tab_forge','tab_process'];p.write_text(json.dumps(d,indent=2),encoding='utf-8')
print('Opened and recorded',len(opened),'images; layout probe checks',result['probe_results']['checks'])
