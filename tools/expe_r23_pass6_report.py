"""Finalize pass 6 evidence only after the owned full suite has completed."""
from pathlib import Path
import json,hashlib,re,collections
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
previous=read(O/'expe-pass6-start-ledger.json');ledger=json.loads(json.dumps(previous,ensure_ascii=False))
suite_dir=O/'expe-pass6-suite-verified';suite=[read(p)for p in sorted((suite_dir/'rows').glob('*.json'))]
expected=1+sum(len(x['tests'])for x in read(suite_dir/'plan.json').values())
assert (suite_dir/'group-exits.json').exists() and len(suite)==expected and all(r['passed']for r in suite)
assert read(suite_dir/'code-lock-result.json')['changed']==[]
core=read(O/'expe-pass6-after-results.json');ui=read(O/'expe-pass6-ui-results.json');direct=read(O/'expe-pass6-ui-source-results.json');saves=read(O/'expe-pass6-save-validation.json')
assert not core['failures'] and not ui['failures'] and direct['failures']==0 and all(r['passed']for r in saves)
promoted={'P2752','P2753','P2754','P2755','P2756','P3017','P3018'}
implemented=promoted|{'P2757','P3016','P3020','P3032','P3041','P3079','P3202','P3287','P3296','P3305'}
remaining={
'P2757':'마을 본문·전체 시설 설명·수락 의뢰/최고층 안내를 기존 하단 영역의 스크롤에 추가했다. 출전자 없음 안내, place_id에 따른 장소별 hero 제목/본문, 원본 전체 버튼 순서는 아직 직접 일치하지 않는다. 고정 시안의 기존 바로가기도 유지했으므로 전체 화면은 승격하지 않는다.',
'P2758':'마을의 새 의뢰/대던전 버튼은 실제 모드 선택으로 연결했다. 전체 이동의 ui.tab 초기화·잘못된 scene·의뢰 없음 메시지 및 거래 영수증 경계는 facilities_world_r22.facility_route와 world_screen.go에 걸친다. 시설 파일 수정 금지이며 전체 handler 직접 대조는 남는다.',
'P2784':'실제품 의뢰 정산은 수정 금지인 facilities_world_r22.settle이 override한다. st.rg 우선/의뢰 fallback, 미종료 전투, 엘리트 입고, 재정산, 원문 메시지의 단일 진입점 직접 대조가 남는다. 허용된 town_world만 바꿔도 제품 경로에는 반영되지 않는다.',
'P2792':'원본 battle HUD의 id/load/bn 실패·탐색 승리 제외와 귀환/층 정산 label/subtitle은 현재 battle 화면 파일에 있다. 이번에 고친 패배 후 마을 경로만으로 전체 HUD의 같음을 주장하지 않는다. 전투 화면/규칙 수정 금지.',
'P3016':'동료의 원본 초상과 새 번역 첫 글자 fallback은 유지·보강했다. SO.face의 persona pimg(호스트 사용자 아바타/실루엣)와 PX.face의 nonempty plain-string provider 반환 경계는 town tw_face와 다른 계약이다. native persona 표시는 이 전체 분기와 아직 같지 않다. 호스트 아바타 부분은 호스트 전용 범위로 별도 기록한다.',
'P3020':'persona 이름·직접 싸운다/지휘만 한다 문구·3/4명 설명·선택 표시를 직접 대조하고 UI에 연결했다. 클래스 정보가 없는 옛 native 저장에서는 직접 참전 버튼을 비활성화하는 기존 보존 처리가 남아 원본의 무조건 활성 버튼과 다르므로 전체 승격하지 않는다.',
'P3032':'의뢰/대던전 모드·의뢰 카드·4슬롯·persona 설명·출발 문구를 추가했다. 기존 시안의 hero/picker·고정 슬롯·스크롤 구성과 의뢰 직접 출발 보조 버튼을 유지했다. 원본 전체 화면의 정보/버튼 순서, 옛 저장 참전 활성 경계는 아직 같지 않다.',
'P3037':'현재 전투 엔진이 없는 원본 환경의 fresh(T.bn) 옛 전투 생성 fallback은 native의 옛 저장 재개와 별개의 기능이다. canonical legacy 출정 상태 생성/이관 ABI가 아직 없으며 이번 화면 fixture로 대체하지 않았다.',
'P3041':'실제 슬롯 제거·persona 지휘 전환·mode/filter/floor/page를 연결했고 중복 rm이 재등록하지 않도록 했다. 참전 전환의 마지막 동료 대기/만석 메시지를 보강했다. source go/back의 모든 scene·무효 입력과 legacy engine-absent 분기를 하나의 handler로 직접 대조하는 것은 남는다.',
'P3079':'0/2/8/27/54/419 최고층과 1/2/99쪽의 목록·잠김·돌파/추천·보스/일반 금화·적 레벨·4인 안내 36건의 직접 대조를 추가했다. rank_head의 cached percentile은 원본처럼 카드 안에 표시하지 않고 별도 native 순위 화면으로 연결한다. 명시적 클라우드 대체의 순위 기능은 기존 시험으로 유지하지만 전체 카드의 cached 상태 표시까지 같음으로 올리지는 않는다.',
'P3145':'전투 진입 자원·탐색 투영은 기존 대조를 유지한다. 원본 sid/bn/dn/carry 전부와 native battle snapshot의 전체 경계 동등성은 아직 직접 확정하지 못했다. 전투 규칙 수정 금지.',
'P3182':'수치 투영·스냅샷 회귀는 유지했다. native continuation의 적 이름 중복 제거 last/log·정예 장비 log와 source sid/bn/over/dn 불일치 분기 전체는 아직 직접 비교/수정하지 않았다.',
'P3195':'포화 가방의 원본 장비 버림과 native overflow 보존은 실제 정책 차이다. 사용자 저장 보존 규칙과 장비 규칙 수정 금지를 유지했다. 현재 bank_expedition_gear의 반환 개수만 같다고 승격하지 않는다.',
'P3202':'패배 후 live run 제거·마을 이동·ui.sel/tab 초기화·원문 손실 알림·D.last 보존을 수정했다. 승리/퇴각/패배·케른 유지·재호출·native 저장 재개를 12개 실제 Lua fixture로 대조했다. 포화 가방 overflow 정책과 전체 장비/보상 조합은 남아 있으므로 함수 전체 승격은 보류한다.',
'P3223':'원본 sid/bn 불일치 시 거점 복귀와 legacy stage 분기, native snapshot 검증을 통합한 정산 경계의 직접 대조가 미완료다. 패배의 정상 경로 수정만으로 무효 입력까지 승격하지 않는다.',
'P3225':'옛 native 저장 재개 회귀는 유지했다. canonical 원본 st.dn.stage 1/2 저장을 읽어 정산하는 입력 ABI가 아직 없다. 매체 차이가 아니라 미지원 구체 입력 경로로 남긴다.',
'P3249':'휴식 장착/해제의 기존 정상 경로는 유지했다. source gear code 버튼 해독·잘못된 슬롯·다른 소유자 장비·거절 메시지의 전체 직접 대조는 장비 규칙에 걸려 남는다. 해당 파일 수정 금지.',
'P3251':'탐색·물약·퇴각 요청/취소/확정의 기존 대조와 새 확인 화면 정보를 유지했다. cont/next/home의 무효 전투 상태 및 모든 장비 버튼을 합친 전체 handler 직접 대조는 남는다.',
'P3287':'ask에도 head/last/party/물약 정보를 함께 남기도록 수정하고 실제 UI에서 확인했다. 원본 전체 explore 화면의 버튼 종류/순서와 시안의 지도·기록·카드·보급품 이동 차이는 남아 전체 승격하지 않는다.',
'P3290':'같은 휴식 화면에 source 슬롯별 장비 후보·해제·장착 순서를 표시하는 기능이 남는다. native는 별도 정비 페이지를 쓰며 후보/소유자/레벨 판정은 장비 갈래 소유다. 장비 규칙 파일 수정 금지.',
'P3293':'원본 R.sel의 무효 슬롯 정규화와 슬롯별 후보 전체가 native의 별도 정비 대상 선택과 아직 다르다. gear_card를 이식하려면 장비 갈래의 후보/소유자 경계 근거가 필요하다.',
'P3296':'휴식 중 ask에도 기존 파티 정보를 보존하도록 수정했다. 원본은 gear_card를 같은 휴식 화면에 두고 native는 별도 장비 정비로 이동한다. 후보/슬롯 차이가 남는다. 성적 휴식 카드는 제외하며 추가하지 않았다.',
'P3305':'ask의 기존 파티 정보와 패배 후 마을 이동·live run 제거를 보강했다. run 없음 안내/귀환, inline gear_card, 전체 phase별 버튼 구성의 직접 대조가 남는다. 구성 조각의 통과만으로 전체 화면을 승격하지 않는다.',
'P3309':'potion/mana의 유효 옛 저장 합산은 유지했다. 원본 음수/소수 합산과 native 원자적 거부는 실제 허용 입력 차이로 남는다. 저장 검증을 약화하거나 손상 데이터를 조용히 버리지 않았다.',
'P3311':'이번 local mode 필드의 손실 없는 이관·왕복 시험은 추가했다. 원본 canonical G 전체/옛 stage 저장을 native로 읽는 범용 이관은 아직 없다. 이 추가 이관을 전체 G_migrate 근거로 쓰지 않는다.',
'P3331':'현재 행동자 인덱스의 source cur_i와 native 실행 행동자를 함수 단위로 연결한 직접 시험은 여전히 없다. 전투 파일 수정 금지.',
'P3332':'44개 효과의 기존 대조는 유지했다. 무재고·무효 대상·현재 행동자·이벤트/타이머·메뉴 저장 재개·원문 메시지의 전체 직접 대조는 남는다. 전투 파일 수정 금지.',
'P3337':'탐색 아이템 이름 helper의 기존 같음을 전투 메뉴 이름에 전파하지 않았다. 전투가 실제 사용하는 표시 이름과 unknown fallback의 별도 직접 대조가 남는다. 전투 파일 수정 금지.',
'P3338':'전투 아이템 버튼의 무재고/불가 이유·대상·활성·클릭 후 상태 전체 직접 대조가 남는다. 전투 파일 수정 금지.',
'P3340':'전투 아이템 목록의 순서·수량·빈 안내·활성 조건·메뉴 저장 재개의 전체 직접 대조가 남는다. 전투 파일 수정 금지.',
'P3344':'전투 아이템 handler의 scene/menu/target·취소·중복·타이머·저장 재개·원문 메시지 전체 직접 대조가 남는다. 전투 파일 수정 금지.'}
groups={'P2752':['face'],'P2753':['heading'],'P2754':['place'],'P2755':['stars','quest'],'P2756':['hint'],'P3017':['quest'],'P3018':['slots'],'P3020':['fight'],'P3079':['dungeon_card'],'P3202':['finish'],'P3032':['quest','slots','fight','dungeon_card','mode_save'],'P3041':['slots','mode_save']}
native_files=['project/game/expedition_ui_r23.gd','project/game/expedition_world_r22.gd','project/game/persona_world.gd','project/ui/expedition_screen_r22.gd','project/ui/persona_sortie_screen.gd','project/ui/town_screen_r21.gd','project/ui/world_screen.gd']
locations=[{'file':f,'line':i,'function':m[1]}for f in native_files for i,line in enumerate((R/f).read_text(encoding='utf8').splitlines(),1)if(m:=re.match(r'(?:static )?func (\w+)',line))]
symbols={'P2752':'source_portrait_record','P2753':'source_entries','P2754':'town_detail_button','P2755':'quest','P2756':'source_entries','P3017':'quest','P3018':'formation_slots','P3020':'fight','P3032':'build','P3041':'source_action','P3079':'dungeon_card','P3202':'settle','P3287':'retreat','P3296':'retreat','P3305':'expedition_defeat_home','P2757':'home','P3016':'picture'}
reviews=[]
for row in ledger['rows']:
 if row['status']in ['같음','제외']:continue
 rid=row['id'];old={k:row[k]for k in ['status','fixed','remaining_reason']}
 assert rid in promoted or rid in remaining,rid
 evidence={'previous':old,'comparison_mode':'functional equivalence per r21-common.md 2026-11-03','source':row['source'],'groups':groups.get(rid,[]),'direct_native_contract':rid in promoted,'full_function_unresolved':rid not in promoted,'implementation_changed':rid in implemented,'tests':['project/tests/expe_pass6_r23_test.gd','project/tests/ui_expe_pass6_r23_test.gd']if rid in implemented else [],'provenance':'verification/parity-r23/expe-pass6-provenance.json','results':'verification/parity-r23/expe-pass6-after-results.json','painted_source_comparison':'verification/parity-r23/expe-pass6-ui-source-results.json'if rid in implemented else None}
 if rid in promoted:
  row['status']='같음';row['remaining_reason']='';row['tests']=list(dict.fromkeys(row['tests']+evidence['tests']))
 else:
  row['remaining_reason']=remaining[rid]
  if rid in implemented:row['status']='일부'
 evidence['native_locations']=[p for p in locations if p['function']==symbols.get(rid)]
 if rid in implemented:row['implementation']=list(dict.fromkeys(row['implementation']+[x['file']+':'+str(x['line'])for x in evidence['native_locations']]))
 row['pass6_fixed']=rid in implemented;row['fixed']=old['fixed']or rid in implemented;row['pass6_evidence']=evidence
 reviews.append({'id':rid,'source':row['source'],'previous_status':old['status'],'status':row['status'],'fixed_this_pass':rid in implemented,'remaining_reason':row['remaining_reason'],'evidence':evidence})
