extends "res://ui/panel_screen_r22.gd"
func build(owner_screen) -> void:
	setup(owner_screen,"상태창");persona();section("즐겨찾기 동료")
	if state.favs().is_empty():
		text(L.u("도감에서 동료를 즐겨찾기하면 여기에 모아 볼 수 있습니다. (최대 {max}명)",{"max":3},L.language(host.model.s)),15,T.MUTED)
		button("p7_open_codex","도감 열기",host.go.bind("codex"),true)
	for id in state.favs():favorite_card(id)
