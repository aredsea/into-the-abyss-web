from pathlib import Path
import json,shutil
p=Path(__file__).resolve().parent;repo=p.parents[1]/'outputs/github-publication'
game=repo/'project/assets/motion-r8';lab=repo/'docs/motion-lab/r8';assets=lab/'assets'
game.mkdir(parents=True,exist_ok=True);assets.mkdir(parents=True,exist_ok=True)
read=lambda f:json.loads(f.read_text(encoding='utf-8'))
chars={'hildegard':'힐데가르트','bargut':'바르구트','teiris':'테이리스','berenga':'베렝가'}
catalog={};web={'characters':{},'clips':{}}
for id,name in chars.items():
    src=p/(id+'-seed.png');shutil.copy2(src,game/src.name);shutil.copy2(src,assets/src.name)
    web['characters'][id]={'name':name,'seed':'assets/'+src.name,'actions':[]}
angles={'guard':[29,-10,-55,-65,-65,-65,-10,29], 'taunt':[29,15,-15,-15,-15,-15,-45,-65,0,29], 'personal':[29,-5,-45,-72,-72,-72,-65,-40,-5,29]}
anchors={'guard':[[88,125],[97,126],[133,119],[136,116],[128,122],[135,117],[111,121],[88,125]],'taunt':[[88,125],[92,124],[129,119],[132,123],[127,118],[128,120],[133,120],[136,117],[107,123],[88,125]],'personal':[[88,125],[90,124],[134,122],[151,120],[157,122],[150,122],[135,118],[126,118],[98,126],[88,125]]}
titles={'idle':'대기','attack':'일반 공격','guard':'방어','taunt':'도발','personal':'고유 스킬','cast':'파티 축복','charge':'마력 충전'}
skills={'hildegard':'전방 근무 개시','bargut':'선점 효과','teiris':'마감 전날 대폭발','berenga':'트리아지'}
notes={
'idle':'발을 고정하고 호흡과 머리카락·옷자락의 움직임을 확인합니다.',
'hildegard:attack':'몸을 모으고 발을 디딘 뒤 상체를 돌려 크게 벱니다. 검기는 없습니다.',
'hildegard:guard':'무릎을 낮추고 장검을 세워 몸 앞을 지킵니다. 실제 방패 장비는 추가하지 않습니다.',
'hildegard:taunt':'적을 향해 빈손을 내밀고 당긴 뒤 방어 자세로 받습니다.',
'hildegard:personal':'앞발을 디디고 장검을 세워 전선을 막습니다. 피해 감소·도발을 부여하는 기술입니다.',
'bargut:attack':'낮게 중심을 모으고 짧게 파고들어 단검으로 벤 뒤 발을 거둡니다.',
'bargut:personal':'낮은 진입에서 두 단검으로 한 표적을 기습한 뒤 빠르게 회수합니다.',
'teiris:attack':'수정 지팡이를 받치고 빈손을 내밀어 한 적에게 마력을 보냅니다.',
'teiris:personal':'짧게 몸을 모으고 손바닥을 밀어 즉시 발동한 뒤 반동을 받아냅니다. 긴 충전이 없습니다.',
'berenga:attack':'나무 성표 지팡이를 잡고 한 적을 향해 손을 뻗습니다.',
'berenga:personal':'몸을 기울여 한 아군을 살피고 빈손을 둥글게 펴 치유할 곳을 지정합니다.',
'cast':'지팡이를 받치고 빈팔을 넓게 열어 파티를 향해 축복합니다.',
'charge':'마력을 모으는 준비 자세입니다. 이 단계에서 폭발 피해를 표현하지 않습니다.',
'guard':'몸을 낮추고 무기를 가까이 모아 방어한 뒤 원래 자세로 돌아갑니다.'}
def add(id,action,src,holds,contact):
    key=id+':'+action;name=id+'-'+action+'.png';shutil.copy2(src/'sheet.png',game/name);shutil.copy2(src/'sheet.png',assets/name)
    shutil.copy2(src/'contact.png',assets/(id+'-'+action+'-contact.png'))
    c={'key':key,'path':'res://assets/motion-r8/'+name,'frames':len(holds),'frame_size':256,'columns':5,'body_height':204,'foot_y':230,'root_motion':True,'durations_ms':holds,'duration':sum(holds)/1000,'contact_frame':contact,'impact_at':sum(holds[:contact])/1000,'label':skills[id] if action=='personal' else titles[action],'note':notes.get(key,notes.get(action,'')),'contact_sheet':'assets/'+id+'-'+action+'-contact.png','reference_path':'res://assets/motion-r8/'+id+'-seed.png','reference_frames':[0,len(holds)-1]}
    if id=='hildegard' and action in angles:
        c['weapon']={'path':'res://assets/motion-r7/hildegard-sword.png','pivot':[88,125],'base_angle':29,'hand_patch':[-3,-4,7,9],'anchors':[pos+[a] for pos,a in zip(anchors[action],angles[action])]}
    catalog[key]=c
