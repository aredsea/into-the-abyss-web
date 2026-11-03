extends "res://tests/battle_r23_round7_test.gd"
func run():
	var research=preload('res://game/persona_research_r21.gd')
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round8-persona-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input
			var got=research.transition(c.saved,c.draft,int(c.spent),int(c.gold),c.arg,c.busy,c.lang)
			if got.message=='':got.message=c.message
			check(same(got,row.expected),'round8/research_action/%s/%d'%[part.file,i],got,row.expected)
	var suffix=OS.get_environment('R23_ROUND8_OUTPUT');if suffix.is_empty():suffix='latest'
	var f=FileAccess.open('res://../verification/parity-r23/battle-round8-persona-'+suffix+'.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND8 PERSONA ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
