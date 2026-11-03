extends Control
const T=preload("res://ui/town_theme_r21.gd")
var metrics=[]
var host
var service
var body: VBoxContainer
var fields={}

func build(owner_screen) -> void:
	host=owner_screen;service=host.cloud
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);theme=T.make_theme()
	var ground=ColorRect.new();add_child(ground);ground.color=T.PAPER;ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ground.mouse_filter=MOUSE_FILTER_IGNORE
	var frame=Control.new();add_child(frame);var w=minf(host.size.x,430);frame.position=Vector2((host.size.x-w)/2,0);frame.size=Vector2(w,host.size.y)
	T.city(frame,Rect2(w-174,0,156,124))
	var title=Label.new();frame.add_child(title);title.position=Vector2(18,12);title.size=Vector2(w-112,58);title.text="토르바 · "+("순위" if host.screen=="rank" else "기록");title.add_theme_font_override("font",T.DISPLAY);title.add_theme_font_size_override("font_size",32)
	var back=Button.new();frame.add_child(back);back.position=Vector2(w-88,20);back.size=Vector2(70,44);back.text="뒤로";T.dress_button(back);back.pressed.connect(host.go.bind("cloud" if host.screen=="rank" else "journal"));host.controls.back=back
	T.rule(frame,80,w-36)
	var scroll=ScrollContainer.new();frame.add_child(scroll);scroll.position=Vector2(18,96);scroll.size=Vector2(w-36,host.size.y-114);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12)
	label("대던전 순위" if host.screen=="rank" else "클라우드 저장",24)
	label(service.notice,14)
	if not host.cloud_confirmation.is_empty():
		label(host.cloud_confirmation.prompt,17)
		button("cloud_confirm","확인",func():var cb=host.cloud_confirmation.callback;host.cloud_confirmation={};cb.call())
		button("cloud_cancel","취소",func():host.cloud_confirmation={};host._draw_screen())
		return
	if host.screen=="rank":rank_page();return
	if not service.connected():
		label("이 기기의 모험을 보관하고, 다른 기기에서 이어하세요.")
		button("cloud_create","처음 저장 · 계정 만들기",service.create_account,not service.enabled())
		label("다른 기기 연결",19)
		input("code","계정 코드 · XXXX-XXXX-XXXX",false)
		input("pin","쓰기 PIN · 읽기만 할 때는 생략",true)
		button("cloud_connect","다른 기기 기록에 연결",connect_values,not service.enabled())
		label("계정 코드만 알면 기록을 읽을 수 있습니다. 쓰기 PIN은 저장과 삭제에 필요합니다.",13)
	else:
		label("계정 코드",14);label(service.account.code,24)
		if service.first_credentials:
			label("쓰기 PIN · 적어 두세요",14);label(service.account.pin,24)
			label("코드와 PIN을 함께 보관하세요. PIN은 잊으면 복구할 수 없습니다.",13)
			button("cloud_noted","적어 두었습니다",func():service.first_credentials=false;host._draw_screen())
		label("이 기기 · "+describe(local_summary()),14)
		if not service.conflict.is_empty():
			label("다른 기기의 새 기록",20)
			label("서버 최신 · "+describe(service.conflict.summary),14)
			button("cloud_keep_local","이 기기 기록을 서버에 저장",service.choose_local)
			button("cloud_keep_server","서버 최신 기록 불러오기",func():ask("서버 기록을 불러올까요? 이 기기 기록은 백업에 남습니다.",service.download))
		else:
			if not service.remote.is_empty():label("서버 · "+describe(service.remote.summary),14)
			button("cloud_save","지금 저장",service.upload,not service.can_upload())
			button("cloud_load","서버 최신 불러오기",func():ask("서버 기록을 불러올까요? 이 기기 기록은 백업에 남습니다.",service.download))
		var auto=CheckButton.new();body.add_child(auto);auto.text="귀환·정산 후 자동 저장";auto.button_pressed=service.account.auto;auto.custom_minimum_size.y=48;auto.disabled=service.busy or not service.can_upload();auto.toggled.connect(service.toggle_auto);host.controls.cloud_auto=auto
		button("cloud_rank","대던전 순위",host.go.bind("rank"))
		button("cloud_history","최근 기록 확인",service.history)
		for row in service.revisions:
			label("기록 %d · %s"%[int(row.rev),describe(row.summary)],14)
			button("cloud_rev:"+str(int(row.rev)),"이 기록 불러오기",func():ask("기록 %d을 불러올까요? 서버에는 새로 저장하기 전까지 반영되지 않습니다."%int(row.rev),service.download.bind(int(row.rev))))
		button("cloud_switch","다른 계정 연결",func():host.cloud_connecting=true;host._draw_screen())
		if host.cloud_connecting:
			input("code","연결할 계정 코드",false);input("pin","연결할 쓰기 PIN",true);button("cloud_connect","계정 연결",connect_values)
		button("cloud_delete","클라우드 계정 삭제",func():ask("클라우드의 계정과 모든 기록(비활성 보관본 포함)을 삭제할까요? 이 작업은 되돌릴 수 없습니다. 이 기기 저장은 남습니다.",service.delete_account),service.account.pin.is_empty())
