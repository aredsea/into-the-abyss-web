extends "res://ui/expedition_screen_r22.gd"
const LegacySortie=preload("res://ui/expe_sortie_legacy_r23.gd")
## One portrait per companion; formation rows and the illustrated source route.
func build(owner_screen) -> void:
	if not owner_screen.model.has_method("source_sortie_view"):
		var legacy=LegacySortie.new();add_child(legacy);legacy.build(owner_screen);metrics=legacy.metrics;boxes=legacy.boxes;return
	build_frame(owner_screen)
	nav_top=792
	background("departure",Rect2(0,48,390,168));boxes["background:departure"].modulate.a=.14
	T.torn(stage,192)
	header("원정 준비")
	host.controls.back.position.y=4;host.controls.back.size.y=56
	var w=host.model;var s=w.s
	var floor_view=w.dungeon_floor_view(w.selected_floor,w.average_level());var info=floor_view.info;var zone=floor_view.zone
	label("탐사 지역",Rect2(18,54,180,20),11,T.INK,T.BOLD)
	display(zone.name,Rect2(18,74,215,48),T.INK,36)
	display("%d층"%w.selected_floor,Rect2(18,121,150,36),T.RED,29)
	paragraph("출발 시 HP·MP 회복",Rect2(18,171,198,28),12)
	var pick=OptionButton.new();stage.add_child(pick);pick.position=Vector2(18,212);pick.size=Vector2(190,56);pick.add_theme_font_size_override("font_size",12)
	for f in range(1,w.dungeon_max()+1):
		var z=w.dungeon_rules.floor_info(f);pick.add_item(L.u("{floor}층 {zone}",{"floor":f,"zone":w.dungeon_rules.zones[z.zone].name},L.language(s)))
	pick.select(w.selected_floor-1)
	pick.item_selected.connect(func(i):w.selected_floor=i+1;s.dungeon_r21.sel=i+1;host._save();host._draw_screen())
	host.controls.dungeon_floor=pick
	if w.has_method("floor_page"):
		pick.clear();pick.fit_to_longest_item=false;pick.clip_text=true
		var mx=w.dungeon_max();var pg=clampi(int(s.dungeon_r21.get("pg",1)),1,int(ceil((mx+1)/6.0)))
		var selection_on_page=false
		for f in range((pg-1)*6+1,mini(pg*6,mx+1)+1):
			var z=w.dungeon_rules.floor_info(f);var status="잠김" if f>mx else "완료" if f<=s.dungeon_r21.best else "도전 가능"
			pick.add_item(L.u("{floor}층 {zone}",{"floor":f,"zone":w.dungeon_rules.zones[z.zone].name},L.language(s))+" · "+localized(status),f)
			pick.get_popup().set_item_disabled(pick.item_count-1,f>mx)
			if f==w.selected_floor:pick.select(pick.item_count-1);selection_on_page=true
		if not selection_on_page:
			pick.select(-1);pick.text="선택 %d층 · 다른 쪽"%w.selected_floor
		elif L.language(s)=="en":pick.text="Floor %d"%pick.get_selected_id()
		for connection in pick.item_selected.get_connections():pick.item_selected.disconnect(connection.callable)
		pick.item_selected.connect(func(i):w.select_dungeon_floor(pick.get_item_id(i));host._save();host._draw_screen())
		action("floor_prev","이전",Rect2(218,212,72,56),func():w.floor_page(pg-1);host._save();host._draw_screen(),false,pg<=1).add_theme_font_size_override("font_size",12)
		action("floor_next","다음",Rect2(298,212,72,56),func():w.floor_page(pg+1);host._save();host._draw_screen(),false,pg>=int(ceil((mx+1)/6.0))).add_theme_font_size_override("font_size",12)
		var rec=w.expedition_rules.recommended(w.average_level(),mx)
		
		label("추천 %d층"%rec,Rect2(244,59,88,25),11)
		icon("floor-star",Rect2(339,66,10,10))
		label(str(int(w.dungeon_rules.floor_star(info))),Rect2(351,59,15,25),11)
		label("권장 Lv.%d · 적 Lv.%d"%[w.expedition_rules.rec_level(w.selected_floor),w.dungeon_rules.floor_level(w.average_level(),info)],Rect2(244,87,122,52),11).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var ui=w.ExpeditionUI.new();ui.lang=L.language(s)
	var self_button=action("so_fight_1",ui.u("직접 싸운다"),Rect2(18,277,174,56),source_action.bind("so_fight_1"),s.persona.fight==1,w.active() or not w.can_persona_fight(),false);self_button.add_theme_font_size_override("font_size",13)
	if not w.can_persona_fight():self_button.tooltip_text="모험가 생성 정보가 없는 옛 저장입니다. 기존 동료 편성을 유지하고 지휘로 출발합니다."
	action("so_fight_0",ui.u("지휘만 한다"),Rect2(198,277,174,56),source_action.bind("so_fight_0"),s.persona.fight==0,w.active(),false).add_theme_font_size_override("font_size",13)
	var ids=w.sortie_members().map(func(m):return m.id) if w.has_method("sortie_members") else w.sortie_ids()
	label(ui.u("출전 인원")+" · "+ui.u("{n} / 4 (칸을 누르면 뺀다)",{"n":ids.size()}),Rect2(18,335,354,24),12,T.INK,T.BOLD,false)
	formation_slots(w.sortie_members())
	var previous=stage;stage=scroll_page(501,227,227)
	var sheet=fill("source_sortie_sheet",Rect2(0,0,342,243),Color.TRANSPARENT)
	var y=preparation_entries(w.source_preparation_view("modes"),0)
	y=preparation_entries(w.source_preparation_view("dungeon_card" if w.sortie_mode()==1 else "quest"),y+12)
	# Preserve the illustrated formation above while keeping its full class,
	# level, and persona command-mode explanation accessible in this scroll.
	y=preparation_entries(w.source_preparation_view("fight").slice(0,2),y+12)
	y=source_entries(w.source_sortie_view("cards"),y+16)
	y=source_entries(w.source_sortie_view("summary"),y+16)
	if not s.quest.is_empty() and host.save_error==OK:
		var quest_button=action("accepted_quest","수락한 균열 의뢰로 출발",Rect2(0,y,342,56),func():host._act(w.depart_accepted_quest,"");host.go("explore"),true,ids.is_empty() or w.active())
		quest_button.tooltip_text="\n".join(w.sortie_quest_summary(s.quest).warns);y+=68
	stage.custom_minimum_size.y=maxf(243,y+12);sheet.size.y=stage.custom_minimum_size.y;stage=previous
	var summary_data=w.sortie_quest_summary({"lv":floor_view.el} if w.sortie_mode()==1 else w.quest_contract(s.quest)) if w.has_method("sortie_quest_summary") else {}
	var start_button=action("start_run",ui.u("대던전에 도전한다" if w.sortie_mode()==1 else "균열로 들어간다"),Rect2(18,736,354,56),func():host._act(w.start_selected_dungeon if w.sortie_mode()==1 else w.depart_accepted_quest,"");host.go("explore"),true,ids.is_empty() or w.active() or (w.sortie_mode()==0 and s.quest.is_empty()),false)
	if not summary_data.is_empty():start_button.tooltip_text="\n".join(summary_data.warns)
	if not s.ui.get("msg","").is_empty():
		# Keep toggle controls usable while displaying the original feedback.
		var keep=stage;stage=sheet.get_parent();var my=stage.custom_minimum_size.y
		preparation_entries([{"role":"body","text":s.ui.msg}],my);stage.custom_minimum_size.y=my+100;sheet.size.y=stage.custom_minimum_size.y;stage=keep
	navigation()
	if host.save_error!=OK:action("save_retry","저장 다시 시도",Rect2(18,667,354,56),func():host._save();host._draw_screen(),true)
	finish_localization()

