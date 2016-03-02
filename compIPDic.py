import atlasTools as at
import pathTools as pt
from globalConfig import *
import os

cymruDict = pt.loadIPDict(DIC_IP_2_ASN)
arinDict = pt.loadIPDict(DIC_IP_2_ASN_ARIN)

EqcYaY = 0
NqcYaY = 0
cYaN = 0
cNaY = 0
cNaN = 0

diffIP = []

for ip in cymruDict:
    asnCY = cymruDict[ip]['asn']
    asnAR = arinDict[ip]['asn']
    if asnCY >0 and asnAR > 0:
        if asnCY == asnAR:
            EqcYaY += 1
        else:
            NqcYaY += 1
            diffIP.append(ip)
    elif asnCY == -2 and asnAR == -2:
        cNaN += 1
    elif asnCY == -2:
        cNaY += 1
        cymruDict[ip]['asn'] = asnAR
        cymruDict[ip]['as_name'] = arinDict[ip]['as_name']
    elif asnAR == -2:
        cYaN += 1

print "Both hit %d" % (EqcYaY + NqcYaY)
print "\t same %d" % EqcYaY
print "\t diff %d" % NqcYaY
print "Both miss %d" % cNaN
print "Cymru single hit %d" % cYaN
print "ARIN single hit %d" % cNaY


for ip in diffIP:
    print ip
    print "\tCymru :"
    print '\t%d\t%s\n' % (cymruDict[ip]['asn'], cymruDict[ip]['as_name'])
    print "\tARIN :"
    print '\t%d\t%s\n' % (arinDict[ip]['asn'], arinDict[ip]['as_name'])

f = open(DIC_IP_2_ASN_MERG, 'w')
for hop in cymruDict:
    line = '%s;%d;%s\n' % (hop, cymruDict[hop]['asn'], cymruDict[hop]['as_name'])
    f.write(line)
f.close()
