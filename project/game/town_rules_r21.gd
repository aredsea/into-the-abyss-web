extends RefCounted
static var DATA=JSON.parse_string(FileAccess.get_file_as_string("res://data/town-r21-rules.json"))
const SourceValue=preload("res://game/ui_value_r23.gd")

static func source_town(g: Dictionary) -> Dictionary:
	# Transient source boundary, shared by experience awards. Persisted native
	# saves keep their existing schema and validation before they reach this code.
	if not g.get("town") is Dictionary:g.town={}
	var t=g.town
	for pair in [["bn",0],["day",1],["rr",0]]:
		if not SourceValue.truth(t.get(pair[0])):t[pair[0]]=pair[1]
	if not (t.get("acts") is Dictionary or t.get("acts") is Array):t.acts={}
	if not g.get("guild") is Dictionary:g.guild={"quests":[],"active":"","done":0,"recruits":0,"tickets":0}
	if not (g.guild.get("quests") is Dictionary or g.guild.get("quests") is Array):g.guild.quests=[]
	return t

static func aff_r2(value: float) -> float:return floor(value*100+.5)/100

static func inn_act_visible(_g: Variant,_act: Variant,_cid: Variant) -> bool:
	return true

static func aff_add_source(g: Dictionary,cid: Variant,amount: Variant,chron_aff: Callable=Callable()) -> float:
	if not g.get("aff") is Dictionary:g.aff={}
	if cid==null or cid=="" or cid=="persona":return 0
	var numeric=preload("res://game/battle_stats_r23.gd")
	var before=numeric.number(g.aff.get(cid),0)
	var after=aff_next(before,numeric.number(amount,0));g.aff[cid]=after
	if chron_aff.is_valid():chron_aff.call(g,cid,before,after)
	return aff_r2(after-before)

static func aff_fmt(value: Variant) -> String:
	var number=0.0
	if value is int or value is float:number=float(value)
	elif value is String:
		var raw=value.strip_edges()
		if raw.to_lower().trim_prefix("-").trim_prefix("+").begins_with("0x") and raw.is_valid_hex_number(true):number=raw.hex_to_int()
		elif raw.is_valid_float():number=float(raw)
	var rounded=aff_r2(number)
	return str(int(rounded)) if rounded==floor(rounded) else "%.1f"%rounded

static func shop_price(amount: float,count: int) -> int:
	return maxi(1,int(floor(amount*(.88 if count>=3 else .94 if count>=2 else 1.0)+.5)))

static func aff_next(value: float,amount: float) -> float:
	if amount<=0: return maxf(DATA.aff.min,aff_r2(value+amount))
	var room=maxf(0,DATA.aff.soft-value)
	var out=value+amount if amount<=room else maxf(value,DATA.aff.soft)+(amount-room)*DATA.aff.slow
	return minf(DATA.aff.max,aff_r2(out))

static func aff_stage(value: float) -> String:
	if value<=-60: return "적대"
	if value<=-20: return "불신"
	if value<20: return "낯섦"
	if value<50: return "신뢰"
	if value<80: return "유대"
	if value<100: return "깊은 인연"
	if value<150: return "맹세"
	return "운명"

# 72-guild.gd_tier predates the negative affection stages. The ordinary inn and
# recruitment panel still use that source contract, rather than aff_stage.
static func guild_tier(value: Variant=0) -> String:
	if value==null or (value is bool and value==false):value=0
	if value>=150:return "운명"
	if value>=100:return "맹세"
	if value>=80:return "깊은 인연"
	if value>=50:return "유대"
	if value>=20:return "신뢰"
	return "낯섦"

static func recruit_cost(count: int) -> int: return 100+20*count
static func refresh_cost(count: int) -> int: return 10*(1<<mini(count,4))

static func need(level: int) -> int:
	var v=clampi(level,1,40)
	var k=.4 if v<10 else (.6+.4*(v-10)/20.0 if v<30 else 1.0)
	return int(floor((60*v+10*v*v)*k+.5))
