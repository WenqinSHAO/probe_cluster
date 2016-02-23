#fetch the measurement results of ids stored in a txt file
import atlasTools as at
import os
import sys
import time
import calendar
import math
from globalConfig import *

def main():
    pbs=[]
    f = open(PROBE_ID_ALL_FILE, 'r')
    for line in f:
        line = line.strip()
        if line.isdigit():
            pbs.append(line)
    f.close()

    pb_string = (',').join(pbs)

    #1010 ping to b root
    url = "https://atlas.ripe.net/api/v2/measurements/1010/results?start=%d&stop=%d&probe_ids=%s&format=json" \
          % (START, END, pb_string)
    res = at.query(url)
    f = open(MES_PING_FILE, 'w')
    f.write(res.text)
    f.close()

    #5010 ping to b root
    url = "https://atlas.ripe.net/api/v2/measurements/5010/results?start=%d&stop=%d&probe_ids=%s&format=json" \
          % (START, END, pb_string)
    res = at.query(url)
    f = open(MES_TRACE_FILE, 'w')
    f.write(res.text)
    f.close()

if __name__ == "__main__":
    main()
