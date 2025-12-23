#!/usr/bin/env python3
"""Manual calibration using known points from Google Maps."""

import json
import math


def find_linear_transform(geojson_points, google_points):
    """
    Find linear transformation:
    lat_wgs84 = a1 * easting + b1 * northing + c1
    lng_wgs84 = a2 * easting + b2 * northing + c2
    """
    import numpy as np

    # Build matrices
    n = len(geojson_points)
    A = np.zeros((n, 3))
    B_lat = np.zeros(n)
    B_lng = np.zeros(n)

    for i, (e, n) in enumerate(geojson_points):
        A[i] = [e, n, 1]
        B_lat[i] = google_points[i][0]
        B_lng[i] = google_points[i][1]

    # Solve least squares
    coeffs_lat = np.linalg.lstsq(A, B_lat, rcond=None)[0]
    coeffs_lng = np.linalg.lstsq(A, B_lng, rcond=None)[0]

    return coeffs_lat, coeffs_lng


def main():
    print("=" * 80)
    print("MANUAL CALIBRATION FOR DA NANG MAP")
    print("=" * 80)

    # We need at least 2-3 known points
    # Let's try to find them by checking the GeoJSON

    with open("d:/NHS_APP/assets/maps/KM_POINT.geojson", "r", encoding="utf-8") as f:
        data = json.load(f)

    features = [
        f for f in data["features"] if f.get("properties", {}).get("Layer") == "R.GIOI"
    ]

    print(f"\nFound {len(features)} chi bộ markers")
    print("\nPlease identify these locations on Google Maps:")
    print("=" * 80)

    for i, f in enumerate(features[:5]):
        props = f.get("properties", {})
        coords = f.get("geometry", {}).get("coordinates", [])
        name = props.get("Text_utf8", "").split("\n")[0]

        if len(coords) >= 2:
            print(f"\n{i+1}. {name}")
            print(f"   GeoJSON: E={coords[0]:.2f}, N={coords[1]:.2f}")

    print("\n" + "=" * 80)
    print("CALIBRATION APPROACH:")
    print("=" * 80)
    print(
        """
Since no standard CRS matches, we need to:

1. Find 3+ known landmarks in Google Maps that match chi bộ names
2. Get their exact coordinates from Google Maps
3. Calculate affine transformation

For now, let's try a SIMPLE OFFSET FIX:
  - Your markers are ~39km too far northeast
  - This suggests a simple offset error
"""
    )

    # Test simple offset
    print("\n" + "=" * 80)
    print("TESTING SIMPLE OFFSET:")
    print("=" * 80)

    test_e = 553202.45
    test_n = 1774166.03
    expected_lat = 16.0471358
    expected_lng = 108.2335286

    # Current wrong conversion (using UTM 48N)
    from pyproj import Transformer

    transformer = Transformer.from_crs("EPSG:9214", "EPSG:4326", always_xy=True)
    wrong_lng, wrong_lat = transformer.transform(test_e, test_n)

    lat_offset = expected_lat - wrong_lat
    lng_offset = expected_lng - wrong_lng

    print(f"\nCurrent (wrong): Lat={wrong_lat:.6f}, Lng={wrong_lng:.6f}")
    print(f"Expected:        Lat={expected_lat:.6f}, Lng={expected_lng:.6f}")
    print(f"Offset needed:   Lat={lat_offset:+.6f}, Lng={lng_offset:+.6f}")
    print(f"                 ({lat_offset*111:.2f}km, {lng_offset*111:.2f}km)")

    # Apply offset to all KM markers
    print("\n" + "=" * 80)
    print("TESTING OFFSET ON ALL MARKERS:")
    print("=" * 80)

    corrected_coords = []
    for i, f in enumerate(features[:5]):
        coords = f.get("geometry", {}).get("coordinates", [])
        if len(coords) >= 2:
            lng, lat = transformer.transform(coords[0], coords[1])
            corrected_lat = lat + lat_offset
            corrected_lng = lng + lng_offset

            name = f.get("properties", {}).get("Text_utf8", "").split("\n")[0]
            print(f"\n{i+1}. {name}")
            print(f"   Corrected: Lat={corrected_lat:.6f}, Lng={corrected_lng:.6f}")
            print(
                f"   Google: https://www.google.com/maps?q={corrected_lat},{corrected_lng}"
            )

            corrected_coords.append((corrected_lat, corrected_lng))

    if corrected_coords:
        avg_lat = sum(c[0] for c in corrected_coords) / len(corrected_coords)
        avg_lng = sum(c[1] for c in corrected_coords) / len(corrected_coords)

        print("\n" + "=" * 80)
        print("✅ SOLUTION:")
        print("=" * 80)
        print(f"  Use EPSG:9214 (VN-2000 UTM 48N) + offset correction")
        print(f"  Lat offset: {lat_offset:+.6f} ({lat_offset*111:.2f}km)")
        print(f"  Lng offset: {lng_offset:+.6f} ({lng_offset*111:.2f}km)")
        print(f"\n  Center of corrected area:")
        print(f"  https://www.google.com/maps?q={avg_lat},{avg_lng}&z=14")


if __name__ == "__main__":
    try:
        import numpy as np
        import pyproj

        main()
    except ImportError as e:
        print(f"ERROR: Missing package: {e}")
        print("Please install: pip install numpy pyproj")
