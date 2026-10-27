from pathlib import Path
import json
p=Path(__file__).resolve().parent
first=json.loads((p/'bargut-estimate.json').read_text(encoding='utf-8'))['keypoints']
first=[dict(k,z_index=int(k['z_index'])) for k in first]
base={k['label']:[k['x']*256,k['y']*256] for k in first}
def pose(**kw):
    a={k:v[:] for k,v in base.items()}
    for k,v in kw.items():a[k.replace('_',' ')]=v
    for k in ['RIGHT EYE','LEFT EYE','RIGHT EAR','LEFT EAR']:
        a[k]=[a['NOSE'][i]+base[k][i]-base['NOSE'][i] for i in range(2)]
    return a
def mix(a,b,t):return {k:[a[k][i]+(b[k][i]-a[k][i])*t for i in range(2)] for k in a}
coil=pose(NOSE=[137,77],NECK=[127,96],RIGHT_SHOULDER=[110,96],RIGHT_ELBOW=[86,112],RIGHT_ARM=[109,108],LEFT_SHOULDER=[143,92],LEFT_ELBOW=[162,109],LEFT_ARM=[153,126],RIGHT_HIP=[118,141],LEFT_HIP=[137,137],RIGHT_KNEE=[92,175],LEFT_KNEE=[170,169])
strike=pose(NOSE=[166,77],NECK=[153,97],RIGHT_SHOULDER=[138,98],RIGHT_ELBOW=[160,110],RIGHT_ARM=[189,119],LEFT_SHOULDER=[168,95],LEFT_ELBOW=[148,124],LEFT_ARM=[122,126],RIGHT_HIP=[135,140],LEFT_HIP=[153,139],RIGHT_KNEE=[109,176],LEFT_KNEE=[188,170],LEFT_LEG=[205,207])
follow=pose(NOSE=[170,83],NECK=[155,103],RIGHT_SHOULDER=[139,104],RIGHT_ELBOW=[161,127],RIGHT_ARM=[163,149],LEFT_SHOULDER=[171,100],LEFT_ELBOW=[153,126],LEFT_ARM=[129,142],RIGHT_HIP=[136,146],LEFT_HIP=[154,145],RIGHT_KNEE=[110,180],LEFT_KNEE=[190,174],LEFT_LEG=[205,207])
cross=pose(NOSE=[176,87],NECK=[160,107],RIGHT_SHOULDER=[145,108],RIGHT_ELBOW=[170,120],RIGHT_ARM=[196,132],LEFT_SHOULDER=[177,105],LEFT_ELBOW=[188,122],LEFT_ARM=[190,148],RIGHT_HIP=[141,149],LEFT_HIP=[160,148],RIGHT_KNEE=[111,181],LEFT_KNEE=[193,177],LEFT_LEG=[211,207])
recover=mix(follow,base,.55);recover['LEFT LEG']=[193,190];recover['LEFT KNEE']=[169,152]
seqs={'attack':[base,mix(base,coil,.5),coil,mix(coil,strike,.35),strike,follow,mix(follow,recover,.5),recover,mix(recover,base,.5),base], 'personal':[base,coil,mix(coil,cross,.25),cross,follow,mix(follow,recover,.4),recover,mix(recover,base,.4),mix(recover,base,.75),base]}
for action,poses in seqs.items():
    frames=[[dict(label=k,x=round(v[0]/256,6),y=round(v[1]/256,6),z_index=next(j['z_index'] for j in first if j['label']==k)) for k,v in a.items()] for a in poses]
    req=dict(first_frame_url='https://aredsea.github.io/into-the-abyss-web/motion-lab/assets/bargut-seed.png',first_frame_keypoints=first,keypoints=frames,description='The identical slender adult leopard woman in the reference, long blonde hair with pale tips, two small rounded spotted ears, ONE spotted tail, green eyes, high-neck black tunic, charcoal waist cloth and gold waist cord, dark fitted trousers and wrist guards. Holds exactly TWO short steel daggers, one per hand, unchanged lengths. Preserve face and outfit. Body and physical weapons ONLY, no trails, no light, no effects.',action=action,direction='south-east',view='side',no_background=True,template_id='mannequin',seed=8102840+len(action))
    (p/('bargut-'+action+'-request.json')).write_text(json.dumps(req,indent=2),encoding='utf-8')
print('Bargut low step/cut, distinct cross-cut with withdrawal, 10 posed frames each')
