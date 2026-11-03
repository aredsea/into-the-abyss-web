extends "res://tests/ui_phase4_screens_r23_test.gd"
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-screens-oracle.json"));var s=Screen.new();s.size=Vector2(390,844);root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844);root.add_child(s);s.storage.path="user://ui-phase4-detail.json";s.motion_reduced=true
	for c in o.codex_detail:
		s.model=fixture();s.model.s.settings={"lang":c.lang};s.model.s.owned=[c.id];s.model.s.party=[];s.model.s.favs=[c.id];s.model.s.gear=[];s.model.s.members[c.id].level=40;s.model.s.members[c.id].aff=99.9
		for id in s.model.s.equipment:s.model.s.equipment[id]={}
		s.panels_r22=State.new(s.model);s.panels_r22.ui.sel=c.id;s.screen="codex";s._draw_screen();await settle()
		check(body_words(s)==c.expected.text,"P2534 "+c.lang+" "+c.id+" got="+body_words(s)+" expected="+c.expected.text);check(observation(s.town_view.body).bars==c.expected.bars,"P2534 bars "+c.id)
	FileAccess.open("res://../verification/parity-r23/ui-phase4/ui-detail-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));print("UI PHASE4 DETAIL CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
