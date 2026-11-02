"""Build a conservative second-pass report from completed, row-scoped evidence."""
from pathlib import Path
import json,hashlib,re
root=Path(__file__).resolve().parents[1];out=root/'verification/parity-r23'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
base=read(out/'round1-gear.json');rows=base['rows']
promoted=set('P2836 P3683 P3697 P3698 P3699 P3700'.split())
fixed_new=set('P3549 P3552 P3553 P3554 P3683 P3697 P3698 P3699 P3700'.split())
fixed_this=fixed_new|{'P2836','P2841'}
groups={'P3683':'work_of','P3697':'work_note','P3698':'work_cut','P3699':'work_forge_note through work_note','P3700':'work_process_note / work_gear_label'}
reasons={
 'P2841':'새 상점 필드의 서버 저장은 해결. 접두 버튼 전체 메시지·pend_hard/addChat과 native 영수증의 계약 차이는 남음.',
 'P3549':'가방에 없는 장착 UID의 재장착/다른 소유자에게 이전을 원본처럼 거부하도록 수정. bag/self/other/duplicate·JSON 재개는 대조. 코드 기반 반환·dk_bag 쓰기와 native UID 선택/저장 매체는 다름.',
 'P3552':'JSON 재개 후 UID int/float 차이로 장착품이 가방에 중복 노출되던 wearer를 수정. 0/1999/2000 경계·해제·재개는 대조. 코드 기반 반환/채팅 변수와 native UID 저장은 다름.',
 'P3553':'재개 후 장착품을 미장착으로 오인하는 wearer를 수정. 판매·재시도·JSON 재개는 대조. 원본 코드 선택/반환·채팅 변수 쓰기와 native UID 저장은 다름.',
 'P3554':'재개 후 일반 장착품을 판매 대상으로 읽는 wearer를 수정. 0/1999/2000개 일괄판매·금화·가방·장착/재개는 대조. legacy 보존·코드↔UID 저장은 별도 계약.',
}
for row in rows:
 rid=row['id'];row['round2_previous_status']=row['new_status']
 if row['new_status']!='같음':
  row['round2_reviewed']=True
  evidence=['verification/parity-r23/round2-provenance.json']
  if rid in groups:evidence+=['project/tests/gear_r23_round2_test.gd::'+groups[rid]]
  elif rid in {'P3639','P3644','P3647','P3659'}:
   evidence+=['tools/gear_r23_predecessors.mjs','project/tests/gear_r23_predecessors_test.gd']
   row['remaining_reason']='선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.'
  elif rid in {'P3532','P3533','P3536','P3537','P3540','P3549','P3552','P3553','P3554','P3555'}:
   evidence+=['project/tests/gear_r23_round2_test.gd::source_transaction / native_transaction / native_transaction_resume','project/tests/gear_r23_test.gd::bag / migrate','verification/parity-r23/round2-oracle.json::bag_host']
  elif rid in {'P2836','P2841'}:evidence+=['server/abyss-save/test/gear-r23.mjs','verification/parity-r23/cloud-boundary.json','project/tests/gear_r23_test.gd::shop_bonus / shop_resume','project/tests/gear_r23_bonus_resume_test.gd']
  elif rid=='P2981':evidence+=['verification/parity-r23/round2-oracle.json::aff','project/tests/affection_r21_test.gd','project/tests/dialogue_player_r21_test.gd']
  else:evidence+=['verification/parity-r23/round2-oracle.json::screens / pct','project/tests/gear_r23_facilities_test.gd','project/tests/ui_facilities_r22_test.gd','project/tests/ui_gear_r23_test.gd']
  row['round2_evidence']=evidence;row['evidence_tests']+=evidence[1:]
 if rid in promoted:row['new_status']='같음';row['remaining_reason']=''
 elif rid in reasons:row['remaining_reason']=reasons[rid]
 if rid in fixed_new:row['fixed']=True
 if rid in groups:
  row['source_observation']='verification/parity-r23/round2-oracle.json'
  row['comparison_scope']='원본 local 함수 전체 반환과 실제 완료 영수증 source_note 연결. 부모 H.sm의 AI 전송 계약에는 판정을 전파하지 않음.'
 if rid in {'P3532','P3533'}:row['remaining_reason']+=' 2차 원본 실행에서 getChatVar 예외는 빈 목록, setChatVar 예외는 호출자 전파임을 관측. native에는 이 호스트 API가 없어 전체 일치는 아님.'
 if rid=='P2836':row['comparison_scope']='거래 전 호감·횟수·RNG·덤 99 상한·메시지·로컬 재개·실제 서버 저장 보존. 전체 상점 HTML/호스트에는 판정을 전파하지 않음.'
