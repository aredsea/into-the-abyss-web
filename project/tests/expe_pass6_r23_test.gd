extends "res://tests/expe_pass5_r23_test.gd"
func setup_case(r):
	var w=helper.setup();var g=r.G
	w.s.settings={"lang":r.lang};w.s.persona=g.persona.duplicate(true);w.s.party=g.party.duplicate();w.s.owned=g.roster.duplicate();w.s.ui=g.ui.duplicate(true)
	w.s.dungeon_r21=g.dungeon.duplicate(true);w.selected_floor=int(g.dungeon.sel)
	for id in g.lvl:w.s.members[id].level=g.lvl[id]
	if r.extra is Dictionary and r.extra.get("q") is Dictionary:
		w.s.quest=r.extra.q.duplicate(true);w.s.quest.cmp=true
	else:w.s.quest={}
	return w
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-pass6-oracle.json"))
	var diffs=[]
	for r in o.view:
		var w=setup_case(r);var entries=[]
		if not w.has_method("source_preparation_view"):
			check(false,"missing preparation view "+r.kind,r.kind);continue
		entries=w.source_preparation_view(r.kind,r.extra if r.extra is Dictionary else {})
		var actual=project(entries)
		check(helper.same(actual,r.visible),"visible "+r.kind+" "+r.lang,r.kind)
		if not helper.same(actual,r.visible):diffs.append({"kind":r.kind,"lang":r.lang,"actual":actual,"expected":r.visible})
	for r in o.face:
		var w=helper.setup();w.s.settings={"lang":r.lang}
		if not w.has_method("source_portrait_record"):
			check(false,"missing portrait fallback","face");continue
		var value=w.source_portrait_record(r.id,ImageTexture.new() if r.provider=="html" else 7 if r.provider=="number" else "not an image" if r.provider=="plain" else null).fallback
		check(value==r.visible.text,"portrait "+str([r.id,r.lang,r.provider,value,r.visible.text]),"face")
	for r in o.get("finish",[]):
		var w=helper.setup();w.s.settings={"lang":r.lang};w.s.members.persona.level=10;w.s.gold=300;w.s.day=1;w.s.ui.sel="stale";w.s.ui.tab="back";w.s.dungeon_r21.best=2
		if r.kern:w.s.persona.nation="케른 연방";w.s.party=["haldric","urda"]
		w.depart_dungeon(1,7);w.s.run.step=5;w.s.run.wins=3;w.s.run.gold=21;w.s.run.xp=55;w.s.run.loot_items={"hp_s":4}
		if r.result!="retreat":
			w.s.run.phase="battle";w.s.run.final=true
			var b=w.ModernBattle.new(w.battle_data())
			for unit in (b.data.enemies if r.result=="clear" else b.data.allies):unit.hp=0;unit.gauge=0
			b.result="victory" if r.result=="clear" else "defeat";w.record_battle(b.snapshot())
		check(w.settle(r.result),"settles "+r.result,"finish")
		var value={"run_exists":not w.s.run.is_empty(),"phase":w.s.run.get("phase",""),"screen":"town" if w.expedition_defeat_home() else "summary","gold":w.s.gold,"items":w.s.items.hp_s,"day":w.s.day,"runs":w.s.dungeon_r21.runs,"best":w.s.dungeon_r21.best,"msg":w.s.ui.get("msg","") if r.result=="defeat" else "","tab":w.s.ui.get("tab",""),"sel":w.s.ui.sel}
		check(helper.same(value,r.value),"finish transition "+str([r.lang,r.result,r.kern,value,r.value]),"finish")
		if not helper.same(value,r.value):diffs.append({"kind":"finish","actual":value,"expected":r.value})
		var saved=w.s.duplicate(true);check(not w.settle(r.result) and helper.same(saved,w.s) and r.replay_equal,"settlement replay preserves all state","finish")
		var clone=helper.helper.ready_world();check(clone.restore(saved),"settlement state resumes "+r.result,"finish")
	for mode in [0,1]:
		var w=helper.helper.ready_world();var before=w.s.duplicate(true)
		check(w.set_sortie_mode(mode) and not w.s.dungeon_r21.has("mode"),"mode uses existing cloud field","mode_save")
		var clone=helper.helper.ready_world();check(clone.restore(w.s.duplicate(true)) and clone.sortie_mode()==mode,"mode native roundtrip","mode_save")
		var legacy=before.duplicate(true);legacy.dungeon_r21.mode=mode
		check(clone.restore(legacy) and clone.sortie_mode()==mode and not clone.s.dungeon_r21.has("mode"),"prior local mode migrates without schema extension","mode_save")
		var saved=clone.s.duplicate(true);check(not clone.set_sortie_mode(2) and helper.same(saved,clone.s),"invalid mode atomic","mode_save")
	FileAccess.open("res://../verification/parity-r23/expe-pass6-"+("before" if OS.get_environment("EXPE_PASS6_BEFORE")=="1" else "after")+"-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"groups":groups,"diffs":diffs},"  "))
	print("EXPE PASS6 CHECKS ",checks," FAILURES ",failures.size());helper.helper.free();helper.free();quit(0 if failures.is_empty() else 1)
