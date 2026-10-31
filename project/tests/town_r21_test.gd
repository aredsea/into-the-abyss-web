extends SceneTree
const World=preload("res://game/town_world_r21.gd")
const Rules=preload("res://game/town_rules_r21.gd")
const Legacy=preload("res://game/world_state.gd")
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
	check(w.dungeon_catalog().size()==1 and w.dungeon_catalog()[0].id=="academy-review","branch A integration boundary")
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
