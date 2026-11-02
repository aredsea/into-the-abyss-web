from pathlib import Path
import sys,re,json,hashlib,bisect,csv,collections,datetime
sys.stdout.reconfigure(encoding='utf-8');sys.dont_write_bytecode=True
from audit_config import PURPOSES,CANDIDATES,DECISIONS
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[1];BOT=Path('C:/Clauede Code/dungeon-bot');SRC=BOT/'bot/src'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
STATUS=['같음','일부','없음','제외','미확인']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
INDEX=read(OUT/'source-index.json');GAME=read(OUT/'game-index.json');BYGAME={g['path']:g for g in GAME};BYSRC={s['file']:s for s in INDEX}
TEXT={s['file']:(SRC/s['file']).read_text(encoding='utf-8-sig').splitlines() for s in INDEX}
JSONMAP={}
def jsonmap(path):
 if path in JSONMAP:return JSONMAP[path]
 s=(ROOT/path).read_text(encoding='utf-8-sig');starts=[0]+[m.end() for m in re.finditer('\n',s)];decoder=json.JSONDecoder();out={}
 def ws(i):
  while i<len(s) and s[i].isspace():i+=1
  return i
 def parse(i,p):
  i=ws(i);a=i
  if s[i]=='{':
   i=ws(i+1)
   while s[i]!='}':
    k,j=decoder.raw_decode(s,i);i=ws(j);assert s[i]==':';i=parse(i+1,p+'/'+str(k).replace('~','~0').replace('/','~1'));i=ws(i)
    if s[i]==',':i=ws(i+1)
   i+=1
  elif s[i]=='[':
   i=ws(i+1);k=0
   while s[i]!=']':
    i=parse(i,p+'/'+str(k));k+=1;i=ws(i)
    if s[i]==',':i=ws(i+1)
   i+=1
  else:_,i=decoder.raw_decode(s,i)
  out[p]=(bisect.bisect_right(starts,a),bisect.bisect_right(starts,i-1));return i
 parse(0,'');JSONMAP[path]=out;return out
def location(path,fn=None,pointer=None):
 if not path:return None
 if pointer is not None:
  a,b=jsonmap(path).get(pointer,(1,1));return {'file':path,'start':a,'end':b,'pointer':pointer}
 g=BYGAME.get(path)
 if fn:
  match=next((x for x in (g or {}).get('functions',[]) if x['name']==fn),None)
  if not match:raise ValueError((path,fn))
  return {'file':path,'start':match['line'],'end':match['end'],'symbol':fn}
 return {'file':path,'start':1,'end':(g or {}).get('lines',len((ROOT/path).read_text(encoding='utf-8-sig').splitlines()))}
def locstr(l):return '없음' if l is None else f"{l['file']}:{l['start']}–{l['end']}"+(('#'+l['pointer']) if 'pointer' in l else '')
def sourceref(file,a,b):return f'{file}:{a}–{b}'
def counted(rows):return {s:sum(r['status']==s for r in rows) for s in STATUS}
HFILES={p.name:p.read_text(encoding='utf-8-sig') for p in (BOT/'bot').glob('harness*.mjs')}
HDEFAULT={
'01-game.lua':['harness_town.mjs','harness_panels.mjs','harness_i18n.mjs'], '05-gen.lua':['harness_party.mjs','harness_gear.mjs','harness_traits.mjs'], '10-data.lua':['harness.mjs','harness_party.mjs'], '15-josa.lua':['harness_i18n.mjs'], '20-state.lua':['harness.mjs','harness_party.mjs'], '24-stats.lua':['harness_party.mjs'], '26-start.lua':['harness_sortie.mjs'], '27-compose.lua':['harness_expedition.mjs','harness_raid.mjs'], '29-persona-skill.lua':['harness_persona_skill.mjs'], '30-engine.lua':['harness.mjs','harness_party.mjs'], '31-foes.lua':['harness_expedition.mjs','harness_raid.mjs'], '32-personal-a.lua':['harness_personal_a.mjs'], '32-personal-b.lua':['harness_personal_b.mjs'], '34-traits.lua':['harness_traits.mjs','harness_regen_mix.mjs'], '40-fx.lua':['harness.mjs'], '50-render.lua':['harness.mjs'], '51-raid.lua':['harness_raid.mjs'], '60-create.lua':['harness_create.mjs','harness_persona_bonus.mjs'], '65-codex.lua':['harness_panels.mjs'], '66-status.lua':['harness_panels.mjs','harness_gear.mjs'], '67-settings.lua':['harness_panels.mjs','harness_settings_form.mjs','harness_i18n.mjs'], '68-cloud.lua':['harness_cloud.mjs'], '70-town.lua':['harness_town.mjs','harness_economy.mjs'], '71-shop.lua':['harness_economy.mjs','harness_smithy.mjs'], '72-guild.lua':['harness_town.mjs','harness_economy.mjs'], '73-inn.lua':['harness_affection.mjs','harness_town.mjs'], '74-affection.lua':['harness_affection.mjs'], '74-level.lua':['harness_economy.mjs'], '75-sortie.lua':['harness_sortie.mjs','harness_party.mjs'], '76-dungeon.lua':['harness_expedition.mjs'], '77-explore.lua':['harness_expedition.mjs','harness_regen_mix.mjs'], '78-battle-item.lua':['harness_expedition.mjs','harness_regen_mix.mjs'], '79-sex.lua':['harness_sex.mjs','harness_sxaux.mjs','harness_npcaff.mjs'], '80-press.lua':['harness.mjs'], '81-gear.lua':['harness_gear.mjs','harness_smithy.mjs'], '82-smithy.lua':['harness_smithy.mjs'], '85-portrait.lua':['harness_portrait.mjs'], '86-portrait-have.lua':['harness_portrait.mjs'], '87-portrait-modules.lua':['harness_sex.mjs'], '88-lore.lua':['harness_lore.mjs'], '89-art.lua':['harness_art.mjs'], '89-memory.lua':['harness_memory.mjs'], '90-triggers.lua':['harness_settings_form.mjs','harness_art.mjs','harness_memory.mjs']}
def harness(file,name):
 found=[]
 for n,s in HFILES.items():
  if name.startswith('B.') and name in s:
   a=s[:s.index(name)].count('\n')+1;found.append({'file':n,'line':a,'basis':'심볼 직접 참조'})
 if not found:found=[{'file':n,'basis':'모듈 관련 하네스; 해당 내부 함수의 단언 범위는 미확인'} for n in HDEFAULT.get(file,[]) if n in HFILES]
 return found[:4]

