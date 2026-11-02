extends "res://ui/panel_screen_r22.gd"
func build(owner_screen) -> void:
	setup(owner_screen,"상태창");persona();section("즐겨찾기 동료 · 최대 3명")
	if state.favs().is_empty():text("도감에서 동료를 즐겨찾기하면 여기에 모아 볼 수 있습니다.",15,T.MUTED)
	for id in state.favs().slice(0,3):
		var c=R.DATA.cast[id];var m=host.model.s.members[id];var h=row();portrait(id,h,Vector2(76,108));var b=VBoxContainer.new();h.add_child(b);b.size_flags_horizontal=SIZE_EXPAND_FILL
		text(c.name,25,T.INK,b);text("%s · Lv %d%s"%[c.cls,m.level," · 출전" if id in host.model.s.party else ""],14,T.MUTED,b)
		var st=R.companion_stats(id,int(m.level));text("HP %d · MP %d"%[st.hp,st.mp],14,T.MUTED,b);affection(m.aff)
		button("p7_open_"+id,"도감에서 보기",func():state.cx("open_"+id);host.go("codex"))
	button("p7_open_codex","도감 열기",host.go.bind("codex"),true)
