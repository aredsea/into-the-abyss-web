"""Observe an already running native test if its Python wrapper timed out."""
from pathlib import Path
import ctypes,sys,json,time,re
R=Path(__file__).resolve().parents[1];pid=int(sys.argv[1]);name=sys.argv[2]
k=ctypes.WinDLL('kernel32',use_last_error=True);k.OpenProcess.argtypes=[ctypes.c_ulong,ctypes.c_int,ctypes.c_ulong];k.OpenProcess.restype=ctypes.c_void_p;k.WaitForSingleObject.argtypes=[ctypes.c_void_p,ctypes.c_ulong];k.GetExitCodeProcess.argtypes=[ctypes.c_void_p,ctypes.POINTER(ctypes.c_ulong)];k.CloseHandle.argtypes=[ctypes.c_void_p]
handle=k.OpenProcess(0x100000|0x1000,False,pid)
if not handle:raise SystemExit('Native test already exited before observer could attach')
while k.WaitForSingleObject(handle,1000)==258:pass
code=ctypes.c_ulong();k.GetExitCodeProcess(handle,ctypes.byref(code));k.CloseHandle(handle)
log=R/sys.argv[3] if len(sys.argv)>3 else R/'verification/reskin-r24/tests'/(name+'.log')
raw=log.read_bytes();text=raw.decode('utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8',errors='replace')
errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
row={'test':name,'exit':code.value,'errors':errors,'passed':code.value==0 and not errors,'summary':[s[:300] for s in text.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|PASS',s)][-3:],'note':'Original native process completed after Python-wrapper timeout; exit code observed from its process handle, no rerun or expectation changes.'}
path=R/'verification/reskin-r24/late-results.json';rows=json.loads(path.read_text(encoding='utf-8')) if path.exists() else [];rows=[r for r in rows if r['test']!=name]+[row];path.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(row),flush=True)
