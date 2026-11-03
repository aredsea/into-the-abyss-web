extends SceneTree
var checks=0
var failures=[]
var groups={}
func check(ok: bool,id: String,detail: Variant):
	checks+=1
	if not groups.has(id):groups[id]={"checks":0,"failures":0}
	groups[id].checks+=1
	if not ok:groups[id].failures+=1;failures.append({"id":id,"detail":detail})
func _initialize():
	create_timer(60).timeout.connect(func():quit(98));call_deferred("run")
func same(a,b) -> bool:
	if (a is Dictionary or a is Array) and (b is Dictionary or b is Array):
		if a.is_empty() and b.is_empty():return true
	return a==b if typeof(a)==typeof(b) else false
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase3/ui-oracle.json"))
	var path="res://game/ui_semantics_r23.gd"
	var presenter=load(path).new() if FileAccess.file_exists(path) else null
	for f in oracle.cases:
		var actual=presenter.observe(f.fn,f.args,f.lang) if presenter else null
		if presenter and f.fn=="gear_icon":check(ResourceLoader.exists(presenter.icon_path(f.args[0])),"P2513.resource",f.args[0].id)
		checks+=1
		for id in f.id.split(" "):
			if not groups.has(id):groups[id]={"checks":0,"failures":0}
			groups[id].checks+=1
			if actual!=f.expected:groups[id].failures+=1
		if actual!=f.expected:
			failures.append({"id":f.id,"fn":f.fn,"lang":f.lang,"args":f.args,"expected":f.expected,"actual":actual})
	if presenter:
		var world=preload("res://game/persona_world.gd").new()
		var adapter=preload("res://game/panel_gear_r22.gd")
		for f in oracle.cases:
			if f.fn!="gear_fx" or f.args[0].get("seed")==null:continue
			var r=f.args[0];var entry={"id":r.item.id,"seed":int(r.seed),"forge":0,"tries":0,"uid":1,"source_r21":true}
			var d=adapter.describe(world.gear,entry,-1);var it=d.item
			var actual=presenter.observe("gear_fx",[{"item":it,"fx":d.fx,"affix":d.affix,"unique":it.get("sig",it.get("unique",{}))}],f.lang)
			check(actual==f.expected,"P2512.native-adapter",{"item":it.id,"lang":f.lang,"actual":actual,"expected":f.expected})
		world.s.persona.cls="전사";world.s.persona.lv=40;world.s.members.persona.level=40;world.s.gear=[];world.s.equipment={}
		for i in world.gear.catalog.items.size():world.s.gear.append({"id":world.gear.catalog.items[i].id,"seed":101+i,"forge":0,"tries":0,"uid":i+1,"source_r21":true})
		for f in oracle.battle_preview:
			world.s.run={} if f.scene=="town" else {"phase":"battle"}
			var state=preload("res://game/panels_state_r22.gd").new(world)
			check(state.candidates("persona","weapon").map(func(e):return e.id)==f.ids,"P2528.battle-preview",f.scene)
	var getter=preload("res://game/ui_json_r23.gd")
	var file="user://ui-phase3-json-getter.json"
	for f in oracle.host:
		var value
		if f.get("throws",false):value=getter.read_table("user://ui-phase3-missing-dir/no.json")
		else:
			var output=FileAccess.open(file,FileAccess.WRITE);output.store_string(f.raw);output.close();value=getter.read_table(file)
		var expected=f.value if not f.value is bool else null
		check(same(value,expected),"P3816",f);check(same(value,expected),"P3817",f)
	DirAccess.remove_absolute(file)
	var out={"checks":checks,"failures":failures,"groups":groups}
	FileAccess.open("res://../verification/parity-r23/ui-phase3/ui-semantics-results.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print("UI SEMANTICS R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
