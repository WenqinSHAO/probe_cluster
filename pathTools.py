from globalConfig import *
import os
import re
import sys
#reload(sys)
#sys.setdefaultencoding('utf8')
from collections import Counter
import ipaddress
import editdistance as ed

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

def asnLookup(asn):
    answer = ''
    cmdCym = "whois -h whois.cymru.com "
    quest = cmdCym + "''" + 'AS' + str(asn) + "''"
    res = os.popen(quest)
    for line in res:
        if "AS Name" not in line:
            answer += line
    return answer

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
# the unknown ASN should be the same as well
def fillHole(path):
    maxHoleSize = 5
    # the begining and the end shall not count
    for i in range(1, (len(path)-1)):
        # a hole must have a left edge
        if path[i] < 0 and path[i-1] > 0:
            # find the right edge of the hole within maxsize limit
            for j in range(1,maxHoleSize):
                if path[i+j] > 0:
                    break
            # if the two sides are the same, then fill the hole
            if path[i-1] == path[i+j]:
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
    as_path = asPathFormatter(as_path)
    as_path = fillHole(as_path)
    as_path = asPathFormatter(as_path)

    return as_path

def ip2asPathRAW(path, ipDict):
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
    return as_path

def loopCheck(path):
    loopAS = [k for (k,v) in Counter(path).iteritems() if v > 1]
    loopAS = [k for k in loopAS if k != -2 and k!= -3]
    return loopAS

def locPrivaIP(path):
    return {saut: float(path.index(saut))/len(path) for saut in path if saut!='*' and ipaddress.ip_address(saut).is_private}

def locStarIP(path):
    return {saut: float(path.index(saut))/len(path) for saut in path if saut == '*'}

def locPrivaAS(path):
    return {saut: float(path.index(saut))/len(path) for saut in path if saut == -1}

def locUnkAS(path):
    return {saut: float(path.index(saut))/len(path) for saut in path if saut == -2}

def locStarAS(path):
    return {saut: float(path.index(saut))/len(path) for saut in path if saut == -3}

def locdiffPos(path1, path2):
    for i in range(min(len(path1), len(path2))):
        if path1[i] != path2[i]:
            break
    return float(i)/len(path2)

def asPathStatDict():
    return {'length':[],
            'countPriva':[],
            'posPriva':[],
            'countUnkown':[],
            'posUnknown':[],
            'countStar':[],
            'posStar':[],
            'disChange':[],
            'posChange':[]}
def ipPathStatDict():
    return {'length':[],
            'countPriva':[],
            'posPriva':[],
            'countStar':[],
            'posStar':[],
            'disChange':[],
            'posChange':[]}

def updateIPPathStat(statDict, path):
    statDict['length'].append(len(path))
    priva = locPrivaIP(path)
    statDict['countPriva'].append(len(priva))
    if priva:
        statDict['posPriva'].append(priva.values())
    else:
        statDict['posPriva'].append([-1])
    stars = locStarIP(path)
    statDict['countStar'].append(len(stars))
    if stars:
        statDict['posStar'].append(stars.values())
    else:
        statDict['posStar'].append([-1])
    return statDict

def updateASpathStat(statDict, path):
    statDict['length'].append(len(path))
    priva = locPrivaAS(path)
    statDict['countPriva'].append(len(priva))
    if priva:
        statDict['posPriva'].append(priva.values())
    else:
        statDict['posPriva'].append([-1])
    stars = locStarAS(path)
    statDict['countStar'].append(len(stars))
    if stars:
        statDict['posStar'].append(stars.values())
    else:
        statDict['posStar'].append([-1])
    unk = locUnkAS(path)
    statDict['countUnkown'].append(len(unk))
    if unk:
        statDict['posUnknown'].append(unk.values())
    else:
        statDict['posUnknown'].append([-1])
    return statDict

def pathChange(paths):
    pp = zip(paths[1:], paths)
    # each pair in pp, (path after, path before)
    dist = [0,]
    pos = [-1,]
    for p in pp:
        ch = ed.eval(p[0], p[1])
        dist.append(ch)
        if ch:
            pos.append(locdiffPos(p[0],p[1]))
        else:
            pos.append(-1)
    return (dist, pos)
