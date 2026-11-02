extends "res://game/guild_rules_r21.gd"
## 72-guild and 70-town remaining contracts. Reuse the already verified RNG.
const Text=preload("res://game/localization_r22.gd")
const TITLE_WORDS={"균열 핵 토벌":"Destroy the rift core","고립된 탐사대 구조":"Rescue the stranded expedition","잃어버린 유품 회수":"Recover the lost keepsake"}
static func title_word(value: String) -> String:return TITLE_WORDS.get(value,Text.t(value,"en"))
static func title(q: Dictionary,lang="ko") -> String:
	var prefix=q.get("rift","")+", ";var value=q.get("title","")
	if value.begins_with(prefix):return title_word(q.get("rift",""))+": "+title_word(value.substr(prefix.length())) if lang=="en" else value
	return title_word(value) if lang=="en" else value

static func title_en(q: Dictionary) -> String:
	var prefix=q.get("rift","")+", ";var value=q.get("title","")
	if value.begins_with(prefix):return title_word(q.get("rift",""))+", "+title_word(value.substr(prefix.length()))
	return title_word(value)

static func find_quest(board: Array,id: Variant) -> Variant:
	if id==null or (id is bool and not id) or (id is String and id==""):return null
	for q in board:
		if _id_equal(q.get("id"),id):return q
	return null

static func remove_quest(board: Array,id: Variant) -> bool:
	for i in range(board.size()):
		if _id_equal(board[i].get("id"),id):board.remove_at(i);return true
	return false

static func _id_equal(a: Variant,b: Variant) -> bool:
	if typeof(a)==typeof(b):return a==b
	return a==b if (a is int or a is float) and (b is int or b is float) else false

static func fight(q: Dictionary) -> String:
	var d=q.get("difficulty","")
	if q.get("kind","")=="토벌":return "core"
	return "battle" if d=="낮음" else "elite"

static func loss(gold: int,stars: int) -> int:
	return int(floor(mini(gold,100*stars)/2.0))

static func source_id(q: Dictionary) -> int:
	return int(str(q.get("source_id",q.get("id",0))).trim_prefix("q").trim_prefix("legacy-"))

static func source_view(q: Dictionary) -> Dictionary:
	var out=q.duplicate(true)
	out.id="q"+str(source_id(q));out.erase("source_id");out.erase("name");out.erase("level");out.erase("elite")
	out.cmp=1
	return out
