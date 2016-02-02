#fetch the measurement results of ids stored in a txt file
import atlasTools as at
import os
import sys
import time
import calendar
import math

START = calendar.timegm(time.strptime('2016-01-18 00:00:00', '%Y-%m-%d %H:%M:%S'))
END =  calendar.timegm(time.strptime('2016-01-25 00:00:00', '%Y-%m-%d %H:%M:%S'))
FILE = "pbid.txt"
PING_F = 'ping_broot.json'
TRACE_F = 'trace_broot.json'

def main():
    pbs=[]
    f = open(FILE, 'r')
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
    f = open(PING_F, 'w')
    f.write(res.text)
    f.close()

    #5010 ping to b root
    url = "https://atlas.ripe.net/api/v2/measurements/5010/results?start=%d&stop=%d&probe_ids=%s&format=json" \
          % (START, END, pb_string)
    res = at.query(url)
    f = open(TRACE_F, 'w')
    f.write(res.text)
    f.close()

if __name__ == "__main__":
    main()
