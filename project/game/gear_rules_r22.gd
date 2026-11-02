extends "res://game/commerce_rules_r21.gd"
## 81-gear pure rules. The existing native RNG path remains in the parent.
## Code strings use the original table version; never infer code identity from UID.
const SLOTS=["weapon","armor","acc"]
const BAG_MAX=2000
var source=JSON.parse_string(FileAccess.get_file_as_string("res://data/gear-r22.json"))
var dungeon=D.new()

func code(entry: Dictionary) -> String:
	if entry.get("code") is String and not gear_parse(entry.code).is_empty():return entry.code
	return gear_code(entry.id,int(entry.seed))

func gear_code(id: String,seed: Variant) -> String:
	# Integer division is intentional: float division loses the low base36 digits.
	var value: Variant=seed
	if value is String:
		value=value.strip_edges()
		value=value.hex_to_int() if value.is_valid_hex_number(true) and value.trim_prefix("-").trim_prefix("+").begins_with("0x") else (int(value) if value.is_valid_int() else (float(value) if value.is_valid_float() else 0))
	if not (value is int or value is float):value=0
	if value is float:value=int(floor(absf(value))) if is_finite(value) and absf(value)<9223372036854775808.0 else 0
	var n=posmod(value if value==-9223372036854775808 else absi(value),4738381338321616896);var digits=""
	while n>0:
		digits="0123456789abcdefghijklmnopqrstuvwxyz"[n%36]+digits;n=n/36
	return id+"."+(digits if digits!="" else "0")+"."+str(int(source.v))

func gear_parse(value: Variant) -> Dictionary:
	if not value is String:return {}
	var re=RegEx.new();re.compile("\\A([a-z0-9]+)\\.([0-9a-z]{1,12})\\.([0-9]+)\\z")
	var m=re.search(value)
	if m==null or int(m.get_string(3))!=int(source.v):return {}
	var seed=0
	for c in m.get_string(2):seed=seed*36+"0123456789abcdefghijklmnopqrstuvwxyz".find(c)
	return {"id":m.get_string(1),"seed":seed,"v":int(m.get_string(3))}

func gear_roll(value: Variant,wearer_lv: Variant=null,forge_lv: float=0) -> Dictionary:
	var p=gear_parse(value)
	if p.is_empty() or not source.items.has(p.id):return {}
	var it=source.items[p.id];var fx=source.fx;var pool=source.pools[it.cls][it.slot].duplicate()
	var affix=[];var raw=0.0;var fixed=0.0;var out=it.base.duplicate(true)
	for k in it.base:fixed+=it.base[k]*fx.base[k].eff
	var un=it.get("unique",{})
	if not un.is_empty():
		if un.get("sig",false):fixed+=un.e
		else:
			var rule=fx.proc[un.key]
			fixed+=un.p*un.x*maxf(un.n,1)*rule.k if rule.get("k",0)!=0 else un.x*rule.get("flat_eff",0)
	for i in range(mini(int(fx.rarity[it.rarity].affix),pool.size())):
		var j=i+int(floor(D.mix(int(p.seed),1,i+1,0)*(pool.size()-i)))
		var k=pool[j];pool[j]=pool[i];pool[i]=k
		var rg=source.range[k];var v=rg[0]+(rg[1]-rg[0])*D.mix(int(p.seed),2,i+1,0)*(.4+.6*it.lv/40.0)
		affix.append([k,v]);raw+=v*fx.affix[k].eff
	var score=fixed
	for a in affix:score+=r1(a[1])*fx.affix[a[0]].eff
	var trim=score>it.get("cap",fx.cap)+1e-9
	var scale=maxf(0,it.get("cap",fx.cap)-fixed)/raw if trim and raw>0 else 0.0
	score=fixed
	for a in affix:
		a[1]=floor(a[1]*scale*10)/10 if trim else r1(a[1])
		out[a[0]]=out.get(a[0],0)+a[1];score+=a[1]*fx.affix[a[0]].eff
	if wearer_lv!=null and not (wearer_lv is bool and wearer_lv==false):
		var lv=clampi(int(floor(float(wearer_lv))),1,40)
		var mult=(.4+.6*lv/40.0)/(.4+.6*it.lv/40.0)*(1+clampf(forge_lv,0,10)*fx.forge.bonus_per_level)
		for k in out:out[k]=r1(out[k]*mult)
		for a in affix:a[1]=r1(a[1]*mult)
		score*=mult
	var result={"id":p.id,"item":it,"lv":fx.equip_lv[it.rarity],"slot":it.slot,"rarity":it.rarity,"fx":out,"affix":affix,"score":score,"v":p.v,"seed":p.seed}
	if not un.is_empty():result.unique=un
	return result

