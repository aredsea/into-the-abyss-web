extends "res://tests/combat_a6_r22_test.gd"
const Rules=preload("res://game/dungeon_rules_r21.gd")
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/compose-oracle.json"));var rules=Rules.new()
	check(same(rules.pools,source.pools) and same(source.pools,source.cached_pools),"compose/pools first and cached",rules.pools,source.pools)
	for row in source.flags:
		var got=[rules.has_summon(rules.foes[row.id]),rules.has_charge(rules.foes[row.id])]
		check(same(got,[row.summon,row.charge]),"compose/flags/"+row.id,got,[row.summon,row.charge])
	for row in source.flag_boundaries:
		var f={"acts":[]};var v=int(row.variant)
		if v==1:f.acts=[{"kind":"summon"}]
		if v==2:f.phase2={"acts":[{"kind":"summon"}]}
		if v==3:f.phase2={"acts":[],"entry":{"kind":"summon"}}
		if v==4:f.phase2={"acts":[],"entry":{"kind":"guard"}}
		if v==5:f.acts=[{"kind":"charge"}]
		var got=[rules.has_summon(f),rules.has_charge(f)]
		check(same(got,[row.summon,row.charge]),"compose/flags boundary/"+str(v),got,[row.summon,row.charge])
	for i in range(source.fits.size()):
		var row=source.fits[i];var got=rules.fits(rules.foes[row.id],row.cur,row.spec)
		check(got==row.expected,"compose/fits/"+str(i),got,row.expected)
	for row in source.random:
		var rng=Rules.PM.new(int(row.seed));var got=[]
		for i in range(8):rng.next();got.append(rng.s)
		# The source JSON encoder prints 14 significant digits. Compare the
		# exact Park-Miller integer state, including for a 53-bit seed string.
		check(same(got,row.states),"compose/random/"+str(row.seed),got,row.states)
		rng=Rules.PM.new(int(row.seed));got=[]
		for i in range(8):got.append(rng.pick(["a","b","c"]))
		check(same(got,row.picks),"compose/pick/"+str(row.seed),got,row.picks)
	for i in range(source.compositions.size()):
		var row=source.compositions[i];var got=rules.compose(int(row.seed),row.ctx)
		check(same(got,row.expected),"compose/whole/"+str(i),got,row.expected)
	var f=FileAccess.open("res://../verification/parity-r23/compose-latest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 COMPOSE ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
