extends SceneTree
const L=preload("res://game/localization_r22.gd")
const R=preload("res://game/panels_rules_r22.gd")
const View=preload("res://game/ui_semantics_r23.gd")
const Portrait=preload("res://ui/portrait_rules_r22.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg)
func _initialize():
	create_timer(90).timeout.connect(func():quit(98));call_deferred("run")
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-oracle.json"))
	var excluded=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-excluded-translation-keys.json"))
	var baseline="--baseline" in OS.get_cmdline_user_args()
	if baseline:
		var before=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-localization-before.json"));L.configure_packs({"en":JSON.stringify(before.ui)},JSON.stringify(before.words))
	for c in o.cases:
		if baseline and c.fn not in ["u","t","c1_en"]:continue
		var actual: Variant=null
		match c.fn:
			"u":
				if c.args[0] in excluded.ui:continue
				actual=L.u(c.args[0],c.args[1],c.lang)
			"t":
				if c.args[0] in excluded.words:continue
				actual=L.t(c.args[0],c.lang)
			"c1_en":actual=L.new().call("c1_en",c.args[0] if not c.args.is_empty() else null) if L.new().has_method("c1_en") else null
			"c1_custom":
				var saved=L.packs;L.configure_packs(null,c.args[0]);actual=L.c1_en(c.args[1]);L.packs=saved
			"notice":actual=View.observe("notice",c.args,c.lang).text
			"item_name":actual=View.new().call("item_name",c.args[0] if not c.args.is_empty() else null,c.lang) if View.new().has_method("item_name") else null
			"face":
				var p=Portrait.new();p.configure(c.args[0],"default",c.args[1],c.lang);actual={"asset":p.selection.name,"initial":p.initial if p.texture==null else "","persona":c.args[0] in ["","persona"]}
				p.free()
			_ :continue
		var expected=c.get("value",c.get("expected"))
		if c.fn=="notice":expected=c.expected.text
		check(actual==expected,c.id+" "+c.fn+" "+c.lang+" "+str(c.args).left(160)+" expected="+str(expected).left(200)+" actual="+str(actual).left(200))
	if not baseline:
		check(L.ui_pack("en")==o.packs.ui,"P0089 exact public source pack membership")
		check(L.en_dict()==o.packs.words,"P0092 exact public source dictionary membership")
		check(L.ui_pack("ko")=={} and L.ui_pack("missing")=={},"P0089 absent language pack")
		for c in o.portraits:
			var p=Portrait.new();p.configure(c.id,c.variant)
			check(p.selection.name==c.asset,"P3721 source asset "+c.id+" "+c.variant)
			check(p.texture!=null and ResourceLoader.exists(p.selection.path),"P3721 actual resource "+c.id+" "+c.variant)
			check(p.initial=="","P3721 present source portrait hides initial "+c.id);p.free()
	FileAccess.open("res://../verification/parity-r23/ui-phase4/"+("ui-dictionary-baseline.json" if baseline else "ui-rule-results.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("UI PHASE4 RULE CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
