"""Derive final editorial counts and examples from before/current data."""
from polish4 import *
sys.stdout.reconfigure(encoding='utf-8')
base=json.loads(BASE.read_text(encoding='utf-8'))
old=json.loads((OUT/'baseline.json').read_text(encoding='utf-8'))
counts={}; final=[]; source_unchanged=[]
for cid,english in base.items():
 path,d=load(cid)
 assert d['en']['speech']==english['speech'],cid
 assert d['en'].keys()==english.keys(),cid
 assert d['en']['display'].keys()==english['display'].keys(),cid
 raw=path.read_bytes();marker=b',\n  "en": '
 original=raw[:raw.rfind(marker)]+b'\n}\n'
 assert hashlib.sha256(original).hexdigest()==old['files'][path.name]['sha256'],cid
 source_unchanged.append(cid)
 kos={p:k for p,k,_ in display_fields(d)}
 for key,text in d['en']['display'].items():
  before=english['display'][key]
  if before!=text:final.append(dict(id=cid,path=key,korean=kos[key],before=before,after=text))
 counts[cid]=sum(r['id']==cid for r in final)
protected_changes=[]
for rel,digest in old['protected'].items():
 p=ROOT/rel
 if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest:protected_changes.append(rel)
assets=json.loads((ROOT/'ASSET-HASHES.json').read_text(encoding='utf-8'))
asset_changes=[r['path'] for r in assets if hashlib.sha256((ROOT/r['path']).read_bytes()).hexdigest()!=r['sha256']]
assert not protected_changes,protected_changes
assert not asset_changes,asset_changes
review=json.loads((OUT/'polish-review-items.json').read_text(encoding='utf-8'))
for item in review:
 _,d=load(item['id']);item['after']=d['en']['display'][item['path']]
 assert item['after']!=base[item['id']]['display'][item['path']],item
(OUT/'polish-review-items.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'polish-edits-final.json').write_text(json.dumps(final,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
protection=dict(korean_original_bytes_exact=len(source_unchanged),english_speech_and_keys_unchanged=True,protected_files=len(old['protected']),protected_changes=protected_changes,additional_test_helper_changed='project/tests/ui_scroll_r24.gd',original_assets=len(assets),asset_changes=asset_changes)
(OUT/'polish-protection.json').write_text(json.dumps(protection,indent=2)+'\n',encoding='utf-8')
summary=dict(characters=30,fields_read=14216,changed_fields=len(final),unchanged_fields=14216-len(final),changed_by_character=counts,review_items_listed=len(review),review_items_revised=len(review),review_severity={s:sum(r['severity']==s for r in review) for s in ['틀림','어색','권함']},requested_review_count=67,unlisted_review_count=67-len(review),source_protection=protection)
(OUT/'polish-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def esc(s):return s.replace('|','\\|').replace('\n','<br>')
lines=['# EN-R24 4차 영어 대사 다듬기 — 변경 대조', '',
 f'30명 전체 14,216개 영어 표시 필드를 파일 순서대로 읽었다. 실제 달라진 필드는 **{len(final):,}개**다. 같은 필드를 두 번 다듬어도 한 번만 센다. 의심되는 뜻·지시 대상·시제는 한국어 원문과 주변 장면을 함께 확인했다. 짧은 말투의 의도적인 단답·조각 문장은 유지했다.', '',
 '독립 검수 보고서에는 지시서가 요약한 67건과 달리 **62건(틀림 11·어색 40·권함 11)**이 실제 열거되어 있다. 열거된 62건은 전부 수정했다. 나머지 5건은 경로·내용이 보고서에 없어 별도 지적으로 집계하지 않았다. 표본 밖에서도 전 인물의 공통 패턴을 점검했다.', '',
 '| 인물 | 전체 표시 필드 | 바뀐 필드 |', '| --- | ---: | ---: |']
for cid,n in counts.items():lines.append(f'| {cid} | {len(base[cid]["display"])} | {n} |')
lines += ['', '## 문맥에 따라 검수 제안을 조정한 곳', '',
 '- 아델린의 강요하는 선택지는 부정적인 선택지 의미를 유지했다. 영어를 자연스럽게 하되 친절한 권유로 바꾸지 않았다.',
 '- 바르구트는 기존 여성 인물 지시를 유지했다. 에르데네의 `ally_down` 문구는 쓰러진 동료를 가리키므로 `their side`로 다듬었다.',
 '- 토베 `inn/19/lines/2`는 앞의 찬 손끝·잔·바람 문맥에 따라 손이 따뜻해지는 뜻을 살렸다. 긴장 해소로 바꾸지 않았다.',
 '- 할드리크 `inn/23/situation`은 이어지는 계곡 이름·서약 문맥에 맞춰 보증으로 건 이름 전체를 적는 것으로 옮겼다.',
 '- 우르다 `inn/19/choices/0/response/0`는 할드리크에게 도움받았던 밤에 대한 감사로 풀었다.',
 '- 마르셀린 `inn/27/choices/0/response/0`의 원문에는 미래인 `내일`과 과거형 `계셨는지`가 함께 있다. 한국어는 그대로 두고, 영어는 안부를 묻고 다음 날도 평안하길 바라는 문맥으로 조정했다.', '',
 '## 인물별 대표 전후 예시 5개', '', '전체 변경 경로와 전후 문구는 [polish-edits-final.json](polish-edits-final.json), 검수 62건의 처리 내역은 [polish-review-items.json](polish-review-items.json)에 있다.', '']
for cid in counts:
 rows=[r for r in final if r['id']==cid]
 priorities=[r['path'] for r in review if r['id']==cid]
 chosen=sorted(rows,key=lambda r:(r['path'] not in priorities,rows.index(r)))[:5]
 assert len(chosen)==5,cid
 lines += [f'### {cid} — {counts[cid]}개', '', '| 필드 | 한국어 원문 | 전 | 후 |', '| --- | --- | --- | --- |']
 for r in chosen:lines.append('| '+ ' | '.join(esc(r[k]) for k in ['path','korean','before','after'])+' |')
 lines.append('')
(OUT/'polish-diff.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps(dict(changed_fields=len(final),review_items=len(review),protection=protection),ensure_ascii=False))
