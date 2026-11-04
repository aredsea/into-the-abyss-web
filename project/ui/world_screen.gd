extends Control

const RouteMap=preload("res://ui/route_map.gd")
const World=preload("res://game/settings_world_r22.gd")
const ExpeditionScreen=preload("res://ui/expedition_screen_r22.gd")
const CreateScreen=preload("res://ui/create_screen.gd")
const PersonaSortieScreen=preload("res://ui/persona_sortie_screen.gd")
const TownScreen=preload("res://ui/facilities_screen_r22.gd")
const DungeonViewR21=preload("res://game/dungeon_view_r21.gd")
const Store=preload("res://game/settings_save_r22.gd")
const BattleScreen=preload("res://ui/battle_screen.gd")
const UI=preload("res://ui/town_theme_r21.gd")
const FONT=UI.BODY
const PortraitCard=preload("res://ui/portrait_card.gd")
const NavigationButton=preload("res://ui/navigation_button.gd")
const FacilityButton=preload("res://ui/facility_button.gd")
const CharacterSprite=preload("res://ui/character_sprite.gd")
const CharacterPortrait=preload("res://ui/character_portrait.gd")
const SignatureSequence=preload("res://ui/signature_sequence.gd")
const ForgedButton=preload("res://ui/forged_button.gd")
const INK=UI.INK
const GOLD=UI.GOLD
const MUTED=UI.MUTED
var model=World.new()
var storage=Store.new()
var screen="town"
var who="hildegard"
var selected_item=""
var selected_target=""
var catalog_all=false
var shop_tab="items"
var gear_filter="weapon"
var research_prefix="strike"
var research_suffix="bane"
var research_edit=false
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
var art_base_controls={}
var town_view: Control
var details_return="member"
var town_r21_preview=false
var result_view: Control
var cloud
var cloud_connecting=false
var cloud_confirmation: Dictionary={}

var reset_r22=false
var settings_return_r22="town"
var settings_saved_r22=false
var panels_r22
var panels_return="town"
var journal_return="town"
var journal_r22={"place":"town","person":"","legacy":false}

func open_settings_r22() -> void:
	settings_return_r22=screen;reset_r22=false;screen="settings";_draw_screen()

func _ready() -> void:
	motion_reduced=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	self.theme=UI.make_theme()
	restored=storage.read_into(model)
	cloud=preload("res://game/cloud_store_r22.gd").new();cloud.model=model;cloud.storage=storage;add_child(cloud)
	storage.saved.connect(cloud.local_saved)
	cloud.changed.connect(func():
		if screen in ["cloud","rank"]:_draw_screen())
	if model.active(): screen="explore"
	elif model.has_method("expedition_defeat_home") and model.expedition_defeat_home():screen="town"
	elif not model.s.summary.is_empty(): screen="summary"
	resized.connect(_draw_screen)
	_draw_screen()

func _save() -> void:
	if is_instance_valid(cloud):cloud.model=model
	save_error=storage.write(model.s)
	if save_error!=OK: message="저장 실패: 창을 닫기 전에 다시 시도하세요."

func go(page: String,remember_entry=true) -> void:
	cloud_confirmation={}
	if remember_entry and page in ["codex","status","inventory"] and screen not in ["codex","status","inventory"]:panels_return=screen
	if remember_entry and page in ["journal","places","people"] and screen not in ["journal","places","people"]:journal_return=screen
	if page=="town" and screen=="summary" and model.has_method("chronicle_home"):model.chronicle_home();_save()
	if page=="member_details" and screen in ["member","skills"]: details_return=screen
	if model.active() and page in ["town","shop","inn","depart","guild","smithy"]: page="explore"
	if page in ["guild","shop","inn","smithy"] or (page=="town" and screen in ["guild","shop","inn","smithy"]):model.s.place=""
	if model.has_method("facility_route") and not model.facility_route(page): message=model.facility_message;_draw_screen();return
	screen=page; confirm={}; selected_item=""; message=""; _draw_screen()

