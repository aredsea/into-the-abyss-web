extends Control
## First completed delivery: measured home / roster / overview / skills.
## All other destinations retain their complete functional screens in world_screen.
const T=preload("res://ui/town_theme_r21.gd")
const Portrait=preload("res://ui/town_portrait_r21.gd")
const Ink=preload("res://ui/battle_ink_r17.gd")
var host
var stage: Control
var boxes={}
var metrics=[]
var nav_top=763.0
var background_scene=""

func build(owner_screen) -> void:
	build_frame(owner_screen)
	build_page()

func build_frame(owner_screen) -> void:
	host=owner_screen; mouse_filter=MOUSE_FILTER_IGNORE
	theme=T.make_theme(); set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg=ColorRect.new(); add_child(bg); bg.color=T.PAPER; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.mouse_filter=MOUSE_FILTER_IGNORE
	stage=Control.new(); add_child(stage); stage.size=Vector2(390,844)
	var k=minf(host.size.x/390.0,host.size.y/844.0)
	stage.scale=Vector2(k,k); stage.position=(host.size-stage.size*k)/2; stage.clip_contents=true

func build_page() -> void:
	page_background()
	if not host.confirm.is_empty() and host.screen=="explore": retreat()
	elif host.screen=="town":
		nav_top=788; home()
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
	if not host.message.is_empty() and host.screen in ["town","party","member","skills","cards","explore"]:
		fill("notice_bg",Rect2(14,nav_top-44,362,40),T.INK)
		label(host.message,Rect2(22,nav_top-43,346,38),12,T.PAPER)
	if host.save_error!=OK:
		action("save_retry","저장 다시 시도",Rect2(20,nav_top-90,350,44),func():host._save();host._draw_screen(),true)

func mark(id: String,node: Control) -> void:
	node.set_meta("town_r21_box",id); boxes[id]=node

func fill(id: String,r: Rect2,color: Color) -> ColorRect:
	var c=ColorRect.new(); stage.add_child(c); c.position=r.position; c.size=r.size; c.color=color; c.mouse_filter=MOUSE_FILTER_IGNORE
	mark(id,c); return c

func label(value: String,r: Rect2,fs=14,color=T.INK,font: Font=T.BODY) -> Label:
	var l=Label.new(); stage.add_child(l); l.position=r.position; l.size=r.size
	l.text=value; l.add_theme_font_override("font",font); l.add_theme_font_size_override("font_size",fs); l.add_theme_color_override("font_color",color)
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; l.mouse_filter=MOUSE_FILTER_IGNORE
	l.clip_text=true
	metrics.append({"text":value,"needed":font.get_multiline_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x,"available":r.size.x,"font_size":fs})
	return l

func display(value: String,r: Rect2,color=T.INK,fs=64,stretch=false) -> Label:
	var l=label(value,r,fs,color,T.DISPLAY)
	var w=T.DISPLAY.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	if w>r.size.x or stretch:
		l.size.x=w; l.scale.x=r.size.x/w
		metrics[-1].available=w
	if fs>=29 and color==T.INK:
		var grain=TextureRect.new();l.add_child(grain);grain.texture=load("res://assets/ui-r21/type-drybrush.svg");grain.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;grain.stretch_mode=TextureRect.STRETCH_SCALE;grain.size=l.size;grain.mouse_filter=MOUSE_FILTER_IGNORE
	return l

func background(name: String,r: Rect2) -> void:
	var p=TextureRect.new(); stage.add_child(p);p.position=r.position;p.size=r.size
	p.texture=load("res://assets/ui-r21/bg-"+name+".webp");p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;p.stretch_mode=TextureRect.STRETCH_SCALE;p.mouse_filter=MOUSE_FILTER_IGNORE
	mark("background:"+name,p); background_scene=name

