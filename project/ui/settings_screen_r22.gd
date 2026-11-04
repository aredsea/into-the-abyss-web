extends "res://ui/panel_screen_r22.gd"
## Operate: original controls in the existing parchment shell, no host-only controls.
const Settings=preload("res://game/settings_rules_r22.gd")
const ACTION=T.RED
func build(owner_screen) -> void:
	host=owner_screen;theme=T.make_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper=ColorRect.new();add_child(paper);paper.color=T.PAPER;paper.mouse_filter=MOUSE_FILTER_IGNORE;paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);T.paper(self)
	frame=Control.new();add_child(frame);frame.size=Vector2(minf(900 if host.size.x>=900 else 430,host.size.x),host.size.y);frame.position.x=(host.size.x-frame.size.x)/2
	var title=Label.new();frame.add_child(title);title.position=Vector2(18,12);title.size=Vector2(frame.size.x-112,58);title.text=L.render("설정",L.language(host.model.s));title.add_theme_font_override("font",T.DISPLAY);title.add_theme_font_size_override("font_size",36)
	var back=button("p8_back","뒤로",func():host.reset_r22=false;host.go(host.settings_return_r22),false,false,frame);back.position=Vector2(frame.size.x-88,20);back.size=Vector2(70,44)
	T.heading_rule(frame);frame.get_child(-1).position=Vector2(18,72)
	scroll=ScrollContainer.new();frame.add_child(scroll);scroll.position=Vector2(18,88);scroll.size=Vector2(frame.size.x-36,frame.size.y-112);T.scroll_region(scroll)
	body=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12)
	if host.save_error!=OK:
		text("저장하지 못했습니다. 다시 시도해 주세요.",14,ACTION);button("save_retry","저장 다시 시도",func():host._save();host._draw_screen())
	section("언어 · Language")
	var lang=L.language(host.model.s);var h=row()
	button("p8_lang_ko","한국어",apply.bind("lang","ko"),lang=="ko",false,h)
	button("p8_lang_en","English",apply.bind("lang","en"),lang=="en",false,h)
	text(View.settings_note("lang",lang),14,T.MUTED)
	section("난이도")
	var current=Settings.difficulty(host.model.s)
	for i in range(3):
		var d=L.DATA.difficulties[i]
		var multiplier=("%.2f"%d.hp).trim_suffix("0").trim_suffix("0").trim_suffix(".")
		button("p8_diff_"+str(i+1),L.u(d.name,{},lang)+"\n"+L.u("적 HP, 공격 ×{n}",{"n":multiplier},lang),apply.bind("diff",str(i+1)),d.name==current.name)
	text(L.u("적의 HP와 공격력이 달라집니다. 지금은 <b>{level}</b>입니다. 새로 시작하는 전투부터 적용됩니다.",{"level":L.render(current.name,lang)},lang).replace("<b>","").replace("</b>",""),14,T.MUTED)
	section("모험 연대기");h=row()
	var enabled=host.model.s.get("settings",{}).get("chron",1)!=0
	button("p8_chron_1","켜기",apply.bind("chron","1"),enabled,false,h);button("p8_chron_0","끄기",apply.bind("chron","0"),not enabled,false,h)
	text(View.settings_note("chron",lang),14,T.MUTED)
	section("저장 상태")
	text(L.u("저장 버전 {n}",{"n":host.model.s.schema},lang),18)
	text(L.u("영입 동료 {n}명, 금화 {gold}",{"n":host.model.s.owned.size(),"gold":host.model.s.gold},lang))
	text("저장하지 못했습니다." if host.save_error!=OK else "설정을 저장했습니다." if host.settings_saved_r22 else "로컬 자동 저장",14,ACTION if host.save_error!=OK else T.MUTED)
	button("p8_cloud","클라우드 저장",host.go.bind("cloud"))
	section("처음부터 다시")
	if host.reset_r22:
		text("정말 처음부터 다시 시작할까요? 영입한 동료, 호감, 장비, 금화가 모두 사라지고 캐릭터 만들기부터 다시 시작합니다. 되돌릴 수 없습니다.")
		text("현재 모험은 보관 사본으로 남습니다.",14,T.MUTED)
		button("p8_reset_no","취소",func():host.reset_r22=false;host._draw_screen())
		button("p8_reset_yes","네, 처음부터",reset_now)
	else:
		text("모험 기록을 모두 지우고 캐릭터 만들기부터 다시 시작합니다.",14,T.MUTED)
		button("p8_reset","처음부터 다시",func():host.reset_r22=true;host._draw_screen())
func button(id: String,value: String,fn: Callable,selected=false,disabled=false,parent: Node=null) -> Button:
	var b=super(id,value,fn,selected,disabled,parent)
	return b
func apply(key: String,value: String) -> void:
	if key=="diff":host.reset_r22=false
	if Settings.apply(host.model.s,{key:value}):host._save();host.settings_saved_r22=host.save_error==OK
	host._draw_screen()
func reset_now() -> void:
	if not host.reset_r22:return
	var fresh=host.storage.reset_world(host.model)
	if fresh==null:host.save_error=ERR_CANT_CREATE;host._draw_screen();return
	host.model=fresh;host.panels_r22=null;host.journal_r22={"place":"town","person":"","legacy":false};host.reset_r22=false;host.settings_saved_r22=false;host.save_error=OK;host.screen="town";host._draw_screen()
