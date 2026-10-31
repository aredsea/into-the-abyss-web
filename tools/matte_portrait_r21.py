"""R21 1b: RGB-identical originals, alpha-only matte and measured inward crops.

Run: python tools/matte_portrait_r21.py archive|build|verify|finalize
No image generation, color correction, resampling or registration in master PNGs.
Only review previews are resampled. Slot asset PNGs are native pixel crops.
"""
from pathlib import Path
import hashlib
import json
import shutil
import sys

import cv2
import numpy as np
from scipy import ndimage as ndi
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/portraits-r21'
ASSETS = ROOT / 'project/assets/portraits-r21'
ARCHIVE = OUT / 'attempt-1b-before'
IDS = ['hildegard', 'marceline', 'naran']
FACES = {'hildegard': [72, 18, 462, 458], 'marceline': [110, 102, 420, 412], 'naran': [110, 150, 420, 460]}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')


def permitted(path):
    r = path.relative_to(ROOT).as_posix()
    return r.startswith(('project/assets/portraits-r21/', 'verification/portraits-r21/')) or (r.startswith('tools/') and 'portrait_r21' in path.name) or r == 'UI-R21-C.md'


def snapshot():
    return {p.relative_to(ROOT).as_posix(): sha(p) for p in ROOT.rglob('*') if p.is_file() and '.git' not in p.relative_to(ROOT).parts and not permitted(p)}


def archive():
    if ARCHIVE.exists():
        raise RuntimeError('Archive exists; will not overwrite first attempt')
    before = snapshot()
    ARCHIVE.mkdir()
    # Every resolved source and destination must remain within this worktree.
    def move(src, dst):
        assert src.resolve().is_relative_to(ROOT.resolve()) and dst.resolve().is_relative_to(ROOT.resolve())
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))
    for p in list(OUT.iterdir()):
        if p != ARCHIVE:
            move(p, ARCHIVE / 'verification' / p.name)
    for p in list(ASSETS.iterdir()):
        move(p, ARCHIVE / 'project/assets/portraits-r21' / p.name)
    for p in list((ROOT / 'tools').glob('*portrait_r21*')):
        if p.name != Path(__file__).name and p.is_file():
            move(p, ARCHIVE / 'tools' / p.name)
    shutil.copy2(ROOT / 'UI-R21-C.md', ARCHIVE / 'UI-R21-C.md')
    for name in ['slots.json', 'baseline.json']:
        shutil.copy2(ARCHIVE / 'verification' / name, OUT / name)
    write('baseline-1b.json', before)
    print(json.dumps({'archived': str(ARCHIVE), 'protected_files': len(before)}))


