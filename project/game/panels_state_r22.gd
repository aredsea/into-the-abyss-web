extends RefCounted
## P7 facade. Keeps native UID/seed/forge entries intact; no gear migration.
const R=preload("res://game/panels_rules_r22.gd")
var model
var ui={"tab":"","sel":"","page":1,"msg":"","panel":"codex"}
var bg={"pg":1,"cls":"","slot":"","rar":"","sel":"","cmp":"","conf":""}
func _init(world=null):
	model=world
	if model and model.s.get("panels_r22") is Dictionary:
		var saved=model.s.panels_r22
		for k in ui:
			if typeof(saved.get(k))==typeof(ui[k]):ui[k]=saved[k]
			elif ui[k] is int and saved.get(k) is float and is_finite(saved[k]):ui[k]=maxi(1,int(saved[k]))
		if saved.get("bg") is Dictionary:
			for k in bg:
				if typeof(saved.bg.get(k))==typeof(bg[k]):bg[k]=saved.bg[k]
				elif bg[k] is int and saved.bg.get(k) is float and is_finite(saved.bg[k]):bg[k]=maxi(1,int(saved.bg[k]))
func persist() -> void:
	model.s.panels_r22=ui.duplicate(true);model.s.panels_r22.bg=bg.duplicate(true)
func favs() -> Array:
	var raw=model.s.get("favs",[])
	return raw.filter(func(id):return id in model.s.owned) if raw is Array else []
func cx(arg: String) -> void:
	var g={"ui":ui,"roster":model.s.owned,"party":model.s.party,"favs":favs(),"scene":"battle" if in_battle() else "town"}
	R.cx_action(g,arg);ui=g.ui
	if arg=="fav":model.s.favs=g.favs
	if ui.has("bg"):bg=ui.bg;ui.erase("bg")
	persist()
func in_battle() -> bool:return model.active() and model.s.run.phase=="battle"
func entries() -> Array:
	var out=[]
	for raw in model.s.gear:
		if model.wearer(int(raw.uid))!="":continue
		var e=raw.duplicate();e.code=model.gear.code(raw);out.append(e)
	return out
func listing() -> Array:return R.bag_list(entries(),model.gear.by_id,bg)
func selected() -> Dictionary:
	for e in entries():
		if e.code==bg.sel:return e
	return {}
func members(item_class: String) -> Array:
	var out=[];var ids=[]
	if model.s.get("persona",{}).get("cls","")!="":ids.append("persona")
	for id in model.s.party:
		if id in model.s.owned and id not in ids:ids.append(id)
	for id in R.DATA.order:
		if id in model.s.owned and id not in ids and model.class_def(id).id==item_class:ids.append(id)
	for id in ids:out.append({"id":id,"same":model.class_def(id).get("id","")==item_class})
	return out
func can_equip(id: String,e: Dictionary) -> String:
	if in_battle():return "전투 중에는 장비를 바꿀 수 없습니다."
	if e.is_empty():return "가방에 없는 장비입니다."
	if id!="persona" and id not in model.s.owned:return "보유한 동료를 선택하세요."
	var c=model.class_def(id)
	if c.is_empty():return "직업을 알 수 없습니다."
	var it=model.gear.by_id[e.id]
	if c.id!=it.cls:return "다른 직업 전용 장비입니다."
	var lv=model.gear.rules.equip_lv[it.rarity]
	if model.s.members[id].level<lv:return "Lv %d부터 낄 수 있습니다."%lv
	return ""
func equip(id: String,e: Dictionary) -> bool:
	ui.msg=can_equip(id,e)
	if ui.msg!="":return false
	if not entries().any(func(raw):return raw.uid==e.uid):ui.msg="가방에 없는 장비입니다.";return false
	if not model.s.equipment.has(id):model.s.equipment[id]={}
	model.s.equipment[id][model.gear.by_id[e.id].slot]=e.uid
	model._clamp_members()
	ui.msg="장비를 장착했습니다. 끼고 있던 장비는 가방으로 돌아갑니다."
	return true
