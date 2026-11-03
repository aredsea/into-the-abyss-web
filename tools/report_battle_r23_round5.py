"""Finalize row-level R23 evidence only after the complete locked-code suite."""
from pathlib import Path
from collections import Counter
import hashlib,json
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round5-final'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
base=read(O/'battle-round4.json');oracle=read(O/'round5-oracle.json');observed=read(O/'round5-latest.json');coverage=read(O/'coverage.json')
mapping={
 'P2308':('sv','combat_fx_r23.gd','static func style'),
 'P2309':('fx_put','combat_fx_r23.gd','static func put'),
 'P2310':('fx_dn','combat_fx_r23.gd','static func number'),
 'P2311':('fx_cn','combat_fx_r23.gd','func critical'),
 'P2312':('fx_plaque','combat_fx_r23.gd','static func plaque'),
 'P2317':('bz_add','combat_fx_r23.gd','static func camera_add'),
 'P2318':('fx_hit','combat_fx_r23.gd','static func hit'),
 'P2320':('fx_abyss','combat_fx_r23.gd','func abyss'),
 'P2321':('fx_result','combat_fx_r23.gd','func result'),
 'P2322':('fx_cutin','combat_fx_r23.gd','func cutin'),
 'P2323':('fx_pcutin','combat_fx_r23.gd','func persona_cutin'),
 'P2324':('fx_event','combat_fx_r23.gd','func event'),
 'P2326':('sn','combat_hud_r23.gd','func short_name'),
 'P2329':('dyn','combat_hud_r23.gd','static func dyn'),
 'P2331':('dyn','combat_hud_r23.gd','pts.sort_custom'),
 'P2332':('numspan','combat_hud_r23.gd','static func numspan'),
 'P2333':('chip','combat_hud_r23.gd','static func chip('),
 'P2334':('chip_tn','combat_hud_r23.gd','func chip_turns'),
 'P2335':('chip_dotn','combat_hud_r23.gd','static func dot_turns'),
 'P2336':('chips','combat_hud_r23.gd','func chips'),
 'P2337':('hp_stat','combat_hud_r23.gd','static func hp_stat'),
 'P2339':('icn','combat_hud_r23.gd','static func icon'),
 'P2340':('intent','combat_hud_r23.gd','func intent'),
 'P2343':('pbadges','combat_hud_r23.gd','func passive_badges'),
 'P2347':('tile','combat_hud_r23.gd','func tile'),
 'P2348':('rail','combat_hud_r23.gd','func rail'),
 'P2349':('head','combat_hud_r23.gd','func head'),
 'P2350':('kchip','combat_hud_r23.gd','func kind_chip'),
 'P2358':('log','combat_hud_r23.gd','func log_html'),
 'P2361':('camera_compare','combat_hud_r23.gd','static func camera_before'),
 'P2362':('bzo','combat_hud_r23.gd','static func camera_wrapper'),
 'P2365':('pips','combat_hud_r23.gd','func phase_pips'),
 'P2020':('urda_round_full','personal_rules_r22.gd','static func urda_round'),
 'P2079':('hildegard_full','personal_rules_r22.gd','static func hildegard_scan'),
 'P2201':('miko_full','personal_rules_r22.gd','static func miko('),
}
contracts={
 'sv':'선택 CSS 값 false/nil/빈 문자열, 음수·0·경계 시각의 style 문자열 전체.',
 'fx_put':'1/4/5/16칸에 빈 조각·연속 조각을 붙인 전체 L.u. slot map은 명시 JSON 문자열 키.',
 'fx_dn':'문자열/숫자, class 없음/빈/복합, left/top 없음·0·양수와 style/text 전체.',
 'fx_cn':'한국어/영어 치명 문구와 숫자·문자열·소수 시각을 포함한 전체 HTML.',
 'fx_plaque':'class 없음·빈·ab, 표시명·수치·빈 문자열과 전체 style/HTML.',
 'bz_add':'k 없음·0·1·2, rank 0/1/2.5/3의 전체 후보. 최종 둘 선택 루프의 동치로 확대하지 않음.',
 'fx_hit':'아군/적·3강도·7속성/무효 속성·arc/crit/abfx/scale 및 반복 명중. L.u/icwf/hit/hk/bz와 반환 hs 전체.',
 'fx_abyss':'ko/en, 심연 없음/0/소수, 전염 0~3표적의 전체 문구·대상·0.35+n*0.08 시각.',
 'fx_result':'ko/en, 피해 0/1/299/300/599/600, 보호막 0/1/300/600, 치명·약점·last·심연과 모든 layer 필드.',
 'fx_cutin':'ko/en, cuts 유무·대사 없음/빈/값, 인물·아트·이름·마커·카메라·panel 전체.',
 'fx_pcutin':'ko/en, VID/cuts 유무, nil/숫자/빈/인레이/data/http/https/무효/호스트 오류. escape와 fallback·마커·카메라 전체.',
 'fx_event':'29종 사건(unknown 포함)×16상태×ko/en의 전체 L. 별도 연속 사건·실제 Battle.combat_display_frame 경로도 비교. native scene 전체 렌더의 동치로 확대하지 않음.',
 'sn':'ko/en, 아군/옛 적/새 적/없는 정의·범위 밖 번호의 전체 이름 반환.',
 'dyn':'이력 없음/ev 없음/D<=0, 4필드의 역순·동시·늦은 변화, 회복/손실/0최대치. CSS 전체·K map·정렬 callback. 조건 조합 전수를 뜻하지 않음.',
 'numspan':'숫자 -1/0/1/17와 k 없음/빈/값의 전체 span 또는 문자열.',
 'chip':'4class×3text의 전체 chip HTML.',
 'chip_tn':'ko/en, nil/빈 map/음수/0/소수/양수 턴의 전체 단위 문구.',
 'chip_dotn':'빈 목록·누락 턴·음수·여러 DOT의 최대 수명 반환.',
 'chips':'ko/en, 아군/적, 256상태 비트×4중첩 모드. 사망/보호/서약 이름·모든 buff/DOT·고유 표식의 전체 순서/HTML.',
 'hp_stat':'ko/en, HP/MP/SH/심연, 30% 경계·0·초과치, 동적 class/숫자/눈금/단계선의 전체 HTML.',
 'icn':'4전용 icon과 일반/빈/미지정 icon id 전체 반환.',
 'intent':'ko/en, 11행동×4target×도발 유무×전체 공격 유무. 이름/표적/문구/class/style/icon 전체.',
 'pbadges':'12직업×사용 표식 4값×생사×ko/en. 사제 잔여 횟수 포함 HTML 전체.',
 'tile':'ko/en, ally/enemy·current/future·mark/lost·아트/정예/글리프·페르소나 실루엣. 별도 VID/인레이/data/http/https/무효/호스트 오류의 카드 이미지 경로까지 비교.',
 'rail':'ko/en, 16충전 조합×4queue×종결 유무. 중복 표적의 최초 marker/lost만 표시, 지연/당김/충전 우선순위·현재 이름 전체. 페르소나 프로필 이미지 경로도 실제 rail에서 비교.',
 'head':'ko/en, 0~4인·persona 유무·지능/종족/출신 시너지, 별/심층·장소 escape·평균 레벨과 전체 header HTML.',
 'kchip':'ko/en, false/true/0/빈 문자열의 Lua truthiness와 전체 active/passive chip.',
 'log':'0~8줄, 이전/새 기록·현재 줄과 음수/0/소수 시각의 전체 HTML. 6줄 절단 자체는 기존 Record.say 계약.',
 'camera_compare':'원본 render가 실제 table.sort에 넘긴 closure를 관측해 rank 우선·동률 시간·동시각 반환 비교.',
 'bzo':'nil camera 및 k 없음/0/1/>1, 소수 시각의 전체 wrapper. 후보 선택 루프는 상위 render의 잔여 범위.',
 'pips':'모든 실제 phase2 보스와 일반/무효 적×단계0/1/2×ko/en의 전체 단계 표시.',
 'miko_full':'2변형×자기/타인×HP0/부족/상한 직전/상한×대기 음수/0/양수/큰 값. HP/g/mk·전체 payload/h/log/T. 직접 함수 입력의 중립/무장비 도메인.',
 'urda_round_full':'16생존×공격/방어 약화4조합×HP부족/가득. 낮은 HP 비율 동률·치료/해제 우선순위·유효 대상 없음, 전체 HP/buff/h/payload/log/T. 중립/무장비 도메인.',
 'hildegard_full':'도발/캐시/기존 target/공격·방어·행동 없음/확률 경계/비table x의 전체 enemy target/x, trait payload/log/T/RNG 소비. 실제 _hg_scan에서 호출.',
}
fixed={
 'P2020':'우르다 라운드 회복·해제의 원본 trait/log/HP 이력·T를 실제 _round_tick에 연결.',
 'P2079':'행동 목록이 빈 적을 안전하게 건너뛰고 원본 표적 전환 trait payload를 실제 _hg_scan에 기록.',
 'P2201':'미코 PRUN의 짧은 기술명·회복 이력·원본 shield/boost payload·두 줄 로그·T를 실제 run에 연결.',
 'P2307':'소수 시각을 곱한 값 대신 binary64 significand로 반올림. 1.325→1.32 등 Lua/C printf와 일치.',
 'P2328':'HUD도 같은 정확한 binary64 1/2자리 반올림을 사용.',
 'P2363':'레이드도 같은 정확한 binary64 1/2자리 반올림을 사용.',
}
counts=Counter(r['op'] for r in oracle['rows']);cov={r['id']:r for r in coverage['rows']}
assert observed['checks']==len(oracle['rows'])==len(observed['rows']) and not observed['failures']
for want,got in zip(oracle['rows'],observed['rows']):assert got['ok'] and want['expected']==got['want']
def native(file,symbol):
 p=R/'project/game'/file
 return {'file':'project/game/'+file,'symbol':symbol,'line':next(i+1 for i,s in enumerate(p.read_text(encoding='utf-8').splitlines()) if symbol in s)}
