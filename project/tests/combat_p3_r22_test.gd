extends "res://tests/combat_p2_r22_trace.gd"
const UnitBattle=preload("res://tests/combat_p3_r22_fixture.gd")
var checks=0
var failures=[]
var observations=[]
func check(got,want,label):
	checks+=1
	if not same(got,want): failures.append(label); observations.append({"label":label,"got":got,"want":want})
func fixture(row):
	var w=World.new(); w.s.party=row.party.duplicate()
	for id in w.s.party: w.s.members[id].level=10
	w.depart_dungeon(1,12345); var d=w.battle_data(); d.seed=12345
	var plan=d.encounter_r21.duplicate(true)
	plan.enc.merge({"fl":["apprentice_doll","apprentice_doll"],"fg":["",""],"ne":2,"star":1,"raid":false,"dk":0,"dc":0},true)
	plan.enc.erase("floor"); plan.enc.erase("dn"); plan.el=10; plan.star=1; d.encounter_r21=plan; d.enemies=w.make_enemies(plan,d.allies)
	var b=UnitBattle.new(d); b.turn_count=0; b.ctb_tick=0; b.ctb_round=0
	for i in range(6):
		var u=(b.data.allies+b.data.enemies)[i]
		u.hp=600 if i<4 else 5000; u.mhp=1000 if i<4 else 5000; u.effects={}; u.remaining=10000; u.shield=0; b.extra_state[u.id]={}
		if i<4:
			u.mp=1000;u.mmp=1000;u.actions=0;u.once=false;u.race="";u.nation="";u.lineage="";u.gear_fx={};u.gear_special=[]
			for key in ["str","agi","int"]: u.base[key]=50
			u.base.def=30;u.base.spd=100;u.base.crit=7
			if i>0:
				var old=u.id; u.id="neutral%d"%i; b.extra_state[u.id]=b.extra_state[old];b.extra_state.erase(old);u.class_id="warrior";u.line="str";u.passive={};u.trait={"p":{}}
		else:
			u.gauge=100;u.max=100;u.speed=100;u.defense=30;u.grade="mob";u.rules={};u.weak=[];u.broken=false;u.act_index=0;u.acts=[{"kind":"spell","ic":"spell","magic":true,"m":1,"name":"test"}]
	b.x(b.data.enemies[0]).source_rng=1
	b.current_id=b.data.allies[0].id; b.selected_enemy=b.data.enemies[0].id; b.selected_ally=b.data.allies[1].id
	var a=b.data.allies[0]; var e=b.data.enemies[0]
	if row.case==2: a.hp=200;b.data.allies[1].hp=150;e.hp=350;e.weak=[a.element]
	if row.case==3: b._effect(b.data.allies[1],"attack_up",3,.2);b._effect(b.data.allies[1],"defense_up",3,.15);b._effect(a,"attack_up",3,.1)
	if row.case==5: b._effect(e,"attack_down",3,.2);b._effect(e,"defense_down",3,.15)
	if row.case==6: e.grade="boss";e.weak=[a.element]
	return b
func dump(b):
	var units=[]
	for u in b.data.allies+b.data.enemies:
		var buffs={}
		for key in ["attack_up","defense_up","attack_down","defense_down","haste","contract","duty","adeline_guard","zdn","blood","fortified_guard"]:
			if u.effects.has(key): buffs[key]={"amount":b.fx(u,key),"turns":u.effects[key].turns,"doubled":u.effects[key].get("doubled",false)}
		units.append({"hp":u.hp,"mp":u.get("mp",1000),"shield":u.get("shield",0),"g":u.remaining,"tau":u.effects.get("taunt",{}).get("turns",0),"mark":u.effects.has("mark"),"fox":u.effects.get("foxflame",{}).get("turns",0),"rift":u.effects.has("rift_charge"),"once":u.get("once",false),"shield_turns":u.effects.get("shield",{}).get("turns",0),"buffs":buffs,"dots":{"class":b.fx(u,"dot"),"corrosion":b.fx(u,"corrosion"),"bleed":b.fx(u,"bleed")},"regen":b.fx(u,"regen"),"sorel":b.fx(u,"sorel_regen"),"sorel_turns":u.effects.get("sorel_regen",{}).get("turns",0)})
	for i in range(units.size()): units[i].guard=(b.data.allies+b.data.enemies)[i].effects.has("guard")
	return {"units":units,"rng":b.x(b.data.enemies[0]).source_rng}
