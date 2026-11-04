extends RefCounted
## Approved B/C grammar shared by fixed and fluid screens.
const PAPER=Color("eee6d6")
const GROUND=PAPER
const PALE=Color("e4dac6")
const INK=Color("16130f")
const MUTED=Color("4e463b")
const QUIET=Color("7a6f60")
const LINE=Color(.086,.075,.059,.16)
const RED=Color("c9321d")
const ACTION_RED=RED
const DANGER=Color("8e1f12")
const BLUE=RED
const HP=RED
const MP=Color("2c3e63")
const GOLD=Color("9a7432")
const BODY=preload("res://assets/fonts/AbyssNotoText500.ttf")
const BOLD=preload("res://assets/fonts/AbyssNotoText800.ttf")
const DISPLAY=preload("res://assets/fonts/AbyssNotoBlackCondensed.ttf")
const TITLE=DISPLAY
const BRUSH=preload("res://assets/ui-r24/wash.png")
static func panel(bg=PAPER,border=LINE,_radius=0) -> StyleBoxFlat:
	var p=StyleBoxFlat.new();p.bg_color=bg;p.border_color=border;p.border_width_bottom=1;return p
static func brush_style() -> StyleBoxFlat:
	var p=panel(RED,RED);p.content_margin_left=14;p.content_margin_right=14;p.content_margin_top=10;p.content_margin_bottom=10;return p
static func dress_button(b: Button,selected=false) -> void:
	var direction=""
	for c in ["→","▶","▷","►","›"]:
		if b.text.contains(c):direction="arrow";b.text=b.text.replace(c,"").strip_edges()
	for c in ["←","◀","◁","◄","‹"]:
		if b.text.contains(c):direction="back";b.text=b.text.replace(c,"").strip_edges()
	if direction!="":
		b.icon=load(icon_path(direction));b.expand_icon=true;b.add_theme_constant_override("icon_max_width",18);b.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT if direction=="back" else HORIZONTAL_ALIGNMENT_RIGHT
	b.add_theme_font_override("font",BOLD);b.set_meta("r24_selected",selected)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var p=panel(PALE if state in ["hover","pressed"] else Color.TRANSPARENT,RED if selected else LINE);p.border_width_bottom=2 if selected else 1;p.content_margin_left=10;p.content_margin_right=10;p.content_margin_top=8;p.content_margin_bottom=8
		if state=="focus":p.set_border_width_all(2);p.border_color=INK
		b.add_theme_stylebox_override(state,p)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(state,INK)
	b.add_theme_color_override("font_disabled_color",QUIET)
	if selected:
		for state in ["normal","hover","pressed"]:
			var p=StyleBoxTexture.new();p.texture=preload("res://assets/ui-r24/selection.svg");p.texture_margin_bottom=2;p.content_margin_left=10;p.content_margin_right=10;p.content_margin_top=8;p.content_margin_bottom=8;b.add_theme_stylebox_override(state,p)
static func primary(b: Button) -> void:
	dress_button(b)
	for state in ["normal","hover","pressed"]:b.add_theme_stylebox_override(state,brush_style())
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(state,PAPER)
	b.set_meta("r24_primary",true)
static func rule(parent: Control,y: float,width: float,x=18.0) -> void:
	var c=ColorRect.new();parent.add_child(c);c.position=Vector2(x,y);c.size=Vector2(width,2);c.color=INK;c.mouse_filter=Control.MOUSE_FILTER_IGNORE
static func heading_rule(parent: Control) -> void:
	var c=ColorRect.new();parent.add_child(c);c.custom_minimum_size=Vector2(54,2);c.size=c.custom_minimum_size;c.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;c.color=INK;c.mouse_filter=Control.MOUSE_FILTER_IGNORE
static func icon_path(key: String) -> String:
	var n=key.trim_prefix("nav-").trim_prefix("pl-");n={"journal":"book","depart":"gate","town":"home","smith":"smithy","floor-star":"star","settings":"gear","arrow-right":"arrow","plus":"person"}.get(n,n)
	var path="res://assets/ui-r24/"+n+".svg";return path if ResourceLoader.exists(path) else "res://assets/ui-r24/chev.svg"
static func icon(parent: Node,key: String,rect: Rect2,color=INK) -> TextureRect:
	var t=TextureRect.new();parent.add_child(t);t.texture=load(icon_path(key));t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;t.position=rect.position;t.size=rect.size;t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new();material.shader=preload("res://ui/reskin_tint_r24.gdshader");material.set_shader_parameter("tint",color);t.material=material;return t
static func row_arrow(b: Button,_selected=false) -> void:
	for key in ["normal","hover","pressed","disabled","focus"]:
		var p=b.get_theme_stylebox(key).duplicate();p.content_margin_right=38;b.add_theme_stylebox_override(key,p)
	var t=icon(b,"chev",Rect2(0,0,18,18),QUIET);t.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT);t.offset_left=-30;t.offset_right=-12;t.offset_top=-9;t.offset_bottom=9
