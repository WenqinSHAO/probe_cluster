# What it is about
To be added...

# How the whole thing goes
1. select probes with *select_probe.py*, produces *probes.csv*;
2. generate *pbid.txt* with two lines of R code;
3. fetch measurements with *fetch_res_pbid.py*, store in *ping_broot.json* and *trace_broot.json* file;
4. clean ping and traceroute with *cleaning.py*, produce *ping_rm.txt*, *trace_rm.txt*, *ping_val.txt*, *trace_val.txt*;
5. obtain ids of valid probes with a few lines of R code, produce *valid.txt*;
6. align ping measurements with *alignRTT.py*, produces *pingAL_min.csv*;
7. *exploratoryAnalysis.R* reads *probes.csv* and *pingAL_min.csv* , produces clustering results, graphs and more;
8. *plot_ping_suffix.py* read ids in files with certain suffix, and produce 3d RTT plots.
9. *ip2asn\*.py* -> ip2asn dic
10. *comIPDic.py* -> merged dic
11. *pathStat.py* -> *stat_\*.json*
12. *pathStat.R* -> figures
