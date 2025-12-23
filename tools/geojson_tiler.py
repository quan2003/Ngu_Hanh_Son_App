#!/usr/bin/env python3
"""
GeoJSON Tiler - Chia GeoJSON lớn thành các tiles nhỏ
Dùng cho Flutter app để load on-demand theo zoom level
"""

import json
import os
import math
from collections import defaultdict

# Try to use pyproj for accurate coordinate conversion
try:
    from pyproj import (
        Transformer,
    )  # VN2000 TM-3 107-45 to WGS84 (correct for Da Nang area)

    transformer = Transformer.from_crs("EPSG:5899", "EPSG:4326", always_xy=True)
    USE_PYPROJ = True
    print("✅ Using pyproj for accurate coordinate conversion")
except ImportError:
    USE_PYPROJ = False
    print("⚠️ pyproj not found, using simplified conversion (may be less accurate)")
    print("   Install with: pip install pyproj")


def deg2num(lat, lon, zoom):
    """Convert lat/lon to tile coordinates"""
    lat_rad = math.radians(lat)
    n = 2.0**zoom
    xtile = int((lon + 180.0) / 360.0 * n)
    ytile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
    return (xtile, ytile)


def get_feature_bounds(feature):
    """Get bounding box of a feature"""
    coords = feature["geometry"]["coordinates"]
    geom_type = feature["geometry"]["type"]

    def flatten_coords(coords, depth=0):
        """Flatten nested coordinate arrays"""
        if not coords:
            return []
        if isinstance(coords[0], (int, float)):
            return [coords]
        result = []
        for item in coords:
            result.extend(flatten_coords(item, depth + 1))
        return result

    flat_coords = flatten_coords(coords)

    if not flat_coords:
        return None

    lons = [c[0] for c in flat_coords if len(c) >= 2]
    lats = [c[1] for c in flat_coords if len(c) >= 2]

    if not lons or not lats:
        return None

    return {
        "min_lon": min(lons),
        "max_lon": max(lons),
        "min_lat": min(lats),
        "max_lat": max(lats),
    }


def convert_vn2000_to_wgs84(x, y):
    """
    Convert VN2000 TM-3 107-45 (EPSG:5899) to WGS84 (EPSG:4326)
    This is the correct coordinate system for Da Nang area.
    """
    if USE_PYPROJ:
        # Use pyproj for accurate conversion
        lon, lat = transformer.transform(x, y)
        return lat, lon
    else:
        # Fallback to simplified conversion (less accurate)
        import math

        # UTM Zone 48N parameters
        zone = 48
        false_easting = 500000
        false_northing = 0
        scale_factor = 0.9996
        central_meridian = (zone - 1) * 6 - 180 + 3  # = 105°E

        # Remove false easting/northing
        x = x - false_easting
        y = y - false_northing

        # Calculate latitude
        M = y / scale_factor
        mu = M / (6378137 * (1 - 0.00669438 / 4 - 3 * 0.00669438**2 / 64))

        e1 = (1 - math.sqrt(1 - 0.00669438)) / (1 + math.sqrt(1 - 0.00669438))
        phi1 = mu + (3 * e1 / 2 - 27 * e1**3 / 32) * math.sin(2 * mu)

        lat = math.degrees(phi1)

        # Calculate longitude
        N = 6378137 / math.sqrt(1 - 0.00669438 * math.sin(phi1) ** 2)
        T = math.tan(phi1) ** 2
        C = 0.00669438 * math.cos(phi1) ** 2 / (1 - 0.00669438)
        A = x / (N * scale_factor)

        lon = central_meridian + math.degrees(A - (1 + 2 * T + C) * A**3 / 6)

        return lat, lon


def convert_coordinates(coords, depth=0):
    """Recursively convert VN2000 coordinates to WGS84"""
    if not coords:
        return coords

    # Check if this is a coordinate pair [x, y] or [x, y, z]
    if isinstance(coords[0], (int, float)):
        if len(coords) >= 2:
            try:
                lat, lon = convert_vn2000_to_wgs84(coords[0], coords[1])
                z = coords[2] if len(coords) > 2 else 0
                return [lon, lat, z]
            except:
                return coords
        return coords

    # Recursively process nested arrays
    return [convert_coordinates(item, depth + 1) for item in coords]


