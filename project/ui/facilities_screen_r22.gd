extends "res://ui/town_screen_r21.gd"
## P6 functional extension. D owns the inherited composition and artwork.
var selected_class=""

func picture(id: String,r: Rect2,slot="bust") -> Control:
	if id!="persona":return super(id,r,slot)
	var p=fill("persona_portrait",r,T.PALE)
	label(host.model.person(id).name,Rect2(r.position+Vector2(8,8),r.size-Vector2(16,16)),18,T.INK,T.BOLD)
	return p

func equipment_people() -> Array:
	var ids=host.model.s.owned.duplicate()
	if host.model.s.get("persona",{}).get("cls","")!="":ids.push_front("persona")
	return ids

func equipment() -> void:
	var ids=equipment_people()
	if ids.is_empty():header("편성 · 장비");return
	if host.who not in ids:host.who=ids[0]
	super()

func member_choice(r: Rect2) -> void:
	if host.screen!="equipment":super(r);return
	var ids=equipment_people();var pick=OptionButton.new();stage.add_child(pick);pick.position=r.position;pick.size=r.size
	pick.fit_to_longest_item=false;pick.clip_text=true
	for id in ids:pick.add_item(localized(host.model.person(id).name+" · "+host.model.person(id)["class"]))
	pick.select(ids.find(host.who));pick.item_selected.connect(func(i):host.who=ids[i];host._draw_screen())
	host.controls.member_choice=pick

func build_page() -> void:
	if not host.model.has_method("facility_route"):super();return
	if not host.model.receipt.is_empty():page_background();receipt_page();return
	if host.screen=="facility_scroll":page_background();scroll_page_targets();return
	super()
	if not host.model.facility_message.is_empty():
		fill("facility_notice",Rect2(14,62,362,82),T.INK)
		paragraph(host.model.facility_message,Rect2(22,67,346,72),12,T.PAPER)

func shop() -> void:
	super()
	if not host.model.has_method("scroll_targets") or host.shop_tab=="gear":return
	var old=host.controls.get("shop_bag")
	if is_instance_valid(old):old.get_parent().remove_child(old);old.queue_free()
	action("shop_scroll","스크롤 사용 · 보유 %d"%host.model.s.items.level_scroll,Rect2(18,705,190,43),host.go.bind("facility_scroll"),true,host.model.s.items.level_scroll<1)
	action("shop_bag","보유 장비",Rect2(220,705,152,43),host.go.bind("equipment"))

func inn() -> void:
	if not host.model.s.owned.is_empty():super();return
	header("아랫마을 여관");npc_hero("dorothea","여관","도로테아\n여관 주인",430)
	paragraph("함께할 동료가 아직 없다. 길드 본관의 동료 소개 창구에서 사람을 이어 받자.",Rect2(18,486,354,100),17)
	action("inn_recruit","동료 소개 창구",Rect2(18,705,354,44),host.go.bind("recruit"),true)

func shop_gear() -> void:
	if not host.model.has_method("shop_classes"):super();return
	var w=host.model;var classes=w.shop_classes()
	selected_class=host.get_meta("shop_class_r22",w.class_def("persona").get("id","warrior"))
	if selected_class not in classes:selected_class=classes[0]
	var pick=OptionButton.new();stage.add_child(pick);pick.position=Vector2(18,427);pick.size=Vector2(354,38);pick.fit_to_longest_item=false;pick.clip_text=true
	for cls in classes:
		var names=w.config.classes.filter(func(c):return c.id==cls)
		pick.add_item(names[0].name if names else cls)
	pick.select(classes.find(selected_class));pick.item_selected.connect(func(i):host.set_meta("shop_class_r22",classes[i]);host._draw_screen())
	host.controls.shop_class=pick
	for i in range(3):
		var slot=["weapon","armor","acc"][i]
		action("shop_slot:"+slot,w.Gear.SLOT[slot],Rect2(18+i*118,471,118,38),func():host.gear_filter=slot;host._draw_screen(),host.gear_filter==slot)
	var rows=w.shop_stock(selected_class,host.gear_filter)
	var previous=stage;stage=scroll_page(521,175,maxi(130,rows.size()*118))
	for i in range(rows.size()):
		var row=rows[i];var item=w.gear.by_id[row.id];var y=i*118
		icon("sword" if host.gear_filter=="weapon" else "shield",Rect2(8,y+12,56,65))
		label(item.name,Rect2(78,y+3,260,25),15,T.INK,T.BOLD)
		paragraph(host._gear_caption(item),Rect2(78,y+31,260,32),11)
		var cost=w.price({"price":row.price});var sold=w.stock_sold(row.code)
		action("buygear:"+row.id,"품절" if sold else "구입 · 금화 %d"%cost,Rect2(78,y+68,260,39),func():host._act(w.buy_gear.bind(row.code,selected_class),"장비를 구입했습니다."),true,sold or w.s.gold<cost)
		rule(y+115,0,342)
	stage=previous;action("shop_bag","보유 장비 확인",Rect2(18,705,354,43),host.go.bind("equipment"))

