"""Assemble row evidence only after fresh Lua, Godot and final-code checks."""
from pathlib import Path
from collections import Counter
import hashlib,json,sys
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round4-final'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
base=read(O/'battle-round3.json');oracle=read(O/'round4-oracle.json');observed=read(O/'round4-latest.json');coverage=read(O/'coverage.json')
mapping={
 'P1474':('record','combat_record_r23.gd','static func say',''),
 'P1477':('record','combat_record_r23.gd','static func begin',''),
 'P1482':('record','combat_record_r23.gd','static func set_field',''),
 'P1485':('record','combat_record_r23.gd','static func push',''),
 'P1715':('tick','dungeon_enemy_r21.gd','func tick_buffs',''),
 'P1724':('trait_payload','combat_record_r23.gd','static func trait_line',''),
 'P1881':('attack_split','dungeon_enemy_r21.gd','func attack_bonus',''),
 'P2363':('f2','combat_display_r22.gd','static func fixed_two',''),
 'P1957':('haldric','personal_rules_r22.gd','static func haldric',''),
 'P2017':('urda','personal_rules_r22.gd','static func urda',''),
 'P2205':('miko_deal','personal_rules_r22.gd','static func miko_deal',''),
 'P2207':('miko_round','personal_rules_r22.gd','static func miko_round',''),
 'P2235':('ptx','trait_rules_r22.gd','static func passive_text',''),
 'P2236':('ptx','trait_rules_r22.gd','static func passive_text',''),
 'P2239':('pnode','trait_rules_r22.gd','static func passive_node',''),
 'P2267':('trait_payload','combat_record_r23.gd','static func trait_line',''),
 'P2268':('refresh','trait_rules_r22.gd','static func refresh',''),
 'P2292':('double_full','trait_rules_r22.gd','static func turn_end',''),
 'P2300':('kill_full','trait_rules_r22.gd','static func kill_credit',''),
 'P1664':('ps_level','persona_research_r21.gd','static func level',''),
 'P1666':('ps_parts','persona_research_r21.gd','static func clean',''),
 'P1671':('ps_meta','persona_research_r21.gd','static func skill_name',''),
 'P1672':('ps_meta','persona_research_r21.gd','static func description',''),
 'P1673':('ps_meta','persona_research_r21.gd','static func skill',''),
 'P1678':('ps_label','persona_combat_r22.gd','static func part_label',''),
 'P2307':('f2','combat_display_r22.gd','static func fixed_two',''),
 'P2316':('kx','combat_display_r22.gd','static func scale_style',''),
 'P2319':('tagcls','combat_display_r22.gd','static func tag_class',''),
 'P2327':('ratio','combat_display_r22.gd','static func ratio_text',''),
 'P2328':('f2','combat_display_r22.gd','static func fixed_two',''),
}
# Evidence text is written in Korean; keep code-level contracts compact.
contracts={
 'record':'원본 모양의 기록 ABI 전체. journal/pre/h/list/T/q0·임의 payload·반환 참조 보존. 실제 native 연출 전체의 동치를 뜻하지 않음.',
 'tick':'버프 수명·fresh·source 없음/0/1/2/5·보조 필드 전체. tick_buffs를 후속 aura 제거와 분리하여 시험.',
 'trait_payload':'원본 trait_line 및 실제 34-traits wrapper의 전체 event·at·ab·문구.',
 'attack_split':'480경계의 배율·태그 전체와 별도 am 합성. 자기 강화분을 함수 반환에서 분리.',
 'f2':'40-fx/50-render/51-raid의 서로 다른 실제 closure를 모두 실행. 정확한 중간값의 C printf 짝수 반올림과 음수 0 포함.',
 'haldric':'16생존×8줄 편성. 자신·첫 다른 대상·fresh·source 및 전체 buff/event/HTML log/T.',
 'urda':'256버프·기존 doubled 조합. 동률·우선순위·70% 상한·남은 수명·보조 필드·전체 event/log/T.',
 'miko_deal':'4변형×mk 없음/음수/0/양수×opt 캐시 없음/음수/0/양수×opt 유무. nil/값/tags/x/opt 전체.',
 'miko_round':'4변형×16생존×4대기시간. 자기 제외·동률·음수·0·전체 g/event/log/T.',
 'ptx':'모든 종족·출신 문구와 알려진/알 수 없는/잘못된 placeholder. 숫자/비숫자·정수/소수·백분율 변환 전체.',
 'pnode':'14종족·출신 node의 모든 필드와 무효 키의 nil.',
 'refresh':'15표식×0~4인×16생존. sy 전체 및 죽은 아군까지 4인의 bx.',
 'double_full':'3actor×4인원×16생존×기존 2회 행동×4강제 RNG. sy/bx/g/dbl/event/log/T/RNG 소비 전체.',
 'kill_full':'nil/0/1/4/5/7 actor×5인원×16생존×가득/부족 HPMP. HPMP/필드 이력/event/T 및 SKON 복원.',
 'ps_level':'22종 단계 경계: 공백·16진 소수·p지수·무효·Boolean·map. 같은 값을 clean/parts에도 대입.',
 'ps_parts':'66입력의 p/s/v 모든 필드. native clean+part 조합을 원본 ps_parts와 직접 비교.',
 'ps_meta':'전체 접두·접미×4강화 단계×ko/en×force 및 미완성/무효 입력. 이름·설명·skill 모든 필드/nil. native는 명시 lang 경계.',
 'ps_label':'32종 실제 part/언어 입력의 label 반환.',
 'kx':'false/음수/0/1/1초과의 전체 CSS scale 문자열.',
 'tagcls':'빈/일반/약점/고갈/여우불 및 경쟁 문자열의 class·우선순위.',
 'ratio':'16값×4분모. 0 이하 분모의 숫자0과 정상 문자열 구별·0~100 clamp.',
}
fixed={
 'P1474':'새 기록 ABI에서 nil/Boolean/숫자/문자열/map journal 값을 원본처럼 보존.',
 'P1477':'새 기록 ABI의 q=false를 빈 queue로 대체하고 q0의 원본 truthiness 보존.',
 'P1482':'새 기록 ABI에서 ev=false 무기록과 nil 필드 삭제/이력의 nil 필드 생략.',
 'P1485':'새 기록 ABI에서 nil push는 추가하지 않고 scalar/Boolean payload와 반환값 보존.',
 'P1664':'단계의 Lua tonumber 규칙(공백·16진 소수·p 지수)을 공유 계산기로 연결.',
 'P1666':'parts 정규화가 같은 단계 문자열 규칙을 사용.',
 'P1671':'ko/en 및 force에 따른 이름과 미완성 문구.',
 'P1672':'자동 영어 설명·미완성 문구를 명시 lang 경계에 연결.',
 'P1673':'skill의 name/d도 같은 표시 언어 사용.',
 'P1957':'자기 자신은 생존 목록과 별도로 원본처럼 계약 적용. 첫 대상/source/fresh·전체 payload/log 추가.',
 'P2201':'variant1 기술이 회복한 대상에게 다음 공격 강화 mk 부여. 이 행의 전체 로그는 남음.',
 'P2205':'variant1의 mk 소비와 opt.mkv 재사용을 구현. 일반 공격/다중 표적 실제 피해도 직접 대조.',
 'P2207':'변형 구분·자기 제외·동률·음수 대기·원본 전체 이벤트와 시간.',
 'P2292':'죽은 아군 차례에서도 먼저 sy/bx 갱신. 전체 특성 payload/log/시간.',
 'P2300':'아군 외 actor를 제외. HP/MP 전체 필드 이력·특성 payload·SKON 보존.',
 'P2307':'소수 문자열 API의 정확한 중간값을 Lua/C printf처럼 짝수로 반올림.',
 'P2328':'HUD 소수 문자열도 같은 C 반올림을 사용.',
 'P2363':'레이드 소수 문자열도 같은 C 반올림을 사용.',
}
assert not observed['failures'] and observed['checks']==len(oracle['rows'])==len(observed['rows'])
for want,got in zip(oracle['rows'],observed['rows']):assert want['expected']==got['want'] and got['ok']
cov={r['id']:r for r in coverage['rows']};counts=Counter(r['op'] for r in oracle['rows'])
def native(file,symbol):
 p=R/'project/game'/file
 return {'file':'project/game/'+file,'symbol':symbol,'line':next(i+1 for i,s in enumerate(p.read_text(encoding='utf-8').splitlines()) if symbol in s)}