func source_action(id: String) -> void:
	var w=host.model
	if host.screen!="depart" or w.active():return
	w.s.ui.msg=""
	if id=="rk_refresh":
		host.go("rank");host.cloud.fetch_rank();return
	elif id.begins_with("so_mode_"):w.set_sortie_mode(int(id.trim_prefix("so_mode_")))
	elif id.begins_with("so_fl_"):w.select_dungeon_floor(int(id.trim_prefix("so_fl_")))
	elif id.begins_with("so_pg_"):w.floor_page(int(id.trim_prefix("so_pg_")))
	elif id=="so_rm_persona":w.set_fight(0)
	elif id.begins_with("so_rm_"):
		var cid=id.trim_prefix("so_rm_")
		if cid in w.s.party:w.toggle_companion(cid)
	elif id.begins_with("so_fight_"):w.set_fight(int(id.trim_prefix("so_fight_")))
	elif id.begins_with("so_f_"):
		var f=id.trim_prefix("so_f_");w.s.ui.tab="" if f=="all" else f
	elif id.begins_with("so_tg_"):w.toggle_companion(id.trim_prefix("so_tg_"))
	else:super(id);return
	host._save();host._draw_screen()

func preparation_entries(entries: Array,y: float) -> float:
	var before=stage.get_child_count();var end=source_entries(entries,y)
	for node in stage.get_children().slice(before):
		if node.has_meta("expe_entry"):node.set_meta("expe6_entry",node.get_meta("expe_entry"));node.remove_meta("expe_entry")
	return end