def decide(file,r):
 name=r['name'];parent=r.get('parent','');kind=r['kind']
 if (file,name) in DECISIONS:return DECISIONS[(file,name)],'개별 코드/시험 판정'
 if file in ['00-host.lua','79-sex.lua','87-portrait-modules.lua','89-art.lua','90-triggers.lua']:
  why={'00-host.lua':'RisuAI 전용 reloadDisplay/getChat* 호환 API', '79-sex.lua':'사용자 결정: 79-sex.lua 및 친밀/성적 장면 전체 이관 제외; 함수·라우트·필드 목록만 기록, 장면 실행 안 함', '87-portrait-modules.lua':'제외된 성인 에셋 모듈의 namespace/보유 이름표; 기본 초상 표시는 85/86에서 계속 추적', '89-art.lua':'RisuAI 대화 답변의 삽화·표정 선택/모델 요청/파싱/메시지 캐시. Godot 기본 초상 표시는 85/86에서 별도 추적', '90-triggers.lua':'RisuAI 버튼/폼/출력/요청 훅 자체. 설정 값·언어·저장·초상 대응은 관련 모듈에서 유지'}[file]
  return ('제외',None,None,why,None),'제외 범위'
 if file in ['60-create.lua','68-cloud.lua','69-rank.lua','15-josa.lua']:
  if file=='60-create.lua' and 'CTX' in name:return ('제외',None,None,'AI 페르소나 설명 요청 문맥; 실제 생성 화면·능력치 선택은 제외하지 않음',None),'호스트/AI 보조'
  why={'60-create.lua':'게임 초기화는 고정 4명/200금화이며 persona 생성·종족/출신/직업·포인트 배분·첫 만남 화면/저장 필드가 없음', '68-cloud.lua':'game/ui 전체 HTTPRequest/HTTPClient/cloud/wpin/hmac 검색 0건; world_store:write는 로컬 파일/백업뿐, 클라우드 계정·PIN·서명·복원 없음', '69-rank.lua':'최고층 로컬 진도만 존재; rank/백분위/요청/300초 캐시 UI·서버 연동 없음', '15-josa.lua':'한글/ASCII 받침과 조사 유틸 대응 없음'}[file]
  return ('없음',None,None,why,None),'모듈 부재와 등록/상태 전체 검색'
 if file=='67-settings.lua':
  if re.search(r'nsfw|sxpick|redraw|pimg|art_[012]|chap_[01]|diet_[01]|formoff',name) and not re.search(r'chron_[01]',name):return ('제외',None,None,'NSFW/AI 응답/호스트 인레이·폼·화면 갱신용 선택지. 일반 설정·언어·난이도·확정 연대기는 제외하지 않음',None),'호스트 옵션만 제외'
  if name in ['B.PANELS.save']:
   return ('일부','project/game/world_store.gd','write','로컬 자동 저장/백업은 존재; 원본 저장 상태 화면과 클라우드 연결 없음',None),'로컬 저장 코드 대조'
  return ('없음',None,None,'설정 화면·일반 난이도 0.8/1/1.25·ko/en·초기화 확인/실행 대응 없음; 전투 연출 옵션과 다른 기능',None),'화면 등록/상태 검색'
 if file=='01-game.lua' and kind=='save_field':
  if re.search(r'\b(?:sexlog|npcs|nmark|pending|pend_|lore_mv)',name):return ('제외',None,None,'성적 장면 또는 RisuAI 요청/채팅 동기화 전용 저장 필드',None),'필드 용도'
  if re.search(r'^G\.(persona|scenario|favs|settings)(\.|$)',name):return ('없음',None,None,'실행 상태에 해당 원본 필드/동등한 모델이 없음; 고정 동료/전투 연출 상태는 별개',None),'저장 schema 코드 대조'
  return ('일부','project/game/world_state.gd','_init','상태 저장 대응은 있으나 초기값/구조/난수·별도 장비 UID·UI 위치 영속화 계약 차이',None),'저장 schema 코드 대조'
 if file=='88-lore.lua':
  if re.search(r'PLACE|NPC_AT|place_(?:movable|id|label|set)$',name) or re.search(r'place_(?:movable|id|label|set)$',parent):
   return ('일부','project/ui/town_screen_r21.gd','home','일반 장소/NPC 배치와 장소 이동 상태. 주요5시설만 대응하고 기록관/검문소/통역골목/등불쉼터 및 상태 영속화 계약이 빠짐',None),'일반 장소 상태 대조'
  return ('제외',None,None,'RisuAI 장소 마커/채팅 동기화·인물 로어 선별·프롬프트 주입·능력 질문 문맥; 실제 장소/NPC와 고정 소개는 별도 추적',None),'호스트 요청 전용'
 if file=='89-memory.lua' and re.search(r'chap|diet|request|chron_note|chron_english',name):return ('제외',None,None,'AI용 장 요약/프롬프트 정리·영문 요청 변환·AI 주입 전용; 확정 사건 연대기는 제외하지 않음',None),'AI 기억 보조만 제외'
 if file=='05-gen.lua':
  if name in ['B.INTIMACY','B.LORE','B.LORE_ORDER']:return ('제외',None,None,'친밀 장면 수치 또는 RisuAI 인물 로어 주입 원고; 일반 초상/도감 소개/장소/설정은 다른 행에서 추적',None),'데이터 사용처'
  if name in ['B.EN_RAW','B.UI_RAW','B.SCEN','B.SCEN_EN']:return ('없음',None,None,'한국어/영문 UI 사전 또는 고정 첫 만남 시나리오 데이터/화면 연동이 게임에 없음',None),'화면/언어 상태 검색'
 if file=='86-portrait-have.lua':return ('일부','project/data/portrait-slots-r21.json',None,'원본 기본/표정 보유 이름표 전체를 읽음. 게임의 300칸은 30명×10화면 크롭이며 20표정 선택에 해당하지 않음',None),'초상 데이터 계약 대조'
 # An audited handler proves only partial route/affordance coverage, never an
 # individual button's equivalence merely because the containing test passed.
 if kind in ['route','route_value','button'] and (file,parent) in DECISIONS:
  d=DECISIONS[(file,parent)]
  if d[0]=='일부':return d,'상위 처리기의 일부 구현; 개별 버튼 전범위 시험 아님'
 # Semantic code has not been individually compared: preserve that uncertainty.
 c=CANDIDATES.get(file)
 return ('미확인',*(c[:2] if c else (None,None)),('대응 후보만 찾음; 이 함수/표/필드의 규칙·수치·전체 분기는 직접 확정하지 않음. '+c[2]) if c else '개별 기능 대응 미확인',None),'후보 검색만; 동일/부재 추정 금지'

