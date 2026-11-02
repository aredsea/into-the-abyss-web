extends "res://game/battle_v3.gd"
## Narrow 78-battle-item adapter. Shared battle/combat files stay read-only.
func supply_amount(item: Dictionary,t: Dictionary,mul: float=1.0) -> int:
	return int(floor((t.mmp if item.kind=="mp" else t.mhp)*item.fraction*mul+.5))
func supply_state_ok(item: Dictionary,t: Dictionary) -> bool:
	if t.is_empty() or t.level<item.level or inventory.get(item.id,0)<=0:return false
	if item.kind=="revive":return t.hp<=0
	if t.hp<=0:return false
	if item.kind=="hp":return t.hp<t.mhp
	if item.kind=="mp":return t.mmp>0 and t.mp<t.mmp
	if item.kind=="shield":return t.shield<supply_amount(item,t)
	if item.kind=="cleanse":
		for key in t.effects:
			if key in ["dot","corrosion","bleed","foxflame"] or key.begins_with("enemy_dot_"):return true
	return false
func _use_supply(item: Dictionary,t: Dictionary) -> bool:
	if not supply_state_ok(item,t):return false
	var mul=1.1 if count_tag("nation","마렌토 공화국")>=2 else 1.0
	match item.kind:
		"hp":
			var amount=supply_amount(item,t,mul)
			if count_tag("race","인간")>=3:amount=int(floor(amount*1.1+.5))
			t.hp=mini(t.mhp,t.hp+amount)
		"mp":t.mp=mini(t.mmp,t.mp+supply_amount(item,t,mul))
		"shield":
			var amount=supply_amount(item,t,mul)
			if count_tag("nation","솔렌 성왕국")>=2:amount=int(floor(amount*1.03))
			t.shield=maxi(t.shield,amount);t.effects.shield={"turns":3,"amount":0}
		"cleanse":
			for key in t.effects.keys():
				if key in ["dot","corrosion","bleed","foxflame"] or key.begins_with("enemy_dot_"):t.effects.erase(key)
		"revive":
			t.hp=maxi(1,int(floor(t.mhp*.25)));t.remaining=10000.0;t.charging=false;t.broken=false;t.effects={}
	inventory[item.id]-=1;events=[];action_id="supply";_event(item.name+" → "+t.name);_finish_turn();return true
