extends SceneTree
const World=preload("res://game/expedition_world_r22.gd")
const R=preload("res://game/expedition_rules_r22.gd")
const Supply=preload("res://game/expedition_supply_r22.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func same(a,b) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for k in a:
			if not b.has(k) or not same(a[k],b[k]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not same(a[i],b[i]):return false
		return true
	if (a is float or a is int) and (b is float or b is int):return absf(float(a)-float(b))<.000001
	return a==b
func ready_world():
	var w=World.new()
	w.create_action("race_human");w.create_action("nat_border");w.create_action("cls_warrior");w.create_action("auto");w.create_action("done");w.create_action("pick_teiris","sc");w.create_action("go","sc")
	return w
func force_result(w,result: String):
	w.s.run.phase="battle"
	var b=w.ModernBattle.new(w.battle_data())
	if result=="victory":
		for e in b.data.enemies:e.hp=0;e.gauge=0
	else:
		for a in b.data.allies:a.hp=0
	b.result=result;w.record_battle(b.snapshot())
func _initialize():call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/expedition-r22/oracle.json"))
	var rules=R.new();var w=ready_world()
	check(w.s.creation_r22.complete,"new source persona ready")
	for row in oracle.modifiers:check(same(rules.modifiers(row.pm,w.config.companions),row.value),"tx modifiers "+str(row.pm))
	for row in oracle.rolls:check(same(w.dungeon_rules.ex_roll(int(row.seed),int(row.floor),int(row.step),int(row.elites),row.classes),row.value),"roll floor %d step %d"%[row.floor,row.step])
	for row in oracle.discoveries:
		var out=rules.discovery(row.raw,int(row.seed),int(row.floor),int(row.step),rules.modifiers(row.pm,w.config.companions))
		check((out.kind!="coin" or out.gold==row.gold) and (out.kind!="item" or out.count==row.items.get(out.item,0)) and (out.kind!="equip" or row.gear==[out.code]),"source discovery modifiers")
	for row in oracle.recommended:check(rules.recommended(row.avg,int(row.mx))==row.value,"recommendation uncapped")
	for row in oracle.amounts:
		var item=w.item_def(w.web_item_id(row.id));check(int(floor(row.max*item.fraction*row.mul+.5))==row.value and item.level==row.need,"source supply amount "+row.id)
	for row in oracle.rest:
		var mods=rules.modifiers(row.pm,w.config.companions)
		for i in range(4):
			if row.pm[i].id=="":continue
			check(mini(int(row.max),[0,1,50,80][i]+int(floor(row.max*(.3+mods.rest_hp)+.5)))==row.hp[i],"source rest HP")
			check(mini(71,[0,1,10,20][i]+int(floor(71*(.6+mods.rest_mp)+.5)))==row.mp[i],"source rest MP")
	for row in oracle.pouch:
		w=ready_world();w.depart_dungeon(1,1);w.s.items.hp_s=int(row.bank);w.s.run.loot_items.hp_s=int(row.pouch)
		for value in row.value:
			check(w.take_supply("hp_s")==value.ok and w.s.items.hp_s==value.bank and w.s.run.loot_items.get("hp_s",0)==value.pouch and w.supplies("hp_s")==value.have,"pouch first then bank")
	for row in oracle.drops:
		var seed=0;var code=""
		if w.RulesR21.mix(seed,31,0,0)<w.dungeon_rules.config.gear_drop.chance.get(row.kind,0):
			code=w.dungeon_rules.gear_drop(int(floor(w.RulesR21.mix(seed,32,0,0)*2147483646))+1,int(row.floor),row.kind,["warrior"]).get("code","")
		check(code==row.value,"source fractional drop seed")
	for row in oracle.combat_items:
		w=ready_world();w.s.owned=["marceline","naran","teiris"];w.s.party=w.s.owned.duplicate();w.depart_dungeon(1,1);w.s.run.phase="battle"
		var d=w.battle_data()
		for i in range(d.allies.size()):
			var a=d.allies[i];a.level=40;a.race="인간" if row.tags=="human" else "엘프";a.nation="마렌토 공화국" if row.tags=="marento" and i<2 else "솔렌 성왕국" if row.tags=="solen" and i<2 else "경계도시"
		d.inventory[w.web_item_id(row.id)]=1
		var a=d.allies[0];a.hp=1;a.mhp=1001;a.mp=1;a.mmp=101
		var b=Supply.new(d);a=b.data.allies[0];var id=w.web_item_id(row.id)
		if id=="bandage":a.hp=0;a.charging=true;a.effects.attack_down={"turns":2,"amount":.1}
		if id=="antidote":a.effects={"dot":{"turns":2,"amount":5},"enemy_dot_0":{"turns":2,"amount":4},"foxflame":{"turns":2,"amount":2}}
		check(b._use_supply(w.item_def(id),a),"source combat item usable "+id+row.tags)
		check(a.hp==row.hp and a.mp==row.mp and a.shield==row.shield,"source combat item amount "+id+row.tags)
		check(b.inventory[id]==0 and b.turn_count==1,"source combat item stock and turn")
		check(id!="antidote" or a.effects.is_empty(),"source antidote all DOT families")
		check(id!="bandage" or (not a.charging and a.effects.is_empty()),"source bandage clears charge and debuffs")
	# The canonical regen_mix harness checks execution in both orders and JSON safety.
	# Numeric skill/round behavior is owned by P2 and is deliberately not replaced here.
	for row in oracle.regen_mix:
		w=ready_world();w.s.persona.fight=0;w.s.owned=["sorel","adeline","marceline","haldric"];w.s.party=w.s.owned.duplicate()
		for id in w.s.party:w.s.members[id].level=20
		w.depart_dungeon(1,1);w.s.run.phase="battle";var b=Supply.new(w.battle_data());var used=0
		for id in row.order:
			b.current_id=id;b.last_ally=id;b.selected_ally=id
			if b.act("personal"):used+=1
		var copy=Supply.new(w.battle_data());check(used==row.used and copy.restore(JSON.parse_string(JSON.stringify(b.snapshot())))==row.serializable,"source regen_mix execution and JSON "+str(row.order))
	for row in oracle.settlements:
		w=ready_world();w.s.owned=["marceline","naran","teiris"];w.s.party=w.s.owned.duplicate();w.s.persona.nation=row.nat;w.s.dungeon_r21.best=2;w.depart_dungeon(3,7)
		var r=w.s.run;r.persona_pm=row.pm.duplicate(true);r.wins=2;r.step=5;r.gold=304 if row.result=="clear" else 101;r.xp=377 if row.result=="clear" else 250;r.loot_items.hp_s=4
		if row.result=="retreat":check(w.settle("retreat"),"source retreat fixture")
		else:
			r.final=true;r.kind="boss";force_result(w,"victory" if row.result=="clear" else "defeat")
			if row.result=="clear":
				var drop=w.dungeon_rules.gear_drop(int(floor(w.RulesR21.mix(0,32,0,0)*2147483646))+1,3,"boss",w.party_classes());r.loot_gear.append(drop.code)
			check(w.settle(row.result),"source settlement fixture")
		var bank_items=row.items if row.items is Dictionary else {}
		check(w.s.gold==row.gold and w.s.items.hp_s==bank_items.get("hp_s",0) and w.s.summary.xp==row.summary.exp,"source settlement gold items XP")
		var af=row.aff if row.get("aff") is Dictionary else {};var ex=row.exp if row.get("exp") is Dictionary else {}
		for id in w.s.party:check(w.s.members[id].aff==af.get(id,0) and w.s.members[id].level==row.lvl[id] and w.s.members[id].xp==ex.get(id,0),"source settlement companion "+id)
		check(w.s.persona.lv==row.persona.lv and w.s.persona.exp==row.persona.exp,"source settlement persona")
	# Real world transitions, save/restore, stock ownership and once-only settlement.
	for seed in range(1,46):
		w=ready_world();check(w.depart_dungeon(1,seed),"depart")
		var before=w.s.gold;var level=w.s.persona.lv
		for i in range(5):
			check(w.advance(),"advance")
			if w.s.run.phase=="battle":
				force_result(w,"victory");check(w.finish_battle(),"win exploration");check(not w.finish_battle(),"duplicate exploration continuation blocked")
			check(w.s.gold==before and w.s.persona.lv==level and w.s.persona.exp==0,"rewards stay in run until settlement")
		check(w.s.run.phase=="rest" and w.s.run.step==5,"five steps enter rest")
		var hp=w.s.members.persona.hp;var expected_hp=mini(w.s.run.maxima.persona.hp,hp+int(floor(w.s.run.maxima.persona.hp*.3+.5)))
		w.enter_dungeon_rest();check(w.s.members.persona.hp==expected_hp and not w.advance(),"source direct rest invocation heals again; stale explore rejected")
		var save=w.s.duplicate(true);var clone=World.new();check(clone.restore(save),"P5 JSON rest restore")
		check(w.final_battle() and not w.final_battle(),"one boss start")
		force_result(w,"victory");check(w.finish_battle(),"boss settlement")
		var paid=w.s.duplicate(true);check(not w.settle("clear") and not w.finish_battle() and same(w.s,paid),"double settlement no mutation")
		check(w.s.dungeon_r21.best==1 and w.s.day==2 and w.s.summary.xp>0,"record and day on clear")
		check(w.next_dungeon_floor() and w.s.run.floor==2 and not w.next_dungeon_floor(),"continuous descent once")
	# Defeat retains no XP; Kern retention uses ordered gear and floor per count.
	w=ready_world();w.s.persona.nation="케른 연방";w.s.owned=["haldric","urda"];w.s.party=w.s.owned.duplicate();w.depart_dungeon(1,5);w.s.run.gold=101;w.s.run.xp=500;w.s.run.loot_items.hp_s=4
	force_result(w,"defeat");check(w.finish_battle(),"defeat settlement")
	check(w.s.summary.kept_gold==40 and w.s.summary.penalty==35 and w.s.items.hp_s==1 and w.s.summary.xp==0 and w.s.persona.lv==1,"Kern partial loot and no defeat XP")
	# Rest equipment is allowed only for deployed members; found gear stays in pouch.
	w=ready_world();w.depart_dungeon(1,1);var item=w.gear.catalog.items.filter(func(it):return it.cls=="warrior" and it.rarity=="common")[0];w.add_gear(item.id);var uid=w.s.serial
	check(not w.equip("persona",uid),"no explore equipment")
	w.s.run.step=5;w.enter_dungeon_rest();check(w.equip("persona",uid) and w.unequip("persona",item.slot),"rest persona equipment and unequip")
	w.s.items.hp_s=0;w.s.run.loot_items.hp_s=1;w.s.members.persona.hp=1
	check(w.item_preview("hp_s","persona").usable and w.use_item("hp_s","persona") and w.supplies("hp_s")==0,"persona out of combat pouch potion")
	var saved=w.s.duplicate(true);saved.run.loot_items.hp_s=-1;var old=w.s.duplicate(true);check(not w.restore(saved) and same(old,w.s),"bad pouch restore atomic")
	# A real combat action consumes the combined bag, persists pouch first, then
	# resumes without double consumption. Invalid increases are rejected atomically.
	w=ready_world();w.depart_dungeon(1,9);w.s.run.phase="battle";w.s.items.hp_s=1;w.s.run.loot_items.hp_s=2
	var battle=Supply.new(w.battle_data())
	# The source CTB may give the opening turn to an enemy or another ally.
	while not battle.player_turn() and battle.result.is_empty():battle.automatic_turn()
	battle.ally("persona").hp=1;battle.selected_ally="persona"
	check(battle.act("item:hp_s"),"actual combat supply action")
	w.record_battle(battle.snapshot());check(w.s.items.hp_s==1 and w.s.run.loot_items.hp_s==1,"combat consumes pouch before bank")
	var once=w.s.duplicate(true);w.record_battle(battle.snapshot());check(same(once,w.s),"duplicate snapshot no double consume")
	var resumed=World.new();check(resumed.restore(JSON.parse_string(JSON.stringify(w.s))),"combat supply world restore")
	var state=Supply.new(resumed.battle_data());check(state.restore(resumed.s.run.battle) and state.inventory.hp_s==2,"combat supply inventory restore")
	var bad=battle.snapshot();bad.inventory.hp_s=4;w.record_battle(bad);check(same(once,w.s),"inventory increase cannot mint supplies")
	# Bag capacity and deterministic retained gear prefix.
	w=ready_world();w.depart_dungeon(1,1);var code=w.dungeon_rules.gear_drop(117,1,"battle",w.party_classes()).code
	for i in range(2000):w.s.serial+=1;w.s.gear.append({"id":code.split(".")[0],"uid":w.s.serial,"seed":1,"forge":0,"tries":0,"source_r21":true})
	w.s.run.loot_gear=[code,code];check(w.settle("retreat") and w.s.summary.gear_lost==2 and w.s.gear.size()==2000,"full bag reports both pending gear")
	check(w.s.get("gear_r22",{}).get("overflow",[]).is_empty(),"source full bag discards new rewards; old overflow is tested separately")
	w=ready_world();w.depart_dungeon(1,1);w.s.run.phase="battle";w.s.run.final=true;force_result(w,"victory");check(w.finish_battle(),"clear before home")
	var rewarded=w.s.gold;check(w.expedition_home() and not w.next_dungeon_floor() and w.s.gold==rewarded,"home closes continuation without repeat payment")
	# Reproducible P9 handoff specimens; the server/ and cloud_* files are protected.
	var samples={};w=ready_world();w.depart_dungeon(1,5);samples.entry=w.s.duplicate(true)
	w.s.run.phase="battle";var initial=Supply.new(w.battle_data());w.record_battle(initial.snapshot());samples.battle=w.s.duplicate(true)
	w.s.run.phase="explore";w.s.run.battle={};w.s.run.step=5;w.enter_dungeon_rest();samples.rest=w.s.duplicate(true)
	w.final_battle();force_result(w,"victory");w.finish_battle();samples.clear=w.s.duplicate(true)
	w.next_dungeon_floor();samples.next_floor=w.s.duplicate(true)
	for key in samples:check(World.new().restore(samples[key]),"P5 specimen native restore "+key)
	FileAccess.open("res://../verification/expedition-r22/save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify(samples,"  "))
	for path in DirAccess.get_files_at(ProjectSettings.globalize_path("res://../verification/persona-r22/legacy").simplify_path()):
		if not path.ends_with(".json"):continue
		var legacy=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy/"+path))
		check(World.new().restore(legacy),"P5 facade actual old save "+path)
	var malformed=samples.entry.duplicate(true);malformed.run=[];check(not w.restore(malformed),"malformed run type rejected")
	malformed=samples.entry.duplicate(true);malformed.run.maxima.persona.hp=1.5;check(not w.restore(malformed),"fractional retained maximum rejected")
	malformed=samples.entry.duplicate(true);malformed.run.loot_gear=["wa01.0000000000001.1"];check(not w.restore(malformed),"oversized gear code rejected")
	w=ready_world();w.s.persona.nation="마렌토 공화국";w.s.owned=["lynette","bianca"];w.s.party=["lynette"]
	check(w.price({"price":100})==94,"tx_shop counts deployed persona as second Marento")
	w.s.party.append("bianca");check(w.price({"price":100})==88,"tx_shop three Marento")
	var result={"checks":checks,"failures":failures,"oracle_rows":oracle.rolls.size()+oracle.modifiers.size()+oracle.discoveries.size()+oracle.recommended.size()+oracle.amounts.size()+oracle.rest.size()+oracle.pouch.size()+oracle.drops.size()}
	FileAccess.open("res://../verification/expedition-r22/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("EXPEDITION R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
