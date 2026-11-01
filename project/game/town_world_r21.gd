extends "res://game/dungeon_world_r21.gd"
## Additive town corrections. schema 1/2 and live battle snapshots stay intact.
const TOWN_RULES = preload("res://game/town_rules_r21.gd")
const Guild=preload("res://game/guild_rules_r21.gd")
const Commerce=preload("res://game/commerce_rules_r21.gd")

func _init():
	super()
	gear=Commerce.new()
	ensure_town_r21()

func ensure_town_r21() -> void:
	if not s.has("commerce_r21"):s.commerce_r21={"process_n":0,"sold_day":s.day,"bought":{}}
	if not s.has("town_r21"):
		var qn=0
		for q in s.board:
			if q.get("source_id","").begins_with("q"): qn=maxi(qn,int(q.id))
		s.town_r21={"seed":int(s.rng),"counter":qn,"qn":qn}

func fill_source_board() -> void:
	while s.board.size()<4:
		s.town_r21.counter+=1; s.town_r21.qn+=1
		s.board.append(Guild.quest(s.town_r21.seed,s.town_r21.counter,s.town_r21.qn,highest_level(),s.board))

func refill_board() -> void:
	ensure_town_r21()
	s.board=[]
	if not s.quest.is_empty(): s.board.append(s.quest.duplicate(true))
	fill_source_board()

func abandon_quest() -> bool:
	if active() or s.quest.is_empty(): return false
	var id=s.quest.id;s.quest={};s.board=s.board.filter(func(q):return q.id!=id)
	fill_source_board();return true

func quest_contract(q: Dictionary) -> Dictionary:
	if q.is_empty(): return {}
	if q.get("cmp",false): return q.duplicate(true)
	# Preserve previously accepted quests and their saved reward; do not reroll.
	var out=q.duplicate(true)
	out.difficulty={"하":"낮음","중":"중간","상":"높음","정예":"엘리트"}.get(q.difficulty,q.difficulty)
	out.lv=int(q.get("level",1)); out.cmp=true; out.stars=2 if q.rift=="남동 숲 균열" else 1
	out.kind="토벌" if "토벌" in q.name else "구조" if "구조" in q.name else "회수"
	out.title=q.rift+", "+q.name; out.migration_from="legacy-web"; out.source_id="legacy-"+str(q.id)
	return out

func depart_accepted_quest() -> bool:
	if active() or s.quest.is_empty(): return false
	return depart_rift_quest(quest_contract(s.quest))

func settle(result: String) -> bool:
	var quest_run=r21() and s.run.has("source_quest")
	var accepted=s.run.get("source_quest",{}).duplicate(true)
	if not super(result): return false
	if quest_run and result in ["clear","defeat"]:
		if result=="clear":
			s.quest_wins+=1
			var adjusted=Guild.reward_gold(int(s.summary.gold),party_count("nation","마렌토 공화국"))
			s.gold+=adjusted-s.summary.gold;s.summary.gold=adjusted
			if dungeon_rules.quest_difficulty(accepted)=="엘리트":
				var qn=int(str(accepted.get("source_id",str(accepted.id))).trim_prefix("q").trim_prefix("legacy-"))
				for i in range(1,Guild.gear_count(s.town_r21.seed,qn)+1):
					var drop=Guild.elite_gear(dungeon_rules,s.town_r21.seed,qn,party_classes(),i)
					if not drop.is_empty() and gear.by_id.has(drop.id) and s.gear.size()<2000:
						s.serial+=1;s.gear.append({"uid":s.serial,"id":drop.id,"seed":drop.seed,"forge":0,"tries":0})
		if s.quest.get("id",-1)==accepted.get("id",-2): s.quest={}
		# A already pays quest_gold in finish_battle. Never pay it a second time.
		s.board=s.board.filter(func(q):return q.id!=accepted.get("id",-1))
		s.refreshes=0;fill_source_board()
	return true

