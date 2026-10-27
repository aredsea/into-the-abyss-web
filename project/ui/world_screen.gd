extends Control

const RouteMap=preload("res://ui/route_map.gd")
const World=preload("res://game/expansion_world.gd")
const Store=preload("res://game/world_store.gd")
const BattleScreen=preload("res://ui/battle_screen.gd")
const FONT=preload("res://assets/fonts/NanumGothic-Regular.ttf")
const CharacterSprite=preload("res://ui/character_sprite.gd")
const SignatureSequence=preload("res://ui/signature_sequence.gd")
const ForgedButton=preload("res://ui/forged_button.gd")
const INK=Color("eae4d6")
const GOLD=Color("d7b67e")
const MUTED=Color("afb8b3")
var model=World.new()
var storage=Store.new()
var screen="town"
var who="hildegard"
var selected_item=""
var catalog_all=false
var shop_tab="items"
var gear_filter="weapon"
var research_prefix="strike"
var research_suffix="bane"
var message=""
var confirm: Dictionary={}
var content: VBoxContainer
var controls={}
var scroll: ScrollContainer
var battle: Control
var save_error=OK
var restored=false
var metrics_time=0.0
var motion_reduced=false
var last_drawn_screen=""
var art_preview: Control
var art_preview_id=""

func _ready() -> void:
	motion_reduced=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	var theme=Theme.new()
	theme.default_font=FONT; theme.default_font_size=14
	theme.set_color("font_color","Label",INK)
	theme.set_color("font_color","Button",INK)
	theme.set_color("font_disabled_color","Button",Color("a1a6a0"))
	for type in ["normal","hover","pressed","focus","disabled"]:
		var style=StyleBoxFlat.new()
		style.bg_color=Color("292e2c") if type!="pressed" else Color("4b402c")
		style.border_color=Color("756a50") if type!="focus" else GOLD
		style.set_border_width_all(1)
		style.content_margin_left=12; style.content_margin_right=12
		style.content_margin_top=10; style.content_margin_bottom=10
		theme.set_stylebox(type,"Button",style)
	self.theme=theme
	restored=storage.read_into(model)
	if model.active(): screen="explore"
	elif not model.s.summary.is_empty(): screen="summary"
	resized.connect(_draw_screen)
	_draw_screen()

func _save() -> void:
	save_error=storage.write(model.s)
	if save_error!=OK: message="저장 실패: 창을 닫기 전에 다시 시도하세요."

func go(page: String) -> void:
	if model.active() and page in ["town","shop","inn","depart","guild","smithy"]: page="explore"
	screen=page; confirm={}; selected_item=""; message=""; _draw_screen()

func _draw_screen() -> void:
	if not is_inside_tree(): return
	if model.active() and model.s.run.phase=="battle":
		if is_instance_valid(battle): return
		for c in get_children(): remove_child(c); c.queue_free()
		battle=BattleScreen.new()
		battle.session_data=model.battle_data()
		battle.session_snapshot=model.s.run.battle
		battle.session_save=_save_battle
		battle.session_finished.connect(_leave_battle)
		battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(battle)
		_publish()
		return
	for c in get_children(): remove_child(c); c.queue_free()
	battle=null; controls.clear(); art_preview_id=""
	var width=minf(size.x,440); var height=size.y
	var base=Control.new(); add_child(base); base.position=Vector2((size.x-width)/2,0); base.size=Vector2(width,height)
	var back=ColorRect.new(); base.add_child(back); back.size=base.size; back.color=Color("151a1b"); back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var metal=TextureRect.new(); base.add_child(metal); metal.texture=load("res://assets/metal.png"); metal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; metal.size=Vector2(width,68); metal.modulate=Color(1,1,1,0.3); metal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var heading=Label.new(); base.add_child(heading); heading.position=Vector2(16,10); heading.size=Vector2(width-32,26); heading.text=_title(); heading.add_theme_font_size_override("font_size",22); heading.add_theme_color_override("font_color",GOLD)
	var status=Label.new(); base.add_child(status); status.position=Vector2(16,40); status.text="%d일째     금화 %d" % [model.s.day,model.s.gold]; status.add_theme_font_size_override("font_size",12)
	scroll=ScrollContainer.new(); base.add_child(scroll); scroll.position=Vector2(12,76); scroll.size=Vector2(width-24,height-152)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	content=VBoxContainer.new(); scroll.add_child(content); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",8 if screen=="town" else 12)
	if not message.is_empty(): text(message,14,GOLD)
	if save_error!=OK: button("save_retry","저장 다시 시도",func(): _save(); _draw_screen())
	if not confirm.is_empty(): _confirmation()
	else:
		match screen:
			"town": _town()
			"party": _party()
			"member": _member()
			"depart": _departure()
			"explore": _explore()
			"cards": _cards()
			"bag": _bag()
			"shop": _shop()
			"inn": _inn()
			"summary": _summary()
			"journal": _journal()
			"guild": _guild()
			"smithy": _smithy()
			"equipment": _equipment()
			"research": _research()
	var nav=HBoxContainer.new(); base.add_child(nav); nav.position=Vector2(12,height-66); nav.size=Vector2(width-24,54); nav.add_theme_constant_override("separation",6)
	for item in [["explore" if model.active() else "town","원정" if model.active() else "거점"],["party","동료"],["bag","가방"],["journal","기록"]]:
		var b=ForgedButton.new(); b.active=screen==item[0]; nav.add_child(b); b.text=item[1]; b.custom_minimum_size=Vector2(0,52); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.pressed.connect(go.bind(item[0])); controls["nav:"+item[0]]=b
	if last_drawn_screen!=screen and not motion_reduced:
		content.modulate.a=0; create_tween().tween_property(content,"modulate:a",1,.18)
	last_drawn_screen=screen
	call_deferred("_publish")

