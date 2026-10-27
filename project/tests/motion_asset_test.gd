extends SceneTree
## Data contract: timing and attachments must survive a web export unchanged.
func _initialize() -> void:
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat-motion.json"))
	assert(catalog.size() == 1 and catalog.has("hildegard:attack"))
	var clip = catalog["hildegard:attack"]
	assert(clip.frames == 12 and clip.durations_ms.size() == clip.frames)
	assert(clip.weapon.anchors.size() == clip.frames)
	var total = 0.0
	var contact = 0.0
	for i in range(int(clip.frames)):
		assert(clip.durations_ms[i] > 0)
		total += clip.durations_ms[i]
		if i < clip.contact_frame: contact += clip.durations_ms[i]
	assert(is_equal_approx(total / 1000, clip.duration))
	assert(is_equal_approx(contact / 1000, clip.impact_at))
	var body = load(clip.path) as Texture2D
	var sword = load(clip.weapon.path) as Texture2D
	assert(body != null and sword != null)
	assert(body.get_width() == clip.frame_size * clip.columns)
	assert(body.get_height() >= ceili(float(clip.frames) / clip.columns) * clip.frame_size)
	assert(sword.get_width() == 256 and sword.get_height() == 256)
	assert(clip.root_motion, "Do not double the authored step with a global slide")
	print("MOTION ASSET PASS: 12 poses, rigid weapon, contact timing and atlas bounds")
	quit()
