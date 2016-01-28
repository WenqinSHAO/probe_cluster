# RIPE Atlas probe clustering
## Intro
to be added.
## Plan
- Select probes hosted in datacentres across the europe (need to prove this group of probes are less impacted by local conditions); (done, 27/01/16)
- Do some simple stats on prefix, ASN, country; (done 27/01/16)
  - there are probes having not network info, say address prefix; check what happened.
  - it turns out there are abandoned and disconnected probes as well selected, seems to be an issue with the probe query API that ignores (i assume, mailed list waiting for confirmation or patches)the content of status_name field.
  - consequence, the resulted the probes list is not clean,contain inactive probes.
- collect ping and traceroute to one DNS root server (which one? how to justify?);
- clean traces to arrive at tidy datasets;
- exploratory analysis on feature space;