locations={'P3549':('project/game/facilities_world_r22.gd','func equip('),'P3552':('project/game/facilities_world_r22.gd','func wearer('),'P3553':('project/game/facilities_world_r22.gd','func wearer('),'P3554':('project/game/facilities_world_r22.gd','func wearer('),'P3683':('project/game/smithy_rules_r22.gd','func work_of('),'P3697':('project/game/smithy_rules_r22.gd','func work_note('),'P3698':('project/game/smithy_rules_r22.gd','func work_cut('),'P3699':('project/game/smithy_rules_r22.gd','func work_forge_note('),'P3700':('project/game/smithy_rules_r22.gd','func work_process_note(')}
for row in rows:
 if row['id'] in locations:
  file,needle=locations[row['id']];line=next(i for i,s in enumerate((root/file).read_text(encoding='utf-8').splitlines(),1)if s.startswith(needle));row['fix_location']=f'{file}:{line}'
suite=read(out/'suite/results.json')
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
assert len(suite)==1+sum(p.stem.endswith('_test') or p.stem in extras for p in (root/'project/tests').glob('*.gd'))
assert all(r['passed'] for r in suite),[r['test'] for r in suite if not r['passed']]
targets=[read(out/p) for p in ['results.json','hooks-results.json','facility-results.json','ui-results.json','round2-results.json','predecessors-results.json','bonus-results.json']]
assert all(not v['failures'] for v in targets)
server=read(out/'server-results.json');assert not server['failures']
npmlog=(out/'npm-test.log').read_text(encoding='utf-8');assert 'GEAR R23 SERVER '+json.dumps({'checks':server['checks'],'failures':0,'cases':server['cases']},separators=(',',':')) in npmlog
npm_checks=sum(map(int,re.findall(r'(?:CHECKS |"checks":)(\d+)',npmlog)))
parity=[]
for label,file in [('P2','p2-full-battles.json'),('A6','a6-mixed-audit.json'),('P3','p3-mixed-audit.json'),('A7','a7-gear-audit.json'),('A7 balanced','a7-gear-balanced-audit.json'),('A8','a8-audit.json'),('A9 native10','a9-native-10-audit.json'),('A9 native40','a9-native-40-audit.json')]:
 d=read(root/'verification/data-r21'/file);parity.append({'name':label,'battles':d['battles'],'same_battles':d.get('equal_battles',d['battles'] if d.get('different_actions')==0 else 0),'source_actions':d.get('source_actions',d.get('compared_actions')),'actual_actions':d.get('actual_actions',d.get('compared_actions')),'matched_actions':d['matched_actions']})
