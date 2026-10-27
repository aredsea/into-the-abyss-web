extends Control
## Presentation only: no damage, resources, turn order or save mutations here.
signal impact
signal finished
const Sprite=preload("res://ui/character_sprite.gd")
const FONT=preload("res://assets/fonts/NanumGothic-Regular.ttf")
var character_id="hildegard"
var reduced=false
var preview=false
var elapsed=0.0
var duration=1.6
var impacted=false
var art: Dictionary
var figure: Control
var portrait: Control
var heading: Label
var tint=Color.WHITE
var phase="intro"
var fx_surface: Node2D

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE; clip_contents=true
	art=Sprite.info(character_id)
	assert(not art.is_empty(),"Missing character cinematic: "+character_id)
	tint={"ice":Color("a5dbe2"),"bolt":Color("e4cf8b"),"fire":Color("ef9d66"),"holy":Color("efe0ae"),"wind":Color("a4d6a5"),"dark":Color("bba0d4"),"none":Color("d4c6ad")}.get(art.element,Color.WHITE)
	duration=.7 if reduced else 2.0 if preview else 1.6
	portrait=Sprite.new(); portrait.portrait_mode=true; add_child(portrait); portrait.configure(character_id)
	figure=Sprite.new(); add_child(figure); figure.configure(character_id,true)
	heading=Label.new(); add_child(heading); heading.add_theme_font_override("font",FONT); heading.add_theme_font_size_override("font_size",16); heading.add_theme_color_override("font_color",tint); heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; heading.mouse_filter=MOUSE_FILTER_IGNORE
	heading.text=art.name+"  ·  "+art.skill
	fx_surface=Node2D.new(); add_child(fx_surface); fx_surface.draw.connect(_draw_fx)
	resized.connect(_layout); _layout(); _publish()

func _layout() -> void:
	if not is_instance_valid(figure): return
	heading.position=Vector2(12,8); heading.size=Vector2(size.x-24,44)
	portrait.position=Vector2(10,62); portrait.size=Vector2(size.x*.23,size.y-78)
	figure.size=Vector2(size.x*.57,size.y-64); figure.position=Vector2(size.x*.30,58)

func _process(delta: float) -> void:
	elapsed+=delta
	var t=elapsed/duration
	phase="intro" if t<.22 else "windup" if t<.42 else "impact" if t<.78 else "release"
	if not impacted and t>=.42:
		impacted=true; impact.emit()
	if not reduced:
		portrait.modulate.a=minf(1,t*7)
		var lunge=sin(clampf((t-.22)/.42,0,1)*PI)*12
		figure.position.x=size.x*.30+lunge
		figure.modulate.a=minf(1,t*5)
	modulate.a=clampf((1-t)*6,0,1)
	queue_redraw(); fx_surface.queue_redraw(); _publish()
	if elapsed>=duration:
		finished.emit(); queue_free()

func _publish() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__abyssSignature="+JSON.stringify({"id":character_id,"fx":art.fx,"phase":phase,"elapsed":elapsed,"duration":duration,"reduced":reduced,"preview":preview,"complete":elapsed>=duration})+";",true)

func _draw() -> void:
	if art.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),Color(.035,.055,.065,.93))
	draw_line(Vector2(0,0),Vector2(size.x,0),tint*.7,2)
	draw_line(Vector2(0,size.y-1),Vector2(size.x,size.y-1),Color("756a50"),1)
	draw_line(Vector2(size.x*.27,58),Vector2(size.x*.27,size.y-12),Color("756a50"),1)

