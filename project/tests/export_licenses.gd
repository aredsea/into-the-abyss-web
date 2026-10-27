extends SceneTree

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://licenses")
	var out = FileAccess.open("res://licenses/GODOT_AND_THIRD_PARTY.txt",FileAccess.WRITE)
	out.store_string(Engine.get_license_text()+"\n\nTHIRD-PARTY COPYRIGHT NOTICES\n\n")
	out.store_string(JSON.stringify(Engine.get_copyright_info(),"  "))
	out.store_string("\n\nTHIRD-PARTY LICENSE TEXTS\n\n")
	var licenses=Engine.get_license_info()
	for key in licenses:
		out.store_string("\n\n"+key+"\n\n"+licenses[key])
	out.flush()
	print("Exported Godot and bundled library license notices.")
	quit()
