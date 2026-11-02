"""Second-pass evidence; round1/ is historical, not overwritten by this command."""
from collections import Counter
import hashlib
import json
from dialogue_r21_build import ROOT, CANON, OUT, IDS, display_fields, read_json, write_json
from dialogue_r21_round2 import VOICE, TITLES
from dialogue_r21_verify import protected

QUESTIONS = ['어휘·동작의 짝', '보고서 말 대신 입말', '직역 비유 제거', '반복과 말버릇의 구별',
 '맞춤법·조사·띄어쓰기', '번역투 문법·불필요한 주어', '행동 뒤 감정 해설 생략',
 '모호한 뜻을 행동으로 풀기', '관계·자리·거절의 부담', '화계·단계별 노출 정도']
MISSING = [
 '힐데가·게르다: 고립의 해 성문 폐쇄 배후·범람 원인은 없음. 게르다가 본 징조의 구체적인 종류도 없음.',
 '마르셀린: 피고 이름·마지막 말, 연애 소설 고유 제목·저자·완결 줄거리는 없음. 절차를 찾는 독서 습관만 사용했다.',
 '테이리스: 노트 첫 장 질문 문구·장로 발언의 정확한 인용·사절 선발의 숨은 이유는 없음. 첫 장 공개는 미뤘다.',
 '나란: 두 장부가 들킨 뒤 확정 처리·정산 결과는 없음. 장부를 고치려 망설이는 대화에 머물렀다.',
 '할드리크: 부대장이 된 정확한 해·추가 계약 조항 전문은 없음. 정본의 제3조를 부르는 버릇과 보증 이름만 사용했다.',
 '에르데네: 해체된 옛 부족 고유 이름·아버지 생존 여부·복권 결과는 없음. 새 이름·복권 결과를 만들지 않았다.',
 '비앙카: 황금 명부 등재 결과·위원회가 보증 인장을 대신 얻어 주는 규칙은 없음. 반대표 억제·세 인장·대평의회 문턱의 한계를 유지했다.',
 '사야: 신세 진 사람 이름·아샤크 뒷골목 상세 사건은 없음. 추격대 이력은 성향 시트와 상세 설정이 충돌한다. COMPANIONS가 미채택 후보라고 명시하므로 확정 이력으로 쓰지 않았다.',
 '유디트: 시험실 화재 확정 원인·금지 연구의 상세 결론·심연 기원의 확정 답은 없음. 본인 가설과 탐구심으로 표현했다.',
 '레비아: 수정구 파괴 원인·다른 형태의 마법 정체·감시 중 상세 과제는 없음. 노동 계급·도망친 노예로 바꾸지 않았다.',
 '우르다: 두 신이 실제로 하나였다는 확정 사실·신의 답은 없음. 우르다의 믿음과 흔들림으로만 말했다.',
 '동료별 고정 유저 호칭은 없음. speech.address_terms는 이번 편집 규약이며 정본 고정 설정으로 보지 않는다.'
]
SAMPLES = {'hildegard':[4,13,26], 'marceline':[4,14,24], 'teiris':[5,12,27],
 'naran':[4,12,27], 'haldric':[6,13,25], 'erdene':[4,12,27], 'bianca':[4,14,27],
 'saya':[5,12,24], 'gerda':[4,13,27], 'judith':[5,12,27], 'levia':[4,12,27], 'urda':[4,12,24]}

def md(path, rows):
    path.write_text('\n'.join(rows).rstrip()+'\n',encoding='utf-8')