func compare_state(b,want,label):
	var got=dump(b)
	for i in range(6):
		if want.units[i].buffs is Array and want.units[i].buffs.is_empty(): want.units[i].buffs={}
		var regen=0.0
		for entry in (b.data.allies+b.data.enemies)[i].effects.get("regen",{}).get("heals",[]): regen+=entry.amount
		got.units[i].regen=regen
		for field in want.units[i]: check(got.units[i][field],want.units[i][field],label+" slot%d %s"%[i,field])
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/p3-oracle.json"))
	for row in oracle.personal:
		var b=fixture(row)
		for step in range(row.steps.size()):
			var can=b.unavailable("personal").is_empty()
			check(can,row.steps[step].can,"can %s/%d/%d"%[row.id,row.case,step])
			if can: b.act("personal")
			var actual=dump(b); var want=row.steps[step].state
			for i in range(6):
				# wasmoon's empty Lua table has JSON array shape; this field is a map.
				if want.units[i].buffs is Array and want.units[i].buffs.is_empty(): want.units[i].buffs={}
				var regen=0.0
				for entry in (b.data.allies+b.data.enemies)[i].effects.get("regen",{}).get("heals",[]): regen+=entry.amount
				actual.units[i].regen=regen
				for key in want.units[i]: check(actual.units[i][key],want.units[i][key],"%s/%d/%d slot%d %s"%[row.id,row.case,step,i,key])
			check(actual.rng,want.rng,"rng %s/%d/%d"%[row.id,row.case,step])
		if row.case==4:
			# Serialization uses real canonical enemy statistics; the unit fixture has
			# deliberately synthetic 5000 HP enemies and cannot be source-hydrated.
			var world=World.new();world.s.party=row.party.duplicate()
			for id in world.s.party: world.s.members[id].level=10
			world.depart_dungeon(1,12345);var live=UnitBattle.new(world.battle_data());live.selected_ally=live.data.allies[1].id
			if live.unavailable("personal").is_empty(): live.act("personal")
			var saved=JSON.parse_string(JSON.stringify(live.snapshot()));var restored=UnitBattle.new(live.data)
			check(restored.restore(saved),true,"schema3 JSON restores "+row.id)
			check(restored.snapshot(),saved,"schema3 retains all fields "+row.id)
			var old=saved.duplicate(true)
			for id in old.extra_state:
				for key in ["seal_until","cover_turns","first_attack_action","streak_action","echo_action","echoing","mamp","decl","dset","inch","enc","double_turn"]: old.extra_state[id].erase(key)
			check(restored.restore(old),true,"old schema3 without P3 fields "+row.id)
	for row in oracle.traits:
		var b=fixture({"party":["marceline","naran","teiris","haldric"],"case":1})
		var a=b.data.allies[0]; var e=b.data.enemies[0]
		var cls={}
		var w=World.new()
		for definition in w.config.classes:
			if definition.id==row.cls: cls=definition
		b.extra_state.neutral0=b.extra_state[a.id];b.extra_state.erase(a.id);a.id="neutral0";b.current_id=a.id
		a.class_id=row.cls;a.line={"힘":"str","민첩":"agi","지능":"int"}[cls.line];a.passive=cls.get("passive",{});a.trait={"p":{}}
		for skill in cls.skills:
			if skill.id=="atk": a.skills.attack=skill.duplicate(true)
		for i in range(4):
			var u=b.data.allies[i];u.race=row.race if i<row.tier else "";u.nation=row.nation if i<row.tier else "";u.lineage=("개" if i==0 else "고양이") if row.tag=="beast" and i<row.tier else ""
		a.hp=200 if int(row.ci)%2==0 else 600;b._effect(a,"taunt",2)
		if int(row.ci)%3==0: e.hp=30
		b._effect(a,"attack_down",3,.2);b._effect(a,"defense_up",2,.15)
		b.dungeon_enemy_r21.begin_random(1);b.action_id="attack"
		b._damage(a,e,a.skills.attack.power,a.skills.attack.brk)
		b._incoming_strike(a,150,{}, {"name":"test"},false,true);b._receive_heal(a,31.5)
		if row.cls in ["paladin","priest"]:
			var amount=floor(100*(1.2 if row.cls=="paladin" else 1))
			if b.count_tag("nation","솔렌 성왕국")>=2: amount=floor(amount*1.03)
			for u in b.living(true): b._shield(u,amount,3)
		b._finish_turn()
		var got=dump(b);var want=row.state;got.speeds=[]
		for u in b.data.allies+b.data.enemies: got.speeds.append(b.speed(u))
		for i in range(6):
			if want.units[i].buffs is Array and want.units[i].buffs.is_empty(): want.units[i].buffs={}
			for key in want.units[i]: check(got.units[i][key],want.units[i][key],"trait %s/%d/%s slot%d %s"%[row.tag,row.tier,row.cls,i,key])
		check(got.rng,want.rng,"trait rng %s/%d/%s"%[row.tag,row.tier,row.cls]);check(got.speeds,want.speeds,"trait speed %s/%d/%s"%[row.tag,row.tier,row.cls])
	for row in oracle.class_skills:
		var b=fixture({"party":["marceline","naran","teiris","haldric"],"case":1});var a=b.data.allies[0]
		var w=World.new();var cls={}
		for definition in w.config.classes:
			if definition.id==row.cls: cls=definition
		b.extra_state.neutral0=b.extra_state[a.id];b.extra_state.erase(a.id);a.id="neutral0";b.current_id=a.id
		a.class_id=row.cls;a.line={"힘":"str","민첩":"agi","지능":"int"}[cls.line];a.passive=cls.get("passive",{});a.trait={"p":{}};a.skills={};a.hp=200
		for skill in cls.skills:
			if skill.kind in ["기본","능동"]: a.skills["attack" if skill.id=="atk" else skill.id]=skill.duplicate(true)
		if not a.skills.has("guard"): a.skills.guard={"name":"방어","mp":0,"target":"자신","power":.4,"turns":1,"brk":0}
		var key={"atk":"attack","df":"defend" if row.cls=="warrior" else "guard","guard2":"guard","shield":"pshield","pshield":"hshield","defdn":"acid","wave":"chaoswave","taunt":"ptaunt" if row.cls=="paladin" else "taunt"}.get(row.id,row.id)
		check(b.act(key),true,"class skill executed "+row.cls+"/"+row.id)
		var got=dump(b);var want=row.state
		for i in range(6):
			if want.units[i].buffs is Array and want.units[i].buffs.is_empty(): want.units[i].buffs={}
			for field in want.units[i]: check(got.units[i][field],want.units[i][field],"class %s/%s slot%d %s"%[row.cls,row.id,i,field])
		check(got.rng,want.rng,"class rng "+row.cls+"/"+row.id)
	for row in oracle.deaths:
		var b=fixture(row);var a=b.data.allies[0]
		if b.unavailable("personal").is_empty(): b.act("personal")
		for hit in range(3): b._incoming_strike(a,99999,{}, {"name":"test"},false,true)
		var got=dump(b);var want=row.state
		for i in range(6):
			if want.units[i].buffs is Array and want.units[i].buffs.is_empty(): want.units[i].buffs={}
			var regen=0.0
			for entry in (b.data.allies+b.data.enemies)[i].effects.get("regen",{}).get("heals",[]): regen+=entry.amount
			got.units[i].regen=regen
			for field in want.units[i]: check(got.units[i][field],want.units[i][field],"caster death %s slot%d %s"%[row.id,i,field])
	for row in oracle.regen_mix:
		var b=fixture({"party":["sorel","marceline","naran","teiris"],"case":1});var a=b.data.allies[1]
		b.extra_state.adeline=b.extra_state[a.id];b.extra_state.erase(a.id);a.id="adeline";a.class_id="priest";a.line="int"
		var index=0
		for actor in row.order:
			b.current_id=b.data.allies[int(actor)-1].id;b.action_id="personal";b._begin_effect_action(b.current_id)
			b._personal(b.unit(b.current_id),b.data.enemies[0],b.data.allies[1],{});b._finish_turn()
			compare_state(b,row.states[index],"regen cast "+str(row.order)+"/"+str(index));index+=1
		for r in range(1,4):
			b.ctb_round=r;b._round_tick();compare_state(b,row.states[index],"regen round "+str(row.order)+"/"+str(r));index+=1
			b.current_id=b.data.allies[2].id;b._finish_turn();compare_state(b,row.states[index],"regen turn "+str(row.order)+"/"+str(r));index+=1
	for row in oracle.dot_credit:
		var b=fixture({"party":["marceline","naran","teiris","haldric"],"case":1});var a=b.data.allies[0];var e=b.data.enemies[0]
		b.extra_state.neutral0=b.extra_state[a.id];b.extra_state.erase(a.id);a.id="neutral0"
		for i in range(4): b.data.allies[i].mp=0;b.data.allies[i].race="악마" if i<3 else ""
		e.hp=50
		if not row.reverse: b._push_class_dot(e,70,1,a.id)
		b._effect(e,"corrosion",1,80);e.effects.corrosion.by=b.data.allies[1].id;e.effects.corrosion.order=b._next_dot_order()
		if row.reverse: b._push_class_dot(e,70,1,a.id)
		if row.dead: b.data.allies[0 if row.reverse else 1].hp=0
		b._tick_enemy_dots(e);compare_state(b,row.state,"DOT kill owner "+str(row.reverse)+"/"+str(row.dead))
	for row in oracle.counters:
		var b=fixture({"party":row.party,"case":1});var a=b.data.allies[0];var e=b.data.enemies[0]
		if row.kind=="kern":
			b.extra_state.neutral0=b.extra_state[a.id];b.extra_state.erase(a.id);a.id="neutral0"
			for i in range(4): b.data.allies[i].nation="케른 연방" if i<3 else ""
		b.data.seed=int(row.seed)*7919;b.dungeon_enemy_r21.begin_random(1);e.attack=50;e.level=10
		b._enemy_hit(e,a,e.acts[0])
		if not b.last_enemy_hit_target.is_empty(): b.TraitRules.attacked(b,b.ally(b.last_enemy_hit_target),e)
		compare_state(b,row.state,"counter "+row.kind+"/"+str(row.seed));check(b.x(e).source_rng,row.state.rng,"counter RNG "+row.kind+"/"+str(row.seed))
	var b=fixture({"party":["sorel","marceline","naran","teiris"],"case":1});var a=b.data.allies[1];a.class_id="gladiator";a.hp=300;b.current_id=a.id
	a.skills.blood={"name":"피의 갈증","mp":0,"target":"자신","power":.15,"turns":2,"brk":0}
	b.act("blood");compare_state(b,oracle.blood_sorel,"blood HP cost triggers Sorel")
	var f=FileAccess.open("res://../verification/data-r21/p3-latest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations},"\t"));f.close()
	print("P3 ",checks," checks / failures ",failures.size()," ",failures.slice(0,12)); quit(0 if failures.is_empty() else 1)
