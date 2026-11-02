"""Round 3 ledger from actual Lua/Godot observations and completed suite rows."""
from pathlib import Path
from collections import Counter
import hashlib,json,sys,time
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round3-final'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
base=read(O/'battle-round2.json');oracle=read(O/'round3-oracle.json');observed=read(O/'round3-latest.json');coverage=read(O/'coverage.json')
mapping={
 'P1473':('syn','trait_rules_r22.gd','static func int_synergy','생존 16조합의 지능 시너지 표시 배열 전체. 실제 round hook도 같은 helper 사용'),
 'P1604':('legacy_stats','battle_stats_r23.gd','static func enemy_stats','9종 kind(무효 Boolean/숫자 포함) × 7레벨 × 12별 입력(소수/문자열 포함), 전체 5필드'),
 'P1617':('legacy_foes','dungeon_rules_r21.gd','static func foes_for','빈/1~4인 16편성의 옛 고정 적 인덱스 전체'),
 'P1618':('rift','dungeon_rules_r21.gd','func rift_id_of','6균열 id/표시명/의뢰명 및 무효 Boolean/숫자/빈 입력'),
 'P1654':('front','dungeon_rules_r21.gd','func front_before','원본 실제 정렬 closure를 export해 동일 인덱스 포함 모든 쌍 비교. 실제 compose도 같은 comparator 사용'),
 'P1655':('floor_plan','dungeon_rules_r21.gd','func floor_plan','80층 × stage 0/1/2/3의 enc/el/star/info와 dn.stage 전체. 기존 floor_enc의 dn.kind 계약도 유지'),
 'P1699':('names','combat_display_r22.gd','static func unit_name','30인/100적과 무효 이름·user placeholder, ko/en 전체 표시명'),
 'P1713':('boss_half','combat_display_r22.gd','static func boss_half','두 적의 생존/보스 16조합 보조 설명 전체'),
 'P1761':('vconn','combat_display_r22.gd','static func verb_connection','한국어 과거 동사 ㅆ받침·벴 예외·비한글/빈/Boolean/숫자의 반환/nil'),
 'P1864':('names','combat_display_r22.gd','static func unit_name','31-foes의 별도 nm closure도 270 이름/언어 입력 전체 직접 실행'),
 'P1870':('pct','combat_display_r22.gd','static func percent','31-foes pct closure: 음수/0/0.5% 경계/100% 초과, B.floor epsilon 포함'),
 'P1872':('foe_start','dungeon_enemy_r21.gd','func start','fl 없음/있음 × 선제/생존 16조합의 모든 적 g, 실제 battle constructor 연결'),
 'P1875':('defense_tags','dungeon_enemy_r21.gd','func defense_tags','근접/원격/동료/은신/사망 64조합, 배율 및 원본 순서 tags 전체'),
 'P1892':('foe_turn_start','dungeon_enemy_r21.gd','func turn_start','보호·은신 해제/tn 없음·음수·0~3/phase 1·2/순환 없음·있음/3 RNG 상태와 강제 RNG 0~1 clamp/2회 소비. 실제 turn 연결'),
 'P1954':('pct','combat_display_r22.gd','static func percent','32-personal-a pct 실제 closure의 반환과 같은 공유 helper'),
 'P1955':('short','combat_display_r22.gd','static func short_name','빈/일반/중첩/복수/불균형 괄호·탭·Boolean·숫자의 원본 sn 실제 closure'),
 'P1996':('corrode','personal_rules_r22.gd','static func corrode','잘못된 x·오래된 2/7중첩·부식 유무·추가 -1~4·0/소수 공격·방어, 반환 n/per 및 보존 DOT 순서/소유자'),
 'P2040':('felice_save','personal_rules_r22.gd','static func felice_save','자기/타인 × 잘못된 x/빈 map/보조 필드의 nil 반환·death_tick 전체, 실제 save 조건 연결'),
 'P2091':('names','combat_display_r22.gd','static func unit_name','32-personal-b nm 실제 closure의 270 이름/언어 입력 전체'),
 'P2092':('names','combat_display_r22.gd','static func subject','같은 이름 묶음의 bold 주어/한글 받침·ASCII·placeholder/en 조사 전체'),
 'P2093':('bp','combat_display_r22.gd','static func bold_particle','135이름 × 7조사 × 2언어의 bold 문자열 전체'),
 'P2094':('short','combat_display_r22.gd','static func short_name','별도 short 실제 closure의 균형 괄호와 문자열 변환'),
 'P2095':('pct','combat_display_r22.gd','static func percent','32-personal-b pct 실제 closure. 적/개인 태그가 같은 helper 사용'),
 'P2096':('Kc','personal_rules_r22.gd','static func defense_constant','K 없음/0/1/소수 우선과 el 없음/0/1/10/40, 실제 corrode 사용'),
 'P2107':('gunhild','personal_rules_r22.gd','static func gunhild_deal','소유자 불일치·같은/다음 행동·같은/다른 표적·0~20중첩의 nil/배율·gn/gt/gs·tags 전체'),
 'P2120':('bargut_end','personal_rules_r22.gd','static func bargut_turn_end','소유자 불일치·signed g·당김 없음/음수/0/정상/초과의 g와 pull 유지·초기화'),
 'P2218':('drop','personal_rules_r22.gd','static func drop_caster_buffs','3source × 32buff 조합: 없는 bf·다른 source/임의 보조 필드 보존, red20/red만 제거'),
 'P2249':('live_level','trait_rules_r22.gd','static func level','살아 있는 race/nation/missing 표식 × 0~4인 × 생존 16조합. empty/잘못된 표식 12입력도 직접 대조'),
 'P2287':('exp_mult','expedition_rules_r22.gd','func modifiers','출전 pm 기준 3국가의 81편성, 모두 사망해도 출전 기준 EXP 배수. 기존 제품 함수 읽기 전용 비교'),
 'P2301':('trim','trait_rules_r22.gd','static func dot_trim','살아 있는/죽은 적 × 모르가스 0/2/3/4인 × 0~8직업 DOT, FIFO/수명/소유자·비직업 DOT 보존'),
}
fixes={
 'P1892':'약점 순환 RNG=1 경계에서 원본처럼 첫/둘째 인덱스를 clamp하여 범위 초과를 방지.',
 'P1604':'옛 enemy_stats 호환 API 추가. 별은 정수 숫자만 조회하고 소수/문자열/Boolean은 원본 기본 별로 fallback.',
 'P1996':'부식이 원본 저장의 K 우선값을 사용하고 B.floor epsilon과 반환 n/per를 보존.',
 'P2107':'같은 행동에서 다른 표적을 치면 기존 표적의 연속 타격 보너스를 적용하지 않음.',
 'P2120':'당김이 없거나 0 이하면 signed g와 pull을 그대로 보존. 양수일 때만 소비/0 하한 적용.',
 'P2249':'빈 유닛/문자열 아닌 표식을 살아 있는 표식 수에서 제외.',
}
counts=Counter(r['op'] for r in oracle['rows']);cov={r['id']:r for r in coverage['rows']}
def native(file,symbol):
 p=R/'project/game'/file
 return {'file':'project/game/'+file,'line':next(i+1 for i,s in enumerate(p.read_text(encoding='utf-8').splitlines()) if symbol in s),'symbol':symbol}
