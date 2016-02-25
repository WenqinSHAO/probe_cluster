import atlasTools as at
from globalConfig import *
import os
import ipaddress

def main():
    traceDict = at.readTraceJSON(MES_TRACE_FILE)

    ipDict = {}
    countPrivate = 0
    countUnkown = 0
    countUniqueASN = 0
    as_set = set([])
    cmdCym = "whois -h whois.cymru.com "
    for pb in traceDict:
        for p in traceDict[pb]['ip_path']:
            for hop in p:
                if hop != '*' and hop not in ipDict:
                    ipDict[hop]={}
                    ipadd = ipaddress.ip_address(hop)
                    if ipadd.is_private:
                        ipDict[hop]['asn'] = -1
                        ipDict[hop]['as_name'] = 'private'
                        countPrivate += 1
                    else:
                        quest = cmdCym + "''" + hop +"''"

                        res = os.popen(quest)
                        for line in res:
                            cols = line.split('|')
                            if len(cols) >= 3:
                                if cols[0].strip().isdigit():
                                    ipDict[hop]['asn'] = int(cols[0].strip())
                                    ipDict[hop]['as_name'] = cols[2].strip()
                                    if ipDict[hop]['asn'] not in as_set:
                                        as_set.add(ipDict[hop]['asn'])
                                        countUniqueASN += 1
                    if not ipDict[hop]:
                        ipDict[hop]['asn'] = -2
                        ipDict[hop]['as_name'] = 'unknown'
                        countUnkown += 1

    f = open(DIC_IP_2_ASN, 'w')
    for hop in ipDict:
        line = '%s;%d;%s\n' % (hop, ipDict[hop]['asn'], ipDict[hop]['as_name'])
        f.write(line)
    f.close()

    print("%d entries in all.\n\
           %d of them are private address.\n\
           %d don't have resolution results.\n\
           %d unique ASN appeared." \
           % (len(ipDict), countPrivate, countUnkown, countUniqueASN))

if __name__ == "__main__":
    main()
