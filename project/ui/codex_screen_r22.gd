extends "res://ui/panel_screen_r22.gd"
func build(owner_screen) -> void:
	setup(owner_screen,"캐릭터 도감")
	var id=state.ui.sel
	if id=="persona":button("p7_cx_back","목록으로",cx.bind("back"));persona(false);return
	if id in host.model.s.owned and R.DATA.cast.has(id):detail(id);return
	text("영입 %d / %d"%[host.model.s.owned.size(),R.DATA.order.size()],14,T.MUTED)
	button("p7_me","페르소나의 고유 스킬 보기",cx.bind("me"))
	var tabs=row()
	var tab_specs=View.tabs(state.ui.tab,L.language(host.model.s))
	for e in tab_specs.slice(0,4):
		var action=e.action.trim_prefix("cx_")
		var filter_button=button("p7_filter_"+action.trim_prefix("f_"),e.text,cx.bind(action),e.selected,false,tabs)
		if L.language(host.model.s)=="en":filter_button.add_theme_font_size_override("font_size",12)
		filter_button.autowrap_mode=TextServer.AUTOWRAP_OFF
		filter_button.size_flags_horizontal=SIZE_EXPAND_FILL
	if tab_specs.size()>4 and tab_specs[4].action=="cx_f_el":
		var values=[]
		for e in tab_specs.slice(4):values.append([e.action.trim_prefix("cx_f_"),e.text])
		choose("p7_filter_sub",values,state.ui.tab,func(v):cx("f_"+v),null,true)
	elif tab_specs.size()>4 and tab_specs[4].action=="cx_f_cls":
		var values=[]
		for e in tab_specs.slice(4):values.append([e.action.trim_prefix("cx_f_"),e.text])
		choose("p7_filter_sub",values,state.ui.tab,func(v):cx("f_"+v),null,true)
	var list=R.codex_list(host.model.s.owned,state.ui.tab);var page=R.page(list,int(state.ui.page))
	state.ui.page=page.page
	if list.is_empty():text("조건에 맞는 동료가 없습니다.",16,T.MUTED)
	var grid=GridContainer.new();body.add_child(grid);grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",16)
	for cid in page.items:
		var c=R.DATA.cast[cid];var owned=cid in host.model.s.owned;var tile=VBoxContainer.new();grid.add_child(tile);tile.size_flags_horizontal=SIZE_EXPAND_FILL
		tile.set_meta("favorite",owned and cid in state.favs())
		var p=portrait(cid,tile,Vector2(0,138));p.size_flags_horizontal=SIZE_EXPAND_FILL
		if not owned:p.modulate.a=.38
		button("p7_select_"+cid,c.name,cx.bind("sel_"+cid),false,not owned,tile)
		var description=L.u("{cls} · {el} · Lv {lv}",{"cls":c.cls,"el":R.DATA.els.get(c.el,"무"),"lv":state.level(cid)},L.language(host.model.s)) if owned else L.u("아직 만나지 못한 동료",{},L.language(host.model.s))
		var description_label=text(description,12,T.MUTED,tile);description_label.text=description
		if owned:
			var meter=ProgressBar.new();tile.add_child(meter);meter.custom_minimum_size.y=8;meter.show_percentage=false;meter.max_value=1;meter.step=.001;meter.value=View.bar(maxi(R.shown_aff(host.model.s.members[cid].aff),0),200)
			if cid in state.favs():
				var mark=ColorRect.new();p.add_child(mark);mark.position=Vector2(6,6);mark.size=Vector2(6,6);mark.color=READABLE_RED;mark.mouse_filter=MOUSE_FILTER_IGNORE
	if page.pages>1:pager(list,int(state.ui.page),R.PAGE,"cx")
func detail(id: String) -> void:
	var c=R.DATA.cast[id];var m=host.model.s.members[id];var h=row()
	button("p7_cx_back","목록으로",cx.bind("back"),false,false,h);button("p7_fav","즐겨찾기 해제" if id in state.favs() else "즐겨찾기 추가",cx.bind("fav"),id in state.favs(),false,h)
	h=row();portrait(id,h,Vector2(130,190));var copy=VBoxContainer.new();h.add_child(copy);copy.size_flags_horizontal=SIZE_EXPAND_FILL
	var full=L.t(c.full,L.language(host.model.s));var split=full.find(" ")
	if split>=0:full=full.left(split)+"\n"+full.substr(split+1)
	var heading=text(full,27,T.INK,copy);heading.autowrap_mode=TextServer.AUTOWRAP_ARBITRARY
	var lang=L.language(host.model.s);var race=L.u("{race}({lineage})",{"race":c.race,"lineage":c.lineage},lang) if c.lineage!="" else L.t(c.race,lang)
	var tags=" ".join([race,L.t(c.nation,lang),L.t(c.cls,lang),L.t(c.row,lang),View.element(c.el,lang)]);var tag_label=text(tags,14,T.MUTED,copy);tag_label.text=tags
	section("호감도");affection(m.aff);stats(R.companion_stats(id,state.level(id)),state.level(id),int(m.xp),c.cls)
	section(L.u("개인 스킬",{},lang)+" "+View.kind(true,lang));text(L.t(c.skill,lang),19);text(L.t(c.skill_d,lang));section(L.u("개인 특성",{},lang)+" "+View.kind(false,lang))
	var trait_parent: Node=body;var trait_path="res://assets/ui-traits-r23/t-"+id+".webp"
	if ResourceLoader.exists(trait_path):
		var trait_row=row();var icon=TextureRect.new();trait_row.add_child(icon);icon.texture=load(trait_path);icon.custom_minimum_size=Vector2(44,44);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.set_meta("source_trait",id)
		var trait_copy=VBoxContainer.new();trait_row.add_child(trait_copy);trait_copy.size_flags_horizontal=SIZE_EXPAND_FILL;trait_parent=trait_copy
	text(L.t(c.trait,lang),19,T.INK,trait_parent);text(L.t(c.trait_d,lang),15,T.INK,trait_parent)
	passives(c.cls,c.race,c.lineage,c.nation);section("장비")
	var more=false
	for slot in R.DATA.slots:
		text(slot[1],19);var uid=host.model.s.equipment.get(id,{}).get(slot[0],0);var e=host.model.gear_entry(int(uid))
		if not e.is_empty():
			button("p7_un_"+slot[0],"해제",func():state.unequip(id,slot[0]);host._save();host._draw_screen());gear_card(e,-1)
		else:text("비어 있음",14,T.MUTED)
		var candidates=state.candidates(id,slot[0])
		if not candidates.is_empty():text("낄 수 있는 장비",14,T.MUTED)
		for entry in candidates.slice(0,4):gear_tile("p7_cand_"+str(int(entry.uid)),host.model.gear.by_id[entry.id],func():state.equip(id,entry);state.persist();host._save();host._draw_screen(),"장착")
		if candidates.size()>4:more=true
	button("p7_cx_bag","가방 열기",cx.bind("bag"),true)
	if more:text("더 낄 수 있는 장비는 가방에서 볼 수 있습니다.",14,T.MUTED)
