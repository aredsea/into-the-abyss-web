extends "res://tests/finish_r24_test.gd"
func _initialize():create_timer(120).timeout.connect(func():quit(98));call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round4/shop-oracle.json"));var differences=[]
	for f in oracle.rows:
		var w=ready_world();w.s.settings={"lang":f.lang};w.s.gold=f.before.gold;w.s.day=f.before.town.day;w.s.ui.sel="";w.s.ui.msg=f.before.ui.msg;w.facility=f.before.scene;w.s.town_r21.seed=f.before.seed
		set_level(w,"persona",int(f.before.persona.lv));set_level(w,"teiris",int(f.before.lvl.teiris))
		for id in w.s.items:w.s.items[id]=0
		w.s.items.level_scroll=f.before.items.level_scroll;w.s.npc_aff_r21.pietro=f.before.npcs.pietro.aff;w.s.commerce_r21.pietro_buys=0
		if f.before.ui.sel=="level_scroll":w.shop_action("scroll","shop")
		w.shop_action(f.arg,f.before.scene)
		var items={}
		for id in w.s.items:
			if w.s.items[id]!=0:items[w.source_item_id(id)]=w.s.items[id]
		var bought=w.s.commerce_r21.bought if w.s.commerce_r21.sold_day==w.s.day else {}
		var got={}
		for id in w.shop_got:got[w.source_item_id(id)]=w.shop_got[id]
		var actual={"scene":w.facility,"selection":w.shop_selection(),"msg":w.s.ui.msg,"gold":w.s.gold,"items":items,"persona_lv":w.s.persona.lv,"persona_xp":w.s.persona.exp,"member_lv":w.s.members.teiris.level,"member_xp":w.s.members.teiris.xp,"npc_aff":w.s.npc_aff_r21.pietro,"buys":w.s.commerce_r21.pietro_buys,"got":got,"bought":bought,"bag":source_bag(w)}
		var expected=f.after.duplicate(true)
		for key in ["items","got","bought"]:
			if expected[key] is Array:expected[key]={}
		if not same(actual,expected):differences.append({"arg":f.arg,"lang":f.lang,"actual":actual,"expected":expected})
		eqcheck("shop/route",actual,expected)
		if f.arg in ["cls_sanctioned","slot_acc","scroll"] and f.before.scene=="shop":
			var copy=World.new();check(copy.restore(JSON.parse_string(JSON.stringify(w.s))),"shop selection real JSON resume")
			eqcheck("shop/selection_resume",copy.shop_selection(),w.shop_selection())
	FileAccess.open("res://../verification/finish-r24/round4/shop-routes-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts,"differences":differences}))
	print("FINISH SHOP ROUTES CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
