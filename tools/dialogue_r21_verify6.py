"""Preserve sixth-pass regression evidence in its own directory."""
import dialogue_r21_verify as runner
from dialogue_r21_build import ROOT

if __name__ == '__main__':
    runner.OUT = ROOT / 'verification/dialogue-r21/regression6'
    raise SystemExit(runner.main())
