extends Control
## Presentation only. The caller owns resource values; this never writes a unit/save.
const RED=Color("c9321d")
const LOW=Color("8e1f12")
const TRAIL=Color("f0b9a8")
const PAPER=Color("e6dfcf")
const INK=Color("141414")
const MUTED=Color("6d665c")
const MP=Color("2f5f7f")
const MP_TRACK=Color("9fb9c9")
const DIGITS=preload("res://assets/fonts/AbyssNotoBlackCondensed.ttf")
const TEXT=preload("res://assets/fonts/AbyssNotoText800.ttf")
var current=0.0
var maximum=1.0
var shield=0.0
var hp=true
var reduced=false
var thresholds: Array=[]
var journal: Dictionary={}
# Authored, deterministic brush contour. Shared by track, fill, trail and hatching.
const TOP=[.10,.03,.12,.01,.08,.06,.01,.08,.00,.07,.01,.02,.07,.13,.02,.04,.10,.15,.09,.06,.15,.00,.13,.04,.02,.02,.05,.13,.03,.09,.10,.06,.09,.01,.01,.03,.11,.07,.05,.09,.07,.05,.12,.11,.04,.09,.08,.14,.11,.04,.15]
const BOTTOM=[.96,.97,.98,.84,.86,.95,.94,.96,.86,.87,.86,.91,.93,.98,.86,.94,.96,.98,.88,.99,.98,.98,.93,.99,.90,.94,.96,.87,.84,.90,.89,.99,.89,.93,.85,.87,.93,.90,.90,.89,.95,.86,.91,.88,.90,.99,.92,.98,.88,.94,.98]

static func now() -> float: return Time.get_ticks_msec()/1000.0

static func trail_at(entry: Dictionary,at: float) -> float:
	var t=clampf((at-float(entry.get("at",at))-.4)/.25,0,1)
	return lerpf(float(entry.get("from",entry.get("value",0))),float(entry.get("value",0)),1-pow(1-t,3))

static func observe(history: Dictionary,key: String,value: float,reduced_motion: bool,at: float=-1) -> Dictionary:
	if at<0: at=now()
	var old: Dictionary=history.get(key,{"value":value,"from":value,"at":at})
	if old.value!=value:
		var previous=maxf(float(old.value),trail_at(old,at))
		old={"value":value,"from":previous if value<float(old.value) and value>0 and not reduced_motion else value,"at":at}
	if reduced_motion or value<=0: old.from=value
	history[key]=old
	return old

static func attach(parent: Node,rect: Rect2,value: float,limit: float,is_hp=true,protection=0.0,entry: Dictionary={},reduced_motion=false,notches: Array=[]) -> Control:
	var node=load("res://ui/resource_gauge_r24.gd").new()
	node.current=value;node.maximum=limit;node.hp=is_hp;node.shield=protection;node.journal=entry;node.reduced=reduced_motion;node.thresholds=notches
	parent.add_child(node);node.position=rect.position;node.size=rect.size
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.set_process(is_hp and not entry.is_empty() and not reduced_motion)
	return node

static func numbers(parent: Node,rect: Rect2,value: float,limit: float,is_hp=true,protection=0.0,large=20) -> Control:
	var row=Control.new();parent.add_child(row);row.position=rect.position;row.size=rect.size;row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var specs=[["HP" if is_hp else "MP",TEXT,9,MUTED],[str(int(value)),DIGITS,large,RED if is_hp and value>0 and value/maxf(1,limit)<=.25 else INK],["/"+str(int(limit))+(" +"+str(int(protection)) if protection>0 else ""),TEXT,10,MUTED]]
	var widths=[];var total=0.0
	for spec in specs:
		var width=spec[1].get_string_size(spec[0],HORIZONTAL_ALIGNMENT_LEFT,-1,spec[2]).x+1
		widths.append(width);total+=width
	var value_width=widths[1]+widths[2]+2
	var available=maxf(1,rect.size.x-widths[0]-3)
	var k=minf(1,available/value_width)
	var x=maxf(widths[0]+3,rect.size.x-value_width*k)
	for i in range(3):
		var spec=specs[i];var l=Label.new();row.add_child(l);l.text=spec[0];l.mouse_filter=Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_override("font",spec[1]);l.add_theme_font_size_override("font_size",spec[2]);l.add_theme_color_override("font_color",spec[3]);l.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
		l.size=Vector2(widths[i],rect.size.y);l.position=Vector2(0 if i==0 else x,0)
		if i>0:l.scale.x=k;x+=widths[i]*k+1
	row.set_meta("resource_values",{"current":value,"maximum":limit,"shield":protection})
	return row

func _process(_delta: float) -> void:
	queue_redraw()
	if now()-float(journal.get("at",0))>=.65:set_process(false)

func contour() -> PackedVector2Array:
	var points=PackedVector2Array()
	for i in range(TOP.size()):points.append(Vector2(size.x*i/50.0,size.y*TOP[i]))
	for i in range(BOTTOM.size()-1,-1,-1):points.append(Vector2(size.x*i/50.0,size.y*BOTTOM[i]))
	return points

func _segment(left: float,right: float,color: Color) -> void:
	left=clampf(left,0,size.x);right=clampf(right,0,size.x)
	if right<=left:return
	var clip=PackedVector2Array([Vector2(left,0),Vector2(right,0),Vector2(right,size.y),Vector2(left,size.y)])
	for polygon in Geometry2D.intersect_polygons(contour(),clip):draw_colored_polygon(polygon,color)

func _draw() -> void:
	var ratio=clampf(current/maxf(1,maximum),0,1)
	if not hp:
		draw_rect(Rect2(Vector2.ZERO,size),MP_TRACK)
		draw_rect(Rect2(0,0,size.x*ratio,size.y),MP)
		return
	_segment(0,size.x,PAPER)
	var trail=current if journal.is_empty() or reduced or current<=0 else trail_at(journal,now())
	_segment(0,size.x*clampf(trail/maxf(1,maximum),0,1),TRAIL)
	_segment(0,size.x*ratio,LOW if ratio<=.25 else RED)
	var shield_end=minf(size.x,size.x*(current+maxf(0,shield))/maxf(1,maximum))
	if current>0 and shield_end>size.x*ratio:
		_segment(size.x*ratio,shield_end,Color("fffdf8"))
		var region=PackedVector2Array([Vector2(size.x*ratio,0),Vector2(shield_end,0),Vector2(shield_end,size.y),Vector2(size.x*ratio,size.y)])
		for x in range(int(size.x*ratio-size.y),ceili(shield_end)+1,5):
			var stripe=PackedVector2Array([Vector2(x,0),Vector2(x+2,0),Vector2(x+2+size.y,size.y),Vector2(x+size.y,size.y)])
			for part in Geometry2D.intersect_polygons(stripe,region):
				for polygon in Geometry2D.intersect_polygons(part,contour()):draw_colored_polygon(polygon,Color("a69f92"))
	for tick in [.25,.5,.75]:_segment(size.x*tick-.4,size.x*tick+.4,Color(0.08,.08,.08,.55))
	for tick in thresholds:_segment(size.x*float(tick)-1.5,size.x*float(tick)+1.5,INK)
