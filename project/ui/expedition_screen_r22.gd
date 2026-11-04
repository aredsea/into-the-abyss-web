extends "res://ui/town_screen_r21.gd"
## P5 additions reuse the approved r21 canvas, map, portraits and action grammar.

func picture(id: String,r: Rect2,slot="bust") -> Control:
	return super(id,r,slot)

func small_party(y: float,tall=false) -> void:
	var w=host.model;var ids=w.expedition_ids() if w.active() else w.s.summary.get("gains",[]).map(func(g):return g.id)
	for i in range(ids.size()):
		var id=ids[i];var m=w.s.members[id];var b=w.s.run.get("maxima",{}).get(id,w.stats(id,m.level));var x=18+i*91
		picture(id,Rect2(x,y,86,64),"town-party-face")
		label(w.person(id).name,Rect2(x,y+64,86,18),11,T.INK,T.BOLD)
		resource_numbers(Rect2(x,y+81,86,22),m.hp,b.hp)
		resource("party_hp:"+id,Rect2(x,y+104,86,9),m.hp,b.hp)
		resource("party_mp:"+id,Rect2(x,y+116,86,3),m.mp,b.mp,false)
		resource_numbers(Rect2(x,y+120,86,17),m.mp,b.mp,false,15)

func exploration() -> void:
	var w=host.model;var r=w.s.run
	traced_title("rest" if r.phase=="rest" else "explore",Rect2(18,0,216,66))
	display(w.dungeon_title(),Rect2(18,69,354,26),T.INK,21)
	action("expedition_log","탐색 기록 · 주머니",Rect2(18,97,354,44),host.go.bind("expedition_log"))
	var previous=stage;stage=scroll_page(151,474,474)
	var sheet=fill("source_exploration_sheet",Rect2(0,0,342,474),T.PAPER)
	var y=source_entries(w.source_expedition_view("head"),0)
	if r.phase=="explore":
		var map=preload("res://ui/town_map_r21.gd").new();stage.add_child(map);map.position=Vector2(0,y);map.size=Vector2(342,338);map.configure(r,5);mark("source_progress_map",map);y+=350
	y=source_entries(w.source_expedition_view("last"),y)
	y=source_entries(w.source_expedition_view("party"),y+8)
	stage.custom_minimum_size.y=y+12;sheet.size.y=y+12;stage=previous
	var go=w.ExpeditionUI.new();go.lang=L.language(w.s)
	action("final_battle" if r.phase=="rest" else "advance",go.u("층 보스에게 도전" if r.phase=="rest" else "탐색한다"),Rect2(18,650,354,44),func():host._act(w.final_battle if r.phase=="rest" else w.advance,""),true,false,false)
	host.controls["ex_boss" if r.phase=="rest" else "ex_go"]=host.controls["final_battle" if r.phase=="rest" else "advance"]
	var sub=go.u("{boss}, 레이드 전투(4인)",{"boss":w.source_expedition_state().boss_name}) if r.phase=="rest" else go.u("{next}/{total}번째 (전투 {battle}%, 발견 {find}%)",{"next":r.step+1,"total":5,"battle":70,"find":30})
	paragraph(sub,Rect2(18,626,354,22),11,T.MUTED,false)
	action("dungeon_bag","보급품",Rect2(18,705,108,41),host.go.bind("bag"))
	if r.phase=="rest":action("rest_equipment","장비 정비",Rect2(136,705,108,41),func():host.who=w.expedition_ids()[0];host.go("equipment"))
	else:action("cards","카드",Rect2(136,705,108,41),host.go.bind("cards"))
	var entry=w.source_expedition_view("retreat")[0]
	action("retreat",entry.text,Rect2(254,705,118,41),func():
		if w.expedition_retreat("retreat"):host._save();host._ask("",w.expedition_retreat.bind("retreat_yes")),false,false,false)
	host.controls.ex_retreat=host.controls.retreat
	var retreat_sub=paragraph(entry.get("sub",""),Rect2(18,747,354,16),9,T.MUTED,false)
	retreat_sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