def description(file,r):
 name=r['name'];kind=r['kind']
 if name.startswith('B.PRUN.'):return f'{name.split(".")[2]} 개인 기술 실행 ({name})'
 if name.startswith('B.TR.'):return f'{name.split(".")[2]} 특성 {".".join(name.split(".")[3:]) or "사건 훅 표"} ({name})'
 if name.startswith('B.SCREENS.') or name.startswith('B.PANELS.'):return f'{name.split(".")[-1]} 화면/패널 표시'
 if name.startswith('B.H.') or name.startswith('B["H"]'):return f'{name} 버튼 접두 처리'
 labels={'function':'함수','route':'버튼 라우트/인자 분기','route_value':'개별 버튼 인자 값','button':'화면 버튼/동적 버튼 틀','save_field':'저장 상태 쓰기/기본 필드','state_field':'상태 별칭/전투 기본 필드 쓰기(소유/영속성 개별 대조)','table':'규칙·수치·등록 표','constant':'상수·모듈 등록','module_rule':'모듈 초기화·연결 규칙','data_record':'데이터 개별 항목'}
 return f'{PURPOSES[file].split("·")[0]} — {labels.get(kind,kind)} {name}'

def build_rows():
 rows=[]
 for f in INDEX:
  for r in f['features']:
   decision,basis=decide(f['file'],r);status,path,fn,reason,test=decision
   loc=location(path,fn) if path else None
   data={'source':{'file':'bot/src/'+f['file'],'start':r['start'],'end':r['end'],'symbol':r['name']},'kind':r['kind'],'description':description(f['file'],r),'implementation':loc,'status':status,'evidence':{'method':basis,'reason':reason,'tests':[test] if test else [],'source_lines':sourceref(f['file'],r['start'],r['end']),'game_lines':locstr(loc),'scope':'행에 명시한 기능/입력 범위만. 상위/하위 행으로 같음을 전파하지 않음'},'original_harnesses':harness(f['file'],r['name'])}
   if status=='미확인':data['implementation_is_candidate']=True
   rows.append(data)
 # Expanded canonical records: every enemy, gear item, class, companion and
 # companion trait parameter set is individually enumerable and reproducible.
 dc=read(OUT/'data-comparison.json')
 for check in dc['checks']:
  key=check['id'];file='05-gen.lua';name='B.'+key;anchor=None;pointer=None
  if key.startswith('design:'):continue
  if ':' in key:
   category,id=key.split(':',1)
   root={'gear':'B.GEAR_RAW','cast':'B.CAST','trait':'B.GEN','foe':'B.FOES','class':'B.CLS','FAMS':'B.FAMS','ZONES':'B.ZONES','RIFTS':'B.RIFTS'}.get(category)
   if not root:continue
   anchor=next((r for r in BYSRC[file]['features'] if r['name']==root and r['kind']=='table'),None)
   if not anchor:anchor=next(r for r in BYSRC[file]['features'] if r['name']==root)
   a,b=anchor['start'],anchor['end']
   if category!='gear':
    for n in range(a,b+1):
     if re.match(r'\s*(?:\[\s*["\']?'+re.escape(id)+r'["\']?\s*\]|'+re.escape(id)+r')\s*=',TEXT[file][n-1]):a=b=n;break
   name={'gear':'B.GEAR_EXPANDED.items','cast':'B.CAST','trait':'B.GEN.tr','foe':'B.FOES','class':'B.CLS','FAMS':'B.FAMS','ZONES':'B.ZONES','RIFTS':'B.RIFTS'}[category]+'.'+id
   target=check['target'];path,pointer=target.split('#',1)
   loc=location(path,pointer=pointer)
   label={'gear':'장비 정의/수치','cast':'동료 표시/기초 메타데이터','trait':'동료 특성 파라미터','foe':'적 행동표/약점/규칙','class':'직업 기초/성장 수치','FAMS':'적 계통 이름/구역/아이콘','ZONES':'던전 구역 정의','RIFTS':'균열 정의'}[category]
   status='같음' if check['same'] else '일부'
   reason='현재 정본 Lua 테이블과 게임 JSON의 해당 항목을 구조/값으로 직접 대조. '+check['scope']
   if not check['same']:
    reason=({'FAMS':'원본 생성표에는 fam-NN 아이콘 키가 있으나 게임 계통 JSON에는 그 키가 없음; 이름/구역 일치는 별도.', 'cast':'원본 CAST와 게임 표시 메타데이터 차이: 힐데가/베렌가/바르굿 명칭 또는 미코 특성 설명.', 'trait':'현재 정본 미코 variant=2 ↔ 게임 variant=1. bonus=.6/pull=.4 값만 같음.'}.get(category,'구조/값 대조 불일치; 같음으로 세지 않음.'))+' '+check['scope']
   r={'source':{'file':'bot/src/'+file,'start':a,'end':b,'symbol':name,'data_pointer':key},'kind':'data_record','description':f'{label}: {id}','implementation':loc,'status':status,'evidence':{'method':'현재 Lua 실행값/JSON 직접 대조','comparison_id':key,'comparison_passed':check['same'],'reason':reason,'tests':[],'source_lines':sourceref(file,a,b),'game_lines':locstr(loc),'scope':'이 데이터 항목의 선언값만; 전투·UI·저장 동작 완성을 뜻하지 않음'},'original_harnesses':harness(file,name)}
   rows.append(r)
  else:
   # Existing table row receives exact evidence; no duplicate aggregate row.
   symbol='B.'+key
   for r in rows:
    if r['source']['file']=='bot/src/05-gen.lua' and r['source']['symbol']==symbol and check['same']:
     path,target=check['target'].split('#',1) if '#' in check['target'] else (check['target'],'')
     r['implementation']=location(path,pointer=target);r['status']='같음';r.pop('implementation_is_candidate',None)
     r['evidence']={'method':'현재 Lua 실행값/JSON 직접 대조','comparison_id':key,'comparison_passed':True,'reason':'현재 정본 전체 표의 명시된 키/수치와 게임 JSON을 직접 대조. 추가 설명 메타데이터는 비교에서 분리. '+check['scope'],'tests':[],'source_lines':sourceref(file,r['source']['start'],r['source']['end']),'game_lines':locstr(r['implementation']),'scope':'선언 데이터만; 사용처의 전체 동작과 분리'}
 # Nested G_new default fields, including every persona, UI and dungeon field.
 defaults=read(OUT/'lua-save-defaults.json');existing={r['source']['symbol'] for r in rows if r['source']['file']=='bot/src/01-game.lua' and r['kind']=='save_field'}
 def fields(v,p):
  if not isinstance(v,dict):return
  for key,value in v.items():
   name=p+'.'+key
   if name not in existing:
    n=next((i for i in range(15,41) if re.search(r'\b'+re.escape(key)+r'\s*=',TEXT['01-game.lua'][i-1])),13)
    r={'name':name,'kind':'save_field','start':n,'end':n};decision,basis=decide('01-game.lua',r);status,path,fn,reason,test=decision;loc=location(path,fn) if path else None
    rows.append({'source':{'file':'bot/src/01-game.lua','start':n,'end':n,'symbol':name,'default':value},'kind':'save_field','description':'저장 기본 필드 '+name,'implementation':loc,'status':status,'evidence':{'method':basis,'reason':reason,'tests':[],'source_lines':sourceref('01-game.lua',n,n),'game_lines':locstr(loc)},'original_harnesses':harness('01-game.lua','B.G_new')})
   fields(value,name)
 fields(defaults,'G')
 # Potion generation expands one line into nine real item definitions.
 constants=read(OUT/'lua-constants.json');items=read(ROOT/'project/data/world.json')['items']
 for iid,v in sorted(constants['ITEMS'].items()):
  target={'scroll':'return','sh_s':'shield_s','sh_m':'shield_m','sh_l':'shield_l'}.get(iid,iid);idx=next((i for i,x in enumerate(items) if x['id']==target),None)
  ln=31 if v.get('kind') else 15 if iid=='antidote' else 16 if iid=='bandage' else 17 if iid=='scroll' else 20 if iid=='level_scroll' else 23
  loc=location('project/data/world.json',pointer=f'/items/{idx}') if idx is not None else None
  excluded=iid=='charm_potion';legacy=v.get('slot') is not None;reason='원본/게임 소모품은 ID 별명·표시 이름/설명과 사용 규칙을 따로 대조해야 함; 보유 상한10000·원정 주머니 계약 차이. 원본='+json.dumps(v,ensure_ascii=False)
  if excluded:reason='매혹의 비약은 제외된 친밀 장면 전용 소모품'
  file='71-shop.lua'
  if legacy:
   file='77-explore.lua';ln=46;loc=location('project/game/dungeon_world_r21.gd','restore');reason='원본 77-explore:43-46이 임시 장비 정의를 B.ITEMS로 등록. 구형 아이템/이관 전용 데이터의 게임 저장 대응은 개별 미확인. 원본='+json.dumps(v,ensure_ascii=False)
  entry={'source':{'file':'bot/src/'+file,'start':ln,'end':ln,'symbol':'B.ITEMS.'+iid},'kind':'data_record','description':('구형 임시 장비 아이템 정의: ' if legacy else '소모품 개별 정의: ')+iid,'implementation':loc,'status':'제외' if excluded else '미확인' if legacy else '일부','evidence':{'method':'아이템별 선언 직접 열람','reason':reason,'tests':[],'source_lines':sourceref(file,ln,ln),'game_lines':locstr(loc)},'original_harnesses':harness(file,'B.ITEMS')}
  if legacy:entry['implementation_is_candidate']=True
  rows.append(entry)
 rows.sort(key=lambda r:(r['source']['file'],r['source']['start'],r['kind'],r['source']['symbol']))
 for i,r in enumerate(rows,1):r['id']=f'P{i:04d}'
 return rows

