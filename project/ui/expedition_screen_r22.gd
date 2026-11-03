extends "res://ui/town_screen_r21.gd"
## P5 additions reuse the approved r21 canvas, map, portraits and action grammar.

func picture(id: String,r: Rect2,slot="bust") -> Control:
	if id!="persona":return super(id,r,slot)
	var p=fill("persona_portrait",r,T.PALE)
	var name=label("당신",Rect2(r.position+Vector2(4,4),r.size-Vector2(8,8)),16,T.INK,T.BOLD)
	name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return p

func small_party(y: float,tall=false) -> void:
	var w=host.model;var ids=w.expedition_ids() if w.active() else w.s.summary.get("gains",[]).map(func(g):return g.id)
	for i in range(ids.size()):
		var id=ids[i];var m=w.s.members[id];var b=w.s.run.get("maxima",{}).get(id,w.stats(id,m.level));var x=18+i*91
		picture(id,Rect2(x,y,86,64),"town-party-face")
		label(w.person(id).name,Rect2(x,y+64,86,18),11,T.INK,T.BOLD)
		label("HP %d/%d"%[m.hp,b.hp],Rect2(x,y+82,86,17),10)
		label("MP %d/%d"%[m.mp,b.mp],Rect2(x,y+100,86,17),10)
		fill("party_hp:"+id,Rect2(x,y+119,86*clampf(float(m.hp)/maxf(1,b.hp),0,1),4),T.RED)

func exploration() -> void:
	super()
	var w=host.model;var r=w.s.run
	if w.expedition() and host.controls.has("retreat"):
		var button=host.controls.retreat
		for connection in button.pressed.get_connections():button.pressed.disconnect(connection.callable)
		button.pressed.connect(func():
			if w.expedition_retreat("retreat"):
				host._save();host._ask("모은 보상을 정산하고 귀환할까요?",w.expedition_retreat.bind("retreat_yes")))
	if boxes.has("source_progress_map"):
		var map=boxes.source_progress_map
		map.position.y=151;map.size.y=306
		for i in range(map.points.size()):map.points[i].y*=.87
		map.queue_redraw()
	if r.phase=="rest":
		# Replace the old card shortcut with source rest equipment management.
		var old=host.controls.get("cards")
		if is_instance_valid(old):old.queue_free();host.controls.erase("cards")
		action("rest_equipment","장비 정비",Rect2(136,705,108,44),func():host.who=w.expedition_ids()[0];host.go("equipment"))
	var mods=w.expedition_mods()
	if r.phase=="rest":
		remove_text_at(Vector2(18,458))
		label("HP %d%% · MP %d%% 회복 완료"%[int(round((.3+mods.rest_hp)*100)),int(round((.6+mods.rest_mp)*100))],Rect2(18,458,354,24),12)
	# Discovery text may be longer than the status strip; an explicit log opens it whole.
	action("expedition_log","탐색 기록 · 주머니",Rect2(18,97 if r.phase!="rest" else 220,354,44),host.go.bind("expedition_log"))

func build_page() -> void:
	if host.screen=="explore" and host.model.expedition() and host.model.active() and host.model.s.run.ask and host.confirm.is_empty():
		host.confirm={"prompt":"모은 보상을 정산하고 귀환할까요?","callback":host.model.expedition_retreat.bind("retreat_yes")}
	if host.screen=="expedition_log":
		page_background();header(host.model.expedition_label(),"explore")
		var w=host.model;var r=w.s.run;var lines=[]
		for line in r.log:lines.append(line)
		lines.append("미정산 금화 %d · 경험치 %d"%[r.gold,r.xp])
		for key in r.loot_items:lines.append(w.expedition_item_name(key)+" ×%d"%r.loot_items[key])
		for code in r.loot_gear:lines.append(w.expedition_gear_label(code,L.language(w.s)=="en"))
		if L.language(w.s)=="en":lines.push_front(w.expedition_floor_context(int(r.floor)))
		var prev=stage;stage=scroll_page(70,613,maxi(613,lines.size()*75))
		for i in range(lines.size()):paragraph(lines[i],Rect2(0,i*75,342,70),14)
		stage=prev;action("log_back","원정으로",Rect2(18,705,354,44),host.go.bind("explore"),true);navigation();return
	super()

func retreat() -> void:
	super()
	if not host.model.expedition():return
	var cancel=host.controls.get("cancel")
	if is_instance_valid(cancel):
		for connection in cancel.pressed.get_connections():cancel.pressed.disconnect(connection.callable)
		cancel.pressed.connect(func():host.model.expedition_retreat("retreat_no");host.confirm={};host._save();host._draw_screen())

func bag() -> void:
	if not host.selected_item.is_empty():target_item();return
	var w=host.model;var bank=w.s.items;var display_items=bank.duplicate(true)
	for it in w.config.items:display_items[it.id]=w.supplies(it.id)
	w.s.items=display_items;super();w.s.items=bank
	label("거점 보급품 + 탐색 주머니 · 주운 것부터 사용",Rect2(18,754,354,20),11)

func target_item() -> void:
	var w=host.model;var party=w.s.party;w.s.party=w.expedition_ids()
	super();w.s.party=party
	remove_text_at(Vector2(324,110))
	label("× %d"%w.supplies(host.selected_item),Rect2(324,110,62,36),24,T.INK,T.BOLD)
	var ids=w.expedition_ids()
	for i in range(ids.size()):
		var preview=w.item_preview(host.selected_item,ids[i])
		if not preview.usable:label(preview.reason,Rect2(142,278+i*109,219,19),11,T.RED)
	var p=w.item_preview(host.selected_item,host.selected_target)
	if not p.usable and not host.selected_target.is_empty():label(p.reason,Rect2(18,604,354,28),12,T.RED)

