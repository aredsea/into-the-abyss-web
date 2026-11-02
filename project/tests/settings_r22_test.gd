extends SceneTree
const L=preload("res://game/localization_r22.gd")
const J=preload("res://game/josa_r22.gd")
const R=preload("res://game/settings_rules_r22.gd")
const W=preload("res://game/settings_world_r22.gd")
const Base=preload("res://game/chronicle_world_r22.gd")
const Store=preload("res://game/settings_save_r22.gd")
const Battle=preload("res://game/battle_v3.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():create_timer(90).timeout.connect(func():quit(98));call_deferred("run")
func equivalent(a: Variant,b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):return is_equal_approx(a,b)
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for k in a:
			if not b.has(k) or not equivalent(a[k],b[k]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in a.size():
			if not equivalent(a[i],b[i]):return false
		return true
	return a==b
func fixture():
	var w=W.new();w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town";w.s.owned=["naran","marceline","teiris"];w.s.party=w.s.owned.duplicate();w.s.persona.cls="전사";w.s.persona.race="인간";w.s.persona.nation="경계도시";w.s.persona.name="당신";return w
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/settings-r22/oracle.json"))
	for row in oracle.josa:
		check(J.jong(row.word)==row.jong,"jong "+row.word)
		for key in row.tails:check(J.tail(row.word,key,row.lang)==row.tails[key],"josa "+row.word+" "+key+" "+row.lang)
	check(J.p(null,"이가")=="가" and J.p(null,"으로","en")=="","nil names match original")
	for row in oracle.u:check(L.u(row.src,row.vars,row.lang)==row.value,"B.U "+row.src+row.lang)
	for row in oracle.diff:check(R.difficulty({"settings":{"diff":row.input}})==row.value,"source difficulty "+str(row.input))
	for row in oracle.forms:
		var s={"gold":987,"settings":{"diff":2,"nsfw":1}};R.apply(s,row.data)
		for key in ["diff","lang","chron"]:check(s.settings.get(key)==row.settings.get(key),"form validation "+key+str(row.data))
		check(s.gold==row.gold and not s.settings.has("reset") and not s.settings.has("gold"),"form cannot reset/mint")
	for row in oracle.actions:
		# The native buttons and original op buttons share the allowed settings contract.
		# Reset/cancel scene transitions are exercised by the native pointer suite.
		var s={"settings":{"diff":2,"nsfw":1}};var parts=row.action.split("_")
		if parts.size()==2:R.apply(s,{parts[0]:parts[1]})
		for key in ["lang","diff","chron"]:check(s.settings.get(key)==row.settings.get(key),"source op settings "+row.action+" "+key)
	for key in L.DATA.ui:
		check(L.u(key,{},"en")==L.DATA.ui[key],"official UI pack "+key)
		check(L.u(key,{},"ko")==key,"Korean retained "+key)
	for key in L.DATA.words:check(L.t(key,"en")==L.DATA.words[key],"official words/scenarios "+key.left(50))
	check(L.render("미등록 native 문구","en")=="미등록 native 문구","no invented translation")
	check(L.render("저장 버전 12","en")==L.u("저장 버전 {n}",{"n":12},"en"),"template translation")
	check(L.u("{a:으로} 간다",{"a":"서울"})=="서울로 간다" and L.u("{a:이가} 왔다",{"a":"집"})=="집이 왔다","template uses shared josa")
	var w=fixture()
	for c in w.config.companions:check(c.name==L.DATA.display[c.id],"source display name "+c.id)
	for id in L.DATA.profiles:
		for line in L.DATA.profiles[id].lines:check(not line.begins_with(">") and not line.to_lower().contains("hidden truth") and not line.contains("비공개"),"public English profile "+id)
	# Difficulty scales unrounded source values once; summons share the same power.
	for diff in [1,2,3]:
		w=fixture();w.s.settings.diff=diff;check(w.depart_dungeon(1,1234),"depart difficulty")
		w.s.run.phase="battle";w.s.run.kind="battle";var data=w.battle_data();var multiplier=R.difficulty(w.s).hp
		var base=Base.new();base.s=w.s.duplicate(true);var expected=base.battle_data()
		check(is_equal_approx(data.enemy_power_r21,multiplier),"summon/phase power propagated")
		for i in data.enemies.size():
			var e=data.enemies[i];var plan=data.encounter_r21;var enc=plan.enc.duplicate(true);enc.fl[i]="apprentice_doll" if e.foe_id=="" else e.foe_id
			var def=w.dungeon_rules.foe_def(enc,i,int(plan.el));var stats=w.dungeon_rules.foe_stats(plan.enc,def,int(plan.el))
			check(e.mhp==maxi(1,int(floor(stats.hp*multiplier+.5))) and is_equal_approx(e.attack,stats.atk*multiplier),"unrounded source HP/attack")
			for key in ["defense","speed","gauge","weak","acts"]:check(e[key]==expected.enemies[i][key],"difficulty preserves "+key)
		var first=data.duplicate(true);w.s.settings.diff=3 if diff!=3 else 1
		check(w.battle_data()==first,"current battle difficulty locked / no cumulative scale")
		var b=Battle.new(data);var snapshot=b.snapshot();w.record_battle(snapshot);var saved=w.s.duplicate(true);var restored=W.new()
		check(restored.restore(JSON.parse_string(JSON.stringify(saved))),"settings running battle restore")
		if restored.s.run.has("id"):
			var again=restored.battle_data()
			check(equivalent(again,first),"battle scale survives save/load")
		# Existing enemy adapter is used unchanged for reserved/summoned and second phases.
		var adapter=preload("res://game/dungeon_enemy_r21.gd").new(b);var e=b.data.enemies[0];adapter.configure(e,e.foe_id,1,0)
		check(is_equal_approx(e.attack,data.enemies[0].attack) and e.mhp==data.enemies[0].mhp,"runtime enemy configuration has same difficulty")
		w.s.run.battle={};w.s.run.step+=1
		check(w.battle_multiplier()==R.difficulty(w.s).hp,"next battle uses changed setting")
	# Old actual saves are read-only inputs; missing settings are normal/Korean.
	var specimens=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy-specimens.json"))
	for spec in specimens:
		var input=JSON.parse_string(FileAccess.get_file_as_string(spec.path));var before=input.duplicate(true);var restored=W.new()
		check(restored.restore(input) and input==before,"legacy immutable "+spec.path)
		check(L.language(restored.s)=="ko" and R.difficulty(restored.s).hp==1,"legacy default settings")
	w=fixture();w.s.gold=987;R.apply(w.s,{"lang":"en","diff":"3","chron":"0"});var store=Store.new("user://p8-rules-save.json")
	check(store.write(w.s)==OK,"settings save")
	var restored=W.new();var loaded=store.read_into(restored);check(loaded and equivalent(restored.s.settings,w.s.settings),"settings persist")
	var before=w.s.duplicate(true);var disk=FileAccess.get_file_as_bytes(store.path);var fresh=store.reset_world(w)
	check(fresh!=null and fresh.s.gold==300 and not fresh.s.creation_r22.complete and fresh.s.owned.is_empty(),"reset enters creation with source defaults")
	check(w.s==before,"reset does not mutate old in-memory model")
	check(JSON.parse_string(FileAccess.get_file_as_string(store.archive_path)).gold==987,"archived pre-reset memory")
	check(FileAccess.get_file_as_bytes(store.archive_path.trim_suffix(".json")+".disk")==disk,"old disk bytes archived")
	var broken=Store.new("res://missing-p8-directory/save.json");check(broken.reset_world(w)==null and w.s==before,"failed archive cannot reset")
	var roundtrip=W.new();check(store.read_into(roundtrip) and roundtrip.s.gold==300,"reset persists fresh slot")
	var bad=roundtrip.s.duplicate(true);bad.settings=[];check(not roundtrip.restore(bad),"bad settings rejected")
	FileAccess.open("res://../verification/settings-r22/results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("SETTINGS R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