rows=[]
for old in base['rows']:
 r=dict(old);r['round3_status']=r['status'];r['branch_coverage']=cov[r['id']]
 if r['id'] in mapping:
  op,file,symbol,_=mapping[r['id']]
  assert cov[r['id']]['called'] and not cov[r['id']]['remaining_entries'],r['id']
  ops=[op]+({'P1474':['record_edge'],'P1477':['record_edge'],'P1482':['record_edge'],'P1485':['record_edge'],'P2205':['miko_attack'],'P1664':['ps_clean'],'P1666':['ps_clean']}.get(r['id'],[]))
  r.update(status='같음',remaining_reason=None,native_evidence=native(file,symbol))
  r['new_evidence']=r['new_evidence']+[{'test':'battle_r23_round4_test','labels':['round4/'+x for x in ops],'checks':sum(counts[x] for x in ops),'contract':contracts[op],'oracle':'verification/parity-r23/round4-oracle.json','observations':'verification/parity-r23/round4-latest.json','log':'verification/parity-r23/suite-round4-final/battle_r23_round4_test.log'}]
 if r['id'] in fixed:r.update(fixed=True,fix=fixed[r['id']])
 if r['id']=='P2201':
  r['remaining_reason']='48변형/대상/HP/게이지 입력의 회복·당김·mk를 직접 대조했고 variant1 mk 부여를 수정. 전체 PRUN의 부스트 특성 문구/원본 이벤트·필드 시간은 남음.'
  r['new_evidence']=r['new_evidence']+[{'test':'battle_r23_round4_test','labels':['round4/miko_run'],'checks':counts['miko_run'],'contract':r['remaining_reason'],'oracle':'verification/parity-r23/round4-oracle.json','observations':'verification/parity-r23/round4-latest.json'}]
 if r.get('native_evidence'):
  ref=r['native_evidence'];r['native_evidence']=native(Path(ref['file']).name,ref['symbol'])
 rows.append(r)
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
suite=[read(p) for p in sorted((S/'rows').glob('*.json'))]
missing=sorted(expected-{r['test'] for r in suite});failed=[r['test'] for r in suite if not r['passed']]
pending=[r['test'] for r in suite if (S/(r['test']+'.log')).stat().st_mtime_ns>(S/'rows'/(r['test']+'.json')).stat().st_mtime_ns]
manifest=read(O/'round4-start-manifest.json')
protected={n:h for n,h in manifest.items() if n.startswith(('docs/','project/assets/','server/'))}
assert all((R/n).exists() and sha(R/n)==h for n,h in protected.items())
assert {str(p.relative_to(R)).replace('\\','/') for d in ['docs','project/assets','server'] for p in (R/d).rglob('*') if p.is_file()}==set(protected)
assets=read(R/'ASSET-HASHES.json');assert len(assets)==96 and all(sha(R/a['path'])==a['sha256'] for a in assets)
source=Path('C:/Clauede Code/dungeon-bot/bot/src')
for name,h in oracle['provenance'].items():assert sha(source/name)==h
for name,m in read(O/'coverage/instrumentation.json').items():assert sha(source/name)==m['source_sha256']
parity=[]
for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
 j=read(R/'verification/data-r21'/(name+'.json'));assert j['battles']==j['equal_battles'] and j['source_actions']==j['actual_actions']==j['matched_actions'];parity.append(j)
