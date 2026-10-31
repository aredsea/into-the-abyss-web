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
	var font_license=FileAccess.get_file_as_string("res://assets/fonts/OFL-AbyssNoto.txt")
	out.store_string("\n\nAbyss Noto Black Condensed — Noto Sans KR derived font\n"+font_license)
	out.store_string("\n\nAbyss Noto Text 500 / 800 — static subset body fonts\n"+FileAccess.get_file_as_string("res://assets/fonts/OFL-AbyssNotoText.txt"))
	out.store_string("\n\nAbyss Display R19 / Abyss Text R19 W750 W850 Tight — CSS weight and tracking subsets; Noto Sans KR derived fonts\n"+font_license)
	out.flush()
	print("Exported Godot and bundled library license notices.")
	quit()
