"""Scan actual rendered copy plus every data file and UI script. No source rewrites."""
from pathlib import Path
import collections,json,re,sys
R=Path(__file__).resolve().parents[1];O=R/'verification/finish-r24'
def strings(v,path='$'):
    if isinstance(v,dict):
        for k,x in v.items():yield from strings(x,path+'.'+str(k))
    elif isinstance(v,list):
        for i,x in enumerate(v):yield from strings(x,path+f'[{i}]')
    elif isinstance(v,str):yield path,v
hangul=re.compile('[가-힣]');macro=re.compile(r'\{\{[^}]*\}\}')
panels=json.loads((R/'project/data/panels-r22.json').read_text(encoding='utf-8'))
locale=json.loads((R/'project/data/localization-r22.json').read_text(encoding='utf-8'))
english_names={locale['words'].get(c['name'],'') for c in panels['cast'].values()}
english_names.discard('');english_names={n for n in english_names if not hangul.search(n)}
def defects(row):
    t=row['text'];why=[]
    if macro.search(t):why.append('unresolved host placeholder')
    if t in ['{','}']:why.append('orphaned host-placeholder initial')
    if row['lang']=='en' and hangul.search(t):why.append('Korean copy in English setting')
    if row['lang']=='ko':
        account_code=re.fullmatch(r'[A-Z0-9]{4}(?:-[A-Z0-9]{4}){2}',t)
        if not hangul.search(t) and len(re.findall('[A-Za-z]{2,}',t))>=3 and t!='English' and not account_code:why.append('English sentence in Korean setting')
        if any(re.search(r'(?<![A-Za-z])'+re.escape(n)+r'(?![A-Za-z])',t) for n in english_names):why.append('English companion name in Korean setting')
    return why
if '--self-test' in sys.argv:
    assert defects({'lang':'ko','text':'First met Teiris, who joined as a companion.'})
    assert defects({'lang':'ko','text':'{{user}} · 페르소나'})
    assert defects({'lang':'ko','text':'레벨이 올랐다: Teiris Lv 1 → 2'})
    assert defects({'lang':'en','text':'금화 300'})
    assert not defects({'lang':'ko','text':'당신 · 페르소나'})
    assert not defects({'lang':'en','text':'You · Persona'})
    assert not defects({'lang':'ko','text':'ABCD-EFGH-JKMP'})
    assert defects({'lang':'ko','text':'{'})
    print('scan detector: 8 assertions passed')
rows=json.loads((O/'screen-strings.json').read_text(encoding='utf-8'))
bad=[{**row,'reasons':why} for row in rows if (why:=defects(row))]
inventory=[];data_values=0;raw_macros=[]
for p in sorted((R/'project/data').rglob('*.json')):
    values=list(strings(json.loads(p.read_text(encoding='utf-8-sig'))));data_values+=len(values)
    hits=[{'path':key,'tokens':macro.findall(value)} for key,value in values if macro.search(value)]
    raw_macros.extend({'file':p.relative_to(R).as_posix(),**h} for h in hits)
    inventory.append({'file':p.relative_to(R).as_posix(),'strings':len(values),'host_placeholder_fields':len(hits)})
unsupported=[h for h in raw_macros if any(token!='{{user}}' for token in h['tokens'])]
scripts=[]
for p in sorted((R/'project/ui').glob('*.gd')):
    text=p.read_text(encoding='utf-8');scripts.append({'file':p.relative_to(R).as_posix(),'host_tokens':sorted(set(macro.findall(text)))})
result={'rendered_strings':len(rows),'screen_language_states':len({(r['screen'],r['lang']) for r in rows}),'defects':bad,'language_defects':sum(any('setting' in s for s in r['reasons']) for r in bad),'placeholder_defects':sum(any('placeholder' in s for s in r['reasons']) for r in bad),'data_files':len(inventory),'data_strings':data_values,'data_inventory':inventory,'raw_data_macro_fields':raw_macros,'unsupported_data_macros':unsupported,'ui_scripts':scripts,'scope':'All data values and UI scripts inventoried. Bilingual dictionaries, source host contracts and templates are retained; emitted copy is checked after language/name resolution. Custom user free text is not translated. Screen coverage is listed explicitly; state combinations beyond these fixtures are not claimed exhaustive.'}
authored=O/'authored-language-audit.json'
if authored.exists():
    a=json.loads(authored.read_text(encoding='utf-8'));result.update({'authored_display_fields':a['fields'],'authored_untranslated':a['untranslated'],'all_language_complete':not bad and a['untranslated']==0})
(O/'locale-scan.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k in ['rendered_strings','screen_language_states','language_defects','placeholder_defects','data_files','data_strings','authored_untranslated','all_language_complete']},ensure_ascii=False))
if bad:print(json.dumps(bad[:12],ensure_ascii=False,indent=2))
raise SystemExit(bool(bad or unsupported or result.get('authored_untranslated',0)))
