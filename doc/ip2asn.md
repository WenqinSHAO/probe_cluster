# IP to ASN mapping
## Address mapping
We tried two sources of IP2ASN mapping, [Cymru](http://whois.cymru.com) and [ARIN](http://whois.arin.net/), to map the IP hops seen in traceroute measurements to a ASN.
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
Among appeared ASes in two bases, 214 of them are in common, in all there are 236 unique ASN.

## Compare two data sources
```
Both hit 802
     same 794
     diff 8
Both miss 30
Cymru single hit 292
ARIN single hit 20
```
Among all the public addresses (1144-57=1087), 802 of them have mapping records in both bases.
The ASN resolution results are the same for 794 of these 'double-hit' IPs.
For 8 IP addresses that resolution results differ, I manually checked them in [hurricane](http://bgp.he.net/ip).
The results from [hurricane](http://bgp.he.net/ip) and Cymru agree with each other.
292 IPs only have mapping in Cymru, while 20 other IP otherwise.
We thus have the feeling that Cymru base is more complete in coverage and more 'accurate' as well.
Nonetheless, we merged the two ip2asn dictionary (*dic_ip2asn.csv* from Cymru, *dic_ip2asn_arin.txt* from ARIN, *dic_ip2asn_merg.txt* the merged one), by adding IP2ASN mapping unknown to Cymru base.
The intention behind the merge is to see, how it is going to impact the path mapping.


# Difference using Cymru dictionary and the merged dictionary
```
Total path count 43008
Agreement 26912
Disagree 16096
Cy loop count 1
Mg loop count 1
```
43008 IP-path measurements are mapped. 26912 among them lead to same AS-path using both dictionary.
16096 of them have different mapping results. With both dictionary, one loop from a very same IP-path is resulted.

### Where the two base differ
15760 among 16096 paths that have different mapping result using the two dictionary, have an edit distance of 1.
That is due to a -2 ASN in the Cymru path replaced by a valid ASN in Merged-dic path.
By looking into the ASN names and description fields of these ASes, we found all of them are IXP.
```
8674
NETNOD-IX Netnod Internet Exchange Sverige AB,SE

16004
MIXITA-AS MIX S.r.L. - Milan Internet eXchange,IT

9033
ECIX-AS Peering GmbH,DE

6695
DECIX-AS DE-CIX Management GmbH,DE

5459
LINX-AS London Internet Exchange Ltd.,GB

16374
BCIX BCIX e.V,DE

44729
EQUINIX-PARIS-IX Equinix France SAS,FR

24796
NAMEX-IXP NAMEX CONSORZIO,IT
```
336 IP-paths lead to an edit distance of 2 after mapping.
The different come from paths look like this:
```
IP path: 185.51.176.254, 10.0.4.1, 81.255.42.190', 81.55.52.173, 81.52.63.246, 193.253.15.237, 193.253.91.222, 193.252.160.82, 193.252.137.82, 193.251.133.9, *, 129.250.5.217, 129.250.3.179, 129.250.6.162, 129.250.3.84, 129.250.3.189, 129.250.4.107, 165.254.21.242, 130.152.184.3, *, 192.228.79.201

Cymru path: 61984, -1, 3215, -2, -3, 2914, 226

Merged-dic path: 61984, -1, 3215, 25186, -2, 5511, -3, 2914, 226
```
Thus, the difference lies in 25186 and 551, and noting that 3215 is a as well an AS belong to Orange.
```
25186
TRANSIT-VPN-AS Orange S.A.,FR

5511
OPENTRANSIT Orange S.A.,FR
```
According to the IPv4 graph of hurricane, 61984 is a client of 3215, and 5511 have peering relationship with 2915. Therefore a more realistic interpretation of the AS-path could be:
```
61984, 3215, 25186, *3215*, 5511, 2914, 226
```

### Loop
The loop comes from following IP path of probe 20715:
```
[u'31.24.168.1', u'77.67.76.89', u'89.149.128.246', u'77.67.82.10', u'129.250.4.53', u'129.250.2.4', u'129.250.2.149', u'129.250.3.189', u'129.250.4.107', u'165.254.21.242', u'130.152.184.3', '*', u'129.250.7.69', u'129.250.2.207', u'129.250.4.107', u'165.254.21.242', u'130.152.184.3', '*', u'192.228.79.201']
```
The Cymru and Merged-dic mapping for this path is:
```
RAW: [197729, 3257, 3257, 3257, 2914, 2914, 2914, 2914, 2914, 2914, 226, -3, 2914, 2914, 2914, 2914, 226, -3, 226]
Processed: [197729, 3257, 2914, 226, -3, 2914, 226]
```
Considering that
1. the path before and after containing no loop;
2. Atlas uses Paris-traceroute,
We assume this loop in AS-path is due the transient affect of AS-level path change.

## Path mapping
### Procedure
1. given a IP path and a dictionary, translate each hop of IP to an ASN, -1 for private address, -2 for unknown, -3 for \*;
2. for path begin with -1 ASN, remove these -1 till the first valid ASN;
3. compress multiple consecutive same ASN in to one;
4. for a hole, i.e. negative ASN in middle and valid ASN both side, if the two ends have same ASN, fill the hole with the same ASN as the ones on the edge;
5. compress again multiple consecutive same ASN in to one;
6. check if the AS path begins with the ASN hosting the probe (refer to as local ASN) ; 2774 paths does not begin with local ASN; 1148 among them have the local ASN somewhere after; 17 probes are involved. Most of the corresponding IP-path begins with private IP address (ASN thus removed by step 2), and a few with \* (ASN remained in the form -3). Two probes, 17831 and 12460, begin with IP addresses right to the next.
    1. if is the case, append local ASN at the beginning;
    2. fill the hole;
    3. compress consecutive same ASN.
7. remove -1,-2,-3 if edges are not in no-mercy list.

### IP path Length
Most probes (35) have an avg IP path length in (13,14], the main stream is from (11,16], having 96 probes. This observation is sort of biased by the important presence of probes from Germany.

### AS MG path length

### Private IP in IP path
```
Avg. Private IP per probe path    0  1  2  3  4
Number of probes                 71 46  8  2  1
```
Most probe has no private IP address in all of their IP paths.
Some of them have constantly one private IP address.
Very few have more than 3.

Most private IPs locate at the head, especailly the first hop, and the end of the the IP path.
Very likely they belong to local AS hosting the probe and the destination AS of the b-root.

Most of these private IP shall disappear after previous described mapping stepping.
1. At the beginning, first removed than, replaced by local ASN of probe
2. Near the end, absorbed by the ASN of the destination.

### Private IP mapping in AS MG
4 probes have -1 ASN in the middle of the path.
For 3 (18567, 19363 and 22992) of them, the private mapping is at the second hop, while one (19514) at 3rd AS hop.
We then manually checked the ASN at the two sides of the private mapping.
For 19363, 22992 and 19514, the ASN to the right side of the AS path is known to be the provider of the ASN to the left side. Thus it is safe to remove this -1, as no additional ASN shall be in between, even if there is, say an IXP, we are not able to tell.
For 18567, the ASN path is [12993, -1, 1200, 6939, 226]. According to hurricane, 1200 dosen't appear to be one of the provider of 12993, but it is an IXP. We henceforth assume that 12993 and 6939 peer at 1200. (How to verify?)
We assume it is safe as well to remove this -1.

### Stars * in IP path
Most probe IP paths have 1 \* constantly.  The rest have very few stars.
Stars tend to appear at the end part of the IP path, which possible locates in the destination AS.

Most of these stars shall possibly be absorbed after mapping.

### Stars * AS MG path
Only 9 probes have constantly 1 \* mapping in the AS-path MG.
We investigated the relationship between each pair of ASes on the two sides of the \*,
and found out most of them have known peering relationship, except one.
We thus assume it is safe to remove -3 in AS MG path.

(8251, 6939) client-provider
(34948, 8426) client-provider
(39923, 6939) client-provider
(60491, 29075) client-provider
(5610, 6939 client-provider
(8866, 6939) client-provider
(29551, 6939 client-provider
(13237, 6939 client-provider
(174, 2914) client-provider
(3257, 2914) client-provider
(8641, 6939) client-provider
(6453, 2914) client-provider
(5459, 6939) client-provider
(6739, 2914) client-provider
(3320, 2914) client-provider
(226, 2914) client-provider
(5511, 2914) client-provider

(44729, 226) relation not found, 44729 Equinix IXP
(44729, 6939) relation not found, 44729 Equinix IXP
(16374, 6939) 16374's relation not found, being a IXP, very possible connected to hurricane
(28716, 16004) direct relation not found, 16004 is IXP

(6939, 226) provider-client

(9186, 5626) peering relation confirmed

(61303, 201011) 33891 is the provider of 61303, 201011 and 33891 all belong to Netzbetrieb GmbH, seem to be siblings.

for the following \* shall not be removed, how many path do they impact?
(2200, 30781) relation not found
(34524, 8866) relation not found
(12644, 226) relation not found
(174, 226) relation not found

### unknown IP to ASN mapping
24 probes constantly have one unknown mapping remained in the AS MG path.
(12570, 6939) client-provider
(8251, 6939) client-provider
(47377, 5511) client-provider
(16086, 6939 client-provider
(34549, 6939) client-provider
(50989, 6939 client-provider
(29422, 6939) client-provider
(3327, 6939) client-provider
(42000, 6939) client-provider
(5610, 6939) client-provider
(43451, 6939) client-provider
(9050, 6939) client-provider
(8866, 6939) client-provider
(29405, 6939) client-provider

(15368, 1835) relationship not found
(25186, 5511) there is 3125 in between

(8220, 16374) 16374 IXP
