extends Control
## Shared fluid shell: paper, brush titles, red actions; fixed navigation.
const L=preload("res://game/localization_r22.gd")
const T=preload("res://ui/town_theme_r21.gd")
const READABLE_RED=Color("#c62b15")
const R=preload("res://game/panels_rules_r22.gd")
const Portrait=preload("res://ui/portrait_rules_r22.gd")
const Research=preload("res://game/persona_research_r21.gd")
const View=preload("res://game/ui_semantics_r23.gd")
var host
var state
var body: VBoxContainer
var scroll: ScrollContainer
var frame: Control
var metrics=[]
func setup(owner_screen,heading: String) -> void:
	host=owner_screen;state=host.panels_r22;theme=T.make_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper=ColorRect.new();add_child(paper);paper.color=T.PAPER;paper.mouse_filter=MOUSE_FILTER_IGNORE;paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame=Control.new();add_child(frame);frame.size=Vector2(minf(430,host.size.x),host.size.y);frame.position.x=(host.size.x-frame.size.x)/2
	var title=Label.new();frame.add_child(title);title.position=Vector2(18,12);title.size=Vector2(frame.size.x-112,58);title.text=L.render(heading,L.language(host.model.s));title.add_theme_font_override("font",T.DISPLAY);title.add_theme_font_size_override("font_size",38);title.clip_text=true;title.size.x=frame.size.x-112;L.fit_title(title,38)
	var back=button("p7_back","뒤로",host.go.bind(host.panels_return,false),false,false,frame);back.position=Vector2(frame.size.x-88,20);back.size=Vector2(70,44);back.size_flags_horizontal=0
	var tabs=HBoxContainer.new();frame.add_child(tabs);tabs.position=Vector2(18,82);tabs.size=Vector2(frame.size.x-36,48);tabs.add_theme_constant_override("separation",6)
	for e in [["codex","도감"],["status","상태"],["inventory","장비 가방"]]:button("p7_tab_"+e[0],e[1],switch_panel.bind(e[0]),host.screen==e[0],false,tabs)
	scroll=ScrollContainer.new();frame.add_child(scroll);scroll.position=Vector2(18,148);scroll.size=Vector2(frame.size.x-36,frame.size.y-226);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12)
	var nav=HBoxContainer.new();frame.add_child(nav);nav.position=Vector2(12,frame.size.y-62);nav.size=Vector2(frame.size.x-24,50);nav.add_theme_constant_override("separation",4)
	for e in [["town","마을"],["party","동료"],["depart","원정"],["bag","가방"],["journal","기록"]]:
		var selected="bag" if host.screen=="inventory" else "party"
		var b=button("nav:"+e[0],e[1],host.go.bind("explore" if e[0]=="depart" and host.model.active() else e[0]),selected==e[0],false,nav);b.add_theme_font_size_override("font_size",13)
	if state.ui.msg!="":text(state.ui.msg,14,T.RED)
	if host.save_error!=OK:
		text("저장하지 못했습니다. 다시 시도해 주세요.",14,T.RED);button("save_retry","저장 다시 시도",func():host._save();host._draw_screen())
func text(value: String,fs=15,color=T.INK,parent: Node=null) -> Label:
	var l=Label.new();(parent if parent else body).add_child(l);l.text=L.render(value,L.language(host.model.s)).replace("{{user}}","당신");l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=SIZE_EXPAND_FILL;l.add_theme_font_size_override("font_size",fs);l.add_theme_color_override("font_color",READABLE_RED if color==T.RED else color)
	if fs>=21:l.add_theme_font_override("font",T.DISPLAY)
	l.mouse_filter=MOUSE_FILTER_IGNORE;return l
func button(id: String,value: String,fn: Callable,selected=false,disabled=false,parent: Node=null) -> Button:
	var spec=View.button(id,L.render(value,L.language(host.model.s)),("on " if selected else "")+("off" if disabled else ""))
	var b=Button.new();(parent if parent else body).add_child(b);b.text=spec.text;b.set_meta("source_action",id);b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.custom_minimum_size=Vector2(44,48);b.size_flags_horizontal=SIZE_EXPAND_FILL;b.disabled=spec.disabled;b.add_theme_font_size_override("font_size",14)
	if selected:
		for s in ["normal","hover","pressed"]:b.add_theme_stylebox_override(s,T.panel(READABLE_RED,READABLE_RED))
		for s in ["font_color","font_hover_color","font_pressed_color"]:b.add_theme_color_override(s,T.PAPER)
	b.pressed.connect(fn);host.controls[id]=b;return b
