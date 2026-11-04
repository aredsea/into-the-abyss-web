extends "res://tests/gear_hooks_r22_test.gd"
func normalize(st):
	for w in st.u:
		for k in ["x","bf","gq"]:
			if w.get(k) is Array and w[k].is_empty():w[k]={}
	return st
func predecessor(st,args,method,mode):
	st.calls.append({"k":"predecessor","args":[method,mode]})
	if mode==1:
		match method:
			"damaged":st.u[int(args[0])-1].hp=1
			"attacked":args[2].d=80
			"turn_end":st.u[int(args[0])-1].x.adv=1000
			"abyss_after":st.u[int(args[1])-1].dr=1;st.u[int(args[0])-1].mp=0
	elif mode==2:
		match method:
			"damaged":st.u[int(args[0])-1].al=0
			"attacked":st.u[int(args[1])-1].al=0
			"turn_end":st.u[int(args[0])-1].al=0
			"abyss_after":st.u[int(args[1])-1].dr=0
	return "ignored_predecessor_return"
func run():
	var fixtures=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/predecessors.json"))
	var counts={}
	for f in fixtures:
		current=normalize(f.entry.duplicate(true));hooks=Hooks.new(self);hooks.defs=f.defs
		var method=f.method;var mode=int(f.mode)
		match method:
			"damaged":hooks.predecessors[method]=func(st,t,dmg,src,at):return predecessor(st,[t,dmg,src,at],method,mode)
			"attacked":hooks.predecessors[method]=func(st,t,enemy,res,at):return predecessor(st,[t,enemy,res,at],method,mode)
			"turn_end":hooks.predecessors[method]=func(st,i):return predecessor(st,[i],method,mode)
			"abyss_after":hooks.predecessors[method]=func(st,a,t,amt,at,list):return predecessor(st,[a,t,amt,at,list],method,mode)
		var value=hooks.callv(method,[current]+f.entry_args.duplicate(true))
		check(equivalent(current,f.value),"full callback state/order "+f.meta+" "+method)
		check(equivalent("nil" if value==null else value,f.result),"ignored callback result "+method)
		counts[method]=counts.get(method,0)+1
	FileAccess.open("res://../verification/finish-r24/round3/gear-hooks-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts,"fixtures":fixtures.size()}))
	print("FINISH GEAR HOOKS R24 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
