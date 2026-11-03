"""Append the fifth-pass evidence. Previously equal rows are immutable."""
from pathlib import Path
import json,hashlib,collections
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
previous=read(O/'expe-pass5-start-ledger.json');ledger=read(O/'expe-pass5-start-ledger.json');start=read(O/'expe-pass5-start.json')
S=O/'expe-pass5-suite-final';whole=sorted([read(p)for p in (S/'rows').glob('*.json')],key=lambda r:r['test'])
assert len(whole)==118
assert {r['test']for r in whole if not r['passed']}=={'ui_town_r21_round10_test','ui_town_r21_round11_test'}
T=O/'expe-pass5-ui-correction';reruns=[read(p)for p in (T/'rows').glob('*.json')]
required={'ui_town_r21_round10_test','ui_town_r21_round11_test','ui_expe_pass5_r23_test','ui_expedition_r22_test','ui_expe_pass2_r23_test','ui_persona_r22_test'}
assert {r['test']for r in reruns}==required and all(r['passed']for r in reruns),'All affected screen checks must pass'
latest={r['test']:{**r,'evidence_run':S.name}for r in whole}
latest.update({r['test']:{**r,'evidence_run':T.name}for r in reruns});suite=sorted(latest.values(),key=lambda r:r['test'])
assert all(r['passed']for r in suite)
assert read(S/'code-lock-result.json')['changed']==[]
lock=read(O/'expe-pass5-code-lock.json');after_lock=[p for p,h in lock.items()if digest(R/p)!=h]
assert after_lock==['project/ui/expedition_screen_r22.gd']
write(O/'expe-pass5-final-checks.json',{'whole_project_groups':len(whole),'initial_failed_groups':2,'correction':'Widen the original retreat subtitle to 354px, align right, preserve wording','changed_after_whole_suite':after_lock,'affected_screen_groups_rerun':sorted(required),'failed_groups':[],'checks':suite,'current_corrected_file_sha256':digest(R/after_lock[0])})
assert read(S/'server-result.json')['exit']==0
core=read(O/'expe-pass5-results.json');ui=read(O/'expe-pass5-ui-results.json');extra=read(O/'expe-pass5-extra-results.json');direct=read(O/'expe-pass5-ui-direct-results.json')
assert all(not r['failures']for r in [core,ui,extra,direct])
assert all(r['passed']for r in read(O/'expe-pass5-save-validation.json')['results'])
groups={
 'P2746':['town'],'P2749':['town_name'],'P2750':['town_party'],'P2751':['town_tags'],
 'P3003':['award'],'P3004':['award'],'P3026':['sortie_cards'],'P3028':['sortie_cards'],'P3031':['sortie_summary'],
 'P3120':['run'],'P3134':['names_nonsexual_scope'],'P3140':['start','step'],'P3159':['rest'],'P3168':['step'],'P3189':['boss_guard_host_excluded'],
 'P3273':['bar'],'P3274':['pips'],'P3275':['head'],'P3277':['last'],'P3278':['use_btn'],'P3280':['use_row'],'P3281':['party'],'P3282':['retreat'],
 'P3299':['done_act'],'P3303':['done'],'P3304':['done']}
