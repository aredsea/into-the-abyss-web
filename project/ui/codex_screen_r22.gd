extends "res://ui/panel_screen_r22.gd"
func build(owner_screen) -> void:
	setup(owner_screen,"캐릭터 도감")
	var id=state.ui.sel
	if id=="persona":button("p7_cx_back","목록으로",cx.bind("back"));persona();return
	if id in host.model.s.owned and R.DATA.cast.has(id):detail(id);return
	text("영입 %d / %d"%[host.model.s.owned.size(),R.DATA.order.size()],14,T.MUTED)
	var tabs=row()
	for e in [["all","전체"],["rec","영입"],["el","속성"],["cls","직업"]]:
		var filter_button=button("p7_filter_"+e[0],e[1],cx.bind("f_"+e[0]),state.ui.tab==e[0] or (e[0]=="all" and state.ui.tab==""),false,tabs)
		if L.language(host.model.s)=="en":filter_button.add_theme_font_size_override("font_size",12)
		filter_button.autowrap_mode=TextServer.AUTOWRAP_OFF
		filter_button.size_flags_horizontal=SIZE_EXPAND_FILL
	if state.ui.tab.begins_with("el"):
		var values=[["el","모든 속성"]]
		for e in R.DATA.el_order:values.append(["el_"+e,R.DATA.els[e]])
		choose("p7_filter_sub",values,state.ui.tab,func(v):cx("f_"+v))
	elif state.ui.tab.begins_with("cls"):
		var values=[["cls","모든 직업"]]
		for c in R.DATA.classes:values.append(["cls_"+c.id,c.name])
		choose("p7_filter_sub",values,state.ui.tab,func(v):cx("f_"+v))
	button("p7_me","페르소나의 고유 스킬 보기",cx.bind("me"))
	var list=R.codex_list(host.model.s.owned,state.ui.tab);var page=R.page(list,int(state.ui.page))
	if list.is_empty():text("조건에 맞는 동료가 없습니다.",16,T.MUTED)
	var grid=GridContainer.new();body.add_child(grid);grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",16)
	for cid in page.items:
		var c=R.DATA.cast[cid];var owned=cid in host.model.s.owned;var tile=VBoxContainer.new();grid.add_child(tile);tile.size_flags_horizontal=SIZE_EXPAND_FILL
		var p=portrait(cid,tile,Vector2(0,138));p.size_flags_horizontal=SIZE_EXPAND_FILL
		if not owned:p.modulate.a=.38
		button("p7_select_"+cid,c.name,cx.bind("sel_"+cid),false,not owned,tile)
		text("%s · Lv %d%s"%[c.cls,host.model.s.members[cid].level," · 즐겨찾기" if cid in state.favs() else ""] if owned else "아직 만나지 못한 동료",12,T.MUTED,tile)
	if page.pages>1:pager(list,int(state.ui.page),R.PAGE,"cx")
func detail(id: String) -> void:
	var c=R.DATA.cast[id];var m=host.model.s.members[id];var h=row()
	button("p7_cx_back","목록으로",cx.bind("back"),false,false,h);button("p7_fav","즐겨찾기 해제" if id in state.favs() else "즐겨찾기 추가",cx.bind("fav"),id in state.favs(),false,h)
	h=row();portrait(id,h,Vector2(130,190));var copy=VBoxContainer.new();h.add_child(copy);copy.size_flags_horizontal=SIZE_EXPAND_FILL
	var full=L.t(c.full,L.language(host.model.s));var split=full.find(" ")
	if split>=0:full=full.left(split)+"\n"+full.substr(split+1)
	var heading=text(full,27,T.INK,copy);heading.autowrap_mode=TextServer.AUTOWRAP_ARBITRARY
	text(c.race+(" · "+c.lineage if c.lineage!="" else "")+"\n"+c.nation+"\n"+c.cls+" · "+c.row+"\n"+R.DATA.els.get(c.el,"무"),14,T.MUTED,copy)
	section("호감도");affection(m.aff);stats(R.companion_stats(id,int(m.level)),int(m.level),int(m.xp))
	section("개인 스킬 · 액티브");text(c.skill,19);text(c.skill_d);section("개인 특성 · 패시브");text(c.trait,19);text(c.trait_d)
	passives(c.cls,c.race,c.lineage,c.nation);section("장비")
	for slot in R.DATA.slots:
		text(slot[1],19);var uid=host.model.s.equipment.get(id,{}).get(slot[0],0);var e=host.model.gear_entry(int(uid))
		if not e.is_empty():
			gear_card(e,-1);button("p7_un_"+slot[0],"해제",func():state.unequip(id,slot[0]);host._save();host._draw_screen(),false,state.in_battle())
		else:text("비어 있음",14,T.MUTED)
		var candidates=state.candidates(id,slot[0])
		for entry in candidates.slice(0,4):button("p7_cand_"+str(int(entry.uid)),host.model.gear.by_id[entry.id].name+" · 장착",func():state.equip(id,entry);state.persist();host._save();host._draw_screen())
	button("p7_cx_bag","가방 열기",cx.bind("bag"),true,state.in_battle())