func restore(value: Variant) -> bool:
	if not value is Dictionary: return false
	var previous=s.duplicate(true)
	if value.has("commerce_r21"):
		var c=value.commerce_r21
		if not c is Dictionary or not _shape(c,{"process_n":0,"sold_day":0,"bought":{}}):return false
		if c.process_n<0 or c.process_n!=int(c.process_n) or c.sold_day<1 or c.sold_day!=int(c.sold_day) or c.sold_day>value.get("day",0):return false
		for key in c.bought:
			if not key is String or not c.bought[key] is bool:return false
	for e in value.get("gear",[]):
		if e is Dictionary and e.has("source_r21") and not e.source_r21 is bool:return false
	if value.has("town_r21"):
		var t=value.town_r21
		if not t is Dictionary or not _shape(t,{"seed":0,"counter":0,"qn":0}) or t.seed<1 or t.seed>=2147483647 or t.seed!=int(t.seed) or t.counter<0 or t.qn<0 or t.counter!=int(t.counter) or t.qn!=int(t.qn): return false
	s.erase("town_r21")
	s.erase("commerce_r21")
	if not super(value): s=previous; return false
	ensure_town_r21()
	return true

func shop_stock(who: String,slot: String) -> Array:
	if who not in s.owned or slot not in Gear.SLOT:return []
	var rows=gear.stock_source(s.town_r21.seed,int(s.day),class_def(who).id,slot)
	return rows.filter(func(e):return gear.rules.equip_lv[gear.by_id[e.id].rarity]<=highest_level())
func stock_sold(code: String) -> bool:return s.commerce_r21.sold_day==s.day and s.commerce_r21.bought.get(code,false)
func buy_gear(id: String,who: String) -> bool:
	if active() or who not in s.owned or s.gear.size()>=2000:return false
	var found={}
	for slot in Gear.SLOT:
		for row in shop_stock(who,slot):
			if id in [row.id,row.code]:found=row;break
	if found.is_empty() or stock_sold(found.code):return false
	var amount=price({"price":found.price})
	if s.gold<amount:return false
	s.gold-=amount;s.serial+=1;s.gear.append({"uid":s.serial,"id":found.id,"seed":found.seed,"forge":0,"tries":0,"source_r21":true})
	if s.commerce_r21.sold_day!=s.day:s.commerce_r21.sold_day=s.day;s.commerce_r21.bought={}
	s.commerce_r21.bought[found.code]=true;note(gear.by_id[found.id].name+" 구입");return true
func process_gear(_who: String) -> bool:
	if active() or s.gear.size()>=2000:return false
	var amount=gear.band(highest_level()).price
	if s.gold<amount:return false
	var classes=s.owned.map(func(id):return class_def(id).id)
	var result=gear.process_source(s.town_r21.seed,int(s.commerce_r21.process_n)+1,classes,highest_level())
	if result.is_empty():return false
	s.gold-=amount;s.commerce_r21.process_n+=1;s.serial+=1
	s.gear.append({"uid":s.serial,"id":result.id,"seed":result.seed,"forge":0,"tries":0,"source_r21":true})
	note("한나의 가공 · "+gear.by_id[result.id].name);return true
func forge(uid: int) -> bool:
	var e=gear_entry(uid)
	if active() or e.is_empty() or e.forge>=10:return false
	var amount=gear.forge_cost(e)
	if s.gold<amount:return false
	var success=gear.forge_result(s.town_r21.seed,e)
	s.gold-=amount;e.tries+=1
	if success:e.forge+=1
	note(gear.by_id[e.id].name+(" 강화 성공 +%d"%e.forge if success else " 강화 실패 · 장비 보존"));return true

func need(level: int) -> int: return TOWN_RULES.need(level)

func recruit_fee() -> int: return TOWN_RULES.recruit_cost(s.recruits)
func refresh_fee() -> int: return TOWN_RULES.refresh_cost(s.refreshes)

func price(item: Dictionary) -> int:
	var count=0
	for id in s.party:
		if person(id).nation=="마렌토 공화국": count+=1
	return TOWN_RULES.shop_price(float(item.price),count)

