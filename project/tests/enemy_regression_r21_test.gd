extends SceneTree
const World=preload("res://game/dungeon_world_r21.gd")
const Battle=preload("res://tests/enemy_action_fixture_r21.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures.append(label)
func fixture(id: String,neutral=false):
	var w=World.new(); w.depart_dungeon(1,12345)
	w.s.run.phase="battle"
	var d=w.battle_data(); var enc=d.encounter_r21.enc
	enc.fl=[id,"apprentice_doll","rusted_shieldman"]; enc.fg=["","",""]; enc.ne=5; enc.raid=false
	d.enemies=w.make_enemies(d.encounter_r21,d.allies)
	if neutral:
		# Stack arithmetic is isolated from take/save hooks, tested separately.
		for i in range(d.allies.size()):
			var a=d.allies[i]; a.id="neutral_%d"%i; a.class_id="sanctioned"; a.race=""; a.nation=""; a.lineage=""
			a.gear_fx={}; a.gear_special=[]; a.passive={}; a.trait={"p":{}}
	var b=Battle.new(d)
	for a in b.data.allies: a.hp=a.mhp; a.effects={}
	b.current_id=b.data.enemies[0].id
	# Direct phase_check has the same begin_ev prerequisite as the Lua oracle.
	b.combat_events.begin_record(b)
	return b
func _init(): call_deferred("run")
func run():
	var b=fixture("echo_of_bottom"); var e=b.data.enemies[0]
	e.hp=int(e.mhp*.4); b.dungeon_enemy_r21.phase_check()
	check(b.x(e).has("cycle_a"),"1 phase entry weak_cycle")
	var prior=e.weak.duplicate(); b.dungeon_enemy_r21.turn()
	check(b.x(e).has("cycle_a") and (e.weak!=prior or b.rng_state!=12345),"1 per-turn weak_cycle")
	b=fixture("echo_of_bottom"); e=b.data.enemies[0]
	e.acts=[{"kind":"special","fx":"silence","name":"silence"}]
	for a in b.data.allies:
		a.skills={"personal":{},"delay":{},"attack":{},"burst":{},"guard":{}}
		a.class_id="sanctioned"
	b.rng_state=12345; b.dungeon_enemy_r21.turn()
	var sil=""
	for a in b.data.allies:
		if a.effects.has("silence"): sil=b.x(a).silenced_id
	# The sanctioned KIT has burst, then personal; delay is a passive addition.
	var rs=int((int(b.data.seed)*31+977+13)%2147483646)+1
	var k=int(floor(float((rs*16807)%2147483647)/2147483647*8))%2
	check(sil==["burst","personal"][k],"2 ordered silence candidates")
	b=fixture("chained_executioner"); e=b.data.enemies[0]; e.act_index=2
	b.dungeon_enemy_r21.turn(); b._break(e,1e9); b.dungeon_enemy_r21.turn()
	check(not e.charged and e.act_index==0,"3 charged break skips big action")
	b=fixture("apprentice_doll"); e=b.data.enemies[0]
	check(b.dungeon_enemy_r21.target(e,{"kind":"buff"})==e,"4 self support forecast")
	e.acts=[{"kind":"atk","name":"attack","m":1}]
	for member in b.data.allies: member.hp=100000; member.mhp=100000
	var ids=[]
	for n in range(12):
		e.act_index=0; b.dungeon_enemy_r21.turn()
		ids.append(e.target_id)
	check(ids.any(func(id):return id!=ids[0]),"4 random next target")
	var low=b.data.allies[2]; low.hp=100; low.mhp=1000; b.data.allies[0].hp=90; b.data.allies[0].mhp=100
	e.acts=[{"kind":"aimed","name":"aimed"}]
	check(b.dungeon_enemy_r21.pick_target(e)==low,"4 aimed uses ratio rather than absolute HP")
	e.target_id=low.id; b.data.allies[1].effects.taunt={"amount":0,"turns":2}
	check(b.dungeon_enemy_r21.target(e,e.acts[0])==b.data.allies[1],"4 taunt overrides forecast")
	b.data.allies[1].hp=0
	check(b.dungeon_enemy_r21.target(e,e.acts[0])==low,"4 dead taunter ignored")
	var forecast=JSON.stringify(b.snapshot())
	for n in range(5): b.intent(e)
	check(JSON.stringify(b.snapshot())==forecast,"4 reading intent consumes no RNG")
	b=fixture("standard_bearer"); e=b.data.enemies[0]; b.dungeon_enemy_r21.turn()
	var recipient=b.data.enemies[1]
	for n in range(6): b._tick(recipient)
	check(recipient.effects.has("attack_up"),"5 aura survives ordinary turns")
	b._break(e,1e9)
	check(not recipient.effects.has("attack_up"),"5 aura removed on source depletion")
	b=fixture("standard_bearer"); e=b.data.enemies[0]; b.dungeon_enemy_r21.turn(); recipient=b.data.enemies[1]
	var aura_copy=fixture("standard_bearer")
	check(aura_copy.restore(JSON.parse_string(JSON.stringify(b.snapshot()))),"5 aura metadata JSON roundtrip")
	for invalid_rng in [0,-1,2147483647,1.5,"bad"]:
		var bad=b.snapshot(); bad.extra_state[e.id].source_rng=invalid_rng
		check(not aura_copy.restore(bad),"invalid source RNG rejected "+str(invalid_rng))
	e.hp=0; b.dungeon_enemy_r21.drop_auras()
	check(not recipient.effects.has("attack_up"),"5 aura removed on source death")
	b=fixture("echo_of_bottom"); e=b.data.enemies[0]
	e.rules={"weak_hit_delay":{"el":"fire","amount":.2}}; e.remaining=0
	var a=b.data.allies[0]; a.element="fire"; b.dungeon_enemy_r21.after_hit(a,e)
	check(is_equal_approx(e.remaining,1000),"6 boss delay reduced by B.rdm")
	b=fixture("apprentice_doll",true); e=b.data.enemies[0]
	e.acts=[{"kind":"dot","name":"dot","m":1,"turns":3,"tick":.3}]
	for a2 in b.data.allies:
		a2.effects.taunt={"turns":20,"amount":0}
		break
	for n in range(5): b.dungeon_enemy_r21.turn()
	a=b.data.allies[0]; var hp=a.hp; b._tick(a)
	var per=maxi(1,int(floor(e.attack*.3*40/(40+a.base.def))))
	check(hp-a.hp==4*per,"7 four independent dots sum and evict oldest")
	a.effects={}; a.hp=100000; a.mhp=100000
	for n in range(1,6): b.dungeon_enemy_r21.add_dot(a,e,n,n)
	var dot_copy=fixture("apprentice_doll",true); dot_copy.data.allies[0].mhp=100000
	# The production save limit is 100000 per effect; HP fixture stays in range.
	check(dot_copy.restore(JSON.parse_string(JSON.stringify(b.snapshot()))),"7 stacked dots JSON roundtrip")
	hp=a.hp; b._tick(a)
	check(hp-a.hp==14,"7 fifth dot evicts first, distinct amounts")
	b._tick(a); hp=a.hp; b._tick(a)
	check(hp-a.hp==12,"7 stacks expire independently")
	b.inventory.test_cleanse=1; b.current_id=a.id
	check(b._use_supply({"id":"test_cleanse","name":"cleanse","kind":"cleanse","level":1},a),"7 cleanse accepts enemy stacks")
	check(not a.effects.keys().any(func(key):return str(key).begins_with("enemy_dot_")),"7 cleanse removes all enemy stacks")
	b=fixture("apprentice_doll"); e=b.data.enemies[0]; a=b.data.allies[0]
	a.gear_fx={"evade":100}; a.effects.attack_up={"amount":.2,"turns":3}; e.target_id=a.id
	e.acts=[{"kind":"atk","name":"miss","m":1,"push":.5,"drain":.5,"strip":true,"dot":{"m":.3,"turns":3}}]
	hp=a.hp; var remaining=a.remaining; var ehp=e.hp; b.dungeon_enemy_r21.turn()
	check(a.hp==hp and a.remaining==remaining and e.hp==ehp and a.effects.has("attack_up") and not a.effects.has("enemy_dot_0"),"attack additions require a landed hit")
	var w=World.new(); var q={"id":"q17","rift":"서쪽 균열","kind":"토벌","stars":1,"lv":1,"gold":100,"reward_v":2,"difficulty":"엘리트","cmp":true,"strength":1.5}
	q.rift=w.dungeon_rules.config.rifts[0].quest_name
	check(w.depart_rift_quest(q,12345),"8 elite quest starts")
	var real=load("res://game/battle_v3.gd").new(w.battle_data())
	for foe in real.data.enemies: foe.hp=0
	real.result="victory"; w.record_battle(real.snapshot()); var old=w.s.gear.size()
	var finished=w.finish_battle()
	check(finished and w.s.gear.size()-old in [1,2],"8 elite victory guaranteed gear")
	var gained=w.s.gear.size()
	check(not w.finish_battle() and w.s.gear.size()==gained,"8 settlement cannot grant gear twice")
	var out={"checks":checks,"failures":failures}
	FileAccess.open("res://../verification/data-r21/enemy-regression-latest.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print("ENEMY_REGRESSION_R21 "+JSON.stringify(out)); quit(0 if failures.is_empty() else 1)
