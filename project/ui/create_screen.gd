extends Control
## Native, mobile-first P1 form. Inherits the r21 paper / brush / vermilion system.
const L=preload("res://game/localization_r22.gd")
const T=preload("res://ui/town_theme_r21.gd")
const READABLE_RED=T.ACTION_RED
var host
var rules
var body: VBoxContainer
var scroll: ScrollContainer
var frame: Control
var footer: HBoxContainer
var title: Control
var metrics=[]

func setup(owner_screen,heading: String) -> void:
	host=owner_screen;rules=host.model.persona_rules;theme=T.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg=ColorRect.new();add_child(bg);bg.color=T.PAPER;bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.mouse_filter=MOUSE_FILTER_IGNORE
	frame=Control.new();add_child(frame);frame.size=Vector2(minf(host.size.x,900 if host.size.x>=900 else 430),host.size.y);frame.position.x=(host.size.x-frame.size.x)/2
	if L.language(host.model.s)=="ko":
		title=TextureRect.new();frame.add_child(title);title.position=Vector2(18,12);title.size=Vector2(frame.size.x*.72,58);title.texture=load("res://assets/ui-r21/title-"+("meeting" if heading=="첫 만남" else "create")+".svg");title.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;title.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;title.mouse_filter=MOUSE_FILTER_IGNORE
	else:
		title=Label.new();frame.add_child(title);title.position=Vector2(18,12);title.size=Vector2(frame.size.x-36,58);title.text=L.render(heading,L.language(host.model.s));title.add_theme_font_override("font",T.DISPLAY);title.add_theme_font_size_override("font_size",38)
	scroll=ScrollContainer.new();frame.add_child(scroll);scroll.position=Vector2(18,132);scroll.size=Vector2(frame.size.x-36,frame.size.y-228);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12)
	footer=HBoxContainer.new();frame.add_child(footer);footer.position=Vector2(18,frame.size.y-68);footer.size=Vector2(frame.size.x-36,50);footer.add_theme_constant_override("separation",12)
	T.rule(frame,frame.size.y-80,frame.size.x-36)

func text(value: String,fs=15,color=T.INK,parent: Node=null) -> Label:
	var l=Label.new();(parent if parent else body).add_child(l);l.text=L.render(value,L.language(host.model.s)).replace("{{user}}","당신");l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=SIZE_EXPAND_FILL;l.add_theme_font_size_override("font_size",fs);l.add_theme_color_override("font_color",READABLE_RED if color==T.RED else color)
	if fs>=20:l.add_theme_font_override("font",T.DISPLAY)
	return l
func button(id: String,value: String,fn: Callable,selected=false,disabled=false,parent: Node=null) -> Button:
	var b=Button.new();(parent if parent else body).add_child(b);b.text=L.render(value,L.language(host.model.s));b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.custom_minimum_size=Vector2(44,48);b.size_flags_horizontal=SIZE_EXPAND_FILL;b.disabled=disabled;b.add_theme_font_size_override("font_size",15)
	T.dress_button(b,selected)
	b.pressed.connect(fn);host.controls[id]=b;return b
func row() -> HBoxContainer:
	var h=HBoxContainer.new();body.add_child(h);h.add_theme_constant_override("separation",8);return h
func choices() -> GridContainer:
	var grid=GridContainer.new();body.add_child(grid);grid.columns=2 if frame.size.x>=900 else 1;grid.add_theme_constant_override("h_separation",20);grid.add_theme_constant_override("v_separation",8);return grid

func choice(id: String,name_text: String,description: String,fn: Callable,selected=false,parent: Node=null) -> Button:
	var b=button(id,"",fn,selected,false,parent)
	# Keep the native button's accessible name; authored child labels carry its ink.
	b.text=L.render(name_text,L.language(host.model.s))
	for state in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]:b.add_theme_color_override(state,Color.TRANSPARENT)
	b.tooltip_text=L.render(name_text+"\n"+description,L.language(host.model.s))
	var margin=MarginContainer.new();b.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.offset_left=12;margin.offset_right=-12;margin.offset_top=10;margin.offset_bottom=-10;margin.mouse_filter=MOUSE_FILTER_IGNORE
	var h=HBoxContainer.new();margin.add_child(h);h.add_theme_constant_override("separation",12);h.mouse_filter=MOUSE_FILTER_IGNORE
	var stack=VBoxContainer.new();h.add_child(stack);stack.size_flags_horizontal=SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",4);stack.mouse_filter=MOUSE_FILTER_IGNORE
	var name_label=text(name_text,20,T.PAPER if selected else T.INK,stack);name_label.mouse_filter=MOUSE_FILTER_IGNORE
	var desc=text(description,13,T.PAPER if selected else T.MUTED,stack);desc.mouse_filter=MOUSE_FILTER_IGNORE
	var arrow=text("→",28,T.PAPER if selected else T.INK,h);arrow.autowrap_mode=TextServer.AUTOWRAP_OFF;arrow.custom_minimum_size.x=32;arrow.size_flags_horizontal=SIZE_SHRINK_END;arrow.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;arrow.mouse_filter=MOUSE_FILTER_IGNORE
	var fit=func():b.custom_minimum_size.y=maxf(78,margin.get_combined_minimum_size().y+20)
	margin.minimum_size_changed.connect(fit);fit.call()
	return b

