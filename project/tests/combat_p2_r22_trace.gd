extends SceneTree
const World=preload("res://game/dungeon_world_r21.gd")
const Battle=preload("res://tests/combat_p2_r22_trace_fixture.gd")
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
func _init(): call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/p2-oracle.json"))
	var raid=OS.get_cmdline_user_args().has("raid")
	var reports=[]; var matched=0; var actions=0; var differences={}
	for row in (oracle.raid_battles if raid else oracle.battles+oracle.raid_battles):
		var w=World.new(); w.s.party=row.party.duplicate()
		for id in w.s.party: w.s.members[id].level=10
		w.depart_dungeon(1,int(row.seed)); w.s.run.phase="battle"
		var d=w.battle_data(); d.seed=int(row.seed)
		var plan=d.encounter_r21.duplicate(true)
		plan.enc.merge({"fl":row.fl.duplicate(),"fg":[],"ne":int(row.ne),"star":1,"raid":row.raid,"dk":0,"dc":0},true)
		while plan.enc.fg.size()<int(row.ne): plan.enc.fg.append("")
		plan.enc.erase("floor"); plan.enc.erase("dn"); plan.el=10; plan.star=1
		d.encounter_r21=plan; d.enemies=w.make_enemies(plan,d.allies)
		# Equal canonical initial statistics isolate engine behavior from P1/P4.
		for i in range(4):
			var a=d.allies[i]; var u=row.initial[i]
			a.hp=int(u.hp); a.mhp=int(u.mhp); a.mp=int(u.mp); a.mmp=int(u.mmp)
			a.base[a.line]=u.cs; a.base.def=u.de; a.base.agi=u.ag; a.base.crit=u.cr; a.base.spd=u.sp
		var b=Battle.new(d)
		for step in range(500):
			if not b.result.is_empty(): break
			if not b.automatic_turn():
				b.selected_enemy=b.living(false)[0].id
				if not b.act("attack"): break
		b.record(); var mismatch=[]
		for i in range(maxi(b.trace.size(),row.trace.size())):
			if i>=b.trace.size() or i>=row.trace.size():
				mismatch.append({"step":i,"fields":["length"]}); differences.length=differences.get("length",0)+1; continue
			var actual=b.trace[i]; var expected=row.trace[i]; var fields=[]
			for key in ["actor","hp","mp","sh","rng","tk","rd","g","targets","hits","abyss","broken"]:
				if not same(actual[key],expected[key]): fields.append(key); differences[key]=differences.get(key,0)+1
			if fields.is_empty(): matched+=1
			else: mismatch.append({"step":i,"fields":fields,"actual":actual,"expected":expected})
			actions+=1
		reports.append({"party":row.party,"foe":row.foe,"bn":row.bn,"source_actions":row.trace.size(),"godot_actions":b.trace.size(),"source_result":row.result,"godot_result":b.result,"mismatches":mismatch})
	var report={"battles":reports.size(),"compared_actions":actions,"matched_actions":matched,"different_actions":actions-matched,"field_differences":differences,"reports":reports}
	var f=FileAccess.open("res://../verification/data-r21/p2-full-raid-battles.json" if raid else "res://../verification/data-r21/p2-full-battles.json",FileAccess.WRITE); f.store_string(JSON.stringify(report,"\t")); f.close()
	print("P2 full battles ",reports.size()," / actions ",actions," / matched ",matched," / differences ",differences)
	quit(0 if differences.is_empty() else 1)
