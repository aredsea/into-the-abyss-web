from pathlib import Path
from datetime import datetime
import hashlib
import json
import re
import sys

root = Path(__file__).resolve().parents[2]
out = root / 'verification/en-r24'
sys.path.insert(0, str(root / 'tools'))
from en_r24 import audit, sample
from en_r24_verify import HEADLESS, WINDOWED
from dialogue_r21_build import display_fields

added = 'hildegard jorund judith lavinia levia lynette marceline miko naran ornel saya selva sorel teiris tika tove urda zahar'.split()
a = audit()
assert a['fields'] == a['translated'] == 14216 and a['untranslated'] == 0
assert all(x['source_unchanged'] and x['original_bytes_reconstruct_exactly'] for x in a['files'])
sample()
runtime = json.loads((root/'verification/finish-r24/authored-language-audit.json').read_text(encoding='utf8'))
assert runtime['fields'] == 14216 and runtime['untranslated'] == 0
run = json.loads((out/'full-run-round3.json').read_text(encoding='utf8'))
assert run['exit'] == 0
started = datetime.fromisoformat(run['started_at']).timestamp()
regression = json.loads((out/'regression.json').read_text(encoding='utf8'))
expected = ['import', *HEADLESS, *WINDOWED]
assert len(regression) == len(expected) == 20
assert {x['test'] for x in regression} == set(expected)
assert all(x['passed'] and not x['errors'] and x['exit'] == 0 for x in regression)
counts = []
for row in regression:
    path = out/(row['test']+'.log')
    assert path.stat().st_mtime >= started, path
    log = path.read_text(encoding='utf8')
    matches = re.findall(r'\bCHECKS\s*:?\s*(\d+)', log)
    if not matches:
        matches = re.findall(r'(\d+)\s+checks\b', log, re.I)
    if matches:
        counts.append({'test':row['test'],'checks':int(matches[-1])})
ui = json.loads((out/'ui-test.json').read_text(encoding='utf8'))
dialogue = json.loads((out/'dialogue-test.json').read_text(encoding='utf8'))
assert not ui['failures'] and not dialogue['failures']
assert len(dialogue['characters']) == 30 and dialogue['fields'] == 14216
base = json.loads((out/'baseline.json').read_text(encoding='utf8'))
protected_changes = [p for p,h in base['protected'].items() if not (root/p).exists() or hashlib.sha256((root/p).read_bytes()).hexdigest()!=h]
assets = json.loads((root/'ASSET-HASHES.json').read_text(encoding='utf8'))
asset_changes = [x['path'] for x in assets if hashlib.sha256((root/x['path']).read_bytes()).hexdigest()!=x['sha256']]
assert not protected_changes and not asset_changes
batches=[]
for i in range(0,len(added),3):
    ids=added[i:i+3]
    path=out/('batch-'+'-'.join(ids)+'-results.json')
    rows=json.loads(path.read_text(encoding='utf8'))
    assert len(rows)==4 and all(x['passed'] for x in rows),path
    language=json.loads((out/('batch-'+'-'.join(ids)+'-language.json')).read_text(encoding='utf8'))
    assert language['untranslated']==0
    batches.append({'characters':ids,'fields':language['fields'],'untranslated':0,'tests':4,'failed':0})
