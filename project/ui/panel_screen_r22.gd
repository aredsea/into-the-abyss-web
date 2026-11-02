extends Control
## Shared fluid shell: paper, brush titles, red actions; fixed navigation.
const T=preload("res://ui/town_theme_r21.gd")
const R=preload("res://game/panels_rules_r22.gd")
const Portrait=preload("res://ui/portrait_rules_r22.gd")
const Research=preload("res://game/persona_research_r21.gd")
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
	var title=Label.new();frame.add_child(title);title.position=Vector2(18,12);title.size=Vector2(frame.size.x-112,58);title.text=heading;title.add_theme_font_override("font",T.DISPLAY);title.add_theme_font_size_override("font_size",38)
	var back=button("p7_back","마을",host.go.bind("town"),false,false,frame);back.position=Vector2(frame.size.x-88,20);back.size=Vector2(70,44);back.size_flags_horizontal=0
	var tabs=HBoxContainer.new();frame.add_child(tabs);tabs.position=Vector2(18,82);tabs.size=Vector2(frame.size.x-36,48);tabs.add_theme_constant_override("separation",6)
	for e in [["codex","도감"],["status","상태"],["inventory","장비 가방"]]:button("p7_tab_"+e[0],e[1],host.go.bind(e[0]),host.screen==e[0],false,tabs)
	scroll=ScrollContainer.new();frame.add_child(scroll);scroll.position=Vector2(18,148);scroll.size=Vector2(frame.size.x-36,frame.size.y-226);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12)
	var nav=HBoxContainer.new();frame.add_child(nav);nav.position=Vector2(12,frame.size.y-62);nav.size=Vector2(frame.size.x-24,50);nav.add_theme_constant_override("separation",4)
	for e in [["town","마을"],["party","동료"],["depart","원정"],["bag","보급품"],["journal","기록"]]:
		var b=button("nav:"+e[0],e[1],host.go.bind("explore" if e[0]=="depart" and host.model.active() else e[0]),false,false,nav);b.add_theme_font_size_override("font_size",13)
	if state.ui.msg!="":text(state.ui.msg,14,T.RED)
	if host.save_error!=OK:
		text("저장하지 못했습니다. 다시 시도해 주세요.",14,T.RED);button("save_retry","저장 다시 시도",func():host._save();host._draw_screen())
func text(value: String,fs=15,color=T.INK,parent: Node=null) -> Label:
	var l=Label.new();(parent if parent else body).add_child(l);l.text=value.replace("{{user}}","당신");l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=SIZE_EXPAND_FILL;l.add_theme_font_size_override("font_size",fs);l.add_theme_color_override("font_color",color)
	if fs>=21:l.add_theme_font_override("font",T.DISPLAY)
	l.mouse_filter=MOUSE_FILTER_IGNORE;return l
func button(id: String,value: String,fn: Callable,selected=false,disabled=false,parent: Node=null) -> Button:
	var b=Button.new();(parent if parent else body).add_child(b);b.text=value;b.custom_minimum_size=Vector2(44,48);b.size_flags_horizontal=SIZE_EXPAND_FILL;b.disabled=disabled;b.add_theme_font_size_override("font_size",14)
	if selected:
		for s in ["normal","hover","pressed"]:b.add_theme_stylebox_override(s,T.panel(T.RED,T.RED))
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
	for i in range(values.size()):o.add_item(values[i][1]);o.set_item_metadata(i,values[i][0]);o.select(i if values[i][0]==current else o.selected)
	o.item_selected.connect(func(i):fn.call(o.get_item_metadata(i)));host.controls[id]=o;return o
func cx(arg: String) -> void:
	state.ui.msg="";state.cx(arg)
	if arg=="bag" and state.ui.tab=="bag":host.screen="inventory"
	host._save();host._draw_screen()
func bg(arg: String) -> void:
	state.bg_action(arg);host._save();host._draw_screen()
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
	text("최대 레벨" if level>=40 else "경험치 %d / %d"%[xp,host.model.need(level)],14,T.MUTED)
	var grid=GridContainer.new();body.add_child(grid);grid.columns=3;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",10)
	for s in [["hp","HP"],["mp","MP"],["str","힘"],["agi","민첩"],["int","지능"],["def","방어"],["spd","속도"]]:
		var v=VBoxContainer.new();grid.add_child(v);v.size_flags_horizontal=SIZE_EXPAND_FILL
		text(s[1],13,T.MUTED,v);text(str(values.get(s[0],"—")),22,T.INK,v)
