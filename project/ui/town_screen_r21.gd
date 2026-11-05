extends Control
## First completed delivery: measured home / roster / overview / skills.
## All other destinations retain their complete functional screens in world_screen.
const ResourceGauge=preload("res://ui/resource_gauge_r24.gd")
const T=preload("res://ui/town_theme_r21.gd")
const L=preload("res://game/localization_r22.gd")
const Portrait=preload("res://ui/portrait_slot_r24.gd")
const Ink=preload("res://ui/battle_ink_r17.gd")
var host
var stage: Control
var boxes={}
var metrics=[]
var nav_top=763.0
var background_scene=""
var primary_used=false

func build(owner_screen) -> void:
	build_frame(owner_screen)
	build_page()
	finish_localization()

func localized(value: String) -> String:
	return L.display(value,host.model.s)

func finish_localization() -> void:
	if L.language(host.model.s)!="en":return
	# Give short English words room before fitting the artwork's fixed slots.
	for entry in [["town_settings",282,88],["roster_all",309,72]]:
		if host.controls.has(entry[0]):
			var b=host.controls[entry[0]];b.position.x=entry[1];b.size.x=entry[2]
	for node in find_children("*","Control",true,false):
		if node is Label or node is Button:
			L.fit_box(node)
			if node.has_meta("metric_index"):
				var metric=metrics[node.get_meta("metric_index")]
				metric.text=node.text;metric.font_size=node.get_theme_font_size("font_size")
				metric.needed=node.get_theme_font("font").get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,node.size.x if node.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,metric.font_size).x

func build_frame(owner_screen) -> void:
	host=owner_screen; mouse_filter=MOUSE_FILTER_IGNORE
	theme=T.make_theme(); set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg=ColorRect.new(); add_child(bg); bg.color=T.PAPER; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.mouse_filter=MOUSE_FILTER_IGNORE
	stage=Control.new(); add_child(stage); stage.size=Vector2(390,844)
	var k=minf(host.size.x/390.0,host.size.y/844.0)
	stage.scale=Vector2(k,k); stage.position=(host.size-stage.size*k)/2; stage.clip_contents=true
	T.paper(stage)

func build_page() -> void:
	page_background()
	var dialogue_state=host.model.s.get("dialogue_r21",{"pending":{},"response":{},"queue":[]})
	if not dialogue_state.pending.is_empty() or not dialogue_state.response.is_empty():
		inn_dialogue();return
	if not dialogue_state.queue.is_empty() and host.screen in ["explore","summary","inn"]:
		journey_dialogue();return
	if not host.confirm.is_empty() and host.screen=="explore": retreat()
	elif host.screen=="town":
		nav_top=778; home()
	elif host.screen=="party": roster()
	elif host.screen=="member": overview()
	elif host.screen=="skills": skills()
	elif host.screen=="depart": departure()
	elif host.screen=="bag": bag()
	elif host.screen=="formation": formation()
	elif host.screen=="explore":
		if not host.model.r21(): cache()
		else: exploration()
	elif host.screen=="cards": cards()
	elif host.screen=="journal": journal()
	elif host.screen=="summary": summary()
	elif host.screen=="inn": inn()
	elif host.screen=="shop": shop()
	elif host.screen=="guild": guild()
	elif host.screen=="recruit": recruit()
	elif host.screen=="equipment": equipment()
	elif host.screen=="smithy": smithy()
	elif host.screen=="research": research()
	
	navigation()
	if host.save_error==OK and not host.message.is_empty() and host.screen in ["town","party","member","skills","cards","explore"]:
		fill("notice_bg",Rect2(14,nav_top-44,362,40),T.INK)
		label(host.message,Rect2(22,nav_top-43,346,38),12,T.PAPER)
	if host.save_error!=OK:
		save_failure()

func save_failure() -> void:
	# Reserve a recovery strip rather than painting over the existing action.
	# Existing controls keep their callbacks and remain reachable by scrolling.
	var inset=70.0 if host.message.is_empty() else 100.0
	var full: ScrollContainer
	for child in stage.get_children():
		if child is ScrollContainer and child.position.y==0 and child.size.y>=nav_top-2:full=child;break
	if full!=null:
		full.position.y=inset;full.size.y=nav_top-inset
	else:
		var content_nodes=stage.get_children().duplicate()
		full=ScrollContainer.new();stage.add_child(full);full.position=Vector2(0,inset);full.size=Vector2(390,nav_top-inset);T.scroll_region(full)
		var page=Control.new();full.add_child(page);page.custom_minimum_size=Vector2(378,nav_top)
		for node in content_nodes:
			var key=str(node.get_meta("town_r21_box",""))
			if key.begins_with("nav") or node.z_index==60:continue
			node.reparent(page,false)
	if not host.message.is_empty():paragraph(host.message,Rect2(18,2,354,30),11,T.DANGER)
	var retry=action("save_retry","저장 다시 시도",Rect2(18,inset-62,354,54),func():host._save();host._draw_screen())
	T.primary(retry);retry.set_meta("r24_warning",true)

func mark(id: String,node: Control) -> void:
	node.set_meta("town_r21_box",id); boxes[id]=node

func fill(id: String,r: Rect2,color: Color) -> ColorRect:
	var c=ColorRect.new(); stage.add_child(c); c.position=r.position; c.size=r.size; c.color=color; c.mouse_filter=MOUSE_FILTER_IGNORE
	mark(id,c); return c

func resource(id: String,r: Rect2,value: float,maximum: float,hp=true) -> Control:
	var node=ResourceGauge.attach(stage,r,value,maximum,hp)
	mark(id,node);return node

func resource_numbers(r: Rect2,value: float,maximum: float,hp=true,large=20) -> Control:
	return T.readable_resource(ResourceGauge.numbers(stage,r,value,maximum,hp,0,large))

func label(value: String,r: Rect2,fs=14,color=T.INK,font: Font=T.BODY,translate=true) -> Label:
	fs=maxi(12,fs)
	var l=Label.new(); stage.add_child(l); l.position=r.position; l.size=r.size
	l.text=localized(value) if translate else value; l.add_theme_font_override("font",font); l.add_theme_font_size_override("font_size",fs); l.add_theme_color_override("font_color",color)
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; l.mouse_filter=MOUSE_FILTER_IGNORE
	l.clip_text=true
	# Assign after text/font/clip: Label's transient minimum otherwise widens
	# a fixed slot before wrapping, letting copy escape its black sign.
	l.size=r.size
	metrics.append({"text":value,"needed":font.get_multiline_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x,"available":r.size.x,"font_size":fs})
	l.set_meta("metric_index",metrics.size()-1)
	return l