func row(parent: Node=null) -> HBoxContainer:
	var h=HBoxContainer.new();(parent if parent else body).add_child(h);h.add_theme_constant_override("separation",8);return h
func section(name: String,parent: Node=null) -> void:
	var gap=Control.new();(parent if parent else body).add_child(gap);gap.custom_minimum_size.y=8
	text(name,23,T.INK,parent)
	var line=HSeparator.new();(parent if parent else body).add_child(line)
func choose(id: String,values: Array,current: String,fn: Callable,parent: Node=null) -> OptionButton:
	var o=OptionButton.new();(parent if parent else body).add_child(o);o.custom_minimum_size.y=48;o.size_flags_horizontal=SIZE_EXPAND_FILL;o.fit_to_longest_item=false
	var found=false
	for i in range(values.size()):
		o.add_item(L.render(values[i][1],L.language(host.model.s)));o.set_item_metadata(i,values[i][0])
		if values[i][0]==current:o.select(i);found=true
	if not found:o.select(-1)
	o.item_selected.connect(func(i):fn.call(o.get_item_metadata(i)));host.controls[id]=o;return o
func cx(arg: String) -> void:
	state.ui.msg="";state.cx(arg)
	if arg=="bag" and state.ui.tab=="bag":host.screen="inventory"
	host._save();host._draw_screen()
func switch_panel(page: String) -> void:
	# The bag is a status tab; switching HUD panels clears the old selection.
	if page=="inventory":
		if state.ui.panel!="status":state.hd("status")
		state.st("t_bag")
	else:
		if state.ui.panel!=page:state.hd(page)
		if page=="status":state.st("t_me")
	host._save();host.go(page)
func bg(arg: String) -> void:
	state.ui.msg="";state.bg_action(arg);host._save();host._draw_screen()
	if arg=="sell" and state.bg.conf!="":host.town_view.scroll.call_deferred("ensure_control_visible",host.controls.p7_bg_sell)
func pager(items: Array,pg: int,count: int,kind: String) -> void:
	var p=R.page(items,pg,count);var h=row()
	button("p7_prev","이전",cx.bind("pg_"+str(p.page-1)) if kind=="cx" else bg.bind("pg_"+str(p.page-1)),false,p.page<=1,h)
	var label=text("%d / %d"%[p.page,p.pages],14,T.MUTED,h);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.size_flags_vertical=SIZE_SHRINK_CENTER
	button("p7_next","다음",cx.bind("pg_"+str(p.page+1)) if kind=="cx" else bg.bind("pg_"+str(p.page+1)),false,p.page>=p.pages,h)
func portrait(id: String,parent: Node,dims: Vector2) -> Control:
	var p=Portrait.new();parent.add_child(p);p.custom_minimum_size=dims;p.configure(id);return p
func stats(values: Dictionary,level: int,xp: int) -> void:
	section("능력치 · Lv %d"%level)
	var exp_view=View.experience(level,xp,L.language(host.model.s));text(exp_view.text,14,T.MUTED)
	var meter=ProgressBar.new();body.add_child(meter);meter.custom_minimum_size.y=8;meter.show_percentage=false;meter.max_value=1;meter.value=exp_view.ratio
	var grid=GridContainer.new();body.add_child(grid);grid.columns=3;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",10)
	for s in View.stats(values,L.language(host.model.s)):
		var v=VBoxContainer.new();grid.add_child(v);v.size_flags_horizontal=SIZE_EXPAND_FILL
		text(s[0],13,T.MUTED,v);text(s[1],22,T.INK,v)
func affection(value: float) -> void:
	var a=R.shown_aff(value);var p=R.AFF.progress(a)
	var h=row();text(p.stage,21,T.RED,h);text("%d / 200"%a,15,T.MUTED,h).horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var bar=ProgressBar.new();body.add_child(bar);bar.custom_minimum_size.y=8;bar.show_percentage=false;bar.max_value=1;bar.value=View.bar(a,200);bar.add_theme_stylebox_override("background",T.panel(T.PALE,T.PALE));bar.add_theme_stylebox_override("fill",T.panel(READABLE_RED,READABLE_RED))
	text("최고 단계" if p.next=="" else "%s까지 %s"%[p.next,Research.num(p.remaining)],13,T.MUTED)
