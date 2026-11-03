extends "res://game/expedition_world_r22.gd"
## Town/gear facade; combat algorithms and the inherited town composition stay upstream.
const GuildR22=preload("res://game/guild_rules_r22.gd")
const SmithyR22=preload("res://game/smithy_rules_r22.gd")
var facility="town"
var facility_message=""
var smithy_work=[]
var shop_got={}
var receipt={}
var smithy_tab="forge"
var smithy_source_fx={}
var smithy_fx: Dictionary:
	get:return smithy_source_fx.get("forge_fx",smithy_source_fx.get("proc_fx",{}))
	set(value):
		gear.fx_clear(smithy_source_fx)
		if not value.is_empty():smithy_source_fx["forge_fx" if value.kind=="forge" else "proc_fx"]=value

func _init():
	super()
	gear=SmithyR22.new()

func highest_level() -> int:
	return maxi(super(),int(s.get("persona",{}).get("lv",1)))

func award_persona_exp(st: Dictionary) -> Dictionary:
	var out=super(st)
	s.persona_progress_r21={"level":s.persona.lv,"xp":s.persona.exp}
	return out

func recruit() -> bool:
	var old=s.get("persona_progress_r21",{"level":s.persona.lv,"xp":s.persona.exp})
	s.persona_progress_r21={"level":s.persona.lv,"xp":s.persona.exp}
	var result=super()
	if not result:s.persona_progress_r21=old
	return result

func shop_classes() -> Array:
	return gear.classes("",[])

func bag_count() -> int:
	return s.gear.filter(func(e):return wearer(int(e.uid)).is_empty()).size()

func wearer(uid: int) -> String:
	# JSON reloads numeric UIDs as floats. Array.has uses strict Variant types;
	# numeric equality keeps worn entries out of the bag after a real save/resume.
	for cid in s.equipment:
		for worn in s.equipment[cid].values():
			if worn==uid:return cid
	return ""

func equip(who: String,uid: int) -> bool:
	# 81-gear only equips bag-owned entries. A duplicate code in another slot
	# never authorizes transferring that other copy's UID.
	if not wearer(uid).is_empty():return false
	if who!="persona" or active():return super(who,uid)
	var e=gear_entry(uid)
	if e.is_empty():return false
	var item=gear.by_id[e.id]
	if item.cls!=class_def(who).get("id","") or s.members[who].level<gear.rules.equip_lv[item.rarity]:return false
	var old=wearer(uid)
	if old!="":s.equipment[old].erase(item.slot)
	s.equipment[who][item.slot]=uid;return true

func unequip(who: String,slot: String) -> bool:
	if s.equipment.get(who,{}).has(slot) and bag_count()>=2000:return false
	if who!="persona" or active():return super(who,slot)
	if not s.equipment[who].has(slot):return false
	s.equipment[who].erase(slot);return true

func shop_stock(who: String,slot: String) -> Array:
	var cls=who if who in shop_classes() else class_def(who).get("id","") if who=="persona" or who in s.owned else ""
	if cls.is_empty() or slot not in Gear.SLOT:return []
	return gear.stock_source(s.town_r21.seed,int(s.day),cls,slot).filter(func(e):return gear.rules.equip_lv[gear.by_id[e.id].rarity]<=highest_level())

func buy_gear(id: String,who: String) -> bool:
	if active() or bag_count()>=2000:return false
	var found={}
	for slot in Gear.SLOT:
		for row in shop_stock(who,slot):
			if id in [row.id,row.code]:found=row;break
	if found.is_empty() or stock_sold(found.code):return false
	var amount=price({"price":found.price})
	if s.gold<amount:return false
	s.gold-=amount;bank_expedition_gear([found.code])
	if s.commerce_r21.sold_day!=s.day:s.commerce_r21.sold_day=s.day;s.commerce_r21.bought={}
	s.commerce_r21.bought[found.code]=true;shop_got[found.code]=shop_got.get(found.code,0)+1
	s.ui.msg="장비를 샀습니다: "+gear.by_id[found.id].name;note(s.ui.msg);shop_after_buy();return true

func buy(id: String) -> bool:
	var item=item_def(id)
	if active() or item.is_empty() or item.get("nosale",false) or item.has("slot") or s.gold<price(item):return false
	s.gold-=price(item);s.items[id]=s.items.get(id,0)+1;s.ui.msg=item.name+" 하나를 샀습니다. (보유 %d, 남은 금화 %d)"%[s.items[id],s.gold];note(s.ui.msg)
	shop_got[id]=shop_got.get(id,0)+1
	shop_after_buy()
	return true

