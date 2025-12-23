#!/usr/bin/env python3
"""Try to find the actual coordinate system by brute force."""

import json
import math


def utm_to_wgs84(
    easting, northing, zone, central_meridian, false_easting=500000, false_northing=0
):
    """Generic UTM to WGS84 conversion."""
    a = 6378137.0
    e = 0.0818191908426
    e1sq = 0.00673949674227
    k0 = 0.9996

    x = easting - false_easting
    y = northing - false_northing

    M = y / k0
    mu = M / (a * (1 - e * e / 4 - 3 * e**4 / 64 - 5 * e**6 / 256))

    phi1 = (
        mu
        + (3 * e1sq / 2 - 27 * e1sq**3 / 32) * math.sin(2 * mu)
        + (21 * e1sq**2 / 16 - 55 * e1sq**4 / 32) * math.sin(4 * mu)
        + (151 * e1sq**3 / 96) * math.sin(6 * mu)
    )

    N1 = a / math.sqrt(1 - e * e * math.sin(phi1) ** 2)
    T1 = math.tan(phi1) ** 2
    C1 = e1sq * math.cos(phi1) ** 2
    R1 = a * (1 - e * e) / (1 - e * e * math.sin(phi1) ** 2) ** 1.5
    D = x / (N1 * k0)

    lat = phi1 - (N1 * math.tan(phi1) / R1) * (
        D**2 / 2
        - (5 + 3 * T1 + 10 * C1 - 4 * C1**2 - 9 * e1sq) * D**4 / 24
        + (61 + 90 * T1 + 298 * C1 + 45 * T1**2 - 252 * e1sq - 3 * C1**2) * D**6 / 720
    )

    lon = (
        D
        - (1 + 2 * T1 + C1) * D**3 / 6
        + (5 - 2 * C1 + 28 * T1 - 3 * C1**2 + 8 * e1sq + 24 * T1**2) * D**5 / 120
    ) / math.cos(phi1)

    return (lat * 180.0 / math.pi, central_meridian + lon * 180.0 / math.pi)


def main():
    print("=" * 80)
    print("BRUTE FORCE SEARCH FOR CORRECT COORDINATE SYSTEM")
    print("=" * 80)

    # Test coordinate from GeoJSON
    test_easting = 553202.45
    test_northing = 1774166.03

    # Expected WGS84 (Mỹ An from Google Maps)
    expected_lat = 16.0471358
    expected_lng = 108.2335286

    print(f"\nGeoJSON: E={test_easting}, N={test_northing}")
    print(f"Expected WGS84: {expected_lat}, {expected_lng}")
    print("\nTrying different central meridians...\n")

    best_match = None
    best_error = float("inf")

    # Try different central meridians (90° to 120°)
    for cm in range(90, 121):
        lat, lng = utm_to_wgs84(test_easting, test_northing, 48, cm)

        error = math.sqrt((lat - expected_lat) ** 2 + (lng - expected_lng) ** 2)

        if error < 0.01:  # Within ~1km
            print(
                f"  CM={cm:3d}°: Lat={lat:.6f}, Lng={lng:.6f} ✅ ERROR={error*111:.1f}km"
            )

        if error < best_error:
            best_error = error
            best_match = (cm, lat, lng)

    print("\n" + "=" * 80)
    print("BEST MATCH:")
    print("=" * 80)
    print(f"  Central Meridian: {best_match[0]}°")
    print(f"  Converted: Lat={best_match[1]:.6f}, Lng={best_match[2]:.6f}")
    print(f"  Expected:  Lat={expected_lat:.6f}, Lng={expected_lng:.6f}")
    print(f"  Error: {best_error*111:.2f} km")

    if best_error > 0.01:
        print("\n  ❌ No good match found with standard UTM parameters!")
        print("  The GeoJSON might be using:")
        print("    - A non-standard projection")
        print("    - Local coordinates that need calibration")
        print("    - A different ellipsoid (not WGS84)")


if __name__ == "__main__":
    main()
