#!/usr/bin/env python3
"""Verify KM area coordinates and check if they're in the correct location."""

import json
import math


def vn2000_to_wgs84(easting, northing):
    """Convert VN-2000 UTM Zone 48N to WGS84."""
    # VN-2000 UTM Zone 48N parameters
    false_easting = 500000.0
    k0 = 0.9996  # UTM scale factor
    a = 6378137.0  # WGS84 semi-major axis
    e = 0.0818191908426  # WGS84 first eccentricity
    e1sq = 0.00673949674227  # e^2 / (1 - e^2)
    central_meridian = 108.0  # Zone 48N: 108° E

    x = easting - false_easting
    y = northing

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
    print("VERIFYING KM AREA COORDINATES")
    print("=" * 80)

    # Load KM_POINT.geojson
    with open("d:/NHS_APP/assets/maps/KM_POINT.geojson", "r", encoding="utf-8") as f:
        data = json.load(f)

    features = data.get("features", [])
    print(f"\nTotal features: {len(features)}")

    # Filter R.GIOI layer
    chi_bo_features = [
        f for f in features if f.get("properties", {}).get("Layer") == "R.GIOI"
    ]
    print(f"Chi bộ markers (R.GIOI layer): {len(chi_bo_features)}")

    if not chi_bo_features:
        print("❌ NO CHI BỘ MARKERS FOUND!")
        return

    print("\n" + "=" * 80)
    print("COORDINATE CONVERSION RESULTS:")
    print("=" * 80)

    all_lats = []
    all_lngs = []

    for i, feature in enumerate(chi_bo_features[:5]):  # Show first 5
        props = feature.get("properties", {})
        geom = feature.get("geometry", {})
        coords = geom.get("coordinates", [])

        if len(coords) >= 2:
            easting = coords[0]
            northing = coords[1]
            lat, lng = vn2000_to_wgs84(easting, northing)

            all_lats.append(lat)
            all_lngs.append(lng)

            title = props.get("Text_utf8", "Unknown").split("\n")[0]

            print(f"\n{i+1}. {title}")
            print(f"   VN-2000: ({easting:.2f}, {northing:.2f})")
            print(f"   WGS84:   ({lat:.6f}, {lng:.6f})")
            print(f"   Google:  https://www.google.com/maps?q={lat},{lng}")

    # Process all markers for bounds
    for feature in chi_bo_features:
        geom = feature.get("geometry", {})
        coords = geom.get("coordinates", [])
        if len(coords) >= 2:
            lat, lng = vn2000_to_wgs84(coords[0], coords[1])
            all_lats.append(lat)
            all_lngs.append(lng)

    if all_lats and all_lngs:
        min_lat, max_lat = min(all_lats), max(all_lats)
        min_lng, max_lng = min(all_lngs), max(all_lngs)
        center_lat = (min_lat + max_lat) / 2
        center_lng = (min_lng + max_lng) / 2

        print("\n" + "=" * 80)
        print("BOUNDS ANALYSIS:")
        print("=" * 80)
        print(f"Latitude range:  {min_lat:.6f} to {max_lat:.6f}")
        print(f"Longitude range: {min_lng:.6f} to {max_lng:.6f}")
        print(f"Center point:    ({center_lat:.6f}, {center_lng:.6f})")
        print(f"\nView center on Google Maps:")
        print(f"https://www.google.com/maps?q={center_lat},{center_lng}&z=15")

        # Check if coordinates are reasonable for Da Nang area
        print("\n" + "=" * 80)
        print("VALIDATION:")
        print("=" * 80)

        expected_lat_range = (15.9, 16.5)
        expected_lng_range = (108.0, 108.7)

        lat_valid = expected_lat_range[0] <= center_lat <= expected_lat_range[1]
        lng_valid = expected_lng_range[0] <= center_lng <= expected_lng_range[1]

        if lat_valid and lng_valid:
            print("✅ Coordinates are VALID for Da Nang area!")
            print(f"   Expected: Lat {expected_lat_range}, Lng {expected_lng_range}")
            print(
                f"   Actual:   Lat ({min_lat:.3f}, {max_lat:.3f}), Lng ({min_lng:.3f}, {max_lng:.3f})"
            )
        else:
            print("❌ Coordinates are OUT OF RANGE for Da Nang!")
            print(f"   Expected: Lat {expected_lat_range}, Lng {expected_lng_range}")
            print(
                f"   Actual:   Lat ({min_lat:.3f}, {max_lat:.3f}), Lng ({min_lng:.3f}, {max_lng:.3f})"
            )
            if not lat_valid:
                print("   ⚠️  Latitude is out of range")
            if not lng_valid:
                print("   ⚠️  Longitude is out of range")

    print("\n" + "=" * 80)


if __name__ == "__main__":
    main()
