"""Preserve the previous 90 completed rows; attach current evidence to all 54 others."""
from pathlib import Path
from collections import Counter
import json,hashlib,re
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23/ui-phase4'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def loc(file,needle):
    return file+':'+str(next(i for i,s in enumerate((R/file).read_text(encoding='utf-8').splitlines(),1) if needle in s))
base=read(O/'ui-before.json');rows=base['rows'];done={'같음','대체','제외'}
same=set('P0089 P0090 P0091 P0092 P0095 P2370 P2496 P2500 P2501 P2521 P2523 P2563 P2565 P2578 P2586 P2592 P2630 P2631 P3721'.split())
fixed=same|set('P2528 P2534 P2537 P2539 P2593 P2606 P2629 P2637'.split())
results={n:read(O/('ui-'+n+'-results.json')) for n in ['rule','native','screen','codex','detail','status','edge','visual']}
assert all(not d['failures'] for d in results.values()),{n:d['failures'][:2] for n,d in results.items() if d['failures']}
reg=read(O/'ui-regression.json');servers=read(O/'server/ui-results.json')
audits=['combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration','balance_probe']+audits}
missing=expected-{x['test'] for x in reg};assert not missing,sorted(missing)
assert all(d['passed'] for d in reg) and len(servers)==9 and all(d['exit']==0 for d in servers)
combat=[]
for n in audits:
    row=next(x for x in reg if x['test']==n);summary=' '.join(row['summary']);m=re.search(r'(?:parity|battles) (\d+)',summary);assert m,(n,summary)
    combat.append({'test':n,'battles':int(m[1]),'passed':True,'summary':summary})
assert sum(x['battles'] for x in combat)==6320
oracle=read(O/'ui-oracle.json');screens=read(O/'ui-screens-oracle.json');edges=read(O/'ui-edges-oracle.json')
counts=Counter(c['fn'] for c in oracle['cases'])
anchors={
 **{k:('project/game/localization_r22.gd','static func '+v) for k,v in {'P0089':'ui_pack','P0090':'u(','P0091':'u(','P0092':'en_dict','P0095':'t(','P2370':'c1_en'}.items()},
 'P2496':('project/ui/portrait_rules_r22.gd','func configure'), 'P3721':('project/ui/portrait_rules_r22.gd','static func resolve'),
 'P2500':('project/game/ui_semantics_r23.gd','static func notice'), 'P2501':('project/game/ui_semantics_r23.gd','static func item_name'),
 'P2521':('project/ui/codex_screen_r22.gd','for cid in page.items'), 'P2523':('project/ui/codex_screen_r22.gd','func build'),
 'P2563':('project/ui/panel_screen_r22.gd','func favorite_card'), 'P2565':('project/ui/status_screen_r22.gd','func build'),
 'P2578':('project/ui/inventory_screen_r22.gd','func build'), 'P2586':('project/ui/inventory_screen_r22.gd','func detail'),
 'P2592':('project/ui/inventory_screen_r22.gd','if state.bg.sel!'), 'P2630':('project/ui/settings_screen_r22.gd','for i in range(3)'),
 'P2631':('project/game/ui_semantics_r23.gd','static func settings_note'),
 'P2528':('project/ui/codex_screen_r22.gd','for slot in R.DATA.slots'), 'P2534':('project/ui/codex_screen_r22.gd','func detail'),
 'P2537':('project/ui/codex_screen_r22.gd','if id=="persona"'), 'P2539':('project/game/panels_state_r22.gd','func unequip'),
 'P2593':('project/game/panels_state_r22.gd','elif arg.begins_with("eq_")'), 'P2606':('project/ui/panel_screen_r22.gd','if e[0]=="inventory"'),
 'P2629':('project/ui/settings_screen_r22.gd','func build'), 'P2637':('project/ui/settings_screen_r22.gd','func apply')}
tests={
 **{k:['ui_phase4_r23_test'] for k in same},
 'P2521':['ui_phase4_native_r23_test','ui_phase4_codex_r23_test'], 'P2523':['ui_phase4_codex_r23_test','ui_phase4_native_r23_test'],
 'P2563':['ui_phase4_native_r23_test','ui_phase4_status_r23_test'], 'P2565':['ui_phase4_status_r23_test'],
 **{k:['ui_phase4_screens_r23_test','ui_phase4_edges_r23_test'] for k in ['P2578','P2586','P2592']},
 'P2630':['ui_phase4_screens_r23_test'], 'P2631':['ui_phase4_screens_r23_test'],
 'P2528':['ui_phase4_edges_r23_test','ui_phase4_detail_r23_test'], 'P2534':['ui_phase4_detail_r23_test'],
 'P2537':['ui_phase4_detail_r23_test','ui_phase4_codex_r23_test'], 'P2539':['ui_phase4_edges_r23_test'],
 'P2593':['ui_phase4_edges_r23_test'], 'P2606':['ui_phase4_native_r23_test','ui_phase4_status_r23_test'],
 'P2629':['ui_phase4_screens_r23_test','ui_phase4_visual_r23_test'], 'P2637':['ui_phase4_visual_r23_test']}
