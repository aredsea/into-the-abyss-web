extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const CloudScreen=preload("res://ui/cloud_screen_r22.gd")
var checks=0
var failures=[]
var captures=[]
var folder="res://../verification/cloud-r22/render"
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func capture(s,tag,dim):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y]
	check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name)
	for l in s.town_view.find_children("*","Label",true,false):
		var needed=l.get_theme_font("font").get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x,l.get_theme_font_size("font_size"))
		check(needed.y<=l.size.y+1,"label fits "+tag+l.text)
	for id in s.controls:
		var b=s.controls[id]
		check(b.size.y>=44,"touch "+id)
		check(b.get_theme_font("font").get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,b.get_theme_font_size("font_size")).x+24<=b.size.x,"button fits "+id)
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/cloud-r22/fixtures.json"))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://ui-cloud-%d.json"%dim.x;root.add_child(s);s.model.restore(data.town);s.cloud.model=s.model;s.cloud.config.server_url="http://127.0.0.1:8787"
		s.cloud.account={"code":"","pin":"","rev":0,"auto":false};s.go("cloud");await capture(s,"connect",dim)
		s.cloud.account={"code":"ABCD-EFGH-JKMP","pin":"23456789AB","rev":1,"auto":false};s.cloud.first_credentials=true;s._draw_screen();await capture(s,"credentials",dim)
		s.cloud.first_credentials=false;s.cloud.conflict={"rev":2,"summary":{"day":2,"level":2,"best":1,"gold":275,"companions":1}};s._draw_screen();await capture(s,"conflict",dim)
		s.cloud.conflict={};s.cloud.rank={"n":3,"pct":34,"best":1,"top":2,"at":1793577600};s.go("rank");await capture(s,"rank",dim)
		s.go("cloud");s.town_view.ask("클라우드의 계정과 모든 기록을 삭제할까요? 이 작업은 되돌릴 수 없습니다. 이 기기 저장은 남습니다.",func():pass);await capture(s,"confirm",dim)
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open("res://../verification/cloud-r22/native-ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("CLOUD UI R22 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