visual=json.loads((out/'visual-review-round3.json').read_text(encoding='utf8'))
assert visual['reviewed_characters']==30
summary={
    'status':'complete','characters_complete':30,'characters_total':30,
    'fields':14216,'translated':14216,'untranslated':0,
    'round3_characters_added':18,'round3_fields_added':8580,
    'regression_runs':20,'regression_failed':0,
    'counted_checks':sum(x['checks'] for x in counts),'checks_by_test':counts,
    'ui_scenes':ui['scenes'],'ui_checks':ui['checks'],'ui_failures':0,
    'sample_rows':300,'sample_scope':'All 30 characters; all 14,216 fields', 'sample_seed':20261104,
    'protected_files':len(base['protected']),'protected_changes':protected_changes,
    'asset_hash_entries':len(assets),'asset_hash_changes':asset_changes,
    'original_bytes_reconstruct_exactly':True,'save_format_changed':False,
    'release_language_gate_passed':True,'external_translation_services_used':False,
    'runtime_slots_cleaned':not (root/'verification/ui-r17/runtime-en-r24').exists(),
    'visual_captures_reviewed':visual['reviewed_captures'],'batches':batches,
    'full_run':run,
}
assert summary['runtime_slots_cleaned']
summary['regression_kinds']=20
summary['post_screen_copy_retests']=3
summary['editorial_revisions']=len(json.loads((out/'editorial-revisions-round3.json').read_text(encoding='utf8')))
for cid in added:
    d=json.loads((root/'project/data/dialogue-r21'/(cid+'.json')).read_text(encoding='utf8'))
    (out/(cid+'.txt')).write_text('\n'.join(d['en']['display'][k] for k,_,_ in display_fields(d))+'\n',encoding='utf8')
