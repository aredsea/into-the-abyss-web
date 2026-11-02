extends "res://ui/town_screen_r21.gd"
## Result presentation only. The battle's existing exit commits its reward once.
func build_result(owner_screen,combat) -> void:
	build_frame(owner_screen);mouse_filter=MOUSE_FILTER_STOP;z_as_relative=false;z_index=100
	var win=combat.state.result=="victory"
	background("victory" if win else "defeat",Rect2(0,279 if win else 305,390,311 if win else 285))
	if win:plate("accent-victory",Rect2(0,0,390,590))
	traced_title("victory" if win else "defeat",Rect2(8 if win else 4,41 if win else 40,374 if win else 382,238 if win else 265))
	# The original four pixel actors stand in front of the cleaned reference ruins.
	for i in range(host.model.s.party.size()):
		var sprite=host.CharacterSprite.new();stage.add_child(sprite);sprite.position=Vector2(3+i*96,408);sprite.size=Vector2(96,180);sprite.configure(host.model.s.party[i],false)
		if not win:
			var shader=Shader.new();shader.code="shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV);float g=dot(c.rgb,vec3(0.299,0.587,0.114));COLOR=vec4(vec3(g)*0.8,c.a);}"
			var material=ShaderMaterial.new();material.shader=shader;sprite.material=material
	var enemies=combat.state.data.enemies
	var title=enemies[0].name+(" 외 %d"%(enemies.size()-1) if enemies.size()>1 else "")
	# The traced source title and the ruins used to contain/cover parts of this line.
	# Keep a clear paper lane above the actors, and render all copy as actual text.
	fill("result_caption_paper",Rect2(18,265 if win else 306,354,73 if win else 33),T.PAPER)
	var subtitle=label("적을 모두 쓰러뜨렸습니다." if win else "부상으로 전투에서 이탈했습니다.",Rect2(18,278 if win else 308,354,26),15,T.INK,T.BOLD)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mark("result_subtitle",subtitle)
	if win:
		var detail=label("전투 승리 · "+title,Rect2(18,307,354,24),12,T.INK,T.BOLD)
		mark("result_detail",detail)
	for i in range(host.model.s.party.size()):
		var id=host.model.s.party[i];var a=combat.state.ally(id);var x=18+i*91
		picture(id,Rect2(x,597,86,43),"town-party-face")
		label(host.model.person(id).name,Rect2(x,640,86,19),10,T.INK,T.BOLD)
		label("HP %d/%d"%[a.hp,a.mhp],Rect2(x,660,86,19),10)
		fill("result_hp:"+id,Rect2(x,680,86*maxf(0,a.hp)/maxf(1,a.mhp),4),T.RED)
	paragraph("전투 결과를 확인하고 원정을 계속합니다." if win else "부상과 보상을 반영한 정산을 확인합니다.",Rect2(18,689,354,29),13)
	action("result_continue","원정 계속" if win else "정산 확인",Rect2(18,729,354,49),combat._retry,true)
	label("결과 확인 시 원정 상태에 한 번 반영됩니다.",Rect2(18,791,354,24),11)