remaining={
 'P2752':'초상 provider 실패/비 HTML 반환 때 번역된 이름 첫 글자를 쓰는 fallback을 native 초상 경로와 직접 대조하지 못했다. 알려진 동료 초상 보존만으로 전체 승격하지 않았다.',
 'P2753':'native 장소 제목의 아이콘·제목 조합을 원본 tw_hd의 각 인수와 연결한 직접 표시 시험이 없다. 기존 제목 그림만으로 전체 승격하지 않았다.',
 'P2754':'마을 시설 버튼은 일부 짧은 이름을 사용하고 원본의 설명 두 번째 줄을 모두 표시하지 않는다. 원본 장소 버튼의 표시 정보 차이가 남는다.',
 'P2755':'원본은 의뢰 별 수만큼 별을 반복한다. native의 던전 별 숫자 표시는 이 마을/의뢰 helper의 직접 대응 증거가 아니며, accepted quest 별 표시가 남는다.',
 'P2756':'hint의 임의 안내 문자열·빈 문자열을 실제 시설 카드에 연결한 직접 대조가 없다. 공통 paragraph의 존재만으로 전체 승격하지 않았다.',
 'P2757':'페르소나를 포함한 출전 이름 순서는 고쳤다. 마을 본문 설명·수락 의뢰 출정 타일·대던전 최고층 안내·시설 설명 줄이 원본과 아직 다르다. 장미 골목은 명시적 제외다.',
 'P2758':'마을 이동 handler의 ui.sel/tab 초기화, 잘못된 scene에서의 무반응, 의뢰 없음 메시지를 native facility_route/host.go와 함수 전체로 직접 비교하지 못했다. native 거래 영수증의 이동 차단도 별도 동작이다.',
 'P2784':'기존 정산 수치 검사는 유지했다. st.rg 우선/의뢰 보상 fallback, 엘리트 장비 입고, 아직 끝나지 않은 전투, 반복 정산, 원문 메시지까지 합친 native 의뢰 정산 대조는 미완료다.',
 'P2792':'전투 HUD의 bn/id/load 실패 및 탐색 승리 제외 조건, 원본 귀환/층 정산 label/subtitle을 native 결과 화면과 전체 대조하지 못했다. 전투 파일은 수정 금지다.',
 'P3016':'알려진 동료 초상은 보존했다. persona의 host 사용자 초상 및 portrait 실패 시 이름 첫 글자 fallback의 전체 분기 대조는 없다.',
 'P3017':'출정 준비에 원본 의뢰 카드의 제목·설명·별·종류·난이도·금화·적 레벨을 한 묶음으로 표시하는 대응이 남는다. 현재 수락 의뢰 출발 버튼만으로 같음은 아니다.',
 'P3018':'native는 전열/후열별 초상 배열을 쓴다. 원본 4개 슬롯의 순서·빈 칸 번호와 persona 슬롯을 눌러 지휘로 바꾸는 선택지는 아직 다르다.',
 'P3020':'참전/지휘 토글의 상태와 3/4명 상한은 기존 시험을 통과한다. persona 이름·원본 설명 문구·버튼 문구의 표시 대조는 아직 일부다.',
 'P3032':'후보 카드·필터·요약의 직접 표시 대조를 추가했다. 의뢰/대던전 모드 전환, 원본 의뢰 카드와 4개 슬롯, 전체 화면 버튼 종류·문구의 차이가 남는다.',
 'P3037':'B.battle_start가 없을 때 B.fresh(T.bn)로 여는 원본 옛 전투 생성 fallback은 native의 보존된 옛 저장 재개와 별개다. 원본 legacy 출정 상태를 직접 옮기는 ABI는 없다.',
 'P3041':'후보 토글/필터 입력은 실제 native 화면에서 확인했다. scene gate, rm_persona, 꽉 찬 편성/마지막 동료 대기 메시지, mode/back/go와 legacy 전투 시작 전체를 하나의 handler로 비교하지 못했다.',
 'P3079':'기존 층 정보 77건은 유지했다. 원본 층 목록의 잠김 설명·완료/추천 표식·쪽 수·보스/일반 전투 보상·4인 추천 안내를 native picker에 모두 표시하는 대응은 남는다.',
 'P3145':'첫 전투 자원과 탐색 전투 진입 투영은 기존 및 새 시험을 통과한다. 원본 st의 sid/bn/dn/carry 전체와 native 전투 snapshot의 전체 동등성은 아직 미확정이다. 전투 파일 수정 금지다.',
 'P3182':'탐색 승리 뒤 수치 투영은 유지했다. 원본의 적 이름 중복 제거 last/log 및 정예 장비 log, sid/bn/over/dn 불일치의 native continuation 전체 경계는 직접 일치시키지 못했다.',
 'P3195':'가방 포화 때 원본은 장비를 버리지만 native는 사용자 저장 보존을 위해 overflow에 남긴다. 이 실제 보존 정책 차이는 그대로이며 장비 규칙 수정 금지다.',
 'P3202':'보상과 요약 표시 대조를 보강했다. 패배 뒤 원본은 run을 없애고 마을로 가며 native는 완료 run과 정산 화면을 보관한다. 이 관찰 가능한 이동/저장 차이가 남는다.',
 'P3223':'원본 sid/bn 불일치 시 거점 복귀와 legacy 분기, native snapshot 검증을 통합한 정산 경계 대조가 미완료다. 단순 저장 매체 차이를 남은 이유로 쓰지 않는다.',
 'P3225':'옛 native 저장 재개는 회귀 통과한다. 원본 st.dn.stage 1/2 저장 자체를 읽어 정산하는 canonical legacy 입력 이관은 없다.',
 'P3249':'정상 휴식 장비 장착/해제는 유지했다. 원본 gear code 버튼 해독·잘못된 슬롯·다른 소유자 장비·거절 이유 문자열을 포괄하는 장비 규칙 직접 대조가 남는다. 장비 규칙 수정 금지다.',
 'P3251':'탐색·아이템·퇴각 요청/취소/확정은 직접 비교했다. cont/next/home, 잘못된 전투 상태와 모든 장비 버튼을 합친 전체 handler 경계는 아직 미확정이다.',
 'P3287':'head/last/party 및 퇴각 조각은 원본 실행과 일치했다. native는 ask 때 별도 확인 화면을 써 원본처럼 기존 head/party와 퇴각 안내를 한 화면에 함께 남기지 않는다. 추가 카드/보급품 이동도 전체 버튼 대조에 남는다.',
 'P3290':'휴식 화면은 별도 장비 정비 페이지를 쓴다. 원본의 슬롯별 장비 후보·해제·장착 버튼 종류와 순서를 같은 화면에서 직접 비교하지 못했다. 장비 규칙은 수정 금지다.',
 'P3293':'native 정비 대상 선택과 원본 R.sel의 잘못된 슬롯 정규화, 슬롯별 장비 후보의 완전한 일치가 남는다. 버튼 문자열 자체가 아니라 선택지/대상/상태 차이를 남긴다.',
 'P3296':'휴식 head/last/party는 직접 비교했다. 원본은 gear_card를 같은 휴식 화면에 두며 native는 장비 정비로 이동한다. ask 때 함께 남는 정보도 다르다. 성적 휴식 카드는 제외다.',
 'P3305':'탐색·휴식·정산 구성 조각의 표시 대조를 추가했다. run 없음 안내와 귀환, ask의 전체 구성, 정비 페이지 및 패배 뒤 scene 이동까지 합친 분기 전체는 아직 다르다.',
 'P3309':'기존 potion/mana 이관과 사용자 저장 보존 검사는 통과했다. 원본은 음수/소수를 산술 합산하며 native는 기존 유효 저장 규칙에 따라 원자적으로 거부한다. 실제 허용 입력 차이를 남긴다.',
 'P3311':'기존 native 저장과 별칭의 재개는 유지했다. 원본 canonical G 전체를 native 저장으로 읽는 범용 이관이 없다. 매체 차이 자체가 아니라 미지원 원본 입력 스키마가 남는다.',
 'P3331':'원본에서 호출처가 없는 cur_i local의 현재 행동자 인덱스를 native 행동자와 함수 단위로 연결한 직접 대조가 없다. 전투 파일은 수정 금지다.',
 'P3332':'기존 44개 효과 대조는 유지했다. 무재고·무효 대상·현재 행동자·이벤트/타이머·메뉴 저장 재개 및 원문 메시지를 포함한 전투 아이템 전체 대조가 남는다. 전투 파일 수정 금지다.',
 'P3337':'탐색 이름 helper의 같음을 전투 표시 함수로 전파하지 않았다. 전투 메뉴가 쓰는 실제 아이템 이름과 fallback의 별도 직접 대조가 남는다. 전투 파일은 수정 금지다.',
 'P3338':'전투 아이템 버튼의 무재고/사용 불가 이유·대상·활성 조건·누른 뒤 상태의 전체 대조가 남는다. 태그 차이를 이유로 남기지 않으며 전투 파일은 수정 금지다.',
 'P3340':'전투 아이템 목록의 순서·수량·빈 목록 안내·활성 조건·메뉴 저장 재개의 전체 대조가 남는다. 전투 파일은 수정 금지다.',
 'P3344':'아이템 handler의 잘못된 scene/메뉴/대상·취소·중복 입력·타이머·저장 재개·원문 메시지의 전체 일치가 남는다. 전투 파일은 수정 금지다.'}
