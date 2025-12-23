#!/usr/bin/env python3
"""Manual calibration using known control points."""

import json
import math


def find_transformation(control_points):
    """
    Find affine transformation parameters from control points.
    control_points: list of dicts with 'geojson_e', 'geojson_n', 'google_lat', 'google_lng'
    Returns: (scale_lat, scale_lng, offset_lat, offset_lng)
    """
    if len(control_points) < 2:
        print("❌ Need at least 2 control points!")
        return None

    # Use least squares to find best fit transformation
    # Simplified: assume linear transformation
    # lat = scale_lat * northing + offset_lat
    # lng = scale_lng * easting + offset_lng

    p1 = control_points[0]
    p2 = control_points[1]

    # Calculate scales
    delta_n = p2["geojson_n"] - p1["geojson_n"]
    delta_e = p2["geojson_e"] - p1["geojson_e"]
    delta_lat = p2["google_lat"] - p1["google_lat"]
    delta_lng = p2["google_lng"] - p1["google_lng"]

    if abs(delta_n) < 0.1 or abs(delta_e) < 0.1:
        print("❌ Control points are too close together!")
        return None

    scale_lat = delta_lat / delta_n
    scale_lng = delta_lng / delta_e

    # Calculate offsets using first point
    offset_lat = p1["google_lat"] - scale_lat * p1["geojson_n"]
    offset_lng = p1["google_lng"] - scale_lng * p1["geojson_e"]

    return scale_lat, scale_lng, offset_lat, offset_lng


def transform_coordinate(easting, northing, params):
    """Transform a coordinate using calibration parameters."""
    scale_lat, scale_lng, offset_lat, offset_lng = params
    lat = scale_lat * northing + offset_lat
    lng = scale_lng * easting + offset_lng
    return lat, lng


def main():
    print("=" * 80)
    print("MANUAL MAP CALIBRATION FOR DA NANG")
    print("=" * 80)

    # Control points: GeoJSON coordinates vs Google Maps locations
    control_points = [
        {
            "name": "Chi bộ Mỹ Đa Đông 2",
            "geojson_e": 553202.45,  # From GeoJSON
            "geojson_n": 1774166.03,  # From GeoJSON
            "google_lat": 16.0471358,  # From Google Maps
            "google_lng": 108.2335286,  # From Google Maps
        },
        {
            "name": "Chi bộ Mỹ Đa Đông 1",
            "geojson_e": 553144.351314,  # From GeoJSON
            "geojson_n": 1773958.519767,  # From GeoJSON
            "google_lat": 16.0421305,  # From Google Maps
            "google_lng": 108.2400664,  # From Google Maps
        },
    ]

    print("\n📍 Control Points:")
    for i, cp in enumerate(control_points):
        print(f"\n{i+1}. {cp['name']}")
        print(f"   GeoJSON: E={cp['geojson_e']}, N={cp['geojson_n']}")
        print(f"   Google:  Lat={cp['google_lat']}, Lng={cp['google_lng']}")

    print("\n" + "=" * 80)
    print("CALCULATING TRANSFORMATION...")
    print("=" * 80)

    params = find_transformation(control_points)

    if params:
        scale_lat, scale_lng, offset_lat, offset_lng = params

        print(f"\n✅ Transformation Parameters:")
        print(f"   scale_lat = {scale_lat:.12f}")
        print(f"   scale_lng = {scale_lng:.12f}")
        print(f"   offset_lat = {offset_lat:.12f}")
        print(f"   offset_lng = {offset_lng:.12f}")

        print("\n" + "=" * 80)
        print("VERIFICATION:")
        print("=" * 80)

        # Test transformation on control points
        for cp in control_points:
            lat, lng = transform_coordinate(cp["geojson_e"], cp["geojson_n"], params)
            error = (
                math.sqrt((lat - cp["google_lat"]) ** 2 + (lng - cp["google_lng"]) ** 2)
                * 111
            )

            print(f"\n{cp['name']}")
            print(
                f"   Expected: Lat={cp['google_lat']:.6f}, Lng={cp['google_lng']:.6f}"
            )
            print(f"   Got:      Lat={lat:.6f}, Lng={lng:.6f}")
            print(f"   Error:    {error:.2f} km {'✅' if error < 0.1 else '❌'}")

        print("\n" + "=" * 80)
        print("DART CODE FOR FLUTTER:")
        print("=" * 80)
        print(
            f"""
LatLng _transformCoordinate(double easting, double northing) {{
  const double scaleLat = {scale_lat};
  const double scaleLng = {scale_lng};
  const double offsetLat = {offset_lat};
  const double offsetLng = {offset_lng};
  
  final lat = scaleLat * northing + offsetLat;
  final lng = scaleLng * easting + offsetLng;
  
  return LatLng(lat, lng);
}}
"""
        )
    else:
        print("\n❌ Failed to calculate transformation!")
        print("\nTo fix this:")
        print("1. Find 2-3 Chi Bộ markers you can locate on Google Maps")
        print("2. Get their GeoJSON coordinates from the file")
        print("3. Get their exact Google Maps coordinates")
        print("4. Update the control_points list in this script")
        print("5. Run this script again")


if __name__ == "__main__":
    main()
