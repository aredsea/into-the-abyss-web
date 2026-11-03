extends "res://tests/expe_pass3_r23_test.gd"
## The numeric source matrix deliberately edits persona.lv independently of
## its native member mirror. Cloud specimens synchronize that native invariant.
func setup():
	var w=super()
	w.s.members.persona.level=w.s.persona.lv;w.s.members.persona.xp=w.s.persona.exp
	return w
