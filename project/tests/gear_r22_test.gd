extends SceneTree
const Rules=preload("res://game/gear_rules_r22.gd")
const EQ=preload("res://tests/gear_hooks_r22_test.gd")
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		failures.append(msg)
		if failures.size()<15:push_error(msg)
func equivalent(a: Variant,b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):return absf(a-b)<=1e-8*maxf(1,absf(b))
	if (a is Dictionary or a is Array) and (b is Dictionary or b is Array) and a.is_empty() and b.is_empty():return true
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
func run():
	var r=Rules.new();var fixtures=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/gear-r22/oracle.json"))
	check(r.source.order.size()==1030,"1030 original items")
	for it in r.catalog.items:
		var s=r.source.items[it.id]
		for key in ["id","name","cls","slot","rarity","lv","shape","base"]:check(equivalent(it[key],s[key]),"canonical data "+it.id+key)
		if it.has("sig"):check(equivalent(it.sig.v,s.unique.v) and it.sig.key==s.unique.key and it.sig.eff==s.unique.e,"30 signatures "+it.id)
	for f in fixtures.rolls:
		var actual=r.gear_roll(f.code,f.get("lv"),f.get("forge",0));actual.erase("item")
		check(equivalent(actual,f.value),"roll "+f.code+" lv="+str(f.get("lv"))+" forge="+str(f.get("forge")))
	for f in fixtures.codes:check(r.gear_code("wa01",int(f.seed))==f.value,"code integer digits "+f.seed)
	for f in fixtures.parse:
		var p=r.gear_parse(f.code)
		if f.value is bool:check(p.is_empty(),"invalid code "+f.code)
		else:
			check(p.id==f.value.id and str(int(p.seed))==f.value.seed and p.v==f.value.v,"parse "+f.code)
		check(r.gear_price(f.code)==(null if f.price is bool else f.price),"price "+f.code)
		check(r.gear_btn(f.code)==f.btn,"button encode")
		check(r.gear_unbtn(f.btn)==(null if f.unbtn is bool else f.unbtn),"button decode")
	for f in fixtures.process:
		check(r.process_roll(f.game,int(f.n))==f.value,"process code "+str(f.game.seed)+" "+str(f.n))
		check(r.process_level(f.game)==f.lv and equivalent(r.band(r.process_level(f.game)),f.band),"process max level/band")
	for f in fixtures.forge:
		var g=f.game.duplicate(true);var result=r.forge_try(g,f.bag,f.code)
		if result[0]==null:result[0]="nil"
		check(equivalent(result,f.result) and equivalent(g,f.value),"forge "+f.code+" "+str(f.game.get("forge",{})))
	for f in fixtures.equip:check(equivalent(r.gear_can_equip(f.game,f.cid,f.code),f.value),"can equip "+f.code)
	var bag=r.bag_load("null;wa01.1.1;zz99.1.1;;wa01.a.2;wa01.1.1")
	check(bag==["wa01.1.1","wa01.1.1"],"bag filters null and unknown, preserves duplicates")
	for i in range(1998):bag.append("wa01.1.1")
	check(not r.bag_add(bag,"wa01.2.1") and bag.size()==2000,"2000 cap")
	check(r.bag_take(bag,"wa01.1.1") and r.bag_add(bag,"wa01.2.1"),"take one then fill")
	var g={"seed":4242,"gold":1000,"persona":{"cls":"warrior","lv":5},"roster":[]}
	var before=g.duplicate(true);check(not r.process_try(g,bag)[0] and equivalent(g,before),"full bag no charges")
	bag=[];check(r.process_try(g,bag)[0] and g.gold==910 and g.town.process_n==1,"processing atomic charge and count")
	var adapter=preload("res://game/gear_save_r22.gd").new()
	var world=preload("res://game/persona_world.gd").new()
	world.s.creation_r22={"complete":true,"legacy":true};world.s.scene="town";world.s.persona.cls="전사";world.s.persona.lv=40;world.s.members.persona.level=40
	world.s.gear=[{"uid":75,"id":"wa27","seed":999999,"forge":3,"tries":9,"custom":"preserve me"}];world.s.serial=75
	var native_before=world.s.duplicate(true)
	var payload={"bag":"null;wa01.1.1;wa01.1.1;zz99.1.1","equip":{"persona":{"weapon":"wa02.2.1"}},"forge":{"wa01.1.1":{"lv":4,"tries":19}},"items":{"eq_old":3}}
	var payload_before=payload.duplicate(true);var imported=adapter.import_codes(world.s,payload)
	check(imported.ok and imported.added==3,"mixed source code import, duplicate codes retain separate UIDs")
	check(world.s==native_before and payload==payload_before,"import is pure, both input objects unchanged")
	check(imported.state.gear[0]==native_before.gear[0],"legacy UID seed forge tries custom bytes preserved")
	check(imported.state.gear[1].forge==4 and imported.state.gear[1].tries==19,"source forge keyed by exact original code")
	var forge_native=imported.state.duplicate(true);forge_native.gold=10000
	var shared=adapter.source_forge_try(forge_native,4242,"wa01.1.1")
	var source_game={"seed":4242,"gold":10000,"forge":{"wa01.1.1":{"lv":4,"tries":19}}}
	var source_result=r.forge_try(source_game,["wa01.1.1","wa01.1.1"],"wa01.1.1")
	check(equivalent(shared.result,source_result) and shared.state.gold==source_game.gold,"native source forge follows original code RNG and charge")
	check(shared.state.gear[1].forge==shared.state.gear[2].forge and shared.state.gear[1].tries==20 and shared.state.gear[2].tries==20,"duplicate code UIDs share original forge state")
	check(forge_native.gear==imported.state.gear and shared.state.gear[0]==native_before.gear[0],"source forge leaves input and legacy UID forge intact")
	check(imported.state.gear_r22.imports.values()[0].payload==payload,"raw invalid tokens and prototypes archived losslessly")
	var repeat_import=adapter.import_codes(imported.state,payload)
	check(repeat_import.ok and repeat_import.replayed and repeat_import.added==0 and repeat_import.state==imported.state,"import replay idempotent")
	var disk=JSON.parse_string(JSON.stringify(imported.state));var restored=preload("res://game/persona_world.gd").new()
	check(adapter.restore(restored,disk),"mixed schema3 disk restore")
	check(equivalent(restored.s.gear_r22,imported.state.gear_r22),"import archive and ledger survive existing world validator")
	check(equivalent(restored.s.gear,imported.state.gear),"mixed imported and legacy inventory survives disk roundtrip")
	var member=adapter.battle_member(imported.state,"persona","warrior",40)
	check(member.eq.weapon=="wa02.2.1" and member.native_eq.weapon.uid==78,"battle boundary retains code and native UID")
	var full={"gear":[],"serial":0,"equipment":{}}
	for i in range(2000):full.gear.append({"uid":i+1,"id":"wa01","seed":i,"forge":0,"tries":0})
	var overflow=adapter.import_codes(full,{"bag":"wa01.1.1;wa01.2.1"})
	check(overflow.ok and overflow.added==0 and overflow.overflow==2 and overflow.state.gear.size()==2000,"overflow is archived without removing old gear or exceeding bag cap")
	check(overflow.state.gear_r22.overflow.size()==2,"both pending codes retained for later claim")
	check(adapter.claim_pending(overflow.state).added==0,"full bag cannot claim pending codes")
	overflow.state.gear.pop_back();var freed=overflow.state.duplicate(true);var claimed=adapter.claim_pending(overflow.state)
	check(claimed.added==1 and claimed.state.gear.size()==2000 and claimed.state.gear_r22.overflow.size()==1,"claim pending after freeing one slot")
	check(overflow.state==freed and claimed.state.gear[-1].source_r21,"claim is pure and uses original options")
	var old=preload("res://game/gear_rules.gd").new()
	for it in r.catalog.items:
		var e={"id":it.id,"uid":1,"seed":99887766,"forge":3,"tries":8}
		check(equivalent(old.roll(e,40),r.roll(e,40)),"legacy RNG unchanged "+it.id)
		var c=r.gear_code(it.id,99887766);var entry=adapter.entry(c,1)
		check(equivalent(r.roll(entry,40),r.gear_roll(c,40,0).fx),"code entries use original RNG "+it.id)
	var huge=adapter.entry("wa27.zzzzzzzzzzzz.1",1)
	var huge_disk=JSON.parse_string(JSON.stringify(huge))
	check(equivalent(r.roll(huge_disk,40),r.gear_roll(huge.code,40,0).fx),"12 digit code preserves exact seed even past JSON numeric precision")
	var result={"checks":checks,"failures":failures,"counts":{}}
	for key in fixtures:result.counts[key]=fixtures[key].size()
	FileAccess.open("res://../verification/gear-r22/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("GEAR R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
