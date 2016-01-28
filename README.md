# RIPE Atlas probe clustering
## Intro
to be added.
## Plan and progress
- Select probes hosted in datacentres across the europe (done, 27/01/16) (need to prove this group of probes are less impacted by local conditions);
- Do some simple stats on prefix, ASN, country; (done 27/01/16)
  - there are probes having no network info, say address prefix; check what happened.
  - it turns out there are abandoned and disconnected probes as well selected, seems to be an issue with the probe query API that ignores (i assume, mailed list waiting for confirmation or patches)the content of status_name field.
  - Confirmed by Atlas staff that status_name and status fields are actually ignored. Have to clean ourselves. (done 28/01/16)
  - the bug related to status_name and status query field is now fixed by Atlas staff. (28/01/06)
- collect ping and traceroute to one DNS root server (which one? how to justify?);
- clean traces to arrive at tidy datasets;
- exploratory analysis on feature space;
