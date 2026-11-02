extends "res://ui/panel_screen_r22.gd"
func build(owner_screen) -> void:
	setup(owner_screen,"장비 가방")
	if not state.selected().is_empty():detail(state.selected());return
	text("%d / 2000 · 금화 %d"%[state.entries().size(),host.model.s.gold],14,T.MUTED)
	var jobs=[["","모든 직업"]]
	for c in R.DATA.classes:jobs.append([c.id,c.name])
	choose("p7_bg_cls",jobs,state.bg.cls,func(v):bg("f_cls_"+("all" if v=="" else v)))
	var h=row();var slots=[["","모든 부위"]];var rarities=[["","모든 등급"]]
	for e in R.DATA.slots:slots.append(e)
	for k in ["common","fine","rare","epic","legend"]:rarities.append([k,host.model.Gear.RARITY[k]])
	choose("p7_bg_slot",slots,state.bg.slot,func(v):bg("f_slot_"+("all" if v=="" else v)),h);choose("p7_bg_rar",rarities,state.bg.rar,func(v):bg("f_rar_"+("all" if v=="" else v)),h)
	var list=state.listing();var page=R.page(list,int(state.bg.pg),R.BAG_PAGE)
	state.bg.pg=page.page
	if list.is_empty():text("가방이 비어 있습니다. 던전에서 장비를 얻으면 여기에 쌓입니다." if state.entries().is_empty() else "조건에 맞는 장비가 없습니다.",16,T.MUTED)
	for i in range(page.items.size()):
		var e=page.items[i];var it=host.model.gear.by_id[e.id];var hrow=row();var b=button("p7_bg_sel_"+str(i+1),it.name,bg.bind("sel_"+str(i+1)),false,false,hrow);b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		text("%s · Lv %d"%[host.model.Gear.RARITY[it.rarity],host.model.gear.rules.equip_lv[it.rarity]],13,T.MUTED)
	if page.pages>1:pager(list,int(state.bg.pg),R.BAG_PAGE,"bg")
	var bulk=state.bulk()
	if bulk.count>0:button("p7_bg_sellc","일반 %d개 일괄 판매 · 금화 %d"%[bulk.count,bulk.gold],bg.bind("sellc"),false,state.in_battle())
func detail(e: Dictionary) -> void:
	button("p7_bg_back","목록으로",bg.bind("back"));var it=host.model.gear.by_id[e.id];var same=state.members(it.cls).filter(func(m):return m.same);var id=""
	for m in same:
		if id=="" or m.id==state.bg.cmp:id=m.id
	var level=int(host.model.s.members[id].level) if id!="" else int(it.lv);gear_card(e,level);section("지금 낀 것과 비교")
	if id=="":text("이 직업의 동료가 없어 비교할 대상이 없습니다.",15,T.MUTED)
	else:
		var values=[]
		for m in same:values.append([m.id,member_name(m.id)])
		choose("p7_bg_cmp",values,id,func(v):bg("cmp_"+v));var cmp=state.compare(e,id)
		text("이 칸에 낀 장비가 없습니다. 효과가 모두 새로 더해집니다." if cmp.old.is_empty() else "낀 장비 · "+host.model.gear.by_id[cmp.old.id].name,14,T.MUTED)
		var grid=GridContainer.new();body.add_child(grid);grid.columns=4;grid.add_theme_constant_override("h_separation",7);grid.add_theme_constant_override("v_separation",10)
		for heading in ["효과","낀 것","이 장비","차이"]:text(heading,12,T.MUTED,grid)
		for r in cmp.rows:
			text(fx_name(r.key,it.cls),12,T.INK,grid);text(fx_value(r.key,r.before),12,T.MUTED,grid);text(fx_value(r.key,r.after),12,T.INK,grid);text("±0" if r.delta==0 else fx_value(r.key,r.delta),12,T.RED if r.delta>0 else T.INK,grid)
		var old_item=host.model.gear.by_id.get(cmp.old.get("id",""),{});var old_unique=old_item.get("sig",old_item.get("unique",{}));var new_unique=it.get("sig",it.get("unique",{}))
		if not old_unique.is_empty() or not new_unique.is_empty():text("고유 효과 · 낀 것: %s / 이 장비: %s"%[old_unique.get("name","없음"),new_unique.get("name","없음")],14,T.MUTED)
	section("장착하기")
	var members=state.members(it.cls)
	if members.is_empty():text("장착할 수 있는 사람이 없습니다.",15,T.MUTED)
	for m in members:
		var why=state.can_equip(m.id,e);button("p7_bg_eq_"+m.id,L.u("{name}에게 장착",{"name":member_name(m.id)},L.language(host.model.s)),bg.bind("eq_"+m.id),why=="",why!="")
		if why!="":text(why,13,T.MUTED)
	section("판매")
	if state.bg.conf==e.code:text("%s 등급 장비입니다. 정말 팔까요?"%host.model.Gear.RARITY[it.rarity],16,T.RED)
	button("p7_bg_sell",("정말 판매" if state.bg.conf==e.code else "판매")+" · 금화 %d"%host.model.gear.sell_price(e),bg.bind("sell"),false,state.in_battle())
func member_name(id: String) -> String:
	return state.member_name(id)
