extends Control
## Source name selection and local availability are separate contracts.
const R=preload("res://game/panels_rules_r22.gd")
const T=preload("res://ui/town_theme_r21.gd")
const L=preload("res://game/localization_r22.gd")
const Layout24=preload("res://ui/portrait_layout_r24.gd")
var character_id=""
var normalized24=false
var texture: Texture2D
var initial=""
var selection={}
static func matches(value: String,pattern: String) -> bool:
	var r=RegEx.new();r.compile(pattern);return r.search(value)!=null
static func asset_name(id: Variant,variant: Variant=null) -> String:
	return R.Value.text(id)+"_portrait_"+R.Value.text(variant,"default")
static func has_asset(name: String,have: Variant=null,expr: Dictionary={},enabled=false) -> bool:
	if have==null:have=R.DATA.have
	var v=have.get(name,false) if have is Dictionary else false
	var e=expr.get(name,false)
	return (v is bool and v) or (enabled and e is bool and e)
static func pick(id: String,variant="default",have: Variant=null,expr: Dictionary={},enabled=false,hidden=false) -> String:
	if hidden or not matches(id,"^[a-z0-9]+$"):return ""
	var name=asset_name(id,variant)
	if matches(variant,"^[a-z_]+$") and has_asset(name,have,expr,enabled):return name
	name=asset_name(id)
	return name if has_asset(name,have,expr,enabled) else ""
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
static func face_observation(id: String,name: String,lang="ko") -> Dictionary:
	var asset=pick(id)
	return {"asset":asset,"initial":R.first(L.t(name,lang)) if asset=="" and id not in ["","persona"] else "","persona":asset=="" and id in ["","persona"]}
func configure(id: String,variant="default",name: Variant=null,lang="ko") -> void:
	selection=resolve(id,variant);texture=load(selection.path) if selection.path!="" else null
	character_id=id
	var revised=Layout24.path(id);normalized24=not revised.is_empty() and selection.name!="" and (selection.name==id+"_portrait_default" or selection.fallback)
	if normalized24:
		selection.render_path=revised;texture=load(revised)
	var display=R.DATA.cast.get(id,{}).get("name",id) if name==null else name
	initial=face_observation(id,display,lang).initial
	if texture==null and selection.name!="":initial=R.first(L.t(display,lang))
	mouse_filter=MOUSE_FILTER_IGNORE;clip_contents=true;texture_filter=TEXTURE_FILTER_LINEAR;queue_redraw()
func _draw() -> void:
	if texture:
		if normalized24:
			Layout24.paint(self,character_id,size,texture)
			return
		var k=maxf(size.x/texture.get_width(),size.y/texture.get_height());var dims=texture.get_size()*k
		draw_texture_rect(texture,Rect2(Vector2((size.x-dims.x)/2,0),dims),false)
	elif initial!="":draw_string(T.DISPLAY,Vector2(14,size.y*.65),initial,HORIZONTAL_ALIGNMENT_LEFT,-1,48,T.MUTED)
	else:
		draw_circle(Vector2(size.x/2,size.y*.3),minf(size.x,size.y)*.13,T.MUTED)
		draw_style_box(T.panel(T.PALE,T.PALE),Rect2(size.x*.24,size.y*.5,size.x*.52,size.y*.36))
