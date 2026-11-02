extends RefCounted
## Canonical 20-state / 30-engine / 32-personal event clock. The native
## r17-r20 renderer remains the presentation owner; this is the engine contract.
var events=[]
var T=.15
var context={}
func slot(b,u: Dictionary) -> int: return (b.data.allies+b.data.enemies).find(u)+1
func slots(b,list: Array) -> Array: return list.map(func(u):return slot(b,u))
func push(kind: String,actor: int,start: float,targets: Array=[],hit: float=-1) -> void:
	events.append({"k":kind,"a":actor,"t":start,"ht":hit,"targets":targets.duplicate()})
func begin(b,id: String,a: Dictionary,e: Dictionary,t: Dictionary) -> void:
	context={"id":id,"actor":slot(b,a),"owner":a.id,"enemy":slot(b,e),"ally":slot(b,t),"friends":slots(b,b.living(true)),"foes":slots(b,b.living(false)),"row":[]}
	for member in b.living(true):
		if member.id!=a.id and member.row==a.row: context.row.append(slot(b,member))
	if id=="personal":
		push("cut",context.actor,T)
		T+=1.9 if a.id in ["levia","marceline","naran","teiris"] else 1.4
func body_spec() -> Array:
	var id=context.id; var owner=context.owner
	if id=="defend": return ["def",-1,1.0,"none"]
	if id=="personal":
		if owner=="haldric" and context.row.is_empty(): return ["def",-1,1.4,"none"]
		return {
			"levia":["rev",-1,1.2,"none"],"marceline":["oath",-1,1.6,"ally"],"naran":["mark",-1,1.7,"enemy"],
			"teiris":["burst",2.45,3.9,"foes"],"haldric":["oath",-1,1.4,"row"],"erdene":["taunt",-1,1.9,"enemy"],
			"bianca":["atk",.5,1.5,"enemy"],"saya":["mark",-1,1.7,"enemy"],"gerda":["atk",.8,1.5,"enemy"],
			"judith":["mark",-1,1.7,"enemy"],"urda":["oath",-1,1.6,"ally"],"lynette":["shield",-1,2.8,"friends"],
			"sorel":["shield",-1,2.4,"friends"],"tika":["rev",-1,1.2,"none"],"hedwig":["atk",.8,1.7,"enemy"],
			"hildegard":["taunt",-1,1.9,"enemy"],"felice":["shield",-1,1.8,"ally"],"selva":["atk",.45,1.4,"enemy"],
			"gunhild":["atk",.5,1.5,"enemy"],"jorund":["atk",.45,1.4,"enemy"],"bargut":["atk",.45,1.4,"enemy"],
			"berenga":["shield",-1,1.8,"ally"],"altan":["shield",-1,1.6,"none"],"colette":["mark",-1,1.7,"enemy"],
			"ornel":["atk",.6,1.5,"enemy"],"zahar":["wave",.6,2.0,"foes"],"tove":["taunt",-1,1.9,"enemy"],
			"miko":["shield",-1,1.8,"ally"],"adeline":["shield",-1,1.8,"friends"],"lavinia":["atk",.5,1.5,"enemy"]
		}.get(owner,["atk",.4,1.3,"enemy"])
	return {
		"attack":["atk",.45,1.3,"enemy"],"guard":["def",-1,1.0,"none"],"taunt":["taunt",-1,1.9,"enemy"],"ptaunt":["taunt",-1,1.9,"enemy"],
		"pshield":["shield",-1,2.8,"friends"],"hshield":["shield",-1,2.8,"friends"],"snipe":["snipe",1.0,1.9,"enemy"],"burst":["chg",-1,2.0,"enemy"],
		"ruin":["wave",.6,2.0,"foes"],"bless":["shield",-1,1.6,"none"],"heal":["shield",-1,1.8,"friends"],"acid":["mark",-1,1.5,"enemy"],
		"tonic":["def",-1,1.3,"none"],"blood":["rev",-1,1.2,"none"],"rift":["atk",.5,1.6,"enemy"],"chaoswave":["wave",.6,2.0,"foes"],
		"release":["burst",2.45,3.9,"foes"],"supply":["item",-1,1.4,"ally"]
	}.get(id,["atk",.4,1.3,"enemy"])
func hit_time(index: int=0) -> float:
	var spec=body_spec()
	return T+maxf(0,spec[1])+index*.07
func abyss_time(index: int=0) -> float:
	if context.is_empty(): return T+.2
	var offset={"taunt":.9,"ptaunt":.9,"acid":.7}.get(context.id,-1)
	if context.id=="personal": offset={"naran":.8,"saya":.8,"judith":.8,"hildegard":.9,"tove":.9,"erdene":.9}.get(context.owner,-1)
	return T+offset+.2 if offset>=0 else hit_time(index)+.3
func finish(b) -> void:
	if context.is_empty(): return
	var spec=body_spec(); var actor=context.actor; var targets=[]
	match spec[3]:
		"enemy": targets=[context.enemy]
		"ally": targets=[context.ally]
		"friends","foes": targets=context[spec[3]].duplicate()
		"row": targets=context.row.slice(0,1)
	if context.id=="tonic": actor=context.ally
	if context.id=="personal" and context.owner=="colette": push("trait",actor,T+.9)
	push(spec[0],actor,T,targets,T+spec[1] if spec[1]>=0 else -1)
	if context.id=="personal" and context.owner in ["selva","jorund"]: push("trait",actor,T+.75)
	T+=spec[2]
	if context.id=="personal" and context.owner=="gerda" and b.combat_hits.size()>1:
		push("atk",actor,T,[b.combat_hits[1].target],T+.5); T+=1.5
	context={}
func trace() -> Dictionary: return {"events":events.duplicate(true),"T":T}
func enemy(b,e: Dictionary,act: Dictionary,targets: Array) -> void:
	var kind=act.kind; var tag="edef"; var duration=1.2
	match kind:
		"buff": tag="ebuff"
		"debuff","dot": tag="edeb"; duration=1.3
		"heal": tag="eheal" if not targets.is_empty() else "edef"; duration=1.3 if not targets.is_empty() else 1.0
		"charge": tag="echg"; duration=1.4
		"summon": tag="esum"; duration=1.5
		"special": tag="edeb" if not targets.is_empty() else "edef"; duration=1.3 if not targets.is_empty() else 1.0
		"atk","spell","shoot","aimed","big_one","big_all":
			tag="eall" if kind=="big_all" or act.get("target")=="all" else "eatk"; duration=1.9 if tag=="eall" else 1.4
	push(tag,slot(b,e),T,slots(b,targets))
	T+=duration
