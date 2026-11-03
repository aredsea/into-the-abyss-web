extends RefCounted
## 24-stats.lua. Shared unmodified base stats, before race/nation/equipment hooks.
static var world=JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
static var config=JSON.parse_string(FileAccess.get_file_as_string("res://data/dungeons-r21.json")).stats
static var classes={}
static func cls_of(value: Variant) -> Dictionary:
	if not value is String:return {}
	if classes.is_empty():
		for c in world.classes:
			var out={}
			for key in ["id","name","line","row","base","grow"]:out[key]=c[key]
			classes[c.id]=out
	if classes.has(value):return classes[value]
	for c in classes.values():
		if c.name==value:return c
	return {}
static func number(value: Variant,fallback: float=1) -> float:
	if value is int or value is float:return float(value)
	if value is String:
		var s=value.strip_edges()
		if s.is_valid_float():return float(s)
		# Lua tonumber also accepts signed hexadecimal fractions and p exponents.
		var pattern=RegEx.new();pattern.compile("^([+-]?)0[xX]([0-9a-fA-F]*)(?:\\.([0-9a-fA-F]*))?(?:[pP]([+-]?[0-9]+))?$")
		var found=pattern.search(s)
		if found!=null and not (found.get_string(2)+found.get_string(3)).is_empty():
			var n=float(found.get_string(2).hex_to_int()) if not found.get_string(2).is_empty() else 0.0
			var fraction=found.get_string(3)
			for i in range(fraction.length()):n+=fraction.substr(i,1).hex_to_int()*pow(16,-i-1)
			return (-1 if found.get_string(1)=="-" else 1)*n*pow(2,int(found.get_string(4)))
	return fallback
static func fc(key: String,level: float=1,mult: float=1) -> float:
	var c=config.curves[key];var x=level-1
	return 1+mult*(c.a*x+c.b*x*x)
static func stat(c: Dictionary,mod: Dictionary,key: String,curve: String,level: float) -> float:
	return c.base[key]*(1+mod.get(key,0)/100.0)*fc(curve,level,c.grow[key])
static func party_stats(cls: Variant,level: Variant=1,cid: Variant=null) -> Dictionary:
	var c=cls_of(cls)
	if c.is_empty():return {}
	var L=clampf(number(level),1,config.level_max);var mod={}
	for p in world.companions:
		if p.id==cid:mod=p.mod;break
	var out={}
	for key in ["str","agi","int"]:out[key]=stat(c,mod,key,"atk",L)
	out.merge({"hp":floor(stat(c,mod,"hp","hp",L)+.5),"mp":floor(stat(c,mod,"mp","mp",L)+.5),"de":stat(c,mod,"def","def",L),"ag":out.agi,"sp":c.base.spd+mod.get("spd",0)+config.curves.spd.add*(L-1),"cr":c.base.crit+mod.get("crit",0)})
	out.def=out.de;out.cs=out[{"힘":"str","민첩":"agi","지능":"int"}.get(c.line,"str")]
	return out
static func K_of(level: Variant=null,formula: Dictionary={},curve: Dictionary={}) -> float:
	if formula.is_empty():formula=config.formula
	if curve.is_empty():curve=config.curves.def
	var x=(1 if level==null else float(level))-1
	return formula.def_k_ratio*formula.def_std_base*(1+curve.a*x+curve.b*x*x)

static func enemy_stats(kind: Variant,level: float=1,star: Variant=1) -> Dictionary:
	var valid=(star is int or star is float) and is_finite(float(star)) and star==floor(star) and star>=1 and star<=config.stars.size()
	var stars=config.stars[int(star)-1] if valid else config.stars[0]
	var scale={"mob":[1.0,1.0],"elite":[3.5,1.2],"boss":[8.0,1.35]}.get(kind,[1.0,1.0])
	var e=config.enemy_std
	return {"hp":e.hp*fc("atk",level)*scale[0]*stars.hp,"atk":e.str*2*fc("atk",level)*scale[1]*stars.atk,"de":e.def*fc("def",level),"ay":{"mob":30,"elite":80,"boss":150}.get(kind,30),"sp":e.spd}

