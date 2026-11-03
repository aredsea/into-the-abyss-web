"""Publish per-function evidence after the final-code suite and source replay."""
from pathlib import Path
from collections import Counter
import hashlib,json,time
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round6-final'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
base=read(O/'battle-round5.json');coverage=read(O/'coverage.json');cov={r['id']:r for r in coverage['rows']}
packs={}
for suffix,test in [('', 'battle_r23_round6_test'),('-tiles','battle_r23_round6_tiles_test'),('-enemy','battle_r23_round6_enemy_test')]:
 oracle=read(O/('battle-round6'+suffix+'-oracle.json'));observed=read(O/('battle-round6'+suffix+'-latest.json'))
 assert observed['checks']==len(observed['rows']) and not observed['failures']
 assert all(row['ok'] for row in observed['rows'])
 assert observed['checks']==len(oracle['rows'])*(2 if suffix=='-tiles' else 1)
 for file,digest in oracle['provenance'].items():assert sha(Path('C:/Clauede Code/dungeon-bot/bot/src')/file)==digest
 cached=read(O/'coverage'/('battle-round6'+suffix+'-oracle.json'));canonical=dict(oracle);cached.pop('provenance',None);canonical.pop('provenance',None);assert cached==canonical
 packs[suffix]={'oracle':oracle,'observed':observed,'test':test,'counts':Counter(r['op'] for r in oracle['rows'])}
