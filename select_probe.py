import atlasTools as at
import csv
import os
import sys
from globalConfig import *


CC = ['BE', 'BG', 'CZ', 'DK', 'DE', 'EE', 'IE',\
      'EL', 'ES', 'FR', 'HR', 'IT', 'CY', 'LV', \
      'PT', 'RO', 'SI', 'SK', 'FI', 'SE', 'UK']
# eurpean country code

def main():
    with open(PROBE_META_FILE, 'w') as csvfile:
        fieldnames = ['id', 'address_v4', 'prefix_v4', 'asn_v4',\
                     'latitude', 'longitude', 'country_code']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for c_code in CC:
            probe_quest = "https://atlas.ripe.net/api/v1/probe/?country_code=%s&tags=system-v3,datacentre&is_public=true&status_name=Connected" % c_code
            res = at.query(probe_quest).json()
            if res:
                total = res["meta"]["total_count"]
                limit = res["meta"]["limit"]
                print "%d probe is selected from %s." %(min(total, limit), c_code)
                if min(total, limit):
                    for obj in res["objects"]:
                        if obj["status_name"] == "Connected":
                            pb = {}
                            pb["id"] = obj["id"]
                            pb["address_v4"] = obj["address_v4"]
                            pb["prefix_v4"] = obj["prefix_v4"]
                            pb["asn_v4"] = obj["asn_v4"]
                            pb["latitude"] = obj["latitude"]
                            pb["longitude"] = obj["longitude"]
                            pb["country_code"] = c_code
                            writer.writerow(pb)

if __name__ == "__main__":
    main()