rows=[]
for original in base['rows']:
 r=dict(original);r['round2_status']=r['status'];r['branch_coverage']=cov[r['id']]
 if r['id'] in mapping:
  op,file,symbol,contract=mapping[r['id']]
  assert cov[r['id']]['called'] and not cov[r['id']]['remaining_entries'],r['id']
  ops=[op]+({'P2249':['broken_level'],'P1892':['foe_turn_bound']}.get(r['id'],[]))
  r.update(status='같음',remaining_reason=None,native_evidence=native(file,symbol))
  r['new_evidence']=r['new_evidence']+[{'test':'battle_r23_round3_test','labels':['round3/'+x for x in ops],'checks':sum(counts[x] for x in ops),'contract':contract,'oracle':'verification/parity-r23/round3-oracle.json','observations':'verification/parity-r23/round3-latest.json','log':'verification/parity-r23/suite-round3-final/battle_r23_round3_test.log'}]
 if r['id'] in fixes:r['fixed']=True;r['fix']=fixes[r['id']]
 if r['id']=='P1881':
  r['remaining_reason']='분노/장기전 160입력의 배율과 nil/태그 문자열은 직접 일치. 원본의 am은 호출자에서 곱하지만 native attack_mult는 enemy_attack_self를 함께 곱하므로, 자기 강화가 있는 입력의 반환 정규화 계약을 분리 검증하기 전까지 일부 유지.'
  r['new_evidence']=r['new_evidence']+[{'test':'battle_r23_round3_test','labels':['round3/attack_tags'],'checks':counts['attack_tags'],'contract':'자기 강화 없는 160경계의 배율/태그 문자열. am 분배까지 전체 같음으로 세지 않음.','oracle':'verification/parity-r23/round3-oracle.json','observations':'verification/parity-r23/round3-latest.json','log':'verification/parity-r23/suite-round3-final/battle_r23_round3_test.log'}]
 if r.get('native_evidence'):
  ref=r['native_evidence'];r['native_evidence']=native(Path(ref['file']).name,ref['symbol'])
 rows.append(r)