func guild() -> void:
	if not host.model.has_method("reject_quest"):super();return
	header("연합 길드 본관");npc_hero("fenella","의뢰","페넬라\n길드 접수",430);guild_tabs(0)
	var w=host.model;var board=w.s.board
	var previous=stage;stage=scroll_page(503,196,board.size()*228)
	for i in range(board.size()):
		var q=board[i];var c=w.quest_contract(q);var y=i*228;var accepted=w.s.quest.get("id",-1)==q.id
		label(("진행 중 · " if accepted else "")+c.difficulty+" · 적 Lv.%d"%c.lv,Rect2(0,y,342,22),12,T.RED,T.BOLD)
		display(q.name,Rect2(0,y+26,342,30),T.INK,23)
		label(q.rift+" · "+{"core":"균열 핵 레이드","elite":"정예 전투","battle":"일반 전투"}[w.GuildR22.fight(c)],Rect2(0,y+61,342,22),12)
		paragraph(c.get("d",""),Rect2(0,y+88,342,40),12)
		label("보상 금화 %d"%w.dungeon_rules.quest_gold(c,c.lv)+( " · 장비 1~2개 확정" if c.difficulty=="엘리트" else ""),Rect2(0,y+131,342,25),13,T.RED,T.BOLD)
		if accepted:
			action("quest_depart","출발",Rect2(0,y+170,166,42),func():host._act(w.depart_accepted_quest,"");host.go("explore"),true)
			action("quest_abandon","포기",Rect2(178,y+170,164,42),func():host._ask("현재 의뢰를 포기할까요?",w.abandon_quest))
		else:
			action("quest:"+str(int(q.id)),"수락",Rect2(0,y+170,166,42),func():host._act(w.accept_quest.bind(q.id),"의뢰를 수락했습니다."),true,not w.s.quest.is_empty()).tooltip_text=w.GuildR22.title_en(c) if w.s.get("settings",{}).get("lang","")=="en" else w.GuildR22.title(c)
			action("quest_reject:"+str(int(q.id)),"거절",Rect2(178,y+170,164,42),func():host._act(w.reject_quest.bind(q.id),"의뢰 하나를 거절했다. 판에 새 의뢰가 걸렸다."))
		rule(y+225,0,342)
	stage=previous
	action("refresh_board","의뢰판 새로 걸기 · 금화 %d"%w.refresh_fee(),Rect2(18,709,354,40),func():host._act(w.refresh_board,"의뢰판을 새로 걸었다."),true,w.s.gold<w.refresh_fee())

