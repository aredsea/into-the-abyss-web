"""Finish ledger/report from measured results; never promote a partial contract."""
from pathlib import Path
from collections import Counter
import json,hashlib
R=Path(__file__).resolve().parents[1];O=R/'verification/finish-r24/round3'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
done={'같음','대체','제외'}
promoted={
 'P3639':('finish_gear_hooks_r24_test','gear-hooks-results.json','선행 damaged 콜백 → 장비 훅의 전체 상태·호출 순서·반환을 원본과 직접 비교.'),
 'P3644':('finish_gear_hooks_r24_test','gear-hooks-results.json','선행 attacked 콜백 → 반사/가시 훅의 전체 상태·호출 순서·반환을 원본과 직접 비교.'),
 'P3647':('finish_gear_hooks_r24_test','gear-hooks-results.json','선행 turn_end 콜백의 상태 변경 뒤 장비 차례 종료 훅을 원본과 직접 비교.'),
 'P3659':('finish_gear_hooks_r24_test','gear-hooks-results.json','선행 abyss_after 콜백 뒤 MP/고갈/당김·반환·호출 순서를 원본과 직접 비교.'),
 'P2826':('finish_facilities_r24_test','facilities-results.json','한영·provider 없음/무효/성공·NPC_G 유무·호감 -1/0/19.99/200의 48입력. 생략·이름·역할 끝 호감·다중 NPC 순서를 비교. HTML과 Texture 매체는 관찰 결과로 대응. 실제 hero가 같은 helper를 사용하며 기존 원본 그림과 표시 항목을 보존.'),
 'P0017':('finish_initial_r24_test','initial-results.json','호스트/성인 전용 칸을 제외한 G_new 전체 게임 상태 투영과 JSON 재개를 원본 실행 결과와 직접 비교. 초기 의뢰/난수 소비 제거, 기본 출정 모드 0(의뢰) 복원. 명시적 모드 선택은 유지.')}
partial={
 'P1594':'고갈 횟수·마지막 일격 id·옛 필드 없음의 기본값은 재개 및 실제 D1 왕복 통과. 원본 VER2 전체 상태를 native로 읽는 통합 이관은 여전히 없음. 지시된 id 전용 last_kill로 원본 이름+기술 문구를 보존할 수 없어 이 차이도 남는다.',
 'P1595':'native 저장에 고갈 횟수와 알려진 마지막 일격 id를 넣고 서버/D1/다른 기기/파일 재개를 검증했다. 원본 VER2 전체 왕복과 기술명 문구의 id 전용 표현 차이는 남는다.',
 'P1825':'고갈 횟수는 저장 재개 뒤 유지한다. last_kill을 id만 저장하라는 지시 때문에 원본의 이름+기술 문구는 이름으로 복원되어 일부 정보가 빠진다. 실제 의뢰 출처/rg/qmult의 모든 정산 연결도 전체 직접 대조 미완료.',
 'P2961':'대화·식사·선물·휴식은 원본처럼 즉시 확정한다. 320개 원본 행동의 금화·호감·날짜·일일 제한·거절 불변을 직접 비교했다. 대사는 그대로 유지하고 대화 선택에서 중복 지급하지 않는다. back/list/pick/무효 scene·접두 해석·전체 피드백을 같은 최상위 진입점으로 모두 비교한 것은 아니므로 남음.',
 'P2954':'원본 NPC 그림·역할 끝 호감·즉시 행동·완료 상태 가독성은 보완했다. 원본 동료 목록→선택과 native 자동 선택/드롭다운, 종족/행동 설명 및 전체 정보·선택 순서 차이는 남는다.',
 'P2637':'초기화 뒤 초기 의뢰·난수·출정 기본값 차이는 G_new 직접 비교와 실제 파일 초기화/보관 사본 검사로 해소했다. 최상위 op handler 전체의 reset 알림·복귀·무효 접두를 원본과 직접 모두 비교한 것은 아니므로 남음.',
 'P3032':'미지정 출정 기본 모드를 원본 의뢰 모드로 복원했다. picker/고정 슬롯/별도 스크롤·보조 출발 버튼의 전체 정보·버튼 순서 차이는 남는다.'}

