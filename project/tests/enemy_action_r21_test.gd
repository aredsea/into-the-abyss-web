extends SceneTree
const World=preload("res://game/dungeon_world_r21.gd")
const Battle=preload("res://tests/enemy_action_fixture_r21.gd")
var failures=[]
var checks=0
var matched=0
var mismatches=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok:
		failures.append(label)
		if failures.size()<12: print("MISMATCH "+label)
func _init(): call_deferred("run")
func slot(b,i: int) -> Dictionary:
	return b.data.allies[i-1] if i<=4 else b.data.enemies[i-5]
func index(b,id: String) -> int:
	for i in range(1,10):
		if slot(b,i).id==id: return i
	return 0
func setup(w,row):
	var d=w.battle_data(); d.seed=int(row.seed)
	var enc=d.encounter_r21.enc
	enc.fl=[row.id,"apprentice_doll","rusted_shieldman"]; enc.fg=["","",""]; enc.ne=5; enc.raid=false
	enc.erase("floor"); enc.erase("dn"); enc.dk=0; enc.zk="academy_upper"; enc.star=1
	d.enemies=w.make_enemies(d.encounter_r21,d.allies)
	for i in range(4):
		var a=d.allies[i]; a.id="a%d"%(i+1); a.name=a.id; a.class_id="sanctioned"; a.race=""; a.nation=""; a.lineage=""; a.gear_fx={}; a.gear_special=[]; a.passive={}; a.trait={"p":{}}
		a.skills={"personal":{},"burst":{},"attack":{},"guard":{}}
	var b=Battle.new(d)
	b.turn_count=int(row.action_no); b.current_id=b.data.enemies[0].id
	for i in range(1,10):
		var u=slot(b,i); var v=row.input[i-1]
		if i>4 and not v.foe.is_empty():
			b.dungeon_enemy_r21.configure(u,v.foe,int(v.phase),i-5)
			u.grade=v.grade
		for key in ["hp","mhp","remaining"]: u[key]=v[key]
		u.effects={}; u.row=v.row
		if i<=4:
			u.base.def=v.defense; u.base.spd=v.speed; u.shield=v.shield
			if int(row.turn)%6==0 and i==2: u.effects.taunt={"turns":2,"amount":0}
		else:
			u.grade=v.grade
			for key in ["attack","defense","speed","gauge","max","phase","act_index","charged","broken"]: u[key]=v[key]
			u.weak=v.weak.duplicate(); u.target_id=slot(b,int(v.target)).id if v.target>0 else ""
			b.x(u).foe_turns=v.turns; b.x(u).protect=slot(b,int(v.protect)).id if v.protect>0 else ""; b.x(u).hidden=v.hidden
		for key in v.effects:
			var eff=v.effects[key]
			u.effects[key]={"amount":eff.amount,"turns":eff.turns,"r21":true}
			if eff.source>0: u.effects[key].source=slot(b,int(eff.source)).id
		if v.guard: u.effects.guard={"amount":.4,"turns":1,"r21":true}
		if i>4 and v.shield>0: u.effects.shield={"amount":v.shield,"turns":v.shield_turns,"r21":true}
		if not v.silence.is_empty(): u.effects.silence={"amount":0,"turns":1,"r21":true}; b.x(u).silenced_id=v.silence
		for dot in v.dots: b.dungeon_enemy_r21.add_dot(u,slot(b,int(dot.by)),int(dot.amount),int(dot.turns))
	b.x(b.data.enemies[0]).source_rng=int(row.rng)
	# The Lua make() fixture calls begin_ev before these direct engine entries.
	b.combat_events.begin_record(b)
	return b
