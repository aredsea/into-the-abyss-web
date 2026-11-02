extends RefCounted
## Non-host contract of 88-lore. Data is extracted, public profiles only.
const DATA=preload("res://data/chronicle-r22.json").data
static func movable(g: Dictionary) -> bool:return g.get("scene","") in ["town","guild","shop","inn","smithy"]
static func place_id(g: Dictionary) -> String:
	var scene=g.get("scene","")
	if scene in ["guild","shop","inn","smithy"]:return scene
	if scene!="town":return ""
	var p=g.get("place","")
	return p if p is String and p!="smithy" and DATA.places.has(p) else "town"
static func set_place(g: Dictionary,pid: String) -> bool:
	if not DATA.places.has(pid) or not movable(g):return false
	var d=DATA.places[pid]
	if pid=="smithy":
		for key in ["forge_fx","proc_fx","sm_work"]:g.erase(key)
	g.scene=d.scene;g.place=pid if d.scene=="town" and pid!="town" else ""
	if not g.get("ui") is Dictionary:g.ui={}
	g.ui.sel="";g.ui.tab="";return true
static func residents(pid: String) -> Array:return DATA.npcs.get(pid,[]).duplicate()
static func profile(id: String) -> Dictionary:return DATA.profiles.get(id,{})
static func public_lines(id: String) -> Array:return profile(id).get("lines",[])
