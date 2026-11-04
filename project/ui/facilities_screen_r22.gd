extends "res://ui/town_screen_r21.gd"
## P6 functional extension. D owns the inherited composition and artwork.
var selected_class=""
const FacilityLocale=preload("res://game/gear_locale_r23.gd")
const PanelNumbers=preload("res://game/panels_rules_r22.gd")
const FX_ORDER=["dmg","heal","shield","buff","dr","def","stat","crit","critdmg","spd","hp","mp","mpreg","reflect","dot","abyss","elite","lowhp","shdmg","healrecv","first","killmp","evade"]

func source_u(value: String,vars: Variant=null) -> String:
	return FacilityLocale.u(value,vars,L.language(host.model.s))

func source_t(value: String) -> String:
	return FacilityLocale.WORDS.get(value,L.t(value,"en")) if L.language(host.model.s)=="en" else value

# The guild and smithy tab helpers share source labels and selected-state rules.
func guild_tabs(selected: int) -> void:
	for i in range(3):
		var key=["guild","recruit","research"][i]
		var b=action("guild:"+key,source_u(["의뢰판","동료 소개","길드장 로레다나"][i]),Rect2(18+i*118,447,118,40),host.go.bind(key),selected==i,false,false)
		b.set_meta("source_selected",selected==i)
		b.add_theme_font_size_override("font_size",12)

func smithy_tabs() -> void:
	for i in range(2):
		var tab=["forge","process"][i]
		var b=action("sm_tab:"+tab,source_u(["제련","장비 가공"][i]),Rect2(18+i*177,378,177,40),func():host.model.smithy_action("tab_"+tab);host._draw_screen(),host.model.smithy_tab==tab,false,false)
		b.set_meta("source_selected",host.model.smithy_tab==tab)

func smithy_forge() -> void:
	var w=host.model;var rows=w.smithy_list();var y=0.0
	label(source_u("실패해도 장비는 그대로입니다."),Rect2(0,y,342,25),14,T.INK,T.BOLD,false);y+=40
	if rows.is_empty():paragraph(source_u("제련할 장비가 없습니다."),Rect2(0,y,342,70),15,T.INK,false);y+=82
	for e in rows:
		var item=w.gear.by_id[e.id]
		label(source_t(item.name)+" +%d"%e.forge,Rect2(0,y,342,28),19,T.INK,T.BOLD,false);y+=36
		if e.forge<10:
			var cost=w.gear.forge_cost(e);var chance=w.gear.rules.forge.success[int(e.forge)]
			action("forge:"+str(int(e.uid)),source_u("제련"),Rect2(0,y,114,42),func():host._act(w.smithy_action.bind("try_"+str(rows.find(e)+1)),""),true,w.s.gold<cost,false)
			label(source_u("금화 {cost} · 성공 {chance}%",{"cost":cost,"chance":chance}),Rect2(124,y,218,42),12,T.INK,T.BOLD,false)
		else:label("+10",Rect2(0,y,342,42),15,T.INK,T.BOLD,false)
		y+=59;rule(y,0,342);y+=16
	if w.smithy_source_fx.has("forge_fx"):
		var fx=w.smithy_source_fx.forge_fx
		label(source_u("제련 성공!" if fx.get("success",fx.get("ok",false)) else "제련 실패. 장비는 그대로입니다."),Rect2(0,y,342,42),14,T.RED,T.BOLD,false);y+=54
	stage.custom_minimum_size.y=y

func smithy_effect(r: Dictionary,key: String,value: float,y: float) -> float:
	var rules=host.model.gear.note_rules;var def=rules.source.fx.base.get(key,rules.source.fx.affix.get(key,{}))
	var name=def.get("name",key)
	if key=="stat":name=rules.source.classes.filter(func(c):return c.id==r.item.cls)[0].line
	label(source_t(name),Rect2(0,y,235,25),12,T.INK,T.BOLD,false)
	label(("+" if value>=0 else "")+PanelNumbers.fnum(value)+def.get("unit",""),Rect2(244,y,98,25),13,T.RED,T.BOLD,false)
	return y+29

