extends SceneTree
const Rules=preload("res://game/persona_rules.gd")
const World=preload("res://game/persona_world.gd")
const Legacy=preload("res://game/town_world_r21.gd")
const Store=preload("res://game/world_store.gd")
var checks=0
var failures=[]
var folder="res://../verification/persona-r22"
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func map_empty(v):
	if v is Array:return {} if v.is_empty() else v.map(map_empty)
	if v is Dictionary:
		var out={}
		for k in v:out[k]=map_empty(v[k])
		return out
	return v
func eq(a,b) -> bool:
	if a is Array and a.is_empty() and b is Dictionary and b.is_empty():return true
	if b is Array and b.is_empty() and a is Dictionary and a.is_empty():return true
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for k in a:
			if not b.has(k) or not eq(a[k],b[k]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not eq(a[i],b[i]):return false
		return true
	return a==b
func preserves(saved,original) -> bool:
	if original is Dictionary:
		if not saved is Dictionary:return false
		for key in original:
			if not saved.has(key) or not preserves(saved[key],original[key]):return false
		return true
	return eq(saved,original)
func _initialize():call_deferred("run")
func run():
	var rules=Rules.new();var fixture=JSON.parse_string(FileAccess.get_file_as_string(folder+"/oracle.json"))
	for f in fixture.actions:
		var g=f.before.duplicate(true);g.ui={"page":g.page,"sel":g.sel};g.erase("page");g.erase("sel")
		if g.persona.stats is Array:g.persona.stats={}
		rules.create_action(g,f.arg,f.kind)
		g.page=g.ui.page;g.sel=g.ui.sel;g.erase("ui")
		check(eq(g,f.value),"Lua create "+str(checks)+" "+f.kind+" "+f.arg)
	for f in fixture.totals:
		var p={"cls":"사제","bonus":{"str":23,"agi":22,"int":21,"def":20,"spd":19}}
		check(rules.set_total(p,int(f.input),true)==f.cut and eq(p,f.value) and rules.cap(rules.total(p))==f.cap,"Lua total "+str(f.input))
	for f in fixture.levels:
		var result=rules.give(int(f.lv),int(f.xp),0)
		check(result.level==f.value.lv and result.xp==f.value.exp and rules.need(int(f.lv))==f.need,"Lua levels "+str(f.lv)+"/"+str(f.xp))
	var valid=Legacy.new().config.companions.map(func(c):return c.id)
	for f in fixture.party:check(eq(rules.clean(f.party,f.roster,int(f.fight),valid),f.clean),"Lua clean "+str(checks))
	for f in fixture.awards:
		var g=f.before.duplicate(true);g.lvl={};g.exp={}
		var gains=rules.award(g,{"exp":f.xp,"pm":f.pm,"sid":7})
		check(eq(gains,f.gains) and eq(g.persona,f.value.persona) and eq(g.lvl,f.value.lvl) and eq(g.exp,f.value.exp),"Lua award "+str(checks))
		check(rules.award(g,{"exp":f.xp,"pm":f.pm,"sid":7}).is_empty(),"duplicate award")
	for f in fixture.bonus:
		var w=World.new();w.s.persona.cls=f.cls;w.s.persona.bonus={"str":f.b,"agi":f.b,"int":f.b,"def":f.b,"spd":f.b};w.s.persona.stats=rules.calc(w.s.persona)
		var result=w.stats("persona",int(f.lv));var c=w.class_def("persona");var main={"힘":"str","민첩":"agi","지능":"int"}[c.line]
		check(eq(w.s.persona.stats,f.calc) and is_equal_approx(result[main],f.unit.cs) and is_equal_approx(result.agi,f.unit.ag) and floor(result.spd+.5)==f.unit.sp and result.hp==f.unit.hp and result.mp==f.unit.mp,"Lua combat bonus "+f.cls+"/"+str(f.lv)+"/"+str(f.b))
	for f in fixture.migration:check(f.value.scene==f.scene and f.value.persona.fight==1,"source legacy observation "+f.scene)
	var w=World.new();check(w.s.gold==300 and w.s.owned.is_empty() and w.s.party.is_empty() and w.s.scene=="create","native new source state")
	var copy=World.new();check(copy.restore(JSON.parse_string(JSON.stringify(w.s))),"incomplete creation save reload")
	for arg in ["race_beast","lin_cat","nat_border","cls_archer","tot_20","auto","done"]:w.create_action(arg)
	check(w.s.scene=="scenario","creation completes")
	w.create_action("pick_teiris","sc");w.create_action("go","sc")
	check(w.s.owned==["teiris"] and w.s.party==["teiris"] and w.s.gold==300 and w.s.members.teiris.aff==0 and w.s.creation_r22.complete,"first companion and gold")
	var once=w.s.duplicate(true);check(not w.create_action("go","sc") and eq(once,w.s),"first meeting idempotent")
	check(copy.restore(JSON.parse_string(JSON.stringify(w.s))),"completed creation save reload")
	w.s.owned=["levia","teiris","naran","marceline"];w.set_fight(0)
	for id in w.s.owned:
		if id not in w.s.party:w.toggle_companion(id)
	check(w.s.party.size()==4 and w.sortie_ids().size()==4,"commander four companions")
	w.set_fight(1);check(w.s.party.size()==3 and w.sortie_ids()[0]=="persona","persona drops tail companion")
	check(w.depart_dungeon(1,7),"variable party departure")
	w.s.run.phase="battle"
	var bd=w.battle_data();check(bd.allies.map(func(a):return a.id)==w.sortie_ids(),"battle order persona then companions")
	check(copy.restore(JSON.parse_string(JSON.stringify(w.s))),"active expedition reload")
	var b=World.ModernBattle.new(bd);w.record_battle(b.snapshot())
	check(copy.restore(JSON.parse_string(JSON.stringify(w.s))),"active persona battle reload")
	var roundtrip=World.ModernBattle.new(copy.battle_data());var resumed=roundtrip.restore(copy.s.run.battle);check(resumed,"persona battle snapshot resumes")
	# Controlled victory exercises facade settlement without changing combat files.
	for a in bd.allies:a.base[a.line]=1e12
	b=World.ModernBattle.new(bd);var turns=0
	while b.result.is_empty() and turns<1500:
		if b.player_turn() and not b.ally(b.current_id).charging:b.choose_enemy(b.living(false)[0].id);b.act("attack")
		else:b.automatic_turn()
		turns+=1
	w.record_battle(b.snapshot());check(b.result=="victory" and w.finish_battle(),"persona combat facade finishes")
	check(w.s.run.persona_xp_paid>0 and w.s.persona.lv>1 or w.s.persona.exp>0,"persona gets XP immediately after battle")
	w.s.members.persona.hp=1;w.s.members.persona.mp=0;w.enter_dungeon_rest();var hp=w.s.members.persona.hp
	w.enter_dungeon_rest();check(w.s.members.persona.hp==hp and hp>1,"persona rest heals only once")
	var awarded={"lv":w.s.persona.lv,"exp":w.s.persona.exp}
	check(w.settle("retreat") and w.s.persona.lv==awarded.lv and w.s.persona.exp==awarded.exp,"return never repays battle XP")
	check(not w.settle("retreat"),"duplicate return rejected")
	var original=Legacy.new().s;original.extra_p1={"unknown":[1,2,3],"text":"무손실"}
	check(copy.restore(original),"legacy r21 restore")
	for key in original:
		if key in ["members","equipment","research"]:
			for id in original[key]:check(eq(copy.s[key][id],original[key][id]),"legacy preserved "+key+"/"+id)
		else:check(eq(copy.s[key],original[key]) if key!="schema" else copy.s.schema==3,"legacy preserved "+key)
	check(copy.s.persona.fight==0 and copy.s.creation_r22.complete and copy.s.scene=="town","legacy command no creation")
	var overflow=Legacy.new().s;overflow.members.hildegard.xp=500
	check(copy.restore(overflow) and copy.s.members.hildegard.level==rules.give(1,500,0).level and copy.s.experience_before_r22[0].xp==500 and overflow.members.hildegard.xp==500,"old XP overflow settles and archives raw fields without editing input")
	# Test every checked-in save specimen without writing to its source path.
	var specimens=JSON.parse_string(FileAccess.get_file_as_string(folder+"/legacy-specimens.json"))
	for spec in specimens:
		var snap=JSON.parse_string(FileAccess.get_file_as_string(spec.path));var legacy=Legacy.new();var acceptable=legacy.restore(snap)
		check(copy.restore(snap)==acceptable,"historical specimen "+spec.path)
		if acceptable:
			for key in snap:
				if key!="schema":check(preserves(copy.s[key],snap[key]),"historical field "+spec.path+"/"+key)
	var store=Store.new("user://persona-r22-test.json");check(store.write(w.s)==OK and store.read_into(copy),"isolated store round trip")
	var corrupt=w.s.duplicate(true);corrupt.party=["missing"];var untouched=copy.s.duplicate(true)
	check(not copy.restore(corrupt) and eq(copy.s,untouched),"invalid restore atomic")
	for key in ["run","members","ui","scene","persona"]:
		corrupt=w.s.duplicate(true);corrupt.erase(key)
		check(not copy.restore(corrupt) and eq(copy.s,untouched),"missing field rejected atomically "+key)
	var result={"checks":checks,"failures":failures,"oracle_counts":{},"legacy_specimens":specimens.size()}
	for key in fixture:result.oracle_counts[key]=fixture[key].size()
	FileAccess.open(folder+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("PERSONA R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
