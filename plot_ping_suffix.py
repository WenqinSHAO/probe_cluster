#visualize ping measuremnt result in 3d
#given a measurement id, separatly plot probes traces in files of given file suffix
import json
import os
import sys
import time
import calendar
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import itertools
import atlasTools as at
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.ticker import MultipleLocator, FormatStrFormatter

MODE = ['avg', 'min', 'max', 'loss']
MODE_LABEL = {'avg': 'Avg. RTT (ms)',
              'min': 'Min. RTT(ms)',
              'max': 'Max. RTT(ms)',
              'loss': 'Packet loss %'}

def read_by_suffix(suf):
    files = [f for f in os.listdir(os.getcwd()) if os.path.isfile(os.path.join(os.getcwd(), f))]
    pbId_dic = {}
    suf = '.' + suf
    for f in files:
        if suf in f:
            f_head = f.split('.')[0].strip()
            pbId_dic[f_head] = []
            f_name = os.path.join(os.getcwd(), f)
            f_handle = open(f_name, 'r')
            for line in f_handle:
                pbId_dic[f_head].append(int(line.strip()))
    return pbId_dic

def main(argv):
    if len(argv) != 3:
        print "Usage: python plot_ping_suffix.py mode file_suffix json_file"
        exit()

    mode = argv[0]
    if mode not in MODE:
        print "mode %s not recognized, set to default mode 'avg', all possible modes are %s" % (mode, MODE)
        mode = 'avg'
    suffix = argv[1]
    measure_id = argv[-1]
    filename = measure_id + '.json'

    if not os.path.isfile(filename):
        print"Measurement results for #%s doesn't exist." % measure_id
        exit()

    trace_dict = at.readPingJSON(filename)

    pdId_dict = read_by_suffix(suffix)

    for f in pdId_dict:
        fig = plt.figure()
        ax = fig.add_subplot(111, projection='3d')
        y_lable = []
        yi=1
        for probe in pdId_dict[f]:
            #print trace_dict[probe][mode]
            #time.sleep(10)
            trace = [-1 if x < 0 else x for x in trace_dict[probe][mode]]
            ax.plot(xs=trace_dict[probe]['time_md'], ys=[yi]*len(trace_dict[probe]['time_md']),zs=trace, ls='-', lw=0.5, color='black', marker='None')
            y_lable.append(probe)
            yi += 1
        ax.xaxis.set_major_locator(mdates.MinuteLocator(interval=1440))
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%m/%d'))
        ax.yaxis.set_major_locator(MultipleLocator(1))
        ax.set_yticklabels(y_lable)
        ax.set_ylabel('Probe ID', fontsize=16)
        ax.set_xlabel('Time', fontsize=16)
        ax.set_zlabel(MODE_LABEL[mode], fontsize=16)
        fig.set_size_inches(12, 9)
        #plt.show()
        fig_name = os.path.join(os.getcwd(), 'rtt3d_%s.pdf'% f)
        plt.savefig(fig_name, bbox_inches='tight', format='pdf')
        plt.close()


if __name__ == "__main__":
    main(sys.argv[1:])
