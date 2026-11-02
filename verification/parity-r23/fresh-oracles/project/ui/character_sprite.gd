extends Control
## Displays unmodified sheet pixels through a transparent-seam UV polygon.
## A straight atlas crop would cut wide weapons that cross the sheet midpoint.
const Motion = preload("res://ui/motion_library.gd")
var idle_enabled = false
var idle_reduced = false
var idle_clip: Dictionary = {}
var idle_elapsed = 0.0
static var catalog: Dictionary={}
var character_id=""
var action_pose=false
var portrait_mode=false
var sheet: Texture2D
# Ready-pose head framing, in the unchanged 1536x1024 source sheet.
const HEAD={"marceline":[400,95],"naran":[430,65],"teiris":[410,195],"haldric":[400,70],"erdene":[400,155],"bianca":[370,100],"saya":[390,125],"gerda":[330,50],"judith":[350,35],"levia":[420,85],"urda":[400,205],"lynette":[380,185],"felice":[410,50],"sorel":[430,205],"tika":[430,75],"hedwig":[390,150],"hildegard":[380,65],"berenga":[400,165],"gunhild":[410,190],"bargut":[410,90],"altan":[380,95],"colette":[370,75],"selva":[430,165],"ornel":[400,125],"zahar":[440,105],"jorund":[400,55],"lavinia":[400,65],"tove":[370,30],"miko":[430,90],"adeline":[400,100]}

static func info(id: String) -> Dictionary:
	if catalog.is_empty(): catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/character-art-r4.json"))
	return catalog.get(id,{})

func configure(id: String, action=false) -> void:
	character_id=id; action_pose=action
	idle_elapsed = 0.0
	var data=info(id)
	if not data.is_empty(): sheet=load(data.path)
	idle_clip = Motion.get_clip(id, "idle") if idle_enabled and not portrait_mode and not action_pose else {}
	queue_redraw()

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=portrait_mode
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)
	idle_reduced = OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches", true))

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		idle_elapsed = 0.0
		return
	if idle_enabled and not idle_clip.is_empty() and not idle_reduced:
		idle_elapsed += delta
		queue_redraw()

func _draw() -> void:
	if idle_enabled and not idle_clip.is_empty() and not idle_reduced:
		var time = fmod(idle_elapsed, float(idle_clip.duration))
		Motion.draw_frame(self, idle_clip, Motion.frame_at(idle_clip, time), Rect2(Vector2.ZERO, size))
		return
	if sheet==null: return
	var data=info(character_id); var frame=data.frames[1 if action_pose else 0]; var b=frame.bounds
	if portrait_mode:
		var head=HEAD[character_id]
		b=[head[0]-175,maxf(0,head[1]-15),350,500]
	var extent=Vector2(b[2],b[3]); var ratio=minf(size.x/extent.x,size.y/extent.y)
	var origin=Vector2((size.x-extent.x*ratio)/2,size.y-extent.y*ratio)
	var vertices=PackedVector2Array(); var uv=PackedVector2Array()
	for p in frame.polygon:
		vertices.append(origin+(Vector2(p[0],p[1])-Vector2(b[0],b[1]))*ratio)
		uv.append(Vector2(p[0]/float(data.size[0]),p[1]/float(data.size[1])))
	draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,sheet)
