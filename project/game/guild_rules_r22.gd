extends "res://game/guild_rules_r21.gd"
## 72-guild and 70-town remaining contracts. Reuse the already verified RNG.
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