func source_entries(entries: Array,y: float) -> float:
	var i=0
	while i<entries.size():
		var e=entries[i]
		if e.role=="pip":
			var x=0.0
			while i<entries.size() and entries[i].role=="pip":
				var p=entries[i];var width=34.0 if i+2<entries.size() and p.text.is_valid_int() else 63.0
				fill("source_pip:"+str(i),Rect2(x,y,width-4,30),T.PALE if p.state=="" else T.INK if p.state=="done" else T.RED)
				var node=label(p.text,Rect2(x,y,width-4,30),12,T.INK if p.state=="" else T.PAPER,T.BOLD,false);node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;node.set_meta("expe_entry",p)
				x+=width;i+=1
			y+=40;continue
		if e.role=="face":
			picture(e.id,Rect2(0,y,72,64),"town-party-face").set_meta("expe_entry",e);y+=68
		elif e.has("action"):
			var node=action(e.action,e.text,Rect2(0,y,342,44),source_action.bind(e.action),e.get("selected",false),not e.enabled,false);node.set_meta("expe_entry",e);y+=46
			if e.get("sub","")!="":
				var sub_height=maxf(26,T.BODY.get_multiline_string_size(e.sub,HORIZONTAL_ALIGNMENT_LEFT,334,11).y+10)
				paragraph(e.sub,Rect2(4,y,334,sub_height),11,T.MUTED,false);y+=sub_height+4
		elif e.role=="bar":
			var node=label(e.text,Rect2(0,y,342,24),12,T.INK,T.BODY,false);node.set_meta("expe_entry",e);y+=25
			if e.kind in ["hp","mp"]:
				resource("source_bar:"+str(y),Rect2(0,y,342,9 if e.kind=="hp" else 3),e.ratio,1,e.kind=="hp")
			else:
				fill("source_bar_track:"+str(y),Rect2(0,y,342,5),T.PALE);fill("source_bar:"+str(y),Rect2(0,y,342*e.ratio,5),T.BLUE)
			y+=14
		else:
			var fs=18 if e.role=="title" else 14;var font=T.BOLD if e.role in ["title","name"] else T.BODY
			var height=maxf(28,font.get_multiline_string_size(e.text,HORIZONTAL_ALIGNMENT_LEFT,342,fs).y+14)
			var inset=36 if e.has("icon") else 0
			if e.has("icon"):icon(e.icon.trim_prefix("pl-"),Rect2(0,y,28,28))
			var node=paragraph(e.text,Rect2(inset,y,342-inset,height),fs,T.INK,false);node.add_theme_font_override("font",font);node.set_meta("expe_entry",e);y+=height+4
		i+=1
	return y

func source_action(id: String) -> void:
	var w=host.model
	if id.begins_with("ex_u_"):
		var parts=id.trim_prefix("ex_u_").rsplit("_",true,1);var who=w.expedition_equip_key(int(parts[1]))
		host._act(w.use_expedition_item.bind(w.web_item_id(parts[0]),who),"")

