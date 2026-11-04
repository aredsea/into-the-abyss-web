extends "res://tests/ui_look_r24_test.gd"
## Current live screens and state variants at every contracted viewport.
var audit=[]
var glyphs=[]
func _initialize():
	create_timer(600).timeout.connect(func():push_error("reskin watchdog");quit(98));call_deferred("run")
func scan(s,tag,dim):
	var missing=[];var clipped=[];var rails=[]
	for n in s.find_children("*","Control",true,false):
		if not n.is_visible_in_tree():continue
		if n is Button and n.has_node("RowCopy"):
			check(n.get_theme_color("font_color").a==0,"row has one visible copy, including primary state "+tag)
		if n is Label or n is Button or n is RichTextLabel:
			var font=n.get_theme_font("normal_font" if n is RichTextLabel else "font")
			for index in n.text.length():
				var cp=n.text.unicode_at(index)
				if cp>32 and not font.has_char(cp):missing.append({"text":n.text,"codepoint":cp,"node":str(n.get_path())})
		if n is Label and n.get_theme_color("font_color").a>0 and n.text!="":
			var font=n.get_theme_font("font");var fs=n.get_theme_font_size("font_size")
			var need=font.get_multiline_string_size(n.text,n.horizontal_alignment,n.size.x if n.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
			if need.x>n.size.x+1 or need.y>n.size.y+2:clipped.append({"text":n.text,"need":[need.x,need.y],"size":[n.size.x,n.size.y],"node":str(n.get_path())})
		if n is ScrollContainer and n.get_child_count()>0:
			var bar=n.get_v_scroll_bar()
			if bar.visible and n.get_child(0) is Control and n.get_child(0)!=bar:
				var body=n.get_child(0)
				if body.get_global_rect().end.x>bar.get_global_rect().position.x+.5:rails.append(str(n.get_path()))
	audit.append({"screen":tag,"size":[dim.x,dim.y],"missing":missing,"rails":rails,"clipped":clipped})
func shot(s,tag,dim):
	await settle();await settle();await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y]
	check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name);inventory.append({"screen":tag,"file":name,"size":[dim.x,dim.y]});scan(s,tag,dim)
func party_world():
	var w=ready_world();w.s.persona.fight=0;w.s.owned=["hildegard","bargut","teiris","berenga"];w.s.party=w.s.owned.duplicate();return w
