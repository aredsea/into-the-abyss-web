"""Run the common regressions into a new directory, retaining older evidence."""
import dialogue_r21_verify as runner
from dialogue_r21_build import ROOT

if __name__ == '__main__':
    runner.OUT = ROOT / 'verification/dialogue-r21/regression3'
    raise SystemExit(runner.main())
