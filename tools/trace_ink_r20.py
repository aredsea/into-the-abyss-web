"""Trace reference alpha/color coverage into subpixel, even-odd vector geometry.

No reference raster is copied into project/. Dependencies: numpy, Pillow, OpenCV.
Marching squares uses original floating alpha values, not a thresholded bitmap.
The horizontal trapezoid decomposition honors every hole and disconnected island.
"""
from pathlib import Path
from collections import Counter, defaultdict
import hashlib, json, gzip
import numpy as np
import cv2
from PIL import Image

R = Path(__file__).resolve().parents[1]
REF = R.parents[1] / 'outputs/r17-battle/src/assets'
OUT = R / 'project/assets/ui-r20'
STATES = ['base', 'target', 'status', 'skills', 'supplies', 'log']

def layers(path):
    a = np.asarray(Image.open(path).convert('RGBA')).astype(float)
    rgb, alpha = a[:, :, :3], a[:, :, 3] / 255
    # Dominant opaque colors, with distinct paint families (compression and
    # resampling introduce many nearly identical RGB triplets).
    counts = Counter(map(tuple, rgb[alpha > .99].astype(int)))
    palette = []
    for color, count in counts.most_common():
        if all(np.linalg.norm(np.array(color)-p) > 80 for p in palette):
            palette.append(np.array(color, dtype=float))
        if len(palette) == 2: break
    if path.name.startswith('battle-mask'):
        palette = [np.array([255, 255, 255.])]
    if len(palette) == 1:
        return [(palette[0].astype(int).tolist(), alpha)]
    # Unmix the two real paint colors in straight RGB; multiply by coverage.
    # This preserves overlapping color boundaries and antialiased edge pixels.
    p, q = palette
    t = np.clip(((rgb-p)*(q-p)).sum(axis=2) / ((q-p)**2).sum(), 0, 1)
    return [(p.astype(int).tolist(), alpha*(1-t)),
            (q.astype(int).tolist(), alpha*t)]

def contours(coverage, tolerance=.075, level=.5):
    a = np.pad(coverage, 1)
    bits = ((a[:-1,:-1] >= level).astype(int) + 2*(a[:-1,1:] >= level)
            + 4*(a[1:,1:] >= level) + 8*(a[1:,:-1] >= level))
    table = {1:[(3,0)],2:[(0,1)],3:[(3,1)],4:[(1,2)],
             6:[(0,2)],7:[(3,2)],8:[(2,3)],9:[(2,0)],
             11:[(2,1)],12:[(1,3)],13:[(1,0)],14:[(0,3)]}
    edges = defaultdict(list)
    for y,x in zip(*np.where((bits != 0) & (bits != 15))):
        values = [a[y,x], a[y,x+1], a[y+1,x+1], a[y+1,x]]
        corners = [(x,y),(x+1,y),(x+1,y+1),(x,y+1)]
        points = {}
        for e,(i,j) in enumerate([(0,1),(1,2),(2,3),(3,0)]):
            if (values[i] >= level) == (values[j] >= level): continue
            t = (level-values[i])/(values[j]-values[i])
            # Pixel centers are (0.5,0.5); remove the one-pixel padded rim.
            points[e] = tuple(round(corners[i][k]+t*(corners[j][k]-corners[i][k])-.5, 7) for k in [0,1])
        b = bits[y,x]
        if b in [5,10]:
            inside = sum(values)/4 >= level
            pairs = [(0,1),(2,3)] if (b == 5) == inside else [(3,0),(1,2)]
        else: pairs = table[b]
        for i,j in pairs:
            p,q = points[i],points[j]
            if p == q: continue
            edges[p].append(q); edges[q].append(p)
    paths = []
    while edges:
        start = next(iter(edges)); p = start; path = []
        while True:
            path.append(p)
            q = edges[p].pop()
            if not edges[p]: del edges[p]
            edges[q].remove(p)
            if not edges[q]: del edges[q]
            p = q
            if p == start: break
        raw = np.array(path, np.float32)
        simple = cv2.approxPolyDP(raw, tolerance, True).reshape(-1,2)
        if len(simple) >= 3 and abs(cv2.contourArea(simple)) > .00001:
            paths.append(np.round(simple, 5).tolist())
    return paths

def triangulate(paths):
    """Even-odd scanbeam tessellation; no bridges, lost holes or painted holes."""
    starts, ends = defaultdict(list), defaultdict(list)
    edges = []; vertices = []; indices = []
    for path in paths:
        for a,b in zip(path,path[1:]+path[:1]):
            if a[1] == b[1]: continue
            if a[1] > b[1]: a,b = b,a
            i = len(edges); edges.append((a,b))
            starts[a[1]].append(i); ends[b[1]].append(i)
    levels = sorted(set(starts)|set(ends)); active = set()
    def xat(i,y):
        a,b = edges[i]; return a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1])
    lookup = {}
    def vertex(x,y):
        p = (round(x,5),round(y,5))
        if p not in lookup:
            lookup[p] = len(vertices); vertices.append(list(p))
        return lookup[p]
    for lo,hi in zip(levels,levels[1:]):
        active.difference_update(ends[lo]); active.update(starts[lo])
        ordered = sorted(active,key=lambda i:xat(i,(lo+hi)/2))
        assert len(ordered)%2 == 0
        for left,right in zip(ordered[::2],ordered[1::2]):
            ids = [vertex(xat(left,lo),lo),vertex(xat(right,lo),lo),
                   vertex(xat(right,hi),hi),vertex(xat(left,hi),hi)]
            for tri in [ids[:3],[ids[0],ids[2],ids[3]]]:
                if len(set(tri)) == 3: indices.extend(tri)
    return vertices, indices

def main():
    # R20b is the production writer. Historical R20 JSON is verification-only.
    from compact_ink_r20b import main as compact
    compact()

if __name__ == '__main__': main()