func passives(key: String,race: String,lineage: String,nation: String) -> void:
	var ids={"races":"","nations":""}
	for spec in [["races",race],["nations",nation]]:
		for id in View.PASS[spec[0]]:
			var node=View.PASS[spec[0]][id]
			if spec[1] in [id,node.name,node.get("short","")]:ids[spec[0]]=id;break
	var lin="cat" if lineage in ["고양이과","cat"] else "dog" if lineage in ["개과","dog"] else ""
	for group in View.passive_groups(R.cls(key).get("id",""),ids.races,lin,ids.nations,L.language(host.model.s)):
		section(group.title)
		for e in group.entries:
			text(e[0]+(" "+e[1] if e[1]!="" else ""),18)
			if e[2]!="":text(e[2])
		for tier in group.tiers:text(" ".join(tier).strip_edges(),14,T.MUTED)
func persona() -> void:
	var p=host.model.s.get("persona",{});var name=p.get("name","");var h=row();portrait("persona",h,Vector2(72,110));var b=VBoxContainer.new();h.add_child(b);b.size_flags_horizontal=SIZE_EXPAND_FILL
	text("이름 없는 모험가" if name=="" else name,27,T.INK,b);text(" · ".join([p.get("race",""),p.get("nation",""),p.get("cls","")]).trim_prefix(" · "),14,T.MUTED,b)
	text("전투 참여" if p.get("fight",0)==1 else "전투 불참",14,T.RED,b)
	stats(R.persona_stats(p),state.level(),int(p.get("exp",0)));section("고유 스킬");text(Research.skill_name(p.get("skill",{})),18);text(Research.description(p.get("skill",{})))
	passives(p.get("cls",""),p.get("race",""),p.get("lineage",""),p.get("nation",""))
func gear_card(e: Dictionary,level: int) -> void:
	var item=host.model.gear.by_id[e.id];var h=row();gear_icon(item,h);var copy=VBoxContainer.new();h.add_child(copy);copy.size_flags_horizontal=SIZE_EXPAND_FILL
	text(L.t(item.name,L.language(host.model.s)),24,T.INK,copy);text("%s · Lv %d"%[L.t(host.model.Gear.RARITY[item.rarity],L.language(host.model.s)),host.model.gear.rules.equip_lv[item.rarity]],14,T.MUTED,copy)
	var detail=preload("res://game/panel_gear_r22.gd").describe(host.model.gear,e,level);var values=detail.fx
	var u=item.get("sig",item.get("unique",{}))
	for group in View.gear_groups({"item":item,"fx":values,"affix":detail.affix,"unique":u},L.language(host.model.s)):
		text(group.title,14,T.MUTED)
		for line in group.lines:text(line,15)
func gear_icon(item: Dictionary,parent: Node) -> TextureRect:
	var border=PanelContainer.new();parent.add_child(border);border.add_theme_stylebox_override("panel",T.panel(T.PAPER,View.COLORS[item.rarity]));border.set_meta("source_rarity",item.rarity)
	var image=TextureRect.new();border.add_child(image);image.texture=load(View.icon_path(item));image.custom_minimum_size=Vector2(44,44);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=MOUSE_FILTER_IGNORE;image.set_meta("source_icon",View.icon(item));return image
func gear_tile(id: String,item: Dictionary,fn: Callable,sub: Variant=null,disabled=false,parent: Node=null) -> Button:
	var spec=View.tile(item,id,sub,L.language(host.model.s));var b=button(id,spec.text,fn,false,disabled,parent)
	b.icon=load(View.icon_path(item));b.expand_icon=true;b.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT;b.add_theme_constant_override("icon_max_width",44);b.custom_minimum_size.y=64;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.set_meta("source_icon",spec.icon);b.set_meta("source_rarity",spec.rarity)
	for key in ["normal","hover","pressed"]:b.add_theme_stylebox_override(key,T.panel(T.PAPER,View.COLORS[spec.rarity]))
	return b
func fx_name(key: String,job: String) -> String:
	return preload("res://game/panel_gear_r22.gd").effect_name(host.model.gear,key,job)
func fx_value(key: String,value: float) -> String:
	return preload("res://game/panel_gear_r22.gd").effect_value(host.model.gear,key,value)
