#!/usr/bin/env python3
"""Test reverse conversion to find the correct VN-2000 parameters."""

import math


def wgs84_to_utm(lat, lon, zone=48):
    """Convert WGS84 to UTM Zone 48N."""
    # UTM parameters
    a = 6378137.0  # WGS84 semi-major axis
    e = 0.0818191908426
    k0 = 0.9996
    false_easting = 500000.0
    false_northing = 0.0

    lat_rad = math.radians(lat)
    lon_rad = math.radians(lon)
    central_meridian = math.radians((zone - 1) * 6 - 180 + 3)

    N = a / math.sqrt(1 - e * e * math.sin(lat_rad) ** 2)
    T = math.tan(lat_rad) ** 2
    C = (e * e / (1 - e * e)) * math.cos(lat_rad) ** 2
    A = (lon_rad - central_meridian) * math.cos(lat_rad)

    M = a * (
        (1 - e * e / 4 - 3 * e**4 / 64 - 5 * e**6 / 256) * lat_rad
        - (3 * e * e / 8 + 3 * e**4 / 32 + 45 * e**6 / 1024) * math.sin(2 * lat_rad)
        + (15 * e**4 / 256 + 45 * e**6 / 1024) * math.sin(4 * lat_rad)
        - (35 * e**6 / 3072) * math.sin(6 * lat_rad)
    )

    easting = false_easting + k0 * N * (
        A
        + (1 - T + C) * A**3 / 6
        + (5 - 18 * T + T * T + 72 * C - 58 * (e * e / (1 - e * e))) * A**5 / 120
    )

    northing = false_northing + k0 * (
        M
        + N
        * math.tan(lat_rad)
        * (
            A * A / 2
            + (5 - T + 9 * C + 4 * C * C) * A**4 / 24
            + (61 - 58 * T + T * T + 600 * C - 330 * (e * e / (1 - e * e))) * A**6 / 720
        )
    )

    return easting, northing


def main():
    print("=" * 80)
    print("REVERSE ENGINEERING VN-2000 PARAMETERS")
    print("=" * 80)

    # Known WGS84 coordinates from Google Maps
    known_points = [
        ("Mỹ An", 16.0471358, 108.2335286),
        ("Hòa Quý", 15.9869028, 108.194796),
        ("Hòa Hải", 15.990554, 108.2278515),
        ("Khuê Mỹ", 16.02985, 108.2300088),
    ]

    # Expected VN-2000 from GeoJSON (approximate center of KM area)
    expected_vn2000 = (553202.45, 1774166.03)

    print("\n1. Testing different UTM zones:")
    print("-" * 80)

    # Test different zones
    for zone in [47, 48, 49]:
        print(f"\n  Zone {zone} (Central Meridian: {(zone - 1) * 6 - 180 + 3}°):")
        for name, lat, lng in known_points[:1]:  # Test with first point
            e, n = wgs84_to_utm(lat, lng, zone)
            print(f"    {name}: E={e:.2f}, N={n:.2f}")

    print("\n\n2. Compare with expected VN-2000 coordinates:")
    print("-" * 80)
    print(
        f"  Expected from GeoJSON: E={expected_vn2000[0]:.2f}, N={expected_vn2000[1]:.2f}"
    )

    # Test Zone 48 with different False Northing
    print("\n\n3. Testing Zone 48 with different False Northing:")
    print("-" * 80)

    test_point = known_points[0]  # Mỹ An
    e, n = wgs84_to_utm(test_point[1], test_point[2], 48)

    print(f"  {test_point[0]} (WGS84: {test_point[1]}, {test_point[2]})")
    print(f"    UTM Zone 48 (False Northing = 0): E={e:.2f}, N={n:.2f}")

    # Calculate offset
    offset_n = expected_vn2000[1] - n
    print(f"\n  Northing offset needed: {offset_n:.2f} meters")
    print(f"  This suggests False Northing might be: {offset_n:.2f}")

    print("\n\n4. CONCLUSION:")
    print("=" * 80)

    if abs(offset_n) < 100:
        print("  ✅ Zone 48 with False Northing = 0 is correct")
    elif abs(offset_n) > 100000:
        print(f"  ❌ Huge offset detected ({offset_n/1000:.1f} km)")
        print("  🔍 This suggests the GeoJSON might be using:")
        print(f"     - A different coordinate system")
        print(f"     - A different zone")
        print(f"     - False Northing = {offset_n:.2f}")
    else:
        print(f"  ⚠️  Small offset detected ({offset_n:.2f} m)")

    # Check if GeoJSON is actually in a local coordinate system
    print("\n\n5. Analyzing GeoJSON coordinate ranges:")
    print("=" * 80)
    print(f"  VN-2000 Easting: ~553,000 (offset from 500,000 = 53,000m = 53km)")
    print(f"  VN-2000 Northing: ~1,774,000 (offset from 0 = 1,774km)")
    print("\n  For Da Nang at latitude ~16°:")
    e_test, n_test = wgs84_to_utm(16.047, 108.233, 48)
    print(f"    Expected UTM Zone 48: E={e_test:.0f}, N={n_test:.0f}")
    print(f"    GeoJSON shows: E={expected_vn2000[0]:.0f}, N={expected_vn2000[1]:.0f}")
    print(
        f"    Difference: ΔE={expected_vn2000[0]-e_test:.0f}m, ΔN={expected_vn2000[1]-n_test:.0f}m"
    )

    if abs(expected_vn2000[1] - n_test) < 1000:
        print("\n  ✅ Northing matches! Zone 48 is correct.")
    else:
        print(f"\n  ❌ Northing offset: {(expected_vn2000[1] - n_test)/1000:.1f} km")
        print("     The coordinate system might be different!")


if __name__ == "__main__":
    main()