func _title() -> String:
	if screen=="research": return "로레다나의 전술 연구"
	return {"guild":"연합 길드 본관","smithy":"한나의 대장간","equipment":"장비 보관함","town":"토르바","party":"함께하는 동료","member":model.person(who).name,"depart":"원정 준비","explore":"학술원 폐허 상층","cards":"탐색 카드","bag":"공용 가방","shop":"마렌토 상회","inn":"아랫마을 여관","summary":"원정 정산","journal":"모험 기록"}.get(screen,"토르바")

func number(value: float) -> String:
	return str(int(value)) if value==int(value) else str(snappedf(value,0.01))

func text(value: String, fs=14, color=INK, parent: Node=null) -> Label:
	var label=Label.new(); (parent if parent else content).add_child(label)
	label.text=value.replace("−","-"); label.add_theme_font_size_override("font_size",fs); label.add_theme_color_override("font_color",color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func box() -> VBoxContainer:
	var panel=PanelContainer.new(); content.add_child(panel)
	panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style=StyleBoxFlat.new(); style.bg_color=Color("202725"); style.border_color=Color("655e4c"); style.set_border_width_all(1)
	style.content_margin_left=12; style.content_margin_right=12; style.content_margin_top=12; style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style)
	var body=VBoxContainer.new(); panel.add_child(body); body.add_theme_constant_override("separation",8)
	return body

func button(id: String, value: String, callback: Callable, disabled=false, parent: Node=null) -> Button:
	var b=ForgedButton.new(); (parent if parent else content).add_child(b)
	b.text=value; b.custom_minimum_size.y=54; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.disabled=disabled
	b.mouse_filter=Control.MOUSE_FILTER_PASS
	b.pressed.connect(callback); controls[id]=b
	return b

func image(path: String, target: Node, dims: Vector2) -> TextureRect:
	var t=TextureRect.new(); target.add_child(t); t.texture=load(path); t.custom_minimum_size=dims
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return t

func bar(label: String, value: float, maximum: float, parent: Node, hp=true) -> void:
	text("%s %d / %d" % [label,value,maximum],12,INK,parent)
	var p=ProgressBar.new(); parent.add_child(p); p.custom_minimum_size.y=10; p.show_percentage=false; p.max_value=maximum; p.value=value
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bg=StyleBoxFlat.new(); bg.bg_color=Color("090f11"); p.add_theme_stylebox_override("background",bg)
	var fill=StyleBoxFlat.new(); fill.bg_color=Color("b56651") if hp else Color("719da9"); p.add_theme_stylebox_override("fill",fill)

func companion_image(id: String, target: Node, dims: Vector2) -> Control:
	var pic=CharacterSprite.new(); pic.portrait_mode=true; pic.custom_minimum_size=dims
	target.add_child(pic); pic.configure(id); pic.size_flags_horizontal=SIZE_EXPAND_FILL
	return pic

func _portrait(id: String, parent: Node, large=false) -> void:
	var row=HBoxContainer.new(); parent.add_child(row); row.add_theme_constant_override("separation",14)
	companion_image(id,row,Vector2(128,170) if large else Vector2(76,104))
	var body=VBoxContainer.new(); row.add_child(body); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var m=model.s.members[id]; var p=model.person(id); var b=model.stats(id,m.level)
	text(p.name,18,GOLD,body); text("Lv.%d  %s\n%s" % [m.level,p["class"],p.row],13,MUTED,body)
	bar("HP",m.hp,b.hp,body); bar("MP",m.mp,b.mp,body,false)

func _town() -> void:
	var city=image("res://assets/src/torva-town-v1.png",content,Vector2(0,132))
	city.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var grid=GridContainer.new(); content.add_child(grid); grid.columns=2; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",8)
	for facility in [["guild","연합 길드","의뢰 · 영입","guild"],["shop","마렌토 상회","보급 · 장비","shop"],["inn","아랫마을 여관","교류 · 휴식","inn"],["smithy","한나의 대장간","강화 · 가공","smithy"]]:
		var b=button(facility[0],facility[1]+"\n"+facility[2],go.bind(facility[0]),false,grid)
		b.icon=load("res://assets/ic_pl_"+facility[3]+".webp"); b.add_theme_constant_override("icon_max_width",28); b.add_theme_font_size_override("font_size",13); b.custom_minimum_size.y=64
	var caption=HBoxContainer.new(); content.add_child(caption)
	text("출전 파티",17,GOLD,caption)
	var edit=button("town_formation","편성",go.bind("party"),false,caption); edit.custom_minimum_size=Vector2(62,44); edit.size_flags_horizontal=Control.SIZE_SHRINK_END
	var party=HBoxContainer.new(); content.add_child(party); party.add_theme_constant_override("separation",5)
	for id in model.s.party:
		var b=button("town_member:"+id,"",func(): who=id; go("member"),false,party); b.custom_minimum_size.y=160; b.textured=false
		var stack=VBoxContainer.new(); b.add_child(stack); stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); stack.offset_left=3; stack.offset_right=-3; stack.offset_top=3; stack.offset_bottom=-3; stack.add_theme_constant_override("separation",2); stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
		companion_image(id,stack,Vector2(0,112))
		var name_label=text(model.person(id).name,12,INK,stack); name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var role=text(model.person(id)["class"],12,MUTED,stack); role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var depart=button("depart","원정 준비",go.bind("depart")); depart.emphasis=true; depart.custom_minimum_size.y=58; depart.add_theme_font_size_override("font_size",18)
	depart.icon=load("res://assets/ic_pl_guild.webp"); depart.add_theme_constant_override("icon_max_width",24)

