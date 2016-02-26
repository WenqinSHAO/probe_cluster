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

alltrace = at.readTraceJSON(MES_TRACE_FILE)
valid_id = read_pdid(PROBE_ID_VALID_FILE)
pbAct = alltrace.keys()
pbVal =  list(set(valid_id) & set(pbAct))
clean_trace = {k: alltrace[k] for k in pbVal}

ipDictCY = pt.loadIPDict(DIC_IP_2_ASN)
ipDictMG = pt.loadIPDict(DIC_IP_2_ASN_MERG)

countLoopCY = 0
countLoopMG = 0
pathCountTotal = 0
pathEq = 0
pathNq = 0
looppath = {}
pathNqdist = []
diffAS = set()
dictIPpathStat = {}
dictASpathCyStat = {}
#dictASpathRNStat = {}
dictASpathMgStat = {}
dictTraceTime = {}

for pb in clean_trace:
    dictTraceTime[pb]={'time_md':clean_trace[pb]['time_md'],
                       'time_epc':clean_trace[pb]['time_epc']}
    dictIPpathStat[pb] = pt.ipPathStatDict()
    dictASpathCyStat[pb] = pt.asPathStatDict()
    dictASpathMgStat[pb] = pt.asPathStatDict()
    clean_trace[pb]['as_path_cy'] = []
    clean_trace[pb]['as_path_mg'] = []
    #clean_trace[pb]['as_path_cy_rn'] = []
    #clean_trace[pb]['as_path_mg_rn'] = []
    for path in clean_trace[pb]['ip_path']:
        pathCY = pt.ip2asPath(path, ipDictCY)
        pathMG = pt.ip2asPath(path, ipDictMG)
        clean_trace[pb]['as_path_cy'].append(pathCY)
        #clean_trace[pb]['as_path_cy_rn'].append([saut for saut in pathCY if saut > 0])
        clean_trace[pb]['as_path_mg'].append(pathMG)
        #clean_trace[pb]['as_path_mg_rn'].append([saut for saut in pathMG if saut > 0])
        dictIPpathStat[pb] = pt.updateIPPathStat(dictIPpathStat[pb], path)
        dictASpathCyStat[pb] = pt.updateASpathStat(dictASpathCyStat[pb], pathCY)
        dictASpathMgStat[pb] = pt.updateASpathStat(dictASpathCyStat[pb], pathMG)
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


with open(STAT_IP_PATH,'w') as f:
    json.dump(dictIPpathStat, f)

with open(STAT_AS_PATH_CY,'w') as f:
    json.dump(dictASpathCyStat, f)

with open(STAT_AS_PATH_MG,'w') as f:
    json.dump(dictASpathMgStat, f)

with open(TRACE_TIME_STAMP, 'w') as f:
    json.dump(dictTraceTime, f)

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
