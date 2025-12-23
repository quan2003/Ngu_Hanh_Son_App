#!/usr/bin/env python3
"""Test all VN2000 zones to find the correct one for Da Nang."""

from pyproj import Transformer

# Sample coordinates from the GeoJSON
test_coords = (553805.9909, 1770555.9824)

# All VN2000 zones
zones = {
    "EPSG:3405": "VN-2000 / UTM zone 48N",
    "EPSG:3406": "VN-2000 / UTM zone 49N",
    "EPSG:5896": "VN-2000 / TM-3 zone 481",
    "EPSG:5897": "VN-2000 / TM-3 zone 482",
    "EPSG:5898": "VN-2000 / TM-3 zone 491",
    "EPSG:5899": "VN-2000 / TM-3 107-45",
    "EPSG:9205": "VN-2000 / TM-3 103-00",
    "EPSG:9206": "VN-2000 / TM-3 104-00",
    "EPSG:9207": "VN-2000 / TM-3 104-30",
    "EPSG:9208": "VN-2000 / TM-3 104-45",
    "EPSG:9209": "VN-2000 / TM-3 105-30",
    "EPSG:9210": "VN-2000 / TM-3 105-45",
    "EPSG:9211": "VN-2000 / TM-3 106-00",
    "EPSG:9212": "VN-2000 / TM-3 106-15",
    "EPSG:9213": "VN-2000 / TM-3 106-30",
    "EPSG:9214": "VN-2000 / TM-3 107-00",
    "EPSG:9215": "VN-2000 / TM-3 107-15",
    "EPSG:9216": "VN-2000 / TM-3 107-30",
    "EPSG:9217": "VN-2000 / TM-3 108-15",
    "EPSG:9218": "VN-2000 / TM-3 108-30",
}

print("Testing all VN-2000 coordinate systems for Da Nang area")
print("Expected: ~108.2°E, 16.05°N")
print("Input coordinates:", test_coords)
print("-" * 90)

best_match = None
best_distance = float("inf")

for epsg, name in zones.items():
    try:
        transformer = Transformer.from_crs(epsg, "EPSG:4326", always_xy=True)
        lon, lat = transformer.transform(test_coords[0], test_coords[1])

        # Calculate distance from expected (108.2, 16.05)
        distance = abs(lon - 108.2) + abs(lat - 16.05)

        marker = ""
        if distance < best_distance:
            best_distance = distance
            best_match = (epsg, name, lon, lat)
            marker = " <-- CLOSEST MATCH"

        print(f"{epsg:12} {name:35} -> {lon:9.5f}°E, {lat:8.5f}°N{marker}")
    except Exception as e:
        print(f"{epsg:12} {name:35} -> ERROR: {e}")

print("-" * 90)
if best_match:
    print(f"\nBest match: {best_match[0]} ({best_match[1]})")
    print(f"Result: {best_match[2]:.5f}°E, {best_match[3]:.5f}°N")
    print(f"Distance from expected: {best_distance:.5f}°")
