#clean ping/traceroute traces, output probes to be removed.
import atlasTools as at
import os
import sys
import numpy as np
import time
import calendar
from itertools import groupby
from globalConfig import *

# script variables
TRACE = ['t', 'T', 'trace', 'traceroute', 'path']

#cleaning criteria
INTV_MX = 2 # the maximum tolerable consecutive connection losses, times by interval.
LEN_P = 0.9 # the minimum length portion compared to ideal case.
INV_PING = 0.1 # the invalid value measurement shall not surpass 0.1 of ideal length.
INV_PATH = 0.2 # an IP-path is considered invalid if it has * hops that surpass 0.2 of path's total length.
INV_TRACE = 0.3 # if more than 0.3 of all IP-path snapshots are invalid, the entire trace is regarded as un-exploitable.

def removekey(d, keys):
    r = dict(d)
    for k in keys:
        del r[k]
    return r

#check the connection stability to Atlas platform
def plft_stab(timestamps, max_intv, min_length):
    if len(timestamps) < min_length:
        return False
    intv = interv(timestamps)
    if np.max(intv) > max_intv:
        return False
    return True

def interv(list):
    return np.array(list[1:]) - np.array(list[:-1])

#longest platform of certain element in a list
def pltf(list_, element_):
    return max(sum(1 for i in g if k == element_) for k,g in groupby(list_))

#check path validity
def path_val(path, rate):
    if path[-1] == '*':
        return False
    if path.count('*') > rate * len(path):
        return False
    if pltf(path, '*') >= 5:
        return False
    return True


def main(argv):
    traceflag =False
    if len(argv) != 2:
        print "Usage: python cleaning.py t/p(trace/ping) filename"
        exit()

    trace = argv[0]
    if trace in TRACE:
        traceflag = True

    filename = argv[1]
    if not os.path.isfile(filename):
        print "Measurement file %s doesn't exist." % filename
        exit()

    pb_to_rm = set([])

    if traceflag:
        print "Traceroute trace.\n" + \
              "An ip-path\n" + \
              "- ends with *;\n" + \
              "- or contains more than %f *;\n" % INV_PATH + \
              "- or contains five or more consecutive *" + \
              "is considered invalid."
        trace_dict = at.readTraceJSON(filename)
        min_len = LEN_P * TRACE_LEN
        max_intv = INTV_MX * TRACE_INTV
        inv_len = INV_TRACE * TRACE_LEN
        #fsave = 'trace_rm.txt'
        fsave = PROBE_ID_TRACE_RM_FILE
        fval = PROBE_ID_TRACE_VAL_FILE
        for pbid in trace_dict:
            path_val_flag = []
            for p in trace_dict[pbid]['ip_path']:
                if path_val(p, INV_PATH):
                    path_val_flag.append(1)
                else:
                    path_val_flag.append(-1)
            trace_dict[pbid]['path_val'] = path_val_flag
        val_check = 'path_val'
    else:
        print "Ping trace\n" + \
              "An RTT measurement\n" + \
              "- equals -1; \n" + \
              "- missing value;\n" + \
              "- contains err field; \n" + \
              "is considered invalid."

        trace_dict = at.readPingJSON(filename)
        min_len = LEN_P * PING_LEN
        max_intv = INTV_MX * PING_INTV
        inv_len = INV_PING * PING_LEN
        val_check = 'avg'
        #fsave = 'ping_rm.txt'
        fsave = PROBE_ID_PING_RM_FILE
        fval = PROBE_ID_PING_VAL_FILE

    print "\nCleaning criteria:\n\
           Minimum length: %f,\n\
           Maximum neighbour interval: %f,\n\
           Maximum invalid values: %f." % (min_len, max_intv, inv_len)

    for pbid in trace_dict:
        if not plft_stab(trace_dict[pbid]['time_epc'], max_intv, min_len):
            pb_to_rm.add(pbid)
        if trace_dict[pbid][val_check].count(-1) > inv_len:
            pb_to_rm.add(pbid)

    if pb_to_rm:
        print "Probes to be removed:"
        print "{id:<7}{len_:>10}{intv:>10}{invd:>10}".format(id='ID', len_='Len.',
                                                             intv='Max. Intv', invd='# Invd.')
        for pb in pb_to_rm:
            print "{id:>7d}{len_:>10d}{intv:>10d}{invd:>10d}".format(id=pb,
                                                                     len_=len(trace_dict[pb]['time_epc']),
                                                                     intv=max(interv(trace_dict[pb]['time_epc'])),
                                                                     invd=trace_dict[pb][val_check].count(-1))
        clean_trace = removekey(trace_dict, list(pb_to_rm))
    else:
        clean_trace = trace_dict.copy()

    print "%d probes in all, %d probes after cleaning" % (len(trace_dict), len(clean_trace))

    f = open(fsave, 'w')
    for pb in list(pb_to_rm):
        f.write("%d\n" % pb)
    f.close()

    f = open(fval, 'w')
    for pb in clean_trace:
        f.write("%d\n" % pb)
    f.close()

if __name__ == "__main__":
    main(sys.argv[1:])
