extends Control
## Source name selection and local availability are separate contracts.
const R=preload("res://game/panels_rules_r22.gd")
const T=preload("res://ui/town_theme_r21.gd")
var texture: Texture2D
var initial=""
var selection={}
static func matches(value: String,pattern: String) -> bool:
	var r=RegEx.new();r.compile(pattern);return r.search(value)!=null
static func pick(id: String,variant="default",have: Variant=null,expr: Dictionary={},enabled=false,hidden=false) -> String:
	if hidden or not matches(id,"^[a-z0-9]+$"):return ""
	if have==null:have=R.DATA.have
	var name=id+"_portrait_"+variant
	if matches(variant,"^[a-z_]+$") and (have.get(name,false) or (enabled and expr.get(name,false))):return name
	name=id+"_portrait_default"
	return name if have.get(name,false) or (enabled and expr.get(name,false)) else ""
static func resolve(id: String,variant="default") -> Dictionary:
	var name=pick(id,variant);var path=""
	if name!="":
		# Only approved r21 files are eligible. Never request a similar person's art.
		var exact="res://assets/portraits-r21/"+name+".png"
		if ResourceLoader.exists(exact):path=exact
		else:
			for candidate in ["res://assets/portraits-r21-web/slots/"+id+"-detail-overview.tres","res://assets/portraits-r21/slots/"+id+"-detail-overview.png","res://assets/portraits-r21/"+id+"-upperbody.png"]:
				if ResourceLoader.exists(candidate):path=candidate;break
	return {"name":name,"path":path,"fallback":name!="" and name!=id+"_portrait_default" and not path.ends_with(name+".png")}
func configure(id: String,variant="default") -> void:
	selection=resolve(id,variant);texture=load(selection.path) if selection.path!="" else null
	initial=R.DATA.cast.get(id,{}).get("name","").left(1) if id!="persona" else ""
	mouse_filter=MOUSE_FILTER_IGNORE;clip_contents=true;texture_filter=TEXTURE_FILTER_LINEAR;queue_redraw()
func _draw() -> void:
	if texture:
		var k=maxf(size.x/texture.get_width(),size.y/texture.get_height());var dims=texture.get_size()*k
		draw_texture_rect(texture,Rect2(Vector2((size.x-dims.x)/2,0),dims),false)
	elif initial!="":draw_string(T.DISPLAY,Vector2(14,size.y*.65),initial,HORIZONTAL_ALIGNMENT_LEFT,-1,48,T.MUTED)
	else:
		draw_circle(Vector2(size.x/2,size.y*.3),minf(size.x,size.y)*.13,T.MUTED)
		draw_style_box(T.panel(T.PALE,T.PALE),Rect2(size.x*.24,size.y*.5,size.x*.52,size.y*.36))
