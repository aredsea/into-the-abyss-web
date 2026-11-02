"""Run the unmodified skill gates on the 99 deterministic lossless chunks."""
from concurrent.futures import ThreadPoolExecutor
import json
import subprocess
import sys
from dialogue_r21_build import ROOT, OUT, read_json, write_json

SKILL = ROOT.__class__('C:/Users/asone/.codex/skills/humanize-korean')


def main():
    run = ROOT/'_workspace/2026-11-03-001-8495'
    manifest = read_json(run/'chunk_manifest.json')
    source = (run/'01_input.txt').read_text(encoding='utf8')
    target = OUT/'humanize-gates5'
    target.mkdir(exist_ok=True)
    def job(chunk):
        index=chunk['index']
        before=run/f'01_chunk_{index:02d}_original.txt'
        before.write_text(source[chunk['start']:chunk['end']],encoding='utf8')
        command=[sys.executable,'-X','utf8',str(SKILL/'scripts/verify_gates.py'),
            '--before',str(before),'--after',str(run/chunk['rewritten_file']),'--genre','essay','--json']
        p=subprocess.run(command,cwd=ROOT,capture_output=True,timeout=120)
        text=(p.stdout+p.stderr).decode('utf8',errors='replace')
        (target/f'chunk-{index:02d}.log').write_text(text,encoding='utf8')
        start=text.find('\n{')
        report=json.loads(text[start+1:]) if start>=0 else {'parse_error':text[:300]}
        return dict(index=index,exit_code=p.returncode,source_chars=chunk['char_count'],report=report)
    with ThreadPoolExecutor(max_workers=4) as pool:
        results=list(pool.map(job,manifest['chunks']))
    write_json(target/'results.json',results)
    summary=dict(chunks=len(results),errors=sum(r['exit_code']>=2 for r in results),
                 warning_chunks=[r['index'] for r in results if r['exit_code']==1],
                 scope='99개 결정 청크 각각에 스킬 원본 verify_gates.py를 실행했다. 전역 산문 69만자 문자 정렬은 처리 지연으로 중단했다. 청크별 문자율을 사용하며 전역 문자율로 바꾸어 주장하지 않는다.')
    write_json(target/'summary.json',summary)
    print(summary)
    return int(bool(summary['errors']))


if __name__=='__main__':
    raise SystemExit(main())