func smithy_result_card(code: String,level: int,y=0.0) -> float:
	var r=host.model.gear.note_rules.gear_roll(code,level)
	if r.is_empty():return y
	label(source_t(r.item.name),Rect2(0,y,342,29),18,T.INK,T.BOLD,false);y+=36
	label(source_t(host.model.Gear.RARITY[r.rarity])+" · Lv "+str(int(r.lv)),Rect2(0,y,342,25),12,T.INK,T.BOLD,false);y+=34
	if not r.item.base.is_empty():
		label(source_u("기본 효과"),Rect2(0,y,342,25),14,T.INK,T.BOLD,false);y+=29
		for key in FX_ORDER:
			if r.item.base.has(key):y=smithy_effect(r,key,r.fx.get(key,r.item.base[key]),y)
	if not r.affix.is_empty():
		label(source_u("무작위 옵션"),Rect2(0,y,342,25),14,T.INK,T.BOLD,false);y+=29
		for a in r.affix:y=smithy_effect(r,a[0],a[1],y)
	if r.has("unique"):
		label(source_u("고유 효과"),Rect2(0,y,342,25),14,T.INK,T.BOLD,false);y+=29
		label(source_t(r.unique.name),Rect2(0,y,342,26),14,T.RED,T.BOLD,false);y+=31
		var text=source_t(r.unique.text)
		var height=maxf(60,ceil(text.length()/28.0)*21)
		paragraph(text,Rect2(0,y,342,height),12,T.INK,false);y+=height+10
	return y

func smithy_process() -> void:
	var w=host.model;var level=w.highest_level();var band=w.gear.band(level);var y=0.0
	paragraph(source_u("금화를 내면 대장간이 쇳덩이를 가공해 장비 한 점을 내어 준다. 어떤 장비가 나올지는 누르기 전에 이미 정해져 있어서, 되돌리거나 다시 불러와도 같은 차례에는 같은 장비가 나온다."),Rect2(0,y,342,132),13,T.INK,false);y+=144
	for text in [source_u("기준 Lv {lv}",{"lv":level}),source_u("가공 1회 금화 {n}",{"n":band.price}),source_u("지금까지 {n}회",{"n":w.s.commerce_r21.process_n})]:
		label(text,Rect2(0,y,342,25),14,T.INK,T.BOLD,false);y+=31
	label(source_u("등급별 확률"),Rect2(0,y,342,26),18,T.INK,T.BOLD,false);y+=35
	for rarity in w.gear.ORDER:
		label(source_t(w.Gear.RARITY[rarity]),Rect2(0,y,175,23),13,T.INK,T.BOLD,false)
		label(w.gear.pct(band.w.get(rarity,0))+"%",Rect2(220,y,122,23),13,T.RED,T.BOLD,false);y+=29
	paragraph(source_u("Lv {from}~{to} 구간 · 확률은 바뀔 수 있습니다.",{"from":band.from,"to":band.to}),Rect2(0,y,342,44),11,T.INK,false);y+=50
	paragraph(source_u("출전할 수 있는 동료 가운데 가장 높은 레벨이 기준이고, 나오는 장비는 지금 모험가들의 직업에서 정해진다."),Rect2(0,y,342,66),12,T.INK,false);y+=76
	var short=band.price-w.s.gold
	action("process_gear",source_u("장비 가공"),Rect2(0,y,165,42),func():host._act(w.smithy_action.bind("proc"),""),true,short>0,false)
	label(source_u("금화 {n} 모자란다",{"n":short}) if short>0 else source_u("금화 {n}",{"n":band.price}),Rect2(178,y,164,42),12,T.INK,T.BOLD,false);y+=58
	var code=w.smithy_source_fx.get("proc_fx",{}).get("code","");var r=w.gear.note_rules.gear_roll(code,level)
	if not r.is_empty():
		label(source_t(r.item.name),Rect2(0,y,342,28),19,T.RED,T.BOLD,false);y+=36
		y=smithy_result_card(code,level,y)
	stage.custom_minimum_size.y=y

