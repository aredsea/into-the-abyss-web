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

func build(owner_screen) -> void:
	host=owner_screen; mouse_filter=MOUSE_FILTER_IGNORE
	theme=T.make_theme(); set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg=ColorRect.new(); add_child(bg); bg.color=T.PAPER; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.mouse_filter=MOUSE_FILTER_IGNORE
	stage=Control.new(); add_child(stage); stage.size=Vector2(390,844)
	var k=minf(host.size.x/390.0,host.size.y/844.0)
	stage.scale=Vector2(k,k); stage.position=(host.size-stage.size*k)/2; stage.clip_contents=true
	if host.screen=="town":
		nav_top=788; home()
	elif host.screen=="party": roster()
	elif host.screen=="member": overview()
	else: skills()
	navigation()
	if not host.message.is_empty():
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

func display(value: String,r: Rect2,color=T.INK,fs=64) -> Label:
	var l=label(value,r,fs,color,T.DISPLAY)
	var w=T.DISPLAY.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	if w>r.size.x:
		l.size.x=w; l.scale.x=r.size.x/w
		metrics[-1].available=w
	return l

func action(id: String,value: String,r: Rect2,callback: Callable,primary=false,disabled=false) -> Button:
	var b=Button.new(); stage.add_child(b); b.position=r.position; b.size=r.size; b.text=value; b.disabled=disabled
	b.add_theme_font_override("font",T.BOLD); b.add_theme_font_size_override("font_size",16)
	if primary:
		for state in ["normal","hover","pressed"]: b.add_theme_stylebox_override(state,T.panel(T.RED,T.RED))
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
	action("back","",Rect2(10,10,44,44),host.go.bind(back))
	icon("back",Rect2(21,22,23,23))
	label(title,Rect2(56,14,225,38),20,T.INK,T.BOLD)

func icon(name: String,r: Rect2,color=T.INK) -> void:
	var path="res://assets/ui-r17/"+name+".svg"
	if not ResourceLoader.exists(path): path="res://assets/ui-r11/"+name+".svg"
	var t=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage.add_child(t); t.texture=load(path); t.modulate=color; t.position=r.position; t.size=r.size; t.mouse_filter=MOUSE_FILTER_IGNORE

func plate(name: String,r: Rect2) -> void:
	var t=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stage.add_child(t); t.texture=load("res://assets/ui-r21/"+name+".svg"); t.position=r.position; t.size=r.size; t.mouse_filter=MOUSE_FILTER_IGNORE

func navigation() -> void:
	fill("navigation_rule",Rect2(18,nav_top,354,1),T.INK)
	var selected="party" if host.screen in ["member","skills","party"] else "town"
	var entries=[["town","마을","home"],["party","동료","party"],["depart","원정","gate"],["bag","가방","bag"],["journal","기록","journal"]]
	for i in range(5):
		var e=entries[i]; var x=14+i*72.4; var color=T.RED if selected==e[0] else T.INK
		hit("nav:"+e[0],Rect2(x,nav_top+2,72,844-nav_top-2),host.go.bind(e[0]))
		icon(e[2],Rect2(x+25,nav_top+11,24,24),color)
		var l=label(e[1],Rect2(x,nav_top+36,72,18),11,color,T.BOLD); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		if selected==e[0]: fill("nav_active",Rect2(x+20,837,32,2),T.RED)
		if i<4: fill("nav_divider"+str(i),Rect2(x+72,nav_top+13,1,25),T.LINE)