assert len(observed['rows'])==observed['checks']==len(oracle['rows'])
assert not observed['failures'] and all(r['ok'] for r in observed['rows'])
for case,actual in zip(oracle['rows'],observed['rows']):assert case['expected']==actual['want']
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
suite=[read(p) for p in sorted((S/'rows').glob('*.json'))]
missing=sorted(expected-{r['test'] for r in suite});failed=[r['test'] for r in suite if not r['passed']]
pending=[r['test'] for r in suite if (S/(r['test']+'.log')).stat().st_mtime_ns>(S/'rows'/(r['test']+'.json')).stat().st_mtime_ns]
protected=read(O/'round3-start-protected.json')
changes=[n for n,h in protected.items() if not (R/n).exists() or hashlib.sha256((R/n).read_bytes()).hexdigest()!=h]
assert not changes,changes
current_protected={str(p.relative_to(R)).replace('\\','/') for f in ['docs','project/assets','server'] for p in (R/f).rglob('*') if p.is_file()}
assert current_protected==set(protected),'Protected file set changed'
assets=read(R/'ASSET-HASHES.json');assert len(assets)==96
assert all(hashlib.sha256((R/a['path']).read_bytes()).hexdigest()==a['sha256'] for a in assets)
for f,h in oracle['provenance'].items():assert hashlib.sha256((Path('C:/Clauede Code/dungeon-bot/bot/src')/f).read_bytes()).hexdigest()==h
for f,m in read(O/'coverage/instrumentation.json').items():assert hashlib.sha256((Path('C:/Clauede Code/dungeon-bot/bot/src')/f).read_bytes()).hexdigest()==m['source_sha256']
parity=[]
for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
 j=read(R/'verification/data-r21'/(name+'.json'))
 assert j['battles']==j['equal_battles'] and j['source_actions']==j['actual_actions']==j['matched_actions']
 parity.append(j)
p2=read(R/'verification/data-r21/p2-full-battles.json');assert not p2['different_actions']
battles=sum(j['battles'] for j in parity)+p2['battles'];records=sum(j['source_actions'] for j in parity)+p2['compared_actions']
assert (battles,records)==(6320,219785)
old_hash=read(O/'suite-round2-final/tested-code.json')
products=[n for n,h in old_hash.items() if n.startswith('project/game/') and hashlib.sha256((R/n).read_bytes()).hexdigest()!=h]
before={}
for name in ['round3-before','round3-text-before','round3-stats-before','round3-lifecycle-before','round3-before-inline','round3-cycle-before']:
 j=read(O/(name+'.json'));bad=[r for r in j['rows'] if not r['ok']]
 before[name]={'checks':j['checks'],'failures':len(bad),'failed_operations':dict(Counter(r['label'].split('/')[1] for r in bad)),'api_guard_failures':sum(r['got']=='API unavailable' for r in bad),'scope':j.get('scope','Mixed direct production and API-availability guard comparisons. The full old build is not retained.')}
