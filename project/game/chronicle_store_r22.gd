extends RefCounted
## Engine-confirmed facts only. No AI summary, prompt injection or chat host.
const DATA=preload("res://data/chronicle-r22.json").data
const Aff=preload("res://game/affection_r22.gd")
static func ensure(s: Dictionary) -> void:
	if not s.has("chronicle_r22"):s.chronicle_r22={"list":[],"queue":[]}
static func valid(s: Dictionary) -> bool:
	if not s.has("chronicle_r22"):return true
	var c=s.chronicle_r22
	if not c is Dictionary or not c.get("list") is Array or not c.get("queue") is Array:return false
	if c.list.size()>int(DATA.limits.max) or c.queue.size()>4096:return false
	for line in c.list+c.queue:
		if not line is String or line.length()>int(DATA.limits.line):return false
	return true
static func english(s: String) -> String:
	s=preload("res://game/localization_r22.gd").canonical_names(s)
	return str(DATA.english.get(s,s))
static func converted(t: String) -> String:
	var rules=[
		["^(.*?) 첫 만남, 동료로 함께하게 되었다$","meet"],
		["^(.*?) 길드 소개로 동료가 되었다$","guild"],
		["^의뢰 「(.*?)」를 완료했다$","quest_ok"],
		["^의뢰 「(.*?)」에 실패했다$","quest_fail"],
		["^레벨이 올랐다: (.+)$","level"],
		["^대던전 ([0-9]+)층 돌파, 보스 (.+)$","clear"],
		["^대던전 ([0-9]+)층에서 퇴각$","retreat"],
		["^(.*?) 구역 보스 (.*?) 처음 쓰러뜨렸다$","zone"],
		["^대던전 ([0-9]+)층 도전 실패(.*)$","fail"],
		["^대던전 ([0-9]+)층 돌파 뒤 곧장 ([0-9]+)층으로 내려갔다$","next"],
		["^대던전 ([0-9]+)층 돌파 뒤 토르바로 돌아갔다$","home"]]
	for r in rules:
		var re=RegEx.new();re.compile(r[0]);var m=re.search(t)
		if m==null:continue
		var a=m.get_string(1);var b=m.get_string(2) if m.get_group_count()>=2 else ""
		match r[1]:
			"meet":return "First met "+english(a.left(-1))+", who joined as a companion."
			"guild":return english(a.left(-1))+" joined as a companion through a guild introduction."
			"quest_ok":return "Completed the quest '"+english(a)+"'."
			"quest_fail":return "Failed the quest '"+english(a)+"'."
			"clear":return "Cleared Great Dungeon floor "+a+"; boss: "+english(b)
			"retreat":return "Retreated from Great Dungeon floor "+a
			"zone":return "First defeated "+english(b.left(-1))+", the zone boss of "+english(a)
			"next":return "After clearing floor "+a+", descended directly to floor "+b
			"home":return "Returned to Torva after clearing floor "+a
			"fail":
				var f=RegEx.new();f.compile("^, 보스 (.*?) 앞에서 무너졌다$");var boss=f.search(b)
				return "Failed the Great Dungeon floor "+a+" run"+(" before boss "+english(boss.get_string(1)) if boss else " before the boss" if b!="" else "")
			"level":
				var re2=RegEx.new();re2.compile("([^,]+) Lv ([0-9]+) → ([0-9]+)")
				var line="";var pos=0
				for x in re2.search_all(a):
					line+=a.substr(pos,x.get_start()-pos)+english(x.get_string(1).strip_edges(true,false))+" Lv "+x.get_string(2)+" → "+x.get_string(3);pos=x.get_end()
				return "Leveled up: "+line+a.substr(pos)
	return t
static func add(s: Dictionary,text: String,day: float=-999999) -> void:
	if s.get("settings",{}).get("chron",1)==0:return
	var re=RegEx.new();re.compile("[ \\t\\r\\n\\f\\v]+")
	text=re.sub(converted(text)," ",true)
	if text=="":return
	ensure(s)
	var d=int(floor(s.get("town",{}).get("day",s.get("day",1)) if day==-999999 else day))
	var line=("Day %d: "%d+text).left(int(DATA.limits.line))
	if line not in s.chronicle_r22.queue:s.chronicle_r22.queue.append(line)
static func merged(history: Array,queue: Array) -> Array:
	var list=history.duplicate()
	for line in queue:
		var dup=false
		for i in range(maxi(0,list.size()-int(DATA.limits.dedup)),list.size()):
			if list[i]==line:dup=true
		if not dup:list.append(line)
	return list.slice(maxi(0,list.size()-int(DATA.limits.max)))
static func entries(s: Dictionary) -> Array:
	var c=s.get("chronicle_r22",{"list":[],"queue":[]});return merged(c.list,c.queue)
static func flush(s: Dictionary) -> void:
	ensure(s);s.chronicle_r22.list=entries(s);s.chronicle_r22.queue=[]
static func affection_changed(s: Dictionary,cid: String,before: float,after: float,day: float=-999999) -> void:
	# Public event boundary for D choice dialogue and all native affection writers.
	if Aff.stage(before)==Aff.stage(after):return
	var name=DATA.profiles.get(cid,{}).get("name",cid)
	for c in preload("res://data/panels-r22.json").data.cast:
		if c==cid:name=preload("res://data/panels-r22.json").data.cast[c].name;break
	add(s,english(name)+"'s affection "+("rose" if after>before else "fell")+" to "+english(Aff.stage(after))+".",day)
static func legendary(s: Dictionary,item: Dictionary,day: float=-999999) -> void:
	if item.get("rarity","")=="legend":add(s,"Obtained legendary gear: "+english(item.name)+".",day)
