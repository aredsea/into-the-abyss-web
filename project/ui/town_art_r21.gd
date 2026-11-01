extends "res://ui/town_screen_r21.gd"
## The shell is owned by town; signature sequence and combat assets are untouched.
func build_art(owner_screen,id: String) -> void:
	build_frame(owner_screen);mouse_filter=MOUSE_FILTER_STOP;z_as_relative=false;z_index=100
	action("art_back","돌아가기",Rect2(18,10,94,38),host._close_art)
	label("연출 미리보기",Rect2(130,11,242,38),20,T.INK,T.BOLD)
	ink(Rect2(-10,55,430,225));picture(id,Rect2(0,43,390,240),"detail-skills")
	display("연출 미리보기",Rect2(18,60,354,48),T.INK,37)
	fill("art_skill_caption",Rect2(0,234,390,52),T.INK)
	display(host.model.person(id).skill.name,Rect2(18,243,354,42),T.PAPER,31)
	plate("preparation-ruins",Rect2(18,299,354,286))
	var field=Control.new();stage.add_child(field);field.position=Vector2(18,299);field.size=Vector2(354,286)
	var sprite=host.CharacterSprite.new();field.add_child(sprite);sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);sprite.configure(id,true);sprite.visible=false
	var seq=host.SignatureSequence.new();seq.character_id=id;seq.preview=true;seq.reduced=host.motion_reduced;field.add_child(seq);seq.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seq.finished.connect(func():sprite.visible=true)
	paragraph("전용 도트 · "+host.CharacterSprite.info(id).weapon+"\n전투 수치와 저장에는 영향이 없습니다.",Rect2(18,601,354,48),13)
	var ids=host.model.config.companions.map(func(p):return p.id);var index=ids.find(id)
	for i in range(3):
		var key=["art_prev","art_replay","art_next"][i];var next=ids[posmod(index-1,ids.size())] if i==0 else id if i==1 else ids[(index+1)%ids.size()]
		action(key,["이전","다시 재생","다음"][i],Rect2(18+i*118,666,118,42),host._show_art.bind(next),i==1)
	action("art_close","동료 상세로",Rect2(18,721,354,43),host._close_art,true)
	# The existing five navigation targets remain visible and clickable behind
	# the shell's short bottom strip; closing/reopening never changes a save.
	for i in range(5):
		var e=[["town","마을"],["party","동료"],["depart","원정"],["bag","가방"],["journal","기록"]][i]
		var b=action("nav:"+e[0],e[1],Rect2(i*78,790,78,44),func():host._close_art();host.go(e[0]));b.add_theme_font_size_override("font_size",12)
