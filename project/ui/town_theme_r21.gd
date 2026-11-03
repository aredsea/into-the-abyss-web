extends RefCounted
const PAPER=Color("f4efe3")
const INK=Color("111715")
const RED=Color("d83219")
const MUTED=Color("62665d")
const LINE=Color("b8b8ab")
const BODY=preload("res://assets/fonts/AbyssNotoText500.ttf")
const BOLD=preload("res://assets/fonts/AbyssTextR19W850.ttf")
const DISPLAY=preload("res://assets/fonts/AbyssDisplayR19.ttf")
const TITLE=DISPLAY
const GROUND=PAPER
const GOLD=RED
const PALE=Color("e6dfcf")
const BLUE=RED
const HP=RED
const MP=Color("197ab7")
const ACTION_RED=Color("c62b15")
const BRUSH=preload("res://assets/ui-r21/button-ink.svg")

## Authored town colors and brush, shared by the fluid form and cloud screens.
## Kept opt-in so the approved fixed town/battle layouts do not change.
static func brush_style() -> StyleBoxTexture:
	var p=StyleBoxTexture.new();p.texture=BRUSH
	p.modulate_color=Color(ACTION_RED.r/RED.r,ACTION_RED.g/RED.g,ACTION_RED.b/RED.b)
	p.content_margin_left=12;p.content_margin_right=12;p.content_margin_top=10;p.content_margin_bottom=10
	return p

static func dress_button(b: Button,selected=false) -> void:
	b.add_theme_font_override("font",BOLD)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var p=panel(PALE if state in ["hover","pressed"] else PAPER,INK)
		p.set_border_width_all(0);p.border_width_bottom=3
		p.content_margin_left=12;p.content_margin_right=12;p.content_margin_top=10;p.content_margin_bottom=10
		if state=="focus":p.set_border_width_all(2);p.border_color=ACTION_RED
		b.add_theme_stylebox_override(state,p)
	if selected:
		for state in ["normal","hover","pressed"]:b.add_theme_stylebox_override(state,brush_style())
		for state in ["font_color","font_hover_color","font_pressed_color"]:b.add_theme_color_override(state,PAPER)

static func rule(parent: Control,y: float,width: float,x=18.0) -> void:
	var line=ColorRect.new();parent.add_child(line);line.position=Vector2(x,y);line.size=Vector2(width,2);line.color=INK;line.mouse_filter=Control.MOUSE_FILTER_IGNORE

static func heading_rule(parent: Control) -> void:
	var line=ColorRect.new();parent.add_child(line);line.custom_minimum_size=Vector2(54,4);line.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;line.color=RED;line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	line.size=line.custom_minimum_size

## Opt-in treatment for the remaining fluid panels; action text and callbacks stay native.
static func row_arrow(b: Button,selected=false) -> void:
	for key in ["normal","hover","pressed","disabled","focus"]:
		var p=b.get_theme_stylebox(key).duplicate();p.content_margin_right=42;b.add_theme_stylebox_override(key,p)
	var arrow=Label.new();b.add_child(arrow);arrow.text="→";arrow.add_theme_font_override("font",BOLD);arrow.add_theme_font_size_override("font_size",24);arrow.add_theme_color_override("font_color",MUTED if b.disabled else PAPER if selected else INK);arrow.mouse_filter=Control.MOUSE_FILTER_IGNORE
	arrow.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE);arrow.offset_left=-34;arrow.offset_right=-10;arrow.vertical_alignment=VERTICAL_ALIGNMENT_CENTER

static func row_copy(b: Button,title: String,description="",selected=false,left=12.0) -> void:
	if b.has_node("RowCopy"):
		var old=b.get_node("RowCopy");b.remove_child(old);old.queue_free()
	for key in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]:b.add_theme_color_override(key,Color.TRANSPARENT)
	var margin=MarginContainer.new();margin.name="RowCopy";b.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.offset_left=left;margin.offset_right=-42;margin.offset_top=10;margin.offset_bottom=-10;margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var stack=VBoxContainer.new();margin.add_child(stack);stack.add_theme_constant_override("separation",4);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for i in (1 if description.is_empty() else 2):
		var label=Label.new();stack.add_child(label);label.text=title if i==0 else description;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_override("font",BOLD if i==0 else BODY);label.add_theme_font_size_override("font_size",18 if i==0 else 13);label.add_theme_color_override("font_color",MUTED if b.disabled else PAPER if selected else INK if i==0 else MUTED);label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var fit=func():b.custom_minimum_size.y=maxf(52,margin.get_combined_minimum_size().y+20)
	margin.minimum_size_changed.connect(fit);fit.call()

static func dress_navigation(b: Button,key: String,selected=false) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var p=panel(PALE if state in ["hover","pressed"] else PAPER,RED if selected else INK);p.set_border_width_all(0);p.border_width_bottom=3 if selected else 0;p.content_margin_left=2;p.content_margin_right=2;p.content_margin_top=2;p.content_margin_bottom=2
		if state=="focus":p.set_border_width_all(2)
		b.add_theme_stylebox_override(state,p)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(state,Color.TRANSPARENT)
	var col=VBoxContainer.new();b.add_child(col);col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);col.mouse_filter=Control.MOUSE_FILTER_IGNORE;col.add_theme_constant_override("separation",2)
	var icon=TextureRect.new();col.add_child(icon);icon.texture=load("res://assets/ui-r21/nav-"+{"town":"home","party":"party","depart":"gate","bag":"bag","journal":"journal"}[key]+".svg");icon.custom_minimum_size=Vector2(24,24);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.modulate=ACTION_RED if selected else INK;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var caption=Label.new();col.add_child(caption);caption.text=b.text;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_font_override("font",BOLD);caption.add_theme_font_size_override("font_size",12);caption.add_theme_color_override("font_color",ACTION_RED if selected else INK);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE

static func panel(bg=PAPER,border=LINE,_radius=0) -> StyleBoxFlat:
	var p=StyleBoxFlat.new(); p.bg_color=bg; p.border_color=border; p.set_border_width_all(1)
	return p

static func make_theme() -> Theme:
	var t=Theme.new(); t.default_font=BODY; t.default_font_size=14
	t.set_color("font_color","Label",INK)
	for kind in ["Button","OptionButton"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			var p=panel(Color("e6dfcf") if state in ["hover","pressed"] else PAPER,RED if state=="focus" else LINE)
			p.content_margin_left=10; p.content_margin_right=10; p.content_margin_top=8; p.content_margin_bottom=8
			if state=="focus": p.set_border_width_all(2)
			t.set_stylebox(state,kind,p)
		for state in ["font_color","font_hover_color","font_pressed_color"]: t.set_color(state,kind,INK)
		t.set_color("font_disabled_color",kind,MUTED)
	t.set_stylebox("panel","PopupMenu",panel())
	t.set_stylebox("hover","PopupMenu",panel(Color("e6dfcf")))
	t.set_color("font_color","PopupMenu",INK)
	for state in ["grabber","grabber_highlight","grabber_pressed"]: t.set_stylebox(state,"VScrollBar",panel(MUTED,MUTED))
	t.set_stylebox("scroll","VScrollBar",panel(PAPER,PAPER))
	return t