func page_background() -> void:
	var name=host.screen;var r=Rect2(0,0,390,447)
	if name=="explore":
		if not host.confirm.is_empty():name="retreat";r=Rect2(0,0,390,391)
		elif not host.model.r21():name="cache";r=Rect2(0,94,390,388)
		elif host.model.s.run.phase=="rest":name="rest";r=Rect2(0,97,390,385)
		else:name="explore";r=Rect2(0,98,390,407)
	elif name in ["member","skills","party"]:name="town";r=Rect2(0,0,390,484 if host.screen=="member" else 285 if host.screen=="skills" else 757)
	elif name=="town":r=Rect2(0,0,390,530)
	elif name=="depart":name="departure";r=Rect2(0,48,390,219)
	elif name=="summary":r=Rect2(0,0,390,279)
	elif name=="equipment":r=Rect2(0,0,390,190)
	elif name=="cards":name="empty" if host.model.s.hand.is_empty() else "cards";r=Rect2(0,0,390,435 if name=="empty" else 328)
	elif name=="journal":r=Rect2(0,0,390,267)
	elif name=="recruit":r=Rect2(0,0,390,505)
	elif name=="smithy":r=Rect2(0,0,390,482)
	elif name=="inn":r=Rect2(0,0,390,430)
	elif name=="shop":r=Rect2(0,0,390,373)
	elif name not in ["guild","research"]:return
	background(name,r)
	if ResourceLoader.exists("res://assets/ui-r21/accent-"+name+".svg"):plate("accent-"+name,r)

func traced_title(name: String,r: Rect2) -> void:
	var t=TextureRect.new();stage.add_child(t);t.texture=load("res://assets/ui-r21/title-"+name+".svg")
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_SCALE;t.position=r.position;t.size=r.size;t.mouse_filter=MOUSE_FILTER_IGNORE
	mark("title:"+name,t)

func action(id: String,value: String,r: Rect2,callback: Callable,primary=false,disabled=false) -> Button:
	var b=Button.new(); stage.add_child(b); b.position=r.position; b.size=r.size; b.text=value; b.disabled=disabled
	b.add_theme_font_override("font",T.BOLD); b.add_theme_font_size_override("font_size",16)
	if primary:
		for state in ["normal","hover","pressed"]:
			var brush=StyleBoxTexture.new();brush.texture=load("res://assets/ui-r21/button-ink.svg");b.add_theme_stylebox_override(state,brush)
		for state in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(state,T.PAPER)
	b.pressed.connect(callback); host.controls[id]=b; mark(id,b)
	return b

