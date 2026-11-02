"""Human-reviewed decisions. Unlisted functions remain explicitly unverified."""
PURPOSES={
'00-host.lua':'RisuAI 호스트 API 대체', '01-game.lua':'영구 상태·언어·HUD·라우터·대화 잠금', '05-gen.lua':'자동 생성 정본 수치·인물·적·장비·시나리오·번역 표',
'10-data.lua':'직업 기술·공격·방어·개인 기술 기본 표', '15-josa.lua':'한글 받침·조사', '20-state.lua':'전투 상태·아군/적 바인딩·난수·저장', '24-stats.lua':'레벨 성장·적/층 능력치', '26-start.lua':'편성에서 균열 전투 생성', '27-compose.lua':'층·적 조합 제약·결정론 조합',
'29-persona-skill.lua':'페르소나 고유 기술 연구·강화·실행', '30-engine.lua':'CTB·피해·심연·기술·종결·4인 개인 기술', '31-foes.lua':'적 행동·상태·보스·소환·DOT', '32-personal-a.lua':'할드리크~힐데가 개인 기술·특성', '32-personal-b.lua':'베렌가~아델린 개인 기술·특성', '34-traits.lua':'종족·출신·직업 패시브·시너지',
'40-fx.lua':'전투 사건별 연출', '50-render.lua':'전투 HUD·대상·행동·로그·게이지', '51-raid.lua':'레이드 보스·충전·단계 표시', '60-create.lua':'페르소나 생성·능력치 배분·첫 만남', '65-codex.lua':'도감·동료 상세·필터·장비·즐겨찾기', '66-status.lua':'페르소나/참전 상태·가방·비교·판매', '67-settings.lua':'설정·언어·난이도·저장·초기화', '68-cloud.lua':'클라우드 서명·링크·계정/PIN·이관', '69-rank.lua':'도달 층 순위·캐시·갱신',
'70-town.lua':'마을 이동·의뢰 정산', '71-shop.lua':'상점·소모품·일일 장비 진열·스크롤', '72-guild.lua':'의뢰 생성·수락/포기·갱신·동료 소개', '73-inn.lua':'여관 대화·식사·선물·숙박', '74-affection.lua':'호감 곡선·단계·동행 보너스', '74-level.lua':'경험치·개별 레벨·영입·미출전 페르소나', '75-sortie.lua':'균열/던전 출정·가변 편성·페르소나 출전', '76-dungeon.lua':'던전 층 해금·추천·보상·목록', '77-explore.lua':'한 층 탐색·휴식·보스·수확·정산', '78-battle-item.lua':'전투 보급품·원정 주머니·사용 행동', '79-sex.lua':'성적 장면·제안·친밀 이벤트·그림·NPC 연계(이관 제외)', '80-press.lua':'전투 버튼·대상 선택·결과 전달', '81-gear.lua':'장비 1,030종·코드·옵션·가방·강화·전투 훅·드롭·가공', '82-smithy.lua':'대장간 제련·가공 화면과 작업 마감', '85-portrait.lua':'초상 검증·표정 선택·기본 대체·표시', '86-portrait-have.lua':'기본/표정 초상 보유 목록', '87-portrait-modules.lua':'성인 에셋 모듈 보유 목록(이관 제외)', '88-lore.lua':'마을 장소·NPC 배치·로어 선택/주입', '89-art.lua':'AI 응답 삽화·표정·모델/엔진 선택', '89-memory.lua':'확정 사건 연대기·장 요약·프롬프트 정리', '90-triggers.lua':'호스트 버튼/폼·화면·요청·응답 훅'}