func formation_slots(members: Array) -> void:
	var w=host.model;var entries=w.source_preparation_view("slots");var ui=w.ExpeditionUI.new();ui.lang=L.language(w.s)
	for i in range(4):
		var x=18+i*90
		rule(494,x,84)
		if i>=members.size():
			label(str(i+1),Rect2(x,367,84,52),25).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			label(ui.u("비어 있음"),Rect2(x+2,426,80,44),11,T.MUTED,T.BODY,false).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;continue
		var m=members[i];picture(m.id,Rect2(x,359,84,64),"town-party-face")
		label(ui.t(m.name),Rect2(x,423,84,22),12,T.INK,T.BOLD,false)
		paragraph(ui.u("{cls}, {row}, Lv {lv}",{"cls":m.cls,"row":m.row,"lv":m.lv}),Rect2(x,447,84,46),12,T.INK,false)
		var b=hit("so_rm_"+m.id,Rect2(x,359,84,136),source_action.bind("so_rm_"+m.id));b.disabled=w.active();b.tooltip_text=ui.u("{cls}, {row}, Lv {lv}",{"cls":m.cls,"row":m.row,"lv":m.lv})

func formation_row(ids: Array,x: float) -> void:
	var sc=ScrollContainer.new();stage.add_child(sc);sc.position=Vector2(x,359);sc.size=Vector2(174,122)
	sc.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var page=Control.new();sc.add_child(page);page.custom_minimum_size=Vector2(maxi(174,ids.size()*88-5),112)
	var previous=stage;stage=page
	if ids.is_empty():
		fill("empty_row:"+str(x),Rect2(0,0,174,112),T.PALE);label("편성 없음",Rect2(8,0,158,112),14,T.MUTED)
	for i in range(ids.size()):
		var id=ids[i];var px=i*88
		if id=="persona":
			fill("persona_slot",Rect2(px,0,83,112),T.INK)
			label("페르소나",Rect2(px+4,8,75,24),12,T.PAPER,T.BOLD)
			paragraph(host.model.person(id)["class"],Rect2(px+4,34,75,40),13,T.PAPER)
		else:
			picture(id,Rect2(px,0,83,78),"formation-face")
		fill("party_caption:"+id,Rect2(px,78,83,34),T.INK)
		label(host.model.person(id).name,Rect2(px+3,78,77,18),11,T.PAPER,T.BOLD)
		label("Lv.%d"%host.model.s.members[id].level,Rect2(px+3,96,77,16),10,T.PAPER)
		if id!="persona":
			var b=hit("so_tg_"+id,Rect2(px,0,83,112),func():host.model.toggle_companion(id);host._save();host._draw_screen())
			b.disabled=host.model.active();b.tooltip_text=host.model.person(id).name+" 편성 해제"
	stage=previous

