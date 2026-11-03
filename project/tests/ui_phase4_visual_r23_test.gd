extends "res://tests/ui_phase4_native_r23_test.gd"
func run():
	folder="res://../verification/parity-r23/ui-phase4/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932)]:
		for lang in ["ko","en"]:
			root.content_scale_size=dim;root.size=dim;var s=Screen.new();root.add_child(s);s.size=dim;s.storage.path="user://ui-phase4-visual-"+lang+str(dim.x)+".json";s.motion_reduced=true;s.model=fixture();s.model.s.settings={"lang":lang,"diff":2,"chron":1};s.model.s.gear=[];s.panels_r22=State.new(s.model);s.panels_r22.ui.sel="naran";s.screen="codex";s._draw_screen();await settle()
			var icons=s.town_view.find_children("*","TextureRect",true,false).filter(func(n):return n.get_meta("source_trait","")=="naran")
			check(icons.size()==1 and icons[0].texture!=null,"source trait icon actually rendered")
			if not icons.is_empty():s.town_view.scroll.ensure_control_visible(icons[0]);await settle()
			await capture(s,"ui-trait-"+lang,dim)
			s.screen="settings";s.reset_r22=true;s._draw_screen();await settle();check(s.controls.has("p8_lang_ko") and s.controls.has("p8_diff_1") and s.controls.has("p8_reset_yes"),"source public controls remain available during reset confirmation")
			s.town_view.scroll.ensure_control_visible(s.controls.p8_reset_yes);await settle();await capture(s,"ui-reset-"+lang,dim)
			await click(s,"p8_diff_1");check(not s.reset_r22 and not s.controls.has("p8_reset_yes"),"source difficulty action closes reset confirmation")
			await click(s,"p8_cloud");check(s.screen=="cloud" and (s.controls.has("cloud_connect") or s.controls.has("cloud_load") or s.controls.has("cloud_keep_server")),"settings reaches the replacement cloud account actions")
			if lang=="en":
				s.model=fixture();s.model.s.settings={"lang":"en","diff":2,"chron":1};s.model.s.members.naran.aff=90;s.model.s.dialogue_r21.pending={"who":"naran","scene":s.model.dialogue.data("naran").inn[0].id,"day":s.model.s.day};s.who="naran";s.screen="inn";s._draw_screen();await settle()
				var labels=s.town_view.find_children("*","Label",true,false).filter(func(n):return n.text=="Deep bond · Affection 90")
				check(labels.size()==1 and labels[0].get_theme_font_size("font_size")<13,"translation fits authored width before the first settled frame")
				await capture(s,"ui-dialogue-fit-en",dim)
			root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/parity-r23/ui-phase4/ui-visual-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"));print("UI PHASE4 VISUAL CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
