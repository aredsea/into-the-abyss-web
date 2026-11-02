extends "res://game/battle_v3.gd"
var trace=[]
func record():
	if turn_count==0 or (not trace.is_empty() and trace[-1].n==turn_count): return
	var all=data.allies+data.enemies
	var extra={"abyss":all.map(func(u):return 0 if u.has("base") or u.foe_id.is_empty() else u.gauge),"broken":all.map(func(u):return false if u.has("base") else u.broken)}
	trace.append({"n":turn_count,"actor":all.find(unit(current_id))+1,"hp":all.map(func(u):return u.hp),"mp":all.map(func(u):return u.get("mp",0)),"sh":all.map(func(u):return u.get("shield",0) if u.has("base") else fx(u,"shield")),"g":all.map(func(u):return u.remaining),"rng":x(data.enemies[0]).source_rng,"tk":ctb_tick,"rd":ctb_round,"targets":all.map(func(u):return 0 if u.has("base") or u.target_id.is_empty() else all.find(unit(u.target_id))+1),"hits":combat_hits.duplicate(true)})
	trace[-1].merge(extra)
	for i in range(data.enemies.size()):
		if data.enemies[i].foe_id.is_empty(): trace[-1].g[data.allies.size()+i]=0
func _advance_ctb() -> void:
	record()
	super()