# (candidate file, function, module limitation). Candidate != equivalence.
CANDIDATES={
'01-game.lua':('project/game/world_state.gd','_init','저장 틀은 있으나 페르소나/설정/초기 상태·난수가 다름'),
'05-gen.lua':('project/data/world.json',None,'표별 직접 대조 결과를 사용'),
'10-data.lua':('project/game/expansion_world.gd','battle_data','직업 표를 읽지만 개별 기술 선언·대상·전체 수치 미대조'),
'15-josa.lua':('project/ui/world_screen.gd','_member','고정 한국어 UI는 있으나 동적 받침·조사 함수 없음'),
'20-state.lua':('project/game/battle_v3.gd','_init','ID/상태 저장 대응은 있으나 시드·아군 초기 차례·가변 파티 계약이 다름'),
'24-stats.lua':('project/game/dungeon_rules_r21.gd','foe_stats','적/층 수치는 원본 대조, 아군/페르소나 능력치 전체는 별도'),
'26-start.lua':('project/game/dungeon_world_r21.gd','depart_rift_quest','페르소나와 1~4인 편성이 빠짐'),
'27-compose.lua':('project/game/dungeon_rules_r21.gd','compose','순수 조합 함수의 표본 대조와 런타임 출정 UI는 구분'),
'29-persona-skill.lua':('project/game/expansion_world.gd','compose','원본 페르소나 기술을 동료별 전술로 바꾸어 방어를 대체; 원본 계약과 다름'),
'30-engine.lua':('project/game/battle_v3.gd','act','CTB ceil/라운드 MP·아군 RNG/강제치명 RNG 소비가 달라 전체 동등성 없음'),
'31-foes.lua':('project/game/dungeon_enemy_r21.gd','turn','적 전용 시험 범위 밖의 훅 조합·아군 반격 전체는 미확인'),
'32-personal-a.lua':('project/game/battle_v3.gd','_personal','개인 기술 분기는 있으나 원본 함수·특성 훅별 동등성은 미확인'),
'32-personal-b.lua':('project/game/battle_v3.gd','_personal','개인 기술 분기는 있으나 미코 variant 2가 1로 바뀌는 등 차이가 있음'),
'34-traits.lua':('project/game/battle_v3.gd','_damage','일부 전투 특성이 있으나 전투 밖 출신 시너지 누락'),
'40-fx.lua':('project/ui/combat_presentation.gd',None,'Godot 연출 대응이 있지만 원본 사건별 시간·모든 연출은 미대조'),
'50-render.lua':('project/ui/battle_screen.gd',None,'Godot 전투 UI는 존재; HTML의 모든 표시·선택 계약은 개별 미대조'),
'51-raid.lua':('project/ui/battle_screen.gd',None,'적 예고·단계는 존재; 레이드 전용 표시의 전체 동등성 미확인'),
'65-codex.lua':('project/ui/town_screen_r21.gd','overview','동료 상세·장비는 존재; 미영입 도감·즐겨찾기·전체 필터 미완'),
'66-status.lua':('project/ui/town_screen_r21.gd','equipment','동료/가방은 존재; 페르소나 상태·즐겨찾기·판매/정렬 일부 차이'),
'67-settings.lua':('project/ui/world_screen.gd','_draw_screen','마을 화면 등록에 settings/save 메뉴 없음; 전투 연출 설정과 구분'),
'68-cloud.lua':('project/game/world_store.gd','write','로컬 파일/백업 저장만 있음; 클라우드 전송 대응 없음'),
'69-rank.lua':('project/game/dungeon_world_r21.gd','dungeon_max','최고층 로컬 진도만 있음; 외부 백분위 순위 대응 없음'),
'70-town.lua':('project/game/town_world_r21.gd','settle','시설 이동·정산 일부 대응; 페르소나·연대기 등 원본 부가 처리 차이'),
'71-shop.lua':('project/game/town_world_r21.gd','shop_stock','진열/옵션 순수 함수는 대조됨; 직업 선택·문구·보유 상한·부가 처리 차이'),
'72-guild.lua':('project/game/town_world_r21.gd','fill_source_board','의뢰 일부 대조됨; 영입은 페르소나 대신 파티 최고 레벨/웹 RNG'),
'73-inn.lua':('project/game/town_world_r21.gd','inn','요금/하루/호감 시험은 일치; AI 대사·친밀 장면은 제외'),
'74-affection.lua':('project/game/town_rules_r21.gd','aff_next','순수 호감 곡선만 일치; 동행 시너지·단계·연대기 별도'),
'74-level.lua':('project/game/town_world_r21.gd','need','경험치 곡선만 일치; 페르소나 미출전 50%/영입 레벨 계약 없음'),
'75-sortie.lua':('project/ui/town_screen_r21.gd','formation','고정 4인 동료 편성; 페르소나 출전 전환·1~3인 출정 없음'),
'76-dungeon.lua':('project/game/dungeon_world_r21.gd','dungeon_max','층 진도·해금 대응; 원본 페이지/추천/편성 UI는 별도'),
'77-explore.lua':('project/game/dungeon_world_r21.gd','advance','기본 탐색/휴식/보스는 존재; 발견·휴식·패배 출신 시너지와 다음 층 연속 진행 차이'),
'78-battle-item.lua':('project/game/battle_v3.gd','_use_supply','보급품 대응은 존재; 주머니 합산·종족/출신 배율·모든 상태 제한 미대조'),
'80-press.lua':('project/game/battle_v3.gd','act','Godot 입력/선택 대응은 존재; 봇 reset/cancel/상태 재생 전체 미대조'),
'81-gear.lua':('project/game/commerce_rules_r21.gd','roll','새 상점/가공 장비만 source_r21 옵션; 기존 저장/던전 드롭은 옛 옵션 유지'),
'82-smithy.lua':('project/ui/town_screen_r21.gd','smithy','제련/가공 UI는 존재; 원본 작업 마감·영수증·호감 훅 차이'),
'85-portrait.lua':('project/ui/town_portrait_r21.gd',None,'기본 초상·슬롯은 있으나 원본 20표정/variant 대체와 모듈 조건은 다름'),
'86-portrait-have.lua':('project/data/portrait-slots-r21.json',None,'300칸은 화면별 크롭; 원본 표정 목록 20종과 같은 개념이 아님'),
'88-lore.lua':('project/ui/town_screen_r21.gd','home','주요 시설만 대응; 기록관/검문소/골목/등불 쉼터 장소가 빠짐'),
'89-art.lua':('project/ui/town_portrait_r21.gd',None,'고정 UI 초상 표시와 AI 답변 삽화 선택은 별개'),
'89-memory.lua':('project/game/world_state.gd','note','최근 30줄 UI 로그만 존재; 확정 사건 연대기의 중복 제거/분류/보존 규칙과 다름'),
'90-triggers.lua':('project/ui/world_screen.gd','_ready','Godot 진입/저장은 있으나 Risu 훅 자체는 이관 대상 아님')}