func recruit_cell(title: String,value: String,sub: String,r: Rect2) -> void:
	label(source_u(title),Rect2(r.position,Vector2(r.size.x,22)),12,T.INK,T.BOLD,false)
	label(value,Rect2(r.position+Vector2(0,25),Vector2(r.size.x,27)),17,T.RED,T.BOLD,false)
	if not sub.is_empty():paragraph(sub,Rect2(r.position+Vector2(0,55),Vector2(r.size.x,44)),11,T.INK,false)

func recruit_roster(y: float) -> float:
	var w=host.model;var total=w.config.companions.size();var left=total-w.s.owned.size()
	label(source_u("만난 동료"),Rect2(0,y,230,25),18,T.INK,T.BOLD,false)
	label("%d / %d"%[w.s.owned.size(),total],Rect2(244,y,98,25),14,T.INK,T.BOLD,false);y+=38
	if w.s.owned.is_empty():paragraph(source_u("아직 만난 동료가 없다."),Rect2(0,y,342,38),13,T.INK,false);y+=48
	for i in range(w.s.owned.size()-1,-1,-1):
		var id=w.s.owned[i];var p=w.person(id)
		picture(id,Rect2(0,y,48,59),"target-face")
		if w.s.town_r21.get("meet","")==id:fill("recruit_latest:"+id,Rect2(56,y,286,60),T.PALE)
		label(L.t(p.name,L.language(w.s)),Rect2(64,y,275,25),16,T.INK,T.BOLD,false)
		label(source_u("{cls}, Lv {lv}",{"cls":p["class"],"lv":w.s.members[id].level}),Rect2(64,y+29,275,24),12,T.INK,T.BOLD,false);y+=72
	var hint=source_u("아직 만나지 못한 {n}명은 도감에 흐리게 보인다.",{"n":left}) if left>0 else source_u("길드 장부의 모험가를 모두 만났다.")
	paragraph(hint,Rect2(0,y,342,48),12,T.INK,false);y+=54
	action("recruit_codex",source_u("도감에서 보기"),Rect2(0,y,342,42),host.go.bind("codex"),false,false,false)
	return y+54

func recruit_result(y: float,busy=false) -> float:
	var w=host.model;var id=w.s.town_r21.get("meet","")
	if id not in w.s.owned or not PanelNumbers.DATA.cast.has(id):return y
	var c=PanelNumbers.DATA.cast[id];var a=floor(w.s.members[id].aff)
	label(source_u("방금 이어진 사람" if busy else "가장 최근에 소개받은 사람"),Rect2(0,y,342,25),12,T.INK,T.BOLD,false);y+=32
	picture(id,Rect2(0,y,82,98),"target-face")
	label(source_t(c.full),Rect2(94,y,248,29),18,T.INK,T.BOLD,false);y+=40
	var race=source_u("{race}({lineage})",{"race":c.race,"lineage":c.lineage}) if not c.get("lineage","").is_empty() else source_t(c.race)
	for text in [race,source_t(c.nation),source_t(c.cls),source_t(c.row),source_u("무속성") if c.el=="none" else source_t(PanelNumbers.DATA.els.get(c.el,"무속성"))]:
		label(text,Rect2(94,y,248,23),12,T.INK,T.BOLD,false);y+=27
	label(source_u("호감 {stage} ({a} / {max})",{"stage":w.TOWN_RULES.guild_tier(a),"a":a,"max":200}),Rect2(0,y,342,25),13,T.RED,T.BOLD,false);y+=33
	fill("recruit_aff_track",Rect2(0,y,342,5),T.LINE);fill("recruit_aff_value",Rect2(0,y,342*maxf(0,a)/200,5),T.RED);y+=22
	for text in [source_u("개인 스킬"),source_u("액티브"),source_t(c.skill),source_u("개인 특성"),source_u("패시브"),source_t(c.trait)]:
		label(text,Rect2(0,y,342,25),13,T.INK,T.BOLD,false);y+=31
	return y+18