func unequip(id: String,slot: String) -> bool:
	if in_battle():ui.msg="전투 중에는 장비를 바꿀 수 없습니다.";return false
	if entries().size()>=2000:ui.msg="가방이 가득 찼습니다.";return false
	if not model.s.equipment.get(id,{}).has(slot):return false
	model.s.equipment[id].erase(slot);model._clamp_members();ui.msg="장비를 해제했습니다.";persist();return true
func candidates(id: String,slot: String) -> Array:
	var out=[]
	for e in entries():
		var it=model.gear.by_id[e.id]
		if it.slot==slot and it.cls==model.class_def(id).get("id","") and can_equip(id,e)=="":out.append(e)
	out.sort_custom(func(a,b):
		var x=model.gear.by_id[a.id].lv;var y=model.gear.by_id[b.id].lv
		return a.code<b.code if x==y else x>y)
	return out.slice(0,12)
func compare(e: Dictionary,id: String) -> Dictionary:
	if e.is_empty() or model.class_def(id).get("id","")!=model.gear.by_id[e.id].cls:return {}
	var it=model.gear.by_id[e.id];var lv=int(model.s.members[id].level);var old=model.gear_entry(int(model.s.equipment.get(id,{}).get(it.slot,0)))
	var before={} if old.is_empty() else model.gear.roll(old,lv);var after=model.gear.roll(e,lv)
	return {"before":before,"after":after,"rows":R.comparison(before,after),"old":old,"level":lv,"authority":"source-r21" if e.get("source_r21",false) else "legacy-preserved"}
func sell(e: Dictionary) -> bool:
	if in_battle() or e.is_empty() or model.wearer(int(e.uid))!="":return false
	model.s.gold+=model.gear.sell_price(e)
	for raw in model.s.gear:
		if raw.uid==e.uid:model.s.gear.erase(raw);break
	return true
func bulk() -> Dictionary:
	var count=0;var gold=0
	for e in entries():
		if model.gear.by_id[e.id].rarity=="common":count+=1;gold+=model.gear.sell_price(e)
	return {"count":count,"gold":gold}
func bg_action(arg: String) -> void:
	ui.msg=""
	if arg.begins_with("pg_"):bg.pg=maxi(1,int(arg.substr(3)));bg.sel="";bg.conf=""
	elif arg.begins_with("f_"):
		var parts=arg.substr(2).split("_",true,1)
		if parts.size()!=2:return
		var k=parts[0];var v="" if parts[1]=="all" else parts[1]
		if k not in ["cls","slot","rar"]:return
		if v!="" and ((k=="cls" and R.cls(v).get("id","")!=v) or (k=="slot" and v not in model.Gear.SLOT) or (k=="rar" and v not in R.RK)):return
		bg[k]=v;bg.pg=1;bg.sel="";bg.conf=""
	elif arg.begins_with("sel_"):
		var k=int(arg.substr(4));var list=listing();var index=(int(bg.pg)-1)*R.BAG_PAGE+k-1
		if k>=1 and k<=R.BAG_PAGE and index>=0 and index<list.size():bg.sel=list[index].code;bg.conf=""
	elif arg.begins_with("cmp_"):bg.cmp=arg.substr(4)
	elif arg=="back":bg.sel="";bg.conf=""
	elif arg.begins_with("eq_"):
		if equip(arg.substr(3),selected()):bg.sel="";bg.conf=""
	elif arg=="sell":
		var e=selected()
		if e.is_empty():return
		if model.gear.by_id[e.id].rarity in ["epic","legend"] and bg.conf!=bg.sel:bg.conf=bg.sel;persist();return
		if sell(e):ui.msg="장비를 판매했습니다."
		bg.sel="";bg.conf=""
	elif arg=="sellc":
		var result={"count":0,"gold":0}
		if not in_battle():
			result=bulk()
			for e in entries():
				if model.gear.by_id[e.id].rarity=="common":sell(e)
		ui.msg="일반 등급 장비 %d개를 팔아 금화 %d를 받았습니다."%[result.count,result.gold] if result.count>0 else "팔 일반 등급 장비가 없습니다."
		bg.sel="";bg.conf="";bg.pg=1
	persist()