summary={**base['summary'],'newly_equal_rows':sum(r['status']=='같음' for r in rows),'round3_newly_equal_rows':len(mapping),'round3_fixed_rows':len(fixes),'fixed_rows':sum(r['fixed'] for r in rows),'fixed_and_equal_overlap':sum(r['fixed'] and r['status']=='같음' for r in rows),'remaining_rows':sum(r['status']!='같음' for r in rows),'statuses':dict(Counter(r['status'] for r in rows)),'called_functions':coverage['called_functions'],'newly_entered_baseline_entries':coverage['newly_entered_baseline_entries'],'round3_checks':observed['checks'],'new_checks':base['summary']['new_checks']+observed['checks'],'new_failures':0,'suite_groups':len(suite),'expected_suite_groups':len(expected),'suite_missing':missing,'suite_failed_groups':len(failed),'suite_in_progress':pending,'parity_battles':battles,'parity_records':records,'round3_product_files_changed':products,'fresh_oracle_runs':len(coverage['runs'])}
summary['fixed_but_not_equal_rows']=sum(r['fixed'] and r['status']!='같음' for r in rows)
summary['neither_equal_nor_fixed_rows']=sum(not r['fixed'] and r['status']!='같음' for r in rows)
complete=not(missing or failed or pending) and (S/'final-recheck-plan.json').exists()
if complete:
 tested=read(S/'tested-code.json')
 assert all(hashlib.sha256((R/n).read_bytes()).hexdigest()==h for n,h in tested.items())
 servers=[read(p) for p in S.glob('cloud-control-round3-*-server-result.json')]
 good_servers=[r for r in servers if r['exit']==0 and (not r.get('tests') or 'cloud_archive_r22_test' in r['tests'])]
 assert good_servers,'The final cloud recovery server must finish successfully'
 checkplan=read(S/'final-recheck-plan.json')
 for name in checkplan['rerun']:
  record=read(S/'rows'/(name+'.json'))
  assert (S/'rows'/(name+'.json')).stat().st_mtime-record['seconds']>checkplan['code_lock_time']
 visual=read(O/'visual-review-round3.json')
 assert all(i['viewed'] and hashlib.sha256((R/i['path']).read_bytes()).hexdigest()==i['sha256'] for i in visual['images'])
 (S/'final-verification.json').write_text(json.dumps({'passed':True,'groups':len(suite),'failures':failed,'missing':missing,'pending':pending,'tested_code_sha256_verified':True,'cloud_recovery_servers':good_servers,'infrastructure_recovery':'Initial second-pass cloud group startup failed before tests: stale shutdown control, then schema readiness race. Unique controls and full runtime-ready wait fixed the test harness. The entire affected group was rerun; raw failed logs are retained.'},indent=2),encoding='utf-8')