func _draw_fx() -> void:
	if art.is_empty(): return
	var t=elapsed/duration
	if t<.2: return
	var p=clampf((t-.22)/.56,0,1)
	if reduced: p=.65
	var c=Vector2(size.x*.70,size.y*.54)
	var r=minf(size.x*.21,size.y*.31)
	var col=tint; col.a=.85
	match art.fx:
		"shelter":
			_shield(c,r*p,col); _rays(c,r*.8,p,4,col)
		"fox_brand":
			_arrow(c-Vector2(r*1.7,0),c+Vector2(r*.45,0),p,col)
			_seal(c+Vector2(r*.45,0),r*.4*p,3,col); _embers(c,r,p,col)
		"ice_nova":
			for i in range(8): _crystal(c+Vector2.from_angle(i*TAU/8)*r*p,10+18*p,i*TAU/8,col)
			fx_surface.draw_arc(c,r*p,0,TAU,32,col,2)
		"contract_wall":
			for i in range(3):
				var v=c+Vector2((i-1)*r*.6,-r*.4)
				fx_surface.draw_rect(Rect2(v,Vector2(r*.5,r*1.1*p)),col,false,2)
				for j in range(4): fx_surface.draw_line(v+Vector2(5,9+j*9),v+Vector2(r*.4,9+j*9),Color(col,.4),1)
		"wolf_roar":
			for i in range(3): fx_surface.draw_arc(c-Vector2(r,0),r*(p+i*.28),-.8,.8,18,col,3)
			_slash(c+Vector2(0,-r*.4),r*.6,p,.4,col)
		"crosscut":
			_slash(c,r,p,-.7,col); _slash(c,r,clampf(p*1.6-.3,0,1),.7,col)
		"shadow_snare":
			for i in range(5):
				var from=c+Vector2(-r,-r+i*r*.5); var to=c+Vector2(r,r-i*r*.5)
				fx_surface.draw_line(from,from.lerp(to,p),col,2)
			fx_surface.draw_arc(c,r*.7*p,0,TAU,20,col,2)
		"bolt_pierce":
			_arrow(c-Vector2(r*1.8,0),c+Vector2(r*.85,0),p,col)
			for i in range(2): fx_surface.draw_arc(c+Vector2(i*r*.65,0),r*.25,0,TAU,12,Color(col,p),2)
		"three_curses":
			for i in range(3): _seal(c+Vector2.from_angle(-PI/2+i*TAU/3)*r*.6,r*.33*p,3+i,col)
		"void_charge":
			for i in range(4): fx_surface.draw_arc(c,r*(1-p*.6)+i*5,elapsed*3+i,elapsed*3+i+PI*1.4,26,Color(col,.7),2)
			fx_surface.draw_circle(c,8+16*p,Color("34283f")); _rays(c,r,p,6,col)
		"ice_amplify":
			_crystal(c,r*.8*p,0,col)
			for i in range(2): _chevron(c+Vector2(0,r*.6-i*18-p*28),16,col)
		"sanctuary":
			_dome(c,r,p,col)
			for i in range(4): _cross(c+Vector2((i-1.5)*r*.45,r*.5-p*20),7,col)
		"antidote":
			_vial(c,r*.4,col); _bubbles(c,r,p,col)
			for i in range(3): fx_surface.draw_line(c+Vector2(-r*.5,r*(i*.3-.5)),c+Vector2(-r*.5-15*p,r*(i*.3-.5)),col,2)
		"sap_rain":
			for i in range(12):
				var v=c+Vector2((i%4-1.5)*r*.45,(i/4.0-1)*r*.5+p*40)
				fx_surface.draw_line(v,v+Vector2(-3,10),col,3)
			fx_surface.draw_arc(c+Vector2(0,r*.7),r*.8,0,PI,22,col,2)
		"flame_combo":
			_slash(c-Vector2(12,0),r,p,-.7,col); _slash(c+Vector2(12,0),r,clampf(p*1.6-.4,0,1),.5,col); _embers(c,r,p,col)
		"thunder_sigil":
			_seal(c+Vector2(0,-r*.6),r*.45,6,col)
			for i in range(3): _bolt(c+Vector2((i-1)*20,-r),r*1.7*p,col)
		"frost_guard":
			_shield(c,r*.8,col)
			for i in range(5): _crystal(c+Vector2((i-2)*r*.35,r*.5),12+24*p,0,col)
		"triage":
			_cross(c,r*.5*p,col)
			for i in range(2): fx_surface.draw_arc(c,r*(.7+i*.22),p*TAU+i,p*TAU+i+PI,20,col,3)
		"command_strike":
			_slash(c,r*1.2,p,PI/2,col); _shards(c+Vector2(0,r*.6),r,p,7,col)
		"blink_slash":
			for i in range(3): fx_surface.draw_line(c+Vector2(-r-i*12,-15+i*15),c+Vector2(r*p,-15+i*15),Color(col,(3-i)*.22),3)
			_slash(c+Vector2(r*.5,0),r*.8,p,-.8,col)
		"flask_network":
			for i in range(4):
				var v=c+Vector2.from_angle(i*TAU/4)*r*.7; fx_surface.draw_line(c,v*p+c*(1-p),Color(col,.4),2); _vial(v,12,col)
		"silence_seal":
			_seal(c,r*.8*p,8,col); fx_surface.draw_line(c-Vector2(r*.55,0),c+Vector2(r*.55,0),col,5)
		"execution":
			fx_surface.draw_arc(c-Vector2(0,r*.3),r,-PI*.9,-PI*.9+p*PI*1.6,32,col,6); _shards(c+Vector2(0,r*.6),r,p,5,col)
		"root_arrow":
			_arrow(c-Vector2(r*1.5,0),c+Vector2(r*.6,0),p,col)
			for i in range(5):
				var root=c+Vector2((i-2)*r*.35,r*.7); fx_surface.draw_line(root,root-Vector2(8,r*p),col,3); fx_surface.draw_line(root-Vector2(4,r*p*.5),root+Vector2(10,-r*p*.7),col,2)
		"fire_sweep":
			_slash(c,r*1.2,p,.05,col)
			for i in range(7): _embers(c+Vector2((i-3)*r*.25,0),18,p,col)
		"contract_interest":
			for i in range(3):
				var v=c+Vector2.from_angle(i*TAU/3+elapsed)*r*(1-p*.6); _seal(v,12,4,col); fx_surface.draw_line(v,c,Color(col,.5),1)
		"stamp_bolt":
			var q=Rect2(c-Vector2(r*.55,r*.55),Vector2.ONE*r*1.1); fx_surface.draw_rect(q,col,false,3); _seal(c,r*.35,4,col); _bolt(c-Vector2(0,r*.9),r*1.8*p,col)
		"ice_challenge":
			_slash(c,r,p,PI/2,col); fx_surface.draw_arc(c,r*.85*p,0,TAU,32,col,2)
			for i in range(4): _crystal(c+Vector2.from_angle(i*PI/2)*r*.8,17,PI/2*i,col)
		"infusion":
			_vial(c-Vector2(r*.4,0),20,col); _bubbles(c,r,p,col)
			for i in range(3): _chevron(c+Vector2(r*.3+i*14,p*-20),10,col)
		"prayer_guard":
			_dome(c,r,p,col); _seal(c-Vector2(0,r*.55),r*.28,8,col)
			fx_surface.draw_polyline(PackedVector2Array([c+Vector2(-25,5),c+Vector2(0,13),c+Vector2(25,5)]),col,3)
			fx_surface.draw_line(c+Vector2(0,13),c+Vector2(0,38),col,2)

