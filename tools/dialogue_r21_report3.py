"""Third-pass handoff, audit inventory, samples and hash evidence."""
from collections import Counter
from pathlib import Path
import json
from dialogue_r21_build import ROOT, CANON, IDS, display_fields, read_json, write_json
from dialogue_r21_round3 import NEW_IDS, VOICE, OUT, digest
from dialogue_r21_round2 import TITLES

MISSING = [
 '리네트: 물려준 늙은 사제의 이름·구호 기금 총액·송금 성과는 없음. 두 겨울 체류와 죄책감은 정본에 있으며 구호 성과를 확정하지 않았다.',
 '펠리스: 통역 집안 가족 이름·섬 공방 스승 이름·새 단골 이름·국숫집 상호와 영업시간은 없음. 통역 골목·끝집 국수·사야에게 받은 인형만 사용했다.',
 '소렐: 약초를 판 동기는 COMPANIONS에서 아직 미정이라고 명시한다. 생계·가족 치료 등의 동기를 만들지 않았다. 숲 복귀·장로와의 화해 결과도 없음.',
 '티카: 성이 지워지기 전 집안과 빚이 누구 것이었는지는 없음. 새 성·새 빚·자유를 다시 사는 규칙을 만들지 않았다.',
 '헤드비히: 스승 이름·학술원 사건의 숨은 결론·영웅담 제목과 줄거리는 없음. 루미엘의 마지막 새벽은 정본의 본인 작명 예시이며 새 주문이나 효과를 뜻하지 않는다.',
 '베렌가: 이름책을 물려준 스승의 이름·책 속 개별 망자의 이름·소환장 전문·사후 세계의 응답은 없음. 길을 떠난 뒤 사람들의 결과를 만들지 않았다.',
 '군힐트: 가문의 땅 반환·복권 약속·성문 폐쇄의 배후는 없음. 빚을 갚던 노예 검투사가 아니라 상금과 이름을 건 자유 검투사다.',
 '바르굿: 추가 작전의 이름·부족 서열 수치·새 전투 신호 규칙은 없음. 대화에서 합의하는 신호는 연출이며 전투 시스템을 바꾸지 않는다.',
 '알탄: 약재가 다른 곳에 팔린 뒤 해당 마을의 생존·구호 결과는 없음. 후회나 속죄 완료를 확정하지 않고 이익 동기를 유지했다.',
 '정본의 소렐 성향 문서와 상세 프로필은 기질 코드 설명에 차이가 있으므로 코드로 화법을 추정하지 않았다. 정본의 냉정한 말투·정당한 값·할인·숲에 대한 애착을 따랐다.',
 '고정 유저 호칭은 정본 없음. 새 9명 모두 유저가 부를 때 이름+씨를 쓰는 편집 규약이며, 동료가 유저에게 쓰는 직접 호칭은 생략한다.'
]

def md(path, lines):
    path.write_text('\n'.join(lines).rstrip()+'\n',encoding='utf-8')