# Each key must match a source declaration or its source line interval.
DECISIONS={}
def mark(file,names,status,path,func,reason,test=None):
 for name in names.split('|'):DECISIONS[(file,name)]=(status,path,func,reason,test)
def same(file,names,path,func,reason,test):mark(file,names,'같음',path,func,reason,test)
def partial(file,names,path,func,reason):mark(file,names,'일부',path,func,reason)
def absent(file,names,reason):mark(file,names,'없음',None,None,reason)
def exclude(file,names,reason):mark(file,names,'제외',None,None,reason)

same('74-affection.lua','B.aff_next','project/game/town_rules_r21.gd','aff_next','최소/최대·100 경계·0.4·소수 반올림 원본 함수 표본 대조','town_r21_test')
same('74-level.lua','B.exp_need|clamp_lv','project/game/town_rules_r21.gd','need','Lv1~40 clamp와 완화 경험치 곡선 46표본','town_r21_test')
same('72-guild.lua','B.gd_recruit_cost','project/game/town_rules_r21.gd','recruit_cost','100+20×영입수, 31회차 원본 비용 대조','town_r21_test')
same('72-guild.lua','B.gd_refresh_cost','project/game/town_rules_r21.gd','refresh_cost','10×2^min(rr,4), 31회차 원본 비용 대조','town_r21_test')
same('71-shop.lua','B.shop_price','project/game/town_rules_r21.gd','shop_price','마렌토 할인·최소1·반올림 75표본; 함수 결과 범위','town_r21_test')
same('71-shop.lua','B.shop_stock','project/game/commerce_rules_r21.gd','stock_source','10직업×3부위×4일×4씨앗 480표본; 진열 순수 함수만','town_commerce_r21_test')
same('72-guild.lua','B.gd_new|B.gd_rnd','project/game/guild_rules_r21.gd','quest','원본 계정 seed/counter 의뢰 생성 96표본·RNG96표본; 입력 레벨은 같게 고정','town_r21_test')
same('72-guild.lua','B.gd_gear','project/game/guild_rules_r21.gd','elite_gear','의뢰 q번호·씨앗·직업·보장 코드 표본 대조; 지급 장비 옵션은 별도','town_r21_test')
for name,fn in [('B.lv_reward','level_reward'),('B.gd_gold','quest_gold'),('B.gd_fight','quest_fight')]:same('72-guild.lua',name,'project/game/dungeon_rules_r21.gd',fn,'원본 레벨×난이도×의뢰 종류 480표본','data_r21_test')
for name,fn in [('B.fc','fc'),('curve_hp','curve_hp'),('B.floor_final','floor_final'),('floor_raw','floor_final'),('B.foe_stats','foe_stats'),('B.star_mult','star_mult'),('B.zone_tune','foe_stats')]:same('24-stats.lua',name,'project/game/dungeon_rules_r21.gd',fn,'조합 1,028개 및 적100×7층=700개 실제 원본 능력치 대조; 시험 입력 범위','data_r21_test')
for name,fn in [('B.floor_info','floor_info'),('B.floor_star','floor_star'),('B.floor_boss_kind','boss_kind'),('B.floor_level','floor_level'),('B.floor_mult','floor_mult'),('B.compose','compose'),('B.check_comp','check_comp'),('B.threat_limit','threat_limit'),('B.floor_plan','compose'),('B.floor_enc','compose')]:same('27-compose.lua',name,'project/game/dungeon_rules_r21.gd',fn,'층/균열·인원별 1,028개 원본 조합·레벨 출력 대조; 표본 범위','data_r21_test')
same('77-explore.lua','mix|B.ex_roll','project/game/dungeon_rules_r21.gd','ex_roll','1~60층×5탐색=300표본·mix/전투씨앗 대조; 실제 수확에 출신 시너지 적용은 별도','data_r21_test')
same('76-dungeon.lua','B.dn_gold','project/game/dungeon_rules_r21.gd','gold','원본 층별 기본 금화 함수 대조; 최종 출신 시너지 정산은 별도','data_r21_test')
same('01-game.lua','B.G_rnd','project/game/guild_rules_r21.gd','random','splitmix64 계정 RNG96표본; 길드 전용 이식이며 영입은 다른 RNG를 사용','town_r21_test')
same('81-gear.lua','B.forge_cost|B.forge_try','project/game/commerce_rules_r21.gd','forge_result','660표본 제련 성공/비용 대조; 원본 bag 호스트는 fixture로 대체','town_commerce_r21_test')
same('81-gear.lua','to36','project/game/dungeon_rules_r21.gd','base36','상점480·가공1200·옵션6180의 장비 코드 표본에서 검증','town_commerce_r21_test')
partial('81-gear.lua','B.gear_roll|settle|B.gear_code|B.gear_parse|B.gear_price|B.process_roll|B.process_lv|B.process_band|process_classes','project/game/commerce_rules_r21.gd','roll','새 장비 경로 8,520표본은 일치하나 source_r21 미표시 구장비/던전 드롭 경로·페르소나 직업 풀 차이')
partial('81-gear.lua','B.gear_can_equip|B.gear_restrict|B.gear_equip|B.gear_unequip|B.gear_sell|B.gear_sell_common|B.bag_add|B.bag_take|B.bag_load|B.bag_save|B.gear_migrate','project/game/expansion_world.gd','equip','장비/가방/클래스/레벨 제약은 대응; 페르소나·개별 코드/UID 저장·일괄판매와 구장비 옵션 계약 차이')
partial('01-game.lua','B.G_new|B.G_migrate|B.G_load|B.G_save','project/game/world_state.gd','_init','원본 create/300금화/페르소나/빈 roster와 달리 게임은 고정4인/200금화; 로컬 저장 이관은 존재')
absent('01-game.lua','B.ui_pack|B.U|B.en_dict|B.T|B.LANGS|B.LANG|B.UI','영문 UI 사전/언어 설정·동적 문구 조립 대응 없음; game/ui 전체 language/locale/TranslationServer 검색 0건')
exclude('01-game.lua','B.lang_note|B.ai|B.pend_busy|B.locked|B.pend_hard|B.lock_note|pimg_ok|B.pimg_fetch|B.pimg_kick|B.context|B.CTX["00-place"]|B.CTX["90-nsfw"]|B.refresh','RisuAI 요청 문맥·응답 대기·호스트 페르소나 인레이/화면 갱신용; Godot 설정·초상 자체는 별도 추적')
partial('01-game.lua','B.hud|B.H.hd|B.view|B.route|B.btn|B.esc|B.pimg','project/ui/world_screen.gd','_draw_screen','화면/버튼/텍스처 대응 존재; 설정·저장 메뉴·페르소나 초상/도감 동선 일부 누락')
for f in ['15-josa.lua']:
 absent(f,'B.JONG_ASCII|B.jong|B.josa|B.p','정본 한글/ASCII/구두점/토큰 조사 처리를 제공하는 대응 함수가 game/ui에 없음(정적 텍스트는 별개)')
