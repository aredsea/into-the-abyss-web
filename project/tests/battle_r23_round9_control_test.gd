extends "res://tests/battle_r23_round9_core_test.gd"
const Hooks=preload('res://game/combat_hooks_r23.gd')
const Controls=preload('res://game/combat_controls_r23.gd')
func hooks(c: Dictionary) -> Dictionary:
	var api=Hooks.new();api.definitions=c.defs;api.skill='active';var trace=[]
	for i in range(4):
		var owner=i+1
		api.personal['h'+str(owner)]={"probe":func(_state,o,value,one,two):
			trace.append({"owner":o,"value":value,"one":one,"two":two,"skill":api.skill if api.skill!=null else false})
			match c.mode:
				'false':return false
				'zero':return 0
				'number':return (value if value is float or value is int else 0)+owner
			return null}
	if c.bits>=16:api.global.probe=func(_state,value,one,two):
		trace.append({"owner":0,"value":value,"one":one,"two":two,"skill":api.skill if api.skill!=null else false})
		return 99 if c.mode=='number' else null
	var args=[7,'payload',false];var value
	match c.method:
		'fire':api.fire(c.state,'probe',args)
		'chain':value=api.chain(c.state,'probe',7,['payload',false])
		'chain_at':value=api.chain_at(c.state,'probe',1,args)
	var result={"trace":trace,"value":'nil' if value==null else value,"args":args,"skill":api.skill}
	api.personal.clear();api.global.clear()
	return result
func control(c: Dictionary) -> Dictionary:
	var calls=[]
	var state=Controls.act(c.state.duplicate(true),c.skills,c.action,func(_s,_i,_k):return c.allowed,func(_s,n,t):calls.append(['player',n,t]),func(_s):calls.append(['run']),func(_s):calls.append(['again']);return {"restarted":true},func(s):calls.append(['begin']);s.ev={"fresh":true})
	return {"state":state,"calls":calls}
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round9-control-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input
			var got=hooks(c) if row.op=='hook_dispatch' else control(c)
			check(same(got,row.expected),'round9/%s/%d'%[row.op,i],got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-control-latest.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND9 CONTROL ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