static func row_copy(b: Button,title: String,description="",_selected=false,left=10.0) -> void:
	if b.has_node("RowCopy"):
		var old=b.get_node("RowCopy");b.remove_child(old);old.queue_free()
	for key in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]:b.add_theme_color_override(key,Color.TRANSPARENT)
	var margin=MarginContainer.new();margin.name="RowCopy";b.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.offset_left=left;margin.offset_right=-38;margin.offset_top=9;margin.offset_bottom=-9;margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var stack=VBoxContainer.new();margin.add_child(stack);stack.add_theme_constant_override("separation",3);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for i in (1 if description.is_empty() else 2):
		var l=Label.new();stack.add_child(l);l.text=title if i==0 else description;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_override("font",BOLD if i==0 else BODY);l.add_theme_font_size_override("font_size",16 if i==0 else 13);l.add_theme_color_override("font_color",QUIET if b.disabled else INK if i==0 else MUTED);l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var fit=func():b.custom_minimum_size.y=maxf(48,margin.get_combined_minimum_size().y+18)
	margin.minimum_size_changed.connect(fit);fit.call()
static func dress_navigation(b: Button,key: String,selected=false) -> Control:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var p=panel(INK,RED);p.border_width_top=0;p.border_width_bottom=0;p.content_margin_left=0;p.content_margin_right=0
		if state=="focus":p.set_border_width_all(2);p.border_color=PAPER
		b.add_theme_stylebox_override(state,p)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(state,Color.TRANSPARENT)
	var color=PAPER if selected else Color("bdb3a2");var t=icon(b,{"town":"home","party":"party","depart":"gate","bag":"bag","journal":"book"}.get(key,key),Rect2(0,0,22,22),color)
	t.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);t.offset_left=-11;t.offset_right=11;t.offset_top=8;t.offset_bottom=30
	var l=Label.new();b.add_child(l);l.text=b.text;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.add_theme_font_override("font",BOLD);l.add_theme_font_size_override("font_size",11);l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);l.offset_top=-24;l.offset_bottom=-3
	if selected:
		var bar=ColorRect.new();b.add_child(bar);bar.color=RED;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;bar.anchor_left=.22;bar.anchor_right=.78;bar.offset_top=0;bar.offset_bottom=3;return bar
	return null
static func paper(parent: Control) -> void:
	var grain=TextureRect.new();parent.add_child(grain);grain.texture=preload("res://assets/ui-r24/paper-grain.png");grain.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;grain.stretch_mode=TextureRect.STRETCH_TILE;grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);grain.mouse_filter=Control.MOUSE_FILTER_IGNORE;grain.z_index=60
static func torn(parent: Control,y: float,width=390.0) -> void:
	var p=Polygon2D.new();parent.add_child(p);p.color=PAPER;p.position.y=y;var points=PackedVector2Array();points.append(Vector2(0,24))
	for i in 31:points.append(Vector2(width*i/30.0,[9,6,11,7,12,5,9][i%7]))
	points.append(Vector2(width,24));p.polygon=points
static func scroll_region(sc: ScrollContainer) -> void:
	sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;sc.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_RESERVE;sc.follow_focus=false;sc.add_theme_constant_override("separation",8)
static func inline_icons(node: Control) -> void:
	if not node is Label or not node.text.contains("★"):return
	var font=node.get_theme_font("font");var fs=node.get_theme_font_size("font_size");var copy=node.text;var rendered=""
	node.set_meta("source_copy_r24",copy)
	for c in copy:
		if c=="★":
			var x=font.get_string_size(rendered,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
			icon(node,"star",Rect2(x,maxf(0,(node.size.y-fs)/2),fs,fs),node.get_theme_color("font_color"));rendered+="   "
		else:rendered+=c
	node.text=rendered
static func make_theme() -> Theme:
	var t=Theme.new();t.default_font=BODY;t.default_font_size=14;t.set_color("font_color","Label",INK)
	for kind in ["Button","OptionButton","LineEdit","TextEdit"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			var p=panel(PALE if state in ["hover","pressed"] else PAPER,LINE);p.content_margin_left=10;p.content_margin_right=10;p.content_margin_top=8;p.content_margin_bottom=8
			if state=="focus":p.set_border_width_all(2);p.border_color=INK
			t.set_stylebox(state,kind,p)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:t.set_color(state,kind,INK)
		t.set_color("font_disabled_color",kind,QUIET);t.set_color("font_placeholder_color",kind,MUTED);t.set_color("caret_color",kind,RED);t.set_color("selection_color",kind,PALE)
	t.set_stylebox("panel","PopupMenu",panel());t.set_stylebox("hover","PopupMenu",panel(PALE));t.set_color("font_color","PopupMenu",INK)
	for state in ["grabber","grabber_highlight","grabber_pressed"]:
		var p=panel(QUIET,QUIET);p.content_margin_left=3;p.content_margin_right=3;t.set_stylebox(state,"VScrollBar",p)
	var track=panel(Color.TRANSPARENT,Color.TRANSPARENT);track.content_margin_left=4;track.content_margin_right=4;t.set_stylebox("scroll","VScrollBar",track)
	t.set_stylebox("background","ProgressBar",panel(PALE,PALE));t.set_stylebox("fill","ProgressBar",panel(MUTED,MUTED));return t