assert len(groups)==26 and len(remaining)==38
excluded={'P2794':'RisuAI에 제공하는 영어 AI 문맥 문자열만 만드는 host 전용 CTX 함수. 공통 기능 등가 기준에 따라 제외하며 남은 수에 넣지 않는다.'}
implemented=set(groups)-{'P3134','P3189'}|{'P2757','P3032','P3287','P3296','P3305'}
native_files=['project/game/expedition_ui_r23.gd','project/game/expedition_world_r22.gd','project/game/persona_rules.gd','project/game/persona_world.gd','project/game/town_rules_r21.gd','project/game/town_world_r21.gd','project/ui/expedition_screen_r22.gd','project/ui/persona_sortie_screen.gd','project/ui/town_screen_r21.gd']
def locations():
 out=[]
 for p in native_files:
  for i,line in enumerate((R/p).read_text(encoding='utf-8').splitlines(),1):
   if line.startswith(('func ','static func ')):out.append({'file':p,'line':i,'function':line.split('func ',1)[1].split('(',1)[0]})
 return out
loc=locations();reviews=[]
symbols={'P2746':'source_town','P2749':'town_source_name','P2750':'town_source_party','P2751':'town_source_tags','P3003':'award_result','P3004':'award_result','P3026':'sortie','P3028':'sortie','P3031':'sortie','P3120':'source_run','P3134':'expedition_item_name','P3140':'start_selected_dungeon','P3159':'enter_dungeon_rest','P3168':'advance','P3189':'final_battle','P3273':'meter','P3274':'pips','P3275':'head','P3277':'last','P3278':'use_button','P3280':'use_row','P3281':'party','P3282':'retreat','P3299':'done_act','P3303':'done','P3304':'text'}
source_root=Path('C:/Clauede Code/dungeon-bot')
for row,old in zip(ledger['rows'],previous['rows']):
 assert row['id']==old['id']
 if not old['remaining_reason']:
  assert row==old;continue
 rid=row['id'];assert rid in groups or rid in remaining or rid in excluded
 src=source_root/row['source']['file'];lines=src.read_text(encoding='utf-8').splitlines()
 evidence={'previous':{'status':old['status'],'fixed':old['fixed'],'remaining_reason':old['remaining_reason']},'comparison_mode':'functional equivalence per r21-common.md 2026-11-03','source_sha256':digest(src),'source_excerpt_sha256':hashlib.sha256('\n'.join(lines[row['source']['start']-1:row['source']['end']]).encode()).hexdigest(),'groups':groups.get(rid,[]),'tests':['project/tests/expe_pass5_r23_test.gd','project/tests/ui_expe_pass5_r23_test.gd','verification/parity-r23/expe-pass5-extra.gd']if rid in groups else [],'implementation_changed':rid in implemented,'native_locations_index':'verification/parity-r23/expe-pass5-native-locations.json'}
 if rid in groups:
  row['status']='같음';row['remaining_reason']='';evidence['direct_native_contract']=True
  evidence['results']=['verification/parity-r23/expe-pass5-results.json','verification/parity-r23/expe-pass5-ui-direct-results.json','verification/parity-r23/expe-pass5-extra-results.json']
  if rid=='P3134':
   evidence['tests']=['project/tests/expe_pass4_r23_test.gd','project/tests/expe_pass3_r23_test.gd']
   evidence['scope']='78/77 item names outside the explicitly excluded 79-sex charm_potion branch; no sexual scene or potion added'
  if rid=='P3189':evidence['tests']=['project/tests/expe_r23_test.gd'];evidence['scope']='source boss guard and ask transition; host save/chat excluded'
  if rid=='P3140':evidence['scope']='selected-floor normalization, constructor/vitals/RNG/save-resume. D.prev is only for excluded sexual benched conditions; pend_hard chat excluded.'
  row['tests']=list(dict.fromkeys(row['tests']+evidence['tests']))
  evidence['native_locations']=[p for p in loc if p['function']==symbols[rid]]
  row['implementation']=list(dict.fromkeys(row['implementation']+[p['file']+':'+str(p['line'])for p in evidence['native_locations']]))
 elif rid in excluded:
  row['status']='제외';row['remaining_reason']='';evidence['exclusion_reason']=excluded[rid]
 else:row['remaining_reason']=remaining[rid];evidence['direct_native_contract']=False;evidence['remaining_reason']=remaining[rid]
 row['pass5_fixed']=rid in implemented;row['fixed']=old['fixed']or rid in implemented;row['pass5_evidence']=evidence
 reviews.append({'id':rid,'source':row['source'],'previous_status':old['status'],'status':row['status'],'fixed_this_pass':rid in implemented,'groups':groups.get(rid,[]),'remaining_reason':row['remaining_reason'],'evidence':evidence})