assert all(p['battles']==p['same_battles'] and p['source_actions']==p['actual_actions']==p['matched_actions'] for p in parity)
changed=[n for n,sha in read(out/'initial-files.json').items() if not (root/n).exists() or hashlib.sha256((root/n).read_bytes()).hexdigest()!=sha]
allowed_game={'project/game/gear_rules_r22.gd','project/game/gear_save_r22.gd','project/game/smithy_rules_r22.gd','project/game/guild_rules_r22.gd','project/game/town_rules_r21.gd','project/game/town_world_r21.gd','project/game/facilities_world_r22.gd'}
allowed_server={'server/abyss-save/src/validate.js','server/abyss-save/package.json','server/abyss-save/test/gear-r23.mjs'}
protected=[p for p in changed if p.startswith(('docs/','project/assets/','project/data/')) or p.startswith('server/') and p not in allowed_server or p.startswith('project/game/') and p not in allowed_game or p.startswith('project/ui/') and p not in {'project/ui/town_screen_r21.gd','project/ui/facilities_screen_r22.gd'}];assert not protected,protected
same=[r for r in rows if r['new_status']=='같음'];remaining=[r for r in rows if r['new_status']!='같음'];assert all(r['remaining_reason'] for r in remaining)
summary={'assigned':len(rows),'round2_reviewed':sum(r.get('round2_reviewed',False) for r in rows),'round2_promoted_same':len(promoted),'round2_fixed_rows':len(fixed_this),'round2_new_fixed_rows':len(fixed_new),'promoted_same':len(same),'fixed_rows':sum(r['fixed'] for r in rows),'fixed_same':sum(r['fixed'] for r in same),'fixed_remaining':sum(r['fixed'] for r in remaining),'remaining':len(remaining),'suite_groups':len(suite),'suite_failed':0,'suite_failed_assertions':0,'new_checks':sum(v['checks'] for v in targets),'new_failures':0,'round2_checks':sum(t['checks'] for t in targets[4:]),'npm_checks':npm_checks,'npm_failures':0,'server_added_checks':server['checks'],'battle_count':sum(v['battles'] for v in parity),'equal_battles':sum(v['same_battles'] for v in parity),'matched_actions':sum(v['matched_actions'] for v in parity),'parity':parity,'changed_existing_files':changed,'protected_changes':protected,'cloud_boundary':read(out/'cloud-boundary.json')}
(out/'gear.json').write_text(json.dumps({'summary':summary,'baseline':base['baseline'],'round1_snapshot':'verification/parity-r23/round1-gear.json','rows':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
table='\n'.join(f"|{r['id']}|{r['previous_status']} → {r['new_status']}|{'수정' if r['fixed'] else '대조'}|{r['remaining_reason'] or r['evidence_tests'][-1]}|" for r in rows)
report=f'''# R23-gear — 2차 장비·시설 함수 대조

남은 **46행 전부 재검토**, 이번 같음 승격 **6행**, 수정 **11행**(새 수정 표기 9행·기존 수정행 추가 해결 2행). 누적 **77행 중 같음 {len(same)}행·수정 {summary['fixed_rows']}행·남음 {len(remaining)}행**. 수정 수는 상태와 겹친다. 부모 검사 통과를 자식 함수의 같음 근거로 쓰지 않았다.

전체 Godot **{len(suite)}그룹 / 실패 0**, 서버 `npm test` **{npm_checks:,}항목 / 실패 0**. R23 직접 대조 **{summary['new_checks']:,}항목 / 실패 0**(이번 추가 {summary['round2_checks']:,}, 서버 신규 {server['checks']} 별도). 전투 **{summary['equal_battles']:,}/{summary['battle_count']:,}판**, 행동 기록 **{summary['matched_actions']:,}개** 일치. 전체 검사 실패 0을 달성했으나 기능 대조표의 남은 40행까지 완료한 것은 아니다.

- 행별 원본 위치·이전 판정·근거·남은 이유: [gear.json](verification/parity-r23/gear.json). [1차 상태](verification/parity-r23/round1-gear.json)와 [1차 보고](verification/parity-r23/round1-report.md)는 보존했다.
- 전체 명령·결과: [suite/results.json](verification/parity-r23/suite/results.json), [npm-test.log](verification/parity-r23/npm-test.log), [검사 러너](tools/gear_r23_verify.py).
- 원본 직접 실행: 기존 세 oracle 및 [round2](tools/gear_r23_round2.mjs), [선행 콜백](tools/gear_r23_predecessors.mjs). 원본 파일을 수정하지 않고 Wasmoon/lua_sim에서 실행했다. work_of/pct/work_note/cut에는 관찰용 export만 붙였다.

## 이번 수정

서버는 최신 지시서의 예외대로 `validate.js`에서 **items.charm_potion**(선택 정수 0~99), **commerce_r21.pietro_buys**(선택 정수 0~MAX_SAFE_INTEGER)만 허용했다. 옛 저장은 필드 없이 통과한다. 임의 아이템/commerce 키, 객체·문자열·소수·음수·범위 초과·비유한 수, 잘못된 장비 참조를 거부한다. 다른 위치의 아이템 허용 목록과 보안 로직은 변경하지 않았다. package.json에는 신규 시험 실행만 연결했다.

실제 상점 저장을 변경 없이 POST·PUT·GET하고 변조 거절 뒤 내용·revision 보존을 확인했다. **{server['cases']} HTTP 사례·{server['checks']}단언** 통과. [수정 전](verification/parity-r23/cloud-boundary-before-round2.json)의 두 거부 경로가 [수정 후](verification/parity-r23/cloud-boundary.json) 모두 통과한다. 실제 사용자 저장은 제거·덮어쓰지 않았다. 덤을 보유한 실제 native 전투/재개 저장도 서버에 왕복했다. 비전투 보너스가 전투 inventory로 섞이는 실패 2단언을 재현해 시설 facade의 최소 연결로 분리하고 record_battle 때 계정 수량을 보존했다. 전투·원정 파일과 서버 전투 허용 목록은 수정하지 않았다.

JSON 재개 후 UID가 float가 되면 기존 Array.has(int)가 장착 참조를 찾지 못해 가방/판매 대상에 장착품이 섞이는 문제를 찾았다. 허용된 facilities_world_r22에서 wearer를 숫자 비교로 고쳤다. 가방에 없는 장착 UID의 재장착·다른 소유자에게 이전도 원본처럼 거부한다. **38개 원본 거래 fixture**에서 가방·장착·금화·재시도·실제 JSON 재개, 0/1999/2000 한도·중복 코드를 대조했다. UID·legacy RNG·overflow·시제품 보관 이관은 유지했다.

대장간 work_of/work_note/cut/제련·가공 콜백을 이식해 실제 완료 영수증 source_note에 연결했다. 원본 **1,030종 전부**, 성공/실패·0/1/10 단계, 빈 목록·1/7/8/9/20개·혼합 작업·알 수 없는 코드를 비교했다. work_of는 입력 표 정체성을 유지한다. 전체 영수증은 보존하고 영어 요약에만 원본의 8개 제한을 적용한다. 이 반환 일치를 부모 H.sm의 AI 전송 완료로 확대하지 않았다.

네 선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 실제 원본 래퍼에서 호출했다. **24경계·72단언**에서 이후 native 장비 효과/호출 순서를 대조했다. native는 기록한 선행 콜백 직후 상태부터 실행하므로 임의 GH 콜백 ABI 전체를 검증한 것은 아니다.

수정 전 증거는 [round2-before.log](verification/parity-r23/round2-before.log)와 보존된 1차 결과에 있다. 빈 Lua 표의 JSON 배열 정규화·시험용 일괄판매 호출명 수정은 제품 결함 수에 넣지 않았다. 원본 수치/기대값을 바꿔 맞추지 않았다.

## 남은 차이와 검사 환경

남은 40행의 이유는 아래 표에 기록했다. dk_bag 채팅 변수와 UID 전체 JSON 저장, HTML 반환과 native 화면, AI pending/addChat/보내기와 고정 대화·영수증의 계약 차이가 남는다. 알 수 없는 cid의 G.aff/chron_aff 부작용도 native 보유 동료 제한과 다르다. 일반 %g 정밀도/지수 표기, 영입 역순 목록·최근 만남/대기 안내도 미완료다. 한국어/영어·0/1/30인 원본 화면 24개, 호스트 예외/호감 콜백을 round2-oracle.json에 보존했으며 원본 관찰만으로 native 같음을 세지 않았다.

직접 연 화면은 [shop-bonus-390x844.png](verification/parity-r23/render/shop-bonus-390x844.png): 덤 이름·보유 수와 구입 버튼 부재를 확인했다. 다른 회귀 이미지를 모두 직접 열었다고 주장하지 않는다.

지정 test/serve.mjs를 18787에 격리해 클라우드 시험을 실행했다. 기존 r21-d-town 의존성은 읽기만 했으며 npm용 모듈은 자기 worktree의 node_modules에 복사했다. TEMP/TMP/TMPDIR도 자기 worktree 안이다. npm 첫 실행은 로컬 wrangler 모듈 부재로 중단되어 복사 후 전체를 재실행했다. 검사 후 자신이 띄운 서버를 종료했다. Windows 인증서 저장소 진단은 기존 러너와 같은 환경 예외이며 assertion/script 오류는 제외하지 않았다.

변경한 기존 파일: [summary.json](verification/parity-r23/summary.json). 금지된 기존 파일 변경 **{len(protected)}개**. 원본 자산 **96/96개 해시 유지**([직접 검사](verification/parity-r23/asset-hashes-round2.json)). Web export·docs·전투·원정·대사 데이터·원본 초상/픽셀을 수정하지 않았고 Git 명령/커밋을 실행하지 않았다.

## 행별 결과

|행|최초 → 현재|처리|근거 또는 남은 이유|
|---|---|---|---|
{table}
'''
(root/'R23-gear.md').write_text(report,encoding='utf-8')
print(json.dumps({k:summary[k] for k in ['assigned','round2_promoted_same','promoted_same','fixed_rows','remaining','suite_groups','suite_failed','new_checks','new_failures','npm_checks','battle_count','equal_battles']},ensure_ascii=True))
