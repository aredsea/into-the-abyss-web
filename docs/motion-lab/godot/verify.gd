extends SceneTree
## Import/resource test only. This does not mutate the game's state or save.
func _initialize() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	var checked: Array = []
	for clip in manifest.clips:
		var frames: SpriteFrames = load("res://godot/" + clip.id + ".tres")
		assert(frames != null, clip.id)
		assert(frames.has_animation(clip.id), clip.id)
		assert(frames.get_frame_count(clip.id) == int(clip.frames), clip.id)
		assert(not frames.get_animation_loop(clip.id), clip.id)
		for i in range(int(clip.frames)):
			var tex: AtlasTexture = frames.get_frame_texture(clip.id, i)
			assert(tex != null and tex.region.size == Vector2(256,256), clip.id)
			assert(tex.region.end.x <= tex.atlas.get_width() and tex.region.end.y <= tex.atlas.get_height(), clip.id)
		if clip.has("vfx"):
			for effect in clip.vfx.clips:
				if effect.name not in ["behind","front"]: continue
				var name: String = clip.id + "-" + effect.name
				var fx: SpriteFrames = load("res://godot/"+name+".tres")
				assert(fx != null and fx.get_frame_count(name)==int(effect.frames),name)
		checked.append({"id":clip.id,"frames":clip.frames,"duration":clip.duration})
	print(JSON.stringify({"godot_resource_check":"pass","clips":checked}))
	quit()
