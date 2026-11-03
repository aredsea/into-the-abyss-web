extends "res://tests/ui_panels_r22_test.gd"
const L=preload("res://game/localization_r22.gd")
func observation(node: Node) -> Dictionary:
	var o={"text":"","bars":[],"buttons":[],"favorite":node.get_meta("favorite",false)};var words=[]
	collect(node,words,o)
	o.text=" ".join(words).strip_edges();return o
func collect(node: Node,words: Array,o: Dictionary):
	if node is Label or node is Button:words.append(node.text.replace("\n"," "))
	if node is ProgressBar:o.bars.append(float("%.3f"%(node.value/node.max_value)))
	if node is Button and not node.disabled:o.buttons.append(node.get_meta("source_action",""))
	# Native button.text is still the canonical accessible action. Its authored
	# visual title/subtitle and arrow repeat that text without adding an action.
	if node is Button:return
	for child in node.get_children():collect(child,words,o)
func run():
	folder="res://../verification/parity-r23/ui-phase4/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-oracle.json"))
	var s=Screen.new();s.size=Vector2(390,844);root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844);root.add_child(s);s.storage.path="user://ui-phase4.json";s.motion_reduced=true
	for c in oracle.cases:
		if c.fn not in ["fav","tile"]:continue
		var g=c.args[0];var id=c.args[1];s.model=fixture();s.model.s.settings={"lang":c.lang};s.model.s.owned=g.roster.duplicate();s.model.s.favs=g.favs.duplicate();s.model.s.party=g.party.duplicate()
		for cid in g.roster:s.model.s.members[cid].level=int(g.lvl.get(cid,1));s.model.s.members[cid].aff=g.aff.get(cid,0)
		s.panels_r22=State.new(s.model)
		if c.fn=="tile" and g.roster.is_empty():s.panels_r22.ui.page=R.codex_list([]).find(id)/R.PAGE+1
		s.screen="status" if c.fn=="fav" else "codex";s._draw_screen();await settle()
		var card: Node=null
		if c.fn=="tile" and s.controls.has("p7_select_"+id):card=s.controls["p7_select_"+id].get_parent()
		if c.fn=="fav":
			for n in s.town_view.find_children("*","VBoxContainer",true,false):
				if n.get_meta("favorite_id","")==id:card=n;break
		if card==null:check(false,c.id+" actual card missing "+id);continue
		var expected=preload("res://tests/source_locale_r24.gd").text(c.expected.text,c.lang)
		var got=observation(card);check(got.text==expected,c.id+" "+id+" "+c.lang+" text: "+got.text+" expected "+expected)
		check(got.bars==c.expected.bars,c.id+" "+id+" bars "+str(got.bars)+" expected "+str(c.expected.bars))
		check(got.favorite==c.expected.favorite,c.id+" favorite marker "+id)
		check(got.buttons.size()==c.expected.buttons.size(),c.id+" selectable actions "+id)
		if not c.expected.buttons.is_empty():
			var key="p7_open_"+id if c.fn=="fav" else "p7_select_"+id;await click(s,key);check(s.screen=="codex" and s.panels_r22.ui.sel==id,"actual detail action "+id)
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932)]:
		for lang in ["ko","en"]:
			root.content_scale_size=dim;root.size=dim;s.size=dim;s.model=fixture();s.model.s.settings={"lang":lang};s.panels_r22=State.new(s.model);s.screen="status";s._draw_screen();await settle();s.town_view.scroll.scroll_vertical=10000;await capture(s,"ui-favorites-"+lang,dim)
	# Public battle panel hides bag entry; the frozen battle screen itself is separate.
	s.model.s.run={"phase":"battle","battle":{}};s.screen="codex";s.panels_r22.ui.sel="";s.controls.clear()
	var component=preload("res://ui/codex_screen_r22.gd").new();root.add_child(component);component.build(s);await settle()
	check(not s.controls.has("p7_tab_inventory") and not s.controls.has("nav:bag"),"P2606 source battle panel hides bag entry")
	component.free()
	FileAccess.open("res://../verification/parity-r23/ui-phase4/ui-native-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("UI PHASE4 NATIVE CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
