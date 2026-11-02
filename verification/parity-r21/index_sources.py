from pathlib import Path
import re,json,hashlib,bisect,sys
sys.stdout.reconfigure(encoding='utf-8')
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[1]; BOT=Path('C:/Clauede Code/dungeon-bot'); SRC=BOT/'bot/src'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
TOKEN=re.compile(r'--\[(=*)\[[\s\S]*?\]\1\]|--[^\n]*|\[(=*)\[[\s\S]*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
def mask(s):return TOKEN.sub(lambda m:''.join('\n' if c=='\n' else ' ' for c in m[0]),s)
def index(p):
 s=p.read_text(encoding='utf-8-sig');lines=s.splitlines();m=mask(s);starts=[0]+[x.end() for x in re.finditer('\n',s)]
 line=lambda pos:bisect.bisect_right(starts,pos)
 stack=[];ends={};pending=0
 for t in re.finditer(r'\b(function|if|for|while|do|repeat|end|until)\b',m):
  w=t[0]
  if w in ('function','if','repeat'):stack.append((w,t.start()))
  elif w in ('for','while'):stack.append((w,t.start()));pending+=1
  elif w=='do':
   if pending:pending-=1
   else:stack.append((w,t.start()))
  elif w in ('end','until') and stack:
   k,a=stack.pop();ends[a]=t.end()
 funcs=[]
 for t in re.finditer(r'\bfunction\b',m):
  a=t.start();ln=line(a);end=ends.get(a,a);prefix=s[starts[ln-1]:a];tail=m[t.end():t.end()+200]
  named=re.match(r'\s+([\w.:]+)\s*\(',tail)
  if named:name=named[1]
  else:
   assign=re.search(r'([\w.]+(?:\[[^\]\n]+\])*)\s*=\s*$',prefix)
   name=assign[1] if assign else f'익명 함수@{ln}'
  funcs.append({'kind':'function','name':name,'start':ln,'end':line(end-1),'offset':a,'end_offset':end})
 def parent(ln):
  f=[f for f in funcs if f['start']<=ln<=f['end']];return min(f,key=lambda f:f['end']-f['start'])['name'] if f else ''
 rows=funcs.copy()
 for ln,l in enumerate(lines,1):
  ml=m[starts[ln-1]:starts[ln] if ln<len(starts) else len(m)]
  a=re.match(r'\s*(B(?:\.[\w]+|\[[^\]]+\])+|local\s+[A-Z][A-Z_0-9]*)\s*=\s*(?!function\b)',l)
  if a and not l.lstrip().startswith('--') and re.match(r'\s*(?:B|local)',ml):
   name=a[1].replace('local ','');value=l[a.end():]
   if value.lstrip().startswith('function'):continue
   # Definition tables and constants, not transient B.xxx assignments in bodies.
   if not parent(ln) or value.lstrip().startswith(('{','[==','[====')):
    end=ln
    if value.lstrip().startswith('{'):
     pos=starts[ln-1]+l.index('{',a.end());depth=0
     for q in range(pos,len(m)):
      depth+=m[q]=='{';depth-=m[q]=='}'
      if depth==0:end=line(q);break
    rows.append({'kind':'table' if value.lstrip().startswith(('{','[')) else 'constant','name':name,'start':ln,'end':end})
  if re.search(r'\b(?:arg|act|action)\s*(?::(?:match|sub)\([^\n]*?\))?\s*(?:==|~=)|\b(?:arg|act|action):match\(',ml):
   rows.append({'kind':'route','name':l.strip().split(' then')[0][:180],'start':ln,'end':ln,'parent':parent(ln)})
   for value in re.finditer(r'\b(arg|act|action)\s*==\s*(["\'])(.*?)\2',l):
    rows.append({'kind':'route_value','name':value[1]+' == '+json.dumps(value[3],ensure_ascii=False),'start':ln,'end':ln,'parent':parent(ln)})
  # Every first button literal is a distinct route affordance, including dynamic templates.
  for b in re.finditer(r'(?:B|PX)\.btn\(\s*(["\'])([a-z][a-z0-9_]*)(\1)',l):
   rows.append({'kind':'button','name':b[2]+('…' if '..' in l[b.end():b.end()+8] else ''),'start':ln,'end':ln,'parent':parent(ln)})
  for b in re.finditer(r'risu-btn=["\']([a-z][a-z0-9_]*)',l):
   rows.append({'kind':'button','name':b[1]+'… (HTML 직접 등록)','start':ln,'end':ln,'parent':parent(ln)})
 # First occurrence of every persistent G path write, together with defaults added below.
 seen=set()
 for ln,l in enumerate(lines,1):
  for f in re.finditer(r'\b((?:G|st)(?:\.[a-zA-Z_]\w*|\[[^\]\n]*\])+)(?:\s*,\s*(?:G|st)[^=;]*)?\s*=(?!=)',l):
   name=f[1]
   if name not in seen:rows.append({'kind':'save_field','name':name,'start':ln,'end':ln,'parent':parent(ln)});seen.add(name)
 if p.name=='01-game.lua':
  for ln in range(15,41):
   for f in re.finditer(r'^\s*([a-z_]\w*)\s*=',lines[ln-1]):
    name='G.'+f[1]
    if name not in seen:rows.append({'kind':'save_field','name':name,'start':ln,'end':ln,'parent':'B.G_new'});seen.add(name)
 # Explicit source coverage for code/data that is not under any recognized function/table.
 cover=set()
 for r in rows:
  if r['kind'] in ('function','table'):cover.update(range(r['start'],r['end']+1))
 run=[]
 def flush():
  if run:rows.append({'kind':'module_rule','name':'모듈 초기화·등록·상수/규칙','start':run[0],'end':run[-1]});run.clear()
 for ln,l in enumerate(lines,1):
  if ln not in cover and l.strip() and not l.lstrip().startswith('--'):run.append(ln)
  else:flush()
 flush()
 # Qualify hooks inside B.TR tables, and nested callbacks, instead of losing
 # their owner when Lua writes `start = function(...)`.
 for r in rows:
  if r['kind']=='function' and not re.match(r'^(?:B|PX|SO|G)\b',r['name']):
   tables=[t for t in rows if t['kind']=='table' and t['start']<=r['start']<=t['end'] and t['name'].startswith('B.')]
   if tables:
    t=min(tables,key=lambda x:x['end']-x['start']);r['name']=t['name']+'.'+r['name']
 for r in rows:
  if r['kind']=='function' and r['name'].startswith('익명'):
   owners=[t for t in rows if t['kind']=='function' and t is not r and t['start']<=r['start']<=t['end'] and t['end']-t['start']>r['end']-r['start']]
   if owners:r['name']=min(owners,key=lambda x:x['end']-x['start'])['name']+'::'+r['name']
 # Multiple assignment declarations (storage keys in particular) must not
 # disappear merely because they share a physical source line.
 for ln,l in enumerate(lines,1):
  declaration=re.match(r'\s*((?:B\.[A-Za-z_]\w*\s*,\s*)+B\.[A-Za-z_]\w*)\s*=',l)
  if declaration:
   for name in re.findall(r'B\.[A-Za-z_]\w*',declaration[1]):
    rows.append({'kind':'constant','name':name,'start':ln,'end':ln})
 # Mutation fields on known Lua state aliases. Their receiver ownership is
 # recorded explicitly; unknown local ownership is never treated as parity.
 receivers={
  '20-state.lua':['u'], '30-engine.lua':['u','v','w'], '31-foes.lua':['u','v','w'],
  '32-personal-a.lua':['u','v','w','x'], '32-personal-b.lua':['u','v','w','x'],
  '34-traits.lua':['u','v','w','x'], '60-create.lua':['p'],
  '70-town.lua':['T'], '72-guild.lua':['T'], '73-inn.lua':['T'], '74-level.lua':['T'],
  '76-dungeon.lua':['D'], '77-explore.lua':['R','D','T'], '78-battle-item.lua':['u'],
  '79-sex.lua':['R','T','u'], '81-gear.lua':['u','v','w','f'], '82-smithy.lua':['w']}
 aliases=receivers.get(p.name,[]);seen_alias=set()
 if aliases:
  rx=re.compile(r'\b((?:'+ '|'.join(aliases)+r')(?:\.[A-Za-z_]\w*|\[[^\]\n]*\])+)(?:\s*,[^=\n]*)?\s*=(?!=)')
  for ln,l in enumerate(lines,1):
   ml=m[starts[ln-1]:starts[ln] if ln<len(starts) else len(m)]
   owners=[f for f in rows if f['kind']=='function' and f['start']<=ln<=f['end']]
   owner=min(owners,key=lambda f:f['end']-f['start'])['name'] if owners else '모듈'
   for v in rx.finditer(ml):
    field=l[v.start(1):v.end(1)];name=owner+'::$'+field
    if name not in seen_alias:
     rows.append({'kind':'state_field','name':name,'start':ln,'end':ln,'parent':owner,'alias':field});seen_alias.add(name)
 # Every top-level field of the battle constructor/prototype literal.
 if p.name=='20-state.lua':
  for symbol,pattern in [('unit0',r'\breturn\s*(\{)'),('B.fresh',r'\blocal\s+st\s*=\s*(\{)')]:
   f=next(x for x in rows if x['kind']=='function' and x['name']==symbol)
   a=starts[f['start']-1];b=starts[f['end']] if f['end']<len(starts) else len(m);match=re.search(pattern,m[a:b]);pos=a+match.start(1);depth=0
   for t in re.finditer(r'\{|\}|\b[A-Za-z_]\w*\s*=(?!=)',m[pos:b]):
    if t[0]=='{':depth+=1
    elif t[0]=='}':
     depth-=1
     if depth==0:break
    elif depth==1:
     field=t[0].split('=')[0].strip();ln=line(pos+t.start());rows.append({'kind':'state_field','name':symbol+'::기본필드.'+field,'start':ln,'end':ln,'parent':symbol,'alias':field})
 for r in rows:r['source_file']=p.name
 return {'file':p.name,'lines':len(lines),'newline_count':s.count('\n'),'ends_with_newline':s.endswith('\n'),'sha256':sha(p),'read_ranges':[[1,len(lines)]],'read_method':'UTF-8 전체 바이트/행·토큰 검사; 의미 판정은 행별 근거에 한정','features':sorted(rows,key=lambda r:(r['start'],r['kind'],r['name'])),'parse_unclosed_blocks':[(k,line(a)) for k,a in stack]}
def main():
 files=[index(p) for p in sorted(SRC.glob('*.lua'))]
 (OUT/'source-index.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf-8')
 auxiliary=[]
 for p in sorted(list((BOT/'design').glob('*.md'))+list((BOT/'bot').glob('harness*.mjs'))+[BOT/'bot'/n for n in ['ARCHITECTURE.md','ASSETS.md','PERSONAL-PORT.md','lua_sim.mjs']]):
  text=p.read_text(encoding='utf-8-sig');auxiliary.append({'path':str(p),'lines':len(text.splitlines()),'sha256':sha(p),'headings':[{'line':n,'text':l[:180]} for n,l in enumerate(text.splitlines(),1) if re.match(r'^#{1,4} ',l)]})
 (OUT/'auxiliary-index.json').write_text(json.dumps(auxiliary,ensure_ascii=False,indent=2),encoding='utf-8')
 game=[]
 for p in sorted((ROOT/'project').rglob('*.gd')):
  if '.godot' in p.parts:continue
  text=p.read_text(encoding='utf-8-sig');ls=text.splitlines();defs=[]
  for n,l in enumerate(ls,1):
   f=re.match(r'^(?:static )?func\s+(\w+)',l)
   if f:defs.append({'name':f[1],'line':n})
  for i,d in enumerate(defs):d['end']=defs[i+1]['line']-1 if i+1<len(defs) else len(ls)
  game.append({'path':p.relative_to(ROOT).as_posix(),'lines':len(ls),'sha256':sha(p),'functions':defs})
 (OUT/'game-index.json').write_text(json.dumps(game,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({'files':len(files),'lines':sum(f['lines'] for f in files),'features':sum(len(f['features']) for f in files),'kinds':{k:sum(r['kind']==k for f in files for r in f['features']) for k in ['function','route','button','save_field','table','constant','module_rule']},'unclosed':{f['file']:f['parse_unclosed_blocks'] for f in files if f['parse_unclosed_blocks']}},ensure_ascii=False))
 for f in files:print(f['file'],f['lines'],len(f['features']))
if __name__=='__main__':main()