partial('20-state.lua','B.rbegin|B.rnd|B.fresh|B.blank_u|B.member_def|B.member_skills|B.bind|B.apply_carry|B.migrate|B.load|B.save|B.again|B.redo','project/game/battle_v3.gd','_init','전투 저장/상태 대응은 있으나 원본 아군 행동마다 16807 재시드 대신 웹 48271 연속 RNG·고정4인·페르소나 누락')
partial('26-start.lua','B.battle_pm|B.quest_compose|B.battle_start|B.foes_for','project/game/dungeon_world_r21.gd','depart_rift_quest','균열 출정/적 조합 대응; 원본 페르소나 포함 1~4인·개별 능력치/기술/미출전 경험치 누락')
partial('24-stats.lua','B.party_stats|B.K_of|B.cls_of','project/game/expansion_world.gd','stats','기본 곡선/직업은 대응; 실제 파티/페르소나 보너스/장비 경로가 달라 전체 함수 동등성 미충족')
partial('29-persona-skill.lua','B.ps_compatible|B.ps_cost|B.ps_clean|B.ps_parts|B.ps_ready|B.ps_skill|B.PRUN.persona|B.ps_guild_tab|B.ps_guild_action|save|work|changes','project/game/expansion_world.gd','compose','동료별 방어 대체 전술로 구현됨; 원본 persona.skill의 별도 고유 기술 슬롯·확정/취소 흐름과 다름')
for n in ['B.advance','B.preview','B.round_tick','B.begin_turn','B.end_turn','B.hit','B.strike','B.player','B.run','B.attack','B.volley','B.heal','B.party_shield','B.dot_tick','B.dot_push','B.finish','B.exp_reward','B.can_use','B.mpc','B.mpb']:
 partial('30-engine.lua',n,'project/game/battle_v3.gd','act','원본 20-state:3-9/30-engine:188-245,284-326과 game battle_state:71-129/battle_v3:199-346 직접 대조: CTB·라운드·아군 RNG/강제치명 RNG 소비 차이; 대응 기능 일부만')
