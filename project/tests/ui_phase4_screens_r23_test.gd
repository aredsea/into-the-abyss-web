extends "res://tests/ui_phase4_native_r23_test.gd"
var code_parser=preload("res://game/gear_rules_r22.gd").new()
func body_words(s) -> String:
	var words=[];var o={"bars":[],"buttons":[]};collect_choices(s.town_view.body,words,o);return " ".join(words).strip_edges()
func collect_choices(node: Node,words: Array,o: Dictionary):
	if node is OptionButton:
		for i in node.item_count:words.append(node.get_item_text(i))
	elif node is Label or node is Button:words.append(node.text.replace("\n"," "))
	for child in node.get_children():collect_choices(child,words,o)
func source_entry(model,code: String,uid: int) -> Dictionary:
	var p=code_parser.gear_parse(code);return {"id":p.id,"seed":p.seed,"uid":uid,"forge":0,"tries":0,"source_r21":true}
func run():
	folder="res://../verification/parity-r23/ui-phase4/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-screens-oracle.json"))
	var s=Screen.new();s.size=Vector2(390,844);root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844);root.add_child(s);s.storage.path="user://ui-phase4-screens.json";s.motion_reduced=true
	for c in o.settings:
		s.model=fixture();s.model.s.settings={"lang":c.lang,"diff":c.diff,"chron":c.chron};s.screen="settings";s._draw_screen();await settle()
		for b in c.buttons:
			var key=b.action.replace("op_","p8_");check(s.controls.has(key),"P2630 control "+key)
			if not s.controls.has(key):continue
			var control=s.controls[key];check(control.text.replace("\n"," ")==b.text,"P2630 "+key+" label "+control.text+" expected "+b.text)
			check((control.get_theme_color("font_color")==preload("res://ui/town_theme_r21.gd").PAPER)==b.selected,"P2630 "+key+" selection")
		for key in ["lang","chron"]:check(s.town_view.find_children("*","Label",true,false).any(func(n):return n.text==c.notes[key]),"P2631 source public explanation "+key)
	for c in o.bags:
		s.model=fixture();s.model.s.settings={"lang":c.lang};s.model.s.gear=[]
		for cid in s.model.s.equipment:s.model.s.equipment[cid]={}
		for i in c.bag.size():s.model.s.gear.append(source_entry(s.model,c.bag[i],i+1))
		s.panels_r22=State.new(s.model);s.panels_r22.bg=c.state.duplicate();s.panels_r22.bg.pg=int(c.input_page);s.screen="inventory";s._draw_screen();await settle()
		var got=body_words(s);got="가방 "+got if c.lang=="ko" else L.u("가방",{},c.lang)+" "+got
		# Gold belongs to the source HUD; compare the bag component's count here.
		got=got.replace(" · 금화 "+str(int(s.model.s.gold)),"").replace(" · "+str(int(s.model.s.gold))+" gold","")
		check(got==c.expected.text,"P2578 bag "+c.lang+" "+str(c.input_page)+" "+c.state.cls+" got="+got+" expected="+c.expected.text)
		check(s.panels_r22.bg.pg==c.state.pg,"P2578 source page clamp")
		# A stale selection must clear confirmation and remain cleared after reload.
		s.panels_r22.bg.sel="removed-code";s.panels_r22.bg.conf="removed-code";s._draw_screen();await settle();check(s.panels_r22.bg.sel=="" and s.panels_r22.bg.conf=="","P2592 stale selection fallback")
		s._save();var resumed=s.model.get_script().new();check(s.storage.read_into(resumed),"P2592 reload error="+str(s.save_error));check(State.new(resumed).bg.sel=="","P2592 stale selection stays cleared")
	for c in o.details:
		s.model=fixture();s.model.s.settings={"lang":c.lang};s.model.s.owned=[];s.model.s.party=[];s.model.s.persona.cls=c.cls;s.model.s.persona.name="A & B";s.model.s.persona.lv=int(c.level);s.model.s.members.persona.level=int(c.level);s.model.s.gear=[source_entry(s.model,c.selected,1),source_entry(s.model,c.old,2)];s.model.s.equipment={"persona":{"weapon":2}};s.model.s.serial=2
		if c.has("g"):
			s.model.s.owned=c.g.roster.duplicate();s.model.s.party=c.g.party.duplicate();s.model.s.gear=[source_entry(s.model,c.selected,1)];s.model.s.equipment={}
			for id in s.model.s.owned:s.model.s.members[id].level=int(c.g.lvl.get(id,40))
			for id in c.g.equip:
				s.model.s.equipment[id]={}
				if not c.g.equip[id] is Dictionary:continue
				for slot in c.g.equip[id]:
					var code=c.g.equip[id][slot];s.model.s.gear.append(source_entry(s.model,code,s.model.s.gear.size()+1));s.model.s.equipment[id][slot]=s.model.s.gear.size()
			if c.g.forge is Dictionary:
				for entry in s.model.s.gear:entry.forge=c.g.forge.get(s.model.gear.code(entry),{}).get("lv",0)
		s.panels_r22=State.new(s.model);s.panels_r22.bg=c.g.ui.bg.duplicate() if c.has("g") else s.panels_r22.bg;s.panels_r22.bg.sel=c.selected;s.screen="inventory";s._draw_screen();await settle()
		var got=body_words(s);check(got==c.expected.text,"P2586 "+c.lang+" "+c.cls+" Lv"+str(c.level)+" got="+got+" expected="+c.expected.text)
	# Direct screenshots at shipping widths, with the source comparison visible.
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932)]:
		for lang in ["ko","en"]:
			root.content_scale_size=dim;root.size=dim;s.size=dim;s.model.s.settings.lang=lang;s._draw_screen();await settle();s.town_view.scroll.scroll_vertical=300;await capture(s,"ui-comparison-"+lang,dim)
	FileAccess.open("res://../verification/parity-r23/ui-phase4/ui-screen-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("UI PHASE4 SCREEN CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
