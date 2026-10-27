extends SceneTree
const World=preload("res://game/expansion_world.gd")
const Battle=preload("res://game/battle_v3.gd")
var checks=0
var failures=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)

func _init() -> void:
	var w=World.new()
	check(w.s.members.size()==30,"all characters")
	check(w.s.owned.size()==4,"starting ownership")
	w.s.gold=1000000
	for i in range(26): check(w.recruit(),"recruit")
	check(w.s.owned.size()==30 and not w.recruit(),"no duplicates")
	var copied=World.new(); check(copied.restore(w.s),"town round trip")
	for p in w.config.companions:
		w.s.party=World.IDS.duplicate()
		check(w.assign(p.id,0 if p.row=="전열" else 2),"assign "+p.id)
		w.depart(); w.travel("patrol")
		var data=w.battle_data(); var initial=Battle.new(data)
		check(initial.data.allies.size()==4,"party data")
		for id in initial.ally(p.id).skills:
			var b=Battle.new(data); b.current_id=p.id; b.last_ally=p.id; b.selected_ally=p.id
			b.ally(p.id).mp=b.ally(p.id).mmp
			for e in b.data.enemies: e.hp=e.mhp
			b.ally(p.id).hp=int(b.ally(p.id).mhp*.7)
			if b.unavailable(id)=="MP 부족": continue
			check(b.act(id),"cast "+p.id+" "+id)
			var restored=Battle.new(data); check(restored.restore(b.snapshot()),"battle restore "+p.id+" "+id)
			check(restored.snapshot()==b.snapshot(),"exact restore "+p.id+" "+id)
			for n in range(15):
				if not b.result.is_empty(): break
				if b.player_turn() and not b.ally(b.current_id).charging: b.act("attack")
				else: b.automatic_turn()
		w.s.run={}
	var stock=w.gear.stock("warrior",1)
	check(stock.size()==12,"shop stock")
	check(w.buy_gear(stock[0],"hildegard"),"buy gear")
	var uid=w.s.gear[-1].uid
	check(w.equip("hildegard",uid),"equip")
	check(not w.sell_gear(uid),"equipped sale refused")
	check(w.forge(uid) and w.gear_entry(uid).forge==1,"guaranteed first forge")
	check(w.unequip("hildegard","weapon"),"unequip")
	check(w.sell_gear(uid),"sell")
	check(w.process_gear("hildegard"),"process")
	check(copied.restore(w.s),"gear round trip")
	var old=load("res://game/world_state.gd").new()
	check(World.new().restore(old.s),"legacy world migration")
	old.depart(); old.travel("patrol"); var legacy=load("res://game/battle_state.gd").new(old.battle_data()); old.record_battle(legacy.snapshot())
	var migrated=World.new(); check(migrated.restore(old.s),"legacy live battle migration")
	check(migrated.s.run.battle==old.s.run.battle,"legacy snapshot unchanged")
	for item in w.gear.catalog.items:
		var values=w.gear.roll({"id":item.id,"seed":123,"forge":10},40)
		for key in values: check(is_finite(values[key]) and values[key]>=0,"gear numeric "+item.id)
	var oracle=World.new(); oracle.depart(); oracle.travel("patrol"); var data=oracle.battle_data()
	var b=Battle.new(data); b.current_id="berenga"; b.last_ally="berenga"; b.ally("hildegard").hp=20; b.choose_ally("hildegard")
	check(b.act("personal"),"triage action")
	check(b.ally("hildegard").hp==20+int(18*2*(1+.6*(1-20.0/118))),"triage exact runtime coefficient")
	b=Battle.new(data); b.current_id="hildegard"; b.last_ally="hildegard"; var prior=b.ally("hildegard").mp
	check(b.act("personal") and b.ally("hildegard").effects.has("taunt") and b.ally("hildegard").mp==prior-10,"duty MP and taunt")
	b=Battle.new(data); b.ally("hildegard").hp=30; b.choose_ally("hildegard"); check(b.act("item:hp_s"),"combat potion")
	check(b.ally("hildegard").hp==54 and b.inventory.hp_s==1 and b.turn_count==1,"potion exact HP inventory turn")
	var bad=b.snapshot(); bad.inventory.hp_s=-1; check(not Battle.new(data).restore(bad),"reject negative battle inventory")
	# Source signature as_vital adds 48 percentage points to the critical multiplier.
	var plain=Battle.new(data); var enhanced=Battle.new(data)
	for sample in [plain,enhanced]:
		sample.ally("hildegard").base.str=100
		sample.data.enemies[0].hp=100000
		sample._effect(sample.data.enemies[0],"mark",1)
	enhanced.ally("hildegard").gear_special=[{"key":"as_vital","v":[48]}]
	plain._damage(plain.ally("hildegard"),plain.data.enemies[0],1,0)
	enhanced._damage(enhanced.ally("hildegard"),enhanced.data.enemies[0],1,0)
	check(abs((100000-enhanced.data.enemies[0].hp)-(100000-plain.data.enemies[0].hp)*1.32)<2,"critical signature adds 0.48 to 1.5")
	check(not oracle.compose("hildegard","strike","bane"),"no research during expedition")
	check(not oracle.compose("hildegard","strike","regen"),"incompatible tactic")
	oracle.s.run={}; check(oracle.compose("hildegard","strike","bane"),"town compose")
	check(oracle.train("hildegard","prefix") and oracle.s.gold==160,"research canonical cost")
	oracle.depart(); oracle.travel("patrol"); b=Battle.new(oracle.battle_data()); check(b.act("tactic"),"composed skill actual combat")
	print("EXPANSION CHECKS ",checks," FAILURES ",failures)
	quit(1 if failures else 0)
