// Test chuyển đổi từ local coordinate system sang WGS84
class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);

  @override
  String toString() => '($latitude, $longitude)';
}

LatLng vn2000ToWgs84(double easting, double northing) {
  // Manual calibration parameters from control points
  // This GeoJSON uses a local coordinate system, not standard VN-2000
  const double scaleLat = 2.4120738180668202e-05;
  const double scaleLng = -0.0001125292231222876;
  const double offsetLat = -26.74705849866553;
  const double offsetLng = 170.48497052784614;

  final lat = scaleLat * northing + offsetLat;
  final lng = scaleLng * easting + offsetLng;

  return LatLng(lat, lng);
}

void main() {
  print('=== Test Local Coordinate System to WGS84 Conversion ===\n');

  // Test cases from HOAHAI_POINT.geojson (Chi bộ markers)
  final testCases = [
    {'name': 'HOAHAI - Chi bộ 7', 'e': 554119.35, 'n': 1769660.86},
    {'name': 'HOAHAI - Chi bộ 1A', 'e': 553866.40, 'n': 1770002.47},
    {
      'name': 'KM - Mỹ Đa Đông 2 (Control Point)',
      'e': 553202.45,
      'n': 1774166.03
    },
    {
      'name': 'KM - Mỹ Đa Đông 1 (Control Point)',
      'e': 553144.35,
      'n': 1773958.52
    },
  ];

  print('Expected range for Da Nang area:');
  print('  Latitude: 15.9 - 16.3');
  print('  Longitude: 108.1 - 108.6\n');

  for (final tc in testCases) {
    final name = tc['name'] as String;
    final e = tc['e'] as double;
    final n = tc['n'] as double;

    final result = vn2000ToWgs84(e, n);

    final isValid = result.latitude >= 15.9 &&
        result.latitude <= 16.3 &&
        result.longitude >= 108.1 &&
        result.longitude <= 108.6;

    print('$name:');
    print('  VN-2000: ($e, $n)');
    print('  WGS84: ${result.toString()}');
    print('  Status: ${isValid ? "✅ Valid" : "❌ Invalid (out of range)"}\n');
  }

  print('\n=== Google Maps URLs for Verification ===');
  for (final tc in testCases) {
    final name = tc['name'] as String;
    final e = tc['e'] as double;
    final n = tc['n'] as double;
    final result = vn2000ToWgs84(e, n);

    print(
        '$name: https://www.google.com/maps?q=${result.latitude},${result.longitude}');
  }
}