func _draw_screen() -> void:
	if not is_inside_tree(): return
	call_deferred("_finish_display_r24")
	if is_instance_valid(cloud):cloud.model=model
	var dialogue_state=model.s.get("dialogue_r21",{"pending":{},"response":{},"queue":[]})
	var dialogue_open=not dialogue_state.pending.is_empty() or not dialogue_state.response.is_empty()
	var journey_open=not dialogue_state.queue.is_empty() and screen in ["explore","summary","inn"] and not is_instance_valid(battle)
	if model.active() and model.s.run.phase=="battle" and not model.s.run.battle.is_empty():journey_open=false
	if model.active() and model.s.run.phase=="battle" and not journey_open:
		if is_instance_valid(battle): return
		for c in get_children():
			if c==cloud:continue
			remove_child(c); c.queue_free()
		battle=preload("res://ui/expedition_supply_screen_r22.gd").new() if model.has_method("expedition") and model.expedition() else BattleScreen.new()
		if model.s.has("persona"):preload("res://ui/persona_visual_adapter.gd").prepare()
		battle.session_data=model.battle_data()
		battle.session_snapshot=model.s.run.battle
		battle.session_save=_save_battle
		battle.session_finished.connect(_leave_battle)
		battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(battle)
		_publish()
		return
	for c in get_children():
		if c==cloud:continue
		remove_child(c); c.queue_free()
	battle=null; controls.clear(); art_preview_id="";art_preview=null;art_base_controls={}
	town_view=null
	result_view=null
	if model.has_method("acknowledge_receipt") and not model.receipt.is_empty():
		town_view=TownScreen.new();add_child(town_view);town_view.build(self);return
	if screen in ["cloud","rank"]:
		town_view=preload("res://ui/cloud_screen_r22.gd").new();add_child(town_view);town_view.build(self);call_deferred("_publish");return
	if screen=="settings":
		town_view=preload("res://ui/settings_screen_r22.gd").new();add_child(town_view);town_view.build(self);return
	if model.s.has("persona") and not model.s.creation_r22.complete:
		town_view=CreateScreen.new();add_child(town_view);town_view.build(self);return
	if screen in ["codex","status","inventory"]:
		if panels_r22==null or panels_r22.model!=model:panels_r22=preload("res://game/panels_state_r22.gd").new(model)
		town_view=load("res://ui/"+{"codex":"codex","status":"status","inventory":"inventory"}[screen]+"_screen_r22.gd").new();add_child(town_view);town_view.build(self);return
	if screen in ["journal","places","people"]:
		town_view=preload("res://ui/journal_screen_r22.gd").new();add_child(town_view);town_view.build(self);return
	if model.s.has("persona") and screen in ["formation","depart"]:
		town_view=PersonaSortieScreen.new();add_child(town_view);town_view.build(self);return
	var finished_town=screen in ["town","party","member","skills","cards","depart","bag","formation","journal","summary","inn","shop","guild","recruit","equipment","smithy","research","expedition_log","facility_scroll"] or (screen=="explore" and (model.r21() or model.s.run.get("event","")=="sealed"))
	if (finished_town or dialogue_open or journey_open) and (confirm.is_empty() or (screen=="explore" and model.r21())):
		var p5=model.has_method("expedition") and model.expedition() and screen in ["explore","expedition_log","summary","bag","equipment"]
		town_view=ExpeditionScreen.new() if p5 else TownScreen.new(); add_child(town_view); town_view.build(self)
		last_drawn_screen=screen; call_deferred("_publish"); return
	var width=minf(size.x,440); var height=size.y
	var paper_ground=ColorRect.new();add_child(paper_ground);paper_ground.color=UI.PAPER;paper_ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);paper_ground.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var base=Control.new(); add_child(base); base.position=Vector2((size.x-width)/2,0); base.size=Vector2(width,height)
	var back=ColorRect.new(); base.add_child(back); back.size=base.size; back.color=UI.GROUND; back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	UI.rule(base,88,width-36)
	var heading=Label.new(); base.add_child(heading); heading.position=Vector2(18,12); heading.size=Vector2(width-112,40); heading.text=_title(); heading.add_theme_font_size_override("font_size",30); heading.add_theme_font_override("font",UI.TITLE); heading.add_theme_color_override("font_color",UI.INK); heading.clip_text=true
	preload("res://game/localization_r22.gd").fit_title(heading,30)
	var status=Label.new(); base.add_child(status); status.position=Vector2(18,56); status.text="%d일째     금화 %d" % [model.s.day,model.s.gold]; status.add_theme_font_size_override("font_size",12)
	scroll=ScrollContainer.new(); base.add_child(scroll); scroll.position=Vector2(18,104); scroll.size=Vector2(width-36,height-180)
	UI.scroll_region(scroll)
	content=VBoxContainer.new(); scroll.add_child(content); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",8 if screen=="town" else 12)
	if not message.is_empty(): text(message,14,GOLD)
	if save_error!=OK: button("save_retry","저장 다시 시도",func(): _save(); _draw_screen())
	if not confirm.is_empty(): _confirmation()
	else:
		match screen:
			"town": _town()
			"party": _party()
			"member": _member()
			"member_details": _member()
			"formation": _formation()
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
	var nav=HBoxContainer.new(); base.add_child(nav); nav.position=Vector2(0,height-66); nav.size=Vector2(width,66); nav.add_theme_constant_override("separation",0)
	for item in [["town","마을"],["party","동료"],["explore" if model.active() else "depart","원정"],["bag","가방"],["journal","기록"]]:
		var b=Button.new(); b.text=item[1]; nav.add_child(b); b.custom_minimum_size=Vector2(0,66); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",12)
		UI.dress_navigation(b,"depart" if item[0]=="explore" else item[0],item[0]==screen or (screen=="member_details" and item[0]=="party"))
		b.pressed.connect(go.bind(item[0])); controls["nav:"+item[0]]=b
	UI.rule(base,height-76,width-36)
	var back_button=Button.new(); base.add_child(back_button); back_button.position=Vector2(width-88,20); back_button.size=Vector2(70,44); back_button.text="뒤로";UI.dress_button(back_button)
	back_button.pressed.connect(go.bind(details_return if screen=="member_details" else "member" if screen=="formation" else "formation" if screen=="equipment" else "town")); controls["back"]=back_button
	if last_drawn_screen!=screen and not motion_reduced:
		content.modulate.a=0; create_tween().tween_property(content,"modulate:a",1,.18)
	last_drawn_screen=screen
	call_deferred("_publish")

