extends "res://ui/town_screen_r21.gd"
## P1 formation lives inside the approved 03-preparation-0 composition.
func build(owner_screen) -> void:
	build_frame(owner_screen)
	nav_top=792
	background("departure",Rect2(0,48,390,219))
	plate("accent-departure",Rect2(0,48,390,219))
	header("원정 준비")
	host.controls.back.position.y=4;host.controls.back.size.y=56
	var w=host.model;var s=w.s
	var info=w.dungeon_rules.floor_info(w.selected_floor);var zone=w.dungeon_rules.zones[info.zone]
	label("탐사 지역",Rect2(18,54,180,20),11,T.INK,T.BOLD)
	display(zone.name,Rect2(18,74,215,48),T.INK,36)
	display("%d층"%w.selected_floor,Rect2(18,121,150,36),T.RED,29)
	paragraph("탐색 5회 → 휴식 → 층 보스\n출발 시 HP·MP 회복",Rect2(18,165,198,52),12)
	var pick=OptionButton.new();stage.add_child(pick);pick.position=Vector2(18,212);pick.size=Vector2(190,56);pick.add_theme_font_size_override("font_size",12)
	for f in range(1,w.dungeon_max()+1):
		var z=w.dungeon_rules.floor_info(f);pick.add_item("%d층 · %s"%[f,w.dungeon_rules.zones[z.zone].name])
	pick.select(w.selected_floor-1)
	pick.item_selected.connect(func(i):w.selected_floor=i+1;s.dungeon_r21.sel=i+1;host._save();host._draw_screen())
	host.controls.dungeon_floor=pick
	var self_button=action("so_fight_1","자기 참전 · 동료 3명",Rect2(18,277,174,56),func():w.set_fight(1);host._save();host._draw_screen(),s.persona.fight==1,w.active() or not w.can_persona_fight());self_button.add_theme_font_size_override("font_size",13)
	if not w.can_persona_fight():self_button.tooltip_text="모험가 생성 정보가 없는 옛 저장입니다. 기존 동료 편성을 유지하고 지휘로 출발합니다."
	action("so_fight_0","지휘 · 동료 4명",Rect2(198,277,174,56),func():w.set_fight(0);host._save();host._draw_screen(),s.persona.fight==0,w.active()).add_theme_font_size_override("font_size",13)
	var ids=w.sortie_ids()
	for i in range(4):
		var x=18+i*91
		if i>=ids.size():
			fill("empty_slot:"+str(i),Rect2(x,337,86,156),T.PALE)
			label("대기",Rect2(x+8,398,70,24),14,T.MUTED)
			continue
		var id=ids[i]
		if id=="persona":
			fill("persona_slot",Rect2(x,337,86,156),T.INK)
			ink(Rect2(x,341,86,75))
			label("페르소나",Rect2(x+5,354,76,24),13,T.PAPER,T.BOLD)
			paragraph(w.person(id)["class"],Rect2(x+5,390,76,40),14,T.PAPER)
		else:
			var card=Control.new();stage.add_child(card);card.position=Vector2(x,337);card.size=Vector2(86,156);card.clip_contents=true;card.mouse_filter=MOUSE_FILTER_IGNORE
			var portrait=picture(id,Rect2(0,0,125,226),"party-tall");portrait.reparent(card);portrait.position=Vector2(-19,-6)
		fill("party_caption:"+id,Rect2(x,451,86,42),T.INK)
		label(w.person(id).name,Rect2(x+4,451,78,22),12,T.PAPER,T.BOLD)
		label("Lv.%d · %s"%[s.members[id].level,w.person(id).row],Rect2(x+4,473,78,18),10,T.PAPER)
		if id!="persona":hit("departure_member:"+id,Rect2(x,337,86,156),host.go.bind("formation"))
	label("함께할 동료",Rect2(18,500,250,24),15,T.INK,T.BOLD)
	label("%d / 4"%ids.size(),Rect2(326,500,50,24),13)
	for i in range(3):
		var entry=[["","전체"],["front","전열"],["back","후열"]][i]
		action("so_f_"+("all" if entry[0]=="" else entry[0]),entry[1],Rect2(18+i*120,529,114,56),func():s.ui.tab=entry[0];host._save();host._draw_screen(),s.ui.get("tab","")==entry[0])
	var candidates=w.sortie_candidates(s.ui.get("tab",""));var previous=stage
	stage=scroll_page(589,58 if not s.quest.is_empty() else 76,maxf(76,ceil(candidates.size()/2.0)*76))
	for i in range(candidates.size()):
		var id=candidates[i];var x=(i%2)*172;var y=int(i/2)*76
		picture(id,Rect2(x,y,48,68),"formation-face")
		var full=id not in s.party and s.party.size()>=(3 if s.persona.fight==1 else 4)
		var b=action("so_tg_"+id,("출전 · " if id in s.party else "대기 · ")+w.person(id).name,Rect2(x+50,y,116,68),func():w.toggle_companion(id);host._save();host._draw_screen(),id in s.party,w.active() or full)
		b.add_theme_font_size_override("font_size",11)
	if candidates.is_empty():label("이 열에는 동료가 없습니다.",Rect2(0,0,340,48),14,T.MUTED)
	stage=previous
	var fronts=ids.filter(func(id):return w.person(id).row=="전열").size()
	label("모험가 정보가 없는 옛 저장은 지휘로 출발합니다." if not w.can_persona_fight() else "출전할 사람을 골라 주세요." if ids.is_empty() else "전열이 없어 후열이 바로 공격받습니다." if fronts==0 else "출발 시 모든 출전자의 HP·MP를 회복합니다.",Rect2(18,650 if not s.quest.is_empty() else 669,354,24),12,T.RED if fronts==0 else T.INK)
	if s.quest.is_empty():
		for i in range(3):
			fill("route_bg"+str(i),Rect2(18+i*120,700,114,30),T.INK)
			label(["탐색 5회","휴식","층 보스"][i],Rect2(24+i*120,700,102,30),12,T.PAPER,T.BOLD)
	else:action("accepted_quest","수락한 균열 의뢰로 출발",Rect2(18,680,354,56),func():host._act(w.depart_accepted_quest,"");host.go("explore"),true,ids.is_empty() or w.active())
	action("start_run","선택한 층으로 출발 →",Rect2(18,736,354,56),func():host._act(w.depart_dungeon.bind(w.selected_floor),"");host.go("explore"),true,ids.is_empty() or w.active())
	navigation()
	if host.save_error!=OK:action("save_retry","저장 다시 시도",Rect2(18,691,354,48),func():host._save();host._draw_screen(),true)
