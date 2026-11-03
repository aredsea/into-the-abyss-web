extends "res://tests/ui_phase4_screens_r23_test.gd"
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-screens-oracle.json"));var s=Screen.new();s.size=Vector2(390,844);root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844);root.add_child(s);s.storage.path="user://ui-phase4-status.json";s.motion_reduced=true
	for c in o.status:
		s.model=fixture();s.model.s.settings={"lang":c.lang};s.model.s.owned=c.g.roster.duplicate();s.model.s.favs=c.g.favs.duplicate();s.model.s.party=c.g.party.duplicate();s.model.s.persona=c.g.persona.duplicate(true);s.model.s.members.persona.level=1
		for id in s.model.s.owned:s.model.s.members[id].level=1;s.model.s.members[id].aff=c.g.aff.get(id,0)
		s.panels_r22=State.new(s.model);s.screen="status";s._draw_screen();await settle()
		var got=body_words(s);check(got==c.expected.text,"P2565 "+c.lang+" "+c.g.persona.cls+" got="+got+" expected="+c.expected.text)
		check(observation(s.town_view.body).bars==c.expected.bars,"P2565 bars")
	FileAccess.open("res://../verification/parity-r23/ui-phase4/ui-status-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));print("UI PHASE4 STATUS CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
