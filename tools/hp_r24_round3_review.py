"""Review the ten target-only captures and record preservation evidence."""
from pathlib import Path
import difflib, hashlib, json, shutil
from PIL import Image, ImageDraw, ImageFont, ImageChops

R = Path(__file__).resolve().parents[1]
O = R / 'verification/hp-r24/round3'
def write(name, data):
    (O/name).write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

results = json.loads((O/'results.json').read_text(encoding='utf-8'))
assert not results['failures'] and len(results['captures']) == 10
sheet = Image.new('RGB', (2200,1000), '#d6d0c3')
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 16)
comparisons = []
for i, name in enumerate(results['captures']):
    image = Image.open(O/name).convert('RGB')
    previous = Image.open(O.parent/'round2'/name).convert('RGB')
    width, height = image.size
    frame_width, frame_height = min(430,width), min(860,height)
    x, y = (width-frame_width)//2, (height-frame_height)//2
    party = (x+12,y+frame_height-159,x+frame_width-12,y+frame_height-9)
    identical = ImageChops.difference(image.crop(party),previous.crop(party)).getbbox() is None
    comparisons.append({'capture':name,'party_crop':party,'party_identical':identical})
    assert identical, name
    crop = image.crop((x,88,x+frame_width,min(560,height-450)))
    column, row = i//2, i%2
    sheet.paste(crop,(column*440,row*500+30))
    draw.text((column*440+4,row*500+5),name.removeprefix('target-').removesuffix('.png'),font=font,fill='black')
sheet.save(O/'review-target.png')
write('party-pixel-comparison.json', comparisons)

before = json.loads((O/'before.json').read_text(encoding='utf-8'))
preserved = {p:sha(R/p)==value for p,value in before.items() if p!='project/ui/battle_screen.gd'}
assert all(preserved.values())
write('preservation.json', preserved)
assets = json.loads((R/'ASSET-HASHES.json').read_text(encoding='utf-8'))
unchanged = [a['path'] for a in assets if sha(R/a['path'])==a['sha256']]
assert len(unchanged)==len(assets)==96
write('asset-check.json', {'checked':len(assets),'unchanged':len(unchanged)})
old = (O/'battle_screen.before.gd').read_text(encoding='utf-8')
new = (R/'project/ui/battle_screen.gd').read_text(encoding='utf-8')
assert new.replace(''.join(new.splitlines(keepends=True)[390:394]),'',1)==old
(O/'product.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='round2/battle_screen.gd',tofile='round3/battle_screen.gd')),encoding='utf-8')
log = (O/'target-test.log').read_bytes()
log = log.decode('utf-16') if log.startswith(b'\xff\xfe') else log.decode('utf-8-sig')
(O/'target-test.log').write_text(log,encoding='utf-8')
errors = [line for line in log.splitlines() if ('SCRIPT ERROR:' in line or line.startswith('ERROR:') or 'python : ERROR:' in line) and 'root certificate store' not in line]
assert not errors and 'HP R24 ROUND3 CHECKS 1101 FAILURES 0' in log
write('test-summary.json', {'test':'ui_hp_r24_round3_test','checks':results['checks'],'failures':results['failures'],'unexpected_errors':errors,'captures':len(results['captures']),'real_input_selections':24,'marker_cases':len(results['markers']),'minimum_plate_gap_px':min(m['plate_gap'] for m in results['markers']),'environment_diagnostic':'Windows root certificate store diagnostic, unchanged from round2','scope':'Related target/plate/selection checks only; full regression and 6320-battle audit were not rerun'})
base = (R/'verification/ui-r17').resolve()
removed = []
for name in ['runtime-hp-r24-round3','runtime-local-hp-r24-round3','tmp-hp-r24-round3']:
    path = (base/name).resolve()
    assert path.parent==base and path.name==name and path.is_relative_to(R.resolve())
    if path.exists():
        shutil.rmtree(path)
        removed.append(str(path))
write('cleanup.json', {'removed':removed,'remaining':[name for name in ['runtime-hp-r24-round3','runtime-local-hp-r24-round3','tmp-hp-r24-round3'] if (base/name).exists()],'default_runtime_preserved':(base/'runtime').is_dir()})
print(f"{results['checks']} checks, 0 failures; 10/10 party crops identical; 96/96 assets unchanged")
