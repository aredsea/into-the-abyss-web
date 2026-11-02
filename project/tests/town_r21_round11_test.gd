extends SceneTree
const W=preload("res://game/settings_world_r22.gd")
const Store=preload("res://game/settings_save_r22.gd")
const Cloud=preload("res://game/cloud_store_r22.gd")
const C=preload("res://game/chronicle_store_r22.gd")
const L=preload("res://game/localization_r22.gd")
var checks=0
var failures=[]
var samples={}
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():create_timer(100).timeout.connect(func():quit(98));call_deferred("run")
func same(a,b) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for k in a:
			if not b.has(k) or not same(a[k],b[k]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in a.size():
			if not same(a[i],b[i]):return false
		return true
	return a==b
func save_sample(w,key: String):
	var raw=JSON.stringify(w.s);var v=JSON.parse_string(raw);var copy=W.new()
	var untouched=JSON.stringify(v)
	check(copy.restore(v),"integrated native restore "+key)
	check(JSON.stringify(v)==untouched,"input immutable "+key)
	check(same(copy.s,v),"idempotent native save "+key)
	samples[key]=v
func win(w):
	var b=w.ModernBattle.new(w.battle_data())
	# Controlled terminal snapshot uses the production battle serializer/validator.
	for e in b.data.enemies:e.hp=0;e.gauge=0
	b.result="victory";w.record_battle(b.snapshot())
	check(w.finish_battle(),"production finish_battle accepts terminal snapshot")
func run():
	check(L.render("추천 1층","en")=="추천 1층","numeric floor template preserves unmatched source wording")
	check(L.render("1층","en")=="Floor 1","numeric floor template retains exact source English")
	var w=W.new();save_sample(w,"new")
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:check(w.create_action(arg),"create "+arg)
	check(w.create_action("pick_teiris","sc"),"first meeting choice");check(w.create_action("go","sc"),"first meeting committed")
	check(C.entries(w.s).filter(func(x):return x.contains("First met")).size()==1,"one first meeting fact")
	check(w.begin_dialogue("teiris") and w.choose_dialogue("c1"),"dialogue choice committed");save_sample(w,"dialogue")
	check(w.close_dialogue(),"dialogue closes")
	# Native integration fixture supplies funds; all costs and rewards use shipped rules.
	w.s.gold=10000;check(w.recruit(),"guild recruitment")
	check(C.entries(w.s).filter(func(x):return x.contains("guild introduction")).size()==1,"one guild recruitment fact")
	w.s.favs=["teiris"];w.s.panels_r22={"tab":"rec","sel":"teiris","page":1,"msg":"","panel":"status","bg":{"pg":1,"cls":"warrior","slot":"weapon","rar":"fine","sel":"","cmp":"","conf":""}}
	w.s.settings={"lang":"en","diff":3,"chron":1};w.s.place="town"
	check(w.depart_dungeon(1,117),"integrated P5 departure");save_sample(w,"entry")
	w.dismiss_dialogue_queue();var before=w.s.persona.duplicate(true)
	for step in range(5):
		check(w.advance(),"exploration step "+str(step+1))
		if w.s.run.phase=="battle":
			var b=w.ModernBattle.new(w.battle_data());w.record_battle(b.snapshot());save_sample(w,"battle_"+str(step+1));win(w)
		w.dismiss_dialogue_queue()
		check(w.s.persona==before,"P5 defers XP until settlement")
	check(w.s.run.phase=="rest" and w.s.run.step==5,"five explorations then rest");save_sample(w,"rest")
	check(w.final_battle(),"boss starts once");check(not w.final_battle(),"boss duplicate start rejected")
	win(w);w.dismiss_dialogue_queue();save_sample(w,"clear")
	check(w.s.persona.lv>before.lv,"P1 settlement experience")
	check(C.entries(w.s).filter(func(x):return x.contains("Leveled up:")).size()==1,"nested XP grants one level-up fact")
	check(C.entries(w.s).filter(func(x):return x.contains("Cleared Great Dungeon")).size()==1,"one P10 clear fact")
	var paid=JSON.stringify(w.s);check(not w.settle("clear") and not w.finish_battle() and JSON.stringify(w.s)==paid,"duplicate settlement has no effect")
	check(w.next_dungeon_floor() and not w.next_dungeon_floor(),"next floor once");save_sample(w,"next_floor")
	check(C.entries(w.s).filter(func(x):return x.contains("descended directly")).size()==1,"one P10 descent fact")
	w.dismiss_dialogue_queue();check(w.settle("retreat"),"return from next floor");w.dismiss_dialogue_queue();w.chronicle_home()
	check(w.facility_route("shop") and w.buy("hp_s"),"P6 shop transaction")
	check(w.facility_route("town") and not w.receipt.is_empty() and w.acknowledge_receipt(),"P6 shop receipt")
	check(w.facility_route("smithy") and w.process_gear(),"P6 processing")
	check(not w.facility_route("town"),"P6 unfinished smithy locks departure")
	check(w.complete_smithy() and w.acknowledge_receipt() and w.facility_route("town"),"P6 smithy receipt releases route")
	w.s.gold=100000;check(w.forge(int(w.s.gear[0].uid)),"P6 shared-code refinement")
	w.s.items.level_scroll=1;check(w.use_item("level_scroll","persona"),"P6 persona scroll")
	check(not w.s.has("lv") and not w.s.has("persona_progress_r21"),"one canonical growth authority")
	save_sample(w,"facilities")
	var store=Store.new("user://round11/cloud.json");DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://round11"))
	check(store.write(w.s)==OK,"integrated disk save")
	var cloud=Cloud.new();cloud.model=w;cloud.storage=store;root.add_child(cloud);cloud.config.server_url="http://127.0.0.1:8787";cloud.account={"code":"","pin":"","rev":0,"auto":false,"synced":false}
	await cloud.create_account();check(cloud.account.rev==1 and cloud.can_upload(),"integrated local D1 account")
	await cloud.upload();check(cloud.account.rev==2,"integrated local D1 upload")
	var gold=w.s.gold;w.s.gold=1;await cloud.download();check(w.s.gold==gold and cloud.account.rev==2,"integrated local D1 download uses complete model")
	check(w.s.favs==["teiris"] and w.s.commerce_r21.has("forge_codes_r22") and w.s.settings.lang=="en","download retains P6 P7 P8")
	cloud.queue_free()
	var count=0
	for spec in JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy-specimens.json")):
		var raw=FileAccess.get_file_as_string(spec.path);var value=JSON.parse_string(raw);var legacy=W.new()
		check(legacy.restore(value) and JSON.stringify(value)==JSON.stringify(JSON.parse_string(raw)),"legacy input intact")
		value.persona_progress_r21={"level":17,"xp":2};value.persona={"lv":25,"exp":3,"name":"Archived"}
		check(legacy.restore(value) and legacy.s.persona.lv==17 and legacy.s.persona_migration_r21.persona.lv==25,"legacy D authority archive")
		legacy.s.favs=legacy.s.owned.slice(0,3);legacy.s.settings={"lang":"en","diff":2,"chron":1};C.add(legacy.s,"Integrated legacy confirmed.")
		save_sample(legacy,"legacy_%02d"%count);count+=1
	check(count==11,"all 11 actual legacy specimens")
	var combined=W.new();check(combined.restore(samples.legacy_00),"archived legacy combined fixture")
	combined.s.panels_r22=w.s.panels_r22.duplicate(true);combined.s.gold=100000
	check(combined.process_gear() and combined.forge(int(combined.s.gear[-1].uid)),"legacy P6 processing and refinement")
	check(combined.depart_dungeon(1,117),"legacy commander enters real P5 run")
	save_sample(combined,"merged_legacy_expedition")
	FileAccess.open("res://../verification/town-r21/round11/save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify(samples,"  "))
	FileAccess.open("res://../verification/town-r21/round11/integration-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"legacy_specimens":count,"samples":samples.keys()},"  "))
	print("TOWN ROUND11 CHECKS ",checks," FAILURES ",failures.size()," LEGACY ",count," SAMPLES ",samples.size());quit(0 if failures.is_empty() else 1)
