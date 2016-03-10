import atlasTools as at
import pathTools as pt
from globalConfig import *
import editdistance as ed
import json
from collections import Counter
import matplotlib.pyplot as plt
import numpy as np



def read_pdid(file):
    pb_list = []
    f = open(file, 'r')
    for line in f:
        if line.strip().isdigit():
            pb_list.append(int(line))
    return pb_list

def read_pbMeta(file):
    pbMeta = {}
    f = open(file, 'r')
    for line in f:
        cols = line.split(',')
        if len(cols) >= 4 and 'id' not in cols[0]:
            pbid = int(cols[0].strip())
            asn = int(cols[3].strip())
            pbMeta[pbid] = asn
    return pbMeta

def readNoMercy(file):
    noMercy = set()
    f = open(file, 'r')
    for line in f:
        cols = line.split(',')
        if len(cols) >= 2:
            a = int(cols[0].strip())
            b = int(cols[1].strip())
            noMercy.add((a,b))
            noMercy.add((b,a))
    return noMercy


alltrace = at.readTraceJSON(MES_TRACE_FILE)
valid_id = read_pdid(PROBE_ID_VALID_FILE)
pbAct = alltrace.keys()
pbVal =  list(set(valid_id) & set(pbAct))
clean_trace = {k: alltrace[k] for k in pbVal}

ipDictCY = pt.loadIPDict(DIC_IP_2_ASN)
ipDictMG = pt.loadIPDict(DIC_IP_2_ASN_MERG)
pbASN = read_pbMeta(PROBE_META_FILE)
noMercy = readNoMercy(PAIR_NO_MERCY)

countLoopCY = 0
countLoopMG = 0
pathCountTotal = 0
pathEq = 0
pathNq = 0
localASNMiss = 0
localMissAS = set()
localFL = 0
looppath = {}
pathNqdist = []
diffAS = set()
dictIPpathStat = {}
dictASpathCyStat = {}
dictASpathMgStat = {}
dictASpathAPStat = {}
dictTraceTime = {}
dictParisId = {}


for pb in clean_trace:
    dictTraceTime[pb] = {'time_md':clean_trace[pb]['time_md'],
                         'time_epc':clean_trace[pb]['time_epc']}
    dictParisId[pb] = clean_trace[pb]['paris_id']
    dictIPpathStat[pb] = pt.ipPathStatDict()
    dictASpathCyStat[pb] = pt.asPathStatDict()
    dictASpathMgStat[pb] = pt.asPathStatDict()
    dictASpathAPStat[pb] = pt.asPathStatDict()
    clean_trace[pb]['as_path_cy'] = []
    clean_trace[pb]['as_path_mg'] = []
    clean_trace[pb]['as_path_ap'] = []
    for path in clean_trace[pb]['ip_path']:
        pathCY = pt.ip2asPath(path, ipDictCY)
        pathMG = pt.ip2asPath(path, ipDictMG)
        # check if the AS MG path begin with the local ASN of the probe
        # if not, do some treatmeant
        if len(pathMG) > 1 and pathMG[0] != pbASN[pb]:
            if pbASN[pb] in pathMG:
                localFL += 1
            pathCY = [pbASN[pb]] + pathCY
            pathMG = [pbASN[pb]] + pathMG
            pathCY = pt.fillHole(pathCY)
            pathCY = pt.asPathFormatter(pathCY)
            pathMG = pt.fillHole(pathMG)
            pathMG = pt.asPathFormatter(pathMG)
            localASNMiss += 1
            localMissAS.add(pb)
        # absorbe <0 ASN with noMercy expections
        pathAP = pt.pathAP(pathMG, noMercy)
        clean_trace[pb]['as_path_cy'].append(pathCY)
        clean_trace[pb]['as_path_mg'].append(pathMG)
        clean_trace[pb]['as_path_ap'].append(pathAP)
        dictIPpathStat[pb] = pt.updateIPPathStat(dictIPpathStat[pb], path)
        dictASpathCyStat[pb] = pt.updateASpathStat(dictASpathCyStat[pb], pathCY)
        dictASpathMgStat[pb] = pt.updateASpathStat(dictASpathMgStat[pb], pathMG)
        dictASpathAPStat[pb] = pt.updateASpathStat(dictASpathAPStat[pb], pathAP)
        pathCountTotal += 1
        if pathCY == pathMG:
            pathEq += 1
        else:
            pathNq += 1
            nq_as = set(pathMG) - set(pathCY)
            diffAS.update(nq_as)
            pathNqdist.append(ed.eval(pathCY, pathMG))
        if pt.loopCheck(pathCY):
            countLoopCY += 1
            if pb not in looppath:
                looppath[pb] = {'cymru':[], 'arin':[]}
            looppath[pb]['cymru'].append(path)
        if pt.loopCheck(pathMG):
            countLoopMG += 1
            if pb not in looppath:
                looppath[pb] = {'cymru':[], 'arin':[]}
            looppath[pb]['arin'].append(path)
    dis, pos = pt.pathChange(clean_trace[pb]['ip_path'])
    dictIPpathStat[pb]['disChange'] = dis
    dictIPpathStat[pb]['posChange'] = pos
    dis, pos = pt.pathChange(clean_trace[pb]['as_path_cy'])
    dictASpathCyStat[pb]['disChange'] = dis
    dictASpathCyStat[pb]['posChange'] = pos
    dis, pos = pt.pathChange(clean_trace[pb]['as_path_mg'])
    dictASpathMgStat[pb]['disChange'] = dis
    dictASpathMgStat[pb]['posChange'] = pos
    dis, pos = pt.pathChange(clean_trace[pb]['as_path_ap'])
    dictASpathAPStat[pb]['disChange'] = dis
    dictASpathAPStat[pb]['posChange'] = pos

