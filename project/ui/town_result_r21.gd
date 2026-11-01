extends "res://ui/town_screen_r21.gd"
## Result presentation only. The battle's existing exit commits its reward once.
func build_result(owner_screen,combat) -> void:
	build_frame(owner_screen);mouse_filter=MOUSE_FILTER_STOP;z_as_relative=false;z_index=100
	var win=combat.state.result=="victory"
	display("VICTORY" if win else "DEFEAT",Rect2(12,25,366,155),T.RED if win else T.INK,116,true)
	label("전투 승리" if win else "전투 패배",Rect2(18,180,354,34),24,T.INK,T.BOLD)
	plate("preparation-ruins",Rect2(0,224,390,264))
	ink(Rect2(-12,400,414,91))
	var enemies=combat.state.data.enemies
	var title=enemies[0].name+(" 외 %d"%(enemies.size()-1) if enemies.size()>1 else "")
	fill("result_title_paper",Rect2(12,422,366,55),T.INK)
	display(title+" 처치" if win else "이탈 · 토르바로",Rect2(18,427,354,45),T.PAPER,28)
	label("남은 파티 상태",Rect2(18,499,354,26),16,T.INK,T.BOLD)
	for i in range(host.model.s.party.size()):
		var id=host.model.s.party[i];var a=combat.state.ally(id);var x=18+i*91
		picture(id,Rect2(x,537,86,75),"town-party-face")
		label(host.model.person(id).name,Rect2(x,616,86,19),10,T.INK,T.BOLD)
		label("HP %d/%d"%[a.hp,a.mhp],Rect2(x,640,86,19),10)
		fill("result_hp:"+id,Rect2(x,664,86*maxf(0,a.hp)/maxf(1,a.mhp),4),T.RED)
	paragraph("전투 결과를 확인하고 원정을 계속합니다." if win else "부상과 보상을 반영한 정산을 확인합니다.",Rect2(18,682,354,34),13)
	action("result_continue","원정 계속" if win else "정산 확인",Rect2(18,729,354,49),combat._retry,true)
	label("결과 확인 시 원정 상태에 한 번 반영됩니다.",Rect2(18,791,354,24),11)