static func r1(x: float) -> float:return floor(x*10+.5)/10

func gear_price(value: Variant) -> Variant:
	var p=gear_parse(value)
	if p.is_empty() or not source.items.has(p.id):return null
	var it=source.items[p.id];var s=source.fx.sell[it.rarity]
	return s[0]+s[1]*it.lv

func gear_icon(item: Dictionary) -> Variant:
	return "gl-"+item.id if source.gl.has(item.get("id")) else source.shape_css.get(item.get("shape"))

func gear_btn(value: String) -> String:return value.replace(".","_")
func gear_unbtn(value: String) -> Variant:
	var re=RegEx.new();re.compile("^([a-z0-9]+)_([0-9a-z]+)_([0-9]+)$");var m=re.search(value)
	return m.get_string(1)+"."+m.get_string(2)+"."+m.get_string(3) if m!=null else null

func bag_load(raw: Variant) -> Array:
	var out=[]
	if raw is String:
		for c in raw.split(";",false):
			var p=gear_parse(c)
			if not p.is_empty() and source.items.has(p.id):out.append(c)
	return out

func bag_add(list: Array,value: String) -> bool:
	# Original accepts syntactically valid unknown IDs here; bag_load filters them.
	if list.size()>=BAG_MAX or gear_parse(value).is_empty():return false
	list.append(value);return true

func bag_take(list: Array,value: String) -> bool:
	var i=list.find(value)
	if i<0:return false
	list.remove_at(i);return true

func class_id(raw: String) -> String:
	for c in source.classes:
		if raw==c.id or raw==c.name:return c.id
	return ""

func level_of(g: Dictionary,cid: String) -> int:
	return int(g.get("persona",{}).get("lv",1)) if cid=="persona" else int(g.get("lvl",{}).get(cid,1))

func gear_can_equip(g: Dictionary,cid: String,value: String) -> Array:
	var r=gear_roll(value)
	if r.is_empty():return [false,"알 수 없는 장비입니다."]
	var cls=class_id(g.get("persona",{}).get("cls","")) if cid=="persona" else class_id(source.cast.get(cid,{}).get("cls",""))
	if cls=="":return [false,"직업을 알 수 없습니다."]
	if r.item.cls!=cls:return [false,"다른 직업 전용 장비입니다."]
	if r.lv>level_of(g,cid):return [false,"Lv "+str(int(r.lv))+"부터 낄 수 있습니다."]
	return [true]

func forge_state(g: Dictionary,value: String) -> Dictionary:
	if not g.get("forge") is Dictionary:g.forge={}
	if not g.forge.get(value) is Dictionary:g.forge[value]={"lv":0,"tries":0}
	return g.forge[value]

func forge_code_cost(value: String,next_lv: float) -> Variant:
	var p=gear_parse(value)
	if p.is_empty() or not source.items.has(p.id) or next_lv<1 or next_lv>10:return null
	return source.fx.forge.cost_base[source.items[p.id].rarity]*next_lv*next_lv

func smithy_list(g: Dictionary,bag: Array) -> Array:
	var out=[]
	for c in bag:
		if c is String and not gear_roll(c).is_empty() and c not in out:out.append(c)
	for eq in (g.equip.values() if g.get("equip") is Dictionary else []):
		if eq is Dictionary:
			for s in SLOTS:
				var c=eq.get(s,"")
				if c is String and not gear_roll(c).is_empty() and c not in out:out.append(c)
	out.sort();return out

