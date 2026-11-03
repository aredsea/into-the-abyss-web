extends SceneTree
const Base=preload("res://tests/expedition_r22_test.gd")
var helper=Base.new()
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
func same(a,b) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not same(a[key],b[key]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not same(a[i],b[i]):return false
		return true
	if (a is Dictionary or a is Array) or (b is Dictionary or b is Array):return false
	return helper.same(a,b)
func party_expected(value: Dictionary) -> Dictionary:
	var out=value.duplicate(true)
	for m in out.pm:
		if m.get("forge") is Array and m.forge.is_empty():m.forge={}
	return out
func setup():
	var w=helper.ready_world()
	w.s.persona.name="가온";w.s.persona.lv=10;w.s.persona.exp=0;w.s.persona.cls="전사";w.s.persona.fight=1
	w.s.persona.race="인간";w.s.persona.nation="경계도시"
	w.s.owned=["lynette","marceline","urda","haldric"];w.s.party=["lynette"]
	for id in {"lynette":15,"marceline":9,"urda":10,"haldric":40}:
		w.s.members[id].level={"lynette":15,"marceline":9,"urda":10,"haldric":40}[id];w.s.members[id].xp=0;w.s.members[id].aff=0
	w.s.xp_r22={}
	return w
func exists(w,name: String,group: String) -> bool:
	var ok=w.has_method(name);check(ok,"missing "+name,group);return ok
func _initialize():call_deferred("run")
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-pass3-oracle.json"))
	var w=setup()
	if exists(w,"expedition_zero4","zero4"):
		var first=w.call("expedition_zero4");var second=w.call("expedition_zero4")
		check(same([first,second],o.zero),"independent zero slots","zero4")
		first[0]=9;check(second==[0,0,0,0],"zero slots are not aliased","zero4")
	if exists(w,"expedition_item_weight","weights"):
		for r in o.weights:
			for iid in r.value:check(w.call("expedition_item_weight",iid,int(r.floor))==r.value[iid],"weight "+str([iid,r.floor]),"weights")
		for r in o.weighted_roll:check(same(w.call("expedition_roll",int(r.seed),int(r.floor),int(r.step),0,["warrior"]),r.value),"weighted roll "+str([r.floor,r.seed,r.step]),"weighted_roll")
	if exists(w,"snapshot_expedition_record","snapshot"):
		for r in o.snapshot:
			var R={"hp":[11,22,33,44],"mp":[1,2,3,4],"mhp":[21,22,23,24],"mmp":[31,32,33,34],"real":false,"fell":false,"keep":"unchanged"}
			var units=[]
			for i in range(4):units.append({"empty":1 if int(r.mask)&(1<<i) else 0,"al":(i+1)%2,"hp":r.hp,"mp":r.mp,"mhp":101.9,"mmp":71.9})
			w.call("snapshot_expedition_record",R,units,r.down)
			check(helper.same(R,r.value),"snapshot "+str([r.mask,r.down,r.hp,r.mp]),"snapshot")
	if exists(w,"expedition_party","party"):
		for r in o.party:
			w=setup();w.s.persona.cls=r.cls;w.s.persona.fight=int(r.fight);w.s.party=r.party.duplicate()
			if r.equipped:
				# Arbitrary source code is retained by the PM snapshot even when its
				# slot/class is incompatible; this fixture never equips via a UI.
				w.s.gear=[{"uid":1,"id":"wa01","seed":1,"code":"wa01.1.1","source_r21":true,"forge":2,"tries":3},{"uid":2,"id":"aa01","seed":2,"code":"aa01.2.1","source_r21":true,"forge":0,"tries":0}]
				w.s.equipment.persona={"weapon":1};w.s.equipment.lynette={"armor":2}
			var actual=w.call("expedition_party");var expected=party_expected(r.value)
			check(same(actual,expected),"party "+str([r.cls,r.fight,r.party,r.equipped,actual,expected]),"party")
	if exists(w,"expedition_exp_note","exp_fallback"):
		for r in o.exp_fallback:
			var calls=[];var touched=[];var kind=r.kind
			var provider=func(st):
				calls.append(st.duplicate(true));touched.append(true)
				return {"ok":kind!="throw","value":7 if kind=="number" else false if kind=="false" else "bad" if kind=="string" else [] if kind=="empty" else ["first","second"]}
			w=setup();var S={"exp":99,"lv":["stale"],"keep":true};var R={"pm":w.expedition_source_pm(),"sid":7}
			w.call("expedition_exp_note",R,r.exp,S,provider,kind!="missing")
			var projected=[]
			for call in calls:projected.append({"exp":call.exp,"sid":call.sid,"pm":call.pm})
			var expected=[]
			for call in r.calls:expected.append({"exp":call.exp,"sid":call.sid,"pm":party_expected({"pm":call.pm}).pm})
			check(same(S,r.value) and same(projected,expected) and (not touched.is_empty())==r.touched,"exp fallback "+str([kind,r.exp]),"exp_fallback")
		for r in o.exp_actual:
			w=setup();w.s.persona.lv=int(r.lv);w.s.members.persona.level=int(r.lv);w.s.persona.fight=int(r.fight);w.s.members.lynette.level=int(r.lv)
			if r.replay:w.s.xp_r22.xp_bn=7
			var R={"pm":w.source_pm(),"sid":7};var S={};w.call("expedition_exp_note",R,r.exp,S)
			check(helper.same(S,r.value),"exp full lines "+str([r.lv,r.exp,r.fight,r.replay,S,r.value]),"exp_actual")
			check(helper.same({"lv":w.s.persona.lv,"exp":w.s.persona.exp},r.persona) and w.s.members.lynette.level==r.level and w.s.members.lynette.xp==r.xp and w.s.xp_r22.get("xp_bn",false)==r.xp_bn,"exp state "+str([r.lv,r.exp,r.fight,r.replay]),"exp_actual")
	if exists(w,"expedition_aff_note","aff"):
		for r in o.aff:
			w=setup();w.s.persona.nation=r.nation;w.s.settings={"lang":r.lang};w.s.owned=r.roster.duplicate()
			for id in w.s.owned:w.s.members[id].aff=r.aff
			var R={"pm":r.pm,"wins":r.wins};var S={};var got=w.call("expedition_aff_note",R,r.result,S)
			check(helper.same(S.aff,r.value),"aff full text "+str([r.lang,r.result,r.wins,r.aff,r.nation,S.aff,r.value]),"aff")
			var after={}
			for id in w.s.owned:after[id]=w.s.members[id].aff
			check(helper.same(after,r.after),"aff state "+str([r.result,r.wins,r.aff,r.nation]),"aff")
			for id in got:check(got[id]>=0,"aff delta nonnegative","aff")
		for r in o.aff_fallback:
			w=setup();var kind=r.kind
			var provider=func(_pm,_amount):return {"ok":kind!="throw","value":7 if kind=="number" else {} if kind=="empty" else {"lynette":1.6,"persona":0,"unknown":.04}}
			var S={"aff":["stale"]};var R={"wins":r.wins,"pm":[{"id":"lynette"},{"id":"persona"},{"id":"lynette"},{"id":"unknown"}]}
			w.call("expedition_aff_note",R,"retreat",S,provider,kind not in ["missing","no_constants"])
			check(helper.same(S.aff,r.value),"aff fallback "+str([kind,r.wins,S.aff,r.value]),"aff_fallback")
	if exists(w,"expedition_label","labels"):
		for r in o.labels:
			w=setup();w.s.settings={"lang":r.lang};w.s.run={} if r.floor is bool else {"floor":r.floor}
			check(w.call("expedition_label")==r.label,"label "+str([r.lang,r.floor]),"labels")
			if not r.context is bool and exists(w,"expedition_floor_context","floor_context"):check(w.call("expedition_floor_context",int(r.floor))==r.context,"floor context "+str(r.floor),"floor_context")
	if exists(w,"normalize_dungeon_record","normalize"):
		for r in o.normalize:
			var G={"dungeon":r.input.duplicate(true) if r.input is Dictionary or r.input is Array else r.input}
			var D=w.call("normalize_dungeon_record",G)
			check(helper.same(D,r.value) and helper.same(G.dungeon,r.value),"normalize "+str(r.input),"normalize")
	# Source projections must not widen the native/cloud save schema.
	w=setup();var saves={"town":w.s.duplicate(true)}
	var original=JSON.stringify(w.s);w.expedition_party()
	check(JSON.stringify(w.s)==original,"source party projection does not mutate save","save_abi")
	check(not w.s.dungeon_r21.has("mode") and not w.s.dungeon_r21.has("pg"),"source defaults stay transient","save_abi")
	check(w.depart_dungeon(1,7),"native departure still succeeds","save_abi")
	for m in w.s.run.persona_pm:check(not m.has("eq") and not m.has("forge"),"source equipment snapshots stay transient","save_abi")
	saves.active=w.s.duplicate(true);w.s.run.wins=2;w.s.run.xp=55
	check(w.settle("retreat"),"native settlement still succeeds","save_abi")
	check(not w.s.summary.has("exp_lines") and not w.s.summary.has("aff_lines"),"display lines stay transient","save_abi")
	check(w.expedition_summary_aff_lines()==["리네트 +2"],"settlement view derives source lines","save_abi")
	saves.settled=w.s.duplicate(true)
	var restored=setup();check(restored.restore(saves.settled) and restored.expedition_summary_aff_lines()==w.expedition_summary_aff_lines(),"source summary lines survive save resume by derivation","save_abi")
	FileAccess.open("res://../verification/parity-r23/expe-pass3-save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify(saves,"  "))
	var f=FileAccess.open("res://../verification/parity-r23/expe-pass3-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"groups":groups},"  "));f.close()
	print("EXPE PASS3 R23 CHECKS ",checks," FAILURES ",failures.size()," GROUPS ",groups)
	helper.free();quit(0 if failures.is_empty() else 1)
