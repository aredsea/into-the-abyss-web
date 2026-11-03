extends RefCounted
## Town editor from 29-persona-skill.lua. No scene generation or combat hooks.
const DATA_PATH="res://data/persona_skill.json"
static var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))

static func part(kind: String,id: Variant) -> Dictionary:
	if not id is String:return {}
	for x in data[kind]:
		if x.id==id:return x
	return {}
static func compatible(p: Dictionary,q: Dictionary) -> bool:
	return not p.is_empty() and not q.is_empty() and (p.kind in ["attack","volley"])!=(q.kind in ["regen","guard","crit"])
static func level(t: Variant,id: String) -> int:
	if not t is Dictionary:return 0
	var n=preload("res://game/battle_stats_r23.gd").number(t.get(id,0),0)
	if is_nan(n):return 0
	return int(clampf(floor(float(n)),0,10))
static func clean(raw: Variant) -> Dictionary:
	if not raw is Dictionary:raw={}
	var p=part("prefixes",raw.get("prefix"));var q=part("suffixes",raw.get("suffix"))
	var out={"prefix":p.get("id",""),"suffix":q.id if compatible(p,q) else "","prefix_lv":{},"suffix_lv":{}}
	for pair in [["prefixes","prefix_lv"],["suffixes","suffix_lv"]]:
		for x in data[pair[0]]:
			var n=level(raw.get(pair[1]),x.id)
			if n>0:out[pair[1]][x.id]=n
	return out
static func ready(raw: Variant) -> bool:
	var v=clean(raw)
	return not v.prefix.is_empty() and not v.suffix.is_empty()
static func valid_saved(raw: Dictionary) -> bool:
	var normalized=clean(raw)
	if raw.size()!=4:return false
	for key in ["prefix","suffix"]:
		if not raw.get(key) is String or raw[key]!=normalized[key]:return false
	for key in ["prefix_lv","suffix_lv"]:
		if not raw.get(key) is Dictionary or raw[key].size()!=normalized[key].size():return false
		for id in raw[key]:
			var n=raw[key][id]
			if not (n is int or n is float) or not normalized[key].has(id) or n!=normalized[key][id]:return false
	return true
static func cost(n: int) -> int:return int(data.cost.base+data.cost.step*n*n)
static func num(n: float) -> String:
	var s="%.2f"%n
	while s.ends_with("0"):s=s.left(-1)
	return s.left(-1) if s.ends_with(".") else s
static func pct(n: float) -> int:return int(floor(n*100+.5))
static func skill_name(raw: Variant,en=false,lang: String="ko") -> String:
	var v=clean(raw)
	if not ready(v):return preload("res://game/localization_r22.gd").u("아직 조합하지 않음",{},lang)
	var p=part("prefixes",v.prefix);var q=part("suffixes",v.suffix)
	return p.en+" "+q.en if en or lang=="en" else p.name+" "+q.name
