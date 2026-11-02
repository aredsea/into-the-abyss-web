extends SceneTree
const World=preload("res://game/town_world_r21.gd")
const Commerce=preload("res://game/commerce_rules_r21.gd")
const Legacy=preload("res://game/gear_rules.gd")
var checks=0
var failures=[]
var matches=0
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		failures.append(msg)
		if failures.size()<=12:push_error(msg)
func _initialize():call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/town-r21/round3/commerce-oracle.json"))
	if not oracle is Dictionary:push_error("run commerce oracle first");quit(1);return
	var gear=Commerce.new();var old=Legacy.new()
	for row in oracle.stock:
		var got=gear.stock_source(row.seed,row.day,row.cls,row.slot);var ok=got.size()==row.rows.size()
		for i in range(mini(got.size(),row.rows.size())):ok=ok and got[i].code==row.rows[i].code and got[i].id==row.rows[i].id and got[i].price==row.rows[i].price
		check(ok,"Lua daily stock "+str(row));matches+=int(ok)
	for row in oracle.process:
		var got=gear.process_source(row.seed,row.n,row.classes,row.level);var ok=got.get("code","")==row.code
		check(ok,"Lua process "+str(row));matches+=int(ok)
	for row in oracle.forge:
		var e={"id":row.id,"seed":row.gear_seed,"forge":row.forge,"tries":row.tries}
		var ok=gear.forge_result(row.seed,e)==row.success and gear.forge_cost(e)==row.cost
		check(ok,"Lua forge "+str(row));matches+=int(ok)
	for row in oracle.roll:
		var e={"id":row.id,"seed":row.seed,"forge":row.forge,"tries":0,"source_r21":true};var got=gear.roll(e,row.level)
		var ok=got.size()==row.value.size()
		for key in row.value:ok=ok and is_equal_approx(got.get(key,-9999),row.value[key])
		check(ok,"Lua equipment options "+str(row));matches+=int(ok)
		e.erase("source_r21");check(gear.roll(e,row.level)==old.roll(e,row.level),"old saved roll preserved "+row.id)
	var w=World.new();w.s.gold=100000
	var row=w.shop_stock("hildegard","weapon")[0];var cost=w.price({"price":row.price})
	var rng=w.s.rng
	check(w.buy_gear(row.code,"hildegard") and w.s.gold==100000-cost,"source stock purchase")
	check(w.s.gear[-1].source_r21 and w.s.gear[-1].seed==row.seed,"source seed retained")
	var state=w.s.duplicate(true)
	check(not w.buy_gear(row.code,"hildegard") and w.s==state,"same-day sold-out rejection atomic")
	check(w.s.rng==rng,"source shop does not consume legacy RNG")
	var copy=World.new();var encoded=JSON.parse_string(JSON.stringify(w.s));var roundtrip=copy.restore(encoded)
	# Godot JSON decodes numbers as floats; compare to the encoded save, not Variant integer types.
	check(roundtrip and copy.s==encoded and int(copy.s.gear[-1].seed)==int(row.seed),"new stock ledger save roundtrip")
	w.s.day+=1;check(not w.stock_sold(row.code),"new day replenishes stock")
	check(w.process_gear("hildegard") and w.s.commerce_r21.process_n==1,"process counter committed with item")
	var prior=w.s.duplicate(true);var expected=w.gear.process_source(w.s.town_r21.seed,2,w.s.owned.map(func(id):return w.class_def(id).id),w.highest_level())
	check(w.process_gear("hildegard") and w.gear.code(w.s.gear[-1])==expected.code,"next source process result")
	var restored=World.new();check(restored.restore(prior) and restored.process_gear("hildegard") and restored.s==w.s,"reload cannot reroll processing")
	var entry=w.s.gear[-1];var expected_forge=w.gear.forge_result(w.s.town_r21.seed,entry);var lv=entry.forge;var tries=entry.tries;var gold=w.s.gold
	check(w.forge(entry.uid) and entry.tries==tries+1 and entry.forge==lv+int(expected_forge) and w.s.gold==gold-w.gear.forge_cost({"id":entry.id,"forge":lv}),"live forge equals source result")
	var legacy=w.s.duplicate(true);legacy.erase("commerce_r21");var unchanged=legacy.duplicate(true);var migration=World.new()
	check(migration.restore(legacy) and legacy==unchanged,"old save migrates without changing caller")
	check(migration.s.gear==legacy.gear and migration.s.equipment==legacy.equipment and migration.s.rng==legacy.rng,"migration preserves equipment and RNG")
	var bad=w.s.duplicate(true);bad.commerce_r21.process_n=-1;var before=migration.s.duplicate(true)
	check(not migration.restore(bad) and migration.s==before,"bad source ledger rejected atomically")
	w.s.gold=0;before=w.s.duplicate(true);check(not w.process_gear("hildegard") and w.s==before,"insufficient processing funds atomic")
	var report={"checks":checks,"failures":failures,"lua_samples":oracle.stock.size()+oracle.process.size()+oracle.forge.size()+oracle.roll.size(),"lua_matches":matches,"legacy_rolls":oracle.roll.size()}
	FileAccess.open("res://../verification/town-r21/round3/commerce-results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("TOWN COMMERCE R21 CHECKS ",checks," FAILURES ",failures.size()," LUA ",matches," / ",report.lua_samples)
	quit(0 if failures.is_empty() else 1)