func dump(b) -> Array:
	var out=[]
	for i in range(1,10):
		var u=slot(b,i); var ally=i<=4; var fx={}; var dots=[]
		for key in ["attack_up","defense_up","haste","attack_down","defense_down","slow","enemy_attack_self"]:
			if u.effects.has(key):
				var eff=u.effects[key]
				fx[key]={"amount":eff.amount,"turns":eff.turns,"source":index(b,eff.get("source",""))}
		for n in range(4):
			if u.effects.has("enemy_dot_%d"%n):
				var dot=u.effects["enemy_dot_%d"%n]; dots.append({"amount":dot.amount,"turns":dot.turns,"by":index(b,dot.by)})
		out.append({"foe":"" if ally else u.foe_id,"grade":"" if ally else u.grade,"hp":u.hp,"mhp":u.mhp,"attack":10 if ally else u.attack,"defense":u.base.def if ally else u.defense,"speed":u.base.spd if ally else u.speed,
			"remaining":u.remaining,"gauge":0 if ally else u.gauge,"max":0 if ally else u.max,"phase":1 if ally else u.phase,"act_index":0 if ally else u.act_index,"target":0 if ally else index(b,u.target_id),
			"charged":false if ally else u.charged,"broken":false if ally else u.broken,"weak":[] if ally else u.weak,"effects":fx,"dots":dots,
			"turns":0 if ally else b.x(u).get("foe_turns",0),"protect":0 if ally else index(b,b.x(u).get("protect","")),"hidden":false if ally else b.x(u).get("hidden",false),"guard":u.effects.has("guard"),"shield":u.shield if ally else b.fx(u,"shield"),
			"shield_turns":0 if ally else u.effects.get("shield",{}).get("turns",0),"silence":b.x(u).get("silenced_id","") if u.effects.has("silence") else "","row":u.row})
	return out
func differences(a,b,path="") -> Array:
	var out=[]
	if (a is Array or a is Dictionary) and (b is Array or b is Dictionary) and a.is_empty() and b.is_empty(): return []
	if a is Dictionary:
		if not b is Dictionary: return [path+": type"]
		for key in a:
			if not b.has(key): out.append(path+"/"+str(key)+": missing")
			else: out.append_array(differences(a[key],b[key],path+"/"+str(key)))
		for key in b:
			if not a.has(key): out.append(path+"/"+str(key)+": extra")
	elif a is Array:
		if not b is Array or a.size()!=b.size(): return [path+": size"]
		for i in range(a.size()): out.append_array(differences(a[i],b[i],path+"/"+str(i)))
	elif a is float or a is int:
		if not (b is float or b is int) or absf(float(a)-float(b))>1e-8: out.append(path+": "+str(a)+" != "+str(b))
	elif a!=b: out.append(path+": "+str(a)+" != "+str(b))
	return out
func coverage_valid(source,gear,w) -> bool:
	check(source is Dictionary and source.get("samples") is Array and source.get("silence") is Array,"oracle arrays exist")
	check(gear is Array,"gear oracle array exists")
	if not failures.is_empty(): return false
	check(source.samples.size()>=1221,"at least 1221 action samples")
	check(source.silence.size()>=200,"at least 200 silence samples")
	check(gear.size()>=120,"at least 120 gear samples")
	var counts={}; var classes={}
	for row in source.samples: counts[row.id]=counts.get(row.id,0)+1
	for row in source.silence: classes[row["class"]]=classes.get(row["class"],0)+1
	check(w.dungeon_rules.foes.size()==100 and counts.size()==100,"all 100 canonical enemy IDs covered")
	for id in w.dungeon_rules.foes: check(counts.get(id,0)>=12,"at least 12 turns for canonical enemy "+id)
	for cls in w.dungeon_rules.config.enemy_skill_order: check(classes.get(cls,0)>=20,"at least 20 silence samples for "+cls)
	return failures.is_empty()
