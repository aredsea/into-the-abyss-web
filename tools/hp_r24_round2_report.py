"""Prepend the second-pass evidence without replacing the first-pass history."""
from pathlib import Path
import hashlib,json,difflib
R=Path(__file__).resolve().parents[1];O=R/'verification/hp-r24/round2'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,value):p.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
extras={'export_licenses','motion_r9_integration','motion_r18_integration','balance_probe','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
cloud=read(O/'cloud/results.json')
rows=read(O/'regression.json')+cloud
# The first full pass exposed overlapping touch boxes; keep its evidence and
# replace those results only with the completed, post-fix affected rerun.
fixes=read(O/'touch-fix-tests.json');assert len(fixes)==5 and all(r['passed'] for r in fixes)
merged={r['test']:r for r in rows}
for row in fixes:merged[row['test']]=row
rows=list(merged.values())
missing=sorted(expected-{r['test'] for r in rows});failed=[r['test'] for r in rows if not r['passed']]
write(O/'all-tests.json',{'expected_groups':len(expected),'completed_groups':len(rows),'passed_groups':sum(r['passed'] for r in rows),'failed_groups':failed,'missing_groups':missing,'tests':rows})
assert not missing and not failed,(missing,failed)
cloud_names={r['test'] for r in cloud}
write(O/'regression.json',[r for r in rows if r['test'] not in cloud_names])
hp=read(O/'results.json');assert not hp['failures']
base=read(O/'hp-results.json');assert not base['failures'] and not base['captures']
audits=[]
for name in ['p2-full-battles','a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
    d=read(R/'verification/data-r21'/f'{name}.json')
    audits.append({'file':f'verification/data-r21/{name}.json','battles':d['battles'],'equal_battles':d.get('equal_battles',d['battles'] if d.get('different_actions')==0 else 0),'source_actions':d.get('source_actions',d.get('compared_actions')),'matched_actions':d['matched_actions']})
parity={'battles':sum(d['battles'] for d in audits),'equal_battles':sum(d['equal_battles'] for d in audits),'actions':sum(d['source_actions'] for d in audits),'matched_actions':sum(d['matched_actions'] for d in audits),'audits':audits}
assert parity['battles']==parity['equal_battles']==6320 and parity['actions']==parity['matched_actions']
write(O/'battle-parity.json',parity)
assets=read(R/'ASSET-HASHES.json');bad=[a['path'] for a in assets if hashlib.sha256((R/a['path']).read_bytes()).hexdigest()!=a['sha256']]
write(O/'asset-check.json',{'checked':len(assets),'unchanged':len(assets)-len(bad),'failures':bad});assert not bad
files=['project/ui/battle_screen.gd','project/tests/ui_hp_r24_test.gd','project/tests/ui_hp_r24_round2_test.gd','tools/hp_r24_verify.py','tools/hp_r24_round2_review.py','tools/hp_r24_round2_report.py']
if (R/'project/tests/ui_hp_r24_round2_test.gd.uid').exists():files.append('project/tests/ui_hp_r24_round2_test.gd.uid')
write(O/'delivery-files.json',[{'path':p,'sha256':hashlib.sha256((R/p).read_bytes()).hexdigest()} for p in files])
before=(O/'battle_screen.before.gd').read_text(encoding='utf-8');after=(R/'project/ui/battle_screen.gd').read_text(encoding='utf-8')
(O/'product.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/battle_screen.gd',tofile='after/battle_screen.gd')),encoding='utf-8')
temp=R/'verification/ui-r17';leftovers=[str(p.relative_to(R)) for prefix in ['runtime-hp-r24-','runtime-local-hp-r24-','tmp-hp-r24-'] for p in temp.glob(prefix+'*') if p.is_dir()]
write(O/'cleanup.json',{'temporary_slots_remaining':leftovers,'default_runtime_preserved':(temp/'runtime').is_dir()});assert not leftovers
header=f'''# HP-R24 · A 먹 붓 게이지

## 2차 · 적 이름표 숫자 가림 수정

적 이름표를 **이름 → 9px 붓 바 → 오른쪽 체력 숫자**로 분리했다. 일반 판은 **33→48px**, 바와 숫자 행의 간격은 **2px**다. 기존 13px 숫자 행이 실제 글꼴 높이보다 작아 바가 숫자 하단을 덮던 원인을 제거했다.

- 단독 보스 판은 스프라이트 위의 빈 공간에, 여러 적 전투의 보스 판은 아군과 보스 사이 빈 공간에 놓았다. 적 스프라이트 위치·크기는 유지했다. 대상 선택의 클릭 영역도 판과 적 그림을 포함하도록 맞췄다.
- 짧은 전장에서 위쪽 적 판은 38~48px로 조절한다. 9px 바는 유지하며 숫자 서체 크기와 행간만 조절해 보스 머리를 덮지 않게 했다. 긴 이름은 기존 말줄임·전체 이름 tooltip을 유지한다. 테스트의 네 이름에 같은 정본 긴 이름을 넣은 것은 표시 스트레스 사례다.
- 제품 수정은 `battle_screen.gd`의 `_battlefield()` 한 함수에 한정된다. 아군 카드·상태 패널·공용 게이지·잔상 코드 변경 **0**. [5크기×일반/감소의 아군 카드 픽셀 비교](verification/hp-r24/round2/party-pixel-comparison.json) **10/10 동일**. [공용·마을 코드 해시](verification/hp-r24/round2/preservation.json)도 일치하며 1차 아군/잔상 프레임과 캡처는 보존했다.

### 직접 연 캡처와 A 대조

[A와 적 판 확대 비교](verification/hp-r24/round2/compare-approved-A.png), [기본·감소 모션 5크기](verification/hp-r24/round2/review-states.png), [대상 선택 5크기](verification/hp-r24/round2/review-target.png), [4적·긴 이름·대상 선택](verification/hp-r24/round2/review-multi.png)를 열어 확인했다. 바와 숫자 분리·숫자 하단·보스 머리·다른 판과의 간격을 함께 검토했다.

| 화면 | A와 같은 점 | 차이·유지한 점 |
|---|---|---|
| 360×780 | 이름/바/숫자 순서, 9px 붓·문턱·오른쪽 숫자 | 4적 상단 판은 38px, 숫자 13px. 보스 판은 중앙 빈 공간. 이름은 말줄임 가능. |
| 390×664 | 숫자 전체·9px 바·단계가 보임 | 단독 보스 판을 위로 옮겨 108px 전장 안에 수용. |
| 390×844 | A처럼 세 줄이 분리되고 숫자 하단이 온전히 보임 | 판 48px, 기존 HP 라벨 유지. 긴 보스 이름은 말줄임. |
| 430×932 | 동일한 붓·문턱·숫자 계층 | 기존 넓어진 전장·적 크기 유지. |
| 1280×800 | 중앙 430px 프레임에서 숫자·바 분리 | 원본 전체 크기 캡처를 보존하고 검토 시트에서는 중앙 프레임 확대. |
| 대상 선택·감소 모션 | 숫자·바·단계 판독 유지 | 안내문은 커진 이름표 아래로 조정. 감소 모션 자원 동작은 동일. |

**바뀐 전투 캡처만 {len(hp['captures'])}장** 재촬영했다. 5크기×일반/감소×기본/대상 20장, 360·390·1280의 4적/4적 대상 6장이다. 4적+390×664 조합은 이번 추가 캡처 범위에 포함하지 않는다. [캡처 목록·실측](verification/hp-r24/round2/results.json).

### 검사

- [전체 회귀와 수정 후 영향 검사](verification/hp-r24/round2/all-tests.json): **{len(rows)}/{len(expected)}그룹 통과, 실패 0·미실행 0**. import와 지정 회귀·기존 전체 검사·신규 이름표 검사 포함. 첫 전체 실행에서 r17/r18이 선택 영역 겹침을 발견했고, 보스 버튼의 상단을 작은 적 영역 하단에 맞춘 뒤 [r17~r20·HP를 재실행](verification/hp-r24/round2/touch-fix-tests.json)했다. [수정 전 실패 기록](verification/hp-r24/round2/touch-overlap-before.json)은 보존했으며 기존 기대값 변경은 없다.
- [이름표 검사](verification/hp-r24/round2/results.json): **{hp['checks']:,}항목·실패 0**. 숫자 행/바 분리, 판 내부 글꼴 행, 적 그림·이웃 판 비중첩, 전장 안 수용. 3크기×4개 적×이름표/스프라이트 **24곳에 실제 입력 이벤트**를 보내 선택 변경을 확인했다.
- [기존 HP 검사](verification/hp-r24/round2/hp-results.json): **{base['checks']}항목·실패 0**. 1차와 같은 자원/잔상/스냅샷 검사이며, 73회 PNG 저장 검사는 재촬영 금지에 맞춰 생략했다. 기존 602항목과의 차이는 이 73회다.
- [전투 대조](verification/hp-r24/round2/battle-parity.json): **6,320/6,320판·{parity['matched_actions']:,}행동 일치**. [원본 이미지](verification/hp-r24/round2/asset-check.json) **96/96 불변**.
- [로컬 serve.mjs 클라우드](verification/hp-r24/round2/cloud/results.json): **9그룹·실패 0**. 처음에는 길어진 임시 경로에서 SQLite 내부 오류가 났고, 기존 짧은 임시 경로로 재실행해 통과했다. Worker/서버 제품 코드 변경 없음. 1차와 같이 Windows root certificate store 환경 메시지만 별도로 분리했으며 SCRIPT ERROR 등 다른 오류는 실패로 판정했다.
- [수정 파일·해시](verification/hp-r24/round2/delivery-files.json), [제품 차이](verification/hp-r24/round2/product.diff), [임시 슬롯 정리](verification/hp-r24/round2/cleanup.json). 기본 runtime 보존, 임시 실행 슬롯 잔여 0. git·Web export·docs 쓰기 없음.

Web export 금지에 따라 새 브라우저 빌드는 실행하지 않았다. 지정 native viewport 렌더를 검토했으며 최종 시각 수용은 사용자 검토 사항이다. Impeccable detector는 `[]`; 기존 DESIGN.md/디자인 sidecar 동기화 경고는 이번 수정 범위에 포함하지 않았다. 필요하면 `impeccable document`로 별도 갱신할 수 있다.

---

## 1차 기록

'''
original=(O/'HP-R24.before.md').read_text(encoding='utf-8').split('\n',1)[1].lstrip()
(R/'HP-R24.md').write_text(header+original,encoding='utf-8')
print(f'HP round2: {len(rows)} groups, {hp["checks"]} plate checks, {len(hp["captures"])} captures, {parity["battles"]} battles, 96 assets')