func shop_after_buy() -> void:
	# 71-shop: use affection BEFORE this purchase and a persistent buy counter.
	var before=float(s.npc_aff_r21.get("pietro",0))
	var buys=int(s.commerce_r21.get("pietro_buys",0))+1
	s.commerce_r21.pietro_buys=buys;npc_like("pietro")
	if before>=50 and dungeon_rules.mix(int(s.town_r21.seed),9157,buys,3)<.30:
		if not s.get("items") is Dictionary:s.items={}
		if s.items.get("charm_potion",0)<99:
			s.items.charm_potion=s.items.get("charm_potion",0)+1
			var message="피에트로가 덤으로 「매혹의 비약」 하나를 슬쩍 얹어 주었다. (보유 %d)"%s.items.charm_potion
			s.ui.msg=s.ui.get("msg","")+" "+message;note(message)

func battle_data() -> Dictionary:
	var data=super()
	# The shop gift is an account-only noncombat item. The battle schema retains
	# its existing item references; no second server allowlist needs broadening.
	if data.get("inventory") is Dictionary:data.inventory.erase("charm_potion")
	return data

func record_battle(snapshot: Dictionary) -> void:
	var has_bonus=s.items.has("charm_potion");var bonus=s.items.get("charm_potion",0)
	super(snapshot)
	if has_bonus:s.items.charm_potion=bonus

func process_classes() -> Array:
	return gear.classes(class_def("persona").get("id",""),s.owned.map(func(id):return class_def(id).id))

func process_gear(_who: String="") -> bool:
	if active() or bag_count()>=2000:return false
	var amount=gear.band(highest_level()).price
	if s.gold<amount:facility_message="금화가 모자랍니다. 가공 값 %d, 가진 금화 %d"%[amount,s.gold];return false
	var next=int(s.commerce_r21.process_n)+1
	var result=gear.process_source(s.town_r21.seed,next,process_classes(),highest_level())
	if result.is_empty():return false
	s.gold-=amount;s.commerce_r21.process_n=next;bank_expedition_gear([result.code])
	smithy_work.append({"kind":"process","code":result.code,"name":gear.by_id[result.id].name})
	smithy_fx={"kind":"process","name":gear.by_id[result.id].name}
	npc_like("hanna");note("한나의 가공 · "+gear.by_id[result.id].name);return true

func forge(uid: int) -> bool:
	var e=gear_entry(uid)
	if active() or e.is_empty():return false
	var code=gear.code(e);var state=s.commerce_r21.get("forge_codes_r22",{}).get(code,{"forge":e.forge,"tries":e.tries})
	# The bot stores refinement by code, so duplicate bag/equipped copies share it.
	for copy in s.gear:
		if gear.code(copy)==code:
			state.forge=maxi(int(state.forge),int(copy.forge));state.tries=maxi(int(state.tries),int(copy.tries))
	if state.forge>=10:return false
	var input=e.duplicate(true);input.forge=state.forge;input.tries=state.tries
	var amount=gear.forge_cost(input)
	if s.gold<amount:return false
	var old=state.forge;var success=gear.forge_result(s.town_r21.seed,input)
	s.gold-=amount;state.tries+=1
	if success:state.forge+=1
	if not s.commerce_r21.has("forge_codes_r22"):s.commerce_r21.forge_codes_r22={}
	s.commerce_r21.forge_codes_r22[code]=state
	for copy in s.gear:
		if gear.code(copy)==code:copy.forge=state.forge;copy.tries=state.tries
	npc_like("hanna");note(gear.by_id[e.id].name+(" 제련 성공 +%d"%e.forge if success else " 제련 실패. 장비는 그대로입니다."))
	smithy_work.append({"kind":"forge","code":gear.code(e),"name":gear.by_id[e.id].name,"level":e.forge,"tries":e.tries,"success":e.forge>old})
	smithy_fx={"kind":"forge","success":e.forge>old,"name":gear.by_id[e.id].name,"level":e.forge}
	return true

