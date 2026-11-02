extends "res://ui/town_screen_r21.gd"
## One portrait per companion; formation rows and the illustrated source route.
func build(owner_screen) -> void:
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
	var ids=w.sortie_ids()
	for i in range(2):
		var row="전열" if i==0 else "후열"
		var group=ids.filter(func(id):return w.person(id).row==row)
		label(row+" · %d명"%group.size(),Rect2(18+i*180,335,174,24),13,T.INK,T.BOLD)
		formation_row(group,18+i*180)
	label("대기 동료",Rect2(18,485,140,44),14,T.INK,T.BOLD)
	for i in range(3):
		var entry=[["","전체"],["front","전열"],["back","후열"]][i]
		action("so_f_"+("all" if entry[0]=="" else entry[0]),entry[1],Rect2(162+i*71,485,68,56),func():s.ui.tab=entry[0];host._save();host._draw_screen(),s.ui.get("tab","")==entry[0]).add_theme_font_size_override("font_size",12)
	var candidates=w.sortie_candidates(s.ui.get("tab","")).filter(func(id):return id not in s.party)
	var previous=stage
	stage=scroll_page(545,66,maxf(66,ceil(candidates.size()/2.0)*70))
	for i in range(candidates.size()):
		var id=candidates[i];var x=(i%2)*172;var y=int(i/2)*70
		picture(id,Rect2(x,y,48,66),"formation-face")
		var full=s.party.size()>=(3 if s.persona.fight==1 else 4)
		var b=action("so_tg_"+id,"추가 · "+w.person(id).name,Rect2(x+50,y,116,66),func():w.toggle_companion(id);host._save();host._draw_screen(),false,w.active() or full)
		b.add_theme_font_size_override("font_size",11)
	if candidates.is_empty():label("이 열의 대기 동료가 없습니다.",Rect2(0,0,340,48),14,T.MUTED)
	stage=previous
	var fronts=ids.filter(func(id):return w.person(id).row=="전열").size()
	var summary_data=w.sortie_summary(int(floor_view.el)) if w.has_method("sortie_summary") else {}
	var danger=not summary_data.is_empty() and summary_data.n>0 and summary_data.elv-summary_data.avg>=5
	var caption="옛 저장은 지휘로 출발 · 초상을 눌러 편성 해제" if not w.can_persona_fight() else "출전할 사람을 골라 주세요." if ids.is_empty() else "전열 없음 · 초상을 눌러 편성 해제" if fronts==0 else "출전 %d / 4 · 초상을 눌러 편성 해제"%ids.size()
	if danger:caption="위험 · 적 Lv.%d / 파티 평균 Lv.%d%s"%[summary_data.elv,summary_data.avg," · 전열 없음" if fronts==0 else ""]
	label(caption,Rect2(18,613,354,24),12,T.RED if fronts==0 or danger else T.INK)
	label("원정 경로",Rect2(18,637,354,22),13,T.INK,T.BOLD)
	if s.quest.is_empty() and host.save_error==OK:
		for i in range(3):
			var x=18+i*120
			background(["explore","rest","departure"][i],Rect2(x,661,114,45))
			mark("route_picture:"+str(i),boxes["background:"+["explore","rest","departure"][i]])
			label(["탐색 5회","휴식","층 보스"][i],Rect2(x,706,114,24),12,T.INK,T.BOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	elif not s.quest.is_empty() and host.save_error==OK:
		action("accepted_quest","수락한 균열 의뢰로 출발",Rect2(18,667,354,56),func():host._act(w.depart_accepted_quest,"");host.go("explore"),true,ids.is_empty() or w.active())
	var start_button=action("start_run","선택한 층으로 출발 →",Rect2(18,736,354,56),func():host._act(w.depart_dungeon.bind(w.selected_floor),"");host.go("explore"),true,ids.is_empty() or w.active())
	if not summary_data.is_empty():start_button.tooltip_text="\n".join(summary_data.warns)
	navigation()
	if host.save_error!=OK:action("save_retry","저장 다시 시도",Rect2(18,667,354,56),func():host._save();host._draw_screen(),true)
	finish_localization()

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

