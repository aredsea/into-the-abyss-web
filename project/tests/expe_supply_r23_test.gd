extends SceneTree
const World=preload("res://game/expedition_world_r22.gd")
const Supply=preload("res://game/expedition_supply_r22.gd")
const Base=preload("res://tests/expedition_r22_test.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		failures.append(msg)
		if failures.size()<=12:push_error(msg)
func _initialize():call_deferred("run")
func run():
	var helper=Base.new();var w=helper.ready_world();w.s.party=[];w.depart_dungeon(1,1);w.s.run.phase="battle"
	var b=Supply.new(w.battle_data())
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-oracle.json"))
	var api=true
	for method in ["supply_need","has_supply_dot","supply_target_ok","any_supply_target","supply_level_blocked"]:
		check(b.has_method(method),"source predicate API "+method)
		api=api and b.has_method(method)
	if api:
		for row in oracle.needs:check(b.supply_need(w.item_def(w.web_item_id(row.id)))==row.value,"source minimum level "+row.id)
	for row in oracle.combat_targets:
		var id=w.web_item_id(row.id);var it=w.item_def(id)
		var t={"id":"persona","level":row.level,"hp":row.hp,"mp":row.mp,"mhp":row.mhp,"mmp":row.mmp,"shield":row.shield,"effects":{}}
		if row.state=="dot":t.effects.dot={"amount":0,"turns":2}
		if row.state=="edot":t.effects.enemy_dot_0={"amount":0,"turns":2}
		if row.state in ["fox","zerofox"]:t.effects.foxflame={"amount":2 if row.state=="fox" else 0,"turns":2}
		b.data.allies=[] if row.state=="empty" else [t];b.inventory[id]=int(row.stock)
		var target={} if row.state=="empty" else t
		var label=str([row.id,row.level,row.stock,row.state])
		check(b.supply_state_ok(it,target)==(row.value.ok and row.stock>0),"stock and eligibility "+label)
		if api:
			check(b.has_supply_dot(t)==row.dot,"source DOT families "+label)
			check(b.supply_target_ok(it,target)==row.value.ok,"source target level/state "+label)
			check(b.any_supply_target(it)==row.value.any,"source any eligible target "+label)
			check(b.supply_level_blocked(it)==row.value.blocked,"source level-only block "+label)
	if api:
		for row in oracle.combat_parties:
			b.data.allies=[]
			for i in row.units.size():
				var t=row.units[i].duplicate(true);t.id="slot"+str(i);t.effects={}
				if t.fox>0:t.effects.foxflame={"amount":t.fox,"turns":2}
				b.data.allies.append(t)
			var it=w.item_def(w.web_item_id(row.id))
			check(b.any_supply_target(it)==row.value.any and b.supply_level_blocked(it)==row.value.blocked,"mixed 0-4 target eligibility "+str([row.n,row.id,row.layout]))
	# Predicate inspection has no turn, inventory, effect or RNG side effects.
	if api:
		b=Supply.new(w.battle_data());var before=JSON.stringify(b.snapshot())
		for it in w.config.items:
			b.any_supply_target(it);b.supply_level_blocked(it)
		check(JSON.stringify(b.snapshot())==before,"eligibility inspection is pure")
		b=Supply.new(w.battle_data());b.inventory.antidote=1;var a=b.data.allies[0];a.effects.foxflame={"amount":0,"turns":2}
		before=JSON.stringify(b.snapshot())
		check(not b._use_supply(w.item_def("antidote"),a) and JSON.stringify(b.snapshot())==before,"zero foxflame does not spend antidote or a turn")
	FileAccess.open("res://../verification/parity-r23/expe-supply-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"oracle_rows":oracle.combat_targets.size()},"  "))
	print("EXPE SUPPLY R23 CHECKS ",checks," FAILURES ",failures.size());helper.free();quit(0 if failures.is_empty() else 1)
