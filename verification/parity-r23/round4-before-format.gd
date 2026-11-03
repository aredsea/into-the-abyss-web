extends "res://tests/battle_r23_batch_test.gd"
func run():
 var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/round4-oracle.json"))
 for c in oracle.rows:
  if c.op!="f2":continue
  var s="%.2f"%c.input.value
  check(same(s,c.expected.fx),"format/%s"%c.input.value,s,c.expected.fx)
 var f=FileAccess.open("res://../verification/parity-r23/round4-before-format.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"scope":"Reconstruction of the first round4 formatter, not the full prior build.","checks":checks,"failures":failures,"rows":rows},"\t"));f.close();quit(0 if failures.is_empty() else 1)
