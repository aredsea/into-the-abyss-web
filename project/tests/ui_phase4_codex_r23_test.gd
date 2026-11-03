extends "res://tests/ui_phase4_screens_r23_test.gd"
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-screens-oracle.json"));var s=Screen.new();s.size=Vector2(390,844);root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844);root.add_child(s);s.storage.path="user://ui-phase4-codex.json";s.motion_reduced=true
	for c in o.codex:
		s.model=fixture();s.model.s.settings={"lang":c.lang};s.model.s.owned=c.g.roster.duplicate();s.model.s.party=[];s.model.s.favs=c.g.favs.duplicate();s.model.s.persona.lv=1;s.model.s.members.persona.level=1
		for id in s.model.s.owned:s.model.s.members[id].level=1;s.model.s.members[id].aff=c.g.aff.get(id,0)
		s.panels_r22=State.new(s.model);s.panels_r22.ui.tab=c.g.ui.tab;s.panels_r22.ui.page=int(c.g.ui.page);s.screen="codex";s._draw_screen();await settle()
		var got=L.u("캐릭터 도감",{},c.lang)+" "+body_words(s);check(got==c.expected.text,"P2523 "+c.lang+" "+str(c.g.roster.size())+" "+c.g.ui.tab+" "+str(c.g.ui.page)+" got="+got+" expected="+c.expected.text)
		var observed=observation(s.town_view.body);check(observed.bars==c.expected.bars,"P2523 list bars")
	FileAccess.open("res://../verification/parity-r23/ui-phase4/ui-codex-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));print("UI PHASE4 CODEX CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