func _title() -> String:
	if screen=="explore" and model.r21(): return model.dungeon_title()
	if screen=="formation": return "편성 · 장비"
	if screen=="member_details": return model.person(who).name+" 상세"
	if screen=="research": return "로레다나의 전술 연구"
	return {"guild":"연합 길드 본관","smithy":"한나의 대장간","equipment":"장비 보관함","town":"토르바","party":"함께하는 동료","member":model.person(who).name,"depart":"원정 준비","explore":"학술원 폐허 상층","cards":"탐색 카드","bag":"공용 가방","shop":"마렌토 상회","inn":"아랫마을 여관","summary":"원정 정산","journal":"모험 기록"}.get(screen,"토르바")

func _finish_display_r24() -> void:
	var locale=preload("res://game/localization_r22.gd")
	for node in find_children("*","Control",true,false):
		if node is Label or node is Button or node is RichTextLabel:
			node.text=locale.authored_display(node.text,model.s) if node.get_meta("authored_copy",false) else locale.display(node.text,model.s)
		if node is OptionButton:
			for i in node.item_count:node.set_item_text(i,locale.display(node.get_item_text(i),model.s))
		if node is LineEdit:node.placeholder_text=locale.display(node.placeholder_text,model.s)
		if node.tooltip_text!="":node.tooltip_text=locale.display(node.tooltip_text,model.s)
	# Let containers allocate their text before measuring. Fluid body labels keep
	# their authored size and expand vertically; only fixed slots need fitting.
	call_deferred("_fit_display_r24")

