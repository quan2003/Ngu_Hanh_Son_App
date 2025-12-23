#!/usr/bin/env python3
"""Test different VN2000 zones to find the correct one."""

from pyproj import Transformer

# Sample coordinates from the GeoJSON
test_coords = (553805.9909, 1770555.9824)

# Different VN2000 zones
zones = {
    "EPSG:32648": "WGS84 UTM Zone 48N",
    "EPSG:9205": "VN2000 / TM-3 105-45",
    "EPSG:9206": "VN2000 / TM-3 106-45",
    "EPSG:9207": "VN2000 / TM-3 107-45",
    "EPSG:9208": "VN2000 / TM-3 108-00",
    "EPSG:9209": "VN2000 / TM-3 108-45",
}

print("Testing coordinate systems for Da Nang area")
print("Expected: ~108.2°E, 16.05°N")
print("Input coordinates:", test_coords)
print("-" * 80)

for epsg, name in zones.items():
    try:
        transformer = Transformer.from_crs(epsg, "EPSG:4326", always_xy=True)
        lon, lat = transformer.transform(test_coords[0], test_coords[1])
        print(f"{epsg:12} {name:30} -> {lon:.6f}°E, {lat:.6f}°N")
    except Exception as e:
        print(f"{epsg:12} {name:30} -> ERROR: {e}")
