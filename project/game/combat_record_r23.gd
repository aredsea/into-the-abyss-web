extends RefCounted
## Source-shaped record ABI, shared with the combat/gear inspection boundary.
## The native renderer continues to consume CombatEvents' existing event list.
static func say(state: Dictionary,html: Variant,at: Variant=null) -> void:
	var line={"t":0 if at==null or (at is bool and not at) else at}
	if html!=null:line.h=html
	state.log.append(line)
	while state.log.size()>6:state.log.pop_front()
static func begin(state: Dictionary) -> void:
	var pre=[];var h=[]
	for u in state.u:
		var p={}
		for field in ["hp","mp","sh","ay"]:
			if u.has(field):p[field]=u[field]
		pre.append(p);h.append([])
	for line in state.log:line.t=-1
	var q=state.get("q",[])
	state.ev={"pre":pre,"h":h,"list":[],"T":.15,"q0":[] if q is bool and not q else q}
static func set_field(state: Dictionary,index: int,field: String,value: Variant,at: Variant=null) -> void:
	if value==null:state.u[index-1].erase(field)
	else:state.u[index-1][field]=value
	if state.get("ev") is Dictionary and field in ["hp","mp","sh","ay"]:
		var entry={"f":field,"t":state.ev.T if at==null or (at is bool and not at) else at}
		if value!=null:entry.v=value
		state.ev.h[index-1].append(entry)
static func push(state: Dictionary,event: Variant) -> Variant:
	if event!=null:state.ev.list.append(event)
	return event
static func trait_line(state: Dictionary,owner: int,text: String,at: Variant=null,abyss: Variant=null) -> void:
	var event={"k":"trait","a":owner,"t":state.ev.T if at==null or (at is bool and not at) else at,"nm":text}
	if abyss!=null:event.ab=abyss
	push(state,event)