mapping={
 'P1488':('', 'member_def','battle_source_state_r23.gd','static func member_definition','30명·persona·미지/빈 id × 12직업/미지 값. 표시명/아트/열/특성명/lv/skill를 포함한 반환 전체.'),
 'P1489':('', 'member_skills','battle_source_state_r23.gd','func member_skills','직업·개인 기술의 전체 순서/row/아이콘/MP/설명. 페르소나의 미완성 및 모든 유효 32조합 × 0/10단계.'),
 'P1490':('', 'sk_slot','battle_source_state_r23.gd','static func skill_slot','빈/유효 목록, 1~4칸, 발견/미발견 기술 id. Lua nil은 ABI에서 명시적 false로 전달.'),
 'P1491':('', 'bind','battle_source_state_r23.gd','func bind(','16칸 stale 정의 제거, 빈 칸, 0/1/4 cur, atk/df/미지/빈 pid를 통한 pend 재탐색·취소. 상태/DEF/SK 전체.'),
 'P1498':('', 'foe_def','battle_source_state_r23.gd','func foe_definition','미지/빈 적, chiefb/eliteb/심층/표시 레벨 경계. 모든 실제 단계 보스의 ph1/ph2·2개/1개/없는 cwk를 포함한 정의 전체.'),
 'P1499':('', 'bind_legacy','battle_source_state_r23.gd','func bind_foes','옛 EDEF 4칸의 레벨/정예 표시·DEF 9~16 제거, 새 편성 2칸의 DEF 7~16 제거. bind 묶음과 함께 전 정의 비교.'),
 'P1500':('', 'unit0','battle_source_state_r23.gd','static func unit0','상수 생성 함수의 모든 보조 플래그·태그·bf/x를 포함한 반환 전체. blank_u/fresh 전체 완료로 전파하지 않음.'),
 'P1550':('', 'carry','battle_source_state_r23.gd','static func apply_carry','빈 칸·누락/false/문자열·hex 숫자·음수/0/소수/상한 초과 HP·MP. 네 유닛의 모든 입력 필드 보존/변경 비교.'),
 'P1590':('', 'migrate','battle_source_state_r23.gd','static func migrate','VER2 8유닛·pm 조건, rc/ln/na/bx/x의 타입 조합·개인/페르소나/빈/잘못된 슬롯·다른 버전/유닛 수. 원본 기록 ABI의 전체 반환. native schema-3 저장 형식을 바꾸지 않음.'),
 'P1762':('', 'dmg_line','battle_source_state_r23.gd','func damage_line','ko/en, 연결형/비연결형/목적어 동사, 스킬·보호막·태그·심연·아군/적 처치 32조합의 HTML 전체.'),
 'P1847':('', 'marceline_full','personal_rules_r22.gd','static func marceline_save','자기/타인·사용 전/소진·mhp 0/1/2/3/4/7/100/1003. HP=1→회복·보호막의 시간 이력, trait/log와 반환 전체. 실제 lethal save에 연결.'),
 'P1944':('', 'result_context','battle_source_state_r23.gd','func result_context','옛 fl 없음, 중복/빈/empty 적, 장소 누락/빈/HTML, 탐색/구역/보스 단계와 ko/en의 전체 결과 문구.'),
 'P2033':('', 'felice_full','personal_rules_r22.gd','static func felice_scan','16 생사/대기 조합 × 3시각 × 소진 여부. earliest/tie·비table x·보호막/DOT 유지·bf/taunt/mark/charge 해제·HP 이력·trait/log/T 전체. 실제 _felice_scan에 연결.'),
 'P2341':('-tiles','enemy_tile','combat_tiles_r23.gd','func enemy_tile','ko/en × 256상태. 빈 칸·사망/이력 없음/중복 사망 시각·예고 공개/고갈·정예/보스/심층/하수인·출현/피격/대상·동적 게이지의 HTML 전체.'),
 'P2344':('-tiles','ally_tile','combat_tiles_r23.gd','func ally_tile','ko/en × 128상태 × 1/4칸. persona/캐릭터·빈 칸·생사/충전/배지/SH·동적 필드/아이템 및 자기 대상 금지. 아이템 적합 여부는 원본 it_ok의 외부 의존 입력이며 아이템 규칙 전체를 승격하지 않음.'),
 'P2366':('-tiles','boss_tile','combat_tiles_r23.gd','func enemy_tile','모든 실제 단계 보스를 순환한 512입력. ph/cwk·죽음·충전 예고·고갈·단계선·배지·전체 HTML. native scene renderer의 동치로 확대하지 않음.'),
 'P2368':('-tiles','raid_field','combat_tiles_r23.gd','func raid_field','보스 + 호위/하수인·빈 칸/생사·target anchor·field FX의 HTML 전체. 직접 호출과 Battle.combat_display_tile 통합 경로 모두 비교.'),
 'P1897':('-enemy','turn_end','dungeon_enemy_r21.gd','func turn_end','big 유무·1~4차례·hide_every 없음/2·ranged_dr 없음/0.7의 cq/hid·원본 로그/T 전체.'),
 'P1901':('-enemy','buff','dungeon_enemy_r21.gd','func support_action','6 stat × 4대상 × 누락/0/0.2/1.5 × 8상태 × aura. 기본 amount/turns·self scalar·99턴 aura·shield/pull·부수 기록 전체. 중립/무장비 도메인.'),
 'P1908':('-enemy','debuff','dungeon_enemy_r21.gd','func support_action','5 stat × 전체/단일 × 누락/0/0.3 × 8상태. delay·fallback·taunt 우선순위, bf/대상/사건/로그/T 전체. 중립/무장비 도메인.'),
 'P1911':('-enemy','heal','dungeon_enemy_r21.gd','func support_action','self/일반/미지 대상 × 누락/0/0.2/2 × 8상태. 대상 없음·최저 비율·동률·죽음/상한·HP 시각·기록 전체.'),
 'P1920':('-enemy','protect','dungeon_enemy_r21.gd','func support_action','guard 유무·동료 없음/후열 우선·전체 pt/df/사건/로그/T.'),
 'P1926':('-enemy','special','dungeon_enemy_r21.gd','func support_action','silence/다른 fx/빈 fx·후보 없음, 10직업 × 4실제 PM 씨앗 및 RNG=1 clamp 경계. 전체 봉인 id/기록/T와 실제 RNG 상태. RNG=1은 난수 의존성만 주입한 방어 경계이며 실제 PM 난수 범위와 구분.'),
}
fixed={'P2033':'소생 때 보호막·DOT를 유지하고 원본 HP 이력·trait/log/T를 기록.','P1847':'구원 보호막을 고정 수치로 기록하고 HP=1→회복 시각을 보존.','P1897':'숨기 상태/충전 해제의 원본 종료 로그를 기록.','P1901':'누락 amount·미지 stat/target·aura 지속 규칙과 전체 버프 사건을 원본과 일치.','P1908':'원본 debuff 사건·대상·로그를 실제 적 차례에 기록.','P1911':'회복 대상 없음/회복 시각·payload·로그를 실제 적 차례에 기록.','P1920':'보호 대상/방어의 원본 사건·로그를 기록.','P1926':'후보 유무에 따른 원본 침묵/무효 사건·로그·지속을 기록.'}
rows=[]
for old in base['rows']:
 r=dict(old);r['round5_status']=r['status'];r['branch_coverage']=cov[r['id']]
 if r['id'] in mapping:
  suffix,op,file,symbol,contract=mapping[r['id']];pack=packs[suffix]
  assert r['status']!='같음' and cov[r['id']]['called'] and not cov[r['id']]['remaining_entries'],r['id']
  line=next(i+1 for i,s in enumerate((R/'project/game'/file).read_text(encoding='utf-8').splitlines()) if symbol in s)
  r.update(status='같음',remaining_reason=None,unverified_branches=[],native_evidence={'file':'project/game/'+file,'symbol':symbol,'line':line})
  ops=[op]+(['bind'] if r['id']=='P1499' else ['special_choices'] if r['id']=='P1926' else [])
  r['new_evidence']=r['new_evidence']+[{'test':pack['test'],'labels':['round6/'+k for k in ops],'checks':sum(pack['counts'][k] for k in ops),'contract':contract,'oracle':'verification/parity-r23/battle-round6'+suffix+'-oracle.json','observations':'verification/parity-r23/battle-round6'+suffix+'-latest.json','log':str((S/(pack['test']+'.log')).relative_to(R)).replace('\\','/')}]
 if r['id'] in fixed:r['fixed']=True;r['round6_fix']=fixed[r['id']];r['fix']=(r.get('fix')+' / ' if r.get('fix') else '')+fixed[r['id']]
 if r.get('native_evidence'):
  ref=r['native_evidence'];lines=(R/ref['file']).read_text(encoding='utf-8').splitlines();ref={**ref,'line':next(i+1 for i,s in enumerate(lines) if ref['symbol'] in s)};r['native_evidence']=ref
 rows.append(r)
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
suite=[read(p) for p in (S/'rows').glob('*.json')];assert expected=={r['test'] for r in suite};assert all(r['passed'] for r in suite)
assert read(S/'final-code-verification.json')['unchanged'];locked=read(S/'final-code-lock.json')['sha256'];assert locked==read(S/'tested-code.json');assert all(sha(R/p)==h for p,h in locked.items())
plan=read(S/'final-recheck-plan.json');assert plan['sha256']==locked
for name in plan['rerun']+plan['already_final']:
 row=read(S/'rows'/(name+'.json'));assert (S/'rows'/(name+'.json')).stat().st_mtime-row['seconds']>plan['last_code_edit']+2,name
