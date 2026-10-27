extends Control

const World=preload("res://game/world_state.gd")
const Store=preload("res://game/world_store.gd")
const BattleScreen=preload("res://ui/battle_screen.gd")
const FONT=preload("res://assets/fonts/NanumGothic-Regular.ttf")
const INK=Color("eae4d6")
const GOLD=Color("d7b67e")
const MUTED=Color("afb8b3")
var model=World.new()
var storage=Store.new()
var screen="town"
var who="hildegard"
var selected_item=""
var message=""
var confirm: Dictionary={}
var content: VBoxContainer
var controls={}
var scroll: ScrollContainer
var battle: Control
var save_error=OK
var restored=false
var metrics_time=0.0

func _ready() -> void:
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
	if model.active() and page in ["town","shop","inn","depart"]: page="explore"
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
	battle=null; controls.clear()
	var width=minf(size.x,440); var height=size.y
	var base=Control.new(); add_child(base); base.position=Vector2((size.x-width)/2,0); base.size=Vector2(width,height)
	var back=ColorRect.new(); base.add_child(back); back.size=base.size; back.color=Color("151a1b"); back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var metal=TextureRect.new(); base.add_child(metal); metal.texture=load("res://assets/metal.png"); metal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; metal.size=Vector2(width,68); metal.modulate=Color(1,1,1,0.3); metal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var heading=Label.new(); base.add_child(heading); heading.position=Vector2(16,10); heading.size=Vector2(width-32,26); heading.text=_title(); heading.add_theme_font_size_override("font_size",22); heading.add_theme_color_override("font_color",GOLD)
	var status=Label.new(); base.add_child(status); status.position=Vector2(16,40); status.text="%d일째     금화 %d     검수판" % [model.s.day,model.s.gold]; status.add_theme_font_size_override("font_size",12)
	scroll=ScrollContainer.new(); base.add_child(scroll); scroll.position=Vector2(12,76); scroll.size=Vector2(width-24,height-152)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	content=VBoxContainer.new(); scroll.add_child(content); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",12)
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
	var nav=HBoxContainer.new(); base.add_child(nav); nav.position=Vector2(12,height-66); nav.size=Vector2(width-24,54); nav.add_theme_constant_override("separation",6)
	for item in [["explore" if model.active() else "town","원정" if model.active() else "거점"],["party","동료"],["bag","가방"],["journal","기록"]]:
		var b=Button.new(); nav.add_child(b); b.text=item[1]; b.custom_minimum_size=Vector2(0,52); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.pressed.connect(go.bind(item[0])); controls["nav:"+item[0]]=b
	call_deferred("_publish")

func _title() -> String:
	return {"town":"토르바","party":"함께하는 동료","member":model.person(who).name,"depart":"원정 준비","explore":"학술원 폐허 상층","cards":"탐색 카드","bag":"공용 가방","shop":"마렌토 상회","inn":"아랫마을 여관","summary":"원정 정산","journal":"모험 기록"}.get(screen,"토르바")

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
	var b=Button.new(); (parent if parent else content).add_child(b)
	b.text=value; b.custom_minimum_size.y=54; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.disabled=disabled
	b.mouse_filter=Control.MOUSE_FILTER_PASS
	b.pressed.connect(callback); controls[id]=b
	return b

func image(path: String, target: Node, dims: Vector2) -> TextureRect:
	var t=TextureRect.new(); target.add_child(t); t.texture=load(path); t.custom_minimum_size=dims
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return t

func bar(label: String, value: float, maximum: float, parent: Node, hp=true) -> void:
	text("%s %d / %d" % [label,value,maximum],12,INK,parent)
	var p=ProgressBar.new(); parent.add_child(p); p.custom_minimum_size.y=10; p.show_percentage=false; p.max_value=maximum; p.value=value
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bg=StyleBoxFlat.new(); bg.bg_color=Color("090f11"); p.add_theme_stylebox_override("background",bg)
	var fill=StyleBoxFlat.new(); fill.bg_color=Color("b56651") if hp else Color("719da9"); p.add_theme_stylebox_override("fill",fill)

func _portrait(id: String, parent: Node, large=false) -> void:
	var row=HBoxContainer.new(); parent.add_child(row); row.add_theme_constant_override("separation",14)
	image("res://assets/"+id+".webp",row,Vector2(128,170) if large else Vector2(76,104))
	var body=VBoxContainer.new(); row.add_child(body); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var m=model.s.members[id]; var p=model.person(id); var b=model.stats(id,m.level)
	text(p.name,18,GOLD,body); text("Lv.%d  %s\n%s" % [m.level,p["class"],p.row],13,MUTED,body)
	bar("HP",m.hp,b.hp,body); bar("MP",m.mp,b.mp,body,false)