func step_heading(value: String) -> void:
	text(value,23);T.heading_rule(body)

func act(arg: String,kind="cr") -> void:
	# Rebuilding a selection must not send the user back to the top of a long form.
	var old_scene=host.model.s.scene;var old_page=int(host.model.s.ui.page);var old_scroll=scroll.scroll_vertical
	var focus_id=""
	for id in host.controls:
		if host.controls[id]==get_viewport().gui_get_focus_owner():focus_id=id;break
	host.model.create_action(arg,kind);host._save()
	if host.model.s.scene=="town":host.who=host.model.s.owned[0];host.screen="town"
	host._draw_screen()
	if host.model.s.scene==old_scene and int(host.model.s.ui.page)==old_page and is_instance_valid(host.town_view) and host.town_view.has_method("restore_scroll"):
		host.town_view.call_deferred("restore_scroll",old_scroll,focus_id)

func restore_scroll(offset: int,focus_id: String) -> void:
	scroll.scroll_vertical=offset
	if host.controls.has(focus_id) and body.is_ancestor_of(host.controls[focus_id]):
		var target=host.controls[focus_id]
		scroll.ensure_control_visible(target.get_parent() if target.get_parent() is HBoxContainer else target)
func traits(entry: Dictionary) -> void:
	if entry.is_empty():return
	text(entry.name,23)
	if entry.has("d"):text(entry.d)
	if not entry.get("tr","").is_empty():text(entry.tr+" · "+entry.get("te",""))
	if entry.has("syn"):text(L.u("시너지 2명이면 {effect}",{"effect":rules.syn_text(entry,L.language(host.model.s))},L.language(host.model.s)),14,T.MUTED)

func build(owner_screen) -> void:
	var s=owner_screen.model.s;var page=int(s.ui.page)
	setup(owner_screen,"첫 만남" if s.scene=="scenario" else "새 모험가")
	var p=rules.view(s)
	var options=button("p8_open","설정",func():host.open_settings_r22(),false,false,frame);options.position=Vector2(frame.size.x-114,20);options.size=Vector2(96,44)
	title.size.x=minf(240,frame.size.x-144)
	if title is Label:L.fit_title(title,30)
	if s.scene=="scenario":scenario();return
	var steps=HBoxContainer.new();frame.add_child(steps);steps.position=Vector2(18,77);steps.size=Vector2(frame.size.x-36,44);steps.add_theme_constant_override("separation",4)
	for n in range(1,6):
		var step=button("cr_go_"+str(n),rules.data.steps[n-1],act.bind("go_"+str(n)),n==page,not rules.reach(p,n),steps);step.add_theme_font_size_override("font_size",13)
		for state in ["normal","hover","pressed","disabled","focus"]:
			var style=step.get_theme_stylebox(state).duplicate();style.content_margin_left=4;style.content_margin_right=4;step.add_theme_stylebox_override(state,style)
	if not s.ui.msg.is_empty():text(s.ui.msg,14,T.RED)
	if page==1:button("cloud_open","기존 모험 불러오기",host.go.bind("cloud"))
	match page:
		1:
			step_heading("어떤 종족으로 살아왔나요?")
			var grid=choices()
			for r in rules.data.races:
				choice("cr_race_"+r.id,r.name,r.tag,act.bind("race_"+r.id),p.race==r.name,grid)
			if p.race=="수인":
				text("계통",19);var h=choices()
				for l in rules.data.lineages:choice("cr_lin_"+l.id,l.name,l.tag,act.bind("lin_"+l.id),p.lineage==l.name,h)
				traits(rules.by(rules.data.lineages,"name",p.lineage))
			traits(rules.by(rules.data.races,"name",p.race))
		2:
			step_heading("어느 땅에서 왔나요?");var grid=choices()
			for n in rules.data.nations:
				var bl=rules.blocked(p.race,n.id)
				var b=choice("cr_nat_"+n.id,n.name+(" · 선택 불가" if not bl.is_empty() else ""),n.tag,act.bind("nat_"+n.id),p.nation==n.name,grid)
				if not bl.is_empty():
					b.tooltip_text=bl.m
					for label in b.find_children("*","Label",true,false):label.add_theme_color_override("font_color",T.MUTED)
			traits(rules.by(rules.data.nations,"name",p.nation));text(rules.note(p,rules.nation_id(p.nation)),14,T.MUTED)
		3:
			step_heading("어떤 방식으로 싸우나요?");var grid=choices()
			for c in rules.data.classes:choice("cr_cls_"+c.id,c.name,c.line+" / "+c.row,act.bind("cls_"+c.id),p.cls==c.name,grid)
			var c=rules.cls(p.cls)
			if not c.is_empty():
				text(c.name,23);text(rules.data.descriptions[c.id]);text(" · ".join(c.skills),14)
				text("체력 %d · 마력 %d\n힘 %d · 민첩 %d · 지능 %d · 방어 %d · 속도 %d"%[c.hp,c.mp,c.str,c.agi,c.int,c.def,c.spd],14)
				text(rules.data.class_notes.get(rules.nation_id(p.nation),{}).get(c.id,""),14,T.MUTED)
		4:points(p)
		5:
			step_heading("이 모험가로 시작할까요?")
			text(p.race+(" · "+p.lineage if p.lineage!="" else ""),20);text(p.nation);text(p.cls,20,T.RED)
			var b=rules.calc(p)
			text("체력 %d · 마력 %d\n힘 %d · 민첩 %d · 지능 %d\n방어 %d · 속도 %d"%[b.hp,b.mp,b.str,b.agi,b.int,b.def,b.spd],18)
			text("직접 싸울지는 던전에 나설 때마다 고릅니다.",14,T.MUTED)
	if page>1:button("cr_back","뒤로",act.bind("back"),false,false,footer)
	button("cr_done" if page==5 else "cr_next","이 모험가로 결정" if page==5 else "다음",act.bind("done" if page==5 else "next"),true,not rules.reach(p,5) if page==5 else not rules.ok(p,page),footer)
	if host.save_error!=OK:text("저장하지 못했습니다. 다시 시도해 주세요.",14,T.RED);button("save_retry","저장 다시 시도",func():host._save();host._draw_screen())

