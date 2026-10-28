extends SceneTree
## Bake the existing editable silhouette geometry, then frame the original face.
## Only geometry, framing and resampling change; original RGB is not repainted.
const Portrait = preload("res://ui/character_portrait.gd")
const FRAMES = {
	"hildegard": Rect2(72, 18, 390, 440),
	"bargut": Rect2(99, 8, 330, 390),
	"teiris": Rect2(96, 35, 335, 395),
	"berenga": Rect2(74, 42, 380, 430)
}
func _initialize() -> void: call_deferred("bake")
func clean_geometry(p: Dictionary, id: String) -> ArrayMesh:
	var dims: Vector2i = Vector2i(p.texture.get_size()); var w = dims.x; var h = dims.y
	var mask = PackedByteArray(); mask.resize(w*h)
	var vertices = p.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for k in range(0,vertices.size(),4):
		var y = int(vertices[k].y)
		for x in range(int(vertices[k].x),int(vertices[k+1].x)): mask[y*w+x] = 1
	# Tiny paper remnants below the bob, identified in the full-size source.
	if id == "hildegard":
		for box in [Rect2i(374,358,9,8),Rect2i(365,367,10,9)]:
			for y in range(box.position.y,box.end.y):
				for x in range(box.position.x,box.end.x): mask[y*w+x] = 0
	# Disconnected sub-32-pixel fragments are cutout debris, not face detail.
	var seen = PackedByteArray(); seen.resize(w*h)
	for start in range(w*h):
		if mask[start] == 0 or seen[start] == 1: continue
		var queue = PackedInt32Array([start]); seen[start] = 1; var head = 0
		while head < queue.size():
			var at = queue[head]; head += 1
			for dy in range(-1,2):
				for dx in range(-1,2):
					var x = at % w + dx; var y = at / w + dy
					if x < 0 or x >= w or y < 0 or y >= h: continue
					var next = int(y)*w+x
					if mask[next] == 1 and seen[next] == 0: seen[next] = 1; queue.append(next)
		if queue.size() < 32:
			for at in queue: mask[at] = 0
	var points = PackedVector3Array(); var uv = PackedVector2Array(); var indices = PackedInt32Array()
	for y in range(h):
		var x = 0
		while x < w:
			if mask[y*w+x] == 0: x += 1; continue
			var start = x
			while x < w and mask[y*w+x] == 1: x += 1
			var first = points.size()
			for v in [Vector2(start,y),Vector2(x,y),Vector2(x,y+1),Vector2(start,y+1)]: points.append(Vector3(v.x,v.y,0)); uv.append(v/Vector2(dims))
			for n in [0,1,2,0,2,3]: indices.append(first+n)
	var arrays = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=points; arrays[Mesh.ARRAY_TEX_UV]=uv; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh = ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
func render(portrait: Dictionary, frame: Rect2, dims: Vector2i) -> Image:
	var viewport = SubViewport.new()
	viewport.size = dims; viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actor = MeshInstance2D.new(); actor.mesh = portrait.mesh; actor.texture = portrait.texture
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	actor.scale = Vector2(dims) / frame.size
	actor.position = -frame.position * actor.scale
	viewport.add_child(actor)
	await process_frame; await RenderingServer.frame_post_draw
	var result = viewport.get_texture().get_image()
	root.remove_child(viewport); viewport.queue_free()
	return result
func bake() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/portraits-r10")
	var manifest = {}
	for id in FRAMES:
		var p = Portrait.prepare(id).duplicate()
		p.mesh = clean_geometry(p,id)
		var whole = Rect2(Vector2.ZERO, p.texture.get_size())
		var cutout = await render(p, whole, Vector2i(whole.size))
		var full_path = "res://assets/portraits-r10/" + id + "-cutout.png"
		if cutout.save_png(full_path) != OK: quit(1); return
		# Use each source crop's own aspect ratio, never stretch facial anatomy.
		var f: Rect2 = FRAMES[id]
		var dims = Vector2i(512, roundi(512 * f.size.y / f.size.x))
		var face = await render(p, f, dims)
		var face_path = "res://assets/portraits-r10/" + id + "-face.png"
		if face.save_png(face_path) != OK: quit(1); return
		manifest[id] = {"source": p.path, "source_sha256": FileAccess.get_sha256(p.path), "cutout": full_path, "face": face_path, "crop": [f.position.x, f.position.y, f.size.x, f.size.y], "size": [dims.x,dims.y], "method": "original texture through existing silhouette mesh; no generated face"}
	var file = FileAccess.open("res://data/face-portraits.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"  ")+"\n")
	print("Exported 4 separate transparent cutouts and 4 face crops from original textures")
	quit()
