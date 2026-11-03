extends "res://tests/battle_r23_round6_test.gd"
const Research7=preload('res://game/persona_research_r21.gd')
func run():
	var research=Research7.new();var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round7-persona-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for index in range(source.rows.size()):
			var row=source.rows[index];var c=row.input;var got='API unavailable'
			match row.op:
				'work':
					if research.has_method('draft_work'):got=research.draft_work(c.saved,c.ui)
				'dirty':
					if research.has_method('draft_dirty'):got=research.draft_dirty(c.saved,c.ui)
				'same':
					if research.has_method('same_parts'):got=research.same_parts(c.a,c.b)
				'changes':
					if research.has_method('changes'):got=research.changes(c.a,c.b)
			check(same(got,row.expected),'round7/%s/%d'%[row.op,index],got,row.expected)
	var suffix=OS.get_environment('R23_ROUND7_OUTPUT');if suffix.is_empty():suffix='latest'
	var f=FileAccess.open('res://../verification/parity-r23/battle-round7-persona-'+suffix+'.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND7 PERSONA ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