func bank_expedition_gear(codes: Array) -> Dictionary:
	var out=[];var lost=[]
	for code in codes:
		if not valid_gear_code(code):lost.append(code);continue
		var state=s.commerce_r21.get("forge_codes_r22",{}).get(code,{"forge":0,"tries":0})
		var entry=combat_gear_adapter.entry(code,int(s.serial)+1,{"lv":state.forge,"tries":state.tries})
		if bag_count()>=2000:
			if not s.has("gear_r22"):s.gear_r22={}
			if not s.gear_r22.has("overflow"):s.gear_r22.overflow=[]
			s.gear_r22.overflow.append({"code":code,"forge":{"lv":state.forge,"tries":state.tries}})
			lost.append(code);continue
		s.serial+=1;s.gear.append(entry);out.append(code)
	return {"gear":out,"lost":lost.size()}

func smithy_list() -> Array:
	var by_code={}
	for e in s.gear:
		var code=gear.code(e)
		if not by_code.has(code):by_code[code]=e
	var codes=by_code.keys();codes.sort()
	return codes.map(func(code):return by_code[code])

func smithy_select(tab: String) -> bool:
	if tab not in ["forge","process"]:return false
	smithy_tab=tab;smithy_fx={};return true

func scroll_targets() -> Array:
	return ["persona"]+s.owned

func use_item(id: String,who: String) -> bool:
	if id!="level_scroll":return super(id,who)
	if active() or who not in scroll_targets() or s.items.get(id,0)<1 or s.members[who].level>=40:return false
	var m=s.members[who];m.level+=1;m.xp=0;s.items[id]-=1
	if who=="persona":
		s.persona.lv=m.level;s.persona.exp=0;s.lv=m.level
		s.persona_progress_r21={"level":m.level,"xp":0}
	note("레벨이 올랐습니다. Lv %d."%m.level);return true

func item_preview(id: String,who: String) -> Dictionary:
	if id!="level_scroll":return super(id,who)
	var lv=int(s.members.get(who,{}).get("level",40))
	var usable=who in scroll_targets() and s.items.get(id,0)>0 and lv<40 and not active()
	return {"usable":usable,"before":lv,"after":mini(40,lv+1),"maximum":40,"resource":"Lv.","reason":"" if usable else "마을에서 스크롤을 보유하고 Lv.40 미만의 대상을 고르세요."}

func reject_quest(id: int) -> bool:
	if active() or s.quest.get("id",-1)==id:return false
	if GuildR22.find_quest(s.board,id)==null:return false
	GuildR22.remove_quest(s.board,id);fill_source_board();return true

func settle(result: String) -> bool:
	if not r21() or not s.run.has("source_quest"):return super(result)
	var r=s.run
	if not active() or result not in ["clear","defeat"] or r.phase!="battle" or r.battle.is_empty():return false
	var b=ModernBattle.new(battle_data())
	if not b.restore(r.battle) or b.result!=("victory" if result=="clear" else "defeat"):return false
	var q=r.source_quest;var won=result=="clear";var mods=expedition_mods()
	var amount=GuildR22.reward_gold(int(r.gold),int(round((mods.gold-1)/.15))) if won else 0
	var penalty=0 if won else GuildR22.loss(int(s.gold),int(q.get("stars",1)))
	var xp=int(r.xp) if won else 0;var before={};var gains=[];var codes=[]
	for id in expedition_ids():before[id]=s.members[id].level
	if won:
		award_persona_exp({"exp":xp,"sid":int(r.id)*32+31,"pm":r.persona_pm})
		for id in expedition_ids():
			if id!="persona":aff_add(id,dungeon_rules.config.affection.QUEST*mods.aff)
		if dungeon_rules.quest_difficulty(q)=="엘리트":
			for i in range(1,GuildR22.gear_count(s.town_r21.seed,GuildR22.source_id(q))+1):
				var drop=GuildR22.elite_gear(dungeon_rules,s.town_r21.seed,GuildR22.source_id(q),party_classes(),i)
				if not drop.is_empty():codes.append(drop.code)
		bank_expedition_gear(codes);s.quest_wins+=1;s.dungeon_r21.runs+=1
	s.gold+=amount-penalty
	for id in expedition_ids():gains.append({"id":id,"before":before[id],"level":s.members[id].level,"xp":s.members[id].xp})
	s.summary={"result":result,"gold":amount,"xp":xp,"wins":1 if won else 0,"lost":0,"gains":gains,"floor":r.floor,"penalty":penalty,"title":q.title,"gear":codes}
	s.quest={};s.board=s.board.filter(func(row):return row.id!=q.id);s.refreshes=0;s.day+=1
	r.phase="done";r.battle={};r.loot_items={};r.loot_gear=[]
	fill_source_board();npc_like("fenella")
	note("의뢰 「%s」 %s. 금화 %d."%[GuildR22.title(q),"완료" if won else "실패",amount if won else -penalty]);return true

