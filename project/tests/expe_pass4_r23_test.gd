extends SceneTree
const Previous=preload("res://tests/expe_pass3_r23_test.gd")
var helper=Previous.new()
var checks=0
var failures=[]
var groups={}
func check(ok: bool,label: String,group: String):
	checks+=1
	if not groups.has(group):groups[group]={"checks":0,"failures":0}
	groups[group].checks+=1
	if not ok:
		failures.append(label);groups[group].failures+=1
		if failures.size()<12:print("MISMATCH ",label)
func _initialize():call_deferred("run")
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-pass4-oracle.json"))
	var w=helper.setup()
	for r in o.names:check(w.expedition_item_name(r.id)==r.value,"item name "+r.id,"names")
	var api=w.has_method("new_expedition_record")
	check(api,"missing new_expedition_record","new")
	if api:
		for r in o.new:
			w=helper.setup();var calls=[];var rng=[];var kind=r.kind;var pm=helper.party_expected({"pm":r.pm}).pm
			var random=func():rng.append(true);return r.sample
			var provider=func(cls,lv,id):
				calls.append({"cls":cls,"lv":lv,"id":id})
				return {"ok":false} if kind=="throw" else {"ok":true,"value":7} if kind=="number" else {"ok":true,"value":w.initial_expedition_stats(cls,int(lv),id)}
			var actual=w.call("new_expedition_record",int(r.floor),pm,int(r.n),r.avg,7,random,provider)
			var expected=r.value.duplicate(true);expected.pm=pm;expected.loot.items={}
			check(helper.same(actual,expected),"new record "+str([r.sample,r.floor,kind,actual,expected]),"new")
			check(helper.same(calls,r.calls) and rng.size()==r.rnd and rng.size()==r.rng,"provider calls "+str([kind,calls,r.calls]),"new")
			pm[0].marker=true
			check(actual.pm[0].get("marker",false)==r.aliased,"pm reference preserved","new")
	var bank_api=w.has_method("bank_expedition_record")
	check(bank_api,"bank provider boundary missing","gear_bank")
	if bank_api:
		for r in o.gear_bank:
			w=helper.setup();var calls=[];var pattern=r.pattern
			var add=func(id,code):
				calls.append({"id":id,"code":code})
				return pattern=="all" or (pattern=="mixed" and calls.size()%2==1)
			var actual=w.call("bank_expedition_record",[] if r.list is bool else r.list,add,"expe4")
			check(helper.same(actual,{"gear":r.value,"lost":r.lost}) and helper.same(calls,r.calls),"bank callback and complete return "+pattern,"gear_bank")
	# Real native departure must use the same constructor and preserve the save ABI.
	if api:
		for r in o.new_actual:
			w=helper.setup();w.s.members.persona.level=10;w.s.dungeon_r21.best=2;w.s.town_r21.seed=int(r.seed);w.s.town_r21.counter=int(r.counter)
			var old_rng=w.s.rng
			var departed=w.depart_dungeon(int(r.floor))
			check(departed,"unseeded departure succeeds","new_actual")
			if not departed:continue
			var pm=w.expedition_party();var actual=w.call("expedition_record_with_seed",int(r.floor),pm.pm,pm.n,pm.avg,int(w.s.run.id),int(w.s.run.seed))
			var expected=r.value.duplicate(true);expected.pm=helper.party_expected({"pm":expected.pm}).pm;expected.loot.items={}
			check(helper.same(actual,expected),"actual source RNG and record "+str([r.seed,r.counter,r.floor,actual.seed,expected.seed]),"new_actual")
			check(w.s.town_r21.seed==r.after_seed and w.s.town_r21.counter==r.after_counter and w.s.rng==old_rng,"source RNG consumes one saved counter only","new_actual")
		for r in o.resume_actual:
			w=helper.setup();w.s.members.persona.level=10;w.s.town_r21.seed=int(r.seed);w.s.town_r21.counter=int(r.counter)
			check(w.depart_dungeon(1),"first actual source draw","resume_actual")
			var restored=helper.setup();check(restored.restore(w.s.duplicate(true)),"resume preserves source draw counter","resume_actual")
			check(restored.settle("retreat") and restored.depart_dungeon(1),"second departure after restored settlement","resume_actual")
			check(restored.s.run.seed==r.second.seed and restored.s.town_r21.counter==r.after_counter,"next source draw after save resume","resume_actual")
		w=helper.setup();w.s.members.persona.level=10;var counter=w.s.town_r21.counter;var rng=w.s.rng
		check(not w.depart_dungeon(0) and w.s.town_r21.counter==counter and w.s.rng==rng,"rejected departure consumes no RNG","integration")
		check(w.depart_dungeon(1,123) and w.s.town_r21.counter==counter and w.s.rng==rng,"explicit seed consumes no RNG","integration")
		check(not w.depart_dungeon(1) and w.s.town_r21.counter==counter and w.s.rng==rng,"active run rejects another RNG draw","integration")
		w=helper.setup();w.s.members.persona.level=10
		var saves={"town":w.s.duplicate(true)}
		check(w.depart_dungeon(1,123),"departure succeeds","integration")
		var pm=w.expedition_party();var record=w.call("expedition_record_with_seed",1,pm.pm,pm.n,pm.avg,int(w.s.run.id),123)
		for e in w.expedition_members():
			var i=e.slot-1;var id=e.m.id
			check(w.s.members[id].hp==record.hp[i] and w.s.members[id].mp==record.mp[i] and helper.same(w.s.run.maxima[id],{"hp":record.mhp[i],"mp":record.mmp[i]}),"departure source initial resources "+id,"integration")
		var save=w.s.duplicate(true);var restored=helper.setup()
		check(restored.restore(save) and helper.same(save,restored.s),"new departure full save resume","integration")
		check(not w.s.run.has("source_record") and not w.s.run.has("pm"),"source records stay transient","integration")
		saves.active=w.s.duplicate(true)
		check(w.settle("retreat"),"new constructor settles with old ABI","integration")
		saves.settled=w.s.duplicate(true)
		FileAccess.open("res://../verification/parity-r23/expe-pass4-cloud-save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify(saves,"  "))
		# Default bag provider, duplicate codes, capacity and persistent overflow.
		var bank=w.bank_expedition_gear(["wa01.1.1","wa01.1.1"])
		check(bank=={"gear":["wa01.1.1","wa01.1.1"],"lost":0} and w.s.gear[-1].uid!=w.s.gear[-2].uid,"real bag adds duplicate codes independently","integration")
		check(w.bank_expedition_gear(["invalid"])=={"gear":[],"lost":1},"failed insertion is counted","integration")
		var template=w.s.gear[-1].duplicate(true);w.s.gear=[]
		for i in range(2000):
			var entry=template.duplicate(true);entry.uid=i+1;w.s.gear.append(entry)
		w.s.serial=2000
		check(w.bank_expedition_gear(["wa01.1.1"])=={"gear":[],"lost":1} and w.s.gear.size()==2000 and w.s.gear_r22.overflow[-1].code=="wa01.1.1","full bag keeps existing overflow archive","integration")
	FileAccess.open("res://../verification/parity-r23/expe-pass4-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"groups":groups},"  "))
	print("EXPE PASS4 CHECKS ",checks," FAILURES ",failures.size())
	helper.helper.free();helper.free();quit(0 if failures.is_empty() else 1)
