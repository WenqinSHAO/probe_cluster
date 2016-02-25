from globalConfig import *
import os
import re
import sys
#reload(sys)
#sys.setdefaultencoding('utf8')
from collections import Counter

def ip2asARIN(ip):
    asinfo = {}
    cmdARIN = "whois "
    grep = " | grep 'netname\|descr\|origin'"
    quest = cmdARIN + ip + grep
    res = os.popen(quest)
    for line in res:
        cols = line.split(':')
        if len(cols) >= 2:
            if 'netname' in cols[0]:
                asinfo['as_name'] = cols[1].strip()
            elif 'descr' in cols[0]:
                if 'descr' not in asinfo:
                    asinfo['descr'] = cols[1].strip() + ' '
                else:
                    asinfo['descr'] += cols[1].strip() + ' '
            elif 'origin' in cols[0]:
                asinfo['asn'] = int(re.findall('\d+', cols[1].strip())[0])
    if asinfo:
        #replace non ascii character with one space
        asinfo['as_name'] = re.sub(r'[^\x00-\x7F]+', ' ', asinfo['as_name'])
        asinfo['descr'] = re.sub(r'[^\x00-\x7F]+', ' ', asinfo['descr'])
    return asinfo

def ip2asCYMRU(ip):
    asinfo = {}
    cmdCym = "whois -h whois.cymru.com "
    quest = cmdCym + "''" + ip +"''"
    res = os.popen(quest)
    for line in res:
        cols = line.split('|')
        if len(cols) >= 3:
            if cols[0].strip().isdigit():
                asinfo['asn'] = int(cols[0].strip())
                asinfo['as_name'] = cols[2].strip()
    return asinfo


def loadIPDict(file):
    ipDict = {}
    f = open(file, 'r')
    for line in f:
        cols = line.split(";")
        if len(cols) >= 3:
            ipDict[cols[0].strip()] = {'asn': int(cols[1].strip()),
                                       'as_name': cols[2].strip()}
    return ipDict

# replace consecutive same ASN with only one of their presence
def asPathFormatter(path):
    new_path = []
    last_asn = 0
    for hop in path:
        if hop != last_asn:
            new_path.append(hop)
            last_asn = hop
    return new_path

# remove private address at begining so that it is not translated as an AS hop
def rmPriva(path):
    while True:
        if path[0] == -1:
            path = path[1:]
        else:
            break
    return path
# if before and after an unknown ip-asn mapping, the ASNs are the same
# the unknown ASN should be same as well
def guessUnknown(path):
    for i in range(1, (len(path)-1)):
        if path[i] == -2 or path[i] == -3:
            if path[i-1] == path[i+1]:
                path[i] = path[i-1]
    return path

def ip2asPath(path, ipDict):
    as_path = []
    for hop in path:
        if hop != '*':
            if hop in ipDict:
                as_path.append(ipDict[hop]['asn'])
            else:
                print "Wierd missing in dict %s" % hop
                as_path.append(-2)
        else:
            as_path.append(-3)

    as_path = rmPriva(as_path)
    as_path = guessUnknown(as_path)
    as_path = asPathFormatter(as_path)

    return as_path

def loopCheck(path):
    loopAS = [k for (k,v) in Counter(path).iteritems() if v > 1]
    loopAS = [k for k in loopAS if k != -2 and k!= -3]
    return loopAS
