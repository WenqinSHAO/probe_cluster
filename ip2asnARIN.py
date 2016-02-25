import atlasTools as at
from globalConfig import *
import os
import ipaddress
import pathTools as pt
import sys
#reload(sys)
#sys.setdefaultencoding('utf8')


def main():
    traceDict = at.readTraceJSON(MES_TRACE_FILE)

    ipDict = {}
    countPrivate = 0
    countUnkown = 0
    countUniqueASN = 0
    as_set = set([])
    #cmdARIN = "whois "
    #grep = " | grep 'netname\|descr\|origin'"
    for pb in traceDict:
        for p in traceDict[pb]['ip_path']:
            for hop in p:
                if hop != '*' and hop not in ipDict:
                    ipDict[hop]={}
                    ipadd = ipaddress.ip_address(hop)
                    if ipadd.is_private:
                        ipDict[hop]['asn'] = -1
                        ipDict[hop]['as_name'] = 'private'
                        ipDict[hop]['descr'] = 'private'
                        countPrivate += 1
                    else:
                        ipDict[hop] = pt.ip2asARIN(hop)
                        if 'asn' not in ipDict[hop]:
                            ipDict[hop]['asn'] = -2
                            countUnkown += 1
                        elif ipDict[hop]['asn'] not in as_set:
                            as_set.add(ipDict[hop]['asn'])
                            countUniqueASN += 1
                        if 'as_name' not in ipDict[hop]:
                            ipDict[hop]['as_name'] = 'unknown'
                        if 'descr' not in ipDict[hop]:
                            ipDict[hop]['descr'] = 'unknown'
                    if not ipDict[hop]:
                        ipDict[hop]['asn'] = -2
                        ipDict[hop]['as_name'] = 'unknown'
                        ipDict[hop]['descr'] = 'unknown'
                        countUnkown += 1

    f = open(DIC_IP_2_ASN_ARIN, 'w')
    for hop in ipDict:
        line = '%s;%d;%s;%s\n' % (hop, ipDict[hop]['asn'], ipDict[hop]['as_name'], ipDict[hop]['descr'])
        f.write(line)
    f.close()

    print("%d entries in all.\n\
           %d of them are private address.\n\
           %d don't have resolution results.\n\
           %d unique ASN appeared." \
           % (len(ipDict), countPrivate, countUnkown, countUniqueASN))

if __name__ == "__main__":
    main()