func remove_text_at(point: Vector2) -> void:
	for child in stage.get_children():
		if child is Label and child.position==point:stage.remove_child(child);child.queue_free()

func equipment() -> void:
	var w=host.model
	if not w.active():super();return
	header("휴식 · 장비 정비","explore")
	var ids=w.expedition_ids()
	if host.who not in ids:host.who=ids[0]
	for i in range(ids.size()):
		var id=ids[i];action("rest_who:"+id,w.person(id).name,Rect2(18+i*91,66,86,44),func():host.who=id;host._draw_screen(),host.who==id)
	label("%s · Lv.%d"%[w.person(host.who).name,w.s.members[host.who].level],Rect2(18,124,354,26),18,T.INK,T.BOLD)
	paragraph("보유 장비를 갈아 끼울 수 있습니다.\n탐색에서 주운 장비는 정산 뒤 가방에 들어갑니다.",Rect2(18,157,354,47),13)
	var eq=w.s.equipment[host.who]
	for i in range(3):
		var slot=["weapon","armor","acc"][i]
		action("unequip:"+slot,w.Gear.SLOT[slot]+(" 해제" if eq.has(slot) else " 미장착"),Rect2(18+i*118,220,112,44),func():host._act(w.unequip.bind(host.who,slot),"해제했습니다."),false,not eq.has(slot))
	var entries=w.s.gear.filter(func(e):return w.gear.by_id[e.id].cls==w.class_def(host.who).id)
	var prev=stage;stage=scroll_page(282,407,maxi(407,entries.size()*122))
	if entries.is_empty():paragraph("이 직업의 보유 장비가 없습니다.",Rect2(0,20,342,60),16)
	for i in range(entries.size()):
		var e=entries[i];var it=w.gear.by_id[e.id];var y=i*122
		label(it.name,Rect2(0,y,342,27),17,T.INK,T.BOLD)
		label(host._gear_caption(it),Rect2(0,y+29,342,23),12)
		var wearer=w.wearer(e.uid);var usable=w.s.members[host.who].level>=w.gear.rules.equip_lv[it.rarity]
		var reason="Lv.%d 필요"%w.gear.rules.equip_lv[it.rarity] if not usable else "장착 중" if wearer==host.who else "장착"
		action("equip:"+str(int(e.uid)),reason,Rect2(0,y+62,342,44),func():host._act(w.equip.bind(host.who,e.uid),"장착했습니다."),wearer!=host.who,not usable or wearer==host.who)
	stage=prev;action("equipment_back","원정으로",Rect2(18,705,354,44),host.go.bind("explore"),true)

func summary() -> void:
	var w=host.model;var r=w.s.summary
	header("원정 정산")
	plate("preparation-ruins",Rect2(0,52,390,219))
	display("%d층 %s"%[r.floor,{"clear":"돌파","retreat":"귀환","defeat":"도전 실패"}[r.result]],Rect2(18,68,354,60),T.RED,40)
	label("탐색 %d/5 · 전투 승리 %d회"%[r.steps,r.wins],Rect2(18,143,354,28),16,T.INK,T.BOLD)
	var lines=["획득 금화 %d · 경험치 %d"%[r.gold,r.xp]]
	if r.first:lines.append("구역 보스 첫 처치 · 다음 구역 개방")
	if r.penalty>0:lines.append("들고 간 금화 손실 %d"%r.penalty)
	if r.kept_gold>0:lines.append("케른의 계약 · 금화 %d 보전"%r.kept_gold)
	if r.lost>0:lines.append("잃은 미정산 금화 %d"%r.lost)
	for key in r.items:lines.append(w.item_def(w.web_item_id(key)).name+" ×%d"%r.items[key])
	for key in r.lost_items:lines.append("분실 · "+w.item_def(w.web_item_id(key)).name+" ×%d"%r.lost_items[key])
	for code in r.gear:lines.append("장비 · "+w.expedition_gear_label(code,L.language(w.s)=="en"))
	if r.gear_lost>0:lines.append("가방이 가득 차 장비 %d개 폐기"%r.gear_lost)
	if r.lost_gear>0:lines.append("장비 %d개 분실"%r.lost_gear)
	for g in r.gains:lines.append("%s · Lv.%d → %d"%[w.person(g.id).name,g.before,g.level])
	for line in w.expedition_summary_aff_lines():lines.append("호감 · "+line)
	if r.fell:lines.append("전투 중 쓰러진 동료가 있었습니다.")
	lines.append("보상은 지급되었습니다. 같은 정산은 다시 지급되지 않습니다.")
	var prev=stage;stage=scroll_page(230,390,maxi(390,lines.size()*57))
	for i in range(lines.size()):paragraph(lines[i],Rect2(0,i*57,342,52),14)
	stage=prev
	if w.s.run.get("next_available",false):action("summary_next","다음 층으로 내려간다",Rect2(18,640,354,48),func():host._act(w.next_dungeon_floor,"");host.go("explore"),true)
	action("summary_home","토르바로",Rect2(18,705,354,44),func():w.expedition_home();host._save();host.go("town"),r.result!="clear")