func recruit() -> void:
	header("연합 길드 본관","guild");npc_hero("fenella","동료\n소개","페넬라\n소개 창구",430);guild_tabs(1)
	var w=host.model;var cost=w.recruit_fee();var total=w.config.companions.size();var left=total-w.s.owned.size();var short=cost-w.s.gold
	var previous=stage;stage=scroll_page(503,196,600+w.s.owned.size()*72)
	recruit_cell("소개비",source_u("금화 {n}",{"n":cost}),source_u("한 명 늘 때마다 +20"),Rect2(0,0,114,106))
	recruit_cell("가진 금화",str(int(w.s.gold)),source_u("금화 {n} 모자라다",{"n":short}) if short>0 and left>0 else "",Rect2(122,0,106,106))
	recruit_cell("동료","%d / %d"%[w.s.owned.size(),total],"",Rect2(236,0,106,106))
	var next=source_u(" (이번 뒤에는 {cost})",{"cost":cost+20}) if left>0 else ""
	paragraph(source_u("소개비는 100 → 120 → 140 … 만난 사람이 늘수록 20씩 오른다{next}.",{"next":next}),Rect2(0,110,342,66),12,T.INK,false)
	paragraph(source_u("길드가 모험가에게 사람을 이어 준다. 누구를 만날지는 길드도 모른다. 아직 동료가 아닌 사람 가운데 한 명이 나오고, 만나면 곧 동료가 된다. 등급도 확률표도 없다."),Rect2(0,185,342,108),13,T.INK,false)
	var y=304
	y=recruit_result(y,not w.s.dialogue_r21.pending.is_empty())
	if left==0:paragraph(source_u("더 이을 사람이 없다. 길드 장부에 오른 모험가는 모두 당신의 동료다."),Rect2(0,y,342,65),13,T.INK,false);y+=77
	# The latest id and newest-first list use the existing saved town.meet field.
	y=recruit_roster(y);stage.custom_minimum_size.y=y;stage=previous
	if left>0:
		var busy=not w.s.dialogue_r21.pending.is_empty() or not w.s.dialogue_r21.response.is_empty()
		action("recruit",source_u("소개받기")+" · "+source_u("금화 {n}",{"n":cost}),Rect2(18,705,354,44),func():host._act(w.recruit,"");host.message=w.s.log[-1];host._draw_screen(),true,busy or short>0,false)
	feedback(752)

