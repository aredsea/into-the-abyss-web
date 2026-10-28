extends Control
## Menu-only original portrait. A silhouette mesh clips border-connected white
## paper; source texture pixels and files are never repainted or replaced.
static var cache: Dictionary = {}
static var framing: Dictionary = {}
var character_id = ""
var portrait: Dictionary = {}
# Explicit empty spaces enclosed by horns / hair, checked against source art.
# Do not globally key white pixels: clothing, eyes and pale hair must survive.
const PAPER_GAPS = {
	"saya": [[120,170],[407,170],[110,330],[142,415],[190,430],[388,390],[340,430]],
	"tove": [[132,150],[385,150],[115,385],[400,385]],
	"urda": [[100,235],[417,235],[105,410],[414,410]],
	"zahar": [[110,210],[420,210],[115,380],[170,400],[330,399],[410,365]],
	"gerda": [[111,226],[420,250],[84,345],[148,387],[394,384],[439,342]],
	"hildegard": [[250,24],[90,229],[430,213],[103,225],[429,282],[433,306],[93,311],[437,336],[109,350],[407,356],[143,368],[314,370],[375,366],[216,370],[361,375],[329,382]],
	"bargut": [[131,185],[398,213],[119,216],[129,251],[393,247],[405,291],[122,331],[411,338],[436,389],[435,400],[71,483],[61,490],[455,486],[84,492],[463,493],[477,501],[447,500],[433,518],[101,519]],
	"teiris": [[138,181],[143,217],[134,223],[135,269],[139,260],[396,292],[134,287],[130,310],[411,352],[121,357],[430,384],[112,378],[101,391],[406,381],[62,441],[489,480],[46,484],[26,562],[15,594],[512,600],[512,620]]
}

static func prepare(id: String, rebuild=false) -> Dictionary:
	if cache.has(id): return cache[id]
	var path = "res://assets/" + id + ".webp"
	var picture = load(path) as Texture2D
	if not rebuild:
		if framing.is_empty(): framing = JSON.parse_string(FileAccess.get_file_as_string("res://data/menu-portraits.json"))
		var f: Dictionary = framing[id]
		cache[id] = {"texture": picture, "mesh": load(f.mesh), "bounds": Rect2(f.bounds[0], f.bounds[1], f.bounds[2], f.bounds[3]), "path": path}
		return cache[id]
	var source = picture.get_image()
	if source.is_compressed(): source.decompress()
	source.convert(Image.FORMAT_RGBA8)
	var w = source.get_width(); var h = source.get_height()
	var rgba = source.get_data()
	var paper = PackedByteArray(); paper.resize(w * h)
	for i in range(w * h):
		var at = i * 4
		var low = mini(rgba[at], mini(rgba[at + 1], rgba[at + 2]))
		var high = maxi(rgba[at], maxi(rgba[at + 1], rgba[at + 2]))
		paper[i] = 1 if low >= 235 and high - low <= 18 else 0
	# Only the outside paper is clipped: enclosed white cloth/eyes stay intact.
	var outside = PackedByteArray(); outside.resize(w * h)
	var queue = PackedInt32Array(); queue.resize(w * h)
	var tail = 0
	for i in range(w * h):
		if (i < w or i >= w * (h - 1) or i % w == 0 or i % w == w - 1) and paper[i] == 1:
			outside[i] = 1; queue[tail] = i; tail += 1
	for point in PAPER_GAPS.get(id, []):
		var i = int(point[1]) * w + int(point[0])
		if paper[i] == 1 and outside[i] == 0: outside[i] = 1; queue[tail] = i; tail += 1
	var head = 0
	while head < tail:
		var i = queue[head]; head += 1
		for n in [i - w, i + w, i - 1 if i % w > 0 else -1, i + 1 if i % w < w - 1 else -1]:
			if n >= 0 and n < w * h and outside[n] == 0 and paper[n] == 1:
				outside[n] = 1; queue[tail] = n; tail += 1
	# Remove detached foreground specks and sub-four-pixel flyaway strands from
	# the silhouette, rather than repainting the portrait or keying white clothes.
	# Opening erodes then restores broad contours; all operations affect geometry.
	var opened = outside.duplicate()
	for pass_index in range(2):
		var next = opened.duplicate()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var i = y * w + x
				if opened[i] == 0 and (opened[i-1] == 1 or opened[i+1] == 1 or opened[i-w] == 1 or opened[i+w] == 1): next[i] = 1
		opened = next
	for pass_index in range(2):
		var next = opened.duplicate()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var i = y * w + x
				if outside[i] == 0 and (opened[i-1] == 0 or opened[i+1] == 0 or opened[i-w] == 0 or opened[i+w] == 0): next[i] = 0
		opened = next
	outside = opened
	# Recede one source pixel from white-contaminated antialias boundaries.
	var edge = outside.duplicate()
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var i = y * w + x
			if outside[i] == 0:
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if outside[(y+dy)*w+x+dx] == 1: edge[i] = 1
	outside = edge
	# One mesh instead of thousands of canvas draw calls. UVs sample the original.
	var vertices = PackedVector3Array(); var uv = PackedVector2Array()
	var indices = PackedInt32Array()
	var min_x = w; var min_y = h; var max_x = 0; var max_y = 0
	for y in range(h):
		var x = 0
		while x < w:
			if outside[y * w + x] == 1: x += 1; continue
			var start = x
			while x < w and outside[y * w + x] == 0: x += 1
			min_x = mini(min_x, start); min_y = mini(min_y, y)
			max_x = maxi(max_x, x); max_y = maxi(max_y, y + 1)
			var first = vertices.size()
			for p in [Vector2(start, y), Vector2(x, y), Vector2(x, y + 1), Vector2(start, y + 1)]:
				vertices.append(Vector3(p.x, p.y, 0)); uv.append(p / Vector2(w, h))
			for n in [0, 1, 2, 0, 2, 3]: indices.append(first + n)
	var arrays = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices; arrays[Mesh.ARRAY_TEX_UV] = uv; arrays[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	cache[id] = {"texture": picture, "mesh": mesh, "bounds": Rect2(min_x, min_y, max_x - min_x, max_y - min_y), "path": path, "clipped_pixels": tail, "pixels": w * h}
	return cache[id]

func configure(id: String) -> void:
	character_id = id; portrait = prepare(id); queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)

func _draw() -> void:
	if portrait.is_empty(): return
	var bounds: Rect2 = portrait.bounds
	var ratio = maxf(size.x / bounds.size.x, size.y / bounds.size.y)
	var origin = Vector2((size.x - bounds.size.x * ratio) / 2, 0) - bounds.position * ratio
	draw_set_transform(origin, 0, Vector2.ONE * ratio)
	draw_mesh(portrait.mesh, portrait.texture)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
