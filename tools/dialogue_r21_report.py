"""Generate the latest completed editorial pass."""
from dialogue_r21_build import OUT
if (OUT/'edits5-applied.json').exists():
    from dialogue_r21_report5 import main
else:
    from dialogue_r21_report4 import main

if __name__ == "__main__":
    main()
