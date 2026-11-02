extends SceneTree
const Base=preload("res://tests/expedition_r22_test.gd")
const World=preload("res://game/expedition_world_r22.gd")
var checks=0
var failures=[]
var groups={}
func check(ok: bool,label: String,group: String):
	checks+=1
	if not groups.has(group):groups[group]={"checks":0,"failures":0}
	groups[group].checks+=1
	if not ok:
		failures.append(label);groups[group].failures+=1
		if failures.size()<20:push_error(label)
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
	if (a is int or a is float) and (b is int or b is float):return absf(a-b)<.000001
	return a==b
func _initialize():call_deferred("run")
func run():
	var helper=Base.new();var w=helper.ready_world()
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-oracle.json"))
	for row in oracle.sortie:
		w=helper.ready_world();w.s.owned=row.roster.duplicate();w.s.party=row.party.duplicate();w.s.persona.fight=int(row.fight);w.s.persona.lv=10;w.s.members.persona.level=10
		for id in row.levels:w.s.members[id].level=int(row.levels[id])
		check(same(w.sortie_candidates(row.filter),row.ordered),"candidate order "+str([row.fight,row.party,row.filter,row.levels]),"sortie_order")
		check(w.sortie_filter(row.filter)==row.normalized,"filter fallback "+row.filter,"sortie_filter")
		if w.has_method("sortie_summary"):
			check(same(w.sortie_summary(20),row.summary),"soft sortie warnings "+str(row.summary),"sortie_summary")
			for sample in row.summaries:
				check(same(w.sortie_summary(int(sample.enemy)),sample.value),"warning boundary "+str(sample),"sortie_summary")
		else:check(false,"sortie summary missing","sortie_summary")
	for row in oracle.floors:
		w.s.dungeon_r21.best=row.best;w.s.dungeon_r21.cleared_bosses=row.cleared
		check(w.dungeon_max()==row.max,"max "+str(row),"floor_access")
		for a in row.allowed:check(w.dungeon_allowed(int(a.floor))==a.value,"allowed "+str(a),"floor_access")
	for row in oracle.get("floor_view",[]):
		check(same(w.dungeon_floor_view(int(row.floor),float(row.avg)),row.value),"floor view "+str([row.floor,row.avg]),"floor_view")
	for row in oracle.new_run:
		w=helper.ready_world();w.s.owned=["lynette","marceline","urda"];w.s.party=row.party.duplicate();w.s.persona.lv=int(row.level);w.s.persona.race=row.race
		for id in w.sortie_ids():w.s.members[id].level=int(row.level)
		w.depart_dungeon(1,int(row.seed))
		var actual={"hp":[],"mp":[],"mhp":[],"mmp":[],"step":w.s.run.step,"phase":w.s.run.phase,"ask":w.s.run.ask,"elites":w.s.run.elites,"wins":w.s.run.wins}
		for id in w.expedition_ids():
			actual.hp.append(w.s.members[id].hp);actual.mp.append(w.s.members[id].mp);actual.mhp.append(w.s.run.maxima[id].hp);actual.mmp.append(w.s.run.maxima[id].mp)
		for key in ["hp","mp","mhp","mmp"]:
			while actual[key].size()<4:actual[key].append(0)
		check(same(actual,row.value),"initial source vitals "+str([row.n,row.level,row.race,actual,row.value]),"initial_vitals")
		w.s.run.phase="battle"
		var b=w.ModernBattle.new(w.battle_data());var first={"hp":[],"mp":[],"mhp":[],"mmp":[]}
		for a in b.data.allies:
			for key in first:first[key].append(a[key])
		for key in first:
			while first[key].size()<4:first[key].append(0)
		check(same(first,row.first),"first battle full resources "+str([row.n,row.level,row.race,first,row.first]),"first_battle")
	for row in oracle.use:
		w=helper.ready_world();w.s.owned=["lynette"];w.s.party=["lynette"];w.s.persona.nation=row.nat
		w.s.persona.lv=int(row.level);w.s.members.persona.level=int(row.level);w.s.members.lynette.level=int(row.level)
		w.depart_dungeon(1,1);w.s.run.persona_pm=row.input.pm.duplicate(true)
		var key=w.web_item_id(row.id);var m=w.s.members.persona
		m.hp=row.input.hp;m.mp=row.input.mp;w.s.run.maxima.persona={"hp":row.input.mhp,"mp":row.input.mmp}
		w.s.items[key]=int(row.input.bank);w.s.run.loot_items[row.id]=int(row.input.pouch)
		w.use_item(key,"persona")
		var actual={"hp":m.hp,"mp":m.mp,"bank":w.s.items[key],"pouch":w.s.run.loot_items.get(row.id,0)}
		check(same(actual,row.value),"outside use "+str([row.level,row.nat,row.id,row.state,actual,row.value]),"outside_use")
	for row in oracle.boss:
		w=helper.ready_world();w.depart_dungeon(1,1);w.s.run.phase=row.phase;w.s.run.ask=row.ask
		w.s.run.rested=row.phase=="rest"
		var started=w.final_battle()
		check(same({"phase":w.s.run.phase,"ask":w.s.run.ask,"started":started},row.value),"boss phase/ask "+str(row),"boss_guard")
	for row in oracle.logs:
		w=helper.ready_world();w.depart_dungeon(1,1)
		for i in int(row.n):w.append_expedition_log("line "+str(i+1))
		check(same(w.s.run.log,row.value),"bounded log "+str(row.n),"log")
	for row in oracle.snapshot:
		if row.alive==1 and row.hp<=0:continue # Native life state is derived from HP.
		w=helper.ready_world();w.s.party=[];w.depart_dungeon(1,1);w.s.run.phase="battle"
		var b=w.ModernBattle.new(w.battle_data());var a=b.ally("persona")
		a.hp=row.hp if row.alive==1 else 0;a.mp=20.9;a.mhp=101.9;a.mmp=71.9
		w.snapshot_expedition_party(b)
		var actual={"hp":w.s.members.persona.hp,"mp":w.s.members.persona.mp,"mhp":w.s.run.maxima.persona.hp,"mmp":w.s.run.maxima.persona.mp,"fell":w.s.run.fell}
		var expected={"hp":row.value.hp[0],"mp":row.value.mp[0],"mhp":row.value.mhp[0],"mmp":row.value.mmp[0],"fell":row.value.fell}
		check(same(actual,expected),"carry snapshot rounding "+str([row.alive,row.hp,actual,expected]),"snapshot")
	for row in oracle.bank:
		w=helper.ready_world();w.s.items.hp_s=5
		var ids=w.bank_expedition_items(row.input)
		var items={}
		for id in row.items:items[id]=w.s.items.get(w.web_item_id(id),0)
		check(same(items,row.items) and same(ids,row.list),"bank positive items sorted "+str(row.input),"bank_items")
	for row in oracle.drops:
		w=helper.ready_world();w.depart_dungeon(1,1);w.s.run.floor=int(row.floor);w.s.run.persona_pm=row.pm
		var code=w.roll_expedition_gear(row.kind,float(row.seed))
		check(code==row.value and same(w.s.run.loot_gear,row.gear),"drop/seed "+str([row.floor,row.kind,row.seed]),"gear_roll")
	for row in oracle.multipliers:
		w=helper.ready_world();w.depart_dungeon(1,1);w.s.run.persona_pm=row.pm
		check(w.outside_item_multiplier()==row.value,"outside item nation threshold "+str(row.pm),"outside_multiplier")
	for row in oracle.gear_add:
		w=helper.ready_world();w.depart_dungeon(1,1)
		if not row.initialized:w.s.run.erase("loot_gear")
		for code in row.values:w.append_expedition_gear(code)
		check(same(w.s.run.loot_gear,row.value),"append gear preserves order and duplicate "+str(row.initialized),"gear_add")
	for row in oracle.bag:
		w=helper.ready_world();w.depart_dungeon(1,1);w.s.run.phase=row.phase
		w.s.items.hp_s=2;w.s.items.shield_m=3;w.s.run.loot_items={"hp_s":4,"sh_m":5}
		var bag={}
		for id in row.value:bag[id]=w.supplies(w.web_item_id(id))
		check(same(bag,row.value),"combined bag "+row.phase,"bag")
	for row in oracle.discovery:
		w=helper.ready_world();w.s.owned=["lynette"];w.s.party=["lynette"];w.s.dungeon_r21.best=2;w.depart_dungeon(3,int(row.seed));w.s.run.persona_pm=row.pm
		w.s.run.step=int(row.step)-1;w.advance()
		var r=w.s.run;var actual={"phase":r.phase,"step":r.step,"elites":r.elites,"gold":r.gold,"items":r.loot_items,"gear":r.loot_gear,"ask":r.ask}
		# Lua's JSON encodes empty tables as arrays; normalize only empty maps.
		var expected=row.value.duplicate(true)
		if expected.items is Array and expected.items.is_empty():expected.items={}
		check(same(actual,expected),"real discovery "+str(row.raw)+" step "+str(row.step),"discovery")
	# Migration must preserve both resource stores, keep caller input immutable,
	# and remain idempotent after a JSON round trip.
	for row in oracle.migration:
		w=helper.ready_world();w.depart_dungeon(1,1)
		var save=w.s.duplicate(true);save.items.merge(row.input,true);save.run.loot_items=row.input.duplicate(true)
		var untouched=save.duplicate(true);var clone=World.new();var accepted=clone.restore(save)
		check(accepted,"old item aliases accepted "+str(row.input),"migration")
		if accepted:
			for id in ["hp_s","mp_s"]:
				check(clone.s.items.get(id,0)==row.value.get(id,0) and clone.s.run.loot_items.get(id,0)==row.value.get(id,0),"aliases summed in both stores "+id,"migration")
			check(not clone.s.items.has("potion") and not clone.s.items.has("mana") and not clone.s.run.loot_items.has("potion") and not clone.s.run.loot_items.has("mana"),"aliases removed after migration","migration")
			var again=World.new();check(again.restore(JSON.parse_string(JSON.stringify(clone.s))) and same(again.s,clone.s),"migration idempotent JSON","migration")
		check(same(save,untouched),"migration input immutable","migration")
	for bad in [-1,1.5,"broken",{},[]]:
		w=helper.ready_world();w.depart_dungeon(1,1);var saved=w.s.duplicate(true);saved.items.potion=bad
		var original=saved.duplicate(true);var before=w.s.duplicate(true)
		check(not w.restore(saved) and same(w.s,before) and same(saved,original),"bad alias rejected atomically "+str(bad),"migration")
	# Invalid and stale inputs do not change stock or rewards.
	w=helper.ready_world();w.depart_dungeon(1,7)
	for phase in ["battle","done"]:
		w.s.run.phase=phase;var old=w.s.duplicate(true)
		check(not w.use_item("hp_s","persona") and same(w.s,old),"phase rejects outside use "+phase,"invalid")
	w.s.run.phase="explore";w.s.items.hp_s=1
	for who in ["","unknown","haldric"]:
		var old=w.s.duplicate(true);check(not w.use_item("hp_s",who) and same(w.s,old),"undeployed use "+who,"invalid")
	var report={"checks":checks,"failures":failures,"groups":groups}
	FileAccess.open("res://../verification/parity-r23/expe-results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("EXPE R23 CHECKS ",checks," FAILURES ",failures.size()," GROUPS ",groups)
	helper.free();quit(0 if failures.is_empty() else 1)
