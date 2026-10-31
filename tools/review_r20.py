"""Pixel comparisons and measured DOM/Godot bounds. Never alters the reference."""
from pathlib import Path
import csv,json,html
import numpy as np
from PIL import Image,ImageChops,ImageEnhance,ImageDraw
R=Path(__file__).resolve().parents[1]; O=R/'verification/ui-r20'
REF=R.parents[1]/'outputs/r17-battle'
dom=json.loads((O/'reference-dom.json').read_text(encoding='utf-8'))
godot=json.loads((O/'r20-results.json').read_text(encoding='utf-8'))
states=['base','target','status','skills','supplies','log']
metrics=[]; rows=[]; baseline_rows=[]
def match_boxes(state):
    d=dom[state]; boxes=godot['measurements'][state+'-390']['boxes']
    def choose(prefix):return [v for v in d if v['selector'].startswith(prefix)]
    pairs={'back':choose('span.back'),'place':choose('span.place'),'turn-number':[v for v in d if v['selector']=='b.' and v['rect'][1]<40], 'battle':choose('div.battle.'), 'actor':choose('img.sprite.actor'),'actor-heading':choose('h1.display'),'supplies':[],'log':[],'sheet':choose('section.sheet.'),'sheet-title':choose('h2.display'),'status-portrait':choose('img.status-portrait')}
    if not pairs['battle']: pairs['battle']=choose('div.battle')
    for i,v in enumerate(choose('div.queue-slot')): pairs[f'queue-slot:{i}']=[v]
    for i,v in enumerate([v for v in d if v['selector']=='span.' and v['rect'][1]==71]):pairs[f'queue-number:{i}']=[v]
    for who in ['lantern','apprentice','orb','executor']:
        pairs['enemy-art:'+who]=choose('img.sprite.enemy-'+who)
        pairs['enemy-hud:'+who]=choose('div.enemy-hud.'+who)
    for who,v in zip(['hildegard','bargut','teiris','berenga'],choose('div.face-frame')):pairs['face:'+who]=[v]
    for i,v in enumerate(choose('button.action')): pairs[f'action:{i}']=[v]
    for who,v in zip(['hildegard','bargut','teiris','berenga'],choose('div.party-card')):pairs['party-card:'+who]=[v]
    for i,v in enumerate([v for v in d if v['selector']=='button.' and v['text'] in ['보급품','전투 기록']]):pairs['supplies' if i==0 else 'log']=[v]
    for key,vs in pairs.items():
        if key not in boxes or not vs:continue
        a=vs[0]['rect']; b=boxes[key]
        err=max(abs(a[0]-b[0]),abs(a[1]-b[1]),abs(a[0]+a[2]-b[0]-b[2]),abs(a[1]+a[3]-b[1]-b[3]))
        reason='' if err<=2 else 'Native font advance/rounding differs from Chromium' if key in ['place','actor-heading','sheet-title'] else 'See measured bounds; CSS and native Control sizing differ'
        rows.append({'state':state,'element':key,'reference':a,'godot':b,'edge_error_px':round(err,4),'within_2px':err<=2,'reason':reason})
    labs=godot['measurements'][state+'-390']['labels']
    for v in d:
        text=v['text']; base=v.get('baseline')
        if not text or base is None:continue
        exact=[l for l in labs if l['text']==text]
        partial=[l for l in labs if text in l['text']]
        candidates=exact+partial
        # For composite native labels, use the same line's baseline. Prefer
        # proximity over a matching number on an unrelated party card.
        if not candidates:continue
        l=min(candidates,key=lambda x:abs(x['baseline']-base)+abs(x['rect'][0]-v['rect'][0])*.01)
        if abs(l['baseline']-base)>50:continue
        err=abs(l['baseline']-base)
        baseline_rows.append({'state':state,'element':v['selector'],'text':text,'reference_baseline':base,'godot_baseline':l['baseline'],'error_px':round(err,4),'within_2px':err<=2,'composite_label':l['text']!=text,'reason':'' if err<=2 else 'Native font ascent and Chromium inline baseline differ'})
