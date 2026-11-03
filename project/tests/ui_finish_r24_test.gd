extends "res://tests/ui_look_r24_test.gd"
var strings24=[]
func collect24(s,tag,lang):
	await settle()
	for n in s.find_children("*","Control",true,false):
		if n is Label or n is Button or n is RichTextLabel:
			if n.text!="":strings24.append({"screen":tag,"lang":lang,"kind":n.get_class(),"text":n.text})
		if n is OptionButton:
			for i in n.item_count:strings24.append({"screen":tag,"lang":lang,"kind":"option","text":n.get_item_text(i)})
		if n is LineEdit and n.placeholder_text!="":strings24.append({"screen":tag,"lang":lang,"kind":"input_hint","text":n.placeholder_text})
		if n.tooltip_text!="":strings24.append({"screen":tag,"lang":lang,"kind":"tooltip","text":n.tooltip_text})
func run():
	folder="res://../verification/finish-r24/after";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(390,844),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://finish-r24-%d-%d.json"%[OS.get_process_id(),dim.x];root.add_child(s)
		for lang in ["ko","en"]:
			s.cloud.account={"code":"","pin":"","rev":0,"auto":false,"synced":false};s.cloud.remote={};s.cloud.conflict={};s.cloud.revisions=[];s.cloud.rank={};s.cloud.first_credentials=false;s.cloud.notice="클라우드에 연결하면 다른 기기에서도 이어할 수 있습니다."
			s.model=W24.new();s.model.s.settings.lang=lang;s.model.seed_source=func():return 4242
			for page in range(1,6):
				if page>=2:s.model.create_action("race_human")
				if page>=3:s.model.create_action("nat_border")
				if page>=4:s.model.create_action("cls_warrior")
				if page>=5:s.model.create_action("auto")
				s.model.s.ui.page=page;s._draw_screen();await collect24(s,"create-"+str(page),lang)
				await shot(s,"create-"+str(page)+("-en" if lang=="en" else ""),dim)
			s.model.create_action("done");s._draw_screen();await collect24(s,"scenario-empty",lang)
			s.model.create_action("pick_teiris","sc");s._draw_screen();await collect24(s,"scenario-selected",lang)
			s.model.create_action("go","sc");s.model.s.dialogue_r21.queue=[]
			s.model.s.owned=["hildegard","bargut","teiris","marceline"];s.model.s.party=s.model.s.owned.duplicate();s.who="teiris"
			s.model.s.items.level_scroll=2;s.model.s.chronicle_r22={"list":["Day 1: First met Teiris, who joined as a companion.","Day 2: Leveled up: {{user}} Lv 1 → 2,Teiris Lv 1 → 2"],"queue":[]}
			for page in ["town","party","member","member_details","skills","settings","codex","status","inventory","places","people","journal","guild","recruit","research","shop","inn","smithy","equipment","bag","depart","formation","cards","cloud","rank","facility_scroll"]:
				s.screen=page;s._draw_screen();await collect24(s,page,lang)
				if page in ["journal","facility_scroll"] and lang=="ko":await shot(s,page,dim)
				if lang=="en":await shot(s,page+"-en",dim)
			s.cloud.account={"code":"ABCD-EFGH-JKMP","pin":"23456789AB","rev":1,"auto":false,"synced":true};s.cloud.first_credentials=true
			s.screen="cloud";s._draw_screen();await collect24(s,"cloud-credentials",lang)
			s.cloud.first_credentials=false;s.cloud.conflict={"rev":2,"summary":{"day":2,"level":2,"best":1,"gold":275,"companions":1}};s._draw_screen();await collect24(s,"cloud-conflict",lang)
			s.cloud.conflict={};s.cloud.rank={"n":3,"pct":34,"best":1,"top":2,"at":1793577600};s.screen="rank";s._draw_screen();await collect24(s,"rank-record",lang)
			# All companion details, public places and biographies, both settings.
			for id in s.model.config.companions.map(func(c):return c.id):
				s.panels_r22.ui.sel=id;s.screen="codex";s._draw_screen();await collect24(s,"codex-"+id,lang)
			for pid in s.model.Places.DATA.order:
				s.journal_r22.place=pid;s.screen="places";s._draw_screen();await collect24(s,"place-"+pid,lang)
			for id in s.model.Places.DATA.profiles:
				s.journal_r22.person=id;s.screen="people";s._draw_screen();await collect24(s,"person-"+id,lang)
			s.model=ready_world();s.model.s.settings.lang=lang;s.model.depart_dungeon(1,117);s.model.s.dialogue_r21.queue=[]
			for page in ["explore","expedition_log","expedition_items","expedition_equipment"]:
				s.screen=page;s._draw_screen();await collect24(s,page,lang)
			s.model.s.run.phase="rest";s.screen="explore";s._draw_screen();await collect24(s,"explore-rest",lang)
		root.remove_child(s);s.queue_free();await settle()
	var macros=[];var re=RegEx.new();re.compile("\\{\\{[^}]+\\}\\}")
	for row in strings24:
		if re.search(row.text):macros.append(row)
	check(macros.is_empty(),"all rendered screens resolve host placeholders")
	FileAccess.open("res://../verification/finish-r24/screen-strings.json",FileAccess.WRITE).store_string(JSON.stringify(strings24))
	FileAccess.open("res://../verification/finish-r24/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"strings":strings24.size(),"placeholder_defects":macros},"\t"))
	print("UI FINISH R24 CHECKS ",checks," FAILURES ",failures.size()," STRINGS ",strings24.size());quit(0 if failures.is_empty() else 1)
