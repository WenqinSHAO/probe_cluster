import calendar
import time
# measurement related config
START = calendar.timegm(time.strptime('2016-01-18 00:00:00', '%Y-%m-%d %H:%M:%S'))
END = calendar.timegm(time.strptime('2016-01-25 00:00:00', '%Y-%m-%d %H:%M:%S'))
RANGE = END - START
PING_INTV = 240
TRACE_INTV = 1800
PING_LEN = RANGE/PING_INTV
TRACE_LEN = RANGE/TRACE_INTV

#filename related config
PROBE_META_FILE="probes.csv" # probe meta data, such as country code, location etc.

PROBE_ID_ALL_FILE = "pbid.txt" # all probe ids selected
PROBE_ID_PING_RM_FILE = "ping_rm.txt" # probes to be removed accoridng to ping measurement
PROBE_ID_TRACE_RM_FILE = "trace_rm.txt" # probes to be removed accoridng to traceroute measurement
PROBE_ID_PING_VAL_FILE = "ping_val.txt" # probes ping remain valid and have measurements
PROBE_ID_TRACE_VAL_FILE = "trace_val.txt" # probes traceroute remain valid and have measurements
PROBE_ID_VALID_FILE = "valid.txt" # the intersection of the above two files

MES_PING_FILE = 'ping_broot.json' # raw measurement data for ping
MES_TRACE_FILE = 'trace_broot.json' # raw data for traceroute

DIC_IP_2_ASN = 'dic_ip2asn.csv' # Cymru
DIC_IP_2_ASN_ARIN = 'dic_ip2asn_arin.csv' # ARIN
DIC_IP_2_ASN_MERG = 'dic_ip2asn_merg.csv' # MERGE

STAT_IP_PATH = 'stat_ip_path.json' # ip path
STAT_AS_PATH_CY = 'stat_as_path_cy.json' # as path based on Cymru dict
STAT_AS_PATH_MG = 'stat_as_path_mg.json' # as path based on merged dict
STAT_AS_PATH_AP = 'stat_as_path_ap.json' # as path approximated from mg path, remove invalid hops

TRACE_PATH_REC = 'trace_path.json' # file storing parsed ip and AS level path at each traceroute meas

TRACE_TIME_STAMP = 'trace_tsmp.json' # separate file for traceroute timestamps so that I don't have to sotre them in each other json file