(out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(out/'translation-execution.json').write_text(json.dumps({
    'method':'Direct assistant translation; no external translation service or API; no subagents.',
    'round3_completed':added,'completed':[r['id'] for r in a['files']],'remaining':[],
    'translated':14216,'untranslated':0,'original_bytes_reconstruct_exactly':True,
},indent=2)+'\n',encoding='utf8')
lines=[
    '**EN-R24 — 완료 / 30명·14,216개 영어 번역 및 검증**','',
    '이번 3차 실행에서 남은 18명·8,580개 표시 문구를 직접 번역했다. 기존 12명·5,636개를 합쳐 **30명·14,216개 전부 완료**했다. '
    '실제 영어 표시 함수를 거친 authored-language-audit의 한국어 잔존은 **0개**다.','',
    '| 항목 | 결과 |','| --- | ---: |',
    '| 완료 인물 / 표시 문구 | 30명 / 14,216개 |',
    '| 이번 실행 추가 | 18명 / 8,580개 |',
    '| 실제 영어 표시의 한국어 잔존 | 0개 |',
    '| 3명 묶음 검사 | 6묶음·24회, 실패 0 |',
    '| 최종 전체 회귀 검사 | 20종, 실패 0 |',
    '| 화면 문구 수정 후 추가 재검사 | 영어 대사·실제 표시·영어 UI 3종, 실패 0 |',
    f'| 최종 로그에서 집계한 검사 | {summary["counted_checks"]:,}개, 실패 0 |',
    f'| 영어 UI 장면 / 검사 | {ui["scenes"]:,}개 / {ui["checks"]:,}개, 실패 0 |',
    '| 원문 바이트 복원 | 30개 파일 SHA-256 일치 |',
    f'| 보호 파일 / 원본 자산 | {len(base["protected"]):,}개 변경 0 / {len(assets)}개 불일치 0 |',
    '| 한·영 무작위 표본 | 전체 14,216개에서 300줄, 직접 대조 |','',
    '변경한 제품 파일은 `project/data/dialogue-r21/` 아래 다음 18개 JSON이다: '+', '.join('`'+x+'.json`' for x in added)+'. '
    '각 파일에 별도 `en.display`와 `en.speech`를 추가했다. 기존 언어별 표시 연결을 사용하며 이번 실행에서는 제품의 표시 함수나 게임 규칙을 수정하지 않았다. '
    '영어 필드를 제거하면 한국어 원문과 기존 공백까지 최초 바이트가 그대로 복원된다. 장면 구조·id·선택지 순서·호감 수치·저장 형식은 그대로다.','',
    '힐데가·요르드·마르셀린의 격식, 유디트의 자신감과 연구 질문, 레비아의 조심스러운 거절, 사야의 짧은 말, '
    '나란의 거래 농담, 티카의 관객 앞 큰 목소리와 둘만 남았을 때의 망설임 등을 인물별 영어 지침에 적고 대사에 반영했다. '
    '가까워져도 인물의 선택·거절·두려움·가족·신앙·이해관계가 남도록 원문과 대조했다. '
    '기존 사전의 Hildegard, Jorund, Judith, Lavinia da Cadell, Sorel Aenwyn, the March, Berghold, Tarn Valley, '
    'Naerin, Silverbough Watch, Kern, Marento, Harben, Drum 및 Year of Isolation 표기를 확인했다. '
    '새 설정이나 성적 장면을 추가하지 않았다. 외부 번역 서비스·API·보조 에이전트는 사용하지 않았다.','',
    '3명마다 바뀐 파일의 실제 표시 언어 스캔과 영어 선택·한국어 유지·저장 왕복 검사, dialogue_player 및 dialogue_roster 시험을 실행했다. '
    '6개 묶음 모두 한국어 잔존 0과 실패 0이다. 300줄 표본을 읽고 어색한 영어 88개 표현을 다듬은 뒤 전체 검사를 새로 실행했다. '
    '화면을 직접 확인한 뒤 29개 표현을 추가로 다듬어 총 117개 영어 표현을 수정했고, 영어 대사·실제 표시 감사·영어 UI 3종을 다시 통과했다. '
    '최종 20종 로그는 이번 전체 실행 시작 시각 이후에 생성된 파일인지도 확인했다.','',
    '최종 검사는 import, en_r24, dialogue_player/roster, finish_locale_data_audit, world/state/route/expansion/motion/motion_asset/art/export_licenses, '
    'ui_battle_r17/r18/r19/r20, motion_r9/r18, ui_en_r24이다. 기대값을 낮추지 않았다. '
    '루트 인증서 저장소를 읽지 못한다는 기존 환경 메시지를 제외한 스크립트 오류는 0이다.','',
    '[300줄 한·영 표본](verification/en-r24/sample.md)은 전체 30명·14,216개에서 seed 20261104로 중복 없이 추출했다. '
    '표본에는 30명 모두 포함되어 있다. 300줄을 직접 읽고 원문과 대조했으며 수정 후 동일한 표본을 다시 생성했다. '
    '도구 변경은 `tools/en_r24.py`의 표본 범위 설명을 실제 완료 상태에 맞춘 것이며, 새 보조 스크립트와 검증 기록은 `verification/en-r24/` 안에 있다.','',
    f'영어 360/430px 캡처 {visual["reviewed_captures"]}개를 30명 대조 이미지로 직접 열어 확인했다. '+visual['review_ko'], '',
    'Web export·`docs/`·다른 작업 공간·사용자 저장 파일은 수정하지 않았다. 이번 검사의 runtime-en-r24, runtime-local-en-r24, tmp-en-r24 슬롯은 정리했다. '
    '번역 미완료 항목은 없다. 화면 시각 검토는 인물별 첫 선택지·스크롤 하단·응답·탐색 장면 표본이며, 모든 장면의 수동 시각 검토를 뜻하지 않는다.','',
    '근거: [summary.json](verification/en-r24/summary.json), [regression.json](verification/en-r24/regression.json), '
    '[원문 보존 감사](verification/en-r24/authored-language-audit.json), [실제 표시 감사](verification/finish-r24/authored-language-audit.json), '
    '[dialogue-test.json](verification/en-r24/dialogue-test.json), [ui-test.json](verification/en-r24/ui-test.json), '
    '[표본 대조](verification/en-r24/sample-review-round3.json), [표현 수정 기록](verification/en-r24/editorial-revisions-round3.json), '
    '[시각 검토](verification/en-r24/visual-review-round3.json). 묶음별 근거는 `batch-*-results.json`과 해당 로그다.','',
    '| 인물 | 표시 문구 | 미번역 |','| --- | ---: | ---: |',
]
for row in a['files']: lines.append(f'| {row["id"]} | {row["fields"]} | 0 |')
lines += ['', '재검사:', '', '```powershell', 'python tools/en_r24.py audit', 'python tools/en_r24.py sample', 'python tools/en_r24_verify.py', '```', '']
(root/'EN-R24.md').write_text('\n'.join(lines),encoding='utf8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['checks_by_test','batches']},ensure_ascii=False,indent=2))