assert all(sha(R/p)==h for p,h in plan['final_input_sha256'].items())
assert read(S/'local-server-result.json')['exit']==0
assert len(coverage['runs'])==23 and all(r['exit']==0 for r in coverage['runs'])
protected=read(O/'battle-round6-protected-manifest.json')
current={str(p.relative_to(R)).replace('\\','/'):sha(p) for folder in ['docs','project/assets','server'] for p in (R/folder).rglob('*') if p.is_file()};assert current==protected
assets=read(R/'ASSET-HASHES.json');assert len(assets)==96 and all(sha(R/a['path'])==a['sha256'] for a in assets)
parity=[]
for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
 j=read(R/'verification/data-r21'/(name+'.json'));assert j['battles']==j['equal_battles'] and j['source_actions']==j['actual_actions']==j['matched_actions'];parity.append(j)
p2=read(R/'verification/data-r21/p2-full-battles.json');assert p2['different_actions']==0
battles=sum(j['battles'] for j in parity)+p2['battles'];records=sum(j['source_actions'] for j in parity)+p2['compared_actions'];assert (battles,records)==(6320,219785)
visual=read(O/'battle-round6-visual-review.json');assert all(x['viewed'] and sha(R/x['path'])==x['sha256'] for x in visual['images'])
new_checks=sum(pack['observed']['checks'] for pack in packs.values())
products=['battle_source_data_r23.gd','battle_source_state_r23.gd','battle_v3.gd','combat_display_r22.gd','combat_text_r23.gd','combat_tiles_r23.gd','dungeon_enemy_r21.gd','personal_rules_r22.gd'];products=['project/game/'+p for p in products]
summary={**base['summary'],'newly_equal_rows':sum(r['status']=='같음' for r in rows),'remaining_rows':sum(r['status']!='같음' for r in rows),'statuses':dict(Counter(r['status'] for r in rows)),'round6_newly_equal_rows':len(mapping),'round6_fixed_rows':len(fixed),'fixed_rows':sum(r['fixed'] for r in rows),'fixed_and_equal_overlap':sum(r['fixed'] and r['status']=='같음' for r in rows),'called_functions':coverage['called_functions'],'newly_entered_baseline_entries':coverage['newly_entered_baseline_entries'],'round6_checks':new_checks,'new_checks':base['summary']['new_checks']+new_checks,'new_failures':0,'suite_final_code_complete':True,'suite_verification_method':'full numeric/state revision plus single read-only name guard equivalence and 4 final-code checks','suite_groups':len(suite),'expected_suite_groups':len(expected),'suite_failed_groups':0,'suite_missing':[],'suite_in_progress':[],'fresh_oracle_runs':23,'round6_product_files_changed':products,'product_files_changed':sorted(set(base['summary']['product_files_changed']+products)),'parity_battles':battles,'parity_records':records,'protected':{folder:{'files':sum(p.startswith(folder+'/') for p in protected),'changed':[]} for folder in ['docs','project/assets','server']}}
summary['fixed_but_not_equal_rows']=sum(r['fixed'] and r['status']!='같음' for r in rows);summary['neither_equal_nor_fixed_rows']=sum(not r['fixed'] and r['status']!='같음' for r in rows)
before=read(O/'battle-round6-enemy-before.json');bad=[r for r in before['rows'] if not r['ok']]
before_stats={'checks':before['checks'],'failures':len(bad),'missing_amount_guards':sum(isinstance(r['got'],str) for r in bad),'different_unit_outputs':sum(isinstance(r['got'],dict) and r['got']['units']!=r['want']['units'] for r in bad),'method':'이전 turn의 support 분기 추출 재생. 이전 전체 빌드 실행이라고 주장하지 않음.'}
extra_tools=[str(p.relative_to(R)).replace('\\','/') for p in (R/'tools').glob('*battle*round6*') if p.is_file()]+[str(p.relative_to(R)).replace('\\','/') for p in (R/'project/tests').glob('battle_r23_round6*') if p.is_file()]+['tools/sync_battle_state_r23.py','tools/sync_battle_text_r23.py','tools/coverage_battle_r23.py']
write(O/'battle.json',{**base,'test_tool_files':sorted(set(base.get('test_tool_files',[])+extra_tools)),'summary':summary,'rows':rows,'round6':{'new_equal_ids':sorted(mapping),'fixed_ids':sorted(fixed),'checks':new_checks,'before_enemy':before_stats,'suite':S.name,'limitations':'원본 기록 ABI의 정의/이관/HTML 대조와 실제 native 개인/적 지원 훅 대조를 구분한다. B.load/save/press·fresh/run/finish·최상위 render/행동 패널·나머지 기술은 승격하지 않았다. 기존 native 저장을 원본 VER2 저장으로 바꾸지 않는다.'},'target_tests':base['target_tests']+[{'name':'battle-round6'+suffix+'-latest','checks':pack['observed']['checks'],'failures':0} for suffix,pack in packs.items()]})
write(O/'summary.json',summary);write(S/'final-verification.json',{'passed':True,'groups':len(suite),'battles':battles,'records':records,'assets':96,'protected_verified':True,'code_locked':True,'inputs_locked':True})
lines=['# R23-battle 6차 작업 보고','',f'대상 212행. 이번 같음 +{len(mapping)}, 누적 같음 {summary["newly_equal_rows"]}, 남음 {summary["remaining_rows"]}. 이번 수정 근거 {len(fixed)}행, 누적 수정 근거 {summary["fixed_rows"]}행(같음과 중복). 원본 전 기능 완료는 아니다.','',f'신규 대조 {new_checks:,}개 / 실패 0. 누적 신규 대조 {summary["new_checks"]:,}개 / 실패 0. 기존 {battles:,}판 · {records:,}기록 / 차이 0. 전체 프로젝트 {len(suite)}/{len(expected)}그룹 / 실패 0.','', '## 구현과 근거','', '- 원본 기록 편성: 30인/페르소나/미지·빈 칸의 정의와 기술 목록, pend/pid 재탐색·취소, 옛 EDEF·16칸 잔존 정의 제거, VER2 필드 이관과 carry 경계. Battle.combat_display_frame은 정의를 생략하면 원본 기록을 복제·이관·bind하여 표시한다. 기존 native 저장/restore 규칙은 유지한다.','- 표시: 일반 적·보스·레이드 필드·아군 타일 HTML 전체. 직접 호출과 Battle.combat_display_tile 연결을 함께 대조했다. 피해 문구·정산 장소/적 목록의 ko/en 반환도 비교했다. r17~r20 장면 배치는 대체하지 않았다.','- 실제 개인 훅: 펠리체 소생의 보호막·DOT 유지/해제 범위·동률 우선순위·HP 이력/로그/T, 마르셀린 구원의 HP=1→회복·고정 보호막/로그/시각. source 최대 HP=0 방어 경계도 비교했다.','- 실제 적 차례: buff/debuff/heal/protect/special·종료 훅을 분리해 원본 전체 기록을 남긴다. 누락 amount와 지속 기본값, aura·미지 stat/target, 대상 없음, 숨기, 침묵 후보 없음/10직업/실제 RNG·의존성 주입 RNG=1 경계를 포함한다.','',f'함수 {coverage["called_functions"]}/212 호출, 기준 미검증 진입 {coverage["newly_entered_baseline_entries"]}/157 도달(이전 90). 23종 원본 oracle은 계측 전후 출력이 같았다. 함수/then/else/do 진입 계측이며 단락 조건의 모든 조합 전수 검증을 뜻하지 않는다. 행별 이전 상태·원본 위치·라벨·제품 파일:줄·남은 이유: verification/parity-r23/battle.json.','', '## 실패 확인과 한계','', '펠리체 변경 전 동일 96입력에서 39차이를 확인했다. 이전 적 지원 분기를 별도 보존해 1,984입력을 재생했다: '+str(before_stats['failures'])+'실패, 유닛 출력 차이 '+str(before_stats['different_unit_outputs'])+'개, 누락 amount 오류 guard '+str(before_stats['missing_amount_guards'])+'개. 이는 이전 전체 엔진 빌드의 실행이 아니라 이전 turn 분기의 추출 재생이다. 새 API 부재 guard와 fixture 작성 중 오류는 기존 제품 수치 버그 수로 세지 않았다.','', '첫 전체 검사는 일부 독립 전투의 기록장 미초기화 오류를 발견했다. 변경 전 시작한 검사는 first-pass/에 보존하고, 마지막 코드/입력으로 필요한 검사를 재실행했다. final-recheck-plan.json·최종 code/input SHA·전체 로그를 suite-round6-final/에 남겼다. 클라우드는 고유 loopback 포트의 실제 serve.mjs/D1 서버로 실행하고 종료를 확인했다.','', '새 큰 대조 파일은 battle- 접두사를 사용하고 세 파일로 분할했다(각 50 MB 미만). 기존 round5-oracle.json은 이미 52 MB였으며 새 계측 사본은 compact JSON으로 50 MB 미만에 저장한다. 원본 선언 데이터만 제품 상수로 동기화했고 기대값을 규칙으로 복사하지 않았다.','', '초기 보호 해시 목록의 이름이 관측 출력 이름과 충돌해 보존되지 않았다. 따라서 이번 작업 시작부터의 해시 불변을 그 목록으로 주장하지 않는다. 별도 보호 manifest를 만든 이후 검증 구간의 docs/assets/server 해시 불변과 원본 이미지 96개 해시 일치를 확인했다. docs/server에는 이전 5차 manifest와 다른 기존 파일 6개가 있었으며 이번 작업에서 쓰지 않았다. Web export·버전 갱신·커밋 없음.','', '새 HTML/정의/VER2 대조는 원본 기록 호환 경계이며 native 저장의 전면 이관이나 최상위 B.render/버튼 전체 일치로 확대하지 않는다. 개인·적 지원 훅은 명시한 중립/무장비 입력의 전체 부수 출력이고, 장비/혼합 전투는 기존 6,320판의 수치·RNG 회귀로 별도 확인했다. 이미지 검토는 battle-round6-visual-review.json. Web/WASM·실기기·전수 스크린샷은 확인하지 않았다.','', '## 바꾼 제품 파일','',*['- '+p for p in products],'', '## 남은 행','']
for group in sorted({r['feature_group'] for r in rows}):
 rs=[r for r in rows if r['feature_group']==group];lines.append(f'- {group}: 같음 {sum(r["status"]=="같음" for r in rs)}, 남음 {sum(r["status"]!="같음" for r in rs)}.')
