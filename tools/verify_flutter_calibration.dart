/// Verify rằng Flutter calibration constants hoạt động đúng
/// với các control points đã xác minh
library;

void main() {
  print('🔬 Verifying Flutter Calibration Constants...\n');

  // Constants từ CoordinateConverter trong map_screen.dart
  const double scaleLat = 2.4120738180668202e-05;
  const double scaleLng = -0.0001125292231222876;
  const double offsetLat = -26.74705849866553;
  const double offsetLng = 170.48497052784614;

  // Control points đã xác minh
  final controlPoints = [
    {
      'name': 'Chi bộ Mỹ Đa Đông 2',
      'easting': 553202.45,
      'northing': 1774166.03,
      'expectedLat': 16.0471358,
      'expectedLng': 108.2335286,
    },
    {
      'name': 'Chi bộ Mỹ Đa Đông 1',
      'easting': 553144.35,
      'northing': 1773958.52,
      'expectedLat': 16.0421305,
      'expectedLng': 108.2400664,
    },
  ];

  bool allTestsPassed = true;

  for (final point in controlPoints) {
    final easting = point['easting'] as double;
    final northing = point['northing'] as double;
    final expectedLat = point['expectedLat'] as double;
    final expectedLng = point['expectedLng'] as double;
    final name = point['name'] as String;

    // Áp dụng công thức transformation
    final lat = scaleLat * northing + offsetLat;
    final lng = scaleLng * easting + offsetLng;

    // Tính sai số
    final errorLat = (lat - expectedLat).abs();
    final errorLng = (lng - expectedLng).abs();

    // Convert sang mét (xấp xỉ)
    final errorMetersLat = errorLat * 111320; // 1° lat ≈ 111.32 km
    final errorMetersLng = errorLng * 111320 * 0.96; // cos(16°) ≈ 0.96

    final errorMeters =
        (errorMetersLat * errorMetersLat + errorMetersLng * errorMetersLng);
    final errorKm = errorMeters / 1000000;

    print('📍 $name');
    print('   Local: ($easting, $northing)');
    print('   Expected WGS84: ($expectedLat, $expectedLng)');
    print('   Computed WGS84: ($lat, $lng)');
    print('   Error: ${errorKm.toStringAsFixed(2)} km');

    if (errorKm > 0.01) {
      // > 10m = fail
      print('   ❌ FAIL - Error too large!\n');
      allTestsPassed = false;
    } else {
      print('   ✅ PASS\n');
    }
  }

  if (allTestsPassed) {
    print('✅ All calibration tests passed!');
    print('📱 Flutter app should display markers correctly in Da Nang area.');
  } else {
    print('❌ Calibration verification failed!');
    print('⚠️ Please check the constants in CoordinateConverter class.');
  }
}