func guild_quest_card(q: Dictionary,accepted: bool,y: float) -> float:
	var w=host.model;var c=w.quest_contract(q);var lang=L.language(w.s)
	paragraph(w.GuildR22.title(c,lang),Rect2(0,y,342,49),18,T.INK,false);y+=56
	label("★".repeat(int(c.stars)),Rect2(0,y,342,24),13,T.RED,T.BOLD,false);y+=29
	paragraph(source_t(c.get("d","")),Rect2(0,y,342,55),12,T.INK,false);y+=61
	label(source_u("난이도 {difficulty}",{"difficulty":source_u(c.difficulty)}),Rect2(0,y,342,23),12,T.INK,T.BOLD,false);y+=26
	label(source_u(c.kind),Rect2(0,y,342,23),12,T.INK,T.BOLD,false);y+=26
	label(source_u({"core":"균열 핵 레이드","elite":"정예 전투","battle":"일반 전투"}[w.GuildR22.fight(c)]),Rect2(0,y,342,23),12,T.INK,T.BOLD,false);y+=26
	label(source_u("보상 금화 {gold}",{"gold":w.dungeon_rules.quest_gold(c,c.lv)}),Rect2(0,y,342,23),13,T.RED,T.BOLD,false);y+=26
	label(source_u("적 Lv {lv}",{"lv":c.lv}),Rect2(0,y,342,23),12,T.INK,T.BOLD,false);y+=26
	if c.has("strength"):
		label(source_u("적 강도 ×{n}",{"n":"%.1f"%c.strength}),Rect2(0,y,342,23),12,T.INK,T.BOLD,false);y+=26
		label(source_u("장비 1~2개 확정"),Rect2(0,y,342,23),12,T.INK,T.BOLD,false);y+=26
	if accepted:
		label(source_u("진행 중"),Rect2(0,y,164,42),13,T.RED,T.BOLD,false)
		action("quest_abandon",source_u("포기"),Rect2(178,y,164,42),func():host._act(w.abandon_quest,""),false,false,false)
	else:
		action("quest:"+str(int(q.id)),source_u("수락"),Rect2(0,y,166,42),func():host._act(w.accept_quest.bind(q.id),"의뢰를 수락했습니다."),true,false,false)
		action("quest_reject:"+str(int(q.id)),source_u("거절"),Rect2(178,y,164,42),func():host._act(w.reject_quest.bind(q.id),"의뢰 하나를 거절했다. 판에 새 의뢰가 걸렸다."),false,false,false)
	y+=55;rule(y,0,342);return y+14

func guild_board() -> void:
	var w=host.model;var y=0.0
	if w.s.board.is_empty():
		paragraph(source_u("의뢰판이 비어 있다."),Rect2(0,y,342,38),14,T.INK,false);y+=48
		action("fill_board",source_u("의뢰판 살펴보기"),Rect2(0,y,342,42),func():host._act(w.fill_source_board,""),false,false,false);y+=54
	else:
		for q in w.s.board:y=guild_quest_card(q,w.s.quest.get("id",-1)==q.id,y)
		action("refresh_board",source_u("의뢰판 새로 걸기"),Rect2(0,y,218,42),func():host._act(w.refresh_board,"의뢰판을 새로 걸었다."),true,false,false)
		label(source_u("금화 {n}",{"n":w.refresh_fee()}),Rect2(230,y,112,42),12,T.INK,T.BOLD,false);y+=54
		paragraph(source_u("받은 의뢰는 그대로 두고 나머지를 바꾼다"),Rect2(0,y,342,44),12,T.INK,false);y+=52
	stage.custom_minimum_size.y=y

func picture(id: String,r: Rect2,slot="bust") -> Control:
	return super(id,r,slot)

func equipment_people() -> Array:
	var ids=host.model.s.owned.duplicate()
	if host.model.s.get("persona",{}).get("cls","")!="":ids.push_front("persona")
	return ids

func equipment() -> void:
	var ids=equipment_people()
	if ids.is_empty():header("편성 · 장비");return
	if host.who not in ids:host.who=ids[0]
	super()

func member_choice(r: Rect2) -> void:
	if host.screen!="equipment":super(r);return
	var ids=equipment_people();var pick=OptionButton.new();stage.add_child(pick);pick.position=r.position;pick.size=r.size
	pick.fit_to_longest_item=false;pick.clip_text=true
	for id in ids:pick.add_item(localized(host.model.person(id).name+" · "+host.model.person(id)["class"]))
	pick.select(ids.find(host.who));pick.item_selected.connect(func(i):host.who=ids[i];host._draw_screen())
	host.controls.member_choice=pick

func build_page() -> void:
	if not host.model.has_method("facility_route"):super();return
	if not host.model.receipt.is_empty():page_background();receipt_page();return
	if host.screen=="facility_scroll":page_background();scroll_page_targets();return
	super()
	if not host.model.facility_message.is_empty():
		fill("facility_notice",Rect2(14,62,362,82),T.INK)
		paragraph(host.model.facility_message,Rect2(22,67,346,72),12,T.PAPER)