func finish(result: Dictionary):
	FileAccess.open("res://../verification/data-r21/enemy-action-results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	result.erase("mismatches"); result.erase("coverage"); result.erase("continuous_mismatches")
	print("ENEMY_ACTION_R21 "+JSON.stringify(result)); quit(0 if failures.is_empty() else 1)
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/enemy-action-oracle.json"))
	var w=World.new(); w.depart_dungeon(1,12345); w.s.run.phase="battle"
	var gear=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/elite-gear-oracle.json"))
	if not coverage_valid(source,gear,w):
		finish({"checks":checks,"failures":failures.size(),"coverage_failures":failures,"gear_samples":gear.size() if gear is Array else 0})
		return
	var counts={}
	for row in source.samples:
		var b=setup(w,row); b.dungeon_enemy_r21.turn()
		var actual=dump(b)
		var delta=differences(row.output,actual)
		if int(b.x(b.data.enemies[0]).source_rng)!=int(row.output_rng): delta.append("rng")
		check(delta.is_empty(),"%s/%d %s"%[row.id,row.turn,JSON.stringify(delta)])
		counts[row.id]=counts.get(row.id,0)+1
		if delta.is_empty(): matched+=1
		else: mismatches.append({"id":row.id,"turn":row.turn,"differences":delta,"actual":actual,"expected":row.output})
	# A second pass retains the actual GD state across the full enemy sequence.
	# Only the same declared phase/taunt/down fixtures are imposed between turns.
	var chain=null; var continuous=0; var continuous_mismatches=[]
	for row in source.samples:
		if int(row.turn)==1: chain=setup(w,row)
		else:
			for a in chain.data.allies:
				if a.hp>0:
					chain._tick(a); chain.dungeon_enemy_r21.end_effects(a); a.remaining+=10000
			for i in range(1,5):
				var foe=chain.data.enemies[i]
				if foe.hp>0:
					chain._tick(foe); chain.dungeon_enemy_r21.end_effects(foe); foe.remaining+=10000
		var taunter=chain.data.allies[1]
		taunter.effects.erase("taunt")
		if int(row.turn)%6==0: taunter.effects.taunt={"turns":2,"amount":0}
		chain.data.allies[3].hp=0 if int(row.turn)==10 else 80000
		var actor=chain.data.enemies[0]
		if int(row.turn)==7 and chain.dungeon_enemy_r21.rules.foes[row.id].has("phase2"):
			actor.hp=int(floor(actor.mhp*.4)); chain.dungeon_enemy_r21.begin_random(chain.turn_count); chain.dungeon_enemy_r21.phase_check()
		if actor.charged and int(row.turn)%2==0: chain._break(actor,1e9)
		chain._tick(actor); chain.dungeon_enemy_r21.turn()
		var delta=differences(row.output,dump(chain))
		if int(chain.x(actor).get("source_rng",0))!=int(row.output_rng): delta.append("rng")
		check(delta.is_empty(),"continuous %s/%d %s"%[row.id,row.turn,JSON.stringify(delta)])
		if delta.is_empty(): continuous+=1
		else: continuous_mismatches.append({"id":row.id,"turn":row.turn,"differences":delta})
	for row in gear:
		check(w.dungeon_rules.quest_gear(int(row.seed),row.quest,row.classes)==row.codes,"elite gear "+str(row.seed)+row.quest.kind)
	var aliases={"warrior":{"guard2":"guard"},"paladin":{"shield":"pshield","taunt":"ptaunt"},"priest":{"pshield":"hshield"},"alchemist":{"defdn":"acid"},"chaos":{"wave":"chaoswave"}}
	for row in source.silence:
		var data=source.samples[0].duplicate(true); data.seed=row.seed; data.action_no=0
		var b=setup(w,data); var e=b.data.enemies[0]
		e.acts=[{"kind":"special","fx":"silence","name":"silence"}]; e.act_index=0
		for a in b.data.allies:
			a.class_id=row["class"]; a.skills={"attack":{},"personal":{}}
			for cls in w.config.classes:
				if cls.id==a.class_id:
					for sk in cls.skills:
						if sk.kind in ["기본","능동"]: a.skills[sk.id]=sk
		b.dungeon_enemy_r21.turn()
		var target=slot(b,int(row.target)); var skill=aliases.get(row["class"],{}).get(row.skill,row.skill)
		check(target.effects.has("silence") and b.x(target).get("silenced_id")==skill,"silence %s/%d"%[row["class"],row.seed])
	var result={"checks":checks,"failures":failures.size(),"enemies":counts.size(),"samples":source.samples.size(),"matched":matched,"continuous_matched":continuous,"continuous_mismatches":continuous_mismatches,"silence_samples":source.silence.size(),"gear_samples":gear.size(),"mismatches":mismatches,"coverage":counts}
	finish(result)
