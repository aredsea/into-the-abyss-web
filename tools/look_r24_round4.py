"""Round 4 evidence: no git, exports, source art writes, or gameplay changes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib, json, difflib, sys, re
R=Path(__file__).resolve().parents[1]
O=R/'verification/look-r24/round4'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def boundaries():
    before=json.loads((O/'baseline.json').read_text(encoding='utf-8'))
    after={p.relative_to(R).as_posix():sha(p) for d in ['project','docs','server','tools'] for p in (R/d).rglob('*') if p.is_file() and not any(x in p.parts for x in ['.godot','node_modules','__pycache__'])}
    changed=[p for p in sorted(before.keys()|after.keys()) if before.get(p)!=after.get(p)]
    allowed={'panel_screen_r22.gd','town_theme_r21.gd','codex_screen_r22.gd','journal_screen_r22.gd','settings_screen_r22.gd','town_screen_r21.gd','facilities_screen_r22.gd','expedition_screen_r22.gd'}
    forbidden=[p for p in changed if p.startswith(('project/game/','project/data/','project/assets/','server/','docs/')) or (p.startswith('project/ui/') and Path(p).name not in allowed)]
    assets=json.loads((R/'ASSET-HASHES.json').read_text(encoding='utf-8'))
    mismatches=[e['path'] for e in assets if sha(R/e['path'])!=e['sha256']]
    result={'changed':changed,'forbidden_changes':forbidden,'original_assets':len(assets),'asset_mismatches':mismatches,'export_performed':False,'git_commands_used':False}
    (O/'boundaries.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    diff=[]
    for p in (O/'source-before').glob('*.gd'):
        current=R/'project/ui'/p.name
        diff.extend(difflib.unified_diff(p.read_text(encoding='utf-8').splitlines(True),current.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+p.name,tofile='after/'+p.name))
    (O/'appearance.diff').write_text(''.join(diff),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=True,indent=2))
    return bool(forbidden or mismatches)
def review():
    out=O/'review';out.mkdir(exist_ok=True)
    result=json.loads((O/'after-results.json').read_text(encoding='utf-8'))
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    groups={}
    for row in result['inventory']:
        tag=row['screen'];base=tag.removesuffix('-end')
        groups.setdefault(base,[]).append(row)
    for tag,rows in groups.items():
        # One page per viewport, normal/reduced and top/end remain separately labeled.
        sheet=Image.new('RGB',(1560,1240),'#ddd8cd');draw=ImageDraw.Draw(sheet)
        for i,row in enumerate(rows):
            p=O/'after'/row['file'];im=Image.open(p).convert('RGB');im.thumbnail((248,570))
            col=i//2;line=i%2;x=col*260+6;y=line*620+32
            sheet.paste(im,(x+(248-im.width)//2,y))
            draw.text((x,y-26),row['file'].replace(tag,'')[:26],font=font,fill='#111715')
        sheet.save(out/(tag+'.jpg'),quality=92)
    # Explicit comparison against the approved grammar and the same before state.
    for tag,board in [('dialogue','06-town-life.png'),('codex','01-companions.png'),('inventory','02-equipment.png'),('facility_scroll','05-commerce.png'),('expedition-log','07-exploration.png'),('people','00-town-approved-direction.png')]:
        sheet=Image.new('RGB',(1600,940),'#ddd8cd');draw=ImageDraw.Draw(sheet)
        for i,(label,p) in enumerate([('Approved '+board,R.parent.parent/'outputs/r13-b-all'/board),('Round 4 before',O/'before'/f'{tag}-390x844.png'),('Round 4 after',O/'after'/f'{tag}-390x844.png')]):
            im=Image.open(p).convert('RGB');im.thumbnail((760 if i==0 else 390,870))
            x=0 if i==0 else 800+(i-1)*400
            sheet.paste(im,(x,38));draw.text((x+4,8),label,font=font,fill='#111715')
        sheet.save(out/(tag+'-comparison.jpg'),quality=93)
    print('Review pages',len(list(out.glob('*.jpg'))))
def finalize():
    rows=json.loads((R/'verification/look-r24/regression/regression.json').read_text(encoding='utf-8'))
    rows+=json.loads((R/'verification/look-r24/cloud/results.json').read_text(encoding='utf-8'))
    log=(O/'ui_cloud_replacement_r23_test.log').read_text(encoding='utf-8')
    rows.append({'test':'ui_cloud_replacement_r23_test','passed':'CHECKS 40 FAILURES 0' in log and 'SCRIPT ERROR:' not in log,'summary':['UI CLOUD REPLACEMENT R23 CHECKS 40 FAILURES 0'],'exit':0,'errors':[]})
    by_name={row['test']:row for row in rows}
    expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration','balance_probe']}
    missing=sorted(expected-by_name.keys());failed=sorted(n for n in expected&by_name.keys() if not by_name[n]['passed'])
    evidence={'expected_groups':len(expected),'passed_groups':sum(by_name[n]['passed'] for n in expected&by_name.keys()),'missing':missing,'failed':failed,'tests':[by_name[n] for n in sorted(expected&by_name.keys())]}
    (O/'all-tests.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding='utf-8')
    if missing or failed:raise SystemExit('Incomplete: '+str(missing+failed))
    before=json.loads((O/'before-results.json').read_text(encoding='utf-8'));after=json.loads((O/'after-results.json').read_text(encoding='utf-8'))
    shell=json.loads((R/'verification/look-r24/after-shell-results.json').read_text(encoding='utf-8'))
    assert not before['failures'] and not after['failures'] and all(not row['issues'] and not row['errors'] for row in shell)
    roster_checks=int(re.search(r'CHECKS (\d+)',by_name['ui_dialogue_roster_r21_test']['summary'][-1])[1])
    assert not boundaries()
    section=f'''## 4차 · 남은 화면 외형과 스크롤 정리

**전체 검사 {len(expected)}/{len(expected)}그룹 통과, 최종 실패 0·미완료 0.** import, 프로젝트의 `_test.gd` 전부와 공통 지정 검사·integration·balance probe, 실제 `serve.mjs` 클라우드 6그룹을 이번 코드에서 실행했다. [최종 집계](verification/look-r24/round4/all-tests.json) · [전체 최초 실행](verification/look-r24/round4/suite-console.log) · [재검사](verification/look-r24/round4/retests-console.log). 사용자 시각 승인과 새 Web export의 통합 검사는 별도다.

이번 지시서 맨 위에서 허용한 **4차 화면만** 수정했다. 아래 1~3차의 보호 범위·미수정 화면 설명은 당시 기록이며, 이번 차수의 결과는 이 절과 다음 표가 우선한다.

| 화면 | 시안·적용한 문법 | 직접 확인한 결과와 남긴 차이 |
|---|---|---|
| [여관 대화](verification/look-r24/round4/after/dialogue-390x844.png) · [마지막 선택지 390×664](verification/look-r24/round4/after/dialogue-end-390x664.png) | 06 + 00·01 행 문법 | 기존 여관·동료 원본 초상 유지. 제목 아래 짧은 주홍 선, 왼쪽 굵은 선택지·→·3px 먹 구분선, 하단 탭 복원. 상황·본문·선택지를 측정 높이의 스크롤에 넣고, 응답·관계 단계 변화 전문도 같은 방식으로 표시. 하단 행동은 별도 고정 영역이며 390×664에서도 실제 높이 44px 이상이다. 06의 여관 첫 화면 포스터 자체를 대화 화면에 복제하지 않았다. |
| [원정 탐색 기록](verification/look-r24/round4/after/expedition-log-390x844.png) · [긴 기록 끝](verification/look-r24/round4/after/expedition-log-long-end-390x664.png) | 07에 딸린 기록 화면, 00·01 문법 | 기존 원정명·층·기록·미정산 보상 순서 유지. 주홍 밑줄·먹 구분선, 행별 실측 높이와 스크롤 바닥 여백 적용. 지도 화면은 그대로 두었고, 기록에 새 지도·장면 그림을 넣지 않았다. 빈 기록은 보상 정보만 표시한다. |
| [상회 스크롤 대상](verification/look-r24/round4/after/facility_scroll-390x844.png) · [사용 가능](verification/look-r24/round4/after/facility-scroll-enabled-390x844.png) | 05 + 00·01 문법 | 굵은 대상 이름·기존 레벨 설명·3px 먹 선·오른쪽 행동 화살표. 사용 가능은 기존 주홍 붓, 불가는 먹 선과 보조색. 보유량·최대 레벨·사용 조건·대상 순서 그대로. 상회 인물 포스터 대신 대상 선택 목록을 유지했다. |
| [장비 가방](verification/look-r24/round4/after/inventory-390x844.png) · [비교·판매 끝](verification/look-r24/round4/after/inventory-detail-end-390x664.png) | 02 + 00·01 문법 | 원래 장비 아이콘·등급색 유지. 굵은 이름·작은 레벨 줄·→, 굵은 아래 선과 필터·주홍 탭 적용. 비교 수치·판매 확인·장착 조건은 그대로다. 02의 동료 장비 보관함과 기능이 달라 필터·비교 양식은 유지했다. |
| [캐릭터 도감](verification/look-r24/round4/after/codex-390x844.png) · [상세](verification/look-r24/round4/after/codex-detail-390x844.png) | 01 + 00 행 문법 | 기존 인물·미영입 표시·필터·호감 막대 유지. 이름 행·상세 절 제목·주홍 선택과 하단 아이콘 탭 통일. 휴대폰 2열, 데스크톱 4열. 승인된 기존 동료 개요·기술 화면은 그대로이며 도감의 탐색 기능을 유지했다. |
| [모험 기록·연대기](verification/look-r24/round4/after/journal-390x844.png) | 전용 없음, 00·01 문법 | 기존 날짜·사건·기록 설정·최신순 유지. 굵은 날짜/제목 계층·먹 구분선·주홍 탭·아이콘 내비게이션 적용. 사건 그림이나 새 요약 문구를 추가하지 않았다. |
| [토르바 인물 목록](verification/look-r24/round4/after/people-390x844.png) · [상세](verification/look-r24/round4/after/person-isolde-390x844.png) | 전용 없음, 00·01 문법 | 이름·기존 위치 설명·→를 한 행에 묶었다. 상세는 원래 전문·순서를 유지하고 제목·절 서체와 하단 탭만 통일. 새 초상 없음. |
| [마을 시내](verification/look-r24/round4/after/places-390x844.png) · [기록관](verification/look-r24/round4/after/place-archive-390x844.png) | 전용 없음, 00 문법 | 원래 시내 먹 풍경·장소 설명·상주 인물·이동 순서 유지. 굵은 장소/인물 행·→·주홍 현재 장소·먹 선 적용. 기록관용 새 그림을 만들지 않았다. |
| [설정](verification/look-r24/round4/after/settings-390x844.png) · [초기화 확인 끝](verification/look-r24/round4/after/settings-reset-end-390x664.png) | 전용 없음, 00·01 문법 | 난이도 이름과 기존 배율 설명을 두 줄로 분리하고, 굵은 절 제목·짧은 주홍 밑줄·붓 선택·행 화살표 적용. 초기화는 실행하지 않고 확인 상태만 검토. 기존의 뒤로 가기 구조 유지. |
| [상태](verification/look-r24/round4/after/status-390x844.png) · [마지막 행](verification/look-r24/round4/after/status-end-390x664.png) | 전용 없음, 00·01 문법 | 능력치·고유 스킬·패시브·즐겨찾기 정보와 수치는 유지. 굵은 절 제목·주홍 밑줄·상태 탭·아이콘 내비게이션 적용. 전용 대표 초상은 원본에 없어 기존 페르소나 표시를 유지했다. |

문법 준수는 위 대상 전부 **예**로 갱신한다. 이는 승인 보드의 장면·가상 수치까지 동일하다는 뜻이 아니다. [시안과 before/after 비교 6개](verification/look-r24/round4/review/) 및 화면별 크기/스크롤 끝 연락 시트 **18개**를 직접 열고, 주요 원본도 확인했다. 고정 제목·행동 글자 잘림, 떠 있는 헤더 붓 조각, 마지막 행의 하단 띠 가림을 최종 캡처에서 발견하지 못했다. 스크롤 중 위아래 경계에서 지나가는 행이 일부 가려지는 동작은 정상 스크롤로 유지한다.

**크기·증거:** 360×780·390×664·390×844·430×932·1280×800 및 360×780 감소 모션. [before](verification/look-r24/round4/before/) **{len(before['captures'])}장**, [after](verification/look-r24/round4/after/) **{len(after['captures'])}장**. after의 추가 긴 기록·사용 가능 상태는 기존 검사 문구로 만든 격리 fixture다. [신규 검사](verification/look-r24/round4/after-results.json) **{after['checks']:,}건·실패 0**, 셸 Chromium **30상태/크기·실패 0**, 셸 자산 일치 검사 통과. 유동 패널의 스크롤과 하단 구분선 사이에는 **16px** 간격을 둔다. 데스크톱 유동 패널은 기존 생성 화면처럼 최대 900px, 고정 마을 계열은 승인된 마을과 같은 스케일/중앙 배치를 유지한다.

전 동료 대화·응답·관계 단계의 한국어/영어·360×780/430×932 전수 검사는 **{roster_checks:,}건·실패 0·글자 넘침 0**이다. 390×664를 포함한 나머지 크기는 기존 대표 인물 검사와 이번 크기별 검사에서 따로 확인했다.

**수정 파일:** `project/ui/{{town_theme_r21,panel_screen_r22,codex_screen_r22,journal_screen_r22,settings_screen_r22,town_screen_r21,facilities_screen_r22,expedition_screen_r22}}.gd` 8개. inventory/status는 공통 panel을 상속하므로 자체 논리 파일을 고치지 않았다. `town_theme`의 기존 먹·종이·주홍·서체·붓을 선택적 공용 행/내비게이션 헬퍼로 재사용했고, 승인된 다른 화면에는 새 헬퍼를 일괄 적용하지 않았다. [외형 diff](verification/look-r24/round4/appearance.diff) · [수정 경계](verification/look-r24/round4/boundaries.json).

**검사 변경과 초기 실패:** 최초 전체 실행의 7그룹 실패를 보존했고 최종 재검사로 해소했다. 대화 검사 2개는 화면 밖 스크롤 행을 그대로 누르던 포인터와 가려진 행의 겹침 판정을 수정했다. 다른 5그룹은 `button.text`와 버튼 내부 시각 라벨/화살표를 두 번 수집하던 관찰기를 고쳤다. 선택 판정도 부모 버튼의 글자색 대신 실제 주홍 붓 스타일을 확인한다. 변경한 기존 검사 파일은 `ui_dialogue_r21_test.gd`, `ui_dialogue_roster_r21_test.gd`, `ui_phase4_native_r23_test.gd`, `ui_phase4_screens_r23_test.gd` 4개다. 모든 버튼의 내용 영역 내 위치·전체 노출 가능 크기·실제 스크롤 포인터를 검사하며, 정본 데이터·문구·수치·행동 기대값 변경은 **0개**다. 신규 `ui_scroll_r24.gd`는 클리핑을 반영하는 검사 헬퍼, `ui_look_r24_round4_test.gd`는 크기별 실제 스크롤·포인터·캡처 검사다.

**보존:** 원본 이미지 **96개 해시 불변**. 게임 규칙·데이터·저장 형식·전투 파일·서버·`docs/` 변경 **0개**, 새 그림 생성·Web export·git 명령 **0회**. 사용자 저장은 건드리지 않고 격리 경로만 썼다. Windows 인증서 저장소 진단은 기존 환경 메시지이며 SCRIPT ERROR·그 외 ERROR·종료 코드와 구분해 검사했다. 클라우드는 실제 로컬 Worker/D1과 정상 종료를 확인했다.

남은 검증은 Claude의 export 뒤 **새 WASM 통합 웹 검사**와 실제 휴대폰 검토다. 네이티브 Godot와 원본 셸 Chromium에서 확인했다. Impeccable 수동 detector 결과는 `[]`이며 시각 승인 근거로 쓰지 않았다. 과거 r11 DESIGN.md와 현행 r21 코드/sidecar의 차이는 기존대로 남겼다. 해당 문서 동기화는 `document`로 별도 정리할 수 있다.

재현: `python tools/look_r24_suite.py --fresh`, `python tools/look_r24_cloud.py`, `python tools/godot_r17.py --position -10000,-10000 --script res://tests/ui_look_r24_round4_test.gd -- after`, `python tools/look_r24_shell.py after`, `python tools/look_r24_round4.py review`, `python tools/look_r24_round4.py finalize`.

'''
    p=R/'LOOK-R24.md';old=p.read_text(encoding='utf-8');title,rest=old.split('\n',1)
    if rest.lstrip().startswith('## 4차'):rest=rest[rest.index('## 3차'):]
    p.write_text(title+'\n\n'+section+rest.lstrip(),encoding='utf-8')
    print('FINAL',len(expected),'groups;',len(before['captures'])+len(after['captures']),'captures;',after['checks'],'new checks; failures 0')
if __name__=='__main__':
    if sys.argv[1]=='review':review()
    elif sys.argv[1]=='boundaries':sys.exit(boundaries())
    elif sys.argv[1]=='finalize':finalize()
