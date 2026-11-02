"""Compile only the nine third-pass characters; preserve earlier deliveries."""
from copy import deepcopy
from pathlib import Path
import hashlib
import json
from dialogue_r21_build import (ROOT, CANON, STAGES, EVENTS, IDS, REGISTERS,
    source_span, section_rows, display_fields, read_json, write_json, lexicon, mentioned_names)
from dialogue_r21_round2 import TITLES

NEW_IDS = ['lynette', 'felice', 'sorel', 'tika', 'hedwig', 'berenga', 'gunhild', 'bargut', 'altan']
OUT = ROOT / 'verification/dialogue-r21'
VOICE = {
 'lynette': '다정하지만 끈질긴 해요체. 쌀과 기금부터 챙기며 가까워지면 자기 몫도 남겨 둔다.',
 'felice': '빠르고 수다스러운 해요체. 골목 이야기에서 시작해 웃음으로 덮던 외로움을 직접 말한다.',
 'sorel': '짧고 냉정한 해요체. 값을 먼저 정하되 가까운 사람의 값은 말없이 깎고 숲 이야기는 피한다.',
 'tika': '사람들 앞에서는 큰 해요체, 둘이 남으면 더듬는 작은 해요체. 친해지며 관객 없는 대화를 견딘다.',
 'hedwig': '정확한 하십시오체. 선언과 기록으로 감정을 가리고 영웅담을 진지하게 이야기한다.',
 'berenga': '붙임성 좋은 해요체. 이름책과 길 이야기를 하다가 머물고 싶다는 부탁을 꺼낸다.',
 'gunhild': '위엄을 세우는 해체. 호령하다가 칭찬 앞에서 말이 꼬이며 가까워지면 의견을 구한다.',
 'bargut': '짧은 해체. 혼자 할 몫은 지키며 밤에는 곁에 올 구실을 찾다가 직접 허락을 구한다.',
 'altan': '사무적인 하십시오체. 수량과 문서부터 확인하고 가까워져도 이익을 따지는 버릇을 유지한다.'}

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def baseline():
    target = OUT / 'baseline3.json'
    if target.exists():
        return
    files = [p for folder in ['project', 'tools'] for p in (ROOT/folder).rglob('*')
             if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts and p.suffix != '.uid'
             and not p.name.startswith('dialogue_r21_')]
    files += list((ROOT/'project/data/dialogue-r21').glob('*.json'))
    files += list(OUT.glob('kreview-2.*'))
    canon = ['docs/KOREAN-WRITING.md', 'design/stats.json', 'design/PERSONALITY-CAST.md',
             'design/COMPANIONS.md', 'design/GAP-MOE.md', 'world/wiki/terms.json',
             'bot/src/73-inn.lua', 'bot/src/74-affection.lua', 'bot/src/77-explore.lua', 'bot/src/89-memory.lua']
    write_json(target, {'workspace': {str(p.relative_to(ROOT)):digest(p) for p in files},
                        'canon': {f:digest(CANON/f) for f in canon}})

def speech(cid):
    name = IDS[cid]
    cast = source_span('design/PERSONALITY-CAST.md', '### '+name+' (', True)
    comp = source_span('design/COMPANIONS.md', '. '+name+':', True)
    lines = (CANON/cast['file']).read_text(encoding='utf-8').splitlines()[cast['line_start']:cast['line_end']]
    return {'register':VOICE[cid], 'address':'동료는 유저 직접 호칭을 생략한다. 유저 호칭은 '+TITLES[cid]+'로 고정한다. 정본 고정 호칭이 아닌 편집 규약이다.',
            'address_terms':{'companion_to_player':[], 'player_to_companion':TITLES[cid]},
            'stage_relaxation':next(s.split(': ',1)[1] for s in lines if s.startswith('- 낯섦 →')),
            'extension':'적대·불신·맹세·운명의 상세 화법은 정본 없음. 기존 말씨와 사연에서 거리와 부탁의 정도를 연장한다.',
            'source_quote':next(s.removeprefix('- 말투(발현): ') for s in lines if s.startswith('- 말투(발현):')),
            'sources':[cast,comp], 'allowed_endings':REGISTERS[cid], 'ending_exceptions':[]}

