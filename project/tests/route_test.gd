extends SceneTree
const World=preload("res://game/world_state.gd")
const Battle=preload("res://game/battle_state.gd")
var checks=0
var failures=0
func expect(ok: bool, msg: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(msg)
func _init() -> void:
	call_deferred("run_tests")
func roundtrip(w) -> bool:
	var copy=World.new()
	var encoded=JSON.stringify(w.s,"",true,true)
	var decoded=JSON.parse_string(encoded)
	var ok=copy.restore(decoded)
	if not ok: print("RESTORE REJECTED ",decoded.run, " route validation ",World.Route.valid(decoded.run))
	elif copy.s!=decoded: print("RESTORE CHANGED STATE")
	return ok and copy.s==decoded
func win(w) -> void:
	var b=Battle.new(w.battle_data()); var turns=0
	while b.result.is_empty() and turns<400:
		if b.player_turn() and not b.ally(b.current_id).charging:
			b.choose_enemy(b.living(false)[0].id); b.act("attack")
		else: b.automatic_turn()
		turns+=1
	expect(b.result=="victory","Real CTB encounter victory")
	w.record_battle(b.snapshot())
	expect(roundtrip(w),"Saved route battle roundtrip")
	expect(w.finish_battle(),"Route battle claims result")
	expect(not w.finish_battle(),"No duplicate battle rewards")
func run_tests() -> void:
	var w=World.new(); w.depart()
	expect(w.destinations()==["archive","patrol"],"Entry has two meaningful paths")
	expect(not w.advance() and not w.travel("gate") and not w.travel("unknown"),"No legacy advance or disconnected travel")
	expect(w.travel("archive") and w.s.hand==["key"],"Archive gives owned card")
	expect(not w.travel("archive") and not w.travel("entry"),"No farming or backtracking")
	expect(w.travel("cache") and w.destinations().is_empty(),"Resolve encounter before departure")
	expect(roundtrip(w),"Unresolved cache survives reload")
	var count=w.s.items.hp_s
	expect(w.use_card("key") and w.s.items.hp_s==count+1 and w.s.hand.is_empty(),"Key grants exactly one item and consumes one card")
	expect(not w.use_card("key") and not w.leave_cache(),"No double cache payout")
	expect(w.travel("rest") and not w.travel("gate"),"Rest requires explicit rest or skip")
	expect(w.skip_rest() and not w.skip_rest(),"Skip rest without a card")
	expect(w.travel("gate") and w.s.run.final,"Goal starts final combat")
	win(w)
	expect(w.s.summary.wins==1 and w.s.summary.gold==40,"Safe branch skips optional combat")
	expect(roundtrip(w),"Completed map restores")
	var other=World.new(); other.depart(); other.travel("patrol")
	var b=Battle.new(other.battle_data()); other.record_battle(b.snapshot())
	var old=other.s.duplicate(true); old.run.battle.build="world-public-20261027-r1-run-1-explore"
	expect(other.restore(old),"Previous-build in-flight battle remains playable")
	win(other)
	expect(other.s.hand==["camp"] and other.destinations()==["cache","supplies"],"Battle event appends a camp card")
	expect(other.travel("cache") and not other.use_card("key") and other.leave_cache(),"No-key route remains traversable")
	expect(other.travel("rest") and other.rest() and not other.rest(),"Rest only once")
	expect(roundtrip(other),"Restored map keeps used rest")
	other.travel("gate"); win(other)
	expect(other.s.summary.gold==80 and other.s.summary.xp==28,"Two encounter route rewards exact sample values")
	var reward=World.new(); reward.depart(); reward.travel("archive"); reward.travel("coins")
	expect(reward.s.run.gold==20 and not reward.travel("coins"),"Coins awarded once")
	var before=reward.s.duplicate(true)
	for field in ["path","node","event","route_version","route_seed","final","rested"]:
		var bad=before.duplicate(true)
		match field:
			"path": bad.run.path=["entry","gate"]
			"node": bad.run.node="patrol"
			"event": bad.run.event="battle"
			"route_version": bad.run.route_version=99
			"route_seed": bad.run.route_seed=2
			"final": bad.run.final=true
			"rested": bad.run.rested=true
		expect(not reward.restore(bad) and reward.s==before,"Malformed route rejected atomically: "+field)
	expect(reward.settle("retreat") and reward.s.gold==220,"Route retreat banks acquired rewards")
	expect(not reward.travel("rest") and not reward.settle("retreat"),"Finished run cannot move or settle twice")
	print("ROUTE TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