def simplify_feature(feature, tolerance=10):
    """Simplify feature geometry by taking every Nth point"""
    coords = feature["geometry"]["coordinates"]
    geom_type = feature["geometry"]["type"]

    def simplify_line(line):
        if not line or len(line) <= 2:
            return line
        # Keep first, last, and every Nth point
        result = [line[0]]
        for i in range(tolerance, len(line) - 1, tolerance):
            result.append(line[i])
        if line[-1] != result[-1]:
            result.append(line[-1])
        return result

    def simplify_coords(coords, depth=0):
        if not coords:
            return coords
        if isinstance(coords[0], (int, float)):
            return coords
        if isinstance(coords[0][0], (int, float)):
            return simplify_line(coords)
        return [simplify_coords(item, depth + 1) for item in coords]

    feature["geometry"]["coordinates"] = simplify_coords(coords)
    return feature


def tile_geojson(input_file, output_dir, max_zoom=16, simplify_tolerance=10):
    """
    Tile a large GeoJSON file into smaller tiles
    """
    print(f"Loading GeoJSON from {input_file}...")

    with open(input_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    features = data.get("features", [])
    total = len(features)
    print(f"Found {total} features")

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    # Group features by tile
    tiles = defaultdict(list)
    converted_count = 0

    print("Converting coordinates and tiling...")
    for i, feature in enumerate(features):
        if i % 1000 == 0:
            print(f"Processing feature {i}/{total}...")

        # Convert VN2000 to WGS84
        try:
            feature["geometry"]["coordinates"] = convert_coordinates(
                feature["geometry"]["coordinates"]
            )
            converted_count += 1
        except Exception as e:
            print(f"Error converting feature {i}: {e}")
            continue

        # Simplify geometry
        feature = simplify_feature(feature, simplify_tolerance)

        # Get feature bounds
        bounds = get_feature_bounds(feature)
        if not bounds:
            continue

        # Calculate center point
        center_lat = (bounds["min_lat"] + bounds["max_lat"]) / 2
        center_lon = (bounds["min_lon"] + bounds["max_lon"]) / 2

        # Assign to tiles at different zoom levels
        for zoom in range(12, max_zoom + 1):
            x, y = deg2num(center_lat, center_lon, zoom)
            tile_key = f"{zoom}/{x}/{y}"
            tiles[tile_key].append(feature)

    print(f"\nConverted {converted_count} features")
    print(f"Created {len(tiles)} tiles")

    # Write tiles
    print("\nWriting tiles...")
    tile_index = {}

    for tile_key, tile_features in tiles.items():
        zoom, x, y = tile_key.split("/")

        # Create directory structure
        tile_dir = os.path.join(output_dir, zoom, x)
        os.makedirs(tile_dir, exist_ok=True)

        # Write tile
        tile_file = os.path.join(tile_dir, f"{y}.json")
        tile_data = {"type": "FeatureCollection", "features": tile_features}

        with open(tile_file, "w", encoding="utf-8") as f:
            json.dump(tile_data, f, separators=(",", ":"))

        file_size = os.path.getsize(tile_file)
        tile_index[tile_key] = {"features": len(tile_features), "size": file_size}

    # Write index
    index_file = os.path.join(output_dir, "index.json")
    with open(index_file, "w", encoding="utf-8") as f:
        json.dump(tile_index, f, indent=2)

    print(f"\n✅ Tiling complete!")
    print(f"   Output directory: {output_dir}")
    print(f"   Total tiles: {len(tiles)}")
    print(f"   Index file: {index_file}")

    # Calculate total size
    total_size = sum(info["size"] for info in tile_index.values())
    print(f"   Total size: {total_size / 1024 / 1024:.2f} MB")


if __name__ == "__main__":
    input_file = r"d:\NHS_APP\assets\maps\nhs.geojson"
    output_dir = r"d:\NHS_APP\assets\maps\tiles"

    print("=" * 60)
    print("GeoJSON Tiler for Flutter")
    print("=" * 60)

    tile_geojson(
        input_file=input_file, output_dir=output_dir, max_zoom=16, simplify_tolerance=10
    )

    print("\n🎉 Done! You can now use the tiles in your Flutter app.")
