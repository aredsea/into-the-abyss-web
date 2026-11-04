"""Assemble measured round-four evidence without promoting partial contracts."""
from pathlib import Path
from collections import Counter
import hashlib
import json
import re

R = Path(__file__).resolve().parents[1]
O = R / 'verification/finish-r24/round4'
DONE = {'같음', '대체', '제외'}

def read(p):
    return json.loads(p.read_text(encoding='utf-8'))

def write(p, value):
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

PROMOTED = {
    'P2425': ('create-results.json', '종족 없음/전체 종족·계통·설명·주의·버튼 순서와 선택 상태. 실제 생성 화면도 동일 모델을 사용한다.'),
    'P2426': ('create-results.json', '종족·국가의 유효/차단/미선택 조합에서 문구·버튼 순서·활성·선택 보존.'),
    'P2427': ('create-results.json', '직업 없음/전체 직업·수치·스킬·출신 주의 문구·버튼 순서와 선택 상태.'),
    'P2428': ('create-results.json', '프리셋 설명, 직접 모드 0~99 경계, ±1/±5, 추천/초기화의 표시와 활성 상태.'),
    'P2434': ('create-results.json', '능력치·HP/MP·상한·증감/추천/초기화·전체 문구/순서와 기본/총량 막대 비율 564조합. C printf 소수 셋째 자리 반올림까지 직접 대조.'),
    'P3249': ('rest-gear-results.json', '원본 장비 코드 해석, 유효/무효 슬롯·다른 직업·레벨·소유·없는 코드·가득 찬 가방의 장착/해제 상태와 피드백. 실제 UI 및 JSON/D1 재개 연결.'),
    'P3290': ('rest-gear-results.json', '슬롯별 현재 장비·비어 있음·해제·후보 전부의 이름/순서/버튼을 원본과 직접 대조.'),
    'P3293': ('rest-gear-results.json', '휴식 중 멤버 선택·무효 선택 정규화·슬롯별 전체 후보·정보/버튼 순서를 직접 대조. 선택은 기존 ui.sel에 저장.'),
    'P3540': ('../gear-round4-restriction-gaps.json', '기존 미커밋 수정의 실제 현재 동작을 재검사: 가방 0/1999/2000 × 부적합 레벨/직업 장비 6개 원본/native 모두 일치. 가방 포화 시 장착 유지, 기존 overflow 보존. 이번 차수 새 제품 수정은 아님.'),
    'P2961': ('inn-routes-results.json', '원본 최상위 비호스트 handler의 back/list/pick/무효 접두·대상·scene·일일/금화 제한과 성공 피드백 264입력 직접 대조. 대사 데이터는 보존하며 기존 경제 320입력도 재검사.'),
    'P2841': ('shop-routes-results.json', '원본 cls/slot/scroll/target/gear/buy/back·잘못된 선택·수량·금화·Lv40·비매품 거절·피드백 336입력 직접 대조. 실제 UI가 dispatcher를 사용하며 선택 상태 JSON 및 D1 왕복.'),
}
PARTIAL = {
    'P3202': '정산 금화·경험치·레벨·동료 호감·장비/손실/원문 메시지를 48개 원본 입력으로 비교했다(한영×성공/퇴각/패배×케른×가방 0/1999/2000/2001). 기존 넘친 장비는 보존한다. 이 fixture는 1층, 보스 장비 드롭은 no-drop으로 격리하므로 다층/첫 보스/보스 드롭과 탐색 보상의 합성 전체는 아직 직접 대조하지 않았다.',
    'P3296': '원본 gear_card를 실제 휴식 화면 안에 추가하고 선택·장착·해제를 연결했다. 파티/물약/장비 조각은 통과하지만 휴식 화면 전체의 정보·버튼 순서와 별도 보급품/정비 이동 구성이 아직 다르다. 성적 휴식 카드는 제외한다.',
    'P3305': '실제 휴식의 inline gear_card·선택/장착과 정산 보상 문구를 보완했다. run 없음 안내/귀환 및 전체 phase별 정보·버튼 구성의 원본 직접 대조는 미완료다.',
    'P2954': '행동의 즉시 확정·거절·성공 피드백은 원본 handler와 일치하고 화면에 표시한다. 전체 여관 화면의 동료 목록→선택과 native 자동 선택/드롭다운, 종족/행동 설명 및 정보·선택 순서는 아직 다르다.',
}
UPDATED_REASONS = {
    'P2828': '원본처럼 Lv40 대상은 스크롤 목록에서 숨긴다. 구입/선택 handler는 직접 대조했으나 전체 화면의 상품 상세 설명·단일 상품→장비 순서와 native 분리 탭의 정보/선택 순서는 아직 다르다. 비매품의 성인 사용 장면은 제외한다.',
    'P2442': '종족/출신/직업/능력치 단계의 본문·선택·버튼은 직접 대조했다. 전체 생성 합성의 단계 머리·특성/확정·별도 설정/클라우드 진입을 포함한 전체 정보와 동작 순서는 아직 직접 대조하지 않았다.',
    'P0084': '원본 G_migrate는 누락 필드를 채우지만 native는 schema 없는 원본 G와 잘못된 타입을 전체 거절한다. 기존 native schema 1/2 보존 시험만으로 원본 v1 전체 이관을 같음으로 판정하지 않는다.',
    'P0085': '원본 load의 초과 경험치 정산·잘못된 장착 환원과 native restore의 전체 관찰 투영 대조가 남았다. 기존 native 저장 보존은 통과한다.',
    'P0105': '원본 HUD의 장소·금화·즐겨찾기 얼굴·상태/도감/저장/설정 순서와 native 상단/하단에 분산된 동작의 전수 직접 대조가 남았다.',
    'P2467': '원본 첫 만남 시작은 seed 설정·동료/호감/아이템·서술 지시를 함께 바꾼다. AI 지시는 제외하지만 native seed 소비 및 출발 상태의 직접 관찰 대조는 미완료다.',
    'P2528': '표시 순서·장비 해제의 빈 칸/1999/2000칸·중복 코드 장착·저장 재개는 직접 대조 통과. 실제 전투에서 도감 패널을 여는 전체 경로와 원본의 옛 아이템 문자열 장착 저장을 UID 모델로 옮기는 입력 경로는 아직 지원/대조하지 않았다.',
    'P2537': '목록·미영입·전체 동료 상세와 페르소나의 불필요한 패시브 표시는 보완했다. 전체 패널은 P2528/P2534의 옛 장착 저장·실제 전투 연결 경계가 미완료다.',
    'P2539': '8개 실제 상태 대조에서 2000칸 교환, 1999/2000칸 해제, 중복 코드·장착 UID·저장 재개·오류 알림은 일치. 원본 버튼 코드→native UID의 잘못된 코드/옛 장착 입력 및 실제 전투 라우터를 합친 관찰은 미완료다.',
    'P2567': '전투 상태창 단위의 아군 MP/적 심연/상태칩/사망 표시와 native 전투 inspector의 전체 의미상 출력을 직접 대조하지 않았다.',
    'P2568': '전투 승리/패배 표지·아군→적 순서·redo 초기화와 native 상태 패널의 직접 대조가 남았다.',
    'P2593': '판매된 선택의 판매/장착, 중복 장비, 2000칸 교환과 저장 재개는 실제 native 어댑터와 일치. 전투 중 버튼 요청을 공통 라우터에서 거절하는 전체 경로 및 옛 장착 저장 입력은 미완료다.',
    'P2606': '평시 persona/즐겨찾기·가방 표시와 전투 상태가 있는 패널 구성요소의 가방 진입 숨김은 검사했다. 실제 전투 진입은 먼저 전투 화면으로 강제 전환되어 원본 st_unit/st_battle의 동작·탭·복귀를 합친 전체 대응이 미완료다.',
    'P2617': '원본 HUD 즐겨찾기 최대 3명의 얼굴·선택 버튼과 native HUD의 실제 진입/표시 순서를 직접 대조하지 않았다.',
    'P2629': '공개 설정 32상태의 레이블/선택·설명, 초기화 확인 중 다른 설정 유지 및 클라우드 대체 화면 진입은 검사했다. G_new 초기 상태는 일치하지만 P2637의 reset 알림/복귀/무효 입력과 별도 계정 화면 복귀를 포함한 전체 합성 대조는 남았다.',
}

