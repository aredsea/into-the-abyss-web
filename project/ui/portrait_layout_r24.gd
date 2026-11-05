extends Control
## Borderless source-art bust. Screen owners choose the surrounding layout.
static var LANDMARKS=JSON.parse_string(FileAccess.get_file_as_string("res://assets/portraits-r24/landmarks.json"))
static var NPC_LANDMARKS=JSON.parse_string(FileAccess.get_file_as_string("res://assets/portraits-r24/npc/landmarks.json"))
const SLOT_KINDS=["party_card","list_row","chip","hero","detail","battle_card"]
const WASH=preload("res://assets/portraits-r24/wash.png")
var character_id=""
var slot_kind="detail"
var picture: Texture2D
static func path(id: String) -> String:
	var p="res://assets/portraits-r24/masters/"+id+".png"
	if NPC_LANDMARKS.has(id):p="res://assets/portraits-r24/npc/"+id+".png"
	return p if (LANDMARKS.has(id) or NPC_LANDMARKS.has(id)) and ResourceLoader.exists(p) else ""
static func landmark(id: String) -> Dictionary:
	return NPC_LANDMARKS.get(id,LANDMARKS.get(id,{}))
static func kind_for_legacy(slot: String) -> String:
	if slot in SLOT_KINDS:return slot
	if slot in ["town-party","battle-party"]:return "party_card" if slot=="town-party" else "battle_card"
	if slot in ["companion-chip","dialogue-chip","battle-log"]:return "chip"
	if slot in ["companion-main","dialogue-main"]:return "hero"
	if slot in ["roster","panel"]:return "list_row"
	if slot in ["face","formation-face","target-face","town-party-face"]:return "chip"
	if slot=="party-tall":return "party_card"
	if slot=="town-main":return "hero"
	if slot.begins_with("cast-"):return "list_row"
	return "detail"
static func frame(id: String,dims: Vector2,_face=false) -> Rect2:
	if landmark(id).is_empty() or dims.x<=0 or dims.y<=0:return Rect2()
	var m=landmark(id);var head=m.head_bounds_xyxy
	# Crown 10%; shoulders before the final 30% fade; whole ears and horns.
	var h=maxf((m.eye_y-m.top_y)/.32,(m.shoulder_y-m.top_y)/.57)
	h=maxf(h,(head[2]-head[0])/(dims.x/dims.y*.92))
	var w=h*dims.x/dims.y
	var cx=maxf(head[2]-w*.46,minf(m.center_x,head[0]+w*.46))
	return Rect2(cx-w/2,m.top_y-h*.10,w,h)
static func destination(id: String,dims: Vector2,texture_size: Vector2,face=false) -> Rect2:
	var box=frame(id,dims,face)
	if box.size.x<=0:return Rect2(Vector2.ZERO,dims)
	var scale=dims.x/box.size.x
	return Rect2(-box.position*scale,texture_size*scale)

static func fade(y: float) -> float:
	var t=clampf((y-.70)/.30,0,1)
	return 1.0-t*t*(3.0-2.0*t)

static func paint(canvas: Control,id: String,dims: Vector2,texture: Texture2D) -> void:
	if texture==null or dims.x<=0 or dims.y<=0 or landmark(id).is_empty():return
	canvas.draw_texture_rect(WASH,Rect2(dims.x*.12,dims.y*.36,dims.x*.76,dims.y*.36),false,Color(1,1,1,.26))
	var crop=frame(id,dims);var tex_size=texture.get_size()
	var k=dims.x/crop.size.x
	var image_rect=Rect2(-crop.position*k,tex_size*k).intersection(Rect2(Vector2.ZERO,dims))
	if not image_rect.has_area():return
	# Region draws preserve compatibility with the existing KO material and
	# avoid per-polygon UV triangulation artifacts on small compatibility canvases.
	var stops=[0.0,.70]
	for i in range(1,65):stops.append(.70+.30*i/64.0)
	for i in range(stops.size()-1):
		var y0=maxf(image_rect.position.y,dims.y*stops[i])
		var y1=minf(image_rect.end.y,dims.y*stops[i+1])
		if y1<=y0:continue
		var target=Rect2(image_rect.position.x,y0,image_rect.size.x,y1-y0)
		var source=Rect2(target.position/k+crop.position,target.size/k)
		canvas.draw_texture_rect_region(texture,target,source,Color(1,1,1,fade((y0+y1)*.5/dims.y)))

static func make_portrait(id: String,kind: String,dims: Vector2) -> Control:
	var node=load("res://ui/portrait_layout_r24.gd").new()
	node.configure(id,kind);node.custom_minimum_size=dims;node.size=dims
	return node

func configure(id: String,kind="detail") -> void:
	character_id=id;slot_kind=kind_for_legacy(kind)
	var source=path(id);picture=load(source) if source!="" else null
	mouse_filter=MOUSE_FILTER_IGNORE;clip_contents=true;texture_filter=TEXTURE_FILTER_LINEAR
	queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	paint(self,character_id,size,picture)
