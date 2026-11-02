"""Derive round-four review, samples, report and manifest from final bytes."""
from collections import Counter
import hashlib
from dialogue_r21_build import ROOT, CANON, IDS, READ_SOURCES, display_fields, read_json, write_json
from dialogue_r21_round4 import NEW_IDS, VOICE, OUT, digest
from dialogue_r21_round2 import TITLES

SAMPLES={'selva':[5,13,27],'ornel':[4,13,24],'zahar':[4,12,27],
 'jorund':[5,14,27],'lavinia':[4,12,24],'tove':[4,13,24],
 'miko':[4,12,24],'adeline':[5,12,25],'colette':[5,12,27]}
MISSING=[
 '셀바: 단골 국밥집 이름·주인 이름·추가 보수액·미래의 귀향 여부는 없음. 케른 출신과 마렌토 체류를 유지하고 새 맹약 조항을 만들지 않았다.',
 '오르넬: 순찰대 동료 개별 이름·벌레 공포의 원인·치료나 극복의 결말은 없음. 강한 궁술과 벌레 공포를 구별하고 호위 이력을 유지했다.',
 '자하르: 광산 번호 사백십칠은 COMPANIONS 정본에 있다. 반란 때 곁에서 다친 사람의 이름·친척 이름·추방 뒤 장례 결과는 없음. 진압 측 징집 뒤 반란에 합류한 순서를 바꾸지 않았다.',
 '요르드: 원로의 개인 이름·추가 계약 전문·가문 포기나 복권 결과는 없음. 가문 이익과 길드 계약이라는 동기는 유지했다. 문구 밖의 작은 약속은 인물 시트의 허용 범위이며 무상 노동 규칙이 아니다.',
 '라비니아: 심사관 이름·허가 심사 질문·배지 해제 효과는 없음. 토르바의 성안 마법 허가 불필요를 유지한다. 배지 착용 금지 규칙을 만들지 않았고 허가를 전부 버리는 결말도 없다.',
 '토베: 출생지·부모·정식 호적·숙박 거절 당일의 추가 사정은 없음. 하르벤 태생으로 확정하지 않았다. 대화의 실내 휴식은 숙박 결제나 일수 변경을 실행하지 않는다.',
 '미코: 부모·고향 계곡·새 약 제조법·회복 보장·약값은 없음. 막사에서 성장해 길드로 온 이력을 사용했다. 병과 약초는 소품이며 약 지급·치료·회복 수치를 실행하지 않는다.',
 '아델린: 집안·고향 세부·게임 내 내기 보상 규칙은 없음. 마르셀린과 혈연이 아니며 994년에 서품된 두 번째 세대다. 시합과 카드 제안은 대화이며 실제 판정·설거지 강제·재화 이동이 없다.',
 '콜레트: 서약보다 사람을 먼저 구한 날의 날짜·장소·구한 사람·이후 징계는 없음. 그 경험은 인물 시트에만 있는 범위로 언급했다. 웃음 때문에 인장 효력이 달라지거나 감시가 없어지는 규칙은 없다.',
 '동료별 고정 유저 호칭은 없음. 새 9명은 유저가 이름+씨로 부르는 편집 규약이며 동료가 유저에게 쓰는 직접 호칭은 생략한다.'
]

def md(path,lines):path.write_bytes(('\n'.join(lines).rstrip()+'\n').encode('utf-8'))

