"""Independent image-space comparisons. Large residuals stay visible/reported."""
from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image,ImageChops,ImageEnhance
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';C=O/'compare';C.mkdir(exist_ok=True)
pairs={'town':'00-town-approved-direction-0','party':'01-companions-0','member':'01-companions-1','skills':'01-companions-2'}
rows=[];summary={}
def bounds(a,kind,roi):
    mask=np.max(a,axis=2)<90 if kind=='ink' else (a[:,:,0]>160)&(a[:,:,1]<110)&(a[:,:,2]<85)
    x,y,w,h=roi;yy,xx=np.where(mask[y:y+h,x:x+w])
    return [int(xx.min()+x),int(yy.min()+y),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)] if len(xx) else None
reasons={
 'logo':'동일 r19 글꼴 사용. 생성 시안의 라틴 활자 형태·기울기와 실제 폰트의 내부 메트릭 차이.',
 'location':'r19 표시 글꼴의 폭·획 높이가 생성 한글과 다름.',
 'party':'원본 얼굴·옷·비율 보존. 생성 시안의 얼굴과 크롭을 복제하지 않음.',
 'depart':'래스터 시안 CTA 픽셀 영역을 직접 사용.',
 'navigation':'기존 벡터 아이콘 사용. 시안의 솔리드 아이콘·활자 크기와 다름.',
 'navigation_rule':'래스터 검출 기준선에 고정.',
 'back_title':'44px 뒤로 터치 영역. 원본 시안의 작은 화살표와 글꼴 메트릭 차이.',
 'filter':'전체/보유 필터 실제 버튼과 원본 보유 인원 사용.',
 'name':'원본 폰트. 겹친 배경까지 포함하는 참조 ROI는 글자만의 정밀 경계로 해석하지 않음.',
 'identity':'원본 데이터·글꼴. 참조 ROI에 겹친 초상도 함께 검출됨.',
 'tabs':'작동하는 탭 버튼과 포커스. 시안과 선택면·밑줄 높이 다름.',
 'hpmp':'원본 능력치·필터. 막대 기준과 글자 간격 다름.',
 'stats':'출신 시너지 반영 원본 실제 능력치(방어17.68) 표시. 시안17로 바꾸지 않음.',
 'skill_title':'원본 기술 이름·표시 폰트 유지.',
 'preview':'실제 연출 버튼. 테마 최소 높이·원본 표시 폰트 차이.'}
sheet=Image.new('RGB',(1560,1688))
for index,(mode,key) in enumerate(pairs.items()):
    ref=Image.open(O/'panels'/f'{key}.png').convert('RGB');got=Image.open(O/'render'/f'{mode}-390.png').convert('RGB')
    together=Image.new('RGB',(780,844));together.paste(ref,(0,0));together.paste(got,(390,0));together.save(C/f'{mode}-side-by-side.png')
    delta=ImageChops.difference(ref,got);delta.save(C/f'{mode}-difference.png')
    a=np.array(ref).astype(float);b=np.array(got).astype(float);d=abs(a-b)
    summary[mode]={'mean_absolute_rgb_error_0_255':round(float(d.mean()),3),'pixels_max_channel_error_gt30_percent':round(float(np.mean(d.max(axis=2)>30)*100),3),'status':'visual differences remain; not an acceptance score'}
    m=json.loads((O/'measure'/f'{key}.json').read_text(encoding='utf-8'))
    for name,spec in m['elements'].items():
        actual=bounds(b,spec['mask'],spec['search_roi']);expected=spec['pixel_bounds']
        error=[y-x for x,y in zip(expected,actual)] if actual and expected else None
        maxerr=max(map(abs,error)) if error else None
        rows.append({'screen':mode,'element':name,'reference_xywh':expected,'render_xywh':actual,'delta_xywh':error,'max_abs_error_px':maxerr,'within_2px':maxerr is not None and maxerr<=2,'reason':reasons[name]})
    sheet.paste(ref,(390*index,0));sheet.paste(got,(390*index,844))
sheet.save(C/'first-four-reference-above-render-below.png')
result={'target_px':2,'elements':rows,'image_residuals':summary,'within_2px':sum(r['within_2px'] for r in rows),'elements_measured':len(rows)}
(C/'comparison.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# 픽셀 대조 결과','', '상단/왼쪽은 시안, 하단/오른쪽은 실제 렌더. ROI의 색 마스크 경계 비교이며 글자 베이스라인 측정은 아니다. 겹친 초상·그림도 해당 마스크에 포함된다. **≤2px 목표를 전체 달성하지 못했다.**','', '|화면|요소|시안 x/y/w/h|렌더 x/y/w/h|최대 오차 px|≤2px|차이 이유|','|---|---|---|---|---:|---|---|']
for r in rows:lines.append('|'+ '|'.join(str(r[k]) for k in ['screen','element','reference_xywh','render_xywh','max_abs_error_px','within_2px','reason'])+'|')
lines+=['',f"≤2px: {result['within_2px']} / {len(rows)}. 미구현 화면 24개는 대조 완료로 계산하지 않는다."]
(C/'comparison.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='elements'},ensure_ascii=False,indent=2))
