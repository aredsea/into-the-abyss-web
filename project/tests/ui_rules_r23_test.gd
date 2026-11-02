extends SceneTree
const R=preload("res://game/panels_rules_r22.gd")
const P=preload("res://ui/portrait_rules_r22.gd")
const L=preload("res://game/localization_r22.gd")
const Research=preload("res://game/persona_research_r21.gd")
const Rules=preload("res://game/persona_rules.gd")
const State=preload("res://game/panels_state_r22.gd")
const World=preload("res://game/persona_world.gd")
const Chronicle=preload("res://game/chronicle_store_r22.gd")
const Places=preload("res://game/town_places_r22.gd")
const Effects=preload("res://game/panel_gear_r22.gd")
const Cloud=preload("res://game/cloud_legacy_r23.gd")
var checks=0
var failures=[]
var groups={}
func _initialize():
	create_timer(60).timeout.connect(func():push_error("UI rules watchdog expired");quit(98));call_deferred("run")
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
	# Lua's JSON harness serializes an empty table as an object.
	if (a is Array and a.is_empty() and b is Dictionary and b.is_empty()) or (b is Array and b.is_empty() and a is Dictionary and a.is_empty()):return true
	if (a is int or a is float) and (b is int or b is float):return is_equal_approx(a,b)
	return a==b if typeof(a)==typeof(b) else false
func check(ok: bool,group: String,detail: String="") -> void:
	checks+=1
	if not groups.has(group):groups[group]={"checks":0,"failures":0}
	groups[group].checks+=1
	if not ok:
		groups[group].failures+=1;failures.append(group+" "+detail)
		if failures.size()<=30:push_error(group+" "+detail)
func decode(code: String,uid: int) -> Dictionary:
	var parts=code.split(".");var seed=0
	for c in parts[1]:seed=seed*36+"0123456789abcdefghijklmnopqrstuvwxyz".find(c)
	return {"id":parts[0],"seed":seed,"uid":uid,"forge":0,"tries":0,"source_r21":true}
