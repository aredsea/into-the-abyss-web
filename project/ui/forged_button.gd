extends Button
## Shared physical button material. Labels remain real Control text.
var emphasis=false
var active=false
var textured=true
var hover_amount=0.0
var plate: Texture2D
var surface: Node2D

func _ready() -> void:
	surface=Node2D.new(); surface.show_behind_parent=true; add_child(surface); surface.draw.connect(_paint)
	if ResourceLoader.exists("res://assets/ui-r4/forged-plate.png"):
		plate=load("res://assets/ui-r4/forged-plate.png")
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style=StyleBoxEmpty.new()
		style.content_margin_left=12; style.content_margin_right=12
		style.content_margin_top=8; style.content_margin_bottom=8
		add_theme_stylebox_override(state,style)
	mouse_entered.connect(queue_redraw); mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw); button_up.connect(queue_redraw)
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	var goal=1.0 if is_hovered() and not disabled else 0.0
	var next=move_toward(hover_amount,goal,delta*8)
	if next!=hover_amount: hover_amount=next; queue_redraw()

func _draw() -> void:
	if is_instance_valid(surface): surface.queue_redraw()

func _paint() -> void:
	var down=is_pressed() and not disabled
	var color=Color("343b3b") if down else Color("252d30")
	if emphasis: color=Color("4c402a") if down else Color("3c3324")
	var corners=PackedVector2Array([Vector2(6,0),Vector2(size.x-6,0),Vector2(size.x,6),Vector2(size.x,size.y-6),Vector2(size.x-6,size.y),Vector2(6,size.y),Vector2(0,size.y-6),Vector2(0,6)])
	surface.draw_colored_polygon(corners,color)
	if plate and textured: surface.draw_texture_rect(plate,Rect2(Vector2(2,2),size-Vector2(4,4)),false,Color(1,1,1,.4 if not emphasis else .55))
	var edge=Color("b79a62") if emphasis or active else Color("68716e")
	if disabled: edge=Color("424b4b")
	edge=edge.lerp(Color("e0c68c"),hover_amount*.65)
	var outline=corners.duplicate(); outline.append(corners[0]); surface.draw_polyline(outline,edge,1,true)
	surface.draw_line(Vector2(7,3),Vector2(size.x-7,3),Color(1,1,1,.04 if down else .15),1)
	surface.draw_line(Vector2(7,size.y-3),Vector2(size.x-7,size.y-3),Color(0,0,0,.65),2)
	if active: surface.draw_line(Vector2(12,size.y-5),Vector2(size.x-12,size.y-5),Color("d7b67e"),2)
	if has_focus(): surface.draw_rect(Rect2(Vector2(4,4),size-Vector2(8,8)),Color("e0c68c"),false,1)
