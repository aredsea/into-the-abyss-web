extends RefCounted
## Presentation rules from 65/66; deliberately independent of combat bonuses.
static var DATA=JSON.parse_string(FileAccess.get_file_as_string("res://data/panels-r22.json"))
const AFF=preload("res://game/affection_r22.gd")
const PAGE=12
const BAG_PAGE=20
const MAXFAV=3
const RK={"common":1,"fine":2,"rare":3,"epic":4,"legend":5}
const Value=preload("res://game/ui_value_r23.gd")
const Locale=preload("res://game/localization_r22.gd")
static func hud_action(g: Dictionary,arg: String) -> void:
	if arg=="close":g.ui.panel="";return
	g.ui.panel="" if g.ui.panel==arg else arg;g.ui.tab="";g.ui.sel=""
static func status_action(g: Dictionary,arg: String) -> void:
	if arg=="t_battle":g.ui.tab=""
	elif arg=="t_me":g.ui.tab="me"
	elif arg=="t_bag" and g.get("scene")!="battle":g.ui.tab="bag"
static func member_name(g: Dictionary,id: String,lang="ko",html=true) -> String:
	var name=g.get("persona",{}).get("name","") if id=="persona" else DATA.cast.get(id,{}).get("name",id)
	var result=Locale.u("나",{},lang) if id=="persona" and name=="" else Locale.t(name,lang)
	return escape(result) if html else result
static func escape(value) -> String:
	return Value.text(value).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace('"',"&quot;")
static func num(value) -> String:return str(int(floor(Value.number(value)+.5)))
static func fnum(value) -> String:
	var n=Value.number(value);var bits=PackedFloat64Array([absf(n)]).to_byte_array().decode_u64(0)
	var exponent=int((bits>>52)&2047);var mantissa=(bits&0x000fffffffffffff)|(0x0010000000000000 if exponent>0 else 0)
	var shift=1074-exponent if exponent>0 else 1073
	# Lua string.format uses ties-to-even on the exact binary float. Godot's
	# decimal formatter rounds halfway away from zero; do the one-digit step
	# with the binary mantissa so 1.25 -> 1.2 and 2.45 -> 2.5 both match.
	if shift<=0:return ("%.1f"%n).trim_suffix(".0")
	var units=0
	if shift<63:
		var product=mantissa*5;var denominator=1<<shift
		units=product/denominator
		var rem=product%denominator
		if rem>denominator/2 or (rem==denominator/2 and units%2!=0):units+=1
	return ("-" if n<0 else "")+str(units/10)+("."+str(units%10) if units%10!=0 else "")
static func first(value) -> String:
	var s=Value.text(value)
	return "◆" if s=="" or s.contains("{{") else s.left(1)
static func slot_ok(slot: String) -> bool:return slot in ["weapon","armor","acc"]
static func member_class(g: Dictionary,id: String) -> String:
	var p=g.get("persona",{})
	var raw=p.get("cls","") if id=="persona" and p is Dictionary else DATA.cast.get(id,{}).get("cls","")
	return cls(raw).get("id","") if raw is String else ""
static func level(g: Dictionary,id="persona") -> int:
	var p=g.get("persona",{});var raw=p.get("lv") if p is Dictionary else null
	var base=clampi(Value.integer(raw if Value.truth(raw) else g.get("lv"),1),1,40)
	if id=="persona":return base
	if id not in g.get("roster",[]):return 1
	var levels=g.get("lvl",{});var n=Value.number(levels.get(id),NAN) if levels is Dictionary else NAN
	return base if is_nan(n) else clampi(int(floor(n)),1,40)
static func normalize_bg(value: Variant) -> Dictionary:
	var s=value.duplicate(true) if value is Dictionary else {}
	s.pg=maxi(1,Value.integer(s.get("pg"),1))
	for key in ["cls","slot","rar","sel","cmp","conf"]:
		if not s.get(key) is String:s[key]=""
	return s

static func cls(key: String) -> Dictionary:
	for c in DATA.classes:
		if key in [c.id,c.name]:return c
	return {}
static func recruited(g: Dictionary,id: String) -> bool:return DATA.cast.has(id) and id in g.get("roster",[])
static func codex_list(owned: Array,tab="") -> Array:
	var rec=[];var unknown=[]
	for id in DATA.order:
		if id in owned:rec.append(id)
		else:unknown.append(id)
	if tab=="":return rec+unknown
	if tab=="rec":return rec
	var out=[];var ranks={}
	if tab.begins_with("el"):
		for i in range(DATA.el_order.size()):ranks[DATA.el_order[i]]=i
		var want=tab.substr(3)
		for id in rec:
			var el=DATA.cast[id].el
			if not DATA.els.has(el):el="none"
			if want=="" or want==el:out.append(id)
		out.sort_custom(func(a,b):return rec.find(a)<rec.find(b) if ranks[DATA.cast[a].el]==ranks[DATA.cast[b].el] else ranks[DATA.cast[a].el]<ranks[DATA.cast[b].el])
	elif tab.begins_with("cls"):
		for i in range(DATA.classes.size()):ranks[DATA.classes[i].name]=i
		var want=tab.substr(4);var name=cls(want).get("name","")
		for id in rec:
			if want=="" or DATA.cast[id].cls==name:out.append(id)
		out.sort_custom(func(a,b):return rec.find(a)<rec.find(b) if ranks[DATA.cast[a].cls]==ranks[DATA.cast[b].cls] else ranks[DATA.cast[a].cls]<ranks[DATA.cast[b].cls])
	else:return rec
	return out