func forge_try(g: Dictionary,bag: Array,value: String) -> Array:
	if value not in smithy_list(g,bag):return [null,"장비를 찾을 수 없습니다."]
	var f=forge_state(g,value)
	if f.lv>=10:return [null,"이미 +10입니다."]
	var next_lv=int(f.lv)+1;var cost=forge_code_cost(value,next_lv)
	if g.get("gold",0)<cost:return [null,"금화가 모자랍니다."]
	var key=0
	for byte in value.to_utf8_buffer():key=(key*131+byte)%2147483647
	var ok=D.mix(int(g.get("seed",0))+key,int(f.tries)+1,next_lv,41)*100<source.fx.forge.success[next_lv-1]
	g.gold-=cost;f.tries+=1
	if ok:f.lv=next_lv
	return [ok,cost]

func process_level(g: Dictionary) -> int:
	var top=level_of(g,"persona")
	for cid in g.get("roster",[]):top=maxi(top,level_of(g,cid))
	return top

func process_classes(g: Dictionary) -> Array:
	var out=[];var raw=[g.get("persona",{}).get("cls","")]
	for cid in g.get("roster",[]):raw.append(source.cast.get(cid,{}).get("cls",""))
	for r in raw:
		var cls=class_id(r)
		if cls!="" and cls not in out:out.append(cls)
	if out.is_empty():
		for id in source.order:
			if source.items[id].cls not in out:out.append(source.items[id].cls)
	return out

func process_roll(g: Dictionary,n: int) -> String:
	var e=process_source(int(g.get("seed",0)),n,process_classes(g),process_level(g))
	return gear_code(e.id,int(e.seed)) if not e.is_empty() else ""

func process_try(g: Dictionary,bag: Array) -> Array:
	var b=band(process_level(g))
	if g.get("gold",0)<b.price:return [false,"금화가 모자랍니다."]
	if bag.size()>=BAG_MAX:return [false,"가방이 가득 찼습니다."]
	if not g.get("town") is Dictionary:g.town={}
	var n=int(g.town.get("process_n",0))+1;var value=process_roll(g,n)
	if value=="" or not bag_add(bag,value):return [false,"지금은 가공할 수 없습니다."]
	g.gold-=b.price;g.town.process_n=n;return [true,value]

func gear_equip(g: Dictionary,bag: Array,cid: String,value: String) -> Array:
	var can=gear_can_equip(g,cid,value)
	if not can[0]:return can
	var slot=gear_roll(value).slot
	if not g.get("equip") is Dictionary:g.equip={}
	if not g.equip.get(cid) is Dictionary:g.equip[cid]={}
	var eq=g.equip[cid]
	if not bag_take(bag,value):return [false,"가방에 없는 장비입니다."]
	var old=eq.get(slot,"");eq[slot]=value
	if old is String and old!="":bag_add(bag,old)
	return [true]

func gear_unequip(g: Dictionary,bag: Array,cid: String,slot: String) -> Array:
	var eq=g.get("equip",{}).get(cid,{});var cur=eq.get(slot,"")
	if not cur is String or cur=="":return [false,"끼고 있는 장비가 없습니다."]
	if not bag_add(bag,cur):return [false,"가방이 가득 찼습니다."]
	eq[slot]="";return [true]

func gear_restrict(g: Dictionary,bag: Array) -> bool:
	if not g.get("equip") is Dictionary:return false
	var changed=false
	for cid in g.equip:
		var eq=g.equip[cid]
		if not eq is Dictionary:continue
		for slot in SLOTS:
			var c=eq.get(slot,"")
			if c is String and c!="" and not gear_can_equip(g,cid,c)[0] and bag_add(bag,c):eq[slot]="";changed=true
	return changed

func gear_sell(g: Dictionary,bag: Array,value: String) -> Array:
	var price=gear_price(value)
	if price==null or not bag_take(bag,value):return [false]
	g.gold=g.get("gold",0)+price;return [true,price]

func gear_sell_common(g: Dictionary,bag: Array) -> Array:
	var keep=[];var n=0;var gold=0
	for value in bag:
		var p=gear_parse(value);var it=source.items.get(p.get("id",""),{})
		if it.get("rarity")=="common":n+=1;gold+=gear_price(value)
		else:keep.append(value)
	if n>0:bag.assign(keep);g.gold=g.get("gold",0)+gold
	return [n,gold]

