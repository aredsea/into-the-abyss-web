extends RefCounted
## Reuse the existing world's controls; town layout remains owned by branch D.
static func departure(v):
	var w=v.model; var rules=w.dungeon_rules
	v.text("대던전 · 층 선택",20,v.GOLD)
	var floor_pick=OptionButton.new(); v.content.add_child(floor_pick); floor_pick.custom_minimum_size.y=48
	for f in range(1,w.dungeon_max()+1):
		var info=rules.floor_info(f)
		floor_pick.add_item("%d층 · %s"%[f,rules.zones[info.zone].name],f)
	floor_pick.select(clampi(w.selected_floor-1,0,floor_pick.item_count-1))
	floor_pick.item_selected.connect(func(i):w.selected_floor=i+1; w.selected_rift="")
	v.controls["dungeon_floor"]=floor_pick
	v.text("탐색 5회 → 휴식 → 층 보스\n전투 70% · 발견 30% / HP·MP는 전투 사이에 이어집니다.",14)
	v.button("start_run","선택한 층으로 출발",func():v._act(w.depart_dungeon.bind(w.selected_floor),""); v.go("explore"))
	v.text("소규모 균열은 길드에서 의뢰를 받아 출정합니다.",13,v.MUTED)
	v.text("최심층 %d · 구역 보스 %d / 9"%[w.s.dungeon_r21.best,w.s.dungeon_r21.cleared_bosses.size()],13,v.MUTED)

static func explore(v):
	var w=v.model; var r=w.s.run
	v.text(w.dungeon_title(),20,v.GOLD)
	v.text("탐색 %d / 5 · 정예 %d / 2"%[r.step,r.elites],14)
	v.text(r.last if r.last!="入場" else "층의 입구에 도착했다.",14)
	if r.phase=="rest":
		v.text("휴식 · 파티 HP 30% / MP 60% 회복 완료",16)
		v.button("final_battle","층 보스에게 도전",func():v._act(w.final_battle,""))
	else: v.button("advance","탐색",func():v._act(w.advance,""))
	v.text("미정산 금화 %d · 경험치 %d"%[r.gold,r.xp],14,v.GOLD)
	for id in w.s.party:
		var m=w.s.members[id]; var b=w.stats(id,m.level)
		v.text("%s · HP %d/%d · MP %d/%d"%[w.person(id).name,m.hp,b.hp,m.mp,b.mp],13)
	v.button("dungeon_bag","보급품 사용",v.go.bind("bag"))
	v.button("retreat","모은 보상을 챙겨 귀환",func():v._ask("층 도전을 끝내고 모은 보상을 정산할까요?",w.settle.bind("retreat")))
