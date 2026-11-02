extends "res://game/chronicle_world_r22.gd"
## Difficulty belongs to a battle, including its summoned/second-phase enemies.
const Settings=preload("res://game/settings_rules_r22.gd")
func _init() -> void:
	super()
	s.settings={"lang":"ko","diff":2,"chron":1}
func battle_multiplier() -> float:
	var key="%d:%d:%s"%[int(s.run.get("id",0)),int(s.run.get("step",0)),s.run.get("final",false)]
	if s.run.get("settings_battle_r22",{}).get("key","")!=key:
		# A pre-P8 running snapshot already has its original normal stats.
		s.run.settings_battle_r22={"key":key,"multiplier":1.0 if not s.run.get("battle",{}).is_empty() else Settings.difficulty(s).hp}
	return s.run.settings_battle_r22.multiplier
func make_enemy(enc: Dictionary,index: int,level: int,allies: Array,foe_id: String,phase: int=1) -> Dictionary:
	var e=super(enc,index,level,allies,foe_id,phase);var mul=battle_multiplier()
	var local_enc=enc.duplicate(true)
	while local_enc.fl.size()<=index:local_enc.fl.append("");local_enc.fg.append("minion")
	local_enc.fl[index]="apprentice_doll" if foe_id=="" else foe_id
	var d=dungeon_rules.foe_def(local_enc,index,level);var stats=dungeon_rules.foe_stats(enc,d,level)
	var power=clampf(float(s.run.source_quest.get("strength",1.5)),1.5,2) if s.run.has("source_quest") and dungeon_rules.quest_difficulty(s.run.source_quest)=="엘리트" else 1.0
	e.mhp=maxi(1,int(floor(stats.hp*power*mul+.5)));e.hp=0 if foe_id=="" else e.mhp;e.attack=stats.atk*power*mul
	return e
func battle_data() -> Dictionary:
	var d=super();var mul=battle_multiplier()
	d.language_r22=preload("res://game/localization_r22.gd").language(s)
	if r21():d.enemy_power_r21*=mul
	else:
		for e in d.enemies:e.mhp=maxi(1,int(floor(e.mhp*mul+.5)));e.hp=0 if e.hp==0 else e.mhp;e.attack*=mul
	return d
func restore(value: Variant) -> bool:
	if not value is Dictionary or not value.get("settings",{}) is Dictionary:return false
	var r=value.get("run",{}).get("settings_battle_r22",{}) if value.get("run",{}) is Dictionary else {}
	if not r is Dictionary:return false
	if not r.is_empty() and (not r.get("key") is String or r.get("multiplier") not in [0.8,1.0,1.25]):return false
	return super(value)
