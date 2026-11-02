from pathlib import Path
import sys,re,json,hashlib
sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path(__file__).resolve().parents[2]
SRC=Path('C:/Clauede Code/dungeon-bot/bot/src')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def show(p,mode='full',lo=1,hi=100000):
    s=p.read_text(encoding='utf-8-sig');lines=s.splitlines()
    print(f'\n=== {p.name} ({len(lines)} lines) ===')
    for i,l in enumerate(lines,1):
        if not lo<=i<=hi:continue
        if mode=='outline' and not re.search(r'^\s*(?:function |B[.\[]|local function |--.*(?:===|──|[0-9]+\.)|(?:if|elseif)\s+arg|(?:elif|func |static func |const |var ))',l):continue
        if mode=='code' and (not l.strip() or l.lstrip().startswith('--')):continue
        if mode=='brief' and (not l.strip() or l.lstrip().startswith('--')):continue
        cap=220 if mode in ('brief','outline') else 1000
        print(f'{i}: {l[:cap]}'+(f' … [{len(l)} chars; full text read by indexer]' if len(l)>cap else ''))
if __name__=='__main__':
    mode=sys.argv[1]
    for arg in sys.argv[2:]:
        bits=arg.split('@');p=Path(bits[0]);p=p if p.is_absolute() else (ROOT/p if '/' in bits[0] else SRC/p)
        lo,hi=(map(int,bits[1].split(':')) if len(bits)>1 else (1,100000))
        show(p,mode,lo,hi)
