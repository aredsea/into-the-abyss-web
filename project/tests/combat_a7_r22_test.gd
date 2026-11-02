extends "res://tests/combat_a6_r22_test.gd"

func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/a7-oracle.json"))
	var b=fixture(); var a=b.data.allies[0]; var e=b.data.enemies[0]
	var start_data=b.data.duplicate(true)
	start_data.allies[0].gear_fx={"shield":100}; start_data.allies[0].gear_special=[{"key":"guardian","p":100,"x":50,"n":1}]
	start_data.allies[1].id="altan"
	var altan_battle=Battle.new(start_data)
	check(altan_battle.data.allies[0].shield==oracle.altan_start,"Altan start raw shield ignores first ally gear GH",altan_battle.data.allies[0].shield,oracle.altan_start)
	b.data.allies[1].gear_special=[{"key":"party_dmg","p":100,"x":5,"n":0}]
	b.data.allies[2].gear_special=[{"key":"party_dmg","p":100,"x":10,"n":0}]
	var party_damage=b.gear_bridge.invoke("deal",[1,5,100,[],{}])
	check(is_equal_approx(party_damage,oracle.party_damage),"gear party damage uses living maximum once",party_damage,oracle.party_damage)
	b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]
	a.class_id="unsanctioned"; a.line="int"; b.current_id=a.id; b.action_id="attack"
	b._damage(a,e,1,0)
	check(e.effects.dot.lifetimes[0]==oracle.dot_life,"P1-a active path DOT life",e.effects.dot.lifetimes[0],oracle.dot_life)
	var ticks=[]
	for n in range(4):
		var before=e.hp; b._tick_enemy_dots(e); ticks.append(before-e.hp)
	check(same(ticks,oracle.ticks),"P1-a DOT ticks",ticks,oracle.ticks)
	b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]
	b.dungeon_enemy_r21.configure(e,"tome_librarian",1,0)
	e.hp=1440; e.mhp=1440; e.phase=1; a.gear_special=[{"key":"un_chain","v":[3,20]}]
	for n in range(3): b._push_class_dot(e,500,3,a.id)
	check(e.hp==oracle.phase_hp,"P1-b chain respects phase guard",e.hp,oracle.phase_hp)
	for row in oracle.shield:
		b=fixture(); a=b.data.allies[0]; a.hp=100; a.shield=1000
		var s=b.data.allies[1]; b.extra_state.sorel=b.x(s); s.id="sorel"
		a.gear_special=[{"key":"last_stand","p":100,"x":20,"n":2}]
		b._incoming_strike(a,100,b.data.enemies[0],{"name":"test"},false,row.fixed)
		var got=[a.hp,b.x(s).get("rescue",0),b.x(a).get("stood",false)]
		check(same(got,[row.hp,row.rescue,row.stood]),"P2-d shield blocks damaged "+str(row.fixed),got,[row.hp,row.rescue,row.stood])
	b=fixture(); e=b.data.enemies[0]
	b._effect(e,"dot",3,600); b.x(e).dot_stacks=6
	check(b._dot_metadata(e).stacks.size()==5,"Nit-e aggregate migration current cap",b._dot_metadata(e).stacks.size(),5)
	# Floating point just below an integer: pre-r21 floor must remain unadjusted.
	var d=fixture().data; d.erase("encounter_r21"); b=Battle.new(d); a=b.data.allies[0]; e=b.data.enemies[0]
	a.base.str=99.9999999999999; a.line="str"; a.race=""; a.nation=""; a.lineage=""; a.base.crit=0; a.base.agi=0; a.passive={}; a.trait={"p":{}}
	e.defense=0; e.weak=[]; e.broken=false; e.hp=1000; a.gear_fx={}; a.gear_special=[]
	var before=e.hp; b._damage(a,e,1,0,false,1)
	check(before-e.hp==199,"P2-c legacy floor without epsilon",before-e.hp,199)
	var f=FileAccess.open("res://../verification/data-r21/a7-part1-latest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t")); f.close()
	print("A7 part 1 ",checks," checks / failures ",failures.size()); quit(0 if failures.is_empty() else 1)
