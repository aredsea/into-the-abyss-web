extends SceneTree
const World=preload("res://game/town_world_r21.gd")
const Rules=preload("res://game/town_rules_r21.gd")
const Legacy=preload("res://game/world_state.gd")
const Guild=preload("res://game/guild_rules_r21.gd")
var checks=0
var failures=[]
var samples=[]
var folder=ProjectSettings.globalize_path("res://../verification/town-r21")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func _init() -> void:
	var oracle=JSON.parse_string(FileAccess.get_file_as_string(folder+"/oracle.json"))
	if not oracle is Dictionary: push_error("Run tools/town_r21_oracle.mjs first"); quit(1); return
	for row in oracle.need: compare("level",row,Rules.need(row.lv),row.value)
	for row in oracle.aff: compare("affection",row,Rules.aff_next(row.a,row.n),row.value)
	for row in oracle.price: compare("price",row,Rules.shop_price(row.amount,row.count),row.value)
	for row in oracle.costs:
		compare("recruit_cost",row,Rules.recruit_cost(row.n),row.recruit)
		compare("refresh_cost",row,Rules.refresh_cost(row.n),row.refresh)
	for row in oracle.inn:
		var w=World.new(); w.s.gold=200; w.s.members.hildegard.aff=row.initial; w.s.refreshes=3
		for h in row.history:
			w.inn("hildegard",h.action)
			for pair in [["gold",w.s.gold,h.gold],["day",w.s.day,h.day],["aff",w.s.members.hildegard.aff,h.aff],["refreshes",w.s.refreshes,h.refreshes]]:
				compare("inn:"+pair[0],h,pair[1],pair[2])
	for row in oracle.scroll:
		var w=World.new(); var m=w.s.members.hildegard; m.level=row.before; m.xp=12; w.s.items.level_scroll=2
		w.use_item("level_scroll","hildegard")
		compare("level_scroll:level",row,m.level,row.level); compare("level_scroll:xp",row,m.xp,row.xp); compare("level_scroll:count",row,w.s.items.level_scroll,row.count)
	var original=Legacy.new(); var copy=World.new(); var pristine=original.s.duplicate(true)
	for row in oracle.source_rng: compare("source_rng",row,Guild.random(row.seed,row.n),row.value)
	var boards={}
	var loot_rules=World.new().dungeon_rules
	for row in oracle.ledger:compare("quest:ledger",row,Guild.reward_gold(row.base,row.count),row.value)
	for row in oracle.guild_loot:
		compare("quest:gear_count",row,Guild.gear_count(row.seed,row.qn),row.count)
		for i in range(2):
			var actual=Guild.elite_gear(loot_rules,row.seed,row.qn,row.classes,i+1)
			var ok=not actual.is_empty() and actual.code==row.codes[i]
			samples.append({"rule":"quest:gear_code","input":row,"godot":actual.get("code",""),"lua":row.codes[i],"match":ok})
			check(ok,"elite gear "+str(row.seed)+"/"+str(row.qn)+"/"+str(i))
	for row in oracle.guild:
		var key=str(row.seed)+":"+str(row.level)
		if not boards.has(key): boards[key]=[]
		var q=Guild.quest(row.seed,row.n,row.n,row.level,boards[key]); boards[key].append(q)
		var expected=row.quest
		for field in ["title","rift","kind","stars","difficulty","gold","reward_v","d","lv"]:
			var ok=q[field]==expected[field]
			samples.append({"rule":"guild:"+field,"input":row,"godot":q[field],"lua":expected[field],"match":ok})
			check(ok,"guild "+key+"/"+str(row.n)+"/"+field)
		check(q.source_id==expected.id,"guild source identifier")
		if expected.has("strength"): compare("guild:strength",row,q.strength,expected.strength)
	check(copy.restore(original.s),"schema1 migrates"); check(original.s==pristine,"migration does not mutate caller")
	var w=World.new(); w.s.gold=9000; w.s.members.hildegard.aff=99.5; w.inn("hildegard","talk")
	check(w.s.members.hildegard.aff==100.2,"crossing soft cap splits fraction")
	var saved=w.s.duplicate(true); check(World.new().restore(saved),"schema2 keeps new town results")
	var before=w.s.duplicate(true); w.s.gold=0; var zero=w.s.duplicate(true)
	check(not w.inn("hildegard","meal") and w.s==zero,"insufficient money atomic")
	w.s=before; w.s.items.hp_s=1; w.s.members.hildegard.hp=30
	var p=w.item_preview("hp_s","hildegard"); var hp=w.s.members.hildegard.hp
	check(w.use_item("hp_s","hildegard") and w.s.members.hildegard.hp==p.after and hp==p.before,"preview equals actual potion")
	check(not w.item_preview("hp_s","hildegard").usable,"zero stock preview blocked")
	check(not w.item_preview("bad","hildegard").usable,"unknown item preview blocked")
	w.s.items.bandage=1; w.s.members.hildegard.hp=0; p=w.item_preview("bandage","hildegard")
	check(w.use_item("bandage","hildegard") and w.s.members.hildegard.hp==p.after,"revive preview equals actual")
	w.s.items.hp_m=1; check(not w.item_preview("hp_m","hildegard").usable,"potion level gate")
	w.s.items.hp_s=99; w.s.gold=10000; check(w.buy("hp_s") and w.s.items.hp_s==100,"native purchase beyond 99")
	w.s.items.hp_s=10000; before=w.s.duplicate(true); check(not w.buy("hp_s") and w.s==before,"validated save capacity atomic")
	var catalog=w.dungeon_catalog()
	check(catalog.size()==9 and catalog[0].id=="academy_upper" and catalog[-1].last_floor==27,"all nine source destinations")
	check(catalog[0].unlocked and not catalog[1].unlocked,"destination locks honor progression")
	var qworld=World.new(); var qsave=qworld.s.duplicate(true)
	check(qworld.accept_quest(qworld.s.board[0].id),"accept source quest")
	var sourceq=qworld.s.quest.duplicate(true)
	check(qworld.depart_accepted_quest(),"accepted quest uses A rift departure")
	check(qworld.s.run.source_quest==sourceq and not qworld.s.run.rift_id.is_empty(),"rift source quest retained")
	var qcopy=World.new();check(qcopy.restore(qworld.s) and qcopy.s==qworld.s,"rift run and guild RNG save roundtrip")
	var old=qsave.duplicate(true);old.erase("town_r21")
	var oldcopy=old.duplicate(true);var migrated=World.new()
	check(migrated.restore(old) and old==oldcopy,"additive guild RNG migration leaves input unchanged")
	var invalid_rng=qsave.duplicate(true);invalid_rng.town_r21.counter=-1
	check(not migrated.restore(invalid_rng),"malformed RNG rejected atomically")
	var settle_world=World.new();var elite=settle_world.s.board.filter(func(q):return q.difficulty=="엘리트")[0]
	check(settle_world.accept_quest(elite.id) and settle_world.depart_accepted_quest(),"elite quest departure")
	var base=settle_world.dungeon_rules.quest_gold(elite,elite.lv);settle_world.s.run.gold=base
	var before_gold=settle_world.s.gold;var before_gear=settle_world.s.gear.size()
	check(settle_world.settle("clear"),"quest settlement")
	check(settle_world.s.gold-before_gold==Guild.reward_gold(base,settle_world.party_count("nation","마렌토 공화국")),"quest ledger paid once")
	check(settle_world.s.gear.size()-before_gear==Guild.gear_count(settle_world.s.town_r21.seed,elite.id),"elite guaranteed source gear")
	var finished=settle_world.s.duplicate(true)
	check(not settle_world.settle("clear") and settle_world.s==finished,"quest duplicate settlement atomic")
	check(settle_world.s.quest.is_empty() and settle_world.s.board.size()==4 and settle_world.s.refreshes==0,"completed quest removed and board refilled")
	var fail_world=World.new();fail_world.accept_quest(fail_world.s.board[0].id);fail_world.depart_accepted_quest()
	check(fail_world.settle("defeat") and fail_world.s.quest.is_empty() and fail_world.s.board.size()==4,"failed quest also removed")
	var drop_world=World.new();var old_id=drop_world.s.board[0].id;drop_world.accept_quest(old_id)
	check(drop_world.abandon_quest() and not drop_world.s.board.any(func(q):return q.id==old_id),"abandoned quest cannot be accepted again")
	w.add_gear(w.gear.stock("warrior",1)[0]); var uid=w.s.gear[-1].uid
	before=w.s.duplicate(true); var c=w.gear_comparison("hildegard",uid)
	check(w.s==before and not c.is_empty(),"gear comparison has no side effects")
	check(w.equip("hildegard",uid),"comparison candidate equippable")
	c=w.gear_comparison("hildegard",uid)
	check(c.delta.values().all(func(v):return is_zero_approx(v)),"same gear comparison zero")
	before=w.s.duplicate(true); var invalid=before.duplicate(true); invalid.gold=-1
	check(not w.restore(invalid) and w.s==before,"invalid restore atomic")
	w.depart(); w.travel("patrol"); var b=World.ModernBattle.new(w.battle_data()); w.record_battle(b.snapshot())
	var restored=World.new(); check(restored.restore(w.s),"live v3 battle retained")
	check(restored.s.run.battle==w.s.run.battle,"live battle snapshot byte-equivalent dictionary")
	var untouched=w.s.duplicate(true); check(not w.buy("hp_s") and not w.inn("hildegard","rest") and w.s==untouched,"town actions blocked in battle")
	var file=FileAccess.open(folder+"/rules-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"oracle_samples":samples},"  "));file.close()
	print("TOWN R21 CHECKS ",checks," FAILURES ",failures.size()," LUA SAMPLES ",samples.size());quit(1 if failures else 0)
func compare(kind: String,input: Dictionary,actual: float,expected: float) -> void:
	var ok=absf(actual-expected)<.00001
	samples.append({"rule":kind,"input":input,"godot":actual,"lua":expected,"match":ok})
	check(ok,kind+" "+JSON.stringify(input))
