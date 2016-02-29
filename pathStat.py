import atlasTools as at
import pathTools as pt
from globalConfig import *
import editdistance as ed
import json


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

alltrace = at.readTraceJSON(MES_TRACE_FILE)
valid_id = read_pdid(PROBE_ID_VALID_FILE)
pbAct = alltrace.keys()
pbVal =  list(set(valid_id) & set(pbAct))
clean_trace = {k: alltrace[k] for k in pbVal}

ipDictCY = pt.loadIPDict(DIC_IP_2_ASN)
ipDictMG = pt.loadIPDict(DIC_IP_2_ASN_MERG)
pbASN = read_pbMeta(PROBE_META_FILE)

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


for pb in clean_trace:
    dictTraceTime[pb]={'time_md':clean_trace[pb]['time_md'],
                       'time_epc':clean_trace[pb]['time_epc']}
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
        pathAP = pt.pathAP(pathMG)
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

print "%d paths doesn't beign with the ASN hosting the probe." % localASNMiss
print "%d them have local ASN somewhere in the middle." % localFL
print "%d probes involved." % len(localMissAS)
print localMissAS


print "Total path count %d" % pathCountTotal
print "Agreement %d" % pathEq
print "Disagree %d" % pathNq

print "Cy loop count %d" % countLoopCY
print "Mg loop count %d" % countLoopMG


for asn in diffAS:
    print asn
    print pt.asnLookup(asn)

for pb in looppath:
    print pb
    for p in looppath[pb]['cymru']:
        print "IP:\t%s" % p
        print "CY:\t%s" % pt.ip2asPath(p, ipDictCY)
        print "MG:\t%s" % pt.ip2asPath(p, ipDictMG)