rows=[]
for old in base['rows']:
 r=dict(old);r['round4_status']=r['status'];r['branch_coverage']=cov[r['id']]
 if r['id'] in mapping:
  op,file,symbol=mapping[r['id']];assert r['status']!='같음';assert cov[r['id']]['called'] and not cov[r['id']]['remaining_entries'],r['id']
  r.update(status='같음',remaining_reason=None,unverified_branches=[],native_evidence=native(file,symbol))
  ops=[op]+({'P2324':['fx_sequence','frame','fx_optional'],'P2318':['fx_optional'],'P2321':['fx_optional']}.get(r['id'],[]))
  r['new_evidence']=r['new_evidence']+[{'test':'battle_r23_round5_test','labels':['round5/'+k for k in ops],'checks':sum(counts[k] for k in ops),'contract':contracts[op],'oracle':'verification/parity-r23/round5-oracle.json','observations':'verification/parity-r23/round5-latest.json','log':'verification/parity-r23/suite-round5-final/battle_r23_round5_test.log'}]
 if r['id'] in fixed:
  r['fixed']=True;r['round5_fix']=fixed[r['id']];r['fix']=(r.get('fix')+' / ' if r.get('fix') else '')+fixed[r['id']]
  if r['id'] not in mapping:r['new_evidence']=r['new_evidence']+[{'test':'battle_r23_round5_test','labels':['round5/printf'],'checks':counts['printf'],'contract':'814개 binary64 반올림. 보존된 실제 수정 전 formatter도 같은 입력을 실행해 64차이 확인.','oracle':'verification/parity-r23/round5-oracle.json','observations':'verification/parity-r23/round5-latest.json'}]
 if r.get('native_evidence'):
  ref=r['native_evidence'];r['native_evidence']=native(Path(ref['file']).name,ref['symbol'])
 rows.append(r)
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
suite=[read(p) for p in (S/'rows').glob('*.json')];missing=sorted(expected-{r['test'] for r in suite});failed=[r['test'] for r in suite if not r['passed']]
assert not missing and not failed,(missing,failed)
assert read(S/'final-code-verification.json')['unchanged']
locked=read(S/'final-code-lock.json')['sha256'];assert locked==read(S/'tested-code.json')
assert all(sha(R/p)==h for p,h in locked.items())
recheck=read(S/'final-recheck-plan.json');assert recheck['sha256']==locked
for name in recheck['rerun']+recheck['already_final']:
 record=read(S/'rows'/(name+'.json'))
 assert (S/'rows'/(name+'.json')).stat().st_mtime-record['seconds']>recheck['last_code_edit']+2,name
