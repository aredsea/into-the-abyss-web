extends "res://game/dungeon_world_r21.gd"
## Additive town corrections. schema 1/2 and live battle snapshots stay intact.
const TOWN_RULES = preload("res://game/town_rules_r21.gd")

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
	# Branch A can replace only this boundary when its ten destinations land.
	return [{"id":"academy-review","name":"학술원 폐허 상층","floor":2,"image":"res://assets/src/academy.png","route":"갈림길 탐색 → 집행실 정예 → 귀환","provisional":true}]

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
