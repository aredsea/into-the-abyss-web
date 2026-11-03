extends "res://tests/ui_expedition_r22_test.gd"
const Oracle=preload("res://tests/expe_pass6_r23_test.gd")
var oracle=Oracle.new()
var observations=[]
func assert_rendered(s) -> void:
	for node in s.town_view.find_children("*","Control",true,false):
		if node is Label:
			var font=node.get_theme_font("font");var fs=node.get_theme_font_size("font_size")
			if node.autowrap_mode!=TextServer.AUTOWRAP_OFF:
				check(font.get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,node.size.x,fs).y<=node.size.y+2,"wrapped height "+node.text)
func record(s,kind: String,extra: Dictionary={}) -> void:
	var controls=s.controls.duplicate()
	var before=s.town_view.stage.get_child_count()
	var view=s.model.source_preparation_view(kind,extra)
	# Paint through the real product renderer; do not compare an unpainted DTO.
	var previous=s.town_view.stage
	var page=s.town_view.scroll_page(485,243,243);s.town_view.stage=page
	var y=s.town_view.preparation_entries(view,0);page.custom_minimum_size.y=maxf(243,y+12);s.town_view.stage=previous
	var painted=[]
	for node in page.get_children():
		if not node.has_meta("expe6_entry"):continue
		var e=node.get_meta("expe6_entry");check(node.text==e.text,"real entry text "+kind)
		if node is Button:check(node.disabled==not e.enabled,"real entry enabled "+kind)
		painted.append(e)
	check(oracle.helper.same(painted,view),"painted section order "+kind)
	var w=s.model;var g={"persona":w.s.persona.duplicate(true),"party":w.s.party.duplicate(),"roster":w.s.owned.duplicate(),"lvl":{},"exp":{},"aff":{},"ui":w.s.ui.duplicate(true),"dungeon":w.s.dungeon_r21.duplicate(true),"guild":{"active":"","quests":[]}}
	for id in w.s.owned:g.lvl[id]=w.s.members[id].level;g.exp[id]=w.s.members[id].xp;g.aff[id]=w.s.members[id].aff
	observations.append({"kind":kind,"lang":Llang(w),"G":g,"extra":extra,"visible":oracle.project(painted)})
	page.get_parent().queue_free()
	s.controls=controls
func Llang(w) -> String:return w.ExpeditionText.language(w.s)
func run():
	folder="res://../verification/parity-r23/expe-pass6-render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844)]:
		root.content_scale_size=dim;root.size=dim
		for lang in ["ko","en"]:
			var s=Screen.new();s.size=dim;s.storage.path="user://expe-pass6-%s-%d-%d.json"%[lang,dim.x,OS.get_process_id()];root.add_child(s);s.model=oracle.helper.setup();s.motion_reduced=true
			var w=s.model;w.s.settings={"lang":lang};w.s.persona.name="가온";w.s.members.persona.level=w.s.persona.lv;w.s.members.persona.xp=w.s.persona.exp
			await show(s,"depart");assert_rendered(s);await capture(s,"slots-"+lang,dim)
			for kind in ["slots","fight","dungeon_card"]:record(s,kind)
			for text in ["","A&B quotes","출전 인원"]:
				record(s,"heading",{"icon":"pl-guild","text":text});record(s,"hint",{"text":text})
			record(s,"place",{"place":{"scene":"guild","ic":"pl-guild","name":"연합 길드 본관","d":"의뢰판과 동료 소개 창구"}})
			await process_frame;await process_frame
			await click(s,"so_rm_persona");check(w.s.persona.fight==0,"persona slot selects command mode")
			check(w.s.party==["lynette"],"removing persona preserves companion order")
			await click(s,"so_mode_0");check(w.sortie_mode()==0 and s.controls.start_run.disabled,"empty quest mode refuses departure")
			var q=w.Guild.quest(123,1,7,15,[]);q.id=7;w.s.quest=q;w.s.board=[q]
			await show(s,"depart");assert_rendered(s);await capture(s,"quest-"+lang,dim);record(s,"quest",{"q":q});await process_frame;await process_frame
			check(not s.controls.start_run.disabled,"accepted quest allows departure")
			var clone=ready_world();var save=w.s.duplicate(true);check(clone.restore(save),"quest mode and original save resume")
			FileAccess.open("res://../verification/parity-r23/expe-pass6-ui-save-"+lang+".json",FileAccess.WRITE).store_string(JSON.stringify(save,"  "))
			w.s.persona.fight=0;w.s.party=w.s.owned.duplicate();w.set_fight(1)
			check(w.s.party==["lynette","marceline","urda"] and not w.s.ui.msg.is_empty(),"fourth companion waits with original feedback")
			w.s.ui.msg="";w.set_sortie_mode(1);w.s.party=["lynette"]
			w.depart_dungeon(1,6);w.s.run.loot_items.hp_s=2;w.s.members.persona.hp=1
			await show(s,"explore");await click(s,"retreat");assert_rendered(s);await capture(s,"confirm-"+lang,dim)
			var entries=[]
			for node in s.town_view.find_children("*","Control",true,false):
				if node.has_meta("expe6_entry"):entries.append(node.get_meta("expe6_entry"))
			var expected=[]
			for section in ["head","last","party"]:expected.append_array(w.source_expedition_view(section))
			check(oracle.helper.same(entries,expected),"confirmation retains complete ordered floor and party")
			await click(s,"cancel");check(not w.s.run.ask,"cancel retains expedition")
			w.expedition_retreat("retreat");w.expedition_retreat("retreat_yes");s.confirm={}
			await show(s,"town");assert_rendered(s);await capture(s,"town-"+lang,dim)
			check(s.controls.has("tw_sortie") and s.controls.has("tw_dungeon"),"town quest and highest-floor controls")
			for p in ["guild","shop","inn","smithy"]:check(s.controls.has("tw_"+p),"full place button "+p)
			var detail=s.controls.tw_guild;var sc=detail.get_parent()
			while sc and not sc is ScrollContainer:sc=sc.get_parent()
			check(sc is ScrollContainer,"facility details share existing scroll region")
			if sc is ScrollContainer:sc.ensure_control_visible(detail);await process_frame;await process_frame
			await capture(s,"town-details-"+lang,dim)
			w.s.run={};w.depart_dungeon(1,7);w.s.run.phase="battle";w.s.run.final=true
			var battle=w.ModernBattle.new(w.battle_data())
			for unit in battle.data.allies:unit.hp=0;unit.gauge=0
			battle.result="defeat";w.record_battle(battle.snapshot());s._leave_battle();await process_frame;await process_frame
			check(s.screen=="town" and w.s.run.is_empty() and w.s.dungeon_r21.last.result=="defeat","battle defeat removes live run and routes town")
			assert_rendered(s);await capture(s,"defeat-home-"+lang,dim)
			var resumed=ready_world();check(resumed.restore(w.s.duplicate(true)) and resumed.expedition_defeat_home(),"defeat town resumes with summary preserved")
			s.queue_free();await process_frame;await process_frame
	FileAccess.open("res://../verification/parity-r23/expe-pass6-ui-observations.json",FileAccess.WRITE).store_string(JSON.stringify(observations,"  "))
	FileAccess.open("res://../verification/parity-r23/expe-pass6-ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("EXPE PASS6 UI CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size())
	oracle.helper.helper.free();oracle.helper.free();oracle.free();quit(0 if failures.is_empty() else 1)
