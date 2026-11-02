extends "res://tests/gear_r22_test.gd"
const Save=preload("res://game/gear_save_r22.gd")
const Hooks=preload("res://game/gear_hooks_r22.gd")
func rnd(st: Dictionary):st.rs=(int(st.rs)*16807)%2147483647;return float(st.rs)/2147483647.0

func run():
	var r=Rules.new();var save=Save.new();var hooks=Hooks.new()
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/gear-r22/extra-oracle.json"))
	for f in o.context:check(r.gear_context(f.game)==f.value,"legendary context names only equipped active members")
	for f in o.seed_inputs:check(r.gear_code("wa01",f.seed)==f.value,"source seed conversion "+f.seed)
	for f in o.drop:
		var drop=r.gear_drop(int(f.seed),int(f.floor),f.kind,f.classes)
		check((drop.get("code",false))==f.value,"drop code "+str(f.floor)+f.kind+str(f.seed))
		if not drop.is_empty():
			check(r.gear_roll(drop.code).lv==f.lv,"drop equip level")
			var e=save.source_drop(drop,1)
			check(e.source_r21 and equivalent(r.roll(e,40),r.gear_roll(drop.code,40).fx),"future drops original options")
	for f in o.caps:
		r.source.fx.cap=9;var actual=r.gear_roll(f.code);actual.erase("item")
		check(equivalent(actual,f.value),"cap trim exact floor "+f.code)
	r.source.fx.cap=20
	for f in o.transactions:
		var g=f.game.duplicate(true);var bag=f.bag.duplicate();var actual=r.callv(f.method,[g,bag]+f.args)
		if not actual is Array:actual=[actual]
		check(equivalent(actual,f.result),"transaction result "+f.method)
		check(equivalent(g,f.value) and bag==f.after_bag,"transaction state "+f.method)
	for f in o.refresh:
		var pm=f.pm.duplicate(true);r.gear_pm_refresh(f.game,pm)
		check(equivalent(pm,f.value),"rest equipment refresh "+f.game.persona.cls)
	for f in o.process_try:
		var g=f.game.duplicate(true);var bag=f.bag.duplicate();var actual=r.process_try(g,bag)
		check(g.gold==f.value.gold and g.town.process_n==f.value.town.process_n and bag==f.after_bag,"smithy handler outcome without host effects")
		check(actual[0]==(bag.size()>f.bag.size()),"smithy process result")
	for id in r.source.order:
		var it=r.source.items[id]
		check(r.gear_icon(it)==("gl-"+id if r.source.gl.has(id) else "gear-"+it.shape.replace("_","-")),"icons "+id)
		if not it.get("unique",{}).get("sig",false):continue
		var w={"gu":[it.unique]};var v=it.unique.v
		match it.unique.key:
			"as_shadow":check(hooks.assassin_extra(w,.20)==v[0]/100,"shadow replaces assassin chance")
			"ar_wind":check(hooks.snipe_crit(w)==v[1],"wind crit replaces base")
			"gl_boil":
				for base in [0,1,15,31,99]:check(hooks.hp_cost(w,base)==floor(base*(1-v[0]/100)+.5+1e-9),"boil after trait HP discount")
			"al_splash":check(hooks.splash_value(w,1.2)==v[0]/100*1.2,"splash applies item multiplier once")
			"pr_miracle":check(hooks.miracle(w,.5)=={"hp":v[0]/100,"shield":v[1]/100},"miracle priest boundary")
			"sa_warp":
				for charging in [false,true]:
					for raid_mult in [1.0,.5]:
						var st={"u":[{"g":10000,"x":{}},{"g":20000,"x":{}}],"cur":1};st.u[0].gu=w.gu
						var d=hooks.warp(st,1,2,charging,raid_mult,2500 if charging else 800)
						check(d==v[1 if charging else 0]*100*raid_mult and st.u[1].g==20000+d and st.u[0].x.adv==d*v[2]/100,"warp gain from actual boss delay")
	# Native initialization combines preserved old rolls and new code rolls once.
	var legacy={"uid":1,"id":"wa27","seed":99887766,"forge":3,"tries":8}
	var code=save.entry("wa80.abc.1",2);var m={"cls":"warrior","L":40,"native_eq":{"weapon":legacy,"armor":code}}
	var unit={"cs":40.0,"de":25.0,"hp":100,"mhp":100,"mp":100,"mmp":100,"sp":15,"cr":5}
	var st={};hooks.gear_init_native(st,unit,m)
	var sum={}
	for e in [legacy,code]:
		for k in r.roll(e,40):sum[k]=sum.get(k,0)+r.roll(e,40)[k]
	for k in sum:sum[k]=r.r1(sum[k])
	check(equivalent(unit.gq,sum),"native mixed aggregate does not reroll legacy options")
	var old_json=JSON.stringify(legacy);var native={"gear":[legacy],"equipment":{"persona":{"weapon":1}}}
	var pm=save.battle_member(native,"persona","warrior",40)
	check(pm.eq.is_empty() and JSON.stringify(pm.native_eq.weapon)==old_json,"legacy code never substituted into source eq")
	var g={"settings":{},"equip":{"persona":{"weapon":"eq_old","armor":"wa80.abc.1"}},"items":{"eq_old":2,"hp_s":3},"ui":{}}
	check(r.gear_migrate(g) and g.equip.persona.weapon=="" and g.equip.persona.armor=="wa80.abc.1" and g.items=={"hp_s":3},"prototype cleanup matches source active state")
	check(g.gear_r22_prototypes=={"equip":{"persona":{"weapon":"eq_old"}},"items":{"eq_old":2}},"prototype values archived")
	var snap=g.duplicate(true);check(not r.gear_migrate(g) and g==snap,"prototype migration once only")
	# Values below come from executing the actual 30-engine / 34-traits owner
	# functions, with only rendering/attack primitives intercepted by the oracle.
	var owner=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/gear-r22/owner-oracle.json"))
	hooks.bridge=self
	for f in owner.evade:
		var state={"u":[f.unit],"rs":f.seed};var value=hooks.evade_roll(state,1,f.base,f.prior)
		check((value==true if value!=null else false)==f.value and state.rs==f.rs,"owner evade result and exact RNG")
	for f in owner.blood:check(hooks.hp_cost(f.unit,f.base)==f.value,"owner blood cost")
	for f in owner.snipe:check(hooks.snipe_crit(f.unit if f.unit is Dictionary else {})==f.crit and hooks.gear_mpc(f.unit if f.unit is Dictionary else {},{"id":"snipe","mp":17})==f.mp,"owner wind crit and MP")
	for f in owner.shadow:check((f.draw<hooks.assassin_extra(f.unit,.2))==f.value,"owner shadow probability replaces base")
	for f in owner.warp:
		var w=f.unit.duplicate(true);w.x={};w.g=0
		var state={"u":[w,{"g":10000}],"cur":1}
		var d=hooks.warp(state,1,2,true,f.mult,2500)
		check(d==f.delay and state.u[0].x.get("adv",false)==f.adv,"owner charge warp actual raid delay")
	for f in owner.crit:check(floor(100*hooks.crit_damage(f.unit,f.base)+1e-9)==f.value,"owner hit crit damage")
	for f in owner.dot:check(hooks.dot_expiry(f.line)==f.value,"owner terminal DOT explosion")
	var result={"checks":checks,"failures":failures,"counts":{}}
	for k in o:result.counts[k]=o[k].size()
	result.owner_counts={}
	for k in owner:result.owner_counts[k]=owner[k].size()
	FileAccess.open("res://../verification/gear-r22/boundary-results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("GEAR BOUNDARY R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
