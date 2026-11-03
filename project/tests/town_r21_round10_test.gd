extends SceneTree
const W=preload("res://game/settings_world_r22.gd")
const Store=preload("res://game/settings_save_r22.gd")
const C=preload("res://game/chronicle_store_r22.gd")
const L=preload("res://game/localization_r22.gd")
var checks=0
var failures=[]
var legacy=0
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():create_timer(60).timeout.connect(func():quit(98));call_deferred("run")
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
func run():
	var folder="user://round10-reset";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for spec in JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy-specimens.json")):
		var old=JSON.parse_string(FileAccess.get_file_as_string(spec.path));var w=W.new()
		check(w.restore(old),"historical input restores")
		old.persona_progress_r21={"level":17,"xp":2};old.persona={"lv":25,"exp":3,"name":"保管"}
		old.favs=w.s.owned.slice(0,3);old.panels_r22={"tab":"rec","sel":"","page":2,"msg":"keep","panel":"status","bg":{"pg":2,"cls":"warrior","slot":"weapon","rar":"legend","sel":"","cmp":"","conf":""}}
		old.chronicle_r22={"list":["Day 1: Historical fixture confirmed."],"queue":["Day 2: Pending fixture confirmed."]}
		check(w.restore(old),"combined legacy restores")
		check(w.s.schema==3 and w.s.persona.lv==17 and w.s.persona_migration_r21.persona.lv==25,"D migration authority")
		var store=Store.new(folder+"/save-%d.json"%legacy)
		check(store.write(w.s)==OK,"initial canonical disk")
		w.s.settings={"lang":"en","diff":3,"chron":1};w.s.gold+=17
		check(store.write(w.s)==OK,"second generation with backup")
		C.add(w.s,"Pending reset fact.")
		var expected=w.s.duplicate(true);C.flush(expected)
		var before=w.s.duplicate(true);var disk=FileAccess.get_file_as_bytes(store.path);var backup=FileAccess.get_file_as_bytes(store.path+".bak")
		var fresh=store.reset_world(w)
		check(fresh!=null and fresh.s.gold==300 and fresh.s.owned.is_empty(),"reset source defaults")
		check(same(w.s,before),"old memory immutable")
		var archive=JSON.parse_string(FileAccess.get_file_as_string(store.archive_path))
		check(same(archive,expected),"archive entire flushed memory, no omitted fields")
		for key in ["schema","persona","persona_migration_r21","favs","panels_r22","chronicle_r22","settings"]:check(same(archive[key],expected[key]),"archive extension "+key)
		check(FileAccess.get_file_as_bytes(store.archive_path.trim_suffix(".json")+".disk")==disk,"archive current disk exact bytes")
		check(FileAccess.get_file_as_bytes(store.archive_path.trim_suffix(".json")+".disk.bak")==backup,"archive backup exact bytes")
		var restored=W.new();check(restored.restore(archive) and same(restored.s,expected),"archive manually restorable")
		legacy+=1
	# Source names reach the model, P7 cast, dialogue lookup and P10 conversion.
	var w=W.new()
	check(L.render("힐데가르트 · 베렝가 · 바르구트")=="힐데가 · 베렌가 · 바르굿","historical labels canonical without save mutation")
	check(L.render("힐데가르트","en")=="Hildegard" and C.english("베렝가")=="Berenga","historical names use canonical English")
	for text in ["알 수 없는 표시값","새 단어","추가"]:check(L.render(text,"en")==text,"bare-variable template cannot translate unknown label "+text)
	for entry in [["개요","Overview"],["원정","Explore"],["기술","Skills"],["마을","Town"]]:check(L.render(entry[0],"en")==entry[1],"native navigation has an explicit translation "+entry[0])
	for entry in [["hildegard","힐데가","Hildegard"],["berenga","베렌가","Berenga"],["bargut","바르굿","Bargut"]]:
		check(w.person(entry[0]).name==entry[1],"canonical model name")
		check(preload("res://data/panels-r22.json").data.cast[entry[0]].name==entry[1],"canonical panels name")
		check(L.t(entry[1],"en")==entry[2] and C.english(entry[1])==entry[2],"source English same everywhere")
		C.add(w.s,entry[1]+preload("res://game/josa_r22.gd").tail(entry[1],"이가")+" 첫 만남, 동료로 함께하게 되었다")
		check(C.entries(w.s)[-1].contains(entry[2]),"chronicle translated canonical name")
	check(legacy==11,"all historical specimens archived")
	FileAccess.open("res://../verification/town-r21/round10/integration-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"legacy_specimens":legacy},"  "))
	print("TOWN ROUND10 CHECKS ",checks," FAILURES ",failures.size()," LEGACY ",legacy);quit(0 if failures.is_empty() else 1)