func _fit_display_r24() -> void:
	_reskin_primary()
	var locale=preload("res://game/localization_r22.gd")
	for node in find_children("*","Control",true,false):
		if not (node is Label or node is Button):continue
		UI.inline_icons(node)
		if node is Button or node.has_meta("metric_index"):locale.fit_box(node)
		if node.has_meta("metric_index") and is_instance_valid(town_view):
			var metrics=town_view.get("metrics");var index=int(node.get_meta("metric_index"))
			if metrics is Array and index<metrics.size():
				var fs=node.get_theme_font_size("font_size");metrics[index].text=node.text;metrics[index].font_size=fs
				metrics[index].needed=node.get_theme_font("font").get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,node.size.x if node.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs).x

func _reskin_primary() -> void:
	if is_instance_valid(battle):return
	var candidates={"cloud":["cloud_confirm","cloud_create","cloud_save","cloud_connect"],"rank":["rank_refresh"],"settings":["p8_reset_yes","p8_cloud"],"inventory":["p7_bg_equip","p7_bg_sell"],"codex":["p7_cx_join"],"member_details":["gear_for_member","signature_preview"],"journal":["cloud_open"],"places":["p10_visit","p10_facility"],"people":["p10_visit"]}.get(screen,[])
	for id in candidates:
		if controls.has(id) and controls[id] is Button and not controls[id].disabled:
			var b=controls[id];UI.primary(b)
			if b.has_node("RowCopy"):
				for color in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:b.add_theme_color_override(color,Color.TRANSPARENT)
				for l in b.get_node("RowCopy").find_children("*","Label",true,false):l.add_theme_color_override("font_color",UI.PAPER)
				for child in b.get_children():
					if child is TextureRect and child.material is ShaderMaterial:child.material.set_shader_parameter("tint",UI.PAPER)
			break

func number(value: float) -> String:
	return str(int(value)) if value==int(value) else str(snappedf(value,0.01))

func text(value: String, fs=14, color=INK, parent: Node=null) -> Label:
	var label=Label.new(); (parent if parent else content).add_child(label)
	if fs>=17: label.add_theme_font_override("font",UI.TITLE)
	label.text=preload("res://game/localization_r22.gd").display(value,model.s).replace("−","-"); label.add_theme_font_size_override("font_size",fs); label.add_theme_color_override("font_color",UI.INK if color==GOLD else color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func box() -> VBoxContainer:
	var panel=PanelContainer.new(); content.add_child(panel)
	panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style=UI.panel()
	style.set_border_width_all(0);style.border_width_bottom=2;style.border_color=UI.INK
	style.content_margin_left=0; style.content_margin_right=0; style.content_margin_top=12; style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style)
	var body=VBoxContainer.new(); panel.add_child(body); body.add_theme_constant_override("separation",8)
	return body

func button(id: String, value: String, callback: Callable, disabled=false, parent: Node=null) -> Button:
	var b=Button.new(); (parent if parent else content).add_child(b)
	b.text=preload("res://game/localization_r22.gd").display(value,model.s); b.custom_minimum_size.y=54; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.disabled=disabled
	b.mouse_filter=Control.MOUSE_FILTER_PASS
	UI.dress_button(b);b.alignment=HORIZONTAL_ALIGNMENT_LEFT
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
	if label in ["HP","MP"]:
		var gauge=preload("res://ui/resource_gauge_r24.gd").attach(parent,Rect2(0,0,100,9 if hp else 3),value,maximum,hp)
		gauge.custom_minimum_size=Vector2(0,9 if hp else 3);gauge.size_flags_horizontal=SIZE_EXPAND_FILL
	else:
		var p=ProgressBar.new();parent.add_child(p);p.custom_minimum_size.y=10;p.show_percentage=false;p.max_value=maximum;p.value=value
		p.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var bg=StyleBoxFlat.new(); bg.bg_color=UI.PALE; p.add_theme_stylebox_override("background",bg)
		var fill=StyleBoxFlat.new(); fill.bg_color=UI.HP if hp else UI.MP; p.add_theme_stylebox_override("fill",fill)

