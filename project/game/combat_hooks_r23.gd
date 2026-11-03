extends RefCounted
## Dispatch contract: living personal owners in slot order, then one global hook.
var definitions=[]
var personal={}
var global={}
var skill: Variant=null
func eligible(state: Dictionary,index: int,event: String) -> Callable:
	var definition=definitions[index] if index<definitions.size() else null
	var hooks=personal.get(definition.get('cid',''),{}) if definition is Dictionary else {}
	return hooks.get(event,Callable()) if state.u[index].al==1 else Callable()
func fire(state: Dictionary,event: String,args: Array=[]) -> void:
	for i in range(4):
		var callback=eligible(state,i,event)
		if callback.is_valid():callback.callv([state,i+1]+args)
	var callback=global.get(event,Callable())
	if callback.is_valid():callback.callv([state]+args)
func chain(state: Dictionary,event: String,value: Variant,args: Array=[]) -> Variant:
	for i in range(4):
		var callback=eligible(state,i,event)
		if callback.is_valid():
			var old_skill=skill;skill=null
			var next=callback.callv([state,i+1,value]+args);skill=old_skill
			if next!=null:value=next
	var callback=global.get(event,Callable())
	if callback.is_valid():
		var next=callback.callv([state,value]+args)
		if next!=null:value=next
	return value
func chain_at(state: Dictionary,event: String,position: int,args: Array) -> Variant:
	for i in range(4):
		var callback=eligible(state,i,event)
		if callback.is_valid():
			var old_skill=skill;skill=null
			var next=callback.callv([state,i+1]+args);skill=old_skill
			if next!=null:args[position-1]=next
	var callback=global.get(event,Callable())
	if callback.is_valid():
		var next=callback.callv([state]+args)
		if next!=null:args[position-1]=next
	return args[position-1]
