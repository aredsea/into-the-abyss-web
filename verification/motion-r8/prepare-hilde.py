from pathlib import Path
import json
p=Path(__file__).resolve().parent
read=lambda f:json.loads(f.read_text(encoding='utf-8'))
first=read(p.parent/'motion-r7/body-estimate.json')['keypoints']
first=[dict(k,z_index=int(k['z_index'])) for k in first]
base={k['label']:[k['x']*256,k['y']*256] for k in read(p.parent/'motion-r7/step-request.json')['keypoints'][0]}
def change(**kw):
    a={k:v[:] for k,v in base.items()}
    for k,v in kw.items():a[k.replace('_',' ')]=v
    for k in ['RIGHT EYE','LEFT EYE','RIGHT EAR','LEFT EAR']:
        a[k]=[a['NOSE'][i]+base[k][i]-base['NOSE'][i] for i in range(2)]
    return a
def mix(a,b,t):return {k:[a[k][i]+(b[k][i]-a[k][i])*t for i in range(2)] for k in a}
guard=change(NOSE=[132,68],NECK=[130,89],RIGHT_SHOULDER=[114,89],RIGHT_ELBOW=[116,116],RIGHT_ARM=[140,118],LEFT_SHOULDER=[147,86],LEFT_ELBOW=[161,111],LEFT_ARM=[148,125],RIGHT_HIP=[119,135],LEFT_HIP=[138,134],RIGHT_KNEE=[92,171],LEFT_KNEE=[174,172])
guard_recoil=mix(guard,change(NOSE=[122,72],NECK=[121,91],RIGHT_SHOULDER=[105,91],RIGHT_ELBOW=[110,122],RIGHT_ARM=[132,123],LEFT_SHOULDER=[139,90],LEFT_ELBOW=[151,116],LEFT_ARM=[142,129],RIGHT_HIP=[114,137],LEFT_HIP=[133,136],RIGHT_KNEE=[89,174],LEFT_KNEE=[170,174]),1)
taunt=change(NOSE=[146,55],NECK=[137,76],RIGHT_SHOULDER=[119,79],RIGHT_ELBOW=[117,110],RIGHT_ARM=[136,125],LEFT_SHOULDER=[154,75],LEFT_ELBOW=[174,85],LEFT_ARM=[194,77],RIGHT_HIP=[121,121],LEFT_HIP=[140,121])
beckon=change(NOSE=[145,58],NECK=[137,79],RIGHT_SHOULDER=[120,81],RIGHT_ELBOW=[118,111],RIGHT_ARM=[137,125],LEFT_SHOULDER=[153,78],LEFT_ELBOW=[176,94],LEFT_ARM=[175,71],RIGHT_HIP=[121,124],LEFT_HIP=[140,124])
step=change(NOSE=[147,62],NECK=[140,83],RIGHT_SHOULDER=[123,84],RIGHT_ELBOW=[130,105],RIGHT_ARM=[148,112],LEFT_SHOULDER=[156,80],LEFT_ELBOW=[168,103],LEFT_ARM=[153,120],RIGHT_HIP=[126,132],LEFT_HIP=[145,131],RIGHT_KNEE=[105,172],LEFT_KNEE=[174,159],LEFT_LEG=[195,201])
wall=change(NOSE=[151,71],NECK=[143,92],RIGHT_SHOULDER=[126,93],RIGHT_ELBOW=[133,118],RIGHT_ARM=[153,120],LEFT_SHOULDER=[161,89],LEFT_ELBOW=[178,111],LEFT_ARM=[160,126],RIGHT_HIP=[132,141],LEFT_HIP=[150,140],RIGHT_KNEE=[103,178],LEFT_KNEE=[186,174],LEFT_LEG=[207,211])
sequences={
 'guard':[base,mix(base,guard,.35),mix(base,guard,.8),guard,guard_recoil,guard,mix(guard,base,.55),base],
 'taunt':[base,mix(base,taunt,.4),taunt,beckon,taunt,beckon,mix(beckon,guard,.65),guard,mix(guard,base,.6),base],
 'personal':[base,mix(base,step,.4),step,wall,wall,mix(wall,guard,.4),guard,mix(guard,base,.35),mix(guard,base,.75),base]
}
for name,poses in sequences.items():
    frames=[[dict(label=k,x=round(v[0]/256,6),y=round(v[1]/256,6),z_index=next(j['z_index'] for j in first if j['label']==k)) for k,v in a.items()] for a in poses]
    req=dict(first_frame_url='https://api.pixellab.ai/mcp/images/a61d4d47-8bce-4376-bc12-58e36c89a0cf/download?index=0',first_frame_keypoints=first,keypoints=frames,description='The identical adult woman in the reference: wine-red chin-length bob with straight bangs, pale face, fitted black steel chest armor, crimson open coat, black trousers, armored boots, black gloves. Preserve original face, body proportions, outfit and exposed skin exactly. Empty closed hands, no weapons, no shields, no glow, no particles, transparent background.',action=name,direction='south-east',view='side',no_background=True,template_id='mannequin',seed=8102802+len(name))
    (p/('hildegard-'+name+'-request.json')).write_text(json.dumps(req,indent=2),encoding='utf-8')
print('Prepared guard, taunt, personal skeletons; rigid sword added separately')