def build():
    baseline()
    template = read_json(ROOT/'project/data/dialogue-r21/saya.json')
    dictionary = lexicon()
    edits = read_json(ROOT/'tools/dialogue_r21_3_edits.json') if (ROOT/'tools/dialogue_r21_3_edits.json').exists() else []
    applied=[]
    for ci,cid in enumerate(NEW_IDS):
        d=deepcopy(template)
        d.update(character_id=cid, name=IDS[cid], speech=speech(cid), inn=[], dungeon=[], transitions=[])
        d['sources']=d['speech']['sources']
        counts={}
        for stage,row in section_rows(ROOT/f'tools/dialogue_r21_3_{cid}.txt'):
            assert stage in STAGES and len(row)==6, (cid,stage,row)
            situation,opening,pos,neutral,neg,seen=row
            counts[stage]=counts.get(stage,0)+1
            choices=[]
            for j,raw in enumerate([pos,neutral,neg]):
                text,response,reason=raw.split('~')
                choices.append(dict(id=f'c{j+1}',text=text,response=response.split('^'),aff=[2,0,-2][j],reason=reason))
            shift=(len(d['inn'])+ci)%3
            d['inn'].append(dict(id=f'{cid}-inn-{STAGES.index(stage):02d}-{counts[stage]:02d}',stage=stage,
                                situation=situation,lines=opening.split('~'),choices=choices[shift:]+choices[:shift],seen=seen))
        for who,row in section_rows(ROOT/'tools/dialogue_r21_3_dungeon.txt'):
            if who!=cid:continue
            event,*groups=row
            assert event in EVENTS and len(groups)==3
            for band,text in zip(['low','middle','high'],groups):
                d['dungeon'].append(dict(id=f'{cid}-{event}-{band}',event=event,band=band,variants=text.split('~')))
        for who,row in section_rows(ROOT/'tools/dialogue_r21_3_transitions.txt'):
            if who!=cid:continue
            pair,situation,lines=row
            a,b=map(int,pair.split('>'))
            d['transitions'].append(dict(id=f'{cid}-stage-{a}-{b}',**{'from':STAGES[a],'to':STAGES[b]},
                                         direction='up' if b>a else 'down',situation=situation,lines=lines.split('~')))
        tails=[row for who,row in section_rows(ROOT/'tools/dialogue_r21_3_response.txt') if who==cid]
        assert len(tails)==28 and {int(row[0]) for row in tails}==set(range(28)),cid
        for row in tails:
            index,negative,*positive=row
            scene=d['inn'][int(index)]
            next(c for c in scene['choices'] if c['aff']==-2)['response'].append(negative)
            if positive:
                next(c for c in scene['choices'] if c['aff']==2)['response'].append(positive[0])
        write_json(OUT/'draft3'/f'{cid}.json',d)
        for edit in edits:
            if edit['character_id']!=cid:continue
            matches=[(p,t) for p,t,_ in display_fields(d) if t==edit['before'] and ('path' not in edit or p==edit['path'])]
            assert len(matches)==1,(edit,matches)
            from dialogue_r21_build import replace_at
            replace_at(d,matches[0][0],edit['after'])
            applied.append({**edit,'path':matches[0][0]})
        d['proper_nouns']=sorted(mentioned_names('\n'.join(t for _,t,_ in display_fields(d)),dictionary))
        write_json(ROOT/f'project/data/dialogue-r21/{cid}.json',d)
    write_json(OUT/'edits3-applied.json',applied)
    print('round3 characters',len(NEW_IDS),'edits',len(applied))

if __name__=='__main__':build()
