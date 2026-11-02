"""Run unchanged mutation suites, isolating fifth-pass output paths."""
import subprocess
import sys
from dialogue_r21_build import ROOT, OUT, write_json
import dialogue_r21_selftest4 as registers

if __name__ == '__main__':
    p = subprocess.run([sys.executable,'-X','utf8','tools/dialogue_r21_selftest.py',
                        '--report',str(OUT/'selftest5.json')],cwd=ROOT,capture_output=True)
    print('base-selftest-exit',p.returncode)
    if p.returncode:
        print(p.stdout.decode('utf8',errors='replace'))
        raise SystemExit(p.returncode)
    registers.write_json = lambda path,data: write_json(OUT/'selftest5-registers.json',data)
    raise SystemExit(registers.main())
