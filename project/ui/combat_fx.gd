extends Node2D
## Shared deterministic pixel vocabulary, also used for supplies and enemy turns.
const Brush=preload("res://ui/pixel_brush_r18.gd")
const Motif=preload("res://ui/signature_fx_r18.gd")
var element="ice"
var healing=false
var reduced=false
var elapsed=0.0
static func color_for(id: String) -> Color:
	return {"ice":Color("67d5ed"),"bolt":Color("efca4b"),"fire":Color("f47936"),"holy":Color("e9db8a"),"wind":Color("84cf92"),"dark":Color("b08dc6"),"none":Color("e6c5a0")}.get(id,Color("e6c5a0"))
func _process(delta: float) -> void:
	elapsed+=delta; queue_redraw()
	if elapsed>(.18 if reduced else .6): queue_free()
func _draw() -> void:
	paint(self,"holy" if healing else element,"triage" if healing else "",elapsed+.12,.12,.72,Rect2(-80,0,40,80),[Rect2(-40,-48,80,96)],reduced,false,Rect2())
static func paint(canvas: CanvasItem,element_id: String,fx: String,time: float,contact: float,length: float,source: Rect2,targets: Array,reduced_motion: bool,personal: bool,field: Rect2) -> void:
	var brush=Brush.new(canvas); var motif=Motif.new(canvas); var col=color_for(element_id)
	brush.clip_rect=field; motif.clip_rect=field
	var start=.6 if personal else 0.0
	var centers=targets if not targets.is_empty() else [source]
	if reduced_motion:
		if time>=contact:
			for rect in centers:
				var c=rect.get_center()
				brush.draw_rect(Rect2(c-Vector2(15,15),Vector2(30,30)),Color(col,.65),false,3)
				brush.draw_line(c-Vector2(6,0),c+Vector2(6,0),col,3)
		return
	if time<start: return
	var cast_end=minf(contact-.04,start+.16)
	var origin=source.get_center()
	if time<cast_end:
		var p=clampf((time-start)/maxf(.01,cast_end-start),0,1)
		for i in range(8):
			var v=Vector2.from_angle(i*TAU/8)
			brush.draw_line(origin+v*(42-24*p),origin+v*(54-28*p),col,6)
	elif time<contact:
		var p=clampf((time-cast_end)/maxf(.01,contact-cast_end),0,1)
		for rect in centers:
			var end=rect.get_center(); var head=origin.lerp(end,p); var direction=(end-origin).normalized()
			brush.draw_line(head-direction*minf(72,(end-origin).length()*.5),head,col,9 if personal else 6)
			brush.draw_rect(Rect2(head-Vector2(6,6),Vector2(15,15)),Color("f3efe3"))
	else:
		var age=time-contact
		if age>.4: return
		if age<.05 and field.has_area(): canvas.draw_rect(field,Color(col,.18 if personal else .10))
		var alpha=clampf((.4-age)/.18,0,1); col.a=alpha
		for rect in centers:
			var c=rect.get_center(); var r=clampf(rect.size.y*(.65 if personal else .52),42,100)
			var p=clampf(.72+age*.9,0,1)
			if age<.10:
				for i in range(8):
					var v=Vector2.from_angle(i*TAU/8+.22)
					brush.draw_line(c+v*r*.76,c+v*r*1.05,Color(col,.9),6 if personal else 3)
			var pattern=fx
			if pattern.is_empty(): pattern={"ice":"ice_nova","bolt":"thunder_sigil","fire":"fire_sweep","holy":"triage","wind":"wolf_roar","dark":"shadow_snare","none":"crosscut"}.get(element_id,"crosscut")
			if age<.20: motif.render(pattern,c,r,p,col,time)
			# Fixed-seed remnants: no random calls or wall clock in a draw path.
			for i in range(12 if personal else 8):
				var angle=i*2.399963+float(pattern.hash()%31)*.11
				var v=Vector2.from_angle(angle)
				var at=c+v*r*(.4+age*2)+Vector2(0,age*age*140)
				brush.draw_rect(Rect2(at,Vector2(6 if i%3 else 9,6)),Color(col,alpha*.8))