func _party() -> void:
	var row=HBoxContainer.new(); content.add_child(row)
	button("roster_owned","보유 %d명" % model.s.owned.size(),func(): catalog_all=false; _draw_screen(),false,row)
	button("roster_all","전체 30명",func(): catalog_all=true; _draw_screen(),false,row)
	text("전열 2명 · 후열 2명 / 동료 상세에서 편성",13,MUTED)
	var grid=GridContainer.new(); content.add_child(grid); grid.columns=2; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",12)
	for p in model.config.companions:
		if not catalog_all and p.id not in model.s.owned: continue
		var cell=VBoxContainer.new(); grid.add_child(cell); cell.size_flags_horizontal=SIZE_EXPAND_FILL
		companion_image(p.id,cell,Vector2(0,156))
		text(p.name,16,GOLD,cell); text(p.row+" · "+p["class"],12,MUTED,cell)
		var status="편성 중" if p.id in model.s.party else "보유" if p.id in model.s.owned else "미영입"
		button("member:"+p.id,status+" · 상세",func(): who=p.id; go("member"),false,cell)
	button("recruit_go","길드에서 동료 소개받기",go.bind("guild"),model.active())

func _member() -> void:
	var panel=box(); _portrait(who,panel,true)
	var p=model.person(who); var m=model.s.members[who]; var b=model.stats(who,m.level)
	text(p.race+" · "+p.nation,14,INK,panel)
	text("전용 무기 · "+CharacterSprite.info(who).weapon,13,MUTED,panel)
	button("signature_preview","전용 도트 · 고유 기술 연출",_show_art.bind(who),false,panel)
	bar("경험치",m.xp,model.need(m.level),panel,false)
	text("호감 %s / 200" % number(m.aff),14,GOLD,panel)
	text("힘 %.1f   민첩 %.1f   지능 %.1f\n방어 %.1f   속도 %.1f" % [b.str,b.agi,b.int,b.def,b.spd],14,INK,panel)
	text("고유 특성 · "+p.trait.name,17,GOLD)
	text(p.trait.note,14)
	text("고유 스킬 · "+p.skill.name,17,GOLD)
	text("MP %d · %s\n%s" % [p.skill.mp,p.skill.target,p.skill.note],14)

	if who in model.s.owned:
		text("편성 위치",17,GOLD)
		for i in range(4):
			if p.row==("전열" if i<2 else "후열"):
				button("assign:"+str(i),model.person(model.s.party[i]).name+" 자리로",func(): _act(model.assign.bind(who,i),"편성을 변경했습니다."),model.active() or model.s.party[i]==who)
		button("gear_for_member","장비 관리",go.bind("equipment"),model.active())
	else: text("길드에서 소개받으면 편성할 수 있습니다.",14,MUTED)
	text("직업 스킬",17,GOLD)
	for sk in model.class_def(who).skills:
		if sk.kind in ["기본","능동"]: text("%s · MP %d\n%s" % [sk.name,sk.mp,sk.note],14)
	button("party_back","동료 목록",go.bind("party"))

func _departure() -> void:
	var p=box(); image("res://assets/src/academy.png",p,Vector2(0,155))
	text("학술원 폐허 상층 · 2층",20,GOLD,p)
	text("갈림길 탐색 → 집행실 정예 → 귀환",14,INK,p)
	text("8개 장소 중 길을 골라 이동합니다. 전투를 피하거나 추가 보상을 노릴 수 있습니다. 마지막 집행실은 기존 정예전이며, 층 보스는 아직 없습니다.",13,MUTED,p)
	for id in model.s.party: text(model.person(id).row+"  "+model.person(id).name+"  Lv."+str(int(model.s.members[id].level)),14)
	text("출발 시 HP·MP가 채워집니다. 전투 사이에는 남은 수치가 이어집니다.",13,MUTED)
	button("start_run","원정 출발",func(): _act(model.depart,"원정을 시작했습니다."); go("explore"))