for name,fn in [('B.e_buff','turn'),('B.e_debuff','turn'),('B.e_dot','turn'),('B.e_heal','turn'),('B.e_summon','turn'),('B.e_protect','turn'),('B.e_special','turn'),('B.e_act','turn'),('B.foe_turn_start','turn'),('B.foe_turn_end','turn'),('B.edot_add','add_dot'),('B.e_cancel_charge','turn')]:
 same('31-foes.lua',name,'project/game/dungeon_enemy_r21.gd',fn,'100종 각≥12행동:1,221개 단독/연속 및 침묵200·장비120 원본 대조; 고정 중립 아군 fixture 범위','enemy_action_r21_test')
same('31-foes.lua','B.edot_tick','project/game/battle_v3.gd','_tick','DOT fixed strike 훅6·회피/RNG/다음대상120 원본 대조; fixture에 명시된 조합만','enemy_review_r21_test')
partial('34-traits.lua','B.tx_rest|B.tx_aff|B.tx_find|B.tx_defeat','project/game/dungeon_world_r21.gd','settle','원본 추가 휴식 HP/MP·발견 금화/물건/약초·솔렌 호감×1.2·케른 금화손실/수확보전이 적용되지 않음; 기본값만 구현')
same('34-traits.lua','B.tx_shop','project/game/town_world_r21.gd','price','동일 편성의 마렌토2/3인 할인 75가격 표본; 페르소나 편성은 제외','town_r21_test')
same('34-traits.lua','B.reward_gold','project/game/guild_rules_r21.gd','reward_gold','마렌토 구성0~4×보상6=30표본 원본 정산 대조','town_r21_test')
partial('74-affection.lua','B.aff_add|B.aff_party','project/game/dungeon_world_r21.gd','settle','호감 기본 곡선/보상은 존재; 솔렌3인×1.2 및 단계변화 연대기 누락')
absent('74-affection.lua','B.aff_stage','적대/불신/낯섦/신뢰/유대/깊은 인연/맹세/운명의 8단계 경계/표시 대응 없음')
partial('74-level.lua','B.award_exp|B.exp_give|give|B.exp_settle|B.lv_of|B.exp_of|B.join_level','project/game/dungeon_world_r21.gd','settle','동료 경험치/레벨 처리는 존재; 미출전 persona50%·영입 페르소나레벨·넘친 경험치 이관 차이')
partial('72-guild.lua','meet|B.gd_base_lv|B.gd_candidates|B.H.gd|B.gd_fill|B.gd_recruit_tab','project/game/expansion_world.gd','recruit','비용100+20n은 같으나 원본 G_rnd/페르소나레벨 대신 48271 RNG/파티최고레벨·초기 보유4명')
partial('71-shop.lua','B.SCREENS.shop|B.H.sh|B.ITEMS|B.POTION|B.ITEM_ORDER','project/game/town_world_r21.gd','buy','소모품/스크롤 구매 대응; 이름·원본 무제한 보유 대비 웹10000 상한·원본10직업 진열 선택 차이')
exclude('71-shop.lua','B.CHARM|B.ITEMS.charm_potion','매혹의 비약은 제외된 친밀 장면에만 연결되는 소모품')
partial('73-inn.lua','B["H"]["in"]|B.SCREENS.inn|B.INN_ACTS|B.INN_ORDER','project/game/town_world_r21.gd','inn','무료/25/30/20,호감+1,일일제한/숙박 다음날은 대조됨; 원본 숙박 T.rr=0 초기화가 게임에 없음')
exclude('73-inn.lua','act_texts|nsfw_on','AI 대화 지시·NSFW 대화 지문은 제외; 일반 여관 요금/호감은 유지')
partial('75-sortie.lua','SO.cap|SO.clean|SO.members|SO.summary|B.SCREENS.sortie|B.H.so','project/ui/town_screen_r21.gd','formation','동료4명 고정·순서 변경은 존재; 페르소나 직접참전 토글/3동료·1~3명 출정·원본 필터 부족')
partial('76-dungeon.lua','B.dn_G|B.dn_max|B.dn_allowed|B.dn_party|B.dn_floor_view|B.dn_rec_lv|B.dn_rec_floor|B.dn_card','project/game/dungeon_world_r21.gd','dungeon_max','층해금/진도와 기본 목록은 존재; 원본 추천층·6개페이지·가변 편성·순위 동선 차이')
partial('77-explore.lua','B.ex_new|B.dn_start|do_explore|enter_rest|finish_run|B.dn_settle|B.dn_settle_legacy|do_retreat|B.H.ex|do_equip|do_use|B.SCREENS.dungeon','project/game/dungeon_world_r21.gd','advance','5탐색/자동휴식/보스/귀환 대응; 출신 시너지·연속다음층·휴식중장비/소모품·정산 내역·난수 원천 차이')
exclude('77-explore.lua','B.ex_pend|B.dn_enter_note|B.CTX["21-dungeon"]','AI에 입장/발견/정산 서사를 요청하는 문맥; 던전 상태/결과는 별도 추적')
partial('78-battle-item.lua','B.it_amount|B.it_apply|B.it_state_ok|B.it_ok|B.it_any|B.it_blocked|B.H.it|B.ex_pouch|B.ex_have|B.ex_take|B.ex_bag','project/game/battle_v3.gd','_use_supply','물약/해독/부활·MP/턴 사용은 대응; 원정 주머니·마렌토 물약 배율·전체 상태 제한·구저장 소모품 분리 미대조')
partial('82-smithy.lua','B.H.sm|B.SCREENS.smithy|tab_forge|tab_process|work_of|work_note','project/ui/town_screen_r21.gd','smithy','제련/가공 버튼과 결정론은 대응; 원본 완료 후 나가기 잠금·한나 일반호감/AI 영수증 부가 처리 분리 필요')
partial('85-portrait.lua','B.portrait_has|B.portrait_name|B.portrait_pick|B.portrait','project/ui/town_portrait_r21.gd',None,'기본 얼굴/크롭 표시는 대응; 원본 표정20종 variant 선택·기본 대체·Risu 모듈 조건은 동일하지 않음')
partial('88-lore.lua','B.PLACE|B.PLACE_ORDER|B.NPC_AT|B.place_movable|B.place_id|B.place_label|B.place_set','project/ui/town_screen_r21.gd','home','마을/길드/상점/여관/대장간 대응; 비성적 기록관/검문소/통역골목/등불쉼터 이동·NPC 배치 누락')
partial('89-memory.lua','B.chron_add|B.chron_flush|B.chron_aff|B.chron_gear|B.CHRON_KEY','project/game/world_state.gd','note','최근30줄 로그만 존재; 원본 사건별 영구 연대기·일자·단계변화·중복제거·전설장비 기록 계약 부족')