BUNDLES=[
('P1','페르소나·첫 시작·저장 토대','없음','persona_rules.gd / persona_world.gd / create_screen.gd 신규, world_store의 schema 어댑터','60-create,01-game,20-state,26-start,74-level,75-sortie','종족/계통·출신 제약·10직업·포인트5/10/20/사용자값·시나리오·300금화·첫 동료·자기참전/지휘·옛 저장 무손실 이관','harness_create.mjs, harness_persona_bonus.mjs, harness_party.mjs, harness_sortie.mjs'),
('P2','전투 CTB·아군 RNG·라운드·표시 계약','P1','battle_state.gd / battle_v3.gd의 턴 스케줄·피해/훅 어댑터 및 battle_screen.gd 표시 연결','20-state,30-engine,40-fx,50-render,51-raid,80-press','ceil CTB·동률/예측·라운드 MP·행동별16807 재시드·강제치명 RNG 소비·공격/고갈/종료·저장 재개 oracle; 사건별 연출/상태칩·레이드 충전/단계/예고 의미 대조, r18~20 외형 보존','harness.mjs, harness_party.mjs, harness_regen_mix.mjs, harness_raid.mjs'),
('P3','30명 개인 기술·특성·전투 시너지','P2','personal_rules_r22.gd / trait_rules_r22.gd 신규; P2가 연결점 소유','30-engine 후반,32-personal-a/b,34-traits 전투부','각 기술/사건 훅 전수 입력-출력·사용횟수/지속/시전자 사망·미코 variant2·30명/종족·출신·직업 상호작용','harness_personal_a.mjs, harness_personal_b.mjs, harness_traits.mjs, harness_regen_mix.mjs'),
('P4','장비 전투효과·옵션·코드/구저장 계약','P2','gear_rules.gd / gear_hooks_r22.gd 신규 / 전용 장비 이관 어댑터','81-gear,05-gen GEAR_RAW','원본 코드/옵션 생성·전설 장신구30·proc/부가훅·source_r21 구/신 경로 및 던전 드롭 옵션 차이 해소 방안·가방2000·기존 저장 무손실 시험','harness_gear.mjs, harness_smithy.mjs'),
('P5','던전 원정·전투 밖 시너지·정산','P1,P3,P4','dungeon_world_r21.gd / expedition_rules_r22.gd 신규 / dungeon_view_r21.gd','76-dungeon,77-explore,78-battle-item,34-traits tx_*','발견/휴식/호감/패배 보전·주머니/보급품·휴식중 장비·다음층 연속 하강·추천/페이지/완료 내역·폐기/부상·이중정산; 420층 회귀','harness_expedition.mjs, harness_regen_mix.mjs, harness_raid.mjs'),
('P6','길드·영입·상점·여관·대장간 연결','P1,P4','town_world_r21.gd / guild_rules_r21.gd / commerce_rules_r21.gd; 시설별 UI 파일 분리','70-town,71-shop,72-guild,73-inn,82-smithy','영입 정본 RNG/페르소나레벨·원본10직업 진열·페르소나 가공풀·레벨업스크롤 대상·원본 일반 문구/상한·마감 동선; 성적 부가 기능은 제외','harness_town.mjs, harness_economy.mjs, harness_smithy.mjs, harness_affection.mjs'),
('P7','도감·상태·가방·호감 단계·초상','P1,P4','codex_screen_r22.gd / status_screen_r22.gd 신규 / town_portrait_r21.gd','65-codex,66-status,74-affection,85/86-portrait','미영입 포함 도감/필터/페이지·persona 상세·즐겨찾기3·8단계 호감·장비 비교/일괄판매/정렬·원본 기본/표정 선택·결손 대체','harness_panels.mjs, harness_portrait.mjs, harness_affection.mjs'),
('P8','일반 설정·한국어/영문·표기 교정','P1','settings_screen_r22.gd / localization_r22.gd 신규; world.json 명칭/미코 설명은 P3와 순서 조정','01-game 언어,15-josa,67-settings,90-settings 값','ko/en 사전·동적 조사·난이도0.8/1/1.25·저장 상태·안전한 초기화 확인·원본 힐데가/베렌가/바르굿 표시·계통아이콘; AI/NSFW/호스트 redraw 제외','harness_i18n.mjs, harness_settings_form.mjs, harness_panels.mjs'),
('P9','클라우드 저장·이관·순위','P1,P8','cloud_store_r22.gd / rank_service_r22.gd / save_screen_r22.gd 신규','68-cloud,69-rank,67-save','계정코드/PIN·SHA256/HMAC/base64·페이로드 허용목록·검증/원자적 복원·링크·최신rev·백분위300초캐시; 원본 서버 계약과 서명키 제공 방식 확인 후 통합','harness_cloud.mjs (순위 전용 원본 하네스 없음; 새 순위 대조 fixture 필요)'),
('P10','고정 세계 설명·마을 장소·확정 연대기','P1,P5,P7','town_places_r22.gd / chronicle_store_r22.gd / journal_screen_r22.gd 신규','88-lore 비호스트 장소/소개,89-memory chron_*','기록관/검문소/통역골목/등불쉼터·일반 NPC 위치·고정 인물 소개·일자/확정사건/호감단계/전설장비/레벨 기록·중복/보존 규칙; AI 요약/로어주입 제외','harness_lore.mjs, harness_memory.mjs (비AI 사건/장소 부분만)')]

