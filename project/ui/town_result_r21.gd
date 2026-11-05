extends "res://ui/town_screen_r21.gd"
## Result presentation only. The battle's existing exit commits its reward once.
func build_result(owner_screen,combat) -> void:
	build_frame(owner_screen);mouse_filter=MOUSE_FILTER_STOP;z_as_relative=false;z_index=100
	var win=combat.state.result=="victory"
	background("victory" if win else "defeat",Rect2(0,83,390,346))
	var title_ink=display("승리" if win else "패배",Rect2(18,13,354,70),T.INK,54);mark("title:"+("victory" if win else "defeat"),title_ink)
	for i in range(host.model.s.party.size()):
		var sprite=host.CharacterSprite.new();stage.add_child(sprite);sprite.position=Vector2(3+i*96,223);sprite.size=Vector2(96,200);sprite.configure(host.model.s.party[i],false)
		if not win:sprite.modulate=Color(.65,.65,.65,1)
	T.torn(stage,412)
	var enemies=combat.state.data.enemies
	var title=enemies[0].name+(" 외 %d"%(enemies.size()-1) if enemies.size()>1 else "")
	fill("result_caption_paper",Rect2(18,441,354,77),Color.TRANSPARENT)
	var subtitle=paragraph("적을 모두 쓰러뜨렸습니다." if win else "부상으로 전투에서 이탈했습니다.",Rect2(18,447,354,35),19,T.INK)
	mark("result_subtitle",subtitle)
	if win:mark("result_detail",label("전투 승리 · "+title,Rect2(18,487,354,25),14,T.MUTED,T.BOLD))
	for i in range(host.model.s.party.size()):
		var id=host.model.s.party[i];var a=combat.state.ally(id);var x=18+i*91
		picture(id,Rect2(x,520,86,101),"party_card")
		label(host.model.person(id).name,Rect2(x,621,86,24),12,T.INK,T.BOLD)
		resource_numbers(Rect2(x,650,86,25),a.hp,a.mhp)
		resource("result_hp:"+id,Rect2(x,680,86,9),a.hp,a.mhp)
	paragraph("전투 결과를 확인하고 원정을 계속합니다." if win else "부상과 보상을 반영한 정산을 확인합니다.",Rect2(18,703,354,40),14)
	action("result_continue","원정 계속" if win else "정산 확인",Rect2(18,757,354,52),combat._retry,true)
	label("결과 확인 시 원정 상태에 한 번 반영됩니다.",Rect2(18,816,354,24),12)

