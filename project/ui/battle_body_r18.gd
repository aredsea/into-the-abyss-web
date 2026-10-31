extends "res://ui/character_sprite.gd"
## Battle-only logical raster. Original pixels are sampled, never redrawn.
## The 75/80px body is enlarged exactly 2x with NEAREST; menu art is untouched.
var battle_pixels=false
static var bodies: Dictionary={}
func _draw() -> void:
	if not battle_pixels or portrait_mode:
		super._draw(); return
	if idle_enabled and not idle_clip.is_empty() and not idle_reduced:
		Motion.draw_frame(self,idle_clip,Motion.frame_at(idle_clip,fmod(idle_elapsed,float(idle_clip.duration))),Rect2(Vector2.ZERO,size),Vector2.ZERO,2)
		return
	if sheet==null: return
	var h=roundi(size.y/2)
	var key=character_id+str(action_pose)+str(h)
	if not bodies.has(key):
		var data=info(character_id); var frame=data.frames[1 if action_pose else 0]; var b=frame.bounds
		var w=roundi(float(b[2])*h/float(b[3]))
		var image=Image.create(w,h,false,Image.FORMAT_RGBA8)
		var source=sheet.get_image(); var polygon=PackedVector2Array()
		for p in frame.polygon: polygon.append(Vector2(p[0],p[1]))
		for y in range(h):
			for x in range(w):
				var p=Vector2(b[0]+(x+.5)*b[2]/w,b[1]+(y+.5)*b[3]/h)
				if Geometry2D.is_point_in_polygon(p,polygon): image.set_pixel(x,y,source.get_pixel(clampi(int(p.x),0,source.get_width()-1),clampi(int(p.y),0,source.get_height()-1)))
		bodies[key]=ImageTexture.create_from_image(image)
	var body: Texture2D=bodies[key]
	draw_texture_rect(body,Rect2(Vector2(roundf((size.x-body.get_width()*2)/2),size.y-body.get_height()*2),body.get_size()*2),false)