FINDINGS=[
{'id':'F01','title':'첫 시작/페르소나 부재·초기 상태 차이','source':'01-game.lua:13-40;60-create.lua:5-640;75-sortie.lua:15-50,196-255','game':'project/game/world_state.gd:5-16;project/game/expansion_world.gd:11-25;project/data/world.json#/provisional','detail':'원본은 create·금화300·빈 roster·페르소나/첫 만남. 게임은 고정4명(힐데가르트/바르구트/테이리스/베렝가),금화200·기본 보급품으로 시작. 자기참전/1~4인 출정·미출전 persona50% 경험치 없음.','bundle':'P1'},
{'id':'F02','title':'전투 CTB·라운드·아군 RNG 차이','source':'20-state.lua:3-9;30-engine.lua:188-245,284-326,781-806','game':'project/game/battle_state.gd:71-129;project/game/battle_v3.gd:199-211','detail':'원본 ceil(g/sp),시간 라운드·아군 행동별16807 재시드. 게임 연속 실수 CTB·48271 RNG/아군 차례 MP회복. 원본 강제치명에도 rnd를 소비하지만 게임 mark OR _roll은 단락 평가해 건너뛴다. 적1,221행동 시험 통과가 아군 전체 동등성을 뜻하지 않는다.','bundle':'P2'},
{'id':'F03','title':'현재 정본 미코 variant 2와 게임 variant 1 불일치','source':'05-gen.lua:GEN.tr.miko;32-personal-b.lua:481-528','game':'project/data/world.json#/companions/28/trait;project/game/battle_v3.gd:125-138,492','detail':'현재 정본 variant=2: 매 라운드 자신 제외 가장 늦은 아군을 게이지40% 당김. 게임 데이터 variant=1, 미코 회복시 다음 공격+60% 부여. bonus=.6/pull=.4 자체는 같지만 켜진 분기가 다르다. 기존 보고서의 봇 런타임 variant1 설명만으로 같음 처리하지 않았다.','bundle':'P3'},
{'id':'F04','title':'전투 밖 출신 시너지 4종 함수 누락','source':'34-traits.lua:153-178;77-explore.lua:237-305,483-516','game':'project/game/dungeon_world_r21.gd:84-99,193-208','detail':'솔렌3 휴식HP+4%p/동행호감+20%,나에린3 휴식MP+3%p·회복약 추가,카라쉰3 발견금화+40%,경계2/3 아이템 추가30/60%,케른2 패배금화손실−30%·3 수확40%보전이 적용되지 않음.','bundle':'P5'},
{'id':'F05','title':'동료 소개의 RNG·영입 레벨 차이','source':'72-guild.lua:291-318;74-level.lua:50-55;01-game.lua:139-147','game':'project/game/expansion_world.gd:23-25,73-82','detail':'원본은 G_rnd와 페르소나 레벨, 게임은 웹 RNG와 현재 파티 최고 레벨. 100+20n 비용의 동일성과 영입 전체 규칙의 동일성을 분리했다.','bundle':'P6'},
{'id':'F06','title':'원본 연구를 동료 방어 대체 전술로 바꿈','source':'29-persona-skill.lua:69-145,160-257;20-state.lua:93-104','game':'project/game/expansion_world.gd:218-244,280-286;project/ui/world_screen.gd:578-608;project/game/battle_v3.gd:407-422','detail':'조각 데이터는 같음. 그러나 원본 persona.skill 별도 고유기술 대신 동료별 research 슬롯이 방어 버튼을 대신한다. 대상/장착/강화 상한·취소/확정·원본 고유기술 실행을 같음으로 세지 않음.','bundle':'P1/P3'},
{'id':'F07','title':'새 상거래 장비만 정본 옵션을 사용','source':'81-gear.lua:109-164,1074-1169','game':'project/game/commerce_rules_r21.gd:46-66;project/game/town_world_r21.gd:97-127;project/game/dungeon_world_r21.gd:197-201','detail':'상점/가공 신규 장비에 source_r21=true. 구저장과 던전 드롭에는 표시가 없어 legacy 옵션으로 계산. 1,030 장비 정의와 8,520 상거래 표본이 같아도 모든 장비 경로가 같지는 않다.','bundle':'P4'},
{'id':'F08','title':'일반 설정·다국어·클라우드·순위 누락','source':'01-game.lua:78-128;67-settings.lua:4-150;68-cloud.lua:1-348;69-rank.lua:1-48','game':'project/ui/world_screen.gd:69-132;project/game/world_store.gd:1-27;verification/parity-r21/search-evidence.json','detail':'Godot 전투 연출 설정/로컬 저장은 있으나 원본 일반 난이도·언어·설정화면·계정/PIN·클라우드 링크/서명/복원·백분위순위는 없음. 호스트 전용이라는 이유로 제외하지 않았다.','bundle':'P8/P9'},
{'id':'F09','title':'표시 이름 3명·아이템 이름·계통 아이콘 차이','source':'05-gen.lua:65-94,132-162;71-shop.lua:14-23','game':'project/data/world.json#/companions;project/data/enemies-r21.json#/families;project/data/world.json#/items','detail':'힐데가→힐데가르트,베렌가→베렝가,바르굿→바르구트. 원본 해독약/귀환 두루마리/레벨업 스크롤이 게임 해독제/귀환 주문서/성장 주문서로 바뀜. 계통30개는 이름/구역 데이터는 같지만 원본 fam-NN 아이콘 키가 없음. 아이콘의 실제 화면 대응은 미확인.','bundle':'P8'},
{'id':'F10','title':'도감·표정·장소·확정 연대기는 남은 일반 기능','source':'65-codex.lua:217-467;66-status.lua:7-400;85-portrait.lua:10-46;86-portrait-have.lua:1-629;88-lore.lua:12-72;89-memory.lua:80-117','game':'project/ui/town_portrait_r21.gd;project/ui/town_screen_r21.gd:170-242,670-678;project/game/world_state.gd:41-44','detail':'화면별 초상300칸을 원본20표정으로 세지 않음. 미영입 도감/즐겨찾기3·persona 상태·호감8단계·기록관/검문소/통역골목/등불쉼터·확정사건 연대기는 전용 계약을 확인/이식해야 함. 최근30줄 로그와 원본 연대기의 보존/중복/사건 조건은 다름.','bundle':'P7/P10'}]

