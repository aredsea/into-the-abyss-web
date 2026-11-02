extends RefCounted
var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/gear.json"))
var rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/gear_effects.json"))
var shop=JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))
var by_id={}
const RARITY={"common":"일반","fine":"고급","rare":"희귀","epic":"영웅","legend":"전설"}
const SLOT={"weapon":"무기","armor":"방어구","acc":"장신구"}

func _init() -> void:
	for item in catalog.items: by_id[item.id]=item

func roll(entry: Dictionary, level: int) -> Dictionary:
	var item=by_id[entry.id]; var result=item.base.duplicate(true)
	var pool=catalog.pools[item.cls][item.slot].duplicate()
	var rng=RandomNumberGenerator.new(); rng.seed=int(entry.seed)
	var raw=0.0; var fixed=0.0; var affixes={}
	for key in result: fixed+=result[key]*rules.base[key].eff
	if item.has("sig"): fixed+=item.sig.eff
	if item.has("unique"):
		var u=item.unique; var rule=rules.proc[u.key]
		fixed+=u.p*u.x*maxi(u.n,1)*rule.k if rule.get("k",0)!=0 else u.x*rule.get("flat_eff",0)
	for i in range(mini(rules.rarity[item.rarity].affix,pool.size())):
		var at=rng.randi_range(0,pool.size()-1); var key=pool[at]; pool.remove_at(at)
		var bounds=catalog.affix_range[key]
		var value=snappedf(bounds[0]+(bounds[1]-bounds[0])*rng.randf()*(.4+.6*item.lv/40.0),.1)
		affixes[key]=value; raw+=value*rules.affix[key].eff
	var cap=item.get("cap",rules.cap)
	var scale=minf(1,maxf(0,cap-fixed)/maxf(.001,raw))
	for key in affixes: result[key]=result.get(key,0)+floor(affixes[key]*scale*10)/10
	var lv_scale=(.4+.6*level/40.0)/(.4+.6*item.lv/40.0)*(1+entry.forge*.04)
	for key in result: result[key]=snappedf(result[key]*lv_scale,.1)
	return result

func sell_price(entry: Dictionary) -> int:
	var item=by_id[entry.id]; var price=rules.sell[item.rarity]
	return int(price[0]+price[1]*item.lv)

func stock(cls: String,day: int) -> Array:
	var out=[]
	for slot in SLOT:
		for rarity in ["common","fine"]:
			var pool=catalog.items.filter(func(i):return i.cls==cls and i.slot==slot and i.rarity==rarity)
			for n in range(mini(2,pool.size())): out.append(pool[(day*7+n)%pool.size()].id)
	return out

func price(id: String) -> int:
	var item=by_id[id]; var base=rules.sell[item.rarity]
	return int((base[0]+base[1]*rules.equip_lv[item.rarity])*8)

func forge_cost(entry: Dictionary) -> int:
	return int(rules.forge.cost_base[by_id[entry.id].rarity]*pow(entry.forge+1,2))

func band(level: int) -> Dictionary:
	for b in shop.process.bands:
		if level<=b.to: return b
	return shop.process.bands[-1]