func companion_image(id: String, target: Node, dims: Vector2) -> Control:
	var pic=preload("res://ui/portrait_slot_r24.gd").make(id,"detail",dims)
	target.add_child(pic);pic.size_flags_horizontal=SIZE_EXPAND_FILL
	return pic

func _portrait(id: String, parent: Node, large=false) -> void:
	var row=HBoxContainer.new(); parent.add_child(row); row.add_theme_constant_override("separation",14)
	companion_image(id,row,Vector2(128,170) if large else Vector2(76,104))
	var body=VBoxContainer.new(); row.add_child(body); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var m=model.s.members[id]; var p=model.person(id); var b=model.stats(id,m.level)
	text(p.name,18,GOLD,body); text("Lv.%d  %s\n%s" % [m.level,p["class"],p.row],13,MUTED,body)
	bar("HP",m.hp,b.hp,body); bar("MP",m.mp,b.mp,body,false)

func _town() -> void:
	var city=image("res://assets/ui-r11/torva-daylight.png",content,Vector2(0,148))
	city.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var caption=HBoxContainer.new(); content.add_child(caption)
	text("출전 파티",18,INK,caption)
	var edit=button("town_formation","편성",go.bind("party"),false,caption); edit.custom_minimum_size=Vector2(62,44); edit.size_flags_horizontal=Control.SIZE_SHRINK_END
	var party=HBoxContainer.new(); content.add_child(party); party.add_theme_constant_override("separation",6)
	for id in model.s.party:
		var card=PortraitCard.new(); card.configure(id,model.person(id).name,model.person(id)["class"])
		card.custom_minimum_size=Vector2(0,164); card.size_flags_horizontal=SIZE_EXPAND_FILL; party.add_child(card)
		card.pressed.connect(func(): who=id; go("member")); controls["town_member:"+id]=card
	var depart=button("depart","원정 준비",go.bind("depart")); depart.custom_minimum_size.y=54; depart.add_theme_font_size_override("font_size",18)
	depart.add_theme_stylebox_override("normal",UI.panel(UI.RED,UI.RED)); depart.add_theme_color_override("font_color",UI.PAPER)
	text("마을 시설",16,INK)
	var grid=GridContainer.new(); content.add_child(grid); grid.columns=2; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",8)
	for facility in [["guild","연합 길드","의뢰 · 영입"],["shop","마렌토 상회","보급 · 장비"],["inn","아랫마을 여관","교류 · 휴식"],["smithy","한나의 대장간","강화 · 가공"]]:
		var b=FacilityButton.new(); b.configure(facility[1],facility[2],facility[0]); grid.add_child(b)
		b.custom_minimum_size=Vector2(0,60); b.size_flags_horizontal=SIZE_EXPAND_FILL
		b.pressed.connect(go.bind(facility[0])); controls[facility[0]]=b

func _party() -> void:
	var row=HBoxContainer.new(); content.add_child(row)
	button("roster_owned","보유 %d명" % model.s.owned.size(),func(): catalog_all=false; _draw_screen(),false,row)
	button("roster_all","전체 30명",func(): catalog_all=true; _draw_screen(),false,row)
	text("전열 2명 · 후열 2명 / 동료 상세에서 편성",13,MUTED)
	var grid=GridContainer.new(); content.add_child(grid); grid.columns=2; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",12)
	for p in model.config.companions:
		if not catalog_all and p.id not in model.s.owned: continue
		var cell=VBoxContainer.new(); grid.add_child(cell); cell.size_flags_horizontal=SIZE_EXPAND_FILL
		var status="편성 중" if p.id in model.s.party else "보유" if p.id in model.s.owned else "미영입"
		var card=PortraitCard.new(); card.large=true; card.selected=p.id in model.s.party
		card.configure(p.id,p.name,p["class"]+" · "+status,true); card.custom_minimum_size=Vector2(0,222); cell.add_child(card)
		card.pressed.connect(func(): who=p.id; go("member")); controls["member:"+p.id]=card
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
	DungeonViewR21.departure(self)