func display(value: String,r: Rect2,color=T.INK,fs=64,stretch=false) -> Label:
	var l=label(value,r,fs,color,T.DISPLAY)
	var width=T.DISPLAY.get_string_size(l.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	if width>r.size.x or stretch:
		l.size.x=width;l.scale.x=r.size.x/maxf(1,width);metrics[-1].available=width
	return l

func background(name: String,r: Rect2) -> void:
	var p=TextureRect.new(); stage.add_child(p);p.position=r.position;p.size=r.size
	p.texture=load("res://assets/ui-r21/bg-"+name+".webp");p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;p.stretch_mode=TextureRect.STRETCH_SCALE;p.mouse_filter=MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new();material.shader=preload("res://ui/reskin_place_r24.gdshader");p.material=material
	mark("background:"+name,p); background_scene=name
	if name in ["inn","guild","shop","smithy","research","recruit","equipment"]:p.modulate.a=.18

func page_background() -> void:
	var name=host.screen;var r=Rect2(0,0,390,447)
	if name in ["town","party","member","skills"]:return
	if name=="explore":
		if not host.confirm.is_empty():name="retreat";r=Rect2(0,68,390,162)
		elif not host.model.r21():name="cache";r=Rect2(0,94,390,388)
		elif host.model.s.run.phase=="rest":name="rest";r=Rect2(0,68,390,162)
		else:name="explore";r=Rect2(0,68,390,162)
	elif name in ["member","skills","party"]:name="town";r=Rect2(0,0,390,484 if host.screen=="member" else 285 if host.screen=="skills" else 757)
	elif name=="town":r=Rect2(0,0,390,530)
	elif name=="depart":name="departure";r=Rect2(0,48,390,219)
	elif name=="summary":r=Rect2(0,64,390,180)
	elif name=="equipment":r=Rect2(0,0,390,190)
	elif name=="cards":name="empty" if host.model.s.hand.is_empty() else "cards";r=Rect2(0,0,390,355 if name=="empty" else 328)
	elif name=="journal":r=Rect2(0,0,390,267)
	elif name=="recruit":r=Rect2(0,0,390,505)
	elif name=="smithy":r=Rect2(0,0,390,482)
	elif name=="inn":r=Rect2(0,0,390,430)
	elif name=="shop":r=Rect2(0,0,390,373)
	elif name not in ["guild","research"]:return
	background(name,r)
	

func traced_title(name: String,r: Rect2) -> void:
	var titles={"home":"토르바","formation":"편성","rest":"휴식","explore":"탐험","retreat":"후퇴","guild":"의뢰","inn":"여관","research":"전술 연구","equipment":"장비","journal":"기록","summary":"원정 정산","victory":"승리","defeat":"패배","art":"기술 연출","cache":"봉인된 보관함","recruit":"동료 소개","shop":"마렌토 상회","smithy":"한나의 대장간"}
	var title=display(titles.get(name,name),r,T.INK,mini(54,int(r.size.y*.65)))
	mark("title:"+name,title)

func action(id: String,value: String,r: Rect2,callback: Callable,primary=false,disabled=false,translate=true) -> Button:
	# Reuse the bot's exact English action terms; authored choice text stays Korean.
	if translate and L.language(host.model.s)=="en" and id.begins_with("dialogue_"):
		value={"계속":"Continue","여관으로":"Lower Town Inn","나중에 이야기하기":"Cancel"}.get(value,value)
	var b=Button.new(); stage.add_child(b); b.position=r.position; b.size=r.size; b.text=localized(value) if translate else value; b.disabled=disabled
	b.add_theme_font_override("font",T.BOLD); b.add_theme_font_size_override("font_size",16)
	T.dress_button(b,primary)
	var selection=id.contains("tab") or id.begins_with("guild:") or id.begins_with("shop_slot:") or id.begins_with("so_") or id in ["shop_items","shop_equipment"]
	if primary and not selection and not primary_used:
		T.primary(b);primary_used=true
	b.pressed.connect(callback); host.controls[id]=b; mark(id,b)
	return b

func hit(id: String,r: Rect2,callback: Callable) -> Button:
	var b=action(id,"",r,callback)
	for state in ["normal","hover","pressed"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	return b

func picture(id: String,r: Rect2,slot="bust") -> Control:
	if id!="persona" and host.model.has_method("source_portrait_record") and not ResourceLoader.exists("res://assets/"+id+".webp") and not ResourceLoader.exists("res://assets/portraits-r21/"+id+"-upperbody.png"):
		var face=host.model.source_portrait_record(id)
		var box=fill("portrait_fallback:"+id,r,T.PALE)
		var initial=face.fallback
		var glyph=label(initial,r,22,T.INK,T.BOLD,false);glyph.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		return box
	var p=Portrait.make(id,slot,r.size);stage.add_child(p);p.position=r.position
	if id=="persona":boxes.persona_portrait=p
	mark("portrait:"+id+":"+slot,p);return p

func ink(r: Rect2,_kind="base") -> void:
	var c=TextureRect.new();stage.add_child(c);c.texture=T.BRUSH;c.position=r.position;c.size=r.size;c.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;c.stretch_mode=TextureRect.STRETCH_SCALE;c.modulate.a=.12;c.mouse_filter=MOUSE_FILTER_IGNORE

func header(title: String,back="town") -> void:
	hit("back",Rect2(10,10,44,44),host.go.bind(back))
	icon("back",Rect2(21,22,23,23))
	label(title,Rect2(56,11,225,38),20,T.INK,T.BOLD)

func icon(name: String,r: Rect2,color=T.INK) -> void:
	T.icon(stage,name,r,color)

func plate(name: String,r: Rect2) -> void:
	if not background_scene.is_empty() and name in ["preparation-ruins","town-city-left","town-city-right","detail-city"]:return
	var t=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stage.add_child(t); t.texture=load("res://assets/ui-r21/"+name+".svg"); t.position=r.position; t.size=r.size; t.mouse_filter=MOUSE_FILTER_IGNORE

func navigation() -> void:
	nav_top=778 if host.screen in ["town","member","party"] else nav_top
	fill("navigation_rule",Rect2(0,nav_top,390,844-nav_top),T.INK)
	var selected="party" if host.screen in ["member","skills","party","formation"] else "depart" if host.screen in ["depart","explore","cards"] else "bag" if host.screen=="bag" else "journal" if host.screen=="journal" else "town"
	for i in 5:
		var e=[["town","마을"],["party","동료"],["depart","원정"],["bag","가방"],["journal","기록"]][i]
		var destination="explore" if e[0]=="depart" and host.model.active() else e[0]
		var b=action("nav:"+e[0],e[1],Rect2(i*78,nav_top,78,844-nav_top),host.go.bind(destination))
		var active=T.dress_navigation(b,e[0],selected==e[0])
		if active!=null:mark("nav_active",active)

func home() -> void:
	var original_stage=stage
	var sc=ScrollContainer.new();stage.add_child(sc);sc.position=Vector2.ZERO;sc.size=Vector2(390,778);T.scroll_region(sc)
	# The contract's 390px art remains full width; reserved rail is outside ink.
	sc.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var town_page=Control.new();sc.add_child(town_page);town_page.custom_minimum_size=Vector2(378,1420);stage=town_page
	var map=Control.new();stage.add_child(map);map.size=Vector2(390,520);map.clip_contents=true;map.mouse_filter=MOUSE_FILTER_IGNORE
	var previous_stage=stage;stage=map;background("town",Rect2(-60,-154,520,693));stage=previous_stage;T.torn(stage,495)
	display("토르바",Rect2(18,16,238,65),T.INK,50)
	label("%d일째"%host.model.s.day,Rect2(18,79,70,22),13,T.MUTED,T.BOLD)
	icon("coin",Rect2(92,82,15,15),T.GOLD);label("금화 %d"%host.model.s.gold,Rect2(111,79,160,22),13,T.INK,T.BOLD)
	var settings=hit("town_settings",Rect2(332,14,44,44),host.open_settings_r22);settings.text=localized("설정")
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:settings.add_theme_color_override(key,Color.TRANSPARENT)
	icon("gear",Rect2(343,25,22,22))
	var specs=[["guild","연합 길드","의뢰판 · 동료 소개",118,196,176],["shop","마렌토 상회","물약 · 해독약 · 두루마리",150,396,206],["inn","여관","휴식 · 동료와 대화",30,316,150],["smithy","한나의 대장간","제련 · 가공",226,282,158]]
	for e in specs:
		var x=float(e[3]);var y=float(e[4]);var width=minf(e[5],388-x);var color=T.RED if facility_has_news(e[0]) else T.INK
		var b=hit(e[0],Rect2(x,y,width,44),host.go.bind(e[0]));b.tooltip_text=localized(e[1]+" · "+e[2])
		fill("facility_label:"+e[0],Rect2(x+36,y-1,width-36,44),color)
		var circle=Panel.new();stage.add_child(circle);circle.position=Vector2(x,y);circle.size=Vector2(40,40);circle.mouse_filter=MOUSE_FILTER_IGNORE
		var style=T.panel(T.PAPER,color);style.set_border_width_all(2);style.set_corner_radius_all(20);circle.add_theme_stylebox_override("panel",style)
		icon(e[0],Rect2(x+9,y+9,22,22),color);label(e[1],Rect2(x+45,y+2,width-48,20),13,T.PAPER,T.BOLD)
		var description=e[2] if L.language(host.model.s)!="en" else {"guild":"Quests · Companions","shop":"Potions · Antidotes · Scrolls","inn":"Rest · Talk to companions","smithy":"Forge · Process"}[e[0]]
		var desc=label(description,Rect2(x+45,y+21,width-48,19),12,Color("c9bfae"),T.BODY,L.language(host.model.s)!="en");desc.autowrap_mode=TextServer.AUTOWRAP_OFF;desc.size=Vector2(width-48,19)
	var ids=host.model.s.party.duplicate()
	if host.model.s.get("persona",{}).get("fight",0)==1:ids.push_front("persona")
	for i in 4:
		var x=14+i*92.0
		if i>=ids.size():
			icon("party",Rect2(x+29,552,28,28),T.QUIET);label("빈 자리",Rect2(x+6,609,80,23),12,T.MUTED);rule(683,x,84);continue
		var id=ids[i];var person=host.model.person(id);var m=host.model.s.members[id];var stats=host.model.stats(id,m.level)
		picture(id,Rect2(x-3,493,94,112),"town-party")
		label(person.name,Rect2(x+2,606,88,22),12,T.INK,T.BOLD);label(person.row+" · "+person["class"],Rect2(x+2,628,88,22),12,T.MUTED,T.DISPLAY)
		resource_numbers(Rect2(x+6,650,78,20),m.hp,stats.hp,true,18);resource("party_hp:"+id,Rect2(x+6,672,78,7),m.hp,stats.hp);resource("party_mp:"+id,Rect2(x+6,682,78,3),m.mp,stats.mp,false)
		rule(690,x,84);hit("town_member:"+id,Rect2(x,493,88,195),func():host.who=id;host.go("status" if id=="persona" else "member"))
	var b=action("depart","원정 준비",Rect2(14,704,362,62),host.go.bind("depart"),true);b.add_theme_color_override("font_color",Color.TRANSPARENT)
	for key in ["font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:b.add_theme_color_override(key,Color.TRANSPARENT)
	var info=host.model.dungeon_rules.floor_info(host.model.selected_floor)
	label("원정 준비 · %d층"%host.model.selected_floor,Rect2(30,709,280,20),12,T.PAPER,T.BOLD)
	display(host.model.dungeon_rules.zones[info.zone].name,Rect2(30,733,290,30),T.PAPER,25);icon("arrow",Rect2(336,725,25,25),T.PAPER)
	action("panels","도감 · 상태",Rect2(14,804,174,48),host.go.bind("codex"));action("town_places","마을 장소",Rect2(202,804,174,48),host.go.bind("places"))
	if host.model.has_method("source_preparation_view"):
		var w=host.model;var y=904.0
		var ui=w.ExpeditionUI.new();ui.lang=L.language(w.s)
		if w.has_method("expedition_defeat_home") and w.expedition_defeat_home() and not w.s.ui.get("msg","").is_empty():
			var message_height=T.BODY.get_multiline_string_size(w.s.ui.msg,HORIZONTAL_ALIGNMENT_LEFT,342,14).y+20
			paragraph(w.s.ui.msg,Rect2(18,y,342,message_height),14,T.INK,false);y+=message_height+16
		var narrative=ui.u("케른 용병단과 마렌토 상인들이 함께 다스리는 도시. 여기서는 어디서 왔는지 캐묻는 사람이 없고, 다들 계약서부터 내민다. 성문 밖으로 옛 학술원 폐허가 보인다.")
		var height=T.BODY.get_multiline_string_size(narrative,HORIZONTAL_ALIGNMENT_LEFT,342,14).y+20
		paragraph(narrative,Rect2(18,y,342,height),14,T.INK,false);y+=height+16
		for p in [
			{"scene":"guild","ic":"pl-guild","name":"연합 길드 본관","d":"의뢰판과 동료 소개 창구"},
			{"scene":"shop","ic":"pl-shop","name":"마렌토 상회","d":"물약(체력, 마나, 보호막), 해독약, 귀환 두루마리"},
			{"scene":"inn","ic":"pl-inn","name":"아랫마을 여관","d":"동료와 이야기하고 식사하고 쉰다"},
			{"scene":"smithy","ic":"pl-smithy","name":"한나의 대장간","d":"장비를 제련하고 가공한다"}]:
			var e=w.source_preparation_view("place",{"place":p})[0]
			y=town_detail_button(e,y,host.go.bind(p.scene))
		var q=w.quest_contract(w.s.quest);var sub=ui.u("길드 의뢰판에서 의뢰를 받으면 나설 수 있다")
		if not q.is_empty():
			sub=ui.u("{title} {stars}, 보상 금화 {gold}",{"title":preload("res://game/guild_rules_r22.gd").title(q,L.language(w.s)),"stars":"★".repeat(int(q.stars)),"gold":w.dungeon_rules.quest_gold(q,w.sortie_quest_summary(q).elv)})+" · "+ui.u("난이도 {difficulty}",{"difficulty":ui.u(w.dungeon_rules.quest_difficulty(q))})
		y=town_detail_button({"text":ui.u("출정"),"sub":sub,"action":"tw_sortie","enabled":not q.is_empty()},y,func():w.set_sortie_mode(0);host._save();host.go("depart"))
		y=town_detail_button({"text":ui.u("대던전 도전"),"sub":ui.u("{best}층까지 도달",{"best":w.s.dungeon_r21.best}),"action":"tw_dungeon","enabled":true},y,func():w.set_sortie_mode(1);host._save();host.go("depart"))
		town_page.custom_minimum_size.y=y+16
		if w.has_method("expedition_defeat_home") and w.expedition_defeat_home():sc.set_deferred("scroll_vertical",90)
	stage=original_stage

func facility_has_news(key: String) -> bool:
	if key!="inn":return false
	var w=host.model
	for id in w.s.owned:
		if not w.TOWN_RULES.inn_act_visible(w.s,"talk",id) or w.s.acts.get(id+"_talk",0)==w.s.day:continue
		var scene=w.dialogue.select_scene(id,w.s.members[id].aff,w.s.dialogue_r21.seen)
		if not scene.is_empty() and w.s.dialogue_r21.seen.get(scene.id,0)==0:return true
	return false

func town_detail_button(e: Dictionary,y: float,callback: Callable) -> float:
	var height=maxf(32,T.BODY.get_multiline_string_size(e.sub,HORIZONTAL_ALIGNMENT_LEFT,326,12).y+12)
	var b=action(e.action,e.text,Rect2(14,y,350,48),callback,false,not e.enabled,false);b.set_meta("expe6_entry",e)
	if e.has("icon"):icon(e.icon.trim_prefix("pl-"),Rect2(22,y+10,28,28))
	fill(e.action+"_description",Rect2(14,y+48,350,height),T.PAPER)
	paragraph(e.sub,Rect2(24,y+48,326,height),12,T.INK,false)
	return y+height+62

func roster() -> void:
	header("동료")
	label("보유 %d명 / 전체 30명"%host.model.s.owned.size(),Rect2(18,66,270,25),13,T.MUTED)
	action("roster_all","도감",Rect2(300,58,72,44),host.go.bind("codex"))
	var ids=host.model.IDS.duplicate()
	if host.model.s.has("persona"):ids=host.model.s.owned.duplicate()
	for p in host.model.config.companions:
		if p.id not in ids and (host.catalog_all or p.id in host.model.s.owned):ids.append(p.id)
	if ids.is_empty():
		icon("party",Rect2(161,224,68,68),T.MUTED)
		display("아직 만난 동료가 없다.",Rect2(28,320,334,60),T.INK,27)
		action("recruit_go","길드에서 동료 소개받기",Rect2(28,419,334,54),host.go.bind("recruit"),true,host.model.active())
		return
	var previous=stage;stage=scroll_page(114,650,maxi(240,ids.size()*112))
	for i in ids.size():
		var id=ids[i];var p=host.model.person(id);var m=host.model.s.members[id];var y=i*112
		picture(id,Rect2(0,y,82,108),"roster")
		label(p.name,Rect2(94,y+12,221,27),20,T.INK,T.BOLD);label(p.row+" · "+p["class"],Rect2(94,y+43,221,23),13,T.MUTED)
		label("Lv.%d"%m.level+(" · 파티 중" if id in host.model.s.party else ""),Rect2(94,y+72,221,21),12,T.MUTED)
		icon("chev",Rect2(318,y+46,18,18),T.QUIET);rule(y+111,0,338)
		hit("member:"+id,Rect2(0,y,338,111),func():host.who=id;host.go("member"))
	stage=previous

func paragraph(value: String,r: Rect2,fs=13,color=T.INK,translate=true) -> Label:
	var l=label(value,r,maxi(14,fs),color,T.BODY,translate); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.size=r.size;metrics[-1].available=r.size.x
	return l

func rule(y: float,x=18.0,width=354.0) -> void: fill("rule:"+str(y),Rect2(x,y,width,1),T.LINE)

func asset(path: String,r: Rect2) -> void:
	var p=TextureRect.new(); stage.add_child(p); p.position=r.position; p.size=r.size
	p.texture=load(path); p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; p.mouse_filter=MOUSE_FILTER_IGNORE

func scroll_page(y: float,height: float,minimum: float) -> Control:
	var sc=ScrollContainer.new(); stage.add_child(sc); sc.position=Vector2(18,y); sc.size=Vector2(354,height)
	T.scroll_region(sc)
	var page=Control.new(); sc.add_child(page); page.custom_minimum_size=Vector2(342,minimum); page.size=page.custom_minimum_size
	return page

func small_party(y: float,tall=false) -> void:
	for i in range(host.model.s.party.size()):
		var id=host.model.s.party[i]; var m=host.model.s.members[id]; var stats=host.model.stats(id,m.level); var x=18+i*91
		picture(id,Rect2(x,y,86,181 if tall else 64),"party-tall" if tall else "town-party-face")
		if tall:
			fill("party_caption:"+id,Rect2(x,y+144,86,37),Color(.067,.09,.08,.92))
			label(host.model.person(id).name,Rect2(x+4,y+145,80,18),12,T.PAPER,T.BOLD)
			label("Lv.%d"%m.level,Rect2(x+4,y+163,80,17),11,T.PAPER)
		else:
			label(host.model.person(id).name,Rect2(x,y+64,86,18),10,T.INK,T.BOLD)
			resource_numbers(Rect2(x,y+82,86,18),m.hp,stats.hp,true,18)
			resource("party_hp:"+id,Rect2(x,y+101,86,9),m.hp,stats.hp)
			resource("party_mp:"+id,Rect2(x,y+113,86,3),m.mp,stats.mp,false)

func departure() -> void:
	nav_top=790
	header("원정 준비")
	plate("preparation-ruins",Rect2(0,48,390,219))
	var w=host.model; var info=w.dungeon_rules.floor_info(w.selected_floor); var zone=w.dungeon_rules.zones[info.zone]
	label("탐사 지역",Rect2(18,54,180,20),11,T.INK,T.BOLD)
	display(zone.name,Rect2(18,74,215,48),T.INK,36)
	display("%d층"%w.selected_floor,Rect2(18,121,150,36),T.RED,29)
	paragraph("탐색 5회 → 휴식 → 층 보스\n출발 시 파티 HP·MP 회복",Rect2(18,161,198,57),12)
	var pick=OptionButton.new(); stage.add_child(pick); pick.position=Vector2(18,224); pick.size=Vector2(190,38); pick.add_theme_font_size_override("font_size",12)
	for f in range(1,w.dungeon_max()+1):
		var z=w.dungeon_rules.floor_info(f); pick.add_item("%d층 · %s"%[f,w.dungeon_rules.zones[z.zone].name],f)
	pick.select(clampi(w.selected_floor-1,0,pick.item_count-1))
	pick.item_selected.connect(func(i):w.selected_floor=i+1;host._draw_screen())
	host.controls.dungeon_floor=pick
	label("출전 파티",Rect2(18,277,210,20),15,T.INK,T.BOLD)
	label("4 / 4",Rect2(334,277,42,20),13)
	small_party(304,true)
	label("전열",Rect2(25,495,150,23),14,T.INK,T.BOLD); label("후열",Rect2(213,495,150,23),14,T.INK,T.BOLD)
	for i in range(4):
		var x=[25,105,213,293][i]; var id=w.s.party[i]
		picture(id,Rect2(x,520,71,67),"formation-face")
		hit("departure_member:"+id,Rect2(x,520,71,67),func():host.who=id;host.go("formation"))
	rule(599)
	label("원정 경로",Rect2(18,602,200,24),15,T.INK,T.BOLD)
	for i in range(3):
		var x=18+i*122
		fill("route_bg"+str(i),Rect2(x,631,110,61),T.INK)
		icon(["gate","inn","shield"][i],Rect2(x+8,638,24,24),T.PAPER)
		label(["탐색 5회","휴식","층 보스"][i],Rect2(x+5,665,100,20),12,T.PAPER,T.BOLD)
	if w.s.quest.is_empty(): paragraph("휴식에서는 HP 30% · MP 60%를 회복합니다.\n층 도중 얻은 보상은 귀환할 때 정산합니다.",Rect2(18,699,354,42),12)
	action("start_run","선택한 층으로 출발",Rect2(18,747,354,39),func():host._act(w.depart_dungeon.bind(w.selected_floor),"");host.go("explore"),true)
	# An accepted rift quest has its own explicit departure; it never silently
	# changes the selected dungeon floor or rewards a normal dungeon clear.
	if not w.s.quest.is_empty():
		action("accepted_quest","수락한 균열 의뢰로 출발",Rect2(18,699,354,43),func():host._act(w.depart_accepted_quest,"");host.go("explore"),true)

func bag() -> void:
	if not host.selected_item.is_empty(): target_item(); return
	header("가방")
	for i in range(3):
		var key=["bag","equipment","cards"][i]
		action("bag_tab:"+key,["보급품","장비","탐색 카드"][i],Rect2(18+i*118,65,118,38),host.go.bind("inventory" if key=="equipment" else key),i==0)
	var prev=stage; stage=scroll_page(117,636,host.model.config.items.size()*116)
	for i in range(host.model.config.items.size()):
		var it=host.model.config.items[i]; var y=i*116
		asset("res://assets/ic_"+it.icon+".webp",Rect2(0,y+8,73,82))
		display(it.name,Rect2(87,y+6,170,30),T.INK,20)
		label("× %d"%host.model.s.items[it.id],Rect2(278,y+8,60,28),18,T.INK,T.BOLD)
		paragraph(host._item_text(it),Rect2(87,y+38,172,58),11)
		action("item:"+it.id,"사용",Rect2(274,y+56,64,39),func():host.selected_item=it.id;host.selected_target="";host._draw_screen(),true,host.model.s.items[it.id]<1)
		rule(y+110,0,338)
	stage=prev

func target_item() -> void:
	header("대상 선택","bag")
	var w=host.model; var it=w.item_def(host.selected_item)
	asset("res://assets/ic_"+it.icon+".webp",Rect2(3,62,88,83))
	display(it.name,Rect2(103,65,220,29),T.INK,24)
	paragraph(host._item_text(it),Rect2(103,99,210,47),12)
	label("× %d"%w.s.items[it.id],Rect2(324,110,62,36),24,T.INK,T.BOLD)
	rule(154,3,372);label("대상 선택" if host.message.is_empty() else host.message,Rect2(3,165,372,27),15,T.INK,T.BOLD)
	for i in range(w.s.party.size()):
		var id=w.s.party[i]; var y=199+i*109; var m=w.s.members[id]; var p=w.item_preview(it.id,id)
		var selected=host.selected_target==id
		var b=action("target:"+id,"",Rect2(3,y,372,99),func():host.selected_target=id;host._draw_screen(),false,not p.usable)
		b.add_theme_stylebox_override("normal",T.panel(Color("f9e6d5") if selected else T.PAPER,T.RED if selected else T.LINE))
		picture(id,Rect2(42,y+3,88,93),"target-face")
		label(host.model.person(id).name,Rect2(140,y+11,180,22),17,T.INK,T.BOLD)
		label("Lv.%d"%m.level,Rect2(290,y+12,73,20),11)
		if p.get("resource","HP") in ["HP","MP"]:
			resource_numbers(Rect2(142,y+41,136,25),p.get("before",0),p.get("maximum",0),p.get("resource","HP")=="HP")
			resource("target_meter:"+id,Rect2(143,y+70,136,9 if p.get("resource","HP")=="HP" else 3),p.get("before",0),p.get("maximum",0),p.get("resource","HP")=="HP")
		else:
			label("%s  %s / %s"%[p.get("resource","HP"),host.number(p.get("before",0)),host.number(p.get("maximum",0))],Rect2(142,y+45,214,21),12,T.INK,T.BOLD)
			fill("target_meter:"+id,Rect2(143,y+72,136*float(p.get("before",0))/maxf(1,p.get("maximum",1)),6),T.RED)
		label("→ "+host.number(p.get("after",0)),Rect2(292,y+59,75,24),15,T.INK,T.BOLD)
		b.tooltip_text=p.reason if not p.usable else "이 동료 선택"
	var p=w.item_preview(it.id,host.selected_target)
	action("use_selected","사용",Rect2(3,640,372,51),func():host._act(w.use_item.bind(it.id,host.selected_target),"보급품을 사용했습니다."),true,not p.usable)
	action("item_cancel","취소",Rect2(3,701,372,44),func():host.selected_item="";host.selected_target="";host._draw_screen())

func formation() -> void:
	header("편성 · 장비","member")
	traced_title("formation",Rect2(18,50,209,46))
	asset("res://assets/src/academy.png",Rect2(18,101,354,261))
	for i in range(4):
		var id=host.model.s.party[i]; var x=52+(i%2)*177; var y=105+int(i/2)*127
		var sprite=host.CharacterSprite.new();stage.add_child(sprite);sprite.position=Vector2(x,y);sprite.size=Vector2(107,103);sprite.configure(id,false)
		fill("formation_caption:"+str(i),Rect2(x,y+76,107,27),T.INK)
		label(host.model.person(id).name,Rect2(x+5,y+77,97,25),12,T.PAPER,T.BOLD)
		action("formation:"+str(i),("전열" if i<2 else "후열")+" · 선택",Rect2(x,y+105,107,24),func():host._act(host.model.assign.bind(host.who,i),"편성을 변경했습니다."),false,host.model.active() or host.model.person(host.who).row!=("전열" if i<2 else "후열") or id==host.who).add_theme_font_size_override("font_size",11)
	display(host.model.person(host.who).name,Rect2(18,395,354,40),T.INK,32)
	label(host.model.person(host.who).row+" · "+host.model.person(host.who)["class"],Rect2(18,439,354,25),14)
	var prev=stage; stage=scroll_page(477,202,ceil(host.model.s.owned.size()/4.0)*97)
	for i in range(host.model.s.owned.size()):
		var id=host.model.s.owned[i];var x=(i%4)*85; var y=int(i/4)*97
		picture(id,Rect2(x,y,79,72),"formation-face"); label(host.model.person(id).name,Rect2(x,y+73,79,21),10)
		hit("formation_pick:"+id,Rect2(x,y,79,95),func():host.who=id;host._draw_screen())
	stage=prev
	action("gear_for_member","선택한 동료의 장비 관리",Rect2(18,701,354,45),host.go.bind("equipment"),true,host.model.active())

func exploration() -> void:
	var w=host.model; var r=w.s.run
	if r.phase=="rest":
		traced_title("rest",Rect2(18,39,216,54))
		# Reuse the unmodified C portrait crops; never redraw the source party.
		for i in range(w.s.party.size()):picture(w.s.party[i],Rect2(12+i*94,273,94,171),"party-tall")
	else:
		traced_title("explore",Rect2(18,0,186,66))
		var map=preload("res://ui/town_map_r21.gd").new();stage.add_child(map);map.position=Vector2(18,119);map.size=Vector2(354,338);map.configure(r,int(w.dungeon_rules.config.explore.STEPS))
		mark("source_progress_map",map)
	display(w.dungeon_title(),Rect2(18,8 if r.phase=="rest" else 69,354,26),T.INK,16 if r.phase=="rest" else 21)
	fill("explore_status_paper",Rect2(12,457,366,25),T.PAPER)
	label("파티 HP 30% · MP 60% 회복 완료" if r.phase=="rest" else r.last if r.last!="入場" else "층의 입구에 도착했다.",Rect2(18,458,354,24),12)
	small_party(490)
	label("금화 %d · 경험치 %d · 탐색 %d/5"%[r.gold,r.xp,r.step],Rect2(18,613,354,25),14,T.INK,T.BOLD)
	if r.phase=="rest":
		action("final_battle","층 보스에게 도전",Rect2(18,650,354,44),func():host._act(w.final_battle,""),true)
	else:
		action("advance","탐색",Rect2(18,650,354,44),func():host._act(w.advance,""),true)
	action("dungeon_bag","보급품",Rect2(18,705,108,41),host.go.bind("bag"))
	action("cards","카드",Rect2(136,705,108,41),host.go.bind("cards"))
	action("retreat","귀환",Rect2(254,705,118,41),func():host._ask("금화 %d · 경험치 %d를 정산하고 귀환할까요?"%[r.gold,r.xp],w.settle.bind("retreat")))

func cards() -> void:
	header("탐색 카드","explore" if host.model.active() else "bag")
	picture(host.model.s.party[0] if not host.model.s.party.is_empty() else host.model.s.owned[0],Rect2(160,53,230,275 if not host.model.s.hand.is_empty() else 300),"town-main")
	if host.model.s.hand.is_empty():
		T.torn(stage,335)
		display("보유 중인 카드가 없습니다",Rect2(18,390,354,70),T.INK,25)
		paragraph("카드를 얻으면 이곳에서 확인할 수 있습니다.",Rect2(18,474,354,66),14)
	else:
		display("탐색 카드",Rect2(18,331,354,45),T.INK,31)
		for i in range(2):
			var id=["key","camp"][i]; var count=host.model.s.hand.count(id)
			if count==0: continue
			var c=host.model.card_def(id);var x=18+i*182
			fill("card_panel:"+id,Rect2(x,389,172,237),T.PALE)
			plate("card-"+id,Rect2(x+10,391,152,108))
			display(c.name,Rect2(x+10,503,152,32),T.INK,23)
			label("× %d"%count,Rect2(x+10,536,152,28),22,T.INK,T.BOLD)
			paragraph(c.text,Rect2(x+10,570,152,62),14,T.INK)
			var reason=host.model.card_reason(id)
			action("card:"+id,"카드 사용",Rect2(x,640,172,43),func():host._ask(c.name+" 카드 1장을 소모할까요?",host.model.use_card.bind(id)),true,not reason.is_empty()).tooltip_text=reason
	action("cards_back","원정으로" if host.model.active() else "가방으로",Rect2(18,560 if host.model.s.hand.is_empty() else 701,354,48),host.go.bind("explore" if host.model.active() else "bag"),true)

func retreat() -> void:
	header("원정","explore")
	fill("return_sheet",Rect2(0,389,390,371),T.PAPER)
	traced_title("retreat",Rect2(18,391,298,42))
	paragraph("지금까지 모은 보상을 정산합니다.\n계속 탐색하려면 취소를 누르세요.",Rect2(18,445,354,51),14)
	for i in range(2):
		var y=515+i*67
		icon("shop" if i==0 else "sword",Rect2(22,y+4,39,39))
		label("금화" if i==0 else "동료별 경험치",Rect2(74,y,184,42),17,T.INK,T.BOLD)
		display(str(int(host.model.s.run.gold if i==0 else host.model.s.run.xp)),Rect2(265,y,104,45),T.RED,35)
		rule(y+54)
	action("cancel","계속 탐색",Rect2(18,676,170,48),func():host.confirm={};host._draw_screen())
	action("accept","귀환 · 정산",Rect2(200,676,172,48),host._accept,true)

func npc_hero(id: String,title: String,subtitle: String,height=365.0) -> void:
	# The left title lane and right figure never share a bounding box.
	var parts=subtitle.split("\n",true,1)
	var rows=host.model.source_npc_rows([[id,parts[0] if not subtitle.is_empty() else id,parts[1] if parts.size()>1 else ""]])
	if not rows.is_empty():picture(id,Rect2(170,65,220,height-65),"hero")
	var titles={"guild":"의뢰","recruit":"동료 소개","research":"전술 연구","shop":"마렌토 상회","smithy":"한나의 대장간","inn":"여관"}
	var title_copy=localized(titles.get(host.screen,title))
	if L.language(host.model.s)!="en":title_copy=title_copy.replace(" ","\n")
	var heading=label(title_copy,Rect2(18,83,148,120),32,T.INK,T.DISPLAY,false)
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;heading.size=Vector2(148,120);mark("title:"+host.screen,heading)
	if not subtitle.is_empty() and not rows.is_empty():
		fill("npc_caption",Rect2(18,height-90,148,87),T.INK)
		var caption=label(rows[0].name+"\n"+rows[0].role,Rect2(28,height-85,128,77),12,T.PAPER,T.BOLD)
		caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.set_meta("source_npc_caption",true)

func research() -> void:
	if host.research_edit:research_editor();return
	header("전술 연구","guild")
	npc_hero("loredana","전술\n연구","",430)
	paragraph("더 날카롭게,\n더 멀리.",Rect2(18,250,130,43),14)
	var edit=action("research_editor","조각 조합 · 편집 후 저장",Rect2(18,309,144,68),func():host.research_edit=true;host.who="persona" if host.model.s.has("persona") else host.who;host._draw_screen());edit.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;edit.add_theme_font_size_override("font_size",14)
	member_choice(Rect2(18,398,354,38))
	var w=host.model;var r=w.s.research[host.who];var current=w.tactic(host.who)
	guild_tabs(2)
	for index in range(2):
		var kind="prefixes" if index==0 else "suffixes";var parts=[]
		for part in w.research[kind]:
			if index==0 or w.compatible(host.research_prefix,part.id):parts.append(part)
		var pick=OptionButton.new();stage.add_child(pick);pick.position=Vector2(18+index*182,504);pick.size=Vector2(172,56);pick.fit_to_longest_item=false;pick.clip_text=true;pick.add_theme_font_size_override("font_size",12)
		for part in parts:pick.add_item(localized(part.name+" · "+part.note))
		for i in range(parts.size()):
			if parts[i].id==(host.research_prefix if index==0 else host.research_suffix):pick.select(i)
		pick.item_selected.connect(func(i):
			if index==0:
				host.research_prefix=parts[i].id
				for suffix in w.research.suffixes:
					if w.compatible(host.research_prefix,suffix.id):host.research_suffix=suffix.id;break
			else:host.research_suffix=parts[i].id
			host._draw_screen())
		host.controls["research_part:"+kind]=pick
	icon("skill-attack",Rect2(25,570,65,57));icon("skill-taunt",Rect2(210,570,65,57))
	paragraph("장착 · "+current.get("name","없음 · 기본 방어 사용"),Rect2(18,632,354,34),13)
	action("compose","이 조합 장착 · 무료",Rect2(18,681,224,44),func():host._act(w.compose.bind(host.who,host.research_prefix,host.research_suffix),"전술을 장착했습니다."),true)
	action("research_clear","전술 해제",Rect2(252,681,120,44),func():w.s.research[host.who].prefix="";w.s.research[host.who].suffix="";host._save();host._draw_screen(),false,w.active())
	for i in range(2):
		var kind="prefix" if i==0 else "suffix"
		if r[kind].is_empty():continue
		var level=r[kind+"_lv"].get(r[kind],0);var amount=w.PersonaResearch.cost(level+1)
		action("train:"+kind,("몸통" if i==0 else "덧효과")+" +%d · %d금화"%[level,amount],Rect2(18+i*182,730,172,29),func():host._ask("금화를 소모해 전술 조각을 강화할까요?",w.train.bind(host.who,kind)),false,level>=10 or w.s.gold<amount).add_theme_font_size_override("font_size",11)

func research_editor() -> void:
	nav_top=790
	header("전술 연구","guild")
	npc_hero("loredana","전술\n연구","",430)
	paragraph("몸통과 덧효과를 고른 뒤 저장하세요.\n바꾸기는 무료, 강화는 조각에 남습니다.",Rect2(18,222,144,120),14)
	action("research_legacy","동료 전술 관리",Rect2(18,348,144,44),func():host.research_edit=false;host.who=host.model.s.owned[0] if not host.model.s.owned.is_empty() else host.who;host._draw_screen(),false,host.model.s.owned.is_empty())
	if host.model.s.has("persona"):
		host.who="persona"
		fill("persona_research_owner",Rect2(18,398,354,38),T.PAPER)
		label(host.model.person("persona").name,Rect2(18,398,354,38),16)
	else:member_choice(Rect2(18,398,354,38))
	guild_tabs(2)
	var w=host.model;var rules=w.PersonaResearch;var v=w.research_work(host.who)
	for index in range(2):
		var kind="prefixes" if index==0 else "suffixes";var parts=[]
		for x in rules.data[kind]:
			if index==0 or rules.compatible(rules.part("prefixes",v.prefix),x):parts.append(x)
		var pick=OptionButton.new();stage.add_child(pick);pick.position=Vector2(18+index*182,502);pick.size=Vector2(172,44)
		pick.fit_to_longest_item=false;pick.clip_text=true;pick.add_theme_font_size_override("font_size",13)
		pick.add_item("몸통을 고르세요" if index==0 else "덧효과를 고르세요")
		for i in range(parts.size()):
			var x=parts[i];var key="prefix" if index==0 else "suffix"
			pick.add_item(localized(x.name)+" +%d"%rules.level(v[key+"_lv"],x.id))
			if x.id==v[key]:pick.select(i+1)
		pick.set_item_disabled(0,true)
		pick.disabled=w.active() or (index==1 and v.prefix.is_empty())
		pick.item_selected.connect(func(i):
			if i>0:_research_action("ps_"+("pre_" if index==0 else "suf_")+parts[i-1].id))
		host.controls["ps_part:"+kind]=pick;mark("ps_part:"+kind,pick)
	var dirty=w.research_dirty(host.who)
	label(("편집 중 · " if dirty else "현재 스킬 · ")+rules.skill_name(v),Rect2(18,553,354,26),15,T.INK,T.BOLD)
	paragraph(rules.description(v),Rect2(18,584,354,65),12)
	for i in range(2):
		var key="prefix" if i==0 else "suffix";var id=v[key];var n=rules.level(v[key+"_lv"],id)
		var amount=rules.cost(n+1)
		var caption=("몸통" if i==0 else "덧효과")+(" · 최대 +10" if n>=10 else " +%d · %d금화"%[n,amount])
		action("ps_up:"+key,caption,Rect2(18+i*182,655,172,44),_research_action.bind("ps_up_"+("pre" if i==0 else "suf")),false,w.active() or id.is_empty() or n>=10 or w.s.gold<amount).add_theme_font_size_override("font_size",12)
	label("금화 %d · 강화 비용은 즉시 소모됩니다."%w.s.gold,Rect2(18,700,354,22),11)
	action("ps_save","저장 · 조합 확정",Rect2(18,727,354,44),_research_action.bind("ps_save"),true,w.active() or not dirty or not rules.ready(v))

func _research_action(arg: String) -> void:
	var changed=host.model.research_action(host.who,arg)
	if changed:host._save()
	host.message="조합을 저장했습니다." if changed and arg=="ps_save" else ""
	host._draw_screen()

func cache() -> void:
	var w=host.model;var r=w.s.run
	header("원정","depart")
	traced_title("cache",Rect2(18,45,252,54))
	small_party(490)
	label("미정산 금화 %d · 경험치 %d"%[r.gold,r.xp],Rect2(18,608,354,25),14,T.INK,T.BOLD)
	if not r.resolved:
		action("unlock","봉인 해제 카드 사용",Rect2(18,642,354,40),func():host._ask("카드 1장을 소모해 회복약을 얻을까요?",w.use_card.bind("key")),true,not w.card_reason("key").is_empty())
		action("leave_cache","열지 않고 지나가기",Rect2(18,691,224,40),func():host._act(w.leave_cache,"보관함을 지나쳤습니다."))
	elif w.mapped():
		var choices=w.destinations()
		for i in range(choices.size()):
			var id=choices[i]
			action("travel:"+id,w.Route.NODES[id].name,Rect2(18+i*177,642,170,40),func():host._act(w.travel.bind(id),""),true)
	else:action("advance","다음 구역 탐색",Rect2(18,642,354,40),func():host._act(w.advance,""),true)
	var cards_button=action("cards","탐색 카드",Rect2(18,735,170,23),host.go.bind("cards"));cards_button.add_theme_font_size_override("font_size",11)
	for state in ["normal","hover","pressed"]:cards_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	action("retreat","귀환",Rect2(252,691,120,40),func():host._ask("모은 보상을 정산할까요?",w.settle.bind("retreat")))

func feedback(y=715.0) -> void:
	if not host.message.is_empty(): paragraph(host.message,Rect2(18,y,354,40),12)

func member_choice(r: Rect2) -> void:
	if host.who not in host.model.s.owned:host.who=host.model.s.owned[0]
	var pick=OptionButton.new();stage.add_child(pick);pick.position=r.position;pick.size=r.size
	pick.fit_to_longest_item=false;pick.clip_text=true
	for id in host.model.s.owned:pick.add_item(localized(host.model.person(id).name+" · "+host.model.person(id)["class"]))
	pick.select(host.model.s.owned.find(host.who));pick.item_selected.connect(func(i):
		host.who=host.model.s.owned[i]
		if host.screen=="inn" and host.model.has_method("inn_action"):host.model.inn_action("pick_"+host.who,host.screen);host._save()
		host._draw_screen())
	host.controls.member_choice=pick

func inn() -> void:
	header("아랫마을 여관");npc_hero("dorothea","여관","도로테아\n여관 주인",310)
	label("함께하는 동료",Rect2(18,320,180,30),13,T.INK,T.BOLD);member_choice(Rect2(208,320,164,44))
	picture(host.who,Rect2(18,369,106,106),"inn-companion")
	display(host.model.person(host.who).name,Rect2(142,373,222,31),T.INK,24)
	label(host.model.person(host.who)["class"],Rect2(142,408,222,23),12)
	var aff=host.model.s.members[host.who].aff
	label("%s · 호감 %s / 200"%[host.model.TOWN_RULES.guild_tier(aff),host.model.TOWN_RULES.aff_fmt(floor(aff))],Rect2(142,437,222,24),12,T.MUTED,T.BOLD)
	fill("aff_track",Rect2(142,469,222,4),T.LINE);fill("aff_value",Rect2(142,469,222*maxf(0,aff)/200,4),T.MUTED)
	label(host.message if not host.message.is_empty() else "함께, 더 깊은 곳으로.",Rect2(18,481,354,24),15,T.INK,T.BOLD)
	var acts=host.model.TOWN_RULES.DATA.inn
	for i in 4:
		var key=["talk","meal","gift","rest"][i];var e=acts[key];var y=504+i*51
		if not host.model.TOWN_RULES.inn_act_visible(host.model.s,key,host.who):continue
		var used=not e.day and host.model.s.acts.get(host.who+"_"+key,0)==host.model.s.day
		var callback=func():
			if not host.model.has_method("inn_action"):
				host._act(host.model.begin_inn_talk.bind(host.who) if key=="talk" else host.model.inn.bind(host.who,key),"");return
			if host.model.inn_action(key+"_"+host.who,host.screen):host._save()
			host.message=host.model.s.ui.msg;host._draw_screen()
		var b=action("inn:"+key,"",Rect2(18,y,354,48),callback,i==0,used or host.model.s.gold<e.cost)
		var color=T.PAPER if i==0 and not used else T.INK
		icon(["book","shop","bag","inn"][i],Rect2(28,y+14,22,22),color)
		label(e.name,Rect2(66,y+7,190,36),15,color,T.BOLD)
		var inn_status=label("오늘은 이미 했다" if used else "무료" if e.cost==0 else "금화 %d"%e.cost,Rect2(267,y+7,92,36),12,color if i==0 and not used else T.MUTED,T.BOLD);inn_status.set_meta("inn_status",true)
	paragraph("대화·식사·선물은 동료마다 하루 한 번.\n곁에서 쉬면 하루가 지납니다.",Rect2(18,713,354,46),14)
	feedback(306)

func shop() -> void:
	header("상회")
	npc_hero("pietro","마렌토\n상회","",365)
	paragraph("여행자의 여정에\n필요한 모든 것.",Rect2(18,210,150,46),14)
	label("보유 금화",Rect2(18,302,130,22),12,T.INK,T.BOLD)
	display(str(int(host.model.s.gold)),Rect2(18,327,125,37),T.RED,31)
	for i in range(2):
		action(["shop_items","shop_equipment"][i],["보급품","직업 장비"][i],Rect2(18+i*177,378,177,40),func():host.shop_tab="items" if i==0 else "gear";host._draw_screen(),(host.shop_tab=="items")==bool(i==0))
	if host.shop_tab=="gear":shop_gear();return
	var rows=host.model.config.items.duplicate()
	if host.model.s.items.get("charm_potion",0)>0:rows.append({"id":"charm_potion","name":"매혹의 비약","nosale":true})
	var prev=stage;stage=scroll_page(432,270,rows.size()*107)
	for i in range(rows.size()):
		var item=rows[i];var y=i*107
		if item.get("nosale",false):
			label(item.name,Rect2(12,y+14,260,27),16,T.INK,T.BOLD)
			label("보유 %d"%host.model.s.items[item.id],Rect2(12,y+52,260,24),13)
			rule(y+103,0,342);continue
		asset("res://assets/ic_"+item.icon+".webp",Rect2(0,y,90,92))
		label(item.name,Rect2(100,y+4,155,24),14,T.INK,T.BOLD)
		paragraph(host._item_text(item),Rect2(100,y+30,150,52),11)
		label("금화 %d"%host.model.price(item),Rect2(261,y+5,80,24),14,T.RED,T.BOLD)
		action("buy:"+item.id,"구입",Rect2(261,y+43,80,39),func():
			if host.model.has_method("shop_action"):
				host._act(host.model.shop_action.bind("buy_"+host.model.source_item_id(item.id),"shop"),"구입했습니다.")
			else:host._act(host.model.buy.bind(item.id),"구입했습니다."),true,host.model.s.gold<host.model.price(item))
		label("보유 %d"%host.model.s.items[item.id],Rect2(100,y+82,150,19),10)
		rule(y+103,0,342)
	stage=prev;feedback();action("shop_bag","가방과 장비 확인",Rect2(18,705,354,43),host.go.bind("equipment"))

func dialogue_frame(who: String,title: String) -> void:
	fill("dialogue_paper",Rect2(0,0,390,844),T.PAPER);background("inn",Rect2(0,0,390,470));boxes["background:inn"].modulate.a=.38
	picture(who,Rect2(91,33,300,432),"dialogue-main")
	display(title,Rect2(18,20,255,58),T.INK,44)
	label("%d일째 · 금화 %d"%[host.model.s.day,host.model.s.gold],Rect2(18,83,280,24),13,T.MUTED,T.BOLD)
	var ids=host.model.s.party.duplicate()
	if who not in ids:ids.push_front(who)
	for i in mini(4,ids.size()):
		picture(ids[i],Rect2(14,120+i*64,54,59),"dialogue-chip")
		if ids[i]==who:fill("dialogue_chip_active",Rect2(22,178+i*64,38,3),T.RED)
	fill("dialogue_identity_paper",Rect2(14,384,362,68),T.INK)
	display(host.model.person(who).name,Rect2(30,393,300,30),T.PAPER,25)
	var a=host.model.s.members[who].aff
	label(host.model.TOWN_RULES.aff_stage(a)+" · 호감 "+host.model.TOWN_RULES.aff_fmt(a),Rect2(30,426,300,22),12,Color("c9bfae"),T.BOLD)
	fill("dialogue_body",Rect2(0,452,390,392),T.PAPER)

func inn_dialogue() -> void:
	var state=host.model.s.dialogue_r21;var responding=not state.response.is_empty()
	var p=state.response if responding else state.pending
	var row=host.model.dialogue.scene(p.who,p.scene)
	dialogue_frame(p.who,"대화")
	var previous=stage;stage=scroll_page(466,221,221);var content=stage;var y=0.0
	if row.is_empty() and not responding:
		y=reading_line("이 대화의 기록을 찾을 수 없습니다.",y,16)
		stage=previous;action("dialogue_cancel","여관으로",Rect2(18,699,354,56),func():state.pending={};host._save();host.go("inn"),true);navigation();return
	if responding:
		y=reading_line(p.text,y,14,T.INK,false)
		y=reading_line("\n".join(p.lines),y,18,T.INK,false)
		y=reading_line("호감 %s → %s (%s%s)"%[host.number(p.before),host.number(p.after),"+" if p.gained>=0 else "",host.number(p.gained)],y,14,T.RED)
		var t=p.transition
		if not t.is_empty():
			y=reading_line(localized(t.from)+" → "+localized(t.to),y,16,T.RED)
			y=reading_line(t.situation+"\n"+"\n".join(t.lines),y,15,T.INK,false)
		content.custom_minimum_size.y=maxf(351,y+16);stage=previous
		action("dialogue_done","여관으로",Rect2(18,699,354,56),func():host.model.close_dialogue();host._save();host.go("inn"),true)
	else:
		y=reading_line(row.situation,y,14,T.INK,false)
		var lines=[row.seen] if state.seen.get(row.id,0)>0 else row.lines
		y=reading_line("\n".join(lines),y,18,T.INK,false)
		y=reading_line("어떻게 답할까",y,14)
		for i in range(row.choices.size()):
			var c=row.choices[i]
			var height=maxf(58,T.BOLD.get_multiline_string_size(L.authored_display(c.text,host.model.s),HORIZONTAL_ALIGNMENT_LEFT,288,15).y+24)
			var b=action("dialogue_choice:"+c.id,c.text,Rect2(0,y,342,height),func():host._act(host.model.choose_dialogue.bind(c.id),""),false,false,false)
			b.set_meta("authored_copy",true)
			b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.add_theme_font_size_override("font_size",15)
			T.dress_button(b);b.alignment=HORIZONTAL_ALIGNMENT_LEFT;T.row_arrow(b);y+=height+8
		content.custom_minimum_size.y=maxf(351,y+16);stage=previous
		action("dialogue_cancel","나중에 이야기하기",Rect2(18,699,354,56),func():state.pending={};host._save();host.go("inn"))
	navigation()

## Measured reading rows for the remaining long town/expedition screens.
func authored_english_height(copy: String,width: float,fs: int) -> float:
	var measured=T.BODY.get_multiline_string_size(copy,HORIZONTAL_ALIGNMENT_LEFT,width,fs).y
	var lines=maxi(1,ceili(measured/T.BODY.get_height(fs)))
	return measured+(lines-1)*get_theme_constant("line_spacing","Label")+16

func reading_line(value: String,y: float,fs=15,color=T.INK,translate=true) -> float:
	var copy=localized(value) if translate else L.authored_display(value,host.model.s)
	var height=ceilf(T.BODY.get_multiline_string_size(copy,HORIZONTAL_ALIGNMENT_LEFT,342,fs).y*1.25)+24
	if not translate and L.language(host.model.s)=="en":height=authored_english_height(copy,342,fs)
	var line=paragraph(value,Rect2(0,y,342,height),fs,color,translate)
	height=maxf(height,line.get_line_count()*line.get_line_height()+10);line.size.y=height
	if not translate:line.set_meta("authored_copy",true)
	return y+height+12

func journey_dialogue() -> void:
	var rows=host.model.s.dialogue_r21.queue
	fill("journey_paper",Rect2(0,0,390,844),T.PAPER)
	display("함께 걷는 길",Rect2(18,35,354,57),T.INK,39)
	var previous=stage;stage=scroll_page(118,581,rows.size()*172)
	var content=stage;var y=0.0
	var english=L.language(host.model.s)=="en"
	for i in range(rows.size()):
		var row=rows[i]
		picture(row.who,Rect2(0,y,77,104),"target-face")
		label(host.model.person(row.who).name,Rect2(93,y,248,26),18,T.INK,T.BOLD)
		var text="\n".join(row.lines)
		if row.kind=="transition":text=localized(row.from)+" → "+localized(row.to)+"\n"+row.situation+"\n"+text
		var copy=L.authored_display(text,host.model.s) if english else text
		var height=maxf(133,authored_english_height(copy,248,15)) if english else 133.0
		paragraph(copy,Rect2(93,y+32,248,height),15,T.INK,false).set_meta("authored_copy",true)
		y+=maxf(172,32+height+8) if english else 172.0
	if english:content.custom_minimum_size.y=maxf(rows.size()*172,y+8)
	stage=previous
	action("dialogue_continue","계속",Rect2(18,748,354,58),func():host.model.dismiss_dialogue_queue();host._save();host._draw_screen(),true)

func shop_gear() -> void:
	member_choice(Rect2(18,427,354,38))
	for i in range(3):
		var key=["weapon","armor","acc"][i]
		action("shop_slot:"+key,host.model.Gear.SLOT[key],Rect2(18+i*118,471,118,38),func():host.gear_filter=key;host._draw_screen(),host.gear_filter==key)
	var ids=host.model.shop_stock(host.who,host.gear_filter)
	var prev=stage;stage=scroll_page(521,175,maxi(130,ids.size()*118))
	for i in range(ids.size()):
		var row=ids[i];var id=row.id;var item=host.model.gear.by_id[id];var y=i*118
		icon("sword" if host.gear_filter=="weapon" else "shield",Rect2(8,y+12,56,65))
		label(item.name,Rect2(78,y+3,260,25),15,T.INK,T.BOLD)
		paragraph(host._gear_caption(item),Rect2(78,y+31,260,32),11)
		var cost=host.model.price({"price":row.price});var sold=host.model.stock_sold(row.code)
		action("buygear:"+id,"품절" if sold else "구입 · 금화 %d"%cost,Rect2(78,y+68,260,39),func():host._act(host.model.buy_gear.bind(row.code,host.who),"장비를 구입했습니다."),true,sold or host.model.s.gold<cost)
		rule(y+115,0,342)
	stage=prev;action("shop_bag","보유 장비 확인",Rect2(18,705,354,43),host.go.bind("equipment"))

func guild_tabs(selected: int) -> void:
	for i in range(3):
		var key=["guild","recruit","research"][i]
		action("guild:"+key,["의뢰판","동료 소개","전술 연구"][i],Rect2(18+i*118,447,118,40),host.go.bind(key),selected==i)

func guild() -> void:
	header("연합 길드 본관")
	npc_hero("fenella","의뢰","페넬라\n길드 접수",430)
	guild_tabs(0)
	var w=host.model;var board=w.s.board if w.s.quest.is_empty() else [w.s.quest]
	var prev=stage;stage=scroll_page(503,196,board.size()*144)
	for i in range(board.size()):
		var q=board[i];var c=w.quest_contract(q);var y=i*144
		label(c.difficulty+" · Lv.%d"%c.lv,Rect2(0,y,342,20),12,T.RED,T.BOLD)
		display(q.name,Rect2(0,y+23,342,30),T.INK,23)
		label(q.rift,Rect2(0,y+57,342,20),12)
		label("보수 금화 %d"%w.dungeon_rules.quest_gold(c,c.lv),Rect2(0,y+81,185,24),14,T.RED,T.BOLD)
		if w.s.quest.is_empty():action("quest:"+str(int(q.id)),"의뢰 수락",Rect2(205,y+82,137,40),func():host._act(w.accept_quest.bind(q.id),"의뢰를 수락했습니다."),true)
		else:
			action("quest_depart","출발",Rect2(205,y+81,137,40),func():host._act(w.depart_accepted_quest,"");host.go("explore"),true)
			action("quest_abandon","포기",Rect2(0,y+109,91,30),func():host._ask("현재 의뢰를 포기할까요?",w.abandon_quest))
		rule(y+142,0,342)
	stage=prev
	action("refresh_board","게시판 갱신 · 금화 %d"%w.refresh_fee(),Rect2(18,709,354,40),func():host._act(w.refresh_board,"게시판을 갱신했습니다."),true,w.s.gold<w.refresh_fee())

func recruit() -> void:
	header("연합 길드 본관","guild")
	npc_hero("fenella","동료\n소개","페넬라\n소개 창구",430)
	guild_tabs(1)
	var w=host.model
	display("%d / 30명"%w.s.owned.size(),Rect2(18,503,354,49),T.INK,37)
	fill("roster_track",Rect2(18,564,354,7),T.LINE);fill("roster_value",Rect2(18,564,354*w.s.owned.size()/30.0,7),T.RED)
	paragraph("아직 동료가 아닌 사람 가운데 한 명을\n소개받으면 바로 동료가 됩니다.",Rect2(18,590,354,49),15)
	label("보유 금화 %d"%w.s.gold,Rect2(18,656,354,25),16,T.INK,T.BOLD)
	label("합류 레벨 · 당신의 Lv.%d"%w.persona_level(),Rect2(18,629,354,23),12)
	action("recruit","소개받기 · 금화 %d"%w.recruit_fee(),Rect2(18,705,354,44),func():host._act(w.recruit,"");host.message=w.s.log[-1];host._draw_screen(),true,w.s.gold<w.recruit_fee() or w.s.owned.size()==30)
	feedback(674)

func equipment() -> void:
	header("편성 · 장비","formation")
	plate("preparation-ruins",Rect2(0,48,390,150))
	picture(host.who,Rect2(0,128,163,300),"detail-overview")
	traced_title("equipment",Rect2(18,50,209,46))
	member_choice(Rect2(168,200,204,38))
	var m=host.model.s.members[host.who];var stats=host.model.stats(host.who,m.level)
	label("Lv.%d · %s"%[m.level,host.model.person(host.who).row],Rect2(168,247,204,23),13,T.INK,T.BOLD)
	resource_numbers(Rect2(168,270,204,23),m.hp,stats.hp)
	resource("equipment_hp",Rect2(168,296,204,9),m.hp,stats.hp)
	resource_numbers(Rect2(168,306,204,20),m.mp,stats.mp,false,18)
	resource("equipment_mp",Rect2(168,329,204,3),m.mp,stats.mp,false)
	var w=host.model;var eq=w.s.equipment[host.who]
	for i in range(3):
		var slot=["weapon","armor","acc"][i];var x=168+i*68
		icon("sword" if i==0 else "shield",Rect2(x+14,346,34,34))
		label(w.Gear.SLOT[slot],Rect2(x,383,63,20),11,T.INK,T.BOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		if eq.has(slot):action("unequip:"+slot,"해제",Rect2(x,407,63,34),func():host._act(w.unequip.bind(host.who,slot),"해제했습니다."),false,w.active())
		else:label("미장착",Rect2(x,407,63,26),11).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var entries=w.s.gear.filter(func(e):return w.gear.by_id[e.id].cls==w.class_def(host.who).id)
	var prev=stage;stage=scroll_page(461,233,maxi(120,entries.size()*196))
	if entries.is_empty():paragraph("보유한 직업 장비가 없습니다.\n상회에서 구입하거나 대장간을 방문하세요.",Rect2(0,18,342,80),16)
	for i in range(entries.size()):
		var e=entries[i];var item=w.gear.by_id[e.id];var y=i*196
		icon("sword" if item.slot=="weapon" else "shield",Rect2(0,y+8,56,68))
		display(item.name+" +%d"%e.forge,Rect2(67,y,275,30),T.INK,22)
		label(host._gear_caption(item),Rect2(67,y+32,275,22),11)
		paragraph(host._gear_values(w.gear.roll(e,w.s.members[host.who].level)),Rect2(67,y+58,275,47),11)
		var cmp=w.gear_comparison(host.who,e.uid);var change=[]
		for key in cmp.get("delta",{}):
			if not is_zero_approx(cmp.delta[key]):change.append(key+" %+.1f"%cmp.delta[key])
		paragraph("장착 시 변화 · "+("동일" if change.is_empty() else " / ".join(change)),Rect2(0,y+106,342,39),11)
		var wearer=w.wearer(e.uid)
		action("equip:"+str(int(e.uid)),"장착",Rect2(0,y+149,165,38),func():host._act(w.equip.bind(host.who,e.uid),"장착했습니다."),true,w.active() or w.s.members[host.who].level<w.gear.rules.equip_lv[item.rarity] or wearer==host.who)
		action("sell:"+str(int(e.uid)),"판매 · %d"%w.gear.sell_price(e),Rect2(177,y+149,165,38),func():host._ask(item.name+"을 판매할까요?",w.sell_gear.bind(e.uid)),false,w.active() or not wearer.is_empty())
		rule(y+194,0,342)
	stage=prev
	action("equipment_shop","상회",Rect2(18,706,170,42),host.go.bind("shop"),false,w.active())
	action("equipment_smithy","대장간",Rect2(200,706,172,42),host.go.bind("smithy"),false,w.active())

func smithy() -> void:
	header("대장간")
	npc_hero("hanna","한나의\n대장간","",390)
	paragraph("무너진 것도,\n다시 쓸 수 있으니까.",Rect2(18,212,154,52),15)
	fill("process_paper",Rect2(18,392,354,85),T.PAPER)
	var w=host.model;var band=w.gear.band(w.highest_level());var odds=[]
	label("장비 가공",Rect2(26,399,174,27),19,T.INK,T.BOLD)
	for r in w.gear.ORDER:
		if band.w.get(r,0)>0:odds.append(w.Gear.RARITY[r]+" %s%%"%str(band.w[r]))
	paragraph(" / ".join(odds),Rect2(26,433,338,38),11)
	action("process_gear","가공 · 금화 %d"%band.price,Rect2(206,399,158,34),func():host._act(w.process_gear.bind(host.who),"");host.message=w.s.log[-1];host._draw_screen(),true,w.s.gold<band.price)
	var prev=stage;stage=scroll_page(491,203,maxi(120,w.s.gear.size()*151))
	if w.s.gear.is_empty():paragraph("제련할 장비가 없습니다.\n가공하거나 상회에서 장비를 구입하세요.",Rect2(0,15,342,65),16)
	for i in range(w.s.gear.size()):
		var e=w.s.gear[i];var it=w.gear.by_id[e.id];var y=i*151
		icon("sword" if it.slot=="weapon" else "shield",Rect2(0,y+7,61,69))
		display(it.name+" +%d"%e.forge,Rect2(72,y,270,30),T.INK,23)
		label("강화 단계마다 수치 +4% · 최대 +10",Rect2(72,y+34,270,23),11)
		if e.forge<10:
			label("성공률 %d%% · 실패해도 단계 유지"%w.gear.rules.forge.success[int(e.forge)],Rect2(0,y+77,342,23),12,T.RED,T.BOLD)
			var amount=w.gear.forge_cost(e)
			action("forge:"+str(int(e.uid)),"강화 · 금화 %d"%amount,Rect2(0,y+106,342,38),func():host._ask(it.name+" 강화 시도?\n실패해도 비용은 소모됩니다.",w.forge.bind(e.uid)),true,w.s.gold<amount)
		else:label("최대 강화",Rect2(0,y+107,342,28),16)
		rule(y+149,0,342)
	stage=prev
	action("smith_equipment","장비 장착하기",Rect2(18,706,354,42),host.go.bind("equipment"))

func journal() -> void:
	header("모험 기록")
	traced_title("journal",Rect2(14,54,152,134))
	action("cloud_open","클라우드 저장",Rect2(18,220,354,48),host.go.bind("cloud"))
	var prev=stage;stage=scroll_page(285,463,maxi(160,host.model.s.log.size()*89))
	if host.model.s.log.is_empty(): paragraph("아직 모험 기록이 없습니다.",Rect2(0,30,338,48),17)
	for i in range(host.model.s.log.size()):
		paragraph(host.model.s.log[host.model.s.log.size()-1-i],Rect2(18,i*89,320,70),14)
		fill("record_dot"+str(i),Rect2(0,i*89+12,6,6),T.RED);rule(i*89+82,18,320)
	stage=prev

func summary() -> void:
	header("원정 정산")
	var r=host.model.s.summary
	if r.is_empty():
		fill("empty_summary_paper",Rect2(0,60,390,703),T.PAPER)
		icon("gate",Rect2(159,210,72,72),T.MUTED)
		paragraph("아직 정산한 원정이 없습니다.",Rect2(28,318,334,84),22)
		action("summary_home","토르바로",Rect2(28,435,334,52),host.go.bind("town"),true);return
	plate("preparation-ruins",Rect2(0,52,390,219))
	if r.result!="defeat":traced_title("summary",Rect2(12,55,228,207))
	else:display("토르바로\n철수",Rect2(18,63,354,140),T.RED,60)
	label("전투 승리 %d회"%r.wins,Rect2(18,283,354,26),18,T.INK,T.BOLD)
	for i in range(3):
		var x=18+i*122
		icon(["shop","sword","inn"][i],Rect2(x+34,334,40,40))
		label(["금화","동료별 경험치","경과 일수"][i],Rect2(x,385,110,24),12).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		display(["+%d"%r.gold,"+%d"%r.xp,"1일"][i],Rect2(x+12,414,90,38),T.RED,29)
	small_party(484)
	for i in range(r.gains.size()):
		var g=r.gains[i];var x=18+i*91;var m=host.model.s.members[g.id]
		label("Lv.%d → %d"%[g.before,g.level],Rect2(x,600,86,20),11,T.INK,T.BOLD)
		fill("xp:"+g.id,Rect2(x,623,86*float(m.xp)/host.model.need(m.level),4),T.RED)
	paragraph("보상은 정산되었습니다. 이 화면을 다시 열어도 중복 지급되지 않습니다.",Rect2(18,641,354,46),13)
	if r.get("penalty",0)>0: label("패배 손실 · 금화 %d"%r.penalty,Rect2(18,669,354,26),14)
	action("summary_home","토르바로",Rect2(18,705,354,43),host.go.bind("town"),true)

func tabs(y: float,selected: int) -> void:
	for i in range(3):
		var key=["member","skills","formation"][i]
		var b=action("tab:"+key,["개요","기술","편성 · 장비"][i],Rect2(18+i*118,y,118,39),host.go.bind(key),selected==i and selected==0)
		if key=="formation" and host.who not in host.model.s.owned:
			b.disabled=true; b.tooltip_text="길드에서 영입한 뒤 편성할 수 있습니다."
		if selected!=i or selected==1:
			for state in ["normal","hover","pressed"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
			if selected==i: b.add_theme_color_override("font_color",T.RED)
	fill("tabs_rule",Rect2(18,y+42,354,1),T.LINE)
	fill("tab_active_rule",Rect2(18+selected*118+(2 if selected==1 else 0),y+(33 if selected==1 else 37),112 if selected==1 else 118,2),T.RED)

func overview() -> void:
	var w=host.model
	if not w.s.members.has(host.who):host.who=w.s.owned[0] if not w.s.owned.is_empty() else "persona"
	var id=host.who;var p=w.person(id);var m=w.s.members[id];var stats=w.stats(id,m.level)
	var original=stage;var sc=ScrollContainer.new();stage.add_child(sc);sc.size=Vector2(390,778);T.scroll_region(sc)
	var page=Control.new();sc.add_child(page);page.custom_minimum_size=Vector2(378,1270);stage=page
	background("inn",Rect2(0,0,390,470));boxes["background:inn"].modulate=Color(1,1,1,.38)
	picture(id,Rect2(93,38,300,432),"companion-main")
	display("토르바",Rect2(18,16,245,61),T.INK,44);label("%d일째 · 금화 %d"%[w.s.day,w.s.gold],Rect2(18,79,300,23),13,T.MUTED,T.BOLD)
	var chips=w.s.party.duplicate()
	if id not in chips:chips.push_front(id)
	for i in mini(4,chips.size()):
		var cid=chips[i];var y=120+i*64;picture(cid,Rect2(14,y,54,59),"companion-chip");hit("companion_chip:"+cid,Rect2(12,y,58,62),func():host.who=cid;host._draw_screen())
		if cid==id:fill("chip_active",Rect2(22,y+58,38,3),T.RED)
	fill("companion_say",Rect2(14,384,362,148),T.INK)
	display(p.name,Rect2(30,391,180,35),T.PAPER,25);paragraph(p.row+" · "+p["class"]+" · Lv.%d"%m.level,Rect2(218,398,142,30),9,Color("c9bfae"))
	var row=w.dialogue.select_scene(id,m.aff,w.s.dialogue_r21.seen);var line=""
	if not row.is_empty():line=row.seen if w.s.dialogue_r21.seen.get(row.id,0)>0 else " ".join(row.lines)
	var say=paragraph(line,Rect2(30,436,330,59),13,T.PAPER,false);say.set_meta("authored_copy",true);say.set_meta("dialogue_scene",row.get("id",""))
	label("HP",Rect2(30,503,25,18),11,Color("c9bfae"),T.BOLD);resource("hp_fill",Rect2(60,510,224,9),m.hp,stats.hp);label("%d/%d"%[m.hp,stats.hp],Rect2(291,500,69,24),13,T.PAPER,T.BOLD)
	action("companion_depart","원정 준비",Rect2(14,552,362,54),host.go.bind("depart"),true)
	var facilities=[["guild","연합 길드","의뢰판 · 동료 소개"],["shop","마렌토 상회","물약 · 해독약 · 두루마리"],["inn","여관","휴식 · 동료와 대화"],["smithy","한나의 대장간","제련 · 가공"]]
	for i in 4:
		var e=facilities[i];var y=612+i*40;var b=hit("companion:"+e[0],Rect2(14,y,362,40),host.go.bind(e[0]));b.tooltip_text=localized(e[1]);icon(e[0],Rect2(20,y+9,22,22));label(e[1],Rect2(54,y+2,142,36),15,T.INK,T.BOLD)
		var description=e[2] if L.language(w.s)!="en" else {"guild":"Quests · Companions","shop":"Potions · Antidotes · Scrolls","inn":"Rest · Talk to companions","smithy":"Forge · Process"}[e[0]]
		paragraph(description,Rect2(196,y+2,150,36),10,T.MUTED,L.language(w.s)!="en");icon("chev",Rect2(356,y+12,14,14),T.QUIET);rule(y+39,14,362)
	hit("back",Rect2(332,14,44,44),host.go.bind("party"));icon("back",Rect2(343,25,22,22));tabs(800,0)
	resource_numbers(Rect2(22,858,158,26),m.hp,stats.hp,true,24);resource_numbers(Rect2(208,858,158,26),m.mp,stats.mp,false,24);resource("mp_fill",Rect2(208,890,150,3),m.mp,stats.mp,false)
	for i in 5:
		var key=["str","agi","int","def","spd"][i];var x=22+i*70;label(["힘","민첩","지능","방어","속도"][i],Rect2(x,920,60,20),11,T.MUTED);label(str(int(floor(float(stats[key])+.5))),Rect2(x,943,60,28),22,T.INK,T.BOLD)
	rule(989);label("특성",Rect2(22,1000,334,23),12,T.MUTED,T.BOLD);display(p.trait.name,Rect2(22,1030,334,32),T.INK,25);paragraph(p.trait.note,Rect2(22,1073,334,95),13)
	hit("member_details",Rect2(18,996,354,180),host.go.bind("member_details")).tooltip_text="특성·경험치·기술 상세 보기"
	stage=original

func skills() -> void:
	header("동료 상세","party")
	var w=host.model;var p=w.person(host.who);var m=w.s.members[host.who];var stats=w.stats(host.who,m.level);var sk=p.skill
	picture(host.who,Rect2(190,51,188,224),"detail")
	display(p.name,Rect2(18,82,173,42),T.INK,31)
	paragraph(p.row+" · "+p["class"],Rect2(18,132,170,44),14,T.MUTED)
	resource_numbers(Rect2(18,192,165,28),m.hp,stats.hp,true,24);resource("skill_hp",Rect2(18,224,165,9),m.hp,stats.hp)
	resource_numbers(Rect2(18,240,165,24),m.mp,stats.mp,false,20)
	tabs(285,1)
	var prev=stage;stage=scroll_page(340,345,345);var y=0.0
	asset("res://assets/ic_"+{"fire":"fire","ice":"ice","holy":"holy","dark":"dark","wind":"wind"}.get(p.get("element",""),"bolt")+".webp",Rect2(0,0,44,44))
	var title=display(sk.name,Rect2(58,0,280,34),T.INK,24);mark("skill_title",title)
	label("MP %d · %s"%[sk.mp,sk.target],Rect2(58,38,280,24),14,T.MP,T.BOLD)
	var copy=localized(sk.note);var h=maxf(68,T.BODY.get_multiline_string_size(copy,HORIZONTAL_ALIGNMENT_LEFT,338,14).y+18)
	paragraph(copy,Rect2(0,77,338,h),14,T.INK,false)
	hit("personal_detail",Rect2(0,0,338,77+h),host.go.bind("member_details")).tooltip_text="기술 설명 전체 보기"
	y=89+h;rule(y,0,338);y+=22
	for entry in w.class_def(host.who).skills:
		if entry.kind not in ["기본","능동"]:continue
		var name="attack" if entry.id=="atk" else "defend" if entry.id=="guard" else "taunt" if entry.id=="taunt" else "bolt"
		asset("res://assets/ic_"+name+".webp",Rect2(0,y,40,40))
		display(entry.name,Rect2(54,y,284,32),T.INK,23);label("MP %d"%entry.mp,Rect2(54,y+36,284,25),14,T.MP,T.BOLD)
		var note=localized(entry.note);h=maxf(44,T.BODY.get_multiline_string_size(note,HORIZONTAL_ALIGNMENT_LEFT,338,14).y+16)
		paragraph(note,Rect2(0,y+73,338,h),14,T.INK,false)
		hit("skill_detail:"+entry.id,Rect2(0,y,338,73+h),host.go.bind("member_details"));y+=93+h;rule(y,0,338);y+=18
	stage.custom_minimum_size.y=y;stage=prev
	action("signature_preview","연출 보기",Rect2(18,705,354,48),host._show_art.bind(host.who),true)