with open(STAT_IP_PATH,'w') as f:
    json.dump(dictIPpathStat, f)

with open(STAT_AS_PATH_CY,'w') as f:
    json.dump(dictASpathCyStat, f)

with open(STAT_AS_PATH_MG,'w') as f:
    json.dump(dictASpathMgStat, f)

with open(STAT_AS_PATH_AP, 'w') as f:
    json.dump(dictASpathAPStat, f)

with open(TRACE_TIME_STAMP, 'w') as f:
    json.dump(dictTraceTime, f)

with open(TRACE_PATH_REC, 'w') as f:
    json.dump(clean_trace, f)

with open(TRACE_PARIS_ID, 'w') as f:
    json.dump(dictParisId, f)

print "%d paths doesn't beign with the ASN hosting the probe." % localASNMiss
print "%d them have local ASN somewhere in the middle." % localFL
print "%d probes involved." % len(localMissAS)
print localMissAS


print "Total path count %d" % pathCountTotal
print "Agreement %d" % pathEq
print "Disagree %d" % pathNq

print "Cy loop count %d" % countLoopCY
print "Mg loop count %d" % countLoopMG

# check the ASN that causes the difference in AS CY and AS MG paths
for asn in diffAS:
    print asn
    print pt.asnLookup(asn)

# check the pb and its paths containing a loop
for pb in looppath:
    print pb
    for p in looppath[pb]['cymru']:
        print "IP:\t%s" % p
        print "CY:\t%s" % pt.ip2asPath(p, ipDictCY)
        print "MG:\t%s" % pt.ip2asPath(p, ipDictMG)

# find the ASN pairs at the two ends of * in AS-path MG
starpb = []
starpair = set()
for pb in dictASpathMgStat:
    if sum(dictASpathMgStat[pb]['countStar'])>0:
        startpb.append(pb)
        for path in clean_trace[pb]['as_path_mg']:
            for i in range(len(path)):
                if path[i] == -3 and i > 0 and i < (len(path) - 1):
                    edge = pt.findEdge(path, i)
                    if edge:
                        starpair.add(edge)

print startpb
print starpair

# find the ASN pairs at the two ends of unknown mapping in AS-path MG
unkpb = []
unkpair = set()
for pb in dictASpathMgStat:
    if sum(dictASpathMgStat[pb]['countUnknown'])>0:
        unkpb.append(pb)
        for path in clean_trace[pb]['as_path_mg']:
            for i in range(len(path)):
                if path[i] == -2 and i > 0 and i < (len(path) - 1):
                    edge = pt.findEdge(path, i)
                    if edge:
                        unkpair.add(edge)

