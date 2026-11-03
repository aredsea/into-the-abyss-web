extends RefCounted
## Read-only presentation of persisted source chronicle strings, including old saves.
const L=preload("res://game/localization_r22.gd")
const C=preload("res://game/chronicle_store_r22.gd")
static var names={}
static func ko(value: String) -> String:
	if names.is_empty():
		for key in C.DATA.english:
			var en=C.DATA.english[key]
			if en is String and en!=key:names[en]=L.canonical_names(key)
	return names.get(value,value)
static func body(value: String,lang: String) -> String:
	if lang=="en":return C.converted(value)
	var rules=[
		["^First met (.*?), who joined as a companion\\.$","meet"],
		["^(.*?) joined as a companion through a guild introduction\\.$","guild"],
		["^Completed the quest '(.*)'\\.$","quest_ok"],
		["^Failed the quest '(.*)'\\.$","quest_fail"],
		["^Cleared Great Dungeon floor ([0-9]+); boss: (.*)$","clear"],
		["^Retreated from Great Dungeon floor ([0-9]+)$","retreat"],
		["^First defeated (.*?), the zone boss of (.*)$","zone"],
		["^Failed the Great Dungeon floor ([0-9]+) run(.*)$","fail"],
		["^After clearing floor ([0-9]+), descended directly to floor ([0-9]+)$","next"],
		["^Returned to Torva after clearing floor ([0-9]+)$","home"],
		["^(.*?)'s affection (rose|fell) to (.*)\\.$","aff"],
		["^Obtained legendary gear: (.*)\\.$","gear"],
		["^Leveled up: (.*)$","level"]]
	for rule in rules:
		var re=RegEx.new();re.compile(rule[0]);var m=re.search(value)
		if m==null:continue
		var a=m.get_string(1);var b=m.get_string(2) if m.get_group_count()>1 else ""
		match rule[1]:
			"meet":return ko(a)+L.Josa.tail(ko(a),"와과","ko")+" 첫 만남, 동료로 함께하게 되었다"
			"guild":return ko(a)+L.Josa.tail(ko(a),"이가","ko")+" 길드 소개로 동료가 되었다"
			"quest_ok":return "의뢰 「"+ko(a)+"」를 완료했다"
			"quest_fail":return "의뢰 「"+ko(a)+"」에 실패했다"
			"clear":return "대던전 "+a+"층 돌파, 보스 "+ko(b)
			"retreat":return "대던전 "+a+"층에서 퇴각"
			"zone":return ko(b)+" 구역 보스 "+ko(a)+" 처음 쓰러뜨렸다"
			"home":return "대던전 "+a+"층 돌파 뒤 토르바로 돌아갔다"
			"next":return "대던전 "+a+"층 돌파 뒤 곧장 "+b+"층으로 내려갔다"
			"fail":return "대던전 "+a+"층 도전 실패"+(", 보스 "+ko(b.trim_prefix(" before boss "))+" 앞에서 무너졌다" if b.begins_with(" before boss ") else " (보스 전)" if b!="" else "")
			"aff":return ko(a)+"의 호감이 "+ko(m.get_string(3))+" 단계로 "+("올랐다" if b=="rose" else "내려갔다")
			"gear":return "전설 장비 획득: "+ko(a)
			"level":
				var lines=[]
				for raw in a.split(","):
					var part=raw.strip_edges();var at=part.find(" Lv ");lines.append(ko(part.left(at))+part.substr(at) if at>=0 else ko(part))
				return "레벨이 올랐다: "+", ".join(lines)
	return ko(value)
static func entry(value: String,s: Dictionary) -> Dictionary:
	var re=RegEx.new();re.compile("^Day (-?[0-9]+): (.*)$");var m=re.search(value)
	var lang=L.language(s)
	return {"day":("Day "+m.get_string(1) if lang=="en" else m.get_string(1)+"일째") if m else "","text":L.display(body(m.get_string(2) if m else value,lang),s)}
