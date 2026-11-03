extends "res://game/dungeon_enemy_r21.gd"
## The previous turn() support branches, extracted unchanged for direct replay.
## This is a branch-level baseline, not a copy of the complete previous engine.
func support_action(e: Dictionary,a: Dictionary) -> void:
	var targets=b.living(false) if a.get("target")=="allies" else [e]
	var event_targets=[]
	match a.kind:
		"protect":
			var list=b.living(false).filter(func(u):return u.id!=e.id)
			if not list.is_empty(): b.x(e).protect=lowest(list,true).id
			if a.get("guard",false): effect(e,"guard",2,.4)
			b._event(e.name+" · "+a.name)
		"heal":
			var pool=([e] if a.get("target")=="self" else b.living(false)).filter(func(u):return u.hp<u.mhp)
			if not pool.is_empty():
				var t=lowest(pool); var h=mini(t.mhp-t.hp,int(floor(t.mhp*a.get("amount",.2))))
				t.hp+=h; b._event(a.name+" → "+t.name+" · HP +%d"%h)
				event_targets=[t]
		"buff":
			if a.get("target")=="ally":
				var other=b.living(false).filter(func(u):return u.id!=e.id); targets=[lowest(other)] if not other.is_empty() else [e]
			for t in targets:
				if a.stat=="shield": effect(t,"shield",3,maxf(b.fx(t,"shield"),floor(t.mhp*a.amount)))
				elif a.stat=="pull": t.remaining=maxf(0,t.remaining-10000*a.amount)
				else:
					var key="enemy_attack_self" if a.stat=="atk" and a.get("target","self")=="self" and not a.get("until_down",false) else {"atk":"attack_up","def":"defense_up","spd":"haste"}.get(a.stat,"attack_up")
					effect(t,key,99 if a.get("until_down",false) else int(a.get("turns",3))+1,a.get("amount",0),e.id if a.get("until_down",false) else "")
			b._event(e.name+" · "+a.name)
			event_targets=targets
		"debuff":
			var list=allies_alive() if a.get("target")=="all" else [target(e,a)]
			for t in list:
				if a.stat=="delay": t.remaining+=10000*a.get("amount",.2)
				else: effect(t,{"atk":"attack_down","def":"defense_down","spd":"slow"}.get(a.stat,"attack_down"),int(a.get("turns",2)),a.get("amount",.2))
			b._event(e.name+" · "+a.name)
			event_targets=list
		"special":
			if a.get("fx")=="silence":
				var choices=silence_choices()
				if not choices.is_empty():
					var choice=choices[int(floor(random()*choices.size()))]; b.x(choice[0]).silenced_id=str(choice[1]); effect(choice[0],"silence",1)
					event_targets=[choice[0]]
			b._event(e.name+" · "+a.name)
	b.combat_events.enemy(b,e,a,event_targets)
func turn_end(e: Dictionary,a: Dictionary) -> void:
	if a.kind in ["big_one","big_all"]:e.charged=false
	if e.rules.has("hide_every") and int(b.x(e).get("foe_turns",0))%int(e.rules.hide_every)==0:b.x(e).hidden=true