func shop() -> void:
	super()
	if not host.model.has_method("scroll_targets") or host.shop_tab=="gear":return
	var old=host.controls.get("shop_bag")
	if is_instance_valid(old):old.get_parent().remove_child(old);old.queue_free()
	action("shop_scroll","스크롤 사용 · 보유 %d"%host.model.s.items.level_scroll,Rect2(18,705,190,43),func():host.model.shop_action("scroll","shop");host._save();host.go("facility_scroll"),true,host.model.s.items.level_scroll<1)
	action("shop_bag","보유 장비",Rect2(220,705,152,43),host.go.bind("equipment"))

func inn() -> void:
	if not host.model.s.owned.is_empty():super();return
	header("아랫마을 여관");npc_hero("dorothea","여관","도로테아\n여관 주인",430)
	paragraph("함께할 동료가 아직 없다. 길드 본관의 동료 소개 창구에서 사람을 이어 받자.",Rect2(18,486,354,100),17)
	action("inn_recruit","동료 소개 창구",Rect2(18,705,354,44),host.go.bind("recruit"),true)

func shop_gear() -> void:
	if not host.model.has_method("shop_classes"):super();return
	var w=host.model;var classes=w.shop_classes()
	selected_class=w.shop_class()
	host.gear_filter=w.shop_selection().slot
	if selected_class not in classes:selected_class=classes[0]
	var pick=OptionButton.new();stage.add_child(pick);pick.position=Vector2(18,427);pick.size=Vector2(354,38);pick.fit_to_longest_item=false;pick.clip_text=true
	for cls in classes:
		var names=w.config.classes.filter(func(c):return c.id==cls)
		pick.add_item(names[0].name if names else cls)
	pick.select(classes.find(selected_class));pick.item_selected.connect(func(i):w.shop_action("cls_"+classes[i],"shop");host._save();host._draw_screen())
	host.controls.shop_class=pick
	for i in range(3):
		var slot=["weapon","armor","acc"][i]
		action("shop_slot:"+slot,w.Gear.SLOT[slot],Rect2(18+i*118,471,118,38),func():w.shop_action("slot_"+slot,"shop");host.gear_filter=slot;host._save();host._draw_screen(),host.gear_filter==slot)
	var rows=w.shop_stock(selected_class,host.gear_filter)
	var previous=stage;stage=scroll_page(521,175,maxi(130,rows.size()*118))
	for i in range(rows.size()):
		var row=rows[i];var item=w.gear.by_id[row.id];var y=i*118
		icon("sword" if host.gear_filter=="weapon" else "shield",Rect2(8,y+12,56,65))
		label(item.name,Rect2(78,y+3,260,25),15,T.INK,T.BOLD)
		paragraph(host._gear_caption(item),Rect2(78,y+31,260,32),11)
		var cost=w.price({"price":row.price});var sold=w.stock_sold(row.code)
		var original=w.source_shop_stock(selected_class,host.gear_filter);var source_index=original.map(func(v):return v.code).find(row.code)+1
		action("buygear:"+row.id,"품절" if sold else "구입 · 금화 %d"%cost,Rect2(78,y+68,260,39),func():host._act(w.shop_action.bind("gear_"+str(source_index),"shop"),"장비를 구입했습니다."),true,sold or w.s.gold<cost)
		rule(y+115,0,342)
	stage=previous;action("shop_bag","보유 장비 확인",Rect2(18,705,354,43),host.go.bind("equipment"))

func guild() -> void:
	if not host.model.has_method("reject_quest"):super();return
	header("연합 길드 본관");npc_hero("fenella","의뢰","페넬라\n길드 접수",430);guild_tabs(0)
	var w=host.model;var board=w.s.board
	var previous=stage;stage=scroll_page(503,245,board.size()*228);guild_board()
	stage=previous

