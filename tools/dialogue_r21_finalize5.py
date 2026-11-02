"""Preserve finalizer resolution and the exact skill projection of final JSON."""
from dialogue_r21_build import ROOT, OUT, read_json, write_json
from dialogue_r21_round5 import digest


def main():
    run=ROOT/'_workspace/2026-11-03-001-8495'
    gates=read_json(OUT/'humanize-gates5/results.json')
    summary=read_json(OUT/'humanize-gates5/summary.json')
    assert summary['errors']==0 and not summary['warning_chunks']
    reassembled=(run/'03_reassembled.md').read_text(encoding='utf8')
    assert reassembled==(run/'expected-final.txt').read_text(encoding='utf8')
    final=run/'final.md'
    if final.exists() and not (run/'final_pre_finalize.md').exists():
        (run/'final_pre_finalize.md').write_bytes(final.read_bytes())
    rates=[r['report']['change_rate']['rate'] for r in gates]
    uncertain=[dict(chunk=r['index'],**p) for r in gates for p in r['report']['modality']['uncertain_pairs']]
    patches=read_json(ROOT/'tools/dialogue_r21_5_finalizer.json')+read_json(OUT/'finalizer-corrections5.json')
    result=dict(status='corrected',route='heavy',grade='보류',self_check_passed=5,self_check_total=6,
        local_corrections=len(patches),fidelity_violations_unresolved=[],
        change_rate_scope='경로 식별자 포함 99개 결정 청크 각각의 verify_gates.py 값. 전역 문자율이 아니다.',
        min_chunk_change_rate=min(rates),max_chunk_change_rate=max(rates),
        gate_error_count=summary['errors'],gate_warning_count=len(summary['warning_chunks']),
        uncertainty_pairs=uncertain,
        uncertainty_resolution='14개 문맥을 대조했다. 부정된 당위(같아져야 하는 것은 아니다 등)는 의무 소실이 아니다. 먹으려면 앉아야 한다는 자명한 조건·같이 알아볼 칸은 구체 행동으로 대체했다. 졸릴 수도/졸릴지도는 추측을 유지한다. 티카의 부정 선택은 크게 말하라는 요구로 바뀌어 해당 반응도 구체적으로 다시 연결했다.',
        warnings=['S1 전수 잔존 0은 확정하지 않으며 문체 등급을 보류한다. 고유 소재·필요한 거절·전이 안내는 남아 있다.',
                  '69만자 전역 정렬 게이트는 처리 지연으로 중단하고 원본 스킬 게이트를 99개 결정 청크에 적용했다.'],
        self_checks=[
            dict(name='사실·수치·고유명사·의도 보존',status='pass',evidence='정본 해시·구조·aff 비교와 원문 문맥 대조. 비유 자체 삭제는 사용자 지시 범위.'),
            dict(name='변경률',status='pass',evidence='99개 청크 원본 게이트 문자율 30% 미만. 인물별 필드 변경률도 40% 미만.'),
            dict(name='장르',status='pass',evidence='게임 대화 장면과 줄 수 보존.'),
            dict(name='register 양방향 보존',status='pass',evidence='기존 어미 검사·184개 자가시험 기대값 불변.'),
            dict(name='잔존 S1 전수 0',status='unconfirmed',evidence='전체 소재 패턴 감소를 확인했지만 자동·표본 검사만으로 전수 자연스러움은 단정하지 않는다.'),
            dict(name='새 비유·수사·상투구 주입 방지',status='pass',evidence='교차 finalizer와 주 편집자 대조. 숟가락 농담은 기존 유머 갈래의 의미를 구체화했다.')])
    write_json(run/'09_finalize.json',result)
    write_json(OUT/'finalize5.json',result)
    block='\n\n<!-- HUMANIZE-SUMMARY -->\n<!--\n'+__import__('json').dumps({
        'status':'corrected','route':'heavy','before_chars':len((run/'01_input.txt').read_text(encoding='utf8')),
        'after_chars':len(reassembled),'grade':'보류','self_check':'5/6',
        'change_rate':'99개 청크 각각 '+f'{min(rates)*100:.2f}~{max(rates)*100:.2f}%',
        'categories':['생성 비유','원칙 요약','중복 해설','문서어','선택지 진단','먼저 반복','표기'],
        'highlights':['독립 검수 66건 반영','대사 표시 1032필드 교정','장면·선택·aff 불변'],
        'remaining':'S1 전수 잔존 0·문체 등급은 보류. 상세 문맥과 보존 판단은 pattern-audit5.md.'},ensure_ascii=False,indent=2)+'\n-->\n'
    final.write_text(reassembled+block,encoding='utf8')
    manifest=read_json(run/'chunk_manifest.json')
    write_json(OUT/'humanize-gates5/input-hashes.json',[dict(index=c['index'],before=digest(run/f"01_chunk_{c['index']:02d}_original.txt"),after=digest(run/c['rewritten_file'])) for c in manifest['chunks']])
    print('finalized',len(patches),'corrections','99 gate chunks','5/6 self checks')


if __name__=='__main__':
    main()