def matte(rgb, id):
    # Neutral near-white connected to the image perimeter is background.
    # Border connectivity protects white eyes, metal, hair and cloth interiors.
    lo = rgb.min(axis=2).astype(float)
    chroma = rgb.max(axis=2).astype(float) - lo
    threshold = {'hildegard': 239, 'marceline': 239, 'naran': 246}[id]
    candidate = (lo >= threshold) & (chroma <= 7)
    if id in ['hildegard', 'marceline']:
        candidate[:400] |= (lo[:400] >= 225) & (chroma[:400] <= 18)
    seed = np.zeros(candidate.shape, bool)
    seed[0] = candidate[0]
    seed[-1] = candidate[-1]
    seed[:, 0] = candidate[:, 0]
    seed[:, -1] = candidate[:, -1]
    bg = ndi.binary_propagation(seed, mask=candidate)
    # Explicit exterior hair-gap regions, reviewed against the source. Never
    # classify a white connected component inside face, armor or Naran's fur.
    gap_regions = {
        'hildegard': [(0,0,131,400),(398,0,525,400),(130,360,232,400),(310,360,398,400),(225,0,270,28)],
        'marceline': [(0,150,140,380),(390,150,525,345),(134,310,156,380),(310,330,395,380)],
        'naran': [],
    }[id]
    extra = np.zeros(bg.shape, bool)
    labels, _ = ndi.label(candidate & ~bg)
    for x0,y0,x1,y1 in gap_regions:
        for label in np.unique(labels[y0:y1,x0:x1]):
            if not label: continue
            yy,xx=np.where(labels==label)
            if xx.min()>=x0 and xx.max()<x1 and yy.min()>=y0 and yy.max()<y1:
                extra |= labels==label
    bg |= extra
    # Alpha antialias only in a maximum 1px boundary band on each side.
    # Estimate coverage from the nearest opaque interior and background RGB;
    # even fully transparent RGB remains bit-for-bit equal to source.
    foreground = ~bg
    near = bg & ndi.binary_dilation(foreground)
    alpha = np.where(foreground, 255, 0).astype('uint8')
    inner = foreground & ndi.binary_dilation(bg)
    core = ndi.binary_erosion(foreground, iterations=2)
    _, fi = ndi.distance_transform_edt(~core, return_indices=True)
    _, bi = ndi.distance_transform_edt(~bg, return_indices=True)
    b = rgb[bi[0],bi[1]].astype(float)
    f = rgb[fi[0],fi[1]].astype(float)
    denom = np.linalg.norm(f-b,axis=2)
    coverage = np.clip(np.linalg.norm(rgb.astype(float)-b,axis=2)/np.maximum(denom,1),0,1)
    alpha[inner] = np.rint(coverage[inner]*255).astype('uint8')
    alpha[near] = 0
    return alpha, dict(method='border-connected neutral near-white flood; reviewed enclosed exterior hair gaps; alpha-only 1px edge coverage', min_channel_threshold=threshold, max_chroma=7, head_threshold_override=dict(y_range=[0,400],min_channel=225,max_chroma=18) if id!='naran' else None, gap_cleanup_regions_xyxy=gap_regions, enclosed_background_pixels=int(extra.sum()), defringe_rgb_width_px=0, defringe_rgb_pixels=0, alpha_antialias_width_px=1, alpha_antialias_pixels=int(((alpha > 0) & (alpha < 255)).sum()))


