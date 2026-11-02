extends RefCounted
const BODY = preload("res://assets/fonts/GowunBatang-Regular.ttf")
const TITLE = preload("res://assets/fonts/GowunBatang-Bold.ttf")
const GROUND = Color("edf3f8")
const PAPER = Color("fffdf8")
const PALE = Color("dce8f2")
const INK = Color("253c52")
const MUTED = Color("526b7e")
const BLUE = Color("355f80")
const GOLD = Color("8c6833")
const LINE = Color("bbcbd7")
const HP = Color("ad5855")
const MP = Color("477d9f")
static func panel(bg=PAPER, border=LINE, radius=8) -> StyleBoxFlat:
	var style=StyleBoxFlat.new(); style.bg_color=bg; style.border_color=border
	style.set_border_width_all(1); style.set_corner_radius_all(radius); style.anti_aliasing=true
	return style
static func make_theme() -> Theme:
	var t=Theme.new(); t.default_font=BODY; t.default_font_size=14
	t.set_color("font_color","Label",INK)
	for key in ["font_color","font_hover_color","font_pressed_color"]: t.set_color(key,"Button",INK)
	t.set_color("font_disabled_color","Button",Color("6d7d89"))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var p=panel(PALE if state=="pressed" else PAPER,GOLD if state=="focus" else LINE)
		p.content_margin_left=12; p.content_margin_right=12; p.content_margin_top=9; p.content_margin_bottom=9
		t.set_stylebox(state,"Button",p); t.set_stylebox(state,"OptionButton",p)
	t.set_stylebox("panel","PopupMenu",panel())
	t.set_color("font_color","PopupMenu",INK); t.set_color("font_hover_color","PopupMenu",INK)
	t.set_stylebox("hover","PopupMenu",panel(PALE,PALE,3))
	t.set_stylebox("scroll","VScrollBar",panel(GROUND,GROUND,3))
	t.set_stylebox("grabber","VScrollBar",panel(Color("a8becf"),Color("a8becf"),3))
	t.set_stylebox("grabber_highlight","VScrollBar",panel(BLUE,BLUE,3))
	t.set_stylebox("grabber_pressed","VScrollBar",panel(BLUE,BLUE,3))
	return t
