#Cleaning procedure
Not all the measurements fetched (with *fetch_res_pbid.py*) according to *pbid.txt*
can be exploited, as some of them are highly incomplete due to various reasons.
Cleaning is thus needed to remove these traces of corresponding Atlas probes.
The script *cleaning.py* does the job.
Before looking at the code, we would like to first introduce **the criteria** considered,
and their practical meanings.
Then we will see how these parameters are implemented and tuned in the script.

## The idea
The cleaning procedure applies to both ping and traceroute measurements.
There are common causes of data incompleteness for both cases.
Yet, there are also issues that are exclusive to traceroute.
We begin with mutual ones first.

### Unstable connection to the Atlas platform (suspect, or other unknown problems)
If a probe is suffering from some connection issue to the Atlas platform,
or undergoing local firmware or hardware problems, the Atlas server might not
receive the measurements at the scheduled interval.
As a consequence, one witnesses unexceptedly large lag between certain measurement
timestamps and the total length of the record is relatively shorter than the ideal
case, i.e. time range divided by interval.
Though the real causes behind such data incompleteness rest unknown, we believe
that it is prudent to disregard the measurements from such probes that are exposed to
potential problems.

### Invalid measurement values.
Apart from the inherent missing of data, there could as well be invalid values,
that can not be treated the same way as the rest, in traces collected.
This is where ping and traceroute measurement differ from each other.
#### ping
The ping trace from an Atlas probe to certain destination is composed of measurement
conducted at a series of timestamps.
For a single measurement, if all the ping requests send are lost (or timeout),
we will have -1, an invalid RTT (Round-Trip Time) measurement value, for the avg, min and max fields.
If many times, the measured RTT value is -1 in the trace, it indicates that the path being measured is
probably of poor quality (could be link congestion, or destination dropping ICMP, etc.,).
As we are not interested in such black/white description of the path status,
we would like to argue that it is appropriate to leave out traces having to much
of invalid values.
One might argue that it is possible to depict the path using packet loss, where -1
due to total request loss can be translated into 100% packet loss, is actually a valid value.
However, describing the loss rate of path using a handful of ping at very coarse interval is highly
inaccurate and thus meaningless.
It is also worthy of noting that -1 in avg, min and max can also be caused by the
presence of err field in the measurement results, which in most cases can not be regarded as valid.
#### traceroute
A traceroute trace is composed of a series of IP-level path snapshot along the time axis.
In following cases, we consider an IP-level path as invalid as no enough information is provided to described the path:
- ends with an \*, indicating that the traceroute measurement failed to reach the destination;
- has too much \*. It is important to note that Atlas allows **5** consecutive \* at most.
Once the limit is reach, it will skip directly to the final destination and ends the measurement.
Such measurement should be regarded as invalid.
- contains too much hops missing measurement values due to the presence of err field.

Naturally, a traceroute record containing two much invalid IP-path snapshot is very difficult to compare with other traces.
Therefore we remove the traces of such probes.

## The script
The *cleaning.py* script implements the above cleaning criteria and can be used for both ping and trouceroute data. The usage is given as follows:
```
python cleaning.py t/p(trace/ping) filename
```
The cleaning criteria can be tuned by altering following gloabl variables.
The values used to generate *ping_rm.txt* and *trace_rm.txt* are as well given.
```python
INTV_MX = 2 # the maximum tolerable consecutive connection losses, times by interval.
LEN_P = 0.9 # the minimum length portion compared to ideal case.
INV_PING = 0.1 # the invalid value measurement shall not surpass 0.1 of ideal length.
INV_PATH = 0.2 # an IP-path is considered invalid if it has * hops that surpass 0.2 of path's total length.
INV_TRACE = 0.3 # if more than 0.3 of all IP-path snapshots are invalid, the entire trace is regarded as un-exploitable.
```
Each time the script is run, the exact cleaning criteria applied to the data is as well printed on the screen.
## Cleaning summary
### Ping measurement
```
Ping trace
An RTT measurement
- equals -1;
- missing value;
- contains err field;
is considered invalid.

Cleaning criteria:
           Minimum length: 2268.000000,
           Maximum neighbour interval: 480.000000,
           Maximum invalid values: 252.000000.

Probes to be removed:
ID           Len. Max. Intv   # Invd.
  18945      2517       960         3
  23812      2503      4321         2
  20487      1992       479         1
  20745      2510      1442         0
  20874      2510      2640         3
  17931      2519       481         1
  10638      2517       960         6
  21391      2517       960         1
  22545      2517       960         2
  16530      2502      4558         1
  22958      2408     27122         0
  21956      2510      2639         3
  21283      2517       960         2
  20644      2517       961         1
  24562       587       243         0
  13870      2506      3120         0
  25263      2519       483         1
  10806      2512      2401         0
  20673      2511      2400         0
  13124      2518       721         0
  11598      2517       966         0
  20052      2517       957         1
  21333      2517       960         6
  22487      2518       720         2
  24415      2516      1199         1
  19682      1573       244         0
  21349      2343     42719         0
  15594      1266       244         1
  10604      2518       721         1
  22898      2411     26401         2
  13939      2517       959         0
  20468      2518       722         1
  16757       865       243         0
  17270      2517       959         5
  21588      2510      2642         1
```

### Traceroute measurement
```
Traceroute trace.
An ip-path
- ends with *;
- or contains more than 0.200000 *;
- or contains five or more consecutive *is considered invalid.

Cleaning criteria:
           Minimum length: 302.400000,
           Maximum neighbour interval: 3600.000000,
           Maximum invalid values: 100.800000.
Probes to be removed:
ID           Len. Max. Intv   # Invd.
  23812       334      5399         1
  20487       266      1803         0
  20745       334      5398         0
  20874       334      5401         1
  10638       335      3601         0
  10256       336      1803       336
  16530       334      5402         0
  22958       321     28800         0
  13124       335      3602         2
  24562        78      1803         0
  13870       333      5398         0
  24891       336      1803       336
  21956       334      5401         0
  10824       336      1803       336
  20052       335      3603         0
  21333       335      3602         4
  19682       210      1803         1
  21349       312     44998         0
  15594       169      1803         0
  16876       336      1804       336
  22898       322     27000         0
  20468       335      3603         0
  16757       115      1803         0
  17270       335      3602         0
  21588       334      5402         2
167 probes in all, 142 probes after cleaning
```
