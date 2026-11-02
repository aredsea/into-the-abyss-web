extends SceneTree
const World=preload("res://game/facilities_world_r22.gd")
const Rules=preload("res://game/guild_rules_r22.gd")
var checks=0
var failures=[]
var samples=0
var groups={}
var specimens={}
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);if failures.size()<20:push_error(msg)
func same(a,b) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for k in a:
			if not b.has(k) or not same(a[k],b[k]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not same(a[i],b[i]):return false
		return true
	if (a is float or a is int) and (b is float or b is int):return absf(a-b)<.00001
	return a==b
func compare(group: String,ok: bool):
	samples+=1;groups[group]=groups.get(group,0)+1;check(ok,group+" row "+str(groups[group]))
func ready_world():
	var w=World.new()
	w.create_action("race_human");w.create_action("nat_border");w.create_action("cls_warrior");w.create_action("auto");w.create_action("done");w.create_action("pick_teiris","sc");w.create_action("go","sc")
	w.s.dialogue_r21.queue=[];return w
func set_level(w,id,lv,xp=0):
	w.s.members[id].level=lv;w.s.members[id].xp=xp
	if id=="persona":w.s.persona.lv=lv;w.s.persona.exp=xp;w.s.persona_progress_r21={"level":lv,"xp":xp}
func force_result(w,result: String):
	w.s.run.phase="battle"
	var b=w.ModernBattle.new(w.battle_data())
	if result=="victory":
		for e in b.data.enemies:e.hp=0;e.gauge=0
	else:
		for a in b.data.allies:a.hp=0
	b.result=result;w.record_battle(b.snapshot())
func _initialize():call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/facilities-r22/oracle.json"))
	var w=ready_world()
	specimens.town=w.s.duplicate(true)
	check(same(w.shop_classes(),oracle.classes) and oracle.classes.size()==10,"all ten catalog classes in source order")
	for row in oracle.stock:
		var rows=w.gear.stock_source(int(row.seed),int(row.day),row.cls,row.slot).map(func(e):return {"id":e.id,"code":e.code,"price":e.price})
		compare("stock",same(rows,row.rows))
	for row in oracle.process:
		var classes=row.roster.map(func(id):return w.class_def(id).id)
		var out=w.gear.process_for(int(row.seed),int(row.n),row.cls,classes,int(row.level))
		compare("process",out.get("code","")==row.code and w.gear.band(int(row.level)).price==row.price)
	for row in oracle.quests:
		var q=Rules.quest(int(row.seed),int(row.index),int(row.qn),int(row.level),row.board)
		compare("quests",same(Rules.source_view(q),row.q) and w.dungeon_rules.quest_gold(q,int(q.lv))==row.gold and Rules.fight(q)==row.fight)
	for row in oracle.forge:
		var e={"id":row.id,"seed":int(row.gear_seed),"forge":int(row.forge),"tries":int(row.tries)}
		var ok=false if e.forge==10 else w.gear.forge_result(int(row.seed),e)
		compare("forge",(e.forge==10 if not row.has("success") else ok==row.success) and (e.forge==10 or w.gear.forge_cost(e)==row.cost))
	for row in oracle.scroll:
		w=ready_world();w.s.owned=["hildegard"]
		set_level(w,"persona",int(row.level),5);set_level(w,"hildegard",int(row.level),5);w.s.items.level_scroll=row.count
		w.use_item("level_scroll",row.who)
		compare("scroll",w.s.persona.lv==row.persona_lv and w.s.persona.exp==row.persona_xp and w.s.members.hildegard.level==row.member_lv and w.s.members.hildegard.xp==row.member_xp and w.s.items.level_scroll==row.remaining)
	var seed=-1
	for row in oracle.guild_flow:
		if seed!=int(row.seed):
			seed=int(row.seed);w=ready_world();w.s.owned=[];set_level(w,"persona",17)
			w.s.gold=10000;w.s.town_r21={"seed":seed,"counter":0,"qn":0};w.s.quest={};w.refill_board()
		var arg=row.arg
		if arg.begins_with("acc_"):w.accept_quest(int(arg.trim_prefix("acc_q")))
		elif arg.begins_with("rej_"):w.reject_quest(int(arg.trim_prefix("rej_q")))
		elif arg=="refresh":w.refresh_board()
		elif arg=="drop":w.abandon_quest()
		var board=w.s.board.map(func(q):return Rules.source_view(q))
		compare("guild_flow",same(board,row.board) and w.s.gold==row.gold and w.s.refreshes==row.rr and w.s.town_r21.counter==row.index and w.s.town_r21.qn==row.qn and ("" if w.s.quest.is_empty() else "q"+str(int(w.s.quest.id)))==row.active)
	for row in oracle.settlement:
		w=ready_world();w.s.owned=["hildegard","teiris"];w.s.party=w.s.owned.duplicate();w.s.gold=row.gold_before;w.s.day=3;w.s.refreshes=4
		w.s.town_r21={"seed":int(row.seed),"counter":0,"qn":7}
		for id in ["persona","hildegard","teiris"]:set_level(w,id,17)
		w.s.members.hildegard.aff=99.5;w.s.members.teiris.aff=150
		var q={"id":7,"source_id":"q7","title":"남서 설산 균열, 고립된 탐사대 구조","name":"고립된 탐사대 구조","rift":"남서 설산 균열","kind":"구조","stars":2,"difficulty":row.difficulty,"gold":100,"reward_v":2,"lv":17,"level":17,"cmp":true,"elite":row.difficulty=="엘리트"}
		w.s.board=[q];w.s.quest=q.duplicate(true)
		check(w.depart_accepted_quest(),"quest fixture departure")
		w.s.run.gold=123;w.s.run.xp=75
		force_result(w,"victory" if row.over=="win" else "defeat")
		check(w.settle("clear" if row.over=="win" else "defeat"),"verified battle settlement")
		var codes=w.s.gear.map(func(e):return w.gear.code(e))
		compare("settlement",w.s.gold==row.gold and w.s.day==row.day and w.s.refreshes==row.rr and w.s.quest_wins==row.done and w.s.quest.is_empty() and same(codes,row.gear) and w.s.persona.exp==row.persona_xp and w.s.members.hildegard.xp==row.member_xp and same({"hildegard":w.s.members.hildegard.aff,"teiris":w.s.members.teiris.aff},row.aff))
		check(w.s.board.size()==4 and not w.s.board.any(func(v):return v.id==7),"quest consumed and refilled")
		var saved=w.s.duplicate(true);check(not w.settle("clear") and w.s==saved,"repeated settlement atomic")
		var copy=World.new();check(copy.restore(saved) and same(copy.s,saved),"quest settlement save roundtrip")
	# Actual finish_battle used to award elite gear twice. It must award one source set.
	w=ready_world();w.s.gold=100000;w.s.owned=["hildegard","teiris"];w.s.party=w.s.owned.duplicate()
	var elite=w.s.board.filter(func(q):return q.difficulty=="엘리트")[0]
	check(w.accept_quest(elite.id) and w.depart_accepted_quest(),"elite engine path")
	force_result(w,"victory");check(w.finish_battle(),"actual finish_battle settlement")
	check(w.s.gear.size()==Rules.gear_count(w.s.town_r21.seed,int(elite.id)),"elite drops paid exactly once")
	check(w.s.gear.all(func(e):return e.get("source_r21",false)),"quest drop source roll preserved")
	specimens.quest=w.s.duplicate(true)
	w=ready_world();w.s.gold=100000
	check(w.facility_route("smithy") and not w.complete_smithy(),"smithy clean visit")
	check(w.process_gear() and not w.facility_route("town"),"smithy return blocked until complete")
	check(w.complete_smithy() and not w.facility_route("town"),"receipt blocks pending exit")
	check(w.acknowledge_receipt() and w.facility_route("town"),"receipt acknowledged and return")
	w.facility_route("shop");w.buy("hp_s");w.buy("hp_s")
	check(w.facility_route("town") and w.receipt.items.hp_s==2,"shop merged purchase receipt")
	check(not w.facility_route("inn") and w.acknowledge_receipt() and w.facility_route("inn"),"shop receipt once")
	w.s.refreshes=3;var day=w.s.day;var id=w.s.owned[0]
	check(w.inn(id,"meal") and not w.inn(id,"meal") and w.inn(id,"rest") and w.s.day==day+1 and w.s.refreshes==3 and w.inn(id,"meal"),"inn daily reset preserves guild refresh count")
	# Source scroll target on a valid save synchronizes every persona XP view.
	w=ready_world();w.s.items.level_scroll=2;check(w.use_item("level_scroll","persona"),"persona scroll")
	var reload=World.new();check(reload.restore(w.s) and same(reload.s,w.s),"scroll save roundtrip")
	# Empty roster, all ten classes, high persona level and unowned-class purchases.
	w=ready_world();w.s.owned=[];w.s.party=[];w.s.gold=100000;set_level(w,"persona",40)
	for cls in w.shop_classes():
		var rows=w.shop_stock(cls,"weapon");check(rows.size()>0,"unowned class display "+cls)
		check(w.buy_gear(rows[0].code,cls) and not w.buy_gear(rows[0].code,cls),"shared daily stock and sold flag "+cls)
	check(w.process_classes()==["warrior"] and w.process_gear(),"persona-only process pool")
	specimens.shop_and_process=w.s.duplicate(true)
	var next_before=w.s.commerce_r21.process_n;var clone=World.new();check(clone.restore(w.s),"smithy counter roundtrip")
	w.process_gear();clone.process_gear();check(w.s.gear[-1]==clone.s.gear[-1] and w.s.commerce_r21.process_n==next_before+1,"same next process after reload")
	# Rejections leave all persistent state unchanged.
	w=ready_world();w.s.gold=0;var before=w.s.duplicate(true)
	check(not w.process_gear() and not w.buy_gear(w.shop_stock("warrior","weapon")[0].code,"warrior") and not w.use_item("level_scroll","persona") and w.s==before,"poor / no-scroll rejections atomic")
	w.s.gold=100000;w.depart_dungeon(1,1);before=w.s.duplicate(true)
	check(not w.buy("hp_s") and not w.process_gear() and not w.use_item("level_scroll","persona") and not w.reject_quest(w.s.board[0].id) and w.s==before,"active expedition town actions atomic")
	w=ready_world();w.s.gold=100000;w.s.items.hp_s=10000
	check(w.buy("hp_s") and w.s.items.hp_s==10001,"source consumables have no 10000 purchase cap")
	specimens.large_items=w.s.duplicate(true)
	clone=World.new();before=w.s.duplicate(true);check(clone.restore(before) and same(clone.s,before),"large item count roundtrip without changing input")
	var invalid=before.duplicate(true);invalid.items.hp_s=1.5
	check(not clone.restore(invalid) and same(clone.s,before),"fractional inventory rejected atomically")
	w.s.gold=100000001;clone=World.new();check(clone.restore(w.s) and clone.s.gold==w.s.gold,"source gold preserved beyond old web validator cap")
	specimens.large_gold=w.s.duplicate(true);specimens.large_gold.items.hp_s=1
	w.process_gear();var original=w.s.gear[-1].duplicate(true);w.s.serial+=1;var duplicate=original.duplicate(true);duplicate.uid=w.s.serial;w.s.gear.append(duplicate)
	check(w.forge(original.uid) and w.s.gear[-1].forge==w.s.gear[-2].forge and w.s.gear[-1].tries==1 and w.s.gear[-2].tries==1,"duplicate codes share refinement state")
	clone=World.new();check(clone.restore(w.s),"code refinement save roundtrip")
	w.forge(original.uid);clone.forge(duplicate.uid);check(w.s.gear==clone.s.gear and w.s.gold==clone.s.gold,"same refinement across copies after reload")
	specimens.refinement=w.s.duplicate(true)
	w=ready_world();w.s.gold=100000;var equipped=w.shop_stock("warrior","weapon")[0]
	w.buy_gear(equipped.code,"warrior");w.equip("persona",w.s.serial)
	var sample=w.s.gear[0].duplicate(true)
	for i in range(2000):
		w.s.serial+=1;var entry=sample.duplicate(true);entry.uid=w.s.serial;w.s.gear.append(entry)
	check(w.bag_count()==2000,"equipped gear excluded from source bag cap")
	before=w.s.duplicate(true);check(not w.process_gear() and w.s==before,"full bag processing atomic")
	w.s.gear.pop_back();check(w.process_gear() and w.bag_count()==2000,"bag last slot processing succeeds with equipped item")
	# Real archived saves: import, input preservation, and an idempotent second load.
	var legacy=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy-specimens.json"))
	for specimen in legacy:
		var raw=JSON.parse_string(FileAccess.get_file_as_string(specimen.path));var untouched=raw.duplicate(true);var migrated=World.new()
		check(migrated.restore(raw) and raw==untouched,"real legacy import preserves input "+specimen.path)
		var again=World.new();check(again.restore(migrated.s) and same(again.s,migrated.s),"legacy migration idempotent "+specimen.path)
	w=ready_world();set_level(w,"persona",17);w.s.persona_progress_r21={"level":3,"xp":1};before=w.s.duplicate(true)
	clone=World.new();check(clone.restore(before) and clone.s.persona_progress_r21.level==17 and clone.s.commerce_r21.legacy_persona_progress_r22==before.persona_progress_r21 and w.s==before,"stale persona view archived and synchronized without input writes")
	clone.s.gold=100000;check(clone.recruit() and clone.s.members[clone.s.town_r21.meet].level==17,"recruit reuses actual persona level")
	FileAccess.open("res://../verification/facilities-r22/save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify(specimens,"  "))
	FileAccess.open("res://../verification/facilities-r22/results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"lua_samples":samples,"groups":groups},"  "))
	print("FACILITIES R22 CHECKS ",checks," FAILURES ",failures.size()," LUA ",samples);quit(1 if failures else 0)
