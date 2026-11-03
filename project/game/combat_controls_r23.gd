extends RefCounted
## Source button protocol, independent of the canvas's chosen action identifiers.
const State=preload('res://game/battle_source_state_r23.gd')
const Record=preload('res://game/combat_record_r23.gd')
const Text=preload('res://game/combat_display_r22.gd')
const Items=preload('res://game/combat_item_data_r23.gd')
static func item(state: Dictionary,arg: String,api: Dictionary,context: Dictionary,scene: String='battle') -> void:
	if scene!='battle' or state.over!='' or not (state.get('bag') is Dictionary or state.get('bag') is Array) or state.cur<1 or state.cur>4:return
	if arg=='open':
		var any=false
		for id in Items.ORDER:
			if api.have.call(id)>0:any=true
		if not any:return
		state.pend=0;state.erase('ev');state.imenu=1;state.ipk='';state.bag=api.bag.call()
	elif arg=='cancel':
		if state.get('imenu')!=1:return
		state.imenu=0;state.ipk='';state.erase('ev')
	elif matches(arg,'^pick_[a-z_]+$'):
		var id=arg.substr(5)
		if state.get('imenu')!=1 or not Items.ITEMS.has(id) or api.have.call(id)<=0 or not api.any.call(id):return
		if id not in Items.ORDER:return
		state.ipk=id
	elif matches(arg,'^to_[1-4]$'):
		var target=int(arg.substr(3));var id=state.get('ipk','')
		if state.get('imenu')!=1 or id=='' or api.have.call(id)<=0 or not api.ok.call(id,target):return
		api.begin.call(state);state.pend=0;state.imenu=0;state.ipk='';api.take.call(id);state.n+=1;api.rbegin.call(state)
		var cur=int(state.cur);context.actor=state.u[cur-1];context.skill=null
		api.apply.call(state,id,target);api.end_turn.call(state,cur,10000);context.actor=null;api.run.call(state);state.bag=api.bag.call()
	else:return
	api.send.call(state);api.save.call(state)
static func matches(text: String,pattern: String) -> bool:
	var regex=RegEx.new();regex.compile(pattern);return regex.search(text)!=null
static func act(state: Dictionary,skills: Array,action: Variant,can_use: Callable,player: Callable,run: Callable,restart: Callable,begin: Callable=Callable()) -> Dictionary:
	if action=='reset':return state if State.truth(state.get('qid')) else restart.call(state)
	if state.over!='':return state
	if state.get('imenu')==1:state.imenu=0;state.ipk=''
	if action=='cancel':state.pend=0;state.erase('pid');state.erase('ev');return state
	var regex=RegEx.new();regex.compile('^([a-zA-Z]+)_([0-9]+)$');var found=regex.search(Text.lua_string(action))
	if found==null:return state
	var kind=found.get_string(1);var number=int(found.get_string(2));var index=int(state.cur)
	if kind=='sk':
		var list=State.cell(skills,index);var sk=State.cell(list,number)
		if not sk is Dictionary or not can_use.call(state,index,sk):return state
		if sk.tgt=='none':
			if begin.is_valid():begin.call(state)
			else:Record.begin(state)
			state.pend=0;player.call(state,number,0);run.call(state)
		else:state.pend=number;state.pid=sk.id;state.erase('ev')
	elif kind=='tg':
		var slot=int(state.pend)
		if slot==0:return state
		var sk=State.cell(State.cell(skills,index),slot)
		if not sk is Dictionary or not can_use.call(state,index,sk):state.pend=0;state.erase('pid');return state
		if sk.tgt=='enemy' and not (number>=5 and number<=state.u.size() and state.u[number-1].al==1):return state
		if sk.tgt=='ally' and not (number>=1 and number<=4 and state.u[number-1].al==1 and (number!=index or sk.get('cid','')!='marceline')):return state
		if begin.is_valid():begin.call(state)
		else:Record.begin(state)
		state.pend=0;state.erase('pid');player.call(state,slot,number);run.call(state)
	return state