lines+=['', '남은 핵심: 채팅 호스트 load/save/press·VER2의 native 전체 저장 재개, 시작/재시작/종결의 전체 상태, fire/chain·공격/소환/단계 전환의 전 부수 출력, 남은 개인 기술, 행동 패널과 최상위 렌더. 각 행의 구체적인 이전 사유를 ledger에 유지했다.','', '재실행: 세 oracle_battle_r23_round6*_loader.mjs → sync_battle_state_r23.py / sync_battle_text_r23.py → coverage_battle_r23.py → verify_battle_r23_round6.py(필요 시 finalize_battle_r23_round6.py) → 이미지 검토 → report_battle_r23_round6.py. 5차 보고/ledger는 R23-battle-round5.md와 battle-round5.json에 보존했다.']
lines[6:6]=[
 '검증 순서는 전체 검사 → 수치·상태 수정 후 영향받은 111그룹 재검사 → 마지막 기술명 누락 방어 한 줄의 동치 확인과 관련 4그룹 최종 코드 검사다. 마지막 변경은 w.skills[id].name을 get("name", "")으로 바꾼 조회 한 줄뿐임을 이전 해시로 역검증했다. 기존 통과 실행은 해당 조회에 도달하지 않았거나 name이 존재했으므로 반환값·상태·RNG·시각이 같다. 이름 없는 입력은 enemy_action/enemy_regression, 최종 표시 연결은 tiles 검사로 확인했다. 이 단계별 근거는 final-recheck-plan.json/name_guard_supplement와 name-guard-before/에 보존했다.',
 '',
 '첫 5,120판 검사에서 펠리체 소생 뒤 페르소나 치명 버프가 남은 2판의 차이를 발견했다. pscrit를 추가한 동일 96입력에서 39실패를 재현하고 수정 후 0실패를 확인했으며, 최종 5,120판도 모두 일치했다. 처음 시도한 기술명 방어 치환이 반영되지 않았던 문제도 실제 파일의 조회 줄을 확인해 수정했다.',
 '',
 'Windows root certificate store 진단만 환경 메시지로 제외했으며 Script error와 다른 ERROR는 실패로 셌다. 사용자 저장을 열지 않았고 Godot는 격리된 tools/godot_r17.py로만 실행했다.',
 ''
]
(R/'R23-battle.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({k:summary[k] for k in ['round6_newly_equal_rows','newly_equal_rows','remaining_rows','round6_checks','fixed_rows','suite_groups','parity_battles','parity_records']}))
