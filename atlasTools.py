import json
import requests
requests.packages.urllib3.disable_warnings()
import time
import calendar
import matplotlib.dates as mdates
import numpy as np

def query(url):
    #params = {"key": key}
    headers = {"Accept": "application/json"}
    results = requests.get(url=url, headers=headers)
    if results.status_code == 200:
        return results
    else:
        return False


def queryID(pb_id):
    url = "https://atlas.ripe.net/api/v1/probe/?id__in=%d" % int(pb_id)
    return query(url)


def readPingJSON(file):
    at_raw = json.load(open(file, 'r'))
    at_prob_rtt = {}
    for mes in at_raw:
        prob_id = mes['prb_id']
        if prob_id not in at_prob_rtt:
            at_prob_rtt[prob_id] = {'src_ip': mes['from'],
                                    'time_md': [],
                                    'avg': [],
                                    'min':[],
                                    'max':[],
                                    'loss':[],
                                    'time_epc':[]}
        epoch_time = mes['timestamp']
        at_prob_rtt[prob_id]['time_epc'].append(epoch_time)
        utc_string = time.strftime('%Y-%m-%d %H:%M:%S',time.gmtime(epoch_time))
        mdate_time = mdates.strpdate2num('%Y-%m-%d %H:%M:%S')(utc_string)
        at_prob_rtt[prob_id]['time_md'].append(mdate_time)
        at_prob_rtt[prob_id]['min'].append(float(round(mes['min'])))
        at_prob_rtt[prob_id]['avg'].append(float(round(mes['avg'])))
        at_prob_rtt[prob_id]['max'].append(float(round(mes['max'])))
        if mes['sent'] == 0:
            at_prob_rtt[prob_id]['loss'].append(100)
        else:
            at_prob_rtt[prob_id]['loss'].append((1-float(mes['rcvd'])/mes['sent'])*100)
    return at_prob_rtt


def readTraceJSON(file):
    at_raw = json.load(open(file, 'r'))
    at_prob_rtt = {}
    for mes in at_raw:
        prob_id = mes['prb_id']
        if prob_id not in at_prob_rtt:
            at_prob_rtt[prob_id] = {'time_md':[],
                                    'time_epc':[],
                                    'min':[],
                                    'avg':[],
                                    'max':[],
                                    'ip_path':[],
                                    'paris_id':[]}
        epoch_time = mes['timestamp']
        at_prob_rtt[prob_id]['time_epc'].append(epoch_time)
        utc_string = time.strftime('%Y-%m-%d %H:%M:%S',time.gmtime(epoch_time))
        mdate_time = mdates.strpdate2num('%Y-%m-%d %H:%M:%S')(utc_string)
        at_prob_rtt[prob_id]['time_md'].append(mdate_time)
        at_prob_rtt[prob_id]['paris_id'].append(mes['paris_id'])
        min_ = []
        avg_ = []
        max_ = []
        path_ =[]
        for hop in mes['result']:
            res_rtt = []
            hop_ip = ''
            if 'result' in hop:
                for try_ in hop['result']:
                    if ('rtt' in try_) and ('err' not in try_):
                        res_rtt.append(try_['rtt'])
                        hop_ip = try_['from']
                if res_rtt:
                    min_.append(np.min(res_rtt))
                    avg_.append(np.mean(res_rtt))
                    max_.append(np.max(res_rtt))
                    path_.append(hop_ip)
                else:
                    min_.append(-1)
                    avg_.append(-1)
                    max_.append(-1)
                    path_.append('*')
            else:
                min_.append(-1)
                avg_.append(-1)
                max_.append(-1)
                path_.append('*')
        at_prob_rtt[prob_id]['min'].append(min_)
        at_prob_rtt[prob_id]['avg'].append(avg_)
        at_prob_rtt[prob_id]['max'].append(max_)
        at_prob_rtt[prob_id]['ip_path'].append(path_)
    return at_prob_rtt
