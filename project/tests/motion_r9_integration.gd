extends SceneTree
const World = preload("res://game/expansion_world.gd")
const Screen = preload("res://ui/battle_screen.gd")
var failures: Array[String] = []
var checks = 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var folder = ProjectSettings.globalize_path("res://../verification/ui-r17/motion-r9").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	for dimensions in [Vector2i(390,844), Vector2i(360,780)]:
		root.content_scale_size = dimensions; root.size = dimensions
		for id in ["hildegard", "bargut", "teiris", "berenga"]:
			for action in ["attack", "personal"]:
				var expected = ""
				for mode in ["normal", "skip", "reduced"]:
					var world = World.new(); world.depart(); world.travel("patrol")
					var screen = Screen.new(); screen.session_data = world.battle_data()
					screen.session_save = func(_snapshot): return OK
					screen.size = Vector2(dimensions); root.add_child(screen)
					screen.state.current_id = id; screen.state.last_ally = id; screen.state.selected_ally = id
					screen.state.ally(id).mp = screen.state.ally(id).mmp
					screen.state.ally(id).hp = int(screen.state.ally(id).mhp * 0.55)
					screen.animation_ally = id; screen.presenting_source = id; screen.busy = true
					screen._rebuild()
					var before = screen._capture_visual_before()
					check(screen.state.act(action), id + ":" + action + " resolves")
					var resolved = JSON.stringify(screen.state.snapshot())
					if expected.is_empty(): expected = resolved
					else: check(expected == resolved, "Modes resolve same game state")
					screen._present_action(before, id, action)
					var fx = screen.motion; fx.set_process(false)
					check(fx.clip.get("revision",0) == 9, "New action selected")
					check(fx.impact_count == 0, "No early visual impact")
					for unit in before: check(screen.shown_hp[unit] == before[unit].hp, "HP remains old before impact")
					if mode == "skip": fx.skip()
					else:
						if mode == "reduced": fx.reduced = true; fx.clock.configure(0.12,0.36,0)
						fx._process(fx.clock.impact_at - 0.001)
						check(fx.impact_count == 0, "Still before impact")
						fx._process(0.001)
						check(fx.impact_count == 1, "Exactly one contact")
						for unit in screen.state.data.allies + screen.state.data.enemies:
							check(screen.shown_hp.get(unit.id,0) == unit.hp, "HP matches contact or dead enemy is removed")
						if mode == "normal":
							await process_frame
							await RenderingServer.frame_post_draw
							var file = folder + "/" + id + "-" + action + "-" + str(dimensions.x) + ".png"
							check(root.get_texture().get_image().save_png(file) == OK, "Save contact render")
						fx._process(5)
					check(JSON.stringify(screen.state.snapshot()) == resolved, "Visual playback never resolves again")
					await process_frame
					root.remove_child(screen); screen.queue_free()
	var report = {"checks":checks,"failures":failures,"cases":48,"widths":[390,360],"rendered_contact_screens":16}
	var file = FileAccess.open(folder + "/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")); file.close()
	print("R9 INTEGRATION: ", checks, " checks / ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
