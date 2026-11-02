extends SceneTree
const Hooks=preload("res://game/gear_hooks_r22.gd")
var checks=0
var failures=[]
var current={}
var hooks

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
	return typeof(a)==typeof(b) and a==b
func clean(value: Variant) -> Variant:
	if value is Array:return value.map(clean)
	if value is Dictionary:
		var out={}
		for k in value:out[k]=clean(value[k])
		return out
	return value
func actor(i: int):return current.u[i-1]
func record(st: Dictionary,k: String,args: Array):st.calls.append({"k":k,"args":args})
func trait_line(st: Dictionary,i: int,txt: String,at: float):record(st,"trait_line",[i,txt,at])
func setf(st: Dictionary,i: int,k: String,v: float,at: float):st.u[i-1][k]=v;record(st,"setf",[i,k,v,at])
func heal(st: Dictionary,i: int,amt: float,at: float):
	record(st,"heal",[i,amt,at,hooks.skill if hooks.skill!=null else false])
	var w=st.u[i-1];var h=maxf(0,minf(w.mhp-w.hp,floor(amt+.5)));w.hp+=h;return h
func say(st: Dictionary,txt: String,at: float):record(st,"say",[txt,at])
func push(st: Dictionary,x: Dictionary):record(st,"push",[x])
func strike(st: Dictionary,i: int,d: float,at: float,_unused: Variant,src: Variant):
	record(st,"strike",[i,d,at,src if src!=null else false])
	var w=st.u[i-1];w.hp=maxf(0,w.hp-d)
	if w.hp==0:w.al=0
	return {"i":i,"d":d,"kill":1 if w.hp==0 else 0}
func kill_credit(st: Dictionary,i: int,at: float):record(st,"kill_credit",[i,at])
func badd(st: Dictionary,i: int,k: String,v: float,n: int):st.u[i-1].bf[k]={"v":v,"n":n}
func rnd(st: Dictionary):st.rs=(int(st.rs)*16807)%2147483647;return float(st.rs)/2147483647.0

func run():
	var fixtures=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/gear-r22/hooks.json"))
	hooks=Hooks.new(self)
	var counts={}
	for f in fixtures:
		current=f.before.duplicate(true)
		for w in current.u:
			for k in ["x","bf","gq"]:
				if w.get(k) is Array and w[k].is_empty():w[k]={}
		hooks.act=int(f.act);hooks.skill=null if f.skill is bool and f.skill==false else f.skill;hooks.defs=f.defs
		var args=f.args.duplicate(true);var actual=null;var method=f.method
		if method=="deal" and args[4] is Array:args[4]={}
		if method=="crit" and args[2] is Array:args[2]={}
		if method=="hit_after" and args[3] is Array:args[3]={}
		if method=="gear_init":hooks.gear_init(current,current.u[0],args[0])
		elif method=="gear_buff":actual=hooks.gear_buff(args[0])
		elif method=="gear_mpc":actual=hooks.gear_mpc(current.u[0],args[0])
		else:actual=hooks.callv({"heal":"heal_amount","round":"round_end"}.get(method,method),[current]+args)
		if method=="gear_dot" and actual[1]==null:actual[1]=false
		if actual==null:actual="nil"
		var label=method+" "+f.meta
		check(equivalent(actual,f.result),"return "+label+" "+str(actual)+" != "+str(f.result))
		if not equivalent(current,f.value) :
			FileAccess.open("res://../verification/gear-r22/mismatch-"+method+".json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":f,"actual":current},"  "))
		check(equivalent(current,f.value),"state/calls/RNG "+label)
		if method=="deal":check(equivalent(args[3],f.after_args[3]),"deal tags "+label+" "+str(args[3])+" != "+str(f.after_args[3]))
		counts[method]=counts.get(method,0)+1
	# Owner-side formulas located outside 81-gear.
	var w={"gq":{"critdmg":20,"evade":15},"gu":[{"key":"ar_wind","v":[30,90]}]}
	check(hooks.crit_damage(w,1.5)==1.7,"crit damage add")
	check(is_equal_approx(hooks.evade_chance(w,.1),.25),"evade additive same roll")
	check(hooks.snipe_crit(w)==90,"wind snipe crit")
	var result={"checks":checks,"failures":failures,"fixtures":fixtures.size(),"methods":counts}
	FileAccess.open("res://../verification/gear-r22/hook-results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("GEAR HOOKS R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