func affection(value: float) -> void:
	var a=R.shown_aff(value);var p=R.AFF.progress(a)
	var h=row();text(p.stage,21,T.RED,h);text("%d / 200"%a,15,T.MUTED,h).horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var bar=ProgressBar.new();body.add_child(bar);bar.custom_minimum_size.y=8;bar.show_percentage=false;bar.max_value=200;bar.value=maxi(0,a);bar.add_theme_stylebox_override("background",T.panel(T.PALE,T.PALE));bar.add_theme_stylebox_override("fill",T.panel(T.RED,T.RED))
	text("최고 단계" if p.next=="" else "%s까지 %s"%[p.next,Research.num(p.remaining)],13,T.MUTED)
func passives(key: String,race: String,lineage: String,nation: String) -> void:
	var c=R.cls(key);var p=R.DATA.passives
	section("직업 패시브")
	var job=p.classes.get(c.get("id",""),{})
	if job.is_empty():text("직업을 고르면 보입니다.",14,T.MUTED)
	else:text(job.name,18);text(job.text)
	for spec in [["종족 특성","races",race],["출신 특성","nations",nation]]:
		var node={}
		for k in p[spec[1]]:
			if p[spec[1]][k].name==spec[2] or p[spec[1]][k].get("short","")==spec[2]:node=p[spec[1]][k];break
		if node.is_empty():continue
		section(spec[0]+" · "+node.name)
		for e in node.get("own",[]):text(e.name,18);text(e.text)
		if node.has("lin"):
			var keys=["cat"] if lineage in ["고양이과","cat"] else ["dog"] if lineage in ["개과","dog"] else ["dog","cat"]
			for k in keys:text(node.lin[k].name,18);text(node.lin[k].text)
		for i in range(node.get("tier",[]).size()):
			text("%d명 · %s%s"%[i+2,node.tier[i]," · 준비 중" if node.get("wip",[]).size()>i and node.wip[i] else ""],14,T.MUTED)
func persona() -> void:
	var p=host.model.s.get("persona",{});var name=p.get("name","");var h=row();portrait("persona",h,Vector2(72,110));var b=VBoxContainer.new();h.add_child(b);b.size_flags_horizontal=SIZE_EXPAND_FILL
	text("이름 없는 모험가" if name=="" else name,27,T.INK,b);text(" · ".join([p.get("race",""),p.get("nation",""),p.get("cls","")]).trim_prefix(" · "),14,T.MUTED,b)
	text("전투 참여" if p.get("fight",0)==1 else "전투 불참",14,T.RED,b)
	stats(R.persona_stats(p),int(p.get("lv",1)),int(p.get("exp",0)));section("고유 스킬");text(Research.skill_name(p.get("skill",{})),18);text(Research.description(p.get("skill",{})))
	passives(p.get("cls",""),p.get("race",""),p.get("lineage",""),p.get("nation",""))
func gear_card(e: Dictionary,level: int) -> void:
	var item=host.model.gear.by_id[e.id];text(item.name,24);text("%s · Lv %d · %s%s"%[host.model.Gear.RARITY[item.rarity],host.model.gear.rules.equip_lv[item.rarity],host.model.Gear.SLOT[item.slot]," · +%d"%e.forge if e.forge>0 else ""],14,T.MUTED)
	var detail=preload("res://game/panel_gear_r22.gd").describe(host.model.gear,e,level);var values=detail.fx
	text("기본 효과",14,T.MUTED)
	for k in R.DATA.fx_order:
		if item.base.has(k):text(fx_name(k,item.cls)+"  "+fx_value(k,values[k]),15)
	if not detail.affix.is_empty():text("무작위 옵션",14,T.MUTED)
	for a in detail.affix:text(fx_name(a[0],item.cls)+"  "+fx_value(a[0],a[1]),15)
	var u=item.get("sig",item.get("unique",{}))
	if not u.is_empty():text("고유 효과",14,T.MUTED);text(u.get("name","고유 효과"),18);text(u.get("text",""),14)
	if item.get("flavor","")!="":text(item.flavor,14,T.MUTED)
func fx_name(key: String,job: String) -> String:
	if key=="stat":return R.cls(job).get("line","계열 능력치")
	var fx=host.model.gear.rules;return fx.base.get(key,fx.affix.get(key,{})).get("name",key)
func fx_value(key: String,value: float) -> String:
	var fx=host.model.gear.rules;return ("+" if value>=0 else "")+Research.num(value)+fx.base.get(key,fx.affix.get(key,{})).get("unit","")