print unkpb
print unkpair

# count unabsorbed -2, -3 ASN after hole cleaning
noMercyCount = 0
noMercyProbe = set()
invalEndCount = 0
for pb in clean_trace:
    for path in clean_trace[pb]['as_path_ap']:
        if -2 in path or -3 in path:
            noMercyCount += 1
            noMercyProbe.add(pb)
        if path[-1] < 0:
            invalEndCount += 1
print noMercyCount
print invalEndCount



headPriva = 0 # the number of IP paths that begin with private address
headStar = 0 # the number of IP paths that begin with *
headUnk = 0 # the number of IP paths that begin with unknown IP
headBingo = 0 # the number of IP paths that begin with the probe local ASN
headOther = 0 # cases other than above
localMid_priva = 0 # begin with private IP but local ASN somewhere in middle
localMid_star = 0 # begin with * but local ASN somewhere in middle
localMid = 0 # begin with unknown IP but local ASN somewhere in middle
headOtherSet = set() # IP path that begin with ip in other ASN than the probe one, ASN pair probe ASN, first ASN
susset = set() # for probe begin with private IP, but don't have probe ASN in the middle, ASN pair probe ASN, first ASN

for pb in clean_trace:
    for path in clean_trace[pb]['ip_path']:
        raw = pt.ip2asPathRAW(path, ipDictMG)
        if raw[0] == -1:
            headPriva += 1
            if pbASN[pb] in raw:
                localMid_priva += 1
            else:
                clean = pt.ip2asPath(path, ipDictMG)
                clean = [hop for hop in clean if hop > 0]
                if clean:
                    susset.add((pbASN[pb], clean[0]))
        elif raw[0] == -2:
            headUnk += 1
            if pbASN[pb] in raw:
                localMid += 1
        elif raw[0] == -3:
            headStar += 1
            if pbASN[pb] in raw:
                localMid_star += 1
        elif raw[0] == pbASN[pb]:
            headBingo += 1
        else:
            headOther += 1
            headOtherSet.add((pbASN[pb], raw[0]))

# count the number of each ending ASN
endASdict = {}
for pb in clean_trace:
    for path in clean_trace[pb]['as_path_ap']:
        tail = path[-1]
        if tail not in endASdict:
            endASdict[tail] = 0
        endASdict[tail] += 1
        if tail != 226 and tail > 0:
            idx = clean_trace[pb]['as_path_ap'].index(path)
            print clean_trace[pb]['ip_path'][idx]
            print pt.ip2asPathRAW(clean_trace[pb]['ip_path'][idx], ipDictMG)

rawPcount = 0 # the number of RAW translated AS path have at least one hole
naivePcount = 0 # the number of naive path have at least one hole
finalPcount = 0 # the number of AS AP path have at least one hole
rawHcount = 0 # the number of holes in raw translated AS path
naieveHcount = 0 # the number of holes in naive AS path
finalHcount = 0 # the number of holes in final AS AP path
allIPHop = 0 # the total number of IP hops
allNaiveHop = 0 # the total number of AS hop in Navie path
allfinalHop = 0 # the total number of AS hop in final path
for pb in clean_trace:
    for path in clean_trace[pb]['ip_path']:
        raw_path = pt.ip2asPathRAW(path, ipDictMG)
        holes = [hop for hop in raw_path if hop < 0]
        if holes:
            rawPcount += 1
            rawHcount += len(holes)
        allIPHop += len(path)
        naive = pt.fillHole(raw_path)
        naive = pt.asPathFormatter(naive)
        holes = [hop for hop in naive if hop <0]
        if holes:
            naivePcount += 1
            naieveHcount += len(holes)
        allNaiveHop += len(naive)
    for path in clean_trace[pb]['as_path_ap']:
        holes = [hop for hop in path if hop <0]
        if holes:
            finalPcount += 1
            finalHcount += len(holes)
        allfinalHop += len(path)

