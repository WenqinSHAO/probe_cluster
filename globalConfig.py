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

DIC_IP_2_ASN = 'dic_ip2asn.csv'
DIC_IP_2_ASN_ARIN = 'dic_ip2asn_arin.csv'
DIC_IP_2_ASN_MERG = 'dic_ip2asn_merg.csv'