func gear_label(value: String) -> String:
	var r=gear_roll(value)
	return "알 수 없는 장비" if r.is_empty() else r.item.name+" ("+RARITY[r.rarity]+", Lv "+str(int(r.lv))+")"

func gear_drop(seed: int,f: int,kind: String,party_cls: Array=[]) -> Dictionary:
	# The existing r21 selection already follows current 81-gear reservoir draws.
	# Every future grant must pass through gear_save_r22.source_drop to retain this
	# seed's original option path. Never relabel old native drops retroactively.
	return dungeon.gear_drop(seed,f,kind,party_cls)

func gear_drop_p(kind: String) -> float:return source.fx.drop.chance.get(kind,0)
func gear_party_cls(pm: Array) -> Array:
	var out=[]
	for m in pm:
		if m.get("id","")!="" and m.get("cls","")!="":
			var cls=class_id(m.cls)
			if cls!="" and cls not in out:out.append(cls)
	return out

func gear_context(g: Dictionary) -> String:
	if not g.get("equip") is Dictionary:return ""
	var who=[];var lines=[]
	if g.get("persona") is Dictionary and g.persona.get("fight",1)!=0:who.append("persona")
	who.append_array(g.get("party",[]))
	for cid in who:
		var eq=g.equip.get(cid,{});var parts=[]
		if not eq is Dictionary:continue
		for slot in SLOTS:
			var p=gear_parse(eq.get(slot));var it=source.items.get(p.get("id",""),{})
			if it.get("rarity")=="legend":parts.append(it.name)
		if not parts.is_empty():lines.append(("{{user}}" if cid=="persona" else source.cast.get(cid,{}).get("name",cid))+"의 전설 장비: "+", ".join(parts))
	return "\n".join(lines)

func gear_migrate(g: Dictionary) -> bool:
	# Source eq_* prototypes had no stats. Preserve removed values in an archive
	# instead of losing user data when applying the source's one-time cleanup.
	if not g.get("settings") is Dictionary:return false
	var version=g.settings.get("gear_v")
	if version!=null and not (version is bool and version==false):return false
	g.settings.gear_v=1
	var archive={"equip":{},"items":{}};var hit=false
	if g.get("equip") is Dictionary:
		for cid in g.equip:
			var eq=g.equip[cid]
			if not eq is Dictionary:continue
			for slot in eq:
				if eq[slot] is String and eq[slot].begins_with("eq_"):
					if not archive.equip.has(cid):archive.equip[cid]={}
					archive.equip[cid][slot]=eq[slot];eq[slot]="";hit=true
	if g.get("items") is Dictionary:
		for key in g.items.keys():
			if key is String and key.begins_with("eq_"):archive.items[key]=g.items[key];g.items.erase(key);hit=true
	if hit:
		g.gear_r22_prototypes=archive
		if g.get("ui") is Dictionary:g.ui.msg="옛 장비(능력치 없던 시제품)는 새 장비 체계로 바뀌며 정리되었습니다."
	return hit

func gear_eq_of(g: Dictionary,cid: String) -> Variant:
	var out={};var eq=gear_equipment_table(g).get(cid,{})
	if eq is Dictionary:
		for s in SLOTS:
			if eq.get(s) is String and eq[s]!="":out[s]=eq[s]
	return out if not out.is_empty() else null

func gear_equipment_table(g: Dictionary) -> Dictionary:
	return g.equip if g.get("equip") is Dictionary else {}

func gear_pm_refresh(g: Dictionary,pm: Array) -> void:
	for m in pm:
		if m.id!="":
			var eq=gear_eq_of(g,m.id)
			if eq==null:m.erase("eq")
			else:m.eq=eq
			if g.has("forge"):m.forge=g.forge
			else:m.erase("forge")

func roll(entry: Dictionary,level: int) -> Dictionary:
	return gear_roll(code(entry),level,float(entry.get("forge",0))).get("fx",{}) if entry.get("source_r21",false) else super(entry,level)
