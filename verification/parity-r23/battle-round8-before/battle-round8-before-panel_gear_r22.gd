extends RefCounted
## A view over the existing gear adapter. Does not roll or migrate combat gear.
const R=preload("res://game/panels_rules_r22.gd")
const D=preload("res://game/dungeon_rules_r21.gd")
static func effect_def(gear,key: String) -> Dictionary:return gear.rules.base.get(key,gear.rules.affix.get(key,{}))
static func effect_name(gear,key: String,job: String="") -> String:
	if key=="stat" and R.cls(job).has("line"):return R.cls(job).line
	return effect_def(gear,key).get("name",key)
static func effect_value(gear,key: String,value: float) -> String:
	return ("+" if value>=0 else "")+R.fnum(value)+effect_def(gear,key).get("unit","")
static func describe(gear,e: Dictionary,level: int) -> Dictionary:
	var it=gear.by_id[e.id];var raw=e.duplicate();raw.forge=0
	var unscaled=gear.roll(raw,int(it.lv));var values=gear.roll(e,level) if level>0 else unscaled
	var scale=1.0 if level<1 else (.4+.6*clampi(level,1,40)/40.0)/(.4+.6*it.lv/40.0)*(1+clampi(int(e.forge),0,10)*gear.rules.forge.bonus_per_level)
	var keys=[]
	if e.get("source_r21",false):
		var pool=gear.catalog.pools[it.cls][it.slot].duplicate()
		for i in range(mini(gear.rules.rarity[it.rarity].affix,pool.size())):
			var at=i+int(floor(D.mix(e.seed,1,i+1,0)*(pool.size()-i)));var key=pool[at];pool[at]=pool[i];pool[i]=key;keys.append(key)
	else:
		for k in unscaled:
			if not is_zero_approx(unscaled[k]-it.base.get(k,0)):keys.append(k)
	var affix=[]
	for k in keys:affix.append([k,floor((unscaled[k]-it.base.get(k,0))*scale*10+.5)/10])
	return {"fx":values,"affix":affix,"item":it}
