import json
import math


def vn2000_to_wgs84(easting, northing, zone=48):
    """
    Chuyển đổi VN-2000 (UTM) sang WGS84
    Zone 48N: Central Meridian = 105° + 3° = 108° E
    """
    # Constants
    FALSE_EASTING = 500000.0
    FALSE_NORTHING = 0.0
    K0 = 0.9996
    A = 6378137.0  # WGS84 semi-major axis
    E = 0.0818191908426  # first eccentricity
    E1SQ = 0.00673949674227  # e^2 / (1 - e^2)

    # Central meridian for Zone 48
    central_meridian = 105.0 + 3.0  # 108° E

    x = easting - FALSE_EASTING
    y = northing - FALSE_NORTHING

    M = y / K0
    mu = M / (A * (1 - E**2 / 4 - 3 * E**4 / 64 - 5 * E**6 / 256))

    phi1 = (
        mu
        + (3 * E1SQ / 2 - 27 * E1SQ**3 / 32) * math.sin(2 * mu)
        + (21 * E1SQ**2 / 16 - 55 * E1SQ**4 / 32) * math.sin(4 * mu)
        + (151 * E1SQ**3 / 96) * math.sin(6 * mu)
    )

    N1 = A / math.sqrt(1 - E**2 * math.sin(phi1) ** 2)
    T1 = math.tan(phi1) ** 2
    C1 = E1SQ * math.cos(phi1) ** 2
    R1 = A * (1 - E**2) / (1 - E**2 * math.sin(phi1) ** 2) ** 1.5
    D = x / (N1 * K0)

    lat = phi1 - (N1 * math.tan(phi1) / R1) * (
        D**2 / 2
        - (5 + 3 * T1 + 10 * C1 - 4 * C1**2 - 9 * E1SQ) * D**4 / 24
        + (61 + 90 * T1 + 298 * C1 + 45 * T1**2 - 252 * E1SQ - 3 * C1**2) * D**6 / 720
    )

    lon = (
        D
        - (1 + 2 * T1 + C1) * D**3 / 6
        + (5 - 2 * C1 + 28 * T1 - 3 * C1**2 + 8 * E1SQ + 24 * T1**2) * D**5 / 120
    ) / math.cos(phi1)

    lat_deg = lat * 180.0 / math.pi
    lon_deg = central_meridian + lon * 180.0 / math.pi

    return lat_deg, lon_deg


# Test với một số tọa độ từ file
print("Testing coordinate conversion:")
print("=" * 60)

# Test point từ file HOAHAI_POINT.geojson
test_points = [
    (554055.26, 1769811.71, "Tổ 119"),
    (553792.22, 1769840.88, "Tổ 120"),
    (554119.35, 1769660.86, "Chi bộ 7"),
]

for easting, northing, name in test_points:
    lat, lon = vn2000_to_wgs84(easting, northing)
    print(f"{name}:")
    print(f"  VN-2000: E={easting:.2f}, N={northing:.2f}")
    print(f"  WGS84: Lat={lat:.6f}, Lon={lon:.6f}")
    print(f"  Google Maps: https://www.google.com/maps?q={lat},{lon}")
    print()

# Calculate center
print("\nCalculating center of HOAHAI area:")
with open("../assets/maps/HOAHAI_LINE.geojson", "r", encoding="utf-8") as f:
    data = json.load(f)

coords = []
for feature in data["features"]:
    geom = feature["geometry"]
    if geom["type"] == "LineString":
        coords.extend(geom["coordinates"])
    elif geom["type"] == "MultiLineString":
        for line in geom["coordinates"]:
            coords.extend(line)

if coords:
    avg_e = sum(c[0] for c in coords) / len(coords)
    avg_n = sum(c[1] for c in coords) / len(coords)
    center_lat, center_lon = vn2000_to_wgs84(avg_e, avg_n)

    print(f"Average VN-2000: E={avg_e:.2f}, N={avg_n:.2f}")
    print(f"Center WGS84: Lat={center_lat:.6f}, Lon={center_lon:.6f}")
    print(f"Google Maps: https://www.google.com/maps?q={center_lat},{center_lon}")