assert read(S/'local-server-result.json')['exit']==0
manifest=read(O/'round5-start-manifest.json');protected={}
for folder in ['docs','project/assets','server']:
 current={str(p.relative_to(R)).replace('\\','/'):sha(p) for p in (R/folder).rglob('*') if p.is_file()}
 before={p:h for p,h in manifest.items() if p.startswith(folder+'/')};assert current==before,folder
 protected[folder]={'files':len(current),'changed':[]}
assets=read(R/'ASSET-HASHES.json');assert len(assets)==96 and all(sha(R/a['path'])==a['sha256'] for a in assets)
for file,h in oracle['provenance'].items():assert sha(Path('C:/Clauede Code/dungeon-bot/bot/src')/file)==h
for file,data in read(O/'coverage/instrumentation.json').items():assert sha(Path('C:/Clauede Code/dungeon-bot/bot/src')/file)==data['source_sha256']
assert len(coverage['runs'])==20 and all(r['exit']==0 for r in coverage['runs'])
parity=[]
for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
 j=read(R/'verification/data-r21'/(name+'.json'));assert j['battles']==j['equal_battles'] and j['source_actions']==j['actual_actions']==j['matched_actions'];parity.append(j)
p2=read(R/'verification/data-r21/p2-full-battles.json');assert not p2['different_actions']
battles=sum(j['battles'] for j in parity)+p2['battles'];records=sum(j['source_actions'] for j in parity)+p2['compared_actions'];assert (battles,records)==(6320,219785)
visual=read(O/'visual-review-round5.json');assert all(x['viewed'] and sha(R/x['path'])==x['sha256'] for x in visual['images'])
products=[str(p.relative_to(R)).replace('\\','/') for p in sorted((R/'project/game').glob('*.gd')) if manifest.get(str(p.relative_to(R)).replace('\\','/'))!=sha(p)]
before={}
for name in ['round5-before','round5-native-before','round5-format-before']:
 j=read(O/(name+'.json'));bad=[r for r in j['rows'] if not r['ok']]
 before[name]={'checks':j['checks'],'failures':len(bad),'api_guard_failures':sum(r['got']=='API unavailable' for r in bad),'failed_operations':dict(Counter(r['label'].split('/')[1] for r in bad))}
