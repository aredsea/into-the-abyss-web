extends Button
## Porcelain secondary, blue enamel primary, light navigation.
const UI=preload("res://ui/fantasy_theme.gd")
var emphasis=false:
	set(value):
		emphasis=value
		var ink=UI.PAPER if value else UI.INK
		for state in ["font_color","font_hover_color","font_pressed_color"]: add_theme_color_override(state,ink)
		queue_redraw()
var active=false
var textured=true
var navigation=false
var hover_amount=0.0
var surface: Control
func _ready() -> void:
	surface=Control.new(); surface.mouse_filter=MOUSE_FILTER_IGNORE; surface.show_behind_parent=true; add_child(surface)
	surface.draw.connect(_draw_surface)
	add_theme_font_override("font",UI.TITLE)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var s=StyleBoxEmpty.new(); s.content_margin_left=12; s.content_margin_right=12; s.content_margin_top=8; s.content_margin_bottom=8
		add_theme_stylebox_override(state,s)
	var ink=UI.PAPER if emphasis else UI.INK
	for state in ["font_color","font_hover_color","font_pressed_color"]: add_theme_color_override(state,ink)
	add_theme_color_override("font_disabled_color",UI.MUTED)
	resized.connect(queue_redraw); mouse_entered.connect(queue_redraw); mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw); button_up.connect(queue_redraw)
func _process(delta: float) -> void:
	var goal=1.0 if is_hovered() and not disabled else 0.0
	var next=move_toward(hover_amount,goal,delta*8)
	if next!=hover_amount: hover_amount=next; queue_redraw()
func _draw() -> void:
	if is_instance_valid(surface): surface.queue_redraw()
func _draw_surface() -> void:
	var down=is_pressed() and not disabled
	var bg=UI.BLUE if emphasis else UI.PALE if active else UI.PAPER
	if disabled: bg=Color("e3e8eb")
	elif down: bg=bg.darkened(.06)
	elif not emphasis: bg=bg.lerp(Color("e9f1f7"),hover_amount*.65)
	if navigation:
		if active: surface.draw_style_box(UI.panel(UI.PALE,UI.PALE,8),Rect2(2,2,size.x-4,size.y-4))
		if active: surface.draw_line(Vector2(size.x*.28,size.y-3),Vector2(size.x*.72,size.y-3),UI.BLUE,2,true)
	else:
		var rect=Rect2(1,2 if down else 1,size.x-2,size.y-3)
		surface.draw_style_box(UI.panel(bg,UI.GOLD if emphasis else UI.LINE,7),rect)
		if emphasis: surface.draw_style_box(UI.panel(Color.TRANSPARENT,Color("bda778"),4),rect.grow(-4))
	if has_focus(): surface.draw_style_box(UI.panel(Color.TRANSPARENT,UI.BLUE,5),Rect2(4,4,size.x-8,size.y-8))
