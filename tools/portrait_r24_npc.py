"""R24 NPC cutouts: isnet-anime mask plus reviewed paper gaps.

White shirts and collars touch the white paper in these sources, so a flood from
the border eats cloth. The model mask decides the outline; only reviewed boxes
remove closed paper between hair strands. Source files are never overwritten.
Run from the reskin worktree.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
import portrait_r24 as pipeline

R=Path(__file__).resolve().parents[1]
O=R/'verification/reskin-r24/round2/npc'
A=R/'project/assets/portraits-r24/npc'
IDS=['fenella','loredana','dorothea','pietro','hanna']
# (x0,y0,x1,y1) source boxes reviewed against the original: paper seen through hair, never cloth.
GAPS={'fenella':[(170,330,235,410),(300,360,345,412),(385,265,430,412)],'loredana':[],'dorothea':[],'pietro':[],'hanna':[]}

def model_mask(session,im):
    arr=np.array(im.resize((1024,1024),Image.Resampling.LANCZOS)).astype('float32')
    arr=arr/max(float(arr.max()),1e-6)-np.array([.485,.456,.406],dtype='float32')
    pred=session.run(None,{session.get_inputs()[0].name:arr.transpose(2,0,1)[None]})[0][0,0]
    pred=(pred-pred.min())/max(float(pred.max()-pred.min()),1e-6)
    return np.array(Image.fromarray((pred*255).astype('uint8')).resize(im.size,Image.Resampling.LANCZOS))

def cut(rgb,mask,gaps):
    fg=mask>=128
    paper=(rgb.min(2)>=240)&(np.ptp(rgb,axis=2)<14)
    for x0,y0,x1,y1 in gaps:
        region=np.zeros(fg.shape,bool);region[y0:y1,x0:x1]=True
        fg&=~(paper&region)
    fg=ndi.binary_opening(fg,iterations=1)
    fg,_,_=pipeline.largest(fg);fg=ndi.binary_fill_holes(fg)&(fg|~paper)
    b=np.array([255.,255.,255.])
    dist=ndi.distance_transform_edt(fg);inside=dist>4
    _,indices=ndi.distance_transform_edt(~inside,return_indices=True)
    f=rgb[tuple(indices)].astype(float);v=f-b
    coverage=np.clip(np.sum((rgb-b)*v,axis=2)/np.maximum(np.sum(v*v,axis=2),1),0,1)
    recovered=np.minimum(np.clip((rgb-(1-coverage[...,None])*b)/np.maximum(coverage[...,None],.08),0,255),f+8)
    corrected=rgb.copy();edge=fg&(dist<=4);corrected[edge]=np.rint(recovered[edge]).astype('uint8')
    alpha=np.rint(255*np.clip((dist-.75)/1.25,0,1)).astype('uint8')
    main,_,_=pipeline.largest(alpha>0);alpha[~main]=0;corrected[alpha==0]=0
    return np.dstack([corrected,alpha])

def run():
    import onnxruntime as ort
    O.mkdir(parents=True,exist_ok=True);A.mkdir(parents=True,exist_ok=True)
    opts=ort.SessionOptions();opts.intra_op_num_threads=4;opts.inter_op_num_threads=1
    model=Path.home()/'.u2net/isnet-anime.onnx'
    session=ort.InferenceSession(str(model),sess_options=opts,providers=['CPUExecutionProvider'])
    entries=[];landmarks={}
    for id in IDS:
        source=R/f'project/assets/{id}.webp';im=Image.open(source).convert('RGB');rgb=np.array(im)
        rgba=cut(rgb,model_mask(session,im),GAPS[id]);alpha=rgba[...,3]
        Image.fromarray(rgba).save(A/f'{id}.png')
        h=alpha.shape[0];upper=(alpha>127)&(np.indices(alpha.shape)[0]<h*.46);yy,xx=np.where(upper)
        landmarks[id]={'eye_y':h*.32,'shoulder_y':h*.55,'top_y':int(yy.min()),'head_bounds_xyxy':[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)],'center_x':262.5,'method':'source-reviewed NPC bust; image ratios for eyes/shoulders','uncertainty_px':8}
        row={'id':id,'source_sha256':pipeline.sha(source),'output_sha256':pipeline.sha(A/f'{id}.png'),'components':pipeline.components(alpha),'gaps':GAPS[id]}
        entries.append(row);print(id,row['components'],flush=True)
    pipeline.write(A/'landmarks.json',landmarks)
    pipeline.write(O/'validation.json',{'model':'isnet-anime','model_sha256':pipeline.sha(model),'entries':entries})

if __name__=='__main__':run()
