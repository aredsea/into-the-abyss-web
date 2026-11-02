extends SceneTree
const Base=preload("res://tests/combat_p2_r22_test.gd")
const Battle=preload("res://tests/a7_baseline_fixture.gd")
const Legacy=preload("res://tests/combat_a6_legacy_fixture.gd")
var checks=0
var failures=[]
var rows=[]
func same(a,b) -> bool:
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same(a[key],b[key]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same(a[i],b[i]): return false
		return true
	if a is float or a is int: return (b is float or b is int) and absf(float(a)-float(b))<.0000001
	return a==b
func check(ok: bool,label: String,got=null,want=null):
	checks+=1
	rows.append({"label":label,"got":got,"want":want,"ok":ok})
	if not ok: failures.append(label)
func fixture():
	var helper=Base.new(); var b0=helper.fixture(); var b=Battle.new(b0.data); helper.free()
	for u in b.data.allies+b.data.enemies:
		u.hp=1000; u.mhp=1000; u.shield=0; u.effects={}; u.remaining=10000
		if u.has("base"): u.mp=0; u.mmp=100; u.base.spd=100; u.base.str=100; u.base.int=100; u.base.agi=0; u.base.crit=0
		else: u.speed=100; u.defense=0; u.weak=[]
	b.ctb_tick=0; b.ctb_round=0
	return b
