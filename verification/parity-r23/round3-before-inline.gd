extends "res://tests/battle_r23_round3_test.gd"
## Replays the two preserved pre-refactor clauses, not an old whole build.
## The surrounding turn loop and unrelated damage hooks are excluded explicitly.
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/round3-oracle.json"))
	for row in oracle.rows:
		var c=row.input
		if row.op=="bargut_end":
			var b=clean();var u=b.data.allies[0];rename(b,u,"bargut");u.remaining=c.g
			if not c.pull is bool:b.x(u).personal_pull=c.pull
			if not c.other:
				# Original battle_v3.gd _finish_turn, after its interval addition.
				if u.id=="bargut": u.remaining=maxf(0,u.remaining-10000*b.x(u).get("personal_pull",0)); b.x(u).personal_pull=0
			var got={"g":u.remaining,"pull":b.x(u).get("personal_pull",false)}
			check(same(got,row.expected),"before-inline/bargut/%d"%checks,got,row.expected)
		elif row.op=="gunhild":
			var b=clean();var a=b.data.allies[0];var e=b.data.enemies[int(c.target)-5];rename(b,a,"gunhild");b.turn_count=3
			b.x(a).streak_action=c.action;b.x(a).target=b.data.enemies[0].id;b.x(a).streak=c.stacks
			var mult=2.0
			if not c.other:
				# Original battle_v3.gd _damage, with incoming multiplier held fixed.
				if a.id=="gunhild":
					if b.x(a).get("streak_action",-1)!=b.turn_count+1:
						b.x(a).streak_action=b.turn_count+1; b.x(a).streak=int(b.x(a).get("streak",0))+1 if b.x(a).get("target")==e.id else 0; b.x(a).target=e.id
					mult*=1+minf(.5,b.x(a).get("streak",0)*.05)
			var want=row.expected.value if not row.expected.value is bool else 2.0
			check(same(mult,want),"before-inline/gunhild/%d"%checks,mult,want)
	var f=FileAccess.open("res://../verification/parity-r23/round3-before-inline.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"scope":"Reconstructed original inline clauses, not the full pre-edit build; numeric multiplier and personal_pull state only."},"\t"));f.close()
	print("R23 BEFORE INLINE ",checks," failures ",failures.size());quit(0)
