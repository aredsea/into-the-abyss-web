extends RefCounted
## Presentation clock. It cannot access battle state or apply damage.
var elapsed: float = 0.0
var impact_at: float = 0.22
var duration: float = 0.65
var hitstop: float = 0.05
var remaining_stop: float = 0.0
var impacted: bool = false
var finished: bool = false
var paused: bool = false
var speed: float = 1.0

func configure(contact: float, length: float, stop: float) -> void:
	impact_at = contact
	duration = length
	hitstop = stop

func advance(delta: float) -> Array[String]:
	var events: Array[String] = []
	if paused or finished: return events
	var budget = maxf(0.0, delta) * speed
	if remaining_stop > 0.0:
		var consumed = minf(budget, remaining_stop)
		remaining_stop -= consumed
		budget -= consumed
	if not impacted and elapsed + budget >= impact_at:
		budget -= maxf(0.0, impact_at - elapsed)
		elapsed = impact_at
		impacted = true
		events.append("impact")
		remaining_stop = hitstop
		var consumed = minf(budget, remaining_stop)
		remaining_stop -= consumed
		budget -= consumed
	elapsed = minf(duration, elapsed + budget)
	if elapsed >= duration:
		finished = true
		events.append("finished")
	return events

func skip() -> Array[String]:
	var events: Array[String] = []
	if finished: return events
	if not impacted:
		impacted = true
		events.append("impact")
	elapsed = duration
	remaining_stop = 0.0
	finished = true
	events.append("finished")
	return events