func _legacy_departure() -> void:
	var p=box(); image("res://assets/src/academy.png",p,Vector2(0,155))
	text("학술원 폐허 상층 · 2층",20,GOLD,p)
	text("갈림길 탐색 → 집행실 정예 → 귀환",14,INK,p)
	text("8개 장소 중 길을 골라 이동합니다. 전투를 피하거나 추가 보상을 노릴 수 있습니다. 마지막 집행실은 기존 정예전이며, 층 보스는 아직 없습니다.",13,MUTED,p)
	for id in model.s.party: text(model.person(id).row+"  "+model.person(id).name+"  Lv."+str(int(model.s.members[id].level)),14)
	text("출발 시 HP·MP가 채워집니다. 전투 사이에는 남은 수치가 이어집니다.",13,MUTED)
	button("start_run","원정 출발",func(): _act(model.depart,"원정을 시작했습니다."); go("explore"))

func _formation() -> void:
	_member_picker()
	text("출전 위치를 선택하세요",20,INK)
	text("선택한 동료 · "+model.person(who).name+" / "+model.person(who).row,14,MUTED)
	for i in range(4):
		var id=model.s.party[i]
		var row="전열" if i<2 else "후열"
		button("formation:"+str(i),row+" · "+model.person(id).name,func():_act(model.assign.bind(who,i),"편성을 변경했습니다."),model.active() or id==who or model.person(who).row!=row)
	button("gear_for_member","장비 관리",go.bind("equipment"),model.active())

func _explore() -> void:
	if not model.active(): go("town"); return
	if model.r21(): DungeonViewR21.explore(self); return
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
			var preview=model.item_preview(selected_item,id)
			text("%s %s → %s" % [preview.get("resource",""),number(preview.get("before",0)),number(preview.get("after",0))],14,GOLD,p)
			if not preview.usable: text(preview.reason,12,MUTED,p)
			button("use:"+id,"이 동료에게 사용",func(): _act(model.use_item.bind(selected_item,id),"보급품을 사용했습니다."),not preview.usable,p)
		button("item_cancel","취소",func():selected_item="";_draw_screen())
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
	button("cloud_open","클라우드 저장",go.bind("cloud"))
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
	_save(); screen="town" if model.has_method("expedition_defeat_home") and model.expedition_defeat_home() else "explore" if model.active() else "summary"
	if is_instance_valid(battle): remove_child(battle); battle.queue_free(); battle=null
	_draw_screen()