func _explore() -> void:
	if not model.active(): go("town"); return
	if model.mapped():
		_route_explore(); return
	text("이전 저장의 원정 · 이 원정 이후 새 지도가 적용됩니다.",12,MUTED)
	var r=model.s.run
	text("2층 탐색  %d / 5" % r.step,20,GOLD)
	var progress=HBoxContainer.new(); content.add_child(progress); progress.add_theme_constant_override("separation",6)
	for i in range(1,6):
		var l=text(str(i)+(" 완료" if i<=r.step else " 탐색"),12,GOLD if i<=r.step else MUTED,progress)
		l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var panel=box()
	var titles={"":"무너진 학술원 입구","find_card":"서가에 남은 기록","battle":"인형들이 멈춰 섰다","sealed":"봉인된 보관함","supplies":"버려진 야영지","coins":"붕괴한 복도"}
	var details={"":"갈라진 문 너머로 복도가 이어진다.","find_card":"봉인을 푸는 기록을 발견했다.\n‘봉인 해제’가 보유 패에 추가됐다.","battle":"전투에서 얻은 ‘안전한 야영’ 카드가 보유 패에 추가됐다.","sealed":"금속 상자의 잠금에 마력이 남아 있다. 봉인을 풀거나, 그대로 지나갈 수 있다.","supplies":"야영에 쓸 도구를 발견했다.\n‘안전한 야영’이 보유 패에 추가됐다.","coins":"모험가의 주머니에서 금화 20을 모았다."}
	if r.phase=="rest":
		text("마지막 전투 앞 휴식",20,GOLD,panel)
		text("파티 HP 30% · MP 60% 회복\n한 원정에서 한 번만 쉴 수 있습니다.",14,INK,panel)
		button("rest","휴식 완료" if r.rested else "파티 휴식",func(): _act(model.rest,"파티가 휴식을 취했습니다."),r.rested,panel)
		button("final_battle","마지막 정예와 전투",func(): _act(model.final_battle,""),not r.rested,panel)
	else:
		text(titles[r.event],20,GOLD,panel); text(details[r.event],15,INK,panel)
		if r.event=="sealed" and not r.resolved:
			button("unlock","봉인 해제 카드 사용",func(): _ask("카드 1장을 소모해 회복약을 얻을까요?",model.use_card.bind("key")),not model.card_reason("key").is_empty(),panel)
			button("leave_cache","그대로 지나가기",func(): _act(model.leave_cache,"보관함을 지나쳤습니다."),false,panel)
		else:
			button("advance","휴식 장소로" if r.step==5 else "다음 구역 탐색",func(): _act(model.advance,""),false,panel)
	text("미정산 금화 %d · 경험치 %d" % [r.gold,r.xp],14,GOLD)
	button("cards","보유 탐색 카드 · %d장" % model.s.hand.size(),go.bind("cards"))
	var grid=GridContainer.new(); content.add_child(grid); grid.columns=2
	grid.add_theme_constant_override("h_separation",10); grid.add_theme_constant_override("v_separation",12)
	for id in model.s.party:
		var m=model.s.members[id]; var b=model.stats(id,m.level)
		var row=VBoxContainer.new(); grid.add_child(row); row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		text(model.person(id).name,14,GOLD,row); bar("HP",m.hp,b.hp,row); bar("MP",m.mp,b.mp,row,false)
	button("retreat","모은 보상을 챙겨 귀환",func(): _ask("지금까지 모은 금화와 경험치를 정산하고 귀환할까요?",model.settle.bind("retreat")))

func _route_explore() -> void:
	var r=model.s.run; var node=World.Route.NODES[r.node]
	text("2층 · "+node.name,20,GOLD)
	var map=RouteMap.new(); content.add_child(map)
	map.custom_minimum_size.y=158; map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	map.current=r.node; map.path=r.path; map.options=model.destinations()
	text("● 현재 위치   금빛 길: 지나온 길   목표: 집행실",12,MUTED)
	var panel=box()
	if r.event=="sealed" and r.resolved:
		text("보관함 탐색을 마쳤다.",15,INK,panel)
	else: text(node.detail,15,INK,panel)
	if r.event=="sealed" and not r.resolved:
		button("unlock","봉인 해제 · 회복약 1개 획득",func(): _ask("봉인 해제 카드 1장을 소모해 회복약을 얻을까요?",model.use_card.bind("key")),not model.card_reason("key").is_empty(),panel)
		if "key" not in model.s.hand: text("봉인 해제 카드가 없습니다. 지나갈 수 있습니다.",12,MUTED,panel)
		button("leave_cache","열지 않고 지나가기",func(): _act(model.leave_cache,"보관함을 지나쳤습니다."),false,panel)
	elif r.event=="rest":
		button("rest","휴식 완료" if r.rested else "휴식 · HP 30%, MP 60% 회복",func(): _act(model.rest,"파티가 휴식을 취했습니다."),r.rested,panel)
		if not r.resolved: button("skip_rest","쉬지 않고 이동 준비",func(): _act(model.skip_rest,""),false,panel)
	if not model.destinations().is_empty():
		text("다음 장소",16,GOLD)
		for id in model.destinations():
			var n=World.Route.NODES[id]
			var b=button("travel:"+id,n.name+"\n"+n.hint,func(): _act(model.travel.bind(id),""))
			b.custom_minimum_size.y=70; b.add_theme_font_size_override("font_size",13)
	button("cards","탐색 카드 · %d장 보유" % model.s.hand.size(),go.bind("cards"))
	text("미정산 금화 %d · 경험치 %d" % [r.gold,r.xp],13,GOLD)
	button("retreat","보상을 챙겨 귀환",func(): _ask("모은 금화와 경험치를 정산하고 귀환할까요?",model.settle.bind("retreat")))

