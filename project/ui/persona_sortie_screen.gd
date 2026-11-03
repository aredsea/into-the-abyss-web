extends "res://ui/expedition_screen_r22.gd"
const LegacySortie=preload("res://ui/expe_sortie_legacy_r23.gd")
## One portrait per companion; formation rows and the illustrated source route.
func build(owner_screen) -> void:
	if not owner_screen.model.has_method("source_sortie_view"):
		var legacy=LegacySortie.new();add_child(legacy);legacy.build(owner_screen);metrics=legacy.metrics;boxes=legacy.boxes;return
	build_frame(owner_screen)
	nav_top=792
	background("departure",Rect2(0,48,390,219))
	plate("accent-departure",Rect2(0,48,390,219))
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
		action("floor_prev","이전",Rect2(218,212,72,56),func():w.floor_page(pg-1);host._save();host._draw_screen(),false,pg<=1).add_theme_font_size_override("font_size",11)
		action("floor_next","다음",Rect2(298,212,72,56),func():w.floor_page(pg+1);host._save();host._draw_screen(),false,pg>=int(ceil((mx+1)/6.0))).add_theme_font_size_override("font_size",11)
		var rec=w.expedition_rules.recommended(w.average_level(),mx)
		fill("floor_details_paper",Rect2(238,54,134,98),Color(T.PAPER,0.94))
		label("추천 %d층"%rec,Rect2(244,59,88,25),11)
		icon("floor-star",Rect2(339,66,10,10))
		label(str(int(w.dungeon_rules.floor_star(info))),Rect2(351,59,15,25),11)
		label("권장 Lv.%d · 적 Lv.%d"%[w.expedition_rules.rec_level(w.selected_floor),w.dungeon_rules.floor_level(w.average_level(),info)],Rect2(244,87,122,52),11).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var self_button=action("so_fight_1","자기 참전 · 동료 3명",Rect2(18,277,174,56),func():w.set_fight(1);host._save();host._draw_screen(),s.persona.fight==1,w.active() or not w.can_persona_fight());self_button.add_theme_font_size_override("font_size",13)
	if not w.can_persona_fight():self_button.tooltip_text="모험가 생성 정보가 없는 옛 저장입니다. 기존 동료 편성을 유지하고 지휘로 출발합니다."
	action("so_fight_0","지휘 · 동료 4명",Rect2(198,277,174,56),func():w.set_fight(0);host._save();host._draw_screen(),s.persona.fight==0,w.active()).add_theme_font_size_override("font_size",13)
	var ids=w.sortie_members().map(func(m):return m.id) if w.has_method("sortie_members") else w.sortie_ids()
	for i in range(2):
		var row="전열" if i==0 else "후열"
		var group=ids.filter(func(id):return w.person(id).row==row)
		label(row+" · %d명"%group.size(),Rect2(18+i*180,335,174,24),13,T.INK,T.BOLD)
		formation_row(group,18+i*180)
	var previous=stage;stage=scroll_page(485,243,243)
	var sheet=fill("source_sortie_sheet",Rect2(0,0,342,243),T.PAPER)
	var y=source_entries(w.source_sortie_view("cards"),0)
	y=source_entries(w.source_sortie_view("summary"),y+16)
	if not s.quest.is_empty() and host.save_error==OK:
		var quest_button=action("accepted_quest","수락한 균열 의뢰로 출발",Rect2(0,y,342,56),func():host._act(w.depart_accepted_quest,"");host.go("explore"),true,ids.is_empty() or w.active())
		quest_button.tooltip_text="\n".join(w.sortie_quest_summary(s.quest).warns);y+=68
	stage.custom_minimum_size.y=maxf(243,y+12);sheet.size.y=stage.custom_minimum_size.y;stage=previous
	var summary_data=w.sortie_quest_summary({"lv":floor_view.el}) if w.has_method("sortie_quest_summary") else {}
	var start_button=action("start_run","선택한 층으로 출발 →",Rect2(18,736,354,56),func():host._act(w.start_selected_dungeon,"");host.go("explore"),true,ids.is_empty() or w.active())
	if not summary_data.is_empty():start_button.tooltip_text="\n".join(summary_data.warns)
	navigation()
	if host.save_error!=OK:action("save_retry","저장 다시 시도",Rect2(18,667,354,56),func():host._save();host._draw_screen(),true)
	finish_localization()

func source_action(id: String) -> void:
	var w=host.model
	if id.begins_with("so_f_"):
		var f=id.trim_prefix("so_f_");w.s.ui.tab="" if f=="all" else f
	elif id.begins_with("so_tg_"):w.toggle_companion(id.trim_prefix("so_tg_"))
	else:super(id);return
	host._save();host._draw_screen()

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

