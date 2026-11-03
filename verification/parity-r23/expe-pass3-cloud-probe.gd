extends SceneTree
func _initialize():
	var W=preload("res://game/persona_world.gd");var w=W.new()
	var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/cloud-r22/fixtures.json")).town
	print("restored ",w.restore(fixture))
	var parsed=JSON.parse_string(JSON.stringify(w.s));var differences=[]
	for key in w.s:
		if parsed[key]!=w.s[key]:differences.append({"key":key,"native":w.s[key],"roundtrip":parsed[key]})
	FileAccess.open("res://../verification/parity-r23/expe-pass3-cloud-probe.json",FileAccess.WRITE).store_string(JSON.stringify({"roundtrip_equal":parsed==w.s,"differences":differences,"save":w.s},"  "))
	print("roundtrip equal ",parsed==w.s," difference keys ",differences.map(func(d):return d.key));quit()
