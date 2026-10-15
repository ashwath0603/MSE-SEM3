"""
fetch_wdi_archive.py: download the inputs for the constructed PovCalNet line-up

Source : World Bank, WDI Database Archives (API source 57), release 2019 Dec
         (version 201912). Same month the authors downloaded PovCalNet.
Output : constructed/data/wdi_archive_201912/
           <series>.json      API responses exactly as received
           countries.json     country metadata (region, aggregates flagged)
           wdi_201912_long.csv  the same values flattened: iso3, year, series, value
Run    : python3 constructed/scripts/fetch_wdi_archive.py   (from any folder)

Only needed once. Stata cannot read JSON, so constructed.do (step 2) reads the CSV.
"""
import csv
import json
import os
import urllib.request

VERSION = "201912"
SERIES = {
    "SI.POV.DDAY": "Poverty headcount ratio at $1.90 a day (2011 PPP), % (survey years only)",
    "SI.POV.GINI": "Gini index (World Bank estimate), survey years only",
    "NY.GDP.PCAP.KD": "GDP per capita, constant 2010 US$",
    "NE.CON.PRVT.PC.KD": "Household final consumption expenditure per capita, constant 2010 US$",
}
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "wdi_archive_" + VERSION)
API = "https://api.worldbank.org/v2"


def get(url):
    with urllib.request.urlopen(url, timeout=120) as r:
        return r.read()


os.makedirs(OUT, exist_ok=True)
rows = []
for code in SERIES:
    url = (f"{API}/sources/57/country/all/series/{code}/version/{VERSION}"
           f"/time/all?format=json&per_page=100000")
    raw = get(url)
    with open(os.path.join(OUT, code + ".json"), "wb") as f:
        f.write(raw)
    d = json.loads(raw)
    assert d["pages"] == 1, code + ": more than one page"
    n = 0
    for r in d["source"]["data"]:
        if r["value"] is None:
            continue
        v = {x["concept"]: x["id"] for x in r["variable"]}
        rows.append([v["Country"], int(v["Time"][2:]), code, r["value"]])
        n += 1
    print(f"{code}: {n} non-missing values")

with open(os.path.join(OUT, "wdi_201912_long.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["iso3", "year", "series", "value"])
    w.writerows(rows)

# country metadata: current classification (the archive has none). Used only
# to drop aggregates and to flag Sub-Saharan Africa.
raw = get(f"{API}/country?format=json&per_page=400")
with open(os.path.join(OUT, "countries.json"), "wb") as f:
    f.write(raw)
with open(os.path.join(OUT, "countries.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["iso3", "name", "region_id", "region"])
    for c in json.loads(raw)[1]:
        w.writerow([c["id"], c["name"], c["region"]["id"], c["region"]["value"]])
print("wrote", OUT)
