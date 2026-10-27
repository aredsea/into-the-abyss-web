extends SceneTree
const Portrait = preload("res://ui/character_portrait.gd")
func _initialize() -> void:
	var assets = JSON.parse_string(FileAccess.get_file_as_string("res://data/expansion-assets.json"))
	DirAccess.make_dir_recursive_absolute("res://assets/portrait-clips")
	var result = {}
	for asset in assets:
		if not "/portraits/" in asset.source: continue
		var id: String = asset.destination.get_file().get_basename()
		var p = Portrait.prepare(id, true)
		var mesh_path = "res://assets/portrait-clips/" + id + ".res"
		var error = ResourceSaver.save(p.mesh, mesh_path, ResourceSaver.FLAG_COMPRESS)
		if error != OK: push_error("Cannot save portrait mesh: " + id); quit(1); return
		var b: Rect2 = p.bounds
		result[id] = {"mesh": mesh_path, "source": p.path, "source_sha256": FileAccess.get_sha256(p.path), "bounds": [b.position.x, b.position.y, b.size.x, b.size.y], "clipped_paper_pixels": p.clipped_pixels, "source_pixels": p.pixels}
	var file = FileAccess.open("res://data/menu-portraits.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n"); file.close()
	print("MENU PORTRAITS: ", result.size(), " original textures with baked clipping meshes; no original images written")
	quit()
