void main() {
  // Control points from user
  // GeoJSON -> Google Maps (WGS84)

  // Point 1: Chi bộ Mỹ Đa Đông 2
  final geojson1 = [111.4991748, 16.0456582];
  final wgs1 = [108.2420212, 16.0418518];

  // Point 2: Chi bộ Mỹ Đa Đông 1
  final geojson2 = [111.498627, 16.0437836];
  final wgs2 = [108.2426413, 16.0421305];

  print('=== Control Point Analysis ===');
  print('Point 1 (Mỹ Đa Đông 2):');
  print('  GeoJSON: [${geojson1[0]}, ${geojson1[1]}]');
  print('  WGS84:   [${wgs1[0]}, ${wgs1[1]}]');
  print('  Offset:  [${geojson1[0] - wgs1[0]}, ${geojson1[1] - wgs1[1]}]');

  print('\nPoint 2 (Mỹ Đa Đông 1):');
  print('  GeoJSON: [${geojson2[0]}, ${geojson2[1]}]');
  print('  WGS84:   [${wgs2[0]}, ${wgs2[1]}]');
  print('  Offset:  [${geojson2[0] - wgs2[0]}, ${geojson2[1] - wgs2[1]}]');

  // Calculate average offset
  final lngOffset1 = geojson1[0] - wgs1[0];
  final latOffset1 = geojson1[1] - wgs1[1];
  final lngOffset2 = geojson2[0] - wgs2[0];
  final latOffset2 = geojson2[1] - wgs2[1];

  final avgLngOffset = (lngOffset1 + lngOffset2) / 2;
  final avgLatOffset = (latOffset1 + latOffset2) / 2;

  print('\n=== Average Offset ===');
  print('Longitude offset: $avgLngOffset');
  print('Latitude offset:  $avgLatOffset');

  // Test transformation
  print('\n=== Testing Transformation ===');
  print('Applying: WGS84 = GeoJSON - offset');

  for (var i = 0; i < 2; i++) {
    final geojson = i == 0 ? geojson1 : geojson2;
    final expected = i == 0 ? wgs1 : wgs2;
    final name = i == 0 ? 'Mỹ Đa Đông 2' : 'Mỹ Đa Đông 1';

    final transformed = [geojson[0] - avgLngOffset, geojson[1] - avgLatOffset];

    final error = [
      (transformed[0] - expected[0]).abs(),
      (transformed[1] - expected[1]).abs()
    ];

    print('\n$name:');
    print('  Expected:    [${expected[0]}, ${expected[1]}]');
    print('  Transformed: [${transformed[0]}, ${transformed[1]}]');
    print('  Error:       [${error[0]}, ${error[1]}] degrees');
    print(
        '  Error:       [${error[0] * 111000}, ${error[1] * 111000}] meters (approx)');
  }

  print('\n=== Transformation Function ===');
  print('double transformLongitude(double lng) => lng - $avgLngOffset;');
  print('double transformLatitude(double lat) => lat - $avgLatOffset;');
}
