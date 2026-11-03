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