def search_evidence():
 patterns={'network_rank':r'HTTPRequest|HTTPClient|\bcloud\b|wpin|hmac|\brank\b','localization':r'\blanguage\b|\blocale\b|TranslationServer','persona_state':r'\bpersona\b','favorite':r'\bfavs\b|즐겨찾기','affection_stage':r'적대|불신|낯섦|깊은 인연|맹세|운명'}
 report={}
 for name,p in patterns.items():
  hits=[]
  for folder in ['project/game','project/ui']:
   for f in (ROOT/folder).glob('*.gd'):
    for n,l in enumerate(f.read_text(encoding='utf-8-sig').splitlines(),1):
     if re.search(p,l,re.I):hits.append({'file':f.relative_to(ROOT).as_posix(),'line':n,'text':l})
  report[name]={'pattern':p,'scope':'project/game/*.gd + project/ui/*.gd 全文','hits':hits,'count':len(hits)}
 (OUT/'search-evidence.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 return report

def main():
 rows=build_rows();search=search_evidence();files=[]
 for f in INDEX:
  group=[r for r in rows if r['source']['file']=='bot/src/'+f['file']];counts=counted(group);denom=len(group)-counts['제외'];logic=[r for r in group if r['kind']!='data_record'];lc=counted(logic)
  ranges=[[i,min(f['lines'],i+399)] for i in range(1,f['lines']+1,400)]
  files.append({'file':f['file'],'purpose':PURPOSES[f['file']],'total_lines':f['lines'],'read_ranges':ranges,'read_method':f['read_method'],'sha256':f['sha256'],'rows':len(group),'counts':counts,'confirmed_same_row_percentage':round(100*counts['같음']/denom,1) if denom else None,'non_record_counts':lc,'non_record_rows':len(logic),'original_harnesses':sorted(set(h['file'] for r in group for h in r['original_harnesses']))})
 for f in files:
  f['newline_count']=BYSRC[f['file']].get('newline_count')
  f['ends_with_newline']=BYSRC[f['file']].get('ends_with_newline')
 context=[]
 for name in ['UI-R17.md','UI-R18.md','UI-R19.md','UI-R20.md','DATA-R21.md','UI-R21-B.md','UI-R21-C.md','UI-R21-D.md']:
  p=ROOT/name;s=p.read_text(encoding='utf-8-sig');context.append({'file':name,'sha256':sha(p),'lines':len(s.splitlines()),'read_ranges':[[1,len(s.splitlines())]],'same_status_based_on_report_only':False,'headings':[{'line':i,'text':l} for i,l in enumerate(s.splitlines(),1) if l.startswith('#')]})
 (OUT/'report-index.json').write_text(json.dumps(context,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 checks=read(OUT/'checks.json');fresh=read(OUT/'fresh-checks.json');dc=read(OUT/'data-comparison.json');write=read(OUT/'write-audit.json')
 report={'schema_version':1,'title':'R21 원본 봇 기능 전수 대조표','created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'workspace':str(ROOT),'canonical_root':str(BOT),'scope':{'lua_files':len(files),'lua_lines':sum(f['total_lines'] for f in files),'brief_lines':18794,'brief_difference':1,'coverage':'모든 Lua를 UTF-8 전체 읽기/토큰 스캔. 전 함수·등록/수치 표·라우트·버튼 틀·발견된 저장필드와 코드 잔여 구간을 행으로 색인. 모든 함수의 의미 동등성을 검증한 것은 아니며, 개별 미검증은 미확인.','read_semantics':'read_ranges는 전체 텍스트/토큰 읽기 구간. 의미 대조 완료 구간은 개별 행 evidence로 한정. 긴 내장 JSON/로어/성인 이름표도 바이트 전체를 읽었지만 미열람 이미지는 없음으로 판정하지 않음.','not_a_completion_estimate':'행은 함수/라우트/표/필드와 데이터 항목을 함께 세므로 겹침. 행별 같음 비율은 개발 공수/게임 완성률이 아님.'},'summary':{'total_rows':len(rows),'counts':counted(rows),'non_record_counts':counted([r for r in rows if r['kind']!='data_record']),'data_record_counts':counted([r for r in rows if r['kind']=='data_record']),'unverified_rows':sum(r['status']=='미확인' for r in rows),'common_and_added_check_groups':len(checks),'common_and_added_failed_groups':sum(c['exit_code']!=0 or bool(c['errors']) for c in checks),'fresh_oracle_commands':len(fresh),'fresh_failed_commands':sum(c['exit_code']!=0 for c in fresh),'data_value_checks':len(dc['checks']),'data_values_same':dc['passed'],'data_value_differences':dc['not_equal'],'outside_files_checked':write['files_checked'],'outside_allowed_changed':len(write['changed_outside_allowed'])},'files':files,'findings':FINDINGS,'work_packages':[{'id':b[0],'title':b[1],'depends_on':b[2],'owned_files':b[3],'source_modules':b[4],'acceptance':b[5],'original_harnesses':b[6]} for b in BUNDLES],'verification':{'checks':checks,'fresh_checks':fresh,'data_comparison':'data-comparison.json','write_audit':'write-audit.json','visual_review':{'opened':['runtime/verification/ui-r20/base-360.png','runtime/verification/ui-r20/supplies-360.png','runtime/verification/ui-r20/log-360.png'],'observation':'360px 기본/보급품/전투기록에서 주요 적/아군·HP/MP·대상/버튼·모달 배치를 직접 확인. 시안 전패널/모든 생성 이미지를 검수한 것으로 세지 않음.'},'environment_diagnostic':'Godot root certificate store 진단은 로그에 보존. 테스트 단언/스크립트 오류와 분리하며 서버/네트워크 시험 통과로 해석하지 않음.'},'process_notes':['공통 규칙을 읽기 전 초기 묶음 호출에 git status --short가 포함되어 소유권 오류로 실패했다. 이후 git 명령/설정 변경 없음.','초기 격리 실행에서 oracle fixture를 복사하지 않아 data_r21_test가 대기하여 중단했다. 필요한 근거 JSON을 격리에 복사한 뒤 22종 전체를 다시 실행했다. 기대값 변경 없음.','Godot는 허용된 도구 tools/godot_r17.py 원본 복사본으로만 실행. import/라이선스/검사 이미지의 쓰기는 verification/parity-r21/runtime 안에만 발생.','원본 하네스는 관련 코드/시험 이름을 읽어 연결했으며 전체 harness_*.mjs를 실행한 것으로 주장하지 않음. 실제 원본 실행은 lua_sim.mjs 기반 현재 원문 재적재 oracle 5개만 실행. 성적 장면/AI 생성·외부 업로드 호출 없음.'],'rows':rows}
 report['scope'].update({'lua_newline_count':sum(f['newline_count'] for f in files),'brief_difference':0,'line_count_note':'개행(LF) 18,794개로 지시서와 같음. 05-gen.lua 마지막 줄에 LF가 없어 논리 행 수는 18,795. 원본 변경/추가 행을 의미하지 않음.','kind_counts':dict(collections.Counter(r['kind'] for r in rows))})
 validation=read(OUT/'validation.json') if (OUT/'validation.json').exists() else None
 if validation and validation['rows']==len(rows):report['verification']['document_validation']={'checks':validation['checks'],'failures':validation['failures'],'path':'validation.json'}
 report['verification']['context_reports']='report-index.json'
 (OUT/'parity.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 def safe(s):return str(s).replace('|','&#124;').replace('\n',' ')
 counts=report['summary']['counts'];parts=['# PARITY-R21 — 원본 봇 기능 전수 대조표','',f"45개 Lua **18,795줄 전체**를 UTF-8로 읽고 기능 행 **{len(rows):,}개**를 색인했다. **같음 {counts['같음']:,} / 일부 {counts['일부']:,} / 없음 {counts['없음']:,} / 제외 {counts['제외']:,} / 미확인 {counts['미확인']:,}.** 미확인을 같음이나 없음으로 바꾸어 세지 않았다. 지시서의 18,794줄과 현재 실물은 1줄 차이이며 파일별 SHA-256/줄 수는 JSON에 고정했다.",'','- JSON: [verification/parity-r21/parity.json](verification/parity-r21/parity.json)','- 함수/라우트/표/필드와 개별 데이터 항목은 서로 겹칠 수 있다. 데이터 항목을 제외한 수: '+', '.join(f'{k} {v:,}' for k,v in report['summary']['non_record_counts'].items())+'. **행 비율은 게임 완성률/공수 비율이 아니다.**','- 기본 근거: 실제 원본 Lua 재적재 oracle, 직접 코드 줄 대조, 데이터 구조/값 대조. 기존 보고서 문장만으로 같음 처리한 행은 없다.','- 의미 대조가 끝나지 않은 내부 함수/콜백/숫자표는 미확인이다. 이 보고서는 전수 목록이며 모든 기능의 동등성 검증 완료 보고서는 아니다.','','## 남은 작업: 10개 묶음과 의존 순서','', '공용 대형 파일의 동시 수정을 피하도록 새 모듈로 나눈 제안이다. P2가 전투 공용 연결점을 맡고 P3/P4는 순서대로 붙인다. 각 묶음은 원본 하네스의 해당 계약을 Godot 대조 fixture로 옮겨 검사하며, 성적 장면·AI 요청을 실행하지 않는다.','', '|묶음|의존|소유 파일/범위|완료 조건|원본 하네스|','|---|---|---|---|---|']
 for b in BUNDLES:parts.append('|'+ '|'.join(safe(x) for x in [b[0]+' '+b[1],b[2],b[3]+'; 원본 '+b[4],b[5],b[6]])+'|')
 parts+=['','## 파일별 완성도와 읽은 범위','', '같음/대상은 제외를 뺀 행 수를 분모로 삼는다. 긴 생성 파일의 데이터 항목 수가 많으므로 별도 함수·화면 검증을 대신하지 않는다. 읽은 범위는 UTF-8 전체 텍스트/토큰 읽기이며, 의미를 직접 대조한 근거는 각 행에만 적용한다. 400줄 넘는 파일도 빠진 읽기 구간이 없다.','', '|원본 파일|총줄 / 읽은 구간|같음|일부|없음|제외|미확인|같음/대상(행 기준)|','|---|---|---:|---:|---:|---:|---:|---|']
 for f in files:
  c=f['counts'];parts.append('|'+ '|'.join(safe(x) for x in [f['file'],str(f['total_lines'])+' / '+', '.join(f'{a}–{b}' for a,b in f['read_ranges']),*[c[s] for s in STATUS],f"{c['같음']}/{f['rows']-c['제외']}"+(' (전부 제외)' if f['confirmed_same_row_percentage'] is None else f" ({f['confirmed_same_row_percentage']}%)")])+'|')
 parts+=['','## 직접 확인한 차이','']
 for f in FINDINGS:parts += [f"**{f['id']} · {f['title']} — {f['bundle']}**",'',f['detail'], '',f"근거: `{f['source']}` ↔ `{f['game']}`.",'']
 parts+=['## 실행 검사와 대조 범위','',f"격리 사본의 공통·추가 검사 **{len(checks)}종 / 실패 그룹 {report['summary']['common_and_added_failed_groups']}**, 현재 원본 oracle 재생성 5개 및 재대조 검사 5개 **실패 {report['summary']['fresh_failed_commands']}**. 게임 코드/데이터/자산·docs/·원본 폴더는 수정하지 않았다. 허용 경로 밖 파일 **{write['files_checked']:,}개 / 변경 {len(write['changed_outside_allowed'])}**.",'','|검사|직접 실행 결과|','|---|---|']
 for c in checks:
  summary='; '.join(x for x in c['summary'] if 'floors tested' not in x)
  if not summary:
   raw=(OUT/(c['name']+'.log')).read_text(encoding='utf-8');summary='; '.join(l for l in raw.splitlines() if re.search(r'check|fail|integration|R20|WORLD|ROUTE',l,re.I) and not l.startswith('ERROR:')) or 'exit 0'
  parts.append('|'+safe(c['name'])+'|'+safe(summary)+f"; exit {c['exit_code']}; script/test errors {len(c['errors'])}"+'|')
 parts+=['','새로 원본을 실행해 재생성한 표본: 조합1,028·적 능력치700·탐색300·적100종 행동1,221(연속도1,221)·침묵200·장비120·추가 DOT6/회피120·거점2,544·상거래8,520(진열480/가공1,200/제련660/옵션6,180). **중립 아군 fixture와 지정한 입력의 시험이며 모든 개인 기술/장비/전체 난수열을 증명하지 않는다.**','',f"선언 데이터 비교 **{len(dc['checks']):,}개 중 {dc['passed']:,} 같음 / {dc['not_equal']} 차이**. 차이36개는 계통아이콘 키30, 표시명3, 미코 표시/variant2개, 이를 포함하는 동료표 집계1개다. 비교기의 JSON키/배열/누락 처리와 원본 build.py의 순수 schema 변환만 적용했으며 빌드/내보내기는 실행하지 않았다. 차이 항목은 미완료로 남겼다.",'','원본 `harness_*.mjs` 이름은 각 행에 연결했다. 심볼을 직접 참조하지 않는 하네스는 “모듈 관련·내부 함수 단언 미확인”으로 JSON에 표시했다. 하네스가 없거나 찾지 못한 경우 `없음`으로 적었다. 원본 하네스 전체를 실행한 것은 아니며, 기존 `lua_sim.mjs`를 이용한 현재 소스 재적재 oracle 5개를 실행했다. 성적 장면/AI 생성/외부 저장 요청은 실행하지 않았다.','','이미지 직접 열람: 격리 실행의 `ui-r20/base-360.png`, `supplies-360.png`, `log-360.png` 3장. 기본 전투/보급품/기록의 배치·HP/MP·대상/버튼을 확인했다. 시안 전패널이나 모든 출력 이미지 검수로 확대하지 않는다. Godot의 root certificate store 진단은 로그에 보존하고 단언/스크립트 오류와 분리했다.','','근거 파일: [원본 색인](verification/parity-r21/source-index.json), [게임 색인](verification/parity-r21/game-index.json), [설계·하네스 색인](verification/parity-r21/auxiliary-index.json), [전체 검사](verification/parity-r21/checks.json), [원본 재실행](verification/parity-r21/fresh-checks.json), [데이터 대조](verification/parity-r21/data-comparison.json), [부재 검색](verification/parity-r21/search-evidence.json), [쓰기 감사](verification/parity-r21/write-audit.json).','','## 범위·제외·제한','', '- `79-sex.lua`·친밀/성적 장면·매혹의 비약·성인 모듈은 사용자 결정으로 제외. 목록 행만 남겼다.','- RisuAI API·로어 주입·AI 요청/응답·대화 삽화 선택·장 요약/프롬프트 정리는 호스트/AI 전용이어서 제외.','- 기본 초상·표정 선택·일반 설정·클라우드 저장·순위·확정 사건 연대기·비성적 장소는 계속 대조 대상으로 유지했다.','- 함수/테이블/필드의 선언 구간과 코드 잔여 구간을 색인했고, 긴 내장 JSON은 데이터 포인터와 해시로 추적한다. 성인 자산 파일은 열지 않았다.','- 미확인 행은 개별 함수/콜백의 입력·경계·부가 훅·저장 결과를 확정하지 못한 항목이다. “대응 후보” 위치는 구현 동등성의 근거가 아니다.','- 시작 시 공통 규칙을 읽기 전 묶음에 git status가 들어가 소유권 오류로 실패했다. 이후 git 명령/설정 변경은 하지 않았다. 초기 fixture 누락으로 격리 검사를 한 번 중단한 뒤 22종 전체를 재실행했다. 기대값 변경 없음.','','## 기능별 전수 행','', '각 절은 현재 실물의 파일명·전체 줄 수·읽은 범위를 표시한다. 근거에 “후보”가 있는 행은 미확인이다. `같음`은 적힌 시험/코드/데이터 범위에만 적용한다.','']
 for f in files:
  parts += [f"### {f['file']} — {f['purpose']}",'',f"총 {f['total_lines']}줄 · 읽음 "+', '.join(f'{a}–{b}' for a,b in f['read_ranges'])+f" · SHA-256 `{f['sha256']}`.",'', '|ID|원본 파일:줄 범위|기능|게임 구현 위치|상태|근거|원본 하네스|','|---|---|---|---|---|---|---|']
  for r in rows:
   if r['source']['file']!='bot/src/'+f['file']:continue
   ev=r['evidence'];evidence=((', '.join(ev.get('tests',[]))+'; ') if ev.get('tests') else '')+(('data-comparison#'+ev['comparison_id']+'; ') if ev.get('comparison_id') else '')+ev['reason']
   where=locstr(r['implementation'])+(' (후보)' if r.get('implementation_is_candidate') else '')
   hs=', '.join(h['file']+((':'+str(h['line'])) if 'line' in h else ' (관련)') for h in r['original_harnesses']) or '없음'
   parts.append('|'+ '|'.join(safe(x) for x in [r['id'],sourceref(f['file'],r['source']['start'],r['source']['end']),r['description'],where,r['status'],evidence,hs])+'|')
  parts.append('')
 parts=[p.replace('지시서의 18,794줄과 현재 실물은 1줄 차이이며 파일별 SHA-256/줄 수는 JSON에 고정했다.','개행(LF)은 지시서와 같은 18,794개다. `05-gen.lua`의 마지막 줄에 개행이 없어 마지막 줄까지 센 논리 행은 18,795개이며 원본에 추가 행이 생긴 것이 아니다. 파일별 SHA-256/줄 수를 JSON에 고정했다.') for p in parts]
 if validation and validation['rows']==len(rows):
  insert=parts.index('## 실행 검사와 대조 범위')+2
  parts[insert:insert]=[f"문서/JSON 전수 구조 검사 **{validation['checks']:,}개 / 실패 {validation['failures']}**. 함수·라우트·상태 별칭 필드·전투 기본 필드의 색인 누락, 모든 실행 코드 줄의 범위 포함, 원본/게임 줄 번호, 집계·동일 판정 근거, 쓰기 범위를 검사했다. [validation.json](verification/parity-r21/validation.json).",'']
 (ROOT/'PARITY-R21.md').write_text('\n'.join(parts)+'\n',encoding='utf-8')
 with (OUT/'parity.csv').open('w',encoding='utf-8-sig',newline='') as stream:
  writer=csv.writer(stream);writer.writerow(['ID','원본 파일','시작줄','끝줄','기능','게임 위치','상태','근거','원본 하네스'])
  for r in rows:writer.writerow([r['id'],r['source']['file'],r['source']['start'],r['source']['end'],r['description'],locstr(r['implementation']),r['status'],r['evidence']['reason'],','.join(h['file'] for h in r['original_harnesses'])])
 print(json.dumps(report['summary'],ensure_ascii=False))
if __name__=='__main__':main()