def checker(size, cell=12):
    y, x = np.indices((size[1], size[0]))
    t = np.where(((x // cell + y // cell) % 2)[..., None], np.array([185, 188, 188]), np.array([226, 228, 228])).astype('uint8')
    return Image.fromarray(t).convert('RGBA')


def cover_box(region, ratio, centering_y=0):
    x0, y0, x1, y1 = region
    w, h = x1 - x0, y1 - y0
    if w / h > ratio:
        cw = max(1, round(h * ratio))
        x0 += (w - cw) // 2
        x1 = x0 + cw
    else:
        ch = max(1, round(w / ratio))
        y0 += round((h-ch)*centering_y)
        y1 = y0 + ch
    return [x0, y0, x1, y1]


def build():
    slots = json.loads((OUT / 'slots.json').read_text(encoding='utf-8'))
    allslots = [s for screen in slots['screens'] for s in screen['slots']]
    entries, placements = [], []
    (OUT / 'matte').mkdir(exist_ok=True)
    (OUT / 'slot-previews').mkdir(exist_ok=True)
    (ASSETS / 'slots').mkdir(exist_ok=True)
    for id in IDS:
        src = Image.open(ROOT / f'project/assets/{id}.webp').convert('RGB')
        rgb = np.array(src)
        alpha, params = matte(rgb, id)
        cut = Image.fromarray(np.dstack([rgb, alpha]))
        # 3:4 master at original vertical resolution; source frame copied 1:1.
        master = Image.new('RGBA', (576, 768), (0, 0, 0, 0))
        master.paste(cut, (25, 0))
        path = ASSETS / f'{id}-upperbody.png'
        master.save(path)
        Image.fromarray(alpha).save(OUT / 'matte' / f'{id}-alpha.png')
        bg = checker(master.size)
        bg.alpha_composite(master)
        bg.convert('RGB').save(OUT / f'{id}-checker.jpg', quality=93)
        dark = Image.new('RGBA',master.size,'#202725')
        dark.alpha_composite(master)
        dark.convert('RGB').save(OUT / f'{id}-dark.jpg',quality=93)
        review = Image.new('RGB', (1152, 768))
        review.paste(src, (0, 0))
        review.paste(bg.convert('RGB'), (576, 0))
        review.save(OUT / f'{id}-matte-review.jpg', quality=93)
        rows = []
        gallery = Image.new('RGB', (1200, 860), '#eee9dd')
        gd = ImageDraw.Draw(gallery)
        for i, slot in enumerate(allslots):
            sid = slot['id']
            sw, sh = slot['rect'][2:]
            region = FACES[id] if slot['kind'].startswith('face') else [0, 0, 525, 768]
            box = cover_box(region, sw / sh, .8 if slot['kind'].startswith('face') else 0)
            assert 0 <= box[0] < box[2] <= src.width and 0 <= box[1] < box[3] <= src.height
            native_crop = cut.crop(box)
            native_crop.save(ASSETS / 'slots' / f'{id}-{sid}.png')
            crop = native_crop.resize((sw, sh), Image.Resampling.LANCZOS)
            # Actual measured slot dimensions and mask; source mockup person is
            # replaced by a clean panel to avoid presenting mixed identities.
            panel = Image.new('RGBA', (sw, sh), '#e9e3d5')
            pd = ImageDraw.Draw(panel)
            pd.polygon([(0, int(sh*.7)), (sw, int(sh*.2)), (sw, sh), (0, sh)], fill='#ca4928')
            panel.alpha_composite(crop)
            if 'polygon' in slot:
                mask = Image.new('L', (sw, sh))
                ImageDraw.Draw(mask).polygon([(x-slot['rect'][0], y-slot['rect'][1]) for x,y in slot['polygon']], fill=255)
                panel.putalpha(mask)
            panel.save(OUT / 'slot-previews' / f'{id}-{sid}.png')
            thumb = ImageOps.contain(panel, (220, 365), Image.Resampling.LANCZOS)
            gx, gy = (i % 5)*240+10, (i//5)*425+30
            gd.text((gx, gy-20), f'{sid} {sw}x{sh}', fill='#16191a')
            gallery.paste(thumb, (gx+(220-thumb.width)//2, gy), thumb)
            p = dict(id=id, slot=sid, source_crop_xyxy=box, source_frame_xyxy=[0,0,525,768], native_asset_size=list(native_crop.size), slot_size=[sw,sh], requires_outpaint=False, source_scale_in_preview_only=[sw/(box[2]-box[0]),sh/(box[3]-box[1])], transparent_master_padding_consumed=False, crop_reason='inward cover crop; slot boundary intentionally crops shoulders/torso' if not slot['kind'].startswith('face') else 'inward face crop centered toward face; ears/hair top may be cropped', output=f'project/assets/portraits-r21/slots/{id}-{sid}.png')
            rows.append(p)
            placements.append(p)
        gallery.save(OUT / f'{id}-all-slots.jpg', quality=89)
        entries.append(dict(id=id, source=f'project/assets/{id}.webp', source_sha256=sha(ROOT/f'project/assets/{id}.webp'), output=path.relative_to(ROOT).as_posix(), output_sha256=sha(path), canvas=[576,768], original_frame_in_output_xywh=[25,0,525,768], source_native_size=[525,768], parameters=params, generated_pixels=0, extension_blend_width_px=0, original_rgb_changed_pixels=int(np.any(np.array(master)[0:768,25:550,:3] != rgb, axis=2).sum()), alpha_zero_pixels=int((alpha==0).sum()), alpha_opaque_pixels=int((alpha==255).sum()), slots_inward=len(rows)))
    write('preview-placement.json', placements)
    manifest = dict(phase='1b', status='RGB_PRESERVED_ALPHA_MATTE_REVIEW', generation_calls=0, accepted_preservation=3, characters=3, remaining_playable_characters_not_started=27, scope='3-character review only; game code/data unchanged', source_pixels='decoded source RGB copied exactly, including hidden RGB; only alpha changes', master_padding='25px left + 26px right fully transparent; not generated anatomy; consume recorded source crop', slot_count=len(allslots), slot_character_cases=len(placements), inward_cases=len(placements), outpaint_cases=0, slots_file='verification/portraits-r21/slots.json', entries=entries, visual_review={'opened':False}, limitations=['Original side/bottom truncation remains in master; slot crops deliberately stay inside original frame.', 'Small face slots crop tall ears; no new anatomy, clothing or pixels.', 'White edge RGB retained by requirement; alpha-only matte may leave a fine light fringe on dark backgrounds.'])
    write('manifest.json', manifest)
    sheet(entries)
    print(json.dumps({'entries':len(entries),'slot_cases':len(placements),'generation_calls':0}))


def sheet(entries):
    w,h=1176,1140
    im=Image.new('RGB',(w,h),'#eee9dd')
    d=ImageDraw.Draw(im)
    font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',18)
    small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',13)
    for x,label in [(14,'원본'),(280,'1b 결과 · 체커 배경'),(555,'시안 실측 칸 합성 · 게임 연결 없음')]:
        d.text((x,10),label,font=font,fill='#171b19')
    for row,e in enumerate(entries):
        y=48+row*360
        id=e['id']
        d.line((12,y,1163,y),fill='#8c8679')
        d.text((14,y+5),id,font=font,fill='#171b19')
        d.text((280,y+5),'원본 RGB 변경 0px',font=font,fill='#176146')
        for p,x in [(ROOT/e['source'],14),(OUT/f'{id}-checker.jpg',280)]:
            thumb=ImageOps.contain(Image.open(p).convert('RGB'),(245,307),Image.Resampling.LANCZOS)
            im.paste(thumb,(x+(245-thumb.width)//2,y+36))
        for sid,rect,label in [('detail-overview',(555,y+53,287,280),'상세 477×465'),('party-tall',(864,y+52,126,282),'준비 105×235'),('target-face',(1024,y+68,119,127),'얼굴 106×113')]:
            x,yy,ww,hh=rect
            tile=Image.open(OUT/'slot-previews'/f'{id}-{sid}.png').convert('RGBA').resize((ww,hh),Image.Resampling.LANCZOS)
            im.paste(tile,(x,yy),tile)
            d.text((x,y+28),label,font=small,fill='#171b19')
        d.text((1020,y+218),'안쪽 자르기',font=small,fill='#171b19')
        d.text((1020,y+240),'10칸 / 인물',font=small,fill='#171b19')
        d.text((1020,y+262),'생성 0회',font=small,fill='#171b19')
    quality=90
    while True:
        im.save(OUT/'sample-sheet.jpg',quality=quality,optimize=True)
        if (OUT/'sample-sheet.jpg').stat().st_size<=300000: break
        quality-=2
        assert quality>=30
    write('sheet-info.json',dict(width=w,height=h,bytes=(OUT/'sample-sheet.jpg').stat().st_size,quality=quality))


def verify():
    base=json.loads((OUT/'baseline-1b.json').read_text(encoding='utf-8'))
    old=json.loads((OUT/'baseline.json').read_text(encoding='utf-8'))
    hashes=json.loads((ROOT/'ASSET-HASHES.json').read_text(encoding='utf-8'))
    failures=[]
    changed=[p for p,h in base.items() if not (ROOT/p).exists() or sha(ROOT/p)!=h]
    oldchanged=[p for p,h in old.items() if not (ROOT/p).exists() or sha(ROOT/p)!=h]
    newprotected=[p for p in snapshot() if p not in base]
    badhash=[e['path'] for e in hashes if sha(ROOT/e['path'])!=e['sha256']]
    manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
    pixels=[]
    for e in manifest['entries']:
        src=np.array(Image.open(ROOT/e['source']).convert('RGB'))
        full=np.array(Image.open(ROOT/e['output']))
        target=full[:,25:550,:3]
        delta=np.abs(target.astype(int)-src.astype(int))
        n=int(np.any(delta!=0,axis=2).sum())
        face=FACES[e['id']]
        x0,y0,x1,y1=face
        pixels.append(dict(id=e['id'],original_frame_pixels=int(src.shape[0]*src.shape[1]),rgb_changed_pixels=n,max_channel_difference=int(delta.max()),mae_rgb=float(delta.mean()),face_rgb_changed_pixels=int(np.any(delta[y0:y1,x0:x1]!=0,axis=2).sum()),defringe_width_px=0,defringe_pixels=0))
        if n: failures.append(e['id']+' RGB mismatch')
        if np.any(full[:,:25,3]) or np.any(full[:,550:,3]): failures.append(e['id']+' nonempty padding')
    placements=json.loads((OUT/'preview-placement.json').read_text(encoding='utf-8'))
    slot_metrics=[]
    for p in placements:
        x0,y0,x1,y1=p['source_crop_xyxy']
        if not (0<=x0<x1<=525 and 0<=y0<y1<=768): failures.append(p['slot']+' exceeds original')
        im=Image.open(ROOT/p['output'])
        if list(im.size)!=p['native_asset_size'] or im.mode!='RGBA': failures.append(p['slot']+' format/size')
        source=Image.open(ROOT/f"project/assets/{p['id']}.webp").convert('RGB').crop((x0,y0,x1,y1))
        delta=np.abs(np.array(im)[:,:,:3].astype(int)-np.array(source).astype(int))
        count=int(np.any(delta,axis=2).sum())
        slot_metrics.append(dict(id=p['id'],slot=p['slot'],rgb_changed_pixels=count,max_channel_difference=int(delta.max())))
        if count: failures.append(p['id']+'/'+p['slot']+' RGB mismatch')
    sheetinfo=json.loads((OUT/'sheet-info.json').read_text(encoding='utf-8'))
    if sheetinfo['width']>1200 or (OUT/'sample-sheet.jpg').stat().st_size>300000: failures.append('sheet limit')
    if changed or oldchanged or badhash or newprotected: failures.append('protected file changes')
    result=dict(phase='1b',failures=len(failures),failure_details=failures,asset_hashes_checked=len(hashes),asset_hash_failures=badhash,protected_files_checked=len(base),protected_changed=changed,protected_new_files=newprotected,prior_baseline_checked=len(old),prior_baseline_changed=oldchanged,preservation_passed=sum(p['rgb_changed_pixels']==0 for p in pixels),preservation_failed=sum(p['rgb_changed_pixels']!=0 for p in pixels),pixels=pixels,slots_checked=len(placements),slot_rgb_changed_pixels=sum(p['rgb_changed_pixels'] for p in slot_metrics),slot_metrics=slot_metrics,outpaint_cases=0,defringe_width_px=0,defringe_pixels=0,sheet=sheetinfo)
    write('validation.json',result)
    print(json.dumps(result,ensure_ascii=True))
    return int(bool(failures))


def finalize():
    v=json.loads((OUT/'validation.json').read_text(encoding='utf-8'))
    assert v['failures']==0
    m=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
    m['visual_review']=dict(opened=True, reviewed=['three source WEBPs at native resolution','three checker composites','three dark background composites','three 10-slot galleries after face centering correction','final sample-sheet.jpg'],decision='RGB preservation passed for three masters and thirty native crops. Review outputs only; no game integration.',observations=['Faces, hair, clothing, exposure and colors follow original RGB exactly.','Hildegard and Marceline enclosed white hair gaps removed by alpha-only cleanup.','Fine pale fringes remain visible on some dark-background edges; no RGB defringe applied.','Naran tall ears are intact in upperbody master and intentionally cropped in face slots.','Side/bottom truncation remains from the originals and is hidden/cropped by slot bounds rather than invented.'])
    m['native_crop_assets']=30
    m['resampling']='Only verification previews are resized; all 33 asset PNGs retain native original RGB samples.'
    m['sheet']=dict(path='verification/portraits-r21/sample-sheet.jpg',**v['sheet'])
    m['archive']=dict(path='verification/portraits-r21/attempt-1b-before',files=sum(p.is_file() for p in ARCHIVE.rglob('*')),previous_outputs_hashes_match=True)
    oldm=json.loads((ARCHIVE/'verification/manifest.json').read_text(encoding='utf-8'))
    for e in oldm['entries']:
        archived=ARCHIVE/e['output']
        assert sha(archived)==e['output_sha256']
    write('manifest.json',m)
    slots=json.loads((OUT/'slots.json').read_text(encoding='utf-8'))
    slots['phase_1b']=dict(measured_rectangles_unchanged=True,master_canvas=[576,768],original_frame_xywh=[25,0,525,768],placement_file='verification/portraits-r21/preview-placement.json',generation_calls=0,inward_slot_cases=30,outpaint_slot_cases=0)
    for asset in slots['asset_types']:
        if asset['id']=='upperbody':
            asset['phase_1_note']='1단계의 요청/생성 치수는 attempt-1b-before/verification/slots.json에 보존.'
            asset['canvas']=[576,768]
            asset['alignment']='1:1 original 525x768 RGB at x=25,y=0; alpha-only matte; consumers use recorded native inward crops.'
            asset.pop('actual_generated_canvas',None)
            asset.pop('requested_canvas',None)
        else:
            asset['derivation']='Native RGB crop from same source-frame matte; no face generation; per-slot crop recorded in preview-placement.json.'
    write('slots.json',slots)
    rows='\n'.join(f"| {e['id']} | 403,200 | 0 | 0 | 0 | {e['parameters']['alpha_antialias_pixels']:,} | {e['parameters']['enclosed_background_pixels']:,} |" for e in m['entries'])
    report=f'''# 1b — 원본 RGB 복사 + 알파 매트 · 2026-10-31

**힐데가르트·마르셀린·나란 3명 보존 검사 3/3 통과, 실패 0.** 3명 × 실측 칸 10종 = **30/30건을 원본 프레임 안쪽 자르기로 처리**, 생성 **0회**다. 게임 코드·데이터와 기존 초상 파일은 변경하지 않았다. 지시한 3명 검토 범위에서 멈춘다.

원본 WEBP를 디코딩한 525×768 RGB를 576×768 RGBA PNG의 `(25,0)`에 리샘플링 없이 그대로 복사했다. 좌 25px·우 26px는 완전 투명 여백이며 몸을 생성한 부분이 아니다. **숨겨진 배경 RGB까지 포함해 원본 영역 1,209,600픽셀 전체가 동일**하다. 배경 제거는 알파만 바꿨고, PNG 압축 바이트의 동일성을 RGB 동일성과 혼동하지 않았다. 원본 WEBP 파일 바이트는 SHA-256으로 별도 검사했다.

**수치와 판정**

| 인물 | 원본 영역 픽셀 | RGB 변경 픽셀 | 최대 채널 차 | RGB 디프린지 픽셀 | 1px 알파 경계 픽셀 | 닫힌 배경 정리 픽셀 |
|---|---:|---:|---:|---:|---:|---:|
{rows}

- RGB 디프린지 **폭 0px / 0픽셀**, 원본 영역 RGB MAE **0**, 얼굴 영역 RGB 차이 **0픽셀**. 경계 RGB 예외를 사용하지 않았다.
- 알파 경계 정리는 안쪽 **1px**에 한정했다. 색 거리·테두리 연결 배경 매트에 원본을 직접 보고 지정한 머리카락 사이 배경 영역을 더했다. 나란의 흰 머리·털·옷에는 내부 흰색 제거를 적용하지 않았다. 임계값과 정리 영역 좌표는 `manifest.json`에 기록했다.
- 칸별 자르기 PNG **30개도 원본 해상도의 RGB를 그대로 보존**, 변경 **0픽셀**. 미리보기 합성에서만 칸 크기로 리샘플링했다. 파일 자체의 해상도와 목표 칸 해상도는 `preview-placement.json`에 각각 기록했다.
- 생성/확장 **0회 / 0픽셀**, 이음매 혼합 **0px**. 확장 검수 대상은 없다. 기존 실측 10개 칸 모두 기록된 crop 좌표가 `[0,0,525,768]` 안에 들어간다.
- 원본 자산 해시 **{v['asset_hashes_checked']}/96 일치**, 실패 **0**. 이번 시작 보호 파일 **{v['protected_files_checked']:,}개 변경 0**, 허용 경로 밖 새 파일 **0**. 이전 기준 **{v['prior_baseline_checked']:,}개도 변경 0**. 게임 코드·데이터 불변이므로 1b 지시대로 공통 Godot 검사는 재실행하지 않았다. 이번 수치를 이전 공통 시험의 새 실행 결과로 주장하지 않는다.

**산출·변경 파일**

- `project/assets/portraits-r21/{{hildegard,marceline,naran}}-upperbody.png`: 3:4 RGBA 원본 보존 마스터 3개, 576×768. 실제 원본 영역은 `(25,0,525,768)`.
- `project/assets/portraits-r21/slots/*.png`: 인물당 10종, 총 30개 원본 크롭. D가 쓸 경우 `preview-placement.json`의 목표 크기·좌표를 함께 참고한다.
- `verification/portraits-r21/sample-sheet.jpg`: 원본 | 체커 결과 | 상세·준비·얼굴 시안 칸 합성, **{v['sheet']['width']}×{v['sheet']['height']}, {v['sheet']['bytes']:,} bytes**, JPEG 품질 {v['sheet']['quality']}. 폭 1200 이하·300,000 bytes 이하 통과.
- `verification/portraits-r21/{{manifest,validation,preview-placement,slots,sheet-info,baseline-1b}}.json`, `matte/*-alpha.png`, `*-checker.jpg`, `*-dark.jpg`, `*-matte-review.jpg`, `*-all-slots.jpg`, `slot-previews/*.png`: 수치·매트·육안 검토 자료.
- `verification/portraits-r21/attempt-1b-before/`: **{m['archive']['files']:,}개 파일** 보존. 이전 PNG·메타데이터·로그·시험 복제본을 이동했고, 이전 도구 4개와 보고서 원문도 넣었다. 이전 최종 PNG 3개는 이전 manifest SHA-256과 일치한다. 실측 `slots.json`과 이전 `baseline.json`만 현재 검사에 필요한 사본을 다시 두었다. 아래 1단계 본문도 원문을 유지한다.
- `tools/matte_portrait_r21.py`: 재현 도구. 제작은 `python tools/matte_portrait_r21.py build`, 검사만 재현하려면 `python tools/matte_portrait_r21.py verify`. `archive`는 중복 실행을 거부한다. 검토 기록/보고서 갱신은 직접 육안 검토 후에만 `finalize`로 한다.
- `UI-R21-C.md`: 이 1b 절을 맨 위에 추가.

**직접 연 결과와 남은 한계**

원본 3장, 체커/어두운 배경 합성 3장씩, 최종 인물별 10칸 갤러리 3장, 최종 비교 시트를 직접 열었다. 넓은 얼굴 칸에서 턱이 잘리던 구도는 원본 안에서 crop을 아래로 옮겨 얼굴이 보이도록 수정하고 다시 열었다. 얼굴·머리·옷·노출·색의 재그림은 없고, 원본 갑옷과 털 형태가 유지된다.

일부 머리 외곽과 갑옷 가장자리에는 어두운 배경에서 가는 밝은 테두리가 남는다. 이를 없애기 위한 RGB 디프린지는 하지 않았다. 원본의 좌우·아래 잘림도 마스터에는 그대로 남아 있으며, 확장 완성품으로 판정하지 않는다. 큰 초상 칸은 시안 경계로 어깨·몸통을 자르고, 작은 얼굴 칸은 나란의 귀 및 인물의 머리 윗부분을 일부 자른다. 시트의 시안 합성은 실측 크기·사선 마스크를 적용한 깨끗한 패널이며 실제 게임 스크린샷은 아니다. 실측 오차 ±4px는 이전과 같다. 게임 연결, 실제 UI에서의 실행 검증, 나머지 27명 제작은 하지 않았다.

---

'''
    oldreport=(ARCHIVE/'UI-R21-C.md').read_text(encoding='utf-8')
    (ROOT/'UI-R21-C.md').write_text(report+oldreport,encoding='utf-8')
    print(json.dumps(dict(report=str(ROOT/'UI-R21-C.md'),preserved=3,slot_cases=30,generation_calls=0,sheet_bytes=v['sheet']['bytes']),ensure_ascii=True))


if __name__=='__main__':
    command=sys.argv[1] if len(sys.argv)>1 else 'verify'
    if command=='archive': archive()
    elif command=='build': build()
    elif command=='verify': sys.exit(verify())
    elif command=='finalize': finalize()
    else: raise SystemExit('archive|build|verify|finalize')