p2=read(R/'verification/data-r21/p2-full-battles.json');assert not p2['different_actions']
battles=sum(j['battles'] for j in parity)+p2['battles'];records=sum(j['source_actions'] for j in parity)+p2['compared_actions'];assert (battles,records)==(6320,219785)
products=[str(p.relative_to(R)).replace('\\','/') for p in sorted((R/'project/game').glob('*.gd')) if manifest.get(str(p.relative_to(R)).replace('\\','/'))!=sha(p)]
before={}
for name in ['round4-before','round4-miko-before','round4-miko-inline-before','round4-before-format']:
 j=read(O/(name+'.json'));bad=[r for r in j['rows'] if not r['ok']]
 before[name]={'checks':j['checks'],'failures':len(bad),'failed_operations':dict(Counter(r['label'].split('/')[1] if '/' in r['label'] else r['label'] for r in bad)),'api_guard_failures':sum(r['got']=='API unavailable' for r in bad),'scope':j.get('scope','See R23-battle.md for original-production/API guard/fixture/reconstruction distinctions.')}
summary={**base['summary'],'newly_equal_rows':sum(r['status']=='같음' for r in rows),'round4_newly_equal_rows':len(mapping),'round4_fixed_rows':len(fixed),'fixed_rows':sum(r['fixed'] for r in rows),'fixed_and_equal_overlap':sum(r['fixed'] and r['status']=='같음' for r in rows),'remaining_rows':sum(r['status']!='같음' for r in rows),'statuses':dict(Counter(r['status'] for r in rows)),'called_functions':coverage['called_functions'],'newly_entered_baseline_entries':coverage['newly_entered_baseline_entries'],'round4_checks':observed['checks'],'new_checks':base['summary']['new_checks']+observed['checks'],'new_failures':0,'suite_groups':len(suite),'expected_suite_groups':len(expected),'suite_missing':missing,'suite_failed_groups':len(failed),'suite_in_progress':pending,'parity_battles':battles,'parity_records':records,'round4_product_files_changed':products,'fresh_oracle_runs':len(coverage['runs'])}
summary['fixed_but_not_equal_rows']=sum(r['fixed'] and r['status']!='같음' for r in rows)
summary['product_files_changed']=products
summary['neither_equal_nor_fixed_rows']=sum(not r['fixed'] and r['status']!='같음' for r in rows)
complete=not(missing or failed or pending) and (S/'final-recheck-plan.json').exists()
if complete:
 tested=read(S/'tested-code.json');assert all(sha(R/n)==h for n,h in tested.items())
 lock=read(S/'final-code-lock.json');assert lock['sha256']==tested
 checkplan=read(S/'final-recheck-plan.json')
 for name in checkplan['rerun']:
  record=read(S/'rows'/(name+'.json'));assert (S/'rows'/(name+'.json')).stat().st_mtime-record['seconds']>checkplan['code_lock_time']
 servers=[read(p) for p in S.glob('cloud-control-round4-*-server-result.json')];assert servers and all(r['exit']==0 for r in servers)
 visual=read(O/'visual-review-round4.json');assert all(i['viewed'] and sha(R/i['path'])==i['sha256'] for i in visual['images'])
 (S/'final-verification.json').write_text(json.dumps({'passed':True,'groups':len(suite),'failures':failed,'missing':missing,'pending':pending,'tested_code_sha256_verified':True,'cloud_servers':servers},indent=2),encoding='utf-8')
