"""Record the 27 native captures actually opened with view_image this session."""
from pathlib import Path
import json,hashlib,struct
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23/ui-phase4'
notes={
 'favorites':'속성·출전·호감 문구·막대·HP/MP·도감 버튼이 분리되어 읽힌다. 맨 위 이전 카드 일부는 스크롤로 가려진 부분이며 새 글자 넘침은 관찰하지 않았다.',
 'comparison':'비교표의 없는 값은 -, 실제 0은 수치로 구분한다. 증감·강화·고유 효과가 보이고 360의 긴 영문 행은 줄바꿈된다. 아래 장착/판매는 스크롤로 이어진다.',
 'trait':'나란의 정본 특성 아이콘이 실제로 보이고, 스킬/특성 본문과 나란히 놓인다. 한영 문구와 3개 폭에서 텍스트가 서로 겹치는 모습은 관찰하지 않았다.',
 'reset':'연대기·저장 상태·클라우드 진입·초기화 확인/취소가 보인다. 영어 native 저장/보관 설명도 영어로 표시된다. 확인 버튼은 화면 안에 있고 그 위의 설정은 스크롤로 남아 있다.',
 'dialogue':'Deep bond · Affection 90이 원래 신원 슬롯 안에 들어간다. 첫 프레임의 임시 폭에 의존하지 않는다. 대화 본문은 기존 authored 한글을 보존하며 전면 영문 번역을 주장하지 않는다.'}
images=[]
for p in sorted((O/'render').glob('ui-*.png')):
    group=next(k for k in notes if p.name.startswith('ui-'+k))
    raw=p.read_bytes();width,height=struct.unpack('>II',raw[16:24])
    images.append({'path':p.relative_to(O).as_posix(),'sha256':hashlib.sha256(raw).hexdigest(),'dimensions':[width,height],'opened_directly':True,'observation':notes[group]})
assert len(images)==27
detector=O/'ui-design-detector.json';raw=detector.read_bytes();issues=json.loads(raw.decode('utf-16' if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig'));assert issues==[]
detector.write_text(json.dumps(issues,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
value={'opened_directly':27,'images':images,'method':'Godot native offscreen viewport captures; view_image opened every listed image. Pointer checks synthesize mouse input. No browser Web export or physical touch-device verification.','remaining':['영문 모드에서 일부 공통 메뉴와 원본 fallback/기존 authored 대화는 한글로 남는다. 전역 화면 파일 동결 범위와 별도로 기록했다.','전체 게임·기존 회귀 캡처의 시각 승인이나 전체 144행 등가 완성을 뜻하지 않는다.'],'mechanical_detector':{'targets':6,'issues':issues}}
(O/'ui-visual-review.json').write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Reviewed',len(images),'native captures')