func _publish() -> void:
	if not OS.has_feature("web"): return
	var buttons={}
	for id in controls:
		if not is_instance_valid(controls[id]): continue
		var b=controls[id]; var r=b.get_global_rect()
		buttons[id]={"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"disabled":b.disabled,"needed":FONT.get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,b.get_theme_font_size("font_size")).x+24}
		if b is OptionButton:
			buttons[id].selected=b.selected;buttons[id].options=range(b.item_count).map(func(i):return b.get_item_text(i))
			var popup=b.get_popup()
			if popup.visible:
				var top=popup.get_theme_stylebox("panel").get_content_margin(SIDE_TOP)
				var row_height=popup.get_theme_font("font").get_height(popup.get_theme_font_size("font_size"))+popup.get_theme_constant("v_separation")
				buttons[id].popup_first=[popup.position.x+popup.size.x/2.0,popup.position.y+top+row_height/2.0]
		var parent=b.get_parent();var clip=Rect2(Vector2.ZERO,size)
		while parent!=null and parent!=self:
			if parent is ScrollContainer:clip=clip.intersection(parent.get_global_rect())
			parent=parent.get_parent()
		buttons[id].clip=[clip.position.x,clip.position.y,clip.size.x,clip.size.y]
	var report={"build":model.config.build,"ui_build":"r21-d-town-20261103c","town_r21_preview":town_r21_preview,"screen":"battle" if is_instance_valid(battle) else screen,"state":model.s,"controls":buttons,"viewport":[size.x,size.y],"restored":restored,"save_error":save_error,"art_preview":art_preview_id,"town_scroll_height":content.size.y if is_instance_valid(content) else 0}
	if is_instance_valid(town_view): report.town_text=town_view.metrics
	if screen in ["cloud","rank"] and is_instance_valid(town_view):
		report.cloud={"busy":cloud.busy,"code":cloud.account.code,"rev":cloud.account.rev,"notice":cloud.notice,"conflict":not cloud.conflict.is_empty(),"inputs":town_view.input_rects()}
	JavaScriptBridge.eval("window.__abyssWorld="+JSON.stringify(report)+";",true)

func _process(delta: float) -> void:
	# QA reads actual controls, not an action or state mutation bridge.
	metrics_time+=delta
	if metrics_time<0.2: return
	metrics_time=0
	if is_instance_valid(battle) and battle.state!=null and not battle.state.result.is_empty() and not battle.busy:
		if not is_instance_valid(result_view):
			controls.clear();result_view=preload("res://ui/town_result_r21.gd").new();add_child(result_view);result_view.build_result(self,battle)
		_publish();return
	if (is_instance_valid(scroll) or is_instance_valid(town_view)) and not is_instance_valid(battle): _publish()

func _npc(id: String,title: String,line: String) -> void:
	var p=box(); var row=HBoxContainer.new(); p.add_child(row); row.add_theme_constant_override("separation",14)
	companion_image(id,row,Vector2(86,112))
	var body=VBoxContainer.new(); row.add_child(body); body.size_flags_horizontal=SIZE_EXPAND_FILL
	text(title.replace(" · ","\n"),18,GOLD,body); text(line,14,INK,body)

func _member_picker() -> void:
	if who not in model.s.owned: who=model.s.party[0]
	var pick=OptionButton.new(); content.add_child(pick); pick.custom_minimum_size.y=52
	for id in model.s.owned: pick.add_item(model.person(id).name+" · "+model.person(id)["class"])
	pick.selected=model.s.owned.find(who)
	pick.item_selected.connect(func(i): who=model.s.owned[i]; _draw_screen())

func _guild() -> void:
	_npc("fenella","페넬라 · 길드 접수","의뢰와 동료 소개를 맡고 있어요.")
	button("research","로레다나 · 전술 연구",go.bind("research"))
	button("recruit","동료 소개 · 금화 %d" % model.recruit_fee(),func(): _act(model.recruit,""); message=model.s.log[-1]; _draw_screen(),model.s.gold<model.recruit_fee() or model.s.owned.size()==30)
	text("미영입 동료 중 1명 합류 · 중복 없음\n현재 보유 %d / 30명" % model.s.owned.size(),13,MUTED)
	if not model.s.quest.is_empty():
		var p=box(); text("수락한 의뢰 · "+model.s.quest.name,17,GOLD,p)
		var contract=model.quest_contract(model.s.quest)
		text("%s · %s · Lv.%d\n보수 금화 %d"%[contract.rift,model.dungeon_rules.quest_fight(contract),contract.lv,model.dungeon_rules.quest_gold(contract,contract.lv)],13,MUTED,p)
		button("quest_depart","수락한 균열 의뢰로 출발",func():_act(model.depart_accepted_quest,"");go("explore"),false,p)
		button("quest_abandon","의뢰 포기",func(): _ask("현재 의뢰를 포기할까요?",model.abandon_quest),false,p)
	else:
		text("의뢰 게시판",20,GOLD)
		for q in model.s.board:
			var contract=model.quest_contract(q)
			var p=box(); text(q.name,17,GOLD,p); text("%s · %s · Lv.%d\n보수 금화 %d" % [q.rift,contract.difficulty,contract.lv,model.dungeon_rules.quest_gold(contract,contract.lv)],13,INK,p)
			button("quest:"+str(int(q.id)),"의뢰 수락",func(): _act(model.accept_quest.bind(q.id),"의뢰를 수락했습니다."),false,p)
	button("refresh_board","게시판 갱신 · 금화 %d" % model.refresh_fee(),func(): _act(model.refresh_board,"게시판을 갱신했습니다."))

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
		var comparison=model.gear_comparison(who,entry.uid)
		if not comparison.is_empty():
			var delta=[]
			for key in comparison.delta:
				if not is_zero_approx(comparison.delta[key]): delta.append(key+" %+.1f%%" % comparison.delta[key])
			text("장착 시 변화 · "+("동일" if delta.is_empty() else " / ".join(delta)),12,MUTED,p)
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
	for key in controls.keys():
		if key.begins_with("art_") or key.begins_with("art_nav:"):controls.erase(key)
	art_preview_id=id
	if is_instance_valid(town_view):
		if art_base_controls.is_empty():art_base_controls=controls.duplicate()
		controls.clear();town_view.visible=false
		art_preview=preload("res://ui/town_art_r21.gd").new();add_child(art_preview);art_preview.build_art(self,id)
		call_deferred("_publish");return
	art_preview=Control.new(); add_child(art_preview); art_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); art_preview.mouse_filter=Control.MOUSE_FILTER_STOP
	var shade=ColorRect.new(); art_preview.add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.color=Color(0,0,0,.88); shade.mouse_filter=MOUSE_FILTER_IGNORE
	var width=minf(size.x-24,406); var height=minf(size.y-96,510)
	var box=VBoxContainer.new(); art_preview.add_child(box); box.position=Vector2((size.x-width)/2,(size.y-height)/2); box.size=Vector2(width,height); box.add_theme_constant_override("separation",10)
	var data=CharacterSprite.info(id)
	text(data.name+" · "+data["class"],18,UI.PAPER,box)
	text("전용 무기 · "+data.weapon,13,UI.PALE,box)
	var stage=Control.new(); box.add_child(stage); stage.custom_minimum_size=Vector2(0,300); stage.size_flags_vertical=SIZE_EXPAND_FILL
	var sprite=CharacterSprite.new(); stage.add_child(sprite); sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); sprite.configure(id,true); sprite.visible=false
	var seq=SignatureSequence.new(); seq.character_id=id; seq.preview=true; seq.reduced=motion_reduced; stage.add_child(seq); seq.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seq.finished.connect(func(): sprite.visible=true)
	text("연출 미리보기 · 전투 수치와 저장에는 영향 없음",12,UI.PALE,box)
	var row=HBoxContainer.new(); box.add_child(row); row.add_theme_constant_override("separation",6)
	var ids=model.config.companions.map(func(p): return p.id); var index=ids.find(id)
	button("art_prev","이전",_show_art.bind(ids[posmod(index-1,ids.size())]),false,row)
	button("art_replay","다시 재생",_show_art.bind(id),false,row)
	button("art_next","다음",_show_art.bind(ids[(index+1)%ids.size()]),false,row)
	button("art_close","닫기",_close_art,false,box)
	call_deferred("_publish")

func _close_art() -> void:
	if is_instance_valid(art_preview): art_preview.queue_free()
	art_preview=null
	art_preview_id=""
	for key in controls.keys():
		if key.begins_with("art_") or key.begins_with("art_nav:"):controls.erase(key)
	if not art_base_controls.is_empty():controls=art_base_controls;art_base_controls={}
	if is_instance_valid(town_view):town_view.visible=true
	_publish()