def main():
    check=read_json(OUT/'check3.json'); tests=read_json(OUT/'selftest3.json')
    regression=read_json(OUT/'regression3/regression-summary.json')
    assert check['error_count']==tests['failures']==0
    assert regression['runs']==15 and regression['nonzero_exits']==regression['assertion_failures']==regression['unclassified_errors']==0
    corpus={cid:read_json(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in NEW_IDS}
    edits=read_json(OUT/'edits3-applied.json')
    pair_counts=Counter(e['character_id'] for e in edits)
    assert all(pair_counts[cid]>=10 for cid in NEW_IDS)
    baseline=read_json(OUT/'baseline3.json')
    changes=[p for p,h in baseline['workspace'].items() if not (ROOT/p).is_file() or digest(ROOT/p)!=h]
    canon={**baseline['canon'], **{s['file']:s['sha256'] for s in read_json(OUT/'source-manifest2.json')}}
    canon_changes=[p for p,h in canon.items() if digest(CANON/p)!=h]
    assert not changes and not canon_changes,(changes,canon_changes)
    protected={'workspace_count':len(baseline['workspace']),'workspace_changes':changes,
               'old_character_count':12,'old_character_changes':[p for p in changes if 'data/dialogue-r21' in p],
               'canonical_source_count':len(canon),'canonical_source_changes':canon_changes,
               'independent_review_files_at_start':[p for p in baseline['workspace'] if 'kreview-2.' in p],
               'independent_review_file_changes':[p for p in changes if 'kreview-2.' in p]}
    write_json(OUT/'protected3.json',protected)
    metrics=check['characters']
    keys=['inn_scenes','choices','dungeon_variants','transition_scenes','companion_lines','display_lines','ending_sentences']
    counts={k:sum(metrics[cid][k] for cid in NEW_IDS) for k in keys}
    totals={k:sum(m[k] for m in metrics.values()) for k in keys}
    opening=Counter(len(s['lines']) for d in corpus.values() for s in d['inn'])
    response=Counter(len(c['response']) for d in corpus.values() for s in d['inn'] for c in s['choices'])
    reasons=[{'character_id':cid,'scene':s['id'],'choice':c['id'],'reason':c['reason']}
             for cid,d in corpus.items() for s in d['inn'] for c in s['choices']]
    assert len(reasons)==756 and all(len(x['reason'])>=12 and x['reason'].endswith('다.') for x in reasons)
    review=['# 3차 자기 편집','',
            '새 9명만 작성하고 재독했다. 독립 검수 승인이 아니다. draft3/에 편집 전 원문, edits3-applied.json에 실제 적용 경로를 남겼다.',
            '선택 반응을 보강한 뒤 장면 안의 질문→답변, 손동작→부탁, 부담이 큰 거절의 이유를 다시 읽었다. 세 관점은 한 작성자의 관점 전환이며 별도 검수자 수로 세지 않는다.','',
            '재독 기준: 연어·입말·과한 비유·반복·맞춤법·조사·주어 생략·행동과 해설 중복·자리와 부담·화계와 관계 변화.','',
            '시처럼 꾸민 끝줄을 붙이지 않으며, 편집용 선택 이유는 모두 문장으로 썼다. 정본 공백을 대사로 메우지 않았는지도 대조했다.','']
    for cid,d in corpus.items():
        review += [f'## {IDS[cid]} · {cid}','',VOICE[cid],f'유저 호칭: {TITLES[cid]}.','',
                   '| 경로 | 전 | 후 | 지침 |','|---|---|---|---|']
        for e in edits:
            if e['character_id']==cid:
                review.append(f"| `{e['path']}` | {e['before']} | {e['after']} | {e['rule']} |")
        review += ['',f'수정 {pair_counts[cid]}쌍. [대표 장면](sample3-{cid}.md).','']
    md(OUT/'review-3.md',review+['## 정본에서 확인할 수 없는 것','']+['- '+s for s in MISSING])
    line_inventory=[]; scene_inventory=[]
    samples={'lynette':[4,13,24],'felice':[4,15,27],'sorel':[5,12,24],'tika':[5,12,26],
             'hedwig':[6,13,27],'berenga':[4,13,27],'gunhild':[6,12,24],'bargut':[7,14,27],'altan':[6,13,26]}
    for cid,d in corpus.items():
        sample=[f'# {IDS[cid]} · 3차 표본','',VOICE[cid],'',
                f'호칭: 유저 → {TITLES[cid]} / 동료 → 유저 직접 호칭 생략.','',
                '최종 JSON에서 추출했다. 낯섦·유대·운명 각각 1장면이며 독립 판정은 대기다.','',
                '정본: '+', '.join(f"{s['file']}:{s['line_start']}-{s['line_end']}" for s in d['sources']),'']
        chosen=[d['inn'][i] for i in samples[cid]]
        assert [s['stage'] for s in chosen]==['낯섦','유대','운명']
        for s in chosen:
            sample += [f"## {s['stage']} · {s['id']}",'',s['situation'],'']+['> '+t for t in s['lines']]
            sample += ['', '| 선택 | 반응 | aff | 편집용 이유 |', '|---|---|---:|---|']
            sample += [f"| {c['text']} | {' / '.join(c['response'])} | {c['aff']:+d} | {c['reason']} |" for c in s['choices']]
            sample += ['',f"재노출: {s['seen']}",'']
        md(OUT/f'sample3-{cid}.md',sample)
        for p,t,companion in display_fields(d):
            line_inventory.append({'character_id':cid,'path':p,'text':t,'companion':companion,
                                   'sha256':__import__('hashlib').sha256(t.encode('utf-8')).hexdigest()})
        scene_inventory.extend({'character_id':cid,'voice':VOICE[cid],**s} for s in d['inn'])
    write_json(OUT/'review-lines3.json',{'method':'작성자 재독을 위한 문구 목록. 자동 의미 판정이나 독립 승인으로 세지 않음.','records':line_inventory})
    write_json(OUT/'review-scenes3.json',scene_inventory)
    write_json(OUT/'choice-reasons3.json',reasons)
    report=['# 3차','',
      f"새 동료 **9명** 추가. **여관 {counts['inn_scenes']}장면 / 선택지 {counts['choices']}개 / 던전 {counts['dungeon_variants']}개 / 단계 변화 {counts['transition_scenes']}장면**.",
      f"기존 12명은 바이트 그대로 보존했다. 누적 **21명 / 여관 {totals['inn_scenes']} / 선택지 {totals['choices']} / 던전 {totals['dungeon_variants']} / 단계 변화 {totals['transition_scenes']}**.",'',
      '| 인물 · ID | 여관 | 선택 | 던전 | 변화 | 어미 이탈/판정 | 수정쌍 |','|---|---:|---:|---:|---:|---:|---:|']
    for cid in NEW_IDS:
        m=metrics[cid]
        report.append(f"| {IDS[cid]} · `{cid}` | {m['inn_scenes']} | {m['choices']} | {m['dungeon_variants']} | {m['transition_scenes']} | {len(m['ending_deviations'])}/{m['ending_sentences']} | {pair_counts[cid]} |")
    report += ['',f"새 분량 동료 발화 {counts['companion_lines']:,}줄 / 표시 필드 {counts['display_lines']:,}개. 도입 줄수 {dict(opening)}, 선택 반응 줄수 {dict(response)}. 단계 변화는 장면마다 2줄이다.",'',
      '## 판정 반영과 검수','',
      '- 인물 버릇: 리네트의 흥정과 자기 식사, 펠리스의 통역 골목과 조용한 저녁, 소렐의 할인과 아엔윈, 티카의 관객 앞뒤 목소리, 헤드비히의 기록·영웅담·본인 작명, 베렌가의 이름책과 머무름, 군힐트의 호령·이름·꼬리, 바르굿의 거리와 불 가까운 자리, 알탄의 장부와 이름을 단계별로 드러냈다.',
      '- 감점 선택은 좋은 결과를 바라는 제안이라도 설명 공개·효율·공연·대리 결정·무상 노동·과한 보호 등이 상대의 사정과 어긋나게 썼다. 선택 이유 756개는 한 문장 이상의 설명이며 한 낱말 표시는 없다.',
      f"- [review-3.md](verification/dialogue-r21/review-3.md)에 실제 전→후 **{len(edits)}쌍**, 인물당 최소 10쌍. 표본은 sample3-<id>.md 9개, 낯섦·유대·운명 **27장면**이다.",
      '- 초고·최종 문구 목록·장면 전체·선택 이유는 draft3/, review-lines3.json, review-scenes3.json, choice-reasons3.json에 보존했다. 반응 보강은 tools/dialogue_r21_3_response.txt에 있으며 공개 수정쌍 수에 중복 가산하지 않았다.',
      '- 시적인 재노출·끝줄 대신 지금 하는 행동과 부탁을 남겼다. 짧게 말하는 바르굿도 세 줄 도입과 선택 뒤 응답이 이어지게 했다.',
      '- 자기 편집 완료이며 독립 표본 판정은 대기다. kreview-2.*를 읽어 반영하거나 수정하지 않았다.','',
      '## 검사','',
      f"- 누적 21명 대화 검사 **오류 {check['error_count']}**: 단계·상황·경계·호칭·화계·중복 검사 통과.",
      f"- 변이 자가시험 **{tests['checks']}항목 / 실패 {tests['failures']}**. 아니다의 니다 오탐, 해체 군, 들립니까·냅니까의 ㅂ니까를 별도 검증했다.",
      '- 검사기의 어미 판정만 고쳤으며 허용 화계를 넓히지 않았다. 하십시오체 의문형은 받침 ㅂ 뒤의 니까로 한정해 연결어미 -니까를 통과시키지 않는다. 기존 12명 데이터와 기존 테스트 기대값은 변경하지 않았다.',
      f"- 새 분량 던전 최장 {max(metrics[c]['max_dungeon_chars'] for c in NEW_IDS)}자(40자 상한), 전체 표시 필드 최장 {max(metrics[c]['max_line_chars'] for c in NEW_IDS)}자(64자 상한).",
      f"- 공통 Godot 검사 import 포함 **{regression['runs']}개 / {regression['counted_assertions']:,}항목 / 종료·판정 실패 0 / 미분류 엔진 오류 0**. 원시 로그는 regression3/에 있다.",
      f"- 환경 인증서 오류 `Failed to read the root certificate store`는 {regression['environment_error_occurrences']}회 남았다. 검사 실패와 분리해 기록했다.",
      '- regression-contact3.png의 r17~r20 전투·r9 연출·r18 미리보기 대표 6장을 직접 열어 확인했다. 새 대화 UI는 미연결이므로 실제 360폭 대화 줄바꿈은 확인하지 못했다.','',
      '## 정본 대비 차이와 공백','',
      '- 기존 talk 무료·하루 1회·aff +1에 대해 선택 -2/0/+2는 이전 차수와 같은 콘텐츠 계약이다. 실제 연결 시 +1을 대체하며 중복 가산하지 않는다. -100~200·100 초과 양수분 ×0.4는 변경하지 않았다.',
      '- 식탁·국수·쌀 그림·약병·약초·잉크·의자·책·장부는 대화 소품이다. 아이템·기부·거래·선물·숙박·회복·마법 효과를 실행하지 않는다. 대화 중 역할·신호 협의도 새 전투 규칙이 아니다.',
      '- seen은 도입만 대체하고 choices와 하루 제한은 유지한다. 단계 변화는 인접 7경계의 상승·하락, 다중 경계 이동은 최종 도착 경계 하나를 표시하는 이전 계약이다.'
    ]+['- '+s for s in MISSING]
    report += ['', '## 파일·재현·남은 범위','',
      '- 콘텐츠: project/data/dialogue-r21/{lynette,felice,sorel,tika,hedwig,berenga,gunhild,bargut,altan}.json.',
      '- 작성·편집: tools/dialogue_r21_3_*.txt, dialogue_r21_round3.py, dialogue_r21_edit3.py, dialogue_r21_3_edits.json.',
      '- 공용 변경: dialogue_r21_build.py(21명 등록·새 9명 빌드), round2.py(호칭·이전 빌드 범위 고정), check.py(21명·어미), selftest.py(출력 경로·어미 사례), report.py·delivery_check.py(현 차수 연결). report3.py·verify3.py·delivery_check3.py 추가. 전체 목록과 해시는 delivery-manifest3.json.',
      '', '```powershell',
      'python tools/dialogue_r21_edit3.py',
      'python tools/dialogue_r21_build.py',
      'python tools/dialogue_r21_check.py --report verification/dialogue-r21/check3.json',
      'python tools/dialogue_r21_selftest.py --report verification/dialogue-r21/selftest3.json',
      'python tools/dialogue_r21_report3.py',
      'python tools/dialogue_r21_delivery_check3.py',
      '# 공통 회귀 전체 재실행', 'python tools/dialogue_r21_verify3.py', '```','',
      f"보호 대상 {protected['workspace_count']:,}개 변화 0 / 기존 12명 JSON 변화 0 / 정본 {len(canon)}개 변화 0. 독립 검수 파일은 생성된 경우에도 수정 대상에서 제외했다. 이전 검수·로그는 새 경로와 구별해 보존했다.",
      '여관·던전·연대기 실행 훅과 대화 UI는 이전 범위대로 미연결이다. 남은 동료 9명·식사/선물/숙박 전용 콘텐츠·성적 및 친밀 장면은 미작성이다. 저장 형식·게임 코드·원본 에셋은 바꾸지 않았다. 커밋과 웹 내보내기는 하지 않았다.',
      '규칙을 읽는 초기 병렬 호출에 git status --short가 1회 포함됐으나 소유권 오류로 실패했다. 이후 git 명령과 설정 변경은 하지 않았다.','']
    archive=OUT/'original-report2.md'
    if not archive.exists():archive.write_bytes((ROOT/'DIALOGUE-R21.md').read_bytes())
    md(ROOT/'DIALOGUE-R21.md',report+['---','','# 이하 1·2차 보고서 원문 보존','',archive.read_text(encoding='utf-8').rstrip()])
    files=[ROOT/'DIALOGUE-R21.md',*[ROOT/f'project/data/dialogue-r21/{c}.json' for c in NEW_IDS],
           *ROOT.glob('tools/dialogue_r21_3_*'),*[ROOT/f'tools/dialogue_r21_{n}.py' for n in ['build','round2','round3','check','selftest','edit3','report','report3','verify3','delivery_check','delivery_check3']]]
    files += [OUT/'review-3.md',OUT/'review-lines3.json',OUT/'review-scenes3.json',OUT/'choice-reasons3.json',
              OUT/'check3.json',OUT/'selftest3.json',OUT/'edits3-applied.json',OUT/'regression-contact3.png',
              OUT/'regression3/regression-summary.json',*OUT.glob('sample3-*.md')]
    manifest={'new_characters':9,'total_characters':21,'new_counts':counts,'total_counts':totals,
              'review_pairs':dict(pair_counts),'editorial_records':len(edits),'selftest_checks':tests['checks'],
              'error_count':check['error_count'],'protected':protected,'regression':{k:v for k,v in regression.items() if k!='results'},
              'opening_lines':dict(opening),'response_lines':dict(response),'report':'DIALOGUE-R21.md',
              'files':{str(p.relative_to(ROOT)).replace('\\','/'):digest(p) for p in files if p.is_file()}}
    write_json(OUT/'delivery-manifest3.json',manifest)
    print(json.dumps({'counts':counts,'totals':totals,'review_pairs':dict(pair_counts),'protected':protected},ensure_ascii=False))

if __name__=='__main__':main()
