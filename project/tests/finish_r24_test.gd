extends "res://tests/gear_r23_round4_test.gd"
const Display24=preload("res://game/create_display_r24.gd")
const Chronicle24=preload("res://game/chronicle_display_r24.gd")
const Locale24=preload("res://game/localization_r22.gd")
func plain24(s: String) -> String:
	var re=RegEx.new();re.compile("\\s+");return re.sub(s," ",true).strip_edges()
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/oracle.json"));var display=Display24.new()
	var adapter=Save.new()
	for f in o.traits:
		var e=f.entry;var actual=display.trait_row("종족",e.get("tr",""),e.get("te",""),e.get("syn",""),e,f.lang)
		eqcheck("P2416.trait",plain24(" ".join(actual)),f.text)
	for f in o.heads:
		var head=display.head(int(f.page),f.lang);head[2]=Locale24.u(head[2],{"n":f.total},f.lang)
		eqcheck("P2418.head",plain24(" ".join(head)),f.text)
	for f in o.options:
		var option=display.option("전사","전열",f.on,f.lang);var expected=f.buttons[0]
		eqcheck("P2417.option",[option.name+" "+option.sub,option.selected,option.disabled],[expected.text,expected.selected,expected.disabled])
	for f in o.nav:eqcheck("P2421.nav",display.nav(f.p,int(f.page),f.lang),f.buttons.map(func(b):return {"id":b.id,"text":b.text,"disabled":b.disabled}))
	for f in o.steps:
		for i in 5:
			var b=f.buttons[i];eqcheck("P2419.steps",[b.id,b.text,b.selected,b.disabled],["cr_go_"+str(i+1),str(i+1)+" "+Locale24.u(display.rules.data.steps[i],{},f.lang),i+1==f.page,i+1!=f.page and not display.rules.reach(f.p,i+1)])
	for f in o.confirm:eqcheck("P2439.confirm",plain24(" ".join(display.confirmation(f.p,f.lang))),f.text)
	for f in o.seeds:eqcheck("P0101.seed",display.rules.new_seed(int(f.seconds),int(f.micros),int(f.random)),f.value)
	var seeded=World.new();var seed_calls=[0];var seed_case=o.seeds[13]
	seeded.seed_source=func():seed_calls[0]+=1;return display.rules.new_seed(int(seed_case.seconds),int(seed_case.micros),int(seed_case.random))
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:seeded.create_action(arg)
	seeded.create_action("pick_teiris","sc");seeded.create_action("go","sc")
	eqcheck("P0101.creation-entry",[seed_calls[0],seeded.s.town_r21.seed],[seed_case.calls,seed_case.value])
	seeded.seed_source=Callable()
	for f in o.bank:
		var w=ready_world();w.s.gear=[];w.s.equipment.persona={};w.s.serial=0
		for i in int(f.size):w.s.serial+=1;w.s.gear.append(adapter.entry("wa01.1.1",w.s.serial))
		w.s.gear_r22={"overflow":[{"code":"wa01.9.1","forge":{"lv":2,"tries":3}}]}
		var old=w.s.gear_r22.duplicate(true);var bank=w.bank_expedition_gear(["wa01.2.1","wa01.3.1"])
		eqcheck("P3195.bank",[bank.gear,bank.lost,w.s.gear.size()],[f.got,f.lost,f.after])
		eqcheck("P3195.old-overflow",w.s.gear_r22,old)
		var again=World.new();check(again.restore(w.s),"old overflow restore "+str(f.size));eqcheck("overflow_preserved",again.s.gear_r22,old)
	var r4=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/gear-round4-oracle.json"))
	for f in r4.restrictions:
		var w=ready_world();w.s.owned=["hildegard"];w.s.party=[];w.s.gear=[];w.s.serial=0;w.s.equipment.persona={};w.s.equipment.hildegard={};set_level(w,"persona",1);set_level(w,"hildegard",1)
		var imported=Save.new().import_codes(w.s,{"bag":";".join(f.bag),"equip":f.before.equip});check(imported.ok,"restriction import");w.s=imported.state
		eqcheck("P3540.restrict",observe(w),{"gold":w.s.gold,"bag":f.after_bag,"equip":normalized_eq(f.after.equip)})
		if observe(w).equip!=normalized_eq(f.after.equip):print("RESTRICT GAP ",f.n," ",f.code," ",observe(w).equip," EXPECT ",normalized_eq(f.after.equip))
		var again=World.new();check(again.restore(w.s),"restricted old equipment roundtrip");eqcheck("P3540.resume",observe(again),observe(w))
	var s={"settings":{"lang":"ko"},"persona":{"name":"가온"},"chronicle_r22":{"list":[],"queue":[]}}
	for f in o.chronicle:
		var line="Day 1: "+f.en;s.chronicle_r22.list.append(line)
		var entry=Chronicle24.entry(line,s);check(not entry.text.contains("{{"),"chronicle placeholder")
		check(entry.day=="1일째" and entry.text!=f.en,"chronicle Korean display "+f.en)
		var en=s.duplicate(true);en.settings.lang="en";eqcheck("chronicle_en",Chronicle24.entry(line,en).text,Locale24.display(f.en,en))
	var before=s.duplicate(true)
	for line in s.chronicle_r22.list:Chronicle24.entry(line,s)
	check(s==before,"historical chronicle bytes preserved")
	for name in ["","{{user}}","가온"]:
		s.persona.name=name;eqcheck("persona_display",Locale24.display("{{user}} · 페르소나",s),("당신" if name in ["","{{user}}"] else name)+" · 페르소나")
	FileAccess.open("res://../verification/finish-r24/unit-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts},"\t"))
	print("FINISH R24 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