func facility_route(page: String) -> bool:
	# Native receipts replace the bot's host-generated AI scene, without network/chat.
	var next=page if page in ["shop","smithy","inn","guild","recruit","research"] else "town"
	if page=="facility_scroll":next="shop"
	if next in ["recruit","research"]:next="guild"
	if next==facility:return true
	if not receipt.is_empty():facility_message="먼저 거래 내역을 확인하세요.";return false
	if facility=="smithy" and not smithy_work.is_empty():
		facility_message="제련이나 가공을 마쳤다면 「제련 및 가공 완료」를 눌러 한나와 이야기를 나눈 뒤 돌아갈 수 있습니다.";return false
	if facility=="guild":
		for id in s.research_editor_r21:
			if research_dirty(id):facility_message="먼저 저장하세요. 로레다나의 스킬 조합에 저장하지 않은 변경이 있습니다.";return false
	if facility=="shop" and not shop_got.is_empty():
		receipt={"kind":"shop","items":shop_got.duplicate(true),"gold":s.gold};shop_got={}
	if facility=="smithy":smithy_fx={};smithy_tab="forge"
	facility=next;facility_message=""
	return true

func complete_smithy() -> bool:
	if facility!="smithy" or smithy_work.is_empty() or not receipt.is_empty():return false
	var ledger={"forge":[],"proc":[]}
	for row in smithy_work:
		if row.kind=="forge":ledger.forge.append({"code":row.code,"ok":row.success,"lv":row.level})
		else:ledger.proc.append(row.code)
	var work=gear.work_of(ledger)
	receipt={"kind":"smithy","work":smithy_work.duplicate(true),"gold":s.gold,"source_note":gear.work_note(work)};smithy_work=[];smithy_fx={};facility_message="";return true

func acknowledge_receipt() -> bool:
	if receipt.is_empty():return false
	receipt={};facility_message="";return true

func restore(value: Variant) -> bool:
	if not value is Dictionary or not value.get("items") is Dictionary:return false
	if not _num(value.get("gold")) or value.gold<0 or value.gold!=floor(value.gold) or value.gold>9007199254740991:return false
	var probe=value.duplicate(true)
	var commerce=value.get("commerce_r21",{})
	if commerce is Dictionary and commerce.has("pietro_buys"):
		var buys=commerce.pietro_buys
		if not _num(buys) or buys<0 or buys!=floor(buys) or buys>9007199254740991:return false
	var old_progress=value.get("persona_progress_r21",{})
	# A schema-3 P6 mirror is not a second migration transaction on every reload.
	# Legacy D progress still reaches the adapter, which archives its original persona.
	if value.get("schema")==3:probe.erase("persona_progress_r21")
	probe.gold=mini(100000000,int(value.gold))
	for id in probe.items:
		var n=probe.items[id]
		if not _num(n) or n<0 or n!=floor(n) or n>9007199254740991:return false
		probe.items[id]=mini(10000,int(n))
	var codes=value.get("commerce_r21",{}).get("forge_codes_r22",{}) if value.get("commerce_r21",{}) is Dictionary else null
	if not codes is Dictionary:return false
	for code in codes:
		if not code is String or not valid_gear_code(code) or not _shape(codes[code],{"forge":0,"tries":0}):return false
		var f=codes[code]
		if f.forge<0 or f.forge>10 or f.forge!=floor(f.forge) or f.tries<0 or f.tries!=floor(f.tries):return false
	if not super(probe):return false
	s.gold=value.gold
	s.items.merge(value.items.duplicate(true),true)
	var current={"level":s.persona.lv,"xp":s.persona.exp}
	if not old_progress.is_empty() and old_progress!=current:
		if not s.commerce_r21.has("legacy_persona_progress_r22"):s.commerce_r21.legacy_persona_progress_r22=old_progress.duplicate(true)
	if value.has("persona_progress_r21"):s.persona_progress_r21=current
	# Visits are transient in 71-shop/82-smithy; account counters stay in the save.
	facility="town";smithy_work=[];shop_got={};receipt={};smithy_fx={};facility_message=""
	return true