func label(value: String,fs=15) -> void:
	var l=Label.new();body.add_child(l);l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",fs);l.mouse_filter=MOUSE_FILTER_IGNORE
	if fs>=19:l.add_theme_font_override("font",T.DISPLAY)
func button(id: String,value: String,callback: Callable,disabled=false) -> void:
	var b=Button.new();body.add_child(b);b.text=value;b.custom_minimum_size.y=48;b.disabled=disabled or service.busy;b.pressed.connect(callback);host.controls[id]=b
	T.dress_button(b,id in ["cloud_create","cloud_save","cloud_keep_local","cloud_confirm","rank_refresh"])
func input(id: String,hint: String,secret: bool) -> void:
	var field=LineEdit.new();body.add_child(field);field.placeholder_text=hint;field.secret=secret;field.custom_minimum_size.y=48;field.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_DEFAULT
	field.add_theme_color_override("font_color",T.INK);field.add_theme_color_override("font_placeholder_color",T.MUTED)
	for key in ["normal","focus"]:
		var style=T.panel(T.PAPER,T.ACTION_RED if key=="focus" else T.INK);style.set_border_width_all(2);style.content_margin_left=10;style.content_margin_right=10;field.add_theme_stylebox_override(key,style)
	fields[id]=field
func connect_values() -> void:
	var code=fields.code.text;var pin=fields.pin.text;host.cloud_connecting=false;service.connect_account(code,pin)
func ask(prompt: String,callback: Callable) -> void:
	host.cloud_confirmation={"prompt":prompt,"callback":callback};host._draw_screen()
func local_summary() -> Dictionary:
	return {"day":host.model.s.day,"gold":host.model.s.gold,"level":host.model.s.persona.lv,"best":host.model.s.dungeon_r21.best,"companions":host.model.s.owned.size()}
func describe(s: Dictionary) -> String:
	return "%d일 · Lv.%d · %d층\n금화 %d · 동료 %d명"%[int(s.get("day",1)),int(s.get("level",1)),int(s.get("best",0)),int(s.get("gold",0)),int(s.get("companions",0))]
func rank_page() -> void:
	label("최고 도달 %d층"%host.model.s.dungeon_r21.best,22)
	if not service.rank.is_empty():
		var pct=service.Legacy.rank_percent(service.rank,int(host.model.s.dungeon_r21.best))
		if pct!=null:label("내 기록 · 상위 %s%%"%service.Legacy.Value.text(pct),24)
		elif service.rank.get("pct")==null:label("아직 순위에 등록된 도달 기록이 없습니다.")
		label("참여 %d계정 · 최고 %d층"%[int(service.rank.n),int(service.rank.top)])
		label("확인 시각 · "+Time.get_datetime_string_from_unix_time(int(service.rank.at)),13)
	label("클라우드에 저장한 최고 도달 층수를 비교합니다. 같은 층수는 같은 백분위입니다. 이름과 자유 입력은 공개하지 않습니다.",14)
	button("rank_refresh","순위 확인 · 5분마다 갱신",service.fetch_rank,not service.connected())
	button("rank_back","클라우드 저장으로",host.go.bind("cloud"))

func input_rects() -> Dictionary:
	var out={}
	for key in fields:
		var r=fields[key].get_global_rect();out[key]=[r.position.x,r.position.y,r.size.x,r.size.y]
	return out
