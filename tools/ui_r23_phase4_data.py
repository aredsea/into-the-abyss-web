from pathlib import Path
import json,re,hashlib,shutil
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23/ui-phase4'
def dump(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
oracle=json.loads((O/'ui-oracle.json').read_text(encoding='utf-8'));p=R/'project/data/localization-r22.json';data=json.loads(p.read_text(encoding='utf-8'))
# Adult content is outside this port. Keep an explicit inventory, not silent fallback.
adult=re.compile(r'NSFW|섹스|성관계|성교|접대부|애무|자위|절정|삽입|발정|음란|정액|질내|유두|유방|(?<![가-힣])음부(?![가-힣])|음경|보지|자지|sx_|sex_',re.I)
excluded=oracle.get('excluded',{k:[s for s in oracle['packs'][k] if adult.search(s)] for k in ['ui','words']})
changes=json.loads((O/'ui-dictionary-changes.json').read_text(encoding='utf-8')) if (O/'ui-dictionary-changes.json').exists() else []
removed=[]
for c in reversed(changes):
    if c['key'] not in excluded[c['section']]:continue
    if c['before'] is None:data[c['section']].pop(c['key'],None)
    else:data[c['section']][c['key']]=c['before']
    removed.append({'section':c['section'],'key':c['key'],'reason':'adult-only source module; no runtime translation is added'})
changes=[c for c in changes if c['key'] not in excluded[c['section']]]
if removed:dump(O/'ui-adult-dictionary-removals.json',removed)
for section in ['ui','words']:
    for k,v in oracle['packs'][section].items():
        if k in excluded[section]:continue
        if data[section].get(k)!=v:changes.append({'section':section,'key':k,'before':data[section].get(k),'after':v});data[section][k]=v
for k,v in {'현재 모험은 보관 사본으로 남습니다.':'A backup of this adventure will be kept.','로컬 자동 저장':'Saved automatically on this device.'}.items():
    if data['ui'].get(k)!=v:changes.append({'section':'ui','key':k,'before':data['ui'].get(k),'after':v,'scope':'native storage note'});data['ui'][k]=v
dump(p,data);dump(O/'ui-dictionary-changes.json',changes);dump(O/'ui-excluded-translation-keys.json',excluded)
baseline=json.loads(json.dumps(data))
for c in reversed(changes):
    if c['before'] is None:baseline[c['section']].pop(c['key'],None)
    else:baseline[c['section']][c['key']]=c['before']
dump(O/'ui-localization-before.json',baseline)
dump(R/'project/data/ui-source-locale-r23.json',{section:{k:v for k,v in oracle['packs'][section].items() if k not in excluded[section]} for section in ['ui','words']})
dump(R/'project/data/ui-legacy-items-r23.json',oracle['items'])
assets=[];target=R/'project/assets/ui-traits-r23';target.mkdir(exist_ok=True)
for src in Path('C:/Clauede Code/dungeon-bot/bot/assets').glob('ic_t_*.webp'):
    dst=target/('t-'+src.stem[5:]+src.suffix);shutil.copyfile(src,dst);assets.append({'source':str(src),'path':dst.relative_to(R).as_posix(),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest()})
dump(O/'ui-trait-assets.json',assets)
print('dictionary changes',len(changes),'excluded',sum(map(len,excluded.values())))