def contact():
    from PIL import Image, ImageDraw
    paths=['verification/ui-r17/base-360.png','verification/ui-r18/base-360.png',
      'verification/ui-r19/base-360.png','verification/ui-r20/base-360.png',
      'verification/ui-r17/motion-r9/bargut-personal-360.png',
      'verification/ui-r18/state-integration/naran-personal-360.png']
    panel=Image.new('RGB',(1080,1416),'#222222');draw=ImageDraw.Draw(panel)
    inventory=[]
    for i,p in enumerate(paths):
        src=ROOT/p
        im=Image.open(src).convert('RGB')
        assert im.width==360,(p,im.size)
        x=(i%3)*360;y=(i//3)*708
        draw.text((x+8,y+5),p.split('/')[1]+' / '+('base' if i<4 else 'bargut-personal' if i==4 else 'naran-personal'),fill='white')
        im.thumbnail((360,680))
        panel.paste(im,(x,y+28))
        inventory.append({'file':p,'sha256':digest(src),'mtime_ns':src.stat().st_mtime_ns})
    target=OUT/'regression-contact4.png';panel.save(target)
    write_json(OUT/'regression-images4.json',inventory)

def main():
    lint=read_json(OUT/'check4.json');selftest=read_json(OUT/'selftest4.json')
    registers=read_json(OUT/'selftest4-registers.json')
    regression=read_json(OUT/'regression4/regression-summary.json')
    assert lint['error_count']==selftest['failures']==registers['failures']==0
    assert regression['runs']==15 and not any(regression[k] for k in ['nonzero_exits','assertion_failures','unclassified_errors'])
    base=read_json(OUT/'baseline4.json')
    changes=[p for p,h in base['workspace'].items() if not (ROOT/p).is_file() or digest(ROOT/p)!=h]
    canon={**base['canon'],**{s['file']:s['sha256'] for s in read_json(OUT/'source-manifest2.json')}}
    canon_changes=[p for p,h in canon.items() if digest(CANON/p)!=h]
    assert not changes and not canon_changes,(changes,canon_changes)
    protected={'workspace_count':len(base['workspace']),'workspace_changes':changes,
      'old_character_count':21,'old_character_changes':[],
      'canonical_source_count':len(canon),'canonical_source_changes':canon_changes,
      'independent_review_files_at_start':[p for p in base['workspace'] if 'kreview' in p],
      'independent_review_file_changes':[]}
    write_json(OUT/'protected4.json',protected)
    source_files=list(dict.fromkeys([*READ_SOURCES,*canon]))
    write_json(OUT/'source-manifest4.json',[{'file':p,'sha256':digest(CANON/p)} for p in source_files])
    corpus={cid:read_json(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in NEW_IDS}
    edits=read_json(OUT/'edits4-applied.json');pairs=Counter(e['character_id'] for e in edits)
    assert all(pairs[cid]>=10 for cid in NEW_IDS)
    metrics=lint['characters']
    keys=['inn_scenes','choices','dungeon_variants','transition_scenes','companion_lines','display_lines','ending_sentences']
    counts={k:sum(metrics[cid][k] for cid in NEW_IDS) for k in keys}
    totals={k:sum(m[k] for m in metrics.values()) for k in keys}
    opening=Counter(len(s['lines']) for d in corpus.values() for s in d['inn'])
    responses=Counter(len(c['response']) for d in corpus.values() for s in d['inn'] for c in s['choices'])
    inventory=[];scenes=[];reasons=[]
    review=['# 4차 자기 편집','',
      'kreview-2.md·kreview-2.json을 집필 전에 읽고 반복 패턴 10가지를 초고부터 피했다. 독립 검수 파일과 기존 21명 데이터는 수정하지 않았다.',
      '아래 전→후는 draft4/와 최종 JSON의 같은 경로를 대조한 실제 적용문이다. 작성자의 자기 편집이며 독립 검수 승인이 아니다.',
      '재독 기준은 정본 공백, 연어, 입말, 비유, 반복, 맞춤법·조사, 주어 생략, 행동 뒤 감정 해설, 말의 부담, 화계다. 자동 검사는 이 중 구조와 반복·어미 일부만 보조한다.','']
    for cid,d in corpus.items():
        review += [f'## {IDS[cid]} · {cid}','',VOICE[cid],f'유저 호칭: {TITLES[cid]}.','',
          '| 경로 | 전 | 후 | 수정 이유 |','|---|---|---|---|']
        for e in edits:
            if e['character_id']==cid:
                review.append(f"| `{e['path']}` | {e['before']} | {e['after']} | {e['reason']} |")
        review+=['',f'실제 수정 {pairs[cid]}쌍. [최종 표본](sample4-{cid}.md).','']
        sample=[f'# {IDS[cid]} · 4차 표본','',VOICE[cid],
          f'유저 호칭: {TITLES[cid]} / 동료의 유저 직접 호칭: 생략.','',
          '최종 JSON에서 추출한 낯섦·유대·운명 각 1장면. 독립 검수는 미실시다.',
          '정본: '+', '.join(f"{s['file']}:{s['line_start']}-{s['line_end']}" for s in d['sources']),'']
        chosen=[d['inn'][i] for i in SAMPLES[cid]]
        assert [s['stage'] for s in chosen]==['낯섦','유대','운명']
        for s in chosen:
            sample += [f"## {s['stage']} · {s['id']}",'',s['situation'],'']+['> '+t for t in s['lines']]
            sample += ['','| 선택 | 반응 | aff | 편집용 이유 |','|---|---|---:|---|']
            for c in s['choices']:
                sample.append(f"| {c['text']} | {' / '.join(c['response'])} | {c['aff']:+d} | {c['reason']} |")
            sample += ['',f"재노출: {s['seen']}",'']
        md(OUT/f'sample4-{cid}.md',sample)
        inventory.extend({'character_id':cid,'path':p,'text':t,'companion':sp,
            'sha256':hashlib.sha256(t.encode('utf-8')).hexdigest()} for p,t,sp in display_fields(d))
        scenes.extend({'character_id':cid,'voice':VOICE[cid],**s} for s in d['inn'])
        reasons.extend({'character_id':cid,'scene':s['id'],'choice':c['id'],'aff':c['aff'],'reason':c['reason']}
            for s in d['inn'] for c in s['choices'])
    md(OUT/'review-4.md',review+['## 정본 공백','']+['- '+s for s in MISSING])
    write_json(OUT/'review-lines4.json',{'method':'작성자 재독을 위한 최종 문구 목록. 자동 의미 판정이나 독립 승인으로 세지 않는다.','records':inventory})
    write_json(OUT/'review-scenes4.json',scenes)
    assert len(reasons)==756 and all(len(r['reason'])>=8 and r['reason'].endswith('.') for r in reasons)
    write_json(OUT/'choice-reasons4.json',reasons)
    maximum=max(metrics[cid]['max_dungeon_chars'] for cid in NEW_IDS)
    max_all=max(metrics[cid]['max_line_chars'] for cid in NEW_IDS)
    report=['# 4차','',
      f"마지막 동료 **9명** 추가. **여관 {counts['inn_scenes']}장면 / 선택지 {counts['choices']}개 / 던전 {counts['dungeon_variants']}개 / 단계 변화 {counts['transition_scenes']}장면**.",
      f"누적 **30명 / 여관 {totals['inn_scenes']} / 선택지 {totals['choices']} / 던전 {totals['dungeon_variants']} / 단계 변화 {totals['transition_scenes']}**. 기존 21명 데이터 변화 0. kreview 파일은 수정하지 않았다.",'',
      '| 인물 · ID | 여관 | 선택 | 던전 | 변화 | 어미 이탈/판정 | 수정쌍 |','|---|---:|---:|---:|---:|---:|---:|']
    for cid in NEW_IDS:
        m=metrics[cid]
        report.append(f"| {IDS[cid]} · `{cid}` | {m['inn_scenes']} | {m['choices']} | {m['dungeon_variants']} | {m['transition_scenes']} | {len(m['ending_deviations'])}/{m['ending_sentences']} | {pairs[cid]} |")
    report+=['',
      f"새 분량 동료 발화 {counts['companion_lines']:,}줄 / 표시 필드 {counts['display_lines']:,}개. 여관 도입 줄수 {dict(opening)}, 선택 반응 줄수 {dict(responses)}. 단계 변화는 장면당 2줄이다.",'',
      '## 집필·자기 편집','',
      '- kreview-2.*의 반복 패턴 10가지를 집필 전에 읽었다. 일상에서는 국·잔·신발·햇빛·낮잠을 그 자체로 이야기하고, 자리·몫·이름·문·빈칸으로 감정을 빗대는 문형을 피했다.',
      '- 셀바의 단골 식당, 오르넬의 도시 소리와 벌레 공포, 자하르의 힘일과 말 적은 식사, 요르드의 냉정한 협의와 차가운 물, 라비니아의 허가와 일상, 토베의 무던함과 숙박 경험, 미코의 부지런한 손과 낮잠, 아델린의 자발적 승부, 콜레트의 서약과 웃음 버릇을 구별했다.',
      '- 효율·안심·기분 전환·일을 대신 처리하자는 제안도 상대 사정에 따라 감점될 수 있게 했다. 선택 이유 756개는 모두 문장이다. 표시 순서는 순환 배치하여 첫 선택만 정답이 되지 않게 했다.',
      f'- [review-4.md](verification/dialogue-r21/review-4.md): 실제 전→후 **{len(edits)}쌍**, 인물당 최소 10쌍. sample4-<id>.md 9개는 낯섦·유대·운명 **27장면**이다.',
      '- 초고는 draft4/, 적용 경로는 edits4-applied.json, 최종 문구·장면·선택 이유는 review-lines4.json·review-scenes4.json·choice-reasons4.json에 보존했다. 새 9명에 대한 독립 검수는 미실시다.',
      '- 작업 시작 때는 kreview-2.* 2개만 있었다. 진행 중 도착한 kreview-3.*는 읽거나 고치지 않았다. 시작 파일은 baseline4.json, 도착 후 관찰한 4개 파일은 independent-reviews-observed4.json의 해시로 구분해 보존한다.','',
      '## 검사','',
      '- 누적 30명 대화 검사 **오류 0**. 단계·상황·인접 경계·호칭·화계·동일 문장 검사 통과. 기존 21명은 검사만 했다.',
      f"- 기존 변이 자가시험 **{selftest['checks']}항목 / 실패 0**, 새 화계 자가시험 **{registers['checks']}항목 / 실패 0**, 합계 **{selftest['checks']+registers['checks']}항목 / 실패 0**.",
      '- 검사기는 정상적인 응답 감탄사 예·네·응과 잠깐을 문장 어미로 오인하던 부분, 해체의 써·차·셔·파·내·혀·춰 활용을 보완했다. 응은 해체에서만, 예·네는 존대 화계에서만 통과시킨다. 요르드·콜레트의 군요·지요와 미코의 하십시오체는 실제 문구를 고쳐 화계를 넓히지 않았다. 기존 검사 기대값은 변경하지 않았다.',
      f'- 새 분량 던전 최장 **{maximum}자**(40자 상한), 전체 표시 필드 최장 **{max_all}자**(64자 상한). 글자 수 검사이며 실제 대화 UI 360폭 줄바꿈은 미연결이라 확인하지 못했다.',
      f"- 공통 Godot 검사 import 포함 **{regression['runs']}개 / {regression['counted_assertions']:,}항목 / 종료·판정 실패 0 / 미분류 엔진 오류 0**. 원시 로그는 regression4/에 있다.",
      f"- 인증서 환경 오류 `Failed to read the root certificate store` **{regression['environment_error_occurrences']}회**는 검사 실패와 분리해 기록했다.",
      '- regression-contact4.png의 r17~r20 전투·r9 바르굿 연출·r18 나란 연출 대표 6장을 직접 열어 버튼·초상·컷인·전투 배치를 확인했다. 새 대화 화면의 렌더링 검증은 아니다.','',
      '## 정본 대비 차이·미정','',
      '- 원본 talk는 무료·하루 1회·aff +1이다. 선택 -2/0/+2는 이전 차수의 콘텐츠 계약이며 실제 연결 때 +1을 대체한다. -100~200·100 초과 양수분 ×0.4는 변경하지 않았다.',
      '- seen은 도입만 대체하며 선택지와 하루 제한은 유지한다. 인접 7경계의 상승·하락을 작성했고 다중 이동에서는 최종 도착 경계 하나를 표시한다.',
      '- 대화의 음식·천·병·약초·서류·카드·주사위·침상은 장면 소품이다. 비용·소지품·회복·숙박·내기·마법 효과·신규 전투 규칙을 실행하지 않는다.',
      '- ID와 이름은 stats.json을 따랐다. 특히 `jorund`의 이름은 **요르드**다. 기존 게임의 힐데가르트 표시는 이전 차수대로 수정하지 않았다.'
    ]+['- '+s for s in MISSING]+['',
      '## 파일·재현·남은 범위','',
      '- 새 콘텐츠: project/data/dialogue-r21/{selva,ornel,zahar,jorund,lavinia,tove,miko,adeline,colette}.json.',
      '- 새 집필·편집 입력: tools/dialogue_r21_4_*.txt, dialogue_r21_4_edits.json. 빌드·편집·보고·검증: round4.py·edit4.py·report4.py·selftest4.py·verify4.py·delivery_check4.py.',
      '- 공용 변경: dialogue_r21_build.py(30명 등록·4차 빌드 연결), round2.py(호칭 9명 등록), check.py(감탄사·해체 어미), report.py·delivery_check.py(4차 연결). 기존 21명 콘텐츠를 다시 빌드하지 않는다.',
      '- 전체 파일 목록과 해시는 delivery-manifest4.json에 있다. 이전 보고서와 검수 결과는 덮지 않고 분리 보존했다.','',
      '```powershell',
      'python -X utf8 tools/dialogue_r21_edit4.py',
      'python -X utf8 tools/dialogue_r21_build.py',
      'python -X utf8 tools/dialogue_r21_check.py --report verification/dialogue-r21/check4.json',
      'python -X utf8 tools/dialogue_r21_selftest.py --report verification/dialogue-r21/selftest4.json',
      'python -X utf8 tools/dialogue_r21_selftest4.py',
      'python -X utf8 tools/dialogue_r21_report4.py',
      'python -X utf8 tools/dialogue_r21_delivery_check4.py',
      '# 공통 회귀를 다시 실행할 때',
      'python -X utf8 tools/dialogue_r21_verify4.py',
      '```','',
      f"보호 대상 {protected['workspace_count']:,}개 변화 0 / 기존 21명 JSON 변화 0 / 독립 검수 {len(protected['independent_review_files_at_start'])}개 변화 0 / 정본 {len(canon)}개 변화 0.",
      '30명 기본 대화 콘텐츠를 모두 작성했다. 여관·던전·연대기 실행 훅과 대화 UI는 이전 범위대로 미연결이다. 식사/선물/숙박 전용 콘텐츠와 성적·친밀 장면은 작성하지 않았다. 게임 코드·저장 형식·원본 에셋은 바꾸지 않았다. git 명령·커밋·웹 내보내기를 실행하지 않았다.','']
    header=('\n'.join(report).rstrip()+'\n\n---\n\n# 이하 1~3차 보고서 원문 보존\n\n').encode('utf-8')
    (ROOT/'DIALOGUE-R21.md').write_bytes(header+(OUT/'original-report3.md').read_bytes())
    files=[ROOT/'DIALOGUE-R21.md',*[(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in NEW_IDS],
      *[p for p in (ROOT/'tools').glob('dialogue_r21_*') if p.is_file() and ('4' in p.stem or p.name in ['dialogue_r21_build.py','dialogue_r21_round2.py','dialogue_r21_check.py','dialogue_r21_report.py','dialogue_r21_delivery_check.py'])],
      *[p for p in OUT.glob('*4*') if p.is_file() and p.suffix in ['.json','.md','.png'] and p.name not in ['delivery-manifest4.json','delivery-check4.json']],
      *list((OUT/'draft4').glob('*.json')),*list((OUT/'regression4').glob('*.log')),
      *list((OUT/'regression4').glob('*.json')),OUT/'original-report3.md']
    manifest={'new_characters':9,'total_characters':30,'new_counts':counts,'total_counts':totals,
      'review_pairs':dict(pairs),'editorial_records':len(edits),'error_count':0,'selftest_checks':selftest['checks']+registers['checks'],
      'opening_lines':dict(opening),'response_lines':dict(responses),'protected':protected,
      'regression':{k:v for k,v in regression.items() if k!='results'},
      'files':{str(p.relative_to(ROOT)):digest(p) for p in sorted(set(files))},'report':'DIALOGUE-R21.md'}
    write_json(OUT/'delivery-manifest4.json',manifest)
    print('round4 report',counts,'edits',len(edits),'manifest files',len(manifest['files']))

if __name__=='__main__':
    import sys
    contact() if '--contact' in sys.argv else main()
