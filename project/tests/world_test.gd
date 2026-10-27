extends SceneTree
const World=preload("res://game/world_state.gd")
const Battle=preload("res://game/battle_state.gd")
const Store=preload("res://game/world_store.gd")
var checks=0
var failures=0
func expect(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _init() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	var w=World.new()
	expect(w.stats("hildegard",1).hp==118 and w.stats("hildegard",2).hp==129,"Canonical class growth oracle")
	expect(w.need(1)==28 and w.need(2)==64,"Bot XP curve independent oracle")
	expect(w.buy("hp_s") and w.s.gold==160 and w.s.items.hp_s==3,"Shop purchase debits exact canonical price")
	expect(not w.buy("fake"),"Reject unknown item")
	w.s.gold=0
	expect(not w.buy("mp_s") and w.s.items.mp_s==1,"Insufficient funds leaves inventory intact")
	w.s.gold=200
	expect(not w.use_item("hp_s","hildegard") and w.s.items.hp_s==3,"Full health does not consume potion")
	w.s.members.hildegard.hp=60
	expect(w.use_item("hp_s","hildegard") and w.s.members.hildegard.hp==84,"20% rounded HP healing")
	w.s.members.hildegard.hp=0
	expect(not w.use_item("hp_s","hildegard"),"Potion cannot revive")
	expect(w.use_item("bandage","hildegard") and w.s.members.hildegard.hp==29,"Bandage floor 25% revival")
	expect(w.inn("hildegard","talk") and not w.inn("hildegard","talk") and w.s.members.hildegard.aff==1,"Inn once per character/action/day")
	expect(w.inn("hildegard","rest") and w.s.day==2 and w.s.gold==180,"Inn rest day/cost")
	expect(w.inn("hildegard","talk"),"New day reopens interaction")
	expect(w.swap(0,1) and not w.swap(0,2),"Same-row formation only")
	expect(w.depart() and not w.depart() and w.s.members.hildegard.hp==118,"Departure full restore / duplicate prevented")
	expect(not w.buy("hp_s") and not w.inn("hildegard","talk") and not w.swap(0,1),"Town actions guarded during expedition")
	expect(w.advance() and w.s.hand==["key"],"Exploration event adds to owned hand")
	expect(not w.use_card("key") and w.s.hand==["key"],"Wrong context does not consume card")
	expect(w.advance() and w.s.run.phase=="battle","Exploration enters battle")
	var b=Battle.new(w.battle_data())
	var restored=World.new()
	w.record_battle(b.snapshot())
	expect(restored.restore(JSON.parse_string(JSON.stringify(w.s,"",true,true))),"Whole campaign + battle snapshot roundtrip")
	expect(not w.finish_battle(),"Cannot claim unfinished combat reward")
	var turns=0
	while b.result.is_empty() and turns<400:
		if b.player_turn() and not b.ally(b.current_id).charging:
			var target=b.living(false)[0]
			b.choose_enemy(target.id); b.act("attack")
		else: b.automatic_turn()
		turns+=1
	expect(b.result=="victory","Sample expedition fight winnable through real engine")
	w.record_battle(b.snapshot())
	expect(w.finish_battle() and not w.finish_battle(),"Battle reward claimed once")
	expect(w.s.hand==["key","camp"] and w.s.run.gold==40,"Battle event appends card without replacing hand")
	var current_hp=w.s.members.hildegard.hp
	expect(current_hp==b.ally("hildegard").hp,"Combat HP carries into exploration")
	expect(w.advance() and w.s.run.event=="sealed" and not w.advance(),"Unresolved encounter cannot be skipped by advance")
	var items=w.s.items.hp_s
	expect(w.use_card("key") and w.s.hand==["camp"] and w.s.items.hp_s==items+1,"Card consumed once with event effect")
	expect(not w.use_card("key"),"Duplicate card claim blocked")
	w.advance(); w.advance(); w.advance()
	expect(w.s.run.phase=="rest" and w.rest() and not w.rest(),"One-time camp rest after five explorations")
	expect(w.final_battle(),"Rest connects final sample combat")
	var b2=Battle.new(w.battle_data())
	turns=0
	while b2.result.is_empty() and turns<400:
		if b2.player_turn() and not b2.ally(b2.current_id).charging:
			b2.choose_enemy(b2.living(false)[0].id); b2.act("attack")
		else: b2.automatic_turn()
		turns+=1
	expect(b2.result=="victory","Second combat with carried resources is winnable")
	w.record_battle(b2.snapshot()); w.finish_battle()
	expect(w.s.summary.gold==100 and w.s.summary.xp==28 and w.s.members.hildegard.level==2,"Settlement pays exact sample rewards and canonical level gain")
	var gold=w.s.gold
	expect(not w.settle("clear") and w.s.gold==gold,"Settlement idempotence")
	expect(restored.restore(JSON.parse_string(JSON.stringify(w.s))),"Settled growth state restores")
	for edit in ["gold","party","member","summary","hand","battle"]:
		var corrupt=w.s.duplicate(true)
		match edit:
			"gold": corrupt.gold=-1
			"party": corrupt.party=["hildegard","hildegard","teiris","berenga"]
			"member": corrupt.members.hildegard.hp=999999
			"summary": corrupt.summary={"result":"clear"}
			"hand": corrupt.hand=["unknown"]
			"battle": corrupt.run.phase="battle"; corrupt.run.battle={"x":1}
		var before=restored.s.duplicate(true)
		expect(not restored.restore(corrupt) and restored.s==before,"Malformed save rejected atomically: "+edit)
	var retreat=World.new(); retreat.depart(); retreat.advance(); retreat.s.run.gold=20
	expect(retreat.settle("retreat") and retreat.s.gold==220 and retreat.s.hand==["key"],"Retreat and provisional retained hand")
	var loss=World.new(); loss.depart(); loss.s.run.gold=40
	expect(loss.settle("defeat") and loss.s.gold==200 and loss.s.summary.lost==40,"Defeat loses unbanked gold, not existing purse")
	var store=Store.new("user://world_test_fixture.json")
	expect(store.write(w.s)==OK and store.write(w.s)==OK,"Atomic store writes and backs up")
	var from_disk=World.new()
	expect(store.read_into(from_disk) and from_disk.s.gold==w.s.gold,"Read actual stored file")
	var broken=FileAccess.open("user://world_test_fixture.json",FileAccess.WRITE)
	broken.store_string("{"); broken.close()
	expect(store.read_into(from_disk) and from_disk.s.members.hildegard.level==2,"Corrupt primary falls back to last valid backup")
	print("WORLD TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
