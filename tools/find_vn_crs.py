#!/usr/bin/env python3
"""Find all Vietnam coordinate systems."""

import pyproj

print("All VN2000 and Vietnam related CRS in EPSG database:")
print("-" * 80)

crs_list = pyproj.database.query_crs_info(auth_name="EPSG", pj_types=["PROJECTED_CRS"])

for crs_info in crs_list:
    if any(
        keyword in crs_info.name.upper()
        for keyword in ["VN-2000", "VN2000", "VIETNAM", "VIET NAM"]
    ):
        print(f"EPSG:{crs_info.code:6} - {crs_info.name}")