func smithy() -> void:
	if not host.model.has_method("smithy_list"):super();return
	var w=host.model
	header("한나의 대장간");npc_hero("hanna","한나의\n대장간","",365)
	smithy_tabs()
	fill("smithy_body",Rect2(0,418,390,282),T.PAPER)
	var previous=stage
	if w.smithy_tab=="process":
		stage=scroll_page(431,267,90);smithy_process();stage=previous
	else:
		stage=scroll_page(431,254,90);smithy_forge()
		stage=previous
		if not w.smithy_work.is_empty():action("smithy_done","제련 및 가공 완료",Rect2(18,706,354,42),func():w.complete_smithy();host._draw_screen(),true)
		else:action("smith_equipment","장비 장착하기",Rect2(18,706,354,42),host.go.bind("equipment"))
	if w.smithy_tab=="process" and not w.smithy_work.is_empty():
		action("smithy_done","제련 및 가공 완료",Rect2(18,314,354,43),func():w.complete_smithy();host._draw_screen(),true)

func scroll_page_targets() -> void:
	header("레벨업 스크롤","shop")
	fill("scroll_title_rule",Rect2(18,65,54,4),T.RED)
	label("대상 한 명의 레벨 +1 · 최대 Lv.40",Rect2(18,82,354,29),17,T.INK,T.BOLD)
	label("보유 %d개"%host.model.s.items.level_scroll,Rect2(18,124,354,25),14,T.RED,T.BOLD)
	var w=host.model;var ids=w.scroll_targets();var previous=stage;stage=scroll_page(177,510,ids.size()*103)
	for i in range(ids.size()):
		var id=ids[i];var p=w.item_preview("level_scroll",id);var y=i*103
		label(w.person(id).name+(" · 페르소나" if id=="persona" else ""),Rect2(0,y,342,27),20,T.INK,T.BOLD)
		label("Lv.%d → %d · 경험치 초기화"%[p.before,p.after],Rect2(0,y+32,342,24),13)
		var use=action("scroll_target:"+id,"사용" if p.usable else "사용 불가",Rect2(208,y+56,134,39),func():
			w.shop_action("scroll","shop");host._act(w.shop_action.bind("target_"+id,"shop"),"레벨이 올랐습니다."),true,not p.usable)
		T.dress_button(use,p.usable);use.alignment=HORIZONTAL_ALIGNMENT_LEFT;T.row_arrow(use,p.usable)
		fill("scroll_row_rule:"+id,Rect2(0,y+100,342,3),T.INK)
	stage=previous;action("scroll_back","상회로",Rect2(18,712,354,44),host.go.bind("shop"));navigation()

func receipt_page() -> void:
	var w=host.model;var r=w.receipt;var shop_receipt=r.kind=="shop"
	fill("receipt_paper",Rect2(0,0,390,844),T.PAPER)
	display("거래 내역" if shop_receipt else "제련 및 가공 완료",Rect2(18,38,354,70),T.INK,32)
	label("피에트로 · 마렌토 상회" if shop_receipt else "한나 · 한나의 대장간",Rect2(18,121,354,30),17,T.INK,T.BOLD)
	var lines=[]
	if shop_receipt:
		var ids=r.items.keys();ids.sort()
		for id in ids:
			var name=w.item_def(id).get("name","")
			if name.is_empty():name=w.gear.by_id.get(id.split(".")[0],{}).get("name",id)
			lines.append(name+" ×%d"%r.items[id])
	else:
		for row in r.work:lines.append(row.name+(" · 가공" if row.kind=="process" else " · 제련 성공 +%d"%row.level if row.success else " · 제련 실패 +%d 유지"%row.level))
	var previous=stage;stage=scroll_page(188,427,maxi(90,lines.size()*65))
	for i in range(lines.size()):paragraph(lines[i],Rect2(0,i*65,342,58),16)
	stage=previous;label("남은 금화 %d"%r.gold,Rect2(18,649,354,29),17,T.RED,T.BOLD)
	action("receipt_done","확인",Rect2(18,715,354,49),func():w.acknowledge_receipt();host._draw_screen(),true)