func _cross(c: Vector2,r: float,col: Color) -> void:
	fx_surface.draw_line(c-Vector2(r,0),c+Vector2(r,0),col,4); fx_surface.draw_line(c-Vector2(0,r),c+Vector2(0,r),col,4)

func _shield(c: Vector2,r: float,col: Color) -> void:
	var pts=PackedVector2Array([c+Vector2(-r*.6,-r*.6),c+Vector2(0,-r),c+Vector2(r*.6,-r*.6),c+Vector2(r*.5,r*.3),c+Vector2(0,r),c+Vector2(-r*.5,r*.3),c+Vector2(-r*.6,-r*.6)])
	fx_surface.draw_colored_polygon(pts,Color(col,.12)); fx_surface.draw_polyline(pts,col,3); fx_surface.draw_line(c-Vector2(0,r*.7),c+Vector2(0,r*.6),col,2)

func _seal(c: Vector2,r: float,n: int,col: Color) -> void:
	var pts=PackedVector2Array()
	for i in range(n+1): pts.append(c+Vector2.from_angle(i*TAU/n-PI/2)*r)
	fx_surface.draw_polyline(pts,col,2); fx_surface.draw_arc(c,r*.6,0,TAU,20,col,1)

func _crystal(c: Vector2,r: float,rot: float,col: Color) -> void:
	var pts=PackedVector2Array()
	for v in [Vector2(0,-r),Vector2(r*.3,0),Vector2(0,r*.7),Vector2(-r*.3,0),Vector2(0,-r)]: pts.append(c+v.rotated(rot))
	fx_surface.draw_colored_polygon(pts,Color(col,.23)); fx_surface.draw_polyline(pts,col,2)

