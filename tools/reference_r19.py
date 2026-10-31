"""Read-only reference DOM and panel capture; all output stays in this tree."""
from pathlib import Path
import hashlib, json, re, os, tempfile
from playwright.sync_api import sync_playwright
R=Path(__file__).resolve().parents[1]
O=R/'verification/ui-r19'; O.mkdir(parents=True,exist_ok=True)
runtime=O/'runtime/browser';runtime.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(runtime)
for key in ['TEMP','TMP','TMPDIR']:os.environ[key]=str(runtime)
REF=R.parents[1]/'outputs/r17-battle'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
if not (O/'before.json').exists():
    files=[p for folder in ['project/ui','project/tests','project/game','project/data','tools'] for p in (R/folder).rglob('*') if p.is_file()]
    (O/'before.json').write_text(json.dumps({'hashes':{p.relative_to(R).as_posix():sha(p) for p in files},'pck_bytes':(R/'docs/index.pck').stat().st_size},indent=2),encoding='utf-8')
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True)
    page=b.new_page(viewport={'width':390,'height':844},device_scale_factor=1)
    records={}
    for state in ['base','target','status','skills','supplies','log']:
        page.goto((REF/'src/index.html').as_uri()+'?screen='+state)
        page.evaluate('document.fonts.ready')
        page.locator('.screen').screenshot(path=str(O/f'reference-{state}-390.png'))
        records[state]=page.evaluate("() => [...document.querySelectorAll('.screen *')].filter(e=> !e.closest('svg')).map(e=>{\nconst r=e.getBoundingClientRect(), c=getComputedStyle(e); const direct=[...e.childNodes].filter(n=>n.nodeType===3 && n.textContent.trim()); const text=direct.map(n=>n.textContent).join('').trim();\nlet baseline=null;\nif(direct.length){const n=direct[0], wrap=document.createElement('span'),marker=document.createElement('span');wrap.style.cssText='all:unset'; marker.style.cssText='all:initial;display:inline-block;width:0;height:0;position:static;padding:0;margin:0;border:0;vertical-align:baseline;line-height:0';n.replaceWith(wrap);wrap.append(n,marker);baseline=marker.getBoundingClientRect().top;wrap.replaceWith(n);}\nreturn {baseline,selector:e.tagName.toLowerCase()+'.'+[...e.classList].join('.'),text,rect:[r.x,r.y,r.width,r.height],font:c.fontFamily,size:c.fontSize,weight:c.fontWeight,tracking:c.letterSpacing,line_height:c.lineHeight,color:c.color,background:c.backgroundColor};})")
    b.close()
(O/'reference-dom.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
(O/'reference-css.txt').write_text(re.sub(r'data:image/[^\x27]+','[embedded reference-only mask omitted]',(REF/'src/style.css').read_text(encoding='utf-8')),encoding='utf-8')
print('Captured six reference panels and DOM geometry.')
