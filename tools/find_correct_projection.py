#!/usr/bin/env python3
"""Find the correct coordinate system by comparing with known Google Maps locations."""

import json
import math
from pyproj import Transformer, CRS


def test_projection(easting, northing, crs_code, expected_lat, expected_lng):
    """Test a specific CRS code."""
    try:
        # Create transformer from the CRS to WGS84
        transformer = Transformer.from_crs(crs_code, "EPSG:4326", always_xy=True)
        lng, lat = transformer.transform(easting, northing)

        # Calculate error in km
        error = math.sqrt((lat - expected_lat) ** 2 + (lng - expected_lng) ** 2) * 111

        return lat, lng, error
    except Exception as e:
        return None, None, float("inf")


def main():
    print("=" * 80)
    print("FINDING CORRECT COORDINATE SYSTEM FOR DA NANG MAP")
    print("=" * 80)

    # Test data: GeoJSON coordinate vs Google Maps location
    test_cases = [
        {
            "name": "Chi bộ Mỹ Đa Đông 2",
            "geojson_e": 553202.45,
            "geojson_n": 1774166.03,
            "google_lat": 16.0471358,
            "google_lng": 108.2335286,
            "area": "Mỹ An",
        }
    ]

    # Common VN CRS to test
    crs_to_test = [
        ("EPSG:3405", "VN-2000 / TM-3 zone 107 (Ngũ Hành Sơn might use this)"),
        ("EPSG:3406", "VN-2000 / TM-3 zone 108"),
        ("EPSG:3407", "VN-2000 / TM-3 zone 109"),
        ("EPSG:9214", "VN-2000 / UTM zone 48N"),
        ("EPSG:9215", "VN-2000 / UTM zone 49N"),
        ("EPSG:32648", "WGS 84 / UTM zone 48N"),
        ("EPSG:32649", "WGS 84 / UTM zone 49N"),
    ]

    print("\nTest case: Chi bộ Mỹ Đa Đông 2")
    print(f"  GeoJSON: E={test_cases[0]['geojson_e']}, N={test_cases[0]['geojson_n']}")
    print(
        f"  Expected: Lat={test_cases[0]['google_lat']}, Lng={test_cases[0]['google_lng']}"
    )
    print("\n" + "=" * 80)
    print("TESTING DIFFERENT COORDINATE SYSTEMS:")
    print("=" * 80)

    results = []

    for crs_code, description in crs_to_test:
        lat, lng, error = test_projection(
            test_cases[0]["geojson_e"],
            test_cases[0]["geojson_n"],
            crs_code,
            test_cases[0]["google_lat"],
            test_cases[0]["google_lng"],
        )

        if lat is not None:
            results.append((crs_code, description, lat, lng, error))
            status = "✅" if error < 1.0 else "❌"
            print(f"\n{status} {crs_code}: {description}")
            print(f"   Result: Lat={lat:.6f}, Lng={lng:.6f}")
            print(f"   Error: {error:.2f} km")

    # Find best match
    results.sort(key=lambda x: x[4])

    if results and results[0][4] < 1.0:
        print("\n" + "=" * 80)
        print("✅ BEST MATCH FOUND!")
        print("=" * 80)
        crs_code, description, lat, lng, error = results[0]
        print(f"  CRS Code: {crs_code}")
        print(f"  Description: {description}")
        print(f"  Converted: Lat={lat:.6f}, Lng={lng:.6f}")
        print(
            f"  Expected:  Lat={test_cases[0]['google_lat']:.6f}, Lng={test_cases[0]['google_lng']:.6f}"
        )
        print(f"  Error: {error:.2f} km")
        print(f"\n  👉 Update your Flutter code to use: {crs_code}")
    else:
        print("\n" + "=" * 80)
        print("❌ NO GOOD MATCH FOUND")
        print("=" * 80)
        print("  The GeoJSON might be using a custom/local coordinate system.")
        print("  You may need to:")
        print("    1. Check the original CAD file metadata")
        print("    2. Contact the person who created the GeoJSON")
        print("    3. Use manual calibration with known points")


if __name__ == "__main__":
    try:
        import pyproj

        main()
    except ImportError:
        print("ERROR: pyproj is not installed!")
        print("Please install it: pip install pyproj")
