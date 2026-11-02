from pathlib import Path
import json,hashlib,sys,copy,ast
sys.stdout.reconfigure(encoding='utf-8')
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[1];BOT=Path('C:/Clauede Code/dungeon-bot')
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def main():
 c=read(OUT/'lua-constants.json');w=read(ROOT/'project/data/world.json');e=read(ROOT/'project/data/enemies-r21.json');d=read(ROOT/'project/data/dungeons-r21.json');g=read(ROOT/'project/data/gear.json')
 checks=[]
 def projection(template,value):
  if isinstance(template,dict) and isinstance(value,dict):return {k:projection(v,value.get(k)) for k,v in template.items()}
  if isinstance(template,list) and isinstance(value,list):return [projection(t,v) for t,v in zip(template,value)] if len(template)==len(value) else value
  return value
 def check(id,a,b,source,target,scope='데이터 값만; 실행 동작은 별도 판정'):
  same=a==b;checks.append({'id':id,'same':same,'source':source,'target':target,'scope':scope,'source_value_sha256':hashlib.sha256(json.dumps(a,ensure_ascii=False,sort_keys=True).encode()).hexdigest(),'game_value_sha256':hashlib.sha256(json.dumps(b,ensure_ascii=False,sort_keys=True).encode()).hexdigest()});return same
 for name in ['gear.json','gear_effects.json','shop.json','persona_skill.json']:
  check('design:'+name,read(BOT/'design'/name),read(ROOT/'project/data'/name),'design/'+name,'project/data/'+name)
 clean=copy.deepcopy(e);clean.pop('source',None)
 for x in clean['enemies']:x.pop('art',None);x.pop('source',None)
 check('design:enemies.json',read(BOT/'design/enemies.json'),clean,'design/enemies.json','project/data/enemies-r21.json (art/source 메타데이터 제거)')
 srcstats=read(BOT/'design/stats.json')
 check('design:classes',srcstats['classes'],w['classes'],'design/stats.json#/classes','project/data/world.json#/classes')
 check('design:companions',srcstats['companions'],w['companions'],'design/stats.json#/companions','project/data/world.json#/companions')
 for key,target in [('FM','formula'),('CURVES','curves'),('ENEMY_STD','enemy_std'),('STARS','stars'),('LEVEL_MAX','level_max')]:
  a=c[key];b=d['stats'][target]
  if isinstance(b,list) and isinstance(a,dict):a=[a[str(i)] if str(i) in a else a[i] for i in range(1,len(b)+1)]
  check(key,a,projection(a,b),'05-gen.lua::B.'+key,'project/data/dungeons-r21.json#/stats/'+target)
 for key,target in [('EX','explore'),('AFF','affection'),('ZONE_ORDER','zone_order')]:check(key,c[key],d[target],key,'project/data/dungeons-r21.json#/'+target)
 for key,target in [('ROLES','roles'),('GRADES','grades'),('ACT_DEFAULTS','act_defaults'),('THREAT','threat'),('TEMPLATES','templates')]:
  check(key,c[key],projection(c[key],e[target]),key,'project/data/enemies-r21.json#/'+target)
 for key,target in [('TUNE_FLOOR','star'),('DEEP','deep'),('CURVE','curve'),('BOSSR','boss'),('REWARDR','reward')]:
  b=e['tune'].get(target)
  if isinstance(c[key],list) and isinstance(b,dict):b=[b[str(i)] for i in range(1,len(c[key])+1)]
  check(key,c[key],projection(c[key],b),key,'project/data/enemies-r21.json#/tune/'+target)
 check('SHOP_RAW',c['SHOP_RAW'],read(ROOT/'project/data/shop.json'),'05-gen.lua:335','project/data/shop.json')
 check('PERSONA_RAW',c['PERSONA_RAW'],read(ROOT/'project/data/persona_skill.json'),'05-gen.lua:382','project/data/persona_skill.json')
 for i,v in enumerate(w['classes']):
  a=c['CLS'][v['id']];check('class:'+v['id'],a,projection(a,v),'05-gen.lua::B.CLS.'+v['id'],f'project/data/world.json#/classes/{i}')
 for key,target in [('FAMS','families'),('ZONES','zones'),('RIFTS','rifts')]:
  values=e[target]
  for i,v in enumerate(values):
   a=c[key][v['id']-1] if key=='FAMS' and isinstance(c[key],list) else c[key].get(str(v['id']),c[key].get(v['id']))
   check(key+':'+str(v['id']),a,projection(a,v),'05-gen.lua::B.'+key+'.'+str(v['id']),f'project/data/enemies-r21.json#/{target}/{i}')
 def gear_projection(v):
  z=copy.deepcopy(v)
  if 'sig' in z:
   sig=z.pop('sig');z.pop('eff_measured',None);z['unique']={'key':sig['key'],'v':sig['v'],'name':sig['name'],'text':sig['text'],'sig':True,'e':sig['eff']}
  return z
 for i,v in enumerate(g['items']):check('gear:'+v['id'],c['GEAR_EXPANDED']['items'][v['id']],gear_projection(v),'05-gen.lua:332 -> 81-gear.lua:11-58#/'+v['id'],f'project/data/gear.json#/items/{i}')
 for i,v in enumerate(w['companions']):
  a=c['CAST'][v['id']];z={'id':v['id'],'name':v['name'],'full':v['full_name'],'race':v['race'],'lineage':v['lineage'],'nation':v['nation'],'cls':v['class'],'row':v['row'],'el':v['element'],'mod':v['mod'],'skill':v['skill']['name'],'skill_mp':v['skill']['mp'],'skill_d':v['skill']['note'],'skill_tgt':{'아군 1':'ally','적 1':'enemy','아군 전체':'none','적 전체':'none','자신':'none','없음':'none'}.get(v['skill']['target'],'?'),'trait':v['trait']['name'],'trait_d':v['trait']['note'],'bg':v['background']}
  # Generated skill_tgt may be overridden by B.PSK at runtime (e.g. Gerda).
  a=copy.deepcopy(a);a.pop('skill_tgt',None);z.pop('skill_tgt',None)
  check('cast:'+v['id'],a,z,'05-gen.lua::B.CAST.'+v['id'],f'project/data/world.json#/companions/{i}', '표시/기초 메타데이터; 기술 대상은 20-state:98의 PSK 우선순위 때문에 별도 기능 행에서 판정')
  check('trait:'+v['id'],c['GEN']['tr'][v['id']],v['trait']['p'],'05-gen.lua::B.GEN.tr.'+v['id'],f'project/data/world.json#/companions/{i}/trait/p')
 # Source Lua compile stage adds dispatch/UI defaults to enemy acts. Compare the
 # canonical rule data directly, and separately retain this explicit transform.
 # Extract only the original, pure schema compiler. Never import/run build.py.
 tree=ast.parse((BOT/'bot/build.py').read_text(encoding='utf-8-sig'));ns={}
 for node in tree.body:
  if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id in ('ATTACK_KINDS','IC_OF','ROW_KO') for t in node.targets):exec(compile(ast.Module(body=[node],type_ignores=[]),'<canonical constants>','exec'),ns)
  if isinstance(node,ast.FunctionDef) and node.name=='foe_act':exec(compile(ast.Module(body=[node],type_ignores=[]),'<canonical foe_act>','exec'),ns)
 act=lambda a:ns['foe_act'](a,set(e['kinds']),'read-only parity projection')
 for i,v in enumerate(e['enemies']):
  a=c['FOES'][v['id']];gr=e['grades'][v['grade']]
  b={'id':v['id'],'name':v['name'],'fam':v['family'],'zone':v['zone'],'grade':v['grade'],'role':v['role'],'srole':v.get('stat_role',v['role']),'row':ns['ROW_KO'][v['row']],'wk':v['weak'],'looks':v.get('looks',''),'kind':gr['kind'],'elite':gr['kind']=='elite','acts':[act(z) for z in v['acts']]}
  for key in ['gauge','rules','legacy','deep']:
   if v.get(key):b[key]=v[key]
  if v.get('phase2'):
   p=v['phase2'];b['ph2']={'wk':p['weak'],'acts':[act(z) for z in p['acts']]}
   if p.get('entry'):b['ph2']['entry']=act(p['entry'])
   if p.get('weak_cycle'):b['ph2']['cycle']=True
  check('foe:'+v['id'],a,b,'05-gen.lua::B.FOES.'+v['id'],f'project/data/enemies-r21.json#/enemies/{i}', 'build.py:212-215,267-299,409-433의 순수 데이터 변환만 AST로 추출·적용; 빌드 실행/쓰기 없음')
 # Keep both passing and failing projections; a failed transform is not a game bug.
 report={'checks':checks,'passed':sum(x['same'] for x in checks),'not_equal':sum(not x['same'] for x in checks),'projection_failures_are_not_automatically_game_defects':True}
 (OUT/'data-comparison.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({'checks':len(checks),'passed':report['passed'],'not_equal':report['not_equal'],'non_record_checks':[{'id':x['id'],'same':x['same']} for x in checks if not x['id'].startswith(('gear:','cast:','trait:','foe:'))],'record_failures':[{k:x[k] for k in ['id','same']} for x in checks if not x['same']][:12]},ensure_ascii=False))
if __name__=='__main__':main()
