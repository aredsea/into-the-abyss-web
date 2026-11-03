extends "res://game/gear_rules.gd"
## 71-shop/81-gear deterministic code generation. Existing saved rolls stay legacy.
const D=preload("res://game/dungeon_rules_r21.gd")
const ORDER=["common","fine","rare","epic","legend"]
func code(entry: Dictionary) -> String:return entry.id+"."+D.base36(int(entry.seed))+"."+str(int(catalog.version))
func stock_source(seed: int,day: int,cls: String,slot: String) -> Array:
	var out=[];var local_seed=seed+day*7919
	for rarity in shop.gear.rarities:
		var pool=catalog.items.filter(func(i):return i.cls==cls and i.slot==slot and i.rarity==rarity)
		for j in range(1,int(shop.gear.stock_per_slot)+1):
			if pool.is_empty():continue
			var n=out.size();var k=int(floor(D.mix(local_seed,cls.length()+j,slot.length(),n+1)*pool.size()))
			var item=pool.pop_at(k);var roll_seed=int(floor(D.mix(local_seed,cls.length()+j,slot.length(),n+31)*1099511627776))+1
			var e={"id":item.id,"seed":roll_seed};e.code=code(e);e.price=(rules.sell[rarity][0]+rules.sell[rarity][1]*rules.equip_lv[rarity])*shop.gear.buy_multiplier
			out.append(e)
	return out
func process_source(seed: int,n: int,classes: Array,level: int) -> Dictionary:
	var pool=[]
	for cls in classes:
		if cls not in pool and catalog.items.any(func(i):return i.cls==cls):pool.append(cls)
	if pool.is_empty():return {}
	var cls=pool[int(floor(D.mix(seed,n,1,61)*pool.size()))]
	var slot=["weapon","armor","acc"][int(floor(D.mix(seed,n,2,61)*3))]
	var weights=band(level).w;var total=0.0
	for r in ORDER:total+=weights.get(r,0)
	var draw=D.mix(seed,n,3,61)*total;var ri=0
	for i in range(ORDER.size()):
		var weight=weights.get(ORDER[i],0)
		if weight<=0:continue
		ri=i;draw-=weight
		if draw<0:break
	for i in range(ri,-1,-1):
		var candidates=catalog.items.filter(func(it):return it.cls==cls and it.slot==slot and it.rarity==ORDER[i])
		var chosen={};var count=0
		for it in candidates:
			count+=1
			if D.mix(seed+n*7919,5,count,0)*count<1:chosen=it
		if not chosen.is_empty():
			var e={"id":chosen.id,"seed":int(floor(D.mix(seed,n,4,61)*1099511627776))+1};e.code=code(e);return e
	return {}
func forge_result(seed: int,entry: Dictionary) -> bool:
	var key=0;var value=code(entry)
	for byte in value.to_utf8_buffer():key=(key*131+byte)%2147483647
	return D.mix(seed+key,int(entry.tries)+1,int(entry.forge)+1,41)*100<rules.forge.success[int(entry.forge)]
func roll(entry: Dictionary,level: int) -> Dictionary:
	if not entry.get("source_r21",false):return super(entry,level)
	var item=by_id[entry.id];var pool=catalog.pools[item.cls][item.slot].duplicate();var values=[];var keys=[];var raw=0.0;var fixed=0.0
	for key in item.base:fixed+=item.base[key]*rules.base[key].eff
	if item.has("sig"):fixed+=item.sig.eff
	if item.has("unique"):
		var u=item.unique;var r=rules.proc[u.key];fixed+=u.p*u.x*maxi(u.n,1)*r.k if r.get("k",0)!=0 else u.x*r.get("flat_eff",0)
	for i in range(mini(rules.rarity[item.rarity].affix,pool.size())):
		var at=i+int(floor(D.mix(entry.seed,1,i+1,0)*(pool.size()-i)));var key=pool[at];pool[at]=pool[i];pool[i]=key
		var rg=catalog.affix_range[key];var v=rg[0]+(rg[1]-rg[0])*D.mix(entry.seed,2,i+1,0)*(.4+.6*item.lv/40.0)
		keys.append(key);values.append(v);raw+=v*rules.affix[key].eff
	var score=fixed
	for i in range(values.size()):score+=floor(values[i]*10+.5)/10*rules.affix[keys[i]].eff
	var cap=item.get("cap",rules.cap);var trim=score>cap+1e-9;var ratio=maxf(0,cap-fixed)/maxf(.0000001,raw)
	var result=item.base.duplicate(true)
	for i in range(values.size()):result[keys[i]]=result.get(keys[i],0)+(floor(values[i]*ratio*10)/10 if trim else floor(values[i]*10+.5)/10)
	var scale=(.4+.6*clampi(level,1,40)/40.0)/(.4+.6*item.lv/40.0)*(1+clampi(int(entry.forge),0,10)*rules.forge.bonus_per_level)
	for key in result:result[key]=floor(result[key]*scale*10+.5)/10
	return result
