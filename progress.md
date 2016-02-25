# Progress and working plan
- Select probes hosted in datacentres across the europe (done, 27/01/16) (need to prove this group of probes are less impacted by local conditions);
**NOTE: probe selection results may differ, if the script launched on different day, as the status of probes change over time. Once probes re-selected, DO remember update pbid.txt, ping trace measurements and valid.txt.**
- Do some simple stats on prefix, ASN, country; (done 27/01/16)
  - there are probes having no network info, say address prefix; check what happened.
  - it turns out there are abandoned and disconnected probes as well selected, seems to be an issue with the probe query API that ignores (i assume, mailed list waiting for confirmation or patches) the content of status_name field.
  - Confirmed by Atlas staff that status_name and status fields are actually ignored. Have to clean ourselves. (done 28/01/16)
  - the bug related to status_name and status query field is now fixed by Atlas staff. (28/01/06)
- collect ping and traceroute to one DNS root server;
  - [b root](http://b.root-servers.org/) is chosen. It has only one instance, which saves us concerns on anycast.
  Plusm, it is on another continent across the oceans,
  which increases the chance that the selected probes in Europe might share transatlantic links to reach the destination.  
  - Built-in ping (\#1010) and traceroute (\#5010) measurements are collected from 2016-01-18 to 2016-01-25 UTC. (done 28/01/16, resulted .json file is not included in this repository, as they are big and one can get them easily using the script fectch_res_pbid.py)
  - text file containing probe lists *pbid.txt* can be generated with following R code:
  ```R
  probes <- read.csv("probes.csv", header=T)
  write(probes$id, "pbid.txt", ncolumns=1)
  ```
  - **NOTE: not all the selected probes have measurement data, as probe's current status is not
  necessary consistent with its status is the past. An example is for a newly joined probe, it
  may appear to be connected, but do posses any measurement data during the data collection period.**
- clean traces to arrive at tidy datasets;
  - script and results uploaded; probes to be removed stored in *ping_rm.txt* and *trace_rm.txt* . (done 29/01/16)
  - Considering the note right above, valid probes with actual measurement traces are separately stored in *ping_val.txt* and *trace_val.txt* . (done 25/02/16)
  - add file explain cleaning criteria. (done 01/02/16)
  - add file *valid.txt* storing the ID of valid probes,
  ~~ones in *pbid.txt* subtracted by ones in *ping_rm.txt*  and *trace_rm.txt*.~~
  being intersection of IDs in *ping_val.txt* and *trace_val.txt*.
  The file can be generated with following R code:
  ```R
  ping <- c(as.matrix(read.csv("ping_val.txt", header=F)))
  trace <- c(as.matrix(read.csv("trace_val.txt", header=F)))
  valid <- intersect(ping, trace)
  write(valid, file='valid.txt',ncolumns = 1)
  ```
  It is not a surprise to notice that probes in *ping_rm.txt* (35 probes) and *trace_rm.txt* (25 probes) overlap a lot,
  21 among them are actually in common. (Total selected probe number is 170.)
  128 probes with valid measurement records remain.
  - Align ping measurements of probes in *valid.txt* with script *alignRTT.py*. (done 03/02/16)
  - document alignment operation and how we handle invalid values (done 07/02/16)
  - Put all global variables, such measurement time range, in one file (done 23/02/16)
- exploratory analysis on feature space;
  - RTT measurement in feature space.
      - Compared different ways estimating PSD (done 18/02/16)
      - Add features based on CPA (done 12/02/16)
      - Adapt CPA calculation for RTT (done 19/02/16)
      - ANOVA test on feature (done 18/02/16)
      - Translate IP to ASN, tried both Cymru and ARIN source. (done 25/02/16)
      ```
      Cymru
      1144 entries in all.
           57 of them are private address.
           50 don't have resolution results.
           225 unique ASN appeared.
      ARIN
      1144 entries in all.
           57 of them are private address.
           322 don't have resolution results.
           225 unique ASN appeared.
      ```
      - IP to ASN resolution results are compared and merged. (done 25/02/16)
      ```
      Both hit 802
	         same 794
	         diff 8
      Both miss 30
      Cymru single hit 292
      ARIN single hit 20
      ```
      For 8 IP addresses that resolution results that differ, I manually cross check with [hurricane](http://bgp.he.net/ip).
      The results from [hurricane](http://bgp.he.net/ip) and Cymru agree with each other.
      Therefore, the dictionary merge bases on the Cymru one, only ARIN single hit is added.
      - TODO: compare changepoints to traceroute path changes
      - TODO: document the tests so far perform in choosing features
  - Clustering in time-series data representation
      - Device new data representation based on CPA (done 19/02/16)
      - TODO: cross clustering results and traceroute
      - TODO: review the pathology biblio
