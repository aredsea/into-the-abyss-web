extends "res://tests/facilities_r22_test.gd"
const GearRules=preload("res://game/gear_rules_r22.gd")
const TownRules=preload("res://game/town_rules_r21.gd")
var counts={}
func same(a,b) -> bool:
	if (a is Dictionary)!=(b is Dictionary) or (a is Array)!=(b is Array):return false
	if (a is bool)!=(b is bool):return false
	return super(a,b)
func eqcheck(group: String,a,b):
	counts[group]=counts.get(group,0)+1
	check(same(a,b),group+" #"+str(counts[group]))
func nul(value):return false if value==null else value
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/gear-oracle.json"))
	var r=GearRules.new()
	var catalog=r.source.duplicate(true);catalog.erase("cast");catalog.erase("classes")
	eqcheck("catalog",catalog,o.catalog)
	for f in o.icons:
		var item=r.source.items[f.id] if f.has("id") else f.item
		if item is Array and item.is_empty():item={}
		eqcheck("icons",nul(r.gear_icon(item)),f.value)
	for f in o.labels:eqcheck("labels",r.gear_label(f.code),f.value)
	for f in o.parse:
		var p=r.gear_parse(f.input)
		if not p.is_empty():p.seed=str(p.seed)
		eqcheck("parse",false if p.is_empty() else p,f.value)
	for f in o.roll:
		var p=r.gear_roll(f.code,f.lv,f.forge);p.erase("item")
		if not p.is_empty():p.seed=str(p.seed)
		eqcheck("roll",false if p.is_empty() else p,f.value)
	for f in o.cost:eqcheck("cost",nul(r.forge_code_cost(f.code,f.level)),f.value)
	for f in o.bag:
		var bag=r.bag_load(f.raw)
		if f.kind=="load":eqcheck("bag_load",bag,f.loaded);eqcheck("bag_save",";".join(bag),f.saved)
		else:
			var ok=r.call(f.kind,bag,f.code)
			eqcheck("bag_result",ok,f.ok)
			# The host writes only after a successful mutation.
			eqcheck("bag_save",";".join(bag) if ok else f.raw,f.saved)
			eqcheck("bag_reload",r.bag_load(";".join(bag)),f.loaded)
	for f in o.transactions:
		var g=f.game.duplicate(true);var bag=f.bag.duplicate();var result=r.callv(f.method,[g,bag]+f.args)
		eqcheck("transaction_result",result if result is Array else [nul(result)],f.result)
		eqcheck("transaction_state",g,f.value);eqcheck("transaction_bag",bag,f.after)
	for f in o.refresh:
		# Invalid table shapes are exercised once the adapter supplies a guard.
		if not f.game.equip is Dictionary or (f.game.equip.has("persona") and not f.game.equip.persona is Dictionary):
			if not r.has_method("gear_equipment_table"):check(false,"equipment table guard missing");continue
		var pm=f.pm.duplicate(true);r.gear_pm_refresh(f.game,pm)
		eqcheck("refresh",pm,f.value);eqcheck("eq_of",nul(r.gear_eq_of(f.game,"persona")),f.eq)
	for f in o.migrate:
		var g=f.game.duplicate(true);eqcheck("migrate_result",r.gear_migrate(g),f.result)
		g.erase("gear_r22_prototypes");eqcheck("migrate_active",g,f.value)
	for f in o.party:eqcheck("party_classes",r.gear_party_cls(f.pm),f.value)
	for f in o.context:eqcheck("legend_context",r.gear_context(f.game),f.value)
	for f in o.smithy:eqcheck("smithy_list",r.smithy_list(f.game,f.bag),f.value)
	for f in o.smithy:
		var w=ready_world();w.s.gear=[];w.s.serial=0
		w.bank_expedition_gear(f.bag)
		# The real native listing includes equipped entries too, and deduplicates
		# by source code even when each copy has a different UID.
		w.bank_expedition_gear([f.game.equip.persona.weapon])
		eqcheck("native_smithy_list",w.smithy_list().map(func(e):return w.gear.code(e)),f.value)
	for f in o.shop:
		var w=ready_world();w.s.town_r21.seed=f.game.seed;w.s.npc_aff_r21["pietro"]=f.game.npcs.pietro.aff
		w.s.commerce_r21.pietro_buys=f.game.npcs.pietro.buys;w.s.items=f.game.items.duplicate(true) if f.game.items is Dictionary else f.game.items
		w.s.ui.msg=f.game.ui.msg
		if not w.has_method("shop_after_buy"):check(false,"shop_after_buy missing");continue
		w.shop_after_buy()
		eqcheck("shop_bonus",[w.s.npc_aff_r21.pietro,w.s.commerce_r21.pietro_buys,w.s.items.charm_potion],[f.aff,f.buys,f.count])
		eqcheck("shop_bonus_message",w.s.ui.msg,f.msg)
	for f in o.shop_flow:
		if not f.arg.begins_with("buy_"):continue
		var w=ready_world();w.s.gold=f.game.gold;w.s.town_r21.seed=f.game.seed;w.s.npc_aff_r21["pietro"]=60
		w.s.commerce_r21.pietro_buys=0;w.s.items.hp_s=0
		w.buy(f.arg.trim_prefix("buy_"))
		eqcheck("shop_purchase",[w.s.gold,w.s.items.get("hp_s",0),w.s.items.get("charm_potion",0),w.s.commerce_r21.pietro_buys],[f.gold,f.items.get("hp_s",0),f.items.get("charm_potion",0),f.npcs.pietro.buys])
	for f in o.guild:
		var w=ready_world();w.s.owned=f.roster;set_level(w,"persona",f.level);w.s.members.hildegard.level=33
		eqcheck("guild_base",w.highest_level(),f.base)
		var candidates=w.config.companions.filter(func(p):return p.id not in w.s.owned).map(func(p):return p.id)
		eqcheck("guild_candidates",candidates,f.candidates)
		var board=f.before.duplicate(true)
		eqcheck("guild_find",Rules.find_quest(board,"q1"),f.found)
		eqcheck("guild_find_missing",nul(Rules.find_quest(board,"missing")),f.missing)
		eqcheck("guild_remove",Rules.remove_quest(board,"q1"),f.removed)
		eqcheck("guild_remove_state",board,f.board)
		eqcheck("guild_remove_missing",Rules.remove_quest(board,"missing"),f.remove_missing)
	for f in o.fill:
		var w=ready_world();w.s.owned=f.game.roster;set_level(w,"persona",40);w.s.members.hildegard.level=40;w.s.members.teiris.level=10
		w.s.town_r21={"seed":int(f.game.seed),"counter":int(f.game.n),"qn":int(f.game.guild.qn)}
		w.s.board=f.game.guild.quests.map(func(q):var v=q.duplicate(true);v.source_id=q.id;v.id=int(q.id.trim_prefix("q"));return v)
		w.fill_source_board()
		eqcheck("guild_fill",w.s.board.map(func(q):return Rules.source_view(q)),f.board)
		eqcheck("guild_fill_counters",[w.s.town_r21.counter,w.s.town_r21.qn],[f.index,f.qn])
	for f in o.classes:eqcheck("process_fallback",r.process_roll(f.game,1),f.code)
	for f in o.drop:
		var saved=r.dungeon.config.gear_drop.duplicate(true)
		if f.get("zero_weights",false):
			r.dungeon.config=r.dungeon.config.duplicate(true)
			for band in r.dungeon.config.gear_drop.bands:
				for rarity in band.w.battle:band.w.battle[rarity]=0
		eqcheck("drop_boundaries",r.gear_drop(f.seed,f.floor,f.kind,f.classes).get("code",false),f.value)
		r.dungeon.config.gear_drop=saved
	for f in o.aff_party:
		var w=ready_world();w.s.owned=f.game.roster;w.s.members.hildegard.aff=f.game.aff.hildegard;w.s.members.teiris.aff=f.game.aff.teiris
		w.s.party=f.pm.map(func(m):return m.id if m is Dictionary else m)
		var delta=w.call("aff_party",2)
		eqcheck("aff_party_delta",delta,{} if f.delta is Array and f.delta.is_empty() else f.delta)
		eqcheck("aff_party_state",{"hildegard":w.s.members.hildegard.aff,"teiris":w.s.members.teiris.aff},f.value)
	var town=TownRules.new()
	for f in o.fmt:eqcheck("aff_fmt_invalid",town.call("aff_fmt",f.input),f.value)
	for f in o.aff:
		eqcheck("guild_tier",TownRules.guild_tier(f.input),f.tier)
		if town.has_method("aff_r2"):eqcheck("aff_r2",town.call("aff_r2",f.input),f.r2)
		else:check(false,"aff_r2 missing")
		if town.has_method("aff_fmt"):eqcheck("aff_fmt",town.call("aff_fmt",f.input),f.fmt)
		else:check(false,"aff_fmt missing")
	# Compare the ordinary inn's economic result and the action/day ledger.
	for f in o.inn:
		if not f.arg.begins_with("talk_") and not f.arg.begins_with("meal_") and not f.arg.begins_with("gift_") and not f.arg.begins_with("rest_"):continue
		var w=ready_world();w.s.gold=f.game.gold;w.s.day=3;w.s.refreshes=4;w.s.acts=f.game.town.acts.duplicate(true)
		w.s.owned=["hildegard","teiris"];w.s.members.hildegard.aff=99.5;w.s.members.teiris.aff=150
		var parts=f.arg.split("_");w.inn(parts[1],parts[0])
		eqcheck("inn_economy",[w.s.gold,w.s.day,w.s.refreshes,w.s.acts,w.s.members.hildegard.aff,w.s.members.teiris.aff],[f.gold,f.day,f.rr,f.acts,f.aff.hildegard,f.aff.teiris])
	# Persisted buy count drives the same next gift after reload; visits stay transient.
	var gift=o.shop.filter(func(f):return f.game.items is Dictionary and f.game.items.get("charm_potion",0)==0 and f.game.npcs.pietro.aff==50 and f.game.npcs.pietro.buys==0 and f.count==1)[0]
	var w=ready_world();w.s.gold=10000;w.s.npc_aff_r21["pietro"]=50;w.s.town_r21.seed=gift.game.seed
	w.buy("hp_s");var restored=World.new();check(restored.restore(w.s),"bonus inventory and counter restore")
	check(w.s.items.get("charm_potion",0)==1,"actual successful purchase grants source bonus")
	w.buy("hp_s");restored.buy("hp_s")
	eqcheck("shop_resume",[w.s.gold,w.s.items,w.s.commerce_r21,w.s.npc_aff_r21],[restored.s.gold,restored.s.items,restored.s.commerce_r21,restored.s.npc_aff_r21])
	FileAccess.open("res://../verification/parity-r23/shop-save.json",FileAccess.WRITE).store_string(JSON.stringify(w.s,"  "))
	var result={"checks":checks,"failures":failures,"counts":counts}
	FileAccess.open("res://../verification/parity-r23/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("GEAR R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