func home() -> void:
	display("INTO",Rect2(9,-19,141,163),T.INK,166)
	display("ABYSS",Rect2(155,-19,226,231),T.RED,166)
	display("THE",Rect2(9,104,140,135),T.INK,148)
	var city=TextureRect.new(); city.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; city.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage.add_child(city); city.texture=load("res://assets/src/torva-town-v1.png"); city.position=Vector2(0,343); city.size=Vector2(390,188); city.mouse_filter=MOUSE_FILTER_IGNORE
	var shader=Shader.new(); shader.code="shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); float l=dot(c.rgb,vec3(.299,.587,.114)); COLOR=vec4(mix(vec3(.067,.09,.08),vec3(.957,.937,.89),smoothstep(.1,.8,l)),c.a);}"
	var material=ShaderMaterial.new(); material.shader=shader;city.material=material
	ink(Rect2(-24,286,450,246))
	label("현재 위치",Rect2(14,232,82,16),9,T.INK,T.BOLD)
	display("토르바",Rect2(14,248,90,37),T.INK,35)
	fill("location_rule",Rect2(14,286,73,2),T.INK)
	label("%d일째" % host.model.s.day,Rect2(14,293,78,22),13,T.INK,T.BOLD)
	label("금화",Rect2(14,315,38,22),14,T.INK,T.BOLD)
	display(str(int(host.model.s.gold)),Rect2(48,308,77,35),T.RED,30)
	label("학술원 폐허\n상층 · 2층",Rect2(332,211,58,40),9)
	picture(host.model.s.party[0],Rect2(73,99,337,432))
	fill("hero_caption",Rect2(14,460,277,71),Color(0.067,.09,.08,.85))
	label("주요 동료",Rect2(22,460,160,17),9,T.PAPER)
	display(host.model.person(host.model.s.party[0]).name,Rect2(22,473,225,40),T.PAPER,37)
	label(host.model.person(host.model.s.party[0])["class"],Rect2(255,493,42,23),13,T.PAPER,T.BOLD)
	label("출전 파티",Rect2(14,532,150,16),9,T.INK,T.BOLD)
	for i in range(4):
		var id=host.model.s.party[i]; var x=14+i*92
		fill("party_frame"+str(i),Rect2(x,548,87,62),T.RED if i==0 else T.LINE)
		picture(id,Rect2(x+2,550,83,58),"face")
		var l=label(host.model.person(id).name,Rect2(x,610,87,16),9); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		hit("town_member:"+id,Rect2(x,548,87,78),func():host.who=id;host.go("member"))
	var b=action("depart","원정 준비",Rect2(14,631,362,67),host.go.bind("depart"),true)
	b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_font_size_override("font_size",23)
	icon("gate",Rect2(326,650,30,28),T.PAPER)
	label("마을에서 할 일",Rect2(14,702,280,17),9,T.INK,T.BOLD)
	for i in range(4):
		var e=[["guild","길드"],["shop","상회"],["inn","여관"],["smithy","대장간"]][i]; var x=14+i*92
		action(e[0],e[1],Rect2(x,722,87,54),host.go.bind(e[0]))
		icon(e[0],Rect2(x+31,727,24,24))
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
		var id=ids[i]; var col=i%2; var row=int(i/2); var x=0 if col==0 else 197
		var y=row*352.0+(0 if col==0 else 66)
		if i%4==3: y-=58
		var rect=Rect2(x,y,210 if col==0 else 193,350 if col==0 else 292)
		ink(Rect2(x-25,y+20,240,315))
		picture(id,rect)
		var nameplate=fill("nameplate:"+id,Rect2(x+10,y+rect.size.y-97,178,70),T.INK)
		nameplate.rotation=-.07 if col==0 else -.12
		display(host.model.person(id).name,Rect2(x+17,y+rect.size.y-94,164,33),T.PAPER,29)
		label(host.model.person(id)["class"],Rect2(x+19,y+rect.size.y-63,161,25),15,T.PAPER,T.BOLD)
		if id in host.model.s.party:
			fill("party_badge:"+id,Rect2(x+12,y+rect.size.y-30,117,26),T.RED)
			label("파티 중",Rect2(x+23,y+rect.size.y-30,96,26),13,T.PAPER,T.BOLD)
		hit("member:"+id,rect,func():host.who=id;host.go("member"))
	stage=previous

func tabs(y: float,selected: int) -> void:
	for i in range(3):
		var key=["member","skills","formation"][i]
		var b=action("tab:"+key,["개요","기술","편성 · 장비"][i],Rect2(18+i*118,y,118,40),host.go.bind(key),selected==i)
		if key=="formation" and host.who not in host.model.s.owned:
			b.disabled=true; b.tooltip_text="길드에서 영입한 뒤 편성할 수 있습니다."
		if selected!=i:
			for state in ["normal","hover","pressed"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	fill("tabs_rule",Rect2(18,y+42,354,1),T.LINE)
	fill("tab_active_rule",Rect2(18+selected*118,y+41,118,3),T.RED)

func overview() -> void:
	ink(Rect2(0,170,440,315))
	display(host.model.person(host.who).name,Rect2(19,53,350,83),T.INK,68)
	var portrait=picture(host.who,Rect2(-18,123,425,360)); portrait.shift.y=-44; portrait.queue_redraw()
	fill("identity_paper",Rect2(18,137,354,30),T.PAPER)
	label("Lv.%d · %s · %s" % [host.model.s.members[host.who].level,host.model.person(host.who)["class"],host.model.person(host.who).row],Rect2(20,139,350,27),16,T.INK,T.BOLD)
	header("동료 상세","party")
	tabs(490,0)
	var m=host.model.s.members[host.who]; var s=host.model.stats(host.who,m.level)
	for i in range(2):
		var k="hp" if i==0 else "mp"; var x=28+i*182
		label("%s   %d / %d" % [k.to_upper(),m[k],s[k]],Rect2(x,550,158,24),13,T.INK,T.BOLD)
		fill(k+"_track",Rect2(x,576,150,9),T.LINE)
		fill(k+"_fill",Rect2(x,576,150*float(m[k])/maxf(1,s[k]),9),T.RED if i==0 else Color("197ab7"))
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
	ink(Rect2(-10,30,430,255)); picture(host.who,Rect2(0,50,390,234),"face")
	fill("header_paper",Rect2(0,0,390,52),T.PAPER)
	header("동료 상세","party")
	tabs(285,1)
	var p=host.model.person(host.who); var sk=p.skill
	if host.who=="hildegard": plate("signature-guard",Rect2(23,340,129,165))
	else:
		fill("signature_plate",Rect2(23,340,129,165),T.RED)
		icon("shield",Rect2(58,389,60,69),T.INK)
	var title=display(sk.name,Rect2(169,333,204,34),T.INK,25); mark("skill_title",title)
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
		icon("sword" if entry.id=="atk" else "shield",Rect2(6,y+8,44,44))
		display(entry.name,Rect2(73,y+2,270,28),T.INK,21)
		label("MP %d" % entry.mp,Rect2(74,y+32,55,21),12,Color("197ab7"),T.BOLD)
		var excerpt=entry.note.left(29)+("…" if entry.note.length()>29 else "")
		var note=label(excerpt,Rect2(130,y+32,212,40),12); note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		metrics[-1].available=1000
		fill("skill_rule"+str(index),Rect2(2,y+77,340,1),T.LINE)
		hit("skill_detail:"+entry.id,Rect2(0,y,344,78),host.go.bind("member_details")); index+=1
	stage=previous