func _cards() -> void:
	text("사용한 카드는 소모됩니다. 전투와 탐색 이벤트에서 새 카드를 얻습니다.",14)
	text("카드 효과·지급량·귀환 후 보존은 검수용 임시안입니다.",12,MUTED)
	if model.s.hand.is_empty(): text("아직 보유한 카드가 없습니다. 원정에서 카드를 발견할 수 있습니다.",16)
	for id in ["key","camp"]:
		var count=model.s.hand.count(id)
		if count==0: continue
		var c=model.card_def(id); var p=box()
		text(c.name+"  ×"+str(count),20,GOLD,p); text(c.text,15,INK,p)
		var reason=model.card_reason(id)
		if not reason.is_empty(): text(reason,13,MUTED,p)
		button("card:"+id,"카드 1장 사용",func(): _ask(c.name+" 카드 1장을 소모할까요?",model.use_card.bind(id)),not reason.is_empty(),p)
	button("cards_back","원정으로" if model.active() else "거점으로",go.bind("explore" if model.active() else "town"))

func _bag() -> void:
	button("equipment","장비 보관함",go.bind("equipment"))
	text("파티가 함께 쓰는 보급품입니다.",14,MUTED)
	if not selected_item.is_empty():
		text(model.item_def(selected_item).name+" · 사용할 동료",19,GOLD)
		for id in model.s.party:
			var p=box(); _portrait(id,p)
			button("use:"+id,"이 동료에게 사용",func(): _act(model.use_item.bind(selected_item,id),"보급품을 사용했습니다."),false,p)
		return
	for item in model.config.items:
		var p=box(); var row=HBoxContainer.new(); p.add_child(row)
		image("res://assets/ic_"+item.icon+".webp",row,Vector2(44,44))
		text(item.name+"  ×"+str(int(model.s.items[item.id])),17,GOLD,row)
		text(_item_text(item),13,MUTED,p)
		button("item:"+item.id,"대상 선택",func(): selected_item=item.id; _draw_screen(),model.s.items[item.id]<=0,p)
	button("bag_cards","탐색 카드 보기",go.bind("cards"))

func _item_text(item: Dictionary) -> String:
	var extra={"hp":"최대 HP의 %d%% 회복" % int(item.fraction*100),"mp":"최대 MP의 %d%% 회복" % int(item.fraction*100),"shield":"최대 HP의 %d%% 보호막 · 3턴" % int(item.fraction*100),"revive":"쓰러진 동료를 HP 25%로 소생","cleanse":"지속 피해 해제 · 전투 중 사용","return":"탐색 중 원정을 끝내고 보상 정산","level":"레벨 +1 · 최대 40 · 마을에서 사용"}
	return "Lv.%d부터 · %s" % [item.level,extra.get(item.kind,"")]

func _shop() -> void:
	_npc("pietro","마렌토 상회","원정에 필요한 물건은 여기서 챙기십시오.")
	var tabs=HBoxContainer.new(); content.add_child(tabs)
	button("shop_items","보급품",func(): shop_tab="items"; _draw_screen(),false,tabs)
	button("shop_equipment","장비",func(): shop_tab="gear"; _draw_screen(),false,tabs)
	if shop_tab=="items":
		for item in model.config.items:
			var p=box(); text(item.name+" · 보유 "+str(int(model.s.items[item.id])),17,GOLD,p)
			text(_item_text(item),13,MUTED,p)
			button("buy:"+item.id,"구입 · 금화 %d" % model.price(item),func(): _act(model.buy.bind(item.id),"구입했습니다."),model.s.gold<model.price(item) or model.active(),p)
	else:
		_member_picker()
		text(model.person(who).name+"의 직업 장비 · 하루마다 재고 변경",13,MUTED)
		var slots=HBoxContainer.new(); content.add_child(slots)
		for slot in World.Gear.SLOT:
			button("shop_slot:"+slot,World.Gear.SLOT[slot],func(): gear_filter=slot; _draw_screen(),false,slots)
		for id in model.gear.stock(model.class_def(who).id,model.s.day):
			var item=model.gear.by_id[id]
			if item.slot!=gear_filter: continue
			var p=box()
			text(item.name,17,GOLD,p); text(_gear_caption(item),13,MUTED,p)
			text(_gear_values(item.base),13,INK,p)
			button("buygear:"+id,"구입 · 금화 %d" % model.price({"price":model.gear.price(id)}),func(): _act(model.buy_gear.bind(id,who),"장비를 구입했습니다."),model.s.gold<model.price({"price":model.gear.price(id)}),p)
	button("shop_bag","가방과 장비 확인",go.bind("equipment"))

