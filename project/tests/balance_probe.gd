extends SceneTree
const World=preload("res://game/expansion_world.gd")
const Battle=preload("res://game/battle_v3.gd")
func _init() -> void:
	var results=[]
	var parties=[["hildegard","bargut","teiris","berenga"],["marceline","gunhild","naran","lynette"],["erdene","bianca","judith","sorel"],["saya","tove","gerda","miko"],["zahar","tika","levia","urda"],["haldric","selva","hedwig","altan"],["hildegard","jorund","colette","felice"],["bargut","tove","ornel","adeline"]]
	for party in parties:
		var wins=0; var turns=0; var hp=0.0
		for seed in range(1,41):
			var w=World.new(); w.s.party=party.duplicate(); w.depart(); w.travel("patrol")
			var data=w.battle_data(); data.seed=seed*3571
			for e in data.enemies: e.hp=e.mhp
			var b=Battle.new(data)
			for n in range(250):
				if not b.result.is_empty(): break
				if not b.player_turn() or b.ally(b.current_id).charging: b.automatic_turn(); continue
				var a=b.ally(b.current_id); var foes=b.living(false); var target=foes[0]
				for e in foes:
					if e.hp<target.hp: target=e
				b.choose_enemy(target.id)
				var wounded=b._lowest(); b.choose_ally(wounded.id)
				var action="attack"
				if a.id in ["berenga","miko","felice","lynette","sorel","adeline"] and wounded.hp<wounded.mhp*.6 and b.unavailable("personal").is_empty(): action="personal"
				elif a.id in ["teiris","bargut","gunhild","bianca","gerda","judith","zahar","ornel","colette","lavinia","jorund","tove","hedwig","selva","erdene"] and b.unavailable("personal").is_empty(): action="personal"
				elif a.class_id=="chaos" and b.unavailable("rift").is_empty(): action="rift"
				b.act(action)
			if b.result=="victory": wins+=1
			turns+=b.turn_count
			for a in b.data.allies: hp+=float(a.hp)/a.mhp/4
		results.append({"party":party,"seeds":40,"wins":wins,"mean_turns":turns/40.0,"remaining_hp":hp/40})
	print("BALANCE ",JSON.stringify(results))
	quit()
