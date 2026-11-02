extends "res://ui/create_screen.gd"

func build(owner_screen) -> void:
	setup(owner_screen,"출전 편성")
	var w=host.model;var s=w.s
	button("sortie_back","마을로",host.go.bind("town"),false,false,footer)
	text("직접 참전하면 동료 3명, 지휘하면 동료 4명과 출발합니다.",17)
	var h=row()
	button("so_fight_1","자기 참전",func():w.set_fight(1);host._save();host._draw_screen(),s.persona.fight==1,w.active(),h)
	button("so_fight_0","지휘",func():w.set_fight(0);host._save();host._draw_screen(),s.persona.fight==0,w.active(),h)
	text("출전 인원 %d / 4"%w.sortie_ids().size(),22,T.RED)
	for id in w.sortie_ids():text(w.person(id).name+" · "+w.person(id)["class"]+" · Lv.%d"%s.members[id].level,16)
	if w.sortie_ids().is_empty():text("출전할 사람이 없습니다. 한 명 이상 고르세요.",15,T.RED)
	text("함께할 동료",21)
	h=row()
	for item in [["","전체"],["front","전열"],["back","후열"]]:
		button("so_f_"+("all" if item[0]=="" else item[0]),item[1],func():s.ui.tab=item[0];host._save();host._draw_screen(),s.ui.get("tab","")==item[0],false,h)
	var candidates=w.sortie_candidates(s.ui.get("tab",""))
	if candidates.is_empty():text("이 열에는 동료가 없다.",14,T.MUTED)
	for id in candidates:
		button("so_tg_"+id,w.person(id).name+" · "+w.person(id)["class"]+" · Lv.%d"%s.members[id].level,func():w.toggle_companion(id);host._save();host._draw_screen(),id in s.party,w.active() or (id not in s.party and s.party.size()>=(3 if s.persona.fight==1 else 4)))
	var fronts=w.sortie_ids().filter(func(id):return w.person(id).row=="전열").size()
	if not w.sortie_ids().is_empty() and fronts==0:text("앞에서 막을 사람이 없습니다. 전열이 한 명도 없으면 후열이 바로 맞습니다.",14,T.RED)
	text("탐사 지역",21)
	var pick=OptionButton.new();body.add_child(pick);pick.custom_minimum_size.y=48
	for f in range(1,w.dungeon_max()+1):
		var info=w.dungeon_rules.floor_info(f);pick.add_item("%d층 · %s"%[f,w.dungeon_rules.zones[info.zone].name])
	pick.select(w.selected_floor-1);pick.item_selected.connect(func(i):w.selected_floor=i+1;s.dungeon_r21.sel=i+1;host._save());host.controls.dungeon_floor=pick
	text("출발 시 HP·MP를 모두 회복합니다.",14,T.MUTED)
	button("start_run","선택한 층으로 출발",func():host._act(w.depart_dungeon.bind(w.selected_floor),"");host.go("explore"),true,w.sortie_ids().is_empty() or w.active(),footer)
	if not s.quest.is_empty():button("accepted_quest","수락한 균열 의뢰로 출발",func():host._act(w.depart_accepted_quest,"");host.go("explore"),true,w.sortie_ids().is_empty() or w.active())