def current_reason(rid, reason):
    if rid in PARTIAL:
        return PARTIAL[rid]
    if rid in UPDATED_REASONS:
        return UPDATED_REASONS[rid]
    reason = (reason or '').split(' 4차:')[0]
    for old, new in {
        '시설 파일 수정 금지이며 전체 handler 직접 대조는 남는다.': '전체 handler 직접 대조는 남는다.',
        '실제품 의뢰 정산은 수정 금지인 facilities_world_r22.settle이 override한다.': '실제품 의뢰 정산은 facilities_world_r22.settle이 override한다.',
        '허용된 town_world만 바꿔도 제품 경로에는 반영되지 않는다.': '',
        ' 전투 화면/규칙 수정 금지.': '',
        ' 전투 규칙 수정 금지.': '',
        ' 연구/마을 소유자 파일은 이번 수정 금지.': '',
        ' 연결은 수정 금지 persona_world/상위 world 경로.': '',
        ' 일부 HUD 연결은 수정 금지 town_screen_r21.gd.': '',
    }.items():
        reason = reason.replace(old, new)
    assert not any(x in reason for x in ['수정 금지', '동결']), (rid, reason)
    return reason.strip()

def main():
    extras = {'export_licenses','motion_r9_integration','motion_r18_integration','balance_probe','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
    expected = {'import'} | {p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
    original, focused, cloud = [read(O/n) for n in ['regression.json','focused-results.json','cloud/results.json']]
    candidates = []
    for rows, folder, suffix in [(original,O,''),(focused,O,'-focused'),(cloud,O/'cloud','')]:
        for t in rows:
            log = folder/(t['test']+suffix+'.log')
            assert log.exists(), log
            candidates.append((log.stat().st_mtime,t,log.relative_to(R).as_posix()))
    latest = {t['test']: dict(t,log=log) for _,t,log in sorted(candidates,key=lambda x:x[0])}
    assert expected <= latest.keys(), sorted(expected-latest.keys())
    assert all(latest[n]['passed'] for n in expected), [n for n in expected if not latest[n]['passed']]
    write(O/'all-tests.json',{'expected':len(expected),'passed':len(expected),'failures':0,'tests':[latest[n] for n in sorted(expected)]})
    write(O/'recheck-history.json',{
        'initial_failures':[t for t in original if not t['passed']], 'focused_rechecks':focused,
        'fixture_changes':[
            'chronicle_r22_test: legacy completed-game fixture explicitly fills the board before accepting a first quest; source G_new intentionally has no pre-created offers.',
            'ui_expe_pass5_r23_test: expected rest entries now include the source gear_card; explicit dungeon mode matches the original floor-plan oracle.',
            'New harnesses: coherent native persona/companion levels and complete equip projection; numeric JSON equality and shield_s/sh_s source alias normalization.',
        ],
        'oracle_changes':'expe pass5 UI oracle now includes canonical gear_card; creation oracle includes source CSS allocation ratios. Canonical Lua numerical outcomes were not edited.',
        'npm_transients':['An earlier run crossed the per-minute limit boundary; standard retry passed.', 'The prior read-only sibling node_modules disappeared; final run uses r21-d-town dependencies read-only.'],
    })
    result_names = ['create-results','rest-gear-results','settle-results','inn-routes-results','shop-routes-results','cloud-rest','ui-results']
    results = {n:read(O/(n+'.json')) for n in result_names}
    assert all(not d['failures'] for d in results.values())
    restrict = read(R/'verification/parity-r23/gear-round4-restriction-gaps.json')
    assert len(restrict)==6 and all(d['same'] for d in restrict)
    npm_bytes = (O/'npm-test.log').read_bytes()
    npm = npm_bytes.decode('utf-16' if npm_bytes.startswith(b'\xff\xfe') else 'utf-8',errors='replace')
    assert '"normal_samples":393' in npm and 'FINISH R24 SERVER {"checks":449,"failures":0,"cases":64}' in npm
    assert not any(x in npm for x in ['AssertionError','ERR_MODULE_NOT_FOUND','ECONNRESET','FAIL '])
    scan = read(R/'verification/finish-r24/locale-scan.json')
    authored = read(R/'verification/finish-r24/authored-language-audit.json')
    assert scan['language_defects']==scan['placeholder_defects']==0
    assert not scan['defects'] and not scan['unsupported_data_macros']
    review = read(O/'visual-review.json')
    assert review['viewed'] and review['captures']==52
    assert all(sha(R/f['path'])==f['sha256'] for f in review['files'])
    battles=records=0
    for name in ['a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
        d=read(R/f'verification/data-r21/{name}.json')
        assert d['battles']==d['equal_battles'] and d['source_actions']==d['actual_actions']==d['matched_actions']
        battles+=d['battles']; records+=d['source_actions']
    d=read(R/'verification/data-r21/p2-full-battles.json')
    assert d['different_actions']==0
    battles+=d['battles']; records+=d['compared_actions']
    assert (battles,records)==(6320,219785)
    write(O/'battle-regression.json',{'battles':battles,'equal_battles':battles,'records':records,'differences':0})
    baseline=read(O/'baseline.json')
    changed=[n for n,h in baseline.items() if not (R/n).exists() or sha(R/n)!=h]
    protected={'project/game/localization_r22.gd','project/game/dialogue_player_r21.gd','project/ui/resource_gauge_r24.gd'}
    forbidden=[n for n in changed if n.startswith(('docs/','project/assets/','project/data/dialogue-r21/','server/')) or n in protected]
    assert not forbidden, forbidden
    images=read(R/'ASSET-HASHES.json')
    assert len(images)==96 and all(sha(R/f['path'])==f['sha256'] for f in images)
    new_files = [p.relative_to(R).as_posix() for folder in ['project/game','project/ui','project/tests','tools'] for p in (R/folder).glob('*') if p.is_file() and p.relative_to(R).as_posix() not in baseline and ('r24' in p.name)]
    write(O/'boundaries.json',{
        'changed_existing_this_round':changed,'new_files_this_round':new_files,'forbidden_changes':[],
        'original_images':96,'image_changes':0,'dialogue_changes':0,'english_display_changes':0,'gauge_changes':0,'docs_changes':0,
        'server_changes_this_round':0,'inherited_server_fix_retained':['depletions','last_kill'],'security_rate_limit_changes':0,
        'web_export':False,'runtime_slots_created_by_this_round_remaining':0,
        'authored_town_function_review':'inn_dialogue, journey_dialogue and reading_line bodies were not edited; handler and feedback presentation only.',
        'git':'Only read-only diff inspection requested by the continuation brief; no git configuration, commit, reset, checkout or other mutation.',
    })
    counts=[]; audit=[]
    modified=(set(PROMOTED)-{'P3540'}) | set(PARTIAL)
    for pack in ['expe','gear','ui','battle']:
        path=R/f'verification/parity-r23/{pack}.json'
        data=read(path); key='new_status' if pack=='gear' else 'status'
        before={r['id']:r for r in read(O/(pack+'-before.json'))['rows']}
        initial=[r for r in before.values() if r[key] not in DONE]
        for row in data['rows']:
            prior=before[row['id']]
            if prior[key] in DONE:
                continue
            rid=row['id']; src=row['source']; source=Path('C:/Clauede Code/dungeon-bot')/src['file']
            excerpt='\n'.join(source.read_text(encoding='utf-8').splitlines()[src['start']-1:src['end']])
            evidence={'stage':'finish round4','previous_status':prior[key],'previous_remaining_reason':prior.get('remaining_reason',''),'source_sha256':sha(source),'source_excerpt_sha256':hashlib.sha256(excerpt.encode()).hexdigest(),'modified_this_round':rid in modified}
            if rid in PROMOTED:
                result,detail=PROMOTED[rid]; row[key]='같음'; row['remaining_reason']=''
                if rid in modified: row['fixed']=True
                evidence.update(disposition='같음 승격',detail=detail,results=['verification/parity-r23/gear-round4-restriction-gaps.json' if rid=='P3540' else 'verification/finish-r24/round4/'+result])
            else:
                reason=current_reason(rid,prior.get('remaining_reason',''))
                row[key]=prior[key]; row['remaining_reason']=reason
                if rid in PARTIAL:row['fixed']=True
                evidence.update(disposition='수정 후 일부 유지' if rid in PARTIAL else '남음',detail=reason)
            row.setdefault('finish',{})['round4']=evidence
            audit.append({'ledger':pack,'id':rid,'symbol':src['symbol'],'status':row[key],**evidence})
        count={'ledger':pack,'initial_remaining':len(initial),'promoted_same':sum(r['id'] in PROMOTED for r in initial),'modified':sum(r['id'] in modified for r in initial),'remaining':sum(r[key] not in DONE for r in data['rows']),'statuses':dict(Counter(r[key] for r in data['rows']))}
        data.setdefault('finish',{})['round4']=count
        if 'summary' in data:
            s=data['summary'];s.setdefault('finish',{})['round4']=count;s['remaining_rows']=count['remaining'];s['latest_status_counts']=count['statuses']
            for field,value in [('remaining',count['remaining']),('same',count['statuses'].get('같음',0)),('statuses',count['statuses']),('remaining_counts',{k:v for k,v in count['statuses'].items() if k not in DONE})]:
                if field in s:s[field]=value
        write(path,data);counts.append(count)
    assert [sum(c[k] for c in counts) for k in ['initial_remaining','promoted_same','modified','remaining']]==[74,11,14,63]
    write(O/'row-audit.json',{'counts':counts,'rows':audit,'source_contract_not_complete':True})
    write(O/'summary.json',{'tests':len(expected),'test_failures':0,'cloud_groups':len(cloud),'normal_samples':393,'promoted_same':11,'modified':14,'remaining':63,'battles':6320,'records':219785,'general_language_defects':0,'placeholders':0,'protected_untranslated':authored['untranslated'],'overall_complete':False})
    lines=[
        '# FINISH-R24 · 4차','',
        '**전체 완료 아님. 이어받은 잔여 74행에서 같음 11행 승격, 14행 수정(승격 포함), 63행이 남았다.** 3차 시작 80행 기준 누적 승격은 17행이다. 전 화면·전 데이터 언어 검사는 보호된 대사 미번역 14,216필드 때문에 완료 기준을 충족하지 못한다. 금지된 데이터/영어 대사 표시 함수를 수정하지 않았다.','',
        f'프로젝트 **{len(expected)}/{len(expected)}그룹 최종 통과·실패 0**, 실제 `serve.mjs` Worker/D1 클라우드 **{len(cloud)}그룹** 포함. `npm test` 종료 0, 정상 표본 **393/393**, 두 필드 서버 **64사례·449검사**. 전투 **6,320/6,320판·219,785기록 일치**.','',
        f'일반 화면 언어 **0건**, 자리표시자 **0건**: {scan["screen_language_states"]}개 화면·언어 상태, {scan["rendered_strings"]:,}개 표시 문자열, 데이터 {scan["data_files"]}파일·{scan["data_strings"]:,}문자열. 별도 보호 대사 **{authored["untranslated"]:,}필드 미번역**, `all_language_complete=false`, 전체 스캐너 종료 1. 전체 언어 0건으로 보고하지 않는다.','',
        '| 대조표 | 시작 잔여 | 같음 승격 | 수정 | 남음 |','|---|---:|---:|---:|---:|',
    ]
    lines += [f'| {c["ledger"]} | {c["initial_remaining"]} | {c["promoted_same"]} | {c["modified"]} | {c["remaining"]} |' for c in counts]
    lines += ['',
        '수정 수는 이번 제품 동작을 바꾼 행이며 승격과 중복된다. P3540은 이어받은 기존 수정의 재검사로 승격했으므로 이번 수정 수에는 넣지 않았다. 전체 화면/handler의 일부만 확인한 행은 승격하지 않았다. 원본 HTML·저장 매체 자체나 과거 갈래 금지는 잔여 이유로 쓰지 않는다.','',
        '주요 변경과 직접 대조:','',
        '- 생성: 원본 순서의 종족/출신/직업/능력치 설명·주의·선택·활성·추천/초기화를 실제 화면에 연결했다. 1,008페이지+28총량 입력, 2,636검사. 기본/보너스 막대 비율 564조합을 포함한다. 원본 C printf와 Godot 소수 셋째 자리 tie 16건을 고쳤으며 기존 0~2자리 전투 표시 회귀도 통과했다.',
        '- 휴식 장비: 같은 화면에 원본 슬롯별 후보·해제/장착을 표시하고 선택을 기존 ui.sel에 저장한다. 72표시+252행동, 1,872검사. 잘못된 코드·소유자·직업/레벨·가득 찬 가방과 JSON 재개를 비교했다.',
        '- 정산: 금화·경험치·레벨·호감·장비 획득/버림 메시지를 복원했다. 48입력·560검사, 2,001개 기존 가방도 보존한다. 이 비교의 보스 드롭은 no-drop으로 격리했다. 다층/첫 보스/복합 드롭의 전체 계약은 P3202에 남는다.',
        '- 여관/상회: 실제 UI에서 최상위 원본 버튼 dispatcher를 사용한다. 여관 264입력·266검사, 상회 336입력·384검사. back/list/pick/분류/슬롯/대상/구입·거절 문구와 상태를 직접 비교했다. 기존 여관 경제 320입력·1,281검사도 통과한다. 호스트 채팅 전송 문구만 제외했다. NPC 접근자는 79-sex.lua의 sx_npcst/npc_like만 추출했으며 성인 장면은 실행/이식하지 않았다.',
        '- 실제 D1: 장비 선택/장착, 상회 분류/슬롯/스크롤 선택을 업로드→다른 기기→후속 행동→역방향 저장/파일 재개까지 25검사했다. 외부 소유 장비 거절을 포함하고 서버 키를 추가하지 않았다.',
        '- 언어: 실제 영어 정산 화면의 한국어 제목 1건을 locale 사전에 추가했다. 예전 연대기/스크롤 사용자 이름 결함의 1차 수정은 유지하며 두 크기의 화면을 다시 열었다.','',
        '시각 확인: 최신 한영 생성·휴식·정산·여관 48장과 기존 연대기/스크롤 결함 4장, **총 52장**을 `390×844`·`1280×800`에서 직접 열었다. 관련 실제 UI **3,092검사**, 소스 표시 조각/컨트롤/미터와 콜백을 확인했다. 긴 설명은 기존 스크롤 영역을 사용한다. 원본 그림·팔레트·서체·공용 게이지는 유지했다. 전체 화면 순서의 남은 차이는 행별 기록을 따른다.','',
        '검증 근거:','',
        '- [최종 전체 검사](verification/finish-r24/round4/all-tests.json), [최초 실패와 재검사](verification/finish-r24/round4/recheck-history.json), [npm test](verification/finish-r24/round4/npm-test.log), [실제 클라우드](verification/finish-r24/round4/cloud/results.json)',
        '- [생성](verification/finish-r24/round4/create-results.json), [휴식 장비](verification/finish-r24/round4/rest-gear-results.json), [정산](verification/finish-r24/round4/settle-results.json), [여관](verification/finish-r24/round4/inn-routes-results.json), [상회](verification/finish-r24/round4/shop-routes-results.json), [새 D1 재개](verification/finish-r24/round4/cloud-rest.json)',
        '- [행별 원본 hash·판정·남은 이유](verification/finish-r24/round4/row-audit.json), [전투](verification/finish-r24/round4/battle-regression.json), [시각 검토와 PNG hash](verification/finish-r24/round4/visual-review.json), [변경 파일/보호 경계](verification/finish-r24/round4/boundaries.json)',
        '- [전체 언어 스캔](verification/finish-r24/locale-scan.json), [보호 대사 검출](verification/finish-r24/authored-language-audit.json), [이전 보고](verification/finish-r24/round4/round3-report.md)','',
        '재검사 해석: 최초 전체 실행의 chronicle fixture는 초기 의뢰가 없다는 원본 G_new 복원 뒤 비어 있는 배열을 참조했다. 완료된 게임용 fixture에 의뢰판 생성을 명시했다. pass5 화면 fixture는 새 gear_card 포함 및 원본이 가정한 dungeon 모드를 명시했다. 둘 다 관련 재검사 통과, 원본 수치 기대값은 바꾸지 않았다. 전체 대사 UI 검사도 1,489,324검사·실패/overflow 0을 유지했다. npm의 시간 경계 실패와 사라진 외부 의존성 경로는 재실행으로 확인했으며 최종 실행은 성공했다.','',
        '경계: 원본 이미지 **96/96 불변**. 대사 데이터·영어 표시 함수·공용 게이지·docs 불변, 새 그림/Web export 없음. 기존 미커밋 3차 변경을 보존했다. 이번 서버 파일 변경은 0건이며 기존 depletions/last_kill strict allowlist만 유지·재검사했다. 보안/속도 제한은 바꾸지 않았다. 다른 갈래 node_modules는 읽기만 했고 launcher는 개발 registry 공유만 끈 실제 Worker/D1을 사용한다. 만든 runtime 슬롯은 모두 정리했고 기본 runtime은 보존했다.','',
        '남은 이유: 보호 대사 외에도 원본 G/VER2 전체·옛 stage 입력 이관, 전체 화면 정보/선택 순서, 전투 복합 훅의 반환·로그·시간 이력 및 일부 최상위 dispatcher 합성의 직접 대조가 미완료다. id 전용 last_kill은 원본 이름+기술 문구를 완전히 보존할 수 없다. 세부 63행은 다음과 같다.','',
    ]
    lines += [f'- {a["ledger"]} {a["id"]} `{a["symbol"]}`: {a["detail"]}' for a in audit if a['id'] not in PROMOTED]
    lines += ['', '재실행: `node tools/finish_r24_round4_oracle.mjs` 및 같은 접두사의 expe/settle/inn/shop oracle, `R24_FINISH_OUTPUT=verification/finish-r24/round4` 환경에서 `python tools/finish_r24_verify.py`와 `--cloud`. `npm test`는 기존 설치 경로를 ABYSS_NODE_MODULES로 지정하고 finish_r24_node_launcher.mjs를 NODE_OPTIONS --import로 사용한다. 전체 스캔은 `python tools/finish_r24_scan.py`이며 보호 대사가 남으면 종료 1이 정상 검출 결과다. 보고/표는 `python tools/finish_r24_round4_report.py`로 재생성한다.']
    (R/'FINISH-R24.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print(json.dumps(read(O/'summary.json'),ensure_ascii=False))

if __name__=='__main__':
    main()