reasons={
 'P2528':'표시 순서·장비 해제의 빈 칸/1999/2000칸·중복 코드 장착·저장 재개는 새 대조 통과. 실제 전투에서 도감 패널을 여는 전체 경로는 world_screen.gd/전투 파일 동결로 연결하지 못했다. 원본의 옛 아이템 문자열이 든 장착 저장을 UID 모델로 옮기는 전체 경로는 gear_*·persona_world 동결 범위다.',
 'P2534':'30명×한영의 전체 공개 상세 정보/문구/순서/막대, 실제 원본 특성 아이콘 4개와 여우/늑대/표범 계통 패시브까지 직접 대조 통과. 장착·해제와 옛 장착 저장 및 실제 전투 진입의 복합 경계 P2528이 남아 전체 승격은 보류.',
 'P2537':'목록·미영입·전체 동료 상세와 페르소나에서 불필요한 패시브를 보이는 차이는 보완했다. 전체 패널은 P2528/P2534의 옛 저장·전투 연결 경계를 상속한다. 동결 대상 world_screen.gd/gear_*/persona_world.',
 'P2539':'새 8개 실제 상태 대조에서 2000칸 교환, 1999/2000칸 해제, 중복 코드·장착 UID·저장 재개와 오류 알림은 일치. 원본 버튼 코드→native UID의 잘못된 코드/옛 장착 입력 및 실제 전투 라우터를 잇는 전체 관찰은 동결 world_screen.gd/gear_* 경계로 남긴다.',
 'P2593':'판매된 선택의 판매/장착, 중복 장비, 가방 2000칸 교환 및 저장 재개는 실제 native 어댑터와 직접 일치. 전투 중 남은 버튼 요청을 공통 라우터에서 거절하는 전체 경로 및 옛 장착 저장 입력은 world_screen.gd/gear_* 동결 범위라 함수 전체는 일부 유지.',
 'P2606':'평시 persona/즐겨찾기와 가방 표시, 전투 상태를 가진 패널 구성요소에서 가방 진입 숨김은 검사했다. 실제 전투 화면은 world_screen.gd가 먼저 전투로 강제 전환하며, source st_unit/st_battle의 동작·탭·복귀를 잇는 전투 파일은 동결이다.',
 'P2629':'공개 선택지 32개 상태의 레이블/선택·설명, 초기화 확인 중 나머지 설정 유지, 클라우드 대체 화면 진입을 검사했다. 전체 초기화 뒤 원본 G_new 관찰은 P2637에 남고, 별도 계정 화면의 복귀/전체 합성은 동결 cloud_screen_r22.gd·world_screen.gd를 포함한다.',
 'P2637':'실제 포인터로 난이도 변경 시 초기화 확인 해제 및 저장/재개 경로를 보완했다. 초기화 후 전체 초기 관찰(난수·진행·장비·동료)의 원본 G_new 투영은 persona_world/gear_*/town_world 동결 경계라 보류.'}
review=[]
for r in rows:
    if r['status'] in done:continue
    before=r['status'];r['phase4_previous_status']=before
    if r['id'] in same:r['status']='같음';r['remaining_reason']='';r['unverified_branches']=[]
    elif r['id'] in reasons:r['remaining_reason']=reasons[r['id']]
    else:
        protected=('create_screen.gd·persona_rules' if r['id'].startswith('P24') else
                   'town_screen_r21.gd·world_screen.gd' if r['id'] in ['P0105','P2617'] else
                   'world_screen.gd' if r['id'] in ['P0131','P0133'] else
                   'world_screen.gd·battle_screen.gd·전투 규칙' if r['id'] in ['P2567','P2568'] else
                   'persona_world.gd·town_world_r21.gd·gear_*')
        r['remaining_reason']=r.get('remaining_reason','')+' 4차: 해당 전체 화면/초기 상태 연결은 이번 동결 대상 '+protected+'에 의존하므로 파일을 바꾸지 않았다.'
    if r['id'] in fixed:
        file=loc(*anchors[r['id']]);r['phase4_modified']={'file':file,'scope':'source-backed public presentation / adapter edge; no protected rule edits'}
        r['new_evidence'].append({'phase':4,'tests':['project/tests/'+n+'.gd' for n in tests[r['id']]],'implementation':file,'artifacts':['verification/parity-r23/ui-phase4/ui-oracle.json','verification/parity-r23/ui-phase4/ui-screens-oracle.json','verification/parity-r23/ui-phase4/ui-edges-oracle.json']})
    review.append({'id':r['id'],'feature':r['feature'],'source':r['source'],'prior_reason':r.get('prior_reason'),'before':before,'after':r['status'],'tests':tests.get(r['id'],[]),'remaining_reason':r['remaining_reason']})
