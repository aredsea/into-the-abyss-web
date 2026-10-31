extends RefCounted
## Shared presentation data. Never resolves game actions or modifies original art.
static var catalog: Dictionary = {}
static var textures: Dictionary = {}

static func get_clip(id: String, action: String) -> Dictionary:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat-motion.json"))
	var result: Dictionary = catalog.get(id + ":" + action, {})
	if result.has("alias"): return catalog.get(result.alias, {})
	return result

static func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path] = load(path)
	return textures[path]

static func frame_at(clip: Dictionary, time: float) -> int:
	var boundary = 0.0
	for i in range(int(clip.frames)):
		boundary += float(clip.durations_ms[i]) / 1000.0
		# Contact time and cumulative frame time can differ by floating-point dust.
		# At the boundary, show the new pose (including during hitstop).
		if time + 0.000001 < boundary: return i
	return int(clip.frames) - 1

static func uses_reference(clip: Dictionary, frame: int) -> bool:
	for value in clip.get("reference_frames", []):
		if int(value) == frame: return true
	return false

static func draw_frame(canvas: CanvasItem, clip: Dictionary, frame: int, rect: Rect2, step: Vector2 = Vector2.ZERO, pixel: int = 0) -> void:
	var cell = int(clip.get("frame_size", 256))
	var columns = int(clip.get("columns", 5))
	var region = Rect2((frame % columns) * cell, int(frame / columns) * cell, cell, cell)
	var side = rect.size.y * float(cell) / float(clip.get("body_height", 204))
	if pixel>0: side=roundf(side/cell/pixel*cell)*pixel
	var scale_factor = side / cell
	var origin = Vector2(rect.get_center().x - side / 2.0, rect.end.y - side * float(clip.get("foot_y", 230)) / cell) + step
	if pixel>0: origin=origin.round()
	if uses_reference(clip, frame):
		var tex=normalized_texture(clip.reference_path,roundi(side/pixel),roundi(side/pixel)) if pixel>0 else texture(clip.reference_path)
		canvas.draw_texture_rect(tex, Rect2(origin, Vector2.ONE * side), false)
		return
	var body = texture(clip.path)
	if pixel>0:
		var n=roundi(side/pixel)
		body=normalized_texture(clip.path,columns*n,roundi(body.get_height()/float(cell))*n)
		region=Rect2((frame%columns)*n,int(frame/columns)*n,n,n)
	canvas.draw_texture_rect_region(body, Rect2(origin, Vector2.ONE * side), region)
	if not clip.has("weapon"): return
	var attachment = clip.weapon
	var grip = attachment.anchors[frame]
	var hand = Vector2(grip[0], grip[1])
	var pivot = Vector2(attachment.pivot[0], attachment.pivot[1])
	canvas.draw_set_transform(origin + hand * scale_factor, deg_to_rad(float(grip[2]) - float(attachment.base_angle)), Vector2.ONE * scale_factor)
	canvas.draw_texture(texture(attachment.path), -pivot)
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var patch = attachment.hand_patch
	var offset = hand + Vector2(patch[0], patch[1])
	var patch_size = Vector2(patch[2], patch[3])
	canvas.draw_texture_rect_region(texture(clip.path), Rect2(origin + offset * scale_factor, patch_size * scale_factor), Rect2(Vector2((frame%columns)*cell,int(frame/columns)*cell) + offset, patch_size))

static func normalized_texture(path: String,w: int,h: int) -> Texture2D:
	var key=path+":"+str(w)+":"+str(h)
	if not textures.has(key):
		var image=texture(path).get_image()
		image.resize(w,h,Image.INTERPOLATE_NEAREST)
		textures[key]=ImageTexture.create_from_image(image)
	return textures[key]
