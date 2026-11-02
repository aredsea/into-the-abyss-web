"""Compile the final nine companions, preserving all previous character bytes."""
from copy import deepcopy
import hashlib
from dialogue_r21_build import (ROOT, CANON, STAGES, EVENTS, IDS, REGISTERS,
    source_span, section_rows, display_fields, read_json, write_json, lexicon, mentioned_names, replace_at)

NEW_IDS = ['selva','ornel','zahar','jorund','lavinia','tove','miko','adeline','colette']
OUT = ROOT/'verification/dialogue-r21'
VOICE = {
 'selva':'담담한 하십시오체에 해요체가 섞인다. 보수는 정확히 정하지만 쉬는 시간에는 단골집과 식사 이야기를 한다.',
 'ornel':'관찰이 세밀한 조용한 해요체. 낯선 도시의 생활을 묻고 벌레 앞에서는 솔직히 도움을 청한다.',
 'zahar':'투박한 해체. 말보다 손이 먼저 움직인다. 가까워지면 광산과 반란 이야기를 짧게 털어놓는다.',
 'jorund':'예의 바른 하십시오체. 냉정한 계획을 유지하되 가까워지면 자기 취향과 가족 이야기도 꺼낸다.',
 'lavinia':'정확한 하십시오체와 해요체. 실무에서는 절차를 따지지만 사적인 부탁은 생활 말로 한다.',
 'tove':'조용한 해체. 추위와 불편에 무던하고 다정하다. 다른 사람을 내쫓으려 할 때는 단호하다.',
 'miko':'느긋한 해요체. 손은 부지런하고 거친 말에도 태연하다. 친해지면 쉬고 싶다는 부탁도 한다.',
 'adeline':'공손한 해요체와 하십시오체. 감사와 사양이 많지만 자기가 고른 시합에서는 말이 빨라진다.',
 'colette':'간결한 하십시오체. 엄숙한 태도를 지키려다 농담에 웃음을 참으며, 친해지면 변명을 줄인다.'}

def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def baseline():
    target=OUT/'baseline4.json'
    if target.exists(): return
    paths=[p for folder in ['project','tools'] for p in (ROOT/folder).rglob('*')
           if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts
           and p.suffix!='.uid' and not p.name.startswith('dialogue_r21_')]
    paths+=list((ROOT/'project/data/dialogue-r21').glob('*.json'))
    paths+=list(OUT.glob('kreview*'))
    canon=['docs/KOREAN-WRITING.md','design/stats.json','design/PERSONALITY-CAST.md',
           'design/PERSONALITY.md','design/COMPANIONS.md','design/GAP-MOE.md','world/wiki/terms.json',
           'bot/src/73-inn.lua','bot/src/74-affection.lua','bot/src/77-explore.lua','bot/src/89-memory.lua']
    write_json(target,{'workspace':{str(p.relative_to(ROOT)):digest(p) for p in paths},
                       'canon':{f:digest(CANON/f) for f in canon}})
    (OUT/'original-report3.md').write_bytes((ROOT/'DIALOGUE-R21.md').read_bytes())

def speech(cid):
    from dialogue_r21_round2 import TITLES
    name=IDS[cid]
    cast=source_span('design/PERSONALITY-CAST.md','### '+name+' (',True)
    comp=source_span('design/COMPANIONS.md','. '+name+':',True)
    lines=(CANON/cast['file']).read_text(encoding='utf-8').splitlines()[cast['line_start']:cast['line_end']]
    return {'register':VOICE[cid],
        'address':'동료는 유저 직접 호칭을 생략한다. 호칭은 편집 규약이며 정본 고정 호칭은 없음.',
        'address_terms':{'companion_to_player':[],'player_to_companion':TITLES[cid]},
        'stage_relaxation':next(s.split(': ',1)[1] for s in lines if s.startswith('- 낯섦 →')),
        'extension':'적대·불신·맹세·운명의 상세 화법은 정본 없음. 정본 말씨와 사연 안에서 대화의 거리만 연장한다.',
        'source_quote':next(s.removeprefix('- 말투(발현): ') for s in lines if s.startswith('- 말투(발현):')),
        'sources':[cast,comp],'allowed_endings':REGISTERS[cid],'ending_exceptions':[]}

def build():
    baseline()
    template=read_json(ROOT/'project/data/dialogue-r21/saya.json')
    dictionary=lexicon()
    edits_path=ROOT/'tools/dialogue_r21_4_edits.json'
    edits=read_json(edits_path) if edits_path.exists() else []
    applied=[]
    for ci,cid in enumerate(NEW_IDS):
        d=deepcopy(template)
        d.update(character_id=cid,name=IDS[cid],speech=speech(cid),inn=[],dungeon=[],transitions=[])
        d['speech']['address']='동료는 유저 직접 호칭을 생략한다. 유저는 '+d['speech']['address_terms']['player_to_companion']+'로 부른다. 정본 고정 호칭이 아닌 편집 규약이다.'
        d['sources']=d['speech']['sources']
        counts={}
        for stage,row in section_rows(ROOT/f'tools/dialogue_r21_4_{cid}.txt'):
            assert stage in STAGES and len(row)==6,(cid,stage,row)
            situation,opening,pos,neutral,neg,seen=[v.strip() for v in row]
            counts[stage]=counts.get(stage,0)+1
            choices=[]
            for j,raw in enumerate([pos,neutral,neg]):
                text,response,reason=raw.split('~')
                assert len(reason)>=8 and reason.endswith('.'),(cid,reason)
                choices.append(dict(id=f'c{j+1}',text=text,response=response.split('^'),aff=[2,0,-2][j],reason=reason))
            shift=(len(d['inn'])+ci)%3
            d['inn'].append(dict(id=f'{cid}-inn-{STAGES.index(stage):02d}-{counts[stage]:02d}',
                stage=stage,situation=situation,lines=opening.split('~'),choices=choices[shift:]+choices[:shift],seen=seen))
        for who,row in section_rows(ROOT/'tools/dialogue_r21_4_dungeon.txt'):
            if who!=cid: continue
            event,*groups=row
            assert event in EVENTS and len(groups)==3
            for band,text in zip(['low','middle','high'],groups):
                d['dungeon'].append(dict(id=f'{cid}-{event}-{band}',event=event,band=band,variants=text.split('~')))
        for who,row in section_rows(ROOT/'tools/dialogue_r21_4_transitions.txt'):
            if who!=cid: continue
            pair,situation,lines=row
            a,b=map(int,pair.split('>'))
            d['transitions'].append(dict(id=f'{cid}-stage-{a}-{b}',**{'from':STAGES[a],'to':STAGES[b]},
                direction='up' if b>a else 'down',situation=situation,lines=lines.split('~')))
        write_json(OUT/'draft4'/f'{cid}.json',d)
        for e in edits:
            if e['character_id']!=cid:continue
            matches=[p for p,t,_ in display_fields(d) if t==e['before'] and ('path' not in e or p==e['path'])]
            assert len(matches)==1,(e,matches)
            replace_at(d,matches[0],e['after']);applied.append({**e,'path':matches[0]})
        d['proper_nouns']=sorted(mentioned_names('\n'.join(t for _,t,_ in display_fields(d)),dictionary))
        write_json(ROOT/f'project/data/dialogue-r21/{cid}.json',d)
    write_json(OUT/'edits4-applied.json',applied)
    print('round4 characters',len(NEW_IDS),'edits',len(applied))

if __name__=='__main__':
    import sys
    baseline() if '--baseline' in sys.argv else build()
