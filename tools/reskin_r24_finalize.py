"""Record the completed manual review and a source handoff manifest; no git calls."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/reskin-r24'

def write(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

tests = json.loads((OUT / 'all-tests.json').read_text(encoding='utf-8'))
assert len(tests) == 160 and all(row['passed'] for row in tests)
cleanup = json.loads((OUT / 'cleanup.json').read_text(encoding='utf-8'))
assert not cleanup['temporary_slots_remaining'] and cleanup['base_runtime_preserved']
sheets = [OUT / f'sheet-{i}.jpg' for i in range(1, 37)]
assert all(p.exists() and p.stat().st_size <= 800000 for p in sheets)
write('visual-review.json', {
    'method': 'Direct visual inspection of the native PNG comparison images, all 36 contact sheets, and selected full-size native captures.',
    'native_captures': 423,
    'states': 141,
    'sizes': [[390, 844], [360, 780], [1280, 800]],
    'reviewed_sheets': [p.name for p in sheets],
    'final_rechecked_sheets': [2, 14, 26, 31, 32, 33, 34, 35, 36],
    'reviewed_comparisons': ['compare-town.png', 'compare-companion.png'],
    'selected_full_size_checks': ['town', 'member', 'create', 'save-error', 'save-error-inn', 'save-error-member', 'person-cesare', 'person-dorothea', 'person-godfroi', 'person-hanna'],
    'fixed_during_review': ['Duplicate native text underneath RowCopy primary labels', 'Save recovery controls overlapping existing actions', 'Legacy navigation appearing as separate boxed controls', 'Old desktop gutter background on fallback screens', 'Selected shop and departure filters taking the primary-action treatment'],
    'remaining_limits': ['Portrait lane not merged', 'No new Web export or deployment', 'No physical-phone validation'],
})

baseline = ROOT.parent / 'r21-portrait'
digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
paths = []
for folder, pattern in [('project/ui', '*'), ('project/tests', 'ui_*.gd')]:
    for p in (ROOT / folder).glob(pattern):
        if not p.is_file() or p.suffix not in {'.gd', '.gdshader'}:
            continue
        if p.name in {'portrait_layout_r24.gd', 'character_portrait.gd', 'town_portrait_r21.gd', 'battle_face_r17.gd', 'portrait_rules_r22.gd'}:
            continue
        other = baseline / p.relative_to(ROOT)
        if not other.exists() or digest(p) != digest(other):
            paths.append(p)
            sidecar = Path(str(p) + '.uid')
            if not other.exists() and sidecar.exists():
                paths.append(sidecar)
paths += [p for p in (ROOT / 'project/assets/ui-r24').rglob('*') if p.is_file()]
paths += list((ROOT / 'tools').glob('*reskin*.py'))
paths += [ROOT / 'DESIGN.md', ROOT / 'RESKIN-R24.md']

marker = '\n## 최종 검토와 인계\n'
report_path = ROOT / 'RESKIN-R24.md'
report = report_path.read_text(encoding='utf-8').split(marker)[0]
report += marker + '''
네이티브 캡처 423장으로 구성한 시트 36장을 직접 검토했다. 최종 수정 후 시트 2·14·26·31~36을 다시 확인했다. [검토 기록](verification/reskin-r24/visual-review.json), [소스 인계 목록](verification/reskin-r24/source-handoff.json), [런타임 정리](verification/reskin-r24/cleanup.json)를 함께 남긴다. 임시 런타임 슬롯은 0개이며 공용 기본 런타임은 보존했다.

저장 실패의 복구 안내는 본문 위에 별도 공간을 예약하고 원래 행동은 스크롤로 접근할 수 있게 했다. 페르소나 파티 자리는 동료 전용 대사·특성 데이터가 없으므로 기존 상태창을 연다. 실제 클릭으로 원본 능력치·스킬을 확인했다. 구형 상세창의 내비게이션도 연속된 검은 띠로 통일했다. 셰이더는 공유하여 화면 반복 구성 비용을 줄였다.

소스 인계 목록은 읽기 전용 r21-portrait 사본과 다른 허용 UI·시험 파일, 이 작업의 UI 자산·도구·문서에 대한 경로와 SHA-256이다. 전체 작업공간의 git diff를 대신하는 목록은 아니며, 보호 파일 검사는 별도 protected-check.json을 기준으로 한다.
'''
report_path.write_text(report, encoding='utf-8')
write('source-handoff.json', {
    'comparison_reference': str(baseline),
    'comparison_scope': 'Allowed UI and UI tests; owned ui-r24 assets, reskin tools and documentation',
    'files': [{'path': p.relative_to(ROOT).as_posix(), 'bytes': p.stat().st_size, 'sha256': digest(p)} for p in sorted(set(paths))],
    'verification_directory': 'verification/reskin-r24',
})
print(json.dumps({'tests_passed': len(tests), 'reviewed_sheets': len(sheets), 'source_manifest_files': len(set(paths)), 'temporary_slots': 0}))
