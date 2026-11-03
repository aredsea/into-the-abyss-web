extends "res://tests/battle_r23_round9_core_test.gd"
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round9-items-oracle.json'))
	var api=load('res://game/combat_items_r23.gd') if FileAccess.file_exists('res://game/combat_item_data_r23.gd') else null
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;c.op=row.op
			var selected=OS.get_environment('R23_ROUND9_OPS')
			if not selected.is_empty() and not row.op in selected.split(','):continue
			var got='API unavailable';var want=row.expected
			if api!=null:
				match row.op:
					'cur_i':got=api.current_actor(c)
					'item_name':got=api.item_name(c.id)
					'item_button':got=api.button(c.state.get('bag'),c.lang);want=row.expected.view
					'item_menu','item_targets','item_apply':
						var b=setup_nine(c);b.current_id=b.data.allies[int(c.state.cur)-1].id
						for j in range(4):
							var w=b.data.allies[j];w.level=c.defs[j].get('lv',1);w.mp=c.state.u[j].mp;w.mmp=c.state.u[j].mmp
							w.nation={'marento':'마렌토 공화국','solen':'솔렌 성왕국'}.get(c.state.u[j].na,'')
							w.charging=c.state.u[j].chg==1;w.broken=c.state.u[j].dr==1
							if c.state.u[j].has('gq'):w.gear_fx=c.state.u[j].gq.duplicate(true)
							if c.state.u[j].fx>0:w.effects.foxflame={"amount":c.state.u[j].fx,"turns":3}
							if c.state.u[j].mk>0:w.effects.mark={"amount":1,"turns":3}
							if c.state.u[j].x.has('psrg'):
								var regen=c.state.u[j].x.psrg;w.effects.persona_regen={"amount":regen.d,"turns":regen.n,"order":regen.s};b.x(w).erase('psrg')
						if c.get('gear',false):b.gear_bridge=b.GearBattle.new(b)
						if row.op=='item_menu':got=api.menu(b,c.state.get('bag'),c.state.get('ipk',''),c.lang);want=row.expected.view
						elif row.op=='item_targets':
							var flags=[]
							for j in range(6):
								var target=b.data.allies[j-1] if j>=1 and j<=4 else {}
								flags.append({"state":api.state_ok(b,c.iid,target),"ok":api.target_ok(b,c.iid,target)})
							got={"flags":flags,"any":api.any_target(b,c.iid),"blocked":api.blocked(b,c.iid)}
						else:
							var value=api.apply(b,c.iid,b.data.allies[int(c.target)-1]);got=project_nine(b,c,value)
							for j in range(4):
								var w=b.data.allies[j];got.units[j].fx=b.fx(w,'foxflame');got.units[j].chg=1 if w.charging else 0;got.units[j].dr=1 if w.broken else 0;got.units[j].mk=1 if w.effects.has('mark') else 0;got.units[j].dot=got.units[j].get('dot',[])
							for j in range(c.state.u.size()):
								if j>=4:got.units[j].fx=0
								for key in ['dot','edot']:
									if not c.state.u[j].has(key) and got.units[j].get(key,[]).is_empty() and not (j==int(c.target)-1 and c.iid in ['antidote','bandage']):got.units[j].erase(key)
			check(same(got,want),'round9/%s/%s/%d'%[row.op,part.file,i],got,want)
	var suffix=OS.get_environment('R23_ROUND9_OUTPUT');if suffix.is_empty():suffix='latest'
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-items-'+suffix+'.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND9 ITEMS ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