func _inn() -> void:
	_npc("dorothea","도로테아 · 여관 주인","동료와 식사하고, 다음 출발을 준비하세요.")
	_member_picker()
	var p=box(); _portrait(who,p,true)
	text("호감 %s / 200" % number(model.s.members[who].aff),14,GOLD,p)
	text("대화·식사·선물은 동료마다 하루 한 번. 숙박하면 하루가 지납니다.",14)
	for entry in [["talk","대화하기",0],["meal","함께 식사",25],["gift","작은 선물",30],["rest","곁에서 쉬기",20]]:
		var used=entry[0]!="rest" and model.s.acts.get(who+"_"+entry[0],0)==model.s.day
		button("inn:"+entry[0],entry[1]+(" · 오늘 완료" if used else " · 금화 "+str(entry[2])),func(): _ask(entry[1]+" 행동을 할까요?\n호감이 오르고 "+str(entry[2])+"금화를 씁니다.",model.inn.bind(who,entry[0])),used or model.s.gold<entry[2])
	var row=HBoxContainer.new(); content.add_child(row)
	for id in World.IDS:
		var b=button("inn_pick:"+id,model.person(id).name.substr(0,2),func(): who=id; _draw_screen(),false,row); b.custom_minimum_size.x=0
	text("숙박은 날짜와 호감만 변경합니다. 출발할 때 파티 HP·MP가 채워집니다.",12,MUTED)

func _summary() -> void:
	if model.s.summary.is_empty(): text("아직 정산한 원정이 없습니다."); return
	var r=model.s.summary; var p=box()
	text({"clear":"검수 원정 종료","retreat":"토르바로 귀환","defeat":"부상으로 철수"}[r.result],24,GOLD,p)
	text("전투 승리 %d회" % r.wins,15,INK,p)
	text("획득 금화  +%d\n동료별 경험치  +%d" % [r.gold,r.xp],21,GOLD,p)
	if r.lost>0: text("잃은 미정산 금화 %d" % r.lost,14,INK,p)
	text("보상은 이미 지급됐습니다. 이 화면을 다시 열어도 중복 지급되지 않습니다.",13,MUTED,p)
	for g in r.gains:
		var m=model.s.members[g.id]; var row=box(); text(model.person(g.id).name+"  Lv.%d → %d" % [g.before,g.level],17,GOLD,row)
		bar("경험치",m.xp,model.need(m.level),row,false)
	button("summary_home","토르바로",go.bind("town"))

func _journal() -> void:
	text("브라우저에 자동 저장됩니다. 기기 간 저장 공유는 아직 지원하지 않습니다.",13,MUTED)
	text("원정 %d회 · 보유 카드 %d장" % [model.s.runs,model.s.hand.size()],17,GOLD)
	if model.s.log.is_empty(): text("아직 모험 기록이 없습니다.")
	for i in range(model.s.log.size()-1,-1,-1): text(model.s.log[i],14)

func _ask(prompt: String, callback: Callable) -> void:
	confirm={"prompt":prompt,"callback":callback}; message=""; _draw_screen()

func _confirmation() -> void:
	var p=box(); text(confirm.prompt,19,GOLD,p)
	button("accept","확인",_accept,false,p)
	button("cancel","취소",func(): confirm={}; _draw_screen(),false,p)

func _accept() -> void:
	if confirm.is_empty(): return
	var action=confirm.callback; confirm={}
	_act(action,"처리했습니다.")

func _act(callback: Callable, success: String) -> void:
	var ok=callback.call()
	message=success if ok else "지금 사용할 수 없습니다. 대상의 상태와 보유량을 확인하세요."
	if ok:
		_save()
		if not model.active() and not model.s.summary.is_empty() and screen in ["explore","cards"]: screen="summary"
	_draw_screen()

func _save_battle(snapshot: Dictionary) -> Error:
	model.record_battle(snapshot); _save(); return save_error

func _leave_battle() -> void:
	if not model.finish_battle(): return
	_save(); screen="explore" if model.active() else "summary"
	if is_instance_valid(battle): remove_child(battle); battle.queue_free(); battle=null
	_draw_screen()

