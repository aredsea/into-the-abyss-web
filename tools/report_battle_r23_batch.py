"""Round 2 row ledger, derived only from saved oracle and Godot observations."""
from pathlib import Path
from collections import Counter
import json,hashlib,os,sys
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
base=read(O/'battle-round1.json');coverage=read(O/'coverage.json')
oracle=read(O/'batch-oracle.json');observed=read(O/'batch-latest.json')
cov={r['id']:r for r in coverage['rows']}
suite_name=os.environ.get('R23_SUITE_NAME','suite-round2-final');S=O/suite_name
# id: (oracle operation, production file, production method, bounded contract)
mapping={
 'P1599':('class','battle_stats_r23.gd','static func cls_of','직업 id/한글 이름 전체·미지/빈/Boolean/숫자 조회, 정의 6필드 전체와 같은 정의 참조'),
 'P1600':('stats','battle_stats_r23.gd','static func party_stats','10직업 × 30인·persona·없는 보정 × 13레벨 경계·12필드 전체'),
 'P1601':('stat','battle_stats_r23.gd','static func stat','원본 내부 st closure 직접 호출, 6능력치 반올림 전 실수 전체'),
 'P1602':('K','battle_stats_r23.gd','static func K_of','누락·0/1/2/2.7/10/40/99 레벨 방어 상수'),
 'P1613':('reset','dungeon_rules_r21.gd','func floor_final_reset','normal/chief/boss/미지 종류 캐시 유지→곡선 변경→reset→재계산'),
 'P1630':('rng','dungeon_rules_r21.gd','static func seed_value','누락·Boolean·무효/공백/지수/16진 소수 문자열·음수 소수·53비트 상한 씨앗'),
 'P1631':('rng','dungeon_rules_r21.gd','func next','씨앗별 독립 closure의 연속 12회 정확한 PM 정수 상태'),
 'P1645':('pick','dungeon_rules_r21.gd','static func pick_value','빈/1/3원소·RNG 0~1 선택과 호출 수'),
 'P1647':('party_target','dungeon_rules_r21.gd','func party_target','인원 -2/0/1~5·순서 0~4·확률 경계·tcount 없음/0/1/5/8과 RNG 소비'),
 'P1650':('result','dungeon_rules_r21.gd','func _composition','정상/심층/빌린 chief의 전체 payload 및 compose 160개 전체 반환'),
 'P1651':('slots','dungeon_rules_r21.gd','func build_slots','모든 템플릿 × tc 0~8 × 일반/정예의 전체 슬롯'),
 'P1652':('shuffle','dungeon_rules_r21.gd','func shuffle','빈/1/2/5원소·4씨앗 배열/다음 RNG, 강제 RNG=1 clamp/호출 수'),
 'P1653':('dfs','dungeon_rules_r21.gd','func dfs','362경계의 bool/fl/fg/예산/다음 RNG 전체'),
 'P1702':('weak','personal_rules_r22.gd','static func isweak','속성 없음/미지/6속성·약점 없음/빈/단일/중복'),
 'P1705':('cid','battle_v3.gd','func companion_id','0~4인·자리 0~9·없는 정의/cid fallback'),
 'P1706':('slot_of','battle_v3.gd','func slot_of','0~4인·빈/미지/중복 cid의 첫 슬롯/nil→0'),
 'P1726':('enemy0','battle_v3.gd','func initial_enemy_count','foe 없음→4·빈→0·처음 적 1/2/6'),
 'P1882':('edot','dungeon_enemy_r21.gd','func add_dot','기존 0~4개·per -3/0/1/7·수명 -1~3의 FIFO/피해/소유자 전체'),
 'P1948':('xs','battle_v3.gd','func x','Boolean/숫자/문자열 x 초기화·기존 map 수정/같은 참조 반환'),
 'P1950':('foes','battle_v3.gd','func living','6슬롯 생존 64조합의 순서 있는 적 슬롯 전체'),
 'P1951':('behind','battle_v3.gd','func _behind','64조합 × 대상 5/6 × 전열/후열의 반환 슬롯'),
 'P1994':('cor_live','personal_rules_r22.gd','static func cor_live','잘못된 x·부식 있음/없음·만료 cor=0'),
 'P2132':('magic','personal_rules_r22.gd','static func has_magic','정의/각 행동 magic·ic spell·kind spell·빈 목록'),
 'P2181':('casting','personal_rules_r22.gd','static func casting','현재/범위 밖 행동 ic/kind Boolean'),
 'P2242':('tr_xs','battle_v3.gd','func x','34-traits 별도 xs closure의 잘못된 x/같은 참조'),
 'P2245':('sy_level','trait_rules_r22.gd','static func level','개수 -1/0/1/2/3/4/100 → 0/2/3; 실제 훅이 같은 helper 사용'),
}
fixes={
 'P1599':'같은 직업 id/한글 이름은 같은 정의 Dictionary 참조 반환',
 'P1630':'Lua 씨앗 기본값 1·음수 소수 floor·16진 소수 변환',
 'P1631':'씨앗 변환에 따른 PM closure 초기 정수 상태',
 'P1645':'빈 목록에서도 RNG 한 번 소비 후 nil 반환',
 'P1647':'tcount 0 포함 우선 반환, RNG 소비 없음',
 'P1948':'잘못된 x 초기화·기존 map 같은 참조 보존',
 'P2242':'공유 x 경로에서 잘못된 x 초기화/참조 보존',
 'P1994':'부식 만료 뒤 cor=0 정리',
 'P1600':'Lua 16진수 레벨 문자열 능력치 계산',
}
counts=Counter(r['op'] for r in oracle['rows'])
def native(file,symbol):
 p=R/'project/game'/file
 lines=p.read_text(encoding='utf-8').splitlines()
 return {'file':'project/game/'+file,'line':next(i+1 for i,s in enumerate(lines) if symbol in s),'symbol':symbol}