assert len(review)==54 and len(same)==19
old={r['id']:r for r in read(O/'ui-before.json')['rows'] if r['status'] in done}
assert all(r==old[r['id']] for r in rows if r['id'] in old)
original=read(R.parent/'r21-parity/verification/parity-r21/audit-r22b.json')
items={i['id']:i for group in original['remaining_work'] for i in group['items']}
write(O/'ui-original-work-items.json',[items[r['id']] for r in rows if r['id'] in items])
write(O/'ui-row-review.json',review)
protected=[]
for a in read(R/'ASSET-HASHES.json'):
    actual=hashlib.sha256((R/a['path']).read_bytes()).hexdigest();assert actual==a['sha256'];protected.append(a['path'])
for source in oracle['sources']:assert hashlib.sha256((Path('C:/Clauede Code/dungeon-bot/bot/src')/source['file']).read_bytes()).hexdigest()==source['sha256']
before=read(O/'ui-hashes-before.json');changed=[];new=[]
for folder in ['project','tools','server','docs']:
    for p in (R/folder).rglob('*'):
        if not p.is_file() or any(s in p.parts for s in ['.godot','node_modules','__pycache__']):continue
        name=p.relative_to(R).as_posix();digest=hashlib.sha256(p.read_bytes()).hexdigest()
        if name not in before:new.append(name)
        elif digest!=before[name]:changed.append(name)
for name in changed+new:
    assert not name.startswith(('server/','docs/')),name
    if name.startswith('project/game/'):assert Path(name).name in ['localization_r22.gd','ui_semantics_r23.gd','panels_state_r22.gd'],name
    if name.startswith('project/ui/'):assert Path(name).name in ['panel_screen_r22.gd','status_screen_r22.gd','codex_screen_r22.gd','inventory_screen_r22.gd','settings_screen_r22.gd','portrait_rules_r22.gd'],name
