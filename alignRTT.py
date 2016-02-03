#alignment
import atlasTools as at
from scipy.cluster.vq import kmeans
import numpy as np
import sys

PING_F = 'ping_broot.json'
VALID_ID = 'valid.txt'
MODE = ['avg', 'min', 'max']

def read_pdid(file):
    pb_list = []
    f = open(file, 'r')
    for line in f:
        if line.strip().isdigit():
            pb_list.append(int(line))
    return pb_list


def interv(list):
    return np.array(list[1:]) - np.array(list[:-1])


def main(argv):
    mode = 'avg'
    if len(argv) != 1:
        print "Usage: python alignRTT.py mode\n\
               all possible modes are %s." % MODE
        exit()

    mode = argv[0]
    if mode not in MODE:
        print "mode %s not recognized, set to default mode 'avg', \
               all possible modes are %s" % (mode, MODE)
        mode = 'avg'

    valid_id = read_pdid(VALID_ID)
    alltrace = at.readPingJSON(PING_F)
    pbAct = alltrace.keys()
    pbVal =  list(set(valid_id) & set(pbAct))
    clean_trace = {k: alltrace[k] for k in pbVal}
    print len(clean_trace)


    #Quantify measurment dis-sync in time with k-means
    len_sort = sorted(clean_trace.items(), key=lambda s:len(s[1]['time_epc']), reverse=True)
    #find the probe with maximum data length
    max_len_pb = len_sort[0][0]
    max_length = len(len_sort[0][1]['time_epc'])
    all_time_epc = []
    for pb in clean_trace:
        for t in clean_trace[pb]['time_epc']:
            all_time_epc.append(t)
    all_time_epc = np.array(all_time_epc).astype(float).reshape(len(all_time_epc),1)
    # use the timestamps of the probe with max data length as the beginning centroids
    book = np.array(clean_trace[max_len_pb]['time_epc']).astype(float).reshape(max_length,1)
    alTP, dist = kmeans(all_time_epc, book)
    alTP = sorted(alTP)
    tpIntv = interv(alTP)
    print "In average measurements are dis-synchronized by %.3fsec." % dist
    print "Aligned timestamps have:\n\
           - mean interval of %.3fsec;\n\
           - interval std of %.3fsec." % (np.mean(tpIntv), np.std(tpIntv))
    print "RTT measurements of each probe will be aligned to the cloest 'aligned' timestamp."

    filename = 'pingAL_'+mode+'.csv'
    f = open(filename, 'w')
    line = 'id,' + ','.join(['%d'%t for t in alTP]) + '\n'
    f.write(line)

    for pb in clean_trace:
        align = np.zeros(max_length) # max_length equals the length of alTP
        for i in range(len(clean_trace[pb]['time_epc'])):
            distance = []
            for c in alTP:
                distance.append(np.linalg.norm(c - clean_trace[pb]['time_epc'][i]))
            lb = np.argmin(distance)
            # assign RTT measuremrnt to the cloest aligend timestamp
            align[lb] = clean_trace[pb][mode][i]
        # in case 0 or -1 align list,
        # assigne the cloest (in time both direction) valide value
        for i in range(max_length):
            if align[i] == 0 or align[i] == -1:
                left_candi = -1
                right_candi = -1
                for j in range(1,5,1): # neighbour search range
                    if left_candi == -1:
                        if (i-j >= 0) and (align[i-j] != 0 and align[i-j] != -1):
                            left_candi = i-j
                    if right_candi == -1:
                        if (i+j < max_length) and (align[i+j] != 0 and align[i+j] != -1):
                            right_candi = i+j
                    if left_candi + right_candi > -2: #at least one candidate
                        break
                if left_candi == -1:
                    align[i] = align[right_candi]
                elif right_candi == -1:
                    align[i] = align[left_candi]
                elif (alTP[i] - alTP[left_candi]) <= (alTP[right_candi] - alTP[i]):
                    align[i] = align[left_candi]
                else:
                    align[i] = align[right_candi]

        clean_trace[pb]['align'] = align

        line = "%s," % pb + ",".join(map(str, clean_trace[pb]['align'])) + '\n'
        f.write(line)

    f.close()

if __name__ == "__main__":
    main(sys.argv[1:])
