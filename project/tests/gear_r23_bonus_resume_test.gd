extends "res://tests/facilities_r22_test.gd"
func run():
	var w=ready_world();check(w.depart_dungeon(1,1),"actual native expedition starts")
	w.s.run.phase="battle"
	w.s.items.charm_potion=99
	var data=w.battle_data()
	check(not data.inventory.has("charm_potion"),"noncombat bonus stays in account inventory")
	var battle=w.ModernBattle.new(data)
	w.record_battle(battle.snapshot())
	check(w.s.items.get("charm_potion")==99,"recording combat preserves account bonus")
	check(not w.s.run.battle.inventory.has("charm_potion"),"combat snapshot needs no new server field")
	var reloaded=World.new();check(reloaded.restore(JSON.parse_string(JSON.stringify(w.s))),"actual combat JSON resume with bonus")
	check(reloaded.s.items.get("charm_potion")==99,"bonus count survives combat resume")
	var resumed=reloaded.ModernBattle.new(reloaded.battle_data());check(resumed.restore(reloaded.s.run.battle),"combat snapshot resumes")
	reloaded.record_battle(resumed.snapshot())
	check(reloaded.s.items.get("charm_potion")==99,"next combat record preserves bonus")
	FileAccess.open("res://../verification/parity-r23/bonus-save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify({"combat":w.s,"resumed":reloaded.s},"  "))
	FileAccess.open("res://../verification/parity-r23/bonus-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("GEAR R23 BONUS RESUME CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
