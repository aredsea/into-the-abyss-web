extends "res://tests/ui_look_r24_test.gd"
func run():
	phase="before"
	for a in OS.get_cmdline_user_args():
		if a=="after":phase=a
	folder="res://../verification/look-r24/"+phase;DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var dims=[Vector2i(390,844),Vector2i(1280,800)] if phase=="before" else [Vector2i(360,780),Vector2i(390,664),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800),Vector2i(360,780)]
	for i in dims.size():
		var dim=dims[i];root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://look-r24-extra-%d-%d.json"%[OS.get_process_id(),i];root.add_child(s);s.model=ready_world();s.motion_reduced=phase=="after" and i==dims.size()-1
		s.model.s.owned=["hildegard","bargut","teiris","marceline"];s.model.s.party=s.model.s.owned.duplicate();s.who="teiris"
		await show(s,"member_details","member-details",dim)
		if phase=="before":
			s.research_edit=true;await show(s,"research","research-editor",dim);s.research_edit=false
			s.shop_tab="gear";await show(s,"shop","shop-gear",dim)
			await show(s,"facility_scroll","facility-scroll",dim)
			s.model.s.members.teiris.aff=25;s.screen="inn";s._draw_screen();await settle()
			if s.controls.has("inn:talk"):await tap(s,"inn:talk");await shot(s,"dialogue",dim)
			s.model=preload("res://game/town_world_r21.gd").new();s.model.depart_dungeon(1,117);s.model.s.dialogue_r21.queue=[];s.model.s.run.phase="battle"
			var b=s.model.ModernBattle.new(s.model.battle_data())
			for e in b.data.enemies:e.hp=0;e.gauge=0
			b.result="victory";s.model.record_battle(b.snapshot());s.screen="explore";s._draw_screen();await settle();s._process(.21);await shot(s,"battle-victory",dim)
			# A separate terminal snapshot keeps the normal result route intact.
			if is_instance_valid(s.battle):s.remove_child(s.battle);s.battle.queue_free();s.battle=null
			s.model=preload("res://game/town_world_r21.gd").new();s.model.depart_dungeon(1,117);s.model.s.dialogue_r21.queue=[];s.model.s.run.phase="battle"
			b=s.model.ModernBattle.new(s.model.battle_data())
			for e in b.data.allies:e.hp=0;e.gauge=0
			b.result="defeat";s.model.record_battle(b.snapshot());s._draw_screen();await settle();s._process(.21);await shot(s,"battle-defeat",dim)
		else:
			for label in s.find_children("*","Label",true,false):
				var need=label.get_theme_font("font").get_multiline_string_size(label.text,label.horizontal_alignment,label.size.x,label.get_theme_font_size("font_size"))
				check(need.x<=label.size.x+1 and need.y<=label.size.y+2,"detail glyph bounds "+label.text)
			s.cloud.account={"code":"ABCD-EFGH-JKMP","pin":"23456789AB","rev":1,"auto":false,"synced":true};s.cloud.first_credentials=true;await show(s,"cloud","cloud-credentials",dim)
			s.cloud.first_credentials=false;s.cloud.conflict={"rev":2,"summary":{"day":2,"level":2,"best":1,"gold":275,"companions":1}};await show(s,"cloud","cloud-conflict",dim)
			s.cloud.conflict={};s.cloud.rank={"n":3,"pct":34,"best":1,"top":2,"at":1793577600};await show(s,"rank","rank-record",dim)
			s.cloud_confirmation={"prompt":"서버 기록을 불러올까요? 이 기기 기록은 백업에 남습니다.","callback":func():pass};await show(s,"cloud","cloud-confirm",dim)
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/look-r24/"+phase+"-extras-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("LOOK EXTRAS ",phase," CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
