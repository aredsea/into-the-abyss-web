extends Control
## Slot contract for branch C. Missing slots fall back to original source art.
const Original=preload("res://ui/character_portrait.gd")
var character_id=""
var kind="bust"
var source_path=""
var texture: Texture2D
var shift=Vector2.ZERO
var source_crop=Rect2()
const SLOTS=["cast-feature","cast-secondary","cast-lower-left","detail-overview","detail-skills","party-tall","formation-face","target-face","town-main","town-party-face"]
static var PLACEMENTS=JSON.parse_string(FileAccess.get_file_as_string("res://data/portrait-slots-r21.json"))

static func preferred_path(id: String,slot: String) -> String:
	# Exact C crops, deduplicated over one lossless master per person.
	var packed="res://assets/portraits-r21-web/slots/"+id+"-"+slot+".tres"
	if ResourceLoader.exists(packed): return packed
	var preferred="res://assets/portraits-r21/slots/"+id+"-"+slot+".png"
	if ResourceLoader.exists(preferred): return preferred
	var original="res://assets/portraits-r10/"+id+("-face.png" if slot=="face" else "-cutout.png")
	return original if ResourceLoader.exists(original) else ""

func configure(id: String,slot="bust") -> void:
	character_id=id; kind=slot; source_path=preferred_path(id,slot)
	for c in get_children(): remove_child(c); c.queue_free()
	if not source_path.is_empty():
		texture=load(source_path)
		source_crop=Rect2(Vector2.ZERO,texture.get_size())
		if slot in SLOTS and not source_path.contains("/slots/"):
			for entry in PLACEMENTS:
				if entry.id==id and entry.slot==slot:
					var c=entry.source_crop_xyxy
					source_crop=Rect2(c[0],c[1],c[2]-c[0],c[3]-c[1]); break
			# For the remaining original portraits use the same inward frame,
			# retaining identity and RGB. C can supply per-character crops later.
			if source_crop.size==texture.get_size():
				for entry in PLACEMENTS:
					if entry.id=="hildegard" and entry.slot==slot:
						var c=entry.source_crop_xyxy
						source_crop=Rect2(c[0],c[1],c[2]-c[0],c[3]-c[1]).intersection(Rect2(Vector2.ZERO,texture.get_size())); break
	else:
		var t=Original.new(); add_child(t); t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); t.configure(id)
	clip_contents=true; mouse_filter=MOUSE_FILTER_IGNORE; texture_filter=TEXTURE_FILTER_LINEAR
	queue_redraw()

func _draw() -> void:
	if texture:
		var k=maxf(size.x/source_crop.size.x,size.y/source_crop.size.y)
		var scaled=source_crop.size*k
		var y=(size.y-scaled.y)*.65 if kind=="face" else 0.0
		draw_texture_rect_region(texture,Rect2(Vector2((size.x-scaled.x)/2,y)+shift,scaled),source_crop)