# check if atlas built-in traceroute measurement uses Paris traceroute
# check how many unique Paris IP each probe trace have
parisZeroCount = 0
parisIdCount = {}
dictParisId = {}
for pb in clean_trace:
    if not sum(clean_trace[pb]['paris_id']):
        parisZeroCount += 1
    parisIdCount[pb] = Counter(clean_trace[pb]['paris_id'])
    dictParisId[pb] = clean_trace[pb]['paris_id']

with open(TRACE_PARIS_ID, 'w') as f:
    json.dump(dictParisId, f)

# count and rank AS occurence


# group RTT and paris id by path
# one ID can appear in different path
path2rtt = {}
path2Paris = {}
DEST = '192.228.79.201'
for pb in clean_trace:
    path2rtt[pb] = {}
    path2Paris[pb] = {}
    ip_paths = clean_trace[pb]['ip_path']
    rtts =  clean_trace[pb]['min']
    paris = clean_trace[pb]['paris_id']
    for i in range(len(ip_paths)):
        if ip_paths[i][-1] == DEST:
            path = ','.join(ip_paths[i])
            rtt_ = rtts[i]
            id_ = paris[i]
            if path not in path2rtt[pb]:
                path2rtt[pb][path] = []
                path2Paris[pb][path] = set()
            path2rtt[pb][path].append(rtt_[-1])
            path2Paris[pb][path].add(id_)

for pb in clean_trace:
    rtt_box = []
    rtt_lab = []
    rtt_box.append([])
    rtt_lab.append('all')
    for path in path2rtt[pb]:
        rtt_box[0] += path2rtt[pb][path]
        rtt_box.append(path2rtt[pb][path])
        rtt_lab.append(','.join([str(i) for i in path2Paris[pb][path]]))
    fig, ax = plt.subplots()
    hd = ax.boxplot(rtt_box, labels=rtt_lab, whis='range')
    labs = ax.get_xticklabels()
    plt.setp(labs, rotation=90, fontsize=10)
    fig.set_size_inches(6,4)
    fig_name = ('rtt_box_%d.pdf'%pb)
    plt.savefig(fig_name, bbox_inches='tight', format='pdf')
    plt.close()











parisRTTDict = {}
parisPathDict = {}
DEST = '192.228.79.201'
for pb in clean_trace:
    parisRTTDict[pb] = {}
    parisPathDict[pb] = {}
    for i in range(len(clean_trace[pb]['ip_path'])):
        paris_id = dictParisId[pb][i]
        # initialize the Paris ID array
        if paris_id not in parisRTTDict:
            parisRTTDict[pb][paris_id] = []
            parisPathDict[pb][paris_id] = set()
        ip_path = clean_trace[pb]['ip_path'][i]
        rtt_ = clean_trace[pb]['min'][i]
        # if the measurement ends with the destination counts it
        if ip_path[-1] == DEST:
            parisRTTDict[pb][paris_id].append(rtt_)
            parisPathDict[pb][paris_id].add(','.join(ip_path))
# tuple of probe and Paris ID that have multiple paths
multipathID = []
for pb in clean_trace:
    for paris_id in parisPathDict[pb]:
        if len(parisPathDict[pb][paris_id]) > 1:
            multipathID.append((pb, paris_id))
# non of the probe-id tuple have more than one path

# merge ID's if have the same path, update observed RTT as well
mgParisRTT = {}
mgParisPath = {}
for pb in clean_trace:
    allpath = set()
    for paris_id in parisPathDict[pb]:
        allpath.update(parisPathDict[pb][paris_id])
    allpath = list(allpath)
    # path to paris id dictionary
    revDict = {}
    for path in allpath:
        revDict[path] = []
        for paris_id in parisPathDict[pb]:
            if list(parisPathDict[pb][paris_id])[0] == path:
                revDict[path].append(paris_id)
    # new dict with new key and merged RTT
    mgParisRTT[pb] = {}
    mgParisPath[pb] = {}
    for path in revDict:
        ids = revDict[path]
        mg_rtt = []
        new_ids = []
        for id_ in ids:
             mg_rtt += parisRTTDict[pb][id_]
             new_ids.append(str(id_))
        new_ids = ','join(new_ids)
        mgParisRTT[pb][new_ids] = mg_rtt
        mgParisPath[pb][new_ids] = path
