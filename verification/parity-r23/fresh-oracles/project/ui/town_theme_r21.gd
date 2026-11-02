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