func points(p: Dictionary) -> void:
	step_heading("보너스 총량");var h=row()
	for n in [5,10,20]:button("cr_tot_"+str(n),L.u("{n}점",{"n":n},L.language(host.model.s)),act.bind("tot_"+str(n)),p.bonus_custom!=1 and rules.total(p)==n,false,h)
	button("cr_tot_free","직접 정하기",act.bind("tot_free"),p.bonus_custom==1)
	if p.bonus_custom==1:
		h=row()
		for value in [["m5","−5"],["m1","−1"],["p1","+1"],["p5","+5"]]:button("cr_tot_"+value[0],value[1],act.bind("tot_"+value[0]),false,false,h)
	text("남은 점수 %d / %d"%[rules.left(p),rules.total(p)],22,T.RED)
	text("한 능력치 최대 %d점 · 속도는 1점에 +2"%rules.cap(rules.total(p)),14,T.MUTED)
	var c=rules.cls(p.cls)
	for stat in rules.data.stats:
		h=row();var k=stat[0];var b=int(p.bonus.get(k,0));var l=text("%s  %d  (+%d)"%[L.render(stat[1],L.language(host.model.s)),c[k]+b*stat[2],b*stat[2]],17,T.INK,h);l.size_flags_horizontal=SIZE_EXPAND_FILL
		button("cr_dn_"+k,"−",act.bind("dn_"+k),false,b==0,h).size_flags_horizontal=0
		button("cr_up_"+k,"+",act.bind("up_"+k),false,rules.left(p)<=0 or b>=rules.cap(rules.total(p)),h).size_flags_horizontal=0
	h=row();button("cr_auto","직업 추천대로",act.bind("auto"),false,false,h);button("cr_clear","점수 비우기",act.bind("clear"),false,false,h)
	text("체력 %d · 마력 %d"%[c.hp,c.mp],15)

func scenario() -> void:
	var ribbon=TextureRect.new();frame.add_child(ribbon);ribbon.position=Vector2(0,81);ribbon.size=Vector2(frame.size.x,38);ribbon.texture=load("res://assets/ui-r21/button-ink.svg");ribbon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;ribbon.mouse_filter=MOUSE_FILTER_IGNORE
	var caption=text("토르바에서 이어질 첫 인연",16,T.PAPER,frame);caption.position=Vector2(18,87);caption.size=Vector2(frame.size.x-36,28)
	var selected=rules.by(rules.data.scenarios,"id",host.model.s.ui.sel)
	if not selected.is_empty():
		var portrait_frame=CenterContainer.new();body.add_child(portrait_frame);portrait_frame.custom_minimum_size.y=280
		var portrait=preload("res://ui/town_portrait_r21.gd").new();portrait_frame.add_child(portrait);portrait.custom_minimum_size=Vector2(minf(frame.size.x-36,340),280);portrait.configure(selected.companion,"detail-overview")
		text(host.model.person(selected.companion).name,27)
		text(selected.title,20,T.RED);text(selected.place,14,T.MUTED);text(selected.text,16)
	else:text("만남을 고르면 장면이 미리 보입니다. 시작하면 이 동료와 함께 토르바에서 출발합니다.",15,T.MUTED)
	text("누구와 마주치나요?",20)
	var grid=choices()
	for sc in rules.scenarios(rules.data.scenarios):
		choice("sc_pick_"+sc.id,host.model.person(sc.companion).name,sc.title,act.bind("pick_"+sc.id,"sc"),host.model.s.ui.sel==sc.id,grid)
	button("sc_back","만들기로",act.bind("back","sc"),false,false,footer)
	button("sc_go","이 만남으로 시작",act.bind("go","sc"),true,selected.is_empty(),footer)