changed=[p for p,h in start['files'].items()if not (R/p).exists()or digest(R/p)!=h]
allowed=set(native_files)|{'project/tests/expedition_r22_test.gd'}
assert set(changed)<=allowed,changed
original_changes=[p for p,h in start['original'].items()if digest(source_root/'bot'/p)!=h]
assert not original_changes
before_assets=read(R/'ASSET-HASHES.json')
assert len(before_assets)==96 and all(digest(R/a['path'])==a['sha256']for a in before_assets)
# All project assets existed at the start: byte identity follows directly from
# the complete project snapshot, independently of the manifest's representation.
asset_changes=[p for p in changed if p.startswith('project/assets/')]
assert not asset_changes
assert all(digest(R/p)==h for p,h in start['files'].items()if p.startswith(('server/','docs/')))
assert all(digest(R/p)==h for p,h in start['files'].items()if p.startswith('project/tests/')and Path(p).name.startswith(('battle_','combat_','ui_battle_')))
trace=ledger['trace_reports'];trace_battles=0;trace_equal=0;trace_records=0
for t in trace:
 p=R/t['file'];j=read(p)
 # The suite reruns all eight original audit scripts. Their machine summaries
 # retain the complete original evidence and totals.
 assert next(r for r in suite if r['test']==t['test'])['passed']
 equal=j.get('equal_battles',sum(not r.get('mismatches') and r.get('source_result')=={'victory':'win','defeat':'lose'}.get(r.get('godot_result'),'')for r in j.get('reports',[])))
 t.update(battles=j['battles'],equal=equal,records=j['matched_actions'])
 trace_battles+=t['battles'];trace_equal+=t['equal'];trace_records+=t['records']
 t['sha256']=digest(p)