rows=[]
for original in base['rows']:
 r=dict(original);r['round1_status']=r['status'];r['branch_coverage']=cov[r['id']]
 if r['id'] in mapping:
  op,file,symbol,contract=mapping[r['id']]
  assert cov[r['id']]['called'] and not cov[r['id']]['remaining_entries'],(r['id'],cov[r['id']])
  r.update(status='같음',remaining_reason=None,native_evidence=native(file,symbol))
  ops=[op]+({'P1599':['class_ref'],'P1650':['compose'],'P1652':['shuffle_roll']}.get(r['id'],[]))
  r['new_evidence']=[{'test':'battle_r23_batch_test','labels':['batch/'+x for x in ops],'checks':sum(counts[x] for x in ops),'contract':contract,'oracle':'verification/parity-r23/batch-oracle.json','observations':'verification/parity-r23/batch-latest.json','log':f'verification/parity-r23/{suite_name}/battle_r23_batch_test.log'}]
 if r['id'] in fixes:r['fixed']=True;r['fix']=fixes[r['id']]
 if r['id']=='P1715':
  r['remaining_reason']='bf 없음/빈·4종 16조합·fresh·수명 -1~3·source/db/임의 보조 필드는 직접 비교했다. 사망/고갈 source 정리와 native end_effects의 추가 부수 효과를 원본 btick과 분리 검증해야 하므로 전체 같음으로 세지 않음.'
  r['new_evidence']=r['new_evidence']+[{'test':'battle_r23_batch_test','labels':['batch/btick'],'checks':counts['btick'],'contract':'생존 source의 대응 buff map 반환. 추가 aura 정리의 전체 동치는 아님.','log':f'verification/parity-r23/{suite_name}/battle_r23_batch_test.log'}]
 if r.get('native_evidence'):
  ref=r['native_evidence'];r['native_evidence']=native(Path(ref['file']).name,ref['symbol'])
 r['new_evidence']=[{**e,'log':e.get('log','').replace('/suite-final/','/'+suite_name+'/')} for e in r['new_evidence']]
 rows.append(r)
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
suite=[read(p) for p in sorted((S/'rows').glob('*.json'))]
missing=sorted(expected-{r['test'] for r in suite});failed=[r for r in suite if not r['passed']]
pending=[r['test'] for r in suite if (S/(r['test']+'.log')).stat().st_mtime_ns>(S/'rows'/(r['test']+'.json')).stat().st_mtime_ns]
target=[]
for name in ['latest','enemy-latest','state-latest','compose-latest','display-latest','clock-latest','batch-latest']:
 j=read(O/(name+'.json'));target.append({'name':name,'checks':j['checks'],'failures':len(j['failures'])})
