extends SceneTree
const World=preload("res://game/persona_world.gd")
const Battle=preload("res://game/battle_v3.gd")
var checks=0
var failures=[]
var w=World.new()
func check(ok: bool,message: String):
	checks+=1
	if not ok:
		if failures.size()<30:push_error(message)
		failures.append(message)
func same(a,b) -> bool:
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for k in a:
			if not b.has(k) or not same(a[k],b[k]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same(a[i],b[i]): return false
		return true
	if a is float or a is int: return absf(float(a)-float(b))<.0000001
	return a==b
func _init():call_deferred("run")
func prepare(row: Dictionary):
	w.s.run={};w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town"
	w.s.persona.merge({"cls":row.cls,"lv":row.pm[0].L,"stats":row.pm[0].get("ps",{}),"skill":row.pm[0].get("skill",w.PersonaResearch.clean({})),"race":row.pm[0].get("race",""),"nation":row.pm[0].get("nat",""),"lineage":row.pm[0].get("lin","")},true)
	w.s.party=[];w.s.owned=[]
	for m in row.pm:
		w.s.members[m.id].level=m.L
		if m.id!="persona":w.s.party.append(m.id);w.s.owned.append(m.id)
	w.s.members.persona.xp=0;w.s.persona.exp=0
func data(row: Dictionary) -> Dictionary:
	prepare(row);w.depart_dungeon(1,1);w.s.run.phase="battle"
	var d=w.battle_data();d.seed=int(row.get("seed",1))
	var plan=d.encounter_r21.duplicate(true)
	plan.enc.merge({"fl":["apprentice_doll","apprentice_doll"],"fg":["",""],"ne":2,"raid":false,"star":1,"dk":0,"dc":0},true)
	plan.enc.erase("floor");plan.enc.erase("dn");plan.el=10;plan.star=1
	d.encounter_r21=plan;d.enemies=w.make_enemies(plan,d.allies)
	return d
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/a8-persona-oracle.json"))
	for row in source.initial:
		prepare(row)
		for i in range(4):
			var m=row.pm[i];var b=w.stats(m.id,int(m.L));var u=row.units[i]
			var actual=[b.hp,b.mp,b[{"힘":"str","민첩":"agi","지능":"int"}[w.class_def(m.id).line]],b.def,b.agi,floor(b.spd+.5),b.crit]
			check(same(actual,[u.mhp,u.mmp,u.cs,u.de,u.ag,u.sp,u.cr]),"initial %s %s %s %s %s / %s"%[row.cls,row.pm[0].race,row.pm[0].nat,m.id,actual,[u.mhp,u.mmp,u.cs,u.de,u.ag,u.sp,u.cr]])
	for row in source.skills:
		var b=Battle.new(data(row));b.current_id="persona";b.action_id="personal";b.r21_action_actor="persona"
		for u in b.data.allies+b.data.enemies:
			u.hp=50 if u.has("base") else 1000;u.mhp=1000;u.effects={};u.remaining=10000
			if u.has("base"):u.mp=100;u.mmp=100;u.shield=0;u.race="";u.nation="";u.lineage=""
			else:u.gauge=100;u.max=100;u.broken=false
			b.extra_state[u.id]={}
		var a=b.ally("persona");var e=b.data.enemies[0];var t=b.data.allies[1]
		b._begin_combat_events("personal",a,e,t);b.dungeon_enemy_r21.begin_random(0)
		b.gear_bridge.hooks.act=1;b.gear_bridge.hooks.skill="persona_skill"
		b.PersonaCombat.run(b,a,e,t,a.skills.personal)
		for i in range(6):
			var u=(b.data.allies+b.data.enemies)[i];var expected=row.units[i]
			var actual=[u.hp,u.get("mp",100),u.get("shield",0) if u.has("base") else b.fx(u,"shield"),u.remaining,0 if u.has("base") else u.gauge]
			check(same(actual,[expected.hp,expected.mp,expected.sh,expected.g,0 if i<4 else expected.ay]),"skill %s %s slot%s %s / %s"%[row.cls,row.raw,i,actual,[expected.hp,expected.mp,expected.sh,expected.g,expected.ay]])
			for key in expected.bf:
				var native={"adn":"attack_down","ddn":"defense_down"}.get(key,key)
				check(u.effects.has(native) and same([b.fx(u,native),u.effects[native].turns],[expected.bf[key].v,expected.bf[key].n]),"buff "+key+str(row.raw))
			if expected.regen is Dictionary:check(same([b.fx(u,"persona_regen"),u.effects.get("persona_regen",{}).get("turns",0)],[expected.regen.d,expected.regen.n]),"regen "+str(row.raw))
			if not expected.dot.is_empty():check(same(u.effects.get("dot",{}).get("stacks",[]),expected.dot.map(func(v):return v.d)),"dot "+str(row.raw))
		check(b.x(e).source_rng==row.rng,"rng "+str(row.raw))
	FileAccess.open("res://../verification/data-r21/a8-persona-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"initial":source.initial.size(),"skills":source.skills.size()},"\t"))
	print("PERSONA COMBAT A8 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
