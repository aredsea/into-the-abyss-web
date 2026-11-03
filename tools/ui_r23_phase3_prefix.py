"""Give every new comparison artifact the brief's ui- filename prefix."""
from pathlib import Path
import re,hashlib
R=Path(__file__).resolve().parents[1];P=R/'verification/parity-r23/ui-phase3'
names=['oracle.json','baseline.json','semantics-results.json','native-results.json','cloud-results.json','dictionary-changes.json','report-before.md','hashes-before.json','row-review.json','summary.json','write-audit.json','suite-coverage.json','visual-review.json']
targets=list((R/'tools').glob('ui_r23_phase3_*.py'))+[R/'tools/ui_r23_phase3_oracle.mjs']+[R/'project/tests'/n for n in ['ui_semantics_r23_test.gd','ui_semantics_native_r23_test.gd','ui_cloud_replacement_r23_test.gd']]
for p in targets:
    if p.name==Path(__file__).name:continue
    text=p.read_text(encoding='utf-8');before=text
    for name in names:text=re.sub(r'(?<![A-Za-z0-9_-])'+re.escape(name),'ui-'+name,text)
    if text!=before:p.write_text(text,encoding='utf-8')
renamed=[]
for name in names:
    source=P/name;dest=P/('ui-'+name)
    if source.exists():
        assert source.resolve().parent==P.resolve() and dest.resolve().parent==P.resolve()
        if dest.exists():
            assert hashlib.sha256(dest.read_bytes()).digest()==hashlib.sha256(source.read_bytes()).digest()
            source.unlink()
        else:source.rename(dest)
        renamed.append(dest.name)
for source in list((P/'render').glob('*.png')):
    if source.name.startswith('ui-'):continue
    dest=source.with_name('ui-'+source.name)
    assert source.resolve().parent==(P/'render').resolve() and not dest.exists()
    source.rename(dest)
print('Prefixed comparison files:',len(renamed))