# Narrow earlier declarations to their actually exercised scope.
same('27-compose.lua','B.floor_boss_kind','project/game/dungeon_rules_r21.gd','floor_boss_kind','순서3 이상 boss, 나머지 chief; 원본:31 ↔ 게임:51 직접 코드 대조','data_r21_test')
same('72-guild.lua','B.gd_rnd','project/game/guild_rules_r21.gd','random','원본 B.G_rnd 호출과 game splitmix64 계정 RNG96표본','town_r21_test')
partial('81-gear.lua','B.forge_try','project/game/town_world_r21.gd','forge','성공/비용/시도수 표본은 같음; 원본 코드/장착 가방의 소유권 경계 전체를 same으로 확대하지 않음')
partial('73-inn.lua','B["H"]["in"]|B.SCREENS.inn|B.INN_ACTS|B.INN_ORDER','project/game/town_world_r21.gd','inn','무료/25/30/20,호감+1,일일제한/숙박 다음날은 원본 시험 일치; 원본 AI 대화와 NPC 연계/화면 문구는 별도')
absent('34-traits.lua','B.tx_rest|B.tx_aff|B.tx_find|B.tx_defeat','원본 출신 추가 휴식/호감/발견/패배 보전 modifier 대응 없음. game dungeon_world_r21:84-99,193-208은 기본값만 계산')
same('81-gear.lua','B.forge_cost','project/game/gear_rules.gd','forge_cost','원본 rarity별 base×next_level² ↔ 게임 entry.forge+1 제곱, 660표본 비용 대조','town_commerce_r21_test')
same('77-explore.lua','mix','project/game/dungeon_rules_r21.gd','mix','원본34-39 ↔ 게임312-318 unsigned shift/wrap/mix와 300표본 직접 대조','data_r21_test')
same('27-compose.lua','B.floor_enc','project/game/dungeon_rules_r21.gd','floor_enc','원본397-403 ↔ 게임293-296의 enc/dn/level/star/info를 직접 대조; 내부 조합/능력치는1,028표본','data_r21_test')
partial('27-compose.lua','B.floor_plan','project/game/dungeon_rules_r21.gd','floor_enc','원본 legacy stage=1/2 및 enc.dn.stage 저장 계약은 game kind 기반 floor_enc로 바뀌었음')
exclude('80-press.lua','B.nudge|B.send_result','RisuAI 채팅 메시지 다시 그리기/결과 문장 addChat 전달. 실제 전투 결과/정산 UI는 30/50/70/77에서 별도 추적')
absent('60-create.lua','B.C1_en','정적 이름/문구의 영어 사전 조회 보조. 게임에는 ko/en 사전 및 언어 전환 대응이 없음')
DECISIONS.pop(('31-foes.lua','B.e_cancel_charge'),None)