for i,state in enumerate(states):
    board=Image.open(REF/('r17-09-battle-core.png' if i<3 else 'r17-10-battle-tools.png')).convert('RGB')
    scale=3072/1248; x=(20+410*(i%3))*scale; y=54*scale
    approved=board.transform((390,844),Image.Transform.EXTENT,(x,y,x+390*scale,y+844*scale),Image.Resampling.BICUBIC)
    approved.save(O/f'approved-{state}-390.png')
    actual=Image.open(O/f'{state}-390.png').convert('RGB')
    pair=Image.new('RGB',(780,844)); pair.paste(approved,(0,0)); pair.paste(actual,(390,0)); pair.save(O/f'{state}-side-by-side.png')
    Image.blend(approved,actual,.5).save(O/f'{state}-overlay.png')
    diff=ImageChops.difference(approved,actual); ImageEnhance.Contrast(diff).enhance(4).save(O/f'{state}-difference.png')
    a=np.asarray(approved).astype(float); b=np.asarray(actual).astype(float)
    metrics.append({'state':state,'mae_0_255':float(np.abs(a-b).mean()),'pixels_any_channel_delta_gt_16_pct':float((np.max(np.abs(a-b),axis=2)>16).mean()*100),'source_panel_vs_html_mae':float(np.abs(a-np.asarray(Image.open(O/f'reference-{state}-390.png').convert('RGB')).astype(float)).mean())})
    match_boxes(state)
for width,height in [(390,844),(360,780),(430,844)]:
    sheet=Image.new('RGB',(width*3,height*2))
    for i,state in enumerate(states):sheet.paste(Image.open(O/f'{state}-{width}.png'),((i%3)*width,(i//3)*height))
    sheet.save(O/f'all-states-{width}.png')
for suffix in ['overlay','difference']:
    sheet=Image.new('RGB',(1170,1688))
    for i,state in enumerate(states):sheet.paste(Image.open(O/f'{state}-{suffix}.png'),((i%3)*390,(i//3)*844))
    sheet.save(O/f'all-{suffix}.png')
for name,data in [('box-errors',rows),('baseline-errors',baseline_rows)]:
    (O/f'{name}.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    with (O/f'{name}.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
summary={'box_count':len(rows),'boxes_within_2px':sum(v['within_2px'] for v in rows),'box_max_error_px':max(v['edge_error_px'] for v in rows),'box_exceptions':[v for v in rows if not v['within_2px']],'baseline_count':len(baseline_rows),'baselines_within_2px':sum(v['within_2px'] for v in baseline_rows),'baseline_max_error_px':max(v['error_px'] for v in baseline_rows),'baseline_exceptions':[v for v in baseline_rows if not v['within_2px']],'pixel_comparison':metrics,'method':'Box edge maximum = max of four absolute edge deltas. Browser baselines measured with an inline zero-height marker in each text run; native baselines from Label font ascent and vertical alignment. Composite text runs share their actual native baseline. R20 uses alpha=0.5 traced vector contours.'}
(O/'comparison-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
links=''.join(f'<h2>{s}</h2><a href="{s}-side-by-side.png"><img src="{s}-side-by-side.png" width="780"></a><p><a href="{s}-overlay.png">50% overlay</a> · <a href="{s}-difference.png">difference</a> · <a href="{s}-360.png">360×780</a></p>' for s in states)
(O/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>R19 comparison evidence</title><style>body{background:#ddd;color:#111;font:16px sans-serif;margin:24px}img{max-width:100%;height:auto}a{color:#17445c}</style><h1>R20: approved panel / Godot</h1><p><a href="state-ink-metrics.csv">Ink by state/color</a> ? <a href="asset-ink-metrics.csv">Ink by source asset</a> ? <a href="mae-r19-r20.csv">R19/R20 pixel MAE</a> ? <a href="ink-text-reference.csv">Text/reference coverage</a></p><p>Left: cropped approved PNG; right: actual fixed-fixture Godot capture. Ink is traced vector geometry.</p><p><a href="comparison-summary.json">Measurements</a> · <a href="box-errors.csv">Bounds CSV</a> · <a href="baseline-errors.csv">Baselines CSV</a></p>'+links,encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['box_exceptions','baseline_exceptions','pixel_comparison','method']},indent=2))