func _publish() -> void:
	if not OS.has_feature("web"): return
	var buttons={}
	for id in controls:
		if not is_instance_valid(controls[id]): continue
		var b=controls[id]; var r=b.get_global_rect()
		buttons[id]={"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"disabled":b.disabled,"needed":FONT.get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,b.get_theme_font_size("font_size")).x+24}
	var report={"build":model.config.build,"screen":"battle" if is_instance_valid(battle) else screen,"state":model.s,"controls":buttons,"viewport":[size.x,size.y],"restored":restored,"save_error":save_error,"art_preview":art_preview_id,"town_scroll_height":content.size.y if is_instance_valid(content) else 0}
	JavaScriptBridge.eval("window.__abyssWorld="+JSON.stringify(report)+";",true)

func _process(delta: float) -> void:
	# QA reads actual controls, not an action or state mutation bridge.
	metrics_time+=delta
	if metrics_time<0.2: return
	metrics_time=0
	if is_instance_valid(scroll) and not is_instance_valid(battle): _publish()

func _npc(id: String,title: String,line: String) -> void:
	var p=box(); var row=HBoxContainer.new(); p.add_child(row); row.add_theme_constant_override("separation",14)
	image("res://assets/"+id+".webp",row,Vector2(86,112))
	var body=VBoxContainer.new(); row.add_child(body); body.size_flags_horizontal=SIZE_EXPAND_FILL
	text(title,18,GOLD,body); text(line,14,INK,body)

func _member_picker() -> void:
	if who not in model.s.owned: who=model.s.party[0]
	var pick=OptionButton.new(); content.add_child(pick); pick.custom_minimum_size.y=52
	for id in model.s.owned: pick.add_item(model.person(id).name+" · "+model.person(id)["class"])
	pick.selected=model.s.owned.find(who)
	pick.item_selected.connect(func(i): who=model.s.owned[i]; _draw_screen())

func _guild() -> void:
	_npc("fenella","페넬라 · 길드 접수","의뢰와 동료 소개를 맡고 있어요.")
	button("research","로레다나 · 전술 연구",go.bind("research"))
	button("recruit","동료 소개 · 금화 %d" % (100+20*model.s.recruits),func(): _act(model.recruit,""); message=model.s.log[-1]; _draw_screen(),model.s.gold<100+20*model.s.recruits or model.s.owned.size()==30)
	text("미영입 동료 중 1명 합류 · 중복 없음\n현재 보유 %d / 30명" % model.s.owned.size(),13,MUTED)
	if not model.s.quest.is_empty():
		var p=box(); text("수락한 의뢰 · "+model.s.quest.name,17,GOLD,p)
		text("현재 검수판에서는 학술원 원정 완료로 의뢰를 정산합니다. 균열 전용 전장은 아직 없습니다.",13,MUTED,p)
		button("quest_depart","원정 준비",go.bind("depart"),false,p)
		button("quest_abandon","의뢰 포기",func(): _ask("현재 의뢰를 포기할까요?",model.abandon_quest),false,p)
	else:
		text("의뢰 게시판",20,GOLD)
		for q in model.s.board:
			var p=box(); text(q.name,17,GOLD,p); text("%s · %s · Lv.%d\n보수 금화 %d" % [q.rift,q.difficulty,q.level,q.gold],13,INK,p)
			button("quest:"+str(int(q.id)),"의뢰 수락",func(): _act(model.accept_quest.bind(q.id),"의뢰를 수락했습니다."),false,p)
	button("refresh_board","게시판 갱신 · 금화 %d" % (10*int(pow(2,mini(model.s.refreshes,4)))),func(): _act(model.refresh_board,"게시판을 갱신했습니다."))

func _gear_caption(item: Dictionary) -> String:
	return "%s · %s · 착용 Lv.%d" % [World.Gear.RARITY[item.rarity],World.Gear.SLOT[item.slot],model.gear.rules.equip_lv[item.rarity]]

func _gear_values(values: Dictionary) -> String:
	var out=[]
	for key in values:
		var label=model.gear.rules.base.get(key,model.gear.rules.affix.get(key,{})).get("name",key)
		out.append(label+" +"+number(values[key])+"%")
	return " · ".join(out)

func _equipment() -> void:
	_member_picker()
	var eq=model.s.equipment[who]
	text(model.person(who).name+"의 장착 장비",19,GOLD)
	for slot in World.Gear.SLOT:
		if eq.has(slot):
			var entry=model.gear_entry(eq[slot]); var item=model.gear.by_id[entry.id]
			button("unequip:"+slot,World.Gear.SLOT[slot]+" · "+item.name+" 해제",func(): _act(model.unequip.bind(who,slot),"해제했습니다."),model.active())
		else: text(World.Gear.SLOT[slot]+" · 미장착",13,MUTED)
	if model.s.gear.is_empty(): text("보유 장비가 없습니다. 상회에서 구입하거나 한나에게 가공을 맡기세요.")
	for entry in model.s.gear:
		var item=model.gear.by_id[entry.id]
		if item.cls!=model.class_def(who).id: continue
		var p=box(); text(item.name+" +"+str(int(entry.forge)),17,GOLD,p); text(_gear_caption(item),13,MUTED,p)
		text(_gear_values(model.gear.roll(entry,model.s.members[who].level)),13,INK,p)
		if item.has("unique"): text(item.unique.name+" · "+item.unique.text,13,GOLD,p)
		if item.has("sig"): text(item.sig.name+" · "+item.sig.text,13,GOLD,p)
		var wearer=model.wearer(entry.uid)
		if not wearer.is_empty(): text(model.person(wearer).name+" 장착 중",13,GOLD,p)
		button("equip:"+str(int(entry.uid)),"장착",func(): _act(model.equip.bind(who,entry.uid),"장착했습니다."),model.active() or model.s.members[who].level<model.gear.rules.equip_lv[item.rarity] or wearer==who,p)
		button("sell:"+str(int(entry.uid)),"판매 · 금화 %d" % model.gear.sell_price(entry),func(): _ask(item.name+"을 판매할까요?",model.sell_gear.bind(entry.uid)),model.active() or not wearer.is_empty(),p)

func _smithy() -> void:
	_npc("hanna","한나 · 대장장이","장비는 실패해도 사라지지 않아. 비용부터 확인해.")
	_member_picker()
	var band=model.gear.band(model.highest_level()); var odds=[]
	for key in band.w: odds.append(World.Gear.RARITY[key]+" "+str(band.w[key])+"%")
	text("가공 확률 · "+" / ".join(odds),13,MUTED)
	button("process_gear","장비 가공 · 금화 %d" % band.price,func(): _act(model.process_gear.bind(who),""); message=model.s.log[-1]; _draw_screen(),model.s.gold<band.price)
	text("보유 장비 강화 · 최대 +10",19,GOLD)
	text("강화 단계마다 장비 수치 +4% · 실패 시 단계 유지",13,MUTED)
	for entry in model.s.gear:
		var item=model.gear.by_id[entry.id]; var p=box(); text(item.name+" +"+str(int(entry.forge)),17,GOLD,p)
		if entry.forge>=10: text("최대 강화",13,MUTED,p); continue
		text("다음 단계 성공률 %d%%" % model.gear.rules.forge.success[int(entry.forge)],14,INK,p)
		button("forge:"+str(int(entry.uid)),"강화 · 금화 %d" % model.gear.forge_cost(entry),func(): _ask(item.name+" 강화 시도? 실패해도 비용은 소모됩니다.",model.forge.bind(entry.uid)),model.s.gold<model.gear.forge_cost(entry),p)
	button("smith_equipment","장비 장착하기",go.bind("equipment"))

func _research() -> void:
	_npc("loredana","로레다나 · 길드장","기술의 몸통과 덧효과를 조합해 보죠.")
	_member_picker()
	text("웹판 전술 슬롯: 조합한 기술이 방어 버튼을 대신합니다. 원래 스킬은 유지됩니다.",13,MUTED)
	var r=model.s.research[who]
	var current=model.tactic(who)
	text("장착: "+current.get("name","없음 · 기본 방어 사용"),16,GOLD)
	for kind in ["prefixes","suffixes"]:
		var pick=OptionButton.new(); content.add_child(pick); pick.custom_minimum_size.y=52
		pick.fit_to_longest_item=false; pick.clip_text=true
		var parts=[]
		for part in model.research[kind]:
			if kind=="prefixes" or model.compatible(research_prefix,part.id): parts.append(part)
		for part in parts: pick.add_item(part.name+" · "+part.note)
		var selected=research_prefix if kind=="prefixes" else research_suffix
		for i in range(parts.size()):
			if parts[i].id==selected: pick.selected=i
		pick.item_selected.connect(func(i):
			if kind=="prefixes":
				research_prefix=parts[i].id
				for suffix in model.research.suffixes:
					if model.compatible(research_prefix,suffix.id): research_suffix=suffix.id; break
			else: research_suffix=parts[i].id
			_draw_screen())
	button("compose","이 조합 장착 · 무료",func(): _act(model.compose.bind(who,research_prefix,research_suffix),"전술을 장착했습니다."))
	for kind in ["prefix","suffix"]:
		if r[kind].is_empty(): continue
		var level=r[kind+"_lv"].get(r[kind],0); var amount=40+20*level*level
		button("train:"+kind,("몸통" if kind=="prefix" else "덧효과")+" +%d → +%d · 금화 %d" % [level,level+1,amount],func(): _ask("금화를 소모해 전술 조각을 강화할까요?",model.train.bind(who,kind)),level>=10 or model.s.gold<amount)
	button("research_clear","전술 해제 · 기본 방어 복원",func(): model.s.research[who].prefix=""; model.s.research[who].suffix=""; _save(); _draw_screen(),model.active())
	button("research_back","길드 접수로",go.bind("guild"))


func _show_art(id: String) -> void:
	if is_instance_valid(art_preview): remove_child(art_preview); art_preview.queue_free()
	for key in ["art_prev","art_next","art_replay","art_close"]: controls.erase(key)
	art_preview_id=id
	art_preview=Control.new(); add_child(art_preview); art_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); art_preview.mouse_filter=Control.MOUSE_FILTER_STOP
	var shade=ColorRect.new(); art_preview.add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.color=Color(0,0,0,.88); shade.mouse_filter=MOUSE_FILTER_IGNORE
	var width=minf(size.x-24,406); var height=minf(size.y-96,510)
	var box=VBoxContainer.new(); art_preview.add_child(box); box.position=Vector2((size.x-width)/2,(size.y-height)/2); box.size=Vector2(width,height); box.add_theme_constant_override("separation",10)
	var data=CharacterSprite.info(id)
	text(data.name+" · "+data["class"],18,GOLD,box)
	text("전용 무기 · "+data.weapon,13,INK,box)
	var stage=Control.new(); box.add_child(stage); stage.custom_minimum_size=Vector2(0,300); stage.size_flags_vertical=SIZE_EXPAND_FILL
	var sprite=CharacterSprite.new(); stage.add_child(sprite); sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); sprite.configure(id,true); sprite.visible=false
	var seq=SignatureSequence.new(); seq.character_id=id; seq.preview=true; seq.reduced=motion_reduced; stage.add_child(seq); seq.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seq.finished.connect(func(): sprite.visible=true)
	text("연출 미리보기 · 전투 수치와 저장에는 영향 없음",12,MUTED,box)
	var row=HBoxContainer.new(); box.add_child(row); row.add_theme_constant_override("separation",6)
	var ids=model.config.companions.map(func(p): return p.id); var index=ids.find(id)
	button("art_prev","이전",_show_art.bind(ids[posmod(index-1,ids.size())]),false,row)
	button("art_replay","다시 재생",_show_art.bind(id),false,row)
	button("art_next","다음",_show_art.bind(ids[(index+1)%ids.size()]),false,row)
	button("art_close","닫기",_close_art,false,box)
	call_deferred("_publish")

func _close_art() -> void:
	if is_instance_valid(art_preview): art_preview.queue_free()
	art_preview_id=""
	for key in ["art_prev","art_next","art_replay","art_close"]: controls.erase(key)
	_publish()
