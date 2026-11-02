"""Build fifth-pass review evidence and samples from final JSON bytes."""
from collections import Counter
from dialogue_r21_build import ROOT, OUT, CANON, IDS, read_json, write_json, display_fields
from dialogue_r21_round5 import digest, at
from dialogue_r21_patterns5 import main as patterns_main


def md(path, lines):
    path.write_text('\n'.join(lines).rstrip()+'\n', encoding='utf-8')


def main():
    patterns_main()
    edits = read_json(OUT/'edits5-applied.json')
    decisions = read_json(OUT/'decisions5.json')
    lint = read_json(OUT/'check5.json')
    tests = read_json(OUT/'selftest5.json')
    registers = read_json(OUT/'selftest5-registers.json')
    regression = read_json(OUT/'regression5/regression-summary.json')
    assert lint['error_count'] == tests['failures'] == registers['failures'] == 0
    assert all(regression[k] == 0 for k in ['nonzero_exits', 'assertion_failures', 'unclassified_errors'])
    base = read_json(OUT/'baseline5.json')
    protected = {
        'workspace_count': len(base['protected']),
        'workspace_changes': [p for p,h in base['protected'].items() if digest(ROOT/p) != h],
        'canon_count': len(base['canon']),
        'canon_changes': [p for p,h in base['canon'].items() if digest(CANON/p) != h],
        'review_count': len(base['reviews']),
        'review_changes': [p for p,h in base['reviews'].items() if digest(ROOT/p) != h],
        'historical_count': len(base['historical']),
        'historical_changes': [p for p,h in base['historical'].items() if digest(ROOT/p) != h],
    }
    assert not any(protected[k] for k in ['workspace_changes','canon_changes','review_changes','historical_changes']), protected
    write_json(OUT/'protected5.json', protected)
    gates = read_json(OUT/'humanize-gates5/summary.json')
    gate_rows = read_json(OUT/'humanize-gates5/results.json')
    assert gates['chunks']==99 and gates['errors']==0 and not gates['warning_chunks']
    chunk_rates=[r['report']['change_rate']['rate']*100 for r in gate_rows]
    finalized=read_json(ROOT/'_workspace/2026-11-03-001-8495/09_finalize.json')
    assert finalized['status']=='corrected'
    pattern_data = read_json(OUT/'patterns5.json')
    review = ['# 5차 독립 검수 반영 및 전체 패턴 교정', '',
        '세 벌 66건의 원문 ID별 처리와 30명 전체의 국소 편집이다. 독립 검수 파일은 그대로 보존했다.',
        '검수의 문법·의미 지적을 반영하되 감점 선택을 호의적 답으로 뒤집는 제안은 같은 aff 의미의 대안으로 적용했다.', '',
        '## 지적 반영 표', '', '| ID | 위치 | 판정 | 처리 이유 |', '|---|---|---|---|']
    for d in decisions:
        review.append(f"| {d['id']} | `{d['scene_id']}` · `{d.get('path',d.get('field',''))}` | {d['status']} | {d['reason']} |")
    review += ['', '원문·제안·최종 실제 문구와 경로는 decisions5.json에 보존한다.', '',
        '## 반복 패턴 전후', '',
        '동일 정규식으로 원문과 최종 발화 필드의 출현 수를 센다. situation·편집용 reason은 제외한다. 선택지 진단은 선택 text만, 사적 문서어는 여관 발화만 센다.',
        '**아래 수치는 검색 후보 수이며 오용 수가 아니다.** 실제 의자·이름·서류와 필요한 거절도 포함한다. 감정 해설·시적 여운의 의미 판정은 패턴 표본 대조와 edits5-applied.json의 편집 근거를 함께 본다.', '',
        '| 패턴 | 전 출현 | 후 출현 | 전 필드 | 후 필드 |', '|---|---:|---:|---:|---:|']
    for name, p in pattern_data['patterns'].items():
        review.append(f"| {name} | {p['before_occurrences']} | {p['after_occurrences']} | {p['before_fields']} | {p['after_fields']} |")
    review += ['', '정규식과 모든 검출 경로·문구는 patterns5.json, 표본의 의미 확인은 pattern-audit5.md에 있다.', '',
        '## 인물별 변경률 및 대표 전후', '',
        '변경률은 상황 지문을 제외한 동료 발화+플레이어 선택 문구 중 달라진 필드 비율이다. 줄이 둘로 나뉘어도 한 필드는 1건이며 편집용 reason·자동 인벤토리는 제외한다. 동료만의 비율도 metrics5.json에 별도 기록한다.', '']
    all_metrics = {}
    for cid, name in IDS.items():
        before = read_json(OUT/f'draft5/{cid}.json')
        after = read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
        b = {p:(t,sp) for p,t,sp in display_fields(before) if not p.endswith('/situation')}
        a = {p:t for p,t,_ in display_fields(after) if not p.endswith('/situation')}
        assert set(a) == set(b)
        changed = [p for p in b if b[p][0] != a[p]]
        companion = [p for p in b if b[p][1]]
        rate = 100*len(changed)/len(b)
        local = [e for e in edits if e['character_id'] == cid and e['path'] in changed]
        assert len(local) == len(changed) and len(local) >= 5, cid
        m = dict(total_fields=len(b), changed_fields=len(changed), field_change_percent=round(rate,2),
            companion_fields=len(companion), companion_changed=sum(p in changed for p in companion),
            companion_change_percent=round(100*sum(p in changed for p in companion)/len(companion),2),
            warning_over_40=rate>40, skill_warning_over_30=rate>=30)
        all_metrics[cid] = m
        review += [f'### {name} · {cid}', '', f"변경 {len(changed)}/{len(b)}필드 ({rate:.2f}%). 동료 발화 {m['companion_changed']}/{len(companion)}필드 ({m['companion_change_percent']:.2f}%).", '',
            '| 경로 | 전 | 후 | 근거 |', '|---|---|---|---|']
        # Favor concrete independent-review corrections, then diverse paths.
        ranked = sorted(local, key=lambda e: (not any(d.get('character_id')==cid and d.get('path')==e['path'] for d in decisions), e['path']))
        for e in ranked[:5]:
            assert at(before,e['path']) == e['before'] and at(after,e['path']) == e['after']
            review.append(f"| `{e['path']}` | {e['before']} | {e['after']} | {e['reason']} |")
        if rate>40:
            review += ['', '경고: 인물당 대사의 40%를 넘게 수정했다. 사유: '+next(e['reason'] for e in local)]
        elif rate>=30:
            review += ['', '스킬 경고: 발화 필드 변경률 30% 이상. 문자율과 다른 집계이며 국소 편집 근거를 전수 보존했다.']
        review += ['', f'[낯섦·유대·운명 최종 표본](sample5-{cid}.md)', '']
        sample = [f'# {name} · 5차 최종 표본', '', after['speech']['register'], '',
                  '최종 JSON에서 추출했다. 낯섦·유대·운명 각 1장면이며 새 독립 승인 판정은 아니다.', '']
        picks = []
        for stage in ['낯섦','유대','운명']:
            candidates = [(i,s) for i,s in enumerate(after['inn']) if s['stage']==stage]
            i,s = max(candidates,key=lambda v:sum(p.startswith(f'inn/{v[0]}/') for p in changed))
            picks.append(s['id'])
            sample += [f"## {stage} · {s['id']}", '', s['situation'], '']+['> '+t for t in s['lines']]
            sample += ['', '| 선택 | 반응 | aff | 편집 이유 |', '|---|---|---:|---|']
            for c in s['choices']:
                sample.append(f"| {c['text']} | {' / '.join(c['response'])} | {c['aff']:+d} | {c['reason']} |")
            sample += ['', '재노출: '+s['seen'], '']
        m['sample_scene_ids'] = picks
        md(OUT/f'sample5-{cid}.md',sample)
    write_json(OUT/'metrics5.json',all_metrics)
    md(OUT/'review-5.md',review)
    counts = {k:sum(m[k] for m in lint['characters'].values()) for k in ['inn_scenes','choices','dungeon_variants','transition_scenes']}
    status = Counter(d['status'] for d in decisions)
    total_changed = sum(m['changed_fields'] for m in all_metrics.values())
    warnings = [IDS[c] for c,m in all_metrics.items() if m['warning_over_40']]
    delivery=read_json(OUT/'delivery-check5.json') if (OUT/'delivery-check5.json').exists() else None
    report = ['# 5차', '',
        f"30명 전체 국소 교정. 독립 검수 **66건(고침 19·권함 47) 모두 반영**, 실제 발화 **{total_changed}필드** 수정.",
        f"장면·선택·aff 구조 불변: **여관 {counts['inn_scenes']} / 선택지 {counts['choices']} / 던전 {counts['dungeon_variants']} / 단계 변화 {counts['transition_scenes']}**.", '',
        '- [review-5.md](verification/dialogue-r21/review-5.md): 지적 ID별 반영 표, 반복 패턴 전후 수, 인물당 대표 전후 5쌍(총 150쌍).',
        '- [pattern-audit5.md](verification/dialogue-r21/pattern-audit5.md): 검색 후보의 실제 뜻과 고유 소재 보존 표본. 기계 수치는 오용 수로 주장하지 않는다.',
        '- sample5-<id>.md **30개 / 90장면**. 각 인물 낯섦·유대·운명에서 실제 수정이 많은 장면을 추출했다.',
        f"- 인물당 40% 초과 경고 **{len(warnings)}명**"+(' ('+', '.join(warnings)+')' if warnings else '')+'. 인물별 분모·변경률은 metrics5.json에 있다.', '',
        '## 검사', '',
        '- 최종 30명 대화 검사 **오류 0**. 선택 ID·순서·aff·장면·화계 메타데이터를 원문과 대조하고, 오프라인 재빌드 바이트 일치도 확인했다.',
        (f"- 납품 검사 **{delivery['checks']}항목 / 실패 {delivery['failures']}**. 30개 표본·150개 대표 전후·66개 판정 경로·전체 파일 해시를 최종 데이터와 대조했다." if delivery else '- 납품 검사 결과는 delivery-check5.json에 기록한다.'),
        f"- 기존 변이·화계 자가시험 **{tests['checks']+registers['checks']}항목 / 실패 0**. 검사 기대값·허용 화계 변경 0.",
        f"- 공통 Godot **15종 / {regression['counted_assertions']:,}항목 / 종료·판정 실패 0 / 최종 미분류 오류 0**. 인증서 환경 오류 {regression['environment_error_occurrences']}회는 분리 기록.",
        '- 첫 ui_battle_r18_test 종료에서 resources still in use 오류 1회가 있었다. 같은 명령 재실행 결과와 첫 원시 로그를 regression5/retry5.json 및 *-attempt1.log에 보존했다. 재실행을 숨겨 최초 오류 0으로 세지 않는다.',
        '- regression-contact5.png 대표 6장을 직접 확인했다. 기존 전투·연출 검증이며 새 대화 UI는 미연결이라 실제 대화 줄바꿈은 확인하지 못했다.', '',
        '## 윤문 보조 검증', '',
        f'- humanize-korean heavy: 동결 입력을 결정 청크 **99개**로 나눠 무손실 재조립. 청크별 스킬 원본 게이트 문자 변화율 **{min(chunk_rates):.2f}~{max(chunk_rates):.2f}%**, 최종 경고·실행 오류 0.',
        '- 경로 식별자를 포함한 69만자 전역 문자 정렬은 처리 지연으로 중단했다. 위 수치는 99개 청크 각각의 문자율이며 전역 문자율로 합성하지 않았다. 인물별 대사 변경률은 별도 필드 기준이다.',
        '- 첫 게이트의 추측 소실 1건은 가능성 표현을 복구한 뒤 같은 99개 게이트를 다시 통과했다. 낮은 문장 유사도로 판정이 보류된 14건은 부정된 당위·구체 행동 대체·추측 어미 대체인지 문맥을 대조했고 기록을 남겼다.',
        '- 최종 상태 corrected, 스킬 자체 대조 5/6 통과. S1 전수 잔존 0은 자동·표본 검사로 확정하지 않아 해당 항목과 문체 등급은 보류했다. 남은 고유 소재·실제 거절·상황 설명은 pattern-audit5.md에 보존 이유를 적었다.', '',
        '## 보존·재현', '',
        f"- 보호 대상 {protected['workspace_count']}개·정본 {protected['canon_count']}개·독립 검수 {protected['review_count']}개·이전 검수 산출 {protected['historical_count']}개 변화 0.",
        '- 수정 근거 전체: edits5-applied.json. 원문: draft5/ 30개. 재빌드는 이 동결 원문과 경로별 교정만 사용하며 이전 차수 초고·검수 결과를 덮지 않는다.',
        '- 정본 사실·소재·사연·화계, 저장 형식, 게임 실행 훅, 에셋 변경 0. 앞 차수의 정본 공백·콘텐츠 계약·미연결 범위는 그대로다. 성적·친밀 장면 추가 없음.',
        '- git 명령·커밋·Web export 실행 없음.', '',
        '```powershell', 'python -X utf8 tools/dialogue_r21_build.py',
        'python -X utf8 tools/dialogue_r21_check.py --report verification/dialogue-r21/check5.json',
        'python -X utf8 tools/dialogue_r21_selftest5.py',
        'python -X utf8 tools/dialogue_r21_patterns5.py',
        'python -X utf8 tools/dialogue_r21_report5.py',
        'python -X utf8 tools/dialogue_r21_delivery_check5.py',
        '# 공통 회귀 전체 재실행', 'python -X utf8 tools/dialogue_r21_verify5.py', '```', '']
    (ROOT/'DIALOGUE-R21.md').write_bytes(('\n'.join(report).rstrip()+'\n\n---\n\n# 이하 1~4차 보고서 원문 보존\n\n').encode('utf8')+(OUT/'original-report4.md').read_bytes())
    files = [ROOT/'DIALOGUE-R21.md', *[(ROOT/f'project/data/dialogue-r21/{c}.json') for c in IDS],
        *[p for p in (ROOT/'tools').glob('dialogue_r21_*5*') if p.is_file()],
        ROOT/'tools/dialogue_r21_5_finalizer.json',
        ROOT/'tools/dialogue_r21_build.py',ROOT/'tools/dialogue_r21_report.py',ROOT/'tools/dialogue_r21_delivery_check.py',
        *[p for p in OUT.rglob('*') if p.is_file() and str(p.relative_to(ROOT)) not in base['historical']
          and p.name not in ['delivery-manifest5.json','delivery-check5.json']]]
    skill_run=ROOT/'_workspace/2026-11-03-001-8495'
    files += [skill_run/name for name in ['00_metrics.json','01_input.txt','02_diagnosis.md',
        'chunk_manifest.json','03_reassembled.md','09_finalize.json','final.md','chunk-editorial-map.json']]
    manifest = dict(counts=counts, characters=30, changed_display_fields=total_changed,
        decisions=len(decisions), protected=protected,
        files={str(p.relative_to(ROOT)):digest(p) for p in sorted(set(files))})
    write_json(OUT/'delivery-manifest5.json',manifest)
    print('round5 report', counts, 'edited speech fields',total_changed,'manifest',len(manifest['files']))


if __name__ == '__main__':
    main()
