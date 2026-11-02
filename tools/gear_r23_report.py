"""Generate the current R23 report (first-pass artifacts are retained)."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('gear_r23_report_round2.py')), run_name='__main__')