func build_page() -> void:
	if host.screen=="explore" and host.model.expedition() and host.model.active() and host.model.s.run.ask and host.confirm.is_empty():
		host.confirm={"prompt":"모은 보상을 정산하고 귀환할까요?","callback":host.model.expedition_retreat.bind("retreat_yes")}
	if host.screen=="expedition_log":
		page_background();header(host.model.expedition_label(),"explore")
		fill("log_title_rule",Rect2(18,59,54,4),T.RED)
		var w=host.model;var r=w.s.run;var lines=[]
		for line in r.log:lines.append(line)
		lines.append("미정산 금화 %d · 경험치 %d"%[r.gold,r.xp])
		for key in r.loot_items:lines.append(w.expedition_item_name(key)+" ×%d"%r.loot_items[key])
		for code in r.loot_gear:lines.append(w.expedition_gear_label(code,L.language(w.s)=="en"))
		if L.language(w.s)=="en":lines.push_front(w.expedition_floor_context(int(r.floor)))
		var prev=stage;stage=scroll_page(82,601,601);var content=stage;var y=0.0
		for i in range(lines.size()):
			y=reading_line(lines[i],y,16)
			fill("log_row_rule:"+str(i),Rect2(0,y-6,342,3),T.INK)
		content.custom_minimum_size.y=maxf(601,y+16)
		stage=prev;action("log_back","원정으로",Rect2(18,705,354,44),host.go.bind("explore"),true);navigation();return
	super()

func retreat() -> void:
	if not host.model.expedition():super();return
	header("대던전","explore")
	# Confirmation keeps the same live floor/party/potion information above it.
	var previous=stage;stage=scroll_page(64,319,319)
	var sheet=fill("retreat_party_sheet",Rect2(0,0,342,319),T.PAPER)
	var y=0.0
	for section in ["head","last","party"]:
		var before=stage.get_child_count();y=source_entries(host.model.source_expedition_view(section),y)
		for node in stage.get_children().slice(before):
			if node.has_meta("expe_entry"):node.set_meta("expe6_entry",node.get_meta("expe_entry"));node.remove_meta("expe_entry")
	stage.custom_minimum_size.y=maxf(319,y+12);sheet.size.y=stage.custom_minimum_size.y;stage=previous
	fill("return_sheet",Rect2(0,389,390,371),T.PAPER);traced_title("retreat",Rect2(18,391,298,42))
	var entries=host.model.source_expedition_view("retreat")
	paragraph(entries[0].text,Rect2(18,445,354,190),16,T.INK,false).set_meta("expe_entry",entries[0])
	action("accept",entries[1].text,Rect2(18,676,170,48),host._accept,true,false,false).set_meta("expe_entry",entries[1])
	action("cancel",entries[2].text,Rect2(200,676,172,48),func():host.model.expedition_retreat("retreat_no");host.confirm={};host._save();host._draw_screen(),false,false,false).set_meta("expe_entry",entries[2])
	host.controls.ex_retreat_yes=host.controls.accept;host.controls.ex_retreat_no=host.controls.cancel

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
	var entries=w.source_expedition_view("done");var lines=entries.filter(func(e):return not e.has("action"))
	paragraph(lines[0].text,Rect2(18,68,354,60),28,T.RED,false).set_meta("expe_entry",lines[0])
	fill("source_summary_caption",Rect2(12,134,366,90),T.PAPER)
	paragraph(lines[1].text,Rect2(18,140,354,78),16,T.INK,false).set_meta("expe_entry",lines[1])
	var prev=stage;stage=scroll_page(230,390,390)
	var sheet=fill("source_summary_sheet",Rect2(0,0,342,390),T.PAPER)
	stage.custom_minimum_size.y=maxf(390,source_entries(lines.slice(2),0)+12);sheet.size.y=stage.custom_minimum_size.y;stage=prev
	for entry in entries:
		if not entry.has("action"):continue
		if entry.action=="ex_next":
			action("summary_next",entry.text,Rect2(18,640,354,48),func():host._act(w.next_dungeon_floor,"");host.go("explore"),true,false,false).set_meta("expe_entry",entry)
			paragraph(entry.sub,Rect2(18,688,354,16),10,T.MUTED,false);host.controls.ex_next=host.controls.summary_next
		else:
			action("summary_home",entry.text,Rect2(18,705,354,44),func():w.expedition_home();host._save();host.go("town"),r.result!="clear",false,false).set_meta("expe_entry",entry)
			paragraph(entry.sub,Rect2(18,750,354,16),10,T.MUTED,false);host.controls.ex_home=host.controls.summary_home