summary['suite_final_code_complete']=complete
payload={**base,'summary':summary,'rows':rows,'round4':{'new_equal_ids':sorted(mapping),'fixed_ids':sorted(fixed),'counts':counts,'before':before,'suite':S.name,'original_assets_verified':96,'method':'실제 원본 Lua 함수/closure 실행 + 동일 입력의 native 호출. 19종 oracle의 함수/then/else/do 계측 전후 출력이 같아야 함. 진입 수만으로 승격하지 않음.','limitations':'기록 ABI·문자열 helper·개인/시너지 함수의 명시 계약. 전체 전투 로그·모든 native 필드 이력·최상위 저장/렌더 함수의 완료를 뜻하지 않는다. 원본 79-sex.lua는 대상 제외.'}}
payload['target_tests']=base['target_tests']+[{'name':'round4-latest','checks':observed['checks'],'failures':0}]
(O/'battle.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# R23-battle 4차 작업 보고','',f'대상 212행. 이번 같음 +{len(mapping)}, 누적 같음 {summary["newly_equal_rows"]}, 남음 {summary["remaining_rows"]}. 이번 수정 근거 {len(fixed)}행(같음 {sum(k in mapping for k in fixed)}, 일부 유지 {sum(k not in mapping for k in fixed)}), 누적 수정 근거 {summary["fixed_rows"]}행. 같음과 수정은 중복한다. 원본 전 기능 완료는 아니다.','',f'이번 묶음 {observed["checks"]:,}개 / 실패 0, 누적 신규 대조 {summary["new_checks"]:,}개 / 실패 0. 기존 {battles:,}판 · {records:,}기록 / 차이 0.','',f'프로젝트 검사 {len(suite)}/{len(expected)}그룹, 실패 {len(failed)}, 미실행 {len(missing)}, 실행 중 {len(pending)}. '+('최종 코드 검사 완료.' if complete else '검사 진행 중인 초안.'),'','## 이번 근거','',f'19종 실제 원본 oracle를 재실행했다. 계측 전후 출력 일치. 대상 함수 {coverage["called_functions"]}/212 호출, 기존 미검증 진입 {coverage["newly_entered_baseline_entries"]}/157 도달(3차 68). 원본 함수·then/else/do 진입은 실행 근거이며 조건 조합의 완전성을 뜻하지 않는다. 승격 대상은 모든 명시 진입에 도달했고 같은 입력의 계약 출력을 직접 비교했다.','', '- 기록 ABI·trait payload 6행: 6줄 journal, 전체 pre/h/q0, HP/MP/보호막/심연 및 임의 필드, 중첩 payload와 반환 참조. 실제 native 전체 시간 이력까지 완료한 것은 아니다.','- 개인 기술·시너지: 할드리크/우르다 전체 buff/event/HTML log/T, 미코 deal/round, 2회 행동·처치의 전체 부수 효과. 실제 공격/다중 표적에서 variant1 강화와 캐시도 비교했다.','- 연구 단계·parts·문구·skill·label 6행: 모든 조합과 단계/언어/force, 공백·16진 소수·p지수 입력. persona_research_r21.gd는 이 공유 계산·문구 경계 연결만 수정했다. 마을/시설 화면 파일은 수정하지 않았다.','- placeholder/node/refresh, 버프 tick과 aura 청소 분리, 적 배율과 자기 강화 am 분리, 소수·비율·태그·CSS 배율 문자열을 함께 대조했다.','', '같음 30행의 원본 id/위치/이전 상태/새 시험·라벨/제품 파일:줄과 117행의 남은 사유는 verification/parity-r23/battle.json에 있다. 숫자·Boolean·nil·빈 map/array는 스키마로 구분하고, 실수 허용 오차 1e-7 이외 문자열과 RNG 소비 수는 그대로 비교한다.','', '## 실패와 수정 근거','',f'최초 5,592입력은 {before["round4-before"]["failures"]:,}실패였다. 그중 API 부재 guard {before["round4-before"]["api_guard_failures"]:,}개를 실제 수치 실패와 구분한다. 단계 4개, 파생 clean/parts 16개, 언어 출력 516개가 기존 함수의 직접 비교 차이였다. tick 105개는 유효하지 않은 native source id로 후속 aura 삭제까지 비교한 fixture 오류였다. source/수명 계약을 분리한 최종 800개로 대체했다. 이 105개를 제품 버그 수에 넣지 않았다.','', '미코 새 함수 호출 전 384개 guard 실패를 별도로 보존했다. 기존 mk 미적용·기술의 mk 부여 누락은 이전 해당 절을 별도 코드 사본에서 재구성해 56입력 중 26개 차이를 재현했다(round4-miko-inline-before.gd 계열/.json). 전체 과거 빌드가 아니며 나머지 기능의 수정 전 증거로 확대하지 않는다.','', '소수 표기는 첫 새 구현의 일반 Godot 포맷터가 정확한 ±0.125에서 Lua/C printf와 달랐다. 해당 절 재구성 16입력 중 2차이를 보존하고 짝수 반올림으로 통과시켰다. 기존 제품 전체의 수정 전 수치 실패로 세지 않는다. 최초 fixture의 인자 수 parse error, 초기 미코 fixture의 nil/빈 상태/이전 시작 log 불일치, 처음 원본 ptx 입력 순서가 pairs 때문에 달랐던 계측 시도는 통과 검사나 제품 실패로 세지 않았다. 이후 입력 키 순서를 고정하고 19종 모두 계측 전후 출력 일치를 확인했다.','', '## 제품 연결과 제한','', 'CombatRecord는 gear 경계와 같은 원본 모양의 순수 기록 ABI다. CombatEvents가 이를 실제 action 시작·타격 필드·특성 payload에 연결한다. 포팅한 개인/시너지 함수는 원본 전체 payload와 문구를 기록한다. 아직 옮기지 않은 일반 native 로그를 원본 로그로 가장하지 않으며, 기록은 transient이고 저장 schema/version은 바꾸지 않았다. 모든 native 변경 필드가 원본과 같은 시각으로 기록된다고 주장하지 않는다.','', 'UI의 r17~r20 연출 event 목록/원본 이미지 바이트는 유지했다. source-shaped 기록만으로 render/HUD/버튼/카메라 전체를 승격하지 않았다. 미코 PRUN은 회복·당김·variant1 상태를 고쳤지만 전체 로그/이력이 남아 일부로 유지했다. 저장 가능한 상태에서 부가 sy/bx 표식은 시작/라운드/이탈/restore 때 다시 계산하며 옛 저장의 필드를 요구하지 않는다. 사용자 저장은 열지 않았다.','', '이번 변경 제품 파일:','',*['- '+n for n in products],'', '원본 passive 수치는 실제 Lua가 내보낸 데이터에서 tools/sync_battle_passives_r23.py로 가져왔다. 출처 해시를 확인하고 결과값 fixture를 제품 규칙으로 복사하지 않았다. 원정/장비 규칙/서버/마을 화면 파일 수정은 없다.','', '## 검사·보존','', '전체 로그: verification/parity-r23/suite-round4-final/. import, 모든 *_test, 필수 integration/export_licenses, 전투 8묶음을 포함한다. 검사 중 추가한 변경보다 먼저 시작한 검사는 코드 잠금 이후 재실행했다. first-pass/와 final-recheck-plan.json/final-code-lock.json/final-verification.json에 근거가 있다.','', '클라우드 시험은 node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs를 실제 실행했다. 실행별 고유 loopback 포트/제어 파일, worktree 임시 디렉터리, D1 스키마 완료 대기, 정상 종료를 사용했다. 다른 프로세스/포트는 건드리지 않았다.','', 'docs/·project/assets/·server/는 이번 시작 manifest 대비 파일 추가/삭제/바이트 변경 0. 원본 이미지 해시 96개 일치. Web export·버전 갱신·git 명령·커밋 없음. 전투 결과 이미지 3개를 직접 열었고 HUD/대상/버튼/컷인을 확인했다. 작은 폭의 많은 적 이름은 잘림 표시가 보인다. 전수 이미지·실기기·Web/WASM은 시험하지 않았다.','', '## 남은 행','']
for group in sorted({r['feature_group'] for r in rows}):
 rs=[r for r in rows if r['feature_group']==group];lines.append(f'- {group}: 같음 {sum(r["status"]=="같음" for r in rs)}, 남음 {sum(r["status"]!="같음" for r in rs)}.')
