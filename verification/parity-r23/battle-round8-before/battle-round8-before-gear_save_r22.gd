extends RefCounted
## Explicit, lossless import. Never rewrites the input, saves a file, upgrades a
## legacy RNG entry to source_r21, or discards overflow. Caller commits returned
## state atomically through the existing world store after reviewing conflicts.
const Rules=preload("res://game/gear_rules_r22.gd")
var rules=Rules.new()

func entry(value: String,uid: int,forge: Dictionary={}) -> Dictionary:
	var p=rules.gear_parse(value)
	if p.is_empty() or not rules.source.items.has(p.id):return {}
	return {"uid":uid,"id":p.id,"seed":p.seed,"forge":forge.get("lv",0),"tries":forge.get("tries",0),"source_r21":true,"code":value}

func source_drop(drop: Dictionary,uid: int) -> Dictionary:
	# Both source drop code and native id/seed form enter the same original path.
	return entry(drop.get("code",rules.gear_code(drop.get("id",""),int(drop.get("seed",0)))),uid)

func import_codes(native: Dictionary,payload: Dictionary) -> Dictionary:
	var next=native.duplicate(true);var fingerprint=JSON.stringify(payload).sha256_text()
	if next.get("gear_r22",{}).get("imports",{}).has(fingerprint):return {"ok":true,"state":next,"added":0,"replayed":true}
	var bag_raw=payload.get("bag","")
	if not bag_raw is String:return {"ok":false,"error":"bag must be a string"}
	var codes=rules.bag_load(bag_raw)
	# Preserve invalid tokens in archive too; the original bag loader filters them.
	var pending=[]
	for c in codes:pending.append({"code":c})
	var equip=payload.get("equip",{})
	if not equip is Dictionary and not (equip is Array and equip.is_empty()):return {"ok":false,"error":"equip must be a table"}
	if equip is Dictionary:
		for cid in equip:
			if not equip[cid] is Dictionary:continue
			for slot in Rules.SLOTS:
				var c=equip[cid].get(slot,"")
				if c is String and c!="":pending.append({"code":c,"cid":cid,"slot":slot})
	if not next.get("gear") is Array:next.gear=[]
	if not next.get("equipment") is Dictionary:next.equipment={}
	var serial=int(next.get("serial",0));var worn=[]
	for cid in next.equipment:
		if next.equipment[cid] is Dictionary:
			for uid in next.equipment[cid].values():
				if uid!=0:worn.append(uid)
	var bag_count=0
	for e in next.gear:
		serial=maxi(serial,int(e.uid))
		if e.uid not in worn:bag_count+=1
	var overflow=[];var conflicts=[];var added=0;var imported=[]
	for item in pending:
		var code=item.code;var f=payload.get("forge",{}).get(code,{}) if payload.get("forge") is Dictionary else {}
		item["import"]=fingerprint;item.forge=f.duplicate(true) if f is Dictionary else {}
		var e=entry(code,serial+1,f if f is Dictionary else {})
		if e.is_empty():conflicts.append(item);continue
		var can_wear=item.has("cid") and next.equipment.has(item.cid) and rules.source.items[e.id].slot==item.slot
		if can_wear:
			var g={"persona":next.get("persona",{}),"lvl":{}}
			for cid in next.get("members",{}):g.lvl[cid]=next.members[cid].get("level",1)
			can_wear=rules.gear_can_equip(g,item.cid,code)[0]
		if can_wear:
			if not next.equipment.get(item.cid) is Dictionary:next.equipment[item.cid]={}
			can_wear=int(next.equipment[item.cid].get(item.slot,0))==0
		if not can_wear and bag_count>=Rules.BAG_MAX:overflow.append(item);continue
		serial+=1;next.gear.append(e);added+=1;imported.append(e.uid)
		if can_wear:next.equipment[item.cid][item.slot]=e.uid
		else:bag_count+=1
	if not next.get("gear_r22") is Dictionary:next.gear_r22={"imports":{},"overflow":[],"conflicts":[]}
	if not next.gear_r22.get("imports") is Dictionary:next.gear_r22.imports={}
	if not next.gear_r22.get("overflow") is Array:next.gear_r22.overflow=[]
	if not next.gear_r22.get("conflicts") is Array:next.gear_r22.conflicts=[]
	next.gear_r22.imports[fingerprint]={"payload":payload.duplicate(true),"uids":imported}
	next.gear_r22.overflow.append_array(overflow);next.gear_r22.conflicts.append_array(conflicts)
	next.serial=serial
	return {"ok":true,"state":next,"added":added,"overflow":overflow.size(),"conflicts":conflicts.size(),"replayed":false}