func smithy() -> void:
	if not host.model.has_method("smithy_list"):super();return
	var w=host.model
	header("한나의 대장간");npc_hero("hanna","한나의\n대장간","",365)
	for i in range(2):
		var tab=["forge","process"][i]
		action("sm_tab:"+tab,["제련","장비 가공"][i],Rect2(18+i*177,378,177,40),func():w.smithy_select(tab);host._draw_screen(),w.smithy_tab==tab)
	fill("smithy_body",Rect2(0,418,390,282),T.PAPER)
	var previous=stage
	if w.smithy_tab=="process":
		var band=w.gear.band(w.highest_level())
		label("기준 Lv.%d · 지금까지 %d회"%[w.highest_level(),w.s.commerce_r21.process_n],Rect2(18,431,354,25),15,T.INK,T.BOLD)
		label("등급별 확률",Rect2(18,472,354,26),18,T.INK,T.BOLD)
		for i in range(w.gear.ORDER.size()):
			var rarity=w.gear.ORDER[i]
			label(w.Gear.RARITY[rarity],Rect2(18,510+i*27,175,23),13)
			label(w.gear.pct(band.w.get(rarity,0))+"%",Rect2(220,510+i*27,152,23),13,T.RED,T.BOLD)
		paragraph("Lv.%d~%d 구간 · 확률은 바뀔 수 있습니다.\n같은 씨앗과 가공 회차에는 같은 장비가 나옵니다."%[band.from,band.to],Rect2(18,655,354,42),11)
		action("process_gear","장비 가공 · 금화 %d"%band.price,Rect2(18,706,354,42),func():host._act(w.process_gear.bind(host.who),""),true,w.s.gold<band.price)
	else:
		var rows=w.smithy_list();label("실패해도 장비는 그대로입니다.",Rect2(18,431,354,25),14)
		stage=scroll_page(469,216,maxi(90,rows.size()*130))
		if rows.is_empty():paragraph("제련할 장비가 없습니다.\n장비 가공 탭에서 장비를 만들 수 있습니다.",Rect2(0,12,342,70),15)
		for i in range(rows.size()):
			var e=rows[i];var item=w.gear.by_id[e.id];var y=i*130
			display(item.name+" +%d"%e.forge,Rect2(0,y,342,30),T.INK,22)
			if e.forge<10:
				label("성공 %d%% · 실패 시 단계 유지"%w.gear.rules.forge.success[int(e.forge)],Rect2(0,y+36,342,25),12)
				var cost=w.gear.forge_cost(e)
				action("forge:"+str(int(e.uid)),"제련 · 금화 %d"%cost,Rect2(0,y+72,342,42),func():host._ask(item.name+" 제련 시도?\n실패해도 비용은 소모됩니다.",w.forge.bind(e.uid)),true,w.s.gold<cost)
			else:label("이미 +10입니다.",Rect2(0,y+69,342,30),15)
			rule(y+127,0,342)
		stage=previous
		if not w.smithy_work.is_empty():action("smithy_done","제련 및 가공 완료",Rect2(18,706,354,42),func():w.complete_smithy();host._draw_screen(),true)
		else:action("smith_equipment","장비 장착하기",Rect2(18,706,354,42),host.go.bind("equipment"))
	if w.smithy_tab=="process" and not w.smithy_work.is_empty():
		action("smithy_done","제련 및 가공 완료",Rect2(18,314,354,43),func():w.complete_smithy();host._draw_screen(),true)
	if not w.smithy_fx.is_empty():
		var fx=w.smithy_fx;var text="가공 완료 · "+fx.name if fx.kind=="process" else "제련 성공!" if fx.success else "제련 실패. 장비는 그대로입니다."
		fill("smithy_result",Rect2(14,265,362,42),T.PAPER);label(text,Rect2(22,272,346,28),14,T.RED,T.BOLD)

func scroll_page_targets() -> void:
	header("레벨업 스크롤","shop")
	label("대상 한 명의 레벨 +1 · 최대 Lv.40",Rect2(18,82,354,29),17,T.INK,T.BOLD)
	label("보유 %d개"%host.model.s.items.level_scroll,Rect2(18,124,354,25),14,T.RED,T.BOLD)
	var w=host.model;var ids=w.scroll_targets();var previous=stage;stage=scroll_page(177,510,ids.size()*103)
	for i in range(ids.size()):
		var id=ids[i];var p=w.item_preview("level_scroll",id);var y=i*103
		label(w.person(id).name+(" · 페르소나" if id=="persona" else ""),Rect2(0,y,342,27),17,T.INK,T.BOLD)
		label("Lv.%d → %d · 경험치 초기화"%[p.before,p.after],Rect2(0,y+32,342,24),13)
		action("scroll_target:"+id,"사용" if p.usable else "사용 불가",Rect2(208,y+56,134,39),func():host._act(w.use_item.bind("level_scroll",id),"레벨이 올랐습니다."),true,not p.usable)
		rule(y+100,0,342)
	stage=previous;action("scroll_back","상회로",Rect2(18,712,354,44),host.go.bind("shop"));navigation()

func receipt_page() -> void:
	var w=host.model;var r=w.receipt;var shop_receipt=r.kind=="shop"
	fill("receipt_paper",Rect2(0,0,390,844),T.PAPER)
	display("거래 내역" if shop_receipt else "제련 및 가공 완료",Rect2(18,38,354,70),T.INK,32)
	label("피에트로 · 마렌토 상회" if shop_receipt else "한나 · 한나의 대장간",Rect2(18,121,354,30),17,T.INK,T.BOLD)
	var lines=[]
	if shop_receipt:
		var ids=r.items.keys();ids.sort()
		for id in ids:
			var name=w.item_def(id).get("name","")
			if name.is_empty():name=w.gear.by_id.get(id.split(".")[0],{}).get("name",id)
			lines.append(name+" ×%d"%r.items[id])
	else:
		for row in r.work:lines.append(row.name+(" · 가공" if row.kind=="process" else " · 제련 성공 +%d"%row.level if row.success else " · 제련 실패 +%d 유지"%row.level))
	var previous=stage;stage=scroll_page(188,427,maxi(90,lines.size()*65))
	for i in range(lines.size()):paragraph(lines[i],Rect2(0,i*65,342,58),16)
	stage=previous;label("남은 금화 %d"%r.gold,Rect2(18,649,354,29),17,T.RED,T.BOLD)
	action("receipt_done","확인",Rect2(18,715,354,49),func():w.acknowledge_receipt();host._draw_screen(),true)
