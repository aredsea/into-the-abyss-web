extends SceneTree
const R=preload("res://game/panels_rules_r22.gd")
const P=preload("res://ui/portrait_rules_r22.gd")
const State=preload("res://game/panels_state_r22.gd")
const World=preload("res://game/persona_world.gd")
const D=preload("res://game/dungeon_rules_r21.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func same(a: Dictionary,b: Dictionary,keys: Array) -> bool:
	for k in keys:
		if a.get(k)!=b.get(k):return false
	return true
func equivalent(a: Variant,b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):return is_equal_approx(a,b)
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for k in a:
			if not b.has(k) or not equivalent(a[k],b[k]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not equivalent(a[i],b[i]):return false
		return true
	return a==b
func decode(code: String,uid: int) -> Dictionary:
	var parts=code.split(".");var seed=0
	for c in parts[1]:seed=seed*36+"0123456789abcdefghijklmnopqrstuvwxyz".find(c)
	return {"id":parts[0],"seed":seed,"uid":uid,"forge":0,"tries":0,"source_r21":true,"code":code}
func source_world(g: Dictionary,codes: Array):
	var w=World.new();w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town";w.s.owned=g.roster.duplicate();w.s.party=g.party.duplicate();w.s.gold=g.gold
	w.s.persona.cls=g.persona.get("cls","");w.s.persona.lv=g.persona.get("lv",1);w.s.members.persona.level=w.s.persona.lv
	for id in g.roster:w.s.members[id].level=g.get("lvl",{}).get(id,1)
	w.s.gear=[];w.s.serial=0
	for code in codes:
		w.s.serial+=1;var e=decode(code,int(w.s.serial));e.erase("code");w.s.gear.append(e)
	if g.equip is Dictionary:
		for id in g.equip:
			for slot in g.equip[id]:
				var code=g.equip[id][slot]
				if code=="":continue
				w.s.serial+=1;var e=decode(code,int(w.s.serial));e.erase("code");w.s.gear.append(e);w.s.equipment[id][slot]=e.uid
	return w
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/panels-r22/oracle.json"))
	for f in oracle.lists:check(R.codex_list(f.owned,f.tab)==f.value,"source codex list "+f.tab+str(f.owned.size()))
	for f in oracle.stats:check(equivalent(R.companion_stats(f.id,int(f.level)),f.value),"source stats "+f.id+str(f.level))
	var stat_keys={"HP":"hp","MP":"mp","힘":"str","민첩":"agi","지능":"int","방어":"def","속도":"spd"}
	for f in oracle.persona:
		var actual=R.persona_stats(f.persona)
		for key in stat_keys:check(actual[stat_keys[key]]==f.value[key],"source persona "+f.persona.cls+str(f.persona.lv)+key)
	for f in oracle.aff:
		check(R.AFF.stage(f.a)==f.stage,"source affection stage "+str(f.a));check(R.shown_aff(f.a)==f.shown,"source affection display "+str(f.a))
	for f in oracle.portraits:check(P.pick(f.id,f.variant)==f.value,"source portrait "+f.id+":"+f.variant)
	check(P.pick("levia","smile",{}, {"levia_portrait_smile":true},false)=="","expression module off")
	check(P.pick("levia","smile",{}, {"levia_portrait_smile":true},true)=="levia_portrait_smile","expression module enabled")
	check(P.pick("levia","default",null,{},false,true)=="","source hidden scene contract")
	for id in R.DATA.order:
		check(P.resolve(id).path.begins_with("res://assets/portraits-r21"),"approved local default "+id)
		check(P.resolve(id,"smile").path==P.resolve(id).path,"missing local expression same person "+id)
	check(P.resolve("nobody").path=="" and P.resolve("persona").path=="","no unrelated fallback")
	for f in oracle.actions:
		var g=f.before.duplicate(true);R.cx_action(g,f.arg)
		check(equivalent(g.ui,f.value.ui),"source codex action ui "+f.arg);check(g.favs==f.value.favs,"source favorite "+f.arg)
	var w=World.new()
	for f in oracle.compare:
		var e=decode(f.code,1);e.forge=f.forge;var old=decode(f.old,2);var detail=preload("res://game/panel_gear_r22.gd").describe(w.gear,e,int(f.level))
		check(equivalent(detail.fx,f.fx),"source detail effects "+f.code+str(f.level)+str(f.forge))
		check(equivalent(detail.affix,f.affix),"source detail option groups "+f.code+str(f.level)+str(f.forge))
		var rows=R.comparison(w.gear.roll(old,int(f.level)),detail.fx)
		check(rows.size()==f.table.size(),"source comparison row count")
		for i in range(rows.size()):
			var delta=f.table[i][3];var unit=w.gear.rules.base.get(rows[i].key,w.gear.rules.affix.get(rows[i].key,{})).get("unit","")
			var parsed=0.0 if delta=="±0" else float(delta.trim_suffix(unit))
			check(is_equal_approx(rows[i].delta,parsed),"source rendered comparison delta "+rows[i].key)
	for f in oracle.bags:
		var entries=[]
		for i in range(f.codes.size()):entries.append(decode(f.codes[i],i+1))
		var list=R.bag_list(entries,w.gear.by_id,f.filter);check(list.map(func(e):return e.code)==f.value,"source 1030 gear list "+str(f.filter))
		var n=0;var gold=0
		for e in entries:
			if w.gear.by_id[e.id].rarity=="common":n+=1;gold+=w.gear.sell_price(e)
		check(n==f.common and gold==f.gold,"source bulk quote")
	for f in oracle.gear_actions:
		var native=source_world(f.before,f.bag);var st=State.new(native)
		if f.before.ui.get("bg") is Dictionary:st.bg=f.before.ui.bg.duplicate(true)
		st.bg_action(f.arg)
		var actual=st.entries().map(func(e):return e.code);var expected=f.after_bag.duplicate();actual.sort();expected.sort()
		check(actual==expected,"source bag transaction "+f.arg);check(native.s.gold==f.value.gold,"source transaction gold "+f.arg)
		check(same(st.bg,f.value.ui.bg,["pg","cls","slot","rar","sel","cmp","conf"]),"source bag action state "+f.arg)
		if f.value.equip is Dictionary:
			for id in f.value.equip:
				for slot in f.value.equip[id]:
					var entry=native.gear_entry(int(native.s.equipment[id].get(slot,0)))
					check(not entry.is_empty() and native.gear.code(entry)==f.value.equip[id][slot],"source equip "+id+slot)
	# Native contract: equipped gear never sells; changing gear preserves every UID.
	w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town";w.s.owned=["hildegard"];w.s.party=["hildegard"];w.s.persona.cls="전사";w.s.persona.lv=40;w.s.members.persona.level=40;w.s.members.hildegard.level=40
	w.s.gear=[decode("wa01.25.1",1),decode("wa11.25.1",2),decode("wa27.25.1",3)];w.s.serial=3
	for e in w.s.gear:e.erase("code")
	var state=State.new(w);var snapshot=w.s.duplicate(true)
	check(state.equip("persona",w.s.gear[0]),"persona equips without owned roster membership")
	var quote=state.bulk();check(quote.count==0,"equipped common excluded from bulk")
	state.bg_action("sellc");check(w.s.gear.size()==3,"bulk leaves worn and non-common items")
	check(state.equip("persona",w.s.gear[1]) and state.entries().any(func(e):return e.uid==1),"replaced gear returns to bag")
	check(state.unequip("persona","weapon"),"persona unequips")
	w.s.run={"phase":"battle"};var before=w.s.duplicate(true)
	check(not state.equip("persona",w.s.gear[0]),"battle gear change blocked");state.bg_action("sellc");check(w.s.gear==before.gear and w.s.gold==before.gold,"battle bulk cannot change inventory")
	w.s.run={};state.cx("sel_hildegard");state.cx("fav");state.bg_action("f_rar_epic")
	w._clamp_members()
	var save=w.s.duplicate(true);var restored=World.new();check(restored.restore(save),"schema 3 roundtrip new preferences and favorites");check(save==w.s,"restore leaves original save object intact")
	if restored.s.has("favs"):check(restored.s.favs==["hildegard"],"favorite persists")
	var disk=JSON.parse_string(JSON.stringify(save));var disk_world=World.new();check(disk_world.restore(disk),"JSON disk save restores")
	var preferences=State.new(disk_world);check(preferences.bg.rar=="epic","JSON filters persist")
	var legacy=preload("res://game/town_world_r21.gd").new();var old=legacy.s.duplicate(true);var migrated=World.new();check(migrated.restore(old),"schema 2 loads into P7");check(old==legacy.s,"legacy object unchanged")
	for count in [0,1,12,13,30,2000]:
		var items=[];items.resize(count)
		for pg in [-10,0,1,2,9999]:
			var result=R.page(items,pg);check(result.page>=1 and result.page<=result.pages and result.items.size()<=12,"page clamp")
	var cmp=R.comparison({"dmg":2.56,"hp":5},{"dmg":2.5,"crit":1.55})
	check(is_equal_approx(cmp[0].delta,-.1) and is_equal_approx(cmp[1].delta,1.6) and cmp[2].delta==-5,"signed comparison rounding and FX order")
	var result={"checks":checks,"failures":failures,"oracle_counts":{}}
	for key in oracle:result.oracle_counts[key]=oracle[key].size()
	FileAccess.open("res://../verification/panels-r22/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("PANELS R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
