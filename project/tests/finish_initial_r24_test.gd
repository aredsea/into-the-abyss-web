extends "res://tests/finish_r24_test.gd"
const Current=preload("res://game/settings_world_r22.gd")
func observe_initial(w):
	var s=w.s;var p=s.persona.duplicate(true)
	# Empty, lazy source maps and native explicit zero defaults have the same
	# observable inventory/ownership; unowned preallocated records are invisible.
	for key in ["lineage","bonus"]:p.erase(key)
	var items={}
	for key in s.items:
		if s.items[key]!=0:items[key]=s.items[key]
	var ui=s.ui.duplicate(true);ui.panel="";ui.tab=""
	return {"scene":s.scene,"ui":ui,"persona":p,"roster":s.owned,"aff":{},"favs":s.get("favs",[]),"equip":{},"forge":s.commerce_r21.get("forge_codes_r22",{}),"shop_stock":{"day":0,"bought":s.commerce_r21.bought},"party":s.party,"gold":s.gold,"items":items,"lv":s.persona.lv,"lvl":{},"exp":{},"guild":{"quests":s.board,"active":"" if s.quest.is_empty() else str(s.quest.id),"done":s.quest_wins,"recruits":s.recruits,"tickets":0},"settings":{"diff":s.settings.diff},"scenario":s.scenario,"seed":s.town_r21.seed,"n":s.town_r21.counter,"dungeon":{"best":s.dungeon_r21.best,"cleared_bosses":s.dungeon_r21.cleared_bosses,"runs":s.dungeon_r21.runs,"sel":s.dungeon_r21.sel,"mode":w.sortie_mode(),"pg":s.dungeon_r21.get("pg",1)},"town":{"bn":s.runs,"day":s.day,"acts":s.acts,"rr":s.refreshes,"meet":s.town_r21.get("meet","")},"place":s.get("place",""),"npcs":s.npc_aff_r21}
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round3/oracle.json")).initial
	# RisuAI chat requests/position tracking and excluded adult features have no
	# native user operation. All remaining G_new fields are compared together.
	for key in ["v","pending","lore_mv","sexlog","nmark"]:source.erase(key)
	source.settings.erase("nsfw")
	# Lua's JSON encoder writes empty maps as []; normalize only map fields,
	# retaining ordered roster/party/quest/boss arrays as arrays.
	for key in ["aff","equip","exp","forge","items","lvl","npcs"]:
		if source[key] is Array and source[key].is_empty():source[key]={}
	for pair in [[source.persona,"stats"],[source.persona.skill,"prefix_lv"],[source.persona.skill,"suffix_lv"],[source.shop_stock,"bought"],[source.town,"acts"]]:
		if pair[0][pair[1]] is Array and pair[0][pair[1]].is_empty():pair[0][pair[1]]={}
	var w=Current.new();var actual=observe_initial(w)
	check(same(actual,source),"P0017 entire initial gameplay projection")
	for key in source:eqcheck("P0017.field."+key,actual.get(key),source[key])
	var resumed=Current.new();check(resumed.restore(JSON.parse_string(JSON.stringify(w.s))),"empty initial save resumes")
	eqcheck("P0017.resume",observe_initial(resumed),actual)
	var untouched=Current.new();w.s.gold=12
	eqcheck("P0017.independent",untouched.s.gold,source.gold)
	var store=preload("res://game/settings_save_r22.gd").new("user://finish-r24-initial-reset-%d.json"%OS.get_process_id())
	w=Current.new();w.s.gold=123
	check(store.write(w.s)==OK,"before-reset real disk save")
	var previous=w.s.duplicate(true)
	var reset=store.reset_world(w)
	check(reset!=null,"reset creates a fresh world")
	if reset!=null:eqcheck("P2637.reset.initial",observe_initial(reset),source)
	check(w.s==previous,"reset retains the caller's previous adventure")
	var archive=JSON.parse_string(FileAccess.get_file_as_string(store.archive_path))
	eqcheck("P2637.reset.archive",archive,JSON.parse_string(JSON.stringify(previous)))
	FileAccess.open("res://../verification/finish-r24/round3/initial-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts,"actual":actual,"expected":source}))
	print("FINISH INITIAL R24 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