static func base_stats(key: String,level: int,mod: Dictionary={}) -> Dictionary:
	var cl=cls(key)
	if cl.is_empty():return {}
	var c=DATA.cls[cl.id];var out={};var x=clampi(level,1,40)-1
	for k in ["hp","mp","str","agi","int","def"]:
		var curve=DATA.curves[k if k in ["hp","mp","def"] else "atk"]
		out[k]=int(floor(c.base[k]*(1+float(mod.get(k,0))/100)*(1+c.grow.get(k,1)*(curve.a*x+curve.b*x*x))+.5))
	out.spd=int(floor(c.base.spd+mod.get("spd",0)+DATA.curves.spd.add*x+.5))
	return out
static func companion_stats(id: String,level: int) -> Dictionary:
	var c=DATA.cast.get(id,{})
	return base_stats(c.get("cls",""),level,c.get("mod",{}))
static func persona_stats(p: Dictionary) -> Dictionary:
	var level=clampi(int(p.get("lv",1)),1,40);var b=base_stats(p.get("cls",""),1);var current=base_stats(p.get("cls",""),level);var made=p.get("stats",{})
	if not made is Dictionary or not made.has("hp") or not made.has("str"):return current
	if level==1:return made.duplicate(true)
	if current.is_empty():return made.duplicate(true)
	for k in ["hp","mp","str","agi","int","def"]:current[k]=int(floor(made.get(k,0)*float(current[k])/maxi(1,b[k])+.5))
	current.spd=int(floor(made.get("spd",0)+(current.spd-b.spd)+.5))
	return current
static func shown_aff(value: Variant) -> int:return int(floor(clampf(Value.number(value),-100,200)))
static func page(items: Array,pg: int,count=PAGE) -> Dictionary:
	var pages=maxi(1,int(ceil(float(items.size())/count)));pg=clampi(pg,1,pages)
	return {"page":pg,"pages":pages,"total":items.size(),"items":items.slice((pg-1)*count,pg*count)}
static func cx_action(g: Dictionary,arg: String,lang="ko") -> void:
	var u=g.ui;var sel=u.get("sel","")
	if arg.begins_with("f_"):u.tab=arg.substr(2) if arg!="f_all" else "";u.page=1;u.sel=""
	elif arg.begins_with("pg_"):u.page=maxi(1,Value.integer(arg.substr(3),1))
	elif arg=="me":u.sel="persona"
	elif arg.begins_with("sel_"):
		var id=arg.substr(4)
		if id=="persona" or recruited(g,id):u.sel=id
	elif arg=="back":u.sel=""
	elif arg.begins_with("open_"):
		u.panel="codex";u.tab="";u.sel=arg.substr(5) if recruited(g,arg.substr(5)) else ""
	elif arg=="fav":
		if not recruited(g,sel):return
		if not g.get("favs") is Array:g.favs=[]
		if sel in g.favs:
			while sel in g.favs:g.favs.erase(sel)
			u.msg=Locale.u("즐겨찾기에서 뺐습니다.",{},lang)
		elif g.favs.size()>=MAXFAV:u.msg=Locale.u("즐겨찾기는 {max}명까지입니다. 다른 동료를 먼저 빼 주세요.",{"max":MAXFAV},lang)
		else:g.favs.append(sel);u.msg=Locale.u("즐겨찾기에 넣었습니다.",{},lang)
	elif arg=="bag":
		if g.get("scene")=="battle":u.msg=Locale.u("전투 중에는 가방을 열 수 없습니다.",{},lang);return
		var c=cls(DATA.cast[sel].cls) if recruited(g,sel) else {}
		u.panel="status";u.tab="bag";u.bg={"pg":1,"cls":c.get("id",""),"slot":"","rar":"","sel":"","cmp":sel,"conf":""}

static func bag_list(entries: Array,items: Dictionary,filter: Dictionary) -> Array:
	var out=[]
	for e in entries:
		var it=items.get(e.id,{})
		if it.is_empty():continue
		if filter.get("cls","")!="" and it.cls!=filter.cls:continue
		if filter.get("slot","")!="" and it.slot!=filter.slot:continue
		if filter.get("rar","")!="" and it.rarity!=filter.rar:continue
		out.append(e)
	out.sort_custom(func(a,b):
		var x=items[a.id];var y=items[b.id]
		if RK[x.rarity]!=RK[y.rarity]:return RK[x.rarity]>RK[y.rarity]
		if x.lv!=y.lv:return x.lv>y.lv
		if x.id!=y.id:return x.id<y.id
		return a.code<b.code)
	return out
static func comparison(before: Dictionary,after: Dictionary) -> Array:
	var keys=before.keys()
	for k in after:
		if k not in keys:keys.append(k)
	keys.sort_custom(func(a,b):
		var x=DATA.fx_order.find(a);var y=DATA.fx_order.find(b)
		x=99 if x<0 else x;y=99 if y<0 else y
		return a<b if x==y else x<y)
	var out=[]
	for k in keys:
		var d=after.get(k,0)-before.get(k,0);var rounded=signf(d)*floor(absf(d)*10+.5)/10
		out.append({"key":k,"before":before.get(k,0),"after":after.get(k,0),"delta":rounded})
	return out
