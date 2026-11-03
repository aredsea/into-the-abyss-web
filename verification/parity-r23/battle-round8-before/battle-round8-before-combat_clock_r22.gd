extends RefCounted
## 30-engine.lua:188-245. Slot order is stable; overshoot is deliberately signed.
static func advance(units: Array,speeds: Array) -> Dictionary:
	var best=-1; var elapsed=INF
	for i in range(units.size()):
		if units[i].hp<=0: continue
		var ticks=ceil(maxf(0,float(units[i].remaining))/float(speeds[i]))
		if ticks<elapsed: best=i; elapsed=ticks
	if best<0: return {}
	for i in range(units.size()):
		if units[i].hp>0: units[i].remaining-=elapsed*float(speeds[i])
	return {"index":best,"ticks":int(elapsed)}

static func preview(units: Array,speeds: Array,current: String,n: int=8) -> Array:
	var copies=[]; var out=[]
	for u in units: copies.append({"hp":u.hp,"remaining":float(u.remaining)})
	for i in range(units.size()):
		if units[i].id==current and units[i].hp>0:
			out.append(current); copies[i].remaining+=10000; break
	for step in range(60):
		if out.size()>=n: break
		var next=advance(copies,speeds)
		if next.is_empty(): break
		out.append(units[next.index].id); copies[next.index].remaining+=10000
	return out
