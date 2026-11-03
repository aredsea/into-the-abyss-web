extends "res://tests/ui_facilities_r22_test.gd"
var observations=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		failures.append(msg)
		if failures.size()<=12:push_error(msg)
func texts(view) -> Array:
	# Native text and button labels are separate Controls. Walk tree insertion
	# order, which follows the displayed source-card sequence including sublabels.
	var out=[]
	for child in view.stage.get_children():
		if (child is Label or child is Button) and not child.text.is_empty():out.append(child.text)
	return out
func equal_texts(view,expected,tag):
	var actual=texts(view);observations.append({"tag":tag,"actual":actual,"expected":expected})
	check(actual==expected,"source visible text/order "+tag)
func clean(s):
	for c in s.town_view.stage.get_children():c.free()
	s.town_view.metrics=[];s.controls={}
func equal_buttons(s,expected,tag):
	var actual=s.controls.values().filter(func(b):return b is Button)
	check(actual.size()==expected.size(),"source button count "+tag)
	for i in range(mini(actual.size(),expected.size())):
		check(actual[i].text==expected[i].texts[0],"source button label/order "+tag+str(i))
		check(actual[i].disabled==expected[i].disabled,"source button availability "+tag+str(i))
func run():
	folder="res://../verification/parity-r23/gear-render-round4";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/gear-round4-semantics.json"))
	root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844)
	var s=Screen.new();s.size=Vector2i(390,844);s.storage.path="user://gear-r4-ui.json";root.add_child(s);s.model=ready_world();s.motion_reduced=true;s.go("guild");await process_frame
	check(s.town_view.has_method("recruit_cell"),"native recruit_cell exists")
	check(s.town_view.has_method("recruit_roster"),"native recruit_roster exists")
	check(s.town_view.has_method("guild_quest_card"),"native guild_quest_card exists")
	for f in o.tabs:
		s.model.s.settings={"lang":f.lang};clean(s)
		if f.scene=="guild":
			var selected=["board","recruit","loredana"].find(f.tab if f.tab!="" else "board")
			s.town_view.guild_tabs(selected)
			for i in range(3):
				var button=s.controls["guild:"+["guild","recruit","research"][i]]
				check(button.text==f.buttons[i].label,"guild tab source translation "+f.tab+f.lang+str(i))
				check(button.get_meta("source_selected",false)==f.buttons[i].selected,"guild tab selected "+f.tab+str(i))
		else:
			s.model.smithy_tab="process" if f.tab=="process" else "forge"
			if not s.town_view.has_method("smithy_tabs"):check(false,"native smithy_tabs exists");continue
			s.town_view.smithy_tabs()
			for i in range(2):
				var button=s.controls["sm_tab:"+["forge","process"][i]]
				check(button.text==f.buttons[i].label,"smithy tab source translation "+f.tab+f.lang+str(i))
				check(button.get_meta("source_selected",false)==f.buttons[i].selected,"smithy selected "+f.tab+str(i))
	if s.town_view.has_method("recruit_cell"):
		for f in o.cells:
			s.model.s.settings.lang=f.lang;clean(s)
			s.town_view.recruit_cell(f.label,f.value,f.sub if f.sub is String else "",Rect2(0,0,342,100))
			equal_texts(s.town_view,f.visible_texts,"cell:"+f.lang+f.label+str(f.sub))
	if s.town_view.has_method("recruit_roster"):
		for f in o.rosters:
			s.model.s.settings.lang=f.lang;s.model.s.owned=f.ids.duplicate();s.model.s.town_r21.meet=f.get("last","");clean(s)
			for id in f.ids:s.model.s.members[id].level=40
			s.town_view.recruit_roster(0)
			equal_texts(s.town_view,f.visible_texts,"roster:"+f.lang+str(f.ids.size()))
			check(s.controls.has("recruit_codex") and s.controls.recruit_codex.text==f.visible_buttons[0].texts[0],"codex button")
	if s.town_view.has_method("guild_quest_card"):
		for f in o.quests:
			s.model.s.settings.lang=f.lang;s.model.s.town_r21.seed=f.game.seed;clean(s)
			var q=f.quest.duplicate(true);q.source_id=q.id;q.id=int(q.id.trim_prefix("q"));q.name=q.title
			s.model.s.quest=q.duplicate(true) if f.active else {}
			s.town_view.guild_quest_card(q,f.active,0)
			equal_texts(s.town_view,f.visible_texts,"quest:"+f.lang+str(f.game.seed)+str(q.id)+str(f.active))
			equal_buttons(s,f.visible_buttons,"quest:"+str(q.id)+f.lang+str(f.active))
	check(s.town_view.has_method("smithy_forge"),"native smithy_forge exists")
	if s.town_view.has_method("smithy_forge"):
		for f in o.forges:
			s.model=ready_world();s.model.s.settings={"lang":f.lang};s.model.s.gear=[];s.model.s.serial=0;s.model.s.gold=f.game.gold
			s.model.bank_expedition_gear(f.bag)
			for e in s.model.s.gear:
				var code=s.model.gear.code(e);e.forge=f.game.forge.get(code,{}).get("lv",0)
			if f.mode==5:
				s.model.bank_expedition_gear(["wa01.3.1"]);s.model.s.equipment.persona.weapon=s.model.s.serial
			s.model.smithy_source_fx={"forge_fx":f.game.forge_fx} if f.game.has("forge_fx") else {}
			clean(s);s.town_view.smithy_forge();equal_texts(s.town_view,f.visible_texts,"forge:"+f.lang+str(f.mode))
			equal_buttons(s,f.visible_buttons,"forge:"+f.lang+str(f.mode))
	check(s.town_view.has_method("smithy_process"),"native smithy_process exists")
	if s.town_view.has_method("smithy_process"):
		for f in o.processes:
			s.model=ready_world();s.model.s.settings={"lang":f.lang};s.model.s.gold=f.gold;s.model.s.commerce_r21.process_n=7
			s.model.s.persona.lv=f.level;s.model.s.members.persona.level=f.level
			for id in s.model.s.owned:s.model.s.members[id].level=f.level
			s.model.smithy_source_fx={"proc_fx":{"code":f.code}} if not f.code.is_empty() else {}
			clean(s);s.town_view.smithy_process();equal_texts(s.town_view,f.visible_texts,"process:"+f.lang+str(f.level)+str(f.gold)+f.code)
			equal_buttons(s,f.visible_buttons,"process:"+f.lang+str(f.level)+f.code)
	if s.town_view.has_method("smithy_result_card"):
		for f in o.cards:
			s.model.s.settings.lang=f.lang;clean(s);s.town_view.smithy_result_card(f.code,40)
			equal_texts(s.town_view,f.visible_texts,"card:"+f.lang+f.code)
	if s.town_view.has_method("guild_board"):
		for f in o.boards:
			s.model=ready_world();s.model.s.settings={"lang":f.lang};s.model.s.gold=f.game.gold;s.model.s.refreshes=f.game.town.rr;s.model.s.quest={}
			s.model.s.board=f.game.guild.quests.map(func(q):var row=q.duplicate(true);row.source_id=q.id;row.id=int(q.id.trim_prefix("q"));row.name=q.title;return row)
			if not f.game.guild.active.is_empty():s.model.s.quest=s.model.s.board.filter(func(q):return q.source_id==f.game.guild.active)[0].duplicate(true)
			clean(s);s.town_view.guild_board();equal_texts(s.town_view,f.visible_texts,"board:"+f.lang+str(f.mode));equal_buttons(s,f.visible_buttons,"board:"+f.lang+str(f.mode))
	if s.town_view.has_method("recruit_result"):
		for f in o.recruit_results:
			s.model=ready_world();s.model.s.settings={"lang":f.lang};s.model.s.owned=s.model.config.companions.map(func(p):return p.id)
			s.model.s.town_r21.meet=f.cid
			if s.model.s.members.has(f.cid):s.model.s.members[f.cid].aff=99.5
			clean(s);s.town_view.recruit_result(0,f.busy)
			# Only the final AI/chat continuation instruction is host-only.
			var expected=f.visible_texts.slice(0,-1) if not f.visible_texts.is_empty() else []
			equal_texts(s.town_view,expected,"recruit_result:"+f.lang+f.cid+str(f.busy))
	# Capture the actual composed screens, including their real callbacks.
	for dim in [Vector2i(360,780),Vector2i(390,844)]:
		root.content_scale_size=dim;root.size=dim;s.size=dim;s.model=ready_world();s.model.s.gold=100000
		s.go("guild");await capture(s,"guild",dim)
		s.go("recruit");await capture(s,"recruit",dim)
		if s.controls.has("recruit"):
			await click(s,"recruit");check(s.model.s.owned.size()==2,"real recruit callback")
			await capture(s,"recruit-result",dim)
		if s.controls.has("recruit_codex"):await click(s,"recruit_codex");check(s.screen=="codex","codex navigation")
		s.model.s.dialogue_r21.queue=[];s.go("smithy");await capture(s,"smithy",dim)
		await click(s,"sm_tab:process");await capture(s,"smithy-process",dim)
		await click(s,"process_gear");check(s.model.s.commerce_r21.process_n==1,"source process button applies one confirmed result")
		await capture(s,"smithy-process-result",dim)
	s.queue_free();await process_frame
	FileAccess.open("res://../verification/parity-r23/gear-round4-ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"captures":captures},"  "))
	print("GEAR R23 ROUND4 UI CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
