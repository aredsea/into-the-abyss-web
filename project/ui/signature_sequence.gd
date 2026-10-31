extends Control
## Shared by all 30 companions and the existing world preview. Presentation only.
signal impact
signal finished
const Sprite=preload("res://ui/battle_body_r18.gd")
const Face=preload("res://ui/battle_face_r17.gd")
const FX=preload("res://ui/combat_fx.gd")
const FONT=preload("res://assets/fonts/AbyssNotoBlackCondensed.ttf")
const PAPER=Color("f3efe3")
const INK=Color("111715")
const RED=Color("d93217")
var character_id="hildegard"
var reduced=false
var preview=false
var elapsed=0.0
var externally_timed=false
var duration=1.65
var contact_at=1.10
var impacted=false
var art: Dictionary
var portrait: Control
var heading: Label
var byline: Label
var tint=Color.WHITE
var phase="intro"
var source=Rect2()
var targets: Array=[]
var face_rect=Rect2()
var title_rect=Rect2()
var byline_rect=Rect2()
var preview_body: Control
func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE; clip_contents=true
	art=Sprite.info(character_id); tint=FX.color_for(art.element)
	if reduced: duration=.36; contact_at=.12
	portrait=Face.new(); add_child(portrait); portrait.configure(character_id)
	heading=Label.new(); add_child(heading)
	heading.add_theme_font_override("font",FONT); heading.add_theme_color_override("font_color",PAPER)
	heading.mouse_filter=MOUSE_FILTER_IGNORE
	byline=Label.new(); add_child(byline); byline.add_theme_font_override("font",FONT)
	byline.add_theme_font_size_override("font_size",14); byline.add_theme_color_override("font_color",PAPER); byline.mouse_filter=MOUSE_FILTER_IGNORE
	heading.text=art.skill
	byline.text=art.name+" · "+{"ice":"빙결","bolt":"전격","fire":"화염","holy":"신성","wind":"바람","dark":"암흑","none":"무속성"}.get(art.element,art.element)
	if preview:
		preview_body=Sprite.new(); preview_body.battle_pixels=true; preview_body.configure(character_id,true); add_child(preview_body); move_child(preview_body,0)
	resized.connect(_layout); _layout(); refresh()
func _layout() -> void:
	if not is_instance_valid(heading): return
	var cy=roundf(size.y*.46)
	face_rect=Rect2(12,cy-52,110,104)
	portrait.position=face_rect.position; portrait.size=face_rect.size
	title_rect=Rect2(140,cy-25,maxf(80,size.x-152),82)
	byline_rect=Rect2(140,cy-50,title_rect.size.x,20)
	var fs=30
	while fs>24 and FONT.get_string_size(art.skill,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>title_rect.size.x*1.8: fs-=1
	var lines=""; var row=""
	for ch in art.skill:
		if FONT.get_string_size(row+ch,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>title_rect.size.x and not row.is_empty(): lines+=row+"\n"; row=""
		row+=ch
	heading.text=lines+row; heading.add_theme_font_size_override("font_size",fs)
	heading.position=title_rect.position; heading.size=title_rect.size
	byline.position=byline_rect.position; byline.size=byline_rect.size
	if preview:
		preview_body.size=Vector2(180,160); preview_body.position=Vector2(0,size.y-164)
		source=Rect2(preview_body.position,preview_body.size); targets=[Rect2(size.x*.64,size.y*.24,size.x*.28,size.y*.6)]
func _process(delta: float) -> void:
	if externally_timed: return
	elapsed+=delta; refresh()
	if not impacted and elapsed>=contact_at: impacted=true; impact.emit()
	if elapsed>=duration: finished.emit(); queue_free()
func refresh() -> void:
	phase="intro" if elapsed<.6 and not reduced else "windup" if elapsed<contact_at*.8 else "impact" if elapsed<contact_at+.2 else "release"
	var active=elapsed<(.12 if reduced else .6)
	portrait.visible=active; heading.visible=active; byline.visible=active
	if is_instance_valid(preview_body): preview_body.visible=not active
	if active:
		var shift=0.0 if reduced else size.x*pow(1-clampf(elapsed/.16,0,1),3)
		if not reduced and elapsed>.48: shift=-size.x*clampf((elapsed-.48)/.12,0,1)
		portrait.position=face_rect.position+Vector2(shift,0)
		heading.position=title_rect.position+Vector2(shift,0); byline.position=byline_rect.position+Vector2(shift,0)
	queue_redraw(); _publish()
func _draw() -> void:
	if art.is_empty(): return
	if elapsed<(.12 if reduced else .6):
		var shift=0.0 if reduced else size.x*pow(1-clampf(elapsed/.16,0,1),3)
		if not reduced and elapsed>.48: shift=-size.x*clampf((elapsed-.48)/.12,0,1)
		# New seeded brush silhouettes; the text interior stays solid and clear.
		var shapes=band_polygons()
		for i in range(shapes.size()):
			var points=PackedVector2Array()
			for p in shapes[i]: points.append(p+Vector2(shift,0))
			draw_colored_polygon(points,RED if i==0 else INK)
		# Paper keyline gives original face crop a clean boundary.
		draw_rect(Rect2(portrait.position-Vector2.ONE*2,portrait.size+Vector2.ONE*4),PAPER)
	elif not externally_timed:
		FX.paint(self,art.element,art.fx,elapsed,contact_at,duration,source,targets,reduced,true,Rect2(Vector2.ZERO,size))
func band_polygons() -> Array:
	var cy=roundf(size.y*.46); var rng=RandomNumberGenerator.new(); rng.seed=18031
	var shapes=[]
	for layer in range(2):
		var points=PackedVector2Array(); var half=88 if layer==0 else 76
		for x in range(-24,int(size.x)+49,12): points.append(Vector2(x,cy-half-x*.035+rng.randi_range(-7,4)))
		for x in range(int(size.x)+48,-25,-12): points.append(Vector2(x,cy+half-x*.035+rng.randi_range(-4,7)))
		shapes.append(points)
	return shapes
func _publish() -> void:
	if OS.has_feature("web"): JavaScriptBridge.eval("window.__abyssSignature="+JSON.stringify({"id":character_id,"fx":art.fx,"phase":phase,"elapsed":elapsed,"duration":duration,"reduced":reduced,"preview":preview,"complete":elapsed>=duration})+";",true)
