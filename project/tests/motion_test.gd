extends SceneTree
const Clock = preload("res://ui/combat_timeline.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _initialize() -> void:
	var clock = Clock.new()
	check(clock.advance(0.21).is_empty(), "impact must not precede contact")
	check(clock.advance(0.01) == ["impact"], "one impact at contact")
	clock.advance(0.025)
	check(is_equal_approx(clock.elapsed, 0.22), "freeze body for hitstop")
	clock.advance(0.025)
	check(is_equal_approx(clock.elapsed, 0.22), "finish hitstop before advancing")
	check(clock.advance(0.43) == ["finished"], "finish without duplicate impact")
	check(clock.skip().is_empty(), "skip completed action is idempotent")
	for rate in [0.5, 1.0, 2.0]:
		clock = Clock.new()
		clock.speed = rate
		var events: Array[String] = []
		for i in range(300): events.append_array(clock.advance(1.0 / 60))
		check(events == ["impact", "finished"], "speed preserves events")
	clock = Clock.new()
	clock.paused = true
	check(clock.advance(10).is_empty() and clock.elapsed == 0, "pause")
	check(clock.skip() == ["impact", "finished"], "skip flushes each event once")
	check(clock.skip().is_empty(), "repeat skip")
	clock = Clock.new()
	check(clock.advance(5) == ["impact", "finished"], "large delta cannot lose contact")
	clock = Clock.new()
	clock.configure(0.1, 0.4, 0)
	check(clock.advance(0.4) == ["impact", "finished"], "support action without hitstop")
	if failures.is_empty(): print("MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