func dict(value) -> Dictionary:return value if value is Dictionary else {}
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-oracle.json"));var rules=Rules.new()
	for f in o.prepare:
		var p=dict(f.input).duplicate(true);rules.prepare(p);check(same(p,f.value),"P2394.prepare",JSON.stringify({"input":f.input,"actual":p,"expected":f.value}))
	for f in o.view:check(same(rules.view({"persona":dict(f.input)}),f.value),"P2392.view",JSON.stringify(f))
	for f in o.scenarios:check(same(rules.scenarios(f.input),f.value),"P2390.P2391.scens",JSON.stringify(f))
	for f in o.cx:
		var g=f.before.duplicate(true);R.cx_action(g,f.arg)
		check(same(g.ui,f.value.ui) and same(g.favs,f.value.favs),"P2539.cx",f.arg+" "+JSON.stringify(g.ui)+" / "+JSON.stringify(f.value.ui))
	for f in o.portraits:check(P.pick(f.id,f.variant,dict(f.have),dict(f.expr),f.enabled,f.hidden)==f.value,"P3720.pick",JSON.stringify(f))
	for f in o.portraits:
		check(P.asset_name(f.id,f.variant)==f.name,"P3719.name")
		check(P.has_asset(f.name,dict(f.have),dict(f.expr),f.enabled)==f.has,"P3718.has")
	for f in o.u:check(L.u(f.input,dict(f.vars),f.lang)==f.value,"P0090.u",JSON.stringify(f)+" actual="+L.u(f.input,dict(f.vars),f.lang))
	for f in o.numbers:
		var input=f.input_bits.hex_decode().decode_double(0) if f.has("input_bits") else f.input
		check(R.fnum(input)==f.fnum,"P2507.fnum",str(input)+" actual="+R.fnum(input)+" expected="+f.fnum)
		check(R.num(input)==f.num,"P2493.num",str(input))
	for f in o.first:check(R.first(f.input)==f.value,"P2495.first",f.input)
	for f in o.slots:check(R.slot_ok(f.input)==f.value,"P2505.slot_ok",f.input)
	for f in o.has:check((f.input in f.list)==f.value,"P0103.has")
	for f in o.levels:
		var g=f.input.duplicate(true)
		for key in ["persona","lvl"]:g[key]=dict(g[key])
		check(R.level(g,f.cid)==f.value,"P2484.lv",JSON.stringify(f))
	for f in o.aff_values:check(R.shown_aff(f.input)==f.value,"P2487.aff")
	for f in o.memory:
		check(Chronicle.enabled(dict(f.input),"chron")==f.on,"P3813.mem_on")
		check(Chronicle.cut(f.text,int(f.n))==f.cut,"P3814.mem_cut")
		check(Chronicle.length(f.text)==f.len,"P3815.mem_len")
	for f in o.memory_bytes:
		var bytes=f.hex.hex_decode()
		check(Chronicle.cut(bytes,int(f.n)).hex_encode()==f.value,"P3814.mem_cut_bytes",JSON.stringify(f))
		check(Chronicle.length(bytes)==f.len,"P3815.mem_len_bytes",JSON.stringify(f))
	for f in o.places:check(Places.label(f.input,f.lang)==f.value,"P3731.place_label",JSON.stringify(f))
	var w=World.new();var initial=w.s.duplicate(true)
	for f in o.member_classes:check(R.member_class(f.input,f.cid)==f.value,"P2573.mcls",JSON.stringify(f))
	for f in o.members:
		w.s=initial.duplicate(true);w.s.persona.cls=f.input.persona.cls;w.s.owned=f.input.roster if f.input.roster is Array else [];w.s.party=f.input.party if f.input.party is Array else []
		check(same(State.new(w).members(f.cls),f.value),"P2582.P2583.members",JSON.stringify(f))
	for f in o.fx:
		check(same(Effects.effect_def(w.gear,f.key),f.definition),"P2508.fx_def",f.key)
		check(Effects.effect_name(w.gear,f.key,f.cls)==f.name,"P2510.fx_name",f.key+f.cls)
		check(Effects.effect_value(w.gear,f.key,f.input)==f.value,"P2509.fx_val",JSON.stringify(f))
	for f in o.items:
		w.s=initial.duplicate(true);w.s.owned=[] if f.cid=="persona" else [f.cid] if R.DATA.cast.has(f.cid) else []
		w.s.persona.cls=f.cls;w.s.persona.lv=f.lv;w.s.members.persona.level=f.lv
		if w.s.members.has(f.cid):w.s.members[f.cid].level=f.lv
		w.s.gear=[]
		for i in o.item_bag.size():w.s.gear.append(decode(o.item_bag[i],i+1))
		var st=State.new(w);var actual=st.candidates(f.cid,f.slot).map(func(e):return w.gear.code(e))
		check(same(actual,f.value),"P2503.items_for",f.cid+" "+f.cls+" "+str(f.lv)+" "+f.slot)
	for f in o.bg:
		var actual=R.normalize_bg(f.input);var expected=dict(f.value)
		check(same(actual,expected),"P2571.bgs",JSON.stringify(f))
	for f in o.cloud.crypto:
		var bytes=f.input.to_utf8_buffer();var key=f.key.to_utf8_buffer()
		check(Cloud.hex(Cloud.sha256(bytes))==f.sha,"P2703.sha256")
		check(Cloud.hex(Cloud.hmac(key,bytes))==f.hmac,"P2704.hmac",str(bytes.size())+" / key="+str(key.size()))
		check(Cloud.hex(bytes)==f.hex,"P2705.P2706.hex")
		check(Cloud.b64(bytes)==f.b64,"P2708.b64")
	for f in o.cloud.codes:check(Cloud.code(f.input)==f.value,"P2714.code",f.input)
	for f in o.cloud.bounded:check(Cloud.bounded(f.input,0,10,null if f.get("nil_default",false) else 2)==f.get("value"),"P2715.bounded",str(f.input))
	for f in o.cloud.enabled:check(Cloud.enabled({"HOST":f.host,"KEY_X":f.key})==f.value,"P2700.enabled")
	check(Cloud.hex(Cloud.decode_key({"KEY_X":[22,27,30],"KEY_M":[125,126,103]}))==o.cloud.key,"P2699.key")
	var binary=o.cloud.binary.hex.hex_decode()
	check(Cloud.hex(binary)==o.cloud.binary.hex,"P2705.P2706.hex_all_bytes")
	check(Cloud.hex(Cloud.sha256(binary))==o.cloud.binary.sha,"P2703.sha_binary")
	check(Cloud.hex(Cloud.hmac(binary,binary))==o.cloud.binary.hmac,"P2704.hmac_binary")
	check(Cloud.b64(binary)==o.cloud.binary.b64,"P2708.b64_binary")
	for f in o.cloud.links:check(Cloud.signed_link({"HOST":f.host,"KEY_X":[22,27,30],"KEY_M":[125,126,103]},f.payload)==f.value,"P2713.link_assembly")
	for f in o.rank:check(Cloud.rank_due(f.cache,int(f.now))==f.requested,"P2740.rank_cooldown",JSON.stringify(f))
	for f in o.rank_headers:check((Cloud.rank_percent(dict(f.cache),int(f.best))!=null)==f.show,"P2737.rank_percent",JSON.stringify(f))
	var result={"checks":checks,"failures":failures,"groups":groups}
	var suffix="baseline" if "baseline" in OS.get_cmdline_user_args() else "results"
	FileAccess.open("res://../verification/parity-r23/ui-"+suffix+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("UI R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