files=[p for p in O.rglob('*') if p.is_file()];assert all(p.name.startswith('ui-') for p in files),[str(p) for p in files if not p.name.startswith('ui-')]
assert all(p.stat().st_size<=40*1024*1024 for p in files)
write(O/'ui-write-audit.json',{'changed':changed,'new':new,'protected_assets':len(protected),'changed_protected_assets':[],'source_rules_server_docs_changes':[],'new_comparison_bytes':sum(p.stat().st_size for p in files),'largest_comparison_bytes':max(p.stat().st_size for p in files)})
write(O/'ui-suite-coverage.json',{'expected':len(expected),'executed':len(reg),'missing':sorted(missing),'failed':[r['test'] for r in reg if not r['passed']],'combat':combat,'server_groups':len(servers)})
summary=base['summary'];statuses=Counter(r['status'] for r in rows);cumulative_fixed=[r for r in rows if r.get('modified') or r.get('phase4_modified')]
native=sum(results[n]['checks'] for n in ['native','screen','codex','detail','status','visual']);rule=results['rule']['checks']+results['edge']['checks'];captures=sum(len(v.get('captures',[])) for v in results.values())
summary.update({'promoted_same':statuses['같음'],'replaced_rows':statuses['대체'],'excluded_rows':statuses['제외'],'remaining_rows':sum(v for k,v in statuses.items() if k not in done),'remaining_counts':{k:v for k,v in statuses.items() if k not in done},'fixed_rows':len(cumulative_fixed),'fixed_and_promoted':sum(r['status']=='같음' for r in cumulative_fixed),'fixed_remaining_partial':sum(r['status'] not in done for r in cumulative_fixed),'project_groups':len(reg),'project_failed_groups':0,'server_groups':9,'server_failed_groups':0,'rule_checks':summary['rule_checks']+rule,'native_ui_checks':summary['native_ui_checks']+native,'native_ui_captures':summary['native_ui_captures']+captures})
summary['phase4']={'reviewed_rows':54,'promoted_same':19,'fixed_rows':len(fixed),'remaining_rows':summary['remaining_rows'],'new_rule_checks':rule,'new_native_checks':native,'captures':captures,'full_project_groups':len(reg),'server_groups':9,'combat_battles':6320,'original_trait_icons':len(read(O/'ui-trait-assets.json'))}
base['method']+=' Phase 4 preserves all 90 previously completed rows. Public source U and T dictionaries are separate from native-only render strings. Adult translation keys are inventoried but not shipped in the source pack. Composite functions with frozen old-save/battle/creation dependencies remain partial.'
write(R/'verification/parity-r23/ui.json',base);write(O/'ui-summary.json',summary['phase4'])
report=f'''# R23-ui · 4차 기능 등가 대조

남은 54행 전부 검토: **같음 +19 · 수정/보완 {len(fixed)}행(같음과 중복) · 남음 {summary['remaining_rows']}행**.
누적 **같음 {statuses['같음']}/144 · 대체 {statuses['대체']} · 제외 {statuses['제외']} · 남음 {summary['remaining_rows']}**. 기존 완료 90행의 JSON 객체는 그대로 보존했다.

행 id·원본 위치·기존 판정 사유·이전 상태·새 시험·남은 이유: [ui.json](verification/parity-r23/ui.json). 이번 54행만: [ui-row-review.json](verification/parity-r23/ui-phase4/ui-row-review.json). 원본 재감사의 작업 items도 ui-original-work-items.json에 보존했다.

## 고친 내용

- 원본의 공개 UI 사전 {len(oracle['packs']['ui'])}키와 데이터 번역 사전 {len(oracle['packs']['words'])}키를 별도로 싣고, 전체 집합 및 한영 lookup/변수 치환을 실제 Lua와 대조했다. native 전용 번역·일반 render와 U/T 계약을 분리해 같은 한국어가 메뉴 동작과 능력치 이름에서 다르게 번역되는 경우를 바로잡았다. 성인 키 {sum(map(len,oracle['excluded'].values()))}개는 목록만 남겼다.
- 도감의 페르소나 버튼 순서·호감 막대·즐겨찾기 표식, 즐겨찾기 카드의 속성·호감 문구·HP/MP·순서를 맞췄다. Godot ProgressBar의 기본 간격이 99/200을 0.500으로 만들던 실제 차이를 0.495로 고쳤다.
- 전체 30명×한영 상세의 태그·스킬·직업/종족/출신 패시브·계통 표시를 직접 대조했다. 여우/늑대는 개과, 표범은 고양이과라는 정본의 표시 분류를 적용했다. 정본에 실제 존재하는 특성 아이콘 4개를 새 경로로 바이트 그대로 복사했다. 다른 26개는 새로 지어내지 않았다.
- 가방 90개 목록 상태와 상세 212개 상태를 대조했다. 없는 비교 효과의 `-`, 강화 표지·직업/부위·고유 효과·판매 확인 순서, 빈 비교 대상·여러 비교 대상·없는 장착 대상·모든 등급/직업·레벨 1/40을 확인했다. 사라진 선택은 원본처럼 목록으로 돌아가며 재개 뒤에도 정리가 유지된다.
- 2,000칸 가방의 장비 교환, 1,999/2,000칸 해제, 중복 코드 수량, 이미 팔린 장비의 판매/장착, UID 장착 및 재개를 실제 native 어댑터로 비교했다. 빈 장비 해제 오류와 불필요한 성공 알림, 판매 후 선택 정리, 판매된 장비 장착 오류를 고쳤다.
- 설정의 언어/난이도/연대기 32개 상태와 원본 레이블/선택/공개 설명을 비교했다. 확인 중에도 설정이 남고 난이도 변경으로 초기화 확인이 닫힌다. 설정에서 기존 클라우드 대체 계정 화면으로 들어갈 수 있게 연결했다. 채팅/AI host 설명은 공통 제외 기준에 따라 공개 기능 설명만 남겼다.

## 직접 실행 결과

|검사|결과|
|---|---:|
|새 Lua/native 규칙·이름·사전·초상·저장 경계|{rule:,} / 실패 0|
|새 실제 UI·포인터·레이아웃|{native:,} / 실패 0|
|새 캡처|{captures}장 / 360×780·390×844·430×932 × 한영|
|현재 프로젝트 import·전체 시험·trace|{len(reg)}종 / 실패 0 / 누락 0|
|실제 로컬 Worker/D1 package 시험|9종 / 실패 0|
|전투 대조|6,320 / 6,320판 일치|
|보호 원본 자산|96개 / 변경 0|

전체 결과는 ui-regression.json, ui-suite-coverage.json, server/ui-results.json에 있다. 서버는 기존 serve.mjs를 메모리 포트 어댑터로 실행해 기존 리스너와 충돌하지 않게 했다. 의존성은 다른 작업 공간의 기존 설치를 읽기만 하고, wrangler 해석도 런타임 모듈 hook으로 연결했다. 서버 디스크 수정/원격 배포는 없다. Windows 인증서 저장소 진단은 분리 기록했으며 SCRIPT ERROR나 검사 실패를 제외하지 않았다.

수정 전 표시 대조 실패 308건은 ui-native-baseline.log에 남겼다. 사전은 보존한 이전 데이터를 주입하는 ui-dictionary-baseline.json으로 재현한다. 상세/설정/장비 경계의 수정 전 로그도 별도 ui- 접두 파일에 있다. 최초 실험 중 import 미완료, Lua 빈 table의 배열 표현, 필수 장착 맵을 지운 fixture, 반복 parser 생성, 강제 전투 전환을 탄 fixture는 바로잡았다. 성인 설정을 끈 공개 fixture로 대조하며 성인 장면은 이식하지 않았다.

기존 settings_r22_test는 사전 순회 계약을 보완했다. 원본 실행 사전에 없는 native 시나리오 19개를 B.T 번역으로 기대하던 검사를 원본 U/T fallback 검사와 native render의 기존 영어값 보존 검사로 나눴다. 영어 번역 값은 바꾸지 않았다. 기존 207,781검사의 19실패는 ui-settings-dictionary-before.log에 보존했다. 최종 공개 사전 검사는 ui-regression.json의 settings_r22_test에 체크 수와 실패 0을 기록한다. 수치·난수·전투 기대값은 변경 0이다. 성인 전용 intimacy 사전은 공개 번역 파일과 공유하는 키만 남기고 이식 대상에서 제외했다.

## 남은 {summary['remaining_rows']}행

생성 화면·시나리오·초기 상태·전체 저장 이관·전투/마을 HUD와 연결된 행은 이번 수정 금지 범위다. 허용 상세/가방 표시를 고쳤어도 옛 문자열 장착 저장이나 실제 전투 진입의 전체 관찰이 남은 복합 함수는 같이 승격하지 않았다. 각 행의 구체적인 사유와 파일은 ui-row-review.json에 있다. HTML 태그나 저장 매체가 다르다는 이유만으로 남긴 행은 없다.

주요 남은 의존성: create_screen.gd, persona_*, world_screen.gd, town_screen_r21.gd/town_world_r21.gd, gear_*, 전투 파일, cloud_screen_r22.gd. 이 파일·서버·docs는 변경 0이다. git 명령과 Web export도 실행하지 않았다. [ui-write-audit.json](verification/parity-r23/ui-phase4/ui-write-audit.json)에 변경 파일·자산 hash·대조 파일 크기를 기록했다.

새 영문 번역으로 드러난 대화창 호감 라벨 1,440건의 넘침은 localization의 글자 맞춤 함수에서 원래 슬롯 폭을 기준으로 계산해 고쳤다. 생성 직후 Label 폭이 162로 잠시 늘었다가 원래 148로 돌아오는 상태를 기존 metrics로 처리하며, 마을 파일은 변경하지 않았다. 수정 전은 ui-dialogue-overflow-before.log에 보존했다.

화면 직접 검수는 ui-visual-review.json에 기록한다. 새 {captures}장만을 대상으로 하며 기존 회귀 검사 캡처 전체를 열었다는 뜻은 아니다. 영문 모드의 공통 HUD/뒤로 등 일부 원본 fallback은 남아 있고 해당 전역 화면은 동결 범위다. 디자인 기계 검사는 변경 화면 6개에서 0건. 기존 DESIGN.md와 .impeccable/design.json의 시차는 수정하지 않았으며 별도 `document`로 갱신할 수 있다.

재현: node tools/ui_r23_phase4_screens_oracle.mjs → node tools/ui_r23_phase4_edges_oracle.mjs → python tools/ui_r23_phase4_data.py → python tools/ui_r23_phase4_verify.py → python tools/ui_r23_phase4_server_tests.py → python tools/ui_r23_phase4_report.py.
'''
(R/'R23-ui.md').write_text(report,encoding='utf-8');print(json.dumps(summary['phase4'],ensure_ascii=False))
