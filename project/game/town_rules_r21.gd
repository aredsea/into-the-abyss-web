extends RefCounted
static var DATA=JSON.parse_string(FileAccess.get_file_as_string("res://data/town-r21-rules.json"))

static func shop_price(amount: float,count: int) -> int:
	return maxi(1,int(floor(amount*(.88 if count>=3 else .94 if count>=2 else 1.0)+.5)))

static func aff_next(value: float,amount: float) -> float:
	if amount<=0: return maxf(DATA.aff.min,floor((value+amount)*100+.5)/100)
	var room=maxf(0,DATA.aff.soft-value)
	var out=value+amount if amount<=room else maxf(value,DATA.aff.soft)+(amount-room)*DATA.aff.slow
	return minf(DATA.aff.max,floor(out*100+.5)/100)

static func aff_stage(value: float) -> String:
	if value<=-60: return "적대"
	if value<=-20: return "불신"
	if value<20: return "낯섦"
	if value<50: return "신뢰"
	if value<80: return "유대"
	if value<100: return "깊은 인연"
	if value<150: return "맹세"
	return "운명"

static func recruit_cost(count: int) -> int: return 100+20*count
static func refresh_cost(count: int) -> int: return 10*(1<<mini(count,4))

static func need(level: int) -> int:
	var v=clampi(level,1,40)
	var k=.4 if v<10 else (.6+.4*(v-10)/20.0 if v<30 else 1.0)
	return int(floor((60*v+10*v*v)*k+.5))