func hit(id: String,r: Rect2,callback: Callable) -> Button:
	var b=action(id,"",r,callback)
	for state in ["normal","hover","pressed"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	return b

func picture(id: String,r: Rect2,slot="bust") -> Control:
	var p=Portrait.new(); stage.add_child(p); p.position=r.position; p.size=r.size; p.configure(id,slot)
	mark("portrait:"+id+":"+slot,p); return p

func ink(r: Rect2,kind="base") -> void:
	var c=TextureRect.new(); c.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	c.texture=load("res://assets/ui-r21/town-vermilion.svg"); c.stretch_mode=TextureRect.STRETCH_SCALE
	stage.add_child(c); c.position=r.position; c.size=r.size; c.mouse_filter=MOUSE_FILTER_IGNORE

func header(title: String,back="town") -> void:
	hit("back",Rect2(10,10,44,44),host.go.bind(back))
	icon("back",Rect2(21,22,23,23))
	label(title,Rect2(56,11,225,38),20,T.INK,T.BOLD)

func icon(name: String,r: Rect2,color=T.INK) -> void:
	var path="res://assets/ui-r21/"+name+".svg"
	if not ResourceLoader.exists(path): path="res://assets/ui-r17/"+name+".svg"
	if not ResourceLoader.exists(path): path="res://assets/ui-r11/"+name+".svg"
	var t=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage.add_child(t); t.texture=load(path); t.position=r.position; t.size=r.size; t.mouse_filter=MOUSE_FILTER_IGNORE
	var shader=Shader.new();shader.code="shader_type canvas_item; uniform vec4 tint : source_color; void fragment(){COLOR=vec4(tint.rgb,texture(TEXTURE,UV).a*tint.a);}"
	var material=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("tint",color);t.material=material

func plate(name: String,r: Rect2) -> void:
	if not background_scene.is_empty() and name in ["preparation-ruins","town-city-left","town-city-right","detail-city"]:return
	var t=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stage.add_child(t); t.texture=load("res://assets/ui-r21/"+name+".svg"); t.position=r.position; t.size=r.size; t.mouse_filter=MOUSE_FILTER_IGNORE

func navigation() -> void:
	fill("navigation_rule",Rect2(18,nav_top,354,1),T.INK)
	var selected="party" if host.screen in ["member","skills","party","formation"] else "depart" if host.screen in ["depart","explore","cards"] else "bag" if host.screen=="bag" else "journal" if host.screen=="journal" else "town"
	var entries=[["town","마을","home"],["party","동료","party"],["depart","원정","gate"],["bag","가방","bag"],["journal","기록","journal"]]
	for i in range(5):
		var e=entries[i]; var x=i*78.0; var color=T.RED if selected==e[0] else T.INK
		var destination="explore" if e[0]=="depart" and host.model.active() else e[0]
		hit("nav:"+e[0],Rect2(x,nav_top+2,78,844-nav_top-2),host.go.bind(destination))
		icon("nav-"+e[2],Rect2(x+28,nav_top+11,28,27),color)
		var l=label(e[1],Rect2(x,nav_top+39,78,18),11,color,T.BOLD); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		if selected==e[0]: fill("nav_active",Rect2(x+20,837,39,2),T.RED)
		if i<4: fill("nav_divider"+str(i),Rect2(x+78,nav_top+13,1,25),T.LINE)

func home() -> void:
	traced_title("home",Rect2(0,0,390,233))
	plate("town-city-left",Rect2(0,330,103,128)); plate("town-city-right",Rect2(335,254,55,201))
	ink(Rect2(-24,286,450,246))
	label("현재 위치",Rect2(14,232,82,16),9,T.INK,T.BOLD)
	display("토르바",Rect2(14,246,74,39),T.INK,29,true)
	fill("location_rule",Rect2(14,286,73,2),T.INK)
	label("%d일째" % host.model.s.day,Rect2(14,293,78,22),13,T.INK,T.BOLD)
	label("금화",Rect2(14,315,38,22),14,T.INK,T.BOLD)
	display(str(int(host.model.s.gold)),Rect2(48,308,77,35),T.RED,30)
	var zone=host.model.dungeon_rules.floor_info(host.model.selected_floor)
	label(host.model.dungeon_rules.zones[zone.zone].name+"\n%d층"%host.model.selected_floor,Rect2(332,211,58,40),9).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	metrics[-1].available=1000
	picture(host.model.s.party[0],Rect2(50,103,340,428),"town-main")
	fill("hero_caption",Rect2(14,460,277,71),Color(0.067,.09,.08,.85))
	label("주요 동료",Rect2(22,460,160,17),9,T.PAPER)
	display(host.model.person(host.model.s.party[0]).name,Rect2(22,473,225,40),T.PAPER,37)
	label(host.model.person(host.model.s.party[0])["class"],Rect2(255,493,42,23),13,T.PAPER,T.BOLD)
	label("출전 파티",Rect2(14,532,150,16),9,T.INK,T.BOLD)
	for i in range(4):
		var id=host.model.s.party[i]; var x=14+i*92
		fill("party_frame"+str(i),Rect2(x+2,548,84,62),T.INK)
		picture(id,Rect2(x+2,550,83,58),"town-party-face")
		var l=label(host.model.person(id).name,Rect2(x,610,87,16),9); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		hit("town_member:"+id,Rect2(x,548,87,78),func():host.who=id;host.go("member"))
	var b=action("depart","원정 준비",Rect2(14,631,362,67),host.go.bind("depart"),true)
	plate("town-depart",Rect2(135,631,241,67))
	b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_font_size_override("font_size",23)
	label("마을에서 할 일",Rect2(14,702,280,17),9,T.INK,T.BOLD)
	for i in range(4):
		var e=[["guild","길드"],["shop","상회"],["inn","여관"],["smithy","대장간"]][i]; var x=14+i*92
		action(e[0],e[1],Rect2(x,722,87,54),host.go.bind(e[0]))
		plate("facility-"+e[0],Rect2(x,722,87,37))
		# Keep facility text below its symbol, within one coherent hit target.
		host.controls[e[0]].text=""; label(e[1],Rect2(x+5,752,77,21),11,T.INK,T.BOLD)

func roster() -> void:
	header("동료")
	label("보유 %d명 / 전체 30명" % host.model.s.owned.size(),Rect2(194,20,140,24),11,T.INK,T.BOLD)
	action("roster_all","전체" if not host.catalog_all else "보유",Rect2(337,13,44,38),func():host.catalog_all=not host.catalog_all;host._draw_screen())
	var ids=host.model.IDS.duplicate()
	for p in host.model.config.companions:
		if p.id not in ids and (host.catalog_all or p.id in host.model.s.owned): ids.append(p.id)
	# More than four companions get a scrolling spread. No new geometry is
	# connected until all four cards in that spread have complete labels/hits.
	var sc=ScrollContainer.new(); stage.add_child(sc); sc.position=Vector2(0,53); sc.size=Vector2(390,704)
	sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var page=Control.new(); sc.add_child(page); page.custom_minimum_size=Vector2(380,ceil(ids.size()/4.0)*704); page.size=page.custom_minimum_size
	var previous=stage; stage=page
	for i in range(ids.size()):
		var id=ids[i]; var col=i%2; var x=0 if col==0 else 234 if i%4==1 else 193
		var y=int(i/4)*704+[0,69,331,350][i%4]
		var rect=Rect2(x,y,[239,156,233,197][i%4],[379,297,357,350][i%4])
		ink(Rect2(x-25,y+20,240,315))
		var portrait=picture(id,rect,["cast-feature","cast-secondary","cast-lower-left","cast-lower-left"][i%4])
		# The spread follows the reference's diagonal card edges, without changing art.
		var mask=preload("res://ui/town_diagonal_r21.gd").new();stage.add_child(mask);mask.position=rect.position;mask.size=rect.size
		portrait.reparent(mask);portrait.position=Vector2.ZERO
		var pw=minf(178,rect.size.x-12)
		var previous_plate=stage
		var group=Control.new();stage.add_child(group);group.position=Vector2(x+10,y+rect.size.y-97);group.rotation=-.07 if col==0 else -.12;group.mouse_filter=MOUSE_FILTER_IGNORE
		stage=group
		fill("nameplate:"+id,Rect2(0,0,pw,70),T.INK)
		display(host.model.person(id).name,Rect2(7,3,pw-10,33),T.PAPER,29)
		label(host.model.person(id)["class"],Rect2(9,34,pw-12,25),15,T.PAPER,T.BOLD)
		stage=previous_plate
		if id in host.model.s.party and (i==0 or i>=4):
			fill("party_badge:"+id,Rect2(x+12,y+rect.size.y-30,117,26),T.RED)
			label("파티 중",Rect2(x+23,y+rect.size.y-30,96,26),13,T.PAPER,T.BOLD)
		hit("member:"+id,rect,func():host.who=id;host.go("member"))
	stage=previous

func paragraph(value: String,r: Rect2,fs=13,color=T.INK) -> Label:
	var l=label(value,r,fs,color); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	metrics[-1].available=10000
	return l

func rule(y: float,x=18.0,width=354.0) -> void: fill("rule:"+str(y),Rect2(x,y,width,1),T.LINE)

func asset(path: String,r: Rect2) -> void:
	var p=TextureRect.new(); stage.add_child(p); p.position=r.position; p.size=r.size
	p.texture=load(path); p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; p.mouse_filter=MOUSE_FILTER_IGNORE

func scroll_page(y: float,height: float,minimum: float) -> Control:
	var sc=ScrollContainer.new(); stage.add_child(sc); sc.position=Vector2(18,y); sc.size=Vector2(354,height)
	sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var page=Control.new(); sc.add_child(page); page.custom_minimum_size=Vector2(342,minimum); page.size=page.custom_minimum_size
	return page

func small_party(y: float,tall=false) -> void:
	for i in range(4):
		var id=host.model.s.party[i]; var m=host.model.s.members[id]; var stats=host.model.stats(id,m.level); var x=18+i*91
		picture(id,Rect2(x,y,86,181 if tall else 64),"party-tall" if tall else "town-party-face")
		if tall:
			fill("party_caption:"+id,Rect2(x,y+144,86,37),Color(.067,.09,.08,.92))
			label(host.model.person(id).name,Rect2(x+4,y+145,80,18),12,T.PAPER,T.BOLD)
			label("Lv.%d"%m.level,Rect2(x+4,y+163,80,17),11,T.PAPER)
		else:
			label(host.model.person(id).name,Rect2(x,y+64,86,18),10,T.INK,T.BOLD)
			label("%d / %d"%[m.hp,stats.hp],Rect2(x,y+83,86,17),10)
			fill("party_hp:"+id,Rect2(x,y+102,86*float(m.hp)/maxf(1,stats.hp),4),T.RED)
			fill("party_mp:"+id,Rect2(x,y+109,86*float(m.mp)/maxf(1,stats.mp),3),T.MP)

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
		action("bag_tab:"+key,["보급품","장비","탐색 카드"][i],Rect2(18+i*118,65,118,38),host.go.bind(key),i==0)
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
	for i in range(4):
		var id=w.s.party[i]; var y=199+i*109; var m=w.s.members[id]; var p=w.item_preview(it.id,id)
		var selected=host.selected_target==id
		var b=action("target:"+id,"",Rect2(3,y,372,99),func():host.selected_target=id;host._draw_screen(),false,not p.usable)
		b.add_theme_stylebox_override("normal",T.panel(Color("f9e6d5") if selected else T.PAPER,T.RED if selected else T.LINE))
		picture(id,Rect2(42,y+3,88,93),"target-face")
		label(host.model.person(id).name,Rect2(140,y+11,180,22),17,T.INK,T.BOLD)
		label("Lv.%d"%m.level,Rect2(290,y+12,73,20),11)
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
		for i in range(4):picture(w.s.party[i],Rect2(12+i*94,273,94,171),"party-tall")
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
	picture(host.model.s.party[0],Rect2(160,53,230,275 if not host.model.s.hand.is_empty() else 382),"town-main")
	if host.model.s.hand.is_empty():
		display("보유 중인 카드가 없습니다",Rect2(18,449,354,45),T.INK,25)
		paragraph("카드를 얻으면 이곳에서 확인할 수 있습니다.",Rect2(18,503,354,48),14)
	else:
		display("탐색 카드",Rect2(18,331,354,45),T.INK,31)
		for i in range(2):
			var id=["key","camp"][i]; var count=host.model.s.hand.count(id)
			if count==0: continue
			var c=host.model.card_def(id);var x=18+i*182
			fill("card_panel:"+id,Rect2(x,389,172,237),T.PALE)
			plate("card-"+id,Rect2(x+10,391,152,139))
			display(c.name,Rect2(x+10,533,152,32),T.INK,23)
			label("× %d"%count,Rect2(x+10,568,152,28),22,T.INK,T.BOLD)
			paragraph(c.text,Rect2(x+10,595,152,31),10,T.INK)
			var reason=host.model.card_reason(id)
			action("card:"+id,"카드 사용",Rect2(x,640,172,43),func():host._ask(c.name+" 카드 1장을 소모할까요?",host.model.use_card.bind(id)),true,not reason.is_empty()).tooltip_text=reason
	action("cards_back","원정으로" if host.model.active() else "가방으로",Rect2(18,701,354,45),host.go.bind("explore" if host.model.active() else "bag"),true)

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
	var title_name=host.screen
	var shapes={"guild":Rect2(18,53,141,119),"recruit":Rect2(18,53,140,194),"research":Rect2(18,53,129,189),"shop":Rect2(18,53,166,145),"smithy":Rect2(18,53,196,145),"inn":Rect2(14,61,167,127)}
	picture(id,Rect2(99,43,291,height-3),"town-main")
	if shapes.has(title_name):traced_title(title_name,shapes[title_name])
	else:display(title,Rect2(15,54,210,130),T.INK,68)
	if not subtitle.is_empty():
		fill("npc_caption",Rect2(18,height-64,175,63),T.PAPER)
		label(subtitle,Rect2(28,height-61,154,58),15,T.INK,T.BOLD).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		metrics[-1].available=1000

func research() -> void:
	header("전술 연구","guild")
	npc_hero("loredana","전술\n연구","",430)
	paragraph("더 날카롭게,\n더 멀리.",Rect2(18,250,130,43),14)
	member_choice(Rect2(18,398,354,38))
	var w=host.model;var r=w.s.research[host.who];var current=w.tactic(host.who)
	guild_tabs(2)
	for index in range(2):
		var kind="prefixes" if index==0 else "suffixes";var parts=[]
		for part in w.research[kind]:
			if index==0 or w.compatible(host.research_prefix,part.id):parts.append(part)
		var pick=OptionButton.new();stage.add_child(pick);pick.position=Vector2(18+index*182,504);pick.size=Vector2(172,56);pick.fit_to_longest_item=false;pick.clip_text=true;pick.add_theme_font_size_override("font_size",12)
		for part in parts:pick.add_item(part.name+" · "+part.note)
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
		var level=r[kind+"_lv"].get(r[kind],0);var amount=40+20*level*level
		action("train:"+kind,("몸통" if i==0 else "덧효과")+" +%d · %d금화"%[level,amount],Rect2(18+i*182,730,172,29),func():host._ask("금화를 소모해 전술 조각을 강화할까요?",w.train.bind(host.who,kind)),false,level>=10 or w.s.gold<amount).add_theme_font_size_override("font_size",11)

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
	if host.who not in host.model.s.owned:host.who=host.model.s.party[0]
	var pick=OptionButton.new();stage.add_child(pick);pick.position=r.position;pick.size=r.size
	pick.fit_to_longest_item=false;pick.clip_text=true
	for id in host.model.s.owned:pick.add_item(host.model.person(id).name+" · "+host.model.person(id)["class"])
	pick.select(host.model.s.owned.find(host.who));pick.item_selected.connect(func(i):host.who=host.model.s.owned[i];host._draw_screen())
	host.controls.member_choice=pick

func inn() -> void:
	header("아랫마을 여관")
	npc_hero("dorothea","여관","도로테아\n여관 주인",430)
	label("함께하는 동료",Rect2(18,436,190,24),13,T.INK,T.BOLD)
	member_choice(Rect2(208,437,164,36))
	picture(host.who,Rect2(18,480,139,127),"detail-skills")
	plate("detail-city",Rect2(157,480,215,127))
	fill("inn_member_paper",Rect2(174,514,198,93),T.PAPER)
	display(host.model.person(host.who).name,Rect2(183,518,180,29),T.INK,24)
	label(host.model.person(host.who)["class"],Rect2(183,547,180,18),12)
	var aff=host.model.s.members[host.who].aff
	label("호감 %s / 200"%host.number(aff),Rect2(183,567,180,20),12,T.INK,T.BOLD)
	fill("aff_track",Rect2(183,591,177,8),T.LINE);fill("aff_value",Rect2(183,591,177*maxf(0,aff)/200,8),T.RED)
	label("함께, 더 깊은 곳으로.",Rect2(18,614,354,25),15,T.INK,T.BOLD)
	var acts=host.model.TOWN_RULES.DATA.inn
	for i in range(4):
		var key=["talk","meal","gift","rest"][i];var e=acts[key];var x=18+i*91
		var used=not e.day and host.model.s.acts.get(host.who+"_"+key,0)==host.model.s.day
		action("inn:"+key,"",Rect2(x,645,81,91),func():host._ask(e.name+" · 금화 %d\n호감이 오릅니다."%e.cost,host.model.inn.bind(host.who,key)),i==0,used or host.model.s.gold<e.cost)
		icon(["journal","shop","bag","inn"][i],Rect2(x+26,651,28,28),T.PAPER if i==0 else T.INK)
		label(e.name,Rect2(x+2,684,77,20),11,T.PAPER if i==0 else T.INK,T.BOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label("오늘 완료" if used else "무료" if e.cost==0 else "금화 %d"%e.cost,Rect2(x+2,710,77,19),11,T.PAPER if i==0 else T.RED,T.BOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	paragraph("대화·식사·선물은 동료마다 하루 한 번.\n곁에서 쉬면 하루가 지납니다.",Rect2(18,738,354,22),9)
	feedback(590)

func shop() -> void:
	header("상회")
	npc_hero("pietro","마렌토\n상회","",365)
	paragraph("여행자의 여정에\n필요한 모든 것.",Rect2(18,210,150,46),14)
	label("보유 금화",Rect2(18,302,130,22),12,T.INK,T.BOLD)
	display(str(int(host.model.s.gold)),Rect2(18,327,125,37),T.RED,31)
	for i in range(2):
		action(["shop_items","shop_equipment"][i],["보급품","직업 장비"][i],Rect2(18+i*177,378,177,40),func():host.shop_tab="items" if i==0 else "gear";host._draw_screen(),(host.shop_tab=="items")==bool(i==0))
	if host.shop_tab=="gear":shop_gear();return
	var prev=stage;stage=scroll_page(432,270,host.model.config.items.size()*107)
	for i in range(host.model.config.items.size()):
		var item=host.model.config.items[i];var y=i*107
		asset("res://assets/ic_"+item.icon+".webp",Rect2(0,y,90,92))
		label(item.name,Rect2(100,y+4,155,24),14,T.INK,T.BOLD)
		paragraph(host._item_text(item),Rect2(100,y+30,150,52),11)
		label("금화 %d"%host.model.price(item),Rect2(261,y+5,80,24),14,T.RED,T.BOLD)
		action("buy:"+item.id,"구입",Rect2(261,y+43,80,39),func():host._act(host.model.buy.bind(item.id),"구입했습니다."),true,host.model.s.gold<host.model.price(item))
		label("보유 %d"%host.model.s.items[item.id],Rect2(100,y+82,150,19),10)
		rule(y+103,0,342)
	stage=prev;feedback();action("shop_bag","가방과 장비 확인",Rect2(18,705,354,43),host.go.bind("equipment"))

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
	label("HP %d / %d"%[m.hp,stats.hp],Rect2(168,272,204,20),12)
	fill("equipment_hp",Rect2(168,296,204*float(m.hp)/maxf(1,stats.hp),5),T.RED)
	label("MP %d / %d"%[m.mp,stats.mp],Rect2(168,305,204,20),12)
	fill("equipment_mp",Rect2(168,329,204*float(m.mp)/maxf(1,stats.mp),5),T.MP)
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
	label("장비 가공",Rect2(26,399,150,27),19,T.INK,T.BOLD)
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
	var prev=stage;stage=scroll_page(285,463,maxi(160,host.model.s.log.size()*89))
	if host.model.s.log.is_empty(): paragraph("아직 모험 기록이 없습니다.",Rect2(0,30,338,48),17)
	for i in range(host.model.s.log.size()):
		paragraph(host.model.s.log[host.model.s.log.size()-1-i],Rect2(18,i*89,320,70),14)
		fill("record_dot"+str(i),Rect2(0,i*89+12,6,6),T.RED);rule(i*89+82,18,320)
	stage=prev

func summary() -> void:
	header("원정 정산")
	var r=host.model.s.summary
	if r.is_empty(): paragraph("아직 정산한 원정이 없습니다.",Rect2(18,201,354,100),20); return
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
	ink(Rect2(0,170,440,315))
	plate("detail-city",Rect2(286,0,104,141))
	var name=display(host.model.person(host.who).name,Rect2(16,42,329,91),T.INK,78,true); name.scale.y=1.04
	picture(host.who,Rect2(0,123,390,360),"detail-overview")
	label("Lv.%d · %s · %s" % [host.model.s.members[host.who].level,host.model.person(host.who)["class"],host.model.person(host.who).row],Rect2(19,137,350,27),16,T.INK,T.BOLD)
	header("동료 상세","party")
	tabs(490,0)
	var m=host.model.s.members[host.who]; var s=host.model.stats(host.who,m.level)
	for i in range(2):
		var k="hp" if i==0 else "mp"; var x=28+i*182
		label("%s   %d / %d" % [k.to_upper(),m[k],s[k]],Rect2(x,550,158,24),13,T.INK,T.BOLD)
		fill(k+"_track",Rect2(x+1,573,151,9),T.LINE)
		fill(k+"_fill",Rect2(x+1,573,151*float(m[k])/maxf(1,s[k]),9),T.RED if i==0 else Color("197ab7"))
	for i in range(5):
		var key=["str","agi","int","def","spd"][i]; var x=28+i*70
		var l=label(["힘","민첩","지능","방어","속도"][i],Rect2(x,610,60,19),10); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		l=label(host.number(s[key]),Rect2(x,630,60,26),20,T.INK,T.BOLD); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	fill("trait_rule",Rect2(18,675,354,1),T.LINE)
	var p=host.model.person(host.who)
	label("특성",Rect2(20,675,42,20),10,T.INK,T.BOLD)
	if host.who=="hildegard": plate("trait-penguin",Rect2(24,690,99,64))
	else: icon("shield",Rect2(34,701,54,46))
	display(p.trait.name,Rect2(137,690,233,29),T.INK,21)
	var teaser=p.trait.note.left(32)+("…" if p.trait.note.length()>32 else "")
	var l=label(teaser,Rect2(137,719,233,38),11); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	metrics[-1].available=1000 # measured as wrapped text by the UI test
	hit("member_details",Rect2(18,681,354,78),host.go.bind("member_details")).tooltip_text="특성·경험치·기술 상세 보기"

func skills() -> void:
	ink(Rect2(-10,30,430,255)); plate("detail-city",Rect2(286,0,104,141)); picture(host.who,Rect2(83,27,307,257),"town-main")
	header("동료 상세","party")
	tabs(285,1)
	var p=host.model.person(host.who); var sk=p.skill
	if host.who=="hildegard": plate("signature-guard",Rect2(23,340,129,165))
	else:
		fill("signature_plate",Rect2(23,340,129,165),T.RED)
		icon("shield",Rect2(58,389,60,69),T.INK)
	var title=display(sk.name,Rect2(169,333,134,34),T.INK,25,true); mark("skill_title",title)
	label("MP %d · %s" % [sk.mp,sk.target],Rect2(170,370,203,25),13,T.INK,T.BOLD)
	var teaser=sk.note.left(48)+("…" if sk.note.length()>48 else "")
	var l=label(teaser,Rect2(170,400,204,63),12); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	metrics[-1].available=1000
	hit("personal_detail",Rect2(170,395,204,67),host.go.bind("member_details")).tooltip_text="기술 설명 전체 보기"
	action("signature_preview","연출 보기",Rect2(170,469,200,36),host._show_art.bind(host.who),true)
	fill("skills_rule",Rect2(20,522,350,1),T.INK)
	var sc=ScrollContainer.new(); stage.add_child(sc); sc.position=Vector2(18,535); sc.size=Vector2(354,222)
	sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list=Control.new(); sc.add_child(list)
	var entries=host.model.class_def(host.who).skills.filter(func(e):return e.kind in ["기본","능동"])
	list.custom_minimum_size=Vector2(344,entries.size()*80); list.size=list.custom_minimum_size
	var previous=stage; stage=list; var index=0
	for entry in host.model.class_def(host.who).skills:
		if entry.kind not in ["기본","능동"]: continue
		var y=index*80
		plate("skill-"+("attack" if entry.id=="atk" else "guard" if entry.id=="guard" else "taunt"),Rect2(6,y+8,61,57))
		display(entry.name,Rect2(73,y+2,270,28),T.INK,21)
		label("MP %d" % entry.mp,Rect2(74,y+32,55,21),12,Color("197ab7"),T.BOLD)
		var excerpt=entry.note.left(29)+("…" if entry.note.length()>29 else "")
		var note=label(excerpt,Rect2(130,y+32,212,40),12); note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		metrics[-1].available=1000
		fill("skill_rule"+str(index),Rect2(2,y+77,340,1),T.LINE)
		hit("skill_detail:"+entry.id,Rect2(0,y,344,78),host.go.bind("member_details")); index+=1
	stage=previous