func run():
	folder="res://../verification/reskin-r24/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(390,844),Vector2i(360,780),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://reskin-fixture-%d.json"%OS.get_process_id();root.add_child(s);s.motion_reduced=true;s.model=W24.new();s._draw_screen()
		s.cloud.account={"code":"","pin":"","rev":0,"auto":false,"synced":false};s.cloud.rank={}
		await shot(s,"create-race",dim);await tap(s,"cr_race_beast");await tap(s,"cr_lin_cat");await shot(s,"create-lineage",dim)
		await tap(s,"cr_next");await shot(s,"create-nation",dim);await tap(s,"cr_nat_naerin");await shot(s,"create-blocked",dim)
		await tap(s,"cr_nat_border");await tap(s,"cr_next");await shot(s,"create-class",dim);await tap(s,"cr_cls_archer");await tap(s,"cr_next");await tap(s,"cr_tot_free");await tap(s,"cr_auto");await shot(s,"create-points",dim)
		await tap(s,"cr_next");await shot(s,"create-confirm",dim);await tap(s,"cr_done");await shot(s,"meeting-empty",dim);await tap(s,"sc_pick_teiris");await shot(s,"meeting",dim);await tap(s,"sc_go")
		s.model=party_world()
		for page in ["town","party","member","member_details","skills","settings","codex","status","inventory","places","people","journal","guild","recruit","research","shop","inn","smithy","equipment","bag","depart","formation","cards","cloud","rank"]:
			if page in ["member","member_details","skills"]:s.who="teiris"
			await show(s,page,page,dim)
			if page=="depart":check(s.controls.start_run.get_meta("r24_primary",false),"departure action owns the vermilion surface, not a selected filter")
			if page=="shop":check(s.controls["buy:hp_s"].get_meta("r24_primary",false),"shop purchase owns the vermilion surface, not a selected tab")
			if is_instance_valid(s.town_view) and s.town_view.get("scroll") is ScrollContainer:
				s.town_view.scroll.scroll_vertical=100000;await shot(s,page+"-end",dim)
		var home_before=s.model.s.duplicate(true);await show(s,"town","town-news",dim)
		check(s.model.s==home_before,"town news reads source dialogue without changing save or RNG")
		check(s.town_view.boxes["facility_label:inn"].color==s.town_view.T.RED,"unread available inn dialogue marks its facility")
		for cid in s.model.s.owned:s.model.s.acts[cid+"_talk"]=s.model.s.day
		await show(s,"town","town-no-news",dim)
		check(s.town_view.boxes["facility_label:inn"].color==s.town_view.T.INK,"daily-complete talk does not claim new inn news")
		s.model=party_world();s.panels_r22=null
		# Exhaust the source-backed public places, biographies and owned codex details.
		for pid in s.model.Places.DATA.order:
			s.journal_r22.place=pid;await show(s,"places","place-"+pid,dim)
		for cid in s.model.Places.DATA.profiles:
			s.journal_r22.person=cid;await show(s,"people","person-"+cid,dim)
		if s.panels_r22==null:s.panels_r22=State.new(s.model)
		for cid in s.model.s.owned:
			s.panels_r22.ui.sel=cid;await show(s,"codex","codex-"+cid,dim);s.town_view.scroll.scroll_vertical=100000;await shot(s,"codex-"+cid+"-end",dim)
		s.panels_r22.ui.sel="persona";await show(s,"codex","codex-persona",dim);s.panels_r22.ui.sel=""
		s.model.s.items.hp_s=2;s.model.s.members.teiris.hp=14;s.selected_item="hp_s";s.selected_target="teiris";await show(s,"bag","item-target",dim);s.selected_item="";s.selected_target=""
		s.model.s.items.level_scroll=2;await show(s,"facility_scroll","scroll-target",dim)
		s.research_edit=true;await show(s,"research","research-editor",dim);s.research_edit=false
		var gear=s.model.gear.by_id.values().filter(func(e):return e.cls=="warrior")[0]
		s.model.s.gear=[{"id":gear.id,"seed":1,"uid":1,"forge":0,"tries":0}];s.panels_r22=null;await show(s,"inventory","inventory-stock",dim)
		s.panels_r22.bg_action("sel_1");await show(s,"inventory","inventory-detail",dim)
		s.panels_r22.bg.conf=s.panels_r22.selected().get("code","");await show(s,"inventory","inventory-sell-confirm",dim)
		s.panels_r22.bg.sel="";s.panels_r22.bg.conf="";s.panels_r22.bg.cls="archer";await show(s,"inventory","inventory-filter-empty",dim)
		s.model=party_world();s.panels_r22=null
		s.model.s.gold=0;await show(s,"recruit","recruit-poor",dim);await show(s,"shop","shop-poor",dim);s.model.s.gold=300
		s.model.s.hand=["key","camp"];await show(s,"cards","cards-filled",dim)
		s.model.s.owned=s.model.config.companions.map(func(c):return c.id);await show(s,"recruit","recruit-complete",dim)
		s.model=party_world();s.model.facility_route("shop");s.model.buy("hp_s");s.model.facility_route("town");await show(s,"town","shop-receipt",dim);s.model.acknowledge_receipt()
		s.journal_r22.legacy=true;await show(s,"journal","journal-legacy",dim);s.journal_r22.legacy=false
		s.model.s.settings.chron=0;await show(s,"journal","journal-disabled",dim);s.model.s.settings.chron=1
		s.journal_r22.place="archive";await show(s,"places","place-archive",dim);s.journal_r22.person="isolde";await show(s,"people","person-isolde",dim)
		s.reset_r22=true;await show(s,"settings","settings-reset",dim);s.reset_r22=false
		s.save_error=ERR_CANT_CREATE;await show(s,"town","save-error",dim)
		s.who="teiris"
		for page in ["member","party","inn","shop"]:await show(s,page,"save-error-"+page,dim)
		s.message="저장 실패: 창을 닫기 전에 다시 시도하세요.";await show(s,"town","save-error-message",dim)
		s.save_error=OK;s.message=""
		s.model.set_fight(1);await show(s,"town","town-persona",dim);await tap(s,"town_member:persona")
		check(s.screen=="status","persona slot opens its real source stats and skill panel")
		await shot(s,"persona-status",dim);s.model.set_fight(0)
		s.shop_tab="gear";await show(s,"shop","shop-gear",dim);s.shop_tab="items"
		s.model.smithy_action("tab_process");await show(s,"smithy","smithy-process",dim)
		s.model.begin_dialogue("teiris");await show(s,"inn","dialogue-choice",dim)
		var choices=s.model.dialogue.scene(s.model.s.dialogue_r21.pending.who,s.model.s.dialogue_r21.pending.scene).get("choices",[])
		if not choices.is_empty():s.model.choose_dialogue(choices[0].id);await show(s,"inn","dialogue-response",dim);s.model.close_dialogue()
		s.cloud.account={"code":"ABCD-EFGH-JKMP","pin":"23456789AB","rev":1,"auto":false,"synced":true};s.cloud.first_credentials=true;await show(s,"cloud","cloud-credentials",dim)
		s.cloud.first_credentials=false;s.cloud.conflict={"rev":2,"summary":{"day":2,"level":2,"best":1,"gold":275,"companions":1}};await show(s,"cloud","cloud-conflict",dim);s.cloud.conflict={}
		s.cloud.rank={"n":3,"pct":34,"best":1,"top":2,"at":1793577600};await show(s,"rank","rank-record",dim)
		s.cloud_confirmation={"prompt":"서버 기록을 불러올까요? 이 기기 기록은 백업에 남습니다.","callback":func():pass};await show(s,"cloud","cloud-confirm",dim);s.cloud_confirmation={}
		s.cloud_connecting=true;await show(s,"cloud","cloud-switch-account",dim);s.cloud_connecting=false
		s.cloud.busy=true;await show(s,"cloud","cloud-busy",dim);s.cloud.busy=false
		s.cloud.account.pin="";await show(s,"cloud","cloud-readonly",dim);s.cloud.account.pin="23456789AB"
		s.cloud.archived=true;await show(s,"cloud","cloud-archived",dim);s.cloud.archived=false
		s.cloud.notice="인터넷 연결을 확인한 뒤 다시 시도해 주세요.";await show(s,"cloud","cloud-offline",dim)
		s.model=party_world();s.model.depart_dungeon(1,117);s.model.s.dialogue_r21.queue=[]
		await show(s,"explore","explore",dim);await show(s,"expedition_log","expedition-log",dim)
		s.model.expedition_retreat("retreat");await show(s,"explore","retreat-confirm",dim);s.model.expedition_retreat("retreat_no");s.confirm={}
		s.model.s.run.phase="rest";await show(s,"explore","explore-rest",dim)
		s.model.s.run.phase="battle";s.screen="explore";s._draw_screen();await shot(s,"battle",dim)
		if is_instance_valid(s.battle):
			var b=s.battle;b.motion_reduced=true;b.busy=false;b.state.current_id="hildegard";b.state.last_ally="hildegard"
			b.ally_open="teiris";b._rebuild();await shot(s,"battle-status",dim);b._close_sheets()
			b.skills_open=true;b._rebuild();await shot(s,"battle-skills",dim);b._close_sheets()
			b.items_open=true;b._rebuild();await shot(s,"battle-supplies",dim);b._close_sheets()
			b.log_open=true;b._rebuild();await shot(s,"battle-log",dim);b._close_sheets()
			b.pending_action="attack";b._rebuild();await shot(s,"battle-target",dim);b.pending_action=""
			b.state.ally("berenga").hp=0;b._rebuild();await shot(s,"battle-ko",dim)
			var faces=b.find_children("*","Control",true,false).filter(func(n):return n.get_script()==preload("res://ui/portrait_slot_r24.gd") and n.character_id=="berenga" and n.kind=="battle-party")
			check(faces.size()==1 and faces[0].picture.material.get_shader_parameter("knocked_out"),"KO portrait inherits the existing grayscale state through the adapter")
		if is_instance_valid(s.battle):s.battle.queue_free();s.battle=null;await settle()
		s.model=party_world();s.model.depart_dungeon(1,117);s.model.s.dialogue_r21.queue=[];s.model.expedition_retreat("retreat");s.model.expedition_retreat("retreat_yes");s.model.s.dialogue_r21.queue=[];await show(s,"summary","summary-retreat",dim)
		s.model=ready_world();s.model.s.party=[];await show(s,"town","town-empty-party",dim)
		s.model.s.persona.fight=0;s.model.s.hand=[];await show(s,"cards","cards-empty",dim);s.model.s.summary={};await show(s,"summary","summary-empty",dim)
		s.model.s.owned=[];await show(s,"inn","inn-empty",dim);await show(s,"party","party-empty",dim)
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/reskin-r24/captures.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"inventory":inventory,"audit":audit},"\t"))
	print("RESKIN CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