static func description(raw: Variant,en=false,lang: String="ko") -> String:
	var v=clean(raw)
	if not ready(v):return preload("res://game/localization_r22.gd").u("길드장 로레다나에게서 조합할 수 있습니다.",{},lang)
	en=en or lang=="en"
	var p=part("prefixes",v.prefix);var q=part("suffixes",v.suffix)
	var a=level(v.prefix_lv,p.id);var b=level(v.suffix_lv,q.id)
	var power=p.power+p.step*a;var val=q.value+q.step*b;var body=""
	if p.kind in ["attack","volley"]:
		var who=("all enemies" if en else "적 전체") if p.kind=="volley" else ("one enemy" if en else "적 1명")
		body=who+" ×"+num(power)+(", abyss -" if en else ", 심연 −")+str(int(p.brk))
	else:
		var who=("all allies" if en else "아군 전체") if p.kind in ["heal_all","shield_all"] else ("one ally" if en else "아군 1명")
		var fx=("heal" if en else "회복") if p.kind in ["heal","heal_all"] else ("shield" if en else "보호막")
		body=who+" "+fx+" ×"+num(power)
	var tail={
		"bane":"+%d%% damage vs debuffed foes"%pct(val) if en else "약화된 적 피해 +%d%%"%pct(val),
		"tempo":"on kill, gauge +%d%%"%pct(val) if en else "처치 시 행동 게이지 +%d%%"%pct(val),
		"bleed":"damage over time ×%s for 2 turns"%num(2*val) if en else "지속 피해 ×%s 2턴"%num(2*val),
		"weaken":"enemy attack -%d%% for 2 turns"%pct(val) if en else "적 공격 −%d%% 2턴"%pct(val),
		"regen":"regen ×%s for 2 rounds"%num(2*val) if en else "재생 ×%s 2라운드"%num(2*val),
		"guard":"damage taken -%d%% for 2 turns"%pct(val) if en else "받는 피해 −%d%% 2턴"%pct(val),
		"crit":"critical chance +%d points for 2 turns"%pct(val) if en else "치명 +%d%%p 2턴"%pct(val),
		"abyss":"extra abyss -"+num(val) if en else "심연 추가 −"+num(val)}
	return body+"; "+tail[q.kind]+(" (prefix +%d, suffix +%d)"%[a,b] if en else " (접두 +%d, 접미 +%d)"%[a,b])
static func skill(raw: Variant,lang: String="ko") -> Dictionary:
	var v=clean(raw)
	if not ready(v):return {}
	var p=part("prefixes",v.prefix)
	return {"id":"persona_skill","cid":"persona","pv":true,"row":"com","name":skill_name(v,false,lang),"mp":p.mp,"tgt":p.target,"ic":"attack" if p.kind in ["attack","volley"] else "bless","d":description(v,false,lang)}

static func transition(saved: Variant,draft: Variant,spent: int,gold: int,arg: String,busy=false) -> Dictionary:
	var out={"saved":saved.duplicate(true),"draft":draft.duplicate(true) if draft is Dictionary else {},"spent":spent,"gold":gold,"message":""}
	var v=clean(saved if out.draft.is_empty() else out.draft)
	if arg=="ps_save":
		if out.draft.is_empty() or v==clean(saved):out.message="바꾼 내용이 없습니다.";return out
		if not ready(v):out.message="덧효과를 먼저 고르세요.";return out
		if busy:out.message="앞의 장면이 아직 이어지지 않았습니다. 보내기를 눌러 먼저 이어 주세요.";return out
		out.saved=v;out.draft={};out.spent=0
		out.message="저장했습니다. 보내기를 누르면 로레다나와 이야기가 이어집니다."
		return out
	var bits=arg.split("_")
	if bits.size()!=3 or bits[0]!="ps":return out
	var kind=bits[1];var id=bits[2]
	if kind=="pre":
		var p=part("prefixes",id)
		if p.is_empty():return out
		v.prefix=id
		if not compatible(p,part("suffixes",v.suffix)):v.suffix=""
	elif kind=="suf":
		if not compatible(part("prefixes",v.prefix),part("suffixes",id)):return out
		v.suffix=id
	elif kind=="up" and id in ["pre","suf"]:
		var key="prefix" if id=="pre" else "suffix";var selected=v[key]
		if part("prefixes" if id=="pre" else "suffixes",selected).is_empty():return out
		var n=level(v[key+"_lv"],selected)
		if n>=10:out.message="이미 최대 단계입니다.";return out
		var amount=cost(n+1)
		if gold<amount:out.message="금화가 모자랍니다. 필요 금화 %d"%amount;return out
		out.gold-=amount;out.spent+=amount;v[key+"_lv"][selected]=n+1
	else:return out
	out.draft=v
	if v==clean(saved):out.draft={};out.spent=0
	out.message="고유 스킬: %s. 저장하면 확정됩니다."%skill_name(v) if ready(v) else "덧효과를 고르면 스킬이 완성됩니다."
	return out
