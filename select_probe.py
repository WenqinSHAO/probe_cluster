import requests
requests.packages.urllib3.disable_warnings()
import csv
import os
import sys

CC = ['BE', 'BG', 'CZ', 'DK', 'DE', 'EE', 'IE',\
      'EL', 'ES', 'FR', 'HR', 'IT', 'CY', 'LV', \
      'PT', 'RO', 'SI', 'SK', 'FI', 'SE', 'UK']
# eurpean country code

FILE="probes.csv" #file that save probes at its other info

def query(url):
    #params = {"key": key}
    headers = {"Accept": "application/json"}
    results = requests.get(url=url, headers=headers)
    if results.status_code == 200:
        return results.json()
    else:
        return False

def main():
    with open(FILE, 'w') as csvfile:
        fieldnames = ['id', 'address_v4', 'prefix_v4', 'asn_v4',\
                     'latitude', 'longitude', 'country_code']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for c_code in CC:
            probe_quest = "https://atlas.ripe.net/api/v1/probe/?country_code=%s&tags=system-v3,datacentre&is_public=true&status_name=Connected" % c_code
            res = query(probe_quest)
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
