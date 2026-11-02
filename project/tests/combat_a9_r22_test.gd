extends "res://tests/combat_a6_r22_test.gd"

func clean_fixture():
	var b=fixture(); b.freeze_finish=true; b.data.seed=12345
	for a in b.data.allies:
		a.race=""; a.nation=""; a.lineage=""; a.class_id="warrior"; a.base.def=0; a.gear_fx={}; a.gear_special=[]
	for e in b.data.enemies: e.level=1; e.attack=100; e.rules={}; e.phase=0
	return b

func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/a9-oracle.json"))
	for row in oracle.drain:
		var b=clean_fixture(); var a=b.data.allies[0]; var e=b.data.enemies[0]
		for i in range(3): b.data.allies[i].race="악마"
		e.hp=int(row.start); a.gear_fx={"reflect":10}
		if row.start==500: a.shield=60; a.gear_fx={}
		e.acts=[{"kind":"atk","name":"test","m":1,"drain":.5}]; e.act_index=0; e.target_id=a.id
		b.current_id=e.id; b.dungeon_enemy_r21.turn()
		check(e.hp==row.hp,"drain/reflect HP "+str(row.start),e.hp,row.hp)
		check(a.hp==row.ally and a.mp==row.mp,"drain hit HP / no false kill MP "+str(row.start),[a.hp,a.mp],[row.ally,row.mp])
	for row in oracle.heal:
		var b=clean_fixture(); var a=b.data.allies[0]; var e=b.data.enemies[0]
		for i in range(3): b.data.allies[i].race="악마"
		a.hp=500; b.current_id=a.id; b.action_id="attack"
		if row.kind=="heal": a.gear_fx={"heal":100}
		else: a.gear_special=[{"key":"heal_haste","p":100,"x":50,"n":1}]
		b.gear_bridge.hooks.act=1; b.gear_bridge.hooks.skill=true
		b.dungeon_enemy_r21.begin_random(0); b._damage(a,e,100,0)
		check(a.hp==row.hp,"demon kill raw heal "+row.kind,a.hp,row.hp)
		check(a.remaining==row.g,"demon kill gauge "+row.kind,a.remaining,row.g)
		check(b.x(e).source_rng==row.rng,"demon kill RNG "+row.kind,b.x(e).source_rng,row.rng)
		check(b.gear_bridge.hooks.skill==true,"restore skill context "+row.kind)
	var b=clean_fixture(); var a=b.data.allies[0]; var e=b.data.enemies[0]
	for i in range(3): b.data.allies[i].nation="케른 연방"
	a.gear_fx={"reflect":10}; b.data.seed=int(oracle.counter.seed)
	e.acts=[{"kind":"atk","name":"test","m":1}]; e.act_index=0; e.target_id=a.id
	b.current_id=e.id; b.dungeon_enemy_r21.turn()
	check(e.hp==oracle.counter.hp,"Kern counter and original-hit reflection HP",e.hp,oracle.counter.hp)
	check(b.combat_hits.size()==2,"enemy hit plus Kern counter",b.combat_hits.size(),2)
	var reflected=1000-e.hp-int(b.combat_hits[1].damage) if b.combat_hits.size()==2 else -1
	check(reflected==oracle.counter.reflected,"reflect uses original 100 damage",reflected,oracle.counter.reflected)
	b=clean_fixture(); a=b.data.allies[0]; e=b.data.enemies[0]
	for i in range(3): b.data.allies[i].nation="케른 연방"
	a.gear_fx={"reflect":10}; b.data.seed=1; e.hp=500
	b._effect(a,"attack_up",3,.5)
	e.acts=[{"kind":"atk","name":"test","m":1,"drain":.5,"push":.2,"dot":{"m":.3,"turns":3},"strip":true}]; e.act_index=0; e.target_id=a.id
	b.current_id=e.id; b.dungeon_enemy_r21.turn()
	check(e.hp==oracle.ordering.hp,"drain and strip before counter / reflect",e.hp,oracle.ordering.hp)
	check(a.remaining==oracle.ordering.g,"push before attacked",a.remaining,oracle.ordering.g)
	check(b.fx(a,"attack_up")==oracle.ordering.attack,"strip attack buff",b.fx(a,"attack_up"),oracle.ordering.attack)
	check(b.fx(a,"enemy_dot_0")==oracle.ordering.dot,"after-hit DOT amount",b.fx(a,"enemy_dot_0"),oracle.ordering.dot)
	check(a.effects.enemy_dot_0.turns==oracle.ordering.life,"after-hit DOT life",a.effects.enemy_dot_0.turns,oracle.ordering.life)
	b=clean_fixture(); a=b.data.allies[0]; e=b.data.enemies[0]
	a.hp=100000; a.mhp=100000
	var keys=["attack_up","defense_up","backstep","blood","fortified_guard","adeline_guard","contract","duty","haste"]
	for key in keys: b._effect(a,key,99,.1)
	e.acts=[{"kind":"atk","name":"test","m":1,"strip":true}]; e.act_index=0; e.target_id=a.id; b.current_id=e.id
	for step in range(9):
		b.dungeon_enemy_r21.turn()
		var remaining=keys.map(func(key):return a.effects.has(key))
		check(same(remaining,oracle.strip[step]),"strip canonical priority "+str(step+1),remaining,oracle.strip[step])
	var f=FileAccess.open("res://../verification/data-r21/a9-part1-latest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t")); f.close()
	print("A9 targeted ",checks," checks / failures ",failures.size()); quit(0 if failures.is_empty() else 1)
