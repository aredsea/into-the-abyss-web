extends Control
## Displays unmodified sheet pixels through a transparent-seam UV polygon.
## A straight atlas crop would cut wide weapons that cross the sheet midpoint.
static var catalog: Dictionary={}
var character_id=""
var action_pose=false
var sheet: Texture2D

static func info(id: String) -> Dictionary:
	if catalog.is_empty(): catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/character-art-r4.json"))
	return catalog.get(id,{})

func configure(id: String, action=false) -> void:
	character_id=id; action_pose=action
	var data=info(id)
	if not data.is_empty(): sheet=load(data.path)
	queue_redraw()

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func _draw() -> void:
	if sheet==null: return
	var data=info(character_id); var frame=data.frames[1 if action_pose else 0]; var b=frame.bounds
	var extent=Vector2(b[2],b[3]); var ratio=minf(size.x/extent.x,size.y/extent.y)
	var origin=Vector2((size.x-extent.x*ratio)/2,size.y-extent.y*ratio)
	var vertices=PackedVector2Array(); var uv=PackedVector2Array()
	for p in frame.polygon:
		vertices.append(origin+(Vector2(p[0],p[1])-Vector2(b[0],b[1]))*ratio)
		uv.append(Vector2(p[0]/float(data.size[0]),p[1]/float(data.size[1])))
	draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,sheet)
