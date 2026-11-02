extends SceneTree
const W=preload("res://game/chronicle_world_r22.gd")
const C=preload("res://game/chronicle_store_r22.gd")
const P=preload("res://game/panels_state_r22.gd")
const Store=preload("res://game/chronicle_save_r22.gd")
var checks=0
var failures=[]
var dialogue_cases=0
var legacy_cases=0
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func eq(a,b) -> bool:
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
func fresh():
	var w=W.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:check(w.create_action(arg),"create "+arg)
	check(w.create_action("pick_teiris","sc") and w.create_action("go","sc"),"first meet")
	return w
func run():
	var w=fresh();var original=w.s.duplicate(true)
	check(C.entries(w.s).size()==1,"first meeting one fact")
	w.create_action("go","sc");check(C.entries(w.s).size()==1,"repeat first meeting no fact")
	for id in ["hildegard","marceline","teiris"]:
		for a in [-100,-60,-59,-20,-19,0,19,20,49,50,79,80,99,100,149,150,200]:
			for choice in ["c1","c2","c3"]:
				w=W.new();check(w.restore(original),"dialogue seed restore")
				if id not in w.s.owned:w.s.owned.append(id)
				w.s.members[id].aff=a;w.s.chronicle_r22={"list":[],"queue":[]}
				check(w.begin_dialogue(id),"dialogue begins")
				var pending=w.s.duplicate(true);var copy=W.new()
				check(copy.restore(JSON.parse_string(JSON.stringify(pending))) and eq(copy.s.dialogue_r21,pending.dialogue_r21),"pending migration roundtrip")
				check(not copy.choose_dialogue("invalid") and eq(copy.s,pending),"invalid choice atomic")
				check(copy.choose_dialogue(choice),"choice commits")
				var after=copy.s.members[id].aff;var expected=0 if C.Aff.stage(a)==C.Aff.stage(after) else 1
				var lines=C.entries(copy.s)
				check(lines.size()==expected,"exactly one changed-stage fact / no same-stage fact")
				if expected:check(lines[0].contains("rose" if after>a else "fell"),"stage direction")
				var committed=copy.s.duplicate(true)
				check(not copy.choose_dialogue(choice) and eq(copy.s,committed),"no duplicate choice state or facts")
				check(w.restore(JSON.parse_string(JSON.stringify(copy.s))) and C.entries(w.s)==lines,"committed response reload")
				check(w.close_dialogue() and C.entries(w.s)==lines,"dismiss does not repeat fact")
				dialogue_cases+=1
	# All real historical specimens carry P7/P10 and D migration fields together.
	var folder="user://round9-storage";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for spec in JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy-specimens.json")):
		var value=JSON.parse_string(FileAccess.get_file_as_string(spec.path));var raw=JSON.stringify(value)
		w=W.new();check(w.restore(value) and JSON.stringify(value)==raw,"historical specimen immutable")
		check(w.s.log==value.log and not w.s.has("chronicle_r22"),"historical log / no retrospective facts")
		var old=value.duplicate(true);old.persona_progress_r21={"level":17,"xp":2};old.persona={"lv":25,"exp":3,"name":"보존"}
		old.favs=w.s.owned.slice(0,3);old.panels_r22={"tab":"rec","sel":old.favs[0] if not old.favs.is_empty() else "","page":2,"msg":"keep","panel":"status","bg":{"pg":2,"cls":"warrior","slot":"weapon","rar":"legend","sel":"","cmp":"","conf":""}}
		C.add(old,"Historical fixture confirmed.");var untouched=old.duplicate(true)
		check(w.restore(JSON.parse_string(JSON.stringify(old))) and eq(old,untouched),"combined extension migration")
		check(w.s.persona.lv==17 and w.s.persona.exp==2 and w.s.persona_migration_r21.persona.lv==25,"D authority and archive")
		check(eq(w.s.favs,old.favs) and eq(w.s.panels_r22,old.panels_r22) and eq(w.s.chronicle_r22,old.chronicle_r22),"all extension fields preserved")
		var panel=P.new(w);check(eq(panel.favs(),old.favs) and panel.ui.page==2 and panel.bg.pg==2,"panel facade reads combined JSON")
		var canonical=w.s.duplicate(true);var copy=W.new()
		check(copy.restore(JSON.parse_string(JSON.stringify(canonical))) and eq(copy.s,canonical),"combined migration idempotent")
		var v1=preload("res://game/world_store.gd").new(folder+"/v1-%d.json"%legacy_cases)
		var v3=Store.new(folder+"/v3-%d.json"%legacy_cases)
		check(v1.write(old)==OK,"fixture historical write")
		var bytes=FileAccess.get_file_as_bytes(v1.path)
		check(v1.read_into(copy) and FileAccess.get_file_as_bytes(v1.path)==bytes,"read preserves historical bytes")
		check(v3.write(copy.s)==OK and copy.s.chronicle_r22.queue.is_empty(),"combined atomic flush")
		check(v3.read_into(w) and eq(w.s.favs,old.favs) and eq(w.s.panels_r22,old.panels_r22) and C.entries(w.s)==C.entries(old),"combined disk reload")
		check(FileAccess.get_file_as_bytes(v1.path)==bytes,"v3 write preserves historical save")
		legacy_cases+=1
	check(legacy_cases==11,"eleven real legacy specimens")
	# Observe the actual P1 battle award nested inside the P10 facade.
	w=fresh();w.s.chronicle_r22={"list":[],"queue":[]}
	# Fixture starts one XP before the source level threshold; rewards stay intact.
	w.s.persona.exp=w.need(1)-1;w.s.members.persona.xp=w.s.persona.exp
	check(w.depart_dungeon(1,7),"P1 expedition")
	w.dismiss_dialogue_queue();w.s.run.phase="battle"
	var bd=w.battle_data()
	for ally in bd.allies:ally.base[ally.line]=1e12
	var battle=W.ModernBattle.new(bd);var turns=0
	while battle.result.is_empty() and turns<1500:
		if battle.player_turn() and not battle.ally(battle.current_id).charging:battle.choose_enemy(battle.living(false)[0].id);battle.act("attack")
		else:battle.automatic_turn()
		turns+=1
	w.record_battle(battle.snapshot());check(battle.result=="victory" and w.finish_battle(),"actual finish battle facade")
	var level_lines=C.entries(w.s).filter(func(x):return x.contains("Leveled up:"))
	check(w.s.persona.lv>1 and level_lines.size()==1,"nested persona/companion level award one fact")
	var paid=w.s.persona.duplicate(true)
	check(w.settle("retreat") and w.s.persona==paid,"settlement does not award P1 XP again")
	check(C.entries(w.s).filter(func(x):return x.contains("Leveled up:")).size()==1,"settlement does not repeat level fact")
	check(C.entries(w.s).filter(func(x):return x.contains("Retreated from")).size()==1,"one retreat fact")
	var facts=C.entries(w.s);check(not w.settle("retreat") and C.entries(w.s)==facts,"repeat settlement no facts")
	w.dismiss_dialogue_queue();w.s.gold=10000;check(w.recruit(),"post-growth recruitment")
	check(w.s.members[w.s.owned[-1]].level==paid.lv,"recruit reads canonical growth")
	check(C.entries(w.s).filter(func(x):return x.contains("guild introduction")).size()==1,"one recruit fact")
	FileAccess.open("res://../verification/town-r21/round9/integration-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"dialogue_cases":dialogue_cases,"legacy_specimens":legacy_cases},"  "))
	print("TOWN ROUND9 CHECKS ",checks," FAILURES ",failures.size()," DIALOGUE ",dialogue_cases," LEGACY ",legacy_cases);quit(0 if failures.is_empty() else 1)