assert sha(O/'round5-before-display.gd')==manifest['project/game/combat_display_r22.gd']
summary={**base['summary'],'newly_equal_rows':sum(r['status']=='같음' for r in rows),'remaining_rows':sum(r['status']!='같음' for r in rows),'statuses':dict(Counter(r['status'] for r in rows)),'round5_newly_equal_rows':len(mapping),'round5_fixed_rows':len(fixed),'fixed_rows':sum(r['fixed'] for r in rows),'fixed_and_equal_overlap':sum(r['fixed'] and r['status']=='같음' for r in rows),'called_functions':coverage['called_functions'],'newly_entered_baseline_entries':coverage['newly_entered_baseline_entries'],'round5_checks':observed['checks'],'new_checks':base['summary']['new_checks']+observed['checks'],'new_failures':0,'suite_groups':len(suite),'expected_suite_groups':len(expected),'suite_missing':missing,'suite_failed_groups':0,'suite_in_progress':[],'suite_final_code_complete':True,'fresh_oracle_runs':len(coverage['runs']),'parity_battles':battles,'parity_records':records,'round5_product_files_changed':products,'product_files_changed':sorted(set(base['summary']['product_files_changed']+products)),'protected':protected}
summary['fixed_but_not_equal_rows']=sum(r['fixed'] and r['status']!='같음' for r in rows);summary['neither_equal_nor_fixed_rows']=sum(not r['fixed'] and r['status']!='같음' for r in rows)
payload={**base,'summary':summary,'rows':rows,'round5':{'new_equal_ids':sorted(mapping),'fixed_ids':sorted(fixed),'counts':dict(counts),'before':before,'suite':S.name,'original_assets_verified':96,'method':'실제 원본 Lua 함수/closure의 전체 반환/부수 출력과 동일 입력 Godot를 비교. 20종 oracle 계측 전후 출력 일치. 진입 수만으로 승격하지 않음.','limitations':'source-record → HTML/layer/CSS 호환 ABI. 기존 r17~r20 scene renderer 전체나 B.render/버튼/저장 재개를 승격하지 않음. tile/rail은 VID 없는 호스트 도메인. 개인 훅은 명시된 중립·무장비 입력. 각 행의 계약을 상위/하위 함수로 전파하지 않음.'},'target_tests':base['target_tests']+[{'name':'round5-latest','checks':observed['checks'],'failures':0}]}
payload['round5']['limitations']=payload['round5']['limitations'].replace('tile/rail은 VID 없는 호스트 도메인. ','')
payload['test_tool_files']=sorted(set(base.get('test_tool_files',[])+['project/tests/battle_r23_round5_test.gd','project/tests/battle_r23_round5_test.gd.uid','tools/oracle_battle_r23_round5.lua','tools/oracle_battle_r23_round5.mjs','tools/oracle_battle_r23_round5_loader.mjs','tools/sync_battle_text_r23.py','tools/coverage_battle_r23.py','tools/verify_battle_r23_round5.py','tools/finalize_battle_r23_round5.py','tools/report_battle_r23_round5.py']))
(O/'battle.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');(O/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(S/'final-verification.json').write_text(json.dumps({'passed':True,'groups':len(suite),'missing':missing,'failed':failed,'locked_code_verified':True,'protected':protected,'assets':96,'battles':battles,'records':records},indent=2),encoding='utf-8')
lines=['# R23-battle 5차 작업 보고','',f'대상 212행. 이번 같음 +{len(mapping)}, 누적 같음 {summary["newly_equal_rows"]}, 남음 {summary["remaining_rows"]}. 이번 수정 근거 {len(fixed)}행, 누적 수정 근거 {summary["fixed_rows"]}행. 같음과 수정은 중복한다. 원본 전 기능 완료는 아니다.','',f'신규 대조 {observed["checks"]:,}개 / 실패 0, 누적 신규 대조 {summary["new_checks"]:,}개 / 실패 0. 기존 {battles:,}판 · {records:,}기록 / 차이 0. 전체 프로젝트 검사 {len(suite)}/{len(expected)}그룹 / 실패 0.','', '## 구현과 대조 범위','', '- 40-fx: 모든 사건 분기의 표시 text/class/style/대상/아트/전염/마커/카메라 후보와 전체 L을 source-record ABI로 옮겼다. 29종 사건(미지정 포함)과 1,536개 피격·1,536개 피해 결과를 비교했다. 페르소나 컷인은 인레이/data/http/https/무효/호스트 오류까지 88개를 비교했다.','- HUD primitives: HP/MP/보호막/심연 키프레임 CSS 전체, 상태 chip 4,096개, 기술 예고 352개, 행동 순서표 256개, header 320개와 직업 배지/레이드 단계/로그 전체를 비교했다.','- 실제 개인 훅: 미코 PRUN의 전체 shield/boost/HP 이력/로그/T, 우르다 라운드 회복·해제 우선순위/동률/생사, 힐데가 캐시/빈 행동/확률 경계/비table x와 전체 trait/RNG를 비교했다. 실제 run/_round_tick/_hg_scan에서 새 helper를 사용한다.','- 공용 소수 formatter: 곱셈에서 생기는 반올림 오차를 없애고 binary64 significand를 정수로 처리한다. 1.325→1.32 등 Lua/C printf 814개 경계가 일치한다.','',f'20종 실제 oracle의 계측 전후 출력이 같았다. 대상 함수 {coverage["called_functions"]}/212 호출, 기존 미검증 진입 {coverage["newly_entered_baseline_entries"]}/157 도달(4차 77). 새 같음 35행은 모두 명시 함수/then/else/do 진입에 도달했다. 이는 단락 조건의 모든 조합을 전수 검증했다는 뜻이 아니다. 행 id·원본 위치·4차 상태·시험 라벨·제품 파일:줄·남은 이유는 verification/parity-r23/battle.json에 보존했다.','', '## 실패 확인과 한계','',f'최초 API 추가 전 {before["round5-before"]["checks"]:,}개 모두 API 부재 guard로 실패했다. 이를 기존 수치 버그로 세지 않았다. 새 개인 훅 전 {before["round5-native-before"]["checks"]:,}개 중 {before["round5-native-before"]["failures"]}개가 실패했고 API 부재 guard는 {before["round5-native-before"]["api_guard_failures"]}개였다. 이 관측은 native 훅 변경 전 실행이며 5차 시작 전체 빌드의 재현이라고 주장하지 않는다. 실제 5차 시작 formatter 파일을 보존해 같은 814개를 실행했고 64개 차이를 확인했다.','', '중간 fixture의 sparse Lua table 직렬화, 기록 입력의 언어 불일치, 첫 helper의 GDScript parse 오류는 최종 통과나 제품 버그 수로 세지 않았다. JSON map/array 변환은 지정 필드에만 적용하고 숫자·Boolean·문자열을 강제 변환하지 않는다. 숫자 비교는 기존 1e-7 오차, 문자열과 RNG 횟수는 정확 비교다.','', '새 CombatDisplay.source_frame/Battle.combat_display_frame은 원본 모양 기록을 HTML/layer/CSS로 돌려주는 호환 경계다. 저장 필드를 바꾸지 않으며 r17~r20 native scene renderer를 대체하지 않는다. 이 계층의 일치를 B.render/r_ally/r_enemy/버튼/저장 재개 전체 완료로 확대하지 않았다. tile/rail 대조는 VID 없는 호스트의 기본 실루엣 도메인이며 프로필 이미지 경로는 fx_pcutin에서만 전수 입력을 비교했다. 개인 훅 대조의 새 전체 payload는 명시된 중립·무장비 도메인이다. 기존 장비·혼합 6,320판의 수치/RNG 회귀도 유지한다.','', '번역·배지·단계 보스 id는 실제 원본 Lua의 데이터 정의를 tools/sync_battle_text_r23.py로 가져온 것이다. fixture 결과값을 제품 규칙으로 복사하지 않았다.','', '## 검사와 보존','', '전체 로그: verification/parity-r23/suite-round5-final/. import, 모든 *_test, 필수 UI/integration/export_licenses와 전투 8묶음을 실행했다. final-code-lock.json/tested-code.json/final-code-verification.json/final-verification.json으로 최종 코드 일치를 확인했다. 클라우드는 node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs를 고유 loopback 포트로 실행하고 D1 준비 완료 후 검사해 정상 종료했다.','', 'docs/·project/assets/·server/의 추가/삭제/바이트 변경 0, 원본 이미지 96개 해시 일치. Web export·버전 갱신·커밋 없음. 초기 확인의 git status는 소유권 오류로 실패했으며 공통 규칙을 읽은 뒤 git 명령은 더 사용하지 않았다. 사용자 저장은 열지 않았고 모든 Godot 실행은 격리된 tools/godot_r17.py 경로를 사용했다.','', '전투 결과 이미지를 직접 열어 확인한 내용과 파일 해시는 verification/parity-r23/visual-review-round5.json에 있다. 원본 이미지 바이트와 기존 연출·배치는 유지했다. 전수 이미지·실기기·Web/WASM은 이번에 시험하지 않았다. Windows root certificate store 진단만 환경 메시지로 제외했고 Script error/나머지 ERROR는 실패로 센다.','', '이번 제품 변경 파일:','',*['- '+p for p in products],'', '## 남은 행','']
for group in sorted({r['feature_group'] for r in rows}):
 rs=[r for r in rows if r['feature_group']==group];lines.append(f'- {group}: 같음 {sum(r["status"]=="같음" for r in rs)}, 남음 {sum(r["status"]!="같음" for r in rs)}.')
lines+=['', '남은 핵심은 VER2/채팅 저장/pend·pid 재개, 시작·종결의 전체 상태, 적 소환/단계/공격·방어의 전체 부수 효과, 남은 개인 기술, native 타일/버튼/최상위 렌더의 전체 의미 출력이다. 각 행의 이전 사유를 유지했다.','', '재실행: node tools/oracle_battle_r23_round5.mjs → python tools/sync_battle_text_r23.py → python tools/coverage_battle_r23.py → python tools/verify_battle_r23_round5.py → 이미지 검토 → python tools/report_battle_r23_round5.py. 4차 보고와 ledger는 R23-battle-round4.md/battle-round4.json으로 보존했다.']
lines=[line.replace('tile/rail 대조는 VID 없는 호스트의 기본 실루엣 도메인이며 프로필 이미지 경로는 fx_pcutin에서만 전수 입력을 비교했다. ','tile/rail도 VID/프로필/호스트 오류 경계를 별도로 비교했다. ').replace('행동 순서표 256개','행동 순서표 292개') for line in lines]
lines.insert(lines.index('## 검사와 보존')+2,'검사 도중 프로필/false 기본값과 번역 데이터 범위를 보강했다. 첫 전체 검사의 코드 잠금은 변경을 감지해 거부되며, 마지막 수정 전에 시작한 검사와 import를 최종 코드로 다시 실행했다. final-recheck-plan.json과 first-pass/에 해당 목록·이전 결과를 보존했다.\n')
(R/'R23-battle.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({k:summary[k] for k in ['round5_newly_equal_rows','newly_equal_rows','remaining_rows','round5_checks','fixed_rows','suite_groups','parity_battles','parity_records']},ensure_ascii=False))
