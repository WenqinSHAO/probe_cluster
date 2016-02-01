# RIPE Atlas probe clustering
## Intro
to be added.
## Plan and progress
- Select probes hosted in datacentres across the europe (done, 27/01/16) (need to prove this group of probes are less impacted by local conditions);
- Do some simple stats on prefix, ASN, country; (done 27/01/16)
  - there are probes having no network info, say address prefix; check what happened.
  - it turns out there are abandoned and disconnected probes as well selected, seems to be an issue with the probe query API that ignores (i assume, mailed list waiting for confirmation or patches) the content of status_name field.
  - Confirmed by Atlas staff that status_name and status fields are actually ignored. Have to clean ourselves. (done 28/01/16)
  - the bug related to status_name and status query field is now fixed by Atlas staff. (28/01/06)
- collect ping and traceroute to one DNS root server;
  - b root is chosen. It has only one instance, which saves us concerns on anycast.
  ```
  Operator: Information Sciences Institute
  IPv4: 192.228.79.201
  IPv6: 2001:500:84::b
  ASN: ''
  Homepage: http://b.root-servers.org/
  Statistics: ''
  Peering Policy: ''
  Contact Email: b-poc@isi.edu
  RSSAC: http://b.root-servers.org/rssac/
  Identifier Naming Convention: ''
  Instances:
  Country: USA
  IPv4: 'Yes'
  IPv6: 'Yes'
  Latitude: '34.05'
  Longitude: '-118.25'
  Sites: 1
  State: California
  Town: Los Angeles
  Type: Global
  ```
  - Built-in ping (\#1010) and traceroute (\#5010) measurements are collected from 2016-01-18 to 2016-01-25 UTC. (done 28/01/16, resulted .json file is not included in this repository, as they are big and one can get them easily using the script fectch_res_pbid.py)
  - text file containing probe lists (pbid.txt) can be generated with following R code:
  ```R
  probes <- read.csv("probes.csv", header=T)
  write(probes$id, "pbid.txt", ncolumns=1)
  ```
- clean traces to arrive at tidy datasets;
  - script and results uploaded. (done 29/01/16)
  - add file explain cleaning criteria. (done 01/02/16)
  - TODO: combine cleaning results of ping and traceroute, dis-sync timestamps
  - TODO: devise an appropriate data structure
- exploratory analysis on feature space;
  - RTT measurement in feature space. (mightbe begin this first)
  - for each probe traceroute trace, path length, path changes, etc. basic stats;
  - translate ip-level path to AS-level path; path length, path change, etc, stats;
  - probes set of common AS-path segments
  - probe groups of similar variations in time
  - compare groups
