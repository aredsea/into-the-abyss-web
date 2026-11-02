extends SceneTree
const World=preload("res://game/town_world_r21.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/town-r21/round7/recruit-oracle.json"))
	var w=World.new();var base=w.s.duplicate(true)
	check(w.config.companions.map(func(p):return p.id)==oracle.cast_order,"source CAST_ORDER")
	for row in oracle.rows:
		w.s=base.duplicate(true);w.s.gold=100000;w.s.recruits=row.recruits
		w.s.town_r21.seed=int(row.seed);w.s.town_r21.counter=int(row.n);w.s.persona_progress_r21.level=int(row.lv)
		w.s.owned=oracle.cast_order.filter(func(id):return id not in row.candidates)
		check(w.recruit(),"introduce")
		check(w.s.owned[-1]==row.id,"Lua exact candidate / random order")
		check(w.s.town_r21.counter==row.after_n and w.s.gold==100000-row.cost,"Lua RNG count / fee")
		var m=w.s.members[row.id]
		check(m.aff==row.aff and m.level==row.level and m.xp==row.xp,"Lua join / reset")
		check(w.s.npc_aff_r21.fenella==1,"NPC one successful action")
		check(w.s.owned.count(row.id)==1,"no duplicate")
	# Continuous RNG stream: four quest draws, recruit, then refreshed board, then recruit.
	w.s=base.duplicate(true);w.s.gold=100000
	check(w.s.town_r21.counter==4,"initial source board consumes four G_rnd calls")
	var counter=w.s.town_r21.counter;w.recruit();check(w.s.town_r21.counter==counter+1,"one introduction one draw")
	w.refresh_board();check(w.s.town_r21.counter==counter+5,"refresh shares guild draw counter")
	var copy=World.new();var saved=JSON.parse_string(JSON.stringify(w.s));var untouched=saved.duplicate(true)
	check(copy.restore(saved) and saved==untouched,"guild stream roundtrip / input untouched")
	w.recruit();copy.recruit();check(copy.s.owned==w.s.owned and copy.s.town_r21.counter==w.s.town_r21.counter,"continued source RNG after restore")
	w.s=base.duplicate(true);w.s.gold=99;var before=w.s.duplicate(true)
	check(not w.recruit() and w.s==before,"poor attempt consumes no draw")
	w.s=base.duplicate(true);w.s.owned=oracle.cast_order.duplicate();before=w.s.duplicate(true)
	check(not w.recruit() and w.s==before,"full roster consumes no draw")
	w.s=base.duplicate(true);w.depart_dungeon(1,123);before=w.s.duplicate(true)
	check(not w.recruit() and w.s==before,"expedition cannot recruit")
	w.s=base.duplicate(true);w.s.persona_progress_r21.level=17;w.s.members.hildegard.level=35;w.s.gold=10000
	w.recruit();check(w.s.members[w.s.owned[-1]].level==17,"persona level / party highest ignored")
	var legacy=base.duplicate(true);legacy.erase("persona_progress_r21");legacy.persona={"lv":23}
	check(w.restore(legacy) and w.s.persona_progress_r21.level==23,"existing persona level migration")
	legacy.erase("persona");check(w.restore(legacy) and w.s.persona_progress_r21.level==1,"absent source persona level defaults to one")
	w.s=base.duplicate(true);w.depart_dungeon(1,123);w.s.run.xp=101;w.settle("retreat")
	check(w.s.persona_progress_r21.level==2 and w.s.persona_progress_r21.xp==22,"off-field persona gets floor(101/2), source need(1)=28")
	before=w.s.duplicate(true);check(not w.settle("retreat") and w.s==before,"persona experience awarded once")
	var bad=w.s.duplicate(true);bad.persona_progress_r21.level=41;check(not w.restore(bad) and w.s==before,"invalid progress atomic rejection")
	FileAccess.open("res://../verification/town-r21/round7/recruit-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"lua":oracle.rows.size()},"  "))
	print("RECRUIT R21 CHECKS ",checks," FAILURES ",failures.size()," LUA ",oracle.rows.size());quit(0 if failures.is_empty() else 1)
