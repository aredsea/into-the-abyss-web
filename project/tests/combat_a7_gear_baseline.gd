extends "res://tests/a7_baseline_audit_helper.gd"
## Original mixed policy, including each engine's own skill eligibility decisions.
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/a7-gear-oracle.json"))
	var reports=[]; var equal_battles=0; var equal_actions=0; var source_actions=0; var actual_actions=0; var inputs={}
	for row in oracle.battles+oracle.raid_battles:
		var w=World.new(); w.s.party=row.party.duplicate()
		for id in w.s.party: w.s.members[id].level=10
		w.depart_dungeon(1,int(row.seed)); w.s.run.phase="battle"
		var d=w.battle_data(); d.seed=int(row.seed)
		var plan=d.encounter_r21.duplicate(true)
		plan.enc.merge({"fl":row.fl.duplicate(),"fg":[],"ne":int(row.ne),"star":1,"raid":row.raid,"dk":0,"dc":0},true)
		while plan.enc.fg.size()<int(row.ne): plan.enc.fg.append("")
		plan.enc.erase("floor"); plan.enc.erase("dn"); plan.el=10; plan.star=1
		d.encounter_r21=plan; d.enemies=w.make_enemies(plan,d.allies)
		for i in range(4):
			var a=d.allies[i]; var u=row.initial[i].base
			a.hp=int(u.hp); a.mhp=int(u.mhp); a.mp=int(u.mp); a.mmp=int(u.mmp)
			a.gear_member=row.pm[i]; a.gear_fx={}; a.gear_special=[]
			a.base[a.line]=u.cs; a.base.def=u.de; a.base.agi=u.ag; a.base.crit=u.cr; a.base.spd=u.sp
		d.inventory={"mp_s":3,"hp_s":3}
		d.item_defs=[{"id":"mp_s","name":"소형 마나 물약","kind":"mp","fraction":.15,"level":1},{"id":"hp_s","name":"소형 체력 물약","kind":"hp","fraction":.2,"level":1}]
		var b=Battle.new(d); var used=[]; var step=0
		for guard in range(500):
			if not b.result.is_empty(): break
			if b.automatic_turn(): continue
			step+=1; var a=b.ally(b.current_id); var id="attack"; var target=b.living(false)[0]
			b.selected_enemy=target.id
			if step%3==1:
				if b.unavailable("personal").is_empty(): id="personal"
			elif step%3==0:
				for key in b.dungeon_enemy_r21.rules.config.enemy_skill_order.get(a.class_id,[]):
					if key=="personal": continue # Lua policy excludes sk.pv in the class-skill branch.
					var native={"warrior":{"guard2":"guard"},"paladin":{"shield":"pshield","taunt":"ptaunt"},"priest":{"pshield":"hshield"},"alchemist":{"defdn":"acid"},"chaos":{"wave":"chaoswave"}}.get(a.class_id,{}).get(key,key)
					if b.actions().has(native) and b.actions()[native].mp>0 and b.unavailable(native).is_empty(): id=native; break
			else:
				for iid in ["mp_s","hp_s"]:
					if b.inventory[iid]<=0: continue
					for member in b.living(true):
						if (iid=="mp_s" and member.mp<member.mmp) or (iid=="hp_s" and member.hp<member.mhp): id="item:"+iid; target=member; break
					if id.begins_with("item:"): break
			if not id.begins_with("item:") and b.actions()[id].target=="아군 1":
				var found=false
				for member in b.living(true):
					if not oracle.no_self.get(a.id,false) or member.id!=a.id: target=member; found=true; break
				if not found: id="attack"; target=b.living(false)[0]
			b.selected_ally=target.id if target.has("base") else a.id
			used.append({"n":b.turn_count+1,"actor":b.data.allies.find(a)+1,"id":id})
			inputs[id]=inputs.get(id,0)+1
			if not b.act(id): break
		b.record(); var first={}; var matched=0
		for i in range(maxi(b.trace.size(),row.trace.size())):
			var fields=[]
			if i>=b.trace.size() or i>=row.trace.size(): fields=["length"]
			else:
				for key in ["n","actor","hp","mp","sh","rng","tk","rd","g","targets","hits","abyss","broken"]:
					if not same(b.trace[i][key],row.trace[i][key]): fields.append(key)
			if fields.is_empty(): matched+=1
			elif first.is_empty():
				var decision={}
				for input in row.decisions:
					if input.n<=i+1: decision=input
				first={"step":i+1,"fields":fields,"input":decision,"source":row.trace[i] if i<row.trace.size() else {},"actual":b.trace[i] if i<b.trace.size() else {}}
		if {"win":"victory","lose":"defeat"}.get(row.result,"")!=b.result or b.result.is_empty():
			if first.is_empty(): first={"fields":["final_result"],"source":row.result,"actual":b.result}
		if first.is_empty(): equal_battles+=1
		equal_actions+=matched; source_actions+=row.trace.size(); actual_actions+=b.trace.size()
		reports.append({"party":row.party,"foe":row.foe,"bn":row.bn,"source_result":row.result,"actual_result":b.result,"source_actions":row.trace.size(),"actual_actions":b.trace.size(),"matched_actions":matched,"first_difference":first,"source_inputs":row.decisions,"actual_inputs":used})
	var report={"purpose":"Strict active-skill and consumable full-battle parity","battles":reports.size(),"equal_battles":equal_battles,"source_actions":source_actions,"actual_actions":actual_actions,"matched_actions":equal_actions,"actual_inputs":inputs,"reports":reports}
	var f=FileAccess.open("res://../verification/data-r21/a7-gear-pinned-before.json",FileAccess.WRITE); f.store_string(JSON.stringify(report,"\t")); f.close()
	print("A7 gear parity ",reports.size()," battles / source ",source_actions," / actual ",actual_actions," / equal battles ",equal_battles," / matched actions ",equal_actions)
	quit(0 if equal_battles==reports.size() else 1)