for id in chars:
    for action in ['idle','attack','guard','taunt','personal','cast','charge']:
        src=p/(id+'-'+action+('-selected' if action in ['attack','personal'] else '') if id=='bargut' else id+'-'+action)
        if id=='hildegard' and action=='attack':
            c=read(repo/'project/data/combat-motion.json').get('hildegard:attack',{})
            if c.get('path','').endswith('hildegard-attack-body.png'):
                c.update(key='hildegard:attack',label='일반 공격',note=notes['hildegard:attack'],contact_sheet='../r7/assets/contact.png',reference_path='res://assets/motion-r8/hildegard-seed.png',reference_frames=[0,11]);catalog['hildegard:attack']=c
            else:
                c=read(p.parent/'motion-r7/clip.json');c.update(path='res://assets/motion-r7/hildegard-attack-body.png');c['weapon']['path']='res://assets/motion-r7/hildegard-sword.png';c.update(key='hildegard:attack',label='일반 공격',note=notes['hildegard:attack'],contact_sheet='../r7/assets/contact.png',reference_path='res://assets/motion-r8/hildegard-seed.png',reference_frames=[0,11]);catalog['hildegard:attack']=c
            continue
        if not (src/'sheet.png').exists(): continue
        n=read(src/'audit.json')['frames']
        if action=='idle':holds=[340,260,240,260,360,260,240,260,340];contact=0
        elif id=='hildegard' and action=='guard':holds=[55,60,65,150,100,100,80,70];contact=3
        elif id=='hildegard' and action=='taunt':holds=[45,60,85,80,60,80,70,90,70,65];contact=3
        elif id=='hildegard' and action=='personal':holds=[45,70,60,65,140,85,75,65,65,65];contact=3
        elif id=='bargut' and action=='attack':holds=[45,60,45,65,60,60,55,65,65,60];contact=3
        elif id=='bargut' and action=='personal':holds=[40,45,45,35,25,65,65,65,60,60,55,50];contact=5
        elif action=='guard':holds=[50,65,75,110,110,90,75,65,60];contact=3
        elif action in ['cast','charge']:holds=[60,75,80,100,120,95,80,70,70];contact=4
        else:holds=[40,50,55,45,55,70,70,65,65,65,60,55,50];contact=6 if id=='berenga' and action=='personal' else 2 if id=='berenga' and action=='attack' else 4
        assert n==len(holds),(id,action,n,len(holds));add(id,action,src,holds,contact)
for key,c in catalog.items():
    w=json.loads(json.dumps(c));id,action=key.split(':')
    w['path']='../r7/assets/hildegard-attack-body.png' if key=='hildegard:attack' else 'assets/'+Path(c['path']).name
    w['reference_path']='assets/'+id+'-seed.png'
    if w.get('weapon'):w['weapon']['path']='../r7/assets/hildegard-sword.png'
    web['clips'][key]=w;web['characters'][id]['actions'].append(action)
aliases={'hildegard:duty':'hildegard:personal','berenga:hshield':'berenga:cast','berenga:bless':'berenga:cast','teiris:burst':'teiris:personal'}
for key,target in aliases.items():
    if target in catalog:catalog[key]={'alias':target}
(repo/'project/data/combat-motion.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
(lab/'manifest.json').write_text(json.dumps(web,ensure_ascii=False,indent=2),encoding='utf-8')
print('Installed',len(web['clips']),'clips;',len(catalog)-len(web['clips']),'explicit action mappings')