func _slash(c: Vector2,r: float,p: float,rot: float,col: Color) -> void:
	var v=Vector2.from_angle(rot)*r
	fx_surface.draw_line(c-v,c-v+v*2*p,col,5); fx_surface.draw_line(c-v+Vector2(0,5),c-v+v*2*p+Vector2(0,5),Color(col,.3),3)

func _arrow(a: Vector2,b: Vector2,p: float,col: Color) -> void:
	var end=a.lerp(b,p); fx_surface.draw_line(end-Vector2(45,0),end,col,3); fx_surface.draw_polyline(PackedVector2Array([end-Vector2(8,5),end,end-Vector2(8,-5)]),col,2)

func _rays(c: Vector2,r: float,p: float,n: int,col: Color) -> void:
	for i in range(n):
		var v=Vector2.from_angle(i*TAU/n); fx_surface.draw_line(c+v*r*.5,c+v*r*(.5+p),col,2)

func _shards(c: Vector2,r: float,p: float,n: int,col: Color) -> void:
	for i in range(n):
		var v=Vector2.from_angle(-PI+i*PI/(n-1)); fx_surface.draw_line(c+v*r*p*.3,c+v*r*p,col,3)

func _embers(c: Vector2,r: float,p: float,col: Color) -> void:
	for i in range(5):
		var v=c+Vector2((i-2)*r*.22,-p*r*.8+sin(i*2.1+p*3)*r*.2)
		fx_surface.draw_colored_polygon(PackedVector2Array([v-Vector2(0,8),v+Vector2(4,2),v+Vector2(0,6),v-Vector2(4,-2)]),Color(col,.7))

func _dome(c: Vector2,r: float,p: float,col: Color) -> void:
	fx_surface.draw_arc(c+Vector2(0,r*.6),r*p,PI,TAU,36,col,3); fx_surface.draw_line(c+Vector2(-r,r*.6),c+Vector2(r,r*.6),col,2)

func _vial(c: Vector2,r: float,col: Color) -> void:
	fx_surface.draw_arc(c+Vector2(0,5),r,0,TAU,20,col,2); fx_surface.draw_rect(Rect2(c-Vector2(r*.3,r),Vector2(r*.6,r*.6)),col,false,2); fx_surface.draw_line(c+Vector2(-r*.7,8),c+Vector2(r*.7,8),col,3)

func _bubbles(c: Vector2,r: float,p: float,col: Color) -> void:
	for i in range(6): fx_surface.draw_arc(c+Vector2(sin(i*3.7)*r*.6,r*.5-p*r*1.6+i*6),3+i%3,0,TAU,10,Color(col,.7),1)

func _bolt(c: Vector2,r: float,col: Color) -> void:
	fx_surface.draw_polyline(PackedVector2Array([c,c+Vector2(-9,r*.38),c+Vector2(10,r*.3),c+Vector2(-4,r)]),col,3)

func _chevron(c: Vector2,r: float,col: Color) -> void:
	fx_surface.draw_polyline(PackedVector2Array([c+Vector2(-r,r*.5),c,c+Vector2(r,r*.5)]),col,3)