func claim_pending(native: Dictionary) -> Dictionary:
	var next=native.duplicate(true);var meta=next.get("gear_r22",{})
	if not meta is Dictionary or not meta.get("overflow") is Array:return {"state":next,"added":0}
	var worn=[];var serial=int(next.get("serial",0));var count=0;var keep=[];var added=0
	for eq in next.get("equipment",{}).values():
		if eq is Dictionary:worn.append_array(eq.values())
	for e in next.get("gear",[]):
		serial=maxi(serial,int(e.uid))
		if e.uid not in worn:count+=1
	for item in meta.overflow:
		var e=entry(item.code,serial+1,meta.get("forge",{}).get(item.code,item.get("forge",{})))
		if count>=Rules.BAG_MAX or e.is_empty():keep.append(item);continue
		serial+=1;count+=1;added+=1;next.gear.append(e)
		if meta.get("imports",{}).has(item.get("import","")):meta.imports[item["import"]].uids.append(e.uid)
	meta.overflow=keep;next.serial=serial
	return {"state":next,"added":added}

func source_forge_try(native: Dictionary,account_seed: int,code: String) -> Dictionary:
	# Source forge identity is CODE, even when duplicate codes have different UIDs.
	# Legacy entries keep their old per-UID forge contract and are never included.
	var next=native.duplicate(true);var bag=[];var f={};var worn=[]
	for eq in next.get("equipment",{}).values():
		if eq is Dictionary:worn.append_array(eq.values())
	var equip={}
	for e in next.get("gear",[]):
		if not e.get("source_r21",false):continue
		var c=rules.code(e)
		if c==code and f.is_empty():f={"lv":e.forge,"tries":e.get("tries",0)}
		if e.uid not in worn:bag.append(c)
		else:
			if not equip.has("worn"):equip.worn={}
			# Only ownership is needed by forge_try; no slot is replaced in native.
			if c==code:equip.worn.weapon=c
	var meta=next.get("gear_r22",{})
	if meta.get("forge",{}).has(code):f=meta.forge[code].duplicate(true)
	var game={"gold":next.get("gold",0),"seed":account_seed,"equip":equip,"forge":{}}
	if not f.is_empty():game.forge[code]=f
	var result=rules.forge_try(game,bag,code)
	if result[0]==null:return {"state":next,"result":result}
	if not next.has("gear_r22"):next.gear_r22={}
	if not next.gear_r22.has("forge"):next.gear_r22.forge={}
	var updated=game.forge[code];next.gear_r22.forge[code]=updated.duplicate(true);next.gold=game.gold
	for e in next.gear:
		if e.get("source_r21",false) and rules.code(e)==code:e.forge=updated.lv;e.tries=updated.tries
	return {"state":next,"result":result}

func restore(world: Object,snapshot: Dictionary) -> bool:
	# Existing validator handles the whole native save. Install the original roll
	# adapter before it clamps member HP/MP; restore never writes a disk save.
	var old_rules=world.gear;world.gear=Rules.new()
	if not world.restore(snapshot):world.gear=old_rules;return false
	return true

func battle_member(native: Dictionary,cid: String,cls: String,level: int) -> Dictionary:
	var eq={};var list={};var forge={};var worn=native.get("equipment",{}).get(cid,{})
	for slot in Rules.SLOTS:
		var uid=int(worn.get(slot,0))
		for e in native.get("gear",[]):
			if int(e.uid)!=uid:continue
			list[slot]=e.duplicate(true)
			if e.get("source_r21",false):
				var code=rules.code(e);eq[slot]=code;forge[code]={"lv":e.forge,"tries":e.get("tries",0)}
	return {"id":cid,"cls":cls,"L":level,"eq":eq,"forge":forge,"native_eq":list}
