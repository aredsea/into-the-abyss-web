extends SceneTree
const Motion = preload("res://ui/motion_library.gd")
func _initialize() -> void:
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat-motion.json"))
	var checked = 0
	for id in ["hildegard", "bargut", "teiris", "berenga"]:
		for action in ["idle", "attack", "guard", "personal"]:
			assert(not Motion.get_clip(id, action).is_empty(), id + " missing " + action)
	assert(not Motion.get_clip("hildegard", "taunt").is_empty())
	assert(Motion.get_clip("bargut", "taunt").is_empty(), "Do not invent taunt")
	for key in catalog:
		var c = Motion.get_clip(key.split(":")[0], key.split(":")[1])
		assert(not c.is_empty(), "Unresolved alias: " + key)
		if catalog[key].has("alias"): continue
		checked += 1
		assert(c.frames == c.durations_ms.size() and c.frames > 1)
		var total = 0.0; var contact = 0.0
		for i in range(int(c.frames)):
			assert(c.durations_ms[i] > 0)
			assert(Motion.frame_at(c, total / 1000 + 0.001) == i, "Frame boundary: " + key)
			total += c.durations_ms[i]
			if i < c.contact_frame: contact += c.durations_ms[i]
		assert(is_equal_approx(total / 1000, c.duration))
		assert(is_equal_approx(contact / 1000, c.impact_at))
		assert(Motion.frame_at(c, c.impact_at) == int(c.contact_frame), "Exact contact pose: " + key)
		var body = Motion.texture(c.path)
		assert(body.get_width() == c.frame_size * c.columns)
		assert(body.get_height() >= ceili(float(c.frames) / c.columns) * c.frame_size)
		assert(Motion.uses_reference(c, 0) and not Motion.uses_reference(c, 1), "Original start")
		if int(c.get("revision", 8)) >= 9:
			assert(not Motion.uses_reference(c, int(c.frames) - 1), "Do not snap final pose to another image")
			assert(c.return_at > c.impact_at and c.return_at < c.duration)
			if c.has("launch_at"): assert(c.launch_at < c.impact_at)
		else:
			assert(Motion.uses_reference(c, int(c.frames) - 1))
		assert(Motion.texture(c.reference_path).get_size() == Vector2(256,256))
		if c.has("weapon"):
			assert(c.weapon.anchors.size() == c.frames)
			assert(Motion.texture(c.weapon.path).get_size() == Vector2(256,256))
		assert(c.root_motion, "Do not add a second whole-body slide")
	assert(Motion.get_clip("teiris", "burst").key == "teiris:personal")
	assert(Motion.get_clip("berenga", "hshield").key == "berenga:cast")
	print("MOTION ASSET PASS: ", checked, " clips, original starts, natural recovery, timing, attachments and mappings")
	quit()
