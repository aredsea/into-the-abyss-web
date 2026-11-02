"""Record scoped translation backlog, protected hashes and final evidence."""
from pathlib import Path
import hashlib, json, re
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round10'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
base=read(O/'baseline.json')
changed=[p for p,h in base.items() if not (R/p).exists() or sha(R/p)!=h]
protected={p:h for p,h in base.items() if p.startswith(('project/assets/','project/data/')) and p!='project/data/localization-r22.json' or p.startswith('project/game/') and p not in ['project/game/localization_r22.gd','project/game/chronicle_store_r22.gd'] or p.startswith('project/ui/battle')}
assets=read(R/'ASSET-HASHES.json');sources=read(R/'verification/settings-r22/provenance.json')['files']
audit={'changed_project_files':changed,'protected_count':len(protected),'protected_changed':[p for p,h in protected.items() if sha(R/p)!=h],
 'original_assets':len(assets),'original_assets_changed':[x['path'] for x in assets if sha(R/x['path'])!=x['sha256']],
 'source_count':len(sources),'source_changed':[x['path'] for x in sources if sha(Path(x['path']))!=x['sha256']],
 'conflict_markers':[(str(p.relative_to(R)),n) for p in (R/'project').rglob('*.gd') for n,s in enumerate(p.read_text(encoding='utf-8').splitlines(),1) if s.startswith(('<<<<<<<','=======','>>>>>>>'))],
 'ui_build':read(R/'docs/version.json')['ui_build'],'pck_bytes':(R/'docs/index.pck').stat().st_size,'pck_sha256':sha(R/'docs/index.pck')}
write(O/'audit.json',audit)
ui=read(O/'ui-results.json');p8=read(R/'verification/settings-r22/ui-results.json');data=read(R/'project/data/localization-r22.json')
observed=sorted(set(ui['untranslated_observed']+p8['untranslated_observed']))
candidates=[];deferred=[]
for p in (R/'project/ui').glob('*.gd'):
    battle=p.name.startswith('battle') or p.name=='town_result_r21.gd'
    if not battle and p.name not in ['town_screen_r21.gd','persona_sortie_screen.gd','create_screen.gd','panel_screen_r22.gd','journal_screen_r22.gd','codex_screen_r22.gd','status_screen_r22.gd','inventory_screen_r22.gd','settings_screen_r22.gd']:continue
    for n,line in enumerate(p.read_text(encoding='utf-8').splitlines(),1):
        for raw in re.findall(r'"((?:[^"\\]|\\.)*)"',line):
            try:s=json.loads('"'+raw+'"')
            except ValueError:continue
            if not re.search('[가-힣]',s):continue
            row={'file':str(p.relative_to(R)).replace('\\','/'),'line':n,'text':s}
            if battle:
                row['status']='Deferred read-only battle UI literal candidate, not a rendered-string census.';deferred.append(row)
            elif s not in data['ui'] and s not in data['words']:
                row['status']='No exact whole-literal source key; joined fields/templates can translate portions. Retain remaining Korean.';candidates.append(row)
inventory={'observed_count':len(observed),'observed':observed,'town_observed_count':len(ui['untranslated_observed']),'settings_observed_count':len(p8['untranslated_observed']),
 'static_candidates':candidates,'battle_deferred':deferred,'battle_deferred_count':len(deferred),
 'deferred_name_literals':[{'file':'project/game/battle_state.gd','line':261,'text':'첫 번째 펭귄 · 힐데가르트가 대신 받음','status':'Read-only battle file; old log wording deferred. Town labels/historical display use canonical names.'}],
 'scope':'Round10: 30 states x 5 sizes plus P8 19 states x 5 sizes. Partial English only; source dictionaries and public *_en text. Static candidates are not all rendered.',
 'placeholder':'Existing {{user}} -> 당신 fallback retained because no host persona name is available.'}
write(R/'verification/settings-r22/untranslated.json',inventory)
lines=['# 10차 영어 미대응 목록','','정본에 없는 문구는 한국어로 유지한다. 일부 문구는 이름·공통 필드만 영어다. 정적 후보와 직접 렌더된 관측은 별개다.','',f'관측 {len(observed)}종 (마을 신규 {len(ui["untranslated_observed"])}종, P8 설정 등 {len(p8["untranslated_observed"])}종 합집합).','']
lines += ['- '+s.replace('\n',' / ') for s in observed]
lines += ['',f'전투 정적 후보 {len(deferred)}행은 untranslated.json의 battle_deferred에 보관한다. 전투 파일을 번역하거나 수정하지 않았다.','전투 로그의 옛 힐데가르트 표기 1곳도 별도 후속 목록에 남겼다.']
(R/'verification/settings-r22/untranslated.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
suite=read(O/'regression.json');web=read(R/'verification/town-r21/web/results.json');logic=read(O/'integration-results.json')
summary={'groups':len(suite),'failed_groups':sum(bool(x['exit_code'] or x['errors']) for x in suite),'integration_checks':logic['checks'],'integration_failures':len(logic['failures']),'legacy_archives':logic['legacy_specimens'],
 'ui_checks':ui['checks'],'ui_failures':len(ui['failures']),'native_sizes':5,'native_captures':len(ui['captures']),
 'web_configurations':len(web),'web_languages':sorted(set(x.get('lang','ko') for x in web)),'web_battles':sum(x['battles'] for x in web),'web_errors':sum(len(x['errors'])+len(x['text_errors']) for x in web),
 'web_artifact_matches':all(x['pck_sha256']==audit['pck_sha256'] for x in web),'dictionary_ui':len(data['ui']),'dictionary_words':len(data['words']),'fallback_observed':len(observed),'battle_literal_candidates':len(deferred),'audit':audit}
write(O/'summary.json',summary)
print(json.dumps({k:v for k,v in summary.items() if k!='audit'},ensure_ascii=True,indent=2))
assert not any([summary['failed_groups'],summary['integration_failures'],summary['ui_failures'],summary['web_errors'],audit['protected_changed'],audit['original_assets_changed'],audit['source_changed'],audit['conflict_markers']])
assert len(web)==7 and summary['web_artifact_matches']
