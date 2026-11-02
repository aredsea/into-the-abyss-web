extends "res://ui/panel_screen_r22.gd"
## Read surface in the existing town paper / brush / vermilion grammar.
const Places=preload("res://game/town_places_r22.gd")
const Chronicle=preload("res://game/chronicle_store_r22.gd")
const ACTION_RED=Color("#c62b15")
var view
func button(id: String,value: String,fn: Callable,selected=false,disabled=false,parent: Node=null) -> Button:
	var b=super(id,value,fn,selected,disabled,parent)
	if selected:
		for key in ["normal","hover","pressed"]:b.add_theme_stylebox_override(key,T.panel(ACTION_RED,ACTION_RED))
	return b
func build(owner_screen) -> void:
	host=owner_screen;view=host.journal_r22;theme=T.make_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper=ColorRect.new();add_child(paper);paper.color=T.PAPER;paper.mouse_filter=MOUSE_FILTER_IGNORE;paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame=Control.new();add_child(frame);frame.size=Vector2(minf(430,host.size.x),host.size.y);frame.position.x=(host.size.x-frame.size.x)/2
	var title=Label.new();frame.add_child(title);title.position=Vector2(18,12);title.size=Vector2(frame.size.x-112,58);title.text={"journal":"모험 기록","places":"토르바 산책","people":"토르바 인물"}[host.screen];title.add_theme_font_override("font",T.DISPLAY);title.add_theme_font_size_override("font_size",34)
	var back=button("p10_back","마을",host.go.bind("town"),false,false,frame);back.position=Vector2(frame.size.x-88,20);back.size=Vector2(70,44)
	var tabs=HBoxContainer.new();frame.add_child(tabs);tabs.position=Vector2(18,82);tabs.size=Vector2(frame.size.x-36,48);tabs.add_theme_constant_override("separation",6)
	for e in [["journal","연대기"],["places","마을 장소"],["people","인물 소개"]]:button("p10_tab_"+e[0],e[1],host.go.bind(e[0]),host.screen==e[0],false,tabs)
	scroll=ScrollContainer.new();frame.add_child(scroll);scroll.position=Vector2(18,148);scroll.size=Vector2(frame.size.x-36,frame.size.y-226);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12)
	var nav=HBoxContainer.new();frame.add_child(nav);nav.position=Vector2(12,frame.size.y-62);nav.size=Vector2(frame.size.x-24,50);nav.add_theme_constant_override("separation",4)
	for e in [["town","마을"],["party","동료"],["depart","원정"],["bag","보급품"],["journal","기록"]]:
		var b=button("nav:"+e[0],e[1],host.go.bind("explore" if e[0]=="depart" and host.model.active() else e[0]),host.screen==e[0],false,nav);b.add_theme_font_size_override("font_size",13)
	if host.save_error!=OK:text("저장하지 못했습니다.",14,ACTION_RED);button("save_retry","저장 다시 시도",func():host._save();host._draw_screen())
	match host.screen:
		"journal":journal()
		"places":places()
		"people":people()
func redraw() -> void:host._draw_screen()
func journal() -> void:
	var enabled=host.model.s.get("settings",{}).get("chron",1)!=0
	text("엔진이 확정한 사건을 날짜순으로 보관합니다.",15,T.MUTED)
	button("p10_toggle","기록 켜짐 · 끄기" if enabled else "기록 꺼짐 · 켜기",func():
		if not host.model.s.has("settings"):host.model.s.settings={}
		host.model.s.settings.chron=0 if enabled else 1;host._save();redraw())
	var h=row();button("p10_facts","연대기",func():view.legacy=false;redraw(),not view.legacy,false,h);button("p10_legacy","기존 활동",func():view.legacy=true;redraw(),view.legacy,false,h)
	var lines=host.model.s.log if view.legacy else Chronicle.entries(host.model.s)
	if lines.is_empty():
		section("아직 기록이 없습니다")
		text("첫 만남과 원정에서 확정된 사건이 여기에 남습니다." if not view.legacy else "이전에 남긴 활동이 없습니다.",15,T.MUTED);return
	text("최근 %d개 · 최신순"%lines.size(),13,T.MUTED)
	for i in range(lines.size()-1,-1,-1):
		var line=str(lines[i]);var re=RegEx.new();re.compile("^Day (-?[0-9]+): (.*)$");var m=re.search(line)
		if m:text(m.get_string(1)+"일째",13,ACTION_RED);text(m.get_string(2),16)
		else:text(line,16)
		body.add_child(HSeparator.new())
func places() -> void:
	var pid=view.place;var d=Places.DATA.places[pid]
	text(d.name,27);text(d.note,14,T.MUTED)
	if d.get("d","")!="":text(d.d,16)
	# No invented archive/gate/alley/shelter scenery. Only an existing town asset.
	if pid=="town":
		var image=TextureRect.new();body.add_child(image);image.texture=load("res://assets/ui-r21/bg-town.webp");image.custom_minimum_size.y=150;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.mouse_filter=MOUSE_FILTER_IGNORE
	var current=Places.place_id({"scene":"town","place":host.model.s.get("place","")})
	button("p10_visit","이곳으로 이동" if pid!=current else "현재 있는 곳",visit.bind(pid),pid==current,host.model.active() or pid==current)
	if pid in ["guild","shop","inn","smithy"]:button("p10_facility","시설 이용",host.go.bind(pid),false,host.model.active())
	section("이곳의 인물")
	var ids=Places.residents(pid)
	if ids.is_empty():text("상주 인물 없음",14,T.MUTED)
	for id in ids:button("p10_resident_"+id,Places.profile(id).get("name",id),open_person.bind(id))
	section("다른 장소")
	for id in Places.DATA.order:button("p10_place_"+id,Places.DATA.places[id].name,func():view.place=id;redraw(),id==pid)
func visit(pid: String) -> void:
	if host.model.active():return
	var g={"scene":"town","place":host.model.s.get("place",""),"ui":{}}
	if not Places.set_place(g,pid):return
	host.model.s.place=g.place
	if pid=="guild" and host.model.s.board.is_empty():host.model.fill_source_board()
	host._save()
	if g.scene!="town":host.go(g.scene)
	else:redraw()
func open_person(id: String) -> void:view.person=id;host.go("people")
func people() -> void:
	if view.person!="" and Places.DATA.profiles.has(view.person):
		var p=Places.profile(view.person);text(p.name,28)
		button("p10_people_back","인물 목록",func():view.person="";redraw())
		for raw in p.lines:
			var line=str(raw)
			if line.begins_with("## "):text(line.trim_prefix("## "),18,T.MUTED)
			else:text(line.trim_prefix("- ").replace("**",""),16)
		return
	text("토르바의 사람들과 각국 지도자",15,T.MUTED)
	for id in Places.DATA.profiles:
		var at=[]
		for pid in Places.DATA.order:
			if id in Places.residents(pid):at.append(Places.DATA.places[pid].name)
		button("p10_person_"+id,Places.profile(id).name,open_person.bind(id))
		text(" · ".join(at) if not at.is_empty() else "고정 위치 없음" if id=="knut" else "토르바 상주 아님",13,T.MUTED)