def main():
 extras={'export_licenses','motion_r9_integration','motion_r18_integration','balance_probe','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
 expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
 original=read(O/'regression.json');focused=read(O/'focused-results.json');cloud=read(O/'cloud/results.json')
 # Focused checks use separate logs and preserve the initially failed suite.
 candidates=[]
 for rows,folder,suffix in [(original,O,''),(cloud,O/'cloud',''),(focused,O,'-focused')]:
  for t in rows:
   log=folder/(t['test']+suffix+'.log')
   candidates.append((log.stat().st_mtime if log.exists() else 0,t))
 tests={t['test']:t for _,t in sorted(candidates,key=lambda x:x[0])}
 assert expected<=tests.keys(),sorted(expected-tests.keys())
 assert all(tests[n]['passed'] for n in expected),[n for n in expected if not tests[n]['passed']]
 write(O/'all-tests.json',{'expected':len(expected),'passed':len(expected),'failures':0,'tests':[tests[n] for n in sorted(expected)]})
 write(O/'recheck-history.json',{'initial_failures':[t for t in read(O/'initial-suite.json') if not t['passed']],'rechecks':focused,'fixture_input_changes':['expe_pass5_r23_test: explicit dungeon mode for the original floor-28 q.lv fixture','ui_expedition_r22_test: explicit dungeon mode for dungeon-picker fixtures','ui_town_r21_round3_test: source immediate meal charge/daily rejection replaces the former confirmation-cancel expectation'],'numerical_oracle_expectations_changed':False})
 for name in ['resume-results','gear-hooks-results','facilities-results','initial-results','ui-results','cloud-fields','server-fields']:
  d=read(O/(name+'.json'));assert not d['failures'],name
 npm_bytes=(O/'npm-test.log').read_bytes()
 npm=npm_bytes.decode('utf-16' if npm_bytes.startswith(b'\xff\xfe') else 'utf-8',errors='replace')
 assert '"normal_samples":393' in npm and 'GEAR R23 SERVER' in npm
 assert not any(x in npm for x in ['AssertionError','ERR_MODULE_NOT_FOUND','ECONNRESET'])
 scan=read(R/'verification/finish-r24/locale-scan.json');assert not scan['defects'] and not scan['unsupported_data_macros']
 authored=read(R/'verification/finish-r24/authored-language-audit.json')
 review=read(O/'visual-review.json');assert review['viewed'] and review['captures']==24
 assert all(sha(R/x['path'])==x['sha256'] for x in review['files'])
 battles=records=0
 for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
  d=read(R/f'verification/data-r21/{name}.json');assert d['battles']==d['equal_battles'] and d['source_actions']==d['actual_actions']==d['matched_actions'];battles+=d['battles'];records+=d['source_actions']
 d=read(R/'verification/data-r21/p2-full-battles.json');assert d['different_actions']==0;battles+=d['battles'];records+=d['compared_actions'];assert (battles,records)==(6320,219785)
 write(O/'battle-regression.json',{'battles':battles,'equal_battles':battles,'records':records,'differences':0})
 baseline=read(O/'baseline.json');changed=[n for n,h in baseline.items() if not (R/n).exists() or sha(R/n)!=h]
 server_allowed={'server/abyss-save/src/validate.js','server/abyss-save/test/combat-r14.mjs','server/abyss-save/test/p2-r15.mjs'}
 forbidden=[n for n in changed if n.startswith(('docs/','project/assets/','project/data/dialogue-r21/')) or n in ['project/game/localization_r22.gd','project/ui/resource_gauge_r24.gd'] or n.startswith('server/') and n not in server_allowed]
 assert not forbidden,forbidden
 images=read(R/'ASSET-HASHES.json');assert len(images)==96 and all(sha(R/x['path'])==x['sha256'] for x in images)
 write(O/'boundaries.json',{'changed_existing':changed,'forbidden_changes':forbidden,'original_images':96,'image_changes':0,'dialogue_changes':0,'english_display_changes':0,'gauge_changes':0,'docs_changes':0,'server_production_changed':['server/abyss-save/src/validate.js'],'server_fields_added':['depletions','last_kill'],'server_security_rate_limit_changes':0,'web_export':False,'git_note':'An initial read-only git status attempt failed on ownership before the common rules finished loading. No git configuration/mutation or further git commands were used.'})
 counts=[];audit=[]
 for pack in ['expe','gear','ui','battle']:
  p=R/f'verification/parity-r23/{pack}.json';d=read(p);old=read(O/(pack+'-before.json'));key='new_status' if pack=='gear' else 'status';previous={r['id']:r for r in old['rows']};remaining=[r for r in old['rows'] if r[key] not in done]
  for row in d['rows']:
   prior=previous[row['id']]
   if prior[key] in done:continue
   rid=row['id'];src=row['source'];source=Path('C:/Clauede Code/dungeon-bot')/src['file'];excerpt='\n'.join(source.read_text(encoding='utf-8').splitlines()[src['start']-1:src['end']])
   prior_reason=prior.get('remaining_reason','')
   # Recover the actual unresolved contract behind the obsolete branch boundary.
   actual_reason=prior.get('finish',{}).get('previous_remaining_reason',prior_reason)
   if rid in partial:actual_reason=partial[rid]
   ev={'stage':'finish round3','previous_status':prior[key],'previous_remaining_reason':prior_reason,'source_sha256':sha(source),'source_excerpt_sha256':hashlib.sha256(excerpt.encode()).hexdigest(),'modified':rid in promoted or rid in partial}
   if rid in promoted:
    test,result,detail=promoted[rid];row[key]='같음';row['remaining_reason']='';row['fixed']=True
    ev.update({'disposition':'같음 승격','tests':[test],'results':['verification/finish-r24/round3/'+result],'detail':detail})
   else:
    row[key]=prior[key];row['remaining_reason']=actual_reason
    if rid in partial:row['fixed']=True
    ev.update({'disposition':'수정 후 일부 유지' if rid in partial else '남음','detail':actual_reason,'scope':'함수 전체 직접 비교가 없는 행은 관련 회귀 통과만으로 승격하지 않음. 과거 서버 금지/전투 갈래 이관 자체를 현재 차이의 근거로 사용하지 않음.'})
    if rid in ['P1594','P1595','P1825']:ev['results']=['verification/finish-r24/round3/resume-results.json','verification/finish-r24/round3/cloud-fields.json','verification/finish-r24/round3/server-fields.json']
    if rid in ['P2961','P2954']:ev['results']=['verification/finish-r24/round3/facilities-results.json','verification/finish-r24/round3/ui-results.json','verification/finish-r24/round3/cloud-fields.json']
   row.setdefault('finish',{})['round3']=ev;audit.append({'ledger':pack,'id':rid,'status':row[key],**ev})
  c={'ledger':pack,'initial_remaining':len(remaining),'promoted_same':sum(r['id'] in promoted for r in remaining),'modified':sum(r['id'] in promoted or r['id'] in partial for r in remaining),'remaining':sum(r[key] not in done for r in d['rows'])}
  c['statuses']=dict(Counter(r[key] for r in d['rows']))
  d.setdefault('finish',{})['round3']=c
  if 'summary' in d:
   summary=d['summary'];summary.setdefault('finish',{})['round3']=c
   summary['remaining_rows']=c['remaining']
   summary['latest_status_counts']=c['statuses']
   if 'remaining' in summary:summary['remaining']=c['remaining']
   if 'same' in summary:summary['same']=c['statuses'].get('같음',0)
   if 'statuses' in summary:summary['statuses']=c['statuses']
   if 'remaining_counts' in summary:summary['remaining_counts']={k:v for k,v in c['statuses'].items() if k not in done}
  write(p,d);counts.append(c)
 assert sum(c['initial_remaining'] for c in counts)==80 and sum(c['promoted_same'] for c in counts)==6 and sum(c['remaining'] for c in counts)==74
 write(O/'row-audit.json',{'counts':counts,'rows':audit,'source_contract_not_complete':True})
 lines=['# FINISH-R24 · 3차','','**전체 완료가 아니다. 이번 80행 중 같음 승격 6행, 수정 13행(승격 6행 포함), 남음 74행이다.** 서버의 허용 목록은 지시된 두 필드만 확장했다. 고갈 횟수와 마지막 일격 id/이름은 저장 재개에서 보존한다. 다만 원본 `last_kill`은 이름+기술 문구인데 지시서는 id 또는 빈 문자열만 허용한다. 이 제한을 그대로 지켜 기술명은 저장할 수 없으며, 이를 기록하고 관련 행을 승격하지 않았다. 질의에 대한 답변으로 형식 제한을 바꾸지는 않았다.','',f'프로젝트 **{len(expected)}/{len(expected)}그룹 최종 통과·실패 0**, 실제 로컬 D1 클라우드 **{len(cloud)}그룹** 포함. `npm test` 통과, 정상 표본 **393/393** 수용 유지. 서버 신규 **64사례·449검사**, 전투 저장 **76검사**, 클라우드 새 왕복/대화 재개 **19검사**, 장비 훅 **24입력·48검사**, 시설 **320행동+48표시·1,246검사**, 초기 상태/초기화 **33검사**. 전투 **6,320/6,320판·219,785기록 일치**.','',f'일반 화면 언어·자리표시자 결함 **0건**({scan["screen_language_states"]}상태·{scan["rendered_strings"]:,}문자열, 데이터 {scan["data_files"]}파일·{scan["data_strings"]:,}문자열). 보호된 대사/영어 대사 표시 함수의 미번역 **{authored["untranslated"]:,}필드**는 남아 있다. 언어 스캔의 전체 완료 값과 종료값은 이 때문에 실패이며 전체 언어 0건으로 보고하지 않는다. 해당 데이터와 표시 함수는 수정하지 않았다.','','| 대조표 | 시작 잔여 | 같음 승격 | 수정 | 남음 |','|---|---:|---:|---:|---:|']
 for c in counts:lines.append(f'| {c["ledger"]} | {c["initial_remaining"]} | {c["promoted_same"]} | {c["modified"]} | {c["remaining"]} |')
 lines+=['','변경 내용:','','- `validate.js`: 선택 필드 `depletions`는 0~11,200 정수, `last_kill`은 40자 이하의 알려진 동료/페르소나 id 또는 빈 문자열. schema 3에서만 허용한다. 옛 저장은 원문 그대로 통과하며 native 재개에서 0/빈 문자열을 기본값으로 쓴다. 상한은 원본 `10-data.lua`의 행동 한도 400, `30-engine.lua`의 고갈 중 재고갈 방지/잃은 차례 뒤 충전 규칙과 기존 28개 roster 상한에서 도출한 보수적 한도다. 타입·음수·소수·초과·알 수 없는 id·이름 문구·schema 2를 거절한다. 정상/거절 모두 POST·PUT·GET 및 저장/리비전 불변을 확인했다. 다른 서버 제품 코드·보안·속도 제한은 바꾸지 않았다.','- 전투 snapshot/restore: 두 메타데이터 필드를 보존하고 실패한 재개는 원래 상태를 유지한다. 필드 하나/둘이 없는 옛 저장도 통과한다. id 전용 표현으로 기술명이 빠지는 실제 차이는 resume-results.json의 known_difference에 남겼다.','- 장비 훅: 선행 콜백을 호출하고 그 변경을 반영한 뒤 장비 효과를 적용한다. 선행 반환은 원본처럼 무시한다. 기본 전투 수치 규칙은 유지했다.','- 초기 생성: 상위 legacy 초기화가 미리 만들던 의뢰와 소비한 난수를 새 게임에서 제거했다. 미지정 출정 모드는 원본처럼 의뢰(0)다. 실제 원본 전체 초기 상태와 native JSON 재개를 비교했다.','- 여관: 클릭 즉시 금화·호감·일일 횟수/날짜를 확정한다. 기존 대사/선택지는 유지한다. 이미 지급된 대화의 선택은 호감을 다시 지급하지 않는다. 기존 허용된 acts 키에 이야기 진행 표식을 저장하므로 새 서버 필드를 만들지 않는다. 옛 방식으로 선택 대기 중이던 저장은 기존 처리를 유지한다. 이 새 상태도 실제 서버→다른 기기→선택 완료/중복 거절까지 검증했다.','- NPC 그림/정보: 기존 원본 그림이 이니셜로 잘못 대체되던 fallback을 고쳤다. 원본 tw_npcs의 유효 provider 생략 규칙, 이름·역할·호감과 순서를 표시한다. 승인 그림·배치·색·서체를 보존했고 추가된 정보가 잘리지 않도록 기존 명패 안의 줄 간격과 상태 문구 영역만 맞췄다.','',f'시각 확인: 여관/길드/소개/연구/상회/대장간 한영 **24장**, `390×844`·`1280×800`을 직접 열었다. 새 화면 검사 **{read(O/"ui-results.json")["checks"]}개**, 캡션 실제 표시 줄 수·문구 크기·즉시 행동·저장 재개·중복 지급 방지를 검사했다. 영어 여관 긴 제목, 상회 소개와 그림의 기존 겹침은 승인 외형 범위 때문에 남겨 두었으며 모든 화면이 시각적으로 완결됐다고 주장하지 않는다.','','검증과 변경 경계:','','- [전체 검사](verification/finish-r24/round3/all-tests.json), [재검사 기록](verification/finish-r24/round3/recheck-history.json), [npm test](verification/finish-r24/round3/npm-test.log), [서버 두 필드](verification/finish-r24/round3/server-fields.json), [클라우드](verification/finish-r24/round3/cloud-fields.json)','- [전투 회귀](verification/finish-r24/round3/battle-regression.json), [원본 시설 실행](verification/finish-r24/round3/oracle.json), [행별 감사](verification/finish-r24/round3/row-audit.json), [시각 검토](verification/finish-r24/round3/visual-review.json), [보호 경계](verification/finish-r24/round3/boundaries.json)','- 원본 이미지 96/96 불변. 대사 데이터·영어 대사 표시 함수·공용 게이지·docs 불변. Web export·새 그림 없음. 초기 규칙 읽기와 동시에 실행한 읽기 전용 git status는 소유권 오류로 실패했고, 이후 git 명령/설정/변경은 하지 않았다.','- 의존성은 다른 갈래의 기존 node_modules를 읽기만 했다. 시험 launcher는 개발 registry 공유만 끄고 실제 Worker/D1을 실행한다. 제품 검증·인증·속도 제한은 완화하지 않았다. Windows root certificate store 메시지만 환경 진단으로 분리하며 나머지 ERROR/SCRIPT ERROR는 실패로 센다. 중간 실패를 숨기지 않고 수정 후 관련 검사를 재실행했다.','- 기존 expe_pass5와 UI 출정 시험은 원본 fixture가 비교하는 대던전 모드를 명시하도록 입력을 보완했다. 여관 식사의 확인 취소 기대는 원본의 즉시 차감/일일 중복 거절 기대와 직접 원본 320입력으로 교체했다. 전투 수치/난수/원본 oracle 기대값은 바꾸지 않았다.','','재실행: `node tools/finish_r24_round3_oracle.mjs`, `node tools/gear_r23_predecessors.mjs`; `R24_FINISH_OUTPUT=verification/finish-r24/round3` 환경에서 `python tools/finish_r24_verify.py`, `python tools/finish_r24_verify.py --cloud`. npm은 `ABYSS_NODE_MODULES`를 기존 설치 경로로 지정하고 `NODE_OPTIONS=--import=file:///.../tools/finish_r24_node_launcher.mjs`로 실행했다. 표/보고서는 `python tools/finish_r24_round3_report.py`로 갱신한다. 이전 보고는 [2차 보존본](verification/finish-r24/round3/round2-report.md)에 남겼다.','','남은 행과 이유:','']
 for a in audit:
  if a['id'] not in promoted:lines.append('- '+a['ledger']+' '+a['id']+' · '+a['detail'])
 lines+=['','이번 변경·추가 파일:','']
 files=changed+[
  'project/tests/finish_resume_r24_test.gd','project/tests/finish_gear_hooks_r24_test.gd',
  'project/tests/finish_facilities_r24_test.gd','project/tests/finish_initial_r24_test.gd',
  'project/tests/ui_finish_round3_r24_test.gd','project/tests/cloud_finish_r24_test.gd',
  'project/tests/finish_visual_probe_r24.gd','server/abyss-save/test/finish-r24.mjs',
  'tools/finish_r24_verify.py','tools/gear_r23_predecessors.mjs',
  'tools/finish_r24_round3_oracle.mjs','tools/finish_r24_node_launcher.mjs',
  'tools/finish_r24_round3_report.py']
 lines+=['- '+f for f in sorted(set(files))]
 lines+=['','대조표 4개와 검증 산출물은 verification/parity-r23 및 verification/finish-r24/round3에 기록했다.']
 report='\n'.join(lines)+'\n'
 report=report.replace('**19검사**','**%d검사**'%read(O/'cloud-fields.json')['checks'])
 report=report.replace('**76검사**','**%d검사**'%read(O/'resume-results.json')['checks'])
 report=report.replace('1,246검사',format(read(O/'facilities-results.json')['checks'],',')+'검사')
 report=report.replace('질의에 대한 답변으로 형식 제한을 바꾸지는 않았다.','별도 회신이 없어 지시된 id 제한을 그대로 적용했다.')
 (R/'FINISH-R24.md').write_text(report,encoding='utf-8')
 print(json.dumps({'report':str(R/'FINISH-R24.md'),'tests':len(expected),'failures':0,'promoted':6,'modified':13,'remaining':74,'authored_untranslated':authored['untranslated']},ensure_ascii=False))
if __name__=='__main__':main()