lines+=['','남은 핵심은 원본 VER2/채팅 저장/pend·pid 재개, 시작·종결의 전체 상태, 적 소환/단계/방어/공격 전체 로그, 개인 기술의 나머지 부수 효과, HUD·대상·버튼·카메라 전체 의미 출력이다. 개별 이유는 ledger 각 행을 유지했다.','', '재실행: node tools/oracle_battle_r23_round4.mjs → python tools/coverage_battle_r23.py → python tools/verify_battle_r23_round4.py → python tools/finalize_battle_r23_round4.py → python tools/report_battle_r23_round4.py. 3차 보고/ledger는 R23-battle-round3.md 및 battle-round3.json으로 보존했다.']
lines=[line.replace('round4-miko-inline-before.gd 계열/.json','round4-before-miko-core.gd·round4-before-miko-personal.gd / round4-miko-inline-before.json') for line in lines]
lines.insert(lines.index('## 제품 연결과 제한')-1,'새 기록 ABI의 nil/Boolean/scalar 경계 시험은 최초 helper에서 Script error로 중단됐다(round4-record-before.log). 이를 실패 횟수로 꾸미지 않고 최종 144개 통과를 기록했다. 이 네 함수도 이번 수정 근거에 포함한다.')
lines.insert(lines.index('## 남은 행')-1,'첫 전체 검사에서 이름 없는 내부 할드리크 호출 3건의 Script error를 발견했다. 원본처럼 nm/skill 변수를 생략하도록 보완한 뒤 해당 입력 128개도 대조했다. 이전 잠금 후 코드가 바뀌었으므로 최초 잠금 검증은 의도대로 거부했다. 수정 완료 후 다시 잠그고 전체를 재실행했다. Windows root certificate store 메시지만 환경 진단으로 제외하고 Script error 및 다른 ERROR는 실패로 센다.')
(R/'R23-battle.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
if not complete:sys.exit(1)