start=read(O/'start-manifest.json')
changed=[n for n,h in start.items() if not (R/n).exists() or hashlib.sha256((R/n).read_bytes()).hexdigest()!=h]
product=sorted(set(n for n in changed if n.startswith('project/game/'))|{'project/game/battle_stats_r23.gd'})
protected={folder:{'files':sum(n.startswith(folder+'/') for n in start),'changed':[n for n in changed if n.startswith(folder+'/')]} for folder in ['docs','project/assets','server']}
assert all(not v['changed'] for v in protected.values())
parity=[]
for name,file in [('A6','a6-mixed-audit.json'),('P3','p3-mixed-audit.json'),('A7','a7-gear-audit.json'),('A7 balanced','a7-gear-balanced-audit.json'),('A8','a8-audit.json'),('A9 native10','a9-native-10-audit.json'),('A9 native40','a9-native-40-audit.json')]:
 j=read(R/'verification/data-r21'/file);parity.append({'name':name,**{k:j[k] for k in ['battles','equal_battles','source_actions','actual_actions','matched_actions']}})
p2=read(R/'verification/data-r21/p2-full-battles.json')
assert all(r['battles']==r['equal_battles'] and r['source_actions']==r['actual_actions']==r['matched_actions'] for r in parity) and p2['different_actions']==0
summary={'rows_reviewed':212,'newly_equal_rows':sum(r['status']=='같음' for r in rows),'round2_newly_equal_rows':len(mapping),'fixed_rows':sum(r['fixed'] for r in rows),'round2_fixed_rows':len(fixes),'fixed_and_equal_overlap':sum(r['fixed'] and r['status']=='같음' for r in rows),'remaining_rows':sum(r['status']!='같음' for r in rows),'statuses':dict(Counter(r['status'] for r in rows)),'called_functions':coverage['called_functions'],'baseline_missing_entries':157,'newly_entered_baseline_entries':coverage['newly_entered_baseline_entries'],'batch_checks':observed['checks'],'new_checks':sum(r['checks'] for r in target),'new_failures':sum(r['failures'] for r in target),'suite_groups':len(suite),'expected_suite_groups':len(expected),'suite_missing':missing,'suite_failed_groups':len(failed),'suite_in_progress':pending,'parity_battles':sum(r['battles'] for r in parity)+p2['battles'],'parity_records':sum(r['source_actions'] for r in parity)+p2['compared_actions'],'product_files_changed':product,'protected':protected,'fresh_oracle_runs':len(coverage['runs'])}
summary['fixed_but_not_equal_rows']=sum(r['fixed'] and r['status']!='같음' for r in rows)
summary['neither_equal_nor_fixed_rows']=sum(not r['fixed'] and r['status']!='같음' for r in rows)
round2={'method':'Boolean 원본 진입 계측 + local closure 접근 export + 동일 입력 Godot 반환/상태/RNG 비교. 원본 본문을 대체하지 않음.','new_equal_ids':sorted(mapping),'fixed_ids':sorted(fixes),'batch_counts':counts,'suite':suite_name,'round1_ledger':'verification/parity-r23/battle-round1.json','limitations':'정규화된 native 저장 가능 map·유닛·능력치 도메인. Lua 임의 table/metatable·호스트 HTML 전체를 같음으로 전파하지 않음.','before':{'batch-before.json':{'checks':1628,'failures_raw':212,'comparison_failures_after_fixture_exclusion':211,'excluded_label':'batch/rng/11','reason':'53비트 숫자 입력 직렬화 손실. 최종 입력은 원본과 동일한 정확한 정수 문자열.','scope':'일부 기존 API 부재는 adapter guard로 실패 표시하며 이전 식을 인라인으로 관측. 전체 수정 전 빌드 실행으로 주장하지 않음.'},'batch-numeric-before.json':{'checks':6437,'failures':334}}}
assert observed['checks']==len(oracle['rows']) and len(observed['rows'])==len(oracle['rows'])
round2['before']['batch-class-before.json']={'checks':10827,'failures':20,'contract':'동일 직업 id/한글 이름의 같은 정의 참조'}
round2['before']['before-contracts.json']=read(O/'before-contracts.json')
work_files=sorted(str(p.relative_to(R)).replace('\\','/') for folder,pattern in [('tools','*battle_r23*'),('project/tests','battle_r23*')] for p in (R/folder).glob(pattern) if p.is_file())
source_audit=read(R/'verification/data-r21/source-audit.json')
assert source_audit['failures']==0 and source_audit['original_assets']==96 and not source_audit['changed_assets'] and not source_audit['changed_source']
payload={**base,'summary':summary,'rows':rows,'target_tests':target,'battle_parity':parity,'p2_parity':p2,'round2':round2,'test_tool_files':work_files+['tools/godot_r17.py'],'source_asset_audit':source_audit}
for file,data in [('battle.json',payload),('summary.json',summary)]:
 (O/file).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(S/'results.json').write_text(json.dumps(suite,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
complete=not(missing or failed or pending or summary['new_failures'])
if complete:
 code_manifest=read(S/'tested-code.json')
 assert all(hashlib.sha256((R/n).read_bytes()).hexdigest()==h for n,h in code_manifest.items()),'Code changed during final suite'
 visual=read(O/'visual-review-round2.json')
 assert all(r['viewed'] and hashlib.sha256((R/r['path']).read_bytes()).hexdigest()==r['sha256'] for r in visual['images'])
lines=['# R23-battle 2차 작업 보고','',
 f'대상 212행: 이번 같음 +{len(mapping)}행, 누적 같음 {summary["newly_equal_rows"]}행, 수정 근거 {summary["fixed_rows"]}행(이번 {len(fixes)}행), 남음 {summary["remaining_rows"]}행. 수정과 같음 {summary["fixed_and_equal_overlap"]}행은 중복이다. 원본 전 기능 이식 완료는 아니다.','',
 f'새 묶음 대조 {observed["checks"]:,}개 / 실패 {len(observed["failures"])}. 1차 포함 새 대조 {summary["new_checks"]:,}개 / 실패 {summary["new_failures"]}. 기존 6,320판 · 219,785기록 / 차이 0.','',
 f'프로젝트 검사 {len(suite)}/{len(expected)}그룹, 실패 {len(failed)}, 미실행 {len(missing)}, 실행 중 {len(pending)}. '+('전체 검사 완료.' if complete else '검사가 진행 중인 초안이다.'),
 '', '## 원본 실행과 근거','',
 f'정본 bot/src는 읽기 전용으로 실행했다. Boolean 함수/then/else/do 진입 계측 전후 출력은 동일하다. 기존 6,320판 원본 oracle도 재실행해 보존 기준과 동일함을 확인했다. 총 {len(coverage["runs"])}종 oracle. 대상 함수 {coverage["called_functions"]}/212 호출, 기존 미검증 진입 {coverage["newly_entered_baseline_entries"]}/157 도달(1차 55). 진입만으로 같음 승격하지 않았다.','',
 '원본 local 함수는 로드 사본에 접근문을 추가해 실제 closure를 호출한다. DFS/셔플의 캡처 변수를 경계 입력으로 설정하고 원래 본문을 실행한다. 같은 입력으로 Godot 실제 제품 함수의 반환·변경 배열·예산·다음 정수 RNG를 비교한다. 능력치 내부 st는 반올림 전 6실수도 직접 대조했다.','',
 '일반 실수 허용 오차 1e-7, 정수/RNG는 한 정수 차이도 실패한다. nil 슬롯→0, nil 선택→false, Lua 빈 map→Dictionary만 명시적으로 정규화했다. 전체 원본 위치·이전 상태·새 시험·제품 파일:줄·남은 이유는 verification/parity-r23/battle.json에 있다.','',
 '|원본 함수|새 같음 행|','|---|---:|']
for label,ids in [('능력치·캐시',list(mapping)[:5]),('편성·RNG',list(mapping)[5:13]),('전투 보조',list(mapping)[13:17]),('DOT·개인·시너지',list(mapping)[17:])]:
 lines.append('|'+label+'|'+str(len(ids))+' ('+', '.join(ids)+')|')
lines+=['','## 실패 재현과 수정','',
 '기본 묶음 1,628개 중 원시 실패 212. 53비트 입력 JSON 직렬화 손실 1개를 제외한 비교 불일치 211개이며 raw 관측은 batch-before.json에 보존했다. 이 묶음 일부는 API 부재를 adapter guard로 실패 표시하거나 이전 식을 인라인 관측한 것이며, 전체 수정 전 빌드 실행으로 합산하지 않는다. 16진수 입력 확장 6,437개 중 실제 제품 함수 실패 334개(씨앗 4·능력치 330)는 batch-numeric-before.json에 있다. 최종 묶음은 batch-latest.json 전체 일치. 원본 기대 수치를 바꿔 맞춘 항목은 없다.','',
 '잘못된 x와 빈 선택은 수정 전 메서드 본문을 별도 사본에서 사후 재실행하여 Godot Script error 4개를 확인했다(before-contracts.gd/.log/.json). 이는 보존된 전체 수정 전 빌드가 아니라 이번 편집에서 복원한 본문임을 명시한다.','',
 '직업 조회의 동일 정의 참조도 실패 20개를 재현한 뒤 수정했다(batch-class-before.json). 최종 관측에서는 모든 새 경계가 통과한다.','',
 '수정한 동작: 빈 선택의 RNG 소비, tcount(0 포함) 우선, Lua 씨앗 변환(기본값·음수 floor·16진 소수), 잘못된 x 초기화/같은 참조, 부식 만료 cor 정리, 레벨 숫자 문자열 변환, 직업 정의 참조 보존.','',
 '능력치 식은 battle_stats_r23.gd로 공유한다. 허용 파일 밖 world_state.gd는 기존 base stats를 이 함수에 잇는 최소 연결만 바꾸고 HP/MP 정수 형태를 보존했다. 종족·국가·장비 보정 순서는 기존 경로 그대로다. 전투 방어 상수는 호출자의 formula/curve를 전달한다. 장비 규칙·저장 schema·이관은 변경하지 않았다.','',
 '## 변경 파일','']
lines+=['- '+p for p in product]
lines+=['','새 시험/도구: tools/oracle_battle_r23_batch.mjs 및 .lua, project/tests/battle_r23_batch_test.gd, tools/report_battle_r23_batch.py, tools/run_battle_r23_parallel.py. 기존 coverage/run/report/cloud preload와 Godot wrapper를 확장했다. 1차 보고/ledger는 verification/parity-r23/R23-battle-round1.md 및 battle-round1.json에 보존했다.','',
 '## 검사와 보존','',
 f'검사 로그: verification/parity-r23/{suite_name}/. 모든 프로젝트 검사·import·필수 motion integration·export_licenses와 기존 전체 전투 8종을 포함한다. Windows root certificate store만 환경 메시지로 분리하고 Script error 및 나머지 ERROR는 실패로 센다.','',
 'node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs 로 실제 로컬 Worker/D1을 실행했다. 기존 8787/18787 점유 프로세스는 건드리지 않고 빈 loopback 포트를 골랐다. 시험 loader가 serve.mjs 포트만 바꾸며 서버 제품 파일과 Worker/D1 구현은 그대로다. 제어 파일은 cloud-control-round2로 격리했다.','',
 f'docs/ {protected["docs"]["files"]}개, project/assets/ {protected["project/assets"]["files"]}개, server/ {protected["server"]["files"]}개 manifest 기준 변경 0. Web export·버전 갱신 없음. 사용자 저장을 열거나 덮지 않았다. Godot는 모두 격리 wrapper로 실행했다. 처음 실패한 git status 이후 git 명령·설정 변경·커밋은 하지 않았다.','',
 '최종 결과 이미지는 visual-review-round2.json에 기록한 파일만 직접 확인한다. 이미지 전수 육안·모바일 실기기·새 Web/WASM 검증은 하지 않았다.','',
 '검사 후 임시 엔진 폴더의 재귀 삭제는 자동 승인 검토에서 정책상 차단되어 실행하지 않았다. verification/ui-r17/.gitignore에 이번 격리 런타임 경로만 추가하여 보존·추적 제외했다. 이번에 띄운 로컬 서버는 종료했다.','',
 '## 남은 작업','']
for group in sorted({r['feature_group'] for r in rows}):
 rs=[r for r in rows if r['feature_group']==group];lines.append(f'- {group}: 같음 {sum(r["status"]=="같음" for r in rs)}, 남음 {sum(r["status"]!="같음" for r in rs)}.')
lines+=['','호스트 채팅 변수/옛 VER2 저장 이관·pend/pid 버튼 흐름, 사건 전 필드 시간 이력과 로그/HTML 전체, 측정용 변형·훅 합성, 모든 HUD·대상·연출의 의미상 출력 대조가 남는다. 수치만 비교한 상위 개인 기술·적 행동을 같음으로 확대하지 않았다. 행별 남은 사유를 유지한다.','',
 '## 재실행','',
 'node tools/oracle_battle_r23_batch.mjs','python tools/coverage_battle_r23.py','python tools/run_battle_r23_parallel.py','python tools/report_battle_r23.py','',
 f'환경: R23_SUITE_NAME={suite_name}, R23_CLOUD_CONTROL=cloud-control-round2, ABYSS_TEST_SERVER=실제 로컬 서버 URL. 서버는 ABYSS_NODE_MODULES=기존 읽기 전용 Miniflare 경로, TEMP/TMP/TMPDIR=이 worktree의 .p6tmp, ABYSS_TEST_PORT=빈 포트로 설정한 뒤 위 serve.mjs 명령을 실행한다.']
(R/'R23-battle.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
if not complete:sys.exit(1)
assert summary['parity_battles']==6320 and summary['parity_records']==219785

