#!/usr/bin/env python3
"""Download the CC0 Poly Haven assets used by the web version (1k resolution).
Usage: python3 tools/fetch_polyhaven.py   (run from the repo root)"""
import json, os, urllib.request
UA={"User-Agent":"Mozilla/5.0 (asset-fetch)"}
def op(u): return urllib.request.urlopen(urllib.request.Request(u, headers=UA))
TEX = ["dry_ground_01","sandy_gravel","asphalt_02","burned_ground_01","rough_concrete",
       "damaged_plaster","wood_planks","fabric_pattern_07"]
HDRI = ["moonless_golf","kiara_1_dawn","kloofendal_misty_morning_puresky"]
OUT = os.path.join("web","assets")
def get(url, path):
    if os.path.exists(path): return
    print("↓", path); open(path,"wb").write(op(url).read())
for t in TEX:
    d = json.load(op(f"https://api.polyhaven.com/files/{t}"))
    for key, suf in (("Diffuse" if "Diffuse" in d else "col_1","diff"),("nor_gl","nor"),("arm","arm")):
        get(d[key]["1k"]["jpg"]["url"], os.path.join(OUT,"tex",f"{t}_{suf}.jpg"))
for h in HDRI:
    d = json.load(op(f"https://api.polyhaven.com/files/{h}"))
    get(d["hdri"]["1k"]["hdr"]["url"], os.path.join(OUT,"hdri",f"{h}.hdr"))