summary['suite_final_code_complete']=complete
payload={**base,'summary':summary,'rows':rows,'round3':{'new_equal_ids':sorted(mapping),'fixed_ids':sorted(fixes),'counts':counts,'before':before,'method':'실제 원본 Lua closure·전역 함수 실행 + 같은 입력 native 호출. 함수/then/else/do 진입은 실행 근거로만 사용. 파생 출력 이름별 중복 함수도 원본 각각을 실행. 기존 6320판도 계측 전후 참조 보존.','suite':'suite-round3-final','limitations':'저장 가능한 native 도메인에서 명시된 입력의 함수 계약. 새 legacy 호환 순수 API의 일치는 옛 저장 전체 이관/전체 기능 완료를 뜻하지 않음. 문자열 보조 함수의 일치는 상위 전체 로그/HUD/버튼 출력의 일치로 확대하지 않음.'}}
payload['target_tests']=base['target_tests']+[{'name':'round3-latest','checks':observed['checks'],'failures':0}]
payload['round3']['original_assets_verified']=96
payload['round3']['protected_files']={f:sum(n.startswith(f+'/') for n in protected) for f in ['docs','project/assets','server']}
(O/'battle.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# R23-battle 3차 작업 보고','',f'대상 212행: 이번 같음 +{len(mapping)}, 누적 같음 {summary["newly_equal_rows"]}, 남음 {summary["remaining_rows"]}. 이번 수정 6행, 누적 수정 근거 {summary["fixed_rows"]}행이며 같음과 {summary["fixed_and_equal_overlap"]}행 중복한다. 원본 전 기능 이식 완료는 아니다.','',f'이번 묶음 {observed["checks"]:,}개 / 실패 0. 누적 신규 대조 {summary["new_checks"]:,}개 / 실패 0. 기존 {battles:,}판 · {records:,}기록 / 차이 0.','',f'프로젝트 검사 {len(suite)}/{len(expected)}그룹, 실패 {len(failed)}, 미실행 {len(missing)}, 실행 중 {len(pending)}. '+('최종 코드 검사 완료.' if complete else '검사 진행 중인 초안.'),'','## 직접 대조와 수정','',f'원본 18종 oracle를 함수/then/else/do 진입 계측으로 재실행했다. 계측 전후 관측값 일치. 대상 함수 {coverage["called_functions"]}/212 호출, 기존 미검증 진입 {coverage["newly_entered_baseline_entries"]}/157 도달(2차 58). 진입 수만으로 승격한 행은 없다. 원본과 96개 원본 이미지의 해시를 직접 확인했다.','', '원본 local closure는 로드 사본에서 실제 closure를 노출한다. 정렬 comparator도 원래 본문을 이름 붙인 closure로 바꿔 export하며, 복사한 대체 함수를 oracle로 쓰지 않는다. Boolean/빈 Lua map의 표현만 명시적으로 정규화한다. 일반 실수 오차 1e-7, 정수·RNG는 정확 비교한다.','', '|새 근거|행 수|','|---|---:|','|옛 능력치·편성·균열·층 계획|5|','|이름·조사·동사·기술명·비율 문구|11|','|보스 설명·적 방어·시작/차례 시작|4|','|개인 특성·부식·시전자 정리·방어 상수|6|','|시너지 표시/생존 표식/경험치/DOT 정리|4|','', '행별 원본 위치·이전 상태·시험 라벨·제품 파일:줄·남은 사유는 verification/parity-r23/battle.json에 있다.','', '수정한 계약: 부식의 저장 K 우선값과 floor epsilon; 군힐트의 같은 행동/다른 표적 무보너스; 바르굿의 당김 없음·음수/0일 때 signed 게이지와 상태 보존; 빈 유닛/비문자열 표식 제외; 옛 적 수치 API의 별 인덱스 기본값. 원본 기대 수치는 변경하지 않았다.','', '수정 전 증거를 구분한다. 첫 1,392개 중 실패 1,186개는 API 부재 guard 1,152개와 기존 부식 수치 실패 34개다. 문자열 API 추가 전에는 177개 guard 실패를 보존했다. 별 입력 확장에서는 378개 실패 중 252개가 typed kind API guard, 126개가 새 호환 API의 실제 fallback 수치 불일치다. 생명주기 확장 전 99개 실패는 API guard 98개와 empty 표식 수치 실패 1개다.','', '군힐트·바르굿의 이전 인라인 절은 별도 사본에서 재구성해 90입력 중 15개 불일치를 재현했다(round3-before-inline.gd/.json). 전체 수정 전 빌드가 아니며 다른 피해/차례 훅과 상위 함수 전체의 실패 수로 합산하지 않는다. 오래된 부분 log의 fixture/parse error가 있는 시도는 통과 검사나 실제 제품 실패 수에 넣지 않았다.','', '새 legacy foes_for/enemy_stats/floor_plan은 호환용 순수 API다. 기존 native 저장 이관이나 시작 흐름 전체의 동치를 뜻하지 않는다. 원래 floor_enc의 dn.kind는 유지한다. 문구 helper를 옮긴 것만으로 상위 로그 전체가 같다고 세지 않았다. 신규 저장 형식·버전은 도입하지 않았고 사용자 저장은 열지 않았다.','', '## 변경 파일','',*['- '+n for n in products],'', 'expedition_rules_r22.gd는 기존 EXP 계산을 읽기 전용 대조했으며 수정하지 않았다. 새 시험은 battle_r23_round3_test.gd, oracle는 tools/oracle_battle_r23_round3.mjs/.lua와 생성된 loader다. 전체 재실행은 tools/verify_battle_r23_round3.py, 최종 수정 전 시작한 검사를 재실행하는 도구는 tools/finalize_battle_r23_round3.py다.','', '## 검사·보존','', '전체 검사 로그: verification/parity-r23/suite-round3-final/. import, 모든 *_test 및 필수 integration/export_licenses와 전체 전투 8묶음을 포함한다. 수정 전 시작한 프로세스의 검사는 시작 시각으로 골라 최종 코드에서 재실행하고 첫 로그/결과는 first-pass/에 보존한다. 판단 근거는 final-recheck-plan.json 및 final-code-lock.json이다.','', '클라우드는 node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs로 실제 Worker/D1 서버를 실행했다. 빈 loopback 포트와 이 worktree의 임시 디렉터리를 사용하며, 기존 다른 포트/프로세스는 종료하지 않는다. 자체 제어 파일로 이번 서버를 정상 종료한다. 서버 제품 파일 수정은 없다.','', 'docs/·project/assets/·server/는 이번 시작 manifest 기준 변경 0. Web export·버전 갱신·git 명령·커밋 없음. 결과 이미지 3개를 직접 확인했으며 경로/해시는 visual-review-round3.json에 있다. 전수 이미지·실기기·Web/WASM 시험은 하지 않았다. Windows root certificate store 메시지만 환경 진단으로 제외하고 Script error/그 밖의 ERROR는 검사 실패로 센다.','', '초기 fixture 실행 1개가 Script error 뒤 종료되지 않아 런타임 프로세스가 남았다. 해당 프로세스에 대한 종료 명령은 OS 접근 거부로 실패했다. 이후 단독 실험에는 quit-after 제한을 사용했다. 다른 기존 런타임 프로세스는 건드리지 않았다.','', '## 남은 작업','']
for group in sorted({r['feature_group'] for r in rows}):
 rs=[r for r in rows if r['feature_group']==group];lines.append(f'- {group}: 같음 {sum(r["status"]=="같음" for r in rs)}, 남음 {sum(r["status"]!="같음" for r in rs)}.')