start=read(O/'expe-pass6-start-hashes.json');changed=[p for p,h in start.items()if not (R/p).exists()or digest(R/p)!=h]
assert set(changed)==set(native_files),changed
assets=read(R/'ASSET-HASHES.json');assert len(assets)==96 and all(digest(R/a['path'])==a['sha256']for a in assets)
source=read(O/'expe-pass5-start.json')['original'];source_root=Path('C:/Clauede Code/dungeon-bot/bot');assert all(digest(source_root/p)==h for p,h in source.items())
trace=ledger['trace_reports'];trace_battles=trace_records=0
for t in trace:
 assert next(x for x in suite if x['test']==t['test'])['passed']
 j=read(R/t['file']);equal=j.get('equal_battles',sum(not r.get('mismatches')and r.get('source_result')=={'victory':'win','defeat':'lose'}.get(r.get('godot_result'),'')for r in j.get('reports',[])))
 assert equal==j['battles'];t.update(battles=j['battles'],equal=equal,records=j['matched_actions'],sha256=digest(R/t['file']));trace_battles+=equal;trace_records+=j['matched_actions']
assert trace_battles==6320 and trace_records==219785
assert all(row==next(r for r in previous['rows']if r['id']==row['id'])for row in ledger['rows']if next(r for r in previous['rows']if r['id']==row['id'])['status']in ['같음','제외'])
max_bytes=max(p.stat().st_size for p in O.rglob('expe-pass6*')if p.is_file());assert max_bytes<=40*1024*1024
summary={'reviewed_rows':len(reviews),'promoted_same':len(promoted),'implementation_rows':len(implemented),'fixed_still_remaining':len(implemented-promoted),'cumulative_same':sum(r['status']=='같음'for r in ledger['rows']),'excluded_host_rows':1,'remaining_rows':len(remaining),'native_assertions':core['checks'],'native_failures':0,'ui_assertions':ui['checks'],'ui_failures':0,'direct_rendered_source_cases':direct['cases'],'direct_rendered_source_failures':0,'source_fixture_cases':228,'regression_groups':len(suite),'failed_groups':[],'changed_existing_files':changed,'outside_allowed_changed':[],'assets_checked':96,'asset_changes':[],'source_files_unchanged':len(source),'trace_battles':trace_battles,'trace_equal_battles':trace_battles,'trace_records':trace_records,'cloud_save_specimens':len(saves),'ui_captures':len(ui['captures']),'new_comparison_max_bytes':max_bytes}
ledger['summary'].update({'promoted_same':summary['cumulative_same'],'remaining_rows':len(remaining),'fixed_rows':sum(r['fixed']for r in ledger['rows']),'fixed_still_remaining':sum(r['fixed']and bool(r['remaining_reason'])for r in ledger['rows']),'oracle_checks':previous['summary']['oracle_checks']+core['checks'],'regression_groups':len(suite),'failed_groups':[],'changed_existing_files':changed,'pass6':summary})
ledger['passes'].append({'pass':6,'summary':summary,'row_review':'verification/parity-r23/expe-pass6-row-audit.json'});ledger['checks']=suite
write(O/'expe-pass6-native-locations.json',locations);write(O/'expe-pass6-row-audit.json',reviews);write(O/'expe-pass6-remaining.json',[r for r in reviews if r['remaining_reason']]);write(O/'expe-pass6-summary.json',summary);write(O/'expe.json',ledger)
write(O/'expe-pass6-visual-review.json',{'screenshots':ui['captures'],'opened_contact_sheets':['expe-pass6-sheet-'+str(i)+'.png'for i in range(4)],'review':'Opened all 24 at native pixel scale in four contact sheets, plus four individual captures. Existing hero/fonts/colors remain. Long text is accessible in the existing scroll regions; formation preserves original portrait bytes. Native persona placeholder and full-page composition differences remain in the ledger. No browser/Web export or physical-device claim.'})
report=f'''# R23-expe — 6차 기능 등가 대조

남은 38행을 끝까지 재검토했다. **같음 7행 추가, 누적 같음 77행 / 제외 1행 / 남음 31행**이다. 수정·보강한 행은 17행이며 이 중 10행은 전체 차이가 남아 승격하지 않았다. 원본 기능 전체 이식은 완료하지 못했다.

|항목|이번 결과|
|---|---:|
|검토 / 같음 승격 / 수정·보강 / 남음|38 / 7 / 17 / 31|
|새 native 단언|{core['checks']:,}, 실패 0|
|새 실제 UI 단언|{ui['checks']:,}, 실패 0|
|실제 표시 입력을 정본 Lua로 재실행|{direct['cases']}/{direct['cases']} 일치|
|원본 실행 fixture|228 (표시 196 + 초상 20 + 정산 12)|
|전체 프로젝트 검사|{len(suite)}/{len(suite)} 그룹, 실패 0|
|전투 대조|6,320판 / 219,785기록, 차이 0|
|서버 저장 validate|{len(saves)}/{len(saves)}|
|기존 같음 / 제외 행 보존|70 / 1, 행 객체 변경 0|
|보호 이미지 / 정본 Lua|96개 변경 0 / 46개 변경 0|
|기존 변경 파일|7개, 허용 범위 밖 0|
|새 대조 자료 최대 크기|{max_bytes:,} bytes, 40MB 이하|

승격: P2752(초상 실패 fallback), P2753(아이콘/제목), P2754(시설 버튼 전체 이름과 설명), P2755(의뢰 별 반복), P2756(빈/임의 안내), P3017(의뢰 카드 묶음), P3018(4칸 슬롯/번호/순서/제거).

의뢰의 제목·설명·종류·난이도·금화·적 레벨·별을 함께 표시했다. 4칸은 persona부터 파티 순서로 표시하며 빈 칸에는 원본 번호를 붙였다. persona 칸은 지휘로 전환하고 동료 칸은 제거한다. 직접 참전/지휘 문구, 마지막 동료 대기·만석 메시지와 모드 전환을 연결했다. 층 목록은 잠김 이유·추천/돌파·쪽 수·보스/일반 금화·4인 추천 설명을 추가했다. 후보/요약과 원본 데이터·초상 바이트는 유지한다.

마을은 기존 hero·파티·출정·시설 위치와 색·서체를 보존하고, 기존 시설 영역 안의 스크롤에 본문·전체 장소 설명·의뢰 출정·최고층 안내를 추가했다. 새 단축 버튼은 실제 이동/모드 선택에 연결한다. 퇴각 확인은 별도 안내 아래 원본처럼 층/발견/파티/물약 정보를 함께 보존한다. 패배 뒤 live run을 없애고 마을로 돌아가며, 원본 손실 알림과 D.last/native summary를 보존한다. 케른 유지·중복 정산·저장 재개도 대조했다.

실패를 보존한 첫 대조는 expe-pass6-before-results.json(216/216 미구현 경계 실패)이다. 그 같은 표시/초상 216건은 최종 모두 통과하며 정산/이관 56개 단언을 더해 272개다. 모든 텍스트·버튼·활성·순서는 Lua HTML에서 추출해 native 결과와 비교했다. 실제 그린 입력 44건도 다시 Lua에 넣어 일치했다. native 렌더러의 DTO끼리만 비교한 결과를 원본 대조로 세지 않았다.

클라우드 검사에서 source 전용 dungeon.mode를 서버가 거부했다. 첫 전체 실행(expe-pass6-suite-final)은 26그룹 통과 시점에 중단하고 완료 증거로 쓰지 않았다. ui.sel의 기존 자유 문자열 필드에 모드를 보존하도록 고쳐 native/서버 계약을 맞췄고, 먼저 생긴 local mode 저장은 복사본에서 이관한다. 서버·저장 schema·기존 검증 규칙을 바꾸지 않았다. 이후 expe-pass6-suite-verified는 로컬 node server/abyss-save/test/serve.mjs에서 전부 새로 돌렸고, 검사 중 GDScript 변경은 0이다. 기존 시험 기대값 수정은 없다.

남은 31행의 원본 위치·이전 상태·새 시험/수정 위치·이유는 [expe.json](verification/parity-r23/expe.json)과 [expe-pass6-row-audit.json](verification/parity-r23/expe-pass6-row-audit.json)에 있다. 단순 HTML/캔버스·저장 매체 차이를 남은 이유로 삼지 않았다. 시설/장비/전투 파일은 수정하지 않았다. 실제품 의뢰 정산 override, 전투 HUD와 아이템, inline 정비 후보, overflow 보존 정책은 해당 갈래 수정 금지와 연결된다. 그 외 남은 전체 화면 순서, legacy 출정/옛 stage/canonical 저장 입력, continuation 무효 경계도 아직 미완료다. 클래스가 없는 옛 저장의 참전 비활성·persona host 아바타 차이가 있어 관련 전체 행은 승격하지 않았다.

24장(360×780/390×844, 한국어/영어)을 직접 열어 확인했다. 렌더 결과는 expe-pass6-render/와 expe-pass6-sheet-*.png, 검수 기록은 expe-pass6-visual-review.json이다. native 합성 마우스/스크롤 시험이며 브라우저·Web/WASM·물리 기기는 확인하지 않았다. Impeccable detector는 []였다. 기존 DESIGN.md/.impeccable/design.json의 갱신 시점 차이는 유지했고, 별도 document 작업으로 동기화할 수 있다.

재현: node tools/expe_r23_pass6_oracle.mjs → python tools/expe_r23_pass6_project.py → python tools/godot_r17.py --headless --script res://tests/expe_pass6_r23_test.gd. UI는 같은 래퍼로 --position -10000,-10000 --script res://tests/ui_expe_pass6_r23_test.gd 실행 후 node tools/expe_r23_pass6_ui_oracle.mjs → python tools/expe_r23_pass6_ui_verify.py. 저장은 node tools/expe_r23_pass6_saves.mjs. 전체 검사는 새 EXPE_SUITE_NAME으로 tools/expe_r23_pass5_verify.py를 실행한다. 사용자 실제 저장 파일 접근/삭제·git 명령·commit·Web export·docs 수정·버전 갱신은 없다.
'''
(R/'R23-expe.md').write_text(report,encoding='utf8');(O/'expe-pass6-report.md').write_text(report,encoding='utf8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
