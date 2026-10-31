"""Build typed, compressed Godot vector resources; no raster payloads.

Uses R20's independently extracted paint and marching squares. Tessellation is
per connected outer ring with its immediate holes, avoiding unrelated islands'
scanbeam levels. The intermediate JSON is verification-only, never exported.
"""
from pathlib import Path
import json, hashlib, subprocess, sys
import cv2
import numpy as np
from trace_ink_r20 import REF, OUT, STATES, layers, contours, triangulate

R=Path(__file__).resolve().parents[1]; O=R/'verification/ui-r20'

def tessellate(paths):
    polys=[np.asarray(p,np.float32) for p in paths]
    areas=[abs(cv2.contourArea(p)) for p in polys]
    parents=[]
    for i,p in enumerate(polys):
        containers=[j for j,q in enumerate(polys) if areas[j]>areas[i] and cv2.pointPolygonTest(q,tuple(p[0]),False)>0]
        parents.append(min(containers,key=lambda j:areas[j]) if containers else -1)
    def depth(i):
        d=0
        while parents[i]>=0: d+=1;i=parents[i]
        return d
    vertices=[];indices=[]
    for i in range(len(paths)):
        if depth(i)%2: continue
        group=[paths[i]]+[paths[j] for j,p in enumerate(parents) if p==i]
        v,idx=triangulate(group); n=len(vertices)
        vertices.extend(v);indices.extend(x+n for x in idx)
    return vertices,indices,sum(depth(i)%2 for i in range(len(paths)))

def main():
    names=[f'edge-{s}' for s in STATES]+[f'battle-mask-{s}' for s in STATES]+[f'gesture-{s}' for s in STATES if s!='log']+['gesture-log-r17-hires']
    assets={}
    for name in names:
        path=REF/(name+'.png'); paint=[]
        from PIL import Image
        w,h=Image.open(path).size
        for color,coverage in layers(path):
            # Keep full threshold topology, simplify within the original limit.
            paths=contours(coverage,tolerance=0,level=.5)
            paths=[cv2.approxPolyDP(np.asarray(p,np.float32),.075,True).reshape(-1,2).tolist()
                   if abs(cv2.contourArea(np.asarray(p,np.float32)))>=10 else p for p in paths]
            v,idx,holes=tessellate(paths)
            paint.append(dict(color=color,paths=paths,polygon_count=len(paths),hole_count=holes,vertices=v,indices=idx))
        asset=dict(source=path.name,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),size=[w,h],layers=paint)
        if name.startswith('battle-mask'):
            paths=[[[0,0],[w,0],[w,h],[0,h]]]+paint[0]['paths']
            v,idx=triangulate(paths)
            asset['cover']=dict(color=[244,239,227],paths=paths,vertices=v,indices=idx)
        assets[name]=asset
        print(name,sum(len(l['vertices']) for l in paint),flush=True)
    document=dict(format=2,method='single alpha=.5 contour; connected-island even-odd tessellation; compressed typed Godot resource',simplification_max_error_source_px=.075,coordinate_quantum_source_px=1/128,raster_payload=False,assets=assets,
                  excluded_reference_assets=['gesture-log','approved-black-brush','approved-paper-fringe','approved-vermilion-brush'])
    (O/'compact-intermediate.json').write_text(json.dumps(document,separators=(',',':')),encoding='utf-8')
    # Measurement metadata contains neither duplicate geometry nor raster data.
    metadata=json.loads(json.dumps(document))
    for a in metadata['assets'].values():
        for l in a['layers']+([a['cover']] if 'cover' in a else []):
            for k in ['paths','vertices','indices']: l.pop(k)
    (O/'ink-metadata.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
    subprocess.run([sys.executable,str(R/'tools/godot_r17.py'),'--headless','--script','res://tests/build_ink_r20b.gd'],check=True)

if __name__=='__main__':main()