assert trace_battles==trace_equal==6320 and trace_records==219785
summary={'reviewed_rows':65,'promoted_same':26,'excluded_host_rows':1,'implementation_rows':len(implemented),'remaining_rows':38,'cumulative_same':70,'cumulative_excluded':1,'native_assertions':core['checks']+extra['checks'],'native_failures':0,'ui_assertions':ui['checks'],'ui_failures':0,'direct_rendered_source_cases':direct['checks'],'direct_rendered_source_failures':0,'regression_groups':len(suite),'failed_groups':[],'changed_existing_files':changed,'outside_allowed_changed':[],'assets_checked':96,'asset_changes':asset_changes,'trace_battles':6320,'trace_equal_battles':6320,'trace_records':219785,'cloud_save_specimens':len(read(O/'expe-pass5-save-validation.json')['results']),'source_files_unchanged':len(start['original']),'new_comparison_max_bytes':max(p.stat().st_size for p in O.rglob('expe-pass5*')if p.is_file())}
assert summary['new_comparison_max_bytes']<=50*1024*1024
ledger['summary'].update({'reviewed_rows':109,'promoted_same':70,'excluded_host_rows':1,'remaining_rows':38,'fixed_rows':sum(r['fixed']for r in ledger['rows']),'oracle_checks':previous['summary']['oracle_checks']+summary['native_assertions'],'regression_groups':118,'failed_groups':[],'pass5':summary})
ledger['summary']['fixed_still_remaining']=sum(r['fixed']and bool(r['remaining_reason'])for r in ledger['rows'])
ledger['passes'].append({'pass':5,'summary':summary,'row_review':'verification/parity-r23/expe-pass5-row-audit.json'})
ledger['checks']=suite
write(O/'expe-pass5-native-locations.json',loc);write(O/'expe-pass5-row-audit.json',reviews);write(O/'expe-pass5-remaining.json',[r for r in reviews if r['remaining_reason']]);write(O/'expe-pass5-summary.json',summary);write(O/'expe.json',ledger)
categories=collections.Counter(r['source']['file']for r in reviews if r['remaining_reason'])
report=f'''# R23-expe — 5차 기능 등가 대조

남은 65행을 검토해 **같음 26행 추가, 누적 같음 70행, host 전용 제외 1행, 남음 38행**으로 기록했다. 수정·보강한 함수 행은 29행이며 이 중 5행은 전체 기능 차이가 남아 승격하지 않았다. 원본 전 기능 이식 완료는 아니다.

|항목|결과|
|---|---:|
|이번 검토 / 같음 승격 / 수정·보강 / 제외 / 남음|65 / 26 / 29 / 1 / 38|
|새 native 대조 단언|{summary['native_assertions']:,}, 실패 0|
|새 실제 UI 단언|{summary['ui_assertions']:,}, 실패 0|
|실제 표시 입력을 Lua에 재입력한 화면 대조|24/24 일치|
|원본 실행 fixture 사례|1,704 (기본 1,464 + 경계 216 + 화면 24)|
|전체 프로젝트 검사 최종 집계|118/118 그룹, 실패 0|
|전투 대조|6,320판 / 219,785기록, 차이 0|
|저장 표본의 서버 validate|4/4|
|기존 같음 행 보존|44/44, 행 객체 변경 0|
|보호 이미지 / 정본 Lua|96개 변경 0 / 46개 변경 0|
|기존 전투 시험 파일 / 서버 / docs 변경|0 / 0 / 0|
|새 대조 파일 최대 크기|{summary['new_comparison_max_bytes']:,} bytes, 50MB 이하|

행별 이전 상태·시험·수정 위치·남은 이유는 [expe.json](verification/parity-r23/expe.json)에 이어 기록했다. 이번 65행 검토는 [expe-pass5-row-audit.json](verification/parity-r23/expe-pass5-row-audit.json), 남은 38행은 [expe-pass5-remaining.json](verification/parity-r23/expe-pass5-remaining.json)이다. 4차 보고서와 ledger는 expe-pass5-start-report.md / expe-pass5-start-ledger.json에 보존했다.

## 바뀐 동작

경험치 지급을 실제 74-level.lua의 전체 상태·지급량·레벨업 문구·중복 호출·연대기 문구와 비교했다. 숫자 sid와 문자열 sid를 구분하고, pm 중복/빈 자리/알 수 없는 동료, 편성 fallback, persona 없음, 경험치 0·음수·숫자 문자열·잘못된 문자열을 다뤘다. 동료 레벨이 없는 상태에서는 persona를 먼저 레벨업한 뒤 그 시점의 persona 레벨로 동료의 누락 레벨을 정해야 했다. 실제 실패 결과 60건을 expe-pass5-branch-before-results.json에 보존했다(누락 레벨 관련 12건과 후보 호감도 표시 48건). 수정 후 전부 통과했다. source town 기본값은 transient 경계에서만 쓰며 native xp_r22에는 기존 지급 표식만 저장한다.

선택 층의 범위 정규화와 출발 직후 빈 last를 원본에 맞췄다. 탐색 문구·로그와 휴식 회복 안내에 원본 영어 언어 팩을 연결했다. 반복해서 직접 호출한 휴식은 원본처럼 다시 회복한다. 이 차이를 확인한 24개 Lua 사례를 근거로 기존 expedition_r22_test의 1회 회복 고정 기대값을 반복 호출의 회복 상한 계산으로 바꿨다. 중복 탐색·보스 출발·정산 차단은 기존 시험 그대로 통과한다.

마을 출전 이름에 참전 persona를 먼저 포함했다. 이름 fallback, 중복/알 수 없는 동료 이름, 번역된 tag 순서, town 기본값·동일 참조 반환을 직접 비교했다. 마을 전체 화면이나 시설 이동 handler를 이 일부 근거만으로 승격하지 않았다.

탐색·휴식 화면은 원본의 층/구역/심층/보스/적 레벨/금화/물건 수/경험치, 진행 표식, 긴 발견 문구, 파티 직업/레벨/HP/MP와 사용할 수 있는 물약을 native 노드로 표시한다. 물약의 원본 표시 이름·보유량·레벨 부족·쓰러진 대상·재고 없음 조건과 실제 버튼 사용 후 주머니 우선 소비를 확인했다. 퇴각 안내는 보스 보상/돌파 기록을 받지 못한다는 원문과 퇴각/계속 버튼 순서를 따른다. 정산은 원본의 정렬된 아이템·장비·경험치·레벨업·호감·손실 문구와 다음 층/귀환 선택지를 표시한다.

출정 후보 카드에는 출전 중인 동료도 정렬 순서대로 남기고 직업·열·레벨·속성·호감도를 표시했다. 원본 PX.aff는 소수를 내린 뒤 bar에 넣으므로 99.9의 표시도 맞췄다. 세 필터의 종류/순서/선택 상태와 빈 목록 안내, 출전 수/평균/적 레벨/전열 수/경고를 비교했다. 이미 보존된 이전 persona_world 테스트 경로는 시작 시점과 SHA-256이 같은 출정 화면을 별도 파일로 보존해 연결했다.

HTML 태그·style·class 문자열은 같음 판정에 쓰지 않았다. 실제 Lua 반환에서 text/action/활성 조건/표식/게이지를 추출하고 native가 그린 Label/Button 및 상태 변화를 비교했다. 같은 native 화면 입력을 정본 Lua로 다시 실행한 24건도 일치했다. 1·3·27·28·55·420층의 보스/심층 및 다음 층 허용 여부는 추가 216사례에서 비교했다. raw source 레코드는 비교와 표시를 위한 일시적 투영이며 native 저장 스키마를 대체하지 않는다.

## 검사와 보존

무거운 전체 검사는 로컬 node server/abyss-save/test/serve.mjs를 띄워 한 번 실행했다. 최초 118그룹 중 116그룹 통과, 2그룹은 영어 퇴각 안내의 줄바꿈 높이 초과를 보고했다. 최초 실패와 로그는 [expe-pass5-suite-final](verification/parity-r23/expe-pass5-suite-final)에 그대로 있다. 검사 도중 제품·시험 GDScript 변경은 없었다.

그 뒤 제품 변경은 expedition_screen_r22.gd의 안내 폭 118→354px 및 오른쪽 정렬 두 줄뿐이다. 원문을 유지해 한 줄에 들어가게 했고, 실패한 두 그룹을 포함한 관련 UI 6그룹을 다시 실행해 전부 통과했다. 전체 검사 반복 없이 최종 118그룹 실패 0을 집계했다. 최초 결과와 보정 실행을 구분한 근거는 [expe-pass5-final-checks.json](verification/parity-r23/expe-pass5-final-checks.json), 보정 실행은 [expe-pass5-ui-correction](verification/parity-r23/expe-pass5-ui-correction)에 있다. 전투 대조는 8개 원본 audit의 실제 새 결과를 합산했다.

360×780·390×844, 한국어·영어의 실제 포인터 입력/스크롤/저장 재개/취소/확정/재정산 거부를 확인했다. 전용 캡처 20장이 expe-pass5-render/에 있다. 직접 열어 본 이미지는 expe-pass5-visual-review.json에 기록한다. 처음 발견한 배경 위 문구 대비 문제는 정보 영역에 불투명한 바탕을 넣어 고쳤다. Web/WASM 내보내기·브라우저 실기기는 확인하지 않았다.

기존 파일 변경은 {len(changed)}개다. 게임 규칙: expedition_world_r22.gd, persona_rules.gd, persona_world.gd, town_rules_r21.gd, town_world_r21.gd. 화면: expedition_screen_r22.gd, persona_sortie_screen.gd, town_screen_r21.gd. 시험: expedition_r22_test.gd. 새 구현은 expedition_ui_r23.gd, expe-ui-r23.json과 앞서 보존한 expe_sortie_legacy_r23.gd이며, 새 시험/도구/대조 자료는 expe 접두로 추가했다. 새 번역은 정본 05-gen.lua의 언어 팩에서 해당 표시 키만 추출했다. source, 서버, 전투 코드·시험, docs, 보호 이미지 바이트를 시작 해시와 비교했다. 사용자 저장 접근/삭제, 저장 schema 변경, git 명령·커밋·Web export·버전 갱신은 없다.

## 남은 38행

원본별: {', '.join(Path(k).name+' '+str(v)+'행'for k,v in sorted(categories.items()))}.

주요 실제 차이는 마을 본문/시설 설명/의뢰 카드 누락, 출정의 모드·슬롯·문구, ask 때 기존 파티 정보를 함께 남기는 구성, 휴식 정비의 선택지/순서, 패배 뒤 run 제거와 마을 이동, 포화 가방의 overflow 보존, canonical 원본 저장/옛 stage 입력 미지원이다. 전투 아이템·전투 snapshot의 전체 경계는 여전히 수정 금지인 전투 파일에 걸친다. 수정이 허용된 화면/마을/의뢰의 나머지 기능도 아직 완료하지 못했다. 이 38행에는 단순히 HTML/native 매체가 다르다는 이유만 남긴 행이 없다.

P2794는 AI에게 줄 문맥만 만드는 CTX 함수이므로 공통 기준에 따라 제외했다. P3134의 이름 비교는 명시적으로 제외한 79-sex 전용 charm_potion 분기를 빼고 같음으로 기록했으며, 해당 아이템/장면은 추가하지 않았다. 70행 같음은 이 묶음의 행 판정이며 프로젝트 전체 완성률이 아니다. 기존 316/318 명시 진입 수치를 이번 기능 대조의 전수 조합 증명으로 쓰지 않았다.

재현: node tools/expe_r23_pass5_oracle.mjs → python tools/expe_r23_pass5_project.py → python tools/godot_r17.py --headless --script res://tests/expe_pass5_r23_test.gd. 실제 화면은 ui_expe_pass5_r23_test.gd 실행 후 node tools/expe_r23_pass5_ui_oracle.mjs → python tools/expe_r23_pass5_ui_verify.py. 추가 층/정산은 node tools/expe_r23_pass5_extra.mjs → python tools/expe_r23_pass5_extra_project.py → Godot의 res://../verification/parity-r23/expe-pass5-extra.gd. 전체 검사 도구는 결과 덮어쓰기를 막는다. 재실행하려면 새 EXPE_SUITE_NAME을 지정한다.

도구 메모: Impeccable detector 결과는 []였다. 기존 DESIGN.md와 .impeccable/design.json의 갱신 시점 차이는 그대로 뒀으며, 필요하면 별도 document 작업으로 동기화할 수 있다.
'''
(R/'R23-expe.md').write_text(report,encoding='utf-8');(O/'expe-pass5-report.md').write_text(report,encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
