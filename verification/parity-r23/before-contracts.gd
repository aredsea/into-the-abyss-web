extends SceneTree
# Exact pre-correction method bodies, reconstructed from the edits in this run.
# This is an isolated failing probe, NOT a final production test or full old build.
class OldX:
	extends RefCounted
	var extra_state={}
	func x(u: Dictionary) -> Dictionary:
		return extra_state[u.id]
class OldPM:
	extends RefCounted
	var s: int
	func _init(seed: int):
		s=posmod(seed,2147483646)+1
		for i in range(4):s=(s*16807)%2147483647
	func next() -> float:
		s=(s*16807)%2147483647
		return float(s)/2147483647.0
	func pick(list: Array):return list[mini(list.size()-1,int(floor(next()*list.size())))]
func _init():call_deferred("run")
func run():
	for value in [false,17,"bad"]:
		var old=OldX.new();old.extra_state.actor=value
		print("OLD X INPUT ",typeof(value))
		old.x({"id":"actor"})
	var rng=OldPM.new(1)
	print("OLD EMPTY PICK")
	rng.pick([])
	print("PRE-CORRECTION PROBE FINISHED")
	quit(1)

