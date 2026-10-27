extends SceneTree
const State=preload("res://game/battle_state.gd")
var failures=0
var checks=0
func expect(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _init() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/battle_scene.json"))
	var m=State.new(data)
	expect(m.data.queue==data.queue,"Initial example CTB forecast")
	expect(m.act("attack"),"Hildegard can attack")
	expect(m.enemy("executor").hp==16,"Independent formula oracle: 30 attack damage + 16 overheat self damage")
	expect(m.enemy("executor").broken and m.enemy("executor").gauge==0,"Ice break: 12*1.5=18")
	expect(m.current_id=="executor","Enemy turn follows")
	expect(m.automatic_turn(),"Broken enemy turn is processed")
	expect(m.enemy("executor").hp==16 and not m.enemy("executor").broken and m.enemy("executor").gauge==80,"Break skips steam, restores abyss after skipped turn")
	expect(m.current_id=="teiris" and m.ally("teiris").mp==55,"CTB chooses Teiris, own-turn MP+5")
	var before=m.snapshot()
	var restored=State.new(data)
	expect(restored.restore(JSON.parse_string(JSON.stringify(before,"",true,true))),"JSON save round trip")
	expect(restored.snapshot()==before,"Full state incl seed and CTB restored")
	for item in [null,[],{}, {"schema_version":1}]: expect(not restored.restore(item),"Reject invalid saves")
	var corrupt=before.duplicate(true);corrupt.units.teiris.mp=99999
	expect(not restored.restore(corrupt) and restored.snapshot()==before,"Bounds checked atomically")
	corrupt=before.duplicate(true);corrupt.units.orb.effects={"alarm":{"turns":-1,"amount":0.1}}
	expect(not restored.restore(corrupt),"Invalid duration rejected")
	corrupt=before.duplicate(true);corrupt.units.orb.broken=true
	expect(not restored.restore(corrupt),"Break and gauge invariant")
	m.choose_enemy("orb"); restored.choose_enemy("orb")
	expect(m.act("attack") and restored.act("attack"),"Resumed action legal")
	expect(m.snapshot()==restored.snapshot(),"Save does not reroll or change outcomes")
	m=State.new(data)
	var original=m.snapshot()
	expect(not m.act("unknown") and m.snapshot()==original,"Invalid action has no side effects")
	m.ally("hildegard").mp=0; original=m.snapshot()
	expect(not m.act("guard") and m.snapshot()==original,"Insufficient MP does not advance CTB or RNG")
	m=State.new(data); m.act("guard")
	expect(m.ally("hildegard").mp==15 and m.ally("hildegard").effects.guard.turns==2,"Guard MP and duration")
	m.automatic_turn()
	# Independent formula: floor(33.673608*.9*42.432/59.432*.85*.6)=11.
	expect(m.ally("hildegard").hp==47,"Guard and trait reduce steam damage to 11")
	expect(m.ally("bargut").hp<68 and m.ally("teiris").hp<61 and m.ally("berenga").hp<63,"Steam attacks all four")
	m=State.new(data); m.act("taunt")
	expect(m.ally("hildegard").mp==13 and m.enemy("executor").hp==46,"Taunt MP, no attack damage, overheat self damage only")
	expect(m.enemy("orb").gauge==24 and m.enemy("apprentice").gauge==21,"Intimidation applies to selected enemy only; no fabricated all-target effect")
	m=State.new(data);m.act("duty")
	expect(m.enemy("executor").gauge==18 and m.enemy("orb").gauge==1.5,"Personal duty intimidates lowest absolute HP foe with ice multiplier, not all enemies")
	expect(m.ally("hildegard").effects.duty.amount==0.25,"Duty reduction lasts two own turns")
	m=State.new(data); m.current_id="teiris"
	for u in m.data.allies+m.data.enemies: u.remaining=10000.0
	m.enemy("executor").hp=163
	m.act("burst")
	expect(m.ally("teiris").mp==14 and m.ally("teiris").charging,"Two-action spell spends MP once and charges")
	m.current_id="teiris"
	for u in m.data.allies+m.data.enemies: u.remaining=10000.0
	m.automatic_turn()
	expect(not m.ally("teiris").charging and m.ally("teiris").mp==19,"Charge release free, second action gets immediate extra turn +MP5")
	expect(m.current_id=="teiris" and m.enemy("orb").hp==0,"Burst damages all, relativity advances next turn")
	m=State.new(data); m.current_id="berenga"; m.act("hshield")
	expect(m.ally("berenga").mp==42 and m.ally("hildegard").shield==18,"Explicit canonical shield note takes precedence over generic formula")
	m=State.new(data); m.current_id="berenga"; m.act("bless")
	expect(m.ally("berenga").mp==44 and m.ally("hildegard").effects.bless.amount==0.15,"Party buff cost and canonical strength")
	m=State.new(data); m.ally("hildegard").hp=1
	m._enemy_hit(m.enemy("executor"),m.ally("hildegard"),m.enemy("executor").acts[0])
	expect(m.ally("hildegard").hp==59 and m.ally("hildegard").ward_used,"Priest ward prevents one lethal hit with 50% max HP")
	m._enemy_hit(m.enemy("executor"),m.ally("hildegard"),{"name":"test","m":100.0})
	expect(m.ally("hildegard").hp==0,"Ward cannot prevent a second lethal hit")
	m=State.new(data); m.current_id="orb"; m.enemy("orb").act_index=1; m.automatic_turn()
	expect(is_equal_approx(m.speed(m.enemy("executor")),115.5),"Orb alarm applies +10% speed to living enemies")
	m=State.new(data); m.current_id="lantern"; m.automatic_turn()
	expect(m.enemy("executor").hp==94,"Lamp heals lowest HP ratio for floor(163*20%)=32")
	m=State.new(data); m.current_id="apprentice";m.enemy("apprentice").act_index=1;m.automatic_turn()
	expect(is_equal_approx(m.speed(m.enemy("apprentice")),126),"Apprentice winds up +20% speed")
	m=State.new(data);m.act("taunt")
	expect(m.intent(m.enemy("orb")).ends_with("힐데가르트"),"Taunt intent and actual target agree")
	var seed_before=m.rng_state
	m.intent(m.enemy("orb"));m.intent(m.enemy("orb"))
	expect(m.rng_state==seed_before,"Reading an intent never rerolls targeting")
	m=State.new(data)
	for i in range(150):
		if not m.result.is_empty(): break
		if m.player_turn() and not m.ally(m.current_id).charging:
			m.choose_enemy(m.living(false)[0].id); expect(m.act("attack"),"Playable normal attack")
		else: expect(m.automatic_turn(),"Automatic progression")
	expect(m.result=="victory","Full playable encounter reaches victory")
	print("Victory in ",m.turn_count," actions")
	m=State.new(data)
	for a in m.data.allies: a.hp=1; a.ward_used=true
	m.current_id="executor";m.automatic_turn()
	expect(m.result=="defeat" and m.living(true).is_empty(),"Lethal whole-party attack reaches defeat, not permanent death")
	var defeated=State.new(data)
	expect(defeated.restore(JSON.parse_string(JSON.stringify(m.snapshot()))),"Defeat save can restore")
	var scene=load("res://scenes/battle.tscn").instantiate(); root.add_child(scene)
	await process_frame; await process_frame
	expect(scene.actor.sheet is Texture2D and scene.actor.character_id==scene.state.last_ally and scene.controls.has("action:attack"),"Scene and current character sprite load")
	print("COMBAT CHECKS: ",checks,"; FAILURES: ",failures)
	quit(1 if failures else 0)
