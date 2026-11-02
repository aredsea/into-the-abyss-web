from pathlib import Path
p=Path('project/tests/combat_a7_gear_audit.gd').read_text(encoding='utf-8')
p=p.replace('extends "res://tests/combat_p2_r22_trace.gd"','extends "res://tests/combat_p2_r22_trace.gd"\nconst PersonaWorld=preload("res://game/persona_world.gd")')
p=p.replace('a7-gear-oracle.json','a8-oracle.json').replace('a7-gear-audit.json','a8-audit.json').replace('A7 gear parity','A8 persona parity')
p=p.replace('var w=World.new(); w.s.party=row.party.duplicate()', '''var w=PersonaWorld.new()
		w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town"
		w.s.persona.cls=row.cls;w.s.persona.stats=row.pm[0].ps;w.s.persona.skill=row.pm[0].skill
		w.s.persona.lv=10;w.s.members.persona.level=10
		w.s.owned=row.party.slice(1);w.s.party=row.party.slice(1)''')
p=p.replace('for i in range(4):\n\t\t\tvar a=d.allies[i]; var u=row.initial[i].base','for i in range(4):\n\t\t\tvar a=d.allies[i]; var u=row.initial[i]')
p=p.replace('a.gear_member=row.pm[i]; a.gear_fx={}; a.gear_special=[]','a.gear_fx={}; a.gear_special=[]')
# First compare generated stats too; no source-stat injection into this test.
start=p.index('\t\tfor i in range(4):')
end=p.index('\t\td.inventory=',start)
p=p[:start]+'''\t\tvar generated=Battle.new(d)
		for i in range(4):
			var a=generated.data.allies[i];var u=row.initial[i]
			if not same([a.mhp,a.mmp,a.base[a.line],a.base.def,a.base.agi,a.base.spd,a.base.crit],[u.mhp,u.mmp,u.cs,u.de,u.ag,u.sp,u.cr]):
				print("INITIAL DIFFERENCE ",row.cls," ",row.combo," ",i," ",[a.mhp,a.mmp,a.base[a.line],a.base.def,a.base.agi,a.base.spd,a.base.crit]," / ",[u.mhp,u.mmp,u.cs,u.de,u.ag,u.sp,u.cr]);quit(1);return
'''+p[end:]
p=p.replace('if step%3==1:', 'if a.id=="persona" or step%3==1:')
p=p.replace('"party":row.party,"foe":row.foe', '"class":row.cls,"combo":row.combo,"party":row.party,"foe":row.foe')
p=p.replace('reports.append({','reports.append({')
p=p.replace('for row in oracle.battles+oracle.raid_battles:', 'var rows=oracle.battles+oracle.raid_battles\n\tif OS.get_cmdline_user_args().has("smoke"):rows=rows.slice(0,32)\n\tfor row in rows:')
p=p.replace('if first.is_empty(): equal_battles+=1', 'if first.is_empty(): equal_battles+=1\n\t\telif reports.size()<32:print("DIFFERENCE ",row.cls," ",row.combo," ",row.bn," ",first)')
p=p.replace('var report={','var report={')
p=p.replace('"res://../verification/data-r21/a8-audit.json"','"res://../verification/data-r21/a8-smoke.json" if OS.get_cmdline_user_args().has("smoke") else "res://../verification/data-r21/a8-audit.json"')
p=p.replace('for row in rows:', 'var w=PersonaWorld.new();var initial_world=w.s.duplicate(true)\n\tfor row in rows:')
p=p.replace('rows=rows.slice(0,32)', 'rows=rows.slice(256,512)')
p=p.replace('var w=PersonaWorld.new()\n\t\tw.s.creation_r22=', 'w.s=initial_world.duplicate(true)\n\t\tw.s.creation_r22=')
p=p.replace('var b=Battle.new(d); var used=[];', 'var b=generated;b.inventory=d.inventory.duplicate();b.data.item_defs=d.item_defs; var used=[];')
p=p.replace('reports.append({', 'if reports.size()%256==0:print("A8 progress ",reports.size()," / ",rows.size()," gaps ",reports.size()-equal_battles+1)\n\t\treports.append({')
p=p.replace('reports.size()<32','reports.size()<256 and equal_battles==reports.size()')
Path('project/tests/combat_a8_audit.gd').write_text(p,encoding='utf-8')