func buy(id: String) -> bool:
	var item=item_def(id)
	if active() or item.is_empty() or s.gold<price(item) or s.items[id]>=10000: return false
	s.gold-=price(item); s.items[id]+=1; note(item.name+" 구입"); return true

func inn(id: String,action: String) -> bool:
	var acts=TOWN_RULES.DATA.inn
	if active() or id not in s.owned or not acts.has(action): return false
	var def=acts[action]; var key=id+"_"+action
	if s.gold<def.cost or (not def.day and s.acts.get(key,0)==s.day): return false
	s.gold-=def.cost
	if def.day: s.day+=1
	else: s.acts[key]=s.day
	s.members[id].aff=TOWN_RULES.aff_next(s.members[id].aff,def.aff)
	note(person(id).name+" · "+def.name); return true

func dungeon_catalog() -> Array:
	var out=[]
	for id in dungeon_rules.config.zone_order:
		var z=dungeon_rules.zones[id]
		out.append({"id":id,"name":z.name,"floor":int(z.floors[0]),"last_floor":int(z.floors[1]),"unlocked":z.floors[0]<=dungeon_max(),"image":"res://assets/src/academy.png","route":"탐색 5회 → 휴식 → 층 보스","provisional":false})
	return out

func item_preview(id: String,who: String) -> Dictionary:
	var it=item_def(id)
	if it.is_empty() or who not in s.owned: return {"usable":false,"reason":"보유한 동료와 보급품을 선택하세요."}
	var m=s.members[who]; var b=stats(who,m.level); var out={"usable":false,"before":m.hp,"after":m.hp,"maximum":b.hp,"resource":"HP","reason":""}
	if s.items.get(id,0)<1: out.reason="보유한 보급품이 없습니다."; return out
	if m.level<it.level: out.reason="Lv.%d부터 사용합니다." % it.level; return out
	if active() and s.run.phase=="battle": out.reason="전투의 보급품 메뉴에서 사용하세요."; return out
	match it.kind:
		"hp","mp":
			var k=it.kind; out.before=m[k]; out.maximum=b[k]; out.resource=k.to_upper()
			out.after=mini(b[k],m[k]+int(round(b[k]*it.fraction)))
			out.usable=m.hp>0 and m[k]<b[k]
			if not out.usable: out.reason="쓰러진 동료에게는 붕대를 사용하세요." if m.hp<=0 else "이미 가득 찼습니다."
		"revive":
			out.after=maxi(1,int(b.hp*it.fraction)); out.usable=m.hp==0
			if not out.usable: out.reason="쓰러진 동료에게 사용합니다."
		"level":
			out.before=m.level; out.after=mini(40,m.level+1); out.maximum=40; out.resource="Lv."
			out.usable=not active() and m.level<40
			if not out.usable: out.reason="마을에서 Lv.40 미만의 동료에게 사용합니다."
		"return":
			out.usable=active() and s.run.phase in ["explore","rest"]
			if not out.usable: out.reason="원정 탐색 중 사용합니다."
		_: out.reason="전투의 보급품 메뉴에서 사용하세요."
	return out

func gear_comparison(id: String,uid: int) -> Dictionary:
	var entry=gear_entry(uid)
	if entry.is_empty() or id not in s.owned: return {}
	var item=gear.by_id[entry.id]; var level=s.members[id].level
	if item.cls!=class_def(id).id: return {}
	var old=s.equipment[id].get(item.slot,0); var before={}
	if old: before=gear.roll(gear_entry(old),level)
	var after=gear.roll(entry,level); var delta={}
	for key in before: delta[key]=after.get(key,0)-before[key]
	for key in after: delta[key]=after[key]-before.get(key,0)
	return {"before":before,"after":after,"delta":delta,"slot":item.slot,"can_equip":level>=gear.rules.equip_lv[item.rarity] and not active(),"roll_authority":"legacy-web-rng"}