lines+=['','최종 재검사의 첫 클라우드 묶음은 이전 shutdown 제어 파일을 읽어 서버 시작이 실패했고, 다음 시도는 D1 스키마 준비 전에 시험을 요청했다. 시험 도구를 실행별 고유 제어 파일과 runtime 완료 대기로 고치고 해당 28개 그룹을 모두 재실행했다. 원시 실패 로그는 recheck-*-failed-*.log, 복구 결과는 cloud-group-recovery.log 및 final-verification.json에 남겼다. 서버 제품 코드 수정은 없다.']
lines+=['','RNG=1 약점 순환 경계는 수정 전 실제 제품에서 비교 실패 1개와 범위 초과 Script error를 재현한 뒤 clamp하여 통과시켰다. round3-cycle-before.json/.log는 fixture 오류와 구분한 실제 제품 경계 실패 근거다.']
lines+=['','원본 VER2·채팅 변수·pend/pid 저장 재개, 사건의 모든 필드 시간 이력/payload, 훅 합성과 측정용 변형, 상위 기술/종결의 전체 로그, HUD·대상·버튼·카메라의 의미상 전체 출력은 계속 남는다. 전투 수치가 같다는 이유로 상위 함수를 승격하지 않았다.','', '재실행: node tools/oracle_battle_r23_round3.mjs → python tools/coverage_battle_r23.py → python tools/verify_battle_r23_round3.py → python tools/finalize_battle_r23_round3.py → python tools/report_battle_r23_round3.py. 이전 차수 보고/ledger는 R23-battle-round2.md 및 battle-round2.json으로 보존했다.']
(R/'R23-battle.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
if not complete:sys.exit(1)
