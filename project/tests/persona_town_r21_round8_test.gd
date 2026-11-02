extends SceneTree
const World=preload("res://game/persona_world.gd")
const Legacy=preload("res://game/town_world_r21.gd")
const Store=preload("res://game/world_store.gd")
var checks=0
var failures=[]
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
func run():
	var w=World.new();var copy=World.new();var old=Legacy.new()
	check(not w.s.has("persona_progress_r21"),"new state has one progression")
	# Both conflict directions: writer identity determines authority, not max.
	for pl in range(1,41):
		for prior in [1,20,40]:
			var saved=old.s.duplicate(true);saved.persona={"lv":prior,"exp":0,"extra":"keep"};saved.persona_progress_r21={"level":pl,"xp":0}
			var raw=JSON.stringify(saved)
			check(copy.restore(saved),"r21 migration %d/%d"%[pl,prior])
			check(copy.s.persona.lv==pl and copy.s.persona.exp==0 and copy.s.persona.extra=="keep","r21 writer wins")
			check(copy.s.persona_migration_r21.persona==saved.persona and copy.s.persona_migration_r21.progress==saved.persona_progress_r21,"conflict archived exactly")
			check(not copy.s.has("persona_progress_r21") and JSON.stringify(saved)==raw,"no shadow or input mutation")
			var canonical=copy.s.duplicate(true);canonical.persona_progress_r21={"level":prior,"xp":0}
			check(w.restore(canonical) and w.s.persona.lv==pl,"P1 writer wins")
			check(not w.s.has("persona_progress_r21") and w.s.persona_migration_r21_.progress.level==prior,"P1 shadow archived, not summed")
			check(copy.restore(JSON.parse_string(JSON.stringify(w.s))) and eq(copy.s,w.s),"repeat migration idempotent")
			check(copy.restore(JSON.parse_string(JSON.stringify(saved))) and copy.s.persona.lv==pl,"JSON-number schema authority")
	w=World.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:check(w.create_action(arg),"create "+arg)
	check(w.create_action("pick_teiris","sc") and w.create_action("go","sc"),"first meeting")
	check(w.s.members.teiris.aff==0 and w.s.members.teiris.level==w.s.persona.lv,"first companion zero affection and persona level")
	check(w.begin_dialogue("teiris") and w.choose_dialogue("c1"),"first inn dialogue")
	check(w.s.members.teiris.aff!=0 and w.s.acts.teiris_talk==w.s.day,"dialogue hook persists")
	check(copy.restore(JSON.parse_string(JSON.stringify(w.s))) and eq(copy.s.dialogue_r21,w.s.dialogue_r21),"dialogue reload under schema3")
	# Fix the introduction draw for the controlled engine fixture. The Web
	# smoke separately exercises random introductions with unmodified combat.
	var candidates=w.config.companions.filter(func(p):return p.id not in w.s.owned)
	for seed in range(1,1000):
		if candidates[int(floor(w.Guild.random(seed,5)*candidates.size()))].id=="bargut":w.s.town_r21.seed=seed;w.s.town_r21.counter=4;break
	check(w.close_dialogue() and w.recruit(),"dialogue then recruitment")
	var recruited=w.s.owned[-1]
	check(w.s.members[recruited].level==w.s.persona.lv and w.s.members[recruited].xp==0,"recruit canonical level")
	check(w.toggle_companion(recruited) and w.depart_dungeon(1,7),"new party departs")
	w.dismiss_dialogue_queue();w.s.run.phase="battle"
	var bd=w.battle_data()
	# Controlled native engine victory; source rules and combat files stay read-only.
	for ally in bd.allies:ally.base[ally.line]=1e12
	var battle=World.ModernBattle.new(bd);var turns=0
	while battle.result.is_empty() and turns<1500:
		if battle.player_turn() and not battle.ally(battle.current_id).charging:battle.choose_enemy(battle.living(false)[0].id);battle.act("attack")
		else:battle.automatic_turn()
		turns+=1
	w.record_battle(battle.snapshot());check(battle.result=="victory" and w.finish_battle(),"full flow battle victory")
	var paid={"lv":w.s.persona.lv,"exp":w.s.persona.exp};check(paid.lv>1,"full flow level up")
	check(w.settle("retreat") and w.s.persona.lv==paid.lv and w.s.persona.exp==paid.exp,"return does not double XP")
	check(not w.s.has("persona_progress_r21"),"settlement never recreates shadow")
	w.dismiss_dialogue_queue();w.s.gold=10000;check(w.recruit() and w.s.members[w.s.owned[-1]].level==w.s.persona.lv,"post-level-up recruitment")
	check(copy.restore(JSON.parse_string(JSON.stringify(w.s))),"completed full flow roundtrip")
	for xp in [1,27,28,55,56,101,1000]:
		var legacy=old.s.duplicate(true);check(copy.restore(legacy),"legacy commander restore")
		var retained=copy.s.duplicate(true);check(not copy.set_fight(1) and copy.s==retained,"legacy without class cannot create invalid combat input")
		check(copy.depart_dungeon(1,11),"commander departure")
		copy.s.run.xp=xp;var expected=copy.persona_rules.give(1,0,int(xp/2))
		check(copy.settle("retreat") and copy.s.persona.lv==expected.level and copy.s.persona.exp==expected.xp,"commander floor half XP %d"%xp)
		var once=copy.s.duplicate(true);check(not copy.settle("retreat") and once==copy.s,"duplicate settlement rejected")
		# Old expeditions have no P1 snapshots: preserve them and award at return.
		old=Legacy.new();old.depart_dungeon(1,12);old.s.run.xp=xp
		check(copy.restore(old.s) and copy.settle("retreat"),"active old expedition migration")
		check(copy.s.persona.lv==expected.level and copy.s.persona.exp==expected.xp,"old commander gets canonical XP")
		old=Legacy.new()
	# Storage paths are fixture-only. Reading old data cannot rewrite it.
	var folder="user://round8-storage";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var v1=Store.new(folder+"/world_v1.json");var v3=Store.new(folder+"/world_v3.json")
	check(v1.write(old.s)==OK,"legacy fixture write")
	var original=FileAccess.get_file_as_string(v1.path)
	check(v1.read_into(copy) and FileAccess.get_file_as_string(v1.path)==original,"legacy read leaves bytes unchanged")
	check(v3.write(copy.s)==OK and v3.read_into(w),"new path roundtrip")
	check(FileAccess.get_file_as_string(v1.path)==original,"new write preserves v1")
	var invalid=w.s.duplicate(true);invalid.persona_progress_r21={"level":41,"xp":0};var before=w.s.duplicate(true)
	check(not w.restore(invalid) and w.s==before,"invalid migration atomic")
	invalid=w.s.duplicate(true);invalid.persona=7;invalid.persona_progress_r21={"level":1,"xp":0}
	check(not w.restore(invalid) and w.s==before,"invalid persona with shadow rejected atomically")
	var web_fixture=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/town-r21/round8/web-legacy-v1.json"))
	check(copy.restore(web_fixture),"same legacy fixture as IndexedDB")
	check(copy.s.persona.lv==17 and copy.s.persona.exp==2,"IndexedDB fixture canonical progress")
	FileAccess.open("res://../verification/town-r21/round8/integration-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("PERSONA TOWN ROUND8 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
