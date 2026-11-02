extends SceneTree
const L=preload("res://game/localization_r22.gd")
const R=preload("res://game/panels_rules_r22.gd")
const Rules=preload("res://game/persona_rules.gd")
const Places=preload("res://game/town_places_r22.gd")
var checks=0
var failures=[]
var groups={}
func _initialize():
	create_timer(60).timeout.connect(func():push_error("Remaining UI rules watchdog expired");quit(98));call_deferred("run")
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
	if (a is Array and a.is_empty() and b is Dictionary and b.is_empty()) or (b is Array and b.is_empty() and a is Dictionary and a.is_empty()):return true
	if (a is int or a is float) and (b is int or b is float):return a==b
	return a==b if typeof(a)==typeof(b) else false
func dict(v) -> Dictionary:return v if v is Dictionary else {}
func check(ok: bool,group: String,detail=""):
	checks+=1
	if not groups.has(group):groups[group]={"checks":0,"failures":0}
	groups[group].checks+=1
	if not ok:
		groups[group].failures+=1;failures.append(group+" "+str(detail))
		if failures.size()<=20:print("DIFF ",group," ",detail)
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/phase2/oracle.json"))
	var rules=Rules.new();var locale=L.new();var panels=R.new()
	for f in o.create:
		var g=f.before.duplicate(true)
		if locale.has_method("configure_packs"):rules.call("create_action",g,f.arg,"cr",f.lang)
		else:rules.create_action(g,f.arg)
		check(same(g,f.value),"P2446.create",JSON.stringify({"lang":f.lang,"arg":f.arg,"before":f.before,"actual":g,"expected":f.value}))
	var configured=locale.has_method("configure_packs")
	if configured:
		for f in o.pack:
			locale.call("configure_packs",{"en":f.raw},f.raw)
			var first=locale.call("ui_pack","en");var words=locale.call("en_dict")
			locale.call("change_raw_pack","en","{\"replacement\":\"later\"}","{\"replacement\":\"later\"}")
			check(same(first,f.first) and same(locale.call("ui_pack","en"),f.second) and same(locale.call("ui_pack","fr"),f.unknown),"P0089.ui_pack",f.raw)
			check(same(words,f.words) and same(locale.call("en_dict"),f.words2),"P0092.en_dict",f.raw)
		locale.call("configure_packs")
	else:
		check(false,"P0089.ui_pack","missing cache contract");check(false,"P0092.en_dict","missing cache contract")
	for f in o.u:
		if f.has("pack"):
			if not configured:check(false,"P0090.P0091.u","missing supplied pack");continue
			locale.call("configure_packs",{"en":f.pack})
		var actual=L.u(f.input,dict(f.get("vars")),f.lang)
		check(actual==f.value,"P0090.P0091.u",JSON.stringify(f)+" actual="+actual)
		if configured and f.has("pack"):locale.call("configure_packs")
	for f in o.t:
		if not f.input is String and not configured:check(false,"P0095.t","non-string");continue
		check(same(L.t(f.input,f.lang),f.value),"P0095.t",JSON.stringify(f))
	for f in o.hd:
		var g=f.before.duplicate(true)
		if panels.has_method("hud_action"):panels.call("hud_action",g,f.arg)
		check(same(g,f.value),"P0110.hd",JSON.stringify(f))
	for f in o.st:
		var g=f.before.duplicate(true)
		if panels.has_method("status_action"):panels.call("status_action",g,f.arg)
		check(same(g,f.value),"P2611.st",JSON.stringify(f))
	for f in o.cx:
		var g=f.before.duplicate(true);panels.call("cx_action",g,f.arg,f.lang) if configured else R.cx_action(g,f.arg)
		check(same(g,f.value),"P2539.cx",JSON.stringify(f)+" actual="+JSON.stringify(g))
	for f in o.mname:
		check(panels.call("member_name",f.input,f.id,f.lang)==f.value if panels.has_method("member_name") else false,"P2572.mname",JSON.stringify(f))
	for f in o.syn:
		check(rules.call("syn_text",f.entry,f.lang)==f.get("value") if rules.has_method("syn_text") else false,"P2415.syn_text",JSON.stringify(f))
	for f in o.escape:check(R.escape(f.get("input"))==f.value,"P0102.esc",JSON.stringify(f))
	for f in o.places:check(Places.label(f.input,f.lang,f.enabled)==f.value,"P3731.place_label",JSON.stringify(f))
	var recap_path="res://game/cloud_recap_r23.gd"
	if FileAccess.file_exists(recap_path):
		var journey=load(recap_path)
		for f in o.recap:
			var actual=journey.recap(f.input)
			check(actual==f.value,"P2721.P2722.P2723.recap",JSON.stringify({"input":f.input,"actual":actual,"expected":f.value}))
	else:check(false,"P2721.P2722.P2723.recap","missing recap generator")
	FileAccess.open("res://../verification/parity-r23/phase2/results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"groups":groups},"\t"))
	print("UI REMAINING R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