def main():
    check,tests=read_json(OUT/'check.json'),read_json(OUT/'selftest.json')
    assert check['error_count']==tests['failures']==0
    corpus={cid:read_json(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in IDS}
    edits=read_json(OUT/'edits2-applied.json'); fine=read_json(ROOT/'tools/dialogue_r21_2_edits.json')
    review=['# 2차 자기 편집','','작성 뒤 다시 읽은 자기 편집 기록이다. 독립 검수자의 승인이 아니다. 초고는 draft2/, 적용 경로는 edits2-applied.json에 보존했다.','',
      '기존 3명은 84장면 전부 상황을 여는 말을 더하고 모든 선택 반응을 두 줄로 고쳤다. 새 9명도 초고 작성 뒤 실제 문구를 수정했다. 인물마다 최소 10쌍의 전→후 원문을 싣는다.','',
      '## 재독 기준','']+[f'{i+1}. {q}' for i,q in enumerate(QUESTIONS)]
    review+=['','문학 편집자 관점에서는 상황→본론의 호흡과 여백을, 교열 관점에서는 연어·어미·호칭을, 연재 대사 관점에서는 반복되는 버릇과 선택의 속뜻을 대조했다. 같은 작성자의 관점 전환이며 독립 검수 3인의 판정으로 세지 않았다.','',
      '검사기가 연결어미 -니까를 하십시오체 의문형으로 읽은 2건은 -습니까/-입니까와 구별하도록 고쳤다. 허용 화계를 늘려 이탈을 감추지 않았다.','']
    pair_counts={}
    for cid,data in corpus.items():
        review += [f'## {IDS[cid]} · {cid}','',VOICE[cid],'',f'유저 → {TITLES[cid]} / 동료 → 유저 직접 호칭 생략.','']
        pairs=[]
        if cid in ['hildegard','marceline','teiris']:
            before=read_json(OUT/f'round1/{cid}.json')
            for i in [0,4,6,9,11,12,14,17,24,27]:
                oc=next(c for c in before['inn'][i]['choices'] if c['aff']==-2)
                nc=next(c for c in data['inn'][i]['choices'] if c['aff']==-2)
                pairs.append((f'inn/{i}/choices/aff=-2',oc['text']+' → '+' / '.join(oc['response']),nc['text']+' → '+' / '.join(nc['response']),
                  '5.2·5.4·5.5: 선의의 선택이 이 인물의 사정과 어긋나는 대목을 반응으로 드러냈다.'))
        else:
            pairs=[(e['path'],e['before'],e['after'],e['rule']+': '+e['reason']) for e in fine if e['character_id']==cid]
        assert len(pairs)>=10,(cid,len(pairs))
        pair_counts[cid]=len(pairs)
        review+=['| 경로 | 전 | 후 | 지침·편집 근거 |','|---|---|---|---|']+[f'| `{p}` | {b} | {a} | {r} |' for p,b,a,r in pairs]
        review+=['',f'대표 장면: [sample2-{cid}.md](sample2-{cid}.md)','']
    md(OUT/'review-2.md',review+['## 정본 공백과 충돌','']+['- '+s for s in MISSING])
    line_records,scene_records=[],[]
    for cid,data in corpus.items():
        sample=[f'# {IDS[cid]} · 2차 대표 장면','','최종 JSON에서 추출. 독립 판정 대기.','',VOICE[cid],'',
          f'유저 호칭: {TITLES[cid]} / 동료 직접 호칭: 생략.','',
          '정본: '+', '.join(f"`{s['file']}:{s['line_start']}-{s['line_end']}`" for s in data['sources']),'']
        chosen=[data['inn'][i] for i in SAMPLES[cid]]
        assert [s['stage'] for s in chosen]==['낯섦','유대','운명']
        for s in chosen:
            sample += [f"## {s['stage']} · {s['id']}",'',s['situation'],'']+['> '+t for t in s['lines']]
            sample += ['', '| 선택 | 반응 | aff | 편집용 이유 |','|---|---|---:|---|']
            sample += [f"| {c['text']} | {' / '.join(c['response'])} | {c['aff']:+d} | {c['reason']} |" for c in s['choices']]
            sample += ['',f"재노출: {s['seen']}",'']
        md(OUT/f'sample2-{cid}.md',sample)
        scene_records += [{'character_id':cid,'scene_id':s['id'],'relationship':s['stage'],
          'place':'여관 공용 식탁·문가에서 사적으로 나누는 말','burden':'부탁·거절·고백의 체면과 답할 시간',
          'voice':VOICE[cid],'choice_reasons':{c['id']:c['reason'] for c in s['choices']}} for s in data['inn']]
        for path,text,companion in display_fields(data):
            section,index,*_=path.split('/'); s=data[section][int(index)]
            line_records.append({'character_id':cid,'path':path,'text':text,'sha256':hashlib.sha256(text.encode('utf-8')).hexdigest(),
              'relationship':s.get('stage',s.get('band',f"{s.get('from')}→{s.get('to')}")),
              'speaker':IDS[cid] if companion else '유저 선택지' if '/choices/' in path else '지문',
              'editorial_criteria':list(range(1,11)),'editorial_context':VOICE[cid],
              'method':'작성자 재독 기준과 대조한 문구 목록. 독립 인적 승인·자동 의미 판정으로 세지 않음.'})
    write_json(OUT/'review-lines2.json',{'questions':QUESTIONS,'line_count':len(line_records),'records':line_records})
    write_json(OUT/'review-scenes2.json',scene_records)
    metrics=check['characters']; counts={k:sum(m[k] for m in metrics.values()) for k in ['inn_scenes','choices','dungeon_variants','transition_scenes','companion_lines','display_lines','ending_sentences']}
    regression=read_json(OUT/'regression-summary.json'); initial=read_json(OUT/'regression-initial-summary.json')
    assert regression['nonzero_exits']==regression['assertion_failures']==regression['unclassified_errors']==0
    baseline,current=read_json(OUT/'protected-before.json'),protected()
    differences=[p for p in sorted(set(baseline)|set(current)) if baseline.get(p)!=current.get(p)]
    assert not differences,differences
    sources=read_json(OUT/'source-manifest2.json')
    source_changes=[s['file'] for s in sources if hashlib.sha256((CANON/s['file']).read_bytes()).hexdigest()!=s['sha256']]
    assert not source_changes
    report=['# 2차','',f"기존 3명 84장면 전부 보완 + 새 9명 작성 완료. **12명 / 여관 {counts['inn_scenes']}장면 / 선택지 {counts['choices']}개 / 던전 {counts['dungeon_variants']}개 / 단계 변화 {counts['transition_scenes']}장면**.",'',
      '| 인물 · ID | 여관 | 선택지 | 던전 | 단계 변화 | 어미 이탈 | 공개 수정쌍 |','|---|---:|---:|---:|---:|---:|---:|']
    for cid in IDS:
        m=metrics[cid]; report.append(f"| {IDS[cid]} · `{cid}` | {m['inn_scenes']} | {m['choices']} | {m['dungeon_variants']} | {m['transition_scenes']} | {len(m['ending_deviations'])}/{m['ending_sentences']} | {pair_counts[cid]} |")
    openings=Counter(len(s['lines']) for d in corpus.values() for s in d['inn'])
    responses=Counter(len(c['response']) for d in corpus.values() for s in d['inn'] for c in s['choices'])
    report+=['',f"동료 발화 {counts['companion_lines']:,}줄 / 표시 필드 {counts['display_lines']:,}개 / 어미 판정 {counts['ending_sentences']:,}문장. 여관 도입 줄수 분포 {dict(sorted(openings.items()))}, 선택 반응 줄수 분포 {dict(sorted(responses.items()))}.",'',
      '## 판정 반영','',
      '- 시범 3명 모든 장면의 도입과 모든 선택 반응을 보완했다. 힐데가의 명령→부탁, 마르셀린의 소설 속 절차→교리서 변명→자기 말, 테이리스의 노트·늦은 대박·조용한 질문을 단계별로 드러냈다.',
      '- 감점 선택은 보호·휴식 권유·효율·쉽게 화해하자는 제안이 상대의 바람과 어긋나게 고쳤다. 긍정 선택은 장비를 함께 보기, 소설의 순서보다 기다리기, 노트를 덮고 듣기 등 인물 사정과 맞물린다.',
      '- 유저 호칭을 speech.address_terms에 고정했다. 예: 마르셀린 씨, 힐데가 경, 할드리크 부대장. 동료가 유저에게 쓰는 직접 호칭은 생략한다. 이름을 부를 때 다른 표기는 검사에서 거부한다.',
      '- 겹친 오늘도·없어도와 뜻이 흐린 쉬는 연습 문장을 정리했다. 전·후 원문은 round1·draft2에 남겼다.','',
      '## 검사·검수','',
      f"- 대화 검사 오류 **{check['error_count']}**. 단계·이벤트·경계 누락, 금지 표기·같은 줄/문장·화계·호칭 불일치 모두 0.",
      f"- 변이 자가시험 **{tests['checks']}항목 / 실패 {tests['failures']}**. 호칭 누락·변경·금지 직접 호칭·2줄 도입·4줄 반응·단계 초과·화계 오탐도 검사했다.",
      f"- 던전 최장 {max(m['max_dungeon_chars'] for m in metrics.values())}자(상한 40), 전체 표시 필드 최장 {max(m['max_line_chars'] for m in metrics.values())}자(상한 64).",
      f"- [review-2.md](verification/dialogue-r21/review-2.md): 공개 전→후 **{sum(pair_counts.values())}쌍**, 인물당 최소 10쌍. 적용 기록은 {len(edits)}건이며 시범 3명의 장면·선택 묶음 168건을 포함한다. 두 수치는 단위가 다르다.",
      '- 대표 표본 36장면: verification/dialogue-r21/sample2-<id>.md, 낯섦·유대·운명 각 1개. 전체 문구는 review-lines2.json, 맥락은 review-scenes2.json.',
      '- 자동 검사는 보조 도구다. 문맥상 모든 호칭·새 한국어 고유명사를 완전히 검출하지 못한다. 자연스러움은 자기 재독했고 독립 판정은 대기다.','',
      '## 공통 회귀와 화면','',
      f"최종 유효 검사 import 포함 {regression['runs']}개 / 종료 실패 0 / 수치가 출력된 **{regression['counted_assertions']:,}항목 실패 0** / 미분류 엔진 오류 0. 기대값 변경은 없다.",
      f"첫 ui_battle_r18_test의 종료 자원 해제 오류 {initial['unclassified_errors']}건은 원시 로그·regression-initial-summary.json에 보존했다. 같은 명령을 Python subprocess로 재실행해 종료 코드 {read_json(OUT/'regression-retry.json')['exit_code']}, 자원 해제 오류 0을 확인했다. 최종 합계는 같은 4,592항목을 중복 가산하지 않았다.",
      '인증서 환경 오류 Failed to read the root certificate store는 최종 15개 실행 각각에 남았다. 회귀 실패 0 속에 감추지 않았다. 중간 PowerShell 리디렉션도 따로 보존했고 최종 판정은 subprocess 원시 출력·종료 코드로 했다.',
      'r17/r18/r19/r20 전투 360폭, r9 전투 연출, r18 나란 미리보기를 regression-contact2.png로 직접 열어 확인했다. 버튼·이름·초상·전투 본체·컷인 배치를 확인했다. 새 대화 UI는 미연결이라 실제 360폭 줄바꿈은 확인하지 못했다.','',
      '## 정본 대비 차이·공백','',
      '- 12개 ID는 정본 stats와 현재 world 양쪽에 있다. 정본 이름을 사용했다. 현재 게임의 힐데가르트 표시는 수정하지 않았다.',
      '- 기존 talk는 무료·하루 1회·aff +1이다. 선택 aff -2/0/+2는 콘텐츠 계약이며 기존 +1을 대체하도록 명시했다. 실제 연결·수치 규칙은 변경하지 않았다. -100~200·100 초과 양수분 ×0.4를 유지한다.',
      '- 책·그릇·실·장갑·종이는 대화 소품이다. 아이템 지급·금전 거래·새 장비·전투 효과를 추가하지 않는다.',
      '- talk 장면의 독서·식탁 이야기는 meal/gift/rest 행동·비용을 실행하지 않는다. seen은 도입을 대신할 한 줄이고 choices·하루 제한은 유지한다. 변화는 최종 도착 인접 경계 하나만 표시하는 기존 계약을 유지한다.'
    ]+['- '+s for s in MISSING]
    report+=['','## 파일·재현·미완 범위','',
      '- 콘텐츠: project/data/dialogue-r21/*.json (12개). 작성·편집·검사: tools/dialogue_r21_* (목록·해시는 delivery-manifest2.json).',
      '- 검수·표본·이전 원문·원시 회귀 로그: verification/dialogue-r21/.','',
      '```powershell','python tools/dialogue_r21_build.py','python tools/dialogue_r21_check.py','python tools/dialogue_r21_selftest.py','python tools/dialogue_r21_report.py',
      '# 공통 회귀 전체 재실행 시','python tools/dialogue_r21_verify.py','```','',
      f'보호 대상 {len(baseline):,}개 SHA-256 변화 **0**, 정본 {len(sources)}개 변화 **0**. 저장 데이터·저장 형식·전투 코드·원본 에셋을 바꾸지 않았다.',
      '여관·던전·연대기 실행 훅·대화 UI 연결은 원래 범위대로 미실시다. 나머지 18명·식사/선물/숙박 전용 콘텐츠·성적 및 친밀 장면은 작성하지 않았다. 79-sex.lua는 이관하지 않았다. 커밋·웹 내보내기도 하지 않았다.',
      '규칙 확인과 동시에 초기 git status --short를 1회 잘못 실행했다. 소유권 오류로 실패했고 이후 git 명령·설정 변경은 하지 않았다. 작업 내용은 커밋하지 않은 파일 상태로 남겼다.','',
      '---','','# 이하 1차 보고서 원문 보존','',(OUT/'round1/DIALOGUE-R21.md').read_text(encoding='utf-8').rstrip()]
    md(ROOT/'DIALOGUE-R21.md',report)
    files=sorted([*ROOT.glob('tools/dialogue_r21_*'),*ROOT.glob('project/data/dialogue-r21/*.json')])
    write_json(OUT/'delivery-manifest2.json',{'counts':counts,'characters':len(IDS),'review_pairs':pair_counts,
      'editorial_records':len(edits),'errors':check['error_count'],'selftest':{'checks':tests['checks'],'failures':tests['failures']},
      'protected_files':len(baseline),'protected_changes':differences,'source_changes':source_changes,
      'files':[{'file':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files if p.is_file()],
      'content_sha256':check['input_sha256'],'report':'DIALOGUE-R21.md','status':'자기 편집 완료·독립 표본 판정 대기'})
    print(json.dumps({'report':str(ROOT/'DIALOGUE-R21.md'),**counts,'review_pairs':sum(pair_counts.values())},ensure_ascii=False))

if __name__=='__main__':
    main()
