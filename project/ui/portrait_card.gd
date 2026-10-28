extends Button
## Portrait and nameplate form a single clickable game card.
const UI=preload("res://ui/fantasy_theme.gd")
const Portrait=preload("res://ui/character_portrait.gd")
var character_id=""
var display_name=""
var role=""
var selected=false
var picture: Control
var large=false
func configure(id: String, title: String, job: String, big=false) -> void:
	character_id=id; display_name=title; role=job; large=big
	tooltip_text=title+" · "+job+" · 상세 보기"
func _ready() -> void:
	clip_contents=true; mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for key in ["normal","hover","pressed","focus"]: add_theme_stylebox_override(key,StyleBoxEmpty.new())
	var backing=Panel.new(); add_child(backing); backing.show_behind_parent=true
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); backing.add_theme_stylebox_override("panel",UI.panel(UI.PALE,UI.LINE,8)); backing.mouse_filter=MOUSE_FILTER_IGNORE
	picture=Portrait.new(); picture.configure(character_id); add_child(picture); picture.show_behind_parent=true
	resized.connect(_layout); mouse_entered.connect(queue_redraw); mouse_exited.connect(queue_redraw); button_down.connect(queue_redraw); button_up.connect(queue_redraw)
	_layout()
func _layout() -> void:
	if not is_instance_valid(picture): return
	picture.position=Vector2(4,5); picture.size=Vector2(size.x-8,size.y-20)
	queue_redraw()
func _draw() -> void:
	var rim=UI.GOLD if selected or has_focus() else UI.LINE
	var plate_height=48 if large else 43
	var plate=Rect2(1,size.y-plate_height-1,size.x-2,plate_height)
	draw_style_box(UI.panel(Color("fffaf0"),Color("cfb98f"),5),plate)
	draw_style_box(UI.panel(Color.TRANSPARENT,rim,8),Rect2(1,1,size.x-2,size.y-2))
	var fs=16 if large else 12
	var width=UI.TITLE.get_string_size(display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	draw_string(UI.TITLE,Vector2((size.x-width)/2,plate.position.y+18),display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,UI.INK)
	var rfs=12 if large else 11
	width=UI.BODY.get_string_size(role,HORIZONTAL_ALIGNMENT_LEFT,-1,rfs).x
	draw_string(UI.BODY,Vector2((size.x-width)/2,plate.position.y+35),role,HORIZONTAL_ALIGNMENT_LEFT,-1,rfs,UI.MUTED)
	if is_hovered() or is_pressed(): draw_style_box(UI.panel(Color(1,1,1,.08),UI.GOLD,8),Rect2(1,1,size.x-2,size.y-2))