func _town() -> void:
	var hero=box(); _portrait(model.s.party[0],hero,true)
	text("성문 밖, 옛 학술원으로",19,GOLD,hero)
	text("동료를 살피고 보급품을 챙긴 뒤 폐허로 향한다.",14,INK,hero)
	button("depart","대던전 원정 준비",go.bind("depart"),false,hero)
	var row=HBoxContainer.new(); content.add_child(row); row.add_theme_constant_override("separation",8)
	var shop_button=button("shop","상회 · 보급",go.bind("shop"),false,row)
	shop_button.icon=load("res://assets/ic_pl_shop.webp"); shop_button.add_theme_constant_override("icon_max_width",24)
	var inn_button=button("inn","여관 · 교류",go.bind("inn"),false,row)
	inn_button.icon=load("res://assets/ic_pl_inn.webp"); inn_button.add_theme_constant_override("icon_max_width",24)
	text("학술원 2층의 짧은 검수 원정입니다.\n탐색 5회와 전투, 카드 사용, 귀환을 확인할 수 있습니다.",13,MUTED)
	if not model.s.summary.is_empty(): button("last_summary","지난 원정 정산",go.bind("summary"))

func _party() -> void:
	text("초상을 눌러 능력치와 스킬을 확인하세요.",13,MUTED)
	for i in range(4):
		var id=model.s.party[i]; var panel=box()
		_portrait(id,panel)
		button("member:"+id,"동료 상세",func(): who=id; go("member"),false,panel)
		if i in [0,2]: button("swap:"+str(i),"같은 열의 자리 교환",func(): _act(model.swap.bind(i,i+1),"자리를 교환했습니다."),model.active(),panel)
	if model.active(): text("원정 중에는 편성을 바꿀 수 없습니다.",13,MUTED)

func _member() -> void:
	var panel=box(); _portrait(who,panel,true)
	var p=model.person(who); var m=model.s.members[who]; var b=model.stats(who,m.level)
	text(p.race+" · "+p.nation,14,INK,panel)
	bar("경험치",m.xp,model.need(m.level),panel,false)
	text("호감 %s / 200" % number(m.aff),14,GOLD,panel)
	text("힘 %.1f   민첩 %.1f   지능 %.1f\n방어 %.1f   속도 %.1f" % [b.str,b.agi,b.int,b.def,b.spd],14,INK,panel)
	text("고유 특성 · "+p.trait.name,17,GOLD)
	text(p.trait.note,14)
	text("고유 스킬 · "+p.skill.name,17,GOLD)
	text("MP %d · %s\n%s" % [p.skill.mp,p.skill.target,p.skill.note],14)
	button("party_back","동료 목록",go.bind("party"))

func _departure() -> void:
	var p=box(); image("res://assets/src/academy.png",p,Vector2(0,155))
	text("학술원 폐허 상층 · 2층",20,GOLD,p)
	text("탐색 5회 → 휴식 → 마지막 정예 → 정산",14,INK,p)
	text("검수용 고정 경로입니다. 마지막 전투는 기존 정예전으로 연결하며, 층 보스 돌파 기록은 주지 않습니다.",13,MUTED,p)
	for id in model.s.party: text(model.person(id).row+"  "+model.person(id).name+"  Lv."+str(int(model.s.members[id].level)),14)
	text("출발 시 HP·MP가 채워집니다. 전투 사이에는 남은 수치가 이어집니다.",13,MUTED)
	button("start_run","원정 출발",func(): _act(model.depart,"원정을 시작했습니다."); go("explore"))

func _explore() -> void:
	if not model.active(): go("town"); return
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
	if item.kind=="revive": return "쓰러진 동료를 최대 HP 25%로 일으킵니다."
	return "Lv.%d부터 · 최대 %s %d%% 회복" % [item.level,item.kind.to_upper(),item.fraction*100]

func _shop() -> void:
	text("마렌토 상회에서 원정 보급품을 준비한다.",15)
	for item in model.config.items:
		var p=box(); text(item.name,19,GOLD,p); text(_item_text(item),14,INK,p)
		text("보유 %d개" % model.s.items[item.id],13,MUTED,p)
		button("buy:"+item.id,"1개 구입 · 금화 %d" % item.price,func(): _ask(item.name+" 1개를 금화 %d에 구입할까요?" % item.price,model.buy.bind(item.id)),model.s.gold<item.price or model.s.items[item.id]>=99,p)

func _inn() -> void:
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
		buttons[id]={"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"disabled":b.disabled,"needed":FONT.get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+24}
	var report={"build":model.config.build,"screen":"battle" if is_instance_valid(battle) else screen,"state":model.s,"controls":buttons,"viewport":[size.x,size.y],"restored":restored,"save_error":save_error}
	JavaScriptBridge.eval("window.__abyssWorld="+JSON.stringify(report)+";",true)

func _process(delta: float) -> void:
	# QA reads actual controls, not an action or state mutation bridge.
	metrics_time+=delta
	if metrics_time<0.2: return
	metrics_time=0
	if is_instance_valid(scroll) and not is_instance_valid(battle): _publish()
